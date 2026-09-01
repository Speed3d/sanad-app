// ─────────────────────────────────────────────────────────────────────────────
// advance_report_tab.dart — تقرير سلف المشاريع
//
// 🔄 أُعيدت كتابته (2026-08-07). النسخة السابقة كانت تبحث في السندات بحقل
//    advance_number النصي وتجمع الصرف فقط تحت عنوان «إجمالي المصروفات» —
//    فلم تكن تُجيب سؤال المالك الحقيقي: أرسلتُ كم؟ وكم بقي؟
//
// الآن يعرض لكل سلفة الأرقام الأربعة: المُرسَل · المصروف · المتبقي · العجز،
// مقروءةً من كيان السلفة نفسه لا من مطابقة نصية هشّة.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../core/constants/app_routes.dart';
import '../../../domain/models/advance_model.dart';
import '../../providers/advance_providers.dart';
import '../../providers/repository_providers.dart';
import '../../../core/extensions/string_extensions.dart';
import 'report_print_actions.dart';
import 'report_table_builders.dart';
import 'report_widgets.dart';

// ════════════════════════════════════════════════════════════════════════════
// TAB 4 — تقارير السلف والمشاريع
// ════════════════════════════════════════════════════════════════════════════

class AdvanceReportTab extends ConsumerStatefulWidget {
  const AdvanceReportTab({super.key});

  @override
  ConsumerState<AdvanceReportTab> createState() => _AdvanceReportTabState();
}

class _AdvanceReportTabState extends ConsumerState<AdvanceReportTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _statusFilter;

  String get _statusLabel =>
      _statusFilter == null ? 'الكل' : _statusFilter!.toArabicAdvanceStatus();

  /// بيان الطباعة — من القائمة المفلترة المعروضة نفسها
  ReportTableData _table(List<AdvanceModel> list) => buildAdvancesListTable(
        statusLabel: _statusLabel,
        query: _query,
        advances: list,
      );

  /// تصدير السلف **بسطور مصاريفها** (الدفعة ج — بلاغ المالك 2026-08-30)
  ///
  /// [matches] — السلف التي طابقت بالبند: لهذه وحدها تُصفَّى السطور على البند
  /// المطلوب. أمّا ما طابق برقم السلفة أو باسم المشروع فيخرج **بكل** سطوره،
  /// لأن البند لم يكن سبب مطابقته أصلاً.
  Future<void> _exportDetails(
    List<AdvanceModel> list,
    Map<int, ({int count, double total})> matches,
  ) async {
    final ids = [for (final a in list) a.id];
    final itemQuery = matches.isEmpty ? '' : _query;

    try {
      var lines =
          await ref.read(advanceRepositoryProvider).getLinesForAdvances(ids);

      if (itemQuery.isNotEmpty) {
        final q = itemQuery.toLowerCase();
        lines = lines
            .where((l) =>
                !matches.containsKey(l.advanceId) ||
                l.itemType.toLowerCase().contains(q))
            .toList();
      }

      if (!mounted) return;
      await ReportPrintActions.exportExcel(
        context,
        ref,
        buildAdvanceLinesTable(
          statusLabel: _statusLabel,
          query: _query,
          itemQuery: itemQuery,
          advances: list,
          lines: lines,
        ),
      );
    } catch (e) {
      // الصمت هنا هو عين ع-٢٥: زرٌّ يبدو أنه «لا يفعل شيئاً»
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر تحميل تفاصيل السلف: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(advancesByStatusProvider(_statusFilter));

    // السلف التي فيها بندٌ يطابق البحث — استعلامٌ واحد يخدم الفلترة والشارة
    final matches =
        ref.watch(advancesByItemTypeProvider(_query)).valueOrNull ??
            const <int, ({int count, double total})>{};

    return Column(
      children: [
        // ── الفلاتر ─────────────────────────────────────────────────
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('بحث السلف والمشاريع', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رقم السلفة · اسم المشروع · بند داخل السلفة',
                    helperText:
                        'اكتب بنداً مثل «وقود» لترى السلف التي صُرف فيها',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _StatusFilterChip(
                      label: 'الكل',
                      value: null,
                      selected: _statusFilter,
                      onSelect: (v) => setState(() => _statusFilter = v),
                    ),
                    _StatusFilterChip(
                      label: 'مسودات',
                      value: AdvanceStatus.draft,
                      selected: _statusFilter,
                      onSelect: (v) => setState(() => _statusFilter = v),
                    ),
                    _StatusFilterChip(
                      label: 'مفتوحة',
                      value: AdvanceStatus.open,
                      selected: _statusFilter,
                      onSelect: (v) => setState(() => _statusFilter = v),
                    ),
                    _StatusFilterChip(
                      label: 'معتمدة',
                      value: AdvanceStatus.posted,
                      selected: _statusFilter,
                      onSelect: (v) => setState(() => _statusFilter = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── النتائج ─────────────────────────────────────────────────
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('خطأ: $e')),
            data: (all) {
              // البحث يشمل **البند داخل السلفة** أيضاً (الدفعة ج): كان على
              // رقم السلفة واسم المشروع فقط، فسؤال «أين صُرف الوقود؟» لا
              // سبيل إليه إلا بفتح كل سلفة على حدة.
              final list = _query.isEmpty
                  ? all
                  : all
                      .where((a) =>
                          a.advanceNumber.contains(_query) ||
                          a.projectName.contains(_query) ||
                          matches.containsKey(a.id))
                      .toList();

              if (list.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.manage_search, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('لا توجد سلف تطابق البحث —\n'
                            'لا برقمها ولا باسم مشروعها ولا ببنودها.',
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _AdvanceReportCard(
                        advance: list[i],
                        itemQuery: _query,
                        itemMatch: matches[list[i].id],
                      ),
                    ),
                  ),
                  // الطباعة والتصدير — من القائمة **المفلترة** المعروضة
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ReportActionsBar(
                      onPrint: () => ReportPrintActions.print(
                          context, ref, _table(list)),
                      onExport: () =>
                          ReportPrintActions.exportExcel(context, ref, _table(list)),
                      onExportDetails: () => _exportDetails(list, matches),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final String? value;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => onSelect(value),
    );
  }
}

// ── بطاقة تقرير سلفة ─────────────────────────────────────────────────────────

class _AdvanceReportCard extends ConsumerWidget {
  const _AdvanceReportCard({
    required this.advance,
    this.itemQuery = '',
    this.itemMatch,
  });

  final AdvanceModel advance;

  /// بند البحث الفعّال — يُميَّز داخل تفصيل البنود فتقع عليه العين
  final String itemQuery;

  /// حصيلة هذا البند في هذه السلفة — `null` حين لم تطابق بالبند
  ///
  /// يجيب السؤال في مكانه: لا «هذه السلفة فيها وقود» بل **كم** وقودٍ فيها.
  final ({int count, double total})? itemMatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0');
    final dateFmt = DateFormat('yyyy/MM/dd');
    final summaryAsync = ref.watch(advanceSummaryProvider(advance.id));
    final linesAsync = ref.watch(advanceLinesProvider(advance.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            advance.advanceNumber,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          '${advance.projectName} — ${advance.statusDisplayName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Text(
              dateFmt.format(advance.advanceDate),
              style: const TextStyle(fontSize: 12),
            ),
            if (itemMatch != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$itemQuery: ${itemMatch!.count} مصروف · '
                    '${fmt.format(itemMatch!.total)} د.ع',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new, size: 18),
          tooltip: 'فتح السلفة',
          onPressed: () => context.go('${AppRoutes.advances}/${advance.id}'),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── الأرقام الأربعة ────────────────────────────────
                summaryAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('خطأ: $e'),
                  data: (s) => Column(
                    children: [
                      _ReportRow(
                        label: 'المُرسَل للمشروع',
                        value: '${fmt.format(s.sent)} د.ع',
                        color: theme.colorScheme.primary,
                      ),
                      _ReportRow(
                        label: 'المصروف',
                        value: '${fmt.format(s.spent)} د.ع',
                        color: theme.colorScheme.error,
                      ),
                      const Divider(height: 16),
                      _ReportRow(
                        label: s.remaining < 0
                            ? 'تجاوز السلفة'
                            : 'المتبقي من السلفة',
                        value: '${fmt.format(s.remaining.abs())} د.ع',
                        color: s.remaining < 0
                            ? Colors.orange.shade800
                            : Colors.green.shade700,
                        bold: true,
                      ),
                      if (advance.hasDeficit)
                        _ReportRow(
                          label: 'عجز مستحق لـ ${advance.deficitCoveredBy}',
                          value: '${fmt.format(advance.deficitAmount)} د.ع',
                          color: Colors.red.shade700,
                          bold: true,
                        ),
                      if (!s.matchesExcel && s.excelTotal > 0)
                        _ReportRow(
                          label: 'فرق المسودة عن ملف الإكسل',
                          value: '${fmt.format(s.excelDifference.abs())} د.ع',
                          color: Colors.orange.shade800,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── تفصيل المصاريف حسب البند ───────────────────────
                linesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (lines) {
                    final counted =
                        lines.where((l) => !l.isExcluded).toList();
                    if (counted.isEmpty) return const SizedBox.shrink();

                    // تجميع حسب البند — يُجيب: كم صُرف على البانزين؟
                    final byType = <String, double>{};
                    for (final l in counted) {
                      final key = l.itemType.isEmpty ? 'بلا بند' : l.itemType;
                      byType[key] = (byType[key] ?? 0) + l.amount;
                    }
                    final sorted = byType.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('المصاريف حسب البند',
                            style: theme.textTheme.labelLarge),
                        const SizedBox(height: 6),
                        ...sorted.map(
                          (e) {
                            // البند المطابق للبحث يُميَّز — القائمة قد تطول،
                            // والعين تجد اللون قبل أن تقرأ السطور
                            final isMatch = itemQuery.isNotEmpty &&
                                e.key
                                    .toLowerCase()
                                    .contains(itemQuery.toLowerCase());
                            return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isMatch
                                        ? theme.colorScheme.primaryContainer
                                        : theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    e.key,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isMatch
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                      color: isMatch
                                          ? theme
                                              .colorScheme.onPrimaryContainer
                                          : theme
                                              .colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${fmt.format(e.value)} د.ع',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${counted.length} مصروف'
                          '${lines.length > counted.length ? ' · ${lines.length - counted.length} مستبعَد' : ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
