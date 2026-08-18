// ─────────────────────────────────────────────────────────────────────────────
// transfer_edit_guard_test.dart — حارس تعديل سندات التحويل (ح-١)
//
// الثغرة التي يغلقها:
//   التحويل سندان توأمان. كانت قائمة السندات توجّه سند التحويل إلى شاشة
//   تعديل الصرف/القبض التي لا تفحص النوع، فيُعدَّل طرف واحد دون توأمه:
//     تحويل 3 مليون يُعدَّل إلى 1 مليون
//     ← المُرسِلة تفقد 1 مليون فقط، والمُستقبِلة استلمت 3
//     ← مليونان ظهرا من العدم
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
  late int periodId;
  late int treasuryA;
  late int treasuryB;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = VoucherRepository(db);
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
      TreasuriesCompanion.insert(name: 'البصرة', kind: const Value('main')),
    );
    // تمويل الخزينة الرئيسية
    await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: 1,
        voucherType: 'kabd',
        treasuryId: treasuryA,
        fiscalPeriodId: periodId,
        amount: 5000000.0,
        currency: const Value('IQD'),
        voucherDate: DateTime(2026, 3, 1),
      ),
    );
  });

  tearDown(() async => db.close());

  Future<double> balanceOf(int id) async =>
      (await db.treasuriesDao.getTreasuryBalance(id))?.balanceIqd ?? 0;

  /// إنشاء تحويل 3 مليون من الرئيسية إلى البصرة
  Future<({int outId, int inId})> makeTransfer() {
    return repo.createTransfer(
      fromTreasuryId: treasuryA,
      toTreasuryId: treasuryB,
      amount: 3000000.0,
      currency: 'IQD',
      fiscalPeriodId: periodId,
      voucherDate: DateTime(2026, 3, 5),
      reason: 'تمويل مشروع',
    );
  }

  test('⭐ تعديل طرف التحويل الصادر مرفوض — لا مال من العدم', () async {
    final ids = await makeTransfer();
    expect(await balanceOf(treasuryA), equals(2000000.0));
    expect(await balanceOf(treasuryB), equals(3000000.0));

    final out = await db.vouchersDao.getVoucherById(ids.outId);
    final model = VoucherModel(
      id: out!.id,
      voucherNumber: out.voucherNumber,
      voucherType: out.voucherType,
      treasuryId: out.treasuryId,
      fiscalPeriodId: out.fiscalPeriodId,
      amount: 1000000.0, // ← محاولة التخفيض من 3 مليون إلى 1
      currency: out.currency,
      voucherDate: out.voucherDate,
    );

    await expectLater(
      repo.updateVoucher(model),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        contains('لا يمكن تعديل سند تحويل'),
      )),
    );

    // الأرصدة لم تتغيّر — لم يُخلق ولم يُبخَّر أي مبلغ
    expect(await balanceOf(treasuryA), equals(2000000.0));
    expect(await balanceOf(treasuryB), equals(3000000.0));
  });

  test('تعديل طرف التحويل الوارد مرفوض أيضاً', () async {
    final ids = await makeTransfer();
    final inV = await db.vouchersDao.getVoucherById(ids.inId);

    await expectLater(
      repo.updateVoucher(
        VoucherModel(
          id: inV!.id,
          voucherNumber: inV.voucherNumber,
          voucherType: inV.voucherType,
          treasuryId: inV.treasuryId,
          fiscalPeriodId: inV.fiscalPeriodId,
          amount: 9000000.0,
          currency: inV.currency,
          voucherDate: inV.voucherDate,
        ),
      ),
      throwsA(isA<StateError>()),
    );
    expect(await balanceOf(treasuryB), equals(3000000.0));
  });

  test('تعديل سند صرف عادي ما زال مسموحاً', () async {
    final id = await repo.createVoucher(
      fiscalPeriodId: periodId,
      voucherType: 'sarf',
      treasuryId: treasuryA,
      amount: 500000.0,
      currency: 'IQD',
      voucherDate: DateTime(2026, 3, 6),
    );
    final v = await db.vouchersDao.getVoucherById(id);

    await repo.updateVoucher(
      VoucherModel(
        id: v!.id,
        voucherNumber: v.voucherNumber,
        voucherType: v.voucherType,
        treasuryId: v.treasuryId,
        fiscalPeriodId: v.fiscalPeriodId,
        amount: 400000.0,
        currency: v.currency,
        voucherDate: v.voucherDate,
      ),
    );

    expect(await balanceOf(treasuryA), equals(4600000.0),
        reason: 'الحارس يخصّ التحويلات وحدها ولا يعطّل التعديل العادي');
  });

  test('حذف التحويل ما زال يحذف الطرفين ويعيد التوازن', () async {
    final ids = await makeTransfer();
    await repo.deleteVoucher(ids.outId);

    expect(await balanceOf(treasuryA), equals(5000000.0));
    expect(await balanceOf(treasuryB), equals(0.0),
        reason: 'التصحيح المتاح هو الحذف — ويجب أن يبقى سليماً');
  });
}
