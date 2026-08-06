// ─────────────────────────────────────────────────────────────────────────────
// dashboard_charts.dart — الرسوم البيانية التفاعلية للوحة التحكم (Fintech Charts)
//
// تعليقات توضيحية بالعربية:
// هذا الملف يوفر مكون الرسوم البيانية التفاعلية المتقدم لـ Dashboard:
//   1. LineChart — مخطط اتجاه السيولة المنساب (آخر 7 أيام)
//   2. PieChart  — الرسم البياني الدائري لتوزيع القبض والصرف
//   3. BarChart  — الرسم البياني الشريط لمقارنة أرصدة الخزائن المختلفة
// ─────────────────────────────────────────────────────────────────────────────

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/treasury_model.dart';
import '../../providers/treasury_providers.dart';
import '../../providers/voucher_providers.dart';

/// ويدجت الرسوم البيانية التفاعلية في لوحة التحكم
class DashboardChartsSection extends ConsumerStatefulWidget {
  const DashboardChartsSection({super.key});

  @override
  ConsumerState<DashboardChartsSection> createState() => _DashboardChartsSectionState();
}

class _DashboardChartsSectionState extends ConsumerState<DashboardChartsSection> {
  /// مؤشر التبويب النشط (0: اتجاه السيولة، 1: التوزيع الدائري، 2: أرصدة الخزائن)
  int _activeChartIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── رأس الكارت ومبدّل الرسوم البيانية ───────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.show_chart_rounded,
                      color: isDark ? const Color(0xFFE0BC66) : AppColors.navy,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'اتجاه السيولة — آخر 7 أيام',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                ],
              ),

              // مفاتيح التبديل (Segmented Controls)
              Row(
                children: [
                  _buildTabButton(0, 'اتجاه السيولة', Icons.show_chart_rounded, isDark),
                  const SizedBox(width: 4),
                  _buildTabButton(1, 'الحركة', Icons.pie_chart_outline_rounded, isDark),
                  const SizedBox(width: 4),
                  _buildTabButton(2, 'الخزائن', Icons.bar_chart_rounded, isDark),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── عرض الرسم البياني ─────────────────────────────────────────
          SizedBox(
            height: 220,
            child: _activeChartIndex == 0
                ? const _LiquiditySplineChart()
                : _activeChartIndex == 1
                    ? const _DailyVouchersPieChart()
                    : const _TreasuryBalancesBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon, bool isDark) {
    final isSelected = _activeChartIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeChartIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFFE0BC66).withValues(alpha: 0.18) : AppColors.navy.withValues(alpha: 0.10))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? (isDark ? const Color(0xFFE0BC66) : AppColors.navy)
                  : (isDark ? AppColors.subtextDark : AppColors.subtextLight),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? const Color(0xFFE0BC66) : AppColors.navy)
                    : (isDark ? AppColors.subtextDark : AppColors.subtextLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 1. مخطط اتجاه السيولة المنساب (LineChart Spline Area) ─────────────────────
class _LiquiditySplineChart extends StatelessWidget {
  const _LiquiditySplineChart();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final kabdSpots = const [
      FlSpot(0, 2.1),
      FlSpot(1, 3.5),
      FlSpot(2, 2.8),
      FlSpot(3, 5.2),
      FlSpot(4, 4.1),
      FlSpot(5, 6.25),
      FlSpot(6, 5.8),
    ];

    final sarfSpots = const [
      FlSpot(0, 1.2),
      FlSpot(1, 2.1),
      FlSpot(2, 1.9),
      FlSpot(3, 3.8),
      FlSpot(4, 3.0),
      FlSpot(5, 4.18),
      FlSpot(6, 3.5),
    ];

    const dayLabels = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

    return Column(
      children: [
        // مفتاح الرسم (Legend)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildLegendDot('قبض', Colors.green.shade600, isDark),
            const SizedBox(width: 16),
            _buildLegendDot('صرف', Colors.red.shade600, isDark),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (val) => FlLine(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  strokeWidth: 0.8,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < dayLabels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dayLabels[idx],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: 7,
              lineBarsData: [
                // خط القبض (Green Spline)
                LineChartBarData(
                  spots: kabdSpots,
                  isCurved: true,
                  barWidth: 3,
                  color: Colors.green.shade600,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.green.shade600.withValues(alpha: 0.30),
                        Colors.green.shade600.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // خط الصرف (Red Spline)
                LineChartBarData(
                  spots: sarfSpots,
                  isCurved: true,
                  barWidth: 2.5,
                  color: Colors.red.shade600,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.red.shade600.withValues(alpha: 0.20),
                        Colors.red.shade600.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
          ),
        ),
      ],
    );
  }
}

// ── 2. الرسم البياني الدائري للحركة اليومية (قبض / صرف) ──────────────────────
class _DailyVouchersPieChart extends ConsumerWidget {
  const _DailyVouchersPieChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final summaryAsync = ref.watch(dailySummaryProvider(today));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('خطأ: $err')),
      data: (summary) {
        final totalKabd = summary.totalKabd;
        final totalSarf = summary.totalSarf;
        final total = totalKabd + totalSarf;

        if (total == 0) {
          return Center(
            child: Text(
              'لا توجد حركات مالية مسجّلة اليوم',
              style: TextStyle(
                color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                fontSize: 13,
              ),
            ),
          );
        }

        final kabdPercent = (totalKabd / total) * 100;
        final sarfPercent = (totalSarf / total) * 100;

        return PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 40,
            sections: [
              PieChartSectionData(
                color: Colors.green.shade600,
                value: totalKabd,
                title: '${kabdPercent.toStringAsFixed(0)}%',
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              PieChartSectionData(
                color: Colors.red.shade600,
                value: totalSarf,
                title: '${sarfPercent.toStringAsFixed(0)}%',
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── 3. الرسم البياني الشريط لأرصدة الخزائن ─────────────────────────────────
class _TreasuryBalancesBarChart extends ConsumerWidget {
  const _TreasuryBalancesBarChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(treasuryBalancesProvider);

    return balancesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('خطأ: $err')),
      data: (balances) {
        if (balances.isEmpty) {
          return const Center(child: Text('لا توجد خزائن للعرض'));
        }

        final displayList = balances.take(5).toList();

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _calculateMaxY(displayList),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < displayList.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          displayList[index].treasuryName,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: displayList.asMap().entries.map((entry) {
              final idx = entry.key;
              final t = entry.value;

              return BarChartGroupData(
                x: idx,
                barRods: [
                  BarChartRodData(
                    toY: t.balanceIqd.abs(),
                    color: const Color(0xFFE0BC66),
                    width: 22,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  double _calculateMaxY(List<TreasuryBalanceModel> list) {
    if (list.isEmpty) return 100;
    double maxVal = 0;
    for (final item in list) {
      if (item.balanceIqd.abs() > maxVal) {
        maxVal = item.balanceIqd.abs();
      }
    }
    return maxVal == 0 ? 100 : maxVal * 1.2;
  }
}
