// ─────────────────────────────────────────────────────────────────────────────
// payroll_print_actions.dart — إجراءات طباعة مستندات الرواتب (المرحلة ٤)
//
// **لماذا ملف مشترك لا دوال في كل شاشة؟**
//   إيصال الراتب يُطبع من موضعين: سطرِ كشف الشهر، وتبويبِ «الرواتب» في بطاقة
//   الموظف. ونسختان من إجراء الطباعة تعنيان أن إصلاح ترويسةٍ أو رسالةِ خطأ
//   يصل إلى واحدة وينسى الأخرى — وهو الخطأ نفسه الذي أنتج ٨٤٠ سطراً مكرّرة
//   بين شاشتَي السند (المرحلة د).
//
// 🔑 **وكل إجراء هنا يمسك أخطاءه ويعرضها.**
//   العطل ع-٢٥ كان بالضبط هذا: الحارس يرفض بحقّ ويكتب رسالة عربية واضحة،
//   ولا أحد يعرضها — فيبدو للمالك أن الزرّ «لا يفعل شيئاً». الطباعة تمرّ
//   بالقرص والطابعة والخطوط، وكلها تفشل أحياناً، فالصمت هنا غير مقبول.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/payroll_print_data.dart';
import '../../../core/services/pdf_print_helper.dart';
import '../../../core/services/pdf_service.dart';
import '../../providers/provider_read_once.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';

/// إجراءات طباعة الرواتب
abstract final class PayrollPrintActions {
  /// طباعة كشف رواتب شهر
  ///
  /// [withSignatureColumn] — عمود توقيع الاستلام (يختاره المالك عند الطباعة)
  static Future<void> printSheet(
    BuildContext context,
    WidgetRef ref,
    int periodId, {
    bool withSignatureColumn = false,
  }) async {
    await _guarded(context, () async {
      // البيانات تُبنى في المستودع من `getTotals` — لا تُجمَع هنا
      final data = await ref
          .read(payrollRepositoryProvider)
          .buildSheetPrintData(periodId,
              withSignatureColumn: withSignatureColumn);

      if (data.rows.isEmpty) {
        throw StateError('الكشف فارغ — لا يوجد ما يُطبع.');
      }

      final header = await _header(ref);
      if (!context.mounted) return;
      await PdfPrintHelper.printPayrollSheet(context, data, header: header);
    });
  }

  /// طباعة إيصال راتب موظف واحد
  static Future<void> printSlip(
    BuildContext context,
    WidgetRef ref,
    int entryId,
  ) async {
    await _guarded(context, () async {
      final data =
          await ref.read(payrollRepositoryProvider).buildSlipPrintData(entryId);
      if (data == null) {
        throw StateError('سطر الراتب غير موجود — قد يكون حُذف.');
      }

      final header = await _header(ref);
      if (!context.mounted) return;
      await PdfPrintHelper.printSalarySlip(context, data, header: header);
    });
  }

  /// طباعة تقرير رواتب سنة
  static Future<void> printYearReport(
    BuildContext context,
    WidgetRef ref,
    PayrollYearReportData data,
  ) async {
    await _guarded(context, () async {
      if (data.isEmpty) {
        throw StateError('لا كشوف رواتب في سنة ${data.year} — لا شيء يُطبع.');
      }
      final header = await _header(ref);
      if (!context.mounted) return;
      await PdfPrintHelper.printPayrollYearReport(context, data,
          header: header);
    });
  }

  /// طباعة تقرير رواتب موظف أو موظفي مشروع
  static Future<void> printEmployeeReport(
    BuildContext context,
    WidgetRef ref,
    EmployeePayrollReportData data,
  ) async {
    await _guarded(context, () async {
      if (data.isEmpty) {
        throw StateError(
          'لا رواتب في هذه الفترة — لا شيء يُطبع. '
          'وسّع المدى أو راجع الفلاتر.',
        );
      }
      final header = await _header(ref);
      if (!context.mounted) return;
      await PdfPrintHelper.printEmployeePayrollReport(context, data,
          header: header);
    });
  }

  // ── الداخل ───────────────────────────────────────────────────────────────

  /// هوية الشركة — **لا تُفشل الطباعة أبداً**
  ///
  /// تعذُّر قراءة الشعار يطبع المستند بلا ترويسة: غياب الشعار إزعاج، وفشل
  /// الطباعة تعطيل. (نفس قرار المرحلة ب-٣.)
  static Future<PdfCompanyHeader> _header(WidgetRef ref) async {
    try {
      return await ref.readOnce(
          pdfCompanyHeaderProvider, pdfCompanyHeaderProvider.future);
    } catch (_) {
      return PdfCompanyHeader.empty;
    }
  }

  /// تشغيل إجراء طباعة مع عرض أي خطأ في شريط سفلي
  static Future<void> _guarded(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on StateError catch (e) {
      // فحص `mounted` هنا لا في `_showError` وحدها: المحلّل لا يرى عبر
      // الدوال، والقاعدة مرفوعة إلى **خطأ** في هذا المشروع.
      if (!context.mounted) return;
      _showError(context, e.message);
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'تعذّرت الطباعة: $e');
    }
  }

  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 6),
      ),
    );
  }
}
