// ─────────────────────────────────────────────────────────────────────────────
// schema_v4_test.dart — اختبارات تغييرات الإصدار 4
//
// يغطي القرارات المحسومة من المالك (2026-08-07):
//   1. نوع سند 'opening_balance_debit' يُطرَح من الرصيد (خزينة مدينة)
//   2. قيد CHECK(total_repaid <= amount) على السلف (دفاع في العمق)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('الإصدار الحالي هو 4', () {
    expect(db.schemaVersion, equals(4));
  });

  group('الرصيد الافتتاحي المدين (opening_balance_debit)', () {
    test('يُطرَح من رصيد الخزينة في الـ VIEW', () async {
      final periodId = await db.fiscalPeriodsDao.insertPeriod(
        FiscalPeriodsCompanion.insert(
          name: '2026',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
        ),
      );
      final vaultId = await db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(name: 'خزينة', kind: const Value('main')),
      );

      // رصيد افتتاحي دائن 1,000,000
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: 1,
          voucherType: 'opening_balance',
          treasuryId: vaultId,
          fiscalPeriodId: periodId,
          amount: 1000000.0,
          currency: const Value('IQD'),
          voucherDate: DateTime(2026, 1, 1),
        ),
      );
      // رصيد افتتاحي مدين 300,000 (مبلغ موجب، يُطرَح)
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: 2,
          voucherType: 'opening_balance_debit',
          treasuryId: vaultId,
          fiscalPeriodId: periodId,
          amount: 300000.0,
          currency: const Value('IQD'),
          voucherDate: DateTime(2026, 1, 1),
        ),
      );

      final balances = await db.treasuriesDao.watchTreasuryBalances().first;
      // 1,000,000 − 300,000 = 700,000
      expect(balances.first.balanceIqd, equals(700000.0));
    });

    test('خزينة مدينة صافية تظهر برصيد سالب', () async {
      final periodId = await db.fiscalPeriodsDao.insertPeriod(
        FiscalPeriodsCompanion.insert(
          name: '2026',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
        ),
      );
      final vaultId = await db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(name: 'مدينة', kind: const Value('main')),
      );
      // رصيد افتتاحي مدين فقط → الخزينة مدينة
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: 1,
          voucherType: 'opening_balance_debit',
          treasuryId: vaultId,
          fiscalPeriodId: periodId,
          amount: 250000.0,
          currency: const Value('IQD'),
          voucherDate: DateTime(2026, 1, 1),
        ),
      );

      final balances = await db.treasuriesDao.watchTreasuryBalances().first;
      expect(balances.first.balanceIqd, equals(-250000.0));
    });
  });

  group('قيد CHECK(total_repaid <= amount)', () {
    test('يرفض total_repaid أكبر من amount', () async {
      expect(
        () => db.employeesDao.insertAdvance(
          CashAdvancesCompanion.insert(
            amount: 100000.0,
            advanceDate: DateTime(2026, 1, 1),
            totalRepaid: const Value(150000.0), // يتجاوز المبلغ
            externalPersonName: const Value('دائن'),
          ),
        ),
        throwsA(anything),
        reason: 'قاعدة البيانات يجب أن ترفض المسدَّد الأكبر من المبلغ',
      );
    });

    test('يسمح بـ total_repaid يساوي amount (مسدَّد بالكامل)', () async {
      final id = await db.employeesDao.insertAdvance(
        CashAdvancesCompanion.insert(
          amount: 100000.0,
          advanceDate: DateTime(2026, 1, 1),
          totalRepaid: const Value(100000.0),
          externalPersonName: const Value('دائن'),
        ),
      );
      expect(id, isPositive);
    });
  });
}
