// ─────────────────────────────────────────────────────────────────────────────
// contractors_dao.dart — DAO المقاولين
//
// يُدير عمليات المقاولين CRUD مع إمكانية البحث والفلترة.
//
// العلاقات:
//   - كل مقاول قد يرتبط بخزينة واحدة (treasury_id اختياري)
//   - سجلات السندات المرتبطة بالمقاول تُقرأ من VouchersDao
//
// ملاحظة:
//   `getTreasuriesByKind('contractor')` في TreasuriesDao يكمل هذا الـ DAO
//   عند عرض رصيد حساب المقاول.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/contractors_table.dart';
import '../tables/treasuries_table.dart';

part 'contractors_dao.g.dart';

/// DAO المقاولين
@DriftAccessor(tables: [Contractors, Treasuries])
class ContractorsDao extends DatabaseAccessor<AppDatabase>
    with _$ContractorsDaoMixin {
  ContractorsDao(super.db);

  // ── استعلامات القراءة ────────────────────────────────────────────────────

  /// جميع المقاولين النشطين — Reactive Stream مرتب أبجدياً
  ///
  /// يتحدث تلقائياً عند أي تغيير في جدول Contractors
  Stream<List<Contractor>> watchAllContractors() {
    return (select(contractors)
          ..where((c) => c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  /// جميع المقاولين النشطين (Future)
  Future<List<Contractor>> getAllContractors() {
    return (select(contractors)
          ..where((c) => c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
  }

  /// مقاول واحد بالمعرّف
  Future<Contractor?> getContractorById(int id) {
    return (select(contractors)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// مقاول مرتبط بخزينة محددة
  ///
  /// يُستخدَم عند عرض بطاقة الخزينة لمعرفة المقاول المالك
  Future<Contractor?> getContractorByTreasury(int treasuryId) {
    return (select(contractors)
          ..where(
            (c) =>
                c.treasuryId.equals(treasuryId) & c.isDeleted.equals(false),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  /// فلترة المقاولين حسب النوع (individual / company)
  Future<List<Contractor>> getContractorsByType(String contractorType) {
    return (select(contractors)
          ..where(
            (c) =>
                c.contractorType.equals(contractorType) &
                c.isDeleted.equals(false),
          )
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
  }

  /// بحث نصي في أسماء المقاولين وأرقام هواتفهم
  ///
  /// يبحث في الاسم وكلا الهاتفين — يُعيد أقصى 50 نتيجة
  Future<List<Contractor>> searchContractors(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(contractors)
          ..where(
            (c) =>
                c.isDeleted.equals(false) &
                (c.name.lower().like(q) |
                    c.phone1.lower().like(q) |
                    c.phone2.lower().like(q)),
          )
          ..orderBy([(c) => OrderingTerm.asc(c.name)])
          ..limit(50))
        .get();
  }

  /// عدد المقاولين النشطين — للـ Dashboard
  Future<int> countActiveContractors() async {
    final result = await customSelect(
      'SELECT COUNT(*) as cnt FROM contractors '
      'WHERE is_deleted = 0 AND is_active = 1',
      readsFrom: {contractors},
    ).getSingle();
    return result.data['cnt'] as int;
  }

  // ── عمليات الكتابة ────────────────────────────────────────────────────────

  /// إضافة مقاول جديد — يُعيد الـ ID المُولَّد
  Future<int> insertContractor(ContractorsCompanion contractor) {
    return into(contractors).insert(contractor);
  }

  /// إضافة مقاول **مع خزينته** — معاملة واحدة ذرّية
  ///
  /// 🔑 **الميزة التي وُصلت أخيراً** (قرار المالك 2026-09-01): كان
  ///   `contractors.treasury_id` يبقى `NULL` **أبداً** لأن واجهة الإنشاء لا
  ///   تمرّره، و`kind` ثابت `'main'` عند إنشاء أي خزينة. فتبويبا الفلترة
  ///   «مقاولون/شركاء» في شاشة الخزائن وشاراتهما كانا **واجهةً لبيانات لا
  ///   يمكن أن توجد** — وهو ع-٠٦ في أوسع صوره: ميزةٌ كاملة معروضة ومعطَّلة.
  ///
  /// [treasuryName] — اسم خزينةٍ تُنشَأ له · `null` ⇒ لا خزينة جديدة
  /// [existingTreasuryId] — ربطٌ بخزينة قائمة بدل إنشاء واحدة
  ///
  /// ⚠️ **معاملة واحدة**: مقاولٌ بلا خزينته أو خزينةٌ بلا صاحبها نصفُ
  ///   عملية — والنصف هنا يظهر في شاشة الخزائن ببطاقة «حساب مقاول» بلا
  ///   مقاول، أو بتبويبٍ فارغ رغم وجود المقاول.
  Future<int> insertContractorWithTreasury(
    ContractorsCompanion contractor, {
    String? treasuryName,
    int? existingTreasuryId,
  }) {
    return transaction(() async {
      final id = await into(contractors).insert(contractor);

      var treasuryId = existingTreasuryId;
      if (treasuryId == null && treasuryName != null) {
        treasuryId = await into(treasuries).insert(
          TreasuriesCompanion.insert(
            name: treasuryName,
            kind: const Value('contractor'),
            entityId: Value(id),
            entityType: const Value('contractor'),
          ),
        );
      } else if (treasuryId != null) {
        // خزينةٌ قائمة تصير حساب مقاول — وإلا بقيت «رئيسية» في كل تبويب
        // وشارة، فيُربَط المقاول بها ولا يراه أحد
        await (update(treasuries)..where((t) => t.id.equals(treasuryId!)))
            .write(TreasuriesCompanion(
          kind: const Value('contractor'),
          entityId: Value(id),
          entityType: const Value('contractor'),
        ));
      }

      if (treasuryId != null) {
        await (update(contractors)..where((c) => c.id.equals(id)))
            .write(ContractorsCompanion(treasuryId: Value(treasuryId)));
      }
      return id;
    });
  }

  /// تحديث بيانات مقاول — تحديث جزئي للحقول الحاضرة فقط
  ///
  /// write بدل replace: يمنع إعادة is_deleted/created_at إلى قيمها الافتراضية.
  Future<bool> updateContractor(ContractorsCompanion contractor) async {
    final count = await (update(contractors)
          ..where((c) => c.id.equals(contractor.id.value)))
        .write(contractor);
    return count > 0;
  }

  /// ربط مقاول بخزينة
  ///
  /// [contractorId] — معرّف المقاول
  /// [treasuryId]   — معرّف الخزينة (null = فك الارتباط)
  Future<void> linkContractorToTreasury(
    int contractorId,
    int? treasuryId,
  ) async {
    await (update(contractors)
          ..where((c) => c.id.equals(contractorId)))
        .write(ContractorsCompanion(treasuryId: Value(treasuryId)));
  }

  /// حذف ناعم للمقاول
  ///
  /// لا يُحذَف فعلياً لحفظ سجل المعاملات التاريخية
  Future<void> softDeleteContractor(int id) async {
    await (update(contractors)..where((c) => c.id.equals(id))).write(
      const ContractorsCompanion(
        isDeleted: Value(true),
        isActive: Value(false),
      ),
    );
  }

  /// تفعيل / تعطيل مقاول
  Future<void> setContractorActive(int id, {required bool isActive}) async {
    await (update(contractors)..where((c) => c.id.equals(id))).write(
      ContractorsCompanion(isActive: Value(isActive)),
    );
  }
}
