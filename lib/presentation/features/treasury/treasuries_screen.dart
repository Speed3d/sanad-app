// ─────────────────────────────────────────────────────────────────────────────
// treasuries_screen.dart — شاشة إدارة الخزائن
//
// الوظائف:
//   1. عرض ملخص إجمالي الأرصدة (IQD + USD + عدد الخزائن)
//   2. فلترة الخزائن حسب النوع (الكل / رئيسية / مقاولون / شركاء)
//   3. بطاقات تفاعلية لكل خزينة مع رصيدها الحالي المحسوب من الـ VIEW
//   4. إنشاء خزينة رئيسية جديدة
//   5. تعديل اسم الخزينة
//   6. تفعيل / تعطيل الخزينة
//   7. حذف ناعم (مع تحقق من عدم وجود سندات)
//   8. صفحة تفاصيل سريعة (BottomSheet) تعرض إحصائيات الخزينة
//
// الأرصدة:
//   لا تُخزَّن — تُحسَب من VIEW v_treasury_balances عبر Drift Streams
//   يتحدث الرصيد تلقائياً عند أي تغيير في السندات
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/treasury_model.dart';
import '../../providers/advance_providers.dart';
import '../../providers/database_provider.dart';
import '../../providers/employee_providers.dart';
import '../../providers/treasury_providers.dart';

// ── أجزاء المكتبة (المرحلة د) ───────────────────────────────────────
part 'treasury_card.dart';

// ── ثوابت الفلاتر ────────────────────────────────────────────────────────────

class _KindFilter {
  final String? value; // null = الكل
  final String label;
  final IconData icon;
  const _KindFilter({this.value, required this.label, required this.icon});
}

const List<_KindFilter> _kindFilters = [
  _KindFilter(value: null, label: 'الكل', icon: Icons.grid_view_outlined),
  _KindFilter(value: 'main', label: 'رئيسية', icon: Icons.account_balance_outlined),
  _KindFilter(value: 'contractor', label: 'مقاولون', icon: Icons.engineering_outlined),
  _KindFilter(value: 'partner', label: 'شركاء', icon: Icons.handshake_outlined),
];

// ═══════════════════════════════════════════════════════════════════════════
// TreasuriesScreen — الشاشة الرئيسية
// ═══════════════════════════════════════════════════════════════════════════

/// شاشة إدارة الخزائن
class TreasuriesScreen extends ConsumerStatefulWidget {
  const TreasuriesScreen({super.key});

  @override
  ConsumerState<TreasuriesScreen> createState() => _TreasuriesScreenState();
}

class _TreasuriesScreenState extends ConsumerState<TreasuriesScreen> {
  String? _activeFilter; // null = الكل

  @override
  Widget build(BuildContext context) {
    // ── مراقبة نتائج العمليات ──────────────────────────────────────────
    ref.listen<AsyncValue<String?>>(treasuryNotifierProvider, (_, next) {
      if (!mounted) return;
      if (next is AsyncData<String?> && next.value != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.value!)),
        );
        ref.read(treasuryNotifierProvider.notifier).reset();
      } else if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${next.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
        ref.read(treasuryNotifierProvider.notifier).reset();
      }
    });

    final balancesAsync = ref.watch(treasuryBalancesProvider);
    final isOperating = ref.watch(treasuryNotifierProvider) is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الخزائن'),
        actions: [
          IconButton(
            icon: isOperating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle_outline),
            tooltip: 'إضافة خزينة جديدة',
            onPressed: isOperating ? null : () => _showCreateDialog(context),
          ),
        ],
      ),
      body: balancesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(error: e.toString()),
        data: (balances) {
          // فلترة حسب النوع المحدد
          final filtered = _activeFilter == null
              ? balances
              : balances
                  .where((b) => b.treasuryKind == _activeFilter)
                  .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── شريط الملخص ───────────────────────────────────────
              _SummaryBar(balances: balances),

              // ── شرائح الفلتر ──────────────────────────────────────
              _FilterRow(
                activeFilter: _activeFilter,
                allBalances: balances,
                onFilterChanged: (v) => setState(() => _activeFilter = v),
              ),

              // ── قائمة الخزائن ────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(
                        isFiltered: _activeFilter != null,
                        onClearFilter: () =>
                            setState(() => _activeFilter = null),
                        onCreateTap: () => _showCreateDialog(context),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final balance = filtered[index];
                          return _TreasuryCard(
                            balance: balance,
                            isOperating: isOperating,
                            onTap: () =>
                                _showDetailSheet(context, balance),
                            onEdit: () =>
                                _showEditDialog(context, balance),
                            onToggleActive: (v) => ref
                                .read(treasuryNotifierProvider.notifier)
                                .toggleActive(
                                  balance.treasuryId,
                                  isActive: v,
                                ),
                            onDelete: () =>
                                _confirmDelete(context, balance),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),

      // FAB — إضافة خزينة
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isOperating ? null : () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('خزينة جديدة'),
        tooltip: 'إضافة خزينة رئيسية جديدة',
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // حوار إنشاء خزينة
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _showCreateDialog(BuildContext context) async {
    // ⚠️ لا تُنشئ TextEditingController هنا ثم تتخلّص منه بعد showDialog.
    //   الـ await ينتهي لحظة استدعاء Navigator.pop، بينما يبقى الحوار
    //   **يُعاد بناؤه** طوال أنيميشن خروجه — فالتخلّص الفوري يجعل الحقل
    //   يلمس متحكّماً ميتاً: «A TextEditingController was used after being
    //   disposed»، ثم تنهار الشجرة بـ «_dependents.isEmpty» شاشةً حمراء.
    //   (عطل بلّغ عنه المالك 2026-08-23 عند إنشاء فترة مالية ثانية.)
    //   الحلّ: متغيّر نصّي عادي مع initialValue/onChanged — بلا متحكّم أصلاً.
    String name = '';
    final formKey = GlobalKey<FormState>();
    bool isCreating = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.account_balance_outlined, size: 20),
              SizedBox(width: 8),
              Text('خزينة جديدة'),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: TextFormField(
                initialValue: name,
                onChanged: (v) => name = v,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'اسم الخزينة',
                  hintText: 'مثال: الخزينة الرئيسية',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'اسم الخزينة مطلوب';
                  }
                  if (v.trim().length < 2) return 'الاسم قصير جداً';
                  return null;
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: isCreating
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setS(() => isCreating = true);
                      await ref
                          .read(treasuryNotifierProvider.notifier)
                          .createTreasury(
                            name: name.trim(),
                            kind: 'main',
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              icon: isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add),
              label: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // حوار تعديل الاسم
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _showEditDialog(
    BuildContext context,
    TreasuryBalanceModel balance,
  ) async {
    // ⚠️ لا تُنشئ TextEditingController هنا ثم تتخلّص منه بعد showDialog.
    //   الـ await ينتهي لحظة استدعاء Navigator.pop، بينما يبقى الحوار
    //   **يُعاد بناؤه** طوال أنيميشن خروجه — فالتخلّص الفوري يجعل الحقل
    //   يلمس متحكّماً ميتاً: «A TextEditingController was used after being
    //   disposed»، ثم تنهار الشجرة بـ «_dependents.isEmpty» شاشةً حمراء.
    //   (عطل بلّغ عنه المالك 2026-08-23 عند إنشاء فترة مالية ثانية.)
    //   الحلّ: متغيّر نصّي عادي مع initialValue/onChanged — بلا متحكّم أصلاً.
    String name = balance.treasuryName;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit_outlined, size: 20),
              SizedBox(width: 8),
              Text('تعديل اسم الخزينة'),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: TextFormField(
                initialValue: name,
                onChanged: (v) => name = v,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'الاسم الجديد',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'الاسم مطلوب';
                  if (v.trim().length < 2) return 'الاسم قصير جداً';
                  return null;
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setS(() => isSaving = true);

                      // نبني TreasuryModel مؤقت للتحديث
                      final model = TreasuryModel(
                        id: balance.treasuryId,
                        name: balance.treasuryName,
                        kind: balance.treasuryKind,
                        entityId: balance.entityId,
                        entityType: balance.entityType,
                        isActive: balance.isActive,
                      );

                      await ref
                          .read(treasuryNotifierProvider.notifier)
                          .renameTreasury(model, name.trim());

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // تأكيد الحذف
  // ══════════════════════════════════════════════════════════════════════

  /// تأكيد حذف خزينة — **ويسأل عن موظفيها قبل أن يتيتّموا** (ع-٣٤)
  ///
  /// 🔑 **سبب التنبيه** (بلاغ المالك 2026-08-26): حُذفت خزينة «البصرة» وبقي
  ///   ٤٦ موظفاً منسوبين إليها بصمت. لم يشتكِ النظام، لكن كل ما يعتمد على
  ///   «مشروع الموظف» صار يقرأ خزينةً لا وجود لها — ومنها تقرير الموظف
  ///   بالمشروع.
  Future<void> _confirmDelete(
    BuildContext context,
    TreasuryBalanceModel balance,
  ) async {
    final theme = Theme.of(context);

    // ⚠️ **قراءة مباشرة لا `ref.read(provider.future)`** (ع-٣٥):
    //   المزوّدات المولَّدة `autoDispose` بطبعها. وقراءة `.future` منها في
    //   دالة async **بلا مراقب** تُنشئها ثم تتخلّص منها قبل أن يكتمل
    //   المستقبل، فترمي: «disposed during loading state».
    //   وهو **سباق**: ينجح حين يسبق الاستعلام دورةَ التخلّص ويفشل حين
    //   يتأخّر — فبدا أنه يعمل مع خزينة ويُسقط التطبيق مع التالية.
    //   الاستعلام لمرّة واحدة لا يحتاج مزوّداً أصلاً.
    final employeeCount = await ref
        .read(appDatabaseProvider)
        .employeesDao
        .countEmployeesInTreasury(balance.treasuryId);
    if (!context.mounted) return;

    // وجهة النقل التي يختارها المالك — `null` يعني «اتركهم بلا مشروع»
    int? moveTo;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline, size: 20),
            SizedBox(width: 8),
            Text('حذف الخزينة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (balance.totalVouchers > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.block,
                        color: theme.colorScheme.onErrorContainer,
                        size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'لا يمكن حذف هذه الخزينة — تحتوي على '
                        '${balance.totalVouchers} سند.\n'
                        'يمكنك تعطيلها بدلاً من ذلك.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                'هل تريد حذف خزينة "${balance.treasuryName}"؟\n'
                'سيتم الحذف بشكل ناعم ولن تُفقَد البيانات.',
              ),
              if (employeeCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.groups_outlined,
                              color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$employeeCount موظفاً منسوبون إلى هذه '
                              'الخزينة — سيبقون **بلا مشروع** بعد حذفها.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Consumer(
                        builder: (ctx, ref2, _) {
                          final others = (ref2
                                      .watch(allTreasuriesProvider)
                                      .valueOrNull ??
                                  const [])
                              .where((t) =>
                                  t.id != balance.treasuryId && t.isActive)
                              .toList();
                          return DropdownButtonFormField<int?>(
                            initialValue: moveTo,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'انقلهم إلى (اختياري)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('اتركهم بلا مشروع'),
                              ),
                              for (final t in others)
                                DropdownMenuItem<int?>(
                                  value: t.id,
                                  child: Text(t.name,
                                      overflow: TextOverflow.ellipsis),
                                ),
                            ],
                            onChanged: (v) => setState(() => moveTo = v),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          if (balance.totalVouchers == 0)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('حذف'),
            ),
        ],
        ),
      ),
    );

    if (confirmed == true) {
      // ⚠️ **النقل قبل الحذف**: بعده تصير الخزينة محذوفة ويبقى الموظفون
      //   يشيرون إليها — وهو العطل نفسه الذي جاء التنبيه ليمنعه.
      if (employeeCount > 0) {
        await ref.read(employeeNotifierProvider.notifier).reassignTreasury(
              fromTreasuryId: balance.treasuryId,
              toTreasuryId: moveTo,
            );
      }
      await ref.read(treasuryNotifierProvider.notifier).deleteTreasury(
            balance.treasuryId,
            totalVouchers: balance.totalVouchers,
          );
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // صفحة تفاصيل الخزينة (BottomSheet)
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _showDetailSheet(
    BuildContext context,
    TreasuryBalanceModel balance,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TreasuryDetailSheet(balance: balance),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _SummaryBar — شريط إجمالي الأرصدة
// ═══════════════════════════════════════════════════════════════════════════

class _SummaryBar extends StatelessWidget {
  final List<TreasuryBalanceModel> balances;
  const _SummaryBar({required this.balances});

  @override
  Widget build(BuildContext context) {
    double totalIqd = 0;
    double totalUsd = 0;
    int activeCount = 0;

    for (final b in balances) {
      totalIqd += b.balanceIqd;
      totalUsd += b.balanceUsd;
      if (b.isActive) activeCount++;
    }

    final fmtIqd = NumberFormat('#,##0');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF18233A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'إجمالي رصيد الخزائن',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: fmtIqd.format(totalIqd),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: 'د.ع',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                if (totalUsd != 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '\$ ${fmtIqd.format(totalUsd)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE0BC66),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 1,
            height: 46,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$activeCount',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE0BC66),
                ),
              ),
              Text(
                'خزينة نشطة',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _FilterRow — شريط الفلاتر
// ═══════════════════════════════════════════════════════════════════════════

class _FilterRow extends StatelessWidget {
  final String? activeFilter;
  final List<TreasuryBalanceModel> allBalances;
  final void Function(String?) onFilterChanged;

  const _FilterRow({
    required this.activeFilter,
    required this.allBalances,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: _kindFilters.map((f) {
          final count = f.value == null
              ? allBalances.length
              : allBalances.where((b) => b.treasuryKind == f.value).length;
          final isSelected = activeFilter == f.value;

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilterChip(
              avatar: Icon(f.icon,
                  size: 15,
                  color: isSelected
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onSurfaceVariant),
              label: Text('${f.label} ($count)'),
              selected: isSelected,
              onSelected: (_) => onFilterChanged(f.value),
              selectedColor: theme.colorScheme.secondaryContainer,
              checkmarkColor: theme.colorScheme.onSecondaryContainer,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _PendingDraftWarning — تحذير المسودات المعلّقة على خزينة المشروع
// ═══════════════════════════════════════════════════════════════════════════

/// يعرض ما ينتظر الاعتماد على هذه الخزينة، وما سيصير إليه رصيدها بعده
///
/// لماذا هذا التحذير؟
///   مسودة السلفة لا تمسّ الرصيد (وهذا مقصود — لا شيء يمسّ الدفاتر قبل
///   الاعتماد). لكن ذلك يعني أن الخزينة تبدو ممتلئة بينما مصاريفها وصلت
///   فعلاً وتنتظر الاعتماد فقط. عرض «المتاح بعد الاعتماد» يكشف العجز
///   **قبل** لحظة الاعتماد لا بعدها، فيتاح للمالك تحويل مبلغ تكميلي مبكراً.
class _PendingDraftWarning extends ConsumerWidget {
  const _PendingDraftWarning({
    required this.treasuryId,
    required this.balanceIqd,
  });

  final int treasuryId;
  final double balanceIqd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingDraftTotalsProvider);
    final pending = async.valueOrNull?[treasuryId] ?? 0.0;
    if (pending <= 0) return const SizedBox.shrink();

    final fmt = NumberFormat('#,###', 'en_US');
    final after = balanceIqd - pending;
    final willBeNegative = after < 0;
    final color = willBeNegative ? Colors.red.shade700 : Colors.orange.shade800;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.pending_actions_outlined, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'معلّق في مسودات ${fmt.format(pending)} د.ع · '
                'المتاح بعد الاعتماد ${fmt.format(after.abs())} د.ع'
                '${willBeNegative ? ' (عجز)' : ''}',
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight:
                      willBeNegative ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
