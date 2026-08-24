// ─────────────────────────────────────────────────────────────────────────────
// reports_screen.dart — شاشة التقارير
//
// التبويبات:
//   1. كشف الحساب    — خزينة + نطاق تاريخ → جدول بالرصيد التراكمي
//   2. ملخص يومي     — تاريخ → إجمالي قبض / صرف
//   3. تقرير الفترة  — نطاق تاريخ + خزينة (اختياري) → قائمة سندات + ملخص
//   4. تقارير السلف  — advance_report_tab.dart
//   5. حسب البند     — expenses_by_item_tab.dart  (ب-٢)
//   6. المستحقات     — deficit_report_tab.dart    (ب-٢)
//
// الودجتات المشتركة في report_widgets.dart — استعملها ولا تكتب بديلاً.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat, DateFormat;

import '../../../domain/models/voucher_model.dart';
import '../../providers/treasury_providers.dart';
import '../../providers/voucher_providers.dart';
import 'advance_report_tab.dart';
import 'deficit_report_tab.dart';
import 'expenses_by_item_tab.dart';
import 'report_widgets.dart';

// ════════════════════════════════════════════════════════════════════════════
// ReportsScreen — الشاشة الرئيسية
// ════════════════════════════════════════════════════════════════════════════

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet_outlined), text: 'كشف الحساب'),
            Tab(icon: Icon(Icons.today_outlined), text: 'ملخص يومي'),
            Tab(icon: Icon(Icons.date_range_outlined), text: 'تقرير فترة'),
            Tab(icon: Icon(Icons.manage_search), text: 'سلف المشاريع'),
            Tab(icon: Icon(Icons.pie_chart_outline), text: 'حسب البند'),
            Tab(icon: Icon(Icons.trending_down), text: 'المستحقات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _AccountStatementTab(),
          _DailySummaryTab(),
          _PeriodReportTab(),
          AdvanceReportTab(),
          ExpensesByItemTab(),
          DeficitReportTab(),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 1 — كشف الحساب
// ════════════════════════════════════════════════════════════════════════════

class _AccountStatementTab extends ConsumerStatefulWidget {
  const _AccountStatementTab();

  @override
  ConsumerState<_AccountStatementTab> createState() =>
      _AccountStatementTabState();
}

class _AccountStatementTabState extends ConsumerState<_AccountStatementTab> {
  int? _selectedTreasuryId;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  // الفلاتر المُطبَّقة (null = لم يُضغط "عرض" بعد)
  ({int treasuryId, DateTime start, DateTime end})? _applied;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final treasuriesAsync = ref.watch(allTreasuriesProvider);

    return Column(
      children: [
        // ── لوحة الفلاتر ────────────────────────────────────────────────
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('فلاتر التقرير', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                // اختيار الخزينة
                treasuriesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('خطأ: $e'),
                  data: (list) {
                    final effectiveId = list.any((t) => t.id == _selectedTreasuryId)
                        ? _selectedTreasuryId
                        : null;
                    return DropdownButtonFormField<int>(
                      key: ValueKey(effectiveId),
                      initialValue: effectiveId,
                      decoration: const InputDecoration(
                        labelText: 'الخزينة *',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: list
                          .map((t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedTreasuryId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // نطاق التاريخ
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _selectedTreasuryId == null
                        ? null
                        : () => setState(
                              () => _applied = (
                                treasuryId: _selectedTreasuryId!,
                                start: _startDate,
                                end: _endDate,
                              ),
                            ),
                    icon: const Icon(Icons.search),
                    label: const Text('عرض كشف الحساب'),
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── النتائج ────────────────────────────────────────────────────
        Expanded(
          child: _applied == null
              ? const ReportPlaceholder(
                  icon: Icons.account_balance_wallet_outlined,
                  message: 'اختر الخزينة ونطاق التاريخ ثم اضغط "عرض"',
                )
              : _AccountStatementResults(
                  treasuryId: _applied!.treasuryId,
                  startDate: _applied!.start,
                  endDate: _applied!.end,
                ),
        ),
      ],
    );
  }
}

class _AccountStatementResults extends ConsumerWidget {
  const _AccountStatementResults({
    required this.treasuryId,
    required this.startDate,
    required this.endDate,
  });
  final int treasuryId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statAsync = ref.watch(
      accountStatementProvider(
        treasuryId: treasuryId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
    final fmt = NumberFormat('#,##0');
    final dateFmt = DateFormat('yyyy/MM/dd');

    return statAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return const ReportPlaceholder(
            icon: Icons.inbox_outlined,
            message: 'لا توجد سندات في هذه الفترة',
          );
        }

        final lastBalance = rows.last.runningBalanceIqd;
        final lastBalanceUsd = rows.last.runningBalanceUsd;

        return Column(
          children: [
            // ── ملخص الرصيد ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ReportSummaryCard(
                      label: 'الرصيد النهائي (د.ع)',
                      value: '${fmt.format(lastBalance)} د.ع',
                      color: lastBalance >= 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      icon: Icons.account_balance_wallet,
                    ),
                  ),
                  if (lastBalanceUsd != 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ReportSummaryCard(
                        label: 'الرصيد النهائي (\$)',
                        value: '\$ ${fmt.format(lastBalanceUsd)}',
                        color: lastBalanceUsd >= 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        icon: Icons.attach_money,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ── جدول كشف الحساب ──────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: rows.length,
                itemBuilder: (ctx, i) {
                  final row = rows[i];
                  final v = row.voucher;
                  final isSarf = v.isSarf;
                  final rowColor =
                      isSarf ? Colors.red.shade700 : Colors.green.shade700;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: rowColor.withValues(alpha: 0.1),
                        child: Icon(
                          isSarf ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: rowColor,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            v.voucherNumber.toString(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateFmt.format(v.voucherDate),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      subtitle: v.reason.isNotEmpty
                          ? Text(
                              v.reason,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isSarf ? '-' : '+'} ${fmt.format(v.amount)} ${v.currency}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: rowColor,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'رصيد: ${fmt.format(row.runningBalanceIqd)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 2 — ملخص يومي
// ════════════════════════════════════════════════════════════════════════════

class _DailySummaryTab extends ConsumerStatefulWidget {
  const _DailySummaryTab();

  @override
  ConsumerState<_DailySummaryTab> createState() => _DailySummaryTabState();
}

class _DailySummaryTabState extends ConsumerState<_DailySummaryTab> {
  DateTime _date = DateTime.now();
  DateTime? _appliedDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── لوحة اختيار التاريخ ─────────────────────────────────────
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ReportDateField(
                  label: 'التاريخ',
                  value: _date,
                  onChanged: (d) => setState(() => _date = d),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => setState(() => _appliedDate = _date),
                    icon: const Icon(Icons.today),
                    label: const Text('عرض ملخص اليوم'),
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── النتائج ─────────────────────────────────────────────────
        Expanded(
          child: _appliedDate == null
              ? const ReportPlaceholder(
                  icon: Icons.today_outlined,
                  message: 'اختر تاريخاً ثم اضغط "عرض"',
                )
              : _DailySummaryResults(date: _appliedDate!),
        ),
      ],
    );
  }
}

class _DailySummaryResults extends ConsumerWidget {
  const _DailySummaryResults({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(dailySummaryProvider(date));
    final fmt = NumberFormat('#,##0');
    final dateFmt = DateFormat('EEEE، d MMMM yyyy', 'ar');

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (summary) {
        final net = summary.totalKabd - summary.totalSarf;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // تاريخ العرض
              Center(
                child: Text(
                  dateFmt.format(date),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // بطاقتا القبض والصرف
              Row(
                children: [
                  Expanded(
                    child: _BigSummaryCard(
                      label: 'إجمالي القبض',
                      value: fmt.format(summary.totalKabd),
                      suffix: 'د.ع',
                      icon: Icons.arrow_downward_rounded,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BigSummaryCard(
                      label: 'إجمالي الصرف',
                      value: fmt.format(summary.totalSarf),
                      suffix: 'د.ع',
                      icon: Icons.arrow_upward_rounded,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // صافي اليوم
              Card(
                color: net >= 0
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الصافي',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${net >= 0 ? '+' : ''}${fmt.format(net)} د.ع',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: net >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 3 — تقرير الفترة
// ════════════════════════════════════════════════════════════════════════════

class _PeriodReportTab extends ConsumerStatefulWidget {
  const _PeriodReportTab();

  @override
  ConsumerState<_PeriodReportTab> createState() => _PeriodReportTabState();
}

class _PeriodReportTabState extends ConsumerState<_PeriodReportTab> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  int? _selectedTreasuryId;
  String? _selectedType; // null=الكل | 'sarf' | 'kabd'

  ({DateTime start, DateTime end, int? treasuryId, String? type})? _applied;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final treasuriesAsync = ref.watch(allTreasuriesProvider);

    return Column(
      children: [
        // ── لوحة الفلاتر ────────────────────────────────────────────
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('فلاتر الفترة', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                // نطاق التاريخ
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
                // الخزينة (اختياري)
                treasuriesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('خطأ: $e'),
                  data: (list) {
                    final effectiveId = list.any((t) => t.id == _selectedTreasuryId)
                        ? _selectedTreasuryId
                        : null;
                    return DropdownButtonFormField<int?>(
                      key: ValueKey(effectiveId),
                      initialValue: effectiveId,
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
                      onChanged: (v) => setState(() => _selectedTreasuryId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // نوع السند
                Text('نوع السند', style: theme.textTheme.labelMedium),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('الكل'),
                      selected: _selectedType == null,
                      onSelected: (_) => setState(() => _selectedType = null),
                    ),
                    FilterChip(
                      label: const Text('صرف'),
                      selected: _selectedType == 'sarf',
                      selectedColor: Colors.red.shade100,
                      onSelected: (_) => setState(
                        () => _selectedType =
                            _selectedType == 'sarf' ? null : 'sarf',
                      ),
                    ),
                    FilterChip(
                      label: const Text('قبض'),
                      selected: _selectedType == 'kabd',
                      selectedColor: Colors.green.shade100,
                      onSelected: (_) => setState(
                        () => _selectedType =
                            _selectedType == 'kabd' ? null : 'kabd',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => setState(
                      () => _applied = (
                        start: _startDate,
                        end: _endDate,
                        treasuryId: _selectedTreasuryId,
                        type: _selectedType,
                      ),
                    ),
                    icon: const Icon(Icons.search),
                    label: const Text('عرض التقرير'),
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── النتائج ─────────────────────────────────────────────────
        Expanded(
          child: _applied == null
              ? const ReportPlaceholder(
                  icon: Icons.date_range_outlined,
                  message: 'حدد نطاق التاريخ ثم اضغط "عرض"',
                )
              : _PeriodReportResults(
                  startDate: _applied!.start,
                  endDate: _applied!.end,
                  treasuryId: _applied!.treasuryId,
                  voucherType: _applied!.type,
                ),
        ),
      ],
    );
  }
}

class _PeriodReportResults extends ConsumerWidget {
  const _PeriodReportResults({
    required this.startDate,
    required this.endDate,
    this.treasuryId,
    this.voucherType,
  });
  final DateTime startDate;
  final DateTime endDate;
  final int? treasuryId;
  final String? voucherType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final vouchersAsync = ref.watch(
      vouchersByDateRangeProvider(
        startDate: startDate,
        endDate: endDate,
        treasuryId: treasuryId,
        voucherType: voucherType,
      ),
    );
    final fmt = NumberFormat('#,##0');
    final dateFmt = DateFormat('yyyy/MM/dd');

    return vouchersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (vouchers) {
        if (vouchers.isEmpty) {
          return const ReportPlaceholder(
            icon: Icons.inbox_outlined,
            message: 'لا توجد سندات في هذه الفترة',
          );
        }

        // حساب المجاميع
        double totalSarf = 0, totalKabd = 0;
        for (final v in vouchers) {
          if (v.isSarf) {
            totalSarf += v.currency == 'IQD'
                ? v.amount
                : v.amount * v.exchangeRate;
          } else {
            totalKabd += v.currency == 'IQD'
                ? v.amount
                : v.amount * v.exchangeRate;
          }
        }

        return Column(
          children: [
            // ملخص الفترة
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ReportSummaryCard(
                      label: 'إجمالي القبض',
                      value: '${fmt.format(totalKabd)} د.ع',
                      color: Colors.green.shade700,
                      icon: Icons.arrow_downward,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ReportSummaryCard(
                      label: 'إجمالي الصرف',
                      value: '${fmt.format(totalSarf)} د.ع',
                      color: Colors.red.shade700,
                      icon: Icons.arrow_upward,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ReportSummaryCard(
                      label: 'عدد السندات',
                      value: '${vouchers.length}',
                      color: theme.colorScheme.primary,
                      icon: Icons.receipt_long_outlined,
                    ),
                  ),
                ],
              ),
            ),
            // قائمة السندات
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: vouchers.length,
                itemBuilder: (ctx, i) {
                  final v = vouchers[i];
                  final isSarf = v.isSarf;
                  final rowColor = isSarf
                      ? Colors.red.shade700
                      : Colors.green.shade700;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: rowColor.withValues(alpha: 0.1),
                        child: Icon(
                          isSarf ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: rowColor,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            v.voucherNumber.toString(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateFmt.format(v.voucherDate),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (v.itemType.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                v.itemType,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: v.personName.isNotEmpty || v.reason.isNotEmpty
                          ? Text(
                              [v.personName, v.reason]
                                  .where((s) => s.isNotEmpty)
                                  .join(' — '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: Text(
                        '${fmt.format(v.amount)} ${v.currency}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: rowColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets مساعدة
// ════════════════════════════════════════════════════════════════════════════

/// بطاقة ملخص كبيرة
class _BigSummaryCard extends StatelessWidget {
  const _BigSummaryCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final String suffix;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              suffix,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

