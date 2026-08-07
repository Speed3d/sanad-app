// ─────────────────────────────────────────────────────────────────────────────
// transfer_delete_test.dart — اختبارات حذف التحويلات الموثوق
//
// لماذا هذا الملف؟
//   كشف تدقيق 2026-08-06 أن حذف التحويل كان يعتمد على مطابقة تخمينية
//   (نفس المبلغ+التاريخ+الخزينتين) مع getSingleOrNull. تحويلان متطابقان في
//   نفس اليوم يجعلان الاستعلام يرمي "Too many elements" فيصبح السند غير
//   قابل للحذف. أُضيف عمود transfer_group_id يربط الطرفين برباط صريح.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';

void main() {
  late AppDatabase db;
  late int periodId;
  late int treasuryA;
  late int treasuryB;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    expect(db.schemaVersion, equals(3));
    periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
      ),
    );
    treasuryA = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'خزينة أ', kind: const Value('main')),
    );
    treasuryB = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'خزينة ب', kind: const Value('main')),
    );
  });

  tearDown(() async {
    await db.close();
  });

  /// إنشاء تحويل عبر insertTransfer (يُنشئ الطرفين مع نفس transfer_group_id)
  Future<({int outId, int inId})> makeTransfer(double amount, DateTime date) {
    return db.vouchersDao.insertTransfer(
      outVoucher: VouchersCompanion.insert(
        voucherNumber: 0,
        voucherType: 'transfer_out',
        treasuryId: treasuryA,
        fiscalPeriodId: periodId,
        amount: amount,
        currency: const Value('IQD'),
        voucherDate: date,
        linkedTreasuryId: Value(treasuryB),
      ),
      inVoucher: VouchersCompanion.insert(
        voucherNumber: 0,
        voucherType: 'transfer_in',
        treasuryId: treasuryB,
        fiscalPeriodId: periodId,
        amount: amount,
        currency: const Value('IQD'),
        voucherDate: date,
        linkedTreasuryId: Value(treasuryA),
      ),
    );
  }

  test('insertTransfer يضع نفس transfer_group_id على الطرفين', () async {
    final ids = await makeTransfer(100000.0, DateTime(2026, 5, 1));
    final out = await db.vouchersDao.getVoucherById(ids.outId);
    final inV = await db.vouchersDao.getVoucherById(ids.inId);

    expect(out!.transferGroupId, isNotNull);
    expect(out.transferGroupId, equals(inV!.transferGroupId));
  });

  test('حذف طرف تحويل يحذف الطرف التوأم عبر المجموعة', () async {
    final ids = await makeTransfer(100000.0, DateTime(2026, 5, 1));

    await db.vouchersDao.softDeleteVoucher(ids.outId);

    final out = await db.vouchersDao.getVoucherById(ids.outId);
    final inV = await db.vouchersDao.getVoucherById(ids.inId);
    expect(out!.isDeleted, isTrue);
    expect(inV!.isDeleted, isTrue, reason: 'التوأم يجب أن يُحذف أيضاً');
  });

  test('تحويلان متطابقان في نفس اليوم: كلٌّ يُحذف بمعزل عن الآخر', () async {
    // نفس المبلغ ونفس التاريخ ونفس الخزينتين — الحالة التي كانت تكسر المطابقة
    final t1 = await makeTransfer(100000.0, DateTime(2026, 5, 1));
    final t2 = await makeTransfer(100000.0, DateTime(2026, 5, 1));

    // حذف التحويل الأول — يجب ألا يرمي استثناءً، ويحذف طرفيه فقط
    await db.vouchersDao.softDeleteVoucher(t1.outId);

    final t1Out = await db.vouchersDao.getVoucherById(t1.outId);
    final t1In = await db.vouchersDao.getVoucherById(t1.inId);
    final t2Out = await db.vouchersDao.getVoucherById(t2.outId);
    final t2In = await db.vouchersDao.getVoucherById(t2.inId);

    expect(t1Out!.isDeleted, isTrue);
    expect(t1In!.isDeleted, isTrue);
    // التحويل الثاني يجب أن يبقى سليماً تماماً
    expect(t2Out!.isDeleted, isFalse, reason: 'التحويل الثاني يجب ألا يتأثر');
    expect(t2In!.isDeleted, isFalse);
  });
}
