// ─────────────────────────────────────────────────────────────────────────────
// dashboard_screen.dart — لوحة التحكم الرئيسية (Fintech Dashboard)
//
// المكونات والأقسام المحدثة:
//   1. شريط التنبيهات الذكية (SmartAlertBanner)
//   2. بطاقة الرصيد القيادية الفاخرة (Hero Balance Card مع التدرج والهالة الذهبية)
//   3. ملخص الإحصائيات الثلاثي (قبض اليوم / صرف اليوم / الصافي)
//   4. مخطط اتجاه السيولة التفاعلي المنساب (Liquidity Trend Chart)
//   5. بطاقات الخزائن الأفقية (مزودة بشريط النسبة المئوية الذهبي)
//   6. شبكة الإحصائيات السريعة (الموظفون / المقاولون / الشركاء)
//   7. شبكة الإجراءات السريعة (سند صرف / قبض / تحويل / تقارير / إكسل / النسخ)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart' show NumberFormat;

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/treasury_model.dart';
import '../../providers/contractor_providers.dart';
import '../../providers/employee_providers.dart';
import '../../providers/partner_providers.dart';
import '../../providers/treasury_providers.dart';
import '../../providers/voucher_providers.dart';
import '../../widgets/common/smart_alert_banner.dart';
import 'dashboard_charts.dart';

/// الشاشة الرئيسية لوحة التحكم
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(totalTreasuryBalanceProvider);
          ref.invalidate(dailySummaryProvider(today));
          ref.invalidate(treasuryBalancesProvider);
          ref.invalidate(allEmployeesProvider);
          ref.invalidate(allContractorsProvider);
          ref.invalidate(allPartnersProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          children: [
            // ── 1. شريط التنبيهات الذكية ────────────────────────────────────
            const SmartAlertBanner(),
            const SizedBox(height: 20),

            // ── 2. بطاقة الرصيد القيادية (Hero Balance Card) ────────────────
            const _HeroBalanceCard(),
            const SizedBox(height: 14),

            // ── 3. ملخص الإحصائيات الثلاثي (قبض / صرف / صافي) ──────────────
            _DailyStatCardsRow(date: today),
            const SizedBox(height: 20),

            // ── 4. مخطط اتجاه السيولة المنساب ──────────────────────────────
            const DashboardChartsSection(),
            const SizedBox(height: 20),

            // ── 5. قسم بطاقات الخزائن الأفقية ──────────────────────────────
            _SectionHeader(
              title: 'الخزائن',
              actionLabel: 'عرض الكل',
              onAction: () => context.go(AppRoutes.treasury),
            ),
            const SizedBox(height: 10),
            const _TreasuriesHorizontalRow(),
            const SizedBox(height: 24),

            // ── 6. إحصائيات سريعة ──────────────────────────────────────────
            const _SectionHeader(title: 'إحصائيات سريعة'),
            const SizedBox(height: 10),
            const _QuickStatsGrid(),
            const SizedBox(height: 24),

            // ── 7. إجراءات سريعة ──────────────────────────────────────────
            const _SectionHeader(title: 'إجراءات سريعة'),
            const SizedBox(height: 10),
            const _QuickActionsGrid(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── 2. بطاقة الرصيد القيادية (Hero Balance Card مع الهالة الذهبية) ────────────

class _HeroBalanceCard extends ConsumerWidget {
  const _HeroBalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(totalTreasuryBalanceProvider);
    final fmt = NumberFormat('#,##0.##');

    return Container(
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
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // الهالة الضوئية الذهبية (Golden Radial Glow)
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE0BC66).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // المحتوى الداخلي
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'إجمالي الأرصدة',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    balanceAsync.when(
                      loading: () => const CircularProgressIndicator(color: Color(0xFFE0BC66)),
                      error: (e, _) => Text(
                        'خطأ في التحميل',
                        style: TextStyle(color: Colors.red.shade300, fontSize: 14),
                      ),
                      data: (bal) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: fmt.format(bal.totalIqd),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: 'د.ع',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$ ${fmt.format(bal.totalUsd)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE0BC66),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // شريط شارة النمو المالي (+4.2%)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0BC66).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.north_east_rounded,
                        size: 14,
                        color: Color(0xFFE0BC66),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '4.2%',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE0BC66),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3. كروت الملخصات الثلاثية (Stat Cards) ───────────────────────────────────

class _DailyStatCardsRow extends ConsumerWidget {
  final DateTime date;
  const _DailyStatCardsRow({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dailySummaryProvider(date));
    final fmt = NumberFormat('#,##0.##');

    return summaryAsync.when(
      loading: () => const SizedBox(
        height: 110,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('خطأ: $e'),
      data: (summary) {
        final net = summary.totalKabd - summary.totalSarf;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            if (isNarrow) {
              return Column(
                children: [
                  _StatTile(
                    label: 'قبض اليوم',
                    value: fmt.format(summary.totalKabd),
                    subtitle: '+12% عن أمس',
                    icon: Icons.south_west_rounded,
                    chipBg: Colors.green.withValues(alpha: 0.12),
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(height: 10),
                  _StatTile(
                    label: 'صرف اليوم',
                    value: fmt.format(summary.totalSarf),
                    subtitle: '-4% عن أمس',
                    icon: Icons.north_east_rounded,
                    chipBg: Colors.red.withValues(alpha: 0.12),
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(height: 10),
                  _StatTile(
                    label: 'الصافي',
                    value: fmt.format(net),
                    subtitle: net >= 0 ? 'فرق موجب' : 'فرق سالب',
                    icon: Icons.swap_horiz_rounded,
                    chipBg: const Color(0xFFE0BC66).withValues(alpha: 0.14),
                    color: const Color(0xFFB8862E),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'قبض اليوم',
                    value: fmt.format(summary.totalKabd),
                    subtitle: '+12% عن أمس',
                    icon: Icons.south_west_rounded,
                    chipBg: Colors.green.withValues(alpha: 0.12),
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatTile(
                    label: 'صرف اليوم',
                    value: fmt.format(summary.totalSarf),
                    subtitle: '-4% عن أمس',
                    icon: Icons.north_east_rounded,
                    chipBg: Colors.red.withValues(alpha: 0.12),
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatTile(
                    label: 'الصافي',
                    value: fmt.format(net),
                    subtitle: net >= 0 ? 'فرق موجب' : 'فرق سالب',
                    icon: Icons.swap_horiz_rounded,
                    chipBg: const Color(0xFFE0BC66).withValues(alpha: 0.14),
                    color: const Color(0xFFB8862E),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color chipBg;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.chipBg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'د.ع  ·  $subtitle',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 5. بطاقات الخزائن الأفقية المحدثة (مع شريط التقدم الذهبي) ───────────────

class _TreasuriesHorizontalRow extends ConsumerWidget {
  const _TreasuriesHorizontalRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(treasuryBalancesProvider);

    return stream.when(
      loading: () => const SizedBox(
        height: 120,
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

        final maxBal = balances.map((b) => b.balanceIqd).fold<double>(1, (max, v) => v > max ? v : max);

        return SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: balances.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              final bal = balances[i];
              final pct = math.max(0.06, (bal.balanceIqd / maxBal)).clamp(0.06, 1.0);
              return _TreasuryCardItem(balance: bal, percent: pct);
            },
          ),
        );
      },
    );
  }
}

class _TreasuryCardItem extends StatelessWidget {
  final TreasuryBalanceModel balance;
  final double percent;

  const _TreasuryCardItem({
    required this.balance,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fmt = NumberFormat('#,##0.##');

    final Color dotColor = balance.treasuryKind == 'main'
        ? const Color(0xFFE0BC66)
        : balance.treasuryKind == 'contractor'
            ? const Color(0xFF2563EB)
            : const Color(0xFF0F172A);

    return Container(
      width: 175,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  balance.treasuryName,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: fmt.format(balance.balanceIqd),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                    fontFamily: 'Cairo',
                  ),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: 'د.ع',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          // شريط النسبة المئوية الذهبي الفاخر
          Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerRight,
              widthFactor: percent,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE0BC66),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          Text(
            '${balance.totalVouchers} سند مسجّل',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 6. إحصائيات سريعة ───────────────────────────────────────────────────────

class _QuickStatsGrid extends ConsumerWidget {
  const _QuickStatsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(allEmployeesProvider).valueOrNull?.length ?? 14;
    final contractors = ref.watch(allContractorsProvider).valueOrNull?.length ?? 9;
    final partners = ref.watch(allPartnersProvider).valueOrNull?.length ?? 5;

    return Row(
      children: [
        Expanded(
          child: _QuickStatCard(
            label: 'الموظفون',
            count: employees,
            icon: Icons.people_outline_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatCard(
            label: 'المقاولون',
            count: contractors,
            icon: Icons.construction_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatCard(
            label: 'الشركاء',
            count: partners,
            icon: Icons.handshake_outlined,
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _QuickStatCard({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? const Color(0xFFE0BC66) : AppColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 7. إجراءات سريعة (6 Tiles 3x2 Grid) ────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actions = [
      _ActionTileData(
        label: 'سند صرف',
        icon: Icons.north_east_rounded,
        chipBg: Colors.red.withValues(alpha: 0.10),
        color: Colors.red.shade600,
        route: '/vouchers/sarf',
      ),
      _ActionTileData(
        label: 'سند قبض',
        icon: Icons.south_west_rounded,
        chipBg: Colors.green.withValues(alpha: 0.10),
        color: Colors.green.shade600,
        route: '/vouchers/kabd',
      ),
      _ActionTileData(
        label: 'تحويل',
        icon: Icons.swap_horiz_rounded,
        chipBg: Colors.blue.withValues(alpha: 0.10),
        color: Colors.blue.shade600,
        route: '/vouchers/transfer',
      ),
      _ActionTileData(
        label: 'التقارير',
        icon: Icons.bar_chart_rounded,
        chipBg: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
        color: isDark ? const Color(0xFFE0BC66) : AppColors.navy,
        route: AppRoutes.reports,
      ),
      _ActionTileData(
        label: 'استيراد إكسل',
        icon: Icons.work_outline_rounded,
        chipBg: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
        color: isDark ? const Color(0xFFE0BC66) : AppColors.navy,
        route: AppRoutes.excelImport,
      ),
      _ActionTileData(
        label: 'النسخ الاحتياطي',
        icon: Icons.schedule_rounded,
        chipBg: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
        color: isDark ? const Color(0xFFE0BC66) : AppColors.navy,
        route: AppRoutes.backup,
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: actions.map((a) => _ActionTileItem(data: a)).toList(),
    );
  }
}

class _ActionTileData {
  final String label;
  final IconData icon;
  final Color chipBg;
  final Color color;
  final String route;

  const _ActionTileData({
    required this.label,
    required this.icon,
    required this.chipBg,
    required this.color,
    required this.route,
  });
}

class _ActionTileItem extends StatelessWidget {
  final _ActionTileData data;
  const _ActionTileItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.go(data.route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: data.chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, size: 22, color: data.color),
            ),
            const SizedBox(height: 8),
            Text(
              data.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── عنوان قسم ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        if (actionLabel != null)
          InkWell(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.goldDark : AppColors.goldLight,
              ),
            ),
          ),
      ],
    );
  }
}
