// ─────────────────────────────────────────────────────────────────────────────
// dashboard_screen.dart — لوحة التحكم الرئيسية
//
// الأقسام:
//   1. رأس اليوم         — تحية + تاريخ
//   2. بطاقة الرصيد الإجمالي — إجمالي جميع الخزائن
//   3. ملخص اليوم         — قبض / صرف / صافي
//   4. الخزائن             — قائمة أفقية قابلة للتمرير
//   5. إحصائيات سريعة     — عدد الموظفين / المقاولين / الشركاء
//   6. اختصارات الإجراءات — روابط سريعة
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat, DateFormat;

import '../../../domain/models/treasury_model.dart';
import '../../providers/contractor_providers.dart';
import '../../providers/employee_providers.dart';
import '../../providers/partner_providers.dart';
import '../../providers/treasury_providers.dart';
import '../../providers/voucher_providers.dart';
import '../../widgets/common/global_search_dialog.dart';
import '../../widgets/common/smart_alert_banner.dart';
import 'dashboard_charts.dart';

// ════════════════════════════════════════════════════════════════════════════
// DashboardScreen — الشاشة الرئيسية
// ════════════════════════════════════════════════════════════════════════════

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'البحث الشامل',
            onPressed: () => showGlobalSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: () {
              ref.invalidate(totalTreasuryBalanceProvider);
              ref.invalidate(dailySummaryProvider(today));
              ref.invalidate(treasuryBalancesProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(totalTreasuryBalanceProvider);
          ref.invalidate(dailySummaryProvider(today));
          ref.invalidate(treasuryBalancesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── رأس اليوم ──────────────────────────────────────────────
            _DayHeader(today: today),
            const SizedBox(height: 12),
            // ── شريط التنبيهات الذكية ───────────────────────────────
            const SmartAlertBanner(),
            const SizedBox(height: 12),
            // ── بطاقة الرصيد الإجمالي ───────────────────────────────
            const _TotalBalanceCard(),
            const SizedBox(height: 12),
            // ── ملخص اليوم ─────────────────────────────────────────
            _DailySummaryCard(date: today),
            const SizedBox(height: 16),
            // ── التحليل البياني التفاعلي ─────────────────────────────
            const DashboardChartsSection(),
            const SizedBox(height: 16),
            // ── الخزائن ────────────────────────────────────────────
            _SectionTitle(
              title: 'الخزائن',
              actionLabel: 'عرض الكل',
              onAction: () => context.go('/treasuries'),
            ),
            const SizedBox(height: 8),
            const _TreasuriesRow(),
            const SizedBox(height: 16),
            // ── إحصائيات سريعة ──────────────────────────────────────
            const _SectionTitle(title: 'إحصائيات سريعة'),
            const SizedBox(height: 8),
            const _QuickStats(),
            const SizedBox(height: 16),
            // ── اختصارات الإجراءات ──────────────────────────────────
            const _SectionTitle(title: 'إجراءات سريعة'),
            const SizedBox(height: 8),
            const _QuickActions(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _DayHeader — رأس اليوم
// ════════════════════════════════════════════════════════════════════════════

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.today});
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = today.hour;
    final greeting = hour < 12
        ? 'صباح الخير'
        : hour < 17
            ? 'مساء الخير'
            : 'مساء النور';
    final dateFmt = DateFormat('EEEE، d MMMM yyyy', 'ar');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateFmt.format(today),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.dashboard_outlined,
            color: theme.colorScheme.onPrimaryContainer,
            size: 28,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _TotalBalanceCard — بطاقة الرصيد الإجمالي
// ════════════════════════════════════════════════════════════════════════════

class _TotalBalanceCard extends ConsumerWidget {
  const _TotalBalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final balanceAsync = ref.watch(totalTreasuryBalanceProvider);
    final fmt = NumberFormat('#,##0.##');

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'إجمالي الأرصدة',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            balanceAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('خطأ: $e'),
              data: (balance) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${fmt.format(balance.totalIqd)} د.ع',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (balance.totalUsd != 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '\$ ${fmt.format(balance.totalUsd)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _DailySummaryCard — ملخص اليوم
// ════════════════════════════════════════════════════════════════════════════

class _DailySummaryCard extends ConsumerWidget {
  const _DailySummaryCard({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dailySummaryProvider(date));
    final fmt = NumberFormat('#,##0.##');

    return summaryAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('خطأ: $e'),
      )),
      data: (summary) {
        final net = summary.totalKabd - summary.totalSarf;
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.arrow_downward_rounded,
                label: 'قبض اليوم',
                value: fmt.format(summary.totalKabd),
                suffix: 'د.ع',
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.arrow_upward_rounded,
                label: 'صرف اليوم',
                value: fmt.format(summary.totalSarf),
                suffix: 'د.ع',
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: net >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                label: 'الصافي',
                value: '${net >= 0 ? '+' : ''}${fmt.format(net)}',
                suffix: 'د.ع',
                color: net >= 0 ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _TreasuriesRow — قائمة الخزائن الأفقية
// ════════════════════════════════════════════════════════════════════════════

class _TreasuriesRow extends ConsumerWidget {
  const _TreasuriesRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(treasuryBalancesProvider);
    return stream.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('خطأ: $e'),
      data: (balances) {
        if (balances.isEmpty) {
          return const SizedBox(
            height: 80,
            child: Center(child: Text('لا توجد خزائن مسجّلة')),
          );
        }
        return SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: balances.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) =>
                _TreasuryChip(balance: balances[i]),
          ),
        );
      },
    );
  }
}

class _TreasuryChip extends StatelessWidget {
  const _TreasuryChip({required this.balance});
  final TreasuryBalanceModel balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0.##');
    final isPositive = balance.balanceIqd >= 0;
    final Color chipColor = balance.treasuryKind == 'main'
        ? theme.colorScheme.primary
        : balance.treasuryKind == 'contractor'
            ? Colors.indigo
            : Colors.deepPurple;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_outlined,
                size: 16,
                color: chipColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  balance.treasuryName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: chipColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            '${fmt.format(balance.balanceIqd)} د.ع',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${balance.totalVouchers} سند',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _QuickStats — إحصائيات سريعة
// ════════════════════════════════════════════════════════════════════════════

class _QuickStats extends ConsumerWidget {
  const _QuickStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(allEmployeesProvider).valueOrNull?.length ?? 0;
    final contractors =
        ref.watch(allContractorsProvider).valueOrNull?.length ?? 0;
    final partners = ref.watch(allPartnersProvider).valueOrNull?.length ?? 0;

    return Row(
      children: [
        Expanded(
          child: _CountCard(
            icon: Icons.badge_outlined,
            label: 'الموظفون',
            count: employees,
            color: Colors.teal,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CountCard(
            icon: Icons.construction_outlined,
            label: 'المقاولون',
            count: contractors,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CountCard(
            icon: Icons.handshake_outlined,
            label: 'الشركاء',
            count: partners,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: color.withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _QuickActions — اختصارات الإجراءات
// ════════════════════════════════════════════════════════════════════════════

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.add_card_outlined,
        label: 'سند صرف',
        color: Colors.red.shade600,
        route: '/vouchers/sarf',
      ),
      _ActionItem(
        icon: Icons.receipt_outlined,
        label: 'سند قبض',
        color: Colors.green.shade700,
        route: '/vouchers/kabd',
      ),
      _ActionItem(
        icon: Icons.sync_alt,
        label: 'تحويل',
        color: Colors.indigo.shade600,
        route: '/vouchers/transfer',
      ),
      _ActionItem(
        icon: Icons.people_alt_outlined,
        label: 'الموظفون',
        color: Colors.teal,
        route: '/employees',
      ),
      _ActionItem(
        icon: Icons.bar_chart_outlined,
        label: 'التقارير',
        color: Colors.blue.shade700,
        route: '/reports',
      ),
      _ActionItem(
        icon: Icons.upload_file_outlined,
        label: 'استيراد Excel',
        color: Colors.orange.shade700,
        route: '/reports/excel-import',
      ),
      _ActionItem(
        icon: Icons.backup_outlined,
        label: 'النسخ الاحتياطي',
        color: Colors.purple.shade600,
        route: '/backup',
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.1,
      children: actions
          .map((a) => _ActionTile(action: a))
          .toList(),
    );
  }
}

class _ActionItem {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
  final IconData icon;
  final String label;
  final Color color;
  final String route;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});
  final _ActionItem action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go(action.route),
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: action.color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.color, size: 28),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets مساعدة
// ════════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.suffix,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final String suffix;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: color.withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              suffix,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
