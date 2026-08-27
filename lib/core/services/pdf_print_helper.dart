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
//   4. printPayrollSheet(context, data, ...)        — طباعة كشف رواتب الشهر
//   5. printSalarySlip(context, data, ...)          — طباعة إيصال راتب موظف
//   6. printPayrollYearReport(context, data, ...)   — طباعة تقرير رواتب سنة
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../domain/models/voucher_model.dart';
import 'payroll_print_data.dart';
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

  // ── الرواتب (المرحلة ٤) ───────────────────────────────────────────────

  /// طباعة كشف رواتب شهر
  ///
  /// [data] يبنيه `PayrollRepository.buildSheetPrintData` بإجمالياتٍ قرأها
  /// من `getTotals` — لا تبنِه بيدك في الشاشة، وإلا صار للمجموع مصدر ثانٍ.
  static Future<void> printPayrollSheet(
    BuildContext context,
    PayrollSheetPrintData data, {
    PdfCompanyHeader header = PdfCompanyHeader.empty,
  }) async {
    final pdfData =
        await PdfService().generatePayrollSheet(data, header: header);

    if (context.mounted) {
      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'كشف_رواتب_${data.periodLabel}',
      );
    }
  }

  /// طباعة إيصال راتب موظف واحد
  static Future<void> printSalarySlip(
    BuildContext context,
    SalarySlipPrintData data, {
    PdfCompanyHeader header = PdfCompanyHeader.empty,
  }) async {
    final pdfData =
        await PdfService().generateSalarySlip(data, header: header);

    if (context.mounted) {
      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'إيصال_راتب_${data.employeeName}_${data.periodLabel}',
      );
    }
  }

  /// طباعة تقرير رواتب سنة
  static Future<void> printPayrollYearReport(
    BuildContext context,
    PayrollYearReportData data, {
    PdfCompanyHeader header = PdfCompanyHeader.empty,
  }) async {
    final pdfData =
        await PdfService().generatePayrollYearReport(data, header: header);

    if (context.mounted) {
      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'تقرير_رواتب_${data.year}',
      );
    }
  }

  /// طباعة تقرير رواتب موظف أو موظفي مشروع
  static Future<void> printEmployeePayrollReport(
    BuildContext context,
    EmployeePayrollReportData data, {
    PdfCompanyHeader header = PdfCompanyHeader.empty,
  }) async {
    final bytes = await PdfService()
        .generateEmployeePayrollReport(data, header: header);
    if (!context.mounted) return;
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: data.isSingleEmployee
          ? 'رواتب_${data.employeeName}'
          : 'تقرير_رواتب_الموظفين',
    );
  }
}
