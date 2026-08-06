// ─────────────────────────────────────────────────────────────────────────────
// users_table.dart — جدول المستخدمين
//
// يخزن بيانات مستخدمي النظام مع صلاحياتهم.
//
// الأدوار المتاحة:
//   'super_admin' — مدير النظام: صلاحيات كاملة، لا يمكن حذف آخر واحد
//   'admin'       — مدير: معظم الصلاحيات ما عدا إدارة المستخدمين الحساسة
//   'user'        — مستخدم عادي: صلاحيات محددة حسب الـ permissions JSON
//
// حقل `permissions_json`:
//   JSON يحتوي على 20 صلاحية دقيقة مثل:
//   {"can_view_reports": true, "can_delete_voucher": false, ...}
//
// حقل `failed_login_attempts`:
//   عدد محاولات الدخول الفاشلة — بعد 5 يُقفَل الحساب لـ 15 دقيقة
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

/// جدول المستخدمين في قاعدة البيانات
class Users extends Table {
  // المعرّف الأساسي — يتولد تلقائياً
  IntColumn get id => integer().autoIncrement()();

  // اسم المستخدم للدخول — فريد ولا يتكرر
  TextColumn get username =>
      text().withLength(min: 3, max: 50).unique()();

  // كلمة المرور مُشفَّرة بـ bcrypt (لا تُخزَّن نصاً)
  TextColumn get passwordHash => text().named('password_hash')();

  // الاسم الكامل للمستخدم
  TextColumn get fullName => text().withLength(min: 1, max: 100).named('full_name')();

  // الدور: super_admin | admin | user
  TextColumn get role => text().withDefault(const Constant('user'))();

  // صلاحيات تفصيلية كـ JSON — خاصة بدور user
  // مثال: {"can_view_reports": true, "can_delete_voucher": false}
  TextColumn get permissionsJson =>
      text().named('permissions_json').withDefault(const Constant('{}'))();

  // حالة الحساب: هل هو نشط؟
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  // عدد محاولات الدخول الفاشلة (إعادة التعيين عند النجاح)
  IntColumn get failedLoginAttempts =>
      integer().named('failed_login_attempts').withDefault(const Constant(0))();

  // وقت قفل الحساب — null إذا لم يكن مقفلاً
  DateTimeColumn get lockedUntil =>
      dateTime().named('locked_until').nullable()();

  // آخر وقت دخول ناجح
  DateTimeColumn get lastLoginAt =>
      dateTime().named('last_login_at').nullable()();

  // وقت إنشاء الحساب
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  // هل تم الحذف الناعم (Soft Delete)؟
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
}
