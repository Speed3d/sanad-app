// ─────────────────────────────────────────────────────────────────────────────
// contractors_table.dart — جدول المقاولين
//
// المقاولون: أشخاص أو شركات تقدم خدمات للشركة بعقود.
// لكل مقاول: بيانات أساسية + خزينة خاصة (اختياري) + سجل معاملات.
//
// في النظام القديم (C#): Frm_Add_Contractors.cs + Frm_Sanad_Pull_Contractors.cs
// في النظام الجديد: جدول موحد مع ربط بجدول Treasuries وVouchers
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import 'treasuries_table.dart';

/// جدول المقاولين
class Contractors extends Table {
  IntColumn get id => integer().autoIncrement()();

  // اسم المقاول أو الشركة
  TextColumn get name => text().withLength(min: 1, max: 150)();

  // رقم الهاتف الأول
  TextColumn get phone1 => text().named('phone1').withDefault(const Constant(''))();

  // رقم الهاتف الثاني (اختياري)
  TextColumn get phone2 => text().named('phone2').withDefault(const Constant(''))();

  // العنوان
  TextColumn get address => text().withDefault(const Constant(''))();

  // نوع المقاول: 'individual' | 'company'
  TextColumn get contractorType =>
      text().named('contractor_type').withDefault(const Constant('individual'))();

  // الخزينة الخاصة بهذا المقاول (مرتبطة بجدول Treasuries)
  IntColumn get treasuryId =>
      integer().named('treasury_id').references(Treasuries, #id).nullable()();

  // ملاحظات
  TextColumn get notes => text().withDefault(const Constant(''))();

  // هل المقاول نشط؟
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  // وقت الإنشاء
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  // حذف ناعم
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
}
