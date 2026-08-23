// ─────────────────────────────────────────────────────────────────────────────
// voucher_period_guard_test.dart — منع نقل السند بين السنوات المالية (ح-٥)
//
// الثغرة التي يغلقها:
//   updateVoucher كان يكتب fiscalPeriodId الأصلية دائماً. فنقل تاريخ سند من
//   ديسمبر 2025 إلى يناير 2026 يُبقيه محسوباً في 2025 ← تقارير السنتين
//   خاطئة، والمستخدم لا يرى أي مؤشر على الخلل.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/voucher_repository.dart';
import 'package:sales_management/domain/models/voucher_model.dart';

void main() {
  late AppDatabase db;
  late VoucherRepository repo;
  late int period2025;
  late int period2026;
  late int treasuryId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = VoucherRepository(db);

    period2025 = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2025',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31, 23, 59, 59),
      ),
    );
    period2026 = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31, 23, 59, 59),
      ),
    );
    treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الخزينة', kind: const Value('main')),
    );
    await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: 1,
        voucherType: 'kabd',
        treasuryId: treasuryId,
        fiscalPeriodId: period2025,
        amount: 10000000.0,
        currency: const Value('IQD'),
        voucherDate: DateTime(2025, 6, 1),
      ),
    );
  });

  tearDown(() async => db.close());

  /// سند صرف في ديسمبر 2025
  Future<VoucherModel> makeDecember2025Voucher() async {
    final id = await repo.createVoucher(
      fiscalPeriodId: period2025,
      voucherType: 'sarf',
      treasuryId: treasuryId,
      amount: 500000.0,
      currency: 'IQD',
      voucherDate: DateTime(2025, 12, 20),
    );
    final v = (await db.vouchersDao.getVoucherById(id))!;
    return VoucherModel(
      id: v.id,
      voucherNumber: v.voucherNumber,
      voucherType: v.voucherType,
      treasuryId: v.treasuryId,
      fiscalPeriodId: v.fiscalPeriodId,
      amount: v.amount,
      currency: v.currency,
      voucherDate: v.voucherDate,
    );
  }

  test('⭐ نقل تاريخ السند إلى سنة مالية أخرى مرفوض', () async {
    final v = await makeDecember2025Voucher();
    expect(v.fiscalPeriodId, equals(period2025));

    await expectLater(
      repo.updateVoucher(v.copyWith(voucherDate: DateTime(2026, 1, 15))),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        contains('سنة مالية أخرى'),
      )),
    );

    // السند لم يتحرّك
    final after = await db.vouchersDao.getVoucherById(v.id);
    expect(after!.fiscalPeriodId, equals(period2025));
    expect(after.voucherDate, equals(DateTime(2025, 12, 20)));
  });

  test('تعديل التاريخ داخل نفس السنة مسموح', () async {
    final v = await makeDecember2025Voucher();

    await repo.updateVoucher(v.copyWith(voucherDate: DateTime(2025, 11, 5)));

    final after = await db.vouchersDao.getVoucherById(v.id);
    expect(after!.voucherDate, equals(DateTime(2025, 11, 5)));
    expect(after.fiscalPeriodId, equals(period2025));
  });

  test('تاريخ بلا فترة مالية نشطة مرفوض برسالة واضحة', () async {
    final v = await makeDecember2025Voucher();

    await expectLater(
      repo.updateVoucher(v.copyWith(voucherDate: DateTime(2019, 5, 1))),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        contains('لا توجد فترة مالية نشطة'),
      )),
    );
  });

  test('السنة الأخرى موجودة فعلاً — الرفض ليس بسبب غيابها', () async {
    // يثبت أن الرفض قرار مقصود لا أثر جانبي لغياب الفترة
    final p = await db.fiscalPeriodsDao.getFiscalPeriodForDate(
      DateTime(2026, 1, 15),
    );
    expect(p, isNotNull);
    expect(p!.id, equals(period2026));
  });
}
