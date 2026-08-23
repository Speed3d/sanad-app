// ─────────────────────────────────────────────────────────────────────────────
// fiscal_period_purge_test.dart — المحو القسري لفترة مالية
//
// الميزة التي يحرسها (طلب المالك 2026-08-23):
//   `deleteEmptyPeriod` ترفض — بحقّ — أي فترة فيها أثر مالي، **حتى لو كانت
//   كل سنداتها محذوفة ناعماً**. في مرحلة الاختبار هذا يعني أن كل سنة جُرّبت
//   تبقى حاجزاً دائماً على نطاق تواريخها، فلا يمكن إعادة بنائها من الصفر.
//
//   الحلّ: `purgeFiscalPeriodCompletely` تمحو الفترة بكل سنداتها محواً
//   نهائياً — محروسةً بثلاث طبقات في FiscalNotifier.purgePeriod:
//     صلاحية super_admin · كلمة مرور المستخدم (bcrypt) · رمز محو منفصل
//     + كتابة اسم الفترة حرفياً.
//
// ما يجب أن يبقى بعد المحو — وهو ما تحرسه الاختبارات هنا:
//   • سجل التدقيق (فيه سطر يوثّق أن المحو حدث ومن نفّذه)
//   • الخزائن والموظفون والمستخدمون والإعدادات
//   لولا ذلك لصار في البرنامج زرٌّ يمحو الدفاتر بلا شاهد.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/auth/permissions.dart';
import 'package:sales_management/core/utils/audit_logger.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/voucher_repository.dart';
import 'package:sales_management/domain/models/user_model.dart';

void main() {
  late AppDatabase db;
  late VoucherRepository repo;
  late int periodId;
  late int treasuryId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = VoucherRepository(db);
    periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2025',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31, 23, 59, 59),
      ),
    );
    treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );
  });

  tearDown(() async => db.close());

  /// سيناريو المالك: سندات أُنشئت ثم حُذفت كلها حذفاً ناعماً
  Future<void> seedSoftDeletedVouchers() async {
    for (final amount in [5000000.0, 2000000.0]) {
      final id = await repo.createVoucher(
        fiscalPeriodId: periodId,
        voucherType: 'kabd',
        treasuryId: treasuryId,
        amount: amount,
        currency: 'IQD',
        voucherDate: DateTime(2025, 3, 1),
      );
      await repo.deleteVoucher(id);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // السيناريو الذي دفع المالك لطلب الميزة
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ الحذف العادي يرفض فترة كل سنداتها محذوفة ناعماً', () async {
    await seedSoftDeletedVouchers();
    // هذا بالضبط ما رآه المالك — والسلوك صحيح لا خطأ
    expect(
      () => db.fiscalPeriodsDao.deleteEmptyPeriod(periodId),
      throwsA(isA<StateError>()),
    );
  });

  test('⭐ المحو القسري ينجح حيث يرفض الحذف العادي', () async {
    await seedSoftDeletedVouchers();

    final purged =
        await db.fiscalPeriodsDao.purgeFiscalPeriodCompletely(periodId);
    expect(purged.vouchers, 2);

    final periods = await db.fiscalPeriodsDao.watchAllPeriods().first;
    expect(periods, isEmpty);

    final rows = await db
        .customSelect('SELECT COUNT(*) AS c FROM vouchers')
        .getSingle();
    expect(rows.data['c'], 0, reason: 'لا يبقى سند واحد — ولا محذوفاً ناعماً');
  });

  test('⭐ بعد المحو يتحرّر النطاق فتُنشأ السنة نفسها من جديد', () async {
    await seedSoftDeletedVouchers();
    await db.fiscalPeriodsDao.purgeFiscalPeriodCompletely(periodId);

    // كان هذا مستحيلاً: الفترة القديمة تحجب نطاقها بقاعدة عدم التقاطع
    final newId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2025',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31, 23, 59, 59),
      ),
    );
    expect(newId, greaterThan(0));
  });

  // ═══════════════════════════════════════════════════════════════════════
  // نطاق المحو — ما يُمحى وما لا يُمسّ
  // ═══════════════════════════════════════════════════════════════════════

  test('المحو يشمل السندات الحيّة والمحذوفة وتسلسل الترقيم', () async {
    await repo.createVoucher(
      fiscalPeriodId: periodId,
      voucherType: 'kabd',
      treasuryId: treasuryId,
      amount: 1000000,
      currency: 'IQD',
      voucherDate: DateTime(2025, 3, 1),
    );
    await seedSoftDeletedVouchers();

    final purged =
        await db.fiscalPeriodsDao.purgeFiscalPeriodCompletely(periodId);
    expect(purged.vouchers, 3, reason: 'واحد حيّ واثنان محذوفان');

    final seq = await db
        .customSelect('SELECT COUNT(*) AS c FROM voucher_sequences')
        .getSingle();
    expect(seq.data['c'], 0, reason: 'الترقيم يبدأ من ١ في السنة الجديدة');
  });

  test('المحو يشمل سلف المشاريع وأسطرها', () async {
    final advanceId = await db.advancesDao.insertAdvance(
      AdvancesCompanion.insert(
        advanceNumber: '23',
        projectTreasuryId: treasuryId,
        fiscalPeriodId: periodId,
        advanceDate: DateTime(2025, 3, 1),
      ),
    );
    await db.advancesDao.insertLines([
      AdvanceLinesCompanion.insert(
        advanceId: advanceId,
        voucherDate: DateTime(2025, 3, 2),
        amount: 250000,
        originalAmount: 250000,
        originalDate: DateTime(2025, 3, 2),
      ),
    ]);

    final purged =
        await db.fiscalPeriodsDao.purgeFiscalPeriodCompletely(periodId);
    expect(purged.advances, 1);

    final lines = await db
        .customSelect('SELECT COUNT(*) AS c FROM advance_lines')
        .getSingle();
    expect(lines.data['c'], 0);
  });

  test('⭐ المحو لا يمسّ سجل التدقيق ولا الخزائن', () async {
    await db.auditLogDao.logSimpleAction(
      username: 'admin',
      table: AuditTables.system,
      action: AuditActions.login,
    );
    await seedSoftDeletedVouchers();

    await db.fiscalPeriodsDao.purgeFiscalPeriodCompletely(periodId);

    final logs = await db.auditLogDao.getRecentLogs();
    expect(logs, isNotEmpty,
        reason: 'لولا هذا لصار المحو صامتاً بلا شاهد');

    final treasuries = await db.treasuriesDao.watchAllTreasuries().first;
    expect(treasuries, isNotEmpty, reason: 'المحو يخصّ الفترة لا الهيكل');
  });

  test('فترة غير موجودة تُرفض', () async {
    expect(
      () => db.fiscalPeriodsDao.purgeFiscalPeriodCompletely(9999),
      throwsA(isA<StateError>()),
    );
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الأثر الباقي
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ سجل المحو يحمل اسم الفترة وعدد ما مُحي ومن نفّذه', () async {
    await AuditLogger(db.auditLogDao).logFiscalPurged(
      userId: 1,
      username: 'المالك',
      periodName: '2025',
      vouchersPurged: 4,
      advancesPurged: 1,
    );

    final logs = await db.auditLogDao.getLogsByTable(AuditTables.fiscalPeriods);
    expect(logs, hasLength(1));
    expect(logs.first.username, 'المالك');

    final meta = jsonDecode(logs.first.metaJson) as Map<String, dynamic>;
    expect(meta['event'], 'fiscal_period_purged');
    expect(meta['period_name'], '2025');
    expect(meta['vouchers_purged'], 4);
    expect(meta['note'], 'hard_delete_irreversible');
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الطبقة الأولى: الصلاحية
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ المحو القسري صلاحية super_admin وحده', () {
    UserModel u(String role) => UserModel(
          id: 1,
          username: 'u',
          fullName: 'u',
          role: role,
          createdAt: DateTime(2025, 1, 1),
        );

    expect(u('user').can(AppPermission.purgeFiscalPeriod), isFalse);
    expect(u('admin').can(AppPermission.purgeFiscalPeriod), isFalse,
        reason: 'حتى المدير العادي لا يملك محو الدفاتر');
    expect(u('super_admin').can(AppPermission.purgeFiscalPeriod), isTrue);
  });
}
