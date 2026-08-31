// ─────────────────────────────────────────────────────────────────────────────
// excel_export_service.dart — تصدير التقارير إلى ملف Excel مُنسَّق
//
// ═══ لماذا استُبدل CSV بـ xlsx (بلاغ المالك 2026-08-30) ═══
//   «التصدير إلى PDF التصميم جيد جداً، لكن في الإكسل التصميم غير جيد وبدائي».
//
//   وهو محقّ — و**ليس عيباً في التنفيذ بل حدٌّ في الصيغة**: ملف CSV نصٌّ
//   بفواصل، لا يحمل لوناً ولا خطاً عريضاً ولا عرض أعمدة ولا اتجاهاً. أيّ
//   تصميم فيه مستحيل بنيوياً مهما كُتب من كود.
//
// ═══ والمكسب الأكبر ليس الشكل ═══
//   في CSV كان **كل شيء نصّاً**، فالمالك لا يستطيع جمع عمود مبالغ في Excel
//   ولا فرزه رقمياً — يفرزه أبجدياً فيأتي ٩ بعد ٨٠٠٬٠٠٠. هنا تُكتَب الأرقام
//   **أرقاماً حقيقية** (`DoubleCellValue`) بتنسيق آلاف، فتُجمع وتُفرز وتدخل
//   في معادلات.
//
// ═══ بلا أي تبعية جديدة ═══
//   `excel: ^4.0.6` **مُعلَنة أصلاً** في `pubspec.yaml` وتُستعمل للقراءة في
//   `ExcelSheetReader`. استعمالها في الكتابة لا يمسّ القانون ٥.
//
// ⚠️ **الورقة RTL** (`sheet.isRTL = true`): بدونها يبدأ Excel الأعمدة من
//   اليسار فيقرأ المالك العربي جدولاً معكوساً — سليم البيانات ومقلوب المعنى.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:typed_data';

import 'package:excel/excel.dart';

import 'report_print_data.dart';

/// خدمة تصدير التقارير إلى Excel
abstract final class ExcelExportService {
  /// أقصى عرض عمود — بلا سقف يمدّ «البيان» الورقة إلى ما لا يُطبَع
  static const double _maxColumnWidth = 42;
  static const double _minColumnWidth = 9;

  /// يبني مصنّف Excel من [data] ويُعيده بايتاتٍ جاهزة للحفظ
  ///
  /// [companyName] — يظهر سطراً أعلى العنوان إن وُجد، تماماً كترويسة الـPDF
  static Uint8List build(ReportTableData data, {String companyName = ''}) {
    final excel = Excel.createExcel();

    // ⚠️ **الورقة الافتراضية بلا إعادة تسمية — وهذه مقايضة مقصودة.**
    //   `excel 4.0.6` تُسقط اتّجاه RTL عن أي ورقة أُعيدت تسميتها أو أُنشئت
    //   بعد المصنّف: `rename` تُزيلها من `_xmlSheetId` فلا يجد الحافظُ
    //   ورقتَها ليكتب `rightToLeft`. (تحقّقتُ من الأمرين تجريبياً.)
    //
    //   والمفاضلة: اسمُ تبويبٍ عربي مقابل **اتّجاه الجدول كلّه**. واخترنا
    //   الاتّجاه — فبدونه يقرأ المالك العربي أعمدةً معكوسة، بينما اسم
    //   التقرير موجود في الصفّ الأول بارزاً على أي حال.
    final sheet = excel[excel.getDefaultSheet()!];

    final width = data.columns.length;
    var row = 0;

    // ── ١) الترويسة ──────────────────────────────────────────────────
    if (companyName.trim().isNotEmpty) {
      _merged(sheet, row, width, companyName.trim(),
          _style(bold: true, size: 14, align: HorizontalAlign.Center));
      row++;
    }

    _merged(
      sheet,
      row,
      width,
      data.title,
      _style(
        bold: true,
        size: 13,
        align: HorizontalAlign.Center,
        fg: ExcelColor.white,
        bg: ExcelColor.blueGrey800,
      ),
    );
    row++;

    if (data.subtitle.isNotEmpty) {
      _merged(sheet, row, width, data.subtitle,
          _style(size: 10, align: HorizontalAlign.Center, fg: ExcelColor.grey800));
      row++;
    }

    row++; // سطر فاصل

    // ── ٢) المجاميع ──────────────────────────────────────────────────
    for (final s in data.summary) {
      _cell(sheet, row, 0, TextCellValue(s.label),
          _style(bold: true, bg: ExcelColor.grey200));
      _cell(sheet, row, 1, TextCellValue(s.value),
          _style(bold: true, fg: ExcelColor.blue800));
      row++;
    }
    if (data.summary.isNotEmpty) row++;

    // ── ٣) عناوين الأعمدة ────────────────────────────────────────────
    final headerStyle = _style(
      bold: true,
      fg: ExcelColor.white,
      bg: ExcelColor.blueGrey800,
      align: HorizontalAlign.Center,
      bordered: true,
    );
    for (var c = 0; c < width; c++) {
      _cell(sheet, row, c, TextCellValue(data.columns[c]), headerStyle);
    }
    row++;

    // ── ٤) الصفوف ────────────────────────────────────────────────────
    final bodyStyle = _style(bordered: true);
    final numberStyle = _style(
      bordered: true,
      align: HorizontalAlign.Left,
      numFormat: NumFormat.custom(formatCode: '#,##0'),
    );

    for (final r in data.rows) {
      for (var c = 0; c < width && c < r.length; c++) {
        final raw = r[c];
        final numeric =
            data.numericColumns.contains(c) ? _parseNumber(raw) : null;

        if (numeric != null) {
          _cell(sheet, row, c, DoubleCellValue(numeric), numberStyle);
        } else {
          _cell(sheet, row, c, TextCellValue(raw), bodyStyle);
        }
      }
      row++;
    }

    // ── ٥) الملاحظة المحاسبية ────────────────────────────────────────
    if (data.footerNote != null) {
      row++;
      _merged(sheet, row, width, data.footerNote!,
          _style(size: 9, fg: ExcelColor.grey800, wrap: true));
    }

    // ── ٦) عرض الأعمدة ───────────────────────────────────────────────
    // ℹ️ لا تجميد لصفّ العناوين: `excel 4.0.6` لا تدعم `freezePane`، ولا
    //    نُضيف تبعية لأجله (القانون ٥). والمالك يُجمّده بنقرة في Excel.
    _fitColumns(sheet, data);

    // ⚠️ الاتّجاه **بعد** ملء الورقة: ضبطه قبل إنشاء الخلايا لا يُحفَظ في
    //   `excel 4.0.6` — تُكتَب سمة `rightToLeft` عند الحفظ من حالة الورقة
    //   وقتَها، والورقة الفارغة تُبنى من جديد فتُهمَل.
    sheet.isRTL = true;

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('تعذّر توليد ملف Excel.');
    }
    return Uint8List.fromList(bytes);
  }

  /// اسم ملف صالح على ويندوز
  static String fileNameFor(ReportTableData data) {
    final safe = data.title
        .replaceAll(RegExp(r'[\\/:*?"<>|\[\]]'), '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '${safe.isEmpty ? 'تقرير' : safe}.xlsx';
  }

  // ── مساعدات ──────────────────────────────────────────────────────────────

  static CellStyle _style({
    bool bold = false,
    int? size,
    ExcelColor fg = ExcelColor.black,
    ExcelColor bg = ExcelColor.none,
    HorizontalAlign align = HorizontalAlign.Right,
    bool bordered = false,
    bool wrap = false,
    NumFormat? numFormat,
  }) {
    final border = bordered
        ? Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.grey400,
          )
        : null;
    return CellStyle(
      bold: bold,
      fontSize: size,
      fontColorHex: fg,
      backgroundColorHex: bg,
      horizontalAlign: align,
      verticalAlign: VerticalAlign.Center,
      textWrapping: wrap ? TextWrapping.WrapText : null,
      leftBorder: border,
      rightBorder: border,
      topBorder: border,
      bottomBorder: border,
      numberFormat: numFormat ?? NumFormat.standard_0,
    );
  }

  static void _cell(
    Sheet sheet,
    int row,
    int col,
    CellValue value,
    CellStyle style,
  ) {
    final c = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    c.value = value;
    c.cellStyle = style;
  }

  static void _merged(
    Sheet sheet,
    int row,
    int width,
    String text,
    CellStyle style,
  ) {
    _cell(sheet, row, 0, TextCellValue(text), style);
    if (width > 1) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: width - 1, rowIndex: row),
      );
    }
  }

  /// عرض كل عمود من أطول محتوى فيه — بحدّ أدنى وأقصى
  ///
  /// `setColumnAutoFit` وحده لا يكفي مع العربية: القياس يقع على محارف
  /// لاتينية فتخرج أعمدة النصّ العربي ضيّقة.
  static void _fitColumns(Sheet sheet, ReportTableData data) {
    for (var c = 0; c < data.columns.length; c++) {
      var longest = data.columns[c].length;
      for (final r in data.rows) {
        if (c < r.length && r[c].length > longest) longest = r[c].length;
      }
      final w = (longest + 3).toDouble().clamp(_minColumnWidth, _maxColumnWidth);
      sheet.setColumnWidth(c, w);
    }
  }

  /// يستخرج الرقم من خليّة نسّقناها نحن
  ///
  /// ⚠️ **التحليل آمنٌ هنا لأننا نملك طرفَي العملية**: `report_table_builders`
  ///   هو من كتب النصّ بـ`NumberFormat('#,##0')` وأضاف «د.ع» أو «$» أو «%».
  ///   فالعكس حذفُ ما ليس رقماً — لا تخمين لغة ولا محليّة.
  ///
  ///   ولماذا لا تُمرَّر الأرقام خاماً؟ لأن `ReportTableData.rows` عقدُها
  ///   **نصوصٌ منسَّقة مسبقاً**، والتنسيق قرار محاسبي يقع مرّة واحدة في
  ///   طبقة من يعرف المعنى. عمودٌ رقميّ يُعلَن في `numericColumns` وكفى.
  static double? _parseNumber(String raw) {
    if (raw.trim().isEmpty || raw.trim() == '—') return null;

    final cleaned = raw
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll(RegExp(r'[^0-9.\-]'), '')
        .trim();
    if (cleaned.isEmpty || cleaned == '-' || cleaned == '.') return null;

    return double.tryParse(cleaned);
  }
}
