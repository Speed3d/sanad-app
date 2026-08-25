// ─────────────────────────────────────────────────────────────────────────────
// payroll_dao.dart — كشوف الرواتب الشهرية وسطورها (Schema v7)
//
// 🔑 **العملية الأخطر هنا: [PayrollDao.payEntries]**
//   تُنشئ **سند صرف واحداً بالمجموع** وتُعلّم سطوره مدفوعة وتُسجّل أقساط
//   سلف الموظفين — كلّه في **معاملة واحدة**. فشل جزئي هنا يعني إما مالاً
//   خرج بلا سجلّ يقابله، أو سطوراً معلَّمة مدفوعة بلا سند — وكلاهما يفسد
//   الدفاتر بصمت.
//
// **لماذا سند واحد لا سند لكل موظف؟** (قرار المالك 2026-08-24)
//   السجل التفصيلي لكل موظف محفوظ في **سطر الكشف بلقطته**، فلا حاجة
//   لتكراره في ٣٦٠ سنداً سنوياً. السند يمثّل **حركة المال**، والكشف يمثّل
//   **التفصيل**.
//
// **لماذا لا توجد نماذج domain لهذا النظام؟**
//   الجداول تُعاد كما هي (`PayrollPeriod` · `SalaryPayment` من Drift)، على
//   نمط `AttachmentsDao` المعتمد في Schema v6. إضافة نموذجَي freezed
//   ومسارَي تحويل بينهما لا تشتري شيئاً هنا: لا مصدر بيانات ثانياً
//   يُستبدَل، والاختبارات تستعمل قاعدة حقيقية أصلاً. وكل سطر تحويل إضافي
//   هو موضعٌ يُنسى فيه حقل — وهي **بالضبط** علّة ب-١ (المستودع كان يُسقط
//   أربعة حقول في ثلاثة مواضع).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/employees_table.dart';
import '../tables/payroll_periods_table.dart';
import '../tables/vouchers_table.dart';
import '../../../core/services/payroll_calculator.dart';

part 'payroll_dao.g.dart';

/// سنة رواتب مشتقّة — لا جدول لها
///
/// السنوات تُشتقّ بـ`GROUP BY year` على الكشوف. تخزين سنةٍ فارغة يفتح باب
/// سنةٍ بلا أشهر تظهر في القائمة بلا محتوى.
class PayrollYearSummary {
  final int year;

  /// عدد الأشهر التي أُنشئ لها كشف
  final int monthCount;

  /// عدد الأشهر المسدَّدة منها
  final int paidMonthCount;

  /// مجموع صافي الرواتب بالدينار في السنة كلها
  final double totalIqd;

  const PayrollYearSummary({
    required this.year,
    required this.monthCount,
    required this.paidMonthCount,
    required this.totalIqd,
  });
}

/// إجماليات كشف واحد — تُقرأ دفعةً واحدة بدل ثلاثة استعلامات
class PayrollPeriodTotals {
  /// عدد السطور الحيّة
  final int entryCount;

  /// عدد السطور المسدَّدة
  final int paidCount;

  /// مجموع الصافي بالدينار (كل السطور)
  final double totalIqd;

  /// مجموع الصافي بالدينار للسطور **غير المسدَّدة** — وهو ما سيخرج من الخزينة
  final double unpaidIqd;

  /// هل في الكشف سطر واحد على الأقل بالدولار؟ — يُلزم سعر صرف الشهر
  final bool hasForeignCurrency;

  const PayrollPeriodTotals({
    required this.entryCount,
    required this.paidCount,
    required this.totalIqd,
    required this.unpaidIqd,
    required this.hasForeignCurrency,
  });

  /// هل سُدِّد الكشف بالكامل؟
  bool get isFullyPaid => entryCount > 0 && paidCount == entryCount;
}

/// حصيلة تسديد دفعة رواتب
class PayPayrollResult {
  /// معرّف سند الصرف الواحد الذي أُنشئ
  final int voucherId;

  /// رقم السند داخل سنته المالية
  final int voucherNumber;

  /// عدد الموظفين الذين سُدِّدت رواتبهم
  final int employeeCount;

  /// إجمالي ما خرج من الخزينة بالدينار
  final double totalIqd;

  /// عدد أقساط سلف الموظفين التي سُجِّلت ضمن هذه الدفعة
  final int repaymentCount;

  /// هل صار الكشف مسدَّداً بالكامل بهذه الدفعة؟
  final bool periodCompleted;

  const PayPayrollResult({
    required this.voucherId,
    required this.voucherNumber,
    required this.employeeCount,
    required this.totalIqd,
    required this.repaymentCount,
    required this.periodCompleted,
  });
}

@DriftAccessor(
  tables: [PayrollPeriods, SalaryPayments, Employees, CashAdvances,
      CashAdvanceRepayments, Vouchers],
)
class PayrollDao extends DatabaseAccessor<AppDatabase> with _$PayrollDaoMixin {
  PayrollDao(super.db);

  // ═══════════════════════════════════════════════════════════════════════
  // قراءة الكشوف
  // ═══════════════════════════════════════════════════════════════════════

  /// السنوات المشتقّة من الكشوف — الأحدث أولاً
  Future<List<PayrollYearSummary>> getYears() async {
    final rows = await customSelect(
      'SELECT p.year AS y, '
      '       COUNT(*) AS months, '
      "       SUM(CASE WHEN p.status = 'posted' THEN 1 ELSE 0 END) AS paid, "
      '       COALESCE(('
      '         SELECT SUM(s.net_amount_iqd) FROM salary_payments s '
      '         INNER JOIN payroll_periods pp ON pp.id = s.payroll_period_id '
      '         WHERE pp.year = p.year AND pp.is_deleted = 0 '
      '           AND s.is_deleted = 0'
      '       ), 0) AS total '
      'FROM payroll_periods p '
      'WHERE p.is_deleted = 0 '
      'GROUP BY p.year '
      'ORDER BY p.year DESC',
      readsFrom: {payrollPeriods, salaryPayments},
    ).get();

    return rows
        .map((r) => PayrollYearSummary(
              year: r.data['y'] as int,
              monthCount: r.data['months'] as int? ?? 0,
              paidMonthCount: (r.data['paid'] as int?) ?? 0,
              totalIqd: (r.data['total'] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();
  }

  /// كشوف سنة بعينها — Reactive
  Stream<List<PayrollPeriod>> watchPeriodsForYear(int year) {
    return (select(payrollPeriods)
          ..where((p) => p.year.equals(year) & p.isDeleted.equals(false))
          ..orderBy([(p) => OrderingTerm.asc(p.month)]))
        .watch();
  }

  /// كل الكشوف — الأحدث أولاً
  Stream<List<PayrollPeriod>> watchAllPeriods() {
    return (select(payrollPeriods)
          ..where((p) => p.isDeleted.equals(false))
          ..orderBy([
            (p) => OrderingTerm.desc(p.year),
            (p) => OrderingTerm.desc(p.month),
          ]))
        .watch();
  }

  /// كشف واحد بالمعرّف — Reactive
  Stream<PayrollPeriod?> watchPeriodById(int id) {
    return (select(payrollPeriods)..where((p) => p.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<PayrollPeriod?> getPeriodById(int id) {
    return (select(payrollPeriods)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// كشف شهر بعينه — المفتاح الطبيعي (سنة، شهر)
  Future<PayrollPeriod?> getPeriodForMonth(int year, int month) {
    return (select(payrollPeriods)
          ..where((p) =>
              p.year.equals(year) &
              p.month.equals(month) &
              p.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// البحث عن كشف استُورد فيه ملف بنفس البصمة — كشف الاستيراد المكرّر
  ///
  /// استيراد الملف نفسه مرّتين يضاعف الرواتب بصمت، وهو خطأ وارد جداً في
  /// العمل الشهري. البصمة تكشفه قبل أن يقع.
  Future<PayrollPeriod?> findByFileHash(String hash) {
    if (hash.isEmpty) return Future.value(null);
    return (select(payrollPeriods)
          ..where((p) =>
              p.sourceFileHash.equals(hash) & p.isDeleted.equals(false))
          ..limit(1))
        .getSingleOrNull();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // كتابة الكشوف
  // ═══════════════════════════════════════════════════════════════════════

  Future<int> insertPeriod(PayrollPeriodsCompanion period) {
    return into(payrollPeriods).insert(period);
  }

  /// تحديث جزئي — `write` لا `replace`
  ///
  /// `replace` تُعيد كل حقل غائب إلى قيمته الافتراضية، فتُحيي كشفاً محذوفاً
  /// وتمسح تاريخ اعتماده. راجع ع-١٥.
  Future<void> updatePeriod(int id, PayrollPeriodsCompanion changes) async {
    await (update(payrollPeriods)..where((p) => p.id.equals(id)))
        .write(changes);
  }

  /// حذف ناعم للكشف **وسطوره معاً**
  ///
  /// الحذف الناعم للرأس وحده يترك سطوراً حيّة تُحتسب في تقارير الرواتب بلا
  /// كشف يظهرها — رقمٌ في تقرير لا مصدر له في أي شاشة.
  Future<void> softDeletePeriod(int id) async {
    await transaction(() async {
      final now = DateTime.now();
      await (update(salaryPayments)
            ..where((s) => s.payrollPeriodId.equals(id)))
          .write(SalaryPaymentsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(now),
      ));
      await (update(payrollPeriods)..where((p) => p.id.equals(id))).write(
        PayrollPeriodsCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(now),
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // سطور الكشف
  // ═══════════════════════════════════════════════════════════════════════

  /// سطور كشف — **بترتيب ملف الإكسل**، Reactive
  ///
  /// ⚠️ **بالمعرّف لا بالاسم** (بلاغ المالك 2026-08-25):
  ///   الترتيب الأبجدي يبعثر الكشف عن ترتيب الملف الذي أرسله المحاسب، فلا
  ///   يستطيع المالك مطابقة سطرٍ بسطر وهو يراجع ورقةً أمامه. والمعرّف
  ///   تصاعديّ بترتيب الإدراج، والإدراج يقع بترتيب صفوف الملف — فهو
  ///   **ترتيب الملف نفسه** بلا عمود إضافي.
  ///
  /// 📌 والاستيراد التراكمي يحفظ المعنى: موظفو ملف البصرة أولاً ثم موظفو
  ///   ملف كربلاء، كلٌّ بترتيبه الداخلي.
  Stream<List<SalaryPayment>> watchEntries(int periodId) {
    return (select(salaryPayments)
          ..where((s) =>
              s.payrollPeriodId.equals(periodId) & s.isDeleted.equals(false))
          ..orderBy([(s) => OrderingTerm.asc(s.id)]))
        .watch();
  }

  Future<List<SalaryPayment>> getEntries(int periodId) {
    return (select(salaryPayments)
          ..where((s) =>
              s.payrollPeriodId.equals(periodId) & s.isDeleted.equals(false))
          ..orderBy([(s) => OrderingTerm.asc(s.id)]))
        .get();
  }

  Future<SalaryPayment?> getEntryById(int id) {
    return (select(salaryPayments)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  /// سطر موظف بعينه في كشف بعينه — للاستيراد التراكمي
  ///
  /// وجوده يعني أن الموظف **مُدرَج أصلاً** في هذا الشهر، فلا يُضاف ثانيةً.
  Future<SalaryPayment?> getEntryForEmployee({
    required int periodId,
    required int employeeId,
  }) {
    return (select(salaryPayments)
          ..where((s) =>
              s.payrollPeriodId.equals(periodId) &
              s.employeeId.equals(employeeId) &
              s.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<int> insertEntry(SalaryPaymentsCompanion entry) {
    return into(salaryPayments).insert(entry);
  }

  Future<void> updateEntry(int id, SalaryPaymentsCompanion changes) async {
    await (update(salaryPayments)..where((s) => s.id.equals(id))).write(
      changes.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  /// حذف ناعم لسطر — لإخراج موظف من كشف الشهر
  Future<void> softDeleteEntry(int id) async {
    await (update(salaryPayments)..where((s) => s.id.equals(id))).write(
      SalaryPaymentsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // الإجماليات
  // ═══════════════════════════════════════════════════════════════════════

  /// إجماليات كشف — استعلام واحد بدل أربعة
  ///
  /// 🔑 **هذه هي القاعدة الوحيدة لمجموع الكشف.** كل شاشة وتقرير وطباعة
  ///   تسأل هنا. توزيع الجمع على المستدعين هو **حرفياً** ما ضرب مشروع DMS:
  ///   كان مكرَّراً في ثمانية مواضع، فأُضيف مخرَجٌ تاسع نسي القاعدة
  ///   واحتُسب راتب لم يُدفع.
  Future<PayrollPeriodTotals> getTotals(int periodId) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS cnt, '
      "       SUM(CASE WHEN payment_status = 'paid' THEN 1 ELSE 0 END) AS paid, "
      '       COALESCE(SUM(net_amount_iqd), 0) AS total, '
      '       COALESCE(SUM(CASE WHEN payment_status = \'unpaid\' '
      '                    THEN net_amount_iqd ELSE 0 END), 0) AS unpaid, '
      "       SUM(CASE WHEN snapshot_currency = 'USD' THEN 1 ELSE 0 END) AS usd "
      'FROM salary_payments '
      'WHERE payroll_period_id = ? AND is_deleted = 0',
      variables: [Variable.withInt(periodId)],
      readsFrom: {salaryPayments},
    ).getSingle();

    return PayrollPeriodTotals(
      entryCount: row.data['cnt'] as int? ?? 0,
      paidCount: (row.data['paid'] as int?) ?? 0,
      totalIqd: (row.data['total'] as num?)?.toDouble() ?? 0.0,
      unpaidIqd: (row.data['unpaid'] as num?)?.toDouble() ?? 0.0,
      hasForeignCurrency: ((row.data['usd'] as int?) ?? 0) > 0,
    );
  }

  /// مجموع صافي سطور بعينها بالدينار — أساس مطابقة سطر السلفة (المرحلة ٣)
  Future<double> getTotalIqdForEntries(List<int> entryIds) async {
    if (entryIds.isEmpty) return 0.0;
    final rows = await (select(salaryPayments)
          ..where((s) => s.id.isIn(entryIds) & s.isDeleted.equals(false)))
        .get();
    return rows.fold<double>(0, (sum, e) => sum + e.netAmountIqd);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🔑 التسديد — اللحظة الوحيدة التي تتأثر فيها الخزينة
  // ═══════════════════════════════════════════════════════════════════════

  /// تسديد دفعة رواتب بسند صرف **واحد بالمجموع**
  ///
  /// ⚠️ لا يُجري هذا التابع أي فحص للصلاحيات أو الرصيد أو الفترة المالية —
  ///   تلك مسؤولية `PayrollRepository` الذي يستدعيه. الفصل مقصود: الـ DAO
  ///   يضمن **الذرّية**، والمستودع يضمن **قواعد العمل**. (نمط `postAdvance`.)
  ///
  /// [entryIds]     — السطور الداخلة في هذه الدفعة (غير المسدَّدة)
  /// [treasuryId]   — الخزينة التي يخرج منها المال
  /// [advanceId] / [advanceLineId] — يُملآن حين يقع التسديد عبر سلفة مشروع
  ///
  /// **الترتيب داخل المعاملة:**
  ///   رقم السند ← السند ← تحديث السطور ← أقساط سلف الموظفين ← حالة الكشف
  Future<PayPayrollResult> payEntries({
    required int periodId,
    required List<int> entryIds,
    required int treasuryId,
    required int fiscalPeriodId,
    required DateTime paymentDate,
    required String periodLabel,
    int? paidByUserId,
    int? advanceId,
    int? advanceLineId,
    String? advanceNumber,
    String? projectName,
  }) async {
    return transaction(() async {
      final entries = await (select(salaryPayments)
            ..where((s) =>
                s.id.isIn(entryIds) &
                s.isDeleted.equals(false) &
                s.paymentStatus.equals(PayrollPaymentStatusDb.unpaid)))
          .get();

      if (entries.isEmpty) {
        throw StateError(
          'لا توجد سطور قابلة للتسديد في هذه الدفعة — '
          'قد تكون سُدِّدت بالفعل.',
        );
      }

      final total = entries.fold<double>(0, (s, e) => s + e.netAmountIqd);

      // ── 1. رقم السند — ذرّي عبر UPSERT في voucher_sequences ──────────
      final voucherNumber = await db.fiscalPeriodsDao.getNextVoucherNumber(
        fiscalPeriodId: fiscalPeriodId,
        voucherType: 'sarf',
      );

      // ── 2. سند الصرف الواحد بالمجموع ─────────────────────────────────
      // البيان يذكر الشهر وعدد الموظفين: سندٌ بمليون دينار بلا بيان يجعل
      // مراجعة الدفاتر بعد سنة تخميناً.
      final voucherId = await into(vouchers).insert(
        VouchersCompanion.insert(
          voucherNumber: voucherNumber,
          voucherType: 'sarf',
          treasuryId: treasuryId,
          fiscalPeriodId: fiscalPeriodId,
          amount: total,
          currency: const Value('IQD'),
          exchangeRate: const Value(1.0),
          voucherDate: paymentDate,
          personName: Value('${entries.length} موظفاً'),
          reason: Value('رواتب $periodLabel'),
          itemType: const Value('راتب'),
          projectName: Value(projectName),
          advanceNumber: Value(advanceNumber),
          advanceId: Value(advanceId),
          createdByUserId: Value(paidByUserId),
        ),
      );

      // ── 3. تعليم السطور مدفوعة وربطها بسندها ─────────────────────────
      final now = DateTime.now();
      for (final e in entries) {
        await (update(salaryPayments)..where((s) => s.id.equals(e.id))).write(
          SalaryPaymentsCompanion(
            paymentStatus: const Value(PayrollPaymentStatusDb.paid),
            paidAt: Value(now),
            paymentDate: Value(paymentDate),
            treasuryId: Value(treasuryId),
            voucherId: Value(voucherId),
            advanceId: Value(advanceId),
            advanceLineId: Value(advanceLineId),
            updatedAt: Value(now),
          ),
        );
      }

      // ── 4. أقساط سلف الموظفين المخصومة من هذه الرواتب ────────────────
      //
      // لا سند قبض معها: المال لم يتحرّك، بل خرج راتبٌ أقل. ولهذا وُجدت
      // طريقة `'salary_deduction'` في `cash_advance_repayments` منذ
      // البداية — **وبصفر استعمال حتى الآن**.
      var repayments = 0;
      for (final e in entries) {
        if (e.advanceRepaymentAmount <= 0 || e.cashAdvanceId == null) continue;

        final advance =
            await db.employeesDao.getAdvanceById(e.cashAdvanceId!);

        // ⚠️ **لا تخطٍّ صامت.** الخصم وقع فعلاً في الصافي المصروف، فلو لم
        //   يُسجَّل قسطه بقيت السلفة كاملةً على الموظف: خُصم من راتبه ولم
        //   يُحسَب له. الفشل هنا يُلغي الدفعة كلها — وهو الصواب.
        if (advance == null || advance.isDeleted) {
          throw StateError(
            'خصم سلفة لـ«${e.snapshotName}» يشير إلى سلفة غير موجودة — '
            'أزل الخصم أو صحّح ربطه قبل التسديد.',
          );
        }

        final newRepaid = advance.totalRepaid + e.advanceRepaymentAmount;
        // قيد `CHECK(total_repaid <= amount)` كان سيرمي رسالة إنجليزية
        // غامضة. نسبقه برسالة تسمّي الموظف والمبلغ الفائض.
        if (newRepaid > advance.amount + 0.001) {
          final remaining = advance.amount - advance.totalRepaid;
          throw StateError(
            'خصم سلفة «${e.snapshotName}» (${e.advanceRepaymentAmount}) '
            'يتجاوز المتبقي من سلفته ($remaining).',
          );
        }

        await db.employeesDao.insertRepayment(
          repayment: CashAdvanceRepaymentsCompanion.insert(
            cashAdvanceId: advance.id,
            amount: e.advanceRepaymentAmount,
            repaymentDate: paymentDate,
            method: const Value('salary_deduction'),
            notes: Value('خصم من راتب $periodLabel'),
          ),
          advanceId: advance.id,
          newTotalRepaid: newRepaid,
          // المقارنة بهامش: الفاصلة العائمة تجعل المساواة التامة غير مضمونة
          newStatus:
              newRepaid >= advance.amount - 0.001 ? 'paid' : 'partial',
        );
        repayments++;
      }

      // ── 5. هل اكتمل الكشف؟ ───────────────────────────────────────────
      // يُقرأ بعد التحديث لا قبله — الكشف الشامل يُسدَّد على دفعات، فلا
      // يصير `posted` إلا حين لا يبقى فيه سطر غير مسدَّد.
      final remaining = await customSelect(
        'SELECT COUNT(*) AS c FROM salary_payments '
        "WHERE payroll_period_id = ? AND is_deleted = 0 "
        "AND payment_status = 'unpaid'",
        variables: [Variable.withInt(periodId)],
        readsFrom: {salaryPayments},
      ).getSingle();
      final completed = (remaining.data['c'] as int? ?? 0) == 0;

      if (completed) {
        await (update(payrollPeriods)..where((p) => p.id.equals(periodId)))
            .write(PayrollPeriodsCompanion(
          status: const Value(PayrollStatusDb.posted),
          postedAt: Value(now),
          postedByUserId: Value(paidByUserId),
        ));
      }

      return PayPayrollResult(
        voucherId: voucherId,
        voucherNumber: voucherNumber,
        employeeCount: entries.length,
        totalIqd: total,
        repaymentCount: repayments,
        periodCompleted: completed,
      );
    });
  }
}
