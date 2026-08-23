// ─────────────────────────────────────────────────────────────────────────────
// vouchers_dao.dart — DAO السندات (صرف + قبض + تحويل + افتتاحي)
//
// هذا أهم DAO في التطبيق — يُدير جميع عمليات السندات.
//
// أنواع السندات المدعومة:
//   'sarf'            — سند صرف (صرف من الخزينة)
//   'kabd'            — سند قبض (إيداع في الخزينة)
//   'opening_balance' — رصيد افتتاحي (عند إقفال السنة)
//   'transfer_out'    — تحويل صادر
//   'transfer_in'     — تحويل وارد
//
// عمليات التحويل بين الخزائن:
//   تُنفَّذ في Transaction واحدة:
//   1. سند transfer_out للخزينة المُرسِلة
//   2. سند transfer_in  للخزينة المُستقبِلة
//   كلا السندين أو لا شيء (Atomicity)
//
// كشف الحساب:
//   getAccountStatement() يُعيد سجل كامل مرتب بالتاريخ مع الرصيد التراكمي
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' show Random;

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/vouchers_table.dart';
import '../tables/fiscal_periods_table.dart';
import '../tables/treasuries_table.dart';
import '../tables/advance_lines_table.dart';

part 'vouchers_dao.g.dart';

// ── نموذج بيانات سطر كشف الحساب ──────────────────────────────────────────────

/// سطر واحد في كشف الحساب مع الرصيد التراكمي
class AccountStatementRow {
  /// بيانات السند الأصلية
  final Voucher voucher;

  /// الرصيد التراكمي حتى هذا السطر (IQD)
  final double runningBalanceIqd;

  /// الرصيد التراكمي حتى هذا السطر (USD)
  final double runningBalanceUsd;

  const AccountStatementRow({
    required this.voucher,
    required this.runningBalanceIqd,
    required this.runningBalanceUsd,
  });
}

/// DAO السندات الموحد
@DriftAccessor(tables: [Vouchers, FiscalPeriods, Treasuries, AdvanceLines])
class VouchersDao extends DatabaseAccessor<AppDatabase>
    with _$VouchersDaoMixin {
  VouchersDao(super.db);

  /// مولّد عشوائي لمعرّفات مجموعات التحويل
  static final _random = Random();

  /// أقصى قيمة آمنة لـ [Random.nextInt] على كل المنصات
  ///
  /// ⚠️ لا تستبدل هذا الثابت بإزاحة بتّية مثل `1 << 32`.
  ///   على الويب تُمثَّل أعداد Dart كأعداد JavaScript، والإزاحة البتّية هناك
  ///   ٣٢-بت، فـ `1 << 32` يساوي **صفراً** لا 4294967296 — فيرمي
  ///   `nextInt(0)` الاستثناء:
  ///     RangeError: max must be in range 0 < max < 2^32, was 0
  ///   وكانت هذه بالضبط علّة تعطُّل التحويل على المتصفح (2026-08-15) بينما
  ///   يعمل سليماً على ويندوز والـ VM. لم تكشفه أيٌّ من 152 اختباراً لأن
  ///   `flutter test` يعمل على الـ VM لا على المتصفح.
  static const int maxRandomBound = 0xFFFFFFFF;

  /// توليد معرّف فريد لمجموعة تحويل (يربط سندَي التحويل)
  ///
  /// مُستخرَج كدالة مستقلة ليُختبَر مباشرة دون الحاجة لقاعدة بيانات.
  static String generateTransferGroupId() =>
      'tg_${DateTime.now().microsecondsSinceEpoch}_'
      '${_random.nextInt(maxRandomBound)}';

  // ── استعلامات القراءة الأساسية ────────────────────────────────────────────

  /// سندات خزينة محددة مرتبة بالتاريخ — Reactive Stream
  ///
  /// يتحدث فور إضافة / تعديل / حذف أي سند في هذه الخزينة
  Stream<List<Voucher>> watchVouchersByTreasury(int treasuryId) {
    return (select(vouchers)
          ..where(
            (v) =>
                v.treasuryId.equals(treasuryId) & v.isDeleted.equals(false),
          )
          ..orderBy([(v) => OrderingTerm.desc(v.voucherDate)]))
        .watch();
  }

  /// سندات حسب نوعها — Reactive Stream
  ///
  /// قواعد التصنيف:
  ///   'sarf'     → الصرف + التحويلات الصادرة (transfer_out)
  ///   'kabd'     → القبض + التحويلات الواردة (transfer_in)
  ///   'transfer' → كل التحويلات (وارد + صادر) — لتبويب التحويلات المخصّص
  ///   غير ذلك    → النوع كما هو
  Stream<List<Voucher>> watchVouchersByType(String voucherType) {
    final List<String> types;
    if (voucherType == 'sarf') {
      types = ['sarf', 'transfer_out'];
    } else if (voucherType == 'kabd') {
      types = ['kabd', 'transfer_in'];
    } else if (voucherType == 'transfer') {
      // التبويب المخصّص للتحويلات — كان يُعيد قائمة فارغة دائماً (تدقيق 2026-08-06)
      types = ['transfer_in', 'transfer_out'];
    } else {
      types = [voucherType];
    }

    return (select(vouchers)
          ..where(
            (v) =>
                v.voucherType.isIn(types) & v.isDeleted.equals(false),
          )
          ..orderBy([(v) => OrderingTerm.desc(v.voucherDate)]))
        .watch();
  }

  /// سند واحد بالمعرّف — Reactive Stream (للشاشة التفصيلية)
  Stream<Voucher?> watchVoucherById(int id) {
    return (select(vouchers)..where((v) => v.id.equals(id)))
        .watchSingleOrNull();
  }

  /// جلب جميع السندات غير المحذوفة (Future)
  Future<List<Voucher>> getAllVouchers() {
    return (select(vouchers)..where((v) => v.isDeleted.equals(false))).get();
  }

  /// جلب سند بالمعرّف (Future)
  Future<Voucher?> getVoucherById(int id) {
    return (select(vouchers)..where((v) => v.id.equals(id)))
        .getSingleOrNull();
  }

  // ── استعلامات مع فلترة متقدمة ─────────────────────────────────────────────

  /// سندات ضمن نطاق تاريخ محدد
  ///
  /// [treasuryId] — null = جميع الخزائن
  /// [voucherType] — null = جميع الأنواع
  Future<List<Voucher>> getVouchersByDateRange({
    required DateTime from,
    required DateTime to,
    int? treasuryId,
    String? voucherType,
    int? fiscalPeriodId,
  }) {
    return (select(vouchers)
          ..where((v) {
            // الشرط الأساسي: نطاق التاريخ وليس محذوفاً
            Expression<bool> condition = v.voucherDate.isBetweenValues(from, to) &
                v.isDeleted.equals(false);

            // فلتر الخزينة (اختياري)
            if (treasuryId != null) {
              condition = condition & v.treasuryId.equals(treasuryId);
            }
            // فلتر نوع السند (اختياري)
            if (voucherType != null) {
              condition = condition & v.voucherType.equals(voucherType);
            }
            // فلتر الفترة المالية (اختياري)
            if (fiscalPeriodId != null) {
              condition =
                  condition & v.fiscalPeriodId.equals(fiscalPeriodId);
            }
            return condition;
          })
          ..orderBy([(v) => OrderingTerm.asc(v.voucherDate)]))
        .get();
  }

  /// بحث نصي في السندات (الاسم، السبب، رقم المرجع)
  Future<List<Voucher>> searchVouchers(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(vouchers)
          ..where(
            (v) =>
                v.isDeleted.equals(false) &
                (v.personName.lower().like(q) |
                    v.reason.lower().like(q) |
                    v.referenceNumber.lower().like(q)),
          )
          ..orderBy([(v) => OrderingTerm.desc(v.voucherDate)])
          ..limit(100))
        .get();
  }

  // ملاحظة (2026-08-07): حُذف `searchAdvanceVouchers` من هنا. كان يبحث عن
  // سندات السلف بمطابقة نصية على `advance_number` ويشترط أن يكون غير فارغ،
  // فيستبعد سندات التحويل ولا يستطيع حساب «المُرسَل». حلّ محلّه استعلامات
  // AdvancesDao التي تعمل على كيان السلفة بمفتاح خارجي.

  // ── قيم الفلترة المستعملة فعلاً ───────────────────────────────────────────

  /// أنواع البنود المستعملة فعلاً في سندات غير محذوفة
  ///
  /// **لماذا «المستعملة فعلاً» لا كل البنود المتاحة؟** (ب-١ — 2026-08-23)
  ///   قائمة `item_types` فيها ٢١ بنداً مبذوراً. عرضها كلها في فلتر يعني أن
  ///   أغلب الخيارات تُعطي نتيجة فارغة — فيظنّ المستخدم أن الفلتر معطوب.
  ///   عرض المستعمَل فقط يجعل كل خيار في القائمة مضموناً أن يُظهر شيئاً.
  ///
  /// تدفّق تفاعلي: يتحدّث فور إضافة سند ببند جديد.
  Stream<List<String>> watchUsedItemTypes() {
    return customSelect(
      "SELECT DISTINCT item_type AS v FROM vouchers "
      "WHERE is_deleted = 0 AND item_type != '' "
      "ORDER BY item_type",
      readsFrom: {vouchers},
    ).watch().map(
          (rows) => rows.map((r) => r.data['v'] as String).toList(),
        );
  }

  /// أسماء المشاريع المستعملة فعلاً في سندات غير محذوفة
  ///
  /// العمود nullable، ونستبعد NULL والنصّ الفارغ معاً: الأول هو التمثيل
  /// الصحيح للغياب، والثاني قد يوجد في صفوف قديمة سبقت قاعدة «الغياب = null».
  Stream<List<String>> watchUsedProjects() {
    return customSelect(
      "SELECT DISTINCT project_name AS v FROM vouchers "
      "WHERE is_deleted = 0 AND project_name IS NOT NULL "
      "AND project_name != '' "
      "ORDER BY project_name",
      readsFrom: {vouchers},
    ).watch().map(
          (rows) => rows.map((r) => r.data['v'] as String).toList(),
        );
  }

  // ── كشف الحساب ────────────────────────────────────────────────────────────

  /// كشف الحساب الكامل لخزينة مع الرصيد التراكمي
  ///
  /// يحسب الرصيد التراكمي سطراً بسطر.
  ///
  /// [openingBalance] — الرصيد الابتدائي (من opening_balance vouchers)
  Future<List<AccountStatementRow>> getAccountStatement({
    required int treasuryId,
    required DateTime from,
    required DateTime to,
    double openingBalanceIqd = 0,
    double openingBalanceUsd = 0,
  }) async {
    // جلب السندات مرتبة بالتاريخ
    final voucherList = await getVouchersByDateRange(
      from: from,
      to: to,
      treasuryId: treasuryId,
    );

    double runningIqd = openingBalanceIqd;
    double runningUsd = openingBalanceUsd;
    final rows = <AccountStatementRow>[];

    for (final v in voucherList) {
      // تحديث الرصيد التراكمي حسب نوع السند والعملة
      if (v.currency == 'IQD') {
        if (['kabd', 'opening_balance', 'transfer_in']
            .contains(v.voucherType)) {
          runningIqd += v.amount;
        } else {
          runningIqd -= v.amount;
        }
      } else if (v.currency == 'USD') {
        if (['kabd', 'opening_balance', 'transfer_in']
            .contains(v.voucherType)) {
          runningUsd += v.amount;
        } else {
          runningUsd -= v.amount;
        }
      }

      rows.add(AccountStatementRow(
        voucher: v,
        runningBalanceIqd: runningIqd,
        runningBalanceUsd: runningUsd,
      ));
    }
    return rows;
  }

  // ── إحصائيات للـ Dashboard ────────────────────────────────────────────────

  /// إجمالي الصرف والقبض ليوم محدد
  Future<({double totalSarf, double totalKabd})> getDailySummary(
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final sarfResult = await customSelect(
      "SELECT COALESCE(SUM(amount), 0) as total FROM vouchers "
      "WHERE voucher_type = 'sarf' AND currency = 'IQD' "
      "AND is_deleted = 0 AND voucher_date BETWEEN ? AND ?",
      variables: [
        Variable.withDateTime(startOfDay),
        Variable.withDateTime(endOfDay),
      ],
      readsFrom: {vouchers},
    ).getSingle();

    final kabdResult = await customSelect(
      "SELECT COALESCE(SUM(amount), 0) as total FROM vouchers "
      "WHERE voucher_type = 'kabd' AND currency = 'IQD' "
      "AND is_deleted = 0 AND voucher_date BETWEEN ? AND ?",
      variables: [
        Variable.withDateTime(startOfDay),
        Variable.withDateTime(endOfDay),
      ],
      readsFrom: {vouchers},
    ).getSingle();

    return (
      totalSarf: (sarfResult.data['total'] as num).toDouble(),
      totalKabd: (kabdResult.data['total'] as num).toDouble(),
    );
  }

  // ── عمليات الكتابة ────────────────────────────────────────────────────────

  /// إدراج سند جديد — يُعيد الـ ID المُولَّد
  Future<int> insertVoucher(VouchersCompanion voucher) {
    return into(vouchers).insert(voucher);
  }

  /// تحديث سند موجود — تحديث جزئي يمسّ الحقول الحاضرة في الـ Companion فقط
  ///
  /// ⚠️ لماذا write وليس replace؟ (إصلاح ثغرة تدقيق 2026-08-06)
  ///   replace يُعيد أي حقل غائب من الـ Companion إلى قيمته الافتراضية.
  ///   فتعديل سند كان يُعيد is_deleted إلى false (يُحيي سنداً محذوفاً فيدخل
  ///   حساب الأرصدة!)، ويمسح notes، ويُعيد created_at إلى الآن — تدمير
  ///   الأثر المحاسبي. write يتجاهل الحقول الغائبة فلا يمسّها إطلاقاً.
  Future<bool> updateVoucher(VouchersCompanion voucher) async {
    final count = await (update(vouchers)
          ..where((v) => v.id.equals(voucher.id.value)))
        .write(voucher);
    return count > 0;
  }

  /// حذف ناعم — السند لا يُحذَف فعلياً لأسباب محاسبية
  ///
  /// [id]           — معرّف السند
  /// [deletedByUser] — معرّف المستخدم الذي حذف السند (للـ Audit)
  Future<void> softDeleteVoucher(int id, {int? deletedByUser}) async {
    // تم إضافة هذه المعاملة (transaction) لمنع تضاعف المبالغ عند حذف سند التحويل
    // بحيث يتم حذف السند التوأم (المستلم/المرسل) مع هذا السند تلقائياً
    await db.transaction(() async {
      // 1. جلب بيانات السند المراد حذفه
      final target = await (select(vouchers)..where((v) => v.id.equals(id))).getSingleOrNull();
      if (target == null) return;

      // 2. تحديث السند الأساسي كـ محذوف
      await (update(vouchers)..where((v) => v.id.equals(id))).write(
        VouchersCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(DateTime.now()),
          updatedByUserId: Value(deletedByUser),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // 2ب. فكّ ربط سطر السلفة بهذا السند (إصلاح ح-٦)
      //
      // «المصروف» في ملخص السلفة يُحسَب من السندات غير المحذوفة، فيُصحّح
      // نفسه تلقائياً. لكن سطر المسودة كان يبقى مؤشراً إلى سند محذوف —
      // فيبدو مُرحَّلاً وهو ليس كذلك، ويضيع أثر أن ترحيله أُلغي.
      if (target.advanceId != null) {
        await (update(db.advanceLines)
              ..where((l) => l.voucherId.equals(id)))
            .write(const AdvanceLinesCompanion(voucherId: Value(null)));
      }

      // 3. إذا كان السند تحويلاً، نحذف الطرف التوأم لضمان توازن الحسابات
      if (target.voucherType == 'transfer_out' ||
          target.voucherType == 'transfer_in') {
        if (target.transferGroupId != null) {
          // ✅ الطريقة الموثوقة: حذف كل سندات نفس المجموعة (عدا هذا السند)
          //    لا مطابقة تخمينية — رباط صريح لا يفشل مع التحويلات المتطابقة.
          await (update(vouchers)
                ..where((v) =>
                    v.transferGroupId.equals(target.transferGroupId!) &
                    v.id.equals(id).not() &
                    v.isDeleted.equals(false)))
              .write(
            VouchersCompanion(
              isDeleted: const Value(true),
              deletedAt: Value(DateTime.now()),
              updatedByUserId: Value(deletedByUser),
              updatedAt: Value(DateTime.now()),
            ),
          );
        } else if (target.linkedTreasuryId != null) {
          // 🕰️ توافق مع التحويلات القديمة (قبل v3) التي لا تملك group id:
          //    مطابقة تخمينية مع مراعاة تعدد التوائم (نحذف الجميع، لا getSingle)
          final oppositeType = target.voucherType == 'transfer_out'
              ? 'transfer_in'
              : 'transfer_out';
          await (update(vouchers)
                ..where((v) =>
                    v.voucherType.equals(oppositeType) &
                    v.amount.equals(target.amount) &
                    v.voucherDate.equals(target.voucherDate) &
                    v.treasuryId.equals(target.linkedTreasuryId!) &
                    v.linkedTreasuryId.equals(target.treasuryId) &
                    v.currency.equals(target.currency) &
                    v.transferGroupId.isNull() &
                    v.isDeleted.equals(false)))
              .write(
            VouchersCompanion(
              isDeleted: const Value(true),
              deletedAt: Value(DateTime.now()),
              updatedByUserId: Value(deletedByUser),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }
    });
  }

  /// إدراج عملية تحويل بين خزينتين في Transaction واحدة
  ///
  /// يُنشئ سندَين في نفس الوقت:
  ///   1. transfer_out من الخزينة المُرسِلة
  ///   2. transfer_in  للخزينة المُستقبِلة
  ///
  /// يُعيد: معرّفا السندين (outId, inId)
  Future<({int outId, int inId})> insertTransfer({
    required VouchersCompanion outVoucher,
    required VouchersCompanion inVoucher,
  }) async {
    return db.transaction(() async {
      // معرّف مجموعة مشترك يربط سندَي التحويل برباط موثوق — يُنشأ هنا
      // لضمان تطابقه على الطرفين مهما كان المستدعي (راجع H8).
      final groupId = generateTransferGroupId();

      final outId = await into(vouchers).insert(
        outVoucher.copyWith(transferGroupId: Value(groupId)),
      );
      final inId = await into(vouchers).insert(
        inVoucher.copyWith(transferGroupId: Value(groupId)),
      );
      return (outId: outId, inId: inId);
    });
  }

  /// إدراج مجموعة سندات دفعة واحدة (استيراد إكسل) داخل عملية ذرية (Batch/Transaction)
  ///
  /// يضمن هذا الإجراء الأداء العالي جداً، وأنه إذا فشل إدخال صف واحد (لأي سبب)، 
  /// سيتراجع النظام عن الملف بأكمله (Rollback) لمنع تلف أرصدة الخزينة.
  Future<void> insertVouchersBatch(List<VouchersCompanion> vouchersBatch) async {
    await batch((batch) {
      batch.insertAll(vouchers, vouchersBatch);
    });
  }

  // ملاحظة (2026-08-07): حُذف `softDeleteAdvance(String advanceNumber)` من
  // هنا. كان يحذف **كل** سند يحمل رقم السلفة نصياً — بما فيها سند التحويل
  // الذي موّل المشروع، فيُبخّر التمويل ويُظهر الخزينة صفراً. حلّ محلّه
  // `AdvancesDao.cancelAdvance` الذي يعكس سندات الصرف وحدها.
}
