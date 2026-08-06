// ─────────────────────────────────────────────────────────────────────────────
// app_settings_table.dart — جدول إعدادات التطبيق
//
// يخزن الإعدادات العامة للنظام كأزواج (مفتاح → قيمة).
//
// مفاتيح مهمة:
//   'company_name'      — اسم الشركة
//   'language'          — اللغة: 'ar' أو 'en'
//   'theme'             — المظهر: 'light' | 'dark' | 'system'
//   'primary_currency'  — العملة الأساسية: 'IQD'
//   'secondary_currency'— العملة الثانوية: 'USD'
//   'exchange_rate'     — سعر الصرف الحالي
//
// ملاحظة مهمة:
//   الشعار (اللوجو) لا يُخزَّن هنا — يُخزَّن في جدول `app_blobs` منفصل
//   لتجنب تحميل بيانات ثنائية كبيرة في كل query للإعدادات.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

/// جدول إعدادات النظام (مفتاح → قيمة)
class AppSettings extends Table {
  // المفتاح — فريد ويُستخدَم كمعرّف
  TextColumn get key => text().withLength(min: 1, max: 100)();

  // القيمة — نص مرن (أرقام، JSON، نصوص)
  TextColumn get value => text().withDefault(const Constant(''))();

  // وصف الإعداد (لأغراض التوثيق فقط)
  TextColumn get description => text().withDefault(const Constant(''))();

  // وقت آخر تحديث
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  // المفتاح الأساسي هو حقل key وليس id
  Set<Column> get primaryKey => {key};
}

/// جدول منفصل لتخزين البيانات الثنائية (الشعار)
///
/// السبب: لو خزّنّا الشعار في app_settings، كل query للإعدادات ستحمّل
/// صورة بحجم 100-500KB وهذا يُبطئ التطبيق.
/// الحل: جدول منفصل يُستعلَم فقط عند الحاجة.
class AppBlobs extends Table {
  // المفتاح — مثل: 'company_logo'
  TextColumn get key => text().withLength(min: 1, max: 100)();

  // البيانات الثنائية (الصورة)
  BlobColumn get data => blob()();

  // نوع MIME — مثل: 'image/png', 'image/jpeg'
  TextColumn get mimeType =>
      text().named('mime_type').withDefault(const Constant('image/png'))();

  // وقت آخر تحديث
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}
