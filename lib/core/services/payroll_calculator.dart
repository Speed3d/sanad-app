// ─────────────────────────────────────────────────────────────────────────────
// payroll_calculator.dart — حساب الرواتب (Schema v7)
//
// **منطق نقيّ**: بلا قاعدة بيانات ولا واجهة ولا Riverpod — دوال ثابتة تُختبَر
// وحدها، على نمط [BalanceGuard] و[FiscalPeriodGuard] القائمين.
//
// **لماذا هنا لا داخل الـ DAO؟**
//   لأن هذا الملف هو **ما يقرّر كم يقبض الموظف**. وضعُه في طبقة تحتاج قاعدة
//   بيانات لتشغيلها يعني أن اختباره يحتاج قاعدة بيانات، فتقلّ الحالات
//   المُختبَرة، وتبقى الحالات الحدّية (شهر ٢٨ يوماً · تعيين منتصف الشهر ·
//   خصم يتجاوز الراتب) بلا تغطية. والـ DAO يستدعيه في كل حفظ، فلا يوجد
//   مسارٌ يُخزَّن فيه صافٍ لم يمرّ من هنا.
//
// **المعادلة الكاملة:**
//   المستحقّ    = الراتب الأساسي × الأيام المستحقّة ÷ أيام العمل
//   الصافي      = المستحقّ + المكافأة − الخصومات − خصم الغياب − خصم السلفة
//   بالدينار    = الصافي × سعر الصرف   (أو الصافي نفسه إن كان بالدينار)
//
// **قرارات المالك التي تحكم هذا الملف (2026-08-24):**
//   • الشهر **ثلاثون يوماً عرفاً** مهما كان طوله التقويمي (مع وضع تقويمي اختياري)
//   • **لا يُحفَظ رقم بلا مقابل بالدينار** — الدولار بلا سعر صرف يُرفض
//   • الغياب والمكافأة والخصم **تُدخَل يدوياً**، والنظام يقترح ولا يفرض
//   • **لا مكافأة نهاية خدمة ولا إجازات** — خارج النطاق نهائياً
// ─────────────────────────────────────────────────────────────────────────────

/// عملات الرواتب المدعومة — تطابق قيم `employees.salary_currency`
abstract final class PayrollCurrency {
  static const String iqd = 'IQD';
  static const String usd = 'USD';
}

/// حالات كشف الرواتب — تطابق قيم `payroll_periods.status`
abstract final class PayrollStatusDb {
  /// مسودة: تُراجَع وتُصحَّح ولا تمسّ رصيد أي خزينة
  static const String draft = 'draft';

  /// مُسدَّد: صار لكل سطر سنده، والتعديل ممنوع
  static const String posted = 'posted';
}

/// حالات دفع سطر الراتب — تطابق قيم `salary_payments.payment_status`
abstract final class PayrollPaymentStatusDb {
  static const String unpaid = 'unpaid';
  static const String paid = 'paid';
}

/// أوضاع احتساب أيام العمل — تطابق `payroll_periods.working_days_mode`
abstract final class WorkingDaysModeDb {
  /// عدد ثابت (٣٠ عرفاً) مهما كان طول الشهر — الافتراض بقرار المالك
  static const String fixed = 'fixed';

  /// عدد أيام الشهر التقويمي فعلياً (٢٨–٣١)
  static const String calendar = 'calendar';
}

/// حاصل حساب سطر راتب واحد — كل ما يُخزَّن محسوباً في مكان واحد
class PayrollAmounts {
  /// الأيام المستحقّة من أيام عمل الشهر
  final int eligibleDays;

  /// خصم الغياب المطبَّق فعلاً (المقترَح أو الذي اختاره المستخدم)
  final double absenceDeduction;

  /// الصافي بعملة الموظف — **قد يكون سالباً**، راجع [PayrollCalculator.netSalary]
  final double netSalary;

  /// الصافي بالدينار العراقي — الرقم الذي يدخل الدفاتر والتقارير
  final double netSalaryIqd;

  const PayrollAmounts({
    required this.eligibleDays,
    required this.absenceDeduction,
    required this.netSalary,
    required this.netSalaryIqd,
  });
}

/// حاسبة الرواتب — منطق مجال نقيّ
abstract final class PayrollCalculator {
  // ── ثوابت ────────────────────────────────────────────────────────────────

  /// العرف المحاسبي: الشهر ثلاثون يوماً مهما كان طوله التقويمي
  ///
  /// قرار المالك 2026-08-24 — ونفس عرف مشروعه المرجعي DMS.
  static const int defaultWorkingDays = 30;

  /// المنازل العشرية المعتمدة في تقريب المبالغ
  ///
  /// منزلتان لا ثلاث: الدينار بلا فلوس متداوَلة، والدولار بسنتَين. والتقريب
  /// عند كل خطوة يمنع تراكم فروق الفاصلة العائمة في مجموع الشهر — وهو
  /// **بالضبط** ما يُفشل مطابقة مجموع الكشف مع مبلغ سطر السلفة بفلسٍ واحد.
  static const int _decimals = 2;

  // ── أيام العمل ───────────────────────────────────────────────────────────

  /// عدد أيام الشهر التقويمي (٢٨ · ٢٩ · ٣٠ · ٣١)
  ///
  /// `DateTime(year, month + 1, 0)` هو «اليوم صفر» من الشهر التالي، أي آخر
  /// يوم في هذا الشهر — ويتعامل Dart مع الشهر ١٣ بترحيله للسنة التالية
  /// تلقائياً، فلا حاجة لحالة خاصة لكانون الأول.
  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// أيام العمل المعتمدة لشهر بعينه بحسب الوضع
  ///
  /// [mode] — [WorkingDaysModeDb.fixed] أو [WorkingDaysModeDb.calendar]
  /// [fixedDays] — العدد الثابت المعتمد حين يكون الوضع `fixed`
  static int resolveWorkingDays(
    String mode,
    int fixedDays,
    int year,
    int month,
  ) =>
      mode == WorkingDaysModeDb.calendar
          ? daysInMonth(year, month)
          : fixedDays;

  /// الأيام المستحقّة للموظف في هذا الشهر
  ///
  /// [workingDays]      — أيام العمل المعتمدة للشهر (٣٠ عادةً)
  /// [hireDate]         — تاريخ التعيين · `null` يعني موظفاً قديماً مستقرّاً
  /// [terminationDate]  — تاريخ إنهاء الخدمة إن وُجد
  ///
  /// يُعيد: كامل [workingDays] للموظف المستقرّ · جزءاً منها لمن عُيِّن أو
  /// أُنهيت خدمته داخل الشهر · وصفراً لمن لم يكن على رأس عمله فيه.
  ///
  /// ═══════════════════════════════════════════════════════════════════════
  /// ⚠️ **الأيام تُسقَط لا تُعدّ — وهذا جوهر الدالة لا تفصيل فيها**
  /// ═══════════════════════════════════════════════════════════════════════
  ///
  /// الشهر هنا مدىً من الأيام المرقّمة `1..workingDays` (عرف ٣٠/٣٦٠)، لا
  /// مجموعةَ أيامٍ تُعدّ. نُسقِط يوم الشهر التقويمي على هذا المدى، ثم يكون
  /// الاستحقاق **طول المدى** بين يوم البدء ويوم الانتهاء.
  ///
  /// **لماذا لا تُعدّ الأيام؟** لأن العدّ يجعل طول الشهر التقويمي يتسرّب إلى
  /// الراتب من **الأسفل** حيث لا سقف يحميه. الحساب الساذج هو:
  /// `min(أيام الحضور, workingDays)` — فيُنتج شباط (٢٨ يوماً) حضوراً كاملاً
  /// قدره **٢٨** فيُصرف `28/30` من الراتب، أي **١٬٨٦٦$ لمن راتبه ٢٬٠٠٠$
  /// وقد داوم الشهر كلّه**. السقف يحمي من الأعلى (٣١ ⇒ ٣٠) ولا يحمي من
  /// الأسفل، فالنيّة المعلنة «الشهر ثلاثون مهما كان طوله» لا تتحقّق إلا في
  /// الشهور الطويلة. (عطل موثَّق في DMS — بلاغ المالك 2026-08-05.)
  ///
  /// **ووضع «تقويمي» لا يحتاج استثناءً:** فيه [workingDays] يساوي طول
  /// الشهر، فيصير الإسقاط محايداً ويعود الحساب إلى الأيام الحقيقية.
  /// **دالّةٌ واحدة تخدم الوضعين** — والفرع الثاني كان سيتباعد عن الأول عند
  /// أول تعديل.
  ///
  /// **وتساوي المعاملة مقصود:** من عُيِّن في اليوم ١٦ يأخذ نصف الشهر في شباط
  /// وتموز معاً. العدّ كان يعطيه ١٣ في شباط و١٦ في تموز عن **الجهد نفسه**.
  static int eligibleDays({
    required int year,
    required int month,
    required int workingDays,
    DateTime? hireDate,
    DateTime? terminationDate,
  }) {
    if (workingDays <= 0) return 0;

    final firstOfMonth = DateTime(year, month, 1);
    final lastOfMonth = DateTime(year, month, daysInMonth(year, month));

    final hire = _dateOnly(hireDate);
    final termination = _dateOnly(terminationDate);

    // عُيِّن بعد نهاية الشهر، أو انتهت خدمته قبل بدايته ⇒ لا استحقاق أصلاً
    if (hire != null && hire.isAfter(lastOfMonth)) return 0;
    if (termination != null && termination.isBefore(firstOfMonth)) return 0;

    // من عُيِّن قبل الشهر (أو بلا تاريخ تعيين مسجَّل) يبدأ من اليوم الأول
    final startDay = (hire == null || !hire.isAfter(firstOfMonth))
        ? 1
        : _payrollDay(hire.day, workingDays);

    // الإنهاء في آخر يوم تقويمي أو بعده = شهرٌ كامل، ولو كان الشهر أقصر
    // من أيام العمل — وإلا نقص راتب من أنهى خدمته في ٢٨ شباط بلا سبب.
    final endDay = (termination != null && termination.isBefore(lastOfMonth))
        ? _payrollDay(termination.day, workingDays)
        : workingDays;

    final days = endDay - startDay + 1;
    if (days < 0) return 0;
    return days > workingDays ? workingDays : days;
  }

  /// إسقاط يومٍ من الشهر التقويمي على مدى أيام العمل
  ///
  /// اليوم ٣١ في شهرٍ من ٣٠ يوم عمل هو اليوم ٣٠ — لا يوماً إضافياً.
  static int _payrollDay(int dayOfMonth, int workingDays) {
    if (dayOfMonth < 1) return 1;
    return dayOfMonth > workingDays ? workingDays : dayOfMonth;
  }

  /// تجريد الوقت من التاريخ — المقارنات هنا بالأيام لا بالساعات
  static DateTime? _dateOnly(DateTime? d) =>
      d == null ? null : DateTime(d.year, d.month, d.day);

  // ── الخصومات ─────────────────────────────────────────────────────────────

  /// خصم الغياب **المقترَح** = (أيام الغياب ÷ أيام العمل) × الراتب الأساسي
  ///
  /// ⚠️ **اقتراحٌ لا حكم.** المستخدم يعدّله، ويُصان تعديله بعلَم
  /// `salary_payments.absence_deduction_is_manual`. بدون ذلك العلَم كانت كل
  /// إعادة حساب تمحو ما أدخله المحاسب بيده وتُعيده إلى الرقم المقترَح بلا
  /// إنذار — **«قيمة موجودة» ليست «قيمة اختارها إنسان»، والفرق يحتاج علَماً
  /// لا استنتاجاً.**
  static double suggestAbsenceDeduction({
    required double basicSalary,
    required int absenceDays,
    required int workingDays,
  }) {
    if (absenceDays <= 0 || workingDays <= 0 || basicSalary <= 0) return 0.0;
    // الغياب لا يتجاوز الشهر: من غاب ٤٠ يوماً في شهر ثلاثيني غاب الشهر كلّه،
    // وبلا هذا السقف يصير الخصم أكبر من الراتب بخطأ إدخال واحد.
    final capped = absenceDays > workingDays ? workingDays : absenceDays;
    return _round(basicSalary * capped / workingDays);
  }

  // ── الصافي ───────────────────────────────────────────────────────────────

  /// صافي الراتب **بعملة الموظف**
  ///
  /// [basicSalary]       — الراتب الأساسي بعملة الموظف
  /// [eligibleDays]      — الأيام المستحقّة (من [eligibleDays])
  /// [workingDays]       — أيام العمل المعتمدة للشهر
  /// [bonus]             — المكافأة · بعملة الموظف
  /// [deduction]         — خصومات أخرى · بعملة الموظف
  /// [absenceDeduction]  — خصم الغياب المطبَّق
  /// [advanceRepayment]  — المخصوم سداداً لسلفة الموظف
  ///
  /// ⚠️ **قد يعود سالباً** حين تتجاوز الخصومات الاستحقاق — وهذا مقصود:
  ///   الحساب يقول الحقيقة، وحصرُ السالب في الصفر يُخفي خطأ إدخال بدل أن
  ///   يكشفه. **المسودة تحتمله ليُصحَّح، والتسديد هو ما يرفضه**
  ///   (راجع [ensurePayable]).
  static double netSalary({
    required double basicSalary,
    required int eligibleDays,
    required int workingDays,
    double bonus = 0.0,
    double deduction = 0.0,
    double absenceDeduction = 0.0,
    double advanceRepayment = 0.0,
  }) {
    if (workingDays <= 0) {
      throw StateError('أيام العمل في الشهر يجب أن تكون أكبر من صفر.');
    }
    final earned = _round(basicSalary * eligibleDays / workingDays);
    return _round(
      earned + bonus - deduction - absenceDeduction - advanceRepayment,
    );
  }

  // ── التحويل إلى الدينار ──────────────────────────────────────────────────

  /// هل يمكن تحويل هذه العملة بالسعر المتاح؟ (الدينار لا يحتاج سعراً)
  ///
  /// تُستعمل في الواجهة لعرض تحذير **قبل** أن يرمي [toIqd].
  static bool hasUsableRate(String currency, double? rate) =>
      currency != PayrollCurrency.usd || (rate != null && rate > 0);

  /// المعادل بالدينار العراقي
  ///
  /// ═══════════════════════════════════════════════════════════════════════
  /// ⚠️ **ترمي عند غياب سعر الصرف — ولا تُعيد صفراً**
  /// ═══════════════════════════════════════════════════════════════════════
  ///
  /// قرار المالك 2026-08-24 صريح: **«لا يُحفَظ شيء إلا بمقابله بالدينار،
  /// وأي مبلغ بالدولار يجب أن يكون له سعر صرف»**. فالرفض يقع **عند الحفظ**
  /// لا عند التسديد.
  ///
  /// 📌 **وهذا يخالف المشروع المرجعي DMS عمداً**، وهناك تُعيد نظيرتُها صفراً
  ///   مؤقّتاً. السبب أن كشفهم **يُولَّد من قاعدة البيانات قبل أن يُدخل
  ///   المحاسب سعر الصرف**، فالرمي كان يُنتج قفلاً مغلقاً: لا يستطيع إنشاء
  ///   الشهر ليضع فيه السعر، ولا وضع السعر قبل إنشاء الشهر.
  ///   **عندنا السعر يصل داخل ملف الإكسل نفسه** مع بيانات الموظف، فلا قفل
  ///   ولا مبرّر للتساهل. والصفر الصامت أسوأ الاحتمالات: راتبٌ بألفَي دولار
  ///   يدخل الدفاتر بصفر دينار ويمرّ من كل مجموع بلا أن يشتكي شيء.
  static double toIqd(double net, String currency, double? rate) {
    if (currency != PayrollCurrency.usd) return _round(net);
    if (rate == null || rate <= 0) {
      throw StateError(
        'راتب بالدولار بلا سعر صرف — حدّد سعر صرف الشهر قبل الحفظ.\n'
        'لا يُحفَظ مبلغ في الدفاتر بلا مقابله بالدينار.',
      );
    }
    return _round(net * rate);
  }

  // ── حرّاس التسديد ────────────────────────────────────────────────────────

  /// حارس التسديد: يمنع تجميد سطرٍ صافيه سالب
  ///
  /// ما يُتساهَل معه في المسودة يُرفض هنا — **التسديد لا رجعة فيه** (قرار
  /// المالك: التعديل بعد التسديد ممنوع، والتصحيح بالحذف وإعادة الإنشاء).
  static void ensurePayable(String employeeName, double netSalary) {
    if (netSalary < 0) {
      throw StateError(
        'صافي راتب «$employeeName» سالب ($netSalary) — '
        'راجع الخصومات قبل التسديد.',
      );
    }
  }

  /// حارس التسديد: كشفٌ فيه رواتب بالدولار لا يُسدَّد بلا سعر صرف للشهر
  ///
  /// طبقة ثانية فوق [toIqd]: تلك تحرس **السطر** عند حسابه، وهذه تحرس
  /// **الكشف** عند تسديده — فلو دخل سطرٌ بطريق آخر (استعادة نسخة قديمة
  /// مثلاً) لا يمرّ التسديد بلا سعر.
  static void ensureRateSet({
    required bool hasForeignCurrency,
    required double? rate,
  }) {
    if (hasForeignCurrency && (rate == null || rate <= 0)) {
      throw StateError(
        'الكشف يحتوي رواتب بالدولار — حدّد سعر صرف الشهر قبل التسديد.',
      );
    }
  }

  // ── الحساب الكامل لسطر واحد ──────────────────────────────────────────────

  /// حساب سطر راتب كامل — الدالة التي يستدعيها المستودع في كل حفظ
  ///
  /// ═══════════════════════════════════════════════════════════════════════
  /// 🔴 **الغياب يُخصَم مرّة واحدة — لا مرّتين**
  /// ═══════════════════════════════════════════════════════════════════════
  ///
  /// **العطل الذي أصلحته هذه القاعدة** (بلاغ المالك 2026-08-25):
  ///   ملف المحاسب يذكر **الراتب الفعلي** و**أيام العمل الصافية** و**أيام
  ///   الغياب** معاً — وكلاهما تعبيرٌ عن الواقعة نفسها:
  ///     أساسي 3,000,000 · داوم 25 يوماً · غاب 5 · والملف يقول الصافي
  ///     2,500,000 (استُقطع 500,000 للغياب).
  ///
  ///   والحساب القديم كان يطبّق **الاثنين**:
  ///     المستحقّ  = 3,000,000 × 25/30 = 2,500,000   ← الغياب خُصم بالأيام
  ///     ثم خصم غياب = 3,000,000 × 5/30  =   500,000   ← وخُصم ثانيةً كمبلغ
  ///     الصافي   = 2,000,000                        ← **أقلّ بـ500,000**
  ///
  ///   وعلى 47 موظفاً بلغ الفرق **3,661,667 د.ع** في كشف واحد.
  ///
  /// **القاعدة الآن — ثلاثة مسارات، كلٌّ يخصم مرّة واحدة فقط:**
  ///
  /// | ما وصل | الأيام المستحقّة | خصم الغياب |
  /// |---|---|---|
  /// | الملف ذكر **أيام العمل** | كما ذكرها — الغياب مطروح منها أصلاً | **صفر** |
  /// | المالك أدخل **مبلغ خصم** بيده | كاملة (من التعيين) | المبلغ الذي أدخله |
  /// | **أيام غياب** فقط | الكاملة **ناقص** أيام الغياب | **صفر** |
  ///
  /// ⚠️ **ولا مسار رابع.** أي إضافة هنا يجب أن تُجيب أولاً: «هل تخصم الغياب
  ///   مرّةً ثانية؟» — فهذا العطل لم يظهر في اختبارات الوحدة لأن كلّاً من
  ///   المسارين كان صحيحاً **وحده**، والخلل في اجتماعهما.
  ///
  /// [manualEligibleDays] — أيام العمل كما ذكرها الملف (أو عدّلها المالك)
  /// [manualAbsenceDeduction] — مبلغ خصم الغياب حين يختاره المالك بيده
  static PayrollAmounts compute({
    required int year,
    required int month,
    required int workingDays,
    required double basicSalary,
    required String currency,
    double? exchangeRate,
    DateTime? hireDate,
    DateTime? terminationDate,
    int absenceDays = 0,
    double bonus = 0.0,
    double deduction = 0.0,
    double advanceRepayment = 0.0,
    int? manualEligibleDays,
    double? manualAbsenceDeduction,
  }) {
    // الأيام المستحقّة من التعيين/الإنهاء — قبل أي أثر للغياب
    final fromDates = eligibleDays(
      year: year,
      month: month,
      workingDays: workingDays,
      hireDate: hireDate,
      terminationDate: terminationDate,
    );

    final int days;
    final double absence;

    if (manualEligibleDays != null) {
      // ── المسار ١: الملف (أو المالك) ذكر الأيام النهائية ───────────────
      // 25 يوماً تعني «هذا ما يستحقّه» — والغياب مطروح منها. طرحُه ثانيةً
      // كمبلغ هو العطل نفسه.
      days = manualEligibleDays.clamp(0, workingDays);
      absence = 0.0;
    } else if (manualAbsenceDeduction != null) {
      // ── المسار ٢: المالك اختار مبلغ الخصم بيده ────────────────────────
      // الأيام تبقى كاملة، والخصم بالمبلغ الذي كتبه — فهو يعرف قيمته
      // (جزاء غياب مخفَّف مثلاً) ولا يريد نسبة حسابية.
      days = fromDates;
      absence = manualAbsenceDeduction;
    } else {
      // ── المسار ٣: أيام غياب فقط ───────────────────────────────────────
      // الغياب يُعبَّر عنه **بالأيام** لا بمبلغ: أوضح في الكشف، ويتفادى
      // فروق التقريب بين نسبةٍ ومبلغ.
      final capped = absenceDays > fromDates ? fromDates : absenceDays;
      days = fromDates - capped;
      absence = 0.0;
    }

    final net = netSalary(
      basicSalary: basicSalary,
      eligibleDays: days,
      workingDays: workingDays,
      bonus: bonus,
      deduction: deduction,
      absenceDeduction: absence,
      advanceRepayment: advanceRepayment,
    );

    return PayrollAmounts(
      eligibleDays: days,
      absenceDeduction: absence,
      netSalary: net,
      netSalaryIqd: toIqd(net, currency, exchangeRate),
    );
  }

  // ── أسماء الشهور ─────────────────────────────────────────────────────────

  /// الاسم العربي العراقي للشهر — يظهر في الكشف والسند وشبكة الأشهر
  ///
  /// الأسماء السريانية هي المستعملة في العراق («شباط» لا «فبراير»).
  static String arabicMonth(int month) {
    const names = [
      'كانون الثاني',
      'شباط',
      'آذار',
      'نيسان',
      'أيار',
      'حزيران',
      'تموز',
      'آب',
      'أيلول',
      'تشرين الأول',
      'تشرين الثاني',
      'كانون الأول',
    ];
    if (month < 1 || month > 12) return '$month';
    return names[month - 1];
  }

  /// تسمية الشهر الكاملة للعرض والطباعة: «شباط 2025»
  static String periodLabel(int year, int month) =>
      '${arabicMonth(month)} $year';

  // ── أدوات داخلية ─────────────────────────────────────────────────────────

  /// تقريب إلى منزلتين عشريتين
  ///
  /// يُطبَّق عند **كل خطوة** لا في النهاية فقط: جمع أرقامٍ غير مقرَّبة ثم
  /// تقريب المجموع يُنتج فرقاً عن مجموع الأرقام المقرَّبة — وهو فرقٌ يكفي
  /// لإفشال مطابقة مجموع الكشف مع مبلغ سطر السلفة.
  static double _round(double value) {
    final factor = _pow10(_decimals);
    return (value * factor).roundToDouble() / factor;
  }

  static double _pow10(int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}
