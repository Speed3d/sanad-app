// ─────────────────────────────────────────────────────────────────────────────
// payroll_report_tab.dart — تقرير الرواتب السنوي (المرحلة ٤)
//
// السؤال الذي يجيب عنه: **كم صرفنا رواتب هذه السنة، وأيّ شهر لم يُسدَّد بعد،
// ومن أي خزينة خرج المال؟**
//
// **لماذا السنة وحدةَ التقرير لا مدى تاريخي حرّ؟** (قرار المالك 2026-08-26)
//   الرواتب شهرية بطبعها، والمدى الحرّ يقطع شهراً في نصفه فيُظهر نصف كشف —
//   رقمٌ لا يقابله شيء في أي مستند. والسنة تطابق وحدة الكشوف والسنة المالية.
//
// **ثلاثة قرارات عرضٍ وأسبابها:**
//   ١. الشهر غير المُنشأ **لا يظهر**، والمُنشأ الفارغ يظهر بصفر — «كشفٌ
//      أُنشئ ولم يُستورَد» معلومة، واختفاؤه يوحي بأنه لم يُنشأ.
//   ٢. توزيع الخزائن **للمسدَّد وحده**: المستحقّ لم يخرج من أي خزينة، ونسبتُه
//      إلى واحدة اختراعُ حركةِ مالٍ لم تقع.
//   ٣. **شريط الرواتب خارج الكشوف**: بقايا ما قبل توحيد الصرف المباشر
//      (2026-08-26). الرواتب الجديدة كلها تنتسب لكشوفها، لكن ما كُتب قبل
//      التوحيد يبقى بلا كشف — ولو اقتصر التقرير على الكشوف لأخفى مالاً خرج
//      فعلاً. الشريط يختفي وحده حين لا يوجد شيء منها.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../core/constants/app_routes.dart';
import '../../../core/services/payroll_calculator.dart';
import '../../../core/services/payroll_print_data.dart';
import '../../../data/database/daos/payroll_dao.dart';
import '../../providers/payroll_providers.dart';
import '../payroll/payroll_print_actions.dart';
import '../../widgets/common/password_confirm_dialog.dart';
import 'report_widgets.dart';

/// تبويب تقرير الرواتب
class PayrollReportTab extends ConsumerStatefulWidget {
  const PayrollReportTab({super.key});

  @override
  ConsumerState<PayrollReportTab> createState() => _PayrollReportTabState();
}

class _PayrollReportTabState extends ConsumerState<PayrollReportTab> {
  /// السنة المعروضة — `null` حتى تصل قائمة السنوات فتُختار أحدثها
  int? _year;

  @override
  Widget build(BuildContext context) {
    final yearsAsync = ref.watch(payrollYearsProvider);

    return yearsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (years) {
        if (years.isEmpty) {
          return const ReportPlaceholder(
            icon: Icons.payments_outlined,
            message: 'لا توجد كشوف رواتب بعد.\n'
                'استورد ملف رواتب شهر من شاشة «الرواتب» ليظهر هنا.',
          );
        }

        // أحدث سنة افتراضياً — وهي ما يسأل عنه المالك عادةً.
        // والاختيار يُسقَط إن اختفت سنته (حُذف آخر كشف فيها)، وإلا مرّرنا
        // قيمةً غير موجودة إلى Dropdown فيرمي استثناءً.
        final available = years.map((y) => y.year).toList();
        final year = available.contains(_year) ? _year! : available.first;

        return Column(
          children: [
            _Filters(
              years: available,
              selected: year,
              onChanged: (y) => setState(() => _year = y),
              onRefresh: () {
                ref.invalidate(payrollYearReportProvider(year));
                ref.invalidate(payrollOutOfSheetProvider(year));
              },
            ),
            Expanded(child: _Results(year: year)),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// الفلاتر
// ═══════════════════════════════════════════════════════════════════════════

class _Filters extends StatelessWidget {
  const _Filters({
    required this.years,
    required this.selected,
    required this.onChanged,
    required this.onRefresh,
  });

  final List<int> years;
  final int selected;
  final ValueChanged<int> onChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text('السنة', style: theme.textTheme.titleSmall),
            const SizedBox(width: 12),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<int>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.event_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final y in years)
                    DropdownMenuItem<int>(value: y, child: Text('$y')),
                ],
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('تحديث'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// النتائج
// ═══════════════════════════════════════════════════════════════════════════

class _Results extends ConsumerWidget {
  const _Results({required this.year});

  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(payrollYearReportProvider(year));
    final outOfSheet = ref.watch(payrollOutOfSheetProvider(year)).valueOrNull;

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (report) {
        if (report.isEmpty) {
          return ReportPlaceholder(
            icon: Icons.event_busy_outlined,
            message: 'لا كشوف رواتب في سنة $year.',
          );
        }

        // ⚠️ **قابل للتمرير كلّه**: اثنا عشر شهراً وقائمةُ خزائن مفتوحة
        //   الطول. عمودٌ بلا تمرير هو بالضبط ما أنتج
        //   `Bottom Overflowed by 1839 pixels` في شاشة الكشف (ع-٢٧)،
        //   ويحرسه هنا اختبار ودجت ببيانات كثيرة لا بسطرين.
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            // 🔴 **شبكة الأمان الأخيرة** (ع-٣٣): سندات رواتب لا يقابلها سطر
            //   حيّ — مالٌ خرج من الخزينة بلا أي سجل يقابله. تظهر أولاً لأن
            //   بقية التقرير **لا يعرف عنها شيئاً**، فيبدو متّزناً وهو ناقص.
            const _OrphanVouchersBanner(),
            // 🔑 **الكاشف المرآة** (ع-٤٠): سطورٌ «مسدَّدة» فقدت سندها —
            //   المال رجع للخزينة والتقارير تقول مصروف. ويظهر أولاً لأن
            //   كل ما تحته يقرأ تلك السطور على أنها مصروفة.
            const _StalePaidBanner(),

            _SummaryCards(report: report),
            if (outOfSheet != null && outOfSheet.count > 0) ...[
              const SizedBox(height: 12),
              _OutOfSheetBanner(
                count: outOfSheet.count,
                totalIqd: outOfSheet.totalIqd,
              ),
            ],
            const SizedBox(height: 16),
            _MonthsTable(report: report),
            if (report.treasuryShares.isNotEmpty) ...[
              const SizedBox(height: 20),
              _TreasuryShares(shares: report.treasuryShares),
            ],
            const SizedBox(height: 20),
            Center(
              child: FilledButton.icon(
                onPressed: () => PayrollPrintActions.printYearReport(
                    context, ref, report),
                icon: const Icon(Icons.print_outlined, size: 18),
                label: Text('طباعة تقرير $year'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.report});

  final PayrollYearReportData report;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0');
    return Row(
      children: [
        Expanded(
          child: ReportSummaryCard(
            label: 'إجمالي رواتب السنة',
            value: '${money.format(report.totalIqd)} د.ع',
            color: Theme.of(context).colorScheme.primary,
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ReportSummaryCard(
            label: 'المسدَّد',
            value: '${money.format(report.paidIqd)} د.ع',
            color: Colors.green.shade700,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ReportSummaryCard(
            label: 'المستحقّ',
            value: '${money.format(report.unpaidIqd)} د.ع',
            color: report.unpaidIqd > 0
                ? Colors.orange.shade800
                : Colors.grey.shade600,
            icon: Icons.pending_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ReportSummaryCard(
            label: 'الكشوف',
            value: '${report.postedMonthCount} من ${report.monthCount} مُسدَّد',
            color: Colors.blueGrey.shade700,
            icon: Icons.receipt_long_outlined,
          ),
        ),
      ],
    );
  }
}

/// شريط الرواتب المصروفة خارج الكشوف
///
/// 🔑 **ليس تحذيراً من خطأ بل إعلانُ نقص في التقرير نفسه**: هذه المبالغ خرجت
///   من الخزائن ولا يضمّها أي كشف، فجدول الأشهر أعلاه **لا يشملها**. إخفاؤها
///   يجعل التقرير يبدو شاملاً وهو ليس كذلك.
///
/// 📌 **ولا تُنتَج سطور جديدة من هذا النوع** منذ توحيد الصرف المباشر داخل
///   الكشوف (2026-08-26). ما يظهر هنا صفوفٌ كُتبت قبل ذلك التاريخ — ويبقى
///   الشريط لأن إخفاءها كان سيُخفي مالاً خرج فعلاً من الخزينة.
class _OutOfSheetBanner extends StatelessWidget {
  const _OutOfSheetBanner({required this.count, required this.totalIqd});

  final int count;
  final double totalIqd;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0');
    final color = Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'في هذه السنة $count راتباً صُرفت خارج الكشوف '
              '(قبل توحيد الصرف المباشر) بمجموع '
              '${money.format(totalIqd)} د.ع — غير محسوبة في الجدول أدناه.',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// جدول الأشهر
// ═══════════════════════════════════════════════════════════════════════════

class _MonthsTable extends StatelessWidget {
  const _MonthsTable({required this.report});

  final PayrollYearReportData report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = NumberFormat('#,##0');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أشهر السنة', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'اضغط أي شهر لفتح كشفه.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            // التمرير الأفقي يحمي الأعمدة على الشاشات الضيّقة بدل أن
            // تنضغط الأرقام أو تُقتطع
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 26,
                headingRowHeight: 38,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 46,
                columns: const [
                  DataColumn(label: Text('الشهر')),
                  DataColumn(label: Text('الموظفون')),
                  DataColumn(label: Text('إجمالي الكشف')),
                  DataColumn(label: Text('المسدَّد')),
                  DataColumn(label: Text('المتبقّي')),
                  DataColumn(label: Text('الحالة')),
                ],
                rows: [
                  for (final m in report.months)
                    DataRow(
                      onSelectChanged: (_) => context
                          .push('${AppRoutes.payroll}/${m.periodId}'),
                      cells: [
                        DataCell(Text(PayrollCalculator.arabicMonth(m.month))),
                        DataCell(Text('${m.employeeCount}')),
                        DataCell(Text(money.format(m.totalIqd))),
                        DataCell(Text(
                          money.format(m.paidIqd),
                          style: TextStyle(color: Colors.green.shade700),
                        )),
                        DataCell(Text(
                          m.unpaidIqd == 0 ? '—' : money.format(m.unpaidIqd),
                          style: TextStyle(
                            color: m.unpaidIqd > 0
                                ? Colors.orange.shade800
                                : null,
                            fontWeight: m.unpaidIqd > 0
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        )),
                        DataCell(_StatusChip(isPosted: m.isPosted)),
                      ],
                    ),
                  // سطر المجموع — من الأشهر نفسها لا باستعلام ثالث
                  DataRow(
                    color: WidgetStatePropertyAll(
                      theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    ),
                    cells: [
                      const DataCell(Text('المجموع',
                          style: TextStyle(fontWeight: FontWeight.w800))),
                      const DataCell(Text('')),
                      DataCell(Text(money.format(report.totalIqd),
                          style:
                              const TextStyle(fontWeight: FontWeight.w800))),
                      DataCell(Text(money.format(report.paidIqd),
                          style:
                              const TextStyle(fontWeight: FontWeight.w800))),
                      DataCell(Text(
                        report.unpaidIqd == 0
                            ? '—'
                            : money.format(report.unpaidIqd),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      )),
                      const DataCell(Text('')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isPosted});

  final bool isPosted;

  @override
  Widget build(BuildContext context) {
    final color = isPosted ? Colors.green.shade700 : Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPosted ? 'مُسدَّد' : 'مسودة',
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// توزيع الخزائن
// ═══════════════════════════════════════════════════════════════════════════

class _TreasuryShares extends StatelessWidget {
  const _TreasuryShares({required this.shares});

  final List<PayrollTreasuryShare> shares;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = NumberFormat('#,##0');
    final total = shares.fold<double>(0, (s, e) => s + e.totalIqd);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('توزيع الرواتب المسدَّدة حسب الخزينة',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'المسدَّد وحده — المستحقّ لم يخرج من أي خزينة بعد.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            for (final s in shares) ...[
              _ShareRow(
                name: s.treasuryName,
                count: s.employeeCount,
                amount: s.totalIqd,
                ratio: total == 0 ? 0 : s.totalIqd / total,
                money: money,
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

/// سطر خزينة بشريط نسبة — نفس مبدأ تقرير «المصروفات حسب البند»:
/// الأرقام وحدها لا تُظهر أن خزينةً تحمل نصف الرواتب، والشريط يُظهره في لمحة.
class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.name,
    required this.count,
    required this.amount,
    required this.ratio,
    required this.money,
  });

  final String name;
  final int count;
  final double amount;
  final double ratio;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$count راتباً',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${money.format(amount)} د.ع',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              child: Text(
                '${(ratio * 100).toStringAsFixed(1)}%',
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor:
                theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// سندات الرواتب اليتيمة (ع-٣٣)
// ═══════════════════════════════════════════════════════════════════════════

/// شريط السندات اليتيمة — يظهر **فقط حين توجد**
///
/// 🔑 **لماذا في التقرير لا في شاشة صيانة مخفيّة؟** لأن التقرير هو ما يفتحه
///   المالك ليطمئنّ إلى أرقامه — وهذه السندات هي بالضبط ما يجعل تلك الأرقام
///   كاذبة. إخفاؤها في شاشة لا يزورها أحد يعني ألّا تُكتشف أبداً.
class _OrphanVouchersBanner extends ConsumerWidget {
  const _OrphanVouchersBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orphans = ref.watch(orphanPayrollVouchersProvider).valueOrNull;
    if (orphans == null || orphans.isEmpty) return const SizedBox.shrink();

    final money = NumberFormat('#,##0');
    final total = orphans.fold<double>(0, (s, o) => s + o.amount);
    final theme = Theme.of(context);

    return Card(
      color: Colors.red.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${orphans.length} سند رواتب بلا سطور تقابلها '
                    '— بمجموع ${money.format(total)} د.ع',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'مالٌ خرج من الخزينة ولا سجل رواتب يقابله — لا يظهر في الجداول '
              'أدناه ولا في بطاقة أي موظف. راجع كلاً منها: احذفه ليرجع المال، '
              'أو أعد بناء كشف شهره إن كان الصرف صحيحاً.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            for (final o in orphans)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'سند #${o.voucherNumber} · ${money.format(o.amount)} د.ع '
                        '· ${o.personName.isEmpty ? '—' : o.personName}'
                        '${o.reason.isEmpty ? '' : ' · ${o.reason}'}'
                        '${o.treasuryName.isEmpty ? '' : ' · ${o.treasuryName}'}'
                        ' · ${DateFormat('yyyy/MM/dd').format(o.voucherDate.toLocal())}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _confirmDeleteOrphan(context, ref, o),
                      icon: const Icon(Icons.undo_rounded, size: 16),
                      label: const Text('حذف وإرجاع المال'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// تأكيد حذف سند يتيم — **بسبب مكتوب** كأي عملية تُعيد مالاً
Future<void> _confirmDeleteOrphan(
  BuildContext context,
  WidgetRef ref,
  OrphanPayrollVoucher orphan,
) async {
  final money = NumberFormat('#,##0');
  var reason = '';

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('حذف سند #${orphan.voucherNumber}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سيرجع ${money.format(orphan.amount)} د.ع إلى '
                '${orphan.treasuryName.isEmpty ? 'الخزينة' : orphan.treasuryName}.\n'
                'تأكّد أولاً أن هذا المال لم يُسلَّم فعلاً — فإن كان سُلِّم، '
                'أعد بناء كشف شهره بدل حذف سنده.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: reason,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'السبب *',
                  hintText: 'مثال: بقي بعد حذف كشف أيلول ولم يُسلَّم',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => reason = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: reason.trim().isEmpty
                ? null
                : () async {
                    Navigator.pop(ctx);
                    // 🔑 تأكيد الهويّة قبل إرجاع مالٍ خرج
                    if (!context.mounted) return;
                    final identityOk = await confirmWithPassword(
                      context,
                      ref,
                      action: 'حذف سند رواتب يتيم #${orphan.voucherNumber}',
                      impact: 'سيرجع ${money.format(orphan.amount)} د.ع '
                          'إلى ${orphan.treasuryName.isEmpty ? 'الخزينة' : orphan.treasuryName}.',
                    );
                    if (!identityOk) return;

                    await ref
                        .read(payrollNotifierProvider.notifier)
                        .deleteOrphanVoucher(
                          voucherId: orphan.voucherId,
                          reason: reason,
                        );
                  },
            child: const Text('حذف وإرجاع المال'),
          ),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// رواتب مسدَّدة بسندٍ محذوف — الكاشف المرآة (ع-٤٠)
// ═══════════════════════════════════════════════════════════════════════════

/// شريط الرواتب العالقة — يظهر **فقط حين توجد**
///
/// 🔴 **الحالة التي يكشفها:** سطر راتب حيّ ومعلَّم «مسدَّد»، وسندُه محذوف.
///   أي أن المال رجع إلى الخزينة بينما الكشف وبطاقة الموظف وكل تقرير تقول
///   «مصروف». وقد وقعت فعلاً حين حذف إلغاءُ سلفةِ موظفٍ سندَ رواتب الشهر
///   كلّه (ع-٤٠).
///
/// 📌 وهو **مرآة كاشف السندات اليتيمة**: ذاك سندٌ بلا سطور، وهذا سطورٌ بلا
///   سند. والاثنان يكشفان **العَرَض** فيلتقطان ما لم يُشخَّص سببه بعد.
class _StalePaidBanner extends ConsumerWidget {
  const _StalePaidBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stale = ref.watch(stalePaidPayrollsProvider).valueOrNull;
    if (stale == null || stale.isEmpty) return const SizedBox.shrink();

    final money = NumberFormat('#,##0');
    final theme = Theme.of(context);

    return Card(
      color: Colors.red.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.report_problem_outlined,
                    color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'رواتب مُعلَّمة «مسدَّدة» وسندها محذوف',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'المال رجع إلى الخزينة، والكشف وبطاقات الموظفين والتقارير تقول '
              '«مصروف». أعِدها مستحقّة ليطابق السجلُّ الواقع — لا مال يتحرّك '
              'بهذا الإصلاح.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            for (final item in stale)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'كشف ${item.periodLabel} · ${item.entryCount} راتباً '
                        '· ${money.format(item.totalIqd)} د.ع',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _confirmRestoreStale(context, ref, item),
                      icon: const Icon(Icons.undo_rounded, size: 16),
                      label: const Text('أعِدها مستحقّة'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// تأكيد إعادة الرواتب العالقة — **بسبب مكتوب وبلا كلمة مرور**
///
/// 📌 لا كلمة مرور هنا خلافاً لبقية العمليات: هذه **لا تُرجع مالاً** — المال
///   رجع أصلاً حين حُذف السند. كل ما تفعله أن تجعل السجل يطابق الواقع.
Future<void> _confirmRestoreStale(
  BuildContext context,
  WidgetRef ref,
  StalePaidPayroll item,
) async {
  final money = NumberFormat('#,##0');
  var reason = '';

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('إعادة رواتب ${item.periodLabel} مستحقّة'),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.entryCount} راتباً بمجموع '
                '${money.format(item.totalIqd)} د.ع ستعود «مستحقّة» '
                'ويعود الكشف مسودة.\n\n'
                'لا مال يتحرّك: سند هذه الرواتب محذوف ومالها في الخزينة '
                'أصلاً — الإصلاح يجعل السجل يقول الحقيقة.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: reason,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'السبب *',
                  hintText: 'مثال: حُذف سندها عند إلغاء سلفة موظف',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => reason = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: reason.trim().isEmpty
                ? null
                : () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(payrollNotifierProvider.notifier)
                        .restoreStalePaidPayroll(
                          periodId: item.periodId,
                          reason: reason,
                        );
                  },
            child: const Text('أعِدها مستحقّة'),
          ),
        ],
      ),
    ),
  );
}
