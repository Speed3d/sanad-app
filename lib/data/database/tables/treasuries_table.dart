// ─────────────────────────────────────────────────────────────────────────────
// treasuries_table.dart — جدول الخزائن الموحد
//
// بدلاً من 3 جداول منفصلة (خزينة رئيسية، خزينة مقاولين، خزينة شركاء)،
// استخدمنا جدول واحد موحد مع حقل `kind` لتمييز النوع.
//
// هذا يوفر:
//   ✓ استعلامات أبسط للتقارير الموحدة
//   ✓ سهولة إضافة أنواع خزائن جديدة مستقبلاً
//   ✓ ربط الخزائن بالكيانات (موظف، مقاول، شريك) من جدول واحد
//
// حقول الربط الاختياري:
//   يمكن ربط الخزينة بكيان محدد (موظف / مقاول / شريك)
//   أو تركها بدون ربط (خزينة عامة)
//
// تنبيه مهم:
//   الأرصدة لا تُخزَّن هنا — تُحسَب دائماً من الـ VIEW
//   راجع: v_treasury_balances في ملف app_database_views.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

/// جدول الخزائن الموحد
class Treasuries extends Table {
  // المعرّف الأساسي
  IntColumn get id => integer().autoIncrement()();

  // اسم الخزينة — مثل: 'الخزينة الرئيسية', 'خزينة المشاريع'
  TextColumn get name => text().withLength(min: 1, max: 100)();

  // نوع الخزينة:
  //   'main'       — خزينة رئيسية عامة
  //   'contractor' — خزينة مقاول
  //   'partner'    — خزينة شريك
  TextColumn get kind =>
      text().withDefault(const Constant('main'))();

  // ربط اختياري بكيان محدد (معرّف الكيان)
  // مثال: إذا kind='contractor' هنا يكون معرّف المقاول
  IntColumn get entityId => integer().named('entity_id').nullable()();

  // نوع الكيان المرتبط: 'employee' | 'contractor' | 'partner' | null
  TextColumn get entityType => text().named('entity_type').nullable()();

  // هل الخزينة نشطة؟
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  // ملاحظات
  TextColumn get notes => text().withDefault(const Constant(''))();

  // وقت الإنشاء
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  // حذف ناعم
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
}
