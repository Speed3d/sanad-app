// ─────────────────────────────────────────────────────────────────────────────
// treasuries_dao.dart — DAO الخزائن
//
// يُدير عمليات الخزائن مع حساب الأرصدة من الـ VIEW.
//
// نقطة مهمة جداً:
//   الأرصدة لا تُخزَّن في جدول الخزائن — تُحسَب دائماً من VIEW
//   v_treasury_balances الذي يجمع السندات.
//   هذا يمنع أخطاء التناسق المحاسبية.
//
// TreasuryBalanceRow:
//   كلاس مساعد يمثل صف من VIEW v_treasury_balances.
//   يحتوي على: treasury_id, name, balance_iqd, balance_usd, total_vouchers
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/treasuries_table.dart';
import '../views/treasury_balance_view.dart';

part 'treasuries_dao.g.dart';

// ── نموذج بيانات صف VIEW الأرصدة ─────────────────────────────────────────────

/// يمثل صفاً واحداً من VIEW v_treasury_balances
///
/// يُستخدَم في قوائم الخزائن وبطاقات الرصيد في الـ Dashboard
class TreasuryBalanceRow {
  final int treasuryId;
  final String treasuryName;
  final String treasuryKind;
  final int? entityId;
  final String? entityType;
  final bool isActive;

  /// الرصيد بالدينار العراقي — يمكن أن يكون سالباً (خزينة مدينة)
  final double balanceIqd;

  /// الرصيد بالدولار الأمريكي
  final double balanceUsd;

  /// إجمالي عدد السندات في هذه الخزينة
  final int totalVouchers;

  /// تاريخ آخر سند في هذه الخزينة
  final DateTime? lastVoucherDate;

  const TreasuryBalanceRow({
    required this.treasuryId,
    required this.treasuryName,
    required this.treasuryKind,
    this.entityId,
    this.entityType,
    required this.isActive,
    required this.balanceIqd,
    required this.balanceUsd,
    required this.totalVouchers,
    this.lastVoucherDate,
  });

  /// إنشاء من صف قاعدة بيانات خام
  factory TreasuryBalanceRow.fromRow(QueryRow row) {
    return TreasuryBalanceRow(
      treasuryId: row.data['treasury_id'] as int,
      treasuryName: row.data['treasury_name'] as String,
      treasuryKind: row.data['treasury_kind'] as String,
      entityId: row.data['entity_id'] as int?,
      entityType: row.data['entity_type'] as String?,
      isActive: (row.data['is_active'] as int) == 1,
      balanceIqd: (row.data['balance_iqd'] as num).toDouble(),
      balanceUsd: (row.data['balance_usd'] as num).toDouble(),
      totalVouchers: row.data['total_vouchers'] as int? ?? 0,
      lastVoucherDate: row.data['last_voucher_date'] == null
          ? null
          : DateTime.parse(row.data['last_voucher_date'] as String),
    );
  }
}

/// DAO الخزائن
@DriftAccessor(tables: [Treasuries])
class TreasuriesDao extends DatabaseAccessor<AppDatabase>
    with _$TreasuriesDaoMixin {
  TreasuriesDao(super.db);

  // ── استعلامات الخزائن الأساسية ────────────────────────────────────────────

  /// جميع الخزائن النشطة — Reactive Stream
  Stream<List<Treasury>> watchAllTreasuries() {
    return (select(treasuries)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// جميع الخزائن (Future)
  Future<List<Treasury>> getAllTreasuries() {
    return (select(treasuries)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// خزينة واحدة بالمعرّف
  Future<Treasury?> getTreasuryById(int id) {
    return (select(treasuries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// خزائن حسب النوع (main / contractor / partner)
  Future<List<Treasury>> getTreasuriesByKind(String kind) {
    return (select(treasuries)
          ..where(
            (t) => t.kind.equals(kind) & t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// خزينة مرتبطة بكيان محدد (موظف / مقاول / شريك)
  Future<Treasury?> getTreasuryByEntity(int entityId, String entityType) {
    return (select(treasuries)
          ..where(
            (t) =>
                t.entityId.equals(entityId) &
                t.entityType.equals(entityType) &
                t.isDeleted.equals(false),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  // ── استعلامات الأرصدة من VIEW ─────────────────────────────────────────────

  /// جميع أرصدة الخزائن من VIEW — Reactive Stream
  ///
  /// يتحدث تلقائياً عند أي تغيير في جداول Treasuries أو Vouchers
  Stream<List<TreasuryBalanceRow>> watchTreasuryBalances() {
    return db
        .customSelect(
          kSelectTreasuryBalances,
          // الـ Stream يُعاد توليده عند تغيير الجداول التالية
          readsFrom: {db.treasuries, db.vouchers},
        )
        .watch()
        .map(
          (rows) => rows.map(TreasuryBalanceRow.fromRow).toList(),
        );
  }

  /// رصيد خزينة واحدة من VIEW — Reactive Stream
  Stream<TreasuryBalanceRow?> watchTreasuryBalance(int treasuryId) {
    return db
        .customSelect(
          kSelectTreasuryBalance,
          variables: [Variable.withInt(treasuryId)],
          readsFrom: {db.treasuries, db.vouchers},
        )
        .watchSingleOrNull()
        .map((row) => row == null ? null : TreasuryBalanceRow.fromRow(row));
  }

  /// جلب رصيد خزينة واحدة (Future — للقراءة مرة واحدة)
  Future<TreasuryBalanceRow?> getTreasuryBalance(int treasuryId) async {
    final row = await db
        .customSelect(
          kSelectTreasuryBalance,
          variables: [Variable.withInt(treasuryId)],
          readsFrom: {db.treasuries, db.vouchers},
        )
        .getSingleOrNull();
    return row == null ? null : TreasuryBalanceRow.fromRow(row);
  }

  /// إجمالي الرصيد لجميع الخزائن (للـ Dashboard)
  Future<({double totalIqd, double totalUsd})> getTotalBalance() async {
    final rows = await db
        .customSelect(
          kSelectTreasuryBalances,
          readsFrom: {db.treasuries, db.vouchers},
        )
        .get();
    double iqd = 0;
    double usd = 0;
    for (final row in rows) {
      iqd += (row.data['balance_iqd'] as num).toDouble();
      usd += (row.data['balance_usd'] as num).toDouble();
    }
    return (totalIqd: iqd, totalUsd: usd);
  }

  // ── عمليات الكتابة ────────────────────────────────────────────────────────

  /// إضافة خزينة جديدة — يُعيد الـ ID المُولَّد
  Future<int> insertTreasury(TreasuriesCompanion treasury) {
    return into(treasuries).insert(treasury);
  }

  /// تحديث بيانات خزينة
  Future<bool> updateTreasury(TreasuriesCompanion treasury) {
    return update(treasuries).replace(treasury);
  }

  /// حذف ناعم للخزينة
  ///
  /// لا يُحذَف فعلياً حتى لا تُفقَد السندات المرتبطة بها
  Future<void> softDeleteTreasury(int id) async {
    await (update(treasuries)..where((t) => t.id.equals(id))).write(
      const TreasuriesCompanion(isDeleted: Value(true), isActive: Value(false)),
    );
  }

  /// تفعيل / تعطيل خزينة
  Future<void> setTreasuryActive(int id, {required bool isActive}) async {
    await (update(treasuries)..where((t) => t.id.equals(id))).write(
      TreasuriesCompanion(isActive: Value(isActive)),
    );
  }
}
