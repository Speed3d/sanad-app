// ─────────────────────────────────────────────────────────────────────────────
// item_types_tab.dart — إدارة أنواع البنود (الفلاتر)
//
// المشكلة التي يحلها هذا القسم:
//   كانت أنواع البنود قوائم ثابتة داخل ملفات الشاشات، والاستيراد من الإكسل
//   يقبل أي نص حر — فتصبح «كهربائيات» و«كهربائيه» و«الكهربائيات» ثلاثة بنود
//   مختلفة وتتفتّت التقارير بلا أن يلاحظ أحد.
//
// هنا يدير المالك القائمة الموحّدة التي تقرأ منها كل الشاشات وشاشة مراجعة
// مسودة السلفة.
//
// التعطيل بدل الحذف:
//   بند مستعمَل في سندات قديمة لا يجوز حذفه — التقارير التاريخية ستفقد معناها.
//   التعطيل يُخفيه من قوائم الاختيار الجديدة ويُبقي السجلات القديمة سليمة.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/app_database.dart';
import '../../../providers/advance_providers.dart';
import '../../../providers/database_provider.dart';
import 'settings_shared.dart';

/// قسم إدارة أنواع البنود
class ItemTypesTab extends ConsumerWidget {
  const ItemTypesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(itemTypesProvider(null));

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SettingsSectionHeader(
              icon: Icons.label_outline,
              title: 'أنواع البنود (الفلاتر)',
              subtitle: 'تصنيفات المصروفات والإيرادات المستعملة في السندات '
                  'ومسودات السلف',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'البند المستعمَل في سندات قديمة يُعطَّل ولا يُحذف، حتى '
                      'تبقى التقارير التاريخية سليمة.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('خطأ: $e'),
              data: (types) {
                final sarf = types.where((t) => t.kind != 'kabd').toList();
                final kabd = types.where((t) => t.kind != 'sarf').toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Group(title: 'بنود الصرف', types: sarf),
                    const SizedBox(height: 20),
                    _Group(title: 'بنود القبض', types: kabd),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('بند جديد'),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    // ⚠️ لا تُنشئ TextEditingController هنا ثم تتخلّص منه بعد showDialog.
    //   الـ await ينتهي لحظة استدعاء Navigator.pop، بينما يبقى الحوار
    //   **يُعاد بناؤه** طوال أنيميشن خروجه — فالتخلّص الفوري يجعل الحقل
    //   يلمس متحكّماً ميتاً: «A TextEditingController was used after being
    //   disposed»، ثم تنهار الشجرة بـ «_dependents.isEmpty» شاشةً حمراء.
    //   (عطل بلّغ عنه المالك 2026-08-23 عند إنشاء فترة مالية ثانية.)
    //   الحلّ: متغيّر نصّي عادي مع initialValue/onChanged — بلا متحكّم أصلاً.
    var name = '';
    var kind = 'sarf';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('إضافة نوع بند'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                onChanged: (v) => name = v,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'اسم البند',
                  hintText: 'مثال: كهربائيات',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: kind,
                decoration: const InputDecoration(
                  labelText: 'يصلح لـ',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'sarf', child: Text('سندات الصرف')),
                  DropdownMenuItem(value: 'kabd', child: Text('سندات القبض')),
                  DropdownMenuItem(value: 'both', child: Text('الاثنين')),
                ],
                onChanged: (v) => setLocal(() => kind = v ?? 'sarf'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );

    final trimmed = name.trim();
    if (saved != true || trimmed.isEmpty || !context.mounted) return;

    try {
      await ref.read(appDatabaseProvider).advancesDao.insertItemType(
            ItemTypesCompanion.insert(
              name: name,
              kind: Value(kind),
              sortOrder: const Value(500),
            ),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('أُضيف البند «$name» ✓')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذّرت الإضافة — قد يكون البند «$name» موجوداً بالفعل.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

// ── مجموعة بنود ──────────────────────────────────────────────────────────────

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.types});
  final String title;
  final List<ItemType> types;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${types.where((t) => t.isActive).length} نشط)',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (types.isEmpty)
          const Text('لا توجد بنود.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final t in types) _ItemChip(type: t)],
          ),
      ],
    );
  }
}

class _ItemChip extends ConsumerWidget {
  const _ItemChip({required this.type});
  final ItemType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(type.name),
      selected: type.isActive,
      showCheckmark: false,
      avatar: Icon(
        type.isActive ? Icons.check_circle_outline : Icons.block,
        size: 16,
        color: type.isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      onSelected: (active) async {
        await ref.read(appDatabaseProvider).advancesDao.updateItemType(
              ItemTypesCompanion(
                id: Value(type.id),
                isActive: Value(active),
              ),
            );
      },
      tooltip: type.isActive
          ? 'اضغط لتعطيل «${type.name}» — لن يظهر في القوائم الجديدة'
          : 'اضغط لتفعيل «${type.name}»',
    );
  }
}
