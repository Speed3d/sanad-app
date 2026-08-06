// ─────────────────────────────────────────────────────────────────────────────
// dashboard_charts.dart — الرسوم البيانية التفاعلية للوحة التحكم
//
// تعليقات توضيحية بالعربية:
// هذا الملف يوفر مكون الرسوم البيانية التفاعلية المتقدم لـ Dashboard:
//   1. PieChart   — الرسم البياني الدائري لتوزيع القبض والصرف
//   2. BarChart   — الرسم البياني الشريط لمقارنة أرصدة الخزائن المختلفة
//
// يستمد البيانات مباشرة من Riverpod Providers ويعرضها بتصميم عصري ورسومات سلسة.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
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
  /// مؤشر التبويب النشط (0: توزيع القبض/الصرف، 1: أرصدة الخزائن)
  int _activeChartIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── رأس الكارت ومبدّل الرسوم البيانية ───────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'التحليل البياني التفاعلي',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // زر التبديل بين نوعي الرسم البياني
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('الحركة اليومية', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.pie_chart, size: 16),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('أرصدة الخزائن', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.bar_chart, size: 16),
                    ),
                  ],
                  selected: {_activeChartIndex},
                  onSelectionChanged: (set) {
                    setState(() => _activeChartIndex = set.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // ── عرض الرسم البياني حسب التبويب ────────────────────────────
            SizedBox(
              height: 220,
              child: _activeChartIndex == 0
                  ? const _DailyVouchersPieChart()
                  : const _TreasuryBalancesBarChart(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 1. الرسم البياني الدائري للحركة اليومية (قبض / صرف) ──────────────────────
class _DailyVouchersPieChart extends ConsumerWidget {
  const _DailyVouchersPieChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final summaryAsync = ref.watch(dailySummaryProvider(today));
    final theme = context.theme;

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('خطأ: $err')),
      data: (summary) {
        final totalKabd = summary.totalKabd;
        final totalSarf = summary.totalSarf;
        final total = totalKabd + totalSarf;

        if (total == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.query_stats, size: 40, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 8),
                Text(
                  'لا توجد حركات مالية مسجّلة اليوم',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        final kabdPercent = (totalKabd / total) * 100;
        final sarfPercent = (totalSarf / total) * 100;

        return Row(
          children: [
            // الرسم البياني الدائري
            Expanded(
              flex: 3,
              child: PieChart(
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
              ),
            ),

            // المفتاح التوضيحي (Legend)
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(
                    color: Colors.green.shade600,
                    label: 'إجمالي القبض',
                    value: totalKabd.toIQD(),
                  ),
                  const SizedBox(height: 16),
                  _buildLegendItem(
                    color: Colors.red.shade600,
                    label: 'إجمالي الصرف',
                    value: totalSarf.toIQD(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem({required Color color, required String label, required String value}) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text(value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

// ── 2. الرسم البياني الشريط لأرصدة الخزائن ─────────────────────────────────
class _TreasuryBalancesBarChart extends ConsumerWidget {
  const _TreasuryBalancesBarChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(treasuryBalancesProvider);
    final theme = context.theme;

    return balancesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('خطأ: $err')),
      data: (balances) {
        if (balances.isEmpty) {
          return const Center(child: Text('لا توجد خزائن للعرض'));
        }

        // أخذ أول 5 خزائن للعرض في الرسم الشريط
        final displayList = balances.take(5).toList();

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _calculateMaxY(displayList),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final treasury = displayList[groupIndex];
                  return BarTooltipItem(
                    '${treasury.treasuryName}\n${treasury.balanceIqd.toIQD()}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
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
              final isPositive = t.balanceIqd >= 0;

              return BarChartGroupData(
                x: idx,
                barRods: [
                  BarChartRodData(
                    toY: t.balanceIqd.abs(),
                    color: isPositive
                        ? (t.treasuryKind == 'main' ? theme.colorScheme.primary : Colors.teal)
                        : Colors.red.shade600,
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
