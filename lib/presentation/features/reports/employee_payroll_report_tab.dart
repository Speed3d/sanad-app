// ─────────────────────────────────────────────────────────────────────────────
// employee_payroll_report_tab.dart — تقرير رواتب موظف أو مشروع (طلب المالك)
//
// السؤال الذي يجيب عنه: **كم دُفع لهذا الموظف خلال هذه الفترة، ولماذا كان
// راتب كل شهر بهذا الرقم؟**
//
// **قرارات المالك 2026-08-26 وأسبابها:**
//   ١. **مدى أشهر لا تواريخ حرّة** — الراتب وحدته الشهر، والمدى بالتواريخ
//      يُدخل راتب آب في أيلول لأنه صُرف فيه، فيبدو الموظف قابضاً مرّتين في
//      شهر وصفراً في آخر.
//   ٢. **فلتر المشروع يعمل عملين معاً**: يُضيّق قائمة الموظفين إلى موظفي
//      المشروع، وكل سطر يُظهر **الخزينة التي صرفت فعلاً** — فقد يُموَّل موظف
//      البصرة من الرئيسية في شهر بعينه، وهذا بالضبط ما يريد رؤيته.
//   ٣. **وضعان**: موظف محدَّد ⇒ شهرٌ شهراً بكل بنوده · بلا موظف ⇒ كل موظفي
//      المشروع بمجاميعهم.
//
// ⚠️ **كل بند بعموده لا الصافي وحده**: صافٍ أقلّ من المتوقّع قد يكون غياباً أو
//   خصم سلفة أو شهراً ناقصاً — وثلاثتها تُعالَج معالجةً مختلفة. الصافي وحده
//   يُنهي السؤال ولا يجيبه.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../core/services/payroll_calculator.dart';
import '../../../core/services/payroll_print_data.dart';
import '../../../data/database/app_database.dart';
import '../../providers/payroll_providers.dart';
import '../../providers/treasury_providers.dart';
import '../payroll/payroll_print_actions.dart';
import 'report_widgets.dart';

/// تبويب تقرير الموظف
class EmployeePayrollReportTab extends ConsumerStatefulWidget {
  const EmployeePayrollReportTab({super.key});

  @override
  ConsumerState<EmployeePayrollReportTab> createState() =>
      _EmployeePayrollReportTabState();
}

class _EmployeePayrollReportTabState
    extends ConsumerState<EmployeePayrollReportTab> {
  int? _employeeId;
  int? _treasuryId;

  late int _fromYear;
  late int _fromMonth;
  late int _toYear;
  late int _toMonth;

  @override
  void initState() {
    super.initState();
    // الافتراضي: السنة الجارية حتى الشهر السابق — الرواتب تُصرف بعد شهرها،
    // فالشهر الحالي غالباً بلا كشف بعد.
    final previous = DateTime(DateTime.now().year, DateTime.now().month - 1);
    _fromYear = previous.year;
    _fromMonth = 1;
    _toYear = previous.year;
    _toMonth = previous.month;
  }

  EmployeeReportQuery get _query => EmployeeReportQuery(
        employeeId: _employeeId,
        treasuryId: _treasuryId,
        fromYear: _fromYear,
        fromMonth: _fromMonth,
        toYear: _toYear,
        toMonth: _toMonth,
      );

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(payrollReportEmployeesProvider);
    final reportAsync = ref.watch(employeePayrollReportProvider(_query));

    return Column(
      children: [
        _Filters(
          employees: employeesAsync.valueOrNull ?? const [],
          employeeId: _employeeId,
          treasuryId: _treasuryId,
          fromYear: _fromYear,
          fromMonth: _fromMonth,
          toYear: _toYear,
          toMonth: _toMonth,
          onChanged: ({
            bool clearEmployee = false,
            int? employeeId,
            int? treasuryId,
            bool clearTreasury = false,
            int? fromYear,
            int? fromMonth,
            int? toYear,
            int? toMonth,
          }) {
            setState(() {
              if (clearEmployee) {
                _employeeId = null;
              } else if (employeeId != null) {
                _employeeId = employeeId;
              }
              if (clearTreasury) {
                _treasuryId = null;
              } else if (treasuryId != null) {
                _treasuryId = treasuryId;
              }
              _fromYear = fromYear ?? _fromYear;
              _fromMonth = fromMonth ?? _fromMonth;
              _toYear = toYear ?? _toYear;
              _toMonth = toMonth ?? _toMonth;
            });
          },
          onPrint: reportAsync.valueOrNull == null
              ? null
              : () => PayrollPrintActions.printEmployeeReport(
                    context,
                    ref,
                    reportAsync.value!,
                  ),
        ),
        Expanded(
          child: reportAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('خطأ: $e')),
            data: (report) {
              if (report.isEmpty) {
                return ReportPlaceholder(
                  icon: Icons.person_search_outlined,
                  message: 'لا رواتب في ${report.rangeLabel}'
                      '${_treasuryId != null ? ' لهذا المشروع' : ''}.\n'
                      'وسّع المدى أو راجع الفلاتر.',
                );
              }
              return _Results(
                report: report,
                onPickEmployee: (id) => setState(() => _employeeId = id),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// الفلاتر
// ═══════════════════════════════════════════════════════════════════════════

typedef _FilterChanged = void Function({
  bool clearEmployee,
  int? employeeId,
  int? treasuryId,
  bool clearTreasury,
  int? fromYear,
  int? fromMonth,
  int? toYear,
  int? toMonth,
});

class _Filters extends ConsumerWidget {
  const _Filters({
    required this.employees,
    required this.employeeId,
    required this.treasuryId,
    required this.fromYear,
    required this.fromMonth,
    required this.toYear,
    required this.toMonth,
    required this.onChanged,
    required this.onPrint,
  });

  final List<Employee> employees;
  final int? employeeId;
  final int? treasuryId;
  final int fromYear;
  final int fromMonth;
  final int toYear;
  final int toMonth;
  final _FilterChanged onChanged;
  final VoidCallback? onPrint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treasuries = ref.watch(allTreasuriesProvider).valueOrNull ?? const [];

    // فلتر المشروع يُضيّق قائمة الموظفين — قرار المالك (الاثنان معاً)
    final visible = treasuryId == null
        ? employees
        : employees.where((e) => e.treasuryId == treasuryId).toList();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int?>(
                    // القيمة تُسقَط إن اختفى الموظف من القائمة بعد تضييقها
                    // بالمشروع — تمرير قيمة غير موجودة يرمي استثناءً
                    initialValue:
                        visible.any((e) => e.id == employeeId) ? employeeId : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'الموظف',
                      prefixIcon: Icon(Icons.person_search_outlined),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('كل الموظفين (مجاميع)'),
                      ),
                      for (final e in visible)
                        DropdownMenuItem<int?>(
                          value: e.id,
                          child: Text(
                            e.position.isEmpty
                                ? e.fullName
                                : '${e.fullName} — ${e.position}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => v == null
                        ? onChanged(clearEmployee: true)
                        : onChanged(employeeId: v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int?>(
                    initialValue: treasuryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'المشروع / الخزينة',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('كل المشاريع'),
                      ),
                      for (final t in treasuries)
                        DropdownMenuItem<int?>(
                          value: t.id,
                          child: Text(t.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => v == null
                        ? onChanged(clearTreasury: true, clearEmployee: true)
                        : onChanged(treasuryId: v, clearEmployee: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MonthPicker(
                    label: 'من شهر',
                    year: fromYear,
                    month: fromMonth,
                    onChanged: (y, m) => onChanged(fromYear: y, fromMonth: m),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MonthPicker(
                    label: 'إلى شهر',
                    year: toYear,
                    month: toMonth,
                    onChanged: (y, m) => onChanged(toYear: y, toMonth: m),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onPrint,
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('طباعة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// اختيار شهر وسنة معاً
class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.label,
    required this.year,
    required this.month,
    required this.onChanged,
  });

  final String label;
  final int year;
  final int month;
  final void Function(int year, int month) onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<int>(
            initialValue: month,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (var m = 1; m <= 12; m++)
                DropdownMenuItem(
                  value: m,
                  child: Text(PayrollCalculator.arabicMonth(m)),
                ),
            ],
            onChanged: (v) => onChanged(year, v ?? month),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int>(
            initialValue: year,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (var y = now - 5; y <= now + 1; y++)
                DropdownMenuItem(value: y, child: Text('$y')),
            ],
            onChanged: (v) => onChanged(v ?? year, month),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// النتائج
// ═══════════════════════════════════════════════════════════════════════════

class _Results extends StatelessWidget {
  const _Results({required this.report, required this.onPickEmployee});

  final EmployeePayrollReportData report;
  final ValueChanged<int> onPickEmployee;

  @override
  Widget build(BuildContext context) {
    // ⚠️ `ListView` لا `Column`: موظف بعشرين شهراً أو مشروع بأربعين موظفاً
    //   يتجاوز الشاشة عمودياً — وهو العطل ع-٢٧ نفسه.
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _SummaryCards(report: report),
        const SizedBox(height: 12),
        if (report.isSingleEmployee)
          _MonthsTable(report: report)
        else
          _EmployeesTable(report: report, onPick: onPickEmployee),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.report});

  final EmployeePayrollReportData report;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0');
    final scheme = Theme.of(context).colorScheme;

    Widget card(String label, String value, Color color, IconData icon) =>
        SizedBox(
          width: 190,
          child: ReportSummaryCard(
            label: label,
            value: value,
            color: color,
            icon: icon,
          ),
        );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        card(
          report.isSingleEmployee ? 'عدد الأشهر' : 'عدد الموظفين',
          '${report.isSingleEmployee ? report.monthCount : report.employees.length}',
          scheme.primary,
          Icons.calendar_month_outlined,
        ),
        card('إجمالي المستحقّ', '${money.format(report.totalIqd)} د.ع',
            Colors.indigo, Icons.summarize_outlined),
        card('المصروف فعلاً', '${money.format(report.paidIqd)} د.ع',
            Colors.green, Icons.check_circle_outline),
        if (report.unpaidIqd.abs() > 1)
          card('غير مصروف', '${money.format(report.unpaidIqd)} د.ع',
              Colors.orange, Icons.pending_outlined),
        card('المكافآت', '${money.format(report.bonusIqd)} د.ع', Colors.teal,
            Icons.add_circle_outline),
        card('الخصومات', '${money.format(report.deductionIqd)} د.ع',
            Colors.red, Icons.remove_circle_outline),
        card('خصم السلف', '${money.format(report.advanceRepaymentIqd)} د.ع',
            Colors.deepPurple, Icons.account_balance_outlined),
      ],
    );
  }
}

/// جدول أشهر موظف واحد
class _MonthsTable extends StatelessWidget {
  const _MonthsTable({required this.report});

  final EmployeePayrollReportData report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = NumberFormat('#,##0');
    final decimal = NumberFormat('#,##0.##');

    String amount(double v, String currency) => v == 0
        ? '—'
        : (currency == PayrollCurrency.usd
            ? decimal.format(v)
            : money.format(v));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${report.employeeName} — ${report.rangeLabel}',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'كل بند بعموده: الصافي وحده لا يقول لماذا كان الشهر أقلّ.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowHeight: 38,
                dataRowMinHeight: 38,
                dataRowMaxHeight: 44,
                columns: const [
                  DataColumn(label: Text('الشهر')),
                  DataColumn(label: Text('الأساسي')),
                  DataColumn(label: Text('الأيام')),
                  DataColumn(label: Text('غياب')),
                  DataColumn(label: Text('خصم الغياب')),
                  DataColumn(label: Text('مكافأة')),
                  DataColumn(label: Text('خصم')),
                  DataColumn(label: Text('خصم سلفة')),
                  DataColumn(label: Text('الصافي')),
                  DataColumn(label: Text('بالدينار')),
                  DataColumn(label: Text('الحالة')),
                  DataColumn(label: Text('صُرف من')),
                  DataColumn(label: Text('السند')),
                  DataColumn(label: Text('تاريخ الصرف')),
                ],
                rows: [
                  for (final m in report.months)
                    DataRow(cells: [
                      DataCell(Text(
                          '${PayrollCalculator.arabicMonth(m.month)} ${m.year}')),
                      DataCell(Text(amount(m.basicSalary, m.currency))),
                      DataCell(Text('${m.eligibleDays}')),
                      DataCell(Text(m.absenceDays == 0 ? '—' : '${m.absenceDays}')),
                      DataCell(Text(amount(m.absenceDeduction, m.currency))),
                      DataCell(Text(amount(m.bonus, m.currency))),
                      DataCell(Text(amount(m.deduction, m.currency))),
                      DataCell(Text(amount(m.advanceRepayment, m.currency))),
                      DataCell(Text(
                        '${amount(m.net, m.currency)}'
                        '${m.currency == PayrollCurrency.usd ? ' \$' : ''}',
                      )),
                      DataCell(Text(money.format(m.netIqd))),
                      DataCell(Text(
                        m.isPaid ? 'مصروف' : 'مستحقّ',
                        style: TextStyle(
                          color: m.isPaid ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      )),
                      DataCell(Text(m.paidFromTreasury ?? '—')),
                      DataCell(Text(
                          m.voucherNumber == null ? '—' : '#${m.voucherNumber}')),
                      DataCell(Text(
                        m.paidAt == null
                            ? '—'
                            // ⚠️ `.toLocal()` إلزامي: الأعمدة الزمنية تُخزَّن
                            //   UTC فتظهر ناقصة ثلاث ساعات ببغداد (ع-١٤).
                            : DateFormat('yyyy/MM/dd')
                                .format(m.paidAt!.toLocal()),
                      )),
                    ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// جدول مجاميع الموظفين
class _EmployeesTable extends StatelessWidget {
  const _EmployeesTable({required this.report, required this.onPick});

  final EmployeePayrollReportData report;
  final ValueChanged<int> onPick;

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
            Text(
              '${report.treasuryName ?? 'كل المشاريع'} — ${report.rangeLabel}',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'اضغط أي موظف لفتح تفصيل أشهره.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 26,
                headingRowHeight: 38,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 46,
                columns: const [
                  DataColumn(label: Text('الموظف')),
                  DataColumn(label: Text('الصفة')),
                  DataColumn(label: Text('أشهر')),
                  DataColumn(label: Text('المكافآت')),
                  DataColumn(label: Text('الخصومات')),
                  DataColumn(label: Text('خصم السلف')),
                  DataColumn(label: Text('المصروف')),
                  DataColumn(label: Text('الإجمالي')),
                ],
                rows: [
                  for (final e in report.employees)
                    DataRow(
                      onSelectChanged: (_) => onPick(e.employeeId),
                      cells: [
                        DataCell(Text(e.employeeName)),
                        DataCell(Text(e.position.isEmpty ? '—' : e.position)),
                        DataCell(Text('${e.monthCount}')),
                        DataCell(Text(money.format(e.bonusIqd))),
                        DataCell(Text(money.format(e.deductionIqd))),
                        DataCell(Text(money.format(e.advanceRepaymentIqd))),
                        DataCell(Text(money.format(e.paidIqd))),
                        DataCell(Text(
                          money.format(e.totalIqd),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
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
