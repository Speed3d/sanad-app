// ─────────────────────────────────────────────────────────────────────────────
// fiscal_period_guard_test.dart — اختبارات حماية الفترات المالية المُقفَلة
//
// لماذا هذا الملف؟
//   كشف تدقيق 2026-08-06 أن سندات الفترة المُقفَلة (frozen) تبقى قابلة
//   للتعديل والحذف، فتتغيّر أرصدة تاريخية بعد إغلاق السنة. أُضيف حارس في
//   VoucherRepository يمنع الإنشاء/التعديل/الحذف في فترة غير نشطة.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/voucher_repository.dart';

void main() {
  late AppDatabase db;
  late VoucherRepository repo;
  late int treasuryId;
  late int frozenPeriodId;
  late int voucherId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = VoucherRepository(db);

    treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'خزينة', kind: const Value('main')),
    );

    // فترة نشطة نُنشئ فيها السند أولاً
    frozenPeriodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2025',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31),
        status: const Value('active'),
      ),
    );
    voucherId = await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: 1,
        voucherType: 'kabd',
        treasuryId: treasuryId,
        fiscalPeriodId: frozenPeriodId,
        amount: 100000.0,
        currency: const Value('IQD'),
        voucherDate: DateTime(2025, 6, 1),
      ),
    );

    // ثم نُقفل الفترة
    await db.fiscalPeriodsDao.closePeriod(frozenPeriodId, 1);
  });

  tearDown(() async {
    await db.close();
  });

  test('لا يمكن إنشاء سند في فترة مُقفَلة', () async {
    expect(
      () => repo.createVoucher(
        fiscalPeriodId: frozenPeriodId,
        voucherType: 'sarf',
        treasuryId: treasuryId,
        amount: 5000.0,
        currency: 'IQD',
        voucherDate: DateTime(2025, 7, 1),
      ),
      throwsStateError,
    );
  });

  test('لا يمكن حذف سند في فترة مُقفَلة', () async {
    expect(
      () => repo.deleteVoucher(voucherId),
      throwsStateError,
    );

    // والسند يبقى غير محذوف
    final voucher = await db.vouchersDao.getVoucherById(voucherId);
    expect(voucher!.isDeleted, isFalse);
  });

  test('الفترة النشطة تسمح بالإنشاء والحذف', () async {
    final activePeriodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        status: const Value('active'),
      ),
    );

    // الإنشاء ينجح
    final newId = await repo.createVoucher(
      fiscalPeriodId: activePeriodId,
      voucherType: 'kabd',
      treasuryId: treasuryId,
      amount: 20000.0,
      currency: 'IQD',
      voucherDate: DateTime(2026, 6, 1),
    );
    expect(newId, isPositive);

    // والحذف ينجح
    await repo.deleteVoucher(newId);
    final voucher = await db.vouchersDao.getVoucherById(newId);
    expect(voucher!.isDeleted, isTrue);
  });
}
