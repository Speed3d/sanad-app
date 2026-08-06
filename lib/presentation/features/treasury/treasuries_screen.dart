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
import '../../providers/treasury_providers.dart';

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
    final nameCtrl = TextEditingController();
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
                controller: nameCtrl,
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
                            name: nameCtrl.text.trim(),
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
    nameCtrl.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════
  // حوار تعديل الاسم
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _showEditDialog(
    BuildContext context,
    TreasuryBalanceModel balance,
  ) async {
    final nameCtrl =
        TextEditingController(text: balance.treasuryName);
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
                controller: nameCtrl,
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
                          .renameTreasury(model, nameCtrl.text.trim());

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
    nameCtrl.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════
  // تأكيد الحذف
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _confirmDelete(
    BuildContext context,
    TreasuryBalanceModel balance,
  ) async {
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
            else
              Text(
                'هل تريد حذف خزينة "${balance.treasuryName}"؟\n'
                'سيتم الحذف بشكل ناعم ولن تُفقَد البيانات.',
              ),
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
    );

    if (confirmed == true) {
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

    final fmtIqd = NumberFormat('#,##0.##');

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
// _TreasuryCard — بطاقة الخزينة
// ═══════════════════════════════════════════════════════════════════════════

class _TreasuryCard extends StatelessWidget {
  final TreasuryBalanceModel balance;
  final bool isOperating;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final void Function(bool) onToggleActive;
  final VoidCallback onDelete;

  const _TreasuryCard({
    required this.balance,
    required this.isOperating,
    required this.onTap,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmtIqd = NumberFormat('#,###', 'en_US');
    final fmtUsd = NumberFormat('#,##0.00', 'en_US');
    final isDebtorIqd = balance.balanceIqd < 0;
    final isDebtorUsd = balance.balanceUsd < 0;

    // تاريخ آخر سند
    final lastDate = balance.lastVoucherDate;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: balance.isActive ? 2 : 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: balance.isActive
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: balance.isActive ? 1.0 : 0.65,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── رأس البطاقة ───────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // أيقونة نوع الخزينة
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kindColor(theme, balance.treasuryKind)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _kindIcon(balance.treasuryKind),
                        size: 22,
                        color: _kindColor(theme, balance.treasuryKind),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // الاسم والنوع
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            balance.treasuryName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              _KindBadge(kind: balance.treasuryKind),
                              const SizedBox(width: 6),
                              if (!balance.isActive)
                                _StatusChip(
                                  label: 'معطَّلة',
                                  color: theme.colorScheme.error,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // قائمة الإجراءات
                    _ActionsMenu(
                      balance: balance,
                      isOperating: isOperating,
                      onEdit: onEdit,
                      onToggleActive: onToggleActive,
                      onDelete: onDelete,
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // ── الأرصدة ───────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _BalanceBlock(
                        label: 'بالدينار العراقي',
                        amount: '${fmtIqd.format(balance.balanceIqd.abs())} د.ع',
                        isNegative: isDebtorIqd,
                        isZero: balance.balanceIqd == 0,
                      ),
                    ),
                    if (balance.balanceUsd != 0) ...[
                      Container(
                        width: 1,
                        height: 36,
                        color: theme.colorScheme.outlineVariant,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      Expanded(
                        child: _BalanceBlock(
                          label: 'بالدولار الأمريكي',
                          amount:
                              '${fmtUsd.format(balance.balanceUsd.abs())} \$',
                          isNegative: isDebtorUsd,
                          isZero: balance.balanceUsd == 0,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // ── إحصائيات مختصرة ────────────────────────────────
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${balance.totalVouchers} سند',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (lastDate != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'آخر عملية: ${dateFmt.format(lastDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 12),
                      Text(
                        'لا توجد سندات',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      Icons.chevron_left,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _kindColor(ThemeData theme, String kind) {
    switch (kind) {
      case 'main':
        return theme.colorScheme.primary;
      case 'contractor':
        return Colors.orange.shade700;
      case 'partner':
        return Colors.teal.shade600;
      default:
        return theme.colorScheme.secondary;
    }
  }

  IconData _kindIcon(String kind) {
    switch (kind) {
      case 'main':
        return Icons.account_balance_outlined;
      case 'contractor':
        return Icons.engineering_outlined;
      case 'partner':
        return Icons.handshake_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _ActionsMenu — قائمة إجراءات البطاقة
// ═══════════════════════════════════════════════════════════════════════════

class _ActionsMenu extends StatelessWidget {
  final TreasuryBalanceModel balance;
  final bool isOperating;
  final VoidCallback onEdit;
  final void Function(bool) onToggleActive;
  final VoidCallback onDelete;

  const _ActionsMenu({
    required this.balance,
    required this.isOperating,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      enabled: !isOperating,
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'edit',
          onTap: onEdit,
          child: const Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 10),
              Text('تعديل الاسم'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle',
          onTap: () => onToggleActive(!balance.isActive),
          child: Row(
            children: [
              Icon(
                balance.isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(balance.isActive ? 'تعطيل' : 'تفعيل'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          onTap: onDelete,
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 10),
              Text(
                'حذف',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _TreasuryDetailSheet — صفحة تفاصيل الخزينة (Bottom Sheet)
// ═══════════════════════════════════════════════════════════════════════════

class _TreasuryDetailSheet extends StatelessWidget {
  final TreasuryBalanceModel balance;
  const _TreasuryDetailSheet({required this.balance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmtIqd = NumberFormat('#,###', 'en_US');
    final fmtUsd = NumberFormat('#,##0.00', 'en_US');
    final dateFmt = DateFormat('dd/MM/yyyy — HH:mm');

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // مقبض السحب
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                // ── رأس الصفحة ─────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        balance.treasuryKind == 'main'
                            ? Icons.account_balance_outlined
                            : balance.treasuryKind == 'contractor'
                                ? Icons.engineering_outlined
                                : Icons.handshake_outlined,
                        size: 28,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            balance.treasuryName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              _KindBadge(kind: balance.treasuryKind),
                              if (!balance.isActive) ...[
                                const SizedBox(width: 6),
                                _StatusChip(
                                  label: 'معطَّلة',
                                  color: theme.colorScheme.error,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // ── الأرصدة التفصيلية ──────────────────────────────
                Text(
                  'الرصيد الحالي',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // بطاقة رصيد IQD
                _DetailBalanceCard(
                  currency: 'IQD',
                  symbol: 'د.ع',
                  amount: balance.balanceIqd,
                  formattedAbs: fmtIqd.format(balance.balanceIqd.abs()),
                ),

                if (balance.balanceUsd != 0) ...[
                  const SizedBox(height: 10),
                  _DetailBalanceCard(
                    currency: 'USD',
                    symbol: '\$',
                    amount: balance.balanceUsd,
                    formattedAbs: fmtUsd.format(balance.balanceUsd.abs()),
                  ),
                ],

                const SizedBox(height: 20),

                // ── إحصائيات ────────────────────────────────────────
                Text(
                  'إحصائيات',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                _StatsGrid(
                  totalVouchers: balance.totalVouchers,
                  lastVoucherDate: balance.lastVoucherDate,
                  dateFmt: dateFmt,
                ),

                const SizedBox(height: 20),

                // ── معلومات الكيان المرتبط ──────────────────────────
                if (balance.entityId != null) ...[
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.link,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'مرتبطة بـ ${_entityTypeLabel(balance.entityType)} '
                        '#${balance.entityId}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _entityTypeLabel(String? type) {
    switch (type) {
      case 'contractor':
        return 'مقاول';
      case 'partner':
        return 'شريك';
      case 'employee':
        return 'موظف';
      default:
        return type ?? '';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// widgets مساعدة
// ═══════════════════════════════════════════════════════════════════════════

class _KindBadge extends StatelessWidget {
  final String kind;
  const _KindBadge({required this.kind});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (kind) {
      'main' => ('خزينة رئيسية', theme.colorScheme.primary),
      'contractor' => ('حساب مقاول', Colors.orange.shade700),
      'partner' => ('حساب شريك', Colors.teal.shade600),
      _ => (kind, theme.colorScheme.secondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BalanceBlock extends StatelessWidget {
  final String label;
  final String amount;
  final bool isNegative;
  final bool isZero;

  const _BalanceBlock({
    required this.label,
    required this.amount,
    required this.isNegative,
    required this.isZero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isZero
        ? theme.colorScheme.onSurfaceVariant
        : isNegative
            ? theme.colorScheme.error
            : Colors.green.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (isNegative)
              Icon(Icons.arrow_downward, size: 14, color: color)
            else if (!isZero)
              Icon(Icons.arrow_upward, size: 14, color: color),
            const SizedBox(width: 2),
            Text(
              amount,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        if (isNegative)
          Text(
            'رصيد مدين',
            style: TextStyle(
              color: theme.colorScheme.error,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _DetailBalanceCard extends StatelessWidget {
  final String currency;
  final String symbol;
  final double amount;
  final String formattedAbs;

  const _DetailBalanceCard({
    required this.currency,
    required this.symbol,
    required this.amount,
    required this.formattedAbs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNeg = amount < 0;
    final color = isNeg ? theme.colorScheme.error : Colors.green.shade700;
    final bgColor = isNeg
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
        : Colors.green.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              symbol,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currency == 'IQD' ? 'دينار عراقي' : 'دولار أمريكي',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$formattedAbs $symbol',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (isNeg)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'مدين',
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int totalVouchers;
  final DateTime? lastVoucherDate;
  final DateFormat dateFmt;

  const _StatsGrid({
    required this.totalVouchers,
    required this.lastVoucherDate,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _StatRow(
            icon: Icons.receipt_long_outlined,
            label: 'إجمالي السندات',
            value: '$totalVouchers سند',
            isFirst: true,
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          _StatRow(
            icon: Icons.access_time_outlined,
            label: 'آخر عملية',
            value: lastVoucherDate != null
                ? dateFmt.format(lastVoucherDate!)
                : 'لا توجد عمليات',
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isFirst;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _EmptyState
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onClearFilter;
  final VoidCallback onCreateTap;

  const _EmptyState({
    required this.isFiltered,
    required this.onClearFilter,
    required this.onCreateTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFiltered
                  ? Icons.filter_alt_off_outlined
                  : Icons.account_balance_wallet_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isFiltered ? 'لا توجد نتائج لهذا الفلتر' : 'لا توجد خزائن بعد',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'جرب فلتراً آخر أو اعرض الكل'
                : 'أنشئ أول خزينة للبدء في تسجيل السندات',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          isFiltered
              ? OutlinedButton.icon(
                  onPressed: onClearFilter,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('عرض الكل'),
                )
              : FilledButton.icon(
                  onPressed: onCreateTap,
                  icon: const Icon(Icons.add),
                  label: const Text('إنشاء خزينة'),
                ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _ErrorView
// ═══════════════════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'خطأ في تحميل الخزائن',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
