// ─────────────────────────────────────────────────────────────────────────────
// employee_repayment_sheet.dart — ورقة «كيف سُدّدت السلفة»
//
// **جزء من مكتبة `employees_screen.dart`** — والأصناف فيه تبقى خاصة (`_X`)
// ولا تحتاج إعادة تسمية، وهو النمط المعتمد في هذا المشروع لتقسيم الملفات
// الكبيرة (سوابق: `employees_screen` · `treasuries_screen` · `fiscal_screen`).
//
// استُخرج من `employee_detail_sheet.dart` حين تجاوز **١٣١٩ سطراً** الحدَّ
// المتّفق عليه (١٢٠٠) — وأمسكه `tech_debt_guard_test` قبل أن يُدمج.
// ─────────────────────────────────────────────────────────────────────────────

part of 'employees_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
// ورقة «كيف سُدّدت السلفة»
// ════════════════════════════════════════════════════════════════════════════

/// تفاصيل تسديد سلفة موظف — كل قسط بمصدره
///
/// **لماذا مصدر كل قسط مهمّ؟** لأن السلفة الواحدة تُسدَّد بطرق مختلفة: نقداً
/// من جيب الموظف (بسند قبض له رقم)، أو خصماً من راتب شهر بعينه (بلا سند خاص
/// — يقع ضمن سند رواتب الشهر). ورقمٌ إجمالي لا يقول أيّهما وقع ولا متى.
class _RepaymentDetailsSheet extends ConsumerWidget {
  const _RepaymentDetailsSheet({required this.advance});

  final CashAdvanceModel advance;

  /// أسماء الأشهر بالتقويم المستعمَل في العراق
  static const _months = [
    '',
    'كانون الثاني',
    'شباط',
    'آذار',
    'نيسان',
    'أيار',
    'حزيران',
    'تموز',
    'آب',
    'أيلول',
    'تشرين الأول',
    'تشرين الثاني',
    'كانون الأول',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final money = NumberFormat('#,##0');
    final dateFmt = DateFormat('yyyy/MM/dd');
    final unit = advance.currency == 'IQD' ? 'د.ع' : '\$';
    final async = ref.watch(advanceRepaymentDetailsProvider(advance.id));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('كيف سُدّدت هذه السلفة',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        'المبلغ ${money.format(advance.amount)} $unit'
                        '  ·  المسدَّد ${money.format(advance.totalRepaid)} $unit',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text('لم يُسدَّد من هذه السلفة شيء بعد.'),
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = list[i];
                    final isSalary = r.method == 'salary_deduction';
                    final accent =
                        isSalary ? Colors.blue.shade700 : Colors.green.shade700;

                    // مصدر القسط بلغة المالك — لا اسم عمود ولا رمز طريقة
                    final String source;
                    if (isSalary && r.periodYear != null) {
                      final m = r.periodMonth ?? 0;
                      final name = (m >= 1 && m <= 12) ? _months[m] : '';
                      source = 'خصم من رواتب $name ${r.periodYear}';
                    } else if (isSalary) {
                      source = 'خصم من الراتب';
                    } else if (r.voucherNumber != null) {
                      source = r.method == 'bank_transfer'
                          ? 'حوالة مصرفية — سند قبض رقم ${r.voucherNumber}'
                          : 'تسديد نقدي — سند قبض رقم ${r.voucherNumber}';
                    } else {
                      source = r.method == 'bank_transfer'
                          ? 'حوالة مصرفية'
                          : 'تسديد نقدي';
                    }

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side:
                            BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: accent.withValues(alpha: 0.12),
                          child: Icon(
                            isSalary
                                ? Icons.badge_outlined
                                : Icons.payments_outlined,
                            size: 16,
                            color: accent,
                          ),
                        ),
                        title: Text(
                          '${money.format(r.amount)} $unit',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(source),
                            Text(
                              dateFmt.format(r.date.toLocal()),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (r.notes.isNotEmpty)
                              Text(r.notes,
                                  style: theme.textTheme.labelSmall),
                          ],
                        ),
                        trailing: Text(
                          'دفعة ${i + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
