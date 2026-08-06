// ─────────────────────────────────────────────────────────────────────────────
// exchange_rates_table.dart — جدول أسعار الصرف التاريخية
//
// يخزن سجلاً تاريخياً لأسعار الصرف بين العملات.
// كل سند يحتفظ بسعر الصرف وقت إنشائه (في جدول Vouchers) —
// هذا الجدول يخدم التقارير والاستفسارات التاريخية.
//
// الاستخدام:
//   - عند إنشاء سند: يُقرأ سعر الصرف الحالي ويُحفَظ مع السند
//   - في التقارير: يمكن معرفة سعر الصرف في تاريخ محدد
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

/// جدول أسعار الصرف التاريخية
class ExchangeRates extends Table {
  IntColumn get id => integer().autoIncrement()();

  // العملة الأساسية (من) — مثال: 'USD'
  TextColumn get fromCurrency => text().named('from_currency')();

  // العملة الهدف (إلى) — مثال: 'IQD'
  TextColumn get toCurrency => text().named('to_currency')();

  // سعر الصرف — كم وحدة من toCurrency تساوي وحدة من fromCurrency
  // مثال: 1 USD = 1310 IQD → rate = 1310.0
  RealColumn get rate => real().customConstraint('NOT NULL CHECK(rate > 0)')();

  // تاريخ سريان هذا السعر
  DateTimeColumn get effectiveDate => dateTime().named('effective_date')();

  // من أدخل هذا السعر؟
  IntColumn get createdByUserId =>
      integer().named('created_by_user_id').nullable()();

  // وقت الإنشاء
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}
