// ─────────────────────────────────────────────────────────────────────────────
// voucher_repository.dart — تنفيذ مستودع السندات باستخدام Drift
//
// هذا الـ Repository هو الأكثر تعقيداً لأنه:
//   1. يقرأ رقم السند التالي من FiscalPeriodsDao
//   2. يُحوّل بيانات Drift إلى VoucherModel والعكس
//   3. يُنفّذ عملية التحويل بين الخزائن بـ Atomic Transaction
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

import '../../domain/models/voucher_model.dart';
import '../../domain/repositories/i_voucher_repository.dart';
import '../database/app_database.dart';
import '../database/daos/vouchers_dao.dart';
// VouchersCompanion و Voucher مُولَّدان في app_database.g.dart — لا حاجة لاستيراد vouchers_table.dart

/// تنفيذ مستودع السندات باستخدام Drift
class VoucherRepository implements IVoucherRepository {
  final AppDatabase _db;

  const VoucherRepository(this._db);

  // ── تحويل البيانات ────────────────────────────────────────────────────────

  /// تحويل نموذج Drift إلى نموذج Domain
  VoucherModel _toModel(Voucher v) {
    return VoucherModel(
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
      isDeleted: v.isDeleted,
      deletedAt: v.deletedAt,
    );
  }

  /// تحويل سطر كشف حساب Drift إلى نموذج Domain
  AccountStatementModel _toStatementModel(AccountStatementRow row) {
    return AccountStatementModel(
      voucher: _toModel(row.voucher),
      runningBalanceIqd: row.runningBalanceIqd,
      runningBalanceUsd: row.runningBalanceUsd,
    );
  }

  // ── تنفيذ الواجهة ─────────────────────────────────────────────────────────

  @override
  Stream<List<VoucherModel>> watchVouchersByTreasury(int treasuryId) {
    return _db.vouchersDao
        .watchVouchersByTreasury(treasuryId)
        .map((list) => list.map(_toModel).toList());
  }

  @override
  Stream<List<VoucherModel>> watchVouchersByType(String voucherType) {
    return _db.vouchersDao
        .watchVouchersByType(voucherType)
        .map((list) => list.map(_toModel).toList());
  }

  @override
  Future<List<VoucherModel>> getVouchersByDateRange({
    required DateTime from,
    required DateTime to,
    int? treasuryId,
    String? voucherType,
    int? fiscalPeriodId,
  }) async {
    final list = await _db.vouchersDao.getVouchersByDateRange(
      from: from,
      to: to,
      treasuryId: treasuryId,
      voucherType: voucherType,
      fiscalPeriodId: fiscalPeriodId,
    );
    return list.map(_toModel).toList();
  }

  @override
  Future<List<VoucherModel>> searchVouchers(String query) async {
    final list = await _db.vouchersDao.searchVouchers(query);
    return list.map(_toModel).toList();
  }

  @override
  Future<List<AccountStatementModel>> getAccountStatement({
    required int treasuryId,
    required DateTime from,
    required DateTime to,
    double openingBalanceIqd = 0,
    double openingBalanceUsd = 0,
  }) async {
    final rows = await _db.vouchersDao.getAccountStatement(
      treasuryId: treasuryId,
      from: from,
      to: to,
      openingBalanceIqd: openingBalanceIqd,
      openingBalanceUsd: openingBalanceUsd,
    );
    return rows.map(_toStatementModel).toList();
  }

  @override
  Future<({double totalSarf, double totalKabd})> getDailySummary(
    DateTime date,
  ) {
    return _db.vouchersDao.getDailySummary(date);
  }

  /// حارس الفترة المالية — يرمي استثناءً إذا كانت الفترة غير نشطة
  ///
  /// ⚠️ لماذا؟ (إصلاح تدقيق 2026-08-06)
  ///   الفترة المُقفَلة (frozen) تمثّل بيانات محاسبية مُجمَّدة. الكتابة أو
  ///   التعديل أو الحذف فيها يغيّر أرصدة تاريخية بعد إغلاقها. الإنشاء كان
  ///   محمياً ضمناً (getFiscalPeriodForDate تُعيد النشطة فقط)، لكن التعديل
  ///   والحذف لم يكونا محميَّين إطلاقاً. هذا الحارس يسدّ الثغرة في كل المسارات.
  Future<void> _ensurePeriodActive(int fiscalPeriodId) async {
    final period = await _db.fiscalPeriodsDao.getPeriodById(fiscalPeriodId);
    if (period != null && period.status != 'active') {
      throw StateError(
        'الفترة المالية "${period.name}" مُقفَلة — لا يمكن تعديل أو إضافة '
        'سندات فيها. أعد فتح الفترة أولاً إذا لزم الأمر.',
      );
    }
  }

  @override
  Future<int> createVoucher({
    required int fiscalPeriodId,
    required String voucherType,
    required int treasuryId,
    required double amount,
    required String currency,
    required DateTime voucherDate,
    String personName = '',
    String reason = '',
    String itemType = '',
    String referenceNumber = '',
    bool closeSafe = false,
    int? linkedTreasuryId,
    int? linkedEntityId,
    double exchangeRate = 1.0,
    int? createdByUserId,
  }) async {
    // 0. التأكد أن الفترة نشطة (دفاع في العمق حتى لو مرّر المستدعي فترة مقفلة)
    await _ensurePeriodActive(fiscalPeriodId);

    // 1. الحصول على رقم السند التالي (ذري)
    final voucherNumber = await _db.fiscalPeriodsDao.getNextVoucherNumber(
      fiscalPeriodId: fiscalPeriodId,
      voucherType: voucherType,
    );

    // 2. إدراج السند
    return _db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: voucherNumber,
        voucherType: voucherType,
        treasuryId: treasuryId,
        fiscalPeriodId: fiscalPeriodId,
        amount: amount,
        // currency له قيمة افتراضية 'IQD' → يجب تغليفه بـ Value()
        currency: Value(currency),
        exchangeRate: Value(exchangeRate),
        voucherDate: voucherDate,
        personName: Value(personName),
        reason: Value(reason),
        itemType: Value(itemType),
        referenceNumber: Value(referenceNumber),
        closeSafe: Value(closeSafe),
        linkedTreasuryId: Value(linkedTreasuryId),
        linkedEntityId: Value(linkedEntityId),
        createdByUserId: Value(createdByUserId),
      ),
    );
  }

  @override
  Future<({int outId, int inId})> createTransfer({
    required int fromTreasuryId,
    required int toTreasuryId,
    required double amount,
    required String currency,
    required int fiscalPeriodId,
    required DateTime voucherDate,
    String reason = '',
    int? createdByUserId,
    double exchangeRate = 1.0,
  }) async {
    // التأكد أن الفترة نشطة قبل أي كتابة
    await _ensurePeriodActive(fiscalPeriodId);

    // الحصول على رقمَي السند التاليَين
    final outNumber = await _db.fiscalPeriodsDao.getNextVoucherNumber(
      fiscalPeriodId: fiscalPeriodId,
      voucherType: 'transfer_out',
    );
    final inNumber = await _db.fiscalPeriodsDao.getNextVoucherNumber(
      fiscalPeriodId: fiscalPeriodId,
      voucherType: 'transfer_in',
    );

    // بناء السندين
    final outVoucher = VouchersCompanion.insert(
      voucherNumber: outNumber,
      voucherType: 'transfer_out',
      treasuryId: fromTreasuryId,
      fiscalPeriodId: fiscalPeriodId,
      amount: amount,
      // currency له قيمة افتراضية → Value()
      currency: Value(currency),
      exchangeRate: Value(exchangeRate),
      voucherDate: voucherDate,
      reason: Value(reason),
      linkedTreasuryId: Value(toTreasuryId),
      createdByUserId: Value(createdByUserId),
    );

    final inVoucher = VouchersCompanion.insert(
      voucherNumber: inNumber,
      voucherType: 'transfer_in',
      treasuryId: toTreasuryId,
      fiscalPeriodId: fiscalPeriodId,
      amount: amount,
      // currency له قيمة افتراضية → Value()
      currency: Value(currency),
      exchangeRate: Value(exchangeRate),
      voucherDate: voucherDate,
      reason: Value(reason),
      linkedTreasuryId: Value(fromTreasuryId),
      createdByUserId: Value(createdByUserId),
    );

    // تنفيذ كلا السندين في Transaction واحدة
    return _db.vouchersDao.insertTransfer(
      outVoucher: outVoucher,
      inVoucher: inVoucher,
    );
  }

  @override
  Future<void> updateVoucher(VoucherModel voucher) async {
    // منع تعديل سند داخل فترة مُقفَلة (يغيّر أرصدة تاريخية)
    await _ensurePeriodActive(voucher.fiscalPeriodId);
    await _db.vouchersDao.updateVoucher(
      VouchersCompanion(
        id: Value(voucher.id),
        voucherNumber: Value(voucher.voucherNumber),
        voucherType: Value(voucher.voucherType),
        treasuryId: Value(voucher.treasuryId),
        fiscalPeriodId: Value(voucher.fiscalPeriodId),
        amount: Value(voucher.amount),
        currency: Value(voucher.currency),
        exchangeRate: Value(voucher.exchangeRate),
        voucherDate: Value(voucher.voucherDate),
        personName: Value(voucher.personName),
        reason: Value(voucher.reason),
        itemType: Value(voucher.itemType),
        referenceNumber: Value(voucher.referenceNumber),
        closeSafe: Value(voucher.closeSafe),
        linkedTreasuryId: Value(voucher.linkedTreasuryId),
        linkedEntityId: Value(voucher.linkedEntityId),
      ),
    );
  }

  @override
  Future<void> deleteVoucher(int id, {int? deletedByUserId}) async {
    // منع حذف سند داخل فترة مُقفَلة
    final voucher = await _db.vouchersDao.getVoucherById(id);
    if (voucher != null) {
      await _ensurePeriodActive(voucher.fiscalPeriodId);
    }
    await _db.vouchersDao.softDeleteVoucher(
      id,
      deletedByUser: deletedByUserId,
    );
  }
}
