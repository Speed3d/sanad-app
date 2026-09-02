// ─────────────────────────────────────────────────────────────────────────────
// pdf_payroll_documents.dart — مستندات الرواتب المطبوعة (المرحلة ٤)
//
// جزء من مكتبة `pdf_service.dart` — يستعمل تحميل الخطوط وبناء النمط وترويسة
// الشركة الخاصة بها.
//
// ⚠️ **ولماذا `part` لا خدمة ثانية مستقلّة؟**
//   لأن تحميل الخطوط وبناء النمط هما بالضبط موضع العطل الذي جعل كل نصّ عربي
//   عريض يخرج فارغاً (`ThemeData.withFont(base:)` وحده يُبقي Helvetica-Bold).
//   خدمةٌ ثانية تعني نسخةً ثانية من ذلك الكود — وأولَ نسخةٍ تُنسى عند
//   الإصلاح التالي. هنا **مسار واحد للخطوط** يحرسه `pdf_arabic_font_test`.
//
// ثلاثة مستندات:
//   1. generatePayrollSheet     — كشف رواتب الشهر (A4 عرضيّ · متعدّد الصفحات)
//   2. generateSalarySlip       — إيصال راتب موظف واحد (A5)
//   3. generatePayrollYearReport— تقرير رواتب سنة كاملة
//   4. generateEmployeePayrollReport — تقرير موظف أو موظفي مشروع
// ─────────────────────────────────────────────────────────────────────────────

part of 'pdf_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// تنسيق المال في المستندات
// ═══════════════════════════════════════════════════════════════════════════

/// الدينار **بلا كسور** والدولار **بكسرين** — قرار المالك 2026-08-24
///
/// ⚠️ لا تستعمل `toIQD()` هنا: تطبع ثلاث منازل عشرية (`1,000.000 د.ع`) وهي
///   الصيغة التي طلب المالك إزالتها من الشاشات، ولا معنى لأن تعود في الورق.
final _payrollIqdFormat = intl.NumberFormat('#,##0');
final _payrollUsdFormat = intl.NumberFormat('#,##0.00');

/// مبلغ بعملته — بلا رمز (الرمز في عمود مستقلّ أو في التسمية)
String _payrollMoney(double value, String currency) =>
    currency == PayrollPrintCurrency.iqd
        ? _payrollIqdFormat.format(value)
        : _payrollUsdFormat.format(value);

/// مبلغ بالدينار مع رمزه
String _payrollIqd(double value) => '${_payrollIqdFormat.format(value)} د.ع';

/// خليّة رقمية فارغة حين تكون صفراً
///
/// جدول فيه أصفار في كل خانة يُتعب العين ويُخفي القيم الحقيقية بينها.
/// الصفر هنا يعني «لا شيء»، والفراغ يقولها أوضح من الرقم.
String _payrollMoneyOrDash(double value, String currency) =>
    value == 0 ? '—' : _payrollMoney(value, currency);

/// أيام الإجازة في خليّة واحدة — «م» مدفوعة و«غ» بلا راتب
///
/// والمفتاح يُكتَب في ذيل الكشف، فورقةٌ تُقرأ بعد سنة لا تحتاج شرحاً شفوياً.
String _payrollLeave(PayrollSheetPrintRow r) {
  final parts = <String>[
    if (r.leaveDaysPaid > 0) '${r.leaveDaysPaid} م',
    if (r.leaveDaysUnpaid > 0) '${r.leaveDaysUnpaid} غ',
  ];
  return parts.isEmpty ? '—' : parts.join(' · ');
}

/// رموز العملات المعتمدة في المستندات
abstract final class PayrollPrintCurrency {
  static const String iqd = 'IQD';
}

// ═══════════════════════════════════════════════════════════════════════════
// المستندات
// ═══════════════════════════════════════════════════════════════════════════

/// مستندات الرواتب — امتداد على [PdfService] داخل مكتبتها
///
/// الامتداد داخل نفس المكتبة يرى أعضاءها الخاصة (`_loadFonts` · `_themeWith`
/// · `_buildCompanyHeader`)، فلا يتكرّر شيء منها.
extension PdfPayrollDocuments on PdfService {
  // ───────────────────────────────────────────────────────────────────────
  // ١. كشف رواتب الشهر
  // ───────────────────────────────────────────────────────────────────────

  /// كشف رواتب شهر — صفحة A4 **عرضيّة** لأن الأعمدة أربعة عشر
  ///
  /// 🔑 **عرض الأعمدة نِسَبٌ (`FlexColumnWidth`) لا بكسلات.**
  ///   العطل ع-٢٣ (تجاوز بكسلين) والعطل الذي حجب أسماء الموظفين في المشروع
  ///   المرجعي DMS (تجاوز ٩٤ بكسلاً) كلاهما وُلد من **رقم عرضٍ يُكتَب بيد
  ///   ويُقارَن بمجموعٍ يتغيّر**. النِّسَب تُلغي الحساب كلّه: الجدول يملأ عرض
  ///   الصفحة أياً كانت، وإضافة عمود التوقيع تُضيّق البقية تلقائياً ولا
  ///   تُخرج شيئاً خارج الورقة.
  ///
  /// [data] — الكشف جاهزاً، **بإجمالياته المحسوبة في `PayrollDao.getTotals`**
  /// [header] — هوية الشركة · غيابها يطبع بلا ترويسة ولا يُفشل الطباعة
  Future<Uint8List> generatePayrollSheet(
    PayrollSheetPrintData data, {
    PdfCompanyHeader header = PdfCompanyHeader.empty,
  }) async {
    final fonts = await _loadFonts();
    final pdf = pw.Document();
    const accent = PdfColors.blueGrey800;
    final printedAt = intl.DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now());

    // ── الأعمدة ────────────────────────────────────────────────────────
    final headers = <String>[
      '#',
      'الاسم',
      'الصفة',
      'العملة',
      'الأساسي',
      'الأيام',
      'غياب',
      'إجازة',
      'خصم الغياب',
      'مكافأة',
      'خصم',
      'خصم سلفة',
      'الصافي',
      'بالدينار',
      'الحالة',
      if (data.withSignatureColumn) 'التوقيع',
    ];

    /// نِسَب العرض — الاسم أعرض ما فيها، والتسلسل أضيقه
    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(0.6),
      1: const pw.FlexColumnWidth(3.0),
      2: const pw.FlexColumnWidth(1.9),
      3: const pw.FlexColumnWidth(0.9),
      4: const pw.FlexColumnWidth(1.7),
      5: const pw.FlexColumnWidth(0.8),
      6: const pw.FlexColumnWidth(0.8),
      // ⚠️ عمود الإجازة أُدرج **هنا** فانزاح ما بعده — والخريطة تُعدَّل معه
      //   دائماً: نسيانُها يُخرج «الاسم» بعرض «التسلسل» (درس الدفعة أ).
      7: const pw.FlexColumnWidth(1.0),
      8: const pw.FlexColumnWidth(1.4),
      9: const pw.FlexColumnWidth(1.3),
      10: const pw.FlexColumnWidth(1.3),
      11: const pw.FlexColumnWidth(1.4),
      12: const pw.FlexColumnWidth(1.7),
      13: const pw.FlexColumnWidth(1.9),
      14: const pw.FlexColumnWidth(1.1),
      if (data.withSignatureColumn) 15: const pw.FlexColumnWidth(2.4),
    };

    final rows = <List<String>>[
      for (final r in data.rows)
        [
          '${r.seq}',
          r.name,
          r.position.isEmpty ? '—' : r.position,
          r.currency == PayrollPrintCurrency.iqd ? 'د.ع' : '\$',
          _payrollMoney(r.basicSalary, r.currency),
          '${r.eligibleDays}',
          r.absenceDays == 0 ? '—' : '${r.absenceDays}',
          _payrollLeave(r),
          _payrollMoneyOrDash(r.absenceDeduction, r.currency),
          _payrollMoneyOrDash(r.bonus, r.currency),
          _payrollMoneyOrDash(r.deduction, r.currency),
          _payrollMoneyOrDash(r.advanceRepayment, r.currency),
          _payrollMoney(r.net, r.currency),
          _payrollIqdFormat.format(r.netIqd),
          r.isPaid
              ? (r.addedAfterPosting ? 'مسدَّد (لاحق)' : 'مسدَّد')
              : 'مستحقّ',
          if (data.withSignatureColumn) '',
        ],
      // ── سطر المجموع ────────────────────────────────────────────────
      // 🔑 من `getTotals` لا بجمع السطور أعلاه: مجموعٌ ثانٍ يعني رقمين
      //   يمكن أن يختلفا، وحينها لا يُعرَف أيّهما الصحيح.
      [
        '',
        'المجموع (${data.employeeCount} موظفاً)',
        '', '', '', '', '', '', '', '', '', '',
        '',
        _payrollIqdFormat.format(data.totalIqd),
        '',
        if (data.withSignatureColumn) '',
      ],
    ];

    final totalsRowNum = rows.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(20, 18, 20, 24),
        theme: _themeWith(fonts),
        textDirection: pw.TextDirection.rtl,
        footer: (context) => _payrollFooter(context, printedAt),
        build: (context) => [
          _buildCompanyHeader(header, accent),
          _payrollSheetTitle(data, accent),
          pw.SizedBox(height: 8),
          if (data.rows.any((r) => r.leaveDaysPaid > 0 || r.leaveDaysUnpaid > 0))
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                'عمود الإجازة: «م» = إجازة براتب · «غ» = إجازة بلا راتب '
                '(تُنقِص الأيام المستحقّة)',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                textAlign: pw.TextAlign.right,
              ),
            ),
          pw.TableHelper.fromTextArray(
            context: context,
            // ↔️ الأعمدة معكوسة عمداً — `pw.Table` لا تعرف الاتّجاه فترتّبها
            //    من اليسار دائماً. راجع تعليق `rtlRows` في pdf_service.dart
            headers: rtlRow(headers),
            data: rtlRows(rows),
            columnWidths: rtlColumnMap(widths, headers.length),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3.5),
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: accent),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            // سطر المجموع عريض — العين تقفز إليه مباشرة عند المراجعة
            textStyleBuilder: (col, cell, rowNum) => rowNum == totalsRowNum
                ? pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)
                : const pw.TextStyle(fontSize: 7.5),
            cellAlignment: pw.Alignment.center,
            cellAlignments: rtlColumnMap(const {
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
            }, headers.length),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.4),
          ),
          pw.SizedBox(height: 10),
          _payrollSheetSummary(data),
          pw.SizedBox(height: 18),
          _payrollSignatures(const ['المحاسب', 'المدير المالي', 'المدير العام']),
        ],
      ),
    );

    return pdf.save();
  }

  // ───────────────────────────────────────────────────────────────────────
  // ٢. إيصال راتب موظف
  // ───────────────────────────────────────────────────────────────────────

  /// إيصال راتب موظف واحد — قصاصة A5 تُسلَّم له
  ///
  /// يعرض **لقطة شهره** لا بياناته اليوم، ويذكر رقم سند الصرف حين يكون
  /// مسدَّداً: إيصالٌ بلا سند لا يمكن ردّه إلى حركة في الدفاتر.
  Future<Uint8List> generateSalarySlip(
    SalarySlipPrintData data, {
    PdfCompanyHeader header = PdfCompanyHeader.empty,
  }) async {
    final fonts = await _loadFonts();
    final pdf = pw.Document();
    final accent = data.isPaid ? PdfColors.green800 : PdfColors.orange800;
    final dateFmt = intl.DateFormat('yyyy/MM/dd');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: _themeWith(fonts),
        build: (context) => pw.Directionality(
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
                _buildCompanyHeader(header, accent),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'إيصال راتب',
                      style: pw.TextStyle(
                        fontSize: 17,
                        fontWeight: pw.FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    pw.Text(
                      data.periodLabel,
                      style: pw.TextStyle(
                          fontSize: 13, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.Divider(color: accent, thickness: 1.5),
                pw.SizedBox(height: 6),

                _buildPdfRow('الموظف:', data.employeeName),
                if (data.position.isNotEmpty)
                  _buildPdfRow('الصفة:', data.position),
                if (data.hireDate != null)
                  _buildPdfRow('تاريخ التعيين:', dateFmt.format(data.hireDate!)),
                _buildPdfRow(
                  'أيام الاستحقاق:',
                  '${data.eligibleDays} من ${data.workingDays}',
                ),
                if (data.absenceDays > 0)
                  _buildPdfRow('أيام الغياب:', '${data.absenceDays}'),

                pw.SizedBox(height: 6),
                pw.Divider(color: PdfColors.grey300),

                // ── تفصيل المبالغ ────────────────────────────────────────
                _payrollAmountLine(
                    'الراتب الأساسي', data.basicSalary, data.currency),
                if (data.bonus != 0)
                  _payrollAmountLine('مكافأة', data.bonus, data.currency),
                if (data.absenceDeduction != 0)
                  _payrollAmountLine(
                      'خصم الغياب', -data.absenceDeduction, data.currency),
                if (data.deduction != 0)
                  _payrollAmountLine('خصومات أخرى', -data.deduction, data.currency),
                if (data.advanceRepayment != 0)
                  _payrollAmountLine(
                      'خصم سلفة', -data.advanceRepayment, data.currency),

                pw.Divider(color: PdfColors.grey400),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('الصافي المستحق',
                        style: pw.TextStyle(
                            fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      data.isForeign
                          ? '${_payrollMoney(data.net, data.currency)} \$'
                          : _payrollIqd(data.netIqd),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                // الراتب بالدولار يُطبع بالعملتين: الموظف يقرأ عملته،
                // والدفاتر تقرأ الدينار — ولا يُترك التحويل لتقدير أحد.
                if (data.isForeign) ...[
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        data.exchangeRate == null
                            ? 'ما يعادله بالدينار'
                            : 'ما يعادله بالدينار (سعر الصرف '
                                '${_payrollIqdFormat.format(data.exchangeRate)})',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(_payrollIqd(data.netIqd),
                          style: pw.TextStyle(
                              fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],

                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: data.isPaid ? PdfColors.green50 : PdfColors.orange50,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    data.isPaid
                        ? 'مُسدَّد'
                            '${data.voucherNumber != null ? ' — سند صرف رقم ${data.voucherNumber}' : ''}'
                            '${data.paidAt != null ? ' بتاريخ ${dateFmt.format(data.paidAt!)}' : ''}'
                            '${data.treasuryName != null ? ' من ${data.treasuryName}' : ''}'
                        : 'غير مُسدَّد — هذا الإيصال بيانُ استحقاق لا إشعارُ دفع',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: data.isPaid ? PdfColors.green900 : PdfColors.orange900,
                    ),
                  ),
                ),

                pw.Spacer(),
                pw.Divider(color: PdfColors.grey300),
                _payrollSignatures(const ['توقيع المحاسب', 'توقيع المستلم']),
              ],
            ),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  // ───────────────────────────────────────────────────────────────────────
  // ٣. تقرير رواتب السنة
  // ───────────────────────────────────────────────────────────────────────

  /// تقرير رواتب سنة — الأشهر الاثنا عشر وتوزيع المسدَّد على الخزائن
  Future<Uint8List> generatePayrollYearReport(
    PayrollYearReportData data, {
    PdfCompanyHeader header = PdfCompanyHeader.empty,
  }) async {
    final fonts = await _loadFonts();
    final pdf = pw.Document();
    const accent = PdfColors.teal800;
    final printedAt = intl.DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 26),
        theme: _themeWith(fonts),
        textDirection: pw.TextDirection.rtl,
        footer: (context) => _payrollFooter(context, printedAt),
        build: (context) => [
          _buildCompanyHeader(header, accent),
          pw.Text(
            'تقرير الرواتب — سنة ${data.year}',
            style: pw.TextStyle(
                fontSize: 17, fontWeight: pw.FontWeight.bold, color: accent),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${data.monthCount} كشفاً · ${data.postedMonthCount} مُسدَّداً '
            'بالكامل',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 10),

          // ── الأشهر ─────────────────────────────────────────────────────
          pw.TableHelper.fromTextArray(
            context: context,
            // ↔️ معكوسة — راجع `rtlRows` في pdf_service.dart
            headers: rtlRow(const [
              'الشهر',
              'الموظفون',
              'إجمالي الكشف',
              'المسدَّد',
              'المتبقّي',
              'الحالة',
            ]),
            data: rtlRows([
              for (final m in data.months)
                [
                  PayrollPrintLabels.arabicMonth(m.month),
                  '${m.employeeCount}',
                  _payrollIqdFormat.format(m.totalIqd),
                  _payrollIqdFormat.format(m.paidIqd),
                  m.unpaidIqd == 0
                      ? '—'
                      : _payrollIqdFormat.format(m.unpaidIqd),
                  m.isPosted ? 'مُسدَّد' : 'مسودة',
                ],
              [
                'مجموع السنة',
                '',
                _payrollIqdFormat.format(data.totalIqd),
                _payrollIqdFormat.format(data.paidIqd),
                data.unpaidIqd == 0
                    ? '—'
                    : _payrollIqdFormat.format(data.unpaidIqd),
                '',
              ],
            ]),
            headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: accent),
            cellStyle: const pw.TextStyle(fontSize: 9),
            textStyleBuilder: (col, cell, rowNum) =>
                rowNum == data.months.length + 1
                    ? pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)
                    : const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.center,
            // العمود الأول («الشهر») صار الأخير بعد العكس
            cellAlignments: const {5: pw.Alignment.centerRight},
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.4),
          ),

          // ── توزيع المسدَّد على الخزائن ───────────────────────────────────
          if (data.treasuryShares.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text('توزيع الرواتب المسدَّدة حسب الخزينة',
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(
              'المسدَّد وحده — المستحقّ لم يخرج من أي خزينة بعد.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: rtlRow(const [
                'الخزينة / المشروع',
                'رواتب مسدَّدة',
                'المبلغ',
              ]),
              data: rtlRows([
                for (final s in data.treasuryShares)
                  [
                    s.treasuryName,
                    '${s.employeeCount}',
                    _payrollIqdFormat.format(s.totalIqd),
                  ],
              ]),
              headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blueGrey700),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.center,
              cellAlignments: const {2: pw.Alignment.centerRight},
              border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.4),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ───────────────────────────────────────────────────────────────────────
  // ٤. تقرير الموظف (طلب المالك 2026-08-26)
  // ───────────────────────────────────────────────────────────────────────

  /// تقرير رواتب موظف واحد شهراً شهراً، أو مجاميع موظفي مشروع
  ///
  /// **جدولان مختلفان في مستند واحد** لأن السؤال واحد بصيغتين: «كم قبض هذا
  /// الموظف ولماذا؟» و«كم قبض موظفو هذا المشروع؟». وفصلُهما مستندين يعني
  /// نسختين من الترويسة والمجاميع والتذييل — أوّلُ ما يُنسى عند أي إصلاح.
  Future<Uint8List> generateEmployeePayrollReport(
    EmployeePayrollReportData data, {
    PdfCompanyHeader header = PdfCompanyHeader.empty,
  }) async {
    final fonts = await _loadFonts();
    final pdf = pw.Document();
    const accent = PdfColors.indigo800;
    final printedAt =
        intl.DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        // عرضيّة للموظف الواحد (أربعة عشر عموداً) وطوليّة للمجموعة
        pageFormat: data.isSingleEmployee
            ? PdfPageFormat.a4.landscape
            : PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(22, 20, 22, 26),
        theme: _themeWith(fonts),
        textDirection: pw.TextDirection.rtl,
        footer: (context) => _payrollFooter(context, printedAt),
        build: (context) => [
          _buildCompanyHeader(header, accent),
          pw.Text(
            data.isSingleEmployee
                ? 'تقرير رواتب: ${data.employeeName}'
                : 'تقرير رواتب الموظفين',
            style: pw.TextStyle(
                fontSize: 17, fontWeight: pw.FontWeight.bold, color: accent),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            [
              'الفترة: ${data.rangeLabel}',
              if (data.position != null && data.position!.isNotEmpty)
                'الصفة: ${data.position}',
              if (data.treasuryName != null)
                'المشروع: ${data.treasuryName}',
            ].join('  ·  '),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 10),

          // ── شريط المجاميع ──────────────────────────────────────────────
          _employeeReportTotals(data),
          pw.SizedBox(height: 12),

          if (data.isSingleEmployee)
            _employeeMonthsTable(context, data, accent)
          else
            _employeeSummaryTable(context, data, accent),
        ],
      ),
    );

    return pdf.save();
  }
}

/// شريط المجاميع أعلى تقرير الموظف
///
/// 🔑 الأرقام تُقرأ من `EmployeePayrollReportData` **كما وصلت** — لا جمع هنا.
///   جمعُ الورقة لمجاميعها بنفسها يُنتج رقماً ثانياً لنفس السؤال، وحينها لا
///   يُعرَف أيّهما الصحيح حين يختلفان.
pw.Widget _employeeReportTotals(EmployeePayrollReportData data) {
  pw.Widget cell(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(label,
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 3),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

  return pw.Row(children: [
    cell(data.isSingleEmployee ? 'عدد الأشهر' : 'الموظفون',
        '${data.isSingleEmployee ? data.monthCount : data.employees.length}',
        PdfColors.grey800),
    cell('إجمالي المستحقّ', _payrollIqd(data.totalIqd), PdfColors.indigo800),
    cell('المصروف فعلاً', _payrollIqd(data.paidIqd), PdfColors.green800),
    if (data.unpaidIqd.abs() > 1)
      cell('غير مصروف', _payrollIqd(data.unpaidIqd), PdfColors.orange800),
    cell('المكافآت', _payrollIqd(data.bonusIqd), PdfColors.green700),
    cell('الخصومات', _payrollIqd(data.deductionIqd), PdfColors.red700),
    cell('خصم السلف', _payrollIqd(data.advanceRepaymentIqd),
        PdfColors.deepPurple700),
  ]);
}

/// جدول أشهر موظف واحد — **كل بند بعموده**
pw.Widget _employeeMonthsTable(
  pw.Context context,
  EmployeePayrollReportData data,
  PdfColor accent,
) {
  return pw.TableHelper.fromTextArray(
    context: context,
    // ↔️ معكوسة — راجع `rtlRows` في pdf_service.dart
    headers: rtlRow(const [
      'الشهر',
      'العملة',
      'الأساسي',
      'الأيام',
      'غياب',
      'خصم الغياب',
      'مكافأة',
      'خصم',
      'خصم سلفة',
      'الصافي',
      'بالدينار',
      'الحالة',
      'صُرف من',
      'السند',
    ]),
    data: rtlRows([
      for (final m in data.months)
        [
          '${PayrollPrintLabels.arabicMonth(m.month)} ${m.year}',
          m.currency == PayrollPrintCurrency.iqd ? 'د.ع' : '\$',
          _payrollMoney(m.basicSalary, m.currency),
          '${m.eligibleDays}',
          m.absenceDays == 0 ? '—' : '${m.absenceDays}',
          _payrollMoneyOrDash(m.absenceDeduction, m.currency),
          _payrollMoneyOrDash(m.bonus, m.currency),
          _payrollMoneyOrDash(m.deduction, m.currency),
          _payrollMoneyOrDash(m.advanceRepayment, m.currency),
          _payrollMoney(m.net, m.currency),
          _payrollIqdFormat.format(m.netIqd),
          m.isPaid ? 'مصروف' : 'مستحقّ',
          m.paidFromTreasury ?? '—',
          m.voucherNumber == null ? '—' : '#${m.voucherNumber}',
        ],
      [
        'المجموع',
        '', '', '', '', '', '', '', '',
        '',
        _payrollIqdFormat.format(data.totalIqd),
        '', '', '',
      ],
    ]),
    headerStyle: pw.TextStyle(
        fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
    headerDecoration: pw.BoxDecoration(color: accent),
    cellStyle: const pw.TextStyle(fontSize: 7.5),
    textStyleBuilder: (col, cell, rowNum) => rowNum == data.months.length + 1
        ? pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)
        : const pw.TextStyle(fontSize: 7.5),
    cellAlignment: pw.Alignment.center,
    // «الشهر» كان العمود ٠ فصار الأخير بعد العكس
    cellAlignments: const {13: pw.Alignment.centerRight},
    oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.4),
  );
}

/// جدول مجاميع موظفي مشروع
pw.Widget _employeeSummaryTable(
  pw.Context context,
  EmployeePayrollReportData data,
  PdfColor accent,
) {
  return pw.TableHelper.fromTextArray(
    context: context,
    // ↔️ معكوسة — راجع `rtlRows` في pdf_service.dart
    headers: rtlRow(const [
      'الموظف',
      'الصفة',
      'أشهر',
      'المكافآت',
      'الخصومات',
      'خصم السلف',
      'المصروف',
      'الإجمالي',
    ]),
    data: rtlRows([
      for (final e in data.employees)
        [
          e.employeeName,
          e.position.isEmpty ? '—' : e.position,
          '${e.monthCount}',
          _payrollIqdFormat.format(e.bonusIqd),
          _payrollIqdFormat.format(e.deductionIqd),
          _payrollIqdFormat.format(e.advanceRepaymentIqd),
          _payrollIqdFormat.format(e.paidIqd),
          _payrollIqdFormat.format(e.totalIqd),
        ],
      [
        'المجموع (${data.employees.length} موظفاً)',
        '',
        '${data.monthCount}',
        _payrollIqdFormat.format(data.bonusIqd),
        _payrollIqdFormat.format(data.deductionIqd),
        _payrollIqdFormat.format(data.advanceRepaymentIqd),
        _payrollIqdFormat.format(data.paidIqd),
        _payrollIqdFormat.format(data.totalIqd),
      ],
    ]),
    headerStyle: pw.TextStyle(
        fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
    headerDecoration: pw.BoxDecoration(color: accent),
    cellStyle: const pw.TextStyle(fontSize: 8.5),
    textStyleBuilder: (col, cell, rowNum) => rowNum == data.employees.length + 1
        ? pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)
        : const pw.TextStyle(fontSize: 8.5),
    cellAlignment: pw.Alignment.center,
    // «الموظف» و«الصفة» كانا ٠ و١ فصارا ٧ و٦ بعد العكس
    cellAlignments: const {
      7: pw.Alignment.centerRight,
      6: pw.Alignment.centerRight,
    },
    oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.4),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// أجزاء مشتركة بين المستندات
// ═══════════════════════════════════════════════════════════════════════════

/// أسماء الأشهر العربية للمستندات
///
/// **لماذا هنا لا في `PayrollCalculator`؟** لأن `core/services` يعتمد عليها
/// الطرفان، ولا يجوز أن يعتمد `PdfService` على حاسبة الرواتب لأجل قائمة نصوص.
abstract final class PayrollPrintLabels {
  static const List<String> _months = [
    'كانون الثاني',
    'شباط',
    'آذار',
    'نيسان',
    'أيار',
    'حزيران',
    'تموز',
    'آب',
    'أيلول',
    'تشرين الأول',
    'تشرين الثاني',
    'كانون الأول',
  ];

  /// اسم الشهر العربي — يُعيد رقمه حين يكون خارج ١..١٢
  static String arabicMonth(int month) =>
      month >= 1 && month <= 12 ? _months[month - 1] : '$month';
}

/// ترويسة الكشف — الشهر وأيام العمل وسعر الصرف والحالة
pw.Widget _payrollSheetTitle(PayrollSheetPrintData data, PdfColor accent) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'كشف رواتب ${data.periodLabel}',
            style: pw.TextStyle(
                fontSize: 15, fontWeight: pw.FontWeight.bold, color: accent),
          ),
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pw.BoxDecoration(
              color: data.isPosted ? PdfColors.green50 : PdfColors.amber50,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              data.isPosted ? 'مُسدَّد' : 'مسودة',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color:
                    data.isPosted ? PdfColors.green900 : PdfColors.orange900,
              ),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 3),
      pw.Text(
        'أيام العمل: ${data.workingDays}'
        '${data.exchangeRate != null ? '   ·   سعر الصرف: ${_payrollIqdFormat.format(data.exchangeRate)}' : ''}'
        '   ·   عدد الموظفين: ${data.employeeCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
    ],
  );
}

/// صندوق الإجماليات أسفل الجدول
///
/// يذكر **مجموع الملف** بجوار المحسوب حين يوجد: الورقة المؤرشفة يجب أن
/// تحمل الرقمين، فالفرق بينهما يكشف خطأً في ملف المحاسب بعد شهور.
pw.Widget _payrollSheetSummary(PayrollSheetPrintData data) {
  final gap = data.fileTotalGap;
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(4),
      border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            _payrollTotalChip('إجمالي الكشف', data.totalIqd, PdfColors.black),
            _payrollTotalChip('المسدَّد', data.paidIqd, PdfColors.green800),
            _payrollTotalChip('المستحقّ', data.unpaidIqd, PdfColors.orange800),
            if (data.fileTotal > 0)
              _payrollTotalChip(
                'مجموع الملف',
                data.fileTotal,
                gap == null ? PdfColors.grey700 : PdfColors.red800,
              ),
          ],
        ),
        if (gap != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'فرق عن مجموع الملف: ${_payrollIqd(gap)} — راجع الملف قبل الاعتماد.',
            style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.red800,
                fontWeight: pw.FontWeight.bold),
          ),
        ],
      ],
    ),
  );
}

pw.Widget _payrollTotalChip(String label, double value, PdfColor color) {
  return pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 1),
        pw.Text(
          _payrollIqd(value),
          style: pw.TextStyle(
              fontSize: 11, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    ),
  );
}

/// سطر مبلغ في الإيصال — سالبه يُكتب بإشارته ولونه
pw.Widget _payrollAmountLine(String label, double value, String currency) {
  final isNegative = value < 0;
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(
          '${isNegative ? '−' : ''}'
          '${_payrollMoney(value.abs(), currency)}'
          '${currency == PayrollPrintCurrency.iqd ? ' د.ع' : ' \$'}',
          style: pw.TextStyle(
            fontSize: 10,
            color: isNegative ? PdfColors.red800 : PdfColors.black,
          ),
        ),
      ],
    ),
  );
}

/// خانات التوقيع أسفل المستند
pw.Widget _payrollSignatures(List<String> labels) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
    children: [
      for (final l in labels)
        pw.Column(
          children: [
            pw.Text(l, style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 22),
            pw.Text('..............................',
                style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
    ],
  );
}

/// تذييل كل صفحة — رقمها وتاريخ الطباعة
///
/// **ليس زينة:** كشف من ثلاث صفحات تتناثر أوراقه على المكتب، ورقمُ الصفحة
/// وحده يقول إن واحدة ضاعت. وتاريخ الطباعة يميّز نسخةً قديمة عن أحدث منها.
pw.Widget _payrollFooter(pw.Context context, String printedAt) {
  return pw.Directionality(
    textDirection: pw.TextDirection.rtl,
    child: pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'طُبع في $printedAt',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    ),
  );
}
