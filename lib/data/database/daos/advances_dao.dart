// ─────────────────────────────────────────────────────────────────────────────
// advances_dao.dart — DAO سلف المشاريع (الترويسة + أسطر المسودة)
//
// ⚠️ Advances ≠ CashAdvances (سلف الموظفين) — راجع advances_table.dart
//
// 🔑 العملية الأخطر في هذا الملف: postAdvance()
//   تحوّل أسطر المسودة إلى سندات صرف حقيقية داخل **معاملة واحدة**.
//   إما أن تُنشأ كل السندات وتُربَط بأسطرها وتتغيّر حالة السلفة، أو لا شيء
//   إطلاقاً. فشل جزئي هنا يعني دفاتر مشوّهة: سندات بلا سلفة، أو سلفة معتمدة
//   بنصف مصاريفها — وكلاهما يفسد الأرصدة بصمت.
//
// لماذا لا نستخدم insertVouchersBatch الموجودة في vouchers_dao؟
//   batch.insertAll لا تُعيد المعرّفات المُولَّدة، ونحن نحتاجها لملء
//   advance_lines.voucher_id (الرباط بين السطر وسنده). الإدراج الفردي داخل
//   db.transaction() يحفظ الذرّية نفسها ويُعيد المعرّفات.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/advances_table.dart';
import '../tables/advance_lines_table.dart';
import '../tables/item_types_table.dart';
import '../tables/vouchers_table.dart';
import '../tables/employees_table.dart';
import '../tables/payroll_periods_table.dart';
import '../../../core/services/payroll_calculator.dart';

part 'advances_dao.g.dart';

/// نتيجة اعتماد سلفة
class PostAdvanceResult {
  /// معرّفات السندات التي أُنشئت
  final List<int> voucherIds;

  /// إجمالي المبلغ المُرحَّل
  final double totalPosted;

  /// عدد الموظفين الذين صارت رواتبهم مسدَّدة بهذا الاعتماد (Schema v7)
  ///
  /// صفرٌ في السلفة العادية. وأكبرُ من صفر حين تحوي أسطرها **تسديد رواتب**
  /// مربوطاً بكشف شهر — فيصير الاعتماد الواحد حدثاً في نظامين معاً.
  final int payrollEmployeesPaid;

  /// كشوف الرواتب التي اكتملت بهذا الاعتماد
  final List<String> payrollPeriodsCompleted;

  const PostAdvanceResult({
    required this.voucherIds,
    required this.totalPosted,
    this.payrollEmployeesPaid = 0,
    this.payrollPeriodsCompleted = const [],
  });
}

/// معاينة أثر ربط سطر سلفة بكشف رواتب — تُقرأ **قبل** الاعتماد
///
/// 🔑 قرار المالك 2026-08-24: **التأكيد الذرّي لا الإشعار اليدوي.** يرى
///   المالك الأثر في حوار الاعتماد قبل وقوعه، ويقع كلّه في معاملة واحدة —
///   فلا تبقى نافذة يكون فيها المال قد خرج والكشف ما زال «مسودة».
class PayrollLinkPreview {
  /// السطر المربوط
  final int lineId;

  /// مبلغ السطر كما في المسودة
  final double lineAmount;

  /// مجموع صافي رواتب الموظفين المشمولين — بالدينار
  final double payrollTotal;

  /// عدد الموظفين المشمولين
  final int employeeCount;

  /// تسمية الشهر («شباط 2025»)
  final String periodLabel;

  const PayrollLinkPreview({
    required this.lineId,
    required this.lineAmount,
    required this.payrollTotal,
    required this.employeeCount,
    required this.periodLabel,
  });

  /// الفرق بين مبلغ السطر ومجموع الرواتب
  double get difference => lineAmount - payrollTotal;

  /// هل يتطابق المبلغان؟ — **هامش دينار واحد** للتقريب
  ///
  /// الملفات اليدوية تُقرّب، والفرق الأصغر من دينار ضجيجُ فاصلة عائمة لا
  /// خطأُ حساب. وما فوقه فرقٌ حقيقي يمنع الاعتماد.
  bool get matches => difference.abs() <= 1.0;
}

/// DAO سلف المشاريع
/// دائن واحد في تقرير «المستحقات» — من غطّى عجزاً ولم يُسدَّد له
///
/// يُشتقّ من سلف المشاريع المعتمدة بعجز. حين تتجاوز مصاريف المشروع رصيد
/// خزينته، يُطلَب اسم من غطّى الفرق من ماله قبل الاعتماد — وهذا الاسم
/// **دَين حقيقي على الشركة** كان مدفوناً داخل سجلات السلف بلا تقرير يجمعه.
class DeficitCreditorRow {
  /// اسم من غطّى العجز
  final String coveredBy;

  /// مجموع ما غطّاه عبر كل السلف
  final double totalCovered;

  /// عدد السلف التي غطّى فيها
  final int advanceCount;

  const DeficitCreditorRow({
    required this.coveredBy,
    required this.totalCovered,
    required this.advanceCount,
  });
}

@DriftAccessor(tables: [
  Advances,
  AdvanceLines,
  ItemTypes,
  Vouchers,
  PayrollPeriods,
  SalaryPayments,
])
class AdvancesDao extends DatabaseAccessor<AppDatabase>
    with _$AdvancesDaoMixin {
  AdvancesDao(super.db);

  // ── قراءة السلف ───────────────────────────────────────────────────────────

  /// متابعة السلف حسب الحالة — Reactive Stream
  ///
  /// [status] — null = كل الحالات
  Stream<List<Advance>> watchAdvances({String? status}) {
    final q = select(advances);
    if (status != null) {
      q.where((a) => a.status.equals(status));
    }
    q.orderBy([(a) => OrderingTerm.desc(a.advanceDate)]);
    return q.watch();
  }

  /// متابعة سلفة واحدة — Reactive Stream
  Stream<Advance?> watchAdvanceById(int id) {
    return (select(advances)..where((a) => a.id.equals(id)))
        .watchSingleOrNull();
  }

  /// جلب سلفة بالمعرّف
  Future<Advance?> getAdvanceById(int id) {
    return (select(advances)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  /// السلف المفتوحة أو المسودات لخزينة مشروع محددة
  ///
  /// تُستخدَم في شاشة الاستيراد: «على أي سلفة أُنزل هذا الملف؟»
  Future<List<Advance>> getActiveAdvancesForTreasury(int treasuryId) {
    return (select(advances)
          ..where((a) =>
              a.projectTreasuryId.equals(treasuryId) &
              a.status.isIn([AdvanceStatusDb.open, AdvanceStatusDb.draft]))
          ..orderBy([(a) => OrderingTerm.desc(a.advanceDate)]))
        .get();
  }

  /// البحث عن سلفة استُورد فيها ملف ببصمة معيّنة
  ///
  /// يمنع مضاعفة المصاريف باستيراد نفس الملف مرتين — وهو خطأ وارد جداً
  /// في العمل اليومي ولا يكشفه شيء آخر في النظام.
  Future<Advance?> findByFileHash(String hash) {
    if (hash.isEmpty) return Future.value(null);
    return (select(advances)
          ..where((a) =>
              a.sourceFileHash.equals(hash) &
              a.status.equals(AdvanceStatusDb.cancelled).not())
          ..limit(1))
        .getSingleOrNull();
  }

  /// هل رقم السلفة مستعمَل في هذه الفترة المالية؟
  ///
  /// فحص استباقي لإعطاء رسالة عربية واضحة بدل ترك الفهرس الفريد يرمي
  /// استثناء SQLite غامضاً في وجه المستخدم.
  Future<bool> isAdvanceNumberTaken({
    required String advanceNumber,
    required int fiscalPeriodId,
    int? exceptId,
  }) async {
    final rows = await (select(advances)
          ..where((a) {
            var c = a.advanceNumber.equals(advanceNumber) &
                a.fiscalPeriodId.equals(fiscalPeriodId) &
                a.status.equals(AdvanceStatusDb.cancelled).not();
            if (exceptId != null) c = c & a.id.equals(exceptId).not();
            return c;
          })
          ..limit(1))
        .get();
    return rows.isNotEmpty;
  }

  // ── كتابة السلف ───────────────────────────────────────────────────────────

  /// إنشاء سلفة جديدة — يُعيد المعرّف المُولَّد
  Future<int> insertAdvance(AdvancesCompanion advance) {
    return into(advances).insert(advance);
  }

  /// تحديث جزئي للسلفة
  ///
  /// نستخدم write وليس replace للسبب نفسه الموثَّق في vouchers_dao:
  /// replace يُعيد الحقول الغائبة إلى قيمها الافتراضية فيمحو أثر الاعتماد
  /// والإلغاء ومقدار العجز.
  Future<bool> updateAdvance(AdvancesCompanion advance) async {
    final n = await (update(advances)
          ..where((a) => a.id.equals(advance.id.value)))
        .write(advance);
    return n > 0;
  }

  // ── أسطر المسودة ──────────────────────────────────────────────────────────

  /// متابعة أسطر سلفة — Reactive Stream مرتبة بترتيب الملف الأصلي
  Stream<List<AdvanceLine>> watchLines(int advanceId) {
    return (select(advanceLines)
          ..where((l) => l.advanceId.equals(advanceId))
          ..orderBy([(l) => OrderingTerm.asc(l.rowNumber)]))
        .watch();
  }

  /// جلب أسطر سلفة
  /// سطر مسودة واحد بالمعرّف
  Future<AdvanceLine?> getLineById(int id) {
    return (select(advanceLines)..where((l) => l.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<AdvanceLine>> getLines(int advanceId) {
    return (select(advanceLines)
          ..where((l) => l.advanceId.equals(advanceId))
          ..orderBy([(l) => OrderingTerm.asc(l.rowNumber)]))
        .get();
  }

  /// إدراج أسطر المسودة دفعة واحدة (بعد قراءة ملف الإكسل)
  Future<void> insertLines(List<AdvanceLinesCompanion> lines) async {
    await batch((b) => b.insertAll(advanceLines, lines));
  }

  /// تحديث سطر مسودة — تحديث جزئي
  Future<bool> updateLine(AdvanceLinesCompanion line) async {
    final n = await (update(advanceLines)
          ..where((l) => l.id.equals(line.id.value)))
        .write(line);
    return n > 0;
  }

  /// حذف كل أسطر سلفة (عند إعادة استيراد ملف بديل على نفس السلفة)
  Future<int> deleteLines(int advanceId) {
    return (delete(advanceLines)..where((l) => l.advanceId.equals(advanceId)))
        .go();
  }

  // ── حسابات الملخص ─────────────────────────────────────────────────────────

  /// المبلغ الصافي المُرسَل للمشروع على حساب هذه السلفة
  ///
  /// = مجموع التحويلات الواردة إلى خزينة المشروع
  /// − مجموع التحويلات الصادرة منها (إعادة مبلغ غير مصروف)
  ///
  /// الفلترة على خزينة المشروع ضرورية: سند التحويل الصادر من الخزينة
  /// الرئيسية يحمل نفس advance_id، وحسابه هنا كان سيُصفّر المُرسَل.
  Future<double> getSentAmount({
    required int advanceId,
    required int projectTreasuryId,
  }) async {
    final row = await customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN voucher_type = 'transfer_in'  THEN amount ELSE 0 END), 0)
      - COALESCE(SUM(CASE WHEN voucher_type = 'transfer_out' THEN amount ELSE 0 END), 0)
        AS net_sent
      FROM vouchers
      WHERE advance_id = ?
        AND treasury_id = ?
        AND is_deleted = 0
      ''',
      variables: [Variable.withInt(advanceId), Variable.withInt(projectTreasuryId)],
      readsFrom: {vouchers},
    ).getSingle();
    return (row.data['net_sent'] as num).toDouble();
  }

  /// مجموع مصاريف المسودات المعلّقة لكل خزينة مشروع
  ///
  /// يُستخدَم للتحذير المبكر على بطاقة الخزينة:
  ///   «الرصيد 3,000,000 · معلّق في مسودات 3,500,000 · المتاح −500,000»
  ///
  /// لماذا؟ المسودة لا تمسّ الرصيد (وهذا مقصود)، لكن ذلك يعني أن الخزينة
  /// تبدو ممتلئة بينما مصاريفها وصلت فعلاً وتنتظر الاعتماد فقط. عرض المعلّق
  /// يكشف العجز **قبل** لحظة الاعتماد لا بعدها.
  Stream<Map<int, double>> watchPendingDraftTotals() {
    return customSelect(
      '''
      SELECT a.project_treasury_id AS treasury_id,
             COALESCE(SUM(l.amount), 0) AS pending
      FROM advances a
      JOIN advance_lines l ON l.advance_id = a.id
      WHERE a.status = 'draft' AND l.is_excluded = 0
      GROUP BY a.project_treasury_id
      ''',
      readsFrom: {advances, advanceLines},
    ).watch().map((rows) {
      return {
        for (final r in rows)
          r.data['treasury_id'] as int: (r.data['pending'] as num).toDouble(),
      };
    });
  }

  /// المصروف المُرحَّل فعلياً (بعد الاعتماد) — مجموع سندات الصرف المرتبطة
  Future<double> getPostedSpent(int advanceId) async {
    final row = await customSelect(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM vouchers
      WHERE advance_id = ? AND voucher_type = 'sarf' AND is_deleted = 0
      ''',
      variables: [Variable.withInt(advanceId)],
      readsFrom: {vouchers},
    ).getSingle();
    return (row.data['total'] as num).toDouble();
  }

  // ── تقرير المستحقات (ب-٢) ────────────────────────────────────────────────

  /// من تدين لهم الشركة، مجمَّعين بالاسم ومرتَّبين بالأكبر
  ///
  /// **لماذا `status = 'posted'` فقط؟**
  ///   العجز رقم يُثبَّت **لحظة الاعتماد** لا قبله. السلفة المسودة قد يتغيّر
  ///   إجماليها بالتحرير، والملغاة عُكست سنداتها فلم يعد فيها دَين.
  ///
  /// **ولماذا نستبعد الاسم الفارغ؟**
  ///   الاعتماد بعجز يرفض المرور بلا اسم أصلاً (حارس في `AdvanceRepository`)،
  ///   فوجود صف بلا اسم يعني بيانات تسبق ذلك الحارس. استبعاده أصدق من عرض
  ///   دَين بلا دائن.
  Future<List<DeficitCreditorRow>> getDeficitCreditors() async {
    final rows = await customSelect(
      'SELECT deficit_covered_by AS who, '
      '       SUM(deficit_amount) AS total, '
      '       COUNT(*) AS cnt '
      'FROM advances '
      "WHERE status = 'posted' AND deficit_amount > 0 "
      "  AND deficit_covered_by IS NOT NULL AND deficit_covered_by != '' "
      'GROUP BY deficit_covered_by '
      'ORDER BY total DESC',
      readsFrom: {advances},
    ).get();

    return rows
        .map(
          (r) => DeficitCreditorRow(
            coveredBy: r.data['who'] as String,
            totalCovered: (r.data['total'] as num).toDouble(),
            advanceCount: r.data['cnt'] as int? ?? 0,
          ),
        )
        .toList();
  }

  // ── أنواع البنود ──────────────────────────────────────────────────────────

  /// متابعة أنواع البنود النشطة — Reactive Stream
  ///
  /// [kind] — 'sarf' | 'kabd' | null (الكل). البنود المُعلَّمة 'both' تظهر دائماً.
  Stream<List<ItemType>> watchItemTypes({String? kind}) {
    final q = select(itemTypes)..where((t) => t.isActive.equals(true));
    if (kind != null) {
      q.where((t) => t.kind.isIn([kind, 'both']));
    }
    q.orderBy([
      (t) => OrderingTerm.asc(t.sortOrder),
      (t) => OrderingTerm.asc(t.name),
    ]);
    return q.watch();
  }

  /// جلب أنواع البنود (كل الحالات — للإدارة في الإعدادات)
  Future<List<ItemType>> getAllItemTypes() {
    return (select(itemTypes)
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  /// إضافة نوع بند جديد
  Future<int> insertItemType(ItemTypesCompanion itemType) {
    return into(itemTypes).insert(itemType);
  }

  /// تحديث نوع بند (تعطيل / إعادة تسمية / ترتيب)
  Future<bool> updateItemType(ItemTypesCompanion itemType) async {
    final n = await (update(itemTypes)
          ..where((t) => t.id.equals(itemType.id.value)))
        .write(itemType);
    return n > 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔑 الاعتماد — تحويل المسودة إلى سندات صرف (معاملة ذرّية واحدة)
  // ═══════════════════════════════════════════════════════════════════════════

  /// اعتماد سلفة: كل سطر غير مستبعَد يصبح سند صرف على خزينة المشروع
  ///
  /// **كل شيء أو لا شيء.** أي استثناء في أي خطوة يُلغي المعاملة بالكامل فلا
  /// يبقى سند واحد ولا تتغيّر حالة السلفة.
  ///
  /// [advanceId]          — السلفة المراد اعتمادها
  /// [deficitAmount]      — العجز المحسوب مسبقاً في المستودع (0 = لا عجز)
  /// [deficitCoveredBy]   — من غطّى العجز (مطلوب إذا كان هناك عجز)
  /// [postedByUserId]     — المستخدم المعتمِد (للتدقيق)
  ///
  /// يُعيد معرّفات السندات المُنشأة وإجمالي المبلغ.
  ///
  /// ⚠️ لا يُجري هذا التابع أي فحص للصلاحيات أو الرصيد أو الفترة المالية —
  ///    تلك مسؤولية AdvanceRepository الذي يستدعيه. الفصل مقصود: الـ DAO
  ///    يضمن الذرّية، والمستودع يضمن قواعد العمل.
  // ═══════════════════════════════════════════════════════════════════════
  // 🔑 ربط سطر السلفة بكشف الرواتب (Schema v7)
  // ═══════════════════════════════════════════════════════════════════════

  /// سطور كشف الرواتب التي يغطّيها سطر سلفة
  ///
  /// **من يُعتبَر مشمولاً؟** موظفو **خزينة هذا المشروع** غير المسدَّدين.
  /// (قرار المالك 2026-08-24: `employees.treasury_id` هو رابط المشروع —
  /// موظفو خزنة البصرة هم موظفو مشروع البصرة، لأن `project_treasury_id`
  /// في السلفة تشير إلى الخزينة نفسها.)
  Future<List<SalaryPayment>> getPayrollEntriesForProject({
    required int payrollPeriodId,
    required int projectTreasuryId,
  }) async {
    final rows = await customSelect(
      'SELECT s.* FROM salary_payments s '
      'INNER JOIN employees e ON e.id = s.employee_id '
      'WHERE s.payroll_period_id = ? '
      '  AND s.is_deleted = 0 '
      "  AND s.payment_status = 'unpaid' "
      '  AND e.treasury_id = ? '
      'ORDER BY s.snapshot_name',
      variables: [
        Variable.withInt(payrollPeriodId),
        Variable.withInt(projectTreasuryId),
      ],
      readsFrom: {salaryPayments, db.employees},
    ).get();
    // `QueryRow.data` خريطة أعمدة خام — نحوّلها بمخطّط الجدول نفسه فلا
    // نُعيد كتابة أسماء الأعمدة يدوياً (وهو موضعٌ يُنسى فيه حقل عند التوسعة)
    return rows.map((r) => salaryPayments.map(r.data)).toList();
  }

  /// ربط سطر سلفة بكشف رواتب — ويعلّم سطور موظفي المشروع
  ///
  /// يُستدعى من شاشة المراجعة حين يضع المالك العلامة. **لا يمسّ مالاً**:
  /// السلفة ما زالت مسودة، والكشف ما زال مسودة. كل ما يقع هو رباط يُقرأ
  /// عند الاعتماد.
  Future<int> linkLineToPayroll({
    required int lineId,
    required int payrollPeriodId,
    required int projectTreasuryId,
  }) async {
    return transaction(() async {
      // فكّ أي ربط سابق لهذا السطر أولاً — وإلا تراكمت سطور من كشف قديم
      await (update(salaryPayments)
            ..where((s) => s.advanceLineId.equals(lineId)))
          .write(const SalaryPaymentsCompanion(advanceLineId: Value(null)));

      await (update(advanceLines)..where((l) => l.id.equals(lineId)))
          .write(AdvanceLinesCompanion(
        payrollPeriodId: Value(payrollPeriodId),
      ));

      final entries = await getPayrollEntriesForProject(
        payrollPeriodId: payrollPeriodId,
        projectTreasuryId: projectTreasuryId,
      );
      for (final e in entries) {
        await (update(salaryPayments)..where((s) => s.id.equals(e.id)))
            .write(SalaryPaymentsCompanion(advanceLineId: Value(lineId)));
      }
      return entries.length;
    });
  }

  /// فكّ ربط سطر سلفة عن كشف الرواتب
  Future<void> unlinkLineFromPayroll(int lineId) async {
    await transaction(() async {
      await (update(salaryPayments)
            ..where((s) => s.advanceLineId.equals(lineId)))
          .write(const SalaryPaymentsCompanion(advanceLineId: Value(null)));
      await (update(advanceLines)..where((l) => l.id.equals(lineId)))
          .write(const AdvanceLinesCompanion(payrollPeriodId: Value(null)));
    });
  }

  /// معاينة المطابقة لكل سطر مربوط في سلفة — **تُقرأ قبل الاعتماد**
  Future<List<PayrollLinkPreview>> getPayrollLinkPreviews(
    int advanceId,
  ) async {
    final lines = await (select(advanceLines)
          ..where((l) =>
              l.advanceId.equals(advanceId) &
              l.isExcluded.equals(false) &
              l.payrollPeriodId.isNotNull()))
        .get();

    final previews = <PayrollLinkPreview>[];
    for (final line in lines) {
      final rows = await (select(salaryPayments)
            ..where((s) =>
                s.advanceLineId.equals(line.id) & s.isDeleted.equals(false)))
          .get();
      final period = await (select(payrollPeriods)
            ..where((p) => p.id.equals(line.payrollPeriodId!)))
          .getSingleOrNull();

      previews.add(PayrollLinkPreview(
        lineId: line.id,
        lineAmount: line.amount,
        payrollTotal: rows.fold<double>(0, (sum, r) => sum + r.netAmountIqd),
        employeeCount: rows.length,
        periodLabel: period == null
            ? '—'
            : PayrollCalculator.periodLabel(period.year, period.month),
      ));
    }
    return previews;
  }

  Future<PostAdvanceResult> postAdvance({
    required int advanceId,
    required double deficitAmount,
    String? deficitCoveredBy,
    int? postedByUserId,
  }) async {
    return db.transaction(() async {
      final advance = await getAdvanceById(advanceId);
      if (advance == null) {
        throw StateError('السلفة غير موجودة (معرّف: $advanceId)');
      }

      // الأسطر الداخلة في الاعتماد — المستبعَدة تبقى في المسودة بلا سند
      final lines = await (select(advanceLines)
            ..where((l) =>
                l.advanceId.equals(advanceId) & l.isExcluded.equals(false))
            ..orderBy([(l) => OrderingTerm.asc(l.rowNumber)]))
          .get();

      if (lines.isEmpty) {
        throw StateError(
          'لا توجد أسطر قابلة للاعتماد في هذه السلفة — كل الأسطر مستبعَدة.',
        );
      }

      // ═══════════════════════════════════════════════════════════════
      // 🔑 حارس المطابقة — **قبل إنشاء أي سند**
      // ═══════════════════════════════════════════════════════════════
      //
      // كل سطر مربوط بكشف رواتب يجب أن يساوي مبلغُه **مجموع صافي رواتب
      // الموظفين المشمولين بالدينار**. واختلافهما يعني أحد أمرين، وكلاهما
      // يوجب التوقف:
      //   • الملف الذي أرسله المشروع يخالف كشف الرواتب  ⇐ خطأ يجب تصحيحه
      //   • بعض الموظفين لم يُشمَلوا أو شُمِل من لا يخصّه ⇐ ربط خاطئ
      //
      // ⚠️ **ولماذا هنا في الـ DAO لا في الشاشة؟** لأن هذه هي النقطة التي
      //   لا يمكن الالتفاف عليها: أي مستدعٍ للاعتماد يمرّ منها. ولو عاش
      //   الحارس في حوار التأكيد لأمكن تجاوزه بمسار ثانٍ — وهو بالضبط ما
      //   كلّفنا عطلاً كاملاً في قاعدة عدم تقاطع الفترات (د-٢).
      //
      // 📌 وبدونه يُحتسَب المال **مرّتين**: مرة كسطر مصروف في السلفة ومرة
      //   كرواتب مسدَّدة — وهو صنف العطل ع-١٣ نفسه.
      final payrollLines =
          lines.where((l) => l.payrollPeriodId != null).toList();

      for (final line in payrollLines) {
        final entries = await (select(salaryPayments)
              ..where((sp) =>
                  sp.advanceLineId.equals(line.id) &
                  sp.isDeleted.equals(false)))
            .get();

        if (entries.isEmpty) {
          throw StateError(
            'سطر «${line.reason}» مربوط بكشف رواتب لا يشمل أي موظف من '
            'خزينة هذا المشروع.\n'
            'افكك الربط أو راجع خزائن الموظفين في الكشف.',
          );
        }

        final payrollTotal =
            entries.fold<double>(0, (sum, e) => sum + e.netAmountIqd);
        final diff = line.amount - payrollTotal;

        if (diff.abs() > 1.0) {
          throw StateError(
            'لا تطابق في سطر «${line.reason}»:\n'
            'مبلغ السلفة ${_fmtIqd(line.amount)} '
            'ومجموع رواتب ${entries.length} موظفاً '
            '${_fmtIqd(payrollTotal)} — '
            'الفرق ${_fmtIqd(diff.abs())} '
            '(${diff > 0 ? 'السلفة أعلى' : 'الرواتب أعلى'}).\n'
            'صحّح الملف أو الكشف قبل الاعتماد — الاعتماد بفارق يُدخل '
            'الدفاتر رقماً لا مصدر له.',
          );
        }
      }

      final voucherIds = <int>[];
      double total = 0;
      var payrollEmployeesPaid = 0;
      final completedPeriods = <String>[];

      for (final line in lines) {
        // رقم السند التالي — ذرّي عبر UPSERT في voucher_sequences
        final voucherNumber = await db.fiscalPeriodsDao.getNextVoucherNumber(
          fiscalPeriodId: advance.fiscalPeriodId,
          voucherType: 'sarf',
        );

        final voucherId = await into(vouchers).insert(
          VouchersCompanion.insert(
            voucherNumber: voucherNumber,
            voucherType: 'sarf',
            treasuryId: advance.projectTreasuryId,
            fiscalPeriodId: advance.fiscalPeriodId,
            amount: line.amount,
            // الاستيراد بالدينار حصراً — لا سعر صرف ولا التباس
            currency: const Value('IQD'),
            exchangeRate: const Value(1.0),
            voucherDate: line.voucherDate,
            personName: Value(line.personName),
            reason: Value(line.reason),
            itemType: Value(line.itemType),
            projectName: Value(line.projectName ?? advance.projectName),
            invoiceNumber: Value(line.invoiceNumber),
            spentBy: Value(line.spentBy),
            advanceNumber: Value(advance.advanceNumber),
            advanceId: Value(advanceId),
            createdByUserId: Value(postedByUserId),
          ),
        );

        // ربط السطر بسنده — بهذا يصبح لكل مصروف أثر مزدوج قابل للتتبع
        await (update(advanceLines)..where((l) => l.id.equals(line.id)))
            .write(AdvanceLinesCompanion(voucherId: Value(voucherId)));

        // ── تعليم رواتب هذا السطر مسدَّدة — **في المعاملة نفسها** ──────
        //
        // 🔑 قرار المالك 2026-08-24: **التأكيد الذرّي لا الإشعار اليدوي.**
        //   الإشعار كان يفتح نافذة: المال خرج من خزنة المشروع والكشف ما
        //   زال «مسودة» حتى يتذكّر المالك أن يعلّمه. ونسيانها يُبقي الكشف
        //   معلَّقاً إلى الأبد فيبدو بعد شهرين أن الرواتب لم تُدفع.
        //   وهو نمط د-٨ حرفياً: خطوة يدوية بعد عملية مالية = نصف ميزة.
        if (line.payrollPeriodId != null) {
          final now = DateTime.now();
          final entries = await (select(salaryPayments)
                ..where((sp) =>
                    sp.advanceLineId.equals(line.id) &
                    sp.isDeleted.equals(false) &
                    sp.paymentStatus
                        .equals(PayrollPaymentStatusDb.unpaid)))
              .get();

          for (final e in entries) {
            await (update(salaryPayments)..where((sp) => sp.id.equals(e.id)))
                .write(SalaryPaymentsCompanion(
              paymentStatus: const Value(PayrollPaymentStatusDb.paid),
              paidAt: Value(now),
              treasuryId: Value(advance.projectTreasuryId),
              voucherId: Value(voucherId),
              advanceId: Value(advanceId),
              updatedAt: Value(now),
            ));
          }
          payrollEmployeesPaid += entries.length;

          // هل اكتمل الكشف؟ — يُقرأ **بعد** التحديث لا قبله
          final remaining = await customSelect(
            'SELECT COUNT(*) AS c FROM salary_payments '
            'WHERE payroll_period_id = ? AND is_deleted = 0 '
            "AND payment_status = 'unpaid'",
            variables: [Variable.withInt(line.payrollPeriodId!)],
            readsFrom: {salaryPayments},
          ).getSingle();

          if ((remaining.data['c'] as int? ?? 0) == 0) {
            final period = await (select(payrollPeriods)
                  ..where((pp) => pp.id.equals(line.payrollPeriodId!)))
                .getSingleOrNull();
            if (period != null) {
              await (update(payrollPeriods)
                    ..where((pp) => pp.id.equals(period.id)))
                  .write(PayrollPeriodsCompanion(
                status: const Value(PayrollStatusDb.posted),
                postedAt: Value(now),
                postedByUserId: Value(postedByUserId),
              ));
              completedPeriods.add(
                PayrollCalculator.periodLabel(period.year, period.month),
              );
            }
          }
        }

        voucherIds.add(voucherId);
        total += line.amount;
      }

      // ختم السلفة: معتمدة، بمن اعتمدها ومتى، وبمقدار العجز إن وُجد
      await (update(advances)..where((a) => a.id.equals(advanceId))).write(
        AdvancesCompanion(
          status: const Value(AdvanceStatusDb.posted),
          postedAt: Value(DateTime.now()),
          postedByUserId: Value(postedByUserId),
          deficitAmount: Value(deficitAmount),
          deficitCoveredBy: Value(deficitCoveredBy),
        ),
      );

      return PostAdvanceResult(
        voucherIds: voucherIds,
        totalPosted: total,
        payrollEmployeesPaid: payrollEmployeesPaid,
        payrollPeriodsCompleted: completedPeriods,
      );
    });
  }

  /// إلغاء سلفة معتمدة أو مسودة
  ///
  /// المعتمدة: تُحذف **سندات الصرف** التي أنشأها الاعتماد حذفاً ناعماً، فيرتدّ
  /// المبلغ إلى الخزينة تلقائياً (الرصيد محسوب من السندات لا مخزَّن)، ويبقى
  /// الأثر الرقابي كاملاً.
  ///
  /// ⚠️ سندات التحويل (transfer_in/out) **لا تُحذف** رغم حملها نفس advance_id.
  ///   الإلغاء يتراجع عن *تسجيل المصاريف* لا عن *حركة المال*: المبلغ انتقل
  ///   فعلاً من الخزينة الرئيسية إلى خزنة المشروع وما زال هناك. حذفه كان
  ///   يُبخّر التمويل ويُظهر خزنة المشروع صفراً بدل رصيدها الحقيقي.
  ///   (كشفه اختبار «إلغاء سلفة معتمدة يُعيد المبلغ للخزينة».)
  Future<void> cancelAdvance({
    required int advanceId,
    int? cancelledByUserId,
  }) async {
    await db.transaction(() async {
      final now = DateTime.now();

      // حذف ناعم لسندات الصرف الناتجة عن الاعتماد فقط
      await (update(vouchers)
            ..where((v) =>
                v.advanceId.equals(advanceId) &
                v.voucherType.equals('sarf') &
                v.isDeleted.equals(false)))
          .write(
        VouchersCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(now),
          updatedByUserId: Value(cancelledByUserId),
          updatedAt: Value(now),
        ),
      );

      // فكّ ربط الأسطر بسنداتها المحذوفة
      await (update(advanceLines)
            ..where((l) => l.advanceId.equals(advanceId)))
          .write(const AdvanceLinesCompanion(voucherId: Value(null)));

      await (update(advances)..where((a) => a.id.equals(advanceId))).write(
        AdvancesCompanion(
          status: const Value(AdvanceStatusDb.cancelled),
          cancelledAt: Value(now),
          cancelledByUserId: Value(cancelledByUserId),
        ),
      );
    });
  }
}

/// ثوابت حالات السلفة على مستوى قاعدة البيانات
///
/// نسخة من AdvanceStatus في طبقة الـ domain — مكرّرة عمداً هنا لأن طبقة
/// البيانات يجب ألا تستورد من طبقة الـ domain (اتجاه الاعتماد معاكس).
/// تنسيق مبلغ بالدينار لرسائل الحرّاس
///
/// رسالةٌ تقول «الفرق 1250000.0» أصعب قراءةً من «1,250,000 د.ع» — والمالك
/// يقرأ هذه الرسالة في لحظة توتّر (اعتمادٌ رُفض)، فوضوحها جزء من الإصلاح.
String _fmtIqd(double v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '$buf د.ع';
}

abstract final class AdvanceStatusDb {
  static const String open = 'open';
  static const String draft = 'draft';
  static const String posted = 'posted';
  static const String cancelled = 'cancelled';
}
