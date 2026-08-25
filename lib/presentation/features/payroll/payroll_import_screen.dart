// ─────────────────────────────────────────────────────────────────────────────
// payroll_import_screen.dart — معالج استيراد ملف رواتب الشهر (Schema v7)
//
// أربع خطوات:
//   ١. اختيار الملف — قراءته وبصمته وكشف الاستيراد المكرّر
//   ٢. الشهر والسنة وسعر الصرف
//   ٣. تعيين الأعمدة
//   ٤. المطابقة والمعاينة ثم البناء
//
// **الفرق الجوهري عن استيراد مصاريف السلفة:**
//   ملف الرواتب يصل **ومعه إجاباته الحسابية** — الصافي لكل موظف. وغرض
//   المالك المعلَن منه «التدقيق والمراجعة». فوظيفة هذه الشاشة ليست أن تحسب
//   **له** بل أن تحسب **معه وتُريه أين اختلفا**.
//
// 🔑 **ولا ربط صامت ولا إنشاء صامت** (قرار المالك 2026-08-24): كل سطر يُعرَض
//   بحالة مطابقته — 🟢 موجود · 🔵 جديد سيُنشأ · 🟠 غامض يحتاج بتّاً — ولا
//   يُبنى الكشف قبل حسم كل غامض.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/services/payroll_calculator.dart';
import '../../../core/services/payroll_name_matcher.dart';
import '../../../core/services/payroll_row_parser.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../../core/utils/excel_sheet_reader.dart';
import '../../../core/utils/sheet_value_parser.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/payroll_repository.dart';
import '../../providers/payroll_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/treasury_providers.dart';

// ── أسماء الحقول القابلة للتعيين ────────────────────────────────────────────

const _kName = 'اسم الموظف';
const _kSalary = 'الراتب الأساسي';
const _kPosition = 'الصفة';
const _kHireDate = 'تاريخ التعيين';
const _kDays = 'أيام العمل';
const _kCurrency = 'العملة';
const _kRate = 'سعر الصرف';
const _kBonus = 'المكافأة';
const _kDeduction = 'الخصم';
const _kAbsence = 'أيام الغياب';
const _kNet = 'الصافي المذكور';

const _kRequiredFields = [_kName, _kSalary];

const _kAllFields = [
  _kName,
  _kSalary,
  _kPosition,
  _kHireDate,
  _kDays,
  _kCurrency,
  _kRate,
  _kBonus,
  _kDeduction,
  _kAbsence,
  _kNet,
];

/// قرار المالك في مطابقة سطر
enum _RowDecision {
  /// يُربط بموظف قائم
  link,

  /// يُنشأ موظف جديد
  create,

  /// يُستبعَد من الاستيراد
  skip,
}

/// سطر بعد التحليل والمطابقة — يحمل قرار المالك
class _RowState {
  final ParsedPayrollRow row;
  PayrollNameMatch match;
  _RowDecision decision;
  int? linkedEmployeeId;

  _RowState({
    required this.row,
    required this.match,
    required this.decision,
    this.linkedEmployeeId,
  });

  bool get isResolved =>
      decision == _RowDecision.skip ||
      decision == _RowDecision.create ||
      (decision == _RowDecision.link && linkedEmployeeId != null);
}

class PayrollImportScreen extends ConsumerStatefulWidget {
  const PayrollImportScreen({super.key});

  @override
  ConsumerState<PayrollImportScreen> createState() =>
      _PayrollImportScreenState();
}

class _PayrollImportScreenState extends ConsumerState<PayrollImportScreen> {
  int _step = 0;
  bool _busy = false;

  // ── الملف ──────────────────────────────────────────────────────────────
  String _fileName = '';
  String _fileHash = '';
  PayrollPeriod? _duplicateOf;
  List<List<String>> _rawRows = const [];
  bool _hasHeaderRow = true;

  // ── الوجهة ─────────────────────────────────────────────────────────────
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  double? _exchangeRate;
  double _fileTotal = 0;
  int? _defaultTreasuryId;

  // ── تعيين الأعمدة ──────────────────────────────────────────────────────
  final Map<String, int?> _columnMap = {for (final f in _kAllFields) f: null};

  // ── المطابقة ───────────────────────────────────────────────────────────
  List<_RowState> _rows = const [];
  List<String> _errors = const [];

  List<List<String>> get _dataRows =>
      _hasHeaderRow && _rawRows.isNotEmpty ? _rawRows.sublist(1) : _rawRows;

  // ═══════════════════════════════════════════════════════════════════════
  // الخطوة ١ — الملف
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _pickFile() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _showError('تعذّر قراءة الملف. حاول مجدداً.');
        return;
      }

      final data = ExcelSheetReader.read(bytes);
      final duplicate = await ref
          .read(payrollRepositoryProvider)
          .findByFileHash(data.sha256);

      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _fileHash = data.sha256;
        _duplicateOf = duplicate;
        _rawRows = data.rows;
        _hasHeaderRow = true;
        _autoDetectColumns();
        _step = 1;
      });
    } on FormatException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('خطأ أثناء قراءة الملف: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// تخمين الأعمدة من ترويسة الملف
  ///
  /// تخمينٌ يوفّر على المالك عملاً، **ولا يُلزمه**: كل حقل يبقى قابلاً
  /// للتغيير في الخطوة الثالثة، ويُعرَض عليه ما خُمِّن قبل أن يُبنى شيء.
  void _autoDetectColumns() {
    for (final f in _kAllFields) {
      _columnMap[f] = null;
    }
    if (_rawRows.isEmpty) return;

    const hints = <String, List<String>>{
      _kName: ['اسم', 'الموظف', 'name'],
      _kSalary: ['راتب', 'الاساسي', 'الأساسي', 'salary'],
      _kPosition: ['صفة', 'الصفه', 'وظيفة', 'position', 'title'],
      _kHireDate: ['تعيين', 'مباشرة', 'hire'],
      _kDays: ['ايام العمل', 'أيام العمل', 'المستحقة', 'days'],
      _kCurrency: ['عملة', 'العمله', 'currency'],
      _kRate: ['سعر الصرف', 'صرف', 'rate'],
      _kBonus: ['مكافا', 'مكافأ', 'حافز', 'bonus'],
      _kDeduction: ['خصم', 'استقطاع', 'deduction'],
      _kAbsence: ['غياب', 'absence'],
      _kNet: ['صافي', 'المستحق', 'net'],
    };

    final header = _rawRows.first.map((c) => c.trim().toLowerCase()).toList();
    for (final entry in hints.entries) {
      for (var i = 0; i < header.length; i++) {
        if (_columnMap.containsValue(i)) continue;
        if (entry.value.any((h) => header[i].contains(h))) {
          _columnMap[entry.key] = i;
          break;
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // الخطوة ٤ — التحليل والمطابقة
  // ═══════════════════════════════════════════════════════════════════════

  String _cell(List<String> row, String field) {
    final idx = _columnMap[field];
    if (idx == null || idx >= row.length) return '';
    return row[idx];
  }

  Future<void> _analyze() async {
    setState(() => _busy = true);
    try {
      final candidates =
          await ref.read(payrollMatchCandidatesProvider.future);

      final parsed = <ParsedPayrollRow>[];
      final errors = <String>[];
      final data = _dataRows;

      for (var i = 0; i < data.length; i++) {
        final row = data[i];
        final result = PayrollRowParser.parseRow(
          rowNumber: i + 1,
          rowLabel: 'صف ${i + 1 + (_hasHeaderRow ? 1 : 0)}',
          nameRaw: _cell(row, _kName),
          salaryRaw: _cell(row, _kSalary),
          positionRaw: _cell(row, _kPosition),
          hireDateRaw: _cell(row, _kHireDate),
          eligibleDaysRaw: _cell(row, _kDays),
          currencyRaw: _cell(row, _kCurrency),
          exchangeRateRaw: _cell(row, _kRate),
          bonusRaw: _cell(row, _kBonus),
          deductionRaw: _cell(row, _kDeduction),
          absenceDaysRaw: _cell(row, _kAbsence),
          netAmountRaw: _cell(row, _kNet),
        );
        if (result.row != null) parsed.add(result.row!);
        if (result.error != null) errors.add(result.error!);
      }

      // مجموع الصافي المذكور في الملف — أساس المطابقة الثانية
      final total = parsed.fold<double>(
        0,
        (s, r) => s + (r.fileNetAmount ?? 0),
      );

      final states = parsed.map((r) {
        final match = PayrollNameMatcher.match(
          fileName: r.employeeName,
          fileHireDate: r.hireDate,
          employees: candidates,
        );
        return _RowState(
          row: r,
          match: match,
          decision: switch (match.kind) {
            PayrollMatchKind.matched => _RowDecision.link,
            PayrollMatchKind.isNew => _RowDecision.create,
            // الغامض يبدأ **مستبعَداً** لا مربوطاً: القرار الافتراضي الآمن
            // هو ألّا يدخل شيء حتى يبتّ المالك فيه
            PayrollMatchKind.ambiguous => _RowDecision.skip,
          },
          linkedEmployeeId: match.employee?.employeeId,
        );
      }).toList();

      // سعر الصرف: من الملف إن ورد، وإلا يُدخله المالك في الخطوة ٢
      double? rateFromFile;
      for (final r in parsed) {
        if (r.exchangeRate != null && r.exchangeRate! > 0) {
          rateFromFile = r.exchangeRate;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _rows = states;
        _errors = errors;
        _fileTotal = total;
        _exchangeRate ??= rateFromFile;
        _step = 3;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // البناء النهائي
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _buildSheet() async {
    final included =
        _rows.where((r) => r.decision != _RowDecision.skip).toList();
    if (included.isEmpty) {
      _showError('لا سطر واحد مشمول — راجع قراراتك.');
      return;
    }

    setState(() => _busy = true);
    try {
      final notifier = ref.read(payrollNotifierProvider.notifier);
      final periodId = await notifier.createOrGetPeriod(
        year: _year,
        month: _month,
        exchangeRate: _exchangeRate,
        fileTotal: _fileTotal,
        sourceFileName: _fileName,
        sourceFileHash: _fileHash,
      );
      if (periodId == null) return; // الرسالة عُرضت من المزوّد

      final resolved = included
          .map((r) => ResolvedPayrollRow(
                row: r.row,
                employeeId: r.decision == _RowDecision.link
                    ? r.linkedEmployeeId
                    : null,
                treasuryId: _defaultTreasuryId,
              ))
          .toList();

      final result =
          await notifier.importRows(periodId: periodId, rows: resolved);
      if (result == null || !mounted) return;

      // الفروق بين المحسوب والمذكور تُعرَض قبل مغادرة الشاشة
      if (result.netMismatches.isNotEmpty) {
        await _showMismatches(result.netMismatches);
      }
      if (!mounted) return;
      context.go('${AppRoutes.payroll}/$periodId');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showMismatches(List<String> messages) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('فروق بين المحسوب وما ذكره الملف'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اسْتُورد الكشف كاملاً. هذه السطور اختلف فيها حسابنا عن '
                'الصافي المذكور — راجعها قبل التسديد:',
                style: TextStyle(fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final m in messages)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('• $m',
                            style: const TextStyle(fontSize: 12.5)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.colors.danger,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.payroll);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // البناء
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // ═══════════════════════════════════════════════════════════════════
    // 🔴 مستمع رسائل المزوّد — **غيابه كان العطل نفسه**
    // ═══════════════════════════════════════════════════════════════════
    //
    // بلاغ المالك 2026-08-25: «أضغط بناء كشف أيار 2025 ولا يحدث أي شيء».
    // والحقيقة أن الحارس كان يعمل ويرفض بحقّ (سنته المالية 2026 والكشف
    // لأيار 2025)، ويكتب رسالة عربية واضحة في حالة المزوّد — **ولا أحد
    // يعرضها**. فبدا الزرّ ميتاً.
    //
    // ⚠️ **الدرس:** كل شاشة تستدعي Notifier يضع أخطاءه في حالته **يجب**
    //   أن تستمع إليها. حارسٌ لا تصل رسالته إلى المستخدم يساوي — من
    //   وجهة نظره — زرّاً معطوباً، وهو أسوأ من غياب الحارس لأنه يُفقده
    //   الثقة بالبرنامج كلّه.
    ref.listen(payrollNotifierProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$e'),
              backgroundColor: colors.danger,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: 'إغلاق',
                textColor: Colors.white,
                onPressed: ScaffoldMessenger.of(context).hideCurrentSnackBar,
              ),
            ),
          );
          ref.read(payrollNotifierProvider.notifier).reset();
        },
      );
    });

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text('استيراد ملف رواتب'),
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_forward_rounded),
          tooltip: 'رجوع',
        ),
      ),
      body: Column(
        children: [
          _StepBar(step: _step),
          Expanded(
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : switch (_step) {
                    0 => _buildPickStep(),
                    1 => _buildDestinationStep(),
                    2 => _buildMappingStep(),
                    _ => _buildReviewStep(),
                  },
          ),
        ],
      ),
    );
  }

  // ── الخطوة ١ ───────────────────────────────────────────────────────────

  Widget _buildPickStep() {
    final colors = context.colors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_view_rounded, size: 64, color: colors.gold),
            const SizedBox(height: 16),
            Text(
              'اختر ملف رواتب الشهر',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ملف .xlsx فيه أسماء الموظفين ورواتبهم. '
              'يمكن أن يحوي الصفة وتاريخ التعيين وأيام العمل والمكافآت '
              'والخصومات والصافي — وكلها اختيارية عدا الاسم والراتب.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.subtext),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('اختيار الملف'),
            ),
          ],
        ),
      ),
    );
  }

  // ── الخطوة ٢ ───────────────────────────────────────────────────────────

  Widget _buildDestinationStep() {
    final colors = context.colors;
    final treasuriesAsync = ref.watch(allTreasuriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_duplicateOf != null)
            _Banner(
              color: colors.danger,
              icon: Icons.copy_rounded,
              text: 'هذا الملف استُورد من قبل في كشف '
                  '${PayrollCalculator.periodLabel(_duplicateOf!.year, _duplicateOf!.month)}. '
                  'المتابعة ستُضيف سطوره إلى الشهر الذي تختاره — '
                  'وقد تُضاعف رواتب موظفين.',
            ),
          const SizedBox(height: 12),
          Text('الملف: $_fileName',
              style: TextStyle(fontSize: 13, color: colors.subtext)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _year,
                  decoration: const InputDecoration(
                    labelText: 'السنة',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(6, (i) => DateTime.now().year - 3 + i)
                      .map((y) =>
                          DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (v) => setState(() => _year = v ?? _year),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _month,
                  decoration: const InputDecoration(
                    labelText: 'الشهر',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(12, (i) => i + 1)
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(PayrollCalculator.arabicMonth(m)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _month = v ?? _month),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _exchangeRate?.toString() ?? '',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'سعر صرف الدولار لهذا الشهر (اختياري)',
              helperText:
                  'إلزامي إن كان في الملف راتب بالدولار — لا يُحفَظ مبلغ '
                  'بلا مقابله بالدينار.',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) =>
                _exchangeRate = SheetValueParser.parseSignedAmount(v),
          ),
          const SizedBox(height: 16),
          treasuriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (treasuries) => DropdownButtonFormField<int>(
              initialValue: _defaultTreasuryId,
              decoration: const InputDecoration(
                labelText: 'مشروع/خزينة الموظفين الجدد (اختياري)',
                helperText:
                    'تُنسَب إليها بطاقات الموظفين التي ستُنشأ من هذا الملف، '
                    'فتظهر لاحقاً ضمن موظفي سلفة هذا المشروع.',
                border: OutlineInputBorder(),
              ),
              items: treasuries
                  .map((t) =>
                      DropdownMenuItem(value: t.id, child: Text(t.name)))
                  .toList(),
              onChanged: (v) => setState(() => _defaultTreasuryId = v),
            ),
          ),
          const SizedBox(height: 20),
          // 🔑 التحقّق من السنة المالية **هنا** لا عند البناء: المالك يعرف
          //   المانع قبل أن يعيّن أحد عشر عموداً ويراجع عشرات السطور.
          _FiscalCheckBanner(year: _year, month: _month),
          const SizedBox(height: 24),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton(
              onPressed: () => setState(() => _step = 2),
              child: const Text('التالي — تعيين الأعمدة'),
            ),
          ),
        ],
      ),
    );
  }

  // ── الخطوة ٣ ───────────────────────────────────────────────────────────

  Widget _buildMappingStep() {
    final colors = context.colors;
    final header = _rawRows.isNotEmpty ? _rawRows.first : <String>[];
    final missing = _kRequiredFields
        .where((f) => _columnMap[f] == null)
        .toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  value: _hasHeaderRow,
                  title: const Text('الصف الأول ترويسة أعمدة'),
                  subtitle: const Text('أطفئه إن كان الملف يبدأ ببيانات'),
                  onChanged: (v) => setState(() => _hasHeaderRow = v),
                ),
                const SizedBox(height: 8),
                for (final field in _kAllFields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<int?>(
                      initialValue: _columnMap[field],
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: _kRequiredFields.contains(field)
                            ? '$field *'
                            : field,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('— لا يوجد —')),
                        for (var i = 0; i < header.length; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(
                              header[i].trim().isEmpty
                                  ? 'عمود ${i + 1}'
                                  : '${header[i]}  (عمود ${i + 1})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _columnMap[field] = v),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              if (missing.isNotEmpty)
                Expanded(
                  child: Text(
                    'حقول مطلوبة لم تُعيَّن: ${missing.join(' · ')}',
                    style: TextStyle(fontSize: 12.5, color: colors.danger),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => setState(() => _step = 1),
                child: const Text('السابق'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: missing.isEmpty ? _analyze : null,
                child: const Text('تحليل ومطابقة'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── الخطوة ٤ ───────────────────────────────────────────────────────────

  Widget _buildReviewStep() {
    final colors = context.colors;
    final money = NumberFormat('#,##0.##');

    final ambiguous =
        _rows.where((r) => r.match.isAmbiguous && r.isResolved == false).length;
    final unresolvedAmbiguous = _rows
        .where((r) => r.match.isAmbiguous && r.decision == _RowDecision.skip)
        .length;
    final included =
        _rows.where((r) => r.decision != _RowDecision.skip).length;
    final creating =
        _rows.where((r) => r.decision == _RowDecision.create).length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_errors.isNotEmpty) ...[
                _Banner(
                  color: colors.danger,
                  icon: Icons.error_outline_rounded,
                  text: '${_errors.length} صفاً مرفوضاً لن يدخل الكشف:\n'
                      '${_errors.take(6).join('\n')}'
                      '${_errors.length > 6 ? '\n… و${_errors.length - 6} غيرها' : ''}',
                ),
                const SizedBox(height: 16),
              ],
              if (unresolvedAmbiguous > 0) ...[
                _Banner(
                  color: colors.gold,
                  icon: Icons.help_outline_rounded,
                  text: '$unresolvedAmbiguous سطراً غامضاً — اختر لكلٍّ منها '
                      'الموظف المقصود أو أنشئ موظفاً جديداً. '
                      'الغامض يبقى مستبعَداً حتى تبتّ فيه.',
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  _Chip(
                    label: 'سيدخل الكشف',
                    value: '$included',
                    color: colors.gold,
                  ),
                  const SizedBox(width: 12),
                  _Chip(
                    label: 'موظفون جدد',
                    value: '$creating',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _Chip(
                    label: 'مجموع الملف',
                    value: '${money.format(_fileTotal)} د.ع',
                    color: colors.subtext,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FiscalCheckBanner(year: _year, month: _month),
              const SizedBox(height: 16),
              for (final state in _rows)
                _RowCard(
                  state: state,
                  onDecision: (d, employeeId) => setState(() {
                    state.decision = d;
                    if (employeeId != null) {
                      state.linkedEmployeeId = employeeId;
                    }
                  }),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  ambiguous > 0
                      ? 'يمكنك المتابعة — الغامض المستبعَد لن يدخل الكشف.'
                      : 'كل السطور محسومة.',
                  style: TextStyle(fontSize: 12.5, color: colors.subtext),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _step = 2),
                child: const Text('السابق'),
              ),
              const SizedBox(width: 8),
              // الزرّ يبقى مفعَّلاً حتى لو كانت السنة المالية ناقصة:
              // الضغط يُظهر الرسالة الآن (بعد وصل المستمع)، والمنع الحقيقي
              // في المستودع. تعطيله بلا سبب ظاهر يُعيد «الزرّ الميت» بشكل آخر.
              FilledButton.icon(
                onPressed: included == 0 ? null : _buildSheet,
                icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                label: Text('بناء كشف '
                    '${PayrollCalculator.periodLabel(_year, _month)}'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ودجتات مساعدة
// ═══════════════════════════════════════════════════════════════════════════

class _StepBar extends StatelessWidget {
  final int step;
  const _StepBar({required this.step});

  static const _labels = ['الملف', 'الوجهة', 'الأعمدة', 'المراجعة'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: i <= step ? colors.gold : colors.surface2,
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: i <= step ? colors.onGold : colors.subtext,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _labels[i],
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: i == step ? FontWeight.w800 : FontWeight.w500,
                color: i <= step ? colors.text : colors.subtext,
              ),
            ),
            if (i < _labels.length - 1)
              Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: colors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// شارة حالة السنة المالية للشهر المختار
///
/// تظهر في خطوتَي الوجهة والمراجعة معاً: الأولى لتوفير العمل، والثانية
/// لأن المالك قد يعود ويغيّر الشهر بعد التحليل.
class _FiscalCheckBanner extends ConsumerWidget {
  final int year;
  final int month;

  const _FiscalCheckBanner({required this.year, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final check = ref.watch(payrollMonthFiscalCheckProvider(year, month));

    return check.when(
      loading: () => const SizedBox(height: 4, child: LinearProgressIndicator()),
      error: (e, _) => _Banner(
        color: colors.danger,
        icon: Icons.error_outline_rounded,
        text: 'تعذّر فحص السنة المالية: $e',
      ),
      data: (result) {
        final problem = result.problem;
        if (problem == null) {
          return _Banner(
            color: Colors.green,
            icon: Icons.check_circle_outline_rounded,
            text: 'السنة المالية «${result.fiscalName}» مفتوحة وتغطّي '
                '${PayrollCalculator.periodLabel(year, month)} — '
                'الكشف قابل للبناء.',
          );
        }
        return _Banner(
          color: colors.danger,
          icon: Icons.event_busy_rounded,
          text: problem,
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _Banner({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Chip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: colors.subtext)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

/// بطاقة سطر في المراجعة — تعرض حالة المطابقة وتتيح البتّ فيها
class _RowCard extends StatelessWidget {
  final _RowState state;
  final void Function(_RowDecision, int?) onDecision;

  const _RowCard({required this.state, required this.onDecision});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final money = NumberFormat('#,##0.##');
    final r = state.row;

    final (Color badgeColor, String badgeText) = switch (state.decision) {
      _RowDecision.link => (Colors.green, 'موظف مسجَّل'),
      _RowDecision.create => (Colors.blue, 'جديد — سيُنشأ'),
      _RowDecision.skip => (colors.subtext, 'مستبعَد'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: state.match.isAmbiguous &&
                  state.decision == _RowDecision.skip
              ? colors.gold
              : colors.border,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.employeeName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${r.rowLabel} · ${money.format(r.basicSalary)} '
            '${r.currency == PayrollCurrency.usd ? 'دولار' : 'د.ع'}'
            '${r.position.isNotEmpty ? ' · ${r.position}' : ''}'
            '${r.hireDate != null ? ' · تعيين ${DateFormat('yyyy/MM/dd').format(r.hireDate!)}' : ''}',
            style: TextStyle(fontSize: 12, color: colors.subtext),
          ),
          if (state.match.reason != null) ...[
            const SizedBox(height: 8),
            Text(
              state.match.reason!,
              style: TextStyle(fontSize: 12, color: colors.gold),
            ),
          ],
          if (state.match.candidates.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final c in state.match.candidates)
                  OutlinedButton(
                    onPressed: () => onDecision(_RowDecision.link, c.employeeId),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: state.linkedEmployeeId == c.employeeId &&
                              state.decision == _RowDecision.link
                          ? colors.gold.withValues(alpha: 0.15)
                          : null,
                    ),
                    child: Text(
                      c.hireDate == null
                          ? c.fullName
                          : '${c.fullName} — ${DateFormat('yyyy/MM/dd').format(c.hireDate!)}',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => onDecision(_RowDecision.create, null),
                child: const Text('إنشاء موظف جديد',
                    style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => onDecision(_RowDecision.skip, null),
                child: Text('استبعاد',
                    style: TextStyle(fontSize: 12, color: colors.subtext)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
