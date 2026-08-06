// ─────────────────────────────────────────────────────────────────────────────
// number_extensions.dart — امتدادات الأرقام والعملات
//
// هذا الملف يُضيف دوالاً مساعدة على double وint لتنسيق الأرقام
// بالطريقة المناسبة لنظام المحاسبة والخزينة.
//
// الغرض:
//   توحيد تنسيق الأرقام والعملات في جميع شاشات التطبيق.
//   يدعم الدينار العراقي (IQD) والدولار الأمريكي (USD).
//
// كيفية الاستخدام:
//   final amount = 1500000.500;
//   amount.toIQD()           → '1,500,000.500 د.ع'
//   amount.toUSD()           → '$1,500,000.50'
//   amount.toFormattedIQD()  → '1,500,000.500'  (بدون رمز العملة)
//   amount.toCompactIQD()    → '1.5M د.ع'       (مختصر للأرقام الكبيرة)
//   amount.toPercentage()    → '85.5%'
//   amount.isNegative        → false
//   1000.isMultipleOf(500)   → true
// ─────────────────────────────────────────────────────────────────────────────

import 'package:intl/intl.dart';

/// امتدادات double — تنسيق المبالغ والأرقام المالية
extension DoubleExtensions on double {
  // ── تنسيق الدينار العراقي ─────────────────────────────────────────────────

  /// تنسيق المبلغ بالدينار العراقي (3 منازل عشرية + رمز العملة)
  ///
  /// مثال: 1500000.5 → '1,500,000.500 د.ع'
  String toIQD() {
    final formatted = _iqd3Formatter.format(this);
    return '$formatted د.ع';
  }

  /// تنسيق المبلغ بالدينار العراقي بدون رمز العملة
  ///
  /// مثال: 1500000.5 → '1,500,000.500'
  /// الاستخدام: عند الحاجة لعرض الرمز بشكل منفصل
  String toFormattedIQD() => _iqd3Formatter.format(this);

  /// تنسيق مختصر للأرقام الكبيرة (للـ Dashboard)
  ///
  /// مثال:
  ///   1500000    → '1.5M د.ع'
  ///   850000     → '850K د.ع'
  ///   12500      → '12,500 د.ع'
  String toCompactIQD() {
    if (abs() >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M د.ع';
    } else if (abs() >= 1000) {
      return '${(this / 1000).toStringAsFixed(0)}K د.ع';
    }
    return '${abs().toStringAsFixed(0)} د.ع';
  }

  // ── تنسيق الدولار الأمريكي ───────────────────────────────────────────────

  /// تنسيق المبلغ بالدولار الأمريكي (منزلتان عشريتان)
  ///
  /// مثال: 1250.75 → '$1,250.75'
  String toUSD() {
    final formatted = _usdFormatter.format(this);
    return '\$$formatted';
  }

  /// تنسيق الدولار بدون رمز العملة
  ///
  /// مثال: 1250.75 → '1,250.75'
  String toFormattedUSD() => _usdFormatter.format(this);

  // ── تنسيق مخصص ───────────────────────────────────────────────────────────

  /// تنسيق العملة مع رمز مخصص
  ///
  /// [symbol] — رمز العملة (مثل: 'د.ع' أو '$' أو 'EUR')
  /// [decimalPlaces] — عدد المنازل العشرية (افتراضي: 2)
  String toCurrencyWithSymbol({
    required String symbol,
    int decimalPlaces = 2,
  }) {
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: decimalPlaces,
    );
    return '${formatter.format(this)} $symbol';
  }

  // ── تنسيق عام ─────────────────────────────────────────────────────────────

  /// تنسيق كرقم عشري بعدد منازل محدد
  ///
  /// [places] — عدد المنازل العشرية (افتراضي: 2)
  /// مثال: 1234.5678.toDecimal(3) → '1,234.568'
  String toDecimal([int places = 2]) {
    return NumberFormat('#,##0.${'0' * places}').format(this);
  }

  /// تنسيق كنسبة مئوية
  ///
  /// مثال: 0.856 → '85.6%' | 85.6 → '85.6%'
  String toPercentage([int decimalPlaces = 1]) {
    // إذا كانت القيمة أكبر من 1، نفترض أنها نسبة من 100 وليس من 1
    final value = this > 1 ? this : this * 100;
    return '${value.toStringAsFixed(decimalPlaces)}%';
  }

  // ── الحسابات والفحوصات ────────────────────────────────────────────────────

  /// هل المبلغ موجب (قبض)؟
  bool get isPositiveAmount => this > 0;

  /// هل المبلغ سالب (دين)؟
  bool get isNegativeAmount => this < 0;

  /// هل المبلغ صفر؟
  bool get isZeroAmount => this == 0.0;

  /// القيمة المطلقة
  double get absValue => abs();

  /// تحويل القيمة السالبة إلى صفر (للعرض الآمن)
  double get nonNegative => this < 0 ? 0.0 : this;

  /// تقريب إلى منازل عشرية محددة
  ///
  /// [places] — عدد المنازل العشرية
  double roundTo([int places = 3]) {
    final factor = pow10(places);
    return (this * factor).round() / factor;
  }

  // ── الخوارزميات الداخلية ─────────────────────────────────────────────────

  /// حساب 10^n بشكل فعّال بدون استيراد dart:math
  static double pow10(int n) {
    double result = 1;
    for (int i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }
}

/// امتدادات int — للأرقام الصحيحة
extension IntExtensions on int {
  /// تنسيق الرقم مع فواصل الآلاف
  ///
  /// مثال: 1500000 → '1,500,000'
  String toFormattedNumber() => NumberFormat('#,##0').format(this);

  /// تنسيق كدينار عراقي (بدون منازل عشرية)
  ///
  /// مثال: 1500000 → '1,500,000 د.ع'
  String toIQD() => '${toFormattedNumber()} د.ع';

  /// هل هذا الرقم مضاعف لـ [divisor]؟
  ///
  /// مثال: 1000.isMultipleOf(500) → true
  bool isMultipleOf(int divisor) => divisor != 0 && this % divisor == 0;

  /// تحويل الثواني إلى وصف نصي عربي
  ///
  /// مثال: 90 → '1 دقيقة 30 ثانية'
  String toArabicDuration() {
    if (this < 60) return '$this ثانية';
    if (this < 3600) {
      final minutes = this ~/ 60;
      final seconds = this % 60;
      return seconds > 0
          ? '$minutes دقيقة $seconds ثانية'
          : '$minutes دقيقة';
    }
    final hours = this ~/ 3600;
    final minutes = (this % 3600) ~/ 60;
    return minutes > 0
        ? '$hours ساعة $minutes دقيقة'
        : '$hours ساعة';
  }
}

/// امتدادات num? — للأرقام القابلة للـ null
extension NullableNumberExtensions on double? {
  /// تنسيق كدينار عراقي أو نص بديل عند null
  ///
  /// [fallback] — النص البديل (افتراضي: '—')
  String toIQDOrDefault([String fallback = '—']) {
    return this?.toIQD() ?? fallback;
  }

  /// القيمة أو صفر عند null
  double get orZero => this ?? 0.0;
}

// ── المُنسِّقات الثابتة (Cached Formatters) ──────────────────────────────────
// إنشاؤها مرة واحدة وإعادة استخدامها لتحسين الأداء

/// مُنسِّق الدينار العراقي — 3 منازل عشرية
final _iqd3Formatter = NumberFormat('#,##0.000');

/// مُنسِّق الدولار الأمريكي — منزلتان عشريتان
final _usdFormatter = NumberFormat('#,##0.00');
