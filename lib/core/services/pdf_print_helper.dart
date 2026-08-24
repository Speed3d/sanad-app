// ─────────────────────────────────────────────────────────────────────────────
// pdf_print_helper.dart — مساعد طباعة وتصدير تقارير PDF
//
// تعليقات توضيحية بالعربية:
// هذا الملف يوفر واجهة مركزية لطباعة وتصدير السندات والتقارير المالية.
// يربط بين [PdfService] في الطبقة الأساسية وحزمة [printing] لعرض معاينة الطباعة المباشرة.
//
// الدوال المتاحة:
//   1. printVoucherReceipt(context, voucher)         — طباعة سند قبض/صرف فردي
//   2. printTreasuryStatement(context, title, ...)  — طباعة كشف حساب خزينة
//   3. printAdvanceReport(context, title, ...)      — طباعة تقرير سلفة
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../domain/models/voucher_model.dart';
import 'pdf_service.dart';

/// مساعد الطباعة المباشرة والمعاينة
abstract final class PdfPrintHelper {
  /// طباعة أو معاينة سند فردي (قبض أو صرف)
  ///
  /// [context] — السياق
  /// [voucher] — نموذج السند المراد طباعته
  /// [header] — هوية الشركة (الاسم والشعار). تُمرَّر من طبقة العرض لأن
  /// `core` لا يجوز أن تقرأ من قاعدة البيانات. حذفها يطبع السند بلا ترويسة
  /// بدل أن يفشل — غياب الشعار إزعاج وفشل الطباعة تعطيل.
  static Future<void> printVoucherReceipt(
    BuildContext context,
    VoucherModel voucher, {
    PdfCompanyHeader header = PdfCompanyHeader.empty,
  }) async {
    final pdfService = PdfService();
    final pdfData =
        await pdfService.generateVoucherReceipt(voucher, header: header);

    if (context.mounted) {
      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'سند_${voucher.voucherType}_${voucher.voucherNumber}',
      );
    }
  }

  /// طباعة أو معاينة كشف حساب خزينة
  static Future<void> printVaultStatement({
    required BuildContext context,
    required String vaultName,
    required List<VoucherModel> vouchers,
    required double openingBalance,
    required String periodText,
  }) async {
    final pdfService = PdfService();
    final pdfData = await pdfService.generateVaultStatement(
      vaultName,
      vouchers,
      openingBalance,
      periodText,
    );

    if (context.mounted) {
      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'كشف_حساب_$vaultName',
      );
    }
  }

  /// طباعة أو معاينة تقرير السلف
  static Future<void> printAdvanceReport({
    required BuildContext context,
    required String advanceNumber,
    required List<VoucherModel> vouchers,
    required double totalAmount,
  }) async {
    final pdfService = PdfService();
    final pdfData = await pdfService.generateAdvanceReport(
      advanceNumber,
      vouchers,
      totalAmount,
    );

    if (context.mounted) {
      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'تقرير_سلفة_$advanceNumber',
      );
    }
  }
}
