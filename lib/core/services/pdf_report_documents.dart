// ─────────────────────────────────────────────────────────────────────────────
// pdf_report_documents.dart — مستند التقرير الجدوليّ العام
//
// **جزء من مكتبة `pdf_service.dart` لا خدمة ثانية** — تماماً كـ
// `pdf_payroll_documents.dart`. السبب واحد: مسار تحميل الخطوط العربية
// (`_loadFonts` · `_themeWith`) يجب أن يبقى **واحداً**. خدمةٌ ثانية تعني
// مساراً ثانياً، ونسيان أحد الأنماط الأربعة فيه يُعيد ع-٠٥ حرفياً — نصّ
// عريض يُرسَم بـ Helvetica-Bold بلا حرف عربي واحد.
//
// ═══ ما الذي حلّ محلّه هذا الملف ═══
//   كان في `pdf_service.dart` مولّدان: `generateVaultStatement` و
//   `generateAdvanceReport` — **مكتوبان بالكامل وبصفر مستدعٍ في المشروع
//   كلّه**. وكانا خارج نمط المرحلة ب-٣: بلا ترويسة شركة، وبلا ذيل ترقيم،
//   و`generateVaultStatement` كان **يستقبل `openingBalance` ولا يستعمله
//   إطلاقاً** — فيطبع كشف حساب بلا رصيد افتتاحي ولا تراكمي.
//
//   وهو نمط ع-٠٦ نفسه: «الشعار يُكتَب ولا يُقرأ قط». الكود موجود والميزة
//   معطَّلة بصمت لأن أحداً لم يصلها بزرّ.
//
//   استُبدلا بمولّد **واحد** يخدم التقارير الستّة كلها، ويصله زرّ في كل
//   تبويب. والقاعدة المعتمدة في هذا المشروع: إمّا يُوصَل فيحيا، أو يُحذف.
//   لا ثالث.
// ─────────────────────────────────────────────────────────────────────────────

part of 'pdf_service.dart';

/// مستندات التقارير الجدوليّة — امتداد على [PdfService]
extension PdfReportDocuments on PdfService {
  /// تقرير جدوليّ عامّ — يخدم تبويبات التقارير الستّة
  ///
  /// [data]   — بيان **نقيّ** بصفوف منسَّقة مسبقاً (راجع `ReportTableData`)
  /// [header] — هوية الشركة؛ غيابها يطبع بلا ترويسة ولا يُفشل الطباعة
  ///
  /// الورقة عرضيّة حين `data.landscape` — الجداول التي تتجاوز ستّة أعمدة
  /// تُضغط على A4 الطوليّ حتى تتداخل أرقامها.
  Future<Uint8List> generateReportTable(
    ReportTableData data, {
    PdfCompanyHeader header = PdfCompanyHeader.empty,
  }) async {
    final fonts = await _loadFonts();
    final pdf = pw.Document();
    const accent = PdfColors.blueGrey800;

    final printedAt = intl.DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat:
            data.landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 26),
        theme: _themeWith(fonts),
        textDirection: pw.TextDirection.rtl,
        footer: (ctx) => _payrollFooter(ctx, printedAt),
        build: (pw.Context context) => [
          _buildCompanyHeader(header, accent),
          _reportTitle(data, accent),
          pw.SizedBox(height: 10),
          if (data.summary.isNotEmpty) ...[
            _reportSummary(data.summary, accent),
            pw.SizedBox(height: 12),
          ],
          if (data.rows.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 28),
              child: pw.Center(
                child: pw.Text(
                  'لا توجد بيانات في هذه الفترة.',
                  style: const pw.TextStyle(
                      fontSize: 12, color: PdfColors.grey700),
                ),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              // ↔️ معكوسة — `pw.Table` لا تعرف الاتّجاه، راجع pdf_service.dart
              headers: rtlRow(data.columns),
              data: rtlRows(data.rows),
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: accent),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: .5),
                ),
              ),
              headerPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            ),
          if (data.footerNote != null) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(7),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                data.footerNote!,
                style:
                    const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
              ),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }
}

// ── ودجتات المستند ───────────────────────────────────────────────────────────

/// عنوان التقرير وسطر فلاتره وعدد صفوفه
///
/// عدد الصفوف مطبوع عمداً: ورقةٌ لا تقول كم صفّاً فيها لا يُعرف إن كانت
/// كاملة أم انقطعت عند حدّ ما.
pw.Widget _reportTitle(ReportTableData data, PdfColor accent) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        data.title,
        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
      ),
      if (data.subtitle.isNotEmpty) ...[
        pw.SizedBox(height: 3),
        pw.Text(
          data.subtitle,
          style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
        ),
      ],
      pw.SizedBox(height: 3),
      pw.Text(
        'عدد السطور: ${data.rowCount}',
        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
      ),
      pw.SizedBox(height: 5),
      pw.Divider(color: accent, thickness: 0.8),
    ],
  );
}

/// بطاقات المجاميع — صفٌّ متعدّد يلتفّ إن ضاق العرض
pw.Widget _reportSummary(List<ReportSummaryLine> summary, PdfColor accent) {
  return pw.Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      for (final s in summary)
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.grey300, width: .5),
          ),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                '${s.label}: ',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.Text(
                s.value,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
