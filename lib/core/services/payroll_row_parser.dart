// ─────────────────────────────────────────────────────────────────────────────
// payroll_row_parser.dart — تحليل صفوف ملف رواتب الشهر (Schema v7)
//
// **لماذا صنف منفصل عن الشاشة؟**
//   هذا المنطق يقرّر ما يدخل كشف الرواتب وما يُرفض — وهو أخطر ما في مسار
//   الاستيراد. بقاؤه داخل `State` الشاشة يجعله غير قابل للاختبار، وهو آخر
//   ما يجوز تركه بلا اختبار: قاعدة «لا دولار بلا سعر صرف» تمنع خطأً بمقدار
//   سعر الصرف كلّه.
//
// **ما يميّز ملف الرواتب عن ملف مصاريف السلفة:**
//   ملف السلفة يحمل مصاريف خام. أما ملف الرواتب فيصل **ومعه إجاباته
//   الحسابية** — الصافي المستحقّ لكل موظف، ومجموع الرواتب في آخره. وغرض
//   المالك المعلَن منه «التدقيق والمراجعة».
//
//   ⇒ فوظيفتنا ليست أن نحسب **له** بل أن نحسب **معه ونُريه أين اختلفنا**.
//     لهذا نحفظ [ParsedPayrollRow.fileNetAmount] كما ورد، ويقارنه المستدعي
//     بالمحسوب. نفس مبدأ `advance_lines.original_amount` القائم.
// ─────────────────────────────────────────────────────────────────────────────

import '../utils/sheet_value_parser.dart';
import 'payroll_calculator.dart';

/// سطر واحد من ملف الرواتب — بعد التحليل وقبل المطابقة بموظف
class ParsedPayrollRow {
  /// ترتيب السطر بين أسطر الملف الصالحة (يبدأ من ١)
  final int rowNumber;

  /// تسمية الصف في رسائل الخطأ («صف ١٢»)
  final String rowLabel;

  /// اسم الموظف كما ورد — **غير مُطبَّع**، التطبيع في `PayrollNameMatcher`
  final String employeeName;

  /// الصفة الوظيفية
  final String position;

  /// تاريخ التعيين — جزء من مفتاح المطابقة حين يوجد
  final DateTime? hireDate;

  /// أيام العمل المستحقّة كما ذكرها الملف
  ///
  /// `null` ⇒ لم يُعيَّن عمود لها، فيحسبها النظام من تاريخ التعيين.
  final int? eligibleDays;

  /// الراتب الأساسي **بعملة [currency]**
  final double basicSalary;

  /// `'IQD'` أو `'USD'`
  final String currency;

  /// سعر الصرف — **إلزامي مع الدولار** (قرار المالك 2026-08-24)
  final double? exchangeRate;

  /// المكافأة بعملة الموظف
  final double bonus;

  /// الخصومات الأخرى بعملة الموظف
  final double deduction;

  /// أيام الغياب
  final int absenceDays;

  /// الصافي **كما ذكره الملف** — للمقارنة لا للحساب
  final double? fileNetAmount;

  const ParsedPayrollRow({
    required this.rowNumber,
    required this.rowLabel,
    required this.employeeName,
    this.position = '',
    this.hireDate,
    this.eligibleDays,
    required this.basicSalary,
    this.currency = PayrollCurrency.iqd,
    this.exchangeRate,
    this.bonus = 0,
    this.deduction = 0,
    this.absenceDays = 0,
    this.fileNetAmount,
  });

  bool get isForeignCurrency => currency == PayrollCurrency.usd;
}

/// حصيلة تحليل ملف كامل
class PayrollParseResult {
  /// الأسطر الصالحة
  final List<ParsedPayrollRow> rows;

  /// رسائل عربية بأخطاء الصفوف المرفوضة — تُعرَض كلها لا أولها
  final List<String> errors;

  /// المجموع النهائي كما ورد في سطر الإجمالي بالملف (0 إن لم يُعيَّن)
  final double fileTotal;

  const PayrollParseResult({
    required this.rows,
    required this.errors,
    this.fileTotal = 0,
  });

  /// هل في الملف سطر واحد على الأقل بالدولار؟
  bool get hasForeignCurrency => rows.any((r) => r.isForeignCurrency);

  /// هل الملف صالح للتجهيز بالكامل؟
  bool get isValid => errors.isEmpty && rows.isNotEmpty;
}

/// محلّل صفوف ملف الرواتب — دوال نقيّة
abstract final class PayrollRowParser {
  /// علامات الدينار في عمود العملة
  static const List<String> _iqdMarkers = ['iqd', 'دينار', 'د.ع', 'دع'];

  /// تحديد عملة السطر
  ///
  /// [currencyRaw] — عمود العملة إن عُيِّن
  /// [salaryRaw]   — نصّ الراتب نفسه · قد يحمل `$` أو «دولار»
  ///
  /// ⚠️ الفحص يشمل **نصّ الراتب** لا عمود العملة وحده: كثير من الملفات
  ///   تكتب `1500$` في خانة الراتب بلا عمود عملة أصلاً. إهماله كان يسجّل
  ///   ١٥٠٠ دولار على أنها ١٥٠٠ دينار.
  static String parseCurrency(String currencyRaw, String salaryRaw) {
    final c = currencyRaw.trim().toLowerCase();
    if (c.isNotEmpty) {
      if (_iqdMarkers.any(c.contains)) return PayrollCurrency.iqd;
      if (SheetValueParser.hasForeignCurrency(c)) return PayrollCurrency.usd;
    }
    return SheetValueParser.hasForeignCurrency(salaryRaw)
        ? PayrollCurrency.usd
        : PayrollCurrency.iqd;
  }

  /// تحليل صف واحد
  ///
  /// يُعيد السطر عند النجاح، أو رسالة الخطأ عند الفشل، أو كليهما `null`
  /// إذا كان الصف فارغاً تماماً (يُتجاهَل بلا خطأ — الملفات اليدوية مليئة
  /// بصفوف فاصلة فارغة، ورفضُها يُغرق المالك بأخطاء لا معنى لها).
  static ({ParsedPayrollRow? row, String? error}) parseRow({
    required int rowNumber,
    required String rowLabel,
    required String nameRaw,
    String positionRaw = '',
    String hireDateRaw = '',
    String eligibleDaysRaw = '',
    required String salaryRaw,
    String currencyRaw = '',
    String exchangeRateRaw = '',
    String bonusRaw = '',
    String deductionRaw = '',
    String absenceDaysRaw = '',
    String netAmountRaw = '',
  }) {
    final name = nameRaw.trim();
    final salaryText = salaryRaw.trim();

    // صف فارغ تماماً — يُتجاهَل بلا خطأ
    final everything = [
      name,
      salaryText,
      positionRaw,
      hireDateRaw,
      bonusRaw,
      deductionRaw,
      netAmountRaw,
    ].map((e) => e.trim()).where((e) => e.isNotEmpty);
    if (everything.isEmpty) return (row: null, error: null);

    if (name.isEmpty) {
      return (row: null, error: '$rowLabel: اسم الموظف فارغ.');
    }

    final salary = SheetValueParser.parseAmount(salaryText);
    if (salary == null) {
      return (
        row: null,
        error: '$rowLabel: الراتب الأساسي لـ«$name» غير صالح '
            '(«$salaryText») — يجب أن يكون رقماً أكبر من صفر.',
      );
    }

    final currency = parseCurrency(currencyRaw, salaryText);
    final rate = SheetValueParser.parseSignedAmount(exchangeRateRaw);

    // ═══════════════════════════════════════════════════════════════════
    // 🔑 قرار المالك 2026-08-24: لا يُحفَظ رقم بلا مقابله بالدينار
    // ═══════════════════════════════════════════════════════════════════
    // الرفض هنا — **عند الاستيراد** — لا عند التسديد. والرسالة تسمّي
    // الموظف وصفّه ليصحّح المالك الملف بدل أن يبحث عن السبب.
    if (currency == PayrollCurrency.usd && (rate == null || rate <= 0)) {
      return (
        row: null,
        error: '$rowLabel: راتب «$name» بالدولار بلا سعر صرف — '
            'أضف عمود سعر الصرف أو حوّل الراتب إلى الدينار.',
      );
    }

    final days = SheetValueParser.parseCount(eligibleDaysRaw);
    final absence = SheetValueParser.parseCount(absenceDaysRaw) ?? 0;

    if (days != null && days > 31) {
      return (
        row: null,
        error: '$rowLabel: أيام عمل «$name» ($days) أكبر من طول أي شهر.',
      );
    }

    return (
      row: ParsedPayrollRow(
        rowNumber: rowNumber,
        rowLabel: rowLabel,
        employeeName: name,
        position: positionRaw.trim(),
        hireDate: SheetValueParser.parseDate(hireDateRaw),
        eligibleDays: days,
        basicSalary: salary,
        currency: currency,
        exchangeRate: currency == PayrollCurrency.usd ? rate : null,
        bonus: SheetValueParser.parseSignedAmount(bonusRaw) ?? 0,
        deduction: SheetValueParser.parseSignedAmount(deductionRaw) ?? 0,
        absenceDays: absence,
        fileNetAmount: SheetValueParser.parseSignedAmount(netAmountRaw),
      ),
      error: null,
    );
  }

  /// مقارنة الصافي المحسوب بما ذكره الملف
  ///
  /// يُعيد `null` حين يتطابقان أو حين لا يذكر الملف صافياً، ورسالةً عربية
  /// تصف الفرق حين يختلفان.
  ///
  /// **الهامش فلس واحد**: الملفات اليدوية تُقرِّب، والفرق الأصغر من ذلك
  /// ضجيجُ فاصلة عائمة لا خطأ حساب.
  static String? describeNetMismatch({
    required String employeeName,
    required double? fileNet,
    required double computedNet,
  }) {
    if (fileNet == null) return null;
    final diff = computedNet - fileNet;
    if (diff.abs() <= 0.01) return null;
    final sign = diff > 0 ? 'أعلى' : 'أقل';
    return 'صافي «$employeeName» المحسوب $sign من المذكور في الملف '
        'بمقدار ${diff.abs().toStringAsFixed(2)}';
  }
}
