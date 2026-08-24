import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/advance_model.dart';
import '../../providers/advance_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/treasury_providers.dart';
import '../../providers/voucher_providers.dart';

class VoucherTransferScreen extends ConsumerStatefulWidget {
  const VoucherTransferScreen({super.key});

  @override
  ConsumerState<VoucherTransferScreen> createState() =>
      _VoucherTransferScreenState();
}

class _VoucherTransferScreenState extends ConsumerState<VoucherTransferScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _fromTreasuryId;
  int? _toTreasuryId;
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _exchangeRateCtrl = TextEditingController(text: '1.0');

  DateTime _voucherDate = DateTime.now();
  String _currency = 'IQD';

  // ── ربط التحويل بسلفة مشروع (اختياري) ───────────────────────────────────
  // بهذا الربط يُحتسَب «المُرسَل» في تقرير السلفة، فتصح المطابقة:
  // أرسلتُ كذا ← صرفوا كذا ← المتبقي كذا.
  bool _linkToAdvance = false;
  bool _createNewAdvance = true;
  int? _selectedAdvanceId;
  final _advanceNumberCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _exchangeRateCtrl.dispose();
    _advanceNumberCtrl.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromTreasuryId == null || _toTreasuryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يرجى تحديد الخزينة المُرسِلة والمُستقبِلة'),
          backgroundColor: Colors.red));
      return;
    }
    if (_fromTreasuryId == _toTreasuryId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('لا يمكن التحويل لنفس الخزينة'),
          backgroundColor: Colors.red));
      return;
    }

    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('المبلغ يجب أن يكون أكبر من صفر'),
          backgroundColor: Colors.red));
      return;
    }

    final exRate = double.tryParse(_exchangeRateCtrl.text) ?? 1.0;

    // ── تجهيز السلفة قبل التحويل ─────────────────────────────────────────
    // نُنشئ السلفة أولاً لأن التحويل يحتاج معرّفها ليربط طرفيه بها. لو فشل
    // إنشاؤها (رقم مكرر مثلاً) نتوقف قبل تحريك أي مال.
    int? advanceId;
    if (_linkToAdvance) {
      if (_createNewAdvance) {
        final number = _advanceNumberCtrl.text.trim();
        if (number.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('اكتب رقم السلفة الجديدة أو ألغِ الربط'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        advanceId =
            await ref.read(advanceNotifierProvider.notifier).createAdvance(
                  advanceNumber: number,
                  projectTreasuryId: _toTreasuryId!,
                  advanceDate: _voucherDate,
                );
        if (advanceId == null) {
          // رسالة الخطأ تظهر عبر مستمع advanceNotifierProvider أدناه
          return;
        }
      } else {
        if (_selectedAdvanceId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('اختر السلفة أو ألغِ الربط'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        advanceId = _selectedAdvanceId;
      }
    }

    final success =
        await ref.read(voucherTransferNotifierProvider.notifier).createTransfer(
              fromTreasuryId: _fromTreasuryId!,
              toTreasuryId: _toTreasuryId!,
              amount: amount,
              currency: _currency,
              voucherDate: _voucherDate,
              reason: _reasonCtrl.text.trim(),
              exchangeRate: exRate,
              advanceId: advanceId,
            );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            advanceId != null
                ? 'تم التحويل وربطه بالسلفة بنجاح'
                : 'تم التحويل بين الخزائن بنجاح',
          ),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }

  // ── قسم ربط التحويل بسلفة ────────────────────────────────────────────────

  /// واجهة ربط التحويل بسلفة مشروع
  ///
  /// الربط اختياري: التحويلات الإدارية بين الخزائن لا علاقة لها بالسلف.
  /// لكن عند تمويل مشروع، الربط هو ما يجعل «المُرسَل» قابلاً للحساب لاحقاً.
  Widget _buildAdvanceSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              value: _linkToAdvance,
              onChanged: (v) => setState(() => _linkToAdvance = v),
              contentPadding: EdgeInsets.zero,
              title: const Text('هذا التحويل تمويل لسلفة مشروع'),
              subtitle: const Text(
                'الربط يجعل النظام يحسب: أرسلتُ كذا ← صرفوا كذا ← المتبقي كذا',
                style: TextStyle(fontSize: 11),
              ),
            ),
            if (_linkToAdvance) ...[
              if (_toTreasuryId == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'اختر الخزينة المُستقبِلة أولاً.',
                    style: TextStyle(fontSize: 12),
                  ),
                )
              else ...[
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.folder_open_outlined, size: 16),
                      label: Text('سلفة موجودة'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.create_new_folder_outlined, size: 16),
                      label: Text('سلفة جديدة'),
                    ),
                  ],
                  selected: {_createNewAdvance},
                  onSelectionChanged: (s) =>
                      setState(() => _createNewAdvance = s.first),
                ),
                const SizedBox(height: 12),
                if (_createNewAdvance)
                  TextFormField(
                    controller: _advanceNumberCtrl,
                    decoration: const InputDecoration(
                      labelText: 'رقم السلفة الجديدة *',
                      hintText: 'مثال: 23',
                      prefixIcon: Icon(Icons.tag),
                      isDense: true,
                    ),
                  )
                else
                  Consumer(
                    builder: (_, ref, __) {
                      final async = ref.watch(
                        activeAdvancesForTreasuryProvider(_toTreasuryId!),
                      );
                      return async.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('خطأ: $e'),
                        data: (list) {
                          if (list.isEmpty) {
                            return const Text(
                              'لا توجد سلف مفتوحة لهذه الخزينة — أنشئ سلفة جديدة.',
                              style: TextStyle(fontSize: 12),
                            );
                          }
                          return DropdownButtonFormField<int>(
                            key: ValueKey('adv_$_selectedAdvanceId'),
                            initialValue: _selectedAdvanceId,
                            decoration: const InputDecoration(
                              labelText: 'السلفة *',
                              prefixIcon: Icon(Icons.folder_shared_outlined),
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
                            onChanged: (v) =>
                                setState(() => _selectedAdvanceId = v),
                          );
                        },
                      );
                    },
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final treasuriesAsync = ref.watch(allTreasuriesProvider);

    // أخطاء إنشاء السلفة (رقم مكرر مثلاً) تظهر من هنا
    ref.listen<AsyncValue<String?>>(advanceNotifierProvider, (_, next) {
      if (next is AsyncError && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(advanceNotifierProvider.notifier).reset();
      }
    });
    final settingsAsync = ref.watch(primaryCurrencyProvider);

    // نستمع لحالة التحويل لعرض رسائل الخطأ ومعرفة متى يتم التحميل
    ref.listen<AsyncValue<String?>>(
      voucherTransferNotifierProvider,
      (prev, next) {
        if (next is AsyncError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(next.error.toString()),
              backgroundColor: Colors.red));
        }
      },
    );
    final isWorking =
        ref.watch(voucherTransferNotifierProvider) is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحويل بين الخزائن'),
        backgroundColor: Colors.indigo.shade50,
      ),
      body: treasuriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ في تحميل الخزائن: $e')),
        data: (treasuries) {
          if (treasuries.isEmpty) {
            return const Center(child: Text('لا توجد خزائن متاحة للتحويل'));
          }

          // إذا لم نقم باختيار العملة بعد، نأخذ العملة الأساسية من الإعدادات
          if (settingsAsync.valueOrNull != null) {
            // يمكننا تحديد العملة الافتراضية
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 0,
                    color: Colors.indigo.shade50.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.indigo.shade100),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.sync_alt,
                              size: 40, color: Colors.indigo.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'تحويل الأموال بين الخزائن المختلفة',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.indigo.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'سيتم تسجيل العملية كسند صرف من الخزينة المُرسِلة وسند قبض في الخزينة المُستقبِلة بآن واحد.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.indigo.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── اختيار الخزائن ────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'من الخزينة (المُرسِلة) *',
                            prefixIcon: Icon(Icons.outbox),
                          ),
                          initialValue: _fromTreasuryId,
                          items: treasuries.map((t) {
                            return DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _fromTreasuryId = val),
                          validator: (val) => val == null ? 'مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.grey),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'إلى الخزينة (المُستقبِلة) *',
                            prefixIcon: Icon(Icons.move_to_inbox),
                          ),
                          initialValue: _toTreasuryId,
                          items: treasuries.map((t) {
                            return DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _toTreasuryId = val),
                          validator: (val) {
                            if (val == null) return 'مطلوب';
                            if (val == _fromTreasuryId) {
                              return 'يجب أن تختلف عن المُرسِلة';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── المبلغ والعملة ────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _amountCtrl,
                          decoration: const InputDecoration(
                            labelText: 'المبلغ *',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d*')),
                          ],
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'مطلوب';
                            final v = double.tryParse(val);
                            if (v == null || v <= 0) return 'قيمة غير صالحة';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration:
                              const InputDecoration(labelText: 'العملة'),
                          initialValue: _currency,
                          items: const [
                            DropdownMenuItem(
                                value: 'IQD', child: Text('دينار (IQD)')),
                            DropdownMenuItem(
                                value: 'USD', child: Text('دولار (USD)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _currency = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_currency == 'USD') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _exchangeRateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'سعر الصرف',
                        prefixIcon: Icon(Icons.currency_exchange),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d*')),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  // ── التاريخ ───────────────────────────────
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _voucherDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _voucherDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تاريخ التحويل',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('yyyy/MM/dd').format(_voucherDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── الملاحظات ──────────────────────────────
                  TextFormField(
                    controller: _reasonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'التفاصيل / الملاحظات',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // ── ربط التحويل بسلفة مشروع ────────────────
                  _buildAdvanceSection(theme),
                  const SizedBox(height: 32),

                  // ── زر الحفظ ───────────────────────────────
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.indigo,
                      ),
                      onPressed: isWorking ? null : _onSave,
                      icon: isWorking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label:
                          Text(isWorking ? 'جارٍ التحويل...' : 'تنفيذ التحويل'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
