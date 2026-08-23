// ─────────────────────────────────────────────────────────────────────────────
// item_type_selector.dart — مُنتقي نوع البند من قاعدة البيانات
//
// **المشكلة التي يحلّها (ب-١ — 2026-08-23):**
//   كانت شاشتا الصرف والقبض تعرضان **قائمتين ثابتتين** مكتوبتين في الكود
//   (٨ بنود للصرف · ٧ للقبض)، بينما قاعدة البيانات فيها جدول `item_types`
//   مبذور بـ **٢١ بنداً** ومعه تبويب كامل في الإعدادات لإدارتها.
//
//   النتيجة العملية: المالك يضيف «كهربائيات» من الإعدادات فلا تظهر في شاشة
//   الصرف إطلاقاً — ميزة كاملة معطَّلة بصمت. والأسوأ أن المسودات المستوردة
//   من إكسل تستعمل بنود الجدول، فتختلف مفردات السند اليدوي عن المستورد
//   وتتشتّت التقارير على مسمّيات متعدّدة للبند الواحد.
//
// **الحل:** ودجت واحد يقرأ من `itemTypeNamesProvider` — مصدر الحقيقة نفسه
// الذي تستعمله شاشة مراجعة السلف وتبويب الإعدادات.
//
// ولماذا ودجت مشترك لا نسخة في كل شاشة؟ لأن النسختين المكرّرتين هما سبب
// المشكلة أصلاً: عُدِّلت إحداهما ونُسيت الأخرى.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/advance_providers.dart';

/// شرائح اختيار نوع البند — تُقرأ من جدول `item_types` مباشرةً
///
/// [kind]     — 'sarf' أو 'kabd'. البنود المُعلَّمة 'both' تظهر مع الاثنين.
/// [selected] — البند المختار حالياً ('' = غير محدد)
/// [onSelected] — يُستدعى بالاسم المختار، أو بـ '' عند اختيار «غير محدد»
class ItemTypeSelector extends ConsumerWidget {
  const ItemTypeSelector({
    super.key,
    required this.kind,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final String kind;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final namesAsync = ref.watch(itemTypeNamesProvider(kind));

    return SizedBox(
      height: 38,
      child: namesAsync.when(
        loading: () => const Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),

        // الخطأ لا يُخفى ولا يُعطّل النموذج: يبقى «غير محدد» متاحاً فيستطيع
        // المستخدم إكمال السند، مع رسالة تشرح سبب غياب البنود.
        error: (e, _) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'تعذّر تحميل أنواع البنود',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ),

        data: (names) {
          // '' أولاً دائماً — «غير محدد» خيار مشروع لا نقص في البيانات
          final options = <String>['', ...names];

          if (names.isEmpty) {
            return Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'لا توجد أنواع بنود — أضفها من: الإعدادات ← أنواع البنود',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final value = options[i];
              return ChoiceChip(
                label: Text(value.isEmpty ? 'غير محدد' : value),
                selected: selected == value,
                onSelected: enabled ? (_) => onSelected(value) : null,
                visualDensity: VisualDensity.compact,
              );
            },
          );
        },
      ),
    );
  }
}

/// قائمة منسدلة بأنواع البنود — للفلترة في قوائم السندات
///
/// تختلف عن [ItemTypeSelector] في أنها تعرض **البنود المستعملة فعلاً** لا
/// كل البنود المتاحة: فلترة بقيمة لا سند يحملها تُعطي قائمة فارغة محيّرة.
class ItemTypeFilterDropdown extends StatelessWidget {
  const ItemTypeFilterDropdown({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    this.label = 'البند',
    this.icon = Icons.label_outline,
  });

  /// البنود المستعملة فعلاً في السندات المعروضة
  final List<String> values;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      // القيمة المختارة قد تختفي من القائمة عند تغيّر الفلاتر الأخرى —
      // نُسقطها بدل تمرير قيمة غير موجودة (يرمي Dropdown استثناءً عندها).
      initialValue: values.contains(selected) ? selected : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('الكل')),
        ...values.map(
          (v) => DropdownMenuItem<String>(
            value: v,
            child: Text(v, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
