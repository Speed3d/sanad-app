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
      expect(db.schemaVersion, equals(4));
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

    // ── اختبارات تحديث السجلات الجزئي (إصلاح CRIT-6) ─────────────────────
    group('التحديث الجزئي لا يمسّ الحقول الغائبة (CRIT-6)', () {
      test('تعديل سند محذوف ناعماً لا يُحييه', () async {
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

        // إدراج سند ثم حذفه ناعماً
        final voucherId = await db.vouchersDao.insertVoucher(
          VouchersCompanion.insert(
            voucherNumber: 1,
            voucherType: 'sarf',
            treasuryId: vaultId,
            fiscalPeriodId: periodId,
            amount: 100000.0,
            currency: const Value('IQD'),
            voucherDate: DateTime.now(),
            notes: const Value('ملاحظة مهمة'),
            isDeleted: const Value(true),
          ),
        );

        // تعديل جزئي — Companion يحمل المبلغ فقط (وid)، بلا isDeleted/notes
        await db.vouchersDao.updateVoucher(
          VouchersCompanion(
            id: Value(voucherId),
            amount: const Value(150000.0),
          ),
        );

        final after = await db.vouchersDao.getVoucherById(voucherId);
        expect(after!.amount, equals(150000.0), reason: 'المبلغ يجب أن يتحدث');
        expect(after.isDeleted, isTrue, reason: 'يجب ألا يُحيا السند المحذوف');
        expect(after.notes, equals('ملاحظة مهمة'), reason: 'يجب ألا تُمسح الملاحظة');
      });

      test('تغيير دور مستخدم ينجح ولا يمسّ كلمة المرور أو created_at', () async {
        final userId = await db.usersDao.insertUser(
          UsersCompanion.insert(
            username: 'ahmed',
            passwordHash: r'$2a$12$originalhashvalue',
            fullName: 'أحمد',
            role: const Value('user'),
          ),
        );
        final before = await db.usersDao.getUserById(userId);

        // تغيير الدور فقط — Companion بلا passwordHash (كان يرمي استثناءً)
        final ok = await db.usersDao.updateUser(
          UsersCompanion(
            id: Value(userId),
            role: const Value('admin'),
          ),
        );

        expect(ok, isTrue, reason: 'التحديث يجب أن ينجح لا أن يرمي استثناءً');
        final after = await db.usersDao.getUserById(userId);
        expect(after!.role, equals('admin'), reason: 'الدور يجب أن يتغيّر');
        expect(after.passwordHash, equals(before!.passwordHash),
            reason: 'كلمة المرور يجب ألا تتأثر');
        expect(after.createdAt, equals(before.createdAt),
            reason: 'تاريخ الإنشاء يجب ألا يُعاد');
      });
    });
  });
}
