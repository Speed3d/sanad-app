// ─────────────────────────────────────────────────────────────────────────────
// voucher_sarf_screen.dart — شاشة سند الصرف (إنشاء / تعديل)
//
// الميزات:
//   - إنشاء سند صرف جديد مع الكشف التلقائي للفترة المالية
//   - تعديل سند موجود (editId != null)
//   - حذف سند في وضع التعديل
//   - اختيار الخزينة من Dropdown
//   - إدخال المبلغ مع تبديل العملة (IQD / USD)
//   - عرض سعر الصرف عند اختيار USD
//   - اختيار نوع البند بـ ChoiceChip
//   - التحقق من الفترة المالية النشطة للتاريخ المختار
//   - Validation كامل قبل الحفظ
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/database/app_database.dart';
import '../../../domain/models/treasury_model.dart';
import '../../../domain/models/voucher_model.dart';
import '../../providers/settings_provider.dart';
import '../../providers/treasury_providers.dart';
import '../../providers/voucher_providers.dart';

// ── ثوابت أنواع البنود ──────────────────────────────────────────────────────

const _kItemTypes = [
  '',
  'راتب',
  'سلفة',
  'إيجار',
  'مشتريات',
  'مصاريف تشغيل',
  'رسوم وضرائب',
  'أخرى',
];

const _kItemTypeLabels = {
  '': 'غير محدد',
  'راتب': 'راتب',
  'سلفة': 'سلفة',
  'إيجار': 'إيجار',
  'مشتريات': 'مشتريات',
  'مصاريف تشغيل': 'تشغيل',
  'رسوم وضرائب': 'رسوم',
  'أخرى': 'أخرى',
};

// ═══════════════════════════════════════════════════════════════════════════
// الشاشة الرئيسية
// ═══════════════════════════════════════════════════════════════════════════

/// شاشة سند الصرف — إنشاء أو تعديل
class VoucherSarfScreen extends ConsumerStatefulWidget {
  /// null = وضع الإنشاء، int = وضع التعديل
  final int? editId;

  const VoucherSarfScreen({super.key, this.editId});

  bool get isEdit => editId != null;

  @override
  ConsumerState<VoucherSarfScreen> createState() => _VoucherSarfScreenState();
}

class _VoucherSarfScreenState extends ConsumerState<VoucherSarfScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ──────────────────────────────────────────────────────────
  final _amountCtrl = TextEditingController();
  final _personNameCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _refNumCtrl = TextEditingController();

  // ── حالة النموذج ─────────────────────────────────────────────────────────
  int? _selectedTreasuryId;
  String _currency = 'IQD';
  DateTime _voucherDate = DateTime.now();
  String _itemType = '';
  bool _closeSafe = false;

  // ── وضع التعديل ──────────────────────────────────────────────────────────
  VoucherModel? _editVoucher;
  bool _initialized = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _personNameCtrl.dispose();
    _reasonCtrl.dispose();
    _refNumCtrl.dispose();
    super.dispose();
  }

  // ── تعبئة النموذج في وضع التعديل ─────────────────────────────────────────

  void _prefillForm(VoucherModel v) {
    if (_initialized) return;
    _initialized = true;
    final amtStr = v.amount == v.amount.truncateToDouble()
        ? v.amount.toInt().toString()
        : v.amount.toStringAsFixed(3);
    setState(() {
      _editVoucher = v;
      _amountCtrl.text = amtStr;
      _personNameCtrl.text = v.personName;
      _reasonCtrl.text = v.reason;
      _refNumCtrl.text = v.referenceNumber;
      _selectedTreasuryId = v.treasuryId;
      _currency = v.currency;
      _voucherDate = v.voucherDate;
      _itemType = v.itemType;
      _closeSafe = v.closeSafe;
    });
  }

  // ── اختيار التاريخ ────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _voucherDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
      helpText: 'اختر تاريخ السند',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked != null && mounted) {
      setState(() {
        _voucherDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _voucherDate.hour,
          _voucherDate.minute,
        );
      });
    }
  }

  // ── حفظ السند ─────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTreasuryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الخزينة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final rawAmount = _amountCtrl.text.replaceAll(',', '').trim();
    final amount = double.tryParse(rawAmount) ?? 0;

    final rate =
        ref.read(exchangeRateProvider).valueOrNull ?? 1310.0;

    final notifier = ref.read(voucherSarfNotifierProvider.notifier);
    bool success;

    if (widget.isEdit && _editVoucher != null) {
      success = await notifier.updateSarf(
        _editVoucher!,
        treasuryId: _selectedTreasuryId!,
        amount: amount,
        currency: _currency,
        voucherDate: _voucherDate,
        personName: _personNameCtrl.text.trim(),
        reason: _reasonCtrl.text.trim(),
        itemType: _itemType,
        referenceNumber: _refNumCtrl.text.trim(),
        closeSafe: _closeSafe,
        exchangeRate: rate,
      );
    } else {
      success = await notifier.createSarf(
        treasuryId: _selectedTreasuryId!,
        amount: amount,
        currency: _currency,
        voucherDate: _voucherDate,
        personName: _personNameCtrl.text.trim(),
        reason: _reasonCtrl.text.trim(),
        itemType: _itemType,
        referenceNumber: _refNumCtrl.text.trim(),
        closeSafe: _closeSafe,
        exchangeRate: rate,
      );
    }

    if (success && mounted) {
      context.pop();
    }
  }

  // ── تأكيد الحذف ───────────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    final id = widget.editId;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف السند'),
        content: const Text(
          'هل أنت متأكد من حذف هذا السند؟\nلا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok = await ref
          .read(voucherSarfNotifierProvider.notifier)
          .deleteSarf(id);
      if (ok && mounted) context.pop();
    }
  }

  // ── البناء ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── تحميل السند في وضع التعديل ─────────────────────────────────────────
    if (widget.isEdit) {
      ref.watch(voucherByIdProvider(widget.editId!)).whenData((v) {
        if (v != null && !_initialized) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _prefillForm(v));
        }
      });
    }

    // ── الاستماع لنتيجة العملية ─────────────────────────────────────────────
    ref.listen<AsyncValue<String?>>(voucherSarfNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (msg) {
          if (msg != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            ref.read(voucherSarfNotifierProvider.notifier).reset();
          }
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.read(voucherSarfNotifierProvider.notifier).reset();
        },
      );
    });

    final isOperating =
        ref.watch(voucherSarfNotifierProvider).isLoading;

    // الخزائن والإعدادات
    final treasuriesAsync = ref.watch(allTreasuriesProvider);
    final rateAsync = ref.watch(exchangeRateProvider);

    // الفترة المالية للتاريخ المحدد
    final periodAsync =
        ref.watch(fiscalPeriodForDateProvider(_voucherDate));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'تعديل سند الصرف' : 'سند صرف جديد',
        ),
        centerTitle: false,
        actions: [
          if (widget.isEdit)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
              tooltip: 'حذف السند',
              onPressed: isOperating ? null : _confirmDelete,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── شريط الفترة المالية ───────────────────────────────────────
              _FiscalPeriodBanner(periodAsync: periodAsync),
              const SizedBox(height: 16),

              // ── بطاقة النموذج الرئيسية ────────────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── الخزينة ─────────────────────────────────────────
                      _SectionLabel(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'الخزينة',
                      ),
                      const SizedBox(height: 8),
                      _TreasuryDropdown(
                        treasuriesAsync: treasuriesAsync,
                        selectedId: _selectedTreasuryId,
                        onChanged: (id) =>
                            setState(() => _selectedTreasuryId = id),
                        enabled: !isOperating,
                      ),
                      const SizedBox(height: 20),

                      // ── المبلغ والعملة ──────────────────────────────────
                      _SectionLabel(
                        icon: Icons.attach_money,
                        label: 'المبلغ والعملة',
                      ),
                      const SizedBox(height: 8),
                      _AmountCurrencyRow(
                        amountCtrl: _amountCtrl,
                        currency: _currency,
                        onCurrencyChanged: (c) =>
                            setState(() => _currency = c),
                        enabled: !isOperating,
                      ),
                      // سعر الصرف عند اختيار USD
                      if (_currency == 'USD')
                        _ExchangeRateHint(rateAsync: rateAsync),
                      const SizedBox(height: 20),

                      // ── التاريخ ─────────────────────────────────────────
                      _SectionLabel(
                        icon: Icons.calendar_today_outlined,
                        label: 'تاريخ السند',
                      ),
                      const SizedBox(height: 8),
                      _DatePickerField(
                        date: _voucherDate,
                        onTap: isOperating ? null : _pickDate,
                      ),
                      const SizedBox(height: 20),

                      // ── المستلم والسبب ──────────────────────────────────
                      _SectionLabel(
                        icon: Icons.person_outline,
                        label: 'المستلم والسبب',
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _personNameCtrl,
                        enabled: !isOperating,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'اسم المستلم',
                          hintText: 'مثال: أحمد محمد...',
                          prefixIcon:
                              Icon(Icons.person_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reasonCtrl,
                        enabled: !isOperating,
                        maxLines: 2,
                        minLines: 1,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'السبب / الوصف',
                          hintText: 'وصف مختصر للعملية...',
                          prefixIcon:
                              Icon(Icons.notes_outlined, size: 20),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── نوع البند ───────────────────────────────────────
                      _SectionLabel(
                        icon: Icons.label_outline,
                        label: 'نوع البند',
                      ),
                      const SizedBox(height: 8),
                      _ItemTypeChips(
                        selected: _itemType,
                        onSelected: (t) =>
                            setState(() => _itemType = t),
                        enabled: !isOperating,
                      ),
                      const SizedBox(height: 20),

                      // ── الرقم المرجعي وإقفال الصندوق ────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // الرقم المرجعي
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _SectionLabel(
                                  icon: Icons.tag,
                                  label: 'الرقم المرجعي',
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _refNumCtrl,
                                  enabled: !isOperating,
                                  textInputAction: TextInputAction.done,
                                  keyboardType:
                                      TextInputType.text,
                                  decoration: const InputDecoration(
                                    labelText: 'رقم الشيك / أمر الدفع',
                                    hintText: 'اختياري...',
                                    prefixIcon: Icon(
                                      Icons.tag,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // إقفال الصندوق
                          Column(
                            children: [
                              _SectionLabel(
                                icon: Icons.lock_outline,
                                label: 'إقفال الصندوق',
                              ),
                              const SizedBox(height: 4),
                              Switch(
                                value: _closeSafe,
                                onChanged: isOperating
                                    ? null
                                    : (v) =>
                                        setState(() => _closeSafe = v),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── أزرار الإجراءات ───────────────────────────────────────────
              _ActionButtons(
                isEdit: widget.isEdit,
                isOperating: isOperating,
                onSave: _submit,
                onCancel: () => context.pop(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// مكوّنات مساعدة
// ═══════════════════════════════════════════════════════════════════════════

// ── شريط الفترة المالية ─────────────────────────────────────────────────────

class _FiscalPeriodBanner extends StatelessWidget {
  final AsyncValue<FiscalPeriod?> periodAsync;

  const _FiscalPeriodBanner({required this.periodAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return periodAsync.when(
      data: (period) {
        if (period == null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'لا توجد فترة مالية نشطة لهذا التاريخ\nيرجى مراجعة إعدادات الفترات المالية',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final fmt = DateFormat('dd/MM/yyyy', 'ar');
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.event_available,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الفترة المالية: ${period.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${fmt.format(period.startDate)} — ${fmt.format(period.endDate)}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'نشطة',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'جاري التحقق من الفترة المالية...',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── تسمية القسم ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Dropdown الخزائن ─────────────────────────────────────────────────────────

class _TreasuryDropdown extends StatelessWidget {
  final AsyncValue<List<TreasuryModel>> treasuriesAsync;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final bool enabled;

  const _TreasuryDropdown({
    required this.treasuriesAsync,
    required this.selectedId,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return treasuriesAsync.when(
      data: (treasuries) {
        final active =
            treasuries.where((t) => t.isActive).toList();
        if (active.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Text(
              'لا توجد خزائن نشطة — أضف خزينة أولاً',
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        final effectiveId = selectedId != null &&
                active.any((t) => t.id == selectedId)
            ? selectedId
            : null;
        return DropdownButtonFormField<int>(
          key: ValueKey(effectiveId),
          initialValue: effectiveId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'اختر الخزينة',
            prefixIcon: Icon(
              Icons.account_balance_wallet_outlined,
              size: 20,
            ),
          ),
          hint: const Text('اختر الخزينة'),
          items: active
              .map(
                (t) => DropdownMenuItem<int>(
                  value: t.id,
                  child: Row(
                    children: [
                      _KindDot(kind: t.kind),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.name)),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
          validator: (v) =>
              v == null ? 'يرجى اختيار الخزينة' : null,
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(
        'خطأ في تحميل الخزائن: $e',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}

// ── نقطة نوع الخزينة ─────────────────────────────────────────────────────────

class _KindDot extends StatelessWidget {
  final String kind;

  const _KindDot({required this.kind});

  @override
  Widget build(BuildContext context) {
    final color = switch (kind) {
      'main' => Colors.blue.shade400,
      'contractor' => Colors.orange.shade400,
      'partner' => Colors.purple.shade400,
      _ => Colors.grey.shade400,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── حقل المبلغ والعملة ──────────────────────────────────────────────────────

class _AmountCurrencyRow extends StatelessWidget {
  final TextEditingController amountCtrl;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;
  final bool enabled;

  const _AmountCurrencyRow({
    required this.amountCtrl,
    required this.currency,
    required this.onCurrencyChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // حقل المبلغ
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: amountCtrl,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d*\.?\d{0,3}'),
              ),
            ],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'المبلغ',
              hintText: '0',
              prefixIcon:
                  Icon(Icons.attach_money, size: 20),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'المبلغ مطلوب';
              final val = double.tryParse(v.replaceAll(',', ''));
              if (val == null) return 'رقم غير صالح';
              if (val <= 0) return 'يجب أن يكون > 0';
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        // تبديل العملة
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'IQD', label: Text('د.ع')),
                  ButtonSegment(value: 'USD', label: Text('\$')),
                ],
                selected: {currency},
                onSelectionChanged: enabled
                    ? (s) => onCurrencyChanged(s.first)
                    : null,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── تلميح سعر الصرف ──────────────────────────────────────────────────────────

class _ExchangeRateHint extends StatelessWidget {
  final AsyncValue<double> rateAsync;

  const _ExchangeRateHint({required this.rateAsync});

  @override
  Widget build(BuildContext context) {
    final rate = rateAsync.valueOrNull ?? 1310.0;
    final fmt = NumberFormat('#,##0', 'ar');
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '1 \$ = ${fmt.format(rate)} د.ع (السعر الحالي)',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── حقل التاريخ ─────────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final DateTime date;
  final VoidCallback? onTap;

  const _DatePickerField({required this.date, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE، dd MMMM yyyy', 'ar');
    // نستخدم InputDecorator بدل TextFormField+TextEditingController لأن الحقل
    // للعرض فقط — يمنع تسريب Controller يُنشأ في كل إعادة بناء. تدقيق 2026-08-06.
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'التاريخ',
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          suffixIcon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        child: Text(fmt.format(date)),
      ),
    );
  }
}

// ── شرائح نوع البند ─────────────────────────────────────────────────────────

class _ItemTypeChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  final bool enabled;

  const _ItemTypeChips({
    required this.selected,
    required this.onSelected,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _kItemTypes.map((type) {
          final label = _kItemTypeLabels[type] ?? type;
          final isSelected = selected == type;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: enabled
                  ? (_) => onSelected(type)
                  : null,
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── أزرار الإجراءات ──────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final bool isEdit;
  final bool isOperating;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _ActionButtons({
    required this.isEdit,
    required this.isOperating,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // زر الإلغاء
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isOperating ? null : onCancel,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('إلغاء'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // زر الحفظ
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: isOperating ? null : onSave,
            icon: isOperating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isEdit ? Icons.save_outlined : Icons.add_circle_outline,
                    size: 18,
                  ),
            label: Text(isEdit ? 'حفظ التعديلات' : 'إنشاء السند'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: isEdit
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}
