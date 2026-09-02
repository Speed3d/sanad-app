// ─────────────────────────────────────────────────────────────────────────────
// employee_leaves_ui.dart — تبويب الإجازات وحوارها (Schema v9)
//
// **طلب المالك (2026-09-02):** «يوجد موظفون لديهم أيام نزول أسبوعية أو شهرية
//   إجازة ويُحسب لهم بها راتب. ويوجد موظفون يأخذون إجازات بدون راتب مثلاً
//   ١٠ أيام أو شهر أو أكثر أو أقل وبدون راتب.»
//
// **لماذا ملفٌ مستقلّ؟** `employee_detail_sheet.dart` بلغ ١٣٠٦ أسطر بإضافة
//   حوار إنهاء الخدمة، فتجاوز سقف `tech_debt_guard_test` (١٢٠٠). والحارس
//   أسقط البناء **قبل الدمج** — وهو ثالث دليل عملي على أن الدرس المكتوب لا
//   يحمي إلا إن صار اختباراً.
//
// ⚠️ **الأثر المالي مكتوبٌ في الحوار لا مفهومٌ ضمناً:** «بلا راتب» تُنقِص
//   أيام الاستحقاق، و«براتب» لا تمسّها. ومن يسجّل إجازةً لا يعرف أثرها على
//   الراتب قد يُنقِص راتب موظف بلا قصد.
// ─────────────────────────────────────────────────────────────────────────────

part of 'employees_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// تبويب الإجازات
// ═══════════════════════════════════════════════════════════════════════════

class _LeavesTab extends ConsumerWidget {
  const _LeavesTab({
    required this.employee,
    required this.scrollController,
    required this.onAddLeave,
  });

  final EmployeeModel employee;
  final ScrollController scrollController;
  final VoidCallback onAddLeave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(employeeLeavesProvider(employee.id));
    final fmt = DateFormat('yyyy/MM/dd');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddLeave,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('تسجيل إجازة'),
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('خطأ: $e')),
            data: (leaves) {
              if (leaves.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.beach_access_outlined,
                            size: 56, color: theme.disabledColor),
                        const SizedBox(height: 12),
                        Text('لا إجازات مسجّلة لهذا الموظف',
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: leaves.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final l = leaves[i];
                  final unpaid = l.kind == LeaveKind.unpaid;
                  // الطرفان شاملان — نفس قاعدة العدّ في إنهاء الخدمة
                  final days = l.toDate.difference(l.fromDate).inDays + 1;

                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: unpaid
                            ? theme.colorScheme.errorContainer
                            : theme.colorScheme.secondaryContainer,
                        child: Icon(
                          unpaid
                              ? Icons.money_off_outlined
                              : Icons.beach_access_outlined,
                          size: 18,
                          color: unpaid
                              ? theme.colorScheme.onErrorContainer
                              : theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      title: Text(
                        '${LeaveKind.label(l.kind)} · $days ${days == 1 ? 'يوم' : 'أيام'}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'من ${fmt.format(l.fromDate)} إلى ${fmt.format(l.toDate)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (l.reference.isNotEmpty)
                            Text('بموجب: ${l.reference}',
                                style: const TextStyle(fontSize: 11)),
                          if (l.notes.isNotEmpty)
                            Text(l.notes,
                                style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 18, color: theme.colorScheme.error),
                        tooltip: 'حذف الإجازة',
                        onPressed: () => _confirmDeleteLeave(context, ref, l),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// ⚠️ **التأكيد يذكر الأثر المالي**: حذف إجازةٍ بلا راتب **يزيد** راتب
  ///   شهرها عند إعادة الاستيراد. وحذفٌ يغيّر مالاً لا يقع بلا علم صاحبه.
  Future<void> _confirmDeleteLeave(
    BuildContext context,
    WidgetRef ref,
    EmployeeLeave leave,
  ) async {
    final notifier = ref.read(employeeNotifierProvider.notifier);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الإجازة'),
        content: Text(
          leave.kind == LeaveKind.unpaid
              ? 'ستُحذف الإجازة بلا راتب — فيعود استحقاق أيامها إلى الموظف '
                  'عند إعادة احتساب كشف شهرها.'
              : 'ستُحذف الإجازة براتب. لا أثر على الرواتب — هي سجلٌّ فقط.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) await notifier.deleteLeave(leave.id);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// حوار إنهاء الخدمة
// ═══════════════════════════════════════════════════════════════════════════

/// حوار إنهاء الخدمة — التاريخ والسند والملاحظات (Schema v9)
///
/// ⚠️ **بلا `TextEditingController`** — متغيّرات نصّية داخل
///   `StatefulBuilder`. راجع ع-٠٤: المتحكّم الذي يُتخلَّص منه بعد
///   `await showDialog` يُنتج شاشة حمراء، ويحرسه اختبار آلي.
Future<void> showTerminationDialog(
BuildContext context,
WidgetRef ref,
EmployeeModel emp,
) async {
  var date = DateTime.now();
  var reference = '';
  var notes = '';

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: const Text('إنهاء خدمة الموظف'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                emp.fullName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              // ⚠️ التاريخ **إلزامي وأوّل حقل**: هو ما يقصّ راتب الشهر
              //   الأخير، ووضعُه آخراً يجعله يبدو تفصيلاً اختيارياً
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_busy_outlined),
                title: const Text('تاريخ إنهاء الخدمة'),
                subtitle: Text(
                  '${date.year}/${date.month}/${date.day}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setLocal(() => date = picked);
                },
              ),
              const SizedBox(height: 4),
              TextFormField(
                initialValue: reference,
                decoration: const InputDecoration(
                  labelText: 'بموجب الكتاب المرقّم',
                  hintText: 'مثال: ٣٤٥ في ٢٠٢٦/٨/٢٦',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => reference = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: notes,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => notes = v,
              ),
              const SizedBox(height: 12),
              Text(
                'سيُحتسب راتب شهر الإنهاء حتى هذا اليوم شاملاً إيّاه، '
                'ولن يظهر الموظف في كشوف الشهور التالية.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
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
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.event_busy_outlined, size: 18),
            label: const Text('إنهاء الخدمة'),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true || !context.mounted) return;
  await ref.read(employeeNotifierProvider.notifier).terminate(
        employeeId: emp.id,
        terminationDate: date,
        reference: reference.trim(),
        notes: notes.trim(),
      );
}


// ═══════════════════════════════════════════════════════════════════════════
// حوار تسجيل إجازة
// ═══════════════════════════════════════════════════════════════════════════

/// يُعيد `true` حين سُجِّلت إجازة
///
/// ⚠️ **بلا `TextEditingController`** — متغيّرات نصّية داخل `StatefulBuilder`
///   (درس ع-٠٤، ويحرسه `dialog_controller_lifecycle_test`).
Future<bool> showEmployeeLeaveDialog(
  BuildContext context,
  WidgetRef ref, {
  required int employeeId,
  required String employeeName,
  DateTime? initialFrom,
}) async {
  var from = initialFrom ?? DateTime.now();
  var to = from;
  var kind = LeaveKind.unpaid;
  var reference = '';
  var notes = '';

  final fmt = DateFormat('yyyy/MM/dd');

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        final days = to.difference(from).inDays + 1;
        final invalid = to.isBefore(from);

        return AlertDialog(
          title: const Text('تسجيل إجازة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employeeName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),

                // ── النوع أولاً: هو ما يحدّد الأثر المالي ────────────────
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: LeaveKind.unpaid,
                      label: Text('بلا راتب'),
                      icon: Icon(Icons.money_off_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: LeaveKind.paid,
                      label: Text('براتب'),
                      icon: Icon(Icons.paid_outlined, size: 16),
                    ),
                  ],
                  selected: {kind},
                  onSelectionChanged: (s) => setLocal(() => kind = s.first),
                ),
                const SizedBox(height: 12),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.event_available_outlined),
                  title: const Text('من تاريخ'),
                  subtitle: Text(fmt.format(from),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: from,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setLocal(() {
                        from = picked;
                        // النهاية تتبع البداية حين تسبقها — بدل رسالة خطأ
                        if (to.isBefore(from)) to = from;
                      });
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.event_busy_outlined),
                  title: const Text('إلى تاريخ'),
                  subtitle: Text(fmt.format(to),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: to,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setLocal(() => to = picked);
                  },
                ),

                const SizedBox(height: 8),
                TextFormField(
                  initialValue: reference,
                  decoration: const InputDecoration(
                    labelText: 'بموجب الكتاب المرقّم',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => reference = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: notes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => notes = v,
                ),

                const SizedBox(height: 12),
                // ⚠️ **الأثر مكتوبٌ لا مفهومٌ ضمناً** — والعدد يُحسب أمام
                //   عينه قبل الحفظ فلا يكتشف بعد شهر أنه سجّل يوماً زائداً
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    invalid
                        ? '⚠️ تاريخ النهاية قبل البداية'
                        : kind == LeaveKind.unpaid
                            ? '$days ${days == 1 ? 'يوم' : 'أيام'} — تُنقِص '
                                'أيام الاستحقاق في شهرها (أو شهورها).'
                            : '$days ${days == 1 ? 'يوم' : 'أيام'} — لا تمسّ '
                                'الراتب، تُسجَّل للسجلّ فقط.',
                    style: const TextStyle(fontSize: 12),
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
              onPressed: invalid ? null : () => Navigator.pop(ctx, true),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    ),
  );

  if (saved != true) return false;

  return ref.read(employeeNotifierProvider.notifier).addLeave(
        employeeId: employeeId,
        from: from,
        to: to,
        kind: kind,
        reference: reference.trim(),
        notes: notes.trim(),
      );
}
