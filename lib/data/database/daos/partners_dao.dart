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
import '../tables/treasuries_table.dart';

part 'partners_dao.g.dart';

/// DAO الشركاء
@DriftAccessor(tables: [Partners, Treasuries])
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

  /// إضافة شريك **مع خزينته** — معاملة واحدة ذرّية
  ///
  /// راجع `ContractorsDao.insertContractorWithTreasury` للشرح الكامل: الميزة
  /// كانت **واجهةً لبيانات لا يمكن أن توجد** حتى قرار المالك 2026-09-01.
  Future<int> insertPartnerWithTreasury(
    PartnersCompanion partner, {
    String? treasuryName,
    int? existingTreasuryId,
  }) {
    return transaction(() async {
      final id = await into(partners).insert(partner);

      var treasuryId = existingTreasuryId;
      if (treasuryId == null && treasuryName != null) {
        treasuryId = await into(treasuries).insert(
          TreasuriesCompanion.insert(
            name: treasuryName,
            kind: const Value('partner'),
            entityId: Value(id),
            entityType: const Value('partner'),
          ),
        );
      } else if (treasuryId != null) {
        await (update(treasuries)..where((t) => t.id.equals(treasuryId!)))
            .write(TreasuriesCompanion(
          kind: const Value('partner'),
          entityId: Value(id),
          entityType: const Value('partner'),
        ));
      }

      if (treasuryId != null) {
        await (update(partners)..where((p) => p.id.equals(id)))
            .write(PartnersCompanion(treasuryId: Value(treasuryId)));
      }
      return id;
    });
  }

  /// تحديث بيانات شريك (بما فيها نسبة الحصة) — تحديث جزئي للحقول الحاضرة فقط
  ///
  /// write بدل replace: يمنع إعادة is_deleted/created_at إلى قيمها الافتراضية.
  Future<bool> updatePartner(PartnersCompanion partner) async {
    final count = await (update(partners)
          ..where((p) => p.id.equals(partner.id.value)))
        .write(partner);
    return count > 0;
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

  /// حذف ناعم للشريك **وخزينته معاً** — في معاملة واحدة
  ///
  /// نسخة الشريك من ع-٥٧ — والشرح الكامل في
  /// `ContractorsDao.softDeleteContractorWithTreasury`.
  ///
  /// 📌 **ولماذا يُصلَح البابان معاً في الالتزام نفسه؟** لأن إصلاح باب
  ///   وترك أخيه هو **عين** العلّة التي أنتجت ع-٢٨ و ع-٣١ و ع-٣٣: ثلاثة
  ///   أعطال متتالية من فئة واحدة، كلٌّ منها بابٌ نُسي بعد إصلاح جاره.
  Future<bool> softDeletePartnerWithTreasury(int id) {
    return transaction(() async {
      final row = await (select(partners)..where((p) => p.id.equals(id)))
          .getSingleOrNull();
      final treasuryId = row?.treasuryId;

      if (treasuryId != null) {
        final count = await customSelect(
          'SELECT COUNT(*) AS c FROM vouchers '
          'WHERE treasury_id = ? AND is_deleted = 0',
          variables: [Variable.withInt(treasuryId)],
        ).getSingle();

        if ((count.data['c'] as int? ?? 0) > 0) {
          throw StateError(
            'لا يمكن حذف هذا الشريك: خزينته فيها سندات مسجَّلة.\n'
            'عطّله بدلاً من ذلك — فيبقى سجل معاملاته سليماً.',
          );
        }
      }

      await (update(partners)..where((p) => p.id.equals(id))).write(
        const PartnersCompanion(
          isDeleted: Value(true),
          isActive: Value(false),
        ),
      );

      if (treasuryId != null) {
        await (update(treasuries)..where((t) => t.id.equals(treasuryId)))
            .write(const TreasuriesCompanion(
          isDeleted: Value(true),
          isActive: Value(false),
        ));
      }
      return treasuryId != null;
    });
  }

  /// تفعيل / تعطيل شريك
  Future<void> setPartnerActive(int id, {required bool isActive}) async {
    await (update(partners)..where((p) => p.id.equals(id))).write(
      PartnersCompanion(isActive: Value(isActive)),
    );
  }
}
