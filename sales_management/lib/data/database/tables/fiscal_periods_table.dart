// ─────────────────────────────────────────────────────────────────────────────
// fiscal_periods_table.dart — جدول الفترات المالية (السنوات المالية)
//
// يدير هذا الجدول السنوات المالية وحالاتها.
//
// حالات السنة المالية:
//   'active'           — نشطة: تقبل سندات جديدة
//   'frozen'           — مقفلة: لا تقبل تعديلات (بعد إجراء الإقفال)
//   'frozen_pending_recompute' — مقفلة لكن تحتاج إعادة احتساب
//                                (عند إعادة فتح سنة سابقة)
//
// منطق الانتقال السلس بين السنوات:
//   - في 1 يناير: تُنشَأ سنة جديدة تلقائياً بحالة 'active'
//   - السنة القديمة تبقى 'active' حتى يُغلقها المدير يدوياً
//   - كلتا السنتين تقبلان سندات في نفس الوقت
//   - السند يُنسَب للفترة حسب تاريخه وليس حسب وقت الإدخال
//
// جدول `voucher_sequences`:
//   يُخزَّن في نفس هذا الملف لأنه مرتبط بالفترات المالية ارتباطاً وثيقاً.
//   يُستخدم للحصول على رقم السند التالي بشكل آمن (Atomic).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

/// جدول الفترات المالية
class FiscalPeriods extends Table {
  // المعرّف الأساسي
  IntColumn get id => integer().autoIncrement()();

  // اسم الفترة — مثل: '2025' أو '2025-Q1'
  TextColumn get name => text().withLength(min: 1, max: 50)();

  // نوع الفترة — 'yearly' (حالياً) — قابل للتوسع لـ 'monthly', 'quarterly'
  TextColumn get periodType =>
      text().named('period_type').withDefault(const Constant('yearly'))();

  // تاريخ بداية الفترة
  DateTimeColumn get startDate => dateTime().named('start_date')();

  // تاريخ نهاية الفترة (آخر يوم في الفترة)
  DateTimeColumn get endDate => dateTime().named('end_date')();

  // حالة الفترة: active | frozen | frozen_pending_recompute
  TextColumn get status =>
      text().withDefault(const Constant('active'))();

  // وقت إقفال الفترة — null إذا لم تُقفَل بعد
  DateTimeColumn get closedAt => dateTime().named('closed_at').nullable()();

  // من أجرى الإقفال؟ (User ID)
  IntColumn get closedByUserId =>
      integer().named('closed_by_user_id').nullable()();

  // ملاحظات على الفترة (اختياري)
  TextColumn get notes => text().withDefault(const Constant(''))();

  // وقت الإنشاء
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}

/// جدول تسلسل أرقام السندات — يضمن عدم تكرار رقم السند
///
/// كيف يعمل (Atomic Increment):
///   بدلاً من MAX(voucher_number) + 1 (غير آمن عند التزامن)،
///   نستخدم:
///     UPDATE voucher_sequences
///     SET last_number = last_number + 1
///     WHERE fiscal_period_id = ? AND voucher_type = ?
///     RETURNING last_number;
///
/// هذا يضمن 100% عدم التكرار حتى مع عدة مستخدمين في وقت واحد.
class VoucherSequences extends Table {
  // المفتاح الخارجي للفترة المالية
  IntColumn get fiscalPeriodId =>
      integer().named('fiscal_period_id').references(FiscalPeriods, #id)();

  // نوع السند: 'sarf' (صرف) | 'kabd' (قبض)
  TextColumn get voucherType => text().named('voucher_type')();

  // آخر رقم استُخدِم (يبدأ من 0)
  IntColumn get lastNumber =>
      integer().named('last_number').withDefault(const Constant(0))();

  @override
  // المفتاح الأساسي المركّب: فترة + نوع سند
  Set<Column> get primaryKey => {fiscalPeriodId, voucherType};
}
