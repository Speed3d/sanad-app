// ─────────────────────────────────────────────────────────────────────────────
// treasury_link_picker.dart — اختيار خزينة المقاول أو الشريك
//
// **الميزة التي وُصلت أخيراً** (قرار المالك 2026-09-01):
//   كان `contractors.treasury_id` و`partners.treasury_id` يبقيان `NULL`
//   **أبداً** لأن واجهتَي الإنشاء لا تمرّرانهما، و`kind` ثابت `'main'` عند
//   إنشاء أي خزينة. فتبويبا الفلترة «مقاولون/شركاء» في شاشة الخزائن
//   وشاراتهما وألوانهما — كلها **واجهة لبيانات لا يمكن أن توجد**.
//
// ═══ لماذا ودجت مشترك لا نسخة في كل شاشة؟ ═══
//   الخياران واحد في المقاولين والشركاء، ونسختان تعنيان أن إصلاح تسمية أو
//   إضافة خيارٍ ثالث يصل واحدة وينسى الأخرى — وهي عائلة الأعطال الأشيع في
//   هذا المشروع (٨٤٠ سطراً مكرّراً بين شاشتَي السند).
//
// ⚠️ **و«بلا خزينة» خيارٌ صريح لا غياب**: من يعمل بالمقاولة النقدية قد لا
//   يريد حساباً مستقلاً، والخيار المكتوب يقول ذلك بدل أن يبدو نسياناً.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/treasury_model.dart';
import '../../providers/treasury_providers.dart';

/// كيف تُربَط خزينة الكيان
enum TreasuryLinkMode {
  /// تُنشَأ خزينة جديدة باسمه — الافتراضي
  create,

  /// يُربَط بخزينة قائمة يختارها المالك
  link,

  /// بلا خزينة
  none,
}

/// اختيار خزينة لمقاول أو شريك جديد
class TreasuryLinkPicker extends ConsumerWidget {
  const TreasuryLinkPicker({
    super.key,
    required this.mode,
    required this.linkedTreasuryId,
    required this.autoName,
    required this.onChanged,
  });

  final TreasuryLinkMode mode;
  final int? linkedTreasuryId;

  /// اسم الخزينة التي ستُنشَأ — يُعرَض قبل الحفظ لا بعده
  final String autoName;

  final void Function(TreasuryLinkMode mode, int? treasuryId) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final List<TreasuryModel> treasuries =
        ref.watch(allTreasuriesProvider).valueOrNull ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الخزينة (الحساب المالي)', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'الخزينة حسابٌ يدخله المال ويخرج منه ويظهر في التقارير.',
          style: TextStyle(
            fontSize: 11.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),

        // ⚠️ `RadioGroup` لا `groupValue`/`onChanged` على كل خيار: الأخيرتان
        //   مهجورتان منذ Flutter 3.32، والمحلّل في هذا المشروع لا يقبل تحذيراً.
        RadioGroup<TreasuryLinkMode>(
          groupValue: mode,
          onChanged: (v) {
            if (v == null) return;
            onChanged(v, v == TreasuryLinkMode.link ? linkedTreasuryId : null);
          },
          child: Column(
            children: [
              RadioListTile<TreasuryLinkMode>(
                value: TreasuryLinkMode.create,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('إنشاء خزينة باسمه',
                    style: TextStyle(fontSize: 13)),
                // الاسم يُعرَض **قبل** الحفظ: خزينةٌ تظهر باسمٍ لم يره
                // المالك تبدو له غريبة في كل قائمة بعدها
                subtitle: Text(autoName,
                    style: const TextStyle(fontSize: 11.5)),
              ),
              RadioListTile<TreasuryLinkMode>(
                value: TreasuryLinkMode.link,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('ربطه بخزينة قائمة',
                    style: TextStyle(fontSize: 13)),
              ),
              RadioListTile<TreasuryLinkMode>(
                value: TreasuryLinkMode.none,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('بلا خزينة',
                    style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),

        if (mode == TreasuryLinkMode.link) ...[
          const SizedBox(height: 6),
          if (treasuries.isEmpty)
            const Text('لا خزائن بعد — أنشئ واحدة أو اختر «إنشاء خزينة باسمه».',
                style: TextStyle(fontSize: 12))
          else
            DropdownButtonFormField<int>(
              initialValue: linkedTreasuryId,
              decoration: const InputDecoration(
                labelText: 'الخزينة',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final t in treasuries)
                  DropdownMenuItem(value: t.id, child: Text(t.name)),
              ],
              onChanged: (v) => onChanged(TreasuryLinkMode.link, v),
            ),
          const SizedBox(height: 4),
          Text(
            'ستتحوّل الخزينة المختارة إلى حسابٍ باسمه في شاشة الخزائن.',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
