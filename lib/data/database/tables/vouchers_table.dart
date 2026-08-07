// ─────────────────────────────────────────────────────────────────────────────
// vouchers_table.dart — جدول السندات الموحد
//
// يحتوي على سندات القبض والصرف وأرصدة الافتتاح في جدول واحد.
// هذا يبسّط التقارير والاستعلامات ويضمن اتساق البيانات.
//
// أنواع السندات (voucher_type):
//   'sarf'            — سند صرف (دفع مبلغ من الخزينة)
//   'kabd'            — سند قبض (استلام مبلغ للخزينة)
//   'opening_balance' — رصيد افتتاحي (عند إقفال السنة المالية)
//   'transfer_out'    — تحويل صادر من خزينة
//   'transfer_in'     — تحويل وارد إلى خزينة
//
// معادلة الرصيد (المُحسَبة في VIEW):
//   رصيد IQD = مجموع(kabd+opening_balance حيث currency='IQD')
//             - مجموع(sarf حيث currency='IQD')
//
// هام:
//   الرصيد لا يُخزَّن في هذا الجدول — يُحسَب من الـ VIEW
//   هذا يمنع أخطاء التناسق في البيانات المحاسبية
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import 'treasuries_table.dart';
import 'fiscal_periods_table.dart';

/// جدول السندات الموحد (صرف + قبض + أرصدة افتتاحية)
class Vouchers extends Table {
  // المعرّف الأساسي
  IntColumn get id => integer().autoIncrement()();

  // رقم السند المُولَّد من VoucherSequences (مثل: 1, 2, 3...)
  IntColumn get voucherNumber => integer().named('voucher_number')();

  // نوع السند: sarf | kabd | opening_balance | transfer_out | transfer_in
  TextColumn get voucherType => text().named('voucher_type')();

  // الخزينة المرتبطة بالسند
  IntColumn get treasuryId =>
      integer().named('treasury_id').references(Treasuries, #id)();

  // الفترة المالية — تُحدَّد حسب تاريخ السند وليس وقت الإدخال
  IntColumn get fiscalPeriodId =>
      integer().named('fiscal_period_id').references(FiscalPeriods, #id)();

  // المبلغ — دائماً موجب
  // التحقق CHECK(amount > 0) يُضاف كـ customConstraint لتجنب المشكلة الدورية في Dart
  RealColumn get amount => real().customConstraint('NOT NULL CHECK(amount > 0)')();

  // العملة: 'IQD' | 'USD'
  TextColumn get currency =>
      text().withDefault(const Constant('IQD'))();

  // سعر الصرف وقت إنشاء السند (للأرشفة التاريخية)
  RealColumn get exchangeRate =>
      real().named('exchange_rate').withDefault(const Constant(1.0))();

  // تاريخ السند (يحدد الفترة المالية)
  DateTimeColumn get voucherDate => dateTime().named('voucher_date')();

  // اسم المستلم / الدافع
  TextColumn get personName =>
      text().named('person_name').withDefault(const Constant(''))();

  // السبب / البيان
  TextColumn get reason => text().withDefault(const Constant(''))();

  // نوع البند بالعربية (موحّد على العربية — تدقيق 2026-08-06):
  //   صرف: راتب | سلفة | إيجار | مشتريات | مصاريف تشغيل | رسوم وضرائب | أخرى
  //   قبض: دفعة عميل | إيراد بيع | قرض وارد | رأس مال | مرتجع صرف | إيرادات أخرى
  //   '' = غير محدد. لا نفرض قيد CHECK صارماً لإتاحة إضافة فئات مستقبلاً.
  TextColumn get itemType =>
      text().named('item_type').withDefault(const Constant(''))();

  // رقم المرجع (مثل: رقم شيك، رقم حوالة)
  TextColumn get referenceNumber =>
      text().named('reference_number').withDefault(const Constant(''))();

  // هل هذا السند يؤثر على إقفال الخزينة؟
  // true: سند صرف مقفلة (CloseSafe في النظام القديم)
  BoolColumn get closeSafe =>
      boolean().named('close_safe').withDefault(const Constant(false))();

  // تحويل الخزينة: معرّف الخزينة الأخرى (عند Transfer فقط)
  IntColumn get linkedTreasuryId =>
      integer().named('linked_treasury_id').nullable()();

  // ربط بكيان (موظف / مقاول / شريك)
  IntColumn get linkedEntityId =>
      integer().named('linked_entity_id').nullable()();

  // نوع الكيان المرتبط
  TextColumn get linkedEntityType =>
      text().named('linked_entity_type').nullable()();

  // اسم المشروع أو مكان الصرف (تم إضافته لدعم السلف)
  TextColumn get projectName =>
      text().named('project_name').nullable()();

  // رقم الفاتورة أو الوصل المرفق
  TextColumn get invoiceNumber =>
      text().named('invoice_number').nullable()();

  // الشخص الذي قام بصرف المبلغ فعلياً في الموقع
  TextColumn get spentBy =>
      text().named('spent_by').nullable()();

  // رقم السلفة (نص للعرض على السند وفي الطباعة)
  TextColumn get advanceNumber =>
      text().named('advance_number').nullable()();

  // معرّف السلفة في جدول advances — الرباط الموثوق (Schema v5).
  //
  // لماذا عمود إضافي بينما advance_number موجود؟
  //   المطابقة النصية على رقم السلفة هشّة: فراغ زائد أو اختلاف صياغة يكسر
  //   الربط بصمت فتظهر السلفة ناقصة في التقرير. المفتاح الخارجي لا يكسر.
  //   advance_number يبقى للعرض البشري على السند، وهذا للاستعلامات.
  //
  // يُملأ في حالتين:
  //   1. سندا التحويل (transfer_out/in) عند تمويل السلفة → يُحتسبان «المُرسَل»
  //   2. سندات الصرف الناتجة عن اعتماد المسودة → تُحتسب «المصروف»
  IntColumn get advanceId => integer().named('advance_id').nullable()();

  // معرّف مجموعة التحويل — يربط سندَي التحويل (transfer_out و transfer_in)
  // برباط موثوق بدل المطابقة التخمينية (المبلغ+التاريخ+الخزائن) التي كانت
  // تفشل مع تحويلين متطابقين في نفس اليوم. راجع تدقيق 2026-08-06 (H8).
  TextColumn get transferGroupId =>
      text().named('transfer_group_id').nullable()();

  // ملاحظات إضافية
  TextColumn get notes => text().withDefault(const Constant(''))();

  // المستخدم الذي أنشأ السند
  IntColumn get createdByUserId =>
      integer().named('created_by_user_id').nullable()();

  // وقت الإنشاء
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  // وقت آخر تعديل
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  // المستخدم الذي عدّل آخر مرة
  IntColumn get updatedByUserId =>
      integer().named('updated_by_user_id').nullable()();

  // حذف ناعم — السند لا يُحذف فعلياً لأسباب محاسبية
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  // وقت الحذف الناعم
  DateTimeColumn get deletedAt =>
      dateTime().named('deleted_at').nullable()();
}
