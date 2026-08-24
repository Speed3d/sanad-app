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

import '../../../core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../core/constants/app_routes.dart';
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
    // يوم بلا وقت — `DateTime.now()` كمفتاح عائلي تُنشئ مزوّداً جديداً في
    // كل إعادة بناء فلا ينتهي التحميل أبداً (راجع dashboard_charts.dart)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(totalTreasuryBalanceProvider);
          ref.invalidate(dailySummaryProvider(today));
          ref.invalidate(weeklyLiquidityProvider);
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

            // ── 2. بطاقات الخزائن القيادية ─────────────────────────────────
            const _HeroTreasuryCards(),
            const SizedBox(height: 14),

            // ── 3. ملخص الإحصائيات الثلاثي (قبض / صرف / صافي) ──────────────
            _DailyStatCardsRow(date: today),
            const SizedBox(height: 20),

            // ── 4. مخطط اتجاه السيولة المنساب ──────────────────────────────
            const DashboardChartsSection(),
            const SizedBox(height: 20),

            // ملاحظة (2026-08-24): حُذف قسم «الخزائن» السفلي — صارت بطاقات
            // الخزائن القيادية في الأعلى تعرض الشيء نفسه بتصميم أوضح،
            // فكان القسمان يكرّران بعضهما بتصميمين مختلفين (قرار المالك).
            // زر «عرض الكل» انتقل إلى قسم الإحصائيات أدناه.

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

// ── 2. بطاقات الخزائن القيادية (Hero Treasury Cards) ─────────────────────────
//
// **بدل بطاقة «إجمالي الأرصدة» الواحدة** (طلب المالك 2026-08-24):
//   الرقم المجمَّع لا يجيب عن السؤال الذي يُطرَح فعلاً كل صباح — «كم في
//   خزنة البصرة؟» — بل يُخفيه. خزنتان إحداهما بعشرة ملايين والأخرى بعجز
//   نصف مليون تظهران رقماً واحداً يبدو صحّياً.
//
// كل خزينة بطاقة بتصميم البطاقة القيادية نفسه، تُمرَّر أفقياً. والخزينة
// بالعجز تُبرَز بلون تحذيري وتسمية صريحة.

class _HeroTreasuryCards extends ConsumerWidget {
  const _HeroTreasuryCards();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(treasuryBalancesProvider);

    return balancesAsync.when(
      loading: () => const SizedBox(
        height: 168,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 168,
        child: Center(child: Text('تعذّر تحميل الخزائن: $e')),
      ),
      data: (list) {
        final active = list.where((t) => t.isActive).toList();
        if (active.isEmpty) {
          return _HeroEmptyCard(
            onTap: () => context.go(AppRoutes.treasury),
          );
        }
        // خزينة واحدة لا تحتاج تمريراً أفقياً — تأخذ العرض كاملاً
        if (active.length == 1) {
          return _HeroTreasuryCard(balance: active.first, fullWidth: true);
        }
        return SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: active.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) =>
                _HeroTreasuryCard(balance: active[i]),
          ),
        );
      },
    );
  }
}

/// بطاقة خزينة واحدة بتصميم البطاقة القيادية
class _HeroTreasuryCard extends StatelessWidget {
  const _HeroTreasuryCard({required this.balance, this.fullWidth = false});

  final TreasuryBalanceModel balance;
  final bool fullWidth;

  /// تسمية عربية لنوع الخزينة
  String get _kindLabel => switch (balance.treasuryKind) {
        'contractor' => 'خزنة مقاول',
        'partner' => 'خزنة شريك',
        _ => 'خزنة رئيسية',
      };

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    // العجز يعني أن الشركة مدينة — يُبرَز ولا يُترك رقماً سالباً عابراً
    final inDeficit = balance.balanceIqd < -0.001;
    final accent = inDeficit ? const Color(0xFFF87171) : const Color(0xFFE0BC66);

    final card = Container(
      width: fullWidth ? double.infinity : 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF18233A)],
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
          // الهالة الضوئية — تتبع لون الحالة
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
                    accent.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      inDeficit
                          ? Icons.trending_down
                          : Icons.account_balance_wallet_outlined,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        balance.treasuryName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            // القيمة المطلقة مع تسمية «عجز» صريحة أوضح من
                            // إشارة سالبة قد تُقرأ خطأً في لمحة
                            text: fmt.format(balance.balanceIqd.abs()),
                            style: TextStyle(
                              fontSize: fullWidth ? 36 : 28,
                              fontWeight: FontWeight.w800,
                              color: inDeficit ? accent : Colors.white,
                              letterSpacing: -0.5,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: 'د.ع',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          inDeficit ? 'عجز · $_kindLabel' : _kindLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: inDeficit
                                ? accent
                                : Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        // الدولار يظهر فقط حين يوجد — لا صفر بلا معنى
                        if (balance.balanceUsd.abs() > 0.001) ...[
                          const SizedBox(width: 10),
                          Text(
                            '\$ ${NumberFormat('#,##0.00').format(balance.balanceUsd)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE0BC66),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // النقر يفتح شاشة الخزائن — بديل زرّ «عرض الكل» الذي حُذف مع القسم
    // السفلي المكرَّر، فيبقى الطريق إلى التفاصيل قائماً
    final tappable = InkWell(
      onTap: () => context.go(AppRoutes.treasury),
      borderRadius: BorderRadius.circular(20),
      child: card,
    );
    return fullWidth ? tappable : SizedBox(height: 168, child: tappable);
  }
}

/// بطاقة بديلة حين لا توجد خزائن بعد
class _HeroEmptyCard extends StatelessWidget {
  const _HeroEmptyCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 168,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF18233A)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_business_outlined,
                size: 34, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            Text(
              'لا توجد خزائن بعد — اضغط لإنشاء أول خزينة',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── 3. كروت الملخصات الثلاثية (Stat Cards) ───────────────────────────────────

class _DailyStatCardsRow extends ConsumerWidget {
  final DateTime date;
  const _DailyStatCardsRow({required this.date});

  /// نص التغيّر مقارنةً بأمس — حقيقي، مبني على البيانات الفعلية
  ///
  /// [today]     — قيمة اليوم
  /// [yesterday] — قيمة أمس (null إذا لم تُحمَّل بعد)
  static String _changeSubtitle(double today, double? yesterday) {
    if (yesterday == null) return 'مقارنةً بأمس';
    if (yesterday == 0) {
      return today > 0 ? 'جديد اليوم' : 'لا نشاط';
    }
    final pct = ((today - yesterday) / yesterday) * 100;
    final rounded = pct.round();
    if (rounded == 0) return 'كما أمس';
    final sign = rounded > 0 ? '+' : '';
    return '$sign$rounded% عن أمس';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dailySummaryProvider(date));
    // ملخص أمس — لحساب نسبة التغيّر الحقيقية بدل الأرقام الملفّقة
    final yesterday = DateTime(date.year, date.month, date.day)
        .subtract(const Duration(days: 1));
    final yesterdayAsync = ref.watch(dailySummaryProvider(yesterday));
    final fmt = NumberFormat('#,##0');

    return summaryAsync.when(
      loading: () => const SizedBox(
        height: 110,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('خطأ: $e'),
      data: (summary) {
        final net = summary.totalKabd - summary.totalSarf;
        final prev = yesterdayAsync.valueOrNull;
        final kabdSub = _changeSubtitle(summary.totalKabd, prev?.totalKabd);
        final sarfSub = _changeSubtitle(summary.totalSarf, prev?.totalSarf);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            if (isNarrow) {
              return Column(
                children: [
                  _StatTile(
                    label: 'قبض اليوم',
                    value: fmt.format(summary.totalKabd),
                    subtitle: kabdSub,
                    icon: Icons.south_west_rounded,
                    chipBg: Colors.green.withValues(alpha: 0.12),
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(height: 10),
                  _StatTile(
                    label: 'صرف اليوم',
                    value: fmt.format(summary.totalSarf),
                    subtitle: sarfSub,
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
                    subtitle: kabdSub,
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
                    subtitle: sarfSub,
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.border,
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
                  color: context.colors.subtext,
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
              color: context.colors.subtext,
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
    // قيم افتراضية 0 عند عدم التحميل (كانت 14/9/5 ملفّقة تُعرَض قبل التحميل)
    final employees = ref.watch(allEmployeesProvider).valueOrNull?.length ?? 0;
    final contractors = ref.watch(allContractorsProvider).valueOrNull?.length ?? 0;
    final partners = ref.watch(allPartnersProvider).valueOrNull?.length ?? 0;

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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.colors.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: context.colors.gold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.colors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.colors.subtext,
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
        chipBg: context.colors.surface2,
        color: context.colors.gold,
        route: AppRoutes.reports,
      ),
      _ActionTileData(
        label: 'استيراد إكسل',
        icon: Icons.work_outline_rounded,
        chipBg: context.colors.surface2,
        color: context.colors.gold,
        route: AppRoutes.excelImport,
      ),
      _ActionTileData(
        label: 'النسخ الاحتياطي',
        icon: Icons.schedule_rounded,
        chipBg: context.colors.surface2,
        color: context.colors.gold,
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

    return InkWell(
      onTap: () => context.go(data.route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.border,
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
                color: context.colors.text,
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

  const _SectionHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.colors.text,
          ),
        ),
      ],
    );
  }
}
