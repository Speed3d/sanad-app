// ─────────────────────────────────────────────────────────────────────────────
// partners_dao.dart — DAO الشركاء
//
// يُدير عمليات الشركاء (أصحاب الحصص) CRUD.
//
// القاعدة الذهبية:
//   مجموع حصص جميع الشركاء يجب ألا يتجاوز 100%
//   هذا يُتحقق منه في طبقة الـ Domain (Repository) وليس هنا.
//   الـ DAO لا يُنفّذ هذه القاعدة — يثق بالطبقة الأعلى.
//
// العلاقات:
//   - كل شريك قد يرتبط بخزينة واحدة (treasury_id اختياري)
//   - سجلات السندات تُقرأ من VouchersDao عبر treasury_id
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/partners_table.dart';

part 'partners_dao.g.dart';

/// DAO الشركاء
@DriftAccessor(tables: [Partners])
class PartnersDao extends DatabaseAccessor<AppDatabase>
    with _$PartnersDaoMixin {
  PartnersDao(super.db);

  // ── استعلامات القراءة ────────────────────────────────────────────────────

  /// جميع الشركاء النشطين — Reactive Stream مرتب أبجدياً
  ///
  /// يتحدث تلقائياً عند أي تغيير في جدول Partners
  Stream<List<Partner>> watchAllPartners() {
    return (select(partners)
          ..where((p) => p.isDeleted.equals(false))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  /// جميع الشركاء النشطين (Future)
  Future<List<Partner>> getAllPartners() {
    return (select(partners)
          ..where((p) => p.isDeleted.equals(false))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  /// شريك واحد بالمعرّف
  Future<Partner?> getPartnerById(int id) {
    return (select(partners)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// شريك مرتبط بخزينة محددة
  ///
  /// يُستخدَم عند عرض تفاصيل الخزينة لمعرفة الشريك المالك
  Future<Partner?> getPartnerByTreasury(int treasuryId) {
    return (select(partners)
          ..where(
            (p) =>
                p.treasuryId.equals(treasuryId) & p.isDeleted.equals(false),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  /// بحث نصي في أسماء الشركاء وأرقام هواتفهم
  Future<List<Partner>> searchPartners(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(partners)
          ..where(
            (p) =>
                p.isDeleted.equals(false) &
                (p.name.lower().like(q) | p.phone.lower().like(q)),
          )
          ..orderBy([(p) => OrderingTerm.asc(p.name)])
          ..limit(50))
        .get();
  }

  /// إجمالي الحصص المُخصَّصة لجميع الشركاء النشطين
  ///
  /// يُستخدَم للتحقق من أن مجموع الحصص لا يتجاوز 100%
  /// قبل إضافة أو تعديل شريك
  Future<double> getTotalSharePercentage() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(share_percentage), 0) as total '
      'FROM partners WHERE is_deleted = 0 AND is_active = 1',
      readsFrom: {partners},
    ).getSingle();
    return (result.data['total'] as num).toDouble();
  }

  /// عدد الشركاء النشطين — للـ Dashboard
  Future<int> countActivePartners() async {
    final result = await customSelect(
      'SELECT COUNT(*) as cnt FROM partners '
      'WHERE is_deleted = 0 AND is_active = 1',
      readsFrom: {partners},
    ).getSingle();
    return result.data['cnt'] as int;
  }

  // ── عمليات الكتابة ────────────────────────────────────────────────────────

  /// إضافة شريك جديد — يُعيد الـ ID المُولَّد
  Future<int> insertPartner(PartnersCompanion partner) {
    return into(partners).insert(partner);
  }

  /// تحديث بيانات شريك (بما فيها نسبة الحصة)
  Future<bool> updatePartner(PartnersCompanion partner) {
    return update(partners).replace(partner);
  }

  /// ربط شريك بخزينة
  ///
  /// [partnerId]  — معرّف الشريك
  /// [treasuryId] — معرّف الخزينة (null = فك الارتباط)
  Future<void> linkPartnerToTreasury(int partnerId, int? treasuryId) async {
    await (update(partners)..where((p) => p.id.equals(partnerId))).write(
      PartnersCompanion(treasuryId: Value(treasuryId)),
    );
  }

  /// تحديث نسبة حصة شريك فقط
  ///
  /// عملية مستقلة لأنها تحتاج تحقق من المجموع الكلي في الطبقة الأعلى
  Future<void> updateSharePercentage(int id, double sharePercentage) async {
    await (update(partners)..where((p) => p.id.equals(id))).write(
      PartnersCompanion(sharePercentage: Value(sharePercentage)),
    );
  }

  /// حذف ناعم للشريك
  ///
  /// لا يُحذَف فعلياً لحفظ سجل المعاملات والتوزيعات التاريخية
  Future<void> softDeletePartner(int id) async {
    await (update(partners)..where((p) => p.id.equals(id))).write(
      const PartnersCompanion(
        isDeleted: Value(true),
        isActive: Value(false),
      ),
    );
  }

  /// تفعيل / تعطيل شريك
  Future<void> setPartnerActive(int id, {required bool isActive}) async {
    await (update(partners)..where((p) => p.id.equals(id))).write(
      PartnersCompanion(isActive: Value(isActive)),
    );
  }
}
