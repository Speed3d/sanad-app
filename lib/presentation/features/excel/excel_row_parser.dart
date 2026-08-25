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

import '../../../core/utils/sheet_value_parser.dart';
import '../../../domain/repositories/i_advance_repository.dart';

// نُعيد تصدير علامات العملة الأجنبية: كانت مُعرَّفة هنا قبل أن تنتقل
// إلى `SheetValueParser` ليتشاركها مستوردا السلف والرواتب.
export '../../../core/utils/sheet_value_parser.dart'
    show kForeignCurrencyMarkers;

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
  /// تحليل تاريخ نصي — يفوّض إلى [SheetValueParser.parseDate]
  ///
  /// 📌 كان منطق التحليل مكتوباً هنا حتى 2026-08-25، ثم انتقل إلى
  ///   `core/utils/sheet_value_parser.dart` ليتشاركه مستورد الرواتب.
  ///   بقاؤه نسختين كان يعني أن إصلاح صيغة تاريخ في أحدهما لا يصل للآخر.
  static DateTime? parseDate(String raw) => SheetValueParser.parseDate(raw);

  /// هل يحمل نص المبلغ علامة عملة أجنبية؟
  static bool hasForeignCurrency(String rawAmount) =>
      SheetValueParser.hasForeignCurrency(rawAmount);

  /// تحليل مبلغ نصي بالدينار — موجب حصراً
  static double? parseAmount(String raw) => SheetValueParser.parseAmount(raw);

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
