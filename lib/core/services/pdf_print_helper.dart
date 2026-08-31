// ─────────────────────────────────────────────────────────────────────────────
// pdf_print_helper.dart — مساعد طباعة وتصدير تقارير PDF
//
// تعليقات توضيحية بالعربية:
// هذا الملف يوفر واجهة مركزية لطباعة وتصدير السندات والتقارير المالية.
// يربط بين [PdfService] في الطبقة الأساسية وحزمة [printing] لعرض معاينة الطباعة المباشرة.
//
// الدوال المتاحة:
//   1. printVoucherReceipt(context, voucher)         — طباعة سند قبض/صرف فردي
//   2. printReportTable(context, data, ...)         — أي تقرير جدوليّ
//   4. printPayrollSheet(context, data, ...)        — طباعة كشف رواتب الشهر
//   5. printSalarySlip(context, data, ...)          — طباعة إيصال راتب موظف
//   6. printPayrollYearReport(context, data, ...)   — طباعة تقرير رواتب سنة
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../domain/models/voucher_model.dart';
import 'payroll_print_data.dart';
import 'report_print_data.dart';
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

  /// طباعة أو معاينة **تقرير جدوليّ عام** — يخدم تبويبات التقارير الستّة
  ///
  /// حلّ محلّ `printVaultStatement` و`printAdvanceReport` اللذين كانا
  /// **بصفر مستدعٍ** وخارج نمط ترويسة الشركة (نمط ع-٠٦).
  static Future<void> printReportTable(
    BuildContext context,
    ReportTableData data, {
    PdfCompanyHeader header = PdfCompanyHeader.empty,
  }) async {
    final pdfService = PdfService();
    final pdfData = await pdfService.generateReportTable(data, header: header);

    if (context.mounted) {
      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: data.title.replaceAll(RegExp(r'[\/:*?"<>|]'), '-'),
      );
    }
  }

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
