// ─────────────────────────────────────────────────────────────────────────────
// audit_log_dao.dart — DAO سجل المراجعة (Audit Log)
//
// يُدير تسجيل وقراءة وأرشفة أحداث النظام الحساسة.
//
// الغرض الأساسي:
//   كل تغيير في بيانات حساسة (سندات، مستخدمون، إقفال مالي) يُسجَّل هنا
//   مع معرّف المستخدم ووقت التغيير والفرق (diff) بين القديم والجديد.
//
// الـ diff_gzip:
//   يُخزَّن الفرق بصيغة JSON مضغوطة بـ gzip:
//   {"before": {...}, "after": {...}}
//   يقلل الحجم بنسبة 70-90% مقارنة بالنص الخام.
//
// الأرشفة:
//   archiveOldRecords() يُزيل السجلات الأقدم من [daysToKeep] يوماً
//   من الجدول (تُنقَل للأرشيف في طبقة أعلى — Sprint 12).
//
// الترقيم (Pagination):
//   كل الاستعلامات تدعم [limit] و[offset] لتجنب تحميل آلاف السجلات دفعةً
// ─────────────────────────────────────────────────────────────────────────────

// dart:typed_data مُدرَج ضمن package:drift/drift.dart — لا حاجة لاستيراده منفرداً
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/audit_log_table.dart';

part 'audit_log_dao.g.dart';

// ── نموذج بيانات سجل مراجعة مُفسَّر ─────────────────────────────────────────

/// سجل مراجعة مُفسَّر — يُستخدَم في شاشة Audit Log
class AuditLogEntry {
  /// بيانات السجل الأصلية
  final AuditLogData data;

  /// الفرق مُفكَّك الضغط (JSON نصي) — null إذا لم يكن هناك diff
  final String? diffJson;

  const AuditLogEntry({required this.data, this.diffJson});
}

/// DAO سجل المراجعة
@DriftAccessor(tables: [AuditLog])
class AuditLogDao extends DatabaseAccessor<AppDatabase>
    with _$AuditLogDaoMixin {
  AuditLogDao(super.db);

  // ── استعلامات القراءة ────────────────────────────────────────────────────

  /// آخر [limit] سجل بترتيب زمني عكسي — للـ Dashboard الأمني
  ///
  /// [limit]  — عدد السجلات (افتراضي: 50)
  /// [offset] — الإزاحة للـ Pagination
  Future<List<AuditLogData>> getRecentLogs({
    int limit = 50,
    int offset = 0,
  }) {
    return (select(auditLog)
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Reactive Stream لآخر [limit] سجل — لشاشة المراقبة الحية
  Stream<List<AuditLogData>> watchRecentLogs({int limit = 100}) {
    return (select(auditLog)
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
          ..limit(limit))
        .watch();
  }

  /// سجلات مستخدم معين — لصفحة تفاصيل المستخدم
  Future<List<AuditLogData>> getLogsByUser(
    int userId, {
    int limit = 100,
    int offset = 0,
  }) {
    return (select(auditLog)
          ..where((l) => l.userId.equals(userId))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// سجلات جدول معين — مثال: جميع التغييرات على 'vouchers'
  ///
  /// [tableName] — اسم الجدول المتأثر
  /// [recordId]  — معرّف السجل المحدد (null = جميع السجلات في الجدول)
  Future<List<AuditLogData>> getLogsByTable(
    String tableName, {
    int? recordId,
    int limit = 100,
    int offset = 0,
  }) {
    return (select(auditLog)
          ..where((l) {
            Expression<bool> condition = l.affectedTable.equals(tableName);
            if (recordId != null) {
              condition = condition & l.recordId.equals(recordId);
            }
            return condition;
          })
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// سجلات ضمن نطاق زمني — للتقارير الدورية
  Future<List<AuditLogData>> getLogsByDateRange({
    required DateTime from,
    required DateTime to,
    String? action,
    int limit = 500,
    int offset = 0,
  }) {
    return (select(auditLog)
          ..where((l) {
            // الشرط الأساسي: نطاق التاريخ
            Expression<bool> condition =
                l.createdAt.isBetweenValues(from, to);

            // فلتر نوع العملية (اختياري)
            if (action != null) {
              condition = condition & l.action.equals(action);
            }
            return condition;
          })
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// عدد السجلات الكلي — للـ Pagination في شاشة Audit Log
  Future<int> countLogs() async {
    final result = await customSelect(
      'SELECT COUNT(*) as cnt FROM audit_log',
      readsFrom: {auditLog},
    ).getSingle();
    return result.data['cnt'] as int;
  }

  // ── عمليات الكتابة ────────────────────────────────────────────────────────

  /// تسجيل حدث جديد في سجل المراجعة
  ///
  /// الاستخدام الأمثل: استدعاء هذه الدالة من طبقة Repository بعد كل عملية
  Future<int> insertLog(AuditLogCompanion entry) {
    return into(auditLog).insert(entry);
  }

  /// تسجيل حدث بدون diff — للأحداث البسيطة (تسجيل دخول، خروج)
  ///
  /// [userId]    — معرّف المستخدم
  /// [username]  — اسم المستخدم (للأرشيف)
  /// [table]     — الجدول المتأثر أو وصف الحدث
  /// [action]    — 'LOGIN' | 'LOGOUT' | 'FISCAL_CLOSE' | ...
  /// [meta]      — بيانات JSON إضافية اختياري
  Future<int> logSimpleAction({
    int? userId,
    required String username,
    required String table,
    required String action,
    int? recordId,
    String meta = '{}',
  }) {
    return insertLog(
      AuditLogCompanion.insert(
        userId: Value(userId),
        username: Value(username),
        affectedTable: table,
        recordId: Value(recordId),
        action: action,
        metaJson: Value(meta),
      ),
    );
  }

  /// تسجيل حدث مع diff مضغوط
  ///
  /// [diffGzipBytes] — الـ diff بصيغة JSON مضغوطة بـ gzip
  ///   يُحضَّر في طبقة Repository باستخدام dart:io GZipCodec
  Future<int> logWithDiff({
    int? userId,
    required String username,
    required String table,
    required String action,
    int? recordId,
    required Uint8List diffGzipBytes,
    String meta = '{}',
  }) {
    return insertLog(
      AuditLogCompanion.insert(
        userId: Value(userId),
        username: Value(username),
        affectedTable: table,
        recordId: Value(recordId),
        action: action,
        diffGzip: Value(diffGzipBytes),
        metaJson: Value(meta),
      ),
    );
  }

  // ── الأرشفة والتنظيف ────────────────────────────────────────────────────

  /// جلب السجلات القديمة للأرشفة
  ///
  /// [daysToKeep] — الاحتفاظ بسجلات آخر [daysToKeep] يوماً فقط
  ///   السجلات الأقدم من ذلك تُنقَل للأرشيف (Sprint 12)
  Future<List<AuditLogData>> getLogsForArchive({
    int daysToKeep = 365,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    return (select(auditLog)
          ..where((l) => l.createdAt.isSmallerThanValue(cutoffDate))
          ..orderBy([(l) => OrderingTerm.asc(l.createdAt)]))
        .get();
  }

  /// حذف السجلات القديمة من الجدول بعد أرشفتها
  ///
  /// يُستدعى فقط بعد التأكد من نجاح عملية الأرشفة
  /// [beforeDate] — تاريخ الحد الفاصل — تُحذَف كل ما قبله
  Future<int> deleteLogsBeforeDate(DateTime beforeDate) {
    return (delete(auditLog)
          ..where((l) => l.createdAt.isSmallerThanValue(beforeDate)))
        .go();
  }

  /// عدد السجلات الأقدم من [daysToKeep] يوماً — لمؤشر الأرشفة في الـ Dashboard
  Future<int> countOldLogs({int daysToKeep = 365}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final result = await customSelect(
      'SELECT COUNT(*) as cnt FROM audit_log WHERE created_at < ?',
      variables: [Variable.withDateTime(cutoffDate)],
      readsFrom: {auditLog},
    ).getSingle();
    return result.data['cnt'] as int;
  }
}
