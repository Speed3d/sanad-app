// ─────────────────────────────────────────────────────────────────────────────
// advance_lines_table.dart — أسطر مسودة السلفة
//
// كل سطر هنا = صف واحد في ملف الإكسل الذي أرسله المشروع.
//
// 🔑 هذه الأسطر ليست سندات — ولا تؤثر على رصيد أي خزينة.
//   تعيش في هذا الجدول للمراجعة والتعديل، وعند الاعتماد (postAdvance) يتحوّل
//   كل سطر غير مستبعَد إلى سند صرف في جدول vouchers، ويُحفَظ معرّف السند
//   الناتج في voucher_id لربط السطر بسنده ربطاً موثوقاً.
//
// لماذا نحفظ القيم الأصلية (original_*)؟
//   المالك يريد تعديل تصنيف المصروفات (الفلتر) وتصحيح الأوصاف قبل الحفظ،
//   لكنه يريد أيضاً أن تبقى «مطابقة المبلغ مع جدول الإكسل» ممكنة. حفظ القيمة
//   كما وصلت من الملف يتيح عرض ما تغيّر بالضبط، ويمنع أن يصبح التعديل تزويراً
//   صامتاً على ما أرسله المشروع.
//
// لماذا الاستبعاد (is_excluded) بدل الحذف؟
//   حذف السطر يمحو أثر أن المشروع أرسل هذا المصروف أصلاً. الاستبعاد يُخرجه من
//   الإجمالي ومن الاعتماد، لكنه يبقى مرئياً في المسودة مع سبب استبعاده.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import 'advances_table.dart';
import 'payroll_periods_table.dart';

/// جدول أسطر مسودة السلفة
class AdvanceLines extends Table {
  // المعرّف الأساسي
  IntColumn get id => integer().autoIncrement()();

  // السلفة التي ينتمي إليها هذا السطر
  IntColumn get advanceId =>
      integer().named('advance_id').references(Advances, #id)();

  // رقم الصف في ملف الإكسل الأصلي — لعرض «صف ١٧» في رسائل الخطأ والمراجعة
  IntColumn get rowNumber =>
      integer().named('row_number').withDefault(const Constant(0))();

  // ── الحقول التشغيلية (قابلة للتعديل في شاشة المراجعة) ──────────────────

  // تاريخ الصرف
  DateTimeColumn get voucherDate => dateTime().named('voucher_date')();

  // المبلغ — دائماً موجب وبالدينار العراقي حصراً (الاستيراد لا يقبل الدولار)
  RealColumn get amount =>
      real().customConstraint('NOT NULL CHECK(amount > 0)')();

  // نوع البند / «الفلتر» — كهربائيات، بانزين، إنترنت، طعام، راتب، إيجار…
  // هذا هو الحقل الذي يعدّله المالك سطراً سطراً قبل الاعتماد.
  TextColumn get itemType =>
      text().named('item_type').withDefault(const Constant(''))();

  // السبب / البيان
  TextColumn get reason => text().withDefault(const Constant(''))();

  // اسم الشخص المرتبط بالمصروف
  TextColumn get personName =>
      text().named('person_name').withDefault(const Constant(''))();

  // اسم المشروع كما ورد في الملف (قد يختلف عن مشروع السلفة نفسها)
  TextColumn get projectName => text().named('project_name').nullable()();

  // رقم الفاتورة أو الوصل المرفق
  TextColumn get invoiceNumber => text().named('invoice_number').nullable()();

  // من قام بالصرف فعلياً في الموقع
  TextColumn get spentBy => text().named('spent_by').nullable()();

  // ── القيم الأصلية من الإكسل (للمقارنة — لا تُعدَّل أبداً بعد الاستيراد) ──

  RealColumn get originalAmount => real().named('original_amount')();

  TextColumn get originalItemType =>
      text().named('original_item_type').withDefault(const Constant(''))();

  DateTimeColumn get originalDate => dateTime().named('original_date')();

  // ── حالة السطر ──────────────────────────────────────────────────────────

  // هل عُدِّل هذا السطر عن أصله؟ — يُعلَّم في الواجهة ليبقى التعديل مرئياً
  BoolColumn get isEdited =>
      boolean().named('is_edited').withDefault(const Constant(false))();

  // هل استُبعد من الاعتماد؟ — يبقى مرئياً لكنه خارج الإجمالي وخارج السندات
  BoolColumn get isExcluded =>
      boolean().named('is_excluded').withDefault(const Constant(false))();

  // سبب الاستبعاد (اختياري)
  TextColumn get excludeReason =>
      text().named('exclude_reason').withDefault(const Constant(''))();

  // معرّف السند الناتج بعد الاعتماد — null ما دامت السلفة مسودة
  IntColumn get voucherId => integer().named('voucher_id').nullable()();

  // كشف الرواتب الذي يسدّده هذا السطر (Schema v7) — null في كل سطر عادي.
  //
  // **ما يعنيه وجوده:** هذا السطر ليس مصروفاً عادياً بل «تسديد رواتب شهر
  // كذا». يضع المالك علامةً عليه في شاشة المراجعة ويختار كشف الشهر، فتُعلَّم
  // سطور موظفي خزنة هذا المشروع بـ`salary_payments.advance_line_id`.
  //
  // 🔑 **وعنده يعمل حارس المطابقة** في `AdvancesDao.postAdvance`:
  //     Σ(net_amount_iqd للسطور المرتبطة) == amount
  //   واختلافهما يمنع الاعتماد. بدونه يُحتسب المال مرّتين — مرة كسطر مصروف
  //   ومرة كرواتب مسدَّدة — وهو صنف العطل ع-١٣ نفسه (الرصيد الافتتاحي كان
  //   يُضاعف الرصيد).
  IntColumn get payrollPeriodId => integer()
      .named('payroll_period_id')
      .references(PayrollPeriods, #id)
      .nullable()();

  /// قيود على مستوى الجدول (دفاع في العمق)
  @override
  List<String> get customConstraints => [
        'CHECK (original_amount > 0)',
      ];
}
