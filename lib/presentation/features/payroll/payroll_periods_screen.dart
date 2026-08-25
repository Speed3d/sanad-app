// ─────────────────────────────────────────────────────────────────────────────
// payroll_periods_screen.dart — شبكة أشهر الرواتب (Schema v7)
//
// نقطة الدخول لنظام الرواتب: تختار السنة فتظهر أشهرها الاثنا عشر.
//
// **لماذا تظهر الأشهر الاثنا عشر كلها لا المُنشأ منها فقط؟**
//   الشهر الفارغ **معلومة** لا فراغ: «شباط لم يُستورَد بعد» هو بالضبط ما
//   يريد المالك رؤيته آخر الشهر. عرضُ المُنشأ وحده كان يُخفي الغياب —
//   ولا يُكتشَف إلا حين يسأل موظف عن راتبه.
//
// **لماذا لا يوجد كيان «سنة»؟**
//   السنوات تُشتقّ بـ`GROUP BY` على الكشوف. تخزينها يفتح باب سنةٍ فارغة
//   تظهر في القائمة بلا محتوى.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/payroll_calculator.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/payroll_dao.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payroll_providers.dart';
import '../../widgets/common/app_components.dart';
import '../../../domain/models/auth_state.dart';

class PayrollPeriodsScreen extends ConsumerStatefulWidget {
  const PayrollPeriodsScreen({super.key});

  @override
  ConsumerState<PayrollPeriodsScreen> createState() =>
      _PayrollPeriodsScreenState();
}

class _PayrollPeriodsScreenState extends ConsumerState<PayrollPeriodsScreen> {
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final periodsAsync = ref.watch(payrollPeriodsForYearProvider(_year));
    final yearsAsync = ref.watch(payrollYearsProvider);

    final auth = ref.watch(authNotifierProvider);
    final canPrepare = auth is AuthAuthenticated &&
        auth.user.can(AppPermission.preparePayroll);

    return Scaffold(
      backgroundColor: colors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            year: _year,
            years: yearsAsync.valueOrNull ?? const [],
            canImport: canPrepare,
            onYearChanged: (y) => setState(() => _year = y),
          ),
          Expanded(
            child: periodsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('$e', textAlign: TextAlign.center),
                ),
              ),
              data: (periods) => _MonthsGrid(
                year: _year,
                periods: periods,
                canImport: canPrepare,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// الترويسة — اختيار السنة وزرّ الاستيراد
// ═══════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final int year;
  final List<PayrollYearSummary> years;
  final bool canImport;
  final ValueChanged<int> onYearChanged;

  const _Header({
    required this.year,
    required this.years,
    required this.canImport,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final money = NumberFormat('#,##0');

    // السنوات المتاحة = ما فيه كشوف + السنة الحالية دائماً، فلا يجد المالك
    // نفسه بلا خيار في أول استعمال
    final options = <int>{
      ...years.map((y) => y.year),
      DateTime.now().year,
      year,
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    PayrollYearSummary? summary;
    for (final y in years) {
      if (y.year == year) {
        summary = y;
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_rounded, color: colors.gold, size: 26),
          const SizedBox(width: 12),
          Text(
            'كشوف الرواتب',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colors.text,
            ),
          ),
          const SizedBox(width: 24),
          DropdownButton<int>(
            value: year,
            underline: const SizedBox.shrink(),
            items: options
                .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                .toList(),
            onChanged: (v) {
              if (v != null) onYearChanged(v);
            },
          ),
          if (summary != null) ...[
            const SizedBox(width: 20),
            Text(
              '${summary.monthCount} كشفاً · '
              '${money.format(summary.totalIqd)} د.ع',
              style: TextStyle(fontSize: 13, color: colors.subtext),
            ),
          ],
          const Spacer(),
          if (canImport)
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.payrollImport),
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('استيراد ملف رواتب'),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// شبكة الأشهر
// ═══════════════════════════════════════════════════════════════════════════

class _MonthsGrid extends StatelessWidget {
  final int year;
  final List<PayrollPeriod> periods;
  final bool canImport;

  const _MonthsGrid({
    required this.year,
    required this.periods,
    required this.canImport,
  });

  @override
  Widget build(BuildContext context) {
    final byMonth = {for (final p in periods) p.month: p};

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 760
                ? 3
                : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 132,
          ),
          itemCount: 12,
          itemBuilder: (context, i) => _MonthCard(
            year: year,
            month: i + 1,
            period: byMonth[i + 1],
            canImport: canImport,
          ),
        );
      },
    );
  }
}

class _MonthCard extends ConsumerWidget {
  final int year;
  final int month;
  final PayrollPeriod? period;
  final bool canImport;

  const _MonthCard({
    required this.year,
    required this.month,
    required this.period,
    required this.canImport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final p = period;
    final label = PayrollCalculator.arabicMonth(month);

    // ── الشهر الذي لم يُنشأ بعد ─────────────────────────────────────────
    if (p == null) {
      return _CardShell(
        borderColor: colors.border,
        onTap: canImport
            ? () => context.push(AppRoutes.payrollImport)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.subtext,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.remove_circle_outline,
                    size: 16, color: colors.subtext),
                const SizedBox(width: 6),
                Text(
                  'لم يُستورَد بعد',
                  style: TextStyle(fontSize: 12, color: colors.subtext),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ── الشهر المُنشأ ───────────────────────────────────────────────────
    final totalsAsync = ref.watch(payrollTotalsProvider(p.id));
    final isPosted = p.status == PayrollStatusDb.posted;
    final money = NumberFormat('#,##0');

    return _CardShell(
      borderColor: isPosted ? colors.gold : colors.border,
      onTap: () => context.push('${AppRoutes.payroll}/${p.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.text,
                ),
              ),
              const Spacer(),
              AppStatusBadge(
                label: isPosted ? 'مُسدَّد' : 'مسودة',
                color: isPosted ? Colors.green : colors.gold,
              ),
            ],
          ),
          const Spacer(),
          totalsAsync.when(
            loading: () => const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => Text(
              'تعذّر حساب الإجمالي',
              style: TextStyle(fontSize: 12, color: colors.danger),
            ),
            data: (t) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${money.format(t.totalIqd)} د.ع',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${t.entryCount} موظفاً'
                  '${t.paidCount > 0 && !t.isFullyPaid ? ' · ${t.paidCount} مسدَّد' : ''}',
                  style: TextStyle(fontSize: 12, color: colors.subtext),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// إطار البطاقة — يوحّد الحدود والحشو بين الحالتين
class _CardShell extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final VoidCallback? onTap;

  const _CardShell({
    required this.child,
    required this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}
