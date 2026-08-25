// ─────────────────────────────────────────────────────────────────────────────
// payroll_periods_table.dart — كشف رواتب شهر واحد (Schema v7)
//
// ⚠️ تنبيه على التسمية — ثلاثة مفاهيم متشابهة في الاسم ومختلفة تماماً:
//   PayrollPeriods (هذا الجدول) — كشف رواتب **شهر** (شباط 2025 مثلاً)
//   FiscalPeriods                — **السنة المالية** (2025). هذا الجدول يشير إليها
//   Advances                     — سلفة مشروع
//   CashAdvances                 — سلفة موظف
//
// ما هو الكشف؟
//   المالك يستلم آخر كل شهر ملف إكسل من محاسبي المشاريع فيه أسماء الموظفين
//   ورواتبهم وخصوماتهم ومكافآتهم والصافي المستحق لكل واحد، ومجموع الرواتب
//   في آخره. يُستورَد الملف فيصير **كشفاً** — رأسٌ هنا وسطورٌ في salary_payments.
//
// دورة الحياة (status):
//   'draft'  — مسودة: تُراجَع وتُصحَّح ولا تمسّ رصيد أي خزينة إطلاقاً
//   'posted' — مُسدَّد: صار لكل سطر سنده، والتعديل ممنوع (قرار المالك 2026-08-24)
//
// 🔑 القاعدة الجوهرية — نفس مبدأ سلف المشاريع:
//   الكشف في حالة 'draft' **لا يؤثر على رصيد أي خزينة**. الأثر المالي يقع في
//   لحظة التسديد وحدها، حيث يُنشأ **سند صرف واحد بالمجموع** (لا سند لكل موظف
//   — قرار المالك 2026-08-24: التفصيل محفوظ في سطر الكشف بلقطته، والسند يمثّل
//   حركة المال لا التفصيل).
//
// لماذا لا يوجد جدول «سنة رواتب»؟
//   السنوات تُشتق بـ GROUP BY year على هذا الجدول. تخزين سنةٍ فارغة لا معنى له
//   ويفتح باب سنةٍ بلا أشهر تظهر في القوائم بلا محتوى.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import 'fiscal_periods_table.dart';

/// جدول كشوف الرواتب الشهرية
class PayrollPeriods extends Table {
  // المعرّف الأساسي
  IntColumn get id => integer().autoIncrement()();

  // السنة الميلادية (2025)
  IntColumn get year => integer()();

  // الشهر 1..12 — محروس بقيد CHECK أدناه
  IntColumn get month => integer()();

  // السنة المالية التي ينتمي إليها هذا الشهر.
  //
  // لماذا مفتاح خارجي وليس حقلاً محسوباً؟
  //   لأنه يجعل `FiscalPeriodGuard.ensureActive` قابلاً للتطبيق مباشرةً على
  //   الكشف: لا يُستورَد ولا يُسدَّد كشفُ شهرٍ يقع داخل سنة مالية **مُقفَلة**.
  //   وبدونه كان الحارس يحتاج اشتقاق السنة من التاريخ في كل مستدعٍ — وحارسٌ
  //   يُعاد بناؤه في كل موضع يُنسى في أحدها.
  IntColumn get fiscalPeriodId =>
      integer().named('fiscal_period_id').references(FiscalPeriods, #id)();

  // أيام العمل المعتمدة لهذا الشهر — تُجمَّد على الكشف لحظة إنشائه.
  //
  // الافتراض 30 يوماً **عرفاً محاسبياً** مهما كان طول الشهر التقويمي
  // (قرار المالك 2026-08-24، ونفس عرف مشروعه المرجعي DMS).
  IntColumn get workingDays =>
      integer().named('working_days').withDefault(const Constant(30))();

  // كيف حُدِّدت أيام العمل: 'fixed' (30 عرفاً) | 'calendar' (طول الشهر الفعلي)
  TextColumn get workingDaysMode =>
      text().named('working_days_mode').withDefault(const Constant('fixed'))();

  // سعر صرف الدولار لهذا الشهر — **مجمَّد على الكشف**.
  //
  // لماذا على الكشف لا على السطر؟
  //   السعر واحد للشهر كلّه، ووضعه على كل سطر يفتح احتمال اختلاف سطرين في
  //   الشهر نفسه بلا سبب. وتجميده يعني أن تحرّك سعر الصرف بعد شهور **لا
  //   يُغيّر كشفاً مُسدَّداً** — نفس مبدأ `vouchers.exchange_rate` القائم.
  //
  // يبقى nullable لأن الكشف الذي كل رواتبه بالدينار لا يحتاج سعراً أصلاً.
  // والحارس: أي سطر بالدولار بلا سعر صرف يُرفض عند الحفظ لا عند التسديد
  // (قرار المالك 2026-08-24: «لا يُحفَظ شيء إلا بمقابله بالدينار»).
  RealColumn get exchangeRate => real().named('exchange_rate').nullable()();

  // الحالة: draft | posted — محروسة بقيد CHECK أدناه
  TextColumn get status => text().withDefault(const Constant('draft'))();

  // مجموع الرواتب **كما ذكره الملف** في سطره الأخير.
  //
  // مرجع ثابت للمطابقة على نمط `advances.excel_total`: يبقى كما وصل مهما
  // عدّل المالك في السطور، فتظل مقارنة «مجموع الملف» بـ«مجموع السطور
  // المحسوب» صادقة — وهي التي تكشف **خطأً حسابياً في الملف نفسه** قبل أن
  // يدخل الدفاتر، وهي أرخص لحظة لاكتشافه.
  RealColumn get fileTotal =>
      real().named('file_total').withDefault(const Constant(0.0))();

  // اسم ملف الإكسل المستورَد (للعرض في سجل الكشف)
  TextColumn get sourceFileName =>
      text().named('source_file_name').withDefault(const Constant(''))();

  // بصمة SHA-256 لمحتوى الملف — لكشف استيراد الملف نفسه مرتين.
  // استيراد مكرر يضاعف الرواتب بصمت، وهو خطأ وارد جداً في العمل الشهري.
  TextColumn get sourceFileHash =>
      text().named('source_file_hash').withDefault(const Constant(''))();

  // ملاحظات
  TextColumn get notes => text().withDefault(const Constant(''))();

  // ── أثر التدقيق: من فعل ماذا ومتى ────────────────────────────────────────

  IntColumn get createdByUserId =>
      integer().named('created_by_user_id').nullable()();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  IntColumn get postedByUserId =>
      integer().named('posted_by_user_id').nullable()();

  DateTimeColumn get postedAt => dateTime().named('posted_at').nullable()();

  // ── الحذف الناعم (القانون ٨) ─────────────────────────────────────────────

  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  /// قيود على مستوى الجدول (دفاع في العمق)
  ///
  /// حصر الحالة والشهر في القيم المعروفة يمنع وصول الكشف إلى حالة لا يفهمها
  /// المنطق — مثل خطأ إملائي في كود مستقبلي يجعلها 'postd' فلا تظهر في أي
  /// قائمة، أو شهر 13 يُنتج تاريخاً غير موجود عند حساب الأيام المستحقة.
  @override
  List<String> get customConstraints => [
        'CHECK (month BETWEEN 1 AND 12)',
        'CHECK (year BETWEEN 2000 AND 2100)',
        "CHECK (status IN ('draft', 'posted'))",
        "CHECK (working_days_mode IN ('fixed', 'calendar'))",
        'CHECK (working_days > 0 AND working_days <= 31)',
        'CHECK (exchange_rate IS NULL OR exchange_rate > 0)',
        'CHECK (file_total >= 0)',
      ];
}
