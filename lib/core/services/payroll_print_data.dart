// ─────────────────────────────────────────────────────────────────────────────
// payroll_print_data.dart — بيانات مستندات الرواتب المطبوعة (المرحلة ٤)
//
// **لماذا نماذج نقيّة في `core` بدل تمرير صفوف Drift؟**
//   `PdfService` تعيش في `core` ولا يجوز أن تعرف قاعدة البيانات — وإلا انعكس
//   اتجاه الاعتماد المعماري وصار توليد الـ PDF غير قابل للاختبار بلا قاعدة.
//   نفس الحارس الذي وُضع لترويسة الشركة في المرحلة ب-٣.
//
// 🔑 **ولماذا الإجماليات حقولٌ تُمرَّر لا تُحسَب هنا؟**
//   لأن مجموع الرواتب له **مصدر حقيقة واحد**: `PayrollDao.getTotals`. لو جمع
//   المستند سطوره بنفسه لصار المجموع الثاني في النظام، وأي اختلاف بين شاشة
//   الكشف والورقة المطبوعة يجعل الاثنين موضع شكّ. وهذا **حرفياً** ما ضرب
//   المشروع المرجعي DMS: الجمع كان مكرَّراً في ثمانية مواضع فاحتُسب راتبٌ
//   صرفته جهة أخرى.
//
//   لهذا يبنيها `PayrollRepository.buildSheetPrintData` من الـ DAO ويسلّمها
//   جاهزة، والمستند يطبع ما وصله ولا يحسب شيئاً.
// ─────────────────────────────────────────────────────────────────────────────

/// سطر موظف واحد في كشف الرواتب المطبوع
class PayrollSheetPrintRow {
  /// تسلسل السطر في الورقة (١، ٢، ٣…) — لا معرّف قاعدة البيانات
  final int seq;

  /// **لقطة** الاسم والصفة لحظة الشهر لا القيمة الحالية
  ///
  /// تغيير اسم الموظف أو صفته اليوم لا يجوز أن يُعيد كتابة ورقة شهر مضى.
  final String name;
  final String position;

  /// عملة الراتب — `IQD` أو `USD`
  final String currency;

  final double basicSalary;
  final int eligibleDays;
  final int workingDays;
  final int absenceDays;

  /// أيام الإجازة في هذا الشهر — **تُفسّر الأيام المستحقّة**
  ///
  /// بدونها يقرأ المحاسب «٢٠ يوماً» ولا يعرف لماذا، فيظنّها خطأً.
  final int leaveDaysPaid;
  final int leaveDaysUnpaid;

  final double absenceDeduction;
  final double bonus;
  final double deduction;

  /// خصم سلفة الموظف من هذا الراتب
  final double advanceRepayment;

  /// الصافي بعملة الراتب · والصافي بالدينار (متساويان حين تكون العملة دينار)
  final double net;
  final double netIqd;

  final bool isPaid;

  /// أُضيف هذا السطر **بعد** اعتماد الكشف (صرفٌ مباشر متأخّر)
  ///
  /// 🔑 يُشتقّ بمقارنة `created_at` للسطر بـ`posted_at` للكشف — **بلا عمود
  ///   جديد ولا تغيير مخطط**. ووجوده على الورقة ضروري: نسخةٌ طُبعت أمس
  ///   ونسخةٌ اليوم بمجموعين مختلفين تبدو تلاعباً ما لم يُقل سببها.
  final bool addedAfterPosting;

  const PayrollSheetPrintRow({
    required this.seq,
    required this.name,
    required this.position,
    required this.currency,
    required this.basicSalary,
    required this.eligibleDays,
    required this.workingDays,
    required this.absenceDays,
    this.leaveDaysPaid = 0,
    this.leaveDaysUnpaid = 0,
    required this.absenceDeduction,
    required this.bonus,
    required this.deduction,
    required this.advanceRepayment,
    required this.net,
    required this.netIqd,
    required this.isPaid,
    this.addedAfterPosting = false,
  });
}

/// كشف رواتب شهر جاهزاً للطباعة
class PayrollSheetPrintData {
  /// «شباط ٢٠٢٦» — من `PayrollCalculator.periodLabel`
  final String periodLabel;

  final int workingDays;

  /// سعر صرف الشهر المجمَّد — `null` حين لا راتب بالدولار
  final double? exchangeRate;

  /// هل الكشف مُسدَّد بالكامل؟
  final bool isPosted;

  // ── الإجماليات — من `PayrollDao.getTotals` وحدها ────────────────────────
  final int employeeCount;
  final double totalIqd;
  final double paidIqd;
  final double unpaidIqd;

  /// المجموع **كما ذكره ملف المحاسب** — صفر حين لم يُذكر
  ///
  /// يُطبع بجوار المحسوب: الورقة التي تُرفَع للأرشيف يجب أن تحمل الرقمين
  /// معاً، فالفرق بينهما يكشف خطأً في الملف نفسه بعد شهور.
  final double fileTotal;

  final List<PayrollSheetPrintRow> rows;

  /// عمود توقيع فارغ يوقّع فيه الموظف عند الاستلام (قرار المالك 2026-08-26)
  ///
  /// خيار لا ثابت: الورقة التي تُوزَّع على الموظفين تحتاجه، ونسخة الأرشيف
  /// تستغني عنه فتتّسع بقيةُ الأعمدة.
  final bool withSignatureColumn;

  const PayrollSheetPrintData({
    required this.periodLabel,
    required this.workingDays,
    required this.exchangeRate,
    required this.isPosted,
    required this.employeeCount,
    required this.totalIqd,
    required this.paidIqd,
    required this.unpaidIqd,
    required this.fileTotal,
    required this.rows,
    this.withSignatureColumn = false,
  });

  /// هل في الكشف راتبٌ واحد على الأقل بالدولار؟
  bool get hasForeignCurrency => rows.any((r) => r.currency != 'IQD');

  /// فرق المحسوب عن مجموع الملف — `null` حين لا مجموع مذكور أو لا فرق يُذكر
  ///
  /// هامش الدينار الواحد هو نفسه المعتمد في حارس مطابقة السلفة: ما دونه
  /// ضجيج فاصلة عائمة، وما فوقه فرقٌ حقيقي يُعرَض.
  double? get fileTotalGap {
    if (fileTotal <= 0) return null;
    final gap = totalIqd - fileTotal;
    return gap.abs() > 1 ? gap : null;
  }
}

/// إيصال راتب موظف واحد — قصاصة A5
class SalarySlipPrintData {
  final String periodLabel;

  final String employeeName;
  final String position;
  final DateTime? hireDate;

  final String currency;
  final double basicSalary;
  final int eligibleDays;
  final int workingDays;
  final int absenceDays;
  final double absenceDeduction;
  final double bonus;
  final double deduction;
  final double advanceRepayment;
  final double net;
  final double netIqd;
  final double? exchangeRate;

  final bool isPaid;

  /// رقم سند الصرف الذي خرج به الراتب — `null` ما دام غير مسدَّد
  ///
  /// **وجوده على الإيصال ليس زينة:** الإيصال بلا رقم سند لا يمكن ردّه إلى
  /// حركة في الدفاتر، فيصير ورقةً تدّعي دفعاً لا أثر له.
  final int? voucherNumber;

  final DateTime? paidAt;

  /// الخزينة التي خرج منها المال — `null` ما دام غير مسدَّد
  final String? treasuryName;

  const SalarySlipPrintData({
    required this.periodLabel,
    required this.employeeName,
    required this.position,
    required this.hireDate,
    required this.currency,
    required this.basicSalary,
    required this.eligibleDays,
    required this.workingDays,
    required this.absenceDays,
    required this.absenceDeduction,
    required this.bonus,
    required this.deduction,
    required this.advanceRepayment,
    required this.net,
    required this.netIqd,
    required this.exchangeRate,
    required this.isPaid,
    this.voucherNumber,
    this.paidAt,
    this.treasuryName,
  });

  /// هل الراتب بعملة أجنبية؟ — عندها يُطبع الصافي بالعملتين
  bool get isForeign => currency != 'IQD';
}

/// شهر واحد في تقرير السنة
class PayrollYearMonth {
  final int month;

  /// معرّف الكشف — تفتحه الواجهة بالضغط على السطر
  final int periodId;

  final int employeeCount;
  final double totalIqd;
  final double paidIqd;
  final double unpaidIqd;

  /// هل الكشف `posted`؟
  final bool isPosted;

  const PayrollYearMonth({
    required this.month,
    required this.periodId,
    required this.employeeCount,
    required this.totalIqd,
    required this.paidIqd,
    required this.unpaidIqd,
    required this.isPosted,
  });
}

/// حصّة خزينة (مشروع) من رواتب السنة **المسدَّدة**
class PayrollTreasuryShare {
  final int treasuryId;
  final String treasuryName;
  final int employeeCount;
  final double totalIqd;

  const PayrollTreasuryShare({
    required this.treasuryId,
    required this.treasuryName,
    required this.employeeCount,
    required this.totalIqd,
  });
}

/// تقرير رواتب سنة كاملة
class PayrollYearReportData {
  final int year;
  final List<PayrollYearMonth> months;

  /// توزيع المسدَّد على الخزائن — **المسدَّد وحده**
  ///
  /// ⚠️ **ولماذا المسدَّد وحده؟** لأن السطر غير المسدَّد لم يخرج من أي خزينة
  ///   بعد، فنسبته إلى خزينة تعني اختراع حركة مال لم تقع. والخزينة هنا هي
  ///   **التي دفعت** لا التي يتبعها الموظف اليوم: رابط الموظف بمشروعه قابل
  ///   للتغيير غداً، ولو بُني عليه التقرير لأعاد كتابة تاريخٍ مضى.
  final List<PayrollTreasuryShare> treasuryShares;

  const PayrollYearReportData({
    required this.year,
    required this.months,
    required this.treasuryShares,
  });

  int get monthCount => months.length;

  int get postedMonthCount => months.where((m) => m.isPosted).length;

  /// إجماليات السنة — جمعُ أشهرٍ كلٌّ منها جاء من `getTotals` لكشفه
  ///
  /// 📌 الجمع هنا **فوق مصدر الحقيقة لا بديلاً عنه**: لا يقرأ سطراً واحداً
  ///   من قاعدة البيانات، بل يجمع أرقاماً حسبها الـ DAO أصلاً. ويحرس تطابقه
  ///   مع `getTotals` اختبارٌ مخصّص (`payroll_report_test`).
  double get totalIqd => months.fold<double>(0, (s, m) => s + m.totalIqd);

  double get paidIqd => months.fold<double>(0, (s, m) => s + m.paidIqd);

  double get unpaidIqd => months.fold<double>(0, (s, m) => s + m.unpaidIqd);

  bool get isEmpty => months.isEmpty;
}

// ═══════════════════════════════════════════════════════════════════════════
// تقرير الموظف (طلب المالك 2026-08-26)
// ═══════════════════════════════════════════════════════════════════════════

/// شهر واحد في تقرير موظف — **بتفاصيل راتبه كاملةً**
///
/// 🔑 **لماذا كل بند بعموده لا الصافي وحده؟**
///   السؤال الذي يطرحه المالك ليس «كم قبض؟» بل «**لماذا** قبض هذا الرقم؟».
///   صافٍ أقلّ من المتوقّع قد يكون غياباً أو خصم سلفة أو شهراً ناقصاً —
///   وثلاثتها تُعالَج معالجةً مختلفة. الصافي وحده يُنهي السؤال ولا يجيبه.
class EmployeePayrollMonth {
  final int year;
  final int month;

  /// معرّف كشف الشهر — `null` لسطر قديم كُتب قبل توحيد الصرف المباشر
  final int? periodId;

  final String currency;
  final double basicSalary;
  final int eligibleDays;
  final int workingDays;
  final int absenceDays;
  final double absenceDeduction;
  final double bonus;
  final double deduction;
  final double advanceRepayment;

  /// الصافي بعملة الراتب · وبالدينار (متساويان حين تكون العملة دينار)
  final double net;
  final double netIqd;

  final bool isPaid;
  final DateTime? paidAt;

  /// **الخزينة التي خرج منها المال** — لا خزينة الموظف
  ///
  /// قرار المالك 2026-08-26: يريد أن يعرف من **موّل** راتب هذا الشهر، وقد
  /// يكون موظف البصرة قُبض راتبه من الخزينة الرئيسية في شهر بعينه.
  final String? paidFromTreasury;

  final int? voucherNumber;

  const EmployeePayrollMonth({
    required this.year,
    required this.month,
    required this.periodId,
    required this.currency,
    required this.basicSalary,
    required this.eligibleDays,
    required this.workingDays,
    required this.absenceDays,
    required this.absenceDeduction,
    required this.bonus,
    required this.deduction,
    required this.advanceRepayment,
    required this.net,
    required this.netIqd,
    required this.isPaid,
    required this.paidAt,
    required this.paidFromTreasury,
    required this.voucherNumber,
  });
}

/// موظف واحد في تقرير المجموعة — مجاميعه خلال الفترة
///
/// ⚠️ **كل المبالغ هنا بالدينار حصراً.** جمعُ مكافأةٍ بالدولار على أخرى
///   بالدينار يُنتج رقماً بلا معنى، فتُضرب مبالغُ الدولار بسعر صرف شهرها
///   قبل الجمع — بنفس الطريقة التي يُحسب بها `net_amount_iqd`.
class EmployeePayrollSummaryRow {
  final int employeeId;
  final String employeeName;
  final String position;

  /// عدد الأشهر التي له فيها سطر راتب خلال الفترة
  final int monthCount;

  final double totalIqd;
  final double paidIqd;
  final double bonusIqd;

  /// الخصومات كلها بالدينار: خصم الغياب + الخصومات الأخرى
  final double deductionIqd;

  final double advanceRepaymentIqd;

  const EmployeePayrollSummaryRow({
    required this.employeeId,
    required this.employeeName,
    required this.position,
    required this.monthCount,
    required this.totalIqd,
    required this.paidIqd,
    required this.bonusIqd,
    required this.deductionIqd,
    required this.advanceRepaymentIqd,
  });

  double get unpaidIqd => totalIqd - paidIqd;
}

/// تقرير رواتب موظف أو مجموعة موظفين خلال مدى أشهر
///
/// **وضعان في نموذج واحد** (قرار المالك 2026-08-26):
///   • موظف محدَّد ⇒ [months] مملوءة: شهرٌ شهراً بكل تفاصيله
///   • بلا موظف   ⇒ [employees] مملوءة: كل موظفي المشروع بمجاميعهم
///
/// 🔑 **والإجماليات تُحسَب مرّة واحدة هنا** ويقرأها العرضُ والورقةُ معاً.
///   حسابُ الورقة لمجاميعها بنفسها هو بالضبط ما ضرب المشروع المرجعي DMS:
///   رقمان لنفس السؤال، ولا يُعرَف أيّهما الصحيح.
class EmployeePayrollReportData {
  /// «آب 2025 — كانون الأول 2025»
  final String rangeLabel;

  /// اسم الموظف حين يكون التقرير لموظف واحد
  final String? employeeName;

  final String? position;

  /// اسم المشروع/الخزينة حين يُصفّى بها
  final String? treasuryName;

  final List<EmployeePayrollMonth> months;
  final List<EmployeePayrollSummaryRow> employees;

  // ── الإجماليات — مصدرها هذا الكائن وحده ─────────────────────────────
  final int monthCount;
  final double totalIqd;
  final double paidIqd;
  final double bonusIqd;
  final double deductionIqd;
  final double advanceRepaymentIqd;

  const EmployeePayrollReportData({
    required this.rangeLabel,
    required this.employeeName,
    required this.position,
    required this.treasuryName,
    required this.months,
    required this.employees,
    required this.monthCount,
    required this.totalIqd,
    required this.paidIqd,
    required this.bonusIqd,
    required this.deductionIqd,
    required this.advanceRepaymentIqd,
  });

  /// تقرير موظف واحد أم مجموعة؟
  bool get isSingleEmployee => employeeName != null;

  double get unpaidIqd => totalIqd - paidIqd;

  bool get isEmpty => months.isEmpty && employees.isEmpty;
}

/// كشفٌ فيه رواتب «مسدَّدة» بسندٍ محذوف — **مالٌ رجع والسجل يقول صُرف**
///
/// 🔑 **مرآة كاشف السندات اليتيمة** (ع-٤٠ — 2026-08-27): ذاك يبحث عن سندٍ
///   بلا سطور، وهذا عن سطورٍ بلا سند. والحالتان متقابلتان: في الأولى مالٌ
///   خرج بلا سجل، وفي الثانية سجلٌّ بلا مال.
///
/// 📌 ويكشف **العَرَض لا السبب**: أي بابٍ يحذف سند رواتب من حيث لا نتوقّع
///   يُنتج هذه الحالة — وقد أثبتت ستة أبواب سابقة أن سابعاً وارد.
class StalePaidPayroll {
  final int periodId;

  /// «آب ٢٠٢٦»
  final String periodLabel;

  /// عدد السطور المسدَّدة التي فقدت سندها
  final int entryCount;

  final double totalIqd;

  const StalePaidPayroll({
    required this.periodId,
    required this.periodLabel,
    required this.entryCount,
    required this.totalIqd,
  });
}
