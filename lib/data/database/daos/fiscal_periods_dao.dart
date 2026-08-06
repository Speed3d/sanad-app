// ─────────────────────────────────────────────────────────────────────────────
// fiscal_periods_dao.dart — DAO السنوات المالية وأرقام السندات
//
// يُدير هذا الـ DAO السنوات المالية وتسلسل أرقام السندات.
//
// أهم العمليات:
//   1. getOrCreateCurrentPeriod()  — الحصول على الفترة الحالية أو إنشائها
//   2. getFiscalPeriodForDate()    — تحديد الفترة حسب تاريخ السند
//   3. getNextVoucherNumber()      — رقم السند التالي بطريقة آمنة تمامًا
//   4. closeFiscalPeriod()         — إقفال السنة المالية
//
// آلية getNextVoucherNumber (Atomic Increment):
//   تستخدم UPSERT + Transaction لضمان عدم تكرار رقم السند
//   حتى في حالة عدة مستخدمين يعملون في وقت واحد.
//   النهج: INSERT...ON CONFLICT DO UPDATE (ذري بطبيعته في SQLite)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/fiscal_periods_table.dart';

part 'fiscal_periods_dao.g.dart';

/// DAO السنوات المالية وتسلسل أرقام السندات
@DriftAccessor(tables: [FiscalPeriods, VoucherSequences])
class FiscalPeriodsDao extends DatabaseAccessor<AppDatabase>
    with _$FiscalPeriodsDaoMixin {
  FiscalPeriodsDao(super.db);

  // ── استعلامات الفترات المالية ─────────────────────────────────────────────

  /// متابعة جميع الفترات المالية — Reactive Stream مرتب من الأحدث للأقدم
  Stream<List<FiscalPeriod>> watchAllPeriods() {
    return (select(fiscalPeriods)
          ..orderBy([(p) => OrderingTerm.desc(p.startDate)]))
        .watch();
  }

  /// جلب الفترات النشطة فقط (status = 'active')
  ///
  /// عادةً فترة واحدة، لكن خلال فترة الانتقال بين السنوات قد تكون اثنتان
  Future<List<FiscalPeriod>> getActivePeriods() {
    return (select(fiscalPeriods)
          ..where((p) => p.status.equals('active'))
          ..orderBy([(p) => OrderingTerm.desc(p.startDate)]))
        .get();
  }

  /// جلب الفترة المناسبة لتاريخ محدد
  ///
  /// يُستخدَم عند إنشاء سند لتحديد السنة المالية حسب تاريخ السند
  /// وليس حسب وقت الإدخال
  Future<FiscalPeriod?> getFiscalPeriodForDate(DateTime date) async {
    // نبحث عن فترة نشطة يقع التاريخ ضمن نطاقها
    final result = await (select(fiscalPeriods)
          ..where(
            (p) =>
                p.status.equals('active') &
                p.startDate.isSmallerOrEqualValue(date) &
                p.endDate.isBiggerOrEqualValue(date),
          )
          ..limit(1))
        .getSingleOrNull();
    return result;
  }

  /// جلب فترة مالية بالمعرّف
  Future<FiscalPeriod?> getPeriodById(int id) {
    return (select(fiscalPeriods)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// إنشاء فترة مالية جديدة — يُعيد الـ ID المُولَّد
  Future<int> insertPeriod(FiscalPeriodsCompanion period) {
    return into(fiscalPeriods).insert(period);
  }

  /// الحصول على السنة المالية الحالية أو إنشائها إذا لم تكن موجودة
  ///
  /// يُستخدَم عند بدء التطبيق لضمان وجود فترة نشطة
  Future<FiscalPeriod> getOrCreateCurrentPeriod() async {
    final now = DateTime.now();
    final existing = await getFiscalPeriodForDate(now);
    if (existing != null) return existing;

    // إنشاء فترة للسنة الحالية
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    final id = await insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: now.year.toString(),
        startDate: startOfYear,
        endDate: endOfYear,
        status: const Value('active'),
      ),
    );

    return (select(fiscalPeriods)..where((p) => p.id.equals(id))).getSingle();
  }

  /// إقفال فترة مالية
  ///
  /// [id]         — معرّف الفترة
  /// [closedBy]   — معرّف المستخدم الذي أقفل الفترة
  /// [notes]      — ملاحظات الإقفال (اختياري)
  Future<void> closePeriod(int id, int closedBy, {String notes = ''}) async {
    await (update(fiscalPeriods)..where((p) => p.id.equals(id))).write(
      FiscalPeriodsCompanion(
        status: const Value('frozen'),
        closedAt: Value(DateTime.now()),
        closedByUserId: Value(closedBy),
        notes: Value(notes),
      ),
    );
  }

  /// وضع فترة في حالة "مقفلة تحتاج إعادة احتساب"
  ///
  /// يُستخدَم عند إعادة فتح فترة سابقة تؤثر على الفترات اللاحقة
  Future<void> markPeriodPendingRecompute(int id) async {
    await (update(fiscalPeriods)..where((p) => p.id.equals(id))).write(
      const FiscalPeriodsCompanion(
        status: Value('frozen_pending_recompute'),
      ),
    );
  }

  /// إعادة تفعيل فترة مقفلة (إعادة الفتح — Super Admin فقط)
  Future<void> reopenPeriod(int id) async {
    await (update(fiscalPeriods)..where((p) => p.id.equals(id))).write(
      const FiscalPeriodsCompanion(
        status: Value('active'),
        closedAt: Value(null),
        closedByUserId: Value(null),
      ),
    );
  }

  // ── تسلسل أرقام السندات (Atomic) ─────────────────────────────────────────

  /// الحصول على رقم السند التالي بطريقة آمنة تمامًا
  ///
  /// يستخدم UPSERT ذري في SQLite لضمان عدم التكرار حتى مع مستخدمين متعددين.
  ///
  /// [fiscalPeriodId] — معرّف الفترة المالية
  /// [voucherType]    — 'sarf' أو 'kabd'
  ///
  /// يُعيد: رقم السند التالي (1، 2، 3، ...)
  Future<int> getNextVoucherNumber({
    required int fiscalPeriodId,
    required String voucherType,
  }) async {
    return db.transaction(() async {
      // UPSERT ذري:
      //   إذا لم يوجد السجل → ينشئه بـ last_number = 1
      //   إذا وجد → يزيد last_number بمقدار 1
      // هذا العملية ذرية (Atomic) في SQLite لأن SQLite يسمح بكاتب واحد فقط
      await db.customStatement(
        '''
        INSERT INTO voucher_sequences (fiscal_period_id, voucher_type, last_number)
        VALUES (?, ?, 1)
        ON CONFLICT(fiscal_period_id, voucher_type)
        DO UPDATE SET last_number = last_number + 1
        ''',
        [fiscalPeriodId, voucherType],
      );

      // قراءة القيمة المُحدَّثة
      final result = await db
          .customSelect(
            'SELECT last_number FROM voucher_sequences '
            'WHERE fiscal_period_id = ? AND voucher_type = ?',
            variables: [
              Variable.withInt(fiscalPeriodId),
              Variable.withString(voucherType),
            ],
            readsFrom: {db.voucherSequences},
          )
          .getSingle();

      return result.data['last_number'] as int;
    });
  }

  /// إعادة تعيين تسلسل السند (يُستخدَم فقط عند اختبار قاعدة بيانات جديدة)
  Future<void> resetSequence(int fiscalPeriodId, String voucherType) async {
    await (delete(voucherSequences)
          ..where(
            (s) =>
                s.fiscalPeriodId.equals(fiscalPeriodId) &
                s.voucherType.equals(voucherType),
          ))
        .go();
  }
}
