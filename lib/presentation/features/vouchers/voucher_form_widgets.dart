// ─────────────────────────────────────────────────────────────────────────────
// voucher_form_widgets.dart — مكوّنات نموذج السند المشتركة (المرحلة د)
//
// **المشكلة التي يحلّها:**
//   كانت شاشتا الصرف والقبض تحملان **٨٤٠ سطراً متطابقاً** (٨٦٪ من شاشة
//   القبض)، منها ثمانية أصناف ودجت مكرّرة حرفياً باسمين مختلفين فقط:
//     _SectionLabel      ←→  _KabdSectionLabel
//     _TreasuryDropdown  ←→  _KabdTreasuryDropdown
//     _ActionButtons     ←→  _KabdActionButtons   … وهكذا
//
//   والفرق الحقيقي بينها كان **لون التمييز وحده**: أحمر للصرف وأخضر للقبض.
//
// **الثمن الذي دفعناه فعلاً:** حين وُصلت أنواع البنود بقاعدة البيانات (ب-١)
// وجب تعديل الشاشتين. ولو نُسيت إحداهما لبقيت نصف الميزة معطَّلة بصمت — وهو
// ما حدث فعلاً مع قوائم البنود الثابتة قبل ب-١.
//
// **الحل:** نسخة واحدة بمعامل `accent`. أي تحسين على النموذج يصل الشاشتين معاً.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../data/database/app_database.dart';
import '../../../core/utils/input_validators.dart';
import '../../../domain/models/treasury_model.dart';

class VoucherFiscalPeriodBanner extends StatelessWidget {
  /// لون تمييز الشاشة — أحمر للصرف وأخضر للقبض
  final Color accent;

  final AsyncValue<FiscalPeriod?> periodAsync;

  const VoucherFiscalPeriodBanner(
      {super.key, required this.accent, required this.periodAsync});

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // خلفية مشتقّة من لون الشاشة بدل primaryContainer الثابت،
            // فتتبع الصرف والقبض تلقائياً
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.event_available, color: accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الفترة المالية: ${period.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: accent,
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

class VoucherSectionLabel extends StatelessWidget {
  /// لون تمييز الشاشة — أحمر للصرف وأخضر للقبض
  final Color accent;

  final IconData icon;
  final String label;

  const VoucherSectionLabel(
      {super.key,
      required this.accent,
      required this.icon,
      required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class VoucherTreasuryDropdown extends StatelessWidget {
  /// لون تمييز الشاشة — أحمر للصرف وأخضر للقبض
  final Color accent;

  final AsyncValue<List<TreasuryModel>> treasuriesAsync;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final bool enabled;

  const VoucherTreasuryDropdown({
    super.key,
    required this.accent,
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
        final effectiveId =
            selectedId != null && active.any((t) => t.id == selectedId)
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
                      VoucherKindDot(kind: t.kind),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.name)),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
          validator: (v) => v == null ? 'يرجى اختيار الخزينة' : null,
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

class VoucherKindDot extends StatelessWidget {
  final String kind;

  const VoucherKindDot({super.key, required this.kind});

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

class VoucherAmountCurrencyRow extends StatelessWidget {
  /// لون تمييز الشاشة — أحمر للصرف وأخضر للقبض
  final Color accent;

  final TextEditingController amountCtrl;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;
  final bool enabled;

  const VoucherAmountCurrencyRow({
    super.key,
    required this.accent,
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
              prefixIcon: Icon(Icons.attach_money, size: 20),
            ),
            // مدقّق مشترك بدل نسخة يدوية في كل شاشة (المرحلة د)
            validator: InputValidators.positiveAmount,
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
                onSelectionChanged:
                    enabled ? (s) => onCurrencyChanged(s.first) : null,
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

class VoucherExchangeRateHint extends StatelessWidget {
  /// لون تمييز الشاشة — أحمر للصرف وأخضر للقبض
  final Color accent;

  final AsyncValue<double> rateAsync;

  const VoucherExchangeRateHint(
      {super.key, required this.accent, required this.rateAsync});

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
            color: accent,
          ),
          const SizedBox(width: 6),
          Text(
            '1 \$ = ${fmt.format(rate)} د.ع (السعر الحالي)',
            style: TextStyle(
              fontSize: 12,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class VoucherDatePickerField extends StatelessWidget {
  /// لون تمييز الشاشة — أحمر للصرف وأخضر للقبض
  final Color accent;

  final DateTime date;
  final VoidCallback? onTap;

  const VoucherDatePickerField(
      {super.key, required this.accent, required this.date, this.onTap});

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
            color: accent,
          ),
        ),
        child: Text(fmt.format(date)),
      ),
    );
  }
}

class VoucherActionButtons extends StatelessWidget {
  /// لون تمييز الشاشة — أحمر للصرف وأخضر للقبض
  final Color accent;

  final bool isEdit;
  final bool isOperating;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const VoucherActionButtons({
    super.key,
    required this.accent,
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
