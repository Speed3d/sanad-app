// ─────────────────────────────────────────────────────────────────────────────
// employee_salary_card.dart — بطاقة سطر الراتب في بطاقة الموظف
//
// **لماذا ملفٌ مستقلّ؟** `employee_detail_sheet.dart` تجاوز سقف
//   `tech_debt_guard_test` (١٢٠٠ سطر) بعد إضافة دورة حياة الخدمة
//   (Schema v9). والبطاقة كتلةٌ متماسكة تُقرأ وحدها: تعرض سطر راتب واحد
//   وتفتح إجراءاته.
//
// 📌 الحارس أسقط البناء **قبل الدمج** للمرّة الرابعة في هذا المشروع —
//    والدرس المكتوب لا يحمي إلا إن صار اختباراً (د-٣).
// ─────────────────────────────────────────────────────────────────────────────

part of 'employees_screen.dart';

class _SalaryCard extends ConsumerWidget {
  final SalaryPaymentModel salary;

  const _SalaryCard({required this.salary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmtNum = NumberFormat('#,##0', 'ar');
    final fmtDate = DateFormat('dd/MM/yyyy', 'ar');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الفترة + الصافي
            Row(
              children: [
                Expanded(
                  child: Text(
                    salary.periodLabel.isNotEmpty
                        ? salary.periodLabel
                        : fmtDate.format(salary.paymentDate),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${fmtNum.format(salary.netAmount)} د.ع',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                // إيصال الراتب — نفس الإجراء المستعمَل في كشف الشهر
                // (المرحلة ٤). موضعه هنا لأن هذا هو المكان الذي يفتحه
                // المالك حين يسأله موظف عن راتب شهر مضى.
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () =>
                      PayrollPrintActions.printSlip(context, ref, salary.id),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  tooltip: 'طباعة إيصال الراتب',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 32, minHeight: 32),
                ),
                // 🔑 **إلغاء التسديد من البطاقة** (طلب المالك 2026-08-26):
                //   لم يكن للمالك سبيلٌ لحذف راتب من هنا إطلاقاً، فكان
                //   يلجأ إلى حذف السند من شاشة الخزينة — وهو ما أنتج
                //   ع-٣١. والمسار هنا **هو نفسه** الذي في شاشة الكشف:
                //   يرجع المال ويُحذف السند ويُعاد قسط السلفة معاً.
                if (salary.voucherId != null)
                  IconButton(
                    onPressed: () =>
                        _confirmUnpaySalary(context, ref, salary),
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    tooltip: 'إلغاء التسديد وإرجاع المال',
                    color: theme.colorScheme.error,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
            if (salary.additions > 0 || salary.deductions > 0) ...[
              const SizedBox(height: 6),
              const Divider(height: 1),
              const SizedBox(height: 6),
              // التفاصيل
              Row(
                children: [
                  _SalaryDetailItem(
                    label: 'الأساسي',
                    value: fmtNum.format(salary.basicSalary),
                    color: theme.colorScheme.onSurface,
                  ),
                  if (salary.additions > 0) ...[
                    const SizedBox(width: 12),
                    _SalaryDetailItem(
                      label: 'إضافات',
                      value: '+${fmtNum.format(salary.additions)}',
                      color: Colors.green.shade700,
                    ),
                  ],
                  if (salary.deductions > 0) ...[
                    const SizedBox(width: 12),
                    _SalaryDetailItem(
                      label: 'خصومات',
                      value: '-${fmtNum.format(salary.deductions)}',
                      color: Colors.red.shade700,
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 12,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  fmtDate.format(salary.paymentDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (salary.notes.isNotEmpty) ...[
                  const Spacer(),
                  Text(
                    salary.notes,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// تأكيد إلغاء تسديد راتب من بطاقة الموظف
///
/// ⚠️ **يمرّ بالمسار نفسه** الذي في شاشة الكشف (`unpayEntry`) لا بمسارٍ ثانٍ:
///   مساران لعكس عملية مالية يعنيان أن أحدهما سيُنسى عند أول إصلاح — وهي
///   العلّة نفسها التي ولّدت ع-٢٨ وع-٣١ وع-٣٣.
Future<void> _confirmUnpaySalary(
  BuildContext context,
  WidgetRef ref,
  SalaryPaymentModel salary,
) async {
  final money = NumberFormat('#,##0', 'ar');
  var reason = '';

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('إلغاء تسديد الراتب'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'راتب ${salary.periodLabel} بمبلغ '
                '${money.format(salary.netAmount)} د.ع.\n\n'
                'سيرجع المال إلى الخزينة · ويُحذف سند الصرف (أو يُنقَص إن كان '
                'ضمن دفعة) · ويُعاد قسط السلفة إن كان مخصوماً · ويعود السطر '
                'مستحقّاً في كشف شهره.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: reason,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'السبب *',
                  hintText: 'مثال: صُرف بمبلغ خاطئ',
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
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: reason.trim().isEmpty
                ? null
                : () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(payrollNotifierProvider.notifier)
                        .unpayEntry(entryId: salary.id, reason: reason);
                  },
            child: const Text('إلغاء التسديد'),
          ),
        ],
      ),
    ),
  );
}

class _SalaryDetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SalaryDetailItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
