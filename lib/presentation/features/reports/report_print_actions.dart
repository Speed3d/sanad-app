// ─────────────────────────────────────────────────────────────────────────────
// report_print_actions.dart — طباعة وتصدير تبويبات التقارير
//
// **نسخة من نمط `payroll_print_actions.dart` بالضبط** — لا اجتهاد جديد:
//   ١. كل جسم داخل `_guarded` يمسك `StateError` ويعرض رسالتها **كما كُتبت**
//   ٢. حارس فراغ يرمي `StateError` عربية — لا تُطبَع ورقة فارغة
//   ٣. `_header(ref)` بـ`ref.readOnce` ولا تُفشل الطباعة أبداً
//
// ═══ لماذا `ref.readOnce` ولا شيء غيره ═══
//   `pdfCompanyHeaderProvider` مولَّد بـ`@riverpod` فهو **autoDispose**.
//   و`ref.read(p).valueOrNull` عليه من ودجت لا يراقبه يُعيد `null` **دائماً**
//   — لا أحياناً. وهو بالضبط ع-٤٢: كل سند طُبع بلا شعار ولا اسم شركة طوال
//   حياة الميزة، بصمت. يحرس النمطَ `tech_debt_guard_test`.
//
// ═══ لماذا التصدير هنا لا في كل تبويب ═══
//   ستّة تبويبات × (طباعة + تصدير) = اثنتا عشرة نسخة من منطق واحد. وتصحيح
//   إحداها لا يصل البقيّة — وهي عائلة الأعطال الأشيع في هذا المشروع.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/excel_export_service.dart';
import '../../../core/services/pdf_print_helper.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/report_print_data.dart';
import '../../providers/provider_read_once.dart';
import '../../providers/settings_provider.dart';

/// إجراءات الطباعة والتصدير المشتركة بين تبويبات التقارير
abstract final class ReportPrintActions {
  /// طباعة تقرير جدوليّ — بترويسة الشركة
  static Future<void> print(
    BuildContext context,
    WidgetRef ref,
    ReportTableData data,
  ) async {
    await _guarded(context, () async {
      _ensureNotEmpty(data);
      final header = await _header(ref);
      if (!context.mounted) return;
      await PdfPrintHelper.printReportTable(context, data, header: header);
    });
  }

  /// تصدير تقرير جدوليّ إلى ملف **Excel مُنسَّق** يختار المالك مكانه
  ///
  /// استُبدل CSV بـxlsx بعد بلاغ المالك (2026-08-30): «في الإكسل التصميم
  /// غير جيد وبدائي». وهو محقّ — CSV نصٌّ بفواصل لا يحمل تنسيقاً بنيوياً.
  /// والمكسب الأكبر أن الأرقام تخرج **أرقاماً** فتُجمع وتُفرز في Excel.
  static Future<void> exportExcel(
    BuildContext context,
    WidgetRef ref,
    ReportTableData data,
  ) async {
    await _guarded(context, () async {
      _ensureNotEmpty(data);

      // اسم الشركة في ترويسة الورقة — نفس ترويسة الـPDF
      final header = await _header(ref);
      final bytes = ExcelExportService.build(
        data,
        companyName: header.companyName,
      );

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ التقرير كملف Excel',
        fileName: ExcelExportService.fileNameFor(data),
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );
      if (path == null) return; // ألغى المالك — ليس خطأً

      final target = path.toLowerCase().endsWith('.xlsx') ? path : '$path.xlsx';
      await File(target).writeAsBytes(bytes, flush: true);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text('✅ صُدِّر ${data.rowCount} سطراً إلى:\n$target'),
        ),
      );
    });
  }

  // ── الحُرّاس والمساعدات ──────────────────────────────────────────────────

  /// ورقةٌ فارغة تُطبَع أو تُصدَّر تُوهم بأن لا بيانات — وقد يكون الفلتر خاطئاً
  static void _ensureNotEmpty(ReportTableData data) {
    if (data.isEmpty) {
      throw StateError(
        'لا بيانات في هذا التقرير — لا شيء يُطبع.\n'
        'وسّع المدى أو راجع الفلاتر.',
      );
    }
  }

  /// ترويسة الشركة — **لا تُفشل الطباعة أبداً**
  ///
  /// غياب الشعار إزعاج، وفشل الطباعة تعطيل.
  static Future<PdfCompanyHeader> _header(WidgetRef ref) async {
    try {
      return await ref.readOnce(
          pdfCompanyHeaderProvider, pdfCompanyHeaderProvider.future);
    } catch (_) {
      return PdfCompanyHeader.empty;
    }
  }

  static Future<void> _guarded(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on StateError catch (e) {
      if (!context.mounted) return;
      _showError(context, e.message);
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'تعذّرت العملية: $e');
    }
  }

  // فحص `context.mounted` مكرَّر هنا وفي المستدعي عمداً: المحلّل لا يرى عبر
  // الدوال، والقاعدة مرفوعة إلى **خطأ** في هذا المشروع.
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
