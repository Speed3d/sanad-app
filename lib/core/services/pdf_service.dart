// ─────────────────────────────────────────────────────────────────────────────
// pdf_service.dart — خدمة إنشاء ملفات PDF للتقارير والسندات
//
// تعليقات توضيحية بالعربية:
// هذا الملف يحتوي على الخدمة البرمجية لإنشاء ملفات PDF بدعم كامل للغة العربية (RTL) والخطوط المحمولة.
//
// الوظائف:
//   1. generateVoucherReceipt — إنشاء سند قبض/صرف PDF فردي
//   2. generateVaultStatement — إنشاء كشف حساب خزينة PDF
//   3. generateAdvanceReport  — إنشاء تقرير سلفة مجمعة PDF
//
// ومستندات الرواتب في الجزء `pdf_payroll_documents.dart` (المرحلة ٤):
//   4. generatePayrollSheet      — كشف رواتب الشهر
//   5. generateSalarySlip        — إيصال راتب موظف
//   6. generatePayrollYearReport — تقرير رواتب سنة
//
// **الجزء لا خدمة ثانية:** تحميل الخطوط وبناء النمط هنا هما موضع عطل
// «العربي غير مفهوم» — ونسخة ثانية منهما تعني أن إصلاحاً واحداً لن يصل
// إلى المستندات كلها. راجع `_loadFonts` أدناه.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/models/voucher_model.dart';
import '../extensions/number_extensions.dart';
import '../extensions/string_extensions.dart';
import 'payroll_print_data.dart';
import 'report_print_data.dart';

part 'pdf_payroll_documents.dart';
part 'pdf_report_documents.dart';

/// هوية الشركة على مستندات PDF — الاسم والشعار
///
/// **لماذا كائن يُمرَّر بدل قراءة من قاعدة البيانات هنا؟** (ب-٣ — 2026-08-23)
///   `PdfService` في طبقة `core` ولا يجوز أن تعرف شيئاً عن `data` — وإلا
///   انعكس اتجاه الاعتماد المعماري وصار توليد الـ PDF غير قابل للاختبار بلا
///   قاعدة بيانات. المستدعي هو من يقرأ الإعدادات ويمرّرها.
class PdfCompanyHeader {
  /// اسم الشركة كما أدخله المالك في الإعدادات
  final String companyName;

  /// بايتات الشعار — null إن لم يُرفَع شعار
  final Uint8List? logoBytes;

  const PdfCompanyHeader({this.companyName = '', this.logoBytes});

  /// ترويسة فارغة — تُستعمَل حين يتعذّر قراءة الإعدادات
  ///
  /// المستند يُطبَع بلا ترويسة بدل أن يفشل توليده كلّياً: غياب الشعار
  /// إزعاج، وفشل الطباعة تعطيل.
  static const PdfCompanyHeader empty = PdfCompanyHeader();

  /// هل تستحق العرض؟ (لا اسم ولا شعار = لا ترويسة)
  bool get hasContent => companyName.trim().isNotEmpty || logoBytes != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// عكس أعمدة الجداول — يخدم كل مستندات المكتبة
//
// 🔴 **العلّة (بلاغ المالك 2026-08-30):** «عند فتح كشف الرواتب تبدأ الأسماء
//   من جهة اليسار، وهي يجب أن تبدأ من اليمين لأن اللغة عربية».
//
//   والسبب أن `pw.Table` في حزمة `pdf` **لا تعرف الاتجاه إطلاقاً** — صفر
//   إشارة إلى `Directionality` أو `TextDirection` في مصدرها (تحقّقتُ من
//   الإصدار المثبَّت 3.12.0). فهي ترتّب الأعمدة من اليسار دائماً مهما كان
//   اتّجاه الصفحة، و`textDirection: rtl` على `MultiPage` يضبط النصّ داخل
//   الخليّة لا **ترتيب الأعمدة**.
//
//   ولهذا يخرج جدولٌ عربي معكوساً: التسلسل والاسم في أقصى اليسار، والحالة
//   والتوقيع في أقصى اليمين — عكس ما يقرؤه الإنسان تماماً.
//
// **الحلّ:** نعكس الأعمدة بأنفسنا قبل التسليم — الصفوف والعناوين وخرائط
//   العروض والمحاذاة معاً. وأي جدول جديد يمرّ بهذه الدوال وإلا خرج معكوساً.
// ─────────────────────────────────────────────────────────────────────────────

/// يعكس صفّاً واحداً — العمود الأول يصير الأخير
List<T> rtlRow<T>(List<T> row) => row.reversed.toList();

/// يعكس كل صفوف الجدول
List<List<T>> rtlRows<T>(List<List<T>> rows) =>
    [for (final r in rows) r.reversed.toList()];

/// يعكس خريطة مفهرسة بالعمود (العروض · المحاذاة)
///
/// [count] عدد الأعمدة — المفتاح `i` يصير `count - 1 - i`.
Map<int, T> rtlColumnMap<T>(Map<int, T> map, int count) =>
    {for (final e in map.entries) count - 1 - e.key: e.value};

/// خطّ TrueType عربي — يُصلح **خريطةً معطوبة داخل حزمة `pdf` نفسها**
///
/// 🔴 **ع-٥٢ — بلاغ المالك 2026-09-01: «خصومات أخري» والصواب «أخرى».**
///
/// والنصّ في المصدر **سليم** («خصومات أخرى» بألف مقصورة صحيحة). العلّة في
/// `pdf/lib/src/pdf/font/bidi_utils.dart` — جدول `basicToIsolatedMappings`
/// يحوي سطراً واحداً خاطئاً من سبعة وثلاثين:
///
/// ```dart
/// 0x064A: 0xFEEF, // ي   ← خطأ: FEEF هو الشكل المنفصل لـ ى لا لـ ي
/// ```
///
/// • `U+FEEF` = الشكل المنفصل لـ **ى** (ألف مقصورة)
/// • الشكل المنفصل لـ **ي** هو `U+FEF1`
/// • و`U+0649` (ى) **لا سطر له في الجدول إطلاقاً**
///
/// والحزمة تستعمل هذا الجدول لسدّ نقصٍ حقيقي: الخطوط العربية الحديثة —
/// ومنها Tajawal — لا تُدرج الأشكال المنفصلة في `FE70–FEFF` لأن المحرف
/// الأساس نفسه يحمل الشكل المنفصل. فتُسنِد الحزمة رسم المحرف الأساس إلى
/// رمز الشكل المنفصل. والسطر الخاطئ يُسنِد رسم **ي** إلى رمز **ى**.
///
/// **الأثر المُثبَت تجريبياً على Tajawal:**
///
/// | المحرف | glyph قبل الإصلاح | النتيجة |
/// |---|---|---|
/// | ى منفصلة `FEEF` | **297** — وهو رسم **ي** | «أخرى» تُطبع «أخري» |
/// | ي منفصلة `FEF1` | **null** · عرض **0.0** | **الحرف يختفي كلّياً** |
///
/// ⚠️ **والثاني أخطر من المُبلَّغ عنه ولم يلحظه أحد:** الحرف المنفصل يقع بعد
///   حرفٍ لا يتّصل بما بعده (ا د ذ ر ز و أ إ ة). فاسمٌ مثل **«هادي»** أو
///   **«الجبوري»** كان يُطبع في كل إيصال راتب وكل كشف **بلا يائه الأخيرة**.
///
/// **ولماذا الإصلاح هنا لا في النصّ؟** لأن تعديل «أخرى» إلى «أخري» يُفسد
/// نصّاً سليماً ولا يُصلح الأسماء المبتورة. العلّة في الخريطة فتُصلَح في
/// الخريطة — والمحرفان الصحيحان موجودان في الخطّ أصلاً.
///
/// 📌 **لا تستعمل `pw.Font.ttf` مباشرةً في هذا المشروع** — يحرسه
///   `tech_debt_guard_test`.
class ArabicPdfFont extends pw.TtfFont {
  ArabicPdfFont(super.data);

  /// الأشكال المنفصلة التي تُخطئها الحزمة أو تُغفلها: الرمز ← المحرف الأساس
  static const Map<int, int> _isolatedFixups = {
    0xFEEF: 0x0649, // ى — كانت تُسنَد إلى رسم ي
    0xFEF1: 0x064A, // ي — لم تكن مُسنَدة إطلاقاً فتختفي
  };

  @override
  PdfFont buildFont(PdfDocument pdfDocument) {
    final built = super.buildFont(pdfDocument);
    if (built is! PdfTtfFont) return built;

    final map = built.font.charToGlyphIndexMap;
    for (final entry in _isolatedFixups.entries) {
      final glyph = map[entry.value];
      // خطٌّ بلا المحرف الأساس لا نخترع له رسماً — نتركه كما هو
      if (glyph != null) map[entry.key] = glyph;
    }
    return built;
  }
}

/// خدمة إنشاء ملفات PDF
class PdfService {
  /// [regular] و[bold] — حقن الخطوط بدل تحميلها من الأصول
  ///
  /// الإنتاج يستدعي `PdfService()` بلا معاملات فتُحمَّل من `rootBundle`.
  /// الاختبارات تحقنها من القرص مباشرةً لأن `rootBundle` لا يعمل خارج
  /// تطبيق حيّ — فيبقى توليد الـ PDF قابلاً للاختبار بلا محاكاة.
  PdfService({pw.Font? regular, pw.Font? bold})
      : _arabicRegular = regular,
        _arabicBold = bold;

  /// الخطوط العربية المحمّلة — تُحمَّل مرة واحدة وتُخزَّن
  pw.Font? _arabicRegular;
  pw.Font? _arabicBold;

  /// تحميل الخطوط العربية (Tajawal) من الأصول
  ///
  /// ⚠️ **لماذا خطّان لا خط واحد؟** (إصلاح عطل «العربي غير مفهوم» — 2026-08-24)
  ///
  ///   كانت الشيفرة تحمّل `Tajawal-Regular` وحده وتمرّره:
  ///   ```dart
  ///   _themeWith(fonts)   // ← بلا bold
  ///   ```
  ///   و`ThemeData.withFont` يبني النمط من `TextStyle.defaultStyle()` الذي
  ///   يضع `fontBold: Font.helveticaBold()`، ثم `copyWith(fontBold: null)`
  ///   **يُبقي القيمة الافتراضية** لأن `??` لا تستبدل بـ null.
  ///
  ///   النتيجة: **كل نصّ `fontWeight: bold` كان يُرسَم بـ Helvetica-Bold**،
  ///   وهي لا تحوي حرفاً عربياً واحداً. والسند يستعمل العريض في العنوان
  ///   ورقم السند وكل تسميات الحقول — فبدا نصفه فارغاً أو مشوّهاً.
  ///
  ///   البرهان: توليد سند بلا `bold:` يُضمِّن `Helvetica-Bold` ويطبع
  ///   «Unable to find a font to draw س» لكل حرف؛ ومعه يُضمِّن
  ///   `Tajawal-Bold` بلا تحذير واحد. يحرسه `pdf_arabic_font_test.dart`.
  ///
  /// **ولماذا لا نتراجع إلى Helvetica عند الفشل؟**
  ///   التراجع الصامت كان يُنتج مستنداً يبدو ناجحاً وهو غير مقروء. برنامج
  ///   عربي بالكامل لا معنى لتراجعه إلى خط بلا عربية — الأصدق أن يفشل
  ///   بوضوح فيُعرف السبب فوراً.
  Future<({pw.Font regular, pw.Font bold})> _loadFonts() async {
    if (_arabicRegular != null && _arabicBold != null) {
      return (regular: _arabicRegular!, bold: _arabicBold!);
    }
    final regularData = await rootBundle.load('assets/fonts/Tajawal-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Tajawal-Bold.ttf');
    // `ArabicPdfFont` لا `pw.Font.ttf` — راجع ع-٥٢ أعلى الملف
    _arabicRegular = ArabicPdfFont(regularData);
    _arabicBold = ArabicPdfFont(boldData);
    return (regular: _arabicRegular!, bold: _arabicBold!);
  }

  /// بناء نمط المستند بالخطوط العربية كاملةً
  ///
  /// يملأ **الأربعة** لا `base` وحده: أي فراغ منها يعود تلقائياً إلى
  /// Helvetica بلا عربية. و«المائل» يُربَط بالخط العادي لأن Tajawal بلا
  /// نسخة مائلة — والعادي أفضل ألف مرة من Helvetica-Oblique الفارغة.
  ///
  /// و`fontFallback` شبكة أمان أخيرة لأي نمط لم نتوقّعه.
  pw.ThemeData _themeWith(({pw.Font regular, pw.Font bold}) fonts) {
    return pw.ThemeData.withFont(
      base: fonts.regular,
      bold: fonts.bold,
      italic: fonts.regular,
      boldItalic: fonts.bold,
      fontFallback: [fonts.regular, fonts.bold],
    );
  }

  /// بناء ترويسة الشركة أعلى أي مستند — الشعار يميناً والاسم بجواره
  ///
  /// تُعيد `SizedBox.shrink` حين لا يوجد اسم ولا شعار، فلا تترك فراغاً
  /// أبيض في أعلى الصفحة بلا سبب.
  ///
  /// [header] — هوية الشركة · [accent] — لون الخط الفاصل ليطابق نوع المستند
  pw.Widget _buildCompanyHeader(PdfCompanyHeader header, PdfColor accent) {
    if (!header.hasContent) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (header.logoBytes != null) ...[
              pw.SizedBox(
                width: 42,
                height: 42,
                child: pw.Image(
                  pw.MemoryImage(header.logoBytes!),
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(width: 10),
            ],
            if (header.companyName.trim().isNotEmpty)
              pw.Expanded(
                child: pw.Text(
                  header.companyName.trim(),
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: accent, thickness: 0.8),
        pw.SizedBox(height: 6),
      ],
    );
  }

  /// إنشاء سند قبض أو صرف فردي بصيغة PDF
  Future<Uint8List> generateVoucherReceipt(
    VoucherModel voucher, {
    PdfCompanyHeader header = PdfCompanyHeader.empty,
  }) async {
    final fonts = await _loadFonts();
    final pdf = pw.Document();
    final isKabd = voucher.voucherType == 'kabd';
    final title = isKabd ? 'سند قبض مالي' : 'سند صرف مالي';
    final color = isKabd ? PdfColors.green700 : PdfColors.red700;
    final fmtDate = intl.DateFormat('yyyy/MM/dd HH:mm').format(voucher.voucherDate);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: _themeWith(fonts),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 2),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ── ترويسة الشركة (الشعار والاسم) ────────────────────────
                  _buildCompanyHeader(header, color),

                  // ── ترويسة السند ─────────────────────────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: color,
                        ),
                      ),
                      pw.Text(
                        'رقم السند: #${voucher.voucherNumber}',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Divider(color: color, thickness: 1.5),
                  pw.SizedBox(height: 10),

                  // ── تفاصيل السند ──────────────────────────────────────────
                  _buildPdfRow('التاريخ والوقت:', fmtDate),
                  _buildPdfRow('المبلغ:', voucher.amount.toIQD()),
                  _buildPdfRow('المستفيد / الشخص:', voucher.personName.orDefault('—')),
                  _buildPdfRow('السبب / البيان:', voucher.reason.orDefault('—')),
                  if (voucher.projectName != null)
                    _buildPdfRow('اسم المشروع:', voucher.projectName!),
                  if (voucher.invoiceNumber != null)
                    _buildPdfRow('رقم الفاتورة:', voucher.invoiceNumber!),
                  
                  pw.Spacer(),
                  pw.Divider(color: PdfColors.grey300),

                  // ── التوقيعات ────────────────────────────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text('توقيع المحاسب', style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(height: 25),
                          pw.Text('......................', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('توقيع المستلم', style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(height: 25),
                          pw.Text('......................', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Text('$label ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
