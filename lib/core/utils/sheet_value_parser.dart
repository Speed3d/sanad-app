// ─────────────────────────────────────────────────────────────────────────────
// sheet_value_parser.dart — تحليل القيم القادمة من خلايا الإكسل
//
// **لماذا هذا الملف موجود؟**
//   نظاما استيراد يقرآن ملفات إكسل يكتبها بشر: مصاريف السلف (Schema v5)
//   وكشوف الرواتب (Schema v7). وكلاهما يواجه المشكلات نفسها — تاريخٌ بصيغ
//   متعدّدة، ومبلغٌ بفواصل آلاف عربية أو لاتينية، وعملةٌ أجنبية مكتوبة نصاً.
//
//   نسخُ هذا المنطق في المستوردَين يعني أن إصلاح خطأ في أحدهما لا يصل
//   للآخر — وهو **بالضبط** ما حذّرت منه قاعدة المشروع: «لا تكتب بديلاً
//   ثالثاً يزيد الفوضى». فالأصل واحد هنا، ويستدعيه الاثنان.
//
// **دوال نقيّة بلا حالة** — تُختبَر مباشرةً بلا قاعدة بيانات ولا واجهة.
// ─────────────────────────────────────────────────────────────────────────────

/// علامات تدل على أن المبلغ ليس بالدينار العراقي
///
/// تُستعمل لكشف قيمة كُتبت بالدولار في عمود يُفترض أنه بالدينار — تسجيلها
/// صامتةً خطأ بمقدار **سعر الصرف كلّه** (500 دولار تُسجَّل 500 ديناراً).
const List<String> kForeignCurrencyMarkers = [
  r'$',
  'usd',
  'دولار',
  '€',
  'eur',
  'يورو',
];

/// محلّل قيم خلايا الإكسل — دوال ثابتة نقيّة
abstract final class SheetValueParser {
  /// تحليل تاريخ نصي
  ///
  /// يدعم `YYYY/MM/DD` و`DD/MM/YYYY` بفواصل `/` أو `-` أو `.`
  /// التمييز بينهما: إذا كان الجزء الأول > 31 فهو سنة.
  ///
  /// يُعيد `null` إذا تعذّر التحليل.
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
    // DateTime يُصحّح التواريخ المستحيلة تلقائياً (31 شباط → 2 آذار)،
    // فنتحقق أن ما خرج هو ما دخل بالضبط.
    if (result.year != year || result.month != month || result.day != day) {
      return null;
    }
    return result;
  }

  /// هل يحمل النصّ علامة عملة أجنبية؟
  static bool hasForeignCurrency(String raw) {
    final lower = raw.toLowerCase();
    return kForeignCurrencyMarkers.any(lower.contains);
  }

  /// رموز العملة وأسماؤها التي تُزال قبل تحليل الرقم
  ///
  /// ⚠️ **إزالتها لا تُلغي كشفها**: [hasForeignCurrency] تفحص النصّ **الخام**
  ///   قبل التنظيف، ويستدعيها مستورد السلف قبل التحليل ليرفض الأجنبي.
  ///   الإزالة هنا تخدم مستورد الرواتب الذي **يقبل** الدولار بسعر صرف —
  ///   فراتبٌ مكتوب `1500$` يجب أن يُقرأ ١٥٠٠ لا أن يُرفض كنصّ غير رقمي.
  ///   (كشفه اختبار `payroll_import_test` قبل أن يصل إلى المالك.)
  static const List<String> _currencyTokens = [
    r'$', '\u20AC', '\uFDFC',
    'usd', 'eur', 'iqd',
    'دولار', 'يورو', 'دينار', 'د.ع', 'دع', 'ريال',
  ];

  /// تحويل الأرقام العربية-الهندية والفارسية إلى لاتينية
  ///
  /// ملفات تُكتَب على أجهزة معرَّبة تحمل `١٥٠٠` بدل `1500`، و`double.tryParse`
  /// تُعيد `null` لها — فيبدو الراتب «غير صالح» وهو مكتوب صحيحاً تماماً.
  static String _latinizeDigits(String s) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      final ai = arabic.indexOf(ch);
      if (ai >= 0) {
        buffer.write(ai);
        continue;
      }
      final pi = persian.indexOf(ch);
      if (pi >= 0) {
        buffer.write(pi);
        continue;
      }
      buffer.write(ch);
    }
    return buffer.toString();
  }

  /// تنظيف نصّ رقمي من فواصل الآلاف والمسافات ورموز العملة
  ///
  /// الفاصلة العربية `،` واللاتينية `,` معاً — ملفات المالك تحمل الاثنتين
  /// حسب إعدادات جهاز من كتبها. والفاصلة العشرية العربية `\u066B` تصير نقطة.
  /// وتُزال محارف التحكّم بالاتجاه التي تتسرّب من النسخ ولا تُرى.
  static String _clean(String raw) {
    var s = _latinizeDigits(raw.trim().toLowerCase());
    for (final token in _currencyTokens) {
      s = s.replaceAll(token, '');
    }
    return s
        .replaceAll(',', '')
        .replaceAll('،', '')
        .replaceAll('\u066B', '.')
        .replaceAll(' ', '')
        .replaceAll('\u00A0', '')
        .replaceAll('\u200F', '')
        .replaceAll('\u200E', '');
  }

  /// تحليل مبلغ **موجب** — يُعيد `null` لأي شيء آخر
  ///
  /// يُستعمل حيث لا معنى للصفر ولا للسالب: مبلغ مصروف، راتب أساسي.
  static double? parseAmount(String raw) {
    final cleaned = _clean(raw);
    if (cleaned.isEmpty) return null;
    final v = double.tryParse(cleaned);
    if (v == null || v <= 0) return null;
    return v;
  }

  /// تحليل مبلغ **يقبل الصفر** — يُعيد `null` للفارغ أو غير الرقمي
  ///
  /// يُستعمل للمكافأة والخصم وسعر الصرف: صفرٌ فيها قيمة مشروعة، ورفضُه
  /// كان يجعل «خصم = 0» يبدو خانةً فارغة لم تُملأ.
  static double? parseSignedAmount(String raw) {
    final cleaned = _clean(raw);
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// تحليل عدد صحيح غير سالب (أيام عمل · أيام غياب)
  static int? parseCount(String raw) {
    final v = parseSignedAmount(raw);
    if (v == null || v < 0) return null;
    return v.round();
  }
}
