// ─────────────────────────────────────────────────────────────────────────────
// attachments_dao.dart — DAO المرفقات (Schema v6)
//
// يُدير **فهرس** المرفقات فقط. نسخ الملفات إلى القرص وحذفها مسؤولية
// `AttachmentService` في طبقة `core` — الفصل مقصود:
//   الـ DAO    → ما المرفقات المسجَّلة على هذا الكيان؟
//   الخدمة     → أين يقع الملف فعلاً على القرص وكيف يُفتَح؟
//
// ولهذا الفصل ثمرة عملية: القاعدة تبقى قابلة للاختبار بلا لمس نظام الملفات.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/attachments_table.dart';

part 'attachments_dao.g.dart';

/// أنواع الكيانات التي تقبل مرفقات
///
/// ثوابت لا نصوص حرّة: خطأ إملائي واحد في `'advance'` يُنتج مرفقاً يتيماً
/// لا تصل إليه أي شاشة، ولا يشتكي منه المحلّل.
abstract final class AttachmentEntity {
  /// سلفة مشروع (`Advances`)
  static const String advance = 'advance';

  /// سند (قبض / صرف / تحويل)
  static const String voucher = 'voucher';
}

/// DAO المرفقات
@DriftAccessor(tables: [Attachments])
class AttachmentsDao extends DatabaseAccessor<AppDatabase>
    with _$AttachmentsDaoMixin {
  AttachmentsDao(super.db);

  // ── قراءة ─────────────────────────────────────────────────────────────────

  /// مرفقات كيان محدَّد — تدفّق تفاعلي يتحدّث فور الإرفاق أو الحذف
  ///
  /// [entityType] من [AttachmentEntity] · [entityId] معرّف السلفة أو السند
  Stream<List<Attachment>> watchForEntity({
    required String entityType,
    required int entityId,
  }) {
    return (select(attachments)
          ..where((a) =>
              a.entityType.equals(entityType) & a.entityId.equals(entityId))
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
        .watch();
  }

  /// مرفقات كيان محدَّد (Future)
  Future<List<Attachment>> getForEntity({
    required String entityType,
    required int entityId,
  }) {
    return (select(attachments)
          ..where((a) =>
              a.entityType.equals(entityType) & a.entityId.equals(entityId))
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
        .get();
  }

  /// مرفق واحد بالمعرّف
  Future<Attachment?> getById(int id) {
    return (select(attachments)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  /// عدد مرفقات كيان — لعرض شارة رقمية بلا تحميل الصفوف كلها
  Future<int> countForEntity({
    required String entityType,
    required int entityId,
  }) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM attachments '
      'WHERE entity_type = ? AND entity_id = ?',
      variables: [
        Variable.withString(entityType),
        Variable.withInt(entityId),
      ],
      readsFrom: {attachments},
    ).getSingle();
    return row.data['c'] as int? ?? 0;
  }

  /// البحث عن مرفق بنفس البصمة على الكيان نفسه
  ///
  /// يمنع إرفاق الملف مرّتين بالخطأ — وهو أشيع مما يبدو حين يُرفَق ملف من
  /// مجلد التنزيلات ثم يُعاد إرفاقه بعد إعادة تسميته.
  Future<Attachment?> findDuplicate({
    required String entityType,
    required int entityId,
    required String sha256,
  }) {
    if (sha256.isEmpty) return Future.value(null);
    return (select(attachments)
          ..where((a) =>
              a.entityType.equals(entityType) &
              a.entityId.equals(entityId) &
              a.sha256.equals(sha256))
          ..limit(1))
        .getSingleOrNull();
  }

  /// كل المرفقات — تُستعمَل في النسخة الاحتياطية الشاملة
  Future<List<Attachment>> getAll() {
    return (select(attachments)
          ..orderBy([(a) => OrderingTerm.asc(a.relativePath)]))
        .get();
  }

  /// إجمالي حجم المرفقات بالبايت — لعرضه قبل النسخ الاحتياطي الشامل
  Future<int> totalSizeBytes() async {
    final row = await customSelect(
      'SELECT COALESCE(SUM(size_bytes), 0) AS s FROM attachments',
      readsFrom: {attachments},
    ).getSingle();
    return (row.data['s'] as num?)?.toInt() ?? 0;
  }

  // ── كتابة ─────────────────────────────────────────────────────────────────

  /// تسجيل مرفق جديد — يُعيد معرّفه
  ///
  /// ⚠️ يُستدعى **بعد** نجاح نسخ الملف إلى القرص لا قبله. الترتيب المعاكس
  /// يُنتج صفّاً يشير إلى ملف غير موجود إن فشل النسخ.
  Future<int> insertAttachment(AttachmentsCompanion attachment) {
    return into(attachments).insert(attachment);
  }

  /// حذف مرفق من الفهرس — لا يمسّ الملف على القرص
  ///
  /// حذف الملف مسؤولية `AttachmentService`، ويأتي **بعد** هذا الحذف: لو
  /// حُذف الملف أولاً ثم فشل حذف الصفّ، لبقي فهرس يشير إلى العدم.
  Future<int> deleteAttachment(int id) {
    return (delete(attachments)..where((a) => a.id.equals(id))).go();
  }

  /// حذف كل مرفقات كيان — يُعيد الصفوف المحذوفة ليحذف المستدعي ملفاتها
  ///
  /// **لماذا يُعيد الصفوف؟** لأن العمود `entity_id` بلا مفتاح خارجي (يشير
  /// إلى جدولين حسب `entity_type`)، فلا يوجد حذف تعاقبي تلقائي. حذف سلفة
  /// أو سند دون استدعاء هذه الدالة يترك **مرفقات يتيمة** في الفهرس وملفات
  /// معلّقة على القرص إلى الأبد.
  Future<List<Attachment>> deleteForEntity({
    required String entityType,
    required int entityId,
  }) async {
    final rows = await getForEntity(entityType: entityType, entityId: entityId);
    if (rows.isEmpty) return const [];
    await (delete(attachments)
          ..where((a) =>
              a.entityType.equals(entityType) & a.entityId.equals(entityId)))
        .go();
    return rows;
  }
}
