// ─────────────────────────────────────────────────────────────────────────────
// pdf_arabic_font_test.dart — حارس الخط العربي في ملفات PDF
//
// **العطل الذي يمنعه** (بلاغ المالك 2026-08-24 — «العربي غير مفهوم»):
//
//   كانت الشيفرة تحمّل `Tajawal-Regular` وحده وتمرّره:
//       pw.ThemeData.withFont(base: font)      ← بلا bold
//
//   و`ThemeData.withFont` يبني النمط من `TextStyle.defaultStyle()` الذي يضع
//   `fontBold: Font.helveticaBold()`، ثم `copyWith(fontBold: null)` **يُبقي
//   القيمة الافتراضية** لأن `??` لا تستبدل بـ null.
//
//   النتيجة: كل نصّ عريض يُرسَم بـ **Helvetica-Bold** التي لا تحوي حرفاً
//   عربياً واحداً. والسند يستعمل العريض في العنوان ورقم السند وكل تسميات
//   الحقول — فخرج نصفه فارغاً.
//
// **لماذا لم يكشفه أي اختبار سابق؟** لأن `company_identity_test` كان يتحقّق
// أن الناتج ملف PDF صالح فقط — وهو صالح تماماً، لكنه غير مقروء. الملف
// السليم شكلياً والفارغ معنىً يمرّ من كل فحص لا ينظر إلى **محتواه**.
//
// لهذا يفحص هذا الملف الخطوط المضمَّنة فعلاً داخل الـ PDF الناتج.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sales_management/core/services/pdf_service.dart';
import 'package:sales_management/domain/models/voucher_model.dart';

void main() {
  /// تحميل خط من القرص — `rootBundle` لا يعمل خارج تطبيق حيّ
  pw.Font load(String name) => ArabicPdfFont(
        File('assets/fonts/$name').readAsBytesSync().buffer.asByteData(),
      );

  late PdfService service;

  setUp(() {
    service = PdfService(
      regular: load('Tajawal-Regular.ttf'),
      bold: load('Tajawal-Bold.ttf'),
    );
  });

  /// أسماء الخطوط المضمَّنة داخل ملف PDF
  Set<String> embeddedFonts(Uint8List pdf) {
    final text = String.fromCharCodes(pdf);
    return RegExp(r'/BaseFont\s*/([A-Za-z0-9+\-,._]+)')
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet();
  }

  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ لا يُضمَّن Helvetica إطلاقاً — لا تحوي حرفاً عربياً', () async {
    final pdf = await service.generateVoucherReceipt(_voucher());
    final fonts = embeddedFonts(pdf);

    expect(
      fonts.any((f) => f.contains('Helvetica')),
      isFalse,
      reason: 'وجود Helvetica يعني أن نصّاً عربياً رُسم بخط بلا عربية.\n'
          'الخطوط المضمَّنة: $fonts',
    );
  });

  test('⭐ الخط العريض العربي مضمَّن — العنوان والتسميات عريضة', () async {
    final pdf = await service.generateVoucherReceipt(_voucher());
    final fonts = embeddedFonts(pdf);

    expect(
      fonts.any((f) => f.contains('Tajawal') && f.contains('Bold')),
      isTrue,
      reason: 'بلا Tajawal-Bold يخرج كل نصّ عريض فارغاً.\n'
          'الخطوط المضمَّنة: $fonts',
    );
  });

  test('الخط العادي العربي مضمَّن أيضاً', () async {
    final pdf = await service.generateVoucherReceipt(_voucher());
    expect(
      embeddedFonts(pdf).any((f) => f.contains('Tajawal')),
      isTrue,
    );
  });

  test('⭐ ترويسة الشركة العربية العريضة لا تكسر الخطوط', () async {
    // اسم الشركة يُرسَم عريضاً في الترويسة — وهو أول ما يراه القارئ
    final pdf = await service.generateVoucherReceipt(
      _voucher(),
      header: const PdfCompanyHeader(companyName: 'شركة سند للمقاولات العامة'),
    );
    expect(embeddedFonts(pdf).any((f) => f.contains('Helvetica')), isFalse);
  });

  test('الناتج ملف PDF صالح — الفحص الشكلي يبقى قائماً', () async {
    final pdf = await service.generateVoucherReceipt(_voucher());
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
    expect(pdf.length, greaterThan(1000));
  });

  test('⭐ الخطوط تُحمَّل مرة واحدة وتُعاد استعمالها', () async {
    // بلا التخزين يُعاد تحليل ٦٠ كيلوبايت من بيانات الخط عند كل طباعة
    final first = await service.generateVoucherReceipt(_voucher());
    final second = await service.generateVoucherReceipt(_voucher());
    expect(embeddedFonts(first), equals(embeddedFonts(second)));
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ع-٥٢ — الألف المقصورة والياء المنفصلتان (بلاغ المالك 2026-09-01)
  // ═══════════════════════════════════════════════════════════════════════
  //
  // بلاغ المالك: «إيصال الراتب يكتب خصومات **أخري** والصواب **أخرى**».
  // والنصّ في المصدر سليم — العلّة في `basicToIsolatedMappings` داخل حزمة
  // `pdf`: سطرٌ واحد خاطئ من سبعة وثلاثين يُسنِد رسم **ي** إلى رمز **ى**.
  //
  // راجع `ArabicPdfFont` في `pdf_service.dart` للشرح الكامل.

  group('ع-٥٢ · الأشكال المنفصلة', () {
    /// خريطة المحرف ← رقم الرسم كما ستراها الحزمة عند التوليد
    Map<int, int> glyphMap(String fontFile) {
      final font = ArabicPdfFont(
        File('assets/fonts/$fontFile').readAsBytesSync().buffer.asByteData(),
      );
      final built = font.buildFont(PdfDocument()) as PdfTtfFont;
      return built.font.charToGlyphIndexMap;
    }

    for (final file in ['Tajawal-Regular.ttf', 'Tajawal-Bold.ttf']) {
      test('⭐⭐⭐ [$file] ى المنفصلة برسمها هي لا برسم ي', () {
        final map = glyphMap(file);

        // 🔴 قبل الإصلاح: FEEF ← رسم ي (297 في Tajawal-Regular)، فكانت
        //   «أخرى» تُطبع «أخري» في كل إيصال راتب.
        expect(map[0xFEEF], isNotNull);
        expect(map[0xFEEF], map[0x0649]);
        expect(map[0xFEEF], isNot(map[0x064A]));
      });

      test('⭐⭐⭐ [$file] ي المنفصلة لها رسم أصلاً — كانت تختفي', () {
        final map = glyphMap(file);

        // 🔴 قبل الإصلاح: FEF1 غير موجود إطلاقاً (لا في الخطّ ولا في جدول
        //   الحزمة) فعرضه **صفر** — واسمٌ مثل «هادي» أو «الجبوري» يُطبع
        //   بلا يائه الأخيرة، في كل إيصال وكل كشف.
        expect(map[0xFEF1], isNotNull);
        expect(map[0xFEF1], map[0x064A]);
      });

      test('⭐⭐ [$file] الشكلان النهائيان لم يُمسّا', () {
        final map = glyphMap(file);
        // الخطّ يحوي FEF0 و FEF2 أصلاً — إصلاحنا يمسّ المنفصل وحده
        expect(map[0xFEF0], isNotNull);
        expect(map[0xFEF2], isNotNull);
        expect(map[0xFEF0], isNot(map[0xFEF2]));
      });
    }

    test('⭐⭐ الحرفان يُرسمان بعرضٍ حقيقي لا صفر', () {
      final font = ArabicPdfFont(
        File('assets/fonts/Tajawal-Regular.ttf')
            .readAsBytesSync()
            .buffer
            .asByteData(),
      );
      final built = font.buildFont(PdfDocument()) as PdfTtfFont;

      // عرضُ صفرٍ يعني حرفاً غير مرئي — وهو ما كان يقع لـ ي المنفصلة
      expect(built.glyphMetrics(0xFEEF).advanceWidth, greaterThan(0));
      expect(built.glyphMetrics(0xFEF1).advanceWidth, greaterThan(0));
    });
  });
}

/// سند نموذجي بنصوص عربية في المواضع العريضة والعادية معاً
VoucherModel _voucher() => VoucherModel(
      id: 1,
      voucherNumber: 3,
      voucherType: 'kabd',
      treasuryId: 1,
      fiscalPeriodId: 1,
      amount: 5000000,
      currency: 'IQD',
      voucherDate: DateTime(2026, 3, 1),
      personName: 'أحمد محمد الجبوري',
      reason: 'دفعة من العميل',
      itemType: 'دفعة عميل',
      projectName: 'مشروع البصرة',
      invoiceNumber: 'INV-118',
    );
