// ─────────────────────────────────────────────────────────────────────────────
// advances_table.dart — جدول السلف (سلف المشاريع)
//
// ⚠️ تنبيه على التسمية — لا تخلط بين جدولين مختلفين تماماً:
//   Advances     (هذا الجدول) — سلفة مشروع: مبلغ يُرسَل لمشروع في محافظة،
//                                يُصرَف هناك، ثم تصل مصاريفه في ملف إكسل.
//   CashAdvances (employees_table.dart) — سلفة موظف: مبلغ يأخذه موظف من راتبه
//                                ويُسدَّده على أقساط. لا علاقة له بهذا الجدول.
//
// دورة حياة السلفة (status):
//   'open'      — أُرسل المبلغ للمشروع (تحويل بين الخزائن) ولم تصل مصاريفه بعد
//   'draft'     — وصل ملف الإكسل وأُنشئت أسطر المسودة — تحت المراجعة والتعديل
//   'posted'    — اعتُمدت: تحوّل كل سطر إلى سند صرف حقيقي وأثّر على الخزنة
//   'cancelled' — أُلغيت
//
// 🔑 القاعدة الجوهرية في هذا التصميم:
//   السلفة في حالتَي 'open' و'draft' **لا تؤثر على رصيد أي خزينة إطلاقاً**.
//   أسطر المسودة تعيش في advance_lines وليست سندات. الأثر المالي يقع في
//   لحظة واحدة فقط: postAdvance() التي تحوّل الأسطر إلى سندات صرف.
//   هذا يتيح المراجعة وتصحيح تصنيف المصروفات ومطابقة الإجمالي قبل أن تُمَسّ
//   الدفاتر — وهو سبب وجود هذا الجدول أصلاً.
//
// العجز (deficit):
//   يحدث حين يصرف المشروع أكثر مما أُرسل له (مثال: أُرسل 3 مليون وصُرف 3.5).
//   المدير أو المحاسب في الموقع يغطي الفرق من ماله ويسجّله طلباً على الشركة.
//   في هذه الحالة تصبح خزنة المشروع بالسالب، ويُحفَظ هنا مقدار العجز واسم من
//   غطّاه حتى لا يضيع الدَّين. راجع deficit_amount و deficit_covered_by.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import 'treasuries_table.dart';
import 'fiscal_periods_table.dart';

/// جدول سلف المشاريع
class Advances extends Table {
  // المعرّف الأساسي
  IntColumn get id => integer().autoIncrement()();

  // رقم السلفة — نص وليس رقماً لدعم ترقيم مثل '23' أو '23-أ' أو 'بصرة-5'
  TextColumn get advanceNumber =>
      text().named('advance_number').withLength(min: 1, max: 50)();

  // خزينة المشروع التي أُرسل إليها المبلغ ويُصرَف منها (مثل: خزنة البصرة)
  IntColumn get projectTreasuryId =>
      integer().named('project_treasury_id').references(Treasuries, #id)();

  // الفترة المالية — تُحدَّد حسب تاريخ السلفة وليس وقت الإدخال
  IntColumn get fiscalPeriodId =>
      integer().named('fiscal_period_id').references(FiscalPeriods, #id)();

  // اسم المشروع — يُعبَّأ افتراضياً من اسم الخزينة، ويظهر في التقارير
  // ومسار مجلد المرفقات. محفوظ هنا لتفادي الحاجة لـ JOIN في كل تقرير.
  TextColumn get projectName =>
      text().named('project_name').withDefault(const Constant(''))();

  // تاريخ السلفة
  DateTimeColumn get advanceDate => dateTime().named('advance_date')();

  // الحالة: open | draft | posted | cancelled — مقيَّدة بـ CHECK أدناه
  TextColumn get status => text().withDefault(const Constant('open'))();

  // إجمالي المبالغ كما قُرئت من ملف الإكسل قبل أي تعديل.
  // مرجع ثابت للمطابقة: يبقى كما هو مهما عدّل المستخدم في أسطر المسودة،
  // فتظل مقارنة «إجمالي الإكسل» بـ «إجمالي المسودة» صادقة.
  RealColumn get excelTotal =>
      real().named('excel_total').withDefault(const Constant(0.0))();

  // اسم ملف الإكسل المستورَد (للعرض في سجل السلفة)
  TextColumn get sourceFileName =>
      text().named('source_file_name').withDefault(const Constant(''))();

  // بصمة SHA-256 لمحتوى ملف الإكسل — لكشف استيراد نفس الملف مرتين.
  // استيراد مكرر يضاعف المصاريف بصمت، وهو خطأ وارد جداً في العمل اليومي.
  TextColumn get sourceFileHash =>
      text().named('source_file_hash').withDefault(const Constant(''))();

  // مقدار العجز وقت الاعتماد (0 = لا عجز) — يُثبَّت لحظة الاعتماد ولا يتغير
  RealColumn get deficitAmount =>
      real().named('deficit_amount').withDefault(const Constant(0.0))();

  // اسم من غطّى العجز من ماله (مدير المشروع / المحاسب) — الدائن على الشركة
  TextColumn get deficitCoveredBy =>
      text().named('deficit_covered_by').nullable()();

  // ملاحظات
  TextColumn get notes => text().withDefault(const Constant(''))();

  // ── أثر التدقيق: من فعل ماذا ومتى ──────────────────────────────────────

  IntColumn get createdByUserId =>
      integer().named('created_by_user_id').nullable()();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  IntColumn get postedByUserId =>
      integer().named('posted_by_user_id').nullable()();

  DateTimeColumn get postedAt => dateTime().named('posted_at').nullable()();

  IntColumn get cancelledByUserId =>
      integer().named('cancelled_by_user_id').nullable()();

  DateTimeColumn get cancelledAt =>
      dateTime().named('cancelled_at').nullable()();

  /// قيود على مستوى الجدول (دفاع في العمق)
  ///
  /// حصر الحالة في القيم المعروفة يمنع وصول السلفة إلى حالة لا يفهمها المنطق
  /// (مثل خطأ إملائي في كود مستقبلي يجعلها 'postd' فلا تظهر في أي قائمة).
  @override
  List<String> get customConstraints => [
        "CHECK (status IN ('open', 'draft', 'posted', 'cancelled'))",
        'CHECK (excel_total >= 0)',
        'CHECK (deficit_amount >= 0)',
      ];
}
