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
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/models/voucher_model.dart';
import '../extensions/number_extensions.dart';
import '../extensions/string_extensions.dart';

/// خدمة إنشاء ملفات PDF
class PdfService {
  /// خط عربي محمّل
  pw.Font? _arabicFont;

  /// تحميل الخط العربي (Tajawal) من الأصول
  Future<pw.Font> _loadFont() async {
    if (_arabicFont != null) return _arabicFont!;
    try {
      final fontData = await rootBundle.load('assets/fonts/Tajawal-Regular.ttf');
      _arabicFont = pw.Font.ttf(fontData);
    } catch (_) {
      _arabicFont = pw.Font.helvetica();
    }
    return _arabicFont!;
  }

  /// إنشاء سند قبض أو صرف فردي بصيغة PDF
  Future<Uint8List> generateVoucherReceipt(VoucherModel voucher) async {
    final font = await _loadFont();
    final pdf = pw.Document();
    final isKabd = voucher.voucherType == 'kabd';
    final title = isKabd ? 'سند قبض مالي' : 'سند صرف مالي';
    final color = isKabd ? PdfColors.green700 : PdfColors.red700;
    final fmtDate = intl.DateFormat('yyyy/MM/dd HH:mm').format(voucher.voucherDate);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: pw.ThemeData.withFont(base: font),
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

  /// إنشاء كشف حساب خزينة PDF
  Future<Uint8List> generateVaultStatement(
    String vaultName,
    List<VoucherModel> vouchers,
    double openingBalance,
    String periodText,
  ) async {
    final font = await _loadFont();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font),
        build: (pw.Context context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('كشف حساب خزينة: $vaultName',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('الفترة: $periodText', style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 12),
                  pw.TableHelper.fromTextArray(
                    headers: ['الرقم', 'التاريخ', 'النوع', 'البيان', 'المبلغ'],
                    data: vouchers.map((v) {
                      return [
                        '#${v.voucherNumber}',
                        intl.DateFormat('dd/MM/yyyy').format(v.voucherDate),
                        v.voucherType.toArabicVoucherType(),
                        v.reason.orDefault('—'),
                        v.amount.toIQD(),
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    rowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// إنشاء تقرير سلفة مجمعة PDF
  Future<Uint8List> generateAdvanceReport(
    String advanceNumber,
    List<VoucherModel> vouchers,
    double totalAmount,
  ) async {
    final font = await _loadFont();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font),
        build: (pw.Context context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('تقرير سلفة رقم: $advanceNumber',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('المبلغ الإجمالي: ${totalAmount.toIQD()}',
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.green800, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 12),
                  pw.TableHelper.fromTextArray(
                    headers: ['رقم السند', 'اسم المشروع', 'صرف من قبل', 'المبلغ'],
                    data: vouchers.map((v) {
                      return [
                        '#${v.voucherNumber}',
                        v.projectName ?? '—',
                        v.spentBy ?? '—',
                        v.amount.toIQD(),
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                  ),
                ],
              ),
            ),
          ];
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
