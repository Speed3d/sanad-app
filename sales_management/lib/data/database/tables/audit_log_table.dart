// ─────────────────────────────────────────────────────────────────────────────
// audit_log_table.dart — جدول سجل المراجعة (Audit Log)
//
// يُسجَّل هنا كل تغيير في البيانات الحساسة لأغراض المراجعة والمحاسبة.
//
// ما يُسجَّل:
//   - إنشاء / تعديل / حذف السندات
//   - إنشاء / تعديل المستخدمين وصلاحياتهم
//   - إقفال / إعادة فتح السنوات المالية
//   - عمليات النسخ الاحتياطي والاستعادة
//
// تحسينات الأداء:
//   - حقل `diff_gzip`: يخزن الفرق فقط (وليس النسخة الكاملة) مضغوطاً بـ gzip
//     هذا يقلل حجم الجدول بنسبة 70-90% مقارنة بتخزين النص الكامل
//   - Partial Index على (table_name, record_id, created_at)
//   - حذف تلقائي للسجلات الأقدم من 365 يوماً (عبر Archiver)
//
// الأرشفة:
//   السجلات القديمة (> 365 يوم) تُنقَل إلى ملفات ZIP مضغوطة
//   في مجلد التطبيق بدلاً من الحذف الكامل.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

/// جدول سجل المراجعة
class AuditLog extends Table {
  // المعرّف الأساسي
  IntColumn get id => integer().autoIncrement()();

  // المستخدم الذي نفّذ العملية
  IntColumn get userId => integer().named('user_id').nullable()();

  // اسم المستخدم (نسخة للأرشيف — لو حُذف الحساب لاحقاً)
  TextColumn get username =>
      text().withDefault(const Constant('system'))();

  // اسم الجدول المتأثر (مثال: 'vouchers', 'users')
  // تم تسميته affectedTable بدلاً من tableName لتجنب التعارض مع كلمات SQL المحجوزة
  TextColumn get affectedTable => text().named('affected_table')();

  // معرّف السجل المتأثر
  IntColumn get recordId => integer().named('record_id').nullable()();

  // نوع العملية: 'INSERT' | 'UPDATE' | 'DELETE' | 'LOGIN' | 'LOGOUT' | 'FISCAL_CLOSE'
  TextColumn get action => text()();

  // الفرق بين القديم والجديد — مضغوط بـ gzip لتوفير المساحة
  // يُحوَّل إلى Uint8List عند القراءة ثم يُفكّ ضغطه
  BlobColumn get diffGzip => blob().named('diff_gzip').nullable()();

  // عنوان IP (مفيد لاكتشاف الوصول غير المصرح به)
  TextColumn get ipAddress =>
      text().named('ip_address').withDefault(const Constant(''))();

  // معلومات إضافية كـ JSON (مثال: {"screen": "vouchers", "action_detail": "..."})
  TextColumn get metaJson =>
      text().named('meta_json').withDefault(const Constant('{}'))();

  // وقت العملية — مهم للترتيب الزمني
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}
