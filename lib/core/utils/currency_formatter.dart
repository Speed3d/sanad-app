// ─────────────────────────────────────────────────────────────────────────────
// currency_formatter.dart — أداة تنسيق العملات
//
// هذا الملف يحتوي على كلاس مساعد مركزي لتنسيق الأرقام كعملات في التطبيق.
//
// الغرض:
//   توفير مكان موحد لتنسيق الدينار العراقي (IQD) والدولار الأمريكي (USD)
//   مع دعم تحليل النص العكسي (parse) وتنسيقات مختلفة للسياقات المختلفة.
//
// الفرق بين هذا الملف و number_extensions.dart:
//   - number_extensions.dart: Extensions مباشرة على double/int
//   - هذا الملف: كلاس ثابت يمكن حقنه (Inject) واستخدامه في الـ Providers
//
// كيفية الاستخدام:
//   CurrencyFormatter.formatIQD(1500000.5)     → '1,500,001 د.ع'
//   CurrencyFormatter.formatUSD(1250.75)        → '$1,250.75'
//   CurrencyFormatter.parseAmount('1,500 د.ع') → 1500.0
//   CurrencyFormatter.formatWithSign(+5000)     → '+5,000 د.ع'  (أخضر)
//   CurrencyFormatter.formatWithSign(-3000)     → '-3,000 د.ع'  (أحمر)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:intl/intl.dart';

/// أداة تنسيق العملات المركزية للتطبيق
///
/// جميع الدوال static — لا حاجة لإنشاء instance
abstract final class CurrencyFormatter {
  // ── المُنسِّقات الثابتة (مُنشأة مرة واحدة لتحسين الأداء) ─────────────────

  /// مُنسِّق الدينار العراقي — **بلا كسور** مع فواصل الآلاف
  ///
  /// ⚠️ كان `#,##0.000` فيعرض `1,000.000` (بلاغ المالك 2026-08-24).
  ///   الدينار العراقي بلا فلوس عملياً — لا تُتداوَل كسوره إطلاقاً،
  ///   فالمنازل الثلاث كانت أصفاراً دائمة تُطيل الرقم وتُصعّب قراءته.
  ///
  /// **التقريب للعرض فقط** — القيمة المخزَّنة `double` كاملة الدقة،
  /// وكل الحسابات تجري عليها لا على النصّ المعروض.
  static final _iqd = NumberFormat('#,##0');

  /// مُنسِّق الدولار — **منزلتان** مع فواصل الآلاف
  ///
  /// يبقى بكسرين بقرار المالك: السنت متداوَل فعلاً، وحذفه يجعل
  /// `100.50` تُعرَض `101`.
  static final _usd = NumberFormat('#,##0.00');

  // ── تنسيق الدينار العراقي (IQD) ─────────────────────────────────────────

  /// تنسيق المبلغ بالدينار العراقي مع الرمز
  ///
  /// [amount] — المبلغ المراد تنسيقه
  /// يُعيد: '1,500,000.500 د.ع'
  static String formatIQD(double amount) {
    return '${_iqd.format(amount)} د.ع';
  }

  /// تنسيق الدينار العراقي بدون الرمز
  ///
  /// يُستخدم عند إظهار الرمز في مكان منفصل
  /// يُعيد: '1,500,000.500'
  static String formatIQDNoSymbol(double amount) {
    return _iqd.format(amount);
  }

  /// تنسيق مختصر للأرقام الكبيرة (Dashboard / KPI Cards)
  ///
  /// [amount] — المبلغ
  /// يُعيد:
  ///   >= 1,000,000  → '1.5M د.ع'
  ///   >= 1,000      → '500K د.ع'
  ///   غير ذلك       → '750 د.ع'
  static String formatIQDCompact(double amount) {
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';
    if (abs >= 1000000) {
      return '$sign${(abs / 1000000).toStringAsFixed(1)}M د.ع';
    } else if (abs >= 1000) {
      return '$sign${(abs / 1000).toStringAsFixed(0)}K د.ع';
    }
    return '$sign${abs.toStringAsFixed(0)} د.ع';
  }

  // ── تنسيق الدولار الأمريكي (USD) ─────────────────────────────────────────

  /// تنسيق المبلغ بالدولار الأمريكي مع الرمز
  ///
  /// [amount] — المبلغ المراد تنسيقه
  /// يُعيد: '$1,250.75'
  static String formatUSD(double amount) {
    return '\$${_usd.format(amount)}';
  }

  /// تنسيق الدولار بدون الرمز
  ///
  /// يُعيد: '1,250.75'
  static String formatUSDNoSymbol(double amount) {
    return _usd.format(amount);
  }

  // ── التنسيق الديناميكي حسب العملة ────────────────────────────────────────

  /// تنسيق المبلغ حسب رمز العملة
  ///
  /// [amount]   — المبلغ
  /// [currency] — رمز العملة ('IQD' أو 'USD')
  ///
  /// يُعيد التنسيق المناسب لكل عملة
  static String format(double amount, String currency) {
    return switch (currency.toUpperCase()) {
      'IQD' => formatIQD(amount),
      'USD' => formatUSD(amount),
      _     => '${_iqd.format(amount)} $currency',
    };
  }

  // ── التنسيق مع الإشارة (+ / -) ───────────────────────────────────────────

  /// تنسيق المبلغ مع إشارة الموجب والسالب
  ///
  /// [amount]   — المبلغ (موجب = قبض، سالب = صرف)
  /// [currency] — العملة ('IQD' أو 'USD')
  ///
  /// يُستخدم في كشف الحساب لتوضيح حركة الأموال
  /// مثال: +1500.0 → '+1,500.000 د.ع' | -3000.0 → '-3,000.000 د.ع'
  static String formatWithSign(double amount, {String currency = 'IQD'}) {
    final sign = amount >= 0 ? '+' : '';
    return '$sign${format(amount, currency)}';
  }

  // ── التحليل العكسي (Parse) ────────────────────────────────────────────────

  /// تحليل نص عملة منسقة إلى قيمة double
  ///
  /// يُزيل الرموز والفواصل والمسافات
  /// [text] — النص المراد تحليله
  ///
  /// مثال:
  ///   '1,500,000.500 د.ع' → 1500000.5
  ///   '$1,250.75'         → 1250.75
  ///   '750'               → 750.0
  ///   'abc'               → null
  static double? parseAmount(String text) {
    if (text.trim().isEmpty) return null;

    // تحويل الأرقام الشرقية/العربية والفاصلة العربية
    var s = text
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9')
        .replaceAll('٫', '.')
        .replaceAll('٬', '');

    // الاحتفاظ بالأرقام، الكومة، النقطة وإشارة السالب
    s = s.replaceAll(RegExp(r'[^0-9.,-]'), '');
    if (s.isEmpty || s == '-' || s == '.' || s == ',') return null;

    // التعامل مع الفواصل والنقاط الذكية
    if (s.contains(',') && s.contains('.')) {
      final lastComma = s.lastIndexOf(',');
      final lastDot = s.lastIndexOf('.');
      if (lastDot > lastComma) {
        // النقطة هي الفاصلة العشرية (مثل: 1,500.50)
        s = s.replaceAll(',', '');
      } else {
        // الكومة هي الفاصلة العشرية (مثل: 1.500,50)
        s = s.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (s.contains(',')) {
      final parts = s.split(',');
      if (parts.length == 2 && parts.last.length <= 3) {
        s = '${parts.first}.${parts.last}';
      } else {
        s = s.replaceAll(',', '');
      }
    }

    // إزالة النقاط الزائدة في النهاية (مثل النقطة الموجودة في رمز 'د.ع')
    while (s.endsWith('.') && s.length > 1) {
      s = s.substring(0, s.length - 1);
    }

    return double.tryParse(s);
  }

  /// تحليل نص وإعادة 0.0 عند الفشل بدلاً من null
  ///
  /// [text] — النص المراد تحليله
  static double parseAmountOrZero(String text) => parseAmount(text) ?? 0.0;

  // ── التنسيق المخصص للتقارير ───────────────────────────────────────────────

  /// تنسيق المبلغ لتقارير PDF (أكبر وأوضح)
  ///
  /// [amount]   — المبلغ
  /// [currency] — العملة
  /// يُعيد نصاً بدون فواصل آلاف لسهولة القراءة في التقارير المطبوعة
  static String formatForReport(double amount, {String currency = 'IQD'}) {
    return format(amount, currency);
  }

  /// تنسيق مزدوج — يعرض IQD و USD معاً
  ///
  /// [iqd] — المبلغ بالدينار
  /// [usd] — المبلغ بالدولار
  ///
  /// مثال: '1,500,000.000 د.ع / $1,145.04'
  static String formatDual({required double iqd, required double usd}) {
    return '${formatIQD(iqd)} / ${formatUSD(usd)}';
  }

  // ── مقارنة الأرقام ────────────────────────────────────────────────────────

  /// مقارنة مبلغين مع هامش تسامح (لتجنب مشاكل الأرقام العشرية)
  ///
  /// [a] — المبلغ الأول
  /// [b] — المبلغ الثاني
  /// [tolerance] — الهامش المسموح به (افتراضي: 0.001 دينار)
  ///
  /// يُستخدم في التحقق من تطابق أرصدة الخزائن
  static bool areEqual(double a, double b, {double tolerance = 0.001}) {
    return (a - b).abs() <= tolerance;
  }

  /// هل المبلغ موجب بمقدار ملحوظ؟ (أكبر من الهامش)
  ///
  /// يُستخدم لتجنب عرض رصيد '0.000 د.ع' كـ '-0.001 د.ع' بسبب الدقة العشرية
  static bool isPositive(double amount, {double threshold = 0.001}) {
    return amount > threshold;
  }

  /// هل المبلغ سالب بمقدار ملحوظ؟
  static bool isNegative(double amount, {double threshold = 0.001}) {
    return amount < -threshold;
  }

  // ── الثوابت ───────────────────────────────────────────────────────────────

  /// رمز الدينار العراقي
  static const String iqdSymbol = 'د.ع';

  /// رمز الدولار الأمريكي
  static const String usdSymbol = '\$';

  /// المنازل العشرية للدينار العراقي
  static const int iqdDecimalPlaces = 3;

  /// المنازل العشرية للدولار الأمريكي
  static const int usdDecimalPlaces = 2;
}
