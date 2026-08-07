// ─────────────────────────────────────────────────────────────────────────────
// balance_guard_test.dart — اختبارات حارس رصيد الخزينة
//
// لماذا هذا الملف؟
//   كشف تدقيق 2026-08-06 غياب أي فحص للرصيد عند الصرف — يمكن صرف 10 مليون
//   من خزينة فيها 500. أُضيف حارس موحّد بسياسة قابلة للتغيير (منع/سماح).
//   هذه الاختبارات تتحقق من الحارس في الحالتين.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/constants/app_settings_keys.dart';
import 'package:sales_management/core/services/balance_guard.dart';
import 'package:sales_management/data/database/app_database.dart';

void main() {
  late AppDatabase db;
  late int treasuryId;
  late int periodId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
      ),
    );
    treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'خزينة', kind: const Value('main')),
    );
    // إيداع 500,000 د.ع فقط
    await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: 1,
        voucherType: 'kabd',
        treasuryId: treasuryId,
        fiscalPeriodId: periodId,
        amount: 500000.0,
        currency: const Value('IQD'),
        voucherDate: DateTime(2026, 3, 1),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('المنع مفعّل افتراضياً: يرفض الصرف فوق الرصيد', () async {
    final error = await BalanceGuard.checkSufficientBalance(
      db,
      treasuryId: treasuryId,
      currency: 'IQD',
      amount: 700000.0, // أكبر من 500,000 المتاحة
    );
    expect(error, isNotNull, reason: 'يجب رفض الصرف فوق الرصيد افتراضياً');
  });

  test('المنع مفعّل: يسمح بالصرف ضمن الرصيد', () async {
    final error = await BalanceGuard.checkSufficientBalance(
      db,
      treasuryId: treasuryId,
      currency: 'IQD',
      amount: 300000.0,
    );
    expect(error, isNull, reason: 'يجب السماح بالصرف ضمن الرصيد');
  });

  test('عند تعطيل المنع: يسمح بالرصيد المدين', () async {
    await db.appSettingsDao.setString(
      AppSettingsKeys.enforceBalanceCheck,
      'false',
    );
    final error = await BalanceGuard.checkSufficientBalance(
      db,
      treasuryId: treasuryId,
      currency: 'IQD',
      amount: 900000.0, // يتجاوز الرصيد لكن المنع معطّل
    );
    expect(error, isNull, reason: 'مع تعطيل المنع يُسمح بالرصيد المدين');
  });

  test('عملة مختلفة (USD) لها رصيدها المنفصل', () async {
    // لا يوجد رصيد USD → أي صرف بالدولار يُرفض تحت سياسة المنع
    final error = await BalanceGuard.checkSufficientBalance(
      db,
      treasuryId: treasuryId,
      currency: 'USD',
      amount: 100.0,
    );
    expect(error, isNotNull);
  });
}
