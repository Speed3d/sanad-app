// ─────────────────────────────────────────────────────────────────────────────
// treasury_repository.dart — تنفيذ مستودع الخزائن باستخدام Drift
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

import '../../domain/models/treasury_model.dart';
import '../../domain/repositories/i_treasury_repository.dart';
import '../database/app_database.dart';
import '../database/daos/treasuries_dao.dart';
// TreasuriesCompanion و Treasury مُولَّدان في app_database.g.dart — لا حاجة لاستيراد treasuries_table.dart

/// تنفيذ مستودع الخزائن باستخدام Drift
class TreasuryRepository implements ITreasuryRepository {
  final AppDatabase _db;

  const TreasuryRepository(this._db);

  // ── تحويل البيانات ────────────────────────────────────────────────────────

  /// تحويل صف Drift إلى نموذج Domain
  TreasuryModel _toModel(Treasury t) {
    return TreasuryModel(
      id: t.id,
      name: t.name,
      kind: t.kind,
      entityId: t.entityId,
      entityType: t.entityType,
      isActive: t.isActive,
      isDeleted: t.isDeleted,
    );
  }

  /// تحويل صف VIEW إلى نموذج الرصيد
  TreasuryBalanceModel _toBalanceModel(TreasuryBalanceRow row) {
    return TreasuryBalanceModel(
      treasuryId: row.treasuryId,
      treasuryName: row.treasuryName,
      treasuryKind: row.treasuryKind,
      entityId: row.entityId,
      entityType: row.entityType,
      isActive: row.isActive,
      balanceIqd: row.balanceIqd,
      balanceUsd: row.balanceUsd,
      totalVouchers: row.totalVouchers,
      lastVoucherDate: row.lastVoucherDate,
    );
  }

  // ── تنفيذ الواجهة ─────────────────────────────────────────────────────────

  @override
  Stream<List<TreasuryBalanceModel>> watchTreasuryBalances() {
    return _db.treasuriesDao
        .watchTreasuryBalances()
        .map((rows) => rows.map(_toBalanceModel).toList());
  }

  @override
  Stream<TreasuryBalanceModel?> watchTreasuryBalance(int treasuryId) {
    return _db.treasuriesDao
        .watchTreasuryBalance(treasuryId)
        .map((row) => row == null ? null : _toBalanceModel(row));
  }

  @override
  Future<TreasuryBalanceModel?> getTreasuryBalance(int treasuryId) async {
    final row = await _db.treasuriesDao.getTreasuryBalance(treasuryId);
    return row == null ? null : _toBalanceModel(row);
  }

  @override
  Future<List<TreasuryModel>> getAllTreasuries() async {
    final list = await _db.treasuriesDao.getAllTreasuries();
    return list.map(_toModel).toList();
  }

  @override
  Future<TreasuryModel?> getTreasuryById(int id) async {
    final t = await _db.treasuriesDao.getTreasuryById(id);
    return t == null ? null : _toModel(t);
  }

  @override
  Future<List<TreasuryModel>> getTreasuriesByKind(String kind) async {
    final list = await _db.treasuriesDao.getTreasuriesByKind(kind);
    return list.map(_toModel).toList();
  }

  @override
  Future<TreasuryModel?> getTreasuryByEntity(
    int entityId,
    String entityType,
  ) async {
    final t =
        await _db.treasuriesDao.getTreasuryByEntity(entityId, entityType);
    return t == null ? null : _toModel(t);
  }

  @override
  Future<({double totalIqd, double totalUsd})> getTotalBalance() {
    return _db.treasuriesDao.getTotalBalance();
  }

  @override
  Future<int> createTreasury({
    required String name,
    required String kind,
    int? entityId,
    String? entityType,
  }) {
    return _db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(
        name: name,
        // kind له قيمة افتراضية 'main' في الجدول → يجب تغليفه بـ Value()
        kind: Value(kind),
        entityId: Value(entityId),
        entityType: Value(entityType),
      ),
    );
  }

  @override
  Future<void> updateTreasury(TreasuryModel treasury) async {
    await _db.treasuriesDao.updateTreasury(
      TreasuriesCompanion(
        id: Value(treasury.id),
        name: Value(treasury.name),
        kind: Value(treasury.kind),
        entityId: Value(treasury.entityId),
        entityType: Value(treasury.entityType),
        isActive: Value(treasury.isActive),
      ),
    );
  }

  @override
  Future<void> deleteTreasury(int id) {
    return _db.treasuriesDao.softDeleteTreasury(id);
  }

  @override
  Future<void> setActive(int id, {required bool isActive}) {
    return _db.treasuriesDao.setTreasuryActive(id, isActive: isActive);
  }
}
