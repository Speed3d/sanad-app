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

import 'voucher_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/voucher_model.dart';
import '../../providers/settings_provider.dart';
import '../../providers/treasury_providers.dart';
import '../../providers/voucher_providers.dart';
import '../../../core/services/attachment_service.dart';
import '../../../data/database/daos/attachments_dao.dart';
import '../../widgets/common/item_type_selector.dart';
import '../../widgets/common/attachments_panel.dart';
import '../../widgets/common/password_confirm_dialog.dart';

// ملاحظة (ب-١ — 2026-08-23): حُذفت من هنا قائمتان ثابتتان بأنواع البنود
// (_kItemTypes و _kItemTypeLabels). كانتا تعرضان ٨ بنود مكتوبة في الكود
// بينما جدول `item_types` في قاعدة البيانات فيه ٢١ بنداً يديرها المالك من
// الإعدادات — فكان ما يضيفه لا يظهر هنا إطلاقاً. حلّ محلّهما
// ItemTypeSelector الذي يقرأ من الجدول مباشرةً.

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

  // ── حقول تتبّع المصروفات (ب-١ — 2026-08-23) ─────────────────────────
  // الأعمدة قائمة في قاعدة البيانات منذ Schema v2 ولم تكن الشاشة تعرضها،
  // فكان تتبّع «أين صُرف المال ومن صرفه» مستحيلاً من الواجهة.
  //
  // متحكّمات هنا لا متغيّرات نصّية: هذه شاشة StatefulWidget كاملة تملكها
  // وتتخلّص منها في dispose() — وهو النمط الآمن. المحظور هو إنشاء متحكّم
  // داخل دالة ثم التخلّص منه بعد await showDialog. راجع
  // test/unit/dialog_controller_lifecycle_test.dart
  final _projectCtrl = TextEditingController();
  final _invoiceCtrl = TextEditingController();
  final _spentByCtrl = TextEditingController();
  final _advanceNumCtrl = TextEditingController();

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
    _projectCtrl.dispose();
    _invoiceCtrl.dispose();
    _spentByCtrl.dispose();
    _advanceNumCtrl.dispose();
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
      // الأعمدة nullable — الغياب يُعرَض حقلاً فارغاً
      _projectCtrl.text = v.projectName ?? '';
      _invoiceCtrl.text = v.invoiceNumber ?? '';
      _spentByCtrl.text = v.spentBy ?? '';
      _advanceNumCtrl.text = v.advanceNumber ?? '';
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

    final rate = ref.read(exchangeRateProvider).valueOrNull ?? 1310.0;

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
        projectName: _projectCtrl.text,
        invoiceNumber: _invoiceCtrl.text,
        spentBy: _spentByCtrl.text,
        advanceNumber: _advanceNumCtrl.text,
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
        projectName: _projectCtrl.text,
        invoiceNumber: _invoiceCtrl.text,
        spentBy: _spentByCtrl.text,
        advanceNumber: _advanceNumCtrl.text,
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

    // 🔐 تأكيد الهويّة قبل الحذف (بلاغ المالك 2026-08-30)
    //
    //   حذف السند **يُرجع مالاً خرج من الخزينة** — وهو بالضبط معيار القاعدة
    //   المعتمدة منذ المرحلة ١٠: «كل ما يُرجع مالاً خرج يُثبِت صاحبه هويّته».
    //   وكانت ستّة مواضع أقلّ خطراً محروسة بها بينما حذفُ السند — أشيعها —
    //   بلا حارس. والجلسة المفتوحة تُثبت أن أحداً دخل، لا أن **صاحبها**
    //   يضغط الآن.
    final identityOk = await confirmWithPassword(
      context,
      ref,
      action: 'حذف سند الصرف',
      impact: 'سيرجع المبلغ إلى الخزينة وتتغيّر أرصدة التقارير.',
    );
    if (!identityOk || !mounted) return;

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
      final ok =
          await ref.read(voucherSarfNotifierProvider.notifier).deleteSarf(id);
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
          WidgetsBinding.instance.addPostFrameCallback((_) => _prefillForm(v));
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

    final isOperating = ref.watch(voucherSarfNotifierProvider).isLoading;

    // الخزائن والإعدادات
    final treasuriesAsync = ref.watch(allTreasuriesProvider);
    final rateAsync = ref.watch(exchangeRateProvider);

    // الفترة المالية للتاريخ المحدد
    final periodAsync = ref.watch(fiscalPeriodForDateProvider(_voucherDate));

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
              VoucherFiscalPeriodBanner(
                  accent: theme.colorScheme.error, periodAsync: periodAsync),
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
                      VoucherSectionLabel(
                        accent: theme.colorScheme.error,
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'الخزينة',
                      ),
                      const SizedBox(height: 8),
                      VoucherTreasuryDropdown(
                        accent: theme.colorScheme.error,
                        treasuriesAsync: treasuriesAsync,
                        selectedId: _selectedTreasuryId,
                        onChanged: (id) =>
                            setState(() => _selectedTreasuryId = id),
                        enabled: !isOperating,
                      ),
                      const SizedBox(height: 20),

                      // ── المبلغ والعملة ──────────────────────────────────
                      VoucherSectionLabel(
                        accent: theme.colorScheme.error,
                        icon: Icons.attach_money,
                        label: 'المبلغ والعملة',
                      ),
                      const SizedBox(height: 8),
                      VoucherAmountCurrencyRow(
                        accent: theme.colorScheme.error,
                        amountCtrl: _amountCtrl,
                        currency: _currency,
                        onCurrencyChanged: (c) => setState(() => _currency = c),
                        enabled: !isOperating,
                      ),
                      // سعر الصرف عند اختيار USD
                      if (_currency == 'USD')
                        VoucherExchangeRateHint(
                            accent: theme.colorScheme.error,
                            rateAsync: rateAsync),
                      const SizedBox(height: 20),

                      // ── التاريخ ─────────────────────────────────────────
                      VoucherSectionLabel(
                        accent: theme.colorScheme.error,
                        icon: Icons.calendar_today_outlined,
                        label: 'تاريخ السند',
                      ),
                      const SizedBox(height: 8),
                      VoucherDatePickerField(
                        accent: theme.colorScheme.error,
                        date: _voucherDate,
                        onTap: isOperating ? null : _pickDate,
                      ),
                      const SizedBox(height: 20),

                      // ── المستلم والسبب ──────────────────────────────────
                      VoucherSectionLabel(
                        accent: theme.colorScheme.error,
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
                          prefixIcon: Icon(Icons.person_outline, size: 20),
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
                          prefixIcon: Icon(Icons.notes_outlined, size: 20),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── نوع البند ───────────────────────────────────────
                      VoucherSectionLabel(
                        accent: theme.colorScheme.error,
                        icon: Icons.label_outline,
                        label: 'نوع البند',
                      ),
                      const SizedBox(height: 8),
                      ItemTypeSelector(
                        kind: 'sarf',
                        selected: _itemType,
                        onSelected: (t) => setState(() => _itemType = t),
                        enabled: !isOperating,
                      ),
                      const SizedBox(height: 20),

                      // ── تتبّع المصروف (ب-١) ─────────────────────────────
                      //
                      // هذه الحقول تجيب عن السؤال الذي كانت التقارير عاجزة
                      // عنه: **أين** صُرف المال و**من** صرفه و**بأي فاتورة**.
                      // الأعمدة قائمة في قاعدة البيانات منذ Schema v2 ولم
                      // تكن الشاشة تعرضها، فكان الجواب مستحيلاً.
                      // كلها اختيارية — لا تُثقل الإدخال اليومي السريع.
                      VoucherSectionLabel(
                        accent: theme.colorScheme.error,
                        icon: Icons.assignment_outlined,
                        label: 'تتبّع المصروف (اختياري)',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _projectCtrl,
                              enabled: !isOperating,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'المشروع / الموقع',
                                hintText: 'مثال: مشروع البصرة',
                                prefixIcon: Icon(
                                  Icons.location_city_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _spentByCtrl,
                              enabled: !isOperating,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'صُرف بواسطة',
                                hintText: 'من صرف في الموقع',
                                prefixIcon: Icon(
                                  Icons.engineering_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _invoiceCtrl,
                              enabled: !isOperating,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'رقم الفاتورة / الوصل',
                                hintText: 'مثال: INV-118',
                                prefixIcon: Icon(
                                  Icons.receipt_long_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _advanceNumCtrl,
                              enabled: !isOperating,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'رقم سلفة المشروع',
                                // توضيح ضروري: هذا للعرض والتتبّع اليدوي.
                                // الربط الموثوق بسلفة المشروع يتم عبر
                                // advance_id عند الاعتماد لا من هنا.
                                hintText: 'للعرض فقط',
                                prefixIcon: Icon(
                                  Icons.folder_shared_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── الرقم المرجعي وإقفال الصندوق ────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // الرقم المرجعي
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VoucherSectionLabel(
                                  accent: theme.colorScheme.error,
                                  icon: Icons.tag,
                                  label: 'الرقم المرجعي',
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _refNumCtrl,
                                  enabled: !isOperating,
                                  textInputAction: TextInputAction.done,
                                  keyboardType: TextInputType.text,
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
                              VoucherSectionLabel(
                                accent: theme.colorScheme.error,
                                icon: Icons.lock_outline,
                                label: 'إقفال الصندوق',
                              ),
                              const SizedBox(height: 4),
                              Switch(
                                value: _closeSafe,
                                onChanged: isOperating
                                    ? null
                                    : (v) => setState(() => _closeSafe = v),
                              ),
                            ],
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
              VoucherActionButtons(
                accent: theme.colorScheme.error,
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
