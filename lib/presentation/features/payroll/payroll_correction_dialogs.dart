// ─────────────────────────────────────────────────────────────────────────────
// payroll_correction_dialogs.dart — جزء من مكتبة `payroll_sheet_screen.dart`
//
// حوارا **التصحيح بعد التسديد** و**إلغاء التسديد** (المرحلة ٦ — 2026-08-26).
//
// 🔑 **لماذا وُجدا؟** جرّب المالك النظام فوجد أن راتباً صُرف بمبلغ خاطئ لا
//   سبيل لتصحيحه ولا لحذفه — فحذف **سند الصرف من شاشة الخزينة** ليلتفّ على
//   القاعدة. وذلك الالتفاف كان يترك الراتب معلَّماً «مسدَّداً» بلا مال (ع-٣١).
//
//   **حاجزٌ يدفع صاحبه إلى الالتفاف عليه أسوأ من غيابه.** فالمسار المشروع
//   هنا، محروساً بسببٍ إلزامي وصلاحية مدير وأثرٍ في سجل التدقيق.
//
// ⚠️ **بلا `TextEditingController`** في كل ما يلي — `initialValue`/`onChanged`
//   وحدهما. المتحكّم المُتخلَّص منه بعد `await showDialog` سبّب شاشة حمراء في
//   خمسة مواضع (ع-٠٤)، ويحرسه `dialog_controller_lifecycle_test`.
// ─────────────────────────────────────────────────────────────────────────────

part of 'payroll_sheet_screen.dart';

/// إجراءات السطر **المسدَّد** — تصحيح أو إلغاء
///
/// تُفتَح بالضغط على السطر نفسه (كما يفتح الضغطُ تعديلَ السطر غير المسدَّد)،
/// فلا يتعلّم المالك إيماءتين لشيء واحد.
Future<void> _openPaidEntryActions(
  BuildContext context,
  WidgetRef ref,
  PayrollPeriod period,
  SalaryPayment entry,
) async {
  final colors = context.colors;
  final money = NumberFormat('#,##0');

  final auth = ref.read(authNotifierProvider);
  final user = auth is AuthAuthenticated ? auth.user : null;
  if (user == null || !user.can(AppPermission.managePayroll)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تصحيح راتب مصروف أو إلغاؤه للمدير وحده — '
          'لأنه يغيّر مالاً خرج من الخزينة فعلاً.',
        ),
        backgroundColor: colors.danger,
      ),
    );
    return;
  }

  final action = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('راتب ${entry.snapshotName} — مصروف'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المبلغ المصروف: ${money.format(entry.netAmountIqd)} د.ع'
            '${entry.paidAt != null ? '\nبتاريخ ${DateFormat('yyyy/MM/dd').format(entry.paidAt!.toLocal())}' : ''}',
            style: TextStyle(fontSize: 13, color: colors.subtext),
          ),
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.tune_rounded,
            color: colors.gold,
            title: 'تصحيح المبلغ',
            subtitle: 'يبقى مصروفاً ويتغيّر رقمه — ويُصحَّح سنده معه',
            onTap: () => Navigator.pop(ctx, 'correct'),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.undo_rounded,
            color: colors.danger,
            title: 'إلغاء التسديد',
            subtitle: 'يعود مستحقّاً · يرجع المال · ويُعاد قسط السلفة',
            onTap: () => Navigator.pop(ctx, 'unpay'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إغلاق'),
        ),
      ],
    ),
  );

  if (action == null || !context.mounted) return;
  if (action == 'correct') {
    await _openCorrectionDialog(context, ref, period, entry);
  } else {
    await _openUnpayDialog(context, ref, entry);
  }
}

/// خيار واحد في قائمة الإجراءات
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 380,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: colors.text)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 11.5, color: colors.subtext)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// تصحيح المبلغ
// ═══════════════════════════════════════════════════════════════════════════

/// حوار تصحيح راتب مسدَّد
///
/// 🔑 **يعرض الفرق قبل وقوعه**، ويسأل عن طبيعته بلغة المالك لا بمصطلح تقني:
///   «هل خرج المال بهذا المبلغ فعلاً؟». والجواب يحدّد الأثر المالي بالكامل:
///   لا ⇒ يُصحَّح السند فيرجع الفرق للخزينة · نعم ⇒ الفرق **دينٌ على الموظف**.
Future<void> _openCorrectionDialog(
  BuildContext context,
  WidgetRef ref,
  PayrollPeriod period,
  SalaryPayment entry,
) async {
  var basic = entry.basicSalary;
  var absenceDays = entry.absenceDays;
  var bonus = entry.additions;
  var deduction = entry.deductions;
  var reason = '';
  var mode = PayrollCorrectionMode.dataEntryError;

  final money = NumberFormat('#,##0');

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final colors = ctx.colors;
      return StatefulBuilder(
        builder: (ctx, setState) {
          // 🔑 المعاينة تمرّ بـ`PayrollCalculator` نفسها التي ستحسب فعلاً —
          //   حسابٌ ثانٍ في الحوار يعني رقماً يَعِد بما لا يقع.
          final preview = PayrollCalculator.compute(
            year: period.year,
            month: period.month,
            workingDays: period.workingDays,
            basicSalary: basic,
            currency: entry.snapshotCurrency,
            exchangeRate: entry.exchangeRate ?? period.exchangeRate,
            hireDate: entry.snapshotHireDate,
            absenceDays: absenceDays,
            bonus: bonus,
            deduction: deduction,
            advanceRepayment: entry.advanceRepaymentAmount,
          );
          final delta = preview.netSalaryIqd - entry.netAmountIqd;
          final isLower = delta < -0.001;

          return AlertDialog(
            title: Text('تصحيح راتب ${entry.snapshotName}'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _NumField(
                            label: 'الراتب الأساسي',
                            initial: basic,
                            onChanged: (v) => setState(() => basic = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _NumField(
                            label: 'أيام الغياب',
                            initial: absenceDays.toDouble(),
                            onChanged: (v) =>
                                setState(() => absenceDays = v.round()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _NumField(
                            label: 'مكافأة',
                            initial: bonus,
                            onChanged: (v) => setState(() => bonus = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _NumField(
                            label: 'خصم',
                            initial: deduction,
                            onChanged: (v) => setState(() => deduction = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── الفرق قبل وقوعه ────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المصروف حالياً: '
                            '${money.format(entry.netAmountIqd)} د.ع',
                            style: TextStyle(
                                fontSize: 12.5, color: colors.subtext),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'بعد التصحيح: '
                            '${money.format(preview.netSalaryIqd)} د.ع '
                            '(${preview.eligibleDays} يوماً)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: colors.text,
                            ),
                          ),
                          if (delta.abs() > 0.001) ...[
                            const SizedBox(height: 4),
                            Text(
                              delta < 0
                                  ? 'فرق ناقص: ${money.format(delta.abs())} د.ع'
                                  : 'فرق زائد: ${money.format(delta)} د.ع',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: delta < 0 ? colors.gold : colors.danger,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── طبيعة الفرق — تُسأل بلغة المالك ────────────────
                    if (isLower) ...[
                      const SizedBox(height: 14),
                      Text(
                        'هل خرج المال بالمبلغ القديم فعلاً؟',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: colors.text),
                      ),
                      const SizedBox(height: 6),
                      RadioGroup<PayrollCorrectionMode>(
                        groupValue: mode,
                        onChanged: (v) => setState(
                            () => mode = v ?? PayrollCorrectionMode.dataEntryError),
                        child: Column(
                          children: [
                            RadioListTile<PayrollCorrectionMode>(
                              value: PayrollCorrectionMode.dataEntryError,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('لا — الرقم أُدخل خطأً',
                                  style: TextStyle(fontSize: 13)),
                              subtitle: Text(
                                'يُصحَّح سند الصرف ويرجع الفرق إلى الخزينة',
                                style: TextStyle(
                                    fontSize: 11.5, color: colors.subtext),
                              ),
                            ),
                            RadioListTile<PayrollCorrectionMode>(
                              value: PayrollCorrectionMode.overpaid,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('نعم — استلمه الموظف كاملاً',
                                  style: TextStyle(fontSize: 13)),
                              subtitle: Text(
                                'السند كما هو · ويُسجَّل الفرق سلفةً على '
                                'الموظف تُخصم من راتب قادم',
                                style: TextStyle(
                                    fontSize: 11.5, color: colors.subtext),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: reason,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'سبب التصحيح *',
                        hintText: 'مثال: نُسي احتساب ٤ أيام غياب',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => reason = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                // الحارس الحقيقي في المستودع — وهذا يمنع محاولةً عابثة فقط
                onPressed: reason.trim().isEmpty || delta.abs() < 0.001
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await ref
                            .read(payrollNotifierProvider.notifier)
                            .correctPaidEntry(
                              entryId: entry.id,
                              reason: reason,
                              mode: isLower
                                  ? mode
                                  : PayrollCorrectionMode.dataEntryError,
                              basicSalary: basic,
                              absenceDays: absenceDays,
                              bonus: bonus,
                              deduction: deduction,
                            );
                      },
                child: const Text('تصحيح'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// إلغاء التسديد
// ═══════════════════════════════════════════════════════════════════════════

/// حوار إلغاء تسديد راتب — **يقول ما سيقع قبل وقوعه**
Future<void> _openUnpayDialog(
  BuildContext context,
  WidgetRef ref,
  SalaryPayment entry,
) async {
  var reason = '';
  // 🔑 **إخراجه من الكشف خيارٌ في العملية نفسها** (طلب المالك 2026-08-26):
  //   «حذف الراتب المدفوع» في ذهنه فعلٌ واحد، وتقسيمه خطوتين منفصلتين يجعل
  //   نصفه يُنسى — فيبقى الموظف في الكشف بسطرٍ مستحقّ لا يريده أحد.
  var alsoRemove = false;
  final money = NumberFormat('#,##0');

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final colors = ctx.colors;
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('إلغاء تسديد راتب ${entry.snapshotName}'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: colors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سيقع ما يلي معاً في عملية واحدة:',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: colors.text),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• يعود الراتب «مستحقّاً» بمبلغ '
                        '${money.format(entry.netAmountIqd)} د.ع\n'
                        '• يرجع المال إلى الخزينة (يُصحَّح سند الصرف أو '
                        'يُحذف إن كان لهذا الموظف وحده)\n'
                        '${entry.advanceRepaymentAmount > 0 ? '• يُعاد قسط سلفته البالغ ${money.format(entry.advanceRepaymentAmount)} د.ع\n' : ''}'
                        '• يعود كشف الشهر «مسودة»',
                        style: TextStyle(fontSize: 12.5, color: colors.subtext),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                CheckboxListTile(
                  value: alsoRemove,
                  onChanged: (v) => setState(() => alsoRemove = v ?? false),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('وأخرِجه من كشف الشهر أيضاً',
                      style: TextStyle(fontSize: 13)),
                  subtitle: Text(
                    'اتركه فارغاً إن كنت ستُعيد صرف راتبه بالمبلغ الصحيح',
                    style: TextStyle(fontSize: 11.5, color: colors.subtext),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: reason,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'سبب الإلغاء *',
                    hintText: 'مثال: صُرف للموظف الخطأ',
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
              style: FilledButton.styleFrom(backgroundColor: colors.danger),
              onPressed: reason.trim().isEmpty
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      // 🔑 تأكيد الهويّة قبل إرجاع مالٍ خرج
                      if (!context.mounted) return;
                      final identityOk = await confirmWithPassword(
                        context,
                        ref,
                        action: 'إلغاء تسديد راتب ${entry.snapshotName}',
                        impact: 'سيرجع '
                            '${money.format(entry.netAmountIqd)} د.ع '
                            'إلى الخزينة.',
                      );
                      if (!identityOk) return;

                      final notifier =
                          ref.read(payrollNotifierProvider.notifier);
                      final ok = await notifier.unpayEntry(
                          entryId: entry.id, reason: reason);
                      // ⚠️ الإخراج **بعد نجاح الإلغاء لا قبله**: سطرٌ يُحذف
                      //   ثم يفشل إلغاء تسديده يترك مالاً خرج بلا سجل يقابله.
                      if (ok && alsoRemove) {
                        await notifier.removeEntry(entry.id);
                      }
                    },
              child: const Text('إلغاء التسديد'),
            ),
          ],
        ),
      );
    },
  );
}

/// حقل رقمي بلا متحكّم — يقبل الفراغ ويعيده صفراً
class _NumField extends StatelessWidget {
  const _NumField({
    required this.label,
    required this.initial,
    required this.onChanged,
  });

  final String label;
  final double initial;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initial == 0 ? '' : initial.toStringAsFixed(0),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// حذف الكشف — أخطر حذف في النظام (ع-٣٣)
// ═══════════════════════════════════════════════════════════════════════════

/// حذف الكشف — **بعد قراءة أثره الحقيقي** (ع-٣٣)
///
/// 🔴 **ما كان يقع هنا:** الحوار كان يقول للمالك حرفياً «لا سندات صُرفت منه
///   بعد، فلا أثر مالي» — وهو **كذبٌ في أخطر لحظة** متى كان في الكشف راتبٌ
///   مصروف. فكان الحذف يمسح سطوره المدفوعة وتبقى سنداتها حيّة: مالٌ خارج
///   الخزينة بلا سجل، وإعادة الاستيراد تُدرج أصحابه **مستحقّين من جديد**.
///
///   والسبب أن الحوار كان يستنتج من **حالة الكشف** (مسودة) ما لا تقوله:
///   الحالة تصف السطور المستحقّة لا المدفوعة. والآن يُقرأ الأثر من القاعدة.
Future<void> _confirmDeletePeriod(
  BuildContext context,
  WidgetRef ref,
  PayrollPeriod period,
) async {
  final label = PayrollCalculator.periodLabel(period.year, period.month);
  final impact =
      await ref.read(payrollRepositoryProvider).getDeletionImpact(period.id);
  if (!context.mounted) return;

  // ── لا مالَ خرج ⇒ الحذف كما كان: بسيطٌ وصادق ─────────────────────────
  if (!impact.hasPaid) {
    final ok = await showConfirmDialog(
      context,
      title: 'حذف كشف $label',
      message: 'سيُحذف الكشف و${impact.unpaidCount} سطراً مستحقّاً.\n'
          'لا سندات صُرفت منه، فلا أثر مالي — ويمكن استيراد الشهر '
          'من جديد بعد الحذف.',
      confirmLabel: 'حذف',
      isDestructive: true,
    );
    if (ok != true || !context.mounted) return;
    final done = await ref
        .read(payrollNotifierProvider.notifier)
        .deletePeriod(period.id);
    if (done && context.mounted) PayrollSheetScreen._goBack(context);
    return;
  }

  await _showPaidDeleteDialog(context, ref, period, label, impact);
}

/// حوار الخيارين حين يكون في الكشف مالٌ خرج فعلاً (قرار المالك 2026-08-26)
Future<void> _showPaidDeleteDialog(
  BuildContext context,
  WidgetRef ref,
  PayrollPeriod period,
  String label,
  PayrollDeletionImpact impact,
) async {
  final money = NumberFormat('#,##0');
  var reason = '';
  var mode = PayrollDeleteMode.reverseAndDelete;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final colors = ctx.colors;
      return StatefulBuilder(
        builder: (ctx, setState) {
          final isReverse = mode == PayrollDeleteMode.reverseAndDelete;
          return AlertDialog(
            title: Text('حذف كشف $label'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── الحقيقة أولاً ────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: colors.danger.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        '⚠️ في هذا الكشف ${impact.paidCount} '
                        '${impact.paidCount == 1 ? 'راتباً مصروفاً' : 'رواتب مصروفة'} '
                        'بمجموع ${money.format(impact.paidTotalIqd)} د.ع — '
                        'مالٌ خرج من الخزينة فعلاً بسندات صرف.'
                        '${impact.unpaidCount > 0 ? '\nومعها ${impact.unpaidCount} سطراً مستحقّاً لم يُصرف.' : ''}',
                        style: TextStyle(fontSize: 13, color: colors.text),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('ماذا تريد أن يحدث؟',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: colors.text)),
                    const SizedBox(height: 6),
                    RadioGroup<PayrollDeleteMode>(
                      groupValue: mode,
                      onChanged: (v) => setState(() =>
                          mode = v ?? PayrollDeleteMode.reverseAndDelete),
                      child: Column(
                        children: [
                          RadioListTile<PayrollDeleteMode>(
                            value: PayrollDeleteMode.reverseAndDelete,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                                'ألغِ تسديدها واحذف الكشف كلّه',
                                style: TextStyle(fontSize: 13)),
                            subtitle: Text(
                              'يرجع ${money.format(impact.paidTotalIqd)} د.ع '
                              'إلى الخزينة · تُحذف سندات الصرف · وتُعاد أقساط '
                              'السلف المخصومة',
                              style: TextStyle(
                                  fontSize: 11.5, color: colors.subtext),
                            ),
                          ),
                          RadioListTile<PayrollDeleteMode>(
                            value: PayrollDeleteMode.unpaidOnly,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                                'احذف المستحقّ فقط وأبقِ المصروف',
                                style: TextStyle(fontSize: 13)),
                            subtitle: Text(
                              'يبقى الكشف بالرواتب المصروفة وسنداتها — '
                              'فلا يبقى مالٌ خارج الخزينة بلا سجل',
                              style: TextStyle(
                                  fontSize: 11.5, color: colors.subtext),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isReverse) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: reason,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'سبب الإلغاء والحذف *',
                          hintText: 'مثال: الكشف بُني على ملف خاطئ',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => reason = v),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('تراجع'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: colors.danger),
                onPressed: isReverse && reason.trim().isEmpty
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        // 🔑 الوضع الذي يُرجع مالاً وحده يطلب الهويّة
                        if (isReverse) {
                          if (!context.mounted) return;
                          final identityOk = await confirmWithPassword(
                            context,
                            ref,
                            action: 'حذف كشف $label وإلغاء تسديداته',
                            impact: 'سيرجع '
                                '${money.format(impact.paidTotalIqd)} د.ع '
                                'إلى الخزينة وتُحذف سنداته.',
                          );
                          if (!identityOk) return;
                        }

                        final done = await ref
                            .read(payrollNotifierProvider.notifier)
                            .deletePeriod(period.id,
                                mode: mode, reason: reason);
                        // الرجوع فقط حين يُحذف الكشف — وإلا بقي مفتوحاً
                        // بسطوره المصروفة أمام المالك
                        if (done &&
                            isReverse &&
                            context.mounted) {
                          PayrollSheetScreen._goBack(context);
                        }
                      },
                child: Text(isReverse ? 'إلغاء التسديد والحذف' : 'حذف المستحقّ'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// إلغاء تسديد الشهر كاملاً (بلاغ المالك 2026-08-27)
// ═══════════════════════════════════════════════════════════════════════════

/// إلغاء تسديد **كل** رواتب الشهر — بلا حذف الكشف
///
/// 🔑 **الفرق عن «حذف الكشف»**: هذا يُعيد الشهر مسودةً بسطوره كاملة ليُصحَّح
///   ويُسدَّد من جديد. وذاك يمحو الكشف كلّه. والمالك احتاج الأول ولم يجده،
///   فلجأ إلى إلغاء سلفة موظف — وكشف بذلك ع-٤٠.
Future<void> _confirmUnpayPeriod(
  BuildContext context,
  WidgetRef ref,
  PayrollPeriod period,
) async {
  final label = PayrollCalculator.periodLabel(period.year, period.month);
  final money = NumberFormat('#,##0');
  final impact =
      await ref.read(payrollRepositoryProvider).getDeletionImpact(period.id);
  if (!context.mounted) return;

  if (!impact.hasPaid) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لا رواتب مسدَّدة في هذا الكشف.')),
    );
    return;
  }

  var reason = '';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final colors = ctx.colors;
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('إلغاء تسديد رواتب $label'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.gold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: colors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'سيقع ما يلي لـ${impact.paidCount} راتباً '
                    'بمجموع ${money.format(impact.paidTotalIqd)} د.ع:\n'
                    '• تعود كلها «مستحقّة» والكشف «مسودة»\n'
                    '• يرجع المال إلى الخزينة وتُحذف سنداته\n'
                    '• وتُعاد أقساط سلف الموظفين المخصومة\n\n'
                    'ويبقى الكشف بسطوره لتصحيحه وإعادة تسديده.',
                    style: TextStyle(fontSize: 12.5, color: colors.text),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: reason,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'سبب الإلغاء *',
                    hintText: 'مثال: سُدِّد الشهر بملف خاطئ',
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
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('تراجع'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colors.danger),
              onPressed:
                  reason.trim().isEmpty ? null : () => Navigator.pop(ctx, true),
              child: const Text('إلغاء التسديد'),
            ),
          ],
        ),
      );
    },
  );

  if (confirmed != true || !context.mounted) return;

  // 🔑 تأكيد الهويّة قبل إرجاع مالٍ خرج (القاعدة المعتمدة)
  final identityOk = await confirmWithPassword(
    context,
    ref,
    action: 'إلغاء تسديد رواتب $label',
    impact: 'سيرجع ${money.format(impact.paidTotalIqd)} د.ع إلى الخزينة '
        'وتعود ${impact.paidCount} رواتب مستحقّة.',
  );
  if (!identityOk) return;

  await ref
      .read(payrollNotifierProvider.notifier)
      .unpayPeriod(periodId: period.id, reason: reason);
}
