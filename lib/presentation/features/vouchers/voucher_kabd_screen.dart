// ─────────────────────────────────────────────────────────────────────────────
// voucher_kabd_screen.dart — شاشة سند القبض (إنشاء / تعديل)
//
// الميزات:
//   - إنشاء سند قبض جديد مع الكشف التلقائي للفترة المالية
//   - تعديل سند موجود (editId != null)
//   - حذف سند في وضع التعديل
//   - اختيار الخزينة من Dropdown
//   - إدخال المبلغ مع تبديل العملة (IQD / USD)
//   - عرض سعر الصرف عند اختيار USD
//   - اختيار نوع الإيراد بـ ChoiceChip (مخصص لسندات القبض)
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
import '../../../core/services/attachment_service.dart';
import '../../../data/database/daos/attachments_dao.dart';
import '../../widgets/common/item_type_selector.dart';
import '../../widgets/common/attachments_panel.dart';

// ملاحظة (ب-١ — 2026-08-23): حُذفت من هنا قائمتان ثابتتان بأنواع الإيرادات.
// كانتا تعرضان ٧ بنود مكتوبة في الكود بينما جدول `item_types` يديره المالك
// من الإعدادات — فما يضيفه لم يكن يظهر هنا. راجع ItemTypeSelector.


// ═══════════════════════════════════════════════════════════════════════════
// الشاشة الرئيسية
// ═══════════════════════════════════════════════════════════════════════════

/// شاشة سند القبض — إنشاء أو تعديل
class VoucherKabdScreen extends ConsumerStatefulWidget {
  /// null = وضع الإنشاء، int = وضع التعديل
  final int? editId;

  const VoucherKabdScreen({super.key, this.editId});

  bool get isEdit => editId != null;

  @override
  ConsumerState<VoucherKabdScreen> createState() =>
      _VoucherKabdScreenState();
}

class _VoucherKabdScreenState extends ConsumerState<VoucherKabdScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ──────────────────────────────────────────────────────────
  final _amountCtrl = TextEditingController();
  final _personNameCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _refNumCtrl = TextEditingController();

  // ── رقم الفاتورة (ب-١ — 2026-08-23) ─────────────────────────────────
  // مفهوم مستقلّ عن «الرقم المرجعي»: هذا رقم الفاتورة الصادرة من الشركة
  // للعميل، وذاك رقم الشيك أو الحوالة الواردة. قد يوجد الاثنان في السند
  // نفسه، فدمجهما في حقل واحد كان يُضيّع أحدهما.
  final _invoiceCtrl = TextEditingController();

  // ── حالة النموذج ─────────────────────────────────────────────────────────
  int? _selectedTreasuryId;
  String _currency = 'IQD';
  DateTime _voucherDate = DateTime.now();
  String _itemType = '';

  // ── وضع التعديل ──────────────────────────────────────────────────────────
  VoucherModel? _editVoucher;
  bool _initialized = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _personNameCtrl.dispose();
    _reasonCtrl.dispose();
    _refNumCtrl.dispose();
    _invoiceCtrl.dispose();
    super.dispose();
  }

  // ── تعبئة النموذج في وضع التعديل ─────────────────────────────────────────

  void _prefillForm(VoucherModel v) {
    // ── حارس: هذه الشاشة لا تُعدّل سندات التحويل ──────────────────────
    //
    // التحويل سندان توأمان؛ تعديل أحدهما هنا كان يخلّ بتوازن الخزينتين
    // (ح-١ — تدقيق 2026-08-15). المستودع يرفض ذلك أصلاً، وهذا الحارس
    // يمنع وصول المستخدم لنموذج تعديل لن يُقبَل حفظه أساساً.
    if (v.isTransfer) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'سندات التحويل لا تُعدَّل — احذف التحويل وأنشئه من جديد.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
        context.pop();
      });
      return;
    }

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
      _invoiceCtrl.text = v.invoiceNumber ?? '';
      _selectedTreasuryId = v.treasuryId;
      _currency = v.currency;
      _voucherDate = v.voucherDate;
      _itemType = v.itemType;
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
    final rate = ref.read(exchangeRateProvider).valueOrNull ?? 1310.0;

    final notifier = ref.read(voucherKabdNotifierProvider.notifier);
    bool success;

    if (widget.isEdit && _editVoucher != null) {
      success = await notifier.updateKabd(
        _editVoucher!,
        treasuryId: _selectedTreasuryId!,
        amount: amount,
        currency: _currency,
        voucherDate: _voucherDate,
        personName: _personNameCtrl.text.trim(),
        reason: _reasonCtrl.text.trim(),
        itemType: _itemType,
        referenceNumber: _refNumCtrl.text.trim(),
        invoiceNumber: _invoiceCtrl.text,
        exchangeRate: rate,
      );
    } else {
      success = await notifier.createKabd(
        treasuryId: _selectedTreasuryId!,
        amount: amount,
        currency: _currency,
        voucherDate: _voucherDate,
        personName: _personNameCtrl.text.trim(),
        reason: _reasonCtrl.text.trim(),
        itemType: _itemType,
        referenceNumber: _refNumCtrl.text.trim(),
        invoiceNumber: _invoiceCtrl.text,
        exchangeRate: rate,
      );
    }

    if (success && mounted) context.pop();
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
          .read(voucherKabdNotifierProvider.notifier)
          .deleteKabd(id);
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
    ref.listen<AsyncValue<String?>>(
      voucherKabdNotifierProvider,
      (_, next) {
        next.whenOrNull(
          data: (msg) {
            if (msg != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: Colors.green.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              ref.read(voucherKabdNotifierProvider.notifier).reset();
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
            ref.read(voucherKabdNotifierProvider.notifier).reset();
          },
        );
      },
    );

    final isOperating = ref.watch(voucherKabdNotifierProvider).isLoading;
    final treasuriesAsync = ref.watch(allTreasuriesProvider);
    final rateAsync = ref.watch(exchangeRateProvider);
    final periodAsync =
        ref.watch(fiscalPeriodForDateProvider(_voucherDate));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'تعديل سند القبض' : 'سند قبض جديد',
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
              _KabdFiscalBanner(periodAsync: periodAsync),
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
                      const _KabdSectionLabel(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'الخزينة',
                      ),
                      const SizedBox(height: 8),
                      _KabdTreasuryDropdown(
                        treasuriesAsync: treasuriesAsync,
                        selectedId: _selectedTreasuryId,
                        onChanged: (id) =>
                            setState(() => _selectedTreasuryId = id),
                        enabled: !isOperating,
                      ),
                      const SizedBox(height: 20),

                      // ── المبلغ والعملة ──────────────────────────────────
                      const _KabdSectionLabel(
                        icon: Icons.attach_money,
                        label: 'المبلغ والعملة',
                      ),
                      const SizedBox(height: 8),
                      _KabdAmountCurrencyRow(
                        amountCtrl: _amountCtrl,
                        currency: _currency,
                        onCurrencyChanged: (c) =>
                            setState(() => _currency = c),
                        enabled: !isOperating,
                      ),
                      if (_currency == 'USD')
                        _KabdExchangeRateHint(rateAsync: rateAsync),
                      const SizedBox(height: 20),

                      // ── التاريخ ─────────────────────────────────────────
                      const _KabdSectionLabel(
                        icon: Icons.calendar_today_outlined,
                        label: 'تاريخ السند',
                      ),
                      const SizedBox(height: 8),
                      _KabdDateField(
                        date: _voucherDate,
                        onTap: isOperating ? null : _pickDate,
                      ),
                      const SizedBox(height: 20),

                      // ── الدافع والسبب ────────────────────────────────────
                      const _KabdSectionLabel(
                        icon: Icons.person_outline,
                        label: 'الدافع والسبب',
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _personNameCtrl,
                        enabled: !isOperating,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'اسم الدافع / المُودِع',
                          hintText: 'مثال: شركة الوفاء...',
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
                          hintText: 'مثال: دفعة أولى لمشروع...',
                          prefixIcon:
                              Icon(Icons.notes_outlined, size: 20),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── نوع الإيراد ─────────────────────────────────────
                      const _KabdSectionLabel(
                        icon: Icons.label_outline,
                        label: 'نوع الإيراد',
                      ),
                      const SizedBox(height: 8),
                      ItemTypeSelector(
                        kind: 'kabd',
                        selected: _itemType,
                        onSelected: (t) =>
                            setState(() => _itemType = t),
                        enabled: !isOperating,
                      ),
                      const SizedBox(height: 20),

                      // ── الرقم المرجعي ────────────────────────────────────
                      const _KabdSectionLabel(
                        icon: Icons.tag,
                        label: 'الأرقام المرجعية',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _refNumCtrl,
                              enabled: !isOperating,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                // التسمية كانت «رقم الشيك / أمر القبض /
                                // الفاتورة» — ثلاثة مفاهيم في حقل واحد،
                                // فكان إدخال اثنين منها يُضيّع أحدهما.
                                // فُصلت الفاتورة إلى عمودها الخاص (ب-١).
                                labelText: 'رقم الشيك / أمر القبض',
                                hintText: 'اختياري...',
                                prefixIcon: Icon(Icons.tag, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _invoiceCtrl,
                              enabled: !isOperating,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'رقم الفاتورة',
                                hintText: 'فاتورة الشركة الصادرة',
                                prefixIcon: Icon(
                                  Icons.receipt_long_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── مرفقات السند (المرحلة ج) ──────────────────────────────
              //
              // تظهر في **وضع التعديل فقط**: المرفق يحتاج معرّف سند يرتبط به،
              // والسند الجديد لا معرّف له قبل الحفظ. لو عُرضت عند الإنشاء
              // لأُرفق الملف بمعرّف لا وجود له بعد.
              if (widget.isEdit && _editVoucher != null)
                AttachmentsPanel(
                  entityType: AttachmentEntity.voucher,
                  entityId: _editVoucher!.id,
                  year: _editVoucher!.voucherDate.year,
                  folderName: AttachmentService.voucherFolder(
                    voucherNumber: _editVoucher!.voucherNumber,
                    voucherType: _editVoucher!.voucherType,
                  ),
                  title: 'مرفقات السند',
                ),

              const SizedBox(height: 24),

              // ── أزرار الإجراءات ───────────────────────────────────────────
              _KabdActionButtons(
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
// مكوّنات مساعدة — مخصصة لسند القبض (لون أخضر)
// ═══════════════════════════════════════════════════════════════════════════

// ── شريط الفترة المالية ─────────────────────────────────────────────────────

class _KabdFiscalBanner extends StatelessWidget {
  final AsyncValue<FiscalPeriod?> periodAsync;

  const _KabdFiscalBanner({required this.periodAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return periodAsync.when(
      data: (period) {
        if (period == null) {
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.event_available,
                  color: Colors.green.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الفترة المالية: ${period.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

class _KabdSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _KabdSectionLabel({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.green.shade700),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

// ── Dropdown الخزائن ─────────────────────────────────────────────────────────

class _KabdTreasuryDropdown extends StatelessWidget {
  final AsyncValue<List<TreasuryModel>> treasuriesAsync;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final bool enabled;

  const _KabdTreasuryDropdown({
    required this.treasuriesAsync,
    required this.selectedId,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return treasuriesAsync.when(
      data: (treasuries) {
        final active = treasuries.where((t) => t.isActive).toList();
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
                      _KabdKindDot(kind: t.kind),
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

class _KabdKindDot extends StatelessWidget {
  final String kind;

  const _KabdKindDot({required this.kind});

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

class _KabdAmountCurrencyRow extends StatelessWidget {
  final TextEditingController amountCtrl;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;
  final bool enabled;

  const _KabdAmountCurrencyRow({
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
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: amountCtrl,
            enabled: enabled,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d*\.?\d{0,3}'),
              ),
            ],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'المبلغ المستلَم',
              hintText: '0',
              prefixIcon: Icon(Icons.attach_money, size: 20),
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

class _KabdExchangeRateHint extends StatelessWidget {
  final AsyncValue<double> rateAsync;

  const _KabdExchangeRateHint({required this.rateAsync});

  @override
  Widget build(BuildContext context) {
    final rate = rateAsync.valueOrNull ?? 1310.0;
    final fmt = NumberFormat('#,##0', 'ar');
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 14, color: Colors.green.shade700),
          const SizedBox(width: 6),
          Text(
            '1 \$ = ${fmt.format(rate)} د.ع (السعر الحالي)',
            style: TextStyle(
                fontSize: 12, color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }
}

// ── حقل التاريخ ─────────────────────────────────────────────────────────────

class _KabdDateField extends StatelessWidget {
  final DateTime date;
  final VoidCallback? onTap;

  const _KabdDateField({required this.date, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE، dd MMMM yyyy', 'ar');
    // InputDecorator بدل TextFormField+Controller — حقل عرض فقط بلا تسريب.
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'التاريخ',
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          suffixIcon: Icon(
            Icons.arrow_drop_down,
            color: Colors.green.shade700,
          ),
        ),
        child: Text(fmt.format(date)),
      ),
    );
  }
}

class _KabdActionButtons extends StatelessWidget {
  final bool isEdit;
  final bool isOperating;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _KabdActionButtons({
    required this.isEdit,
    required this.isOperating,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
                    isEdit
                        ? Icons.save_outlined
                        : Icons.add_circle_outline,
                    size: 18,
                  ),
            label: Text(isEdit ? 'حفظ التعديلات' : 'إنشاء السند'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.green.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
