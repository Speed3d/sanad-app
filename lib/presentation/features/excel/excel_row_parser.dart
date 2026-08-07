// ─────────────────────────────────────────────────────────────────────────────
// excel_row_parser.dart — تحليل صفوف ملف الإكسل إلى أسطر مسودة
//
// لماذا صنف منفصل عن الشاشة؟
//   هذا المنطق يقرّر ما يدخل الدفاتر وما يُرفض — أخطر ما في مسار الاستيراد.
//   بقاؤه داخل State الشاشة كان يجعله غير قابل للاختبار، وهو آخر ما يجوز
//   تركه بلا اختبار: قاعدة «رفض العملة الأجنبية» تمنع خطأً بمقدار سعر الصرف
//   كله (500 دولار تُسجَّل 500 دينار)، ولا شيء يكشفه لاحقاً.
//
// دوال نقية بلا حالة ولا واجهة — تُختبَر مباشرة.
// ─────────────────────────────────────────────────────────────────────────────

import '../../../domain/repositories/i_advance_repository.dart';

/// علامات تدل على أن المبلغ ليس بالدينار العراقي
///
/// الاستيراد بالدينار حصراً (قرار المالك). أي سطر يحمل إحدى هذه العلامات
/// يُرفض برسالة واضحة بدل تسجيله صامتاً كدينار.
const List<String> kForeignCurrencyMarkers = [
  r'$',
  'usd',
  'دولار',
  '€',
  'eur',
  'يورو',
];

/// نتيجة تحليل ملف كامل
class ExcelParseResult {
  /// الأسطر الصالحة الجاهزة لبناء المسودة
  final List<ParsedAdvanceLine> lines;

  /// رسائل عربية بأخطاء الصفوف المرفوضة
  final List<String> errors;

  const ExcelParseResult({required this.lines, required this.errors});

  /// إجمالي المبالغ الصالحة
  double get total => lines.fold<double>(0, (s, l) => s + l.amount);

  /// هل الملف صالح للتجهيز بالكامل؟
  bool get isValid => errors.isEmpty && lines.isNotEmpty;
}

/// محلّل صفوف الإكسل
abstract final class ExcelRowParser {
  /// تحليل تاريخ نصي
  ///
  /// يدعم `YYYY/MM/DD` و`DD/MM/YYYY` بفواصل `/` أو `-` أو `.`
  /// التمييز بينهما: إذا كان الجزء الأول > 31 فهو سنة.
  ///
  /// يُعيد null إذا تعذّر التحليل.
  static DateTime? parseDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final parts = s.split(RegExp(r'[/\-.]'));
    if (parts.length != 3) return null;

    final a = int.tryParse(parts[0].trim());
    final b = int.tryParse(parts[1].trim());
    final c = int.tryParse(parts[2].trim());
    if (a == null || b == null || c == null) return null;
    if (a <= 0 || b <= 0 || c <= 0) return null;

    final (year, month, day) = a > 31 ? (a, b, c) : (c, b, a);
    if (month > 12 || day > 31) return null;

    final result = DateTime(year, month, day);
    // DateTime يُصحّح التواريخ المستحيلة تلقائياً (31 فبراير → 2 مارس)،
    // فنتحقق أن ما خرج هو ما دخل بالضبط.
    if (result.year != year || result.month != month || result.day != day) {
      return null;
    }
    return result;
  }

  /// هل يحمل نص المبلغ علامة عملة أجنبية؟
  static bool hasForeignCurrency(String rawAmount) {
    final lower = rawAmount.toLowerCase();
    return kForeignCurrencyMarkers.any(lower.contains);
  }

  /// تحليل مبلغ نصي بالدينار
  ///
  /// يتجاهل فواصل الآلاف والمسافات. يُعيد null إذا لم يكن رقماً موجباً.
  static double? parseAmount(String raw) {
    final cleaned = raw
        .trim()
        .replaceAll(',', '')
        .replaceAll('،', '')
        .replaceAll(' ', '');
    if (cleaned.isEmpty) return null;
    final v = double.tryParse(cleaned);
    if (v == null || v <= 0) return null;
    return v;
  }

  /// تحليل صف واحد
  ///
  /// [rowLabel] — تسمية الصف في رسائل الخطأ (مثل: «صف 12»)
  /// يُعيد السطر عند النجاح، أو رسالة الخطأ عند الفشل، أو كليهما null إذا
  /// كان الصف فارغاً تماماً (يُتجاهَل بلا خطأ).
  static ({ParsedAdvanceLine? line, String? error}) parseRow({
    required int rowNumber,
    required String rowLabel,
    required String dateRaw,
    required String amountRaw,
    String itemType = '',
    String reason = '',
    String personName = '',
    String? projectName,
    String? invoiceNumber,
    String? spentBy,
  }) {
    final date = dateRaw.trim();
    final amount = amountRaw.trim();

    // صف فارغ تماماً — يُتجاهَل بلا اعتباره خطأً
    if (date.isEmpty && amount.isEmpty) {
      return (line: null, error: null);
    }

    // ⚠️ الحاجز الأهم: رفض العملة الأجنبية صراحةً.
    // التسجيل الصامت كدينار يعني خطأً بمقدار سعر الصرف كله.
    if (hasForeignCurrency(amount)) {
      return (
        line: null,
        error: '$rowLabel: المبلغ "$amount" ليس بالدينار. '
            'الاستيراد يقبل الدينار العراقي فقط — حوّل المبلغ قبل الاستيراد.',
      );
    }

    final parsedDate = parseDate(date);
    if (parsedDate == null) {
      return (line: null, error: '$rowLabel: تاريخ غير صحيح "$date"');
    }

    final parsedAmount = parseAmount(amount);
    if (parsedAmount == null) {
      return (line: null, error: '$rowLabel: مبلغ غير صحيح "$amount"');
    }

    return (
      line: ParsedAdvanceLine(
        rowNumber: rowNumber,
        date: parsedDate,
        amount: parsedAmount,
        itemType: itemType.trim(),
        reason: reason.trim(),
        personName: personName.trim(),
        projectName: _nullIfEmpty(projectName),
        invoiceNumber: _nullIfEmpty(invoiceNumber),
        spentBy: _nullIfEmpty(spentBy),
      ),
      error: null,
    );
  }

  static String? _nullIfEmpty(String? s) {
    final t = s?.trim() ?? '';
    return t.isEmpty ? null : t;
  }
}
