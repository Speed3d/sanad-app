// ─────────────────────────────────────────────────────────────────────────────
// dashboard_charts.dart — الرسوم البيانية التفاعلية للوحة التحكم (Fintech Charts)
//
// تعليقات توضيحية بالعربية:
// هذا الملف يوفر مكون الرسوم البيانية التفاعلية المتقدم لـ Dashboard:
//   1. LineChart — مخطط اتجاه السيولة المنساب (آخر 7 أيام)
//   2. PieChart  — الرسم البياني الدائري لتوزيع القبض والصرف
//   3. BarChart  — الرسم البياني الشريط لمقارنة أرصدة الخزائن المختلفة
// ─────────────────────────────────────────────────────────────────────────────

import '../../../core/theme/app_theme_extension.dart';
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

  /// العملة المعروضة — الدينار افتراضاً (الدفعة ج — بلاغ المالك 2026-08-30)
  ///
  /// 🔑 **لماذا مبدّل لا خطّان في مخطّط واحد؟**
  ///   لأن العملتين لا تُجمعان ولا تُقارنان: ٥٠٠ دولار و٥٠٠٬٠٠٠ دينار على
  ///   محور واحد تجعل إحداهما خطّاً مسطّحاً على الصفر، ورسمُهما بمقياسين
  ///   مختلفين يُوهم بمقارنةٍ بين رقمين لا يُقارنان. والقاعدة نفسها التي
  ///   يحرسها `expense_reports_test`: **متجاورتان لا مجموعتان**.
  bool _showUsd = false;

  /// عناوين المخطّطات — العنوان يتبع المعروض
  ///
  /// كان الرأس يكتب «اتجاه السيولة» **دائماً** ولو كان المعروض أرصدة
  /// الخزائن، فيقرأ المالك عنواناً لا يصف ما تحته.
  static const _titles = [
    'اتجاه السيولة — آخر 7 أيام',
    'الحركة اليومية — قبض وصرف',
    'أرصدة الخزائن',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // هل في البيانات دولارٌ أصلاً؟ — المبدّل لا يظهر إلا حين يوجد ما يُعرَض
    //
    // ⚠️ المزوّدان مُراقَبان في المخطّطات نفسها، فمراقبتهما هنا **قراءة
    //   ثانية للمخزَّن لا استعلام إضافي** (Riverpod يشارك النتيجة).
    final weekly = ref.watch(weeklyLiquidityProvider).valueOrNull;
    final balances = ref.watch(treasuryBalancesProvider).valueOrNull;
    final hasUsd = (weekly?.any((p) => p.hasUsd) ?? false) ||
        (balances?.any((b) => b.balanceUsd.abs() > 0.001) ?? false);

    // اختفاء البيانات بعد اختيار الدولار يُعيدنا إلى الدينار: مبدّلٌ مخفيّ
    // وعملةٌ محفوظة يُنتجان مخطّطاً فارغاً بلا تفسير
    final showUsd = _showUsd && hasUsd;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── رأس الكارت ومبدّل الرسوم البيانية ───────────────────────
          //
          // ⚠️ **`Wrap` لا `Row`**: العنوان ومفاتيحُ المخطّطات الثلاثة كانت
          //   تتجاوز عرض النافذة الضيّقة أصلاً، ومبدّل العملة زادها. و`Row`
          //   لا تنكسر — ترمي `RenderFlex overflowed` وتُظهر الشريط الأصفر
          //   المشطوب. `Wrap` تُنزل المفاتيح سطراً وتبقى الشاشة سليمة.
          //   يحرسه `dashboard_currency_test`.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.colors.surface2,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.show_chart_rounded,
                      color: context.colors.gold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _titles[_activeChartIndex],
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: context.colors.text,
                    ),
                  ),
                ],
              ),

              // مفاتيح التبديل (Segmented Controls)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // مبدّل العملة — قبل مفاتيح المخطّطات ليُقرأ أولاً
                  if (hasUsd) ...[
                    _buildCurrencyButton(false, 'د.ع', showUsd, isDark),
                    const SizedBox(width: 4),
                    _buildCurrencyButton(true, '\$', showUsd, isDark),
                    const SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 18,
                      color: context.colors.border,
                    ),
                    const SizedBox(width: 10),
                  ],
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
                ? _LiquiditySplineChart(showUsd: showUsd)
                : _activeChartIndex == 1
                    ? _DailyVouchersPieChart(showUsd: showUsd)
                    : _TreasuryBalancesBarChart(showUsd: showUsd),
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
                  ? (context.colors.gold)
                  : (context.colors.subtext),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (context.colors.gold)
                    : (context.colors.subtext),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// مفتاح عملة — بالشكل نفسه لمفاتيح المخطّطات فلا يبدو عنصراً غريباً
  Widget _buildCurrencyButton(
      bool usd, String label, bool showUsd, bool isDark) {
    final isSelected = showUsd == usd;
    return InkWell(
      onTap: () => setState(() => _showUsd = usd),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? const Color(0xFFE0BC66).withValues(alpha: 0.18)
                  : AppColors.navy.withValues(alpha: 0.10))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? context.colors.gold : context.colors.subtext,
          ),
        ),
      ),
    );
  }
}

// ── 1. مخطط اتجاه السيولة المنساب (LineChart Spline Area) ─────────────────────
//
// ✅ بيانات حقيقية (تصحيح تدقيق 2026-08-06): كان يعرض أرقاماً ثابتة مُلفَّقة.
//    الآن يقرأ إجمالي القبض/الصرف لكل يوم من الأيام السبعة الأخيرة فعلياً.
class _LiquiditySplineChart extends ConsumerWidget {
  const _LiquiditySplineChart({required this.showUsd});

  /// العملة المعروضة — يمرّرها القسم لا الودجت
  final bool showUsd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weeklyAsync = ref.watch(weeklyLiquidityProvider);

    return weeklyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('تعذّر تحميل بيانات السيولة',
            style: theme.textTheme.bodySmall),
      ),
      data: (points) {
        // مقياس المحور الرأسي بحسب العملة: الدينار بالملايين والدولار
        // بالآلاف. مقياسٌ واحد للاثنين يجعل خطّ الدولار مسطّحاً على الصفر.
        final scale = showUsd ? 1000.0 : 1000000.0;
        final kabdSpots = [
          for (var i = 0; i < points.length; i++)
            FlSpot(i.toDouble(),
                (showUsd ? points[i].kabdUsd : points[i].kabd) / scale),
        ];
        final sarfSpots = [
          for (var i = 0; i < points.length; i++)
            FlSpot(i.toDouble(),
                (showUsd ? points[i].sarfUsd : points[i].sarf) / scale),
        ];

        // أقصى قيمة على المحور الرأسي (مع هامش 20%) — 1 كحد أدنى لتجنب مخطط مسطّح
        final maxVal = [
          ...kabdSpots.map((s) => s.y),
          ...sarfSpots.map((s) => s.y),
          1.0,
        ].reduce((a, b) => a > b ? a : b);
        final maxY = maxVal * 1.2;

        // تسميات أيام الأسبوع من التواريخ الفعلية
        const weekdayNames = [
          'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',
          'الجمعة', 'السبت', 'الأحد',
        ];
        final dayLabels = [
          for (final p in points) weekdayNames[p.date.weekday - 1],
        ];

        return _buildChart(
          context,
          isDark,
          kabdSpots,
          sarfSpots,
          dayLabels,
          maxY,
          showUsd ? '\$' : 'د.ع',
        );
      },
    );
  }

  Widget _buildChart(
    BuildContext context,
    bool isDark,
    List<FlSpot> kabdSpots,
    List<FlSpot> sarfSpots,
    List<String> dayLabels,
    double maxY,
    String currencyLabel,
  ) {
    return Column(
      children: [
        // مفتاح الرسم (Legend) — العملة مكتوبة فيه لا مفهومة ضمناً
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildLegendDot(context, 'قبض ($currencyLabel)', Colors.green.shade600),
            const SizedBox(width: 16),
            _buildLegendDot(context, 'صرف ($currencyLabel)', Colors.red.shade600),
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
                  color: context.colors.border,
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
                              color: context.colors.subtext,
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
              maxX: (dayLabels.length - 1).toDouble().clamp(1, 6),
              minY: 0,
              maxY: maxY,
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

  /// نقطة في مفتاح المخطط
  ///
  /// تستقبل [context] لا `bool isDark` بعد اعتماد `AppPalette`
  /// (المرحلة د) — اللون يُقرأ من الثيم لا يُحسَب بشرط.
  Widget _buildLegendDot(BuildContext context, String label, Color color) {
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
            color: context.colors.subtext,
          ),
        ),
      ],
    );
  }
}

// ── 2. الرسم البياني الدائري للحركة اليومية (قبض / صرف) ──────────────────────
class _DailyVouchersPieChart extends ConsumerWidget {
  const _DailyVouchersPieChart({required this.showUsd});

  /// العملة المعروضة — يمرّرها القسم لا الودجت
  final bool showUsd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ⚠️ نُطبّع التاريخ إلى يوم بلا وقت — **سبب المؤشّر الذي لا يتوقّف**.
    //
    //   `dailySummaryProvider` عائلي يُفهرَس بمعامله. و`DateTime.now()`
    //   تتغيّر كل ميلي ثانية، فكل إعادة بناء كانت تُنشئ **مزوّداً جديداً
    //   بمفتاح جديد** يبدأ التحميل من الصفر ولا يصل إلى بيانات أبداً.
    //   (بلاغ المالك 2026-08-24)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final summaryAsync = ref.watch(dailySummaryProvider(today));

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('خطأ: $err')),
      data: (summary) {
        final totalKabd = showUsd ? summary.totalKabdUsd : summary.totalKabd;
        final totalSarf = showUsd ? summary.totalSarfUsd : summary.totalSarf;
        final total = totalKabd + totalSarf;

        if (total == 0) {
          return Center(
            child: Text(
              showUsd
                  ? 'لا حركات بالدولار اليوم'
                  : 'لا توجد حركات مالية مسجّلة اليوم',
              style: TextStyle(
                color: context.colors.subtext,
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
  const _TreasuryBalancesBarChart({required this.showUsd});

  /// العملة المعروضة — يمرّرها القسم لا الودجت
  final bool showUsd;

  /// رصيد الخزينة بالعملة المعروضة — نقطة قراءةٍ **واحدة** يتبعها
  /// الرسمُ وحسابُ أقصى المحور معاً
  ///
  /// ⚠️ كانتا قراءتين مستقلّتين لـ`balanceIqd` (العمود و`_calculateMaxY`)،
  ///   ونسيانُ إحداهما عند إضافة عملةٍ يُنتج أعمدةً تتجاوز سقف المحور فتُقصّ
  ///   بلا رسالة.
  double _value(TreasuryBalanceModel t) =>
      showUsd ? t.balanceUsd.abs() : t.balanceIqd.abs();

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

        // بالدولار تُعرَض الخزائن التي فيها دولار وحدها — خمسة أعمدة
        // صفرية تُوهم بأن الأرصدة صفر لا بأنها بعملة أخرى
        final source = showUsd
            ? balances.where((t) => t.balanceUsd.abs() > 0.001).toList()
            : balances;
        if (source.isEmpty) {
          return const Center(child: Text('لا خزينة برصيد بالدولار'));
        }

        final displayList = source.take(5).toList();

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
                    toY: _value(t),
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
      if (_value(item) > maxVal) {
        maxVal = _value(item);
      }
    }
    return maxVal == 0 ? 100 : maxVal * 1.2;
  }
}
