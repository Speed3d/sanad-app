// ─────────────────────────────────────────────────────────────────────────────
// payroll_sheet_dialogs.dart — جزء من مكتبة `payroll_sheet_screen.dart`
//
// حوارات كشف الشهر: تعديل السطر · التسديد · خيارات الطباعة · حذف الكشف ·
// إلغاء تسديد الشهر.
//
// **لماذا جزءٌ مستقلّ؟** `payroll_sheet_widgets.dart` تجاوز سقف
//   `tech_debt_guard_test` (١٢٠٠ سطر) بعد إضافة عمود الإجازة (Schema v10).
//   والفصل **بحسب الطبيعة لا الحجم**: هناك جدولٌ وترويسةٌ تُقرأ، وهنا
//   حواراتٌ تُكتَب بها البيانات.
//
// ⚠️ **بلا `TextEditingController` في أيٍّ منها** — متغيّرات نصّية مع
//   `initialValue`/`onChanged`. راجع ع-٠٤.
// ─────────────────────────────────────────────────────────────────────────────

part of 'payroll_sheet_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// حوار تعديل سطر
// ═══════════════════════════════════════════════════════════════════════════

/// ⚠️ **بلا `TextEditingController`** — متغيّرات نصّية مع `initialValue`
///   و`onChanged`. المتحكّم المُتخلَّص منه بعد `await showDialog` سبّب شاشة
///   حمراء في خمسة مواضع (ع-٠٤): الـ await ينتهي لحظة `Navigator.pop` لا
///   لحظة اختفاء الحوار، فيبقى الحقل يُعاد بناؤه على متحكّم ميت.
Future<void> _openEditDialog(
  BuildContext context,
  WidgetRef ref,
  SalaryPayment entry,
) async {
  final advances =
      await ref.readOnce(employeePendingAdvancesProvider(entry.employeeId),
          employeePendingAdvancesProvider(entry.employeeId).future);
  if (!context.mounted) return;

  double? basic = entry.basicSalary;
  int? days = entry.eligibleDays;
  int? absenceDays = entry.absenceDays;
  double? absenceDed = entry.absenceDeduction;
  double? bonus = entry.additions;
  double? deduction = entry.deductions;
  double? repayment = entry.advanceRepaymentAmount;
  int? advanceId = entry.cashAdvanceId ??
      (advances.isNotEmpty ? advances.first.id : null);
  var daysTouched = false;
  var absenceDedTouched = false;

  /// طلب المالك فتحَ حوار الإجازة بدل الحفظ — يُعالَج **بعد** إغلاق هذا
  /// الحوار لا فوقه: حوارٌ فوق حوار يُربك، والفصل يجعل كل عمليةٍ مستقلّة.
  var wantsLeave = false;

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final colors = ctx.colors;
      final money = NumberFormat('#,##0.##');

      Widget numField({
        required String label,
        required String initial,
        required ValueChanged<String> onChanged,
        String? helper,
      }) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            initialValue: initial,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: label,
              helperText: helper,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: onChanged,
          ),
        );
      }

      return AlertDialog(
        title: Text('تعديل راتب «${entry.snapshotName}»'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                numField(
                  label: 'الراتب الأساسي',
                  initial: money.format(entry.basicSalary),
                  onChanged: (v) =>
                      basic = double.tryParse(v.replaceAll(',', '')),
                ),
                numField(
                  label: 'الأيام المستحقّة',
                  initial: '${entry.eligibleDays}',
                  helper: 'تعديلها يدوياً يصونها من إعادة الحساب',
                  onChanged: (v) {
                    daysTouched = true;
                    days = int.tryParse(v);
                  },
                ),
                numField(
                  label: 'أيام الغياب',
                  initial: '${entry.absenceDays}',
                  onChanged: (v) => absenceDays = int.tryParse(v),
                ),
                numField(
                  label: 'خصم الغياب',
                  initial: money.format(entry.absenceDeduction),
                  helper: 'اتركه ليُحتسب تلقائياً من أيام الغياب',
                  onChanged: (v) {
                    absenceDedTouched = true;
                    absenceDed = double.tryParse(v.replaceAll(',', ''));
                  },
                ),
                numField(
                  label: 'مكافأة',
                  initial: money.format(entry.additions),
                  onChanged: (v) =>
                      bonus = double.tryParse(v.replaceAll(',', '')),
                ),
                numField(
                  label: 'خصومات أخرى',
                  initial: money.format(entry.deductions),
                  onChanged: (v) =>
                      deduction = double.tryParse(v.replaceAll(',', '')),
                ),
                if (advances.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    'خصم سلفة الموظف',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اقتراحٌ تقرّره أنت — يُسجَّل قسط سداد عند التسديد.',
                    style: TextStyle(fontSize: 11.5, color: colors.subtext),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: advanceId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'السلفة',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: advances
                        .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                'سلفة ${money.format(a.amount)} — '
                                'المتبقي ${money.format(a.amount - a.totalRepaid)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => advanceId = v,
                  ),
                  const SizedBox(height: 12),
                  numField(
                    label: 'المبلغ المخصوم',
                    initial: money.format(entry.advanceRepaymentAmount),
                    onChanged: (v) =>
                        repayment = double.tryParse(v.replaceAll(',', '')),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          // ⚠️ **بابٌ ثانٍ إلى المخزن نفسه لا حقلٌ ثانٍ** (قرار المالك
          //   2026-09-02): البطاقة والكشف كلاهما يكتب في `employee_leaves`،
          //   ولا حقلَ إجازةٍ على سطر الراتب. فالعطلان ع-٣٧ و ع-٤٠ وُلدا من
          //   معنىً واحد يعيش في مكانين.
          TextButton.icon(
            onPressed: () {
              wantsLeave = true;
              Navigator.pop(ctx, false);
            },
            icon: const Icon(Icons.beach_access_outlined, size: 16),
            label: const Text('تسجيل إجازة'),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حفظ'),
          ),
        ],
      );
    },
  );

  // ── مسار الإجازة ───────────────────────────────────────────────────────
  if (wantsLeave) {
    if (!context.mounted) return;
    final period =
        await ref.read(payrollRepositoryProvider).getPeriod(entry.payrollPeriodId!);
    if (!context.mounted) return;

    final added = await showEmployeeLeaveDialog(
      context,
      ref,
      employeeId: entry.employeeId,
      employeeName: entry.snapshotName,
      // يفتح على أول شهر الكشف — فالإجازة التي تُسجَّل من هنا شهرُها معروف
      initialFrom: period == null
          ? null
          : DateTime(period.year, period.month, 1),
    );

    // 🔑 **وإعادة الحساب فوراً** — وإلا سجّل المالك إجازةً ولم يرَ أثرها
    //   فظنّ الميزة معطَّلة (نمط ع-٠٦).
    if (added && context.mounted) {
      await ref
          .read(payrollNotifierProvider.notifier)
          .updateEntry(entryId: entry.id);
    }
    return;
  }

  if (saved != true) return;

  await ref.read(payrollNotifierProvider.notifier).updateEntry(
        entryId: entry.id,
        basicSalary: basic,
        eligibleDays: daysTouched ? days : null,
        absenceDays: absenceDays,
        absenceDeduction: absenceDedTouched ? absenceDed : null,
        bonus: bonus,
        deduction: deduction,
        advanceRepayment: repayment,
        cashAdvanceId: (repayment ?? 0) > 0 ? advanceId : null,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// حوار التسديد
// ═══════════════════════════════════════════════════════════════════════════

Future<void> _openPayDialog(
  BuildContext context,
  WidgetRef ref,
  PayrollPeriod period,
) async {
  final entries = await ref.readOnce(payrollEntriesProvider(period.id),
      payrollEntriesProvider(period.id).future);
  final treasuries = await ref.readOnce(
      allTreasuriesProvider, allTreasuriesProvider.future);
  if (!context.mounted) return;

  final unpaid = entries
      .where((e) => e.paymentStatus == PayrollPaymentStatusDb.unpaid)
      .toList();
  if (unpaid.isEmpty) return;

  final selected = <int>{...unpaid.map((e) => e.id)};
  int? treasuryId = treasuries.isNotEmpty ? treasuries.first.id : null;
  var payDate = DateTime.now();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final colors = ctx.colors;
        final money = NumberFormat('#,##0');
        final total = unpaid
            .where((e) => selected.contains(e.id))
            .fold<double>(0, (s, e) => s + e.netAmountIqd);

        return AlertDialog(
          title: Text(
            'تسديد رواتب '
            '${PayrollCalculator.periodLabel(period.year, period.month)}',
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ملخّص ما سيخرج — قبل اختيار الخزينة لا بعده
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${selected.length} موظفاً',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${money.format(total)} د.ع',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: colors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'يُنشأ **سند صرف واحد** بالمجموع — لا سند لكل موظف. '
                  'وتفصيل كل راتب محفوظ في الكشف.',
                  style: TextStyle(fontSize: 12, color: colors.subtext),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: treasuryId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'الخزينة التي يُصرف منها',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: treasuries
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => treasuryId = v),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الصرف',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('yyyy/MM/dd').format(payDate),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: payDate,
                            firstDate: DateTime(period.year - 1),
                            lastDate: DateTime(period.year + 2),
                          );
                          if (picked != null) {
                            setState(() => payDate = picked);
                          }
                        },
                        child: const Text('تغيير'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'الموظفون الداخلون في هذه الدفعة',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: colors.text),
                ),
                const SizedBox(height: 6),
                // الاختيار الجزئي هو ما يجعل التسديد على دفعات ممكناً:
                // موظفو البصرة من سلفتها ومن في بغداد من الرئيسية
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final e in unpaid)
                        CheckboxListTile(
                          dense: true,
                          value: selected.contains(e.id),
                          title: Text(e.snapshotName),
                          subtitle: Text(
                            '${money.format(e.netAmountIqd)} د.ع'
                            '${e.advanceRepaymentAmount > 0 ? ' · خصم سلفة ${money.format(e.advanceRepaymentAmount)}' : ''}',
                          ),
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              selected.add(e.id);
                            } else {
                              selected.remove(e.id);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: selected.isEmpty || treasuryId == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('تأكيد الصرف'),
            ),
          ],
        );
      },
    ),
  );

  if (confirmed != true || treasuryId == null) return;

  await ref.read(payrollNotifierProvider.notifier).payEntries(
        periodId: period.id,
        entryIds: selected.toList(),
        treasuryId: treasuryId!,
        paymentDate: payDate,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// حذف الكشف
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// حوار خيارات طباعة الكشف
// ═══════════════════════════════════════════════════════════════════════════

/// يسأل عن عمود توقيع الاستلام قبل الطباعة (قرار المالك 2026-08-26)
///
/// **ولماذا سؤال لا ثابت؟** الورقة التي تُوزَّع على الموظفين تحتاج خانة
/// توقيع، ونسخة الأرشيف لا تحتاجها فتتّسع بقيةُ الأعمدة. والافتراضي
/// **مُفعَّل** لأن ورقة التوزيع هي الاستعمال الأشيع.
///
/// ⚠️ **بلا `TextEditingController`** — مربّع اختيار فقط داخل
///   `StatefulBuilder`. راجع تحذير أعلى هذا الملف (ع-٠٤).
Future<void> _openPrintSheetDialog(
  BuildContext context,
  WidgetRef ref,
  PayrollPeriod period,
) async {
  var withSignature = true;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: const Text('طباعة كشف الرواتب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'رواتب '
              '${PayrollCalculator.periodLabel(period.year, period.month)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: withSignature,
              onChanged: (v) => setLocal(() => withSignature = v ?? false),
              title: const Text('عمود توقيع الاستلام'),
              subtitle: const Text(
                'خانة فارغة يوقّع فيها كل موظف عند استلام راتبه.',
                style: TextStyle(fontSize: 12),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('معاينة وطباعة'),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true || !context.mounted) return;
  await PayrollPrintActions.printSheet(
    context,
    ref,
    period.id,
    withSignatureColumn: withSignature,
  );
}
