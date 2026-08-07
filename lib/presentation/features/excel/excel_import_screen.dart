// ─────────────────────────────────────────────────────────────────────────────
// excel_import_screen.dart — معالج استيراد مصاريف السلفة من Excel
//
// 🔄 أُعيدت كتابة هذه الشاشة (2026-08-07) — التغيير جوهري لا تجميلي:
//   قبل: تقرأ الملف و**تُدرج سندات صرف مباشرة** في الدفاتر، متجاوزةً
//        VoucherRepository وBalanceGuard، بلا مراجعة ولا كشف تكرار.
//   بعد: تُنتج **مسودة سلفة** لا تمسّ رصيد أي خزينة. المراجعة والتصحيح
//        والاعتماد في شاشة مراجعة المسودة.
//
// الخطوات الأربع:
//   1. اختيار الملف — قراءة .xlsx وحساب بصمته لكشف الاستيراد المكرر
//   2. الوجهة — خزينة المشروع + سلفة موجودة أو جديدة
//   3. تعيين الأعمدة + معاينة
//   4. تجهيز المسودة ثم الانتقال لمراجعتها
//
// بالدينار حصراً (قرار المالك): لا حقل عملة، وأي سطر بالدولار يُرفض برسالة
// واضحة بدل تسجيله صامتاً كدينار — وهو خطأ بمقدار سعر الصرف كله.
// ─────────────────────────────────────────────────────────────────────────────

// حزمة excel تُصدِّر Border و TextSpan التي تتعارض مع نظيرتيهما في Flutter —
// نخفيهما لأننا نستعمل نسخ Flutter منهما في الواجهة
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:pointycastle/digests/sha256.dart';

import '../../../core/constants/app_routes.dart';
import '../../../domain/models/advance_model.dart';
import '../../../domain/repositories/i_advance_repository.dart';
import '../../providers/advance_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/treasury_providers.dart';
import 'excel_row_parser.dart';

// ── ثوابت أسماء الحقول ──────────────────────────────────────────────────────

const _kDate = 'التاريخ';
const _kAmount = 'المبلغ';
const _kItemType = 'نوع البند (الفلتر)';
const _kPersonName = 'اسم الشخص';
const _kReason = 'السبب';
const _kProjectName = 'اسم المشروع';
const _kInvoiceNumber = 'رقم الفاتورة';
const _kSpentBy = 'صرف من قبل';

const _kRequiredFields = [_kDate, _kAmount];

const _kAllFields = [
  _kDate,
  _kAmount,
  _kItemType,
  _kPersonName,
  _kReason,
  _kProjectName,
  _kInvoiceNumber,
  _kSpentBy,
];

// ════════════════════════════════════════════════════════════════════════════
// الشاشة الرئيسية
// ════════════════════════════════════════════════════════════════════════════

class ExcelImportScreen extends ConsumerStatefulWidget {
  const ExcelImportScreen({super.key});

  @override
  ConsumerState<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends ConsumerState<ExcelImportScreen> {
  int _step = 0;

  // ── الخطوة 1 — الملف ────────────────────────────────────────────────────
  String? _fileName;
  String _fileHash = '';
  List<List<String>> _rawRows = [];
  bool _hasHeaderRow = true;
  bool _pickingFile = false;
  AdvanceModel? _duplicateOf;

  // ── الخطوة 2 — الوجهة ───────────────────────────────────────────────────
  int? _selectedTreasuryId;
  int? _selectedAdvanceId;
  bool _creatingNewAdvance = true;
  final _newAdvanceNumberCtrl = TextEditingController();
  DateTime _advanceDate = DateTime.now();

  // ── الخطوة 3 — تعيين الأعمدة ────────────────────────────────────────────
  late Map<String, int?> _columnMap;
  int _previewPage = 0;
  static const _previewPageSize = 10;

  // ── الخطوة 4 — التجهيز ──────────────────────────────────────────────────
  bool _working = false;
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    _columnMap = {for (final f in _kAllFields) f: null};
  }

  @override
  void dispose() {
    _newAdvanceNumberCtrl.dispose();
    super.dispose();
  }

  // ── المعاينة ────────────────────────────────────────────────────────────

  List<List<String>> get _dataRows =>
      _hasHeaderRow && _rawRows.isNotEmpty ? _rawRows.sublist(1) : _rawRows;

  List<String> get _headers {
    if (_hasHeaderRow && _rawRows.isNotEmpty) return _rawRows[0];
    return List.generate(
      _rawRows.isEmpty ? 0 : _rawRows[0].length,
      (i) => 'عمود ${i + 1}',
    );
  }

  // ── قراءة الملف ─────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    setState(() => _pickingFile = true);
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

      // بصمة المحتوى — لا اسم الملف، فإعادة التسمية لا تُخفي التكرار.
      // نستخدم SHA256 من pointycastle الموجودة أصلاً للنسخ المشفّرة.
      final digest = SHA256Digest().process(bytes);
      final hash =
          digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      final duplicate =
          await ref.read(advanceRepositoryProvider).findByFileHash(hash);

      final excel = Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) {
        _showError('الملف فارغ أو لا يحتوي على بيانات.');
        return;
      }

      final rows = sheet.rows.map((row) {
        return row.map<String>((cell) {
          final v = cell?.value;
          if (v == null) return '';
          if (v is TextCellValue) return v.value.toString();
          if (v is IntCellValue) return v.value.toString();
          if (v is DoubleCellValue) return v.value.toString();
          if (v is DateCellValue) {
            return '${v.year}/${v.month.toString().padLeft(2, '0')}/'
                '${v.day.toString().padLeft(2, '0')}';
          }
          if (v is BoolCellValue) return v.value.toString();
          return v.toString();
        }).toList();
      }).toList();

      final maxLen = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
      final normalized = rows.map((r) {
        final padded = List<String>.from(r);
        padded.addAll(List.filled(maxLen - r.length, ''));
        return padded;
      }).toList();

      setState(() {
        _fileName = file.name;
        _fileHash = hash;
        _duplicateOf = duplicate;
        _rawRows = normalized;
        _hasHeaderRow = true;
        _columnMap = _autoDetectColumns(normalized);
        _previewPage = 0;
        _step = 1;
      });
    } catch (e) {
      _showError('خطأ أثناء قراءة الملف: $e');
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  /// الكشف التلقائي لتعيين الأعمدة من صف الرأس
  Map<String, int?> _autoDetectColumns(List<List<String>> rows) {
    final map = <String, int?>{for (final f in _kAllFields) f: null};
    if (rows.isEmpty) return map;

    for (int i = 0; i < rows[0].length; i++) {
      final cell = rows[0][i].trim().toLowerCase();
      if (cell.contains('تاريخ') || cell == 'date') {
        map[_kDate] = i;
      } else if (cell.contains('مبلغ') || cell == 'amount') {
        map[_kAmount] = i;
      } else if (cell.contains('بند') ||
          cell.contains('فلتر') ||
          cell.contains('item')) {
        map[_kItemType] = i;
      } else if (cell.contains('مشروع') || cell.contains('مكان')) {
        map[_kProjectName] = i;
      } else if (cell.contains('فاتورة') || cell.contains('وصل')) {
        map[_kInvoiceNumber] = i;
      } else if (cell.contains('صرف من قبل') || cell.contains('قائم بالصرف')) {
        map[_kSpentBy] = i;
      } else if (cell.contains('سبب') || cell.contains('reason')) {
        map[_kReason] = i;
      } else if (cell.contains('اسم') || cell.contains('person')) {
        map[_kPersonName] = i;
      }
    }
    return map;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── التحقق ──────────────────────────────────────────────────────────────

  bool get _destinationReady {
    if (_selectedTreasuryId == null) return false;
    if (_creatingNewAdvance) {
      return _newAdvanceNumberCtrl.text.trim().isNotEmpty;
    }
    return _selectedAdvanceId != null;
  }

  bool get _mappingComplete =>
      _kRequiredFields.every((f) => _columnMap[f] != null);

  String _cell(List<String> row, String field) {
    final idx = _columnMap[field];
    if (idx == null || idx >= row.length) return '';
    return row[idx];
  }

  /// تحليل كل الصفوف — يُعيد الأسطر الصالحة ويجمع الأخطاء
  ///
  /// المنطق نفسه في [ExcelRowParser] لأنه قابل للاختبار هناك، وهذه الدالة
  /// تربطه بتعيين الأعمدة الذي اختاره المستخدم فقط.
  ExcelParseResult _parseRows() {
    final lines = <ParsedAdvanceLine>[];
    final errors = <String>[];
    final data = _dataRows;

    for (int i = 0; i < data.length; i++) {
      final row = data[i];
      final result = ExcelRowParser.parseRow(
        rowNumber: i + 1,
        rowLabel: 'صف ${i + 1 + (_hasHeaderRow ? 1 : 0)}',
        dateRaw: _cell(row, _kDate),
        amountRaw: _cell(row, _kAmount),
        itemType: _cell(row, _kItemType),
        reason: _cell(row, _kReason),
        personName: _cell(row, _kPersonName),
        projectName: _cell(row, _kProjectName),
        invoiceNumber: _cell(row, _kInvoiceNumber),
        spentBy: _cell(row, _kSpentBy),
      );
      if (result.line != null) lines.add(result.line!);
      if (result.error != null) errors.add(result.error!);
    }
    return ExcelParseResult(lines: lines, errors: errors);
  }

  // ── تجهيز المسودة ───────────────────────────────────────────────────────

  Future<void> _buildDraft() async {
    setState(() {
      _working = true;
      _errors = [];
    });

    try {
      final parsed = _parseRows();
      if (parsed.errors.isNotEmpty) {
        setState(() => _errors = parsed.errors);
        return;
      }
      if (parsed.lines.isEmpty) {
        setState(() => _errors = ['الملف لا يحتوي على أي سطر صالح.']);
        return;
      }

      final notifier = ref.read(advanceNotifierProvider.notifier);

      // إنشاء السلفة أو استعمال الموجودة
      int? advanceId = _selectedAdvanceId;
      if (_creatingNewAdvance) {
        advanceId = await notifier.createAdvance(
          advanceNumber: _newAdvanceNumberCtrl.text.trim(),
          projectTreasuryId: _selectedTreasuryId!,
          advanceDate: _advanceDate,
        );
        if (advanceId == null) {
          final err = ref.read(advanceNotifierProvider).error;
          setState(() => _errors = [err?.toString() ?? 'تعذّر إنشاء السلفة.']);
          return;
        }
      }

      final ok = await notifier.createDraft(
        advanceId: advanceId!,
        lines: parsed.lines,
        fileName: _fileName ?? '',
        fileHash: _fileHash,
        replaceExisting: true,
      );

      if (!ok) {
        final err = ref.read(advanceNotifierProvider).error;
        setState(() => _errors = [err?.toString() ?? 'تعذّر تجهيز المسودة.']);
        return;
      }

      // الانتقال مباشرة إلى المراجعة — الاستيراد بلا مراجعة بلا قيمة
      if (mounted) {
        context.go('${AppRoutes.advances}/$advanceId');
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // build
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('استيراد مصاريف سلفة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Stepper(
        currentStep: _step,
        controlsBuilder: (_, __) => const SizedBox.shrink(),
        steps: [
          Step(
            title: const Text('اختيار ملف Excel'),
            subtitle: _fileName != null ? Text(_fileName!) : null,
            content: _buildStep1(theme),
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('وجهة الاستيراد'),
            content: _buildStep2(theme),
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('تعيين الأعمدة والمعاينة'),
            content: _buildStep3(theme),
            isActive: _step >= 2,
            state: _step > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('تجهيز المسودة'),
            content: _buildStep4(theme),
            isActive: _step >= 3,
            state: StepState.indexed,
          ),
        ],
      ),
    );
  }

  // ── الخطوة 1 ────────────────────────────────────────────────────────────

  Widget _buildStep1(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoBanner(
          icon: Icons.shield_outlined,
          color: Colors.green,
          title: 'الاستيراد لا يمسّ أرصدة الخزائن',
          body: 'يُنتج هذا المعالج **مسودة** تراجعها وتصحّح تصنيف مصاريفها، '
              'ولا يتأثر رصيد أي خزينة إلا بعد اعتمادك لها.',
        ),
        const SizedBox(height: 16),
        const _FormatHint(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _pickingFile ? null : _pickFile,
            icon: _pickingFile
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: Text(_pickingFile ? 'جارٍ القراءة…' : 'اختيار ملف .xlsx'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── الخطوة 2 — الوجهة ───────────────────────────────────────────────────

  Widget _buildStep2(ThemeData theme) {
    if (_rawRows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // تحذير التكرار — أهم حاجز في هذه الشاشة
        if (_duplicateOf != null) ...[
          _InfoBanner(
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
            title: 'هذا الملف مستورَد سابقاً',
            body: 'نفس محتوى الملف استُورد في السلفة رقم '
                '${_duplicateOf!.advanceNumber} '
                '(${_duplicateOf!.statusDisplayName}). '
                'المتابعة قد تضاعف المصاريف — تأكد قبل الاستمرار.',
          ),
          const SizedBox(height: 16),
        ],

        // خزينة المشروع
        Consumer(
          builder: (_, ref, __) {
            final tAsync = ref.watch(allTreasuriesProvider);
            return tAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('خطأ: $e'),
              data: (list) {
                final eff = list.any((t) => t.id == _selectedTreasuryId)
                    ? _selectedTreasuryId
                    : null;
                return DropdownButtonFormField<int>(
                  key: ValueKey('treasury_$eff'),
                  initialValue: eff,
                  decoration: const InputDecoration(
                    labelText: 'خزينة المشروع *',
                    helperText: 'الخزينة التي صُرفت منها هذه المصاريف',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: list
                      .map((t) =>
                          DropdownMenuItem(value: t.id, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedTreasuryId = v;
                    _selectedAdvanceId = null;
                  }),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),

        Text('السلفة', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.folder_open_outlined),
              label: Text('سلفة موجودة'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.create_new_folder_outlined),
              label: Text('سلفة جديدة'),
            ),
          ],
          selected: {_creatingNewAdvance},
          onSelectionChanged: (s) =>
              setState(() => _creatingNewAdvance = s.first),
        ),
        const SizedBox(height: 12),

        if (_creatingNewAdvance)
          Column(
            children: [
              TextFormField(
                controller: _newAdvanceNumberCtrl,
                decoration: const InputDecoration(
                  labelText: 'رقم السلفة الجديدة *',
                  hintText: 'مثال: 23',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _advanceDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _advanceDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'تاريخ السلفة',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Text(DateFormat('yyyy/MM/dd').format(_advanceDate)),
                ),
              ),
            ],
          )
        else if (_selectedTreasuryId == null)
          const Text('اختر خزينة المشروع أولاً لعرض سلفها المفتوحة.')
        else
          Consumer(
            builder: (_, ref, __) {
              final aAsync = ref.watch(
                activeAdvancesForTreasuryProvider(_selectedTreasuryId!),
              );
              return aAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('خطأ: $e'),
                data: (list) {
                  if (list.isEmpty) {
                    return _InfoBanner(
                      icon: Icons.info_outline,
                      color: Colors.blue,
                      title: 'لا توجد سلف مفتوحة لهذه الخزينة',
                      body: 'أنشئ سلفة جديدة، أو حوّل مبلغاً إلى هذه الخزينة '
                          'مع رقم سلفة أولاً.',
                    );
                  }
                  return DropdownButtonFormField<int>(
                    key: ValueKey('adv_$_selectedAdvanceId'),
                    initialValue: _selectedAdvanceId,
                    decoration: const InputDecoration(
                      labelText: 'السلفة المستهدفة *',
                      prefixIcon: Icon(Icons.folder_shared_outlined),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: list
                        .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                'سلفة ${a.advanceNumber} — '
                                '${a.statusDisplayName}',
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedAdvanceId = v),
                  );
                },
              );
            },
          ),

        const SizedBox(height: 20),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('رجوع'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    _destinationReady ? () => setState(() => _step = 2) : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('متابعة'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── الخطوة 3 — الأعمدة والمعاينة ────────────────────────────────────────

  Widget _buildStep3(ThemeData theme) {
    if (_rawRows.isEmpty) return const SizedBox.shrink();

    final headers = _headers;
    final dataRows = _dataRows;
    final start = _previewPage * _previewPageSize;
    final end = (start + _previewPageSize).clamp(0, dataRows.length);
    final pageRows = dataRows.sublist(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.table_chart_outlined, size: 18),
            const SizedBox(width: 6),
            Text('${dataRows.length} صف | ${headers.length} عمود'),
            const Spacer(),
            Row(
              children: [
                Checkbox(
                  value: _hasHeaderRow,
                  onChanged: (v) => setState(() => _hasHeaderRow = v ?? true),
                ),
                const Text('السطر الأول رأس'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        Text('تعيين الأعمدة', style: theme.textTheme.labelLarge),
        Text(
          'الحقول غير المُعيَّنة تبقى فارغة ويمكن ملؤها في شاشة المراجعة.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ..._kAllFields.map((field) {
          final isRequired = _kRequiredFields.contains(field);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DropdownButtonFormField<int?>(
              key: ValueKey('${field}_${_columnMap[field]}'),
              initialValue: _columnMap[field],
              decoration: InputDecoration(
                labelText: '$field${isRequired ? ' *' : ''}',
                border: const OutlineInputBorder(),
                isDense: true,
                errorText: isRequired && _columnMap[field] == null
                    ? 'هذا الحقل إلزامي'
                    : null,
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('— غير مُعيَّن —'),
                ),
                ...List.generate(
                  headers.length,
                  (j) => DropdownMenuItem<int?>(
                    value: j,
                    child: Text('${j + 1}: ${headers[j]}'),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _columnMap[field] = v),
            ),
          );
        }),
        const SizedBox(height: 12),

        if (pageRows.isNotEmpty) ...[
          Text('معاينة (${start + 1}–$end من ${dataRows.length})',
              style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              headingRowHeight: 36,
              dataRowMinHeight: 28,
              dataRowMaxHeight: 36,
              columns: [
                const DataColumn(label: Text('#')),
                ...headers.map((h) => DataColumn(label: Text(h))),
              ],
              rows: List.generate(pageRows.length, (j) {
                final row = pageRows[j];
                return DataRow(
                  cells: [
                    DataCell(Text('${start + j + 1}')),
                    ...row.map((c) => DataCell(
                          Text(c, overflow: TextOverflow.ellipsis, maxLines: 1),
                        )),
                  ],
                );
              }),
            ),
          ),
          if (dataRows.length > _previewPageSize)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.navigate_before),
                  onPressed: _previewPage > 0
                      ? () => setState(() => _previewPage--)
                      : null,
                ),
                Text('${_previewPage + 1} / '
                    '${((dataRows.length - 1) ~/ _previewPageSize) + 1}'),
                IconButton(
                  icon: const Icon(Icons.navigate_next),
                  onPressed: end < dataRows.length
                      ? () => setState(() => _previewPage++)
                      : null,
                ),
              ],
            ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text('رجوع'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    _mappingComplete ? () => setState(() => _step = 3) : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('متابعة'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── الخطوة 4 — التجهيز ──────────────────────────────────────────────────

  Widget _buildStep4(ThemeData theme) {
    if (_rawRows.isEmpty) return const SizedBox.shrink();

    final parsed = _parseRows();
    final total = parsed.lines.fold<double>(0, (s, l) => s + l.amount);
    final fmt = NumberFormat('#,##0.##');
    final displayErrors = _errors.isNotEmpty ? _errors : parsed.errors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryTile(
          icon: Icons.table_rows_outlined,
          label: 'أسطر صالحة',
          value: '${parsed.lines.length}',
        ),
        _SummaryTile(
          icon: Icons.functions,
          label: 'إجمالي المصاريف',
          value: '${fmt.format(total)} د.ع',
        ),
        if (displayErrors.isNotEmpty)
          _SummaryTile(
            icon: Icons.error_outline,
            label: 'أسطر بها مشاكل',
            value: '${displayErrors.length}',
            color: Colors.red,
          ),

        if (displayErrors.isNotEmpty) ...[
          const SizedBox(height: 8),
          _InfoBanner(
            icon: Icons.block,
            color: Colors.red,
            title: 'لن تُجهَّز المسودة قبل إصلاح هذه الأسطر',
            body: 'تجهيز مسودة ناقصة يعني مطابقة خاطئة مع جدول الإكسل.',
          ),
          const SizedBox(height: 8),
          ...displayErrors.take(20).map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.close, size: 14, color: Colors.red),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(e, style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
          if (displayErrors.length > 20)
            Text('… و${displayErrors.length - 20} خطأ آخر',
                style: const TextStyle(fontSize: 12, color: Colors.red)),
        ] else ...[
          const SizedBox(height: 8),
          _InfoBanner(
            icon: Icons.check_circle_outline,
            color: Colors.green,
            title: 'جاهز للتجهيز',
            body: 'ستُفتح شاشة المراجعة بعدها لتصحّح تصنيف المصاريف '
                'وتطابق الإجمالي قبل الاعتماد. لن يتأثر رصيد الخزينة الآن.',
          ),
        ],

        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton(
              onPressed: _working ? null : () => setState(() => _step = 2),
              child: const Text('رجوع'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: (_working || parsed.lines.isEmpty ||
                        displayErrors.isNotEmpty)
                    ? null
                    : _buildDraft,
                icon: _working
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fact_check_outlined),
                label: Text(_working ? 'جارٍ التجهيز…' : 'تجهيز المسودة'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets مساعدة
// ════════════════════════════════════════════════════════════════════════════

/// شريط معلومات ملوّن
class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// تلميح بتنسيق الأعمدة المتوقع
class _FormatHint extends StatelessWidget {
  const _FormatHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text('الأعمدة المتوقعة (تُكتشَف تلقائياً من صف الرأس):',
                  style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 8),
          const _HintRow(label: 'التاريخ', hint: 'YYYY/MM/DD *'),
          const _HintRow(label: 'المبلغ', hint: 'رقم موجب بالدينار *'),
          const _HintRow(label: 'نوع البند', hint: 'كهربائيات، بانزين، طعام…'),
          const _HintRow(label: 'السبب', hint: 'نصي'),
          const _HintRow(label: 'اسم الشخص', hint: 'نصي'),
          const _HintRow(label: 'اسم المشروع', hint: 'نصي'),
          const _HintRow(label: 'رقم الفاتورة', hint: 'نصي'),
          const _HintRow(label: 'صرف من قبل', hint: 'نصي'),
          const SizedBox(height: 6),
          Text(
            'ملاحظة: الاستيراد بالدينار العراقي فقط — أي سطر بالدولار يُرفض.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.label, required this.hint});
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          const Icon(Icons.chevron_left, size: 14),
          const SizedBox(width: 4),
          SizedBox(
            width: 110,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, color: c)),
        ],
      ),
    );
  }
}
