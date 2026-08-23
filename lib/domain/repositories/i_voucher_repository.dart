// ─────────────────────────────────────────────────────────────────────────────
// i_voucher_repository.dart — واجهة مستودع السندات
// ─────────────────────────────────────────────────────────────────────────────

import '../models/voucher_model.dart';

/// واجهة مستودع السندات
abstract class IVoucherRepository {
  // ── القراءة ────────────────────────────────────────────────────────────────

  /// Stream تفاعلي لسندات خزينة محددة
  Stream<List<VoucherModel>> watchVouchersByTreasury(int treasuryId);

  /// Stream تفاعلي لسندات حسب نوعها
  Stream<List<VoucherModel>> watchVouchersByType(String voucherType);

  /// سندات ضمن نطاق تاريخ مع فلاتر اختيارية
  Future<List<VoucherModel>> getVouchersByDateRange({
    required DateTime from,
    required DateTime to,
    int? treasuryId,
    String? voucherType,
    int? fiscalPeriodId,
  });

  /// بحث نصي في السندات
  Future<List<VoucherModel>> searchVouchers(String query);

  /// كشف الحساب لخزينة مع الرصيد التراكمي
  Future<List<AccountStatementModel>> getAccountStatement({
    required int treasuryId,
    required DateTime from,
    required DateTime to,
    double openingBalanceIqd,
    double openingBalanceUsd,
  });

  /// ملخص الصرف والقبض ليوم محدد (للـ Dashboard)
  Future<({double totalSarf, double totalKabd})> getDailySummary(DateTime date);

  // ── الكتابة ────────────────────────────────────────────────────────────────

  /// إنشاء سند صرف — يُعيد الـ ID المُولَّد
  ///
  /// يُحدَّد رقم السند تلقائياً من FiscalPeriodsDao.getNextVoucherNumber()
  Future<int> createVoucher({
    required int fiscalPeriodId,
    required String voucherType,
    required int treasuryId,
    required double amount,
    required String currency,
    required DateTime voucherDate,
    String personName,
    String reason,
    String itemType,
    String referenceNumber,
    bool closeSafe,
    int? linkedTreasuryId,
    int? linkedEntityId,
    double exchangeRate,
    int? createdByUserId,
  });

  /// إنشاء عملية تحويل بين خزينتين (Atomic)
  ///
  /// يُنشئ سندَين (transfer_out + transfer_in) في Transaction واحدة
  Future<({int outId, int inId})> createTransfer({
    required int fromTreasuryId,
    required int toTreasuryId,
    required double amount,
    required String currency,
    required int fiscalPeriodId,
    required DateTime voucherDate,
    String reason,
    int? createdByUserId,
    double exchangeRate,
  });

  /// تحديث سند (قبل الإقفال المالي فقط)
  ///
  /// [updatedByUserId] — من أجرى التعديل. يُكتَب في `updated_by_user_id`
  /// مع `updated_at` ليبقى في الصف نفسه أثرٌ لمن غيّره ومتى، مستقلاً عن
  /// سجل التدقيق (إصلاح ث-٣ — تدقيق 2026-08-23).
  Future<void> updateVoucher(VoucherModel voucher, {int? updatedByUserId});

  /// حذف ناعم للسند
  Future<void> deleteVoucher(int id, {int? deletedByUserId});
}
