// ─────────────────────────────────────────────────────────────────────────────
// fiscal_period_delete_test.dart — حذف فترة مالية خالية
//
// الفجوة التي يغلقها (اكتُشفت 2026-08-23):
//   لم يكن في النظام أي طريقة لحذف فترة مالية — لا دالة في طبقة البيانات
//   ولا زر في الواجهة. فأي سنة تُنشأ بالخطأ تبقى إلى الأبد، وتحجب — بقاعدة
//   عدم التقاطع — إنشاءَ السنة الصحيحة مكانها. أي أن خطأً إدارياً بسيطاً
//   كان يصير دائماً بلا مخرج.
//
// الشرط الذي لا يُتساهل فيه: الحذف **فعلي لا ناعم**، فلا يُسمح به إلا لفترة
// خالية تماماً — وإلا لاختفى أثر مالي حقيقي بلا رجعة، وهو ما يناقض تصميم
// النظام كله (السندات تُحذف حذفاً ناعماً دائماً).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/auth/permissions.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/voucher_repository.dart';
import 'package:sales_management/domain/models/user_model.dart';

void main() {
  late AppDatabase db;
  late int periodId;
  late int treasuryId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31, 23, 59, 59),
      ),
    );
    treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );
  });

  tearDown(() async => db.close());

  Future<String?> tryDelete(int id) async {
    try {
      await db.fiscalPeriodsDao.deleteEmptyPeriod(id);
      return null;
    } on StateError catch (e) {
      return e.message;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ حذف فترة خالية ينجح', () async {
    expect(await tryDelete(periodId), isNull);
    final all = await db.fiscalPeriodsDao.watchAllPeriods().first;
    expect(all, isEmpty);
  });

  test('⭐ بعد الحذف يصير النطاق متاحاً لفترة جديدة', () async {
    await db.fiscalPeriodsDao.deleteEmptyPeriod(periodId);
    // كان هذا مستحيلاً قبل إضافة الحذف: الفترة الخاطئة تحجب النطاق للأبد
    final newId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026 (الصحيحة)',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31, 23, 59, 59),
      ),
    );
    expect(newId, greaterThan(0));
  });

  test('⭐ فترة فيها سند لا تُحذف', () async {
    await VoucherRepository(db).createVoucher(
      fiscalPeriodId: periodId,
      voucherType: 'kabd',
      treasuryId: treasuryId,
      amount: 500000,
      currency: 'IQD',
      voucherDate: DateTime(2026, 3, 1),
    );

    final err = await tryDelete(periodId);
    expect(err, isNotNull);
    expect(err, contains('1 سند'));

    final all = await db.fiscalPeriodsDao.watchAllPeriods().first;
    expect(all, hasLength(1), reason: 'الفترة باقية — لم يضع أثر مالي');
  });

  test('السند المحذوف ناعماً يمنع الحذف — والرسالة توضّح المفارقة', () async {
    final repo = VoucherRepository(db);
    final id = await repo.createVoucher(
      fiscalPeriodId: periodId,
      voucherType: 'kabd',
      treasuryId: treasuryId,
      amount: 100000,
      currency: 'IQD',
      voucherDate: DateTime(2026, 3, 1),
    );
    await repo.deleteVoucher(id);

    // الشاشة تعرض «0 سند» لأنها تعدّ غير المحذوف فقط — فلولا التوضيح في
    // الرسالة لبدا الرفض تعسّفاً بلا سبب.
    final err = await tryDelete(periodId);
    expect(err, isNotNull);
    expect(err, contains('محذوف'));
  });

  test('فترة فيها سلفة مشروع لا تُحذف', () async {
    await db.advancesDao.insertAdvance(
      AdvancesCompanion.insert(
        advanceNumber: '23',
        projectTreasuryId: treasuryId,
        fiscalPeriodId: periodId,
        advanceDate: DateTime(2026, 3, 1),
      ),
    );
    final err = await tryDelete(periodId);
    expect(err, contains('سلفة مشروع'));
  });

  test('الحذف يمسح تسلسل الترقيم التابع (مفتاح خارجي يمنع الحذف بدونه)',
      () async {
    // إنشاء سند ثم حذفه فعلياً يترك صف تسلسل يشير إلى الفترة
    await db.fiscalPeriodsDao
        .getNextVoucherNumber(fiscalPeriodId: periodId, voucherType: 'kabd');
    final before = await db
        .customSelect('SELECT COUNT(*) AS c FROM voucher_sequences')
        .getSingle();
    expect(before.data['c'], greaterThan(0));

    expect(await tryDelete(periodId), isNull);

    final after = await db
        .customSelect('SELECT COUNT(*) AS c FROM voucher_sequences')
        .getSingle();
    expect(after.data['c'], 0);
  });

  test('فترة غير موجودة تُرفض برسالة واضحة', () async {
    expect(await tryDelete(9999), contains('غير موجودة'));
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الصلاحية — مدير النظام وحده
  // ═══════════════════════════════════════════════════════════════════════

  test('حذف الفترة صلاحية super_admin وحده', () {
    UserModel u(String role) => UserModel(
          id: 1,
          username: 'u',
          fullName: 'u',
          role: role,
          createdAt: DateTime(2026, 1, 1),
        );

    expect(u('user').can(AppPermission.deleteFiscalPeriod), isFalse);
    expect(u('admin').can(AppPermission.deleteFiscalPeriod), isFalse);
    expect(u('super_admin').can(AppPermission.deleteFiscalPeriod), isTrue);
  });
}
