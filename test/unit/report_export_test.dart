// ─────────────────────────────────────────────────────────────────────────────
// report_export_test.dart — طباعة التقارير وتصديرها (المرحلة ١٥)
//
// **ما يحرسه هذا الملف:**
//   ١. الخط العربي في مستند التقرير العام — نفي `Helvetica` وإثبات `Tajawal`.
//      كان هذا بالضبط ع-٠٥: مستندٌ يُنتَج بنجاح ولا يُقرأ حرفُه.
//   ٢. **اتّجاه ورقة Excel** — بدون RTL يقرأ المالك العربي جدولاً معكوساً.
//   ٣. **الأرقام أرقاماً لا نصّاً** — وإلا تعذّر جمع عمود مبالغ في Excel،
//      وفُرز أبجدياً فجاء ٩ بعد ٨٠٠٬٠٠٠.
//   ٤. أن ما ليس رقماً («—») يبقى نصّاً بدل أن يصير صفراً كاذباً.
//
// النمط (نفس `payroll_pdf_test.dart`): حقن الخطوط من القرص لأن `rootBundle`
// لا يعمل خارج تطبيق حيّ، ثم **تفتيش بايتات الناتج** بتعبير نمطي — لا مقارنة
// صور ولا استخراج نصّ.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:sales_management/core/services/excel_export_service.dart';
import 'package:sales_management/core/services/pdf_service.dart';
import 'package:sales_management/core/services/report_print_data.dart';

void main() {
  late PdfService service;

  pw.Font load(String name) => ArabicPdfFont(
      File('assets/fonts/$name').readAsBytesSync().buffer.asByteData());

  setUp(() {
    service = PdfService(
      regular: load('Tajawal-Regular.ttf'),
      bold: load('Tajawal-Bold.ttf'),
    );
  });

  Set<String> embeddedFonts(Uint8List pdf) {
    final text = String.fromCharCodes(pdf);
    return RegExp(r'/BaseFont\s*/([A-Za-z0-9+\-,._]+)')
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet();
  }

  int pageCount(Uint8List pdf) =>
      RegExp(r'/Type\s*/Page[^s]').allMatches(String.fromCharCodes(pdf)).length;

  bool isValidPdf(Uint8List pdf) =>
      String.fromCharCodes(pdf.take(4)) == '%PDF' && pdf.length > 1000;

  ReportTableData table({int rows = 5, bool landscape = false}) =>
      ReportTableData(
        title: 'كشف حساب: خزنة البصرة',
        subtitle: 'من 2026/01/01 إلى 2026/03/31 · كل المشاريع',
        columns: const ['الرقم', 'التاريخ', 'البيان', 'المبلغ', 'الرصيد'],
        rows: [
          for (var i = 1; i <= rows; i++)
            [
              '$i',
              '2026/03/${(i % 28) + 1}',
              'صرف بانزين ونقل للمشروع رقم $i',
              '${i * 125000}',
              '${i * 500000}',
            ],
        ],
        summary: const [
          (label: 'عدد السندات', value: '5'),
          (label: 'الرصيد النهائي', value: '2,500,000 د.ع'),
        ],
        footerNote: 'التحويلات بين الخزائن ليست مصروفاً.',
        landscape: landscape,
      );

  // ══════════════════════════════════════════════════════════════════════
  group('مستند التقرير العام — الخط العربي', () {
    test('⭐⭐ لا Helvetica إطلاقاً — وإلا خرجت العربية بلا حرف واحد', () async {
      final pdf = await service.generateReportTable(table());
      final fonts = embeddedFonts(pdf);

      expect(fonts.any((f) => f.contains('Helvetica')), isFalse,
          reason: 'Helvetica لا تحوي حرفاً عربياً — ع-٠٥');
      expect(fonts.any((f) => f.contains('Tajawal')), isTrue);
    });

    test('⭐⭐ النصّ العريض بخط عربي عريض لا بـHelvetica-Bold', () async {
      // العناوين وعناوين الأعمدة والمجاميع كلها عريضة — وهي بالضبط ما كان
      // يُرسَم بـHelvetica-Bold في ع-٠٥.
      final pdf = await service.generateReportTable(table());
      expect(embeddedFonts(pdf).any((f) => f.contains('Bold')), isTrue);
    });

    test('⭐ ترويسة شركة عربية لا تكسر الخطوط', () async {
      final pdf = await service.generateReportTable(
        table(),
        header: const PdfCompanyHeader(companyName: 'شركة سند للمقاولات'),
      );
      expect(embeddedFonts(pdf).any((f) => f.contains('Helvetica')), isFalse);
      expect(isValidPdf(pdf), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('بنية المستند', () {
    test('⭐ الورقة طوليّة افتراضاً وعرضيّة عند الطلب', () async {
      final portrait = await service.generateReportTable(table());
      final landscape =
          await service.generateReportTable(table(landscape: true));

      final box = RegExp(r'/MediaBox[^\]]+\]');
      expect(box.firstMatch(String.fromCharCodes(portrait))!.group(0),
          startsWith('/MediaBox[0 0 595'),
          reason: 'A4 طوليّ');
      expect(box.firstMatch(String.fromCharCodes(landscape))!.group(0),
          contains('841.88'),
          reason: 'A4 عرضيّ — الجداول العريضة تتداخل أرقامها على الطوليّ');
    });

    test('⭐⭐ ٦٠ سطراً تُقسَّم على أكثر من صفحة', () async {
      // حجم البيانات جزءٌ من الاختبار: جدولٌ يُختبَر بخمسة صفوف لا يُثبت
      // شيئاً عن تقسيم الصفحات.
      final pdf = await service.generateReportTable(table(rows: 60));
      expect(pageCount(pdf), greaterThan(1));
    });

    test('⭐ تقرير بلا صفوف يُنتج ورقة صالحة — الحارس في الواجهة لا هنا',
        () async {
      final pdf = await service.generateReportTable(
        const ReportTableData(
          title: 'تقرير فارغ',
          columns: ['أ', 'ب'],
          rows: [],
        ),
      );
      expect(isValidPdf(pdf), isTrue);
      // منعُ الطباعة الفارغة مسؤولية `ReportPrintActions._ensureNotEmpty`
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('تصدير Excel', () {
    // بلاغ المالك 2026-08-30: «في الإكسل التصميم غير جيد وبدائي».
    // والسبب أن CSV نصٌّ بفواصل لا يحمل تنسيقاً **بنيوياً** — فاستُبدل
    // بـxlsx حقيقي. والمكسب الأكبر ليس الشكل بل أن الأرقام تخرج أرقاماً.

    Excel open(Uint8List bytes) => Excel.decodeBytes(bytes);

    test('⭐⭐ ملف xlsx صالح يُفتَح ويحمل ورقة واحدة', () {
      final bytes = ExcelExportService.build(table());
      final book = open(bytes);

      expect(book.tables.keys, hasLength(1));
      // اسم التبويب يبقى الافتراضي عمداً — راجع تعليق ExcelExportService.build
      expect(book.tables.values.first.rows, isNotEmpty);
    });

    test('⭐⭐⭐ الورقة RTL — وإلا قرأ المالك جدولاً معكوساً', () {
      final book = open(ExcelExportService.build(table()));
      // 🔴 بدونها يبدأ Excel الأعمدة من اليسار: البيانات سليمة والمعنى مقلوب
      expect(book.tables.values.first.isRTL, isTrue);
    });

    test('⭐⭐⭐ الأعمدة الرقمية تُكتَب أرقاماً لا نصّاً', () {
      // في CSV كان كل شيء نصّاً، فلا يستطيع المالك جمع عمود مبالغ ولا فرزه
      // رقمياً — يفرزه أبجدياً فيأتي ٩ بعد ٨٠٠٬٠٠٠.
      final data = ReportTableData(
        title: 'اختبار الأرقام',
        columns: const ['البند', 'المبلغ'],
        rows: const [
          ['بانزين', '1,250,000 د.ع'],
          ['نقل', '900'],
          ['بلا قيمة', '—'],
        ],
        numericColumns: const {1},
      );

      final sheet = open(ExcelExportService.build(data)).tables.values.first;
      final values = <CellValue?>[];
      for (final row in sheet.rows) {
        for (final cell in row) {
          if (cell?.value != null) values.add(cell!.value);
        }
      }

      // تعود `IntCellValue` للأعداد الصحيحة و`DoubleCellValue` لغيرها —
      // المهمّ أنها **رقم** لا نصّ.
      final numbers = <num>[
        ...values.whereType<IntCellValue>().map((v) => v.value),
        ...values.whereType<DoubleCellValue>().map((v) => v.value),
      ];
      expect(numbers, containsAll(<num>[1250000, 900]),
          reason: 'المبالغ أرقامٌ تُجمع وتُفرز في Excel');
      // «—» ليست رقماً فتبقى نصّاً بدل أن تصير صفراً كاذباً
      expect(values.whereType<TextCellValue>().map((v) => v.value.toString()),
          contains('—'));
    });

    test('⭐⭐ عمود غير مُعلَن رقمياً يبقى نصّاً', () {
      final data = ReportTableData(
        title: 'نصّ',
        columns: const ['رقم السند'],
        rows: const [
          ['00123']
        ],
      );
      final sheet = open(ExcelExportService.build(data)).tables.values.first;
      final all = sheet.rows.expand((r) => r).where((c) => c?.value != null);

      expect(
          all.any((c) =>
              c!.value is DoubleCellValue || c.value is IntCellValue),
          isFalse,
          reason: 'رقم السند «00123» رقماً يفقد أصفاره الأمامية');
    });

    test('⭐⭐ الترويسة والعنوان والمجاميع والملاحظة كلها في الورقة', () {
      final book = open(ExcelExportService.build(
        table(),
        companyName: 'شركة سند للمقاولات',
      ));
      final text = book.tables.values.first.rows
          .expand((r) => r)
          .where((c) => c?.value != null)
          .map((c) => c!.value.toString())
          .join(' | ');

      expect(text, contains('شركة سند للمقاولات'));
      expect(text, contains('كشف حساب: خزنة البصرة'));
      expect(text, contains('من 2026/01/01'));
      expect(text, contains('عدد السندات'));
      expect(text, contains('التحويلات بين الخزائن ليست مصروفاً.'));
    });

    test('⭐ صفّ العناوين مُنسَّق — عريض بخلفية داكنة', () {
      final sheet =
          open(ExcelExportService.build(table())).tables.values.first;

      final headerCell = sheet.rows
          .expand((r) => r)
          .firstWhere((c) => c?.value?.toString() == 'الرقم');

      expect(headerCell!.cellStyle?.isBold, isTrue);
      expect(headerCell.cellStyle?.backgroundColor,
          isNot(ExcelColor.none.colorHex));
    });

    test('⭐ اسم الملف ينتهي بـ.xlsx ويُنقّى من محارف يرفضها ويندوز', () {
      final data = ReportTableData(
        title: 'كشف: خزنة/البصرة *2026*',
        columns: const ['أ'],
        rows: const [
          ['ب']
        ],
      );
      final name = ExcelExportService.fileNameFor(data);

      expect(name, endsWith('.xlsx'));
      for (final bad in const ['/', r'\', ':', '*', '?', '"', '<', '>', '|']) {
        expect(name.contains(bad), isFalse, reason: 'المحرف $bad غير مسموح');
      }
    });

  });
}
