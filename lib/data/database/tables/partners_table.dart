// ─────────────────────────────────────────────────────────────────────────────
// partners_table.dart — جدول الشركاء
//
// الشركاء (شركاء العمل): أصحاب حصص في الشركة.
// لكل شريك: بيانات أساسية + نسبة الحصة + خزينة خاصة + سجل معاملات.
//
// في النظام القديم (C#): Frm_Add_Personal.cs + Frm_Sanad_Pull_Personal.cs
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import 'treasuries_table.dart';

/// جدول الشركاء
class Partners extends Table {
  IntColumn get id => integer().autoIncrement()();

  // اسم الشريك
  TextColumn get name => text().withLength(min: 1, max: 150)();

  // رقم الهاتف
  TextColumn get phone => text().withDefault(const Constant(''))();

  // العنوان
  TextColumn get address => text().withDefault(const Constant(''))();

  // نسبة حصة الشريك في الشركة (0.0 إلى 100.0)
  RealColumn get sharePercentage =>
      real().named('share_percentage').withDefault(const Constant(0.0))();

  // الخزينة الخاصة بهذا الشريك
  IntColumn get treasuryId =>
      integer().named('treasury_id').references(Treasuries, #id).nullable()();

  // ملاحظات
  TextColumn get notes => text().withDefault(const Constant(''))();

  // هل الشريك نشط؟
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  // وقت الإنشاء
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  // حذف ناعم
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
}
