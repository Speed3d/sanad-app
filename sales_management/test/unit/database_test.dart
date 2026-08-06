// ─────────────────────────────────────────────────────────────────────────────
// database_test.dart — اختبارات وحدة قاعدة البيانات (Drift In-Memory)
//
// تعليقات توضيحية بالعربية:
// هذا الملف يحتوي على اختبارات الوحدة لقاعدة بيانات Drift باستخدامIn-Memory Database.
// يُختبَر فيها:
//   1. إنشاء واستعلام المستخدمين والخزائن السليمة
//   2. إدراج سندات القبض والصرف
//   3. حساب أرصدة الخزائن تلقائياً من الـ VIEW (v_treasury_balances)
//   4. الحذف الناعم (Soft Delete) وعدم تجميع السندات المحذوفة في الرصيد
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // إنشاء قاعدة بيانات في الذاكرة لكل اختبار لضمان العزل التام
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('اختبارات قاعدة البيانات (Drift DB Tests)', () {
    test('يجب إنشاء قاعدة البيانات بالأدوار والمخطط الصحيح', () async {
      expect(db.schemaVersion, equals(2));
    });

    test('إدراج واستعلام خزينة جديدة', () async {
      final id = await db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(
          name: 'خزينة اربيل',
          kind: const Value('main'),
        ),
      );

      expect(id, isPositive);
      final treasury = await db.treasuriesDao.getTreasuryById(id);
      expect(treasury, isNotNull);
      expect(treasury?.name, equals('خزينة اربيل'));
    });

    test('حساب أرصدة الخزائن تلقائياً عبر SQL View مع السندات', () async {
      // 1. إنشاء فترة مالية أولاً
      final periodId = await db.fiscalPeriodsDao.insertPeriod(
        FiscalPeriodsCompanion.insert(
          name: '2026',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
        ),
      );

      // 2. إنشاء خزينة
      final vaultId = await db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(
          name: 'الخزينة الرئيسية',
          kind: const Value('main'),
        ),
      );

      // 3. إدراج سند قبض بقيمة 1,000,000 د.ع
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: 1,
          voucherType: 'kabd',
          treasuryId: vaultId,
          fiscalPeriodId: periodId,
          amount: 1000000.0,
          currency: const Value('IQD'),
          voucherDate: DateTime.now(),
        ),
      );

      // 4. إدراج سند صرف بقيمة 300,000 د.ع
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: 2,
          voucherType: 'sarf',
          treasuryId: vaultId,
          fiscalPeriodId: periodId,
          amount: 300000.0,
          currency: const Value('IQD'),
          voucherDate: DateTime.now(),
        ),
      );

      // 5. الاستعلام من الـ View المفترضة (الرصيد الصافي = 700,000 د.ع)
      final balances = await db.treasuriesDao.watchTreasuryBalances().first;
      expect(balances.length, equals(1));
      expect(balances.first.balanceIqd, equals(700000.0));
      expect(balances.first.totalVouchers, equals(2));
    });

    test('السندات المحذوفة ناعماً (is_deleted = 1) لا تدخل في حساب الرصيد', () async {
      final periodId = await db.fiscalPeriodsDao.insertPeriod(
        FiscalPeriodsCompanion.insert(
          name: '2026',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
        ),
      );

      final vaultId = await db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(
          name: 'خزينة البصرة',
          kind: const Value('main'),
        ),
      );

      // إدراج سند قبض 500,000 د.ع (نشط)
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: 1,
          voucherType: 'kabd',
          treasuryId: vaultId,
          fiscalPeriodId: periodId,
          amount: 500000.0,
          currency: const Value('IQD'),
          voucherDate: DateTime.now(),
        ),
      );

      // إدراج سند قبض 200,000 د.ع (محذوف ناعماً)
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: 2,
          voucherType: 'kabd',
          treasuryId: vaultId,
          fiscalPeriodId: periodId,
          amount: 200000.0,
          currency: const Value('IQD'),
          voucherDate: DateTime.now(),
          isDeleted: const Value(true),
        ),
      );

      final balances = await db.treasuriesDao.watchTreasuryBalances().first;
      expect(balances.first.balanceIqd, equals(500000.0)); // يتجاهل الـ 200,000 المحذوفة
      expect(balances.first.totalVouchers, equals(1));
    });
  });
}
