import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/settings_provider.dart';
import '../../providers/treasury_providers.dart';
import '../../providers/voucher_providers.dart';

class VoucherTransferScreen extends ConsumerStatefulWidget {
  const VoucherTransferScreen({super.key});

  @override
  ConsumerState<VoucherTransferScreen> createState() => _VoucherTransferScreenState();
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

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _exchangeRateCtrl.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromTreasuryId == null || _toTreasuryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تحديد الخزينة المُرسِلة والمُستقبِلة'), backgroundColor: Colors.red));
      return;
    }
    if (_fromTreasuryId == _toTreasuryId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن التحويل لنفس الخزينة'), backgroundColor: Colors.red));
      return;
    }

    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المبلغ يجب أن يكون أكبر من صفر'), backgroundColor: Colors.red));
      return;
    }

    final exRate = double.tryParse(_exchangeRateCtrl.text) ?? 1.0;

    final success = await ref.read(voucherTransferNotifierProvider.notifier).createTransfer(
          fromTreasuryId: _fromTreasuryId!,
          toTreasuryId: _toTreasuryId!,
          amount: amount,
          currency: _currency,
          voucherDate: _voucherDate,
          reason: _reasonCtrl.text.trim(),
          exchangeRate: exRate,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحويل بين الخزائن بنجاح'), backgroundColor: Colors.green));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final treasuriesAsync = ref.watch(allTreasuriesProvider);
    final settingsAsync = ref.watch(primaryCurrencyProvider);
    
    // نستمع لحالة التحويل لعرض رسائل الخطأ ومعرفة متى يتم التحميل
    ref.listen<AsyncValue<String?>>(
      voucherTransferNotifierProvider,
      (prev, next) {
        if (next is AsyncError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error.toString()), backgroundColor: Colors.red));
        }
      },
    );
    final isWorking = ref.watch(voucherTransferNotifierProvider) is AsyncLoading;

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
                          Icon(Icons.sync_alt, size: 40, color: Colors.indigo.shade400),
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
                          onChanged: (val) => setState(() => _fromTreasuryId = val),
                          validator: (val) => val == null ? 'مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.grey),
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
                          onChanged: (val) => setState(() => _toTreasuryId = val),
                          validator: (val) {
                            if (val == null) return 'مطلوب';
                            if (val == _fromTreasuryId) return 'يجب أن تختلف عن المُرسِلة';
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
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
                          decoration: const InputDecoration(labelText: 'العملة'),
                          initialValue: _currency,
                          items: const [
                            DropdownMenuItem(value: 'IQD', child: Text('دينار (IQD)')),
                            DropdownMenuItem(value: 'USD', child: Text('دولار (USD)')),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
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
                      labelText: 'التفاصيل / الملاحظات (رقم السلفة، المشروع، إلخ)',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 2,
                  ),
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(isWorking ? 'جارٍ التحويل...' : 'تنفيذ التحويل'),
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
