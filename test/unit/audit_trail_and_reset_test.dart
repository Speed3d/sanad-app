// ─────────────────────────────────────────────────────────────────────────────
// audit_trail_and_reset_test.dart — أثر التعديل وتصفير البيانات (ث-١ · ث-٢ · ث-٣)
//
// الثغرات الثلاث التي يغلقها هذا الملف — تدقيق 2026-08-23:
//
//   ث-١  زرّ «تصفير جميع البيانات المالية» كان يحذف vouchers ثم fiscal_periods
//        فقط، بينما voucher_sequences.fiscal_period_id و advances.fiscal_period_id
//        مفتاحان خارجيان إليها و PRAGMA foreign_keys = ON مُفعَّل. وصف التسلسل
//        يُنشأ عند أول سند — فبعد أول سند صار الزر يفشل دائماً بقيد أجنبي.
//
//   ث-٢  سجل التدقيق كان يوثّق إنشاء السند وحذفه، و**التعديل يمرّ صامتاً** —
//        رغم أنه أخطر العمليات الثلاث (المُنشأ والمحذوف يظهران في القوائم،
//        أما تغيير مبلغ سند قائم فلا يميّزه شيء عن سند أُدخل صحيحاً).
//
//   ث-٣  updateVoucher كان لا يكتب updated_at ولا updated_by_user_id إطلاقاً،
//        فيبقيان على قيمة لحظة الإنشاء — وهو خط الدفاع الأخير لو أُفرغ السجل.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/utils/audit_logger.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/voucher_repository.dart';
import 'package:sales_management/domain/models/voucher_model.dart';

void main() {
  late AppDatabase db;
  late VoucherRepository repo;
  late int periodId;
  late int treasuryId;

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
    treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );
  });

  tearDown(() async => db.close());

  // ═══════════════════════════════════════════════════════════════════════
  // ث-١ — التصفير يعمل فعلاً ولا يرتطم بقيد أجنبي
  // ═══════════════════════════════════════════════════════════════════════

  group('ث-١ — تصفير البيانات المالية', () {
    test('⭐ التصفير ينجح بعد وجود سندات — كان يفشل بقيد أجنبي', () async {
      // إنشاء سند عبر المستودع يُنشئ صف تسلسل يشير إلى الفترة المالية،
      // وهو بالضبط ما كان يجعل حذف الفترات مستحيلاً.
      await repo.createVoucher(
        fiscalPeriodId: periodId,
        voucherType: 'kabd',
        treasuryId: treasuryId,
        amount: 5000000,
        currency: 'IQD',
        voucherDate: DateTime(2026, 3, 1),
      );

      final seqBefore = await db
          .customSelect('SELECT COUNT(*) AS c FROM voucher_sequences')
          .getSingle();
      expect(seqBefore.data['c'], greaterThan(0),
          reason: 'الشرط المسبق: صف تسلسل موجود — وهو سبب العطل الأصلي');

      // قبل الإصلاح كان هذا السطر يرمي FOREIGN KEY constraint failed
      final removed = await db.resetFinancialData();

      expect(removed.vouchers, 1);
      expect(removed.periods, 1);
    });

    test('التصفير يمسح تسلسل الترقيم — وإلا استأنف من حيث توقّف', () async {
      await repo.createVoucher(
        fiscalPeriodId: periodId,
        voucherType: 'kabd',
        treasuryId: treasuryId,
        amount: 1000,
        currency: 'IQD',
        voucherDate: DateTime(2026, 3, 1),
      );
      await db.resetFinancialData();

      final row = await db
          .customSelect('SELECT COUNT(*) AS c FROM voucher_sequences')
          .getSingle();
      expect(row.data['c'], 0);
    });

    test('التصفير يمسح سلف المشاريع وأسطرها فلا تبقى يتيمة', () async {
      final advanceId = await db.advancesDao.insertAdvance(
        AdvancesCompanion.insert(
          advanceNumber: '23',
          projectTreasuryId: treasuryId,
          fiscalPeriodId: periodId,
          advanceDate: DateTime(2026, 3, 1),
        ),
      );
      await db.advancesDao.insertLines([
        AdvanceLinesCompanion.insert(
          advanceId: advanceId,
          voucherDate: DateTime(2026, 3, 2),
          amount: 250000,
          originalAmount: 250000,
          originalDate: DateTime(2026, 3, 2),
        ),
      ]);

      final removed = await db.resetFinancialData();
      expect(removed.advances, 1);

      final lines = await db
          .customSelect('SELECT COUNT(*) AS c FROM advance_lines')
          .getSingle();
      expect(lines.data['c'], 0);
    });

    test('التصفير لا يمسّ الخزائن ولا سجل التدقيق', () async {
      await db.auditLogDao.logSimpleAction(
        username: 'admin',
        table: AuditTables.system,
        action: AuditActions.login,
      );
      await db.resetFinancialData();

      final treasuries = await db.treasuriesDao.watchAllTreasuries().first;
      expect(treasuries, isNotEmpty, reason: 'التصفير يمحو الحركة لا الهيكل');

      final logs = await db.auditLogDao.getRecentLogs();
      expect(logs, isNotEmpty,
          reason: 'لو مُحي السجل لضاع أثر التصفير نفسه');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ث-٢ — تعديل السند يترك أثراً بالقيمتين قبل وبعد
  // ═══════════════════════════════════════════════════════════════════════

  group('ث-٢ — توثيق تعديل السند', () {
    test('⭐ logVoucherUpdated يسجّل القيمة السابقة والجديدة معاً', () async {
      final logger = AuditLogger(db.auditLogDao);
      await logger.logVoucherUpdated(
        userId: 3,
        username: 'محاسب',
        voucherId: 42,
        voucherType: 'sarf',
        oldAmount: 100000,
        newAmount: 900000,
        oldCurrency: 'IQD',
        newCurrency: 'IQD',
        oldTreasuryId: treasuryId,
        newTreasuryId: treasuryId,
      );

      final logs = await db.auditLogDao.getLogsByTable(AuditTables.vouchers);
      expect(logs, hasLength(1));
      expect(logs.first.action, AuditActions.update);
      expect(logs.first.recordId, 42);

      final meta = jsonDecode(logs.first.metaJson) as Map<String, dynamic>;
      // القيمة الجديدة وحدها لا تكفي: بدون السابقة لا يُعرف حجم التغيير
      expect(meta['old_amount'], 100000);
      expect(meta['new_amount'], 900000);
      expect(meta['amount_delta'], 800000);
    });

    test('نقل السند إلى خزينة أخرى يُوثَّق بالخزينتين', () async {
      final other = await db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(name: 'البصرة', kind: const Value('main')),
      );
      await AuditLogger(db.auditLogDao).logVoucherUpdated(
        userId: 1,
        username: 'admin',
        voucherId: 7,
        voucherType: 'sarf',
        oldAmount: 5000,
        newAmount: 5000,
        oldCurrency: 'IQD',
        newCurrency: 'IQD',
        oldTreasuryId: treasuryId,
        newTreasuryId: other,
      );

      final logs = await db.auditLogDao.getLogsByTable(AuditTables.vouchers);
      final meta = jsonDecode(logs.first.metaJson) as Map<String, dynamic>;
      expect(meta['old_treasury_id'], treasuryId);
      expect(meta['new_treasury_id'], other);
    });

    test('logFinancialDataReset يوثّق العدّادات قبل المسح', () async {
      await AuditLogger(db.auditLogDao).logFinancialDataReset(
        userId: 1,
        username: 'super',
        vouchersDeleted: 120,
        periodsDeleted: 2,
        advancesDeleted: 5,
      );
      final logs = await db.auditLogDao.getLogsByTable(AuditTables.system);
      final meta = jsonDecode(logs.first.metaJson) as Map<String, dynamic>;
      expect(meta['event'], 'financial_data_reset');
      expect(meta['vouchers_deleted'], 120);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ث-٣ — الصف نفسه يحمل أثر التعديل
  // ═══════════════════════════════════════════════════════════════════════

  group('ث-٣ — updated_at و updated_by_user_id', () {
    test('⭐ التعديل يكتب من عدّل ومتى — كانا يبقيان على قيمة الإنشاء',
        () async {
      final id = await repo.createVoucher(
        fiscalPeriodId: periodId,
        voucherType: 'kabd',
        treasuryId: treasuryId,
        amount: 500000,
        currency: 'IQD',
        voucherDate: DateTime(2026, 3, 1),
        createdByUserId: 1,
      );
      final before = (await db.vouchersDao.getVoucherById(id))!;
      expect(before.updatedByUserId, isNull);

      // فجوة زمنية مضمونة كي لا يتساوى الطابعان على ساعة خشنة الدقة
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      await repo.updateVoucher(
        _modelOf(before).copyWith(amount: 750000),
        updatedByUserId: 9,
      );

      final after = (await db.vouchersDao.getVoucherById(id))!;
      expect(after.amount, 750000);
      expect(after.updatedByUserId, 9);
      expect(after.updatedAt.isAfter(before.updatedAt), isTrue);
      expect(after.createdAt, before.createdAt,
          reason: 'التعديل لا يجوز أن يمسّ تاريخ الإنشاء');
    });
  });
}

/// تحويل صفّ Drift إلى نموذج Domain — نسخة مختصرة للاختبار
VoucherModel _modelOf(Voucher v) => VoucherModel(
      id: v.id,
      voucherNumber: v.voucherNumber,
      voucherType: v.voucherType,
      treasuryId: v.treasuryId,
      fiscalPeriodId: v.fiscalPeriodId,
      amount: v.amount,
      currency: v.currency,
      exchangeRate: v.exchangeRate,
      voucherDate: v.voucherDate,
      personName: v.personName,
      reason: v.reason,
      itemType: v.itemType,
      referenceNumber: v.referenceNumber,
      closeSafe: v.closeSafe,
      linkedTreasuryId: v.linkedTreasuryId,
      linkedEntityId: v.linkedEntityId,
    );
