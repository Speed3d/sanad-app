// ─────────────────────────────────────────────────────────────────────────────
// voucher_edit_balance_test.dart — حارس الرصيد عند تعديل السندات (ح-٢)
//
// الثغرة التي يغلقها:
//   createSarf كان يستدعي BalanceGuard، أما updateSarf/updateKabd فلا.
//   فسند صرف بـ 100 ألف يُعدَّل إلى 100 مليون كان يمرّ بلا اعتراض وتصبح
//   الخزينة سالبة رغم تفعيل «منع الصرف فوق الرصيد» — أي أن الحماية كانت
//   مُلتَفّاً عليها من باب التعديل بالكامل.
//
// يغطي الحالات الأربع: زيادة صرف · خفض قبض · نقل خزينة · تغيير عملة
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/constants/app_settings_keys.dart';
import 'package:sales_management/core/services/balance_guard.dart';
import 'package:sales_management/data/database/app_database.dart';

void main() {
  late AppDatabase db;
  late int periodId;
  late int treasuryA;
  late int treasuryB;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31, 23, 59, 59),
      ),
    );
    treasuryA = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );
    treasuryB = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الفرعية', kind: const Value('main')),
    );
  });

  tearDown(() async => db.close());

  /// إدراج سند وإرجاع صفّه المخزَّن
  Future<Voucher> insert({
    required String type,
    required double amount,
    int? treasury,
    String currency = 'IQD',
    int number = 1,
  }) async {
    final id = await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: number,
        voucherType: type,
        treasuryId: treasury ?? treasuryA,
        fiscalPeriodId: periodId,
        amount: amount,
        currency: Value(currency),
        voucherDate: DateTime(2026, 3, 1),
      ),
    );
    return (await db.vouchersDao.getVoucherById(id))!;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // الحالات الأربع
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ زيادة مبلغ سند صرف فوق الرصيد مرفوضة', () async {
    await insert(type: 'kabd', amount: 1000000, number: 1);
    final sarf = await insert(type: 'sarf', amount: 100000, number: 2);
    // الرصيد الآن 900,000

    final error = await BalanceGuard.checkEditImpact(
      db,
      original: sarf,
      newTreasuryId: treasuryA,
      newCurrency: 'IQD',
      newAmount: 100000000, // 100 مليون
    );

    expect(error, isNotNull,
        reason: 'الالتفاف على المنع من باب التعديل يجب أن يُسدّ');
    expect(error, contains('سالباً'));
  });

  test('زيادة سند صرف ضمن الرصيد مسموحة', () async {
    await insert(type: 'kabd', amount: 1000000, number: 1);
    final sarf = await insert(type: 'sarf', amount: 100000, number: 2);

    // الرصيد 900,000 والسند القديم 100,000 → المتاح للتعديل حتى 1,000,000
    final error = await BalanceGuard.checkEditImpact(
      db,
      original: sarf,
      newTreasuryId: treasuryA,
      newCurrency: 'IQD',
      newAmount: 900000,
    );
    expect(error, isNull, reason: 'التعديل ضمن الرصيد لا يجوز رفضه');
  });

  test('⭐ خفض مبلغ سند قبض بعد الصرف منه مرفوض', () async {
    final kabd = await insert(type: 'kabd', amount: 5000000, number: 1);
    await insert(type: 'sarf', amount: 4000000, number: 2);
    // الرصيد 1,000,000

    final error = await BalanceGuard.checkEditImpact(
      db,
      original: kabd,
      newTreasuryId: treasuryA,
      newCurrency: 'IQD',
      newAmount: 1000000, // خفض القبض من 5 مليون إلى 1
    );

    expect(error, isNotNull,
        reason: 'خفض القبض بعد الصرف منه يُنتج رصيداً سالباً');
  });

  test('⭐ نقل سند صرف إلى خزينة لا تحتمله مرفوض', () async {
    await insert(type: 'kabd', amount: 5000000, number: 1);
    final sarf = await insert(type: 'sarf', amount: 3000000, number: 2);
    // الرئيسية: 2,000,000 · الفرعية: 0

    final error = await BalanceGuard.checkEditImpact(
      db,
      original: sarf,
      newTreasuryId: treasuryB, // ← نقل الصرف إلى الفرعية الفارغة
      newCurrency: 'IQD',
      newAmount: 3000000,
    );

    expect(error, isNotNull);
    expect(error, contains('الفرعية'),
        reason: 'الرسالة يجب أن تسمّي الخزينة المتأثرة');
  });

  test('⭐ تغيير عملة سند صرف إلى عملة بلا رصيد مرفوض', () async {
    await insert(type: 'kabd', amount: 5000000, number: 1);
    final sarf = await insert(type: 'sarf', amount: 1000000, number: 2);
    // رصيد الدينار 4,000,000 · رصيد الدولار 0

    final error = await BalanceGuard.checkEditImpact(
      db,
      original: sarf,
      newTreasuryId: treasuryA,
      newCurrency: 'USD', // ← لا رصيد بالدولار إطلاقاً
      newAmount: 1000,
    );

    expect(error, isNotNull, reason: 'خصم دولار من رصيد دولاري صفري');
  });

  // ═══════════════════════════════════════════════════════════════════════
  // احترام إعداد المالك
  // ═══════════════════════════════════════════════════════════════════════

  test('تعطيل المنع من الإعدادات يسمح بالرصيد المدين', () async {
    await db.appSettingsDao.setBool(
      AppSettingsKeys.enforceBalanceCheck,
      false,
    );
    await insert(type: 'kabd', amount: 1000000, number: 1);
    final sarf = await insert(type: 'sarf', amount: 100000, number: 2);

    final error = await BalanceGuard.checkEditImpact(
      db,
      original: sarf,
      newTreasuryId: treasuryA,
      newCurrency: 'IQD',
      newAmount: 99000000,
    );
    expect(error, isNull, reason: 'قرار المالك بالسماح يجب أن يُحترَم');
  });

  test('خفض مبلغ سند صرف مسموح دائماً — لا يُنقص الرصيد', () async {
    await insert(type: 'kabd', amount: 1000000, number: 1);
    final sarf = await insert(type: 'sarf', amount: 900000, number: 2);

    final error = await BalanceGuard.checkEditImpact(
      db,
      original: sarf,
      newTreasuryId: treasuryA,
      newCurrency: 'IQD',
      newAmount: 100000,
    );
    expect(error, isNull, reason: 'التخفيض يزيد الرصيد فلا وجه لرفضه');
  });
}
