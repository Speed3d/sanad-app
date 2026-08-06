// ─────────────────────────────────────────────────────────────────────────────
// excel_import_screen.dart — معالج استيراد Excel
//
// معالج مكون من 3 خطوات:
//   1. اختيار الملف  — file_picker يختار .xlsx ويقرأ الـ bytes
//   2. معاينة + تعيين الأعمدة — Stepper ثانٍ مع dropdown لكل حقل
//   3. تأكيد + استيراد — progress indicator مع ملخص النتائج
//
// الحقول المدعومة للاستيراد:
//   نوع السند | التاريخ | المبلغ | العملة | اسم الشخص | السبب | نوع البند
//
// ملاحظة:
//   يستخدم FilePicker.platform.pickFiles(withData: true) للتوافق مع Web.
//   يستخدم حزمة excel لتحليل ملفات .xlsx.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' show Value;
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../providers/treasury_providers.dart';
import '../../providers/voucher_providers.dart';

// ── ثوابت أسماء الحقول ──────────────────────────────────────────────────────

const _kVoucherType = 'نوع السند';
const _kDate = 'التاريخ';
const _kAmount = 'المبلغ';
const _kCurrency = 'العملة';
const _kPersonName = 'اسم الشخص';
const _kReason = 'السبب';
const _kItemType = 'نوع البند';
const _kProjectName = 'اسم المشروع';
const _kInvoiceNumber = 'رقم الفاتورة';
const _kSpentBy = 'صرف من قبل';

const _kRequiredFields = [_kVoucherType, _kDate, _kAmount];

const _kAllFields = [
  _kVoucherType,
  _kDate,
  _kAmount,
  _kCurrency,
  _kPersonName,
  _kReason,
  _kItemType,
  _kProjectName,
  _kInvoiceNumber,
  _kSpentBy,
];

// ════════════════════════════════════════════════════════════════════════════
// ExcelImportScreen — الشاشة الرئيسية
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
  List<List<String>> _rawRows = []; // الصفوف كنصوص (بعد التحويل)
  bool _hasHeaderRow = true;
  bool _pickingFile = false;

  // ── الخطوة 2 — تعيين الأعمدة ────────────────────────────────────────────
  // Map<fieldName, columnIndex | null>
  late Map<String, int?> _columnMap;
  int? _selectedTreasuryId;
  String _advanceNumber = '';
  // صفحة المعاينة
  int _previewPage = 0;
  static const _previewPageSize = 10;

  // ── الخطوة 3 — الاستيراد ─────────────────────────────────────────────────
  bool _importing = false;
  int _importedCount = 0;
  int _failedCount = 0;
  List<String> _errors = [];
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _columnMap = {for (final f in _kAllFields) f: null};
  }

  // ── المعاينة من الصفوف المُحوَّلة ───────────────────────────────────────

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

      final excel = Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) {
        _showError('الملف فارغ أو لا يحتوي على بيانات.');
        return;
      }

      // تحويل جميع الخلايا إلى نصوص (مع ضمان النوع String)
      final rows = sheet.rows.map((row) {
        return row.map<String>((cell) {
          final v = cell?.value;
          if (v == null) return '';
          if (v is TextCellValue) return v.value.toString();
          if (v is IntCellValue) return v.value.toString();
          if (v is DoubleCellValue) return v.value.toString();
          if (v is DateCellValue) {
            return '${v.year}/${v.month.toString().padLeft(2, '0')}/${v.day.toString().padLeft(2, '0')}';
          }
          if (v is BoolCellValue) return v.value.toString();
          return v.toString();
        }).toList();
      }).toList();

      // تحديد العرض الأقصى (جعل كل صف بنفس الطول)
      final maxLen = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
      final normalizedRows = rows.map((r) {
        final padded = List<String>.from(r);
        padded.addAll(List.filled(maxLen - r.length, ''));
        return padded;
      }).toList();

      // الكشف التلقائي للأعمدة من الرأس
      final autoMap = <String, int?>{for (final f in _kAllFields) f: null};
      if (normalizedRows.isNotEmpty) {
        final firstRow = normalizedRows[0];
        for (int i = 0; i < firstRow.length; i++) {
          final cell = firstRow[i].trim().toLowerCase();
          if (cell.contains('نوع') && cell.contains('سند')) {
            autoMap[_kVoucherType] = i;
          } else if (cell.contains('تاريخ') || cell == 'date') {
            autoMap[_kDate] = i;
          } else if (cell.contains('مبلغ') || cell == 'amount') {
            autoMap[_kAmount] = i;
          } else if (cell.contains('عملة') || cell == 'currency') {
            autoMap[_kCurrency] = i;
          } else if (cell.contains('اسم') || cell.contains('person')) {
            autoMap[_kPersonName] = i;
          } else if (cell.contains('سبب') || cell.contains('reason')) {
            autoMap[_kReason] = i;
          } else if (cell.contains('بند') || cell.contains('item')) {
            autoMap[_kItemType] = i;
          } else if (cell.contains('مشروع') || cell.contains('مكان')) {
            autoMap[_kProjectName] = i;
          } else if (cell.contains('فاتورة') || cell.contains('وصل')) {
            autoMap[_kInvoiceNumber] = i;
          } else if (cell.contains('صرف من قبل') || cell.contains('قائم بالصرف')) {
            autoMap[_kSpentBy] = i;
          }
        }
      }

      setState(() {
        _fileName = file.name;
        _rawRows = normalizedRows;
        _hasHeaderRow = true;
        _columnMap = autoMap;
        _previewPage = 0;
        _step = 1;
      });
    } catch (e) {
      _showError('خطأ أثناء قراءة الملف: $e');
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
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

  // ── التحقق من اكتمال التعيين ─────────────────────────────────────────────

  bool get _mappingComplete {
    for (final field in _kRequiredFields) {
      if (_columnMap[field] == null) return false;
    }
    return _selectedTreasuryId != null;
  }

  // ── الاستيراد ────────────────────────────────────────────────────────────

  Future<void> _startImport() async {
    setState(() {
      _importing = true;
      _importedCount = 0;
      _failedCount = 0;
      _errors = [];
      _done = false;
    });

    final db = ref.read(appDatabaseProvider);
    final treasuryId = _selectedTreasuryId!;
    final data = _dataRows;
    final List<VouchersCompanion> batchList = [];

    for (int i = 0; i < data.length; i++) {
      final row = data[i];
      try {
        // قراءة القيم المطلوبة
        final typeRaw = _getCell(row, _kVoucherType).toLowerCase().trim();
        final dateRaw = _getCell(row, _kDate).trim();
        final amountRaw = _getCell(row, _kAmount).trim();
        final currency = _getCell(row, _kCurrency).trim().toUpperCase();
        final personName = _getCell(row, _kPersonName).trim();
        final reason = _getCell(row, _kReason).trim();
        final itemType = _getCell(row, _kItemType).trim();
        final projectName = _getCell(row, _kProjectName).trim();
        final invoiceNumber = _getCell(row, _kInvoiceNumber).trim();
        final spentBy = _getCell(row, _kSpentBy).trim();

        // تحويل النوع
        final String voucherType;
        if (typeRaw.contains('صرف') || typeRaw == 'sarf') {
          voucherType = 'sarf';
        } else if (typeRaw.contains('قبض') || typeRaw == 'kabd') {
          voucherType = 'kabd';
        } else {
          throw Exception('نوع السند غير معروف: "$typeRaw"');
        }

        // تحويل التاريخ
        final date = _parseDate(dateRaw);
        if (date == null) {
          throw Exception('تاريخ غير صحيح: "$dateRaw"');
        }

        // تحويل المبلغ
        final amount = double.tryParse(
          amountRaw.replaceAll(',', '').replaceAll(' ', ''),
        );
        if (amount == null || amount <= 0) {
          throw Exception('مبلغ غير صحيح: "$amountRaw"');
        }

        // الفترة المالية
        final period =
            await db.fiscalPeriodsDao.getFiscalPeriodForDate(date);
        if (period == null) {
          throw Exception('لا توجد فترة مالية للتاريخ: $dateRaw');
        }

        // رقم السند التالي
        final voucherNumber = await db.fiscalPeriodsDao.getNextVoucherNumber(
          fiscalPeriodId: period.id,
          voucherType: voucherType,
        );

        // إضافة السند إلى القائمة المجمعة
        batchList.add(
          VouchersCompanion.insert(
            voucherNumber: voucherNumber,
            voucherType: voucherType,
            treasuryId: treasuryId,
            fiscalPeriodId: period.id,
            amount: amount,
            currency: Value(
              currency.isNotEmpty && (currency == 'USD' || currency == 'IQD')
                  ? currency
                  : 'IQD',
            ),
            voucherDate: date,
            personName: Value(personName),
            reason: Value(reason),
            itemType: Value(itemType),
            projectName: Value(projectName.isEmpty ? null : projectName),
            invoiceNumber: Value(invoiceNumber.isEmpty ? null : invoiceNumber),
            spentBy: Value(spentBy.isEmpty ? null : spentBy),
            advanceNumber: Value(_advanceNumber.isEmpty ? null : _advanceNumber),
          ),
        );
      } catch (e) {
        setState(() {
          _failedCount++;
          _errors.add('صف ${i + 1 + (_hasHeaderRow ? 1 : 0)}: $e');
        });
      }
    }

    // التنفيذ המجمّع (Batch Insert)
    if (batchList.isNotEmpty && _failedCount == 0) {
      try {
        await db.vouchersDao.insertVouchersBatch(batchList);
        setState(() => _importedCount = batchList.length);
      } catch (e) {
        setState(() {
          _failedCount = batchList.length;
          _errors.add('خطأ في إدخال قاعدة البيانات: $e');
        });
      }
    } else if (_failedCount > 0) {
       _errors.add('تم إلغاء الترحيل بسبب وجود أخطاء في بعض الصفوف لحماية البيانات.');
    }

    // إعادة تحميل providers المتأثرة
    ref.invalidate(vouchersByTypeProvider('sarf'));
    ref.invalidate(vouchersByTypeProvider('kabd'));

    setState(() {
      _importing = false;
      _done = true;
    });
  }

  String _getCell(List<String> row, String field) {
    final idx = _columnMap[field];
    if (idx == null || idx >= row.length) return '';
    return row[idx];
  }

  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    // صيغ مدعومة: YYYY/MM/DD | YYYY-MM-DD | DD/MM/YYYY | DD-MM-YYYY
    try {
      final parts = raw.split(RegExp(r'[/\-.]'));
      if (parts.length != 3) return null;
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      final c = int.tryParse(parts[2]);
      if (a == null || b == null || c == null) return null;
      if (a > 31) {
        // YYYY/MM/DD
        return DateTime(a, b, c);
      } else {
        // DD/MM/YYYY
        return DateTime(c, b, a);
      }
    } catch (_) {
      return null;
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
        title: const Text('استيراد من Excel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Stepper(
        currentStep: _step,
        controlsBuilder: (ctx, details) => const SizedBox.shrink(),
        steps: [
          // ── الخطوة 1: اختيار الملف ──────────────────────────────────
          Step(
            title: const Text('اختيار ملف Excel'),
            subtitle: _fileName != null ? Text(_fileName!) : null,
            content: _buildStep1(),
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.indexed,
          ),
          // ── الخطوة 2: معاينة وتعيين الأعمدة ────────────────────────
          Step(
            title: const Text('معاينة وتعيين الأعمدة'),
            content: _buildStep2(theme),
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.indexed,
          ),
          // ── الخطوة 3: الاستيراد ─────────────────────────────────────
          Step(
            title: const Text('تأكيد الاستيراد'),
            content: _buildStep3(theme),
            isActive: _step >= 2,
            state: _done ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }

  // ── الخطوة 1 ────────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر ملف Excel (.xlsx) يحتوي على بيانات السندات.\n'
          'يجب أن يحتوي الملف على أعمدة: نوع السند، التاريخ، المبلغ.',
        ),
        const SizedBox(height: 16),
        // تنسيق العمود المتوقع
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

  // ── الخطوة 2 ────────────────────────────────────────────────────────────

  Widget _buildStep2(ThemeData theme) {
    if (_rawRows.isEmpty) return const SizedBox.shrink();

    final headers = _headers;
    final dataRows = _dataRows;
    // صفحة المعاينة
    final start = _previewPage * _previewPageSize;
    final end = (start + _previewPageSize).clamp(0, dataRows.length);
    final pageRows = dataRows.sublist(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── معلومات الملف ──────────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.table_chart_outlined, size: 18),
            const SizedBox(width: 6),
            Text('${dataRows.length} صف | ${headers.length} عمود'),
            const Spacer(),
            // هل السطر الأول رأس؟
            Row(
              children: [
                Checkbox(
                  value: _hasHeaderRow,
                  onChanged: (v) =>
                      setState(() => _hasHeaderRow = v ?? true),
                ),
                const Text('السطر الأول رأس'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ── اختيار الخزينة ────────────────────────────────────────
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
                  key: ValueKey(eff),
                  initialValue: eff,
                  decoration: const InputDecoration(
                    labelText: 'الخزينة المستهدفة *',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: list
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedTreasuryId = v),
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        // ── إدخال رقم السلفة (اختياري) ────────────────────────────
        TextFormField(
          initialValue: _advanceNumber,
          decoration: const InputDecoration(
            labelText: 'رقم السلفة (لتجميع هذه الصرفيات معاً)',
            hintText: 'مثال: 23',
            prefixIcon: Icon(Icons.folder_shared_outlined),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) => _advanceNumber = v,
        ),
        const SizedBox(height: 16),
        // ── تعيين الأعمدة ──────────────────────────────────────────
        Text('تعيين الأعمدة', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        ...List.generate(_kAllFields.length, (i) {
          final field = _kAllFields[i];
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
              onChanged: (v) =>
                  setState(() => _columnMap[field] = v),
            ),
          );
        }),
        const SizedBox(height: 12),
        // ── معاينة البيانات ────────────────────────────────────────
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
                    ...row.map((cell) => DataCell(
                          Text(
                            cell,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        )),
                  ],
                );
              }),
            ),
          ),
          // تنقل الصفحات
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
                  onPressed:
                      end < dataRows.length
                          ? () => setState(() => _previewPage++)
                          : null,
                ),
              ],
            ),
        ],
        const SizedBox(height: 16),
        // ── زر التالي ─────────────────────────────────────────────
        Row(
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('رجوع'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _mappingComplete
                    ? () => setState(() => _step = 2)
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('متابعة للاستيراد'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── الخطوة 3 ────────────────────────────────────────────────────────────

  Widget _buildStep3(ThemeData theme) {
    final dataRows = _dataRows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_importing && !_done) ...[
          // ملخص ما سيُستورَد
          _SummaryTile(
            icon: Icons.table_rows_outlined,
            label: 'عدد السجلات للاستيراد',
            value: '${dataRows.length} سجل',
          ),
          Consumer(
            builder: (_, ref, __) {
              final tAsync = ref.watch(allTreasuriesProvider);
              final name = tAsync.valueOrNull
                      ?.firstWhere(
                        (t) => t.id == _selectedTreasuryId,
                        orElse: () =>
                            tAsync.valueOrNull!.first,
                      )
                      .name ??
                  '—';
              return _SummaryTile(
                icon: Icons.account_balance_outlined,
                label: 'الخزينة المستهدفة',
                value: name,
              );
            },
          ),
          const SizedBox(height: 4),
          const Text(
            'تحذير: لا يمكن التراجع عن الاستيراد بعد البدء.',
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
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
                  onPressed: _startImport,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('بدء الاستيراد'),
                ),
              ),
            ],
          ),
        ],

        if (_importing) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: dataRows.isEmpty
                ? null
                : (_importedCount + _failedCount) / dataRows.length,
          ),
          const SizedBox(height: 12),
          Text(
            'جارٍ الاستيراد… ${_importedCount + _failedCount} / ${dataRows.length}',
            style: theme.textTheme.bodyMedium,
          ),
        ],

        if (_done) ...[
          // نتيجة الاستيراد
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'اكتمل الاستيراد',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryTile(
            icon: Icons.check,
            label: 'تم استيرادها بنجاح',
            value: '$_importedCount سجل',
            color: Colors.green,
          ),
          if (_failedCount > 0)
            _SummaryTile(
              icon: Icons.warning_amber_outlined,
              label: 'فشل استيرادها',
              value: '$_failedCount سجل',
              color: Colors.red,
            ),
          if (_errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            ExpansionTile(
              title: Text(
                'تفاصيل الأخطاء (${_errors.length})',
                style: const TextStyle(fontSize: 13, color: Colors.red),
              ),
              children: _errors
                  .take(20)
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 14, color: Colors.red),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(e, style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.check),
              label: const Text('إنهاء'),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets مساعدة
// ════════════════════════════════════════════════════════════════════════════

/// تلميح بتنسيق العمود المتوقع
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
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'التنسيق المقترح للأعمدة:',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _HintRow(col: 'A', label: 'نوع السند', hint: 'صرف أو قبض *'),
          const _HintRow(col: 'B', label: 'التاريخ', hint: 'YYYY/MM/DD *'),
          const _HintRow(col: 'C', label: 'المبلغ', hint: 'رقم موجب *'),
          const _HintRow(col: 'D', label: 'العملة', hint: 'IQD أو USD'),
          const _HintRow(col: 'E', label: 'اسم الشخص', hint: 'نصي'),
          const _HintRow(col: 'F', label: 'السبب', hint: 'نصي'),
          const _HintRow(col: 'G', label: 'نوع البند', hint: 'نصي'),
        ],
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.col, required this.label, required this.hint});
  final String col;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              col,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: c),
          ),
        ],
      ),
    );
  }
}
