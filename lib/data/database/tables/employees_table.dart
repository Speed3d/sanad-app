// ─────────────────────────────────────────────────────────────────────────────
// employees_table.dart — جداول الموظفين والسلف والرواتب
//
// يحتوي هذا الملف على 4 جداول:
//   1. Employees     — بيانات الموظفين
//   2. CashAdvances  — السلف (كانت تُسمى Employee Loans في النظام القديم)
//   3. CashAdvanceRepayments — أقساط سداد السلف
//   4. SalaryPayments — سطور كشوف الرواتب (راجع تفصيله أسفل الملف)
//
// لماذا "CashAdvances" وليس "EmployeeLoans"؟
//   المصطلح المحاسبي الصحيح هو "سلفة" (Cash Advance) وليس "قرض"
//   لأن الشركة هي الدائنة والموظف هو المدين.
//   حقل `debtor_type` يسمح بتسجيل سلف لأشخاص خارجيين أيضاً.
//
// جدول SalaryPayments (Schema v7 — تغيّر معناه):
//   كان «سجل صرف راتب فردي»، وصار **سطر كشف رواتب الشهر**: يحمل لقطة الموظف
//   لحظة الشهر، والمحسوب بعملته وبالدينار، وحالة دفعه، وربطه بسلفة المشروع
//   إن سُدِّد من خلالها. رأس الكشف في `payroll_periods_table.dart`.
//
//   ⚠️ **ولم يعد لكل راتب سنده**: التسديد يُنشئ سند صرف **واحداً بالمجموع**
//     لكل دفعة، فتشترك سطور الدفعة في `voucher_id` واحد (قرار المالك
//     2026-08-24). التفصيل يعيش في السطر، والسند يمثّل حركة المال.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import '../../../core/constants/employee_status.dart';
import 'departments_table.dart';
import 'treasuries_table.dart';
import 'payroll_periods_table.dart';

/// جدول الموظفين
class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();

  // الاسم الكامل
  TextColumn get fullName => text().withLength(min: 1, max: 100).named('full_name')();

  // رقم الهاتف
  TextColumn get phone => text().withDefault(const Constant(''))();

  // العنوان
  TextColumn get address => text().withDefault(const Constant(''))();

  // الصفة الوظيفية بالعربية: مهندس · سائق · محاسب · حارس… (Schema v7)
  //
  // تصل من ملف رواتب الشهر وتُحفَظ هنا، ثم تُنسَخ **لقطةً** في كل سطر كشف
  // (`salary_payments.snapshot_position`) — فترقية موظف من سائق إلى مشرف في
  // آذار لا تُعيد كتابة كشف شباط المُسدَّد.
  TextColumn get position => text().withDefault(const Constant(''))();

  // الراتب الأساسي — **بعملة [salaryCurrency] لا بالدينار حتماً** (Schema v7)
  //
  // ⚠️ كان هذا العمود بالدينار حصراً حتى v6. من يقرأه الآن يجب أن يقرأ
  //   `salary_currency` معه، وإلا عامل راتباً بالدولار كأنه دينار — وهو خطأ
  //   بمقدار سعر الصرف كلّه.
  RealColumn get basicSalary =>
      real().named('basic_salary').withDefault(const Constant(0.0))();

  // عملة الراتب: 'IQD' | 'USD' (Schema v7 — قرار المالك 2026-08-24)
  //
  // المكافأة والخصم **يتبعانها دائماً** فلا عمود عملة مستقلاً لهما: موظف
  // راتبه بالدولار تُدخَل مكافأته بالدولار. هذا يحذف غموض التحويل نهائياً.
  TextColumn get salaryCurrency =>
      text().named('salary_currency').withDefault(const Constant('IQD'))();

  // تاريخ التعيين
  //
  // 📌 **جزء من مفتاح مطابقة الموظف عند الاستيراد** — لا رقم موظف في ملفات
  //   المالك (يختلف تسلسلها حسب من أرسلها)، فالمطابقة بـ(الاسم المُطبَّع +
  //   تاريخ التعيين). راجع `PayrollNameMatcher` عند بنائه في المرحلة ٢.
  DateTimeColumn get hireDate => dateTime().named('hire_date').nullable()();

  // الخزينة الخاصة بهذا الموظف (اختياري)
  //
  // 📌 **وهي أيضاً رابط المشروع** (قرار المالك 2026-08-24): موظفو خزنة البصرة
  //   هم موظفو مشروع البصرة، لأن `advances.project_treasury_id` تشير إلى
  //   الخزينة نفسها. بهذا يُعرَف «من يغطّيهم سطر رواتب سلفة البصرة» بلا حقل
  //   مشروع مستقل يفتح احتمال التناقض بين حقلين.
  IntColumn get treasuryId =>
      integer().named('treasury_id').references(Treasuries, #id).nullable()();

  // ملاحظات
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// حالة الموظف (Schema v8 — بلاغ المالك 2026-08-30)
  ///
  /// `active` حالي · `terminated` منتهية خدمته · `leave` في إجازة
  ///
  /// 🔑 **حلّ محلّ `is_active` ولم يُضَف بجواره.** كان العمود القديم يحمل
  ///   حالتين (نشط/موقوف) بينما الواقع ثلاث، و«الموقوف» كانت تعني في
  ///   الاستعمال «منتهية خدمته». وإبقاء العمودين معاً يُنتج **عمودين لمعنى
  ///   واحد** يفترقان بأول كتابة تنسى أحدهما — وهو نمط ع-٤٠ حرفياً.
  ///
  ///   والترحيل v7→v8 يحوّل `is_active = 0` إلى `terminated`، فلا يضيع
  ///   قرارُ إيقافٍ اتّخذه المالك سابقاً.
  TextColumn get status =>
      text().withDefault(const Constant(EmployeeStatus.active))();

  /// القسم الذي ينتمي إليه (Schema v8) — `null` يعني «بلا قسم»
  ///
  /// اختياري عمداً: الشركة تعمل اليوم بلا أقسام، وفرضُ قسمٍ على كل موظف
  /// عند الترقية يعني اختراع بيانات لا يعرفها أحد.
  IntColumn get departmentId => integer()
      .named('department_id')
      .nullable()
      .references(Departments, #id)();

  /// ترتيب الموظف **داخل قسمه** (Schema v8) — الأصغر أولاً
  ///
  /// راجع رأس `departments_table.dart` لسبب الترتيب على مستويين.
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();

  // ── إنهاء الخدمة (Schema v9 — طلب المالك 2026-09-02) ───────────────────
  //
  // 🔑 **لماذا تاريخٌ صريح لا `status` وحدها؟**
  //   `status = 'terminated'` تقول **أنه** انتهى ولا تقول **متى**. والراتب
  //   يحتاج المتى: من أُنهيت خدمته في ٢٦ آب يستحقّ ستّة وعشرين يوماً من
  //   آب — لا شهراً كاملاً ولا صفراً.
  //
  // ⚠️ **والحساب كان جاهزاً ومعطَّلاً**: `PayrollCalculator.eligibleDays`
  //   تستقبل `terminationDate` منذ المرحلة الأولى وتحسبها حساباً صحيحاً
  //   محروساً بالاختبارات — **ولا عمود في القاعدة يحملها ولا مستدعٍ
  //   يمرّرها**. نمط ع-٠٦ في أنقى صوره: منطقٌ سليم بلا نصفه الآخر.

  /// تاريخ إنهاء الخدمة — `null` للموظف على رأس عمله
  ///
  /// يدخل حساب الراتب مباشرةً: يُقصّ شهر الإنهاء عند هذا اليوم **شاملاً
  /// إيّاه** (قرار المالك 2026-09-02)، وتصير الشهور التالية صفراً.
  DateTimeColumn get terminationDate =>
      dateTime().named('termination_date').nullable()();

  /// سند إنهاء الخدمة — «بموجب الكتاب المرقّم ٣٤٥ في ٢٠٢٦/٨/٢٦»
  ///
  /// قرارٌ إداري يُنقص راتباً يجب أن يُعرَف **مستنده** بعد سنة، وإلا صار
  /// الفرق في الكشف بلا تفسير.
  TextColumn get terminationReference =>
      text().named('termination_reference').withDefault(const Constant(''))();

  /// ملاحظات إنهاء الخدمة
  TextColumn get terminationNotes =>
      text().named('termination_notes').withDefault(const Constant(''))();

  // وقت الإنشاء
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  // حذف ناعم
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  /// قيود على مستوى الجدول (دفاع في العمق — Schema v7)
  ///
  /// حصر العملة في القيمتين المعروفتين: قيمة ثالثة تعني راتباً لا يعرف
  /// `PayrollCalculator` كيف يحوّله إلى دينار، فيصمت أو يُخطئ.
  ///
  /// وحصر الحالة في الثلاث المعروفة (v8): قيمةٌ رابعة تجعل الموظف يختفي من
  /// كل فلتر بلا رسالة — الحارس في القاعدة يمنع وصولها أصلاً.
  @override
  List<String> get customConstraints => [
        "CHECK (salary_currency IN ('IQD', 'USD'))",
        "CHECK (status IN ('active', 'terminated', 'leave'))",
      ];
}

/// جدول السلف (Cash Advances)
///
/// يدعم سلف للموظفين وسلف لأشخاص خارجيين.
/// CHECK constraint يضمن اتساق البيانات:
///   - إذا debtor_type='employee': employee_id لا يكون null
///   - إذا debtor_type='external': external_person_name لا يكون null
class CashAdvances extends Table {
  IntColumn get id => integer().autoIncrement()();

  // نوع المدين: 'employee' | 'external'
  TextColumn get debtorType =>
      text().named('debtor_type').withDefault(const Constant('employee'))();

  // معرّف الموظف (إذا debtor_type='employee')
  IntColumn get employeeId =>
      integer().named('employee_id').references(Employees, #id).nullable()();

  // اسم الشخص الخارجي (إذا debtor_type='external')
  TextColumn get externalPersonName =>
      text().named('external_person_name').nullable()();

  // مبلغ السلفة (دائماً موجب) — CHECK constraint عبر customConstraint
  RealColumn get amount => real().customConstraint('NOT NULL CHECK(amount > 0)')();

  // العملة: 'IQD' | 'USD'
  TextColumn get currency =>
      text().withDefault(const Constant('IQD'))();

  // تاريخ منح السلفة
  DateTimeColumn get advanceDate => dateTime().named('advance_date')();

  // حالة السلفة: pending | partial | paid | written_off
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  // مجموع ما تم سداده
  RealColumn get totalRepaid =>
      real().named('total_repaid').withDefault(const Constant(0.0))();

  // السبب / الغرض من السلفة
  TextColumn get reason => text().withDefault(const Constant(''))();

  // معرّف السند المرتبط (في جدول Vouchers)
  IntColumn get voucherId =>
      integer().named('voucher_id').nullable()();

  // وقت الإنشاء
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  // حذف ناعم
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  // قيد على مستوى الجدول: المسدَّد لا يتجاوز مبلغ السلفة أبداً (دفاع في العمق)
  // الإصلاح التراكمي في repayAdvance يمنع التجاوز منطقياً، وهذا القيد يمنعه
  // على مستوى قاعدة البيانات نفسها. راجع تدقيق 2026-08-06 (H1/H7).
  @override
  List<String> get customConstraints => ['CHECK(total_repaid <= amount)'];
}

/// جدول أقساط سداد السلف
///
/// كل سداد جزئي أو كلي يُسجَّل هنا.
/// عند اكتمال السداد، يتحوّل `status` في CashAdvances إلى 'paid'.
class CashAdvanceRepayments extends Table {
  IntColumn get id => integer().autoIncrement()();

  // معرّف السلفة المرتبطة
  IntColumn get cashAdvanceId =>
      integer().named('cash_advance_id').references(CashAdvances, #id)();

  // مبلغ القسط — CHECK constraint عبر customConstraint
  RealColumn get amount => real().customConstraint('NOT NULL CHECK(amount > 0)')();

  // تاريخ السداد
  DateTimeColumn get repaymentDate => dateTime().named('repayment_date')();

  // طريقة السداد: 'cash' | 'salary_deduction' | 'bank_transfer'
  TextColumn get method =>
      text().withDefault(const Constant('cash'))();

  // معرّف السند المرتبط (إذا كان سداداً عبر سند قبض)
  IntColumn get voucherId =>
      integer().named('voucher_id').nullable()();

  // ملاحظات
  TextColumn get notes => text().withDefault(const Constant(''))();

  // وقت الإنشاء
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}

/// جدول مدفوعات الرواتب — **وهو سطر كشف الشهر** (Schema v7)
///
/// كل صفّ هنا = راتب موظف واحد عن شهر واحد.
///
/// **لماذا وُسِّع هذا الجدول بدل إنشاء `payroll_entries` جديد؟**
///   جدولان يحملان معنى «راتب مدفوع» يعني أن تقرير «كم صُرف على الرواتب»
///   يجب أن يقرأ الاثنين — ومن ينسى أحدهما يُنتج رقماً ناقصاً بلا أن يشتكي
///   شيء. وهو **حرفياً** العطل الذي ضرب مشروع DMS المرجعي: قاعدة «ما يُدفع
///   فعلاً» كانت مكرَّرة في **ثمانية مواضع**، فاحتُسب في شهرين راتبٌ صرفته
///   جهة أخرى (٣٫٦٨ مليون). **مصدر حقيقة واحد** يمنع هذا الصنف كلّه.
///
/// **العلاقة بالسند:** حتى v6 كان لكل راتب سنده الخاص. من v7 يشترك كل سطور
///   **دفعة تسديد واحدة** في `voucher_id` واحد — لأن التسديد يُنشئ **سند صرف
///   واحداً بالمجموع** (قرار المالك 2026-08-24). التفصيل يعيش هنا باللقطة،
///   والسند يمثّل حركة المال. فالدفعة الواحدة = السطور التي تحمل السند نفسه.
///
/// **الصفوف الأقدم من v7** يملأ لها الترحيل اللقطة و`net_amount_iqd`
///   و`payment_status`، ويبقى `payroll_period_id` فيها `null` (لا كشف لها).
class SalaryPayments extends Table {
  IntColumn get id => integer().autoIncrement()();

  // الموظف المستفيد
  IntColumn get employeeId =>
      integer().named('employee_id').references(Employees, #id)();

  // ── الانتساب إلى كشف الشهر (Schema v7) ──────────────────────────────────

  // كشف الشهر الذي ينتمي إليه هذا السطر.
  //
  // nullable لأن الصفوف الأقدم من v7 أُنشئت قبل وجود مفهوم الكشف. أما
  // الصفوف الجديدة فتُنسَب دائماً لكشف — حتى صرف الراتب الفردي يُنشئ كشف
  // الشهر أو ينضمّ إليه، وإلا تفرّق مجموع الرواتب على مصدرين من جديد.
  IntColumn get payrollPeriodId => integer()
      .named('payroll_period_id')
      .references(PayrollPeriods, #id)
      .nullable()();

  // الفترة التي يغطيها الراتب — نصّ للعرض («شباط 2025»)
  //
  // يبقى للتوافقية وللطباعة. **مصدر الحقيقة للشهر هو الكشف** لا هذا النصّ:
  // النصّ لا يُفلتَر ولا يُرتَّب ولا يُجمَّع عليه بثقة.
  TextColumn get periodLabel =>
      text().named('period_label').withDefault(const Constant(''))();

  // ── اللقطة: حالة الموظف لحظة توليد السطر (Schema v7) ────────────────────
  //
  // 🔑 **سبب وجود اللقطة كلّه:** تغيير راتب الموظف أو صفته في آذار يجب ألّا
  //   يُعيد كتابة كشف شباط المُسدَّد. بدونها كان عرض كشف قديم يقرأ بيانات
  //   الموظف **الحالية** فيُظهر تاريخاً لم يحدث.
  //   وهي أيضاً ما يجعل السجل التفصيلي لكل موظف ممكناً بلا سند لكل موظف.

  TextColumn get snapshotName =>
      text().named('snapshot_name').withDefault(const Constant(''))();

  TextColumn get snapshotPosition =>
      text().named('snapshot_position').withDefault(const Constant(''))();

  TextColumn get snapshotCurrency =>
      text().named('snapshot_currency').withDefault(const Constant('IQD'))();

  DateTimeColumn get snapshotHireDate =>
      dateTime().named('snapshot_hire_date').nullable()();

  // الراتب الأساسي — لقطة أيضاً، بعملة [snapshotCurrency]
  RealColumn get basicSalary =>
      real().named('basic_salary').withDefault(const Constant(0.0))();

  // ── مدخلات الشهر ────────────────────────────────────────────────────────

  // الأيام المستحقّة من أيام عمل الشهر.
  //
  // ⚠️ يحسبها `PayrollCalculator` ولا تُترك فارغة: صفرٌ هنا يعني راتباً صفراً
  //   للموظف العادي.
  IntColumn get eligibleDays =>
      integer().named('eligible_days').withDefault(const Constant(30))();

  // هل عدّل المستخدم الأيام المستحقّة بيده؟
  //
  // ⚠️ **بدون هذا العلَم لا يمكن التمييز** بين قيمةٍ حسبها النظام وقيمةٍ
  //   اختارها إنسان — فإما تمحو إعادةُ الحساب تعديلَ المحاسب، أو تتجمّد
  //   القيمة فيُحسب الصافي ببسطٍ قديم ومقامٍ جديد. **«قيمة موجودة» ليست
  //   «قيمة اختارها إنسان»، والفرق يحتاج علَماً لا استنتاجاً.**
  //   (عطل موثَّق في مشروع DMS المرجعي — بلاغ المالك 2026-08-05.)
  BoolColumn get eligibleDaysIsManual => boolean()
      .named('eligible_days_is_manual')
      .withDefault(const Constant(false))();

  // أيام الغياب المسجَّلة
  IntColumn get absenceDays =>
      integer().named('absence_days').withDefault(const Constant(0))();

  // ── الإجازة في هذا الشهر — **لقطة تُفسّر الرقم** (Schema v10) ───────────
  //
  // 🔴 **بلاغ المالك (2026-09-03):** «أعطيتُ موظفاً إجازة براتب وآخر بلا
  //   راتب، ولم يظهر لي أي شيء عليهما في مسودة الرواتب.»
  //
  // ⚠️ **ولماذا تُخزَّن هنا وقد كانت تُحسَب من الجدول؟** لأن السؤالين
  //   مختلفان: `unpaidLeaveDaysInMonth` تجيب «كم يوماً في هذا الشهر؟» وهي
  //   حسبةٌ حيّة تتغيّر بتعديل الإجازة. وهذا العمود يجيب «**على أي أساس
  //   حُسب هذا السطر؟**» — وهو لقطةٌ يجب ألّا تتغيّر، كـ`snapshot_name`
  //   و`snapshot_hire_date` تماماً.
  //
  //   وبدونه يعرض الكشف عشرين يوماً بلا سبب مكتوب، فيبدو خطأً للمحاسب.
  //   وإجازةُ **الراتب** لا أثر لها في الأرقام إطلاقاً، فتختفي تماماً ما لم
  //   تُكتَب — وهي معلومة إدارية يحتاجها من يقرأ الكشف بعد سنة.
  IntColumn get leaveDaysPaid =>
      integer().named('leave_days_paid').withDefault(const Constant(0))();

  IntColumn get leaveDaysUnpaid =>
      integer().named('leave_days_unpaid').withDefault(const Constant(0))();

  // خصم الغياب المطبَّق فعلاً — **اقتراحٌ يعدّله المستخدم** لا حكم
  RealColumn get absenceDeduction =>
      real().named('absence_deduction').withDefault(const Constant(0.0))();

  // هل عدّل المستخدم خصم الغياب بيده؟ — نظير [eligibleDaysIsManual]
  BoolColumn get absenceDeductionIsManual => boolean()
      .named('absence_deduction_is_manual')
      .withDefault(const Constant(false))();

  // إضافات (مكافآت) — بعملة الموظف
  RealColumn get additions => real().withDefault(const Constant(0.0))();

  // خصومات أخرى — بعملة الموظف
  //
  // ⚠️ **لا تشمل خصم سلفة الموظف** — ذاك في [advanceRepaymentAmount] عمداً:
  //   دمجهما كان يجعل تسجيل قسط السداد في `cash_advance_repayments` مستحيلاً
  //   لأن المبلغ لا يُميَّز عن خصم الغياب أو الجزاء.
  RealColumn get deductions => real().withDefault(const Constant(0.0))();

  // ── خصم سلفة الموظف (Schema v7) ─────────────────────────────────────────

  // المبلغ المخصوم من هذا الراتب سداداً لسلفة الموظف.
  //
  // يقترحه النظام من القسط المستحقّ و**يقرّره المالك** (قرار 2026-08-24).
  // عند التسديد يُدرَج قسطٌ مقابله في `cash_advance_repayments` بطريقة
  // `'salary_deduction'` — وهي قيمة موجودة في ذلك الجدول منذ البداية
  // **وبصفر استعمال**، تُوصَل الآن. ولا سند قبض معها: المال لم يتحرّك، بل
  // خرج راتبٌ أقل.
  RealColumn get advanceRepaymentAmount => real()
      .named('advance_repayment_amount')
      .withDefault(const Constant(0.0))();

  // السلفة المسدَّد منها — بلا مفتاح خارجي عمداً.
  //
  // نظير `vouchers.advance_id`: المفتاح الخارجي هنا كان يقلب ترتيب الحذف في
  // `resetFinancialData` (تُحذف `cash_advances` قبل `salary_payments`)،
  // فيفشل التصفير بقيد أجنبي — وهو بالضبط العطل ع-٠٩.
  IntColumn get cashAdvanceId =>
      integer().named('cash_advance_id').nullable()();

  // ── المحسوب ─────────────────────────────────────────────────────────────

  // الصافي بعملة الموظف = (الأساسي × الأيام ÷ أيام العمل) + مكافأة
  //                       − خصومات − خصم الغياب − خصم السلفة
  //
  // ⚠️ **قد يكون سالباً** حين تتجاوز الخصومات الاستحقاق، وهذا مقصود:
  //   الحساب يقول الحقيقة، وحصرُ السالب في الصفر يُخفي خطأ إدخال بدل كشفه.
  //   المسودة تحتمله ليُصحَّح، و**التسديد هو ما يرفضه**.
  RealColumn get netAmount =>
      real().named('net_amount').withDefault(const Constant(0.0))();

  // سعر الصرف المطبَّق — منسوخ من الكشف لحظة الحساب
  RealColumn get exchangeRate => real().named('exchange_rate').nullable()();

  // **الصافي بالدينار** — الرقم الذي يدخل الدفاتر والتقارير والمطابقة.
  //
  // 🔑 قرار المالك 2026-08-24: **«لا يُحفَظ شيء إلا بمقابله بالدينار»**.
  //   فالراتب بالدولار بلا سعر صرف يُرفض عند الحفظ لا عند التسديد. وبهذا
  //   يستطيع أي تقرير أن يجمع هذا العمود مباشرةً بلا أن يعرف عملة أحد.
  RealColumn get netAmountIqd =>
      real().named('net_amount_iqd').withDefault(const Constant(0.0))();

  // الصافي **كما ذكره ملف الإكسل** — للمقارنة لا للحساب.
  //
  // الملف يصل ومعه إجاباته الحسابية، وغرض المالك المعلَن منه «التدقيق
  // والمراجعة». فنحفظ ما قاله الملف ونحسب بأنفسنا ونُبرز الفرق — نفس مبدأ
  // `advance_lines.original_amount` القائم. null لسطرٍ لم يأتِ من ملف.
  RealColumn get fileNetAmount =>
      real().named('file_net_amount').nullable()();

  // ── التسديد ─────────────────────────────────────────────────────────────

  // تاريخ الصرف
  DateTimeColumn get paymentDate => dateTime().named('payment_date')();

  // حالة الدفع: 'unpaid' | 'paid'
  //
  // على **السطر** لا على الكشف وحده: الكشف شامل لكل الموظفين، والتسديد يقع
  // على دفعات حسب مصدر التمويل — موظفو البصرة من سلفتها وموظفو بغداد من
  // الخزينة الرئيسية. فالكشف لا يصير `posted` إلا حين يُسدَّد كل سطوره.
  TextColumn get paymentStatus =>
      text().named('payment_status').withDefault(const Constant('unpaid'))();

  DateTimeColumn get paidAt => dateTime().named('paid_at').nullable()();

  // الخزينة التي خرج منها المال فعلاً — تُملأ عند التسديد
  IntColumn get treasuryId =>
      integer().named('treasury_id').references(Treasuries, #id).nullable()();

  // معرّف سند الصرف — **مشترك بين كل سطور الدفعة الواحدة** من v7
  IntColumn get voucherId =>
      integer().named('voucher_id').nullable()();

  // ── الربط بسلفة المشروع (Schema v7) — بلا مفاتيح خارجية عمداً ───────────
  //
  // نظير `vouchers.advance_id`: إلغاء سلفة يحذف أسطرها، ومفتاحٌ خارجي هنا
  // كان يمنع الإلغاء أو يتطلّب ترتيب حذف إضافياً في كل مسار.

  // سطر السلفة الذي يغطّي هذا الراتب — يُملأ عند **الربط** في المراجعة،
  // أي قبل الاعتماد. وهو ما يحدّد أي السطور تدخل مطابقة المبلغ.
  IntColumn get advanceLineId =>
      integer().named('advance_line_id').nullable()();

  // السلفة نفسها — تُملأ عند **الاعتماد**، فتصير إجابة سؤال «من أي سلفة
  // سُدِّد راتب هذا الموظف؟» بلا المرور بسطر السلفة.
  IntColumn get advanceId => integer().named('advance_id').nullable()();

  // ── عام ─────────────────────────────────────────────────────────────────

  // ملاحظات
  TextColumn get notes => text().withDefault(const Constant(''))();

  // وقت الإنشاء
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  // وقت آخر تعديل (Schema v7)
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  // حذف ناعم
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  /// قيود على مستوى الجدول (دفاع في العمق — Schema v7)
  ///
  /// ⚠️ لا قيد `net_amount > 0`: الصافي السالب **مسموح في المسودة** ليُصحَّح،
  ///   ويرفضه حارس التسديد. راجع تعليق [netAmount].
  @override
  List<String> get customConstraints => [
        "CHECK (snapshot_currency IN ('IQD', 'USD'))",
        "CHECK (payment_status IN ('unpaid', 'paid'))",
        'CHECK (eligible_days >= 0)',
        'CHECK (absence_days >= 0)',
        'CHECK (absence_deduction >= 0)',
        'CHECK (advance_repayment_amount >= 0)',
        'CHECK (exchange_rate IS NULL OR exchange_rate > 0)',
      ];
}
