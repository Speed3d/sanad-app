// ─────────────────────────────────────────────────────────────────────────────
// i_treasury_repository.dart — واجهة مستودع الخزائن
// ─────────────────────────────────────────────────────────────────────────────

import '../models/treasury_model.dart';

/// واجهة مستودع الخزائن
abstract class ITreasuryRepository {
  // ── القراءة ────────────────────────────────────────────────────────────────

  /// Stream تفاعلي لجميع أرصدة الخزائن من الـ VIEW
  Stream<List<TreasuryBalanceModel>> watchTreasuryBalances();

  /// Stream تفاعلي لرصيد خزينة واحدة
  Stream<TreasuryBalanceModel?> watchTreasuryBalance(int treasuryId);

  /// جلب رصيد خزينة واحدة (Future)
  Future<TreasuryBalanceModel?> getTreasuryBalance(int treasuryId);

  /// جميع الخزائن النشطة
  Future<List<TreasuryModel>> getAllTreasuries();

  /// خزينة واحدة بالمعرّف
  Future<TreasuryModel?> getTreasuryById(int id);

  /// خزائن حسب النوع
  Future<List<TreasuryModel>> getTreasuriesByKind(String kind);

  /// خزينة مرتبطة بكيان معين
  Future<TreasuryModel?> getTreasuryByEntity(int entityId, String entityType);

  /// إجمالي رصيد جميع الخزائن
  Future<({double totalIqd, double totalUsd})> getTotalBalance();

  // ── الكتابة ────────────────────────────────────────────────────────────────

  /// إنشاء خزينة جديدة — يُعيد الـ ID المُولَّد
  Future<int> createTreasury({
    required String name,
    required String kind,
    int? entityId,
    String? entityType,
  });

  /// تحديث بيانات خزينة
  Future<void> updateTreasury(TreasuryModel treasury);

  /// حذف ناعم للخزينة
  Future<void> deleteTreasury(int id);

  /// تفعيل / تعطيل خزينة
  Future<void> setActive(int id, {required bool isActive});
}
