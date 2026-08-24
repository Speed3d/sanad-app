// ─────────────────────────────────────────────────────────────────────────────
// expenses_by_item_tab.dart — تقرير «المصروفات حسب البند» (ب-٢)
//
// السؤال الذي يجيب عنه: **كم صُرف على البانزين هذا الشهر؟**
// كان بلا جواب من البرنامج رغم أن البيانات كلها موجودة — لأن لا تقرير يجمعها.
//
// القرارات المحاسبية الثلاثة (مشروحة في `VouchersDao.getExpensesByItemType`
// ومحروسة في `test/unit/expense_reports_test.dart`):
//   ١. سندات الصرف وحدها — التحويلات ليست مصروفاً
//   ٢. البند الفارغ يظهر «غير محدد» ولا يُستبعَد، وإلا لم يطابق المجموع الدفاتر
//   ٣. الدولار يُحوَّل بسعر صرف سنده لا بسعر اليوم
//
// وقرار عرضٍ واحد: **شريط نسبة لكل بند**. الأرقام وحدها لا تُظهر أن بنداً
// يبتلع نصف الإنفاق؛ الشريط يُظهره في لمحة.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../data/database/daos/vouchers_dao.dart';
import '../../providers/treasury_providers.dart';
import '../../providers/voucher_providers.dart';
import 'report_widgets.dart';

/// تبويب المصروفات حسب البند
class ExpensesByItemTab extends ConsumerStatefulWidget {
  const ExpensesByItemTab({super.key});

  @override
  ConsumerState<ExpensesByItemTab> createState() => _ExpensesByItemTabState();
}

class _ExpensesByItemTabState extends ConsumerState<ExpensesByItemTab> {
  // الافتراضي: الشهر الحالي — أشيع سؤال يطرحه المالك
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  int? _treasuryId;
  String? _project;

  /// الفلاتر المطبَّقة فعلاً — منفصلة عن المختارة كي لا يُعاد الاستعلام
  /// عند كل ضغطة، تماماً كنمط `_PeriodReportTab` القائم
  ({DateTime start, DateTime end, int? treasuryId, String? project})? _applied;

  void _apply() => setState(
        () => _applied = (
          start: DateTime(_startDate.year, _startDate.month, _startDate.day),
          // نمدّد النهاية لآخر لحظة في اليوم، وإلا استُبعدت سندات اليوم الأخير
          // نفسه لأن وقتها بعد منتصف الليل
          end: DateTime(
              _endDate.year, _endDate.month, _endDate.day, 23, 59, 59),
          treasuryId: _treasuryId,
          project: _project,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final treasuriesAsync = ref.watch(allTreasuriesProvider);
    final projects = ref.watch(usedProjectsProvider).valueOrNull ?? const [];

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('فلاتر التقرير', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ReportDateField(
                        label: 'من',
                        value: _startDate,
                        onChanged: (d) => setState(() => _startDate = d),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ReportDateField(
                        label: 'إلى',
                        value: _endDate,
                        onChanged: (d) => setState(() => _endDate = d),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                treasuriesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('خطأ: $e'),
                  data: (list) {
                    // القيمة المختارة قد تختفي (حُذفت الخزينة) — نُسقطها بدل
                    // تمرير قيمة غير موجودة فيرمي Dropdown استثناءً
                    final effective =
                        list.any((t) => t.id == _treasuryId) ? _treasuryId : null;
                    return DropdownButtonFormField<int?>(
                      key: ValueKey(effective),
                      initialValue: effective,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'الخزينة (اختياري)',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('جميع الخزائن'),
                        ),
                        ...list.map(
                          (t) => DropdownMenuItem<int?>(
                            value: t.id,
                            child: Text(t.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _treasuryId = v),
                    );
                  },
                ),
                // فلتر المشروع يظهر فقط حين توجد مشاريع — لا ضجيج في قاعدة جديدة
                if (projects.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    key: ValueKey(_project),
                    initialValue:
                        projects.contains(_project) ? _project : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'المشروع (اختياري)',
                      prefixIcon: Icon(Icons.location_city_outlined),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('جميع المشاريع'),
                      ),
                      ...projects.map(
                        (p) => DropdownMenuItem<String?>(
                          value: p,
                          child: Text(p, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _project = v),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _apply,
                    icon: const Icon(Icons.pie_chart_outline),
                    label: const Text('عرض التقرير'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _applied == null
              ? const ReportPlaceholder(
                  icon: Icons.pie_chart_outline,
                  message: 'حدّد نطاق التاريخ ثم اضغط «عرض التقرير»\n'
                      'لمعرفة كم صُرف على كل بند',
                )
              : _Results(
                  startDate: _applied!.start,
                  endDate: _applied!.end,
                  treasuryId: _applied!.treasuryId,
                  project: _applied!.project,
                ),
        ),
      ],
    );
  }
}

// ── النتائج ──────────────────────────────────────────────────────────────────

class _Results extends ConsumerWidget {
  const _Results({
    required this.startDate,
    required this.endDate,
    this.treasuryId,
    this.project,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int? treasuryId;
  final String? project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0');
    final async = ref.watch(
      expensesByItemTypeProvider(
        startDate: startDate,
        endDate: endDate,
        treasuryId: treasuryId,
        projectName: project,
      ),
    );

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return const ReportPlaceholder(
            icon: Icons.inbox_outlined,
            message: 'لا توجد مصروفات في هذه الفترة',
          );
        }

        final total =
            rows.fold<double>(0, (a, r) => a + r.totalEquivalentIqd);
        final vouchers = rows.fold<int>(0, (a, r) => a + r.voucherCount);
        final anyUsd = rows.any((r) => r.hasUsd);
        // أكبر قيمة تُستعمَل مرجعاً لطول الأشرطة، فيمتلئ شريط البند الأكبر
        final maxValue = rows.first.totalEquivalentIqd;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ReportSummaryCard(
                      label: 'إجمالي المصروفات',
                      value: '${fmt.format(total)} د.ع',
                      color: Colors.red.shade700,
                      icon: Icons.arrow_upward,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ReportSummaryCard(
                      label: 'عدد البنود',
                      value: '${rows.length}',
                      color: theme.colorScheme.primary,
                      icon: Icons.label_outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ReportSummaryCard(
                      label: 'عدد السندات',
                      value: '$vouchers',
                      color: theme.colorScheme.secondary,
                      icon: Icons.receipt_long_outlined,
                    ),
                  ),
                ],
              ),
            ),

            // تنبيه صريح حين يدخل الدولار في الحساب — الرقم الموحّد بلا هذا
            // التنبيه يُخفي أن جزءاً منه كان بعملة أخرى
            if (anyUsd)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 15, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'بعض المصروفات بالدولار — حُوّلت بسعر صرف كل سند وقت '
                        'إنشائه، لا بسعر اليوم.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: rows.length,
                itemBuilder: (ctx, i) => _ItemRow(
                  row: rows[i],
                  total: total,
                  maxValue: maxValue,
                  rank: i + 1,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// صفّ بند واحد — الترتيب والمبلغ والنسبة وشريط بصري
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.row,
    required this.total,
    required this.maxValue,
    required this.rank,
  });

  final ItemTypeExpenseRow row;
  final double total;
  final double maxValue;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0');
    final share = total > 0 ? row.totalEquivalentIqd / total : 0.0;
    final barFactor = maxValue > 0 ? row.totalEquivalentIqd / maxValue : 0.0;

    // «غير محدد» بلون محايد — ليس بنداً حقيقياً بل نقصٌ في التصنيف
    final isUnclassified = row.itemType.isEmpty;
    final color = isUnclassified
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    row.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          isUnclassified ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
                Text(
                  '${fmt.format(row.totalEquivalentIqd)} د.ع',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: barFactor,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${(share * 100).toStringAsFixed(1)}% من الإجمالي',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${row.voucherCount} سند',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                // تفصيل العملتين يظهر فقط حين يوجد دولار فعلاً
                if (row.hasUsd) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'منها ${fmt.format(row.totalUsd)} \$'
                      '${row.totalIqd > 0 ? ' و ${fmt.format(row.totalIqd)} د.ع' : ''}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
