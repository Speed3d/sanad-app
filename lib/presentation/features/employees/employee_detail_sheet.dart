// ─────────────────────────────────────────────────────────────────────────────
// employee_detail_sheet.dart — ورقة تفاصيل الموظف وتبويباتها
//
// جزء من مكتبة `employees_screen.dart` — مفصول عنها لأن الملف الأصل بلغ
// **٢٤٨٩ سطراً** (أكبر ملف في المشروع بفارق كبير)، فصار تصفّحه وتعديله
// عبئاً بذاته.
//
// نستعمل `part` لا ملفاً مستقلاً كي تبقى الأصناف **خاصة** (`_X`) كما هي،
// فلا تتسرّب إلى بقية المشروع ولا نحتاج إعادة تسميتها.
//
// يحوي: ورقة التفاصيل · تبويب سلف الموظف · تبويب الرواتب · بطاقتيهما.
// ─────────────────────────────────────────────────────────────────────────────

part of 'employees_screen.dart';

// ورقة التفاصيل
// ═══════════════════════════════════════════════════════════════════════════

class _EmployeeDetailSheet extends ConsumerStatefulWidget {
  final EmployeeModel employee;
  final ScrollController scrollController;

  const _EmployeeDetailSheet({
    required this.employee,
    required this.scrollController,
  });

  @override
  ConsumerState<_EmployeeDetailSheet> createState() =>
      _EmployeeDetailSheetState();
}

class _EmployeeDetailSheetState
    extends ConsumerState<_EmployeeDetailSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  EmployeeModel get emp => widget.employee;

  // ── حوار تعديل الموظف ────────────────────────────────────────────────────

  Future<void> _showEditDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _EmployeeFormDialog(
        title: 'تعديل بيانات ${emp.fullName}',
        initialData: {
          'fullName': emp.fullName,
          'phone': emp.phone,
          'address': emp.address,
          'basicSalary': emp.basicSalary.toStringAsFixed(0),
          'notes': emp.notes,
          'hireDate': emp.hireDate?.toIso8601String(),
        },
        onSave: (data) async {
          final ok = await ref
              .read(employeeNotifierProvider.notifier)
              .updateEmployee(
                emp,
                fullName: data['fullName']!,
                phone: data['phone'] ?? '',
                address: data['address'] ?? '',
                basicSalary:
                    double.tryParse(data['basicSalary'] ?? '0') ?? 0.0,
                hireDate: data['hireDate'] != null
                    ? DateTime.tryParse(data['hireDate']!)
                    : null,
                notes: data['notes'] ?? '',
              );
          return ok;
        },
      ),
    );
  }

  // ── تأكيد الحذف ──────────────────────────────────────────────────────────

  // 📌 حوارا **إنهاء الخدمة** و**الإجازة** جسمُهما في
  //    `employee_leaves_ui.dart`: نُقلا حين تجاوز هذا الملف سقف ١٢٠٠ سطر،
  //    ومكانهما هناك صحيح — وجهان لدورة حياة الخدمة (Schema v9).

  Future<void> _confirmDelete() async {
    // 🔑 الأثر المالي يُقرأ **قبل** الحوار، فيقول للمالك ما يمنع الحذف بدل
    //   أن يضغط «حذف» ثم يُصفَع برسالة رفض. والحارس المُلزِم في الـDAO.
    final footprint = await ref.read(appDatabaseProvider).employeesDao
        .getEmployeeFinancialFootprint(emp.id);
    final blocked =
        footprint.unpaidAdvances > 0 || footprint.salaryRows > 0;
    if (!mounted) return;

    if (blocked) {
      final reasons = <String>[
        if (footprint.unpaidAdvances > 0)
          '• عليه ${footprint.unpaidAdvances} سلفة غير مسدَّدة '
              '(متبقٍّ ${footprint.advanceBalance.toStringAsFixed(0)})',
        if (footprint.salaryRows > 0)
          '• له ${footprint.salaryRows} سطر راتب في كشوف سابقة',
      ].join('\n');

      final disable = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('لا يمكن حذف هذا الموظف'),
          content: Text(
            '«${emp.fullName}» له أثر مالي:\n\n$reasons\n\n'
            'حذفه يجعل التقارير تقرأ أرقاماً لصاحبٍ لا وجود له.\n\n'
            'البديل: **تعطيله** — يبقى سجلّه وتقاريره كما هي، ولا يظهر في '
            'كشوف الرواتب الجديدة.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('تراجع'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.block_outlined, size: 16),
              label: const Text('عطّل الموظف'),
            ),
          ],
        ),
      );

      if (disable == true && mounted) {
        final ok = await ref
            .read(employeeNotifierProvider.notifier)
            .setStatus(emp.id, EmployeeStatus.terminated);
        if (ok && mounted) Navigator.of(context).pop();
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الموظف'),
        content: Text(
          'هل أنت متأكد من حذف "${emp.fullName}"؟\n'
          'لا أثر مالي له — لا سلف ولا رواتب سابقة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(employeeNotifierProvider.notifier)
          .deleteEmployee(emp.id);
      if (mounted) Navigator.pop(context);
    }
  }

  // ── حوار صرف الراتب ──────────────────────────────────────────────────────

  Future<void> _showPaySalaryDialog() async {
    final treasuries =
        await ref.readOnce(
        allTreasuriesProvider, allTreasuriesProvider.future);
    final active = treasuries.where((t) => t.isActive).toList();
    if (active.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد خزائن نشطة'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _PaySalaryDialog(
        employee: emp,
        treasuries: active,
        onSave: (data) async {
          return ref.read(salaryNotifierProvider.notifier).paySalary(
                employeeId: emp.id,
                employeeName: emp.fullName,
                treasuryId: data['treasuryId'] as int,
                basicSalary: data['basicSalary'] as double,
                additions: data['additions'] as double,
                deductions: data['deductions'] as double,
                year: data['year'] as int,
                month: data['month'] as int,
                paymentDate: data['paymentDate'] as DateTime,
                notes: data['notes'] as String,
              );
        },
      ),
    );
  }

  // ── حوار منح سلفة ────────────────────────────────────────────────────────

  Future<void> _showGrantAdvanceDialog() async {
    final treasuries = await ref.readOnce(
        allTreasuriesProvider, allTreasuriesProvider.future);
    final active = treasuries.where((t) => t.isActive).toList();
    if (active.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد خزائن نشطة'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _GrantAdvanceDialog(
        employee: emp,
        treasuries: active,
        onSave: (data) async {
          return ref.read(advanceNotifierProvider.notifier).grantAdvance(
                employeeId: emp.id,
                employeeName: emp.fullName,
                treasuryId: data['treasuryId'] as int,
                amount: data['amount'] as double,
                currency: data['currency'] as String,
                advanceDate: data['advanceDate'] as DateTime,
                reason: data['reason'] as String,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmtNum = NumberFormat('#,##0', 'ar');
    final isOperating = ref.watch(employeeNotifierProvider).isLoading ||
        ref.watch(salaryNotifierProvider).isLoading ||
        ref.watch(advanceNotifierProvider).isLoading;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    emp.fullName.isNotEmpty ? emp.fullName[0] : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp.fullName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (emp.phone.isNotEmpty)
                        Text(
                          emp.phone,
                          style:
                              theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 4),
                      // شارة الحالة الثلاثية (Schema v8) — التسمية من
                      // `EmployeeStatus` لا مكتوبة هنا: ترجمةٌ منسوخة في
                      // ثلاث شاشات تُصحَّح في واحدة وتُنسى في اثنتين (ع-٤٧)
                      _SmallBadge(
                        label: EmployeeStatus.label(emp.status),
                        color: switch (emp.status) {
                          EmployeeStatus.active => Colors.green.shade100,
                          EmployeeStatus.leave => Colors.amber.shade100,
                          _ => theme.colorScheme.errorContainer,
                        },
                        textColor: switch (emp.status) {
                          EmployeeStatus.active => Colors.green.shade800,
                          EmployeeStatus.leave => Colors.amber.shade900,
                          _ => theme.colorScheme.onErrorContainer,
                        },
                      ),
                    ],
                  ),
                ),
                // أزرار الإجراءات
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  enabled: !isOperating,
                  onSelected: (action) async {
                    switch (action) {
                      case 'edit':
                        await _showEditDialog();
                      case 'dept':
                        await _showAssignDepartmentDialog(context, ref, emp);
                      case 'delete':
                        await _confirmDelete();
                      // بقيّة الخيارات حالات الموظف الثلاث
                      default:
                        if (!EmployeeStatus.all.contains(action)) return;

                        // ⚠️ **إنهاء الخدمة يمرّ بحواره لا بالمبدّل مباشرةً**
                        //   (Schema v9 — طلب المالك 2026-09-02): الحالة بلا
                        //   تاريخ تجعل الراتب يُحسب شهراً كاملاً لمن خرج في
                        //   اليوم الخامس. والتاريخ هو **جوهر** القرار لا
                        //   تفصيلاً فيه.
                        if (action == EmployeeStatus.terminated) {
                          await showTerminationDialog(context, ref, emp);
                          return;
                        }

                        // العودة إلى الخدمة تمحو التاريخ والسند معاً — وإلا
                        // بقي تاريخُ إنهاءٍ قديم يقصّ راتبه بعد عودته
                        if (action == EmployeeStatus.active &&
                            emp.status == EmployeeStatus.terminated) {
                          await ref
                              .read(employeeNotifierProvider.notifier)
                              .reinstate(emp.id);
                          return;
                        }

                        await ref
                            .read(employeeNotifierProvider.notifier)
                            .setStatus(emp.id, action);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('تعديل البيانات'),
                        ],
                      ),
                    ),
                    // نقل بين الأقسام **بابه هنا** لا بالسحب: قرارٌ إداري
                    // يُتَّخذ بوعي لا أثرٌ جانبيّ لسحبةٍ أخطأت هدفها
                    const PopupMenuItem(
                      value: 'dept',
                      child: Row(
                        children: [
                          Icon(Icons.category_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('نقل إلى قسم…'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    // ⚠️ **و«في إجازة» ليست في القائمة** (قرار المالك
                    //   2026-09-03): صارت تُشتقّ من جدول الإجازات لا تُضبط
                    //   بيد. وإبقاء الضبط اليدوي مع الاشتقاق يعني كاتبين
                    //   لمعنىً واحد يتنازعانه — وهو ما جعل الفلتر يكذب.
                    //   من أراد إجازةً يسجّلها بتاريخيها من تبويب الإجازات.
                    for (final s in EmployeeStatus.manuallySettable)
                      PopupMenuItem(
                        value: s,
                        enabled: s != emp.status,
                        child: Row(
                          children: [
                            Icon(
                              s == emp.status
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(EmployeeStatus.label(s)),
                          ],
                        ),
                      ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18,
                              color:
                                  Theme.of(context).colorScheme.error),
                          const SizedBox(width: 10),
                          Text(
                            'حذف',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── إحصائيات سريعة ──────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.payments_outlined,
                  label: 'الراتب',
                  value: '${fmtNum.format(emp.basicSalary)} د.ع',
                  color: theme.colorScheme.primaryContainer,
                ),
                const SizedBox(width: 8),
                Consumer(
                  builder: (ctx, r, _) {
                    final pendingAsync =
                        r.watch(pendingAdvancesAmountProvider(emp.id));
                    return pendingAsync.whenOrNull(
                          data: (amt) => _StatChip(
                            icon: Icons.warning_amber_rounded,
                            label: 'سلف معلّقة',
                            value: '${fmtNum.format(amt)} د.ع',
                            color: amt > 0
                                ? Colors.orange.shade100
                                : Colors.green.shade50,
                          ),
                        ) ??
                        const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // ── تبويبات ──────────────────────────────────────────────────────
          TabBar(
            controller: _tabCtrl,
            tabs: const [
              Tab(text: 'سلف الموظف', icon: Icon(Icons.money_off, size: 16)),
              Tab(
                text: 'الرواتب',
                icon: Icon(Icons.payments_outlined, size: 16),
              ),
              Tab(
                text: 'الإجازات',
                icon: Icon(Icons.beach_access_outlined, size: 16),
              ),
              // طلب المالك (2026-09-03): «سجل حركات في كل صفحة موظف»
              Tab(
                text: 'السجل',
                icon: Icon(Icons.history_rounded, size: 16),
              ),
            ],
            labelPadding: EdgeInsets.zero,
          ),
          const Divider(height: 1),

          // ── محتوى التبويبات ──────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _AdvancesTab(
                  employee: emp,
                  scrollController: widget.scrollController,
                  onGrantAdvance: _showGrantAdvanceDialog,
                ),
                _SalariesTab(
                  employee: emp,
                  scrollController: widget.scrollController,
                  onPaySalary: _showPaySalaryDialog,
                ),
                _LeavesTab(
                  employee: emp,
                  scrollController: widget.scrollController,
                  onAddLeave: () => showEmployeeLeaveDialog(
                    context,
                    ref,
                    employeeId: emp.id,
                    employeeName: emp.fullName,
                  ),
                ),
                _EventsTab(
                  employee: emp,
                  scrollController: widget.scrollController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// تبويب السلف
// ═══════════════════════════════════════════════════════════════════════════

class _AdvancesTab extends ConsumerWidget {
  final EmployeeModel employee;
  final ScrollController scrollController;
  final VoidCallback onGrantAdvance;

  const _AdvancesTab({
    required this.employee,
    required this.scrollController,
    required this.onGrantAdvance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advancesAsync =
        ref.watch(advancesByEmployeeProvider(employee.id));
    final theme = Theme.of(context);

    return advancesAsync.when(
      data: (advances) {
        if (advances.isEmpty) {
          return _TabEmptyState(
            icon: Icons.money_off_outlined,
            message: 'لا توجد سلف لهذا الموظف',
            buttonLabel: 'منح سلفة',
            onAction: onGrantAdvance,
          );
        }
        return Stack(
          children: [
            ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: advances.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _AdvanceCard(
                advance: advances[i],
                treasuries: ref.watch(allTreasuriesProvider).valueOrNull ?? [],
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: FilledButton.icon(
                  onPressed: onGrantAdvance,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('منح سلفة جديدة'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.tertiary,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator.adaptive()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// تبويب الرواتب
// ═══════════════════════════════════════════════════════════════════════════

class _SalariesTab extends ConsumerWidget {
  final EmployeeModel employee;
  final ScrollController scrollController;
  final VoidCallback onPaySalary;

  const _SalariesTab({
    required this.employee,
    required this.scrollController,
    required this.onPaySalary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salariesAsync =
        ref.watch(salariesByEmployeeProvider(employee.id));
    final theme = Theme.of(context);

    return salariesAsync.when(
      data: (salaries) {
        if (salaries.isEmpty) {
          return _TabEmptyState(
            icon: Icons.payments_outlined,
            message: 'لا توجد رواتب مسجَّلة',
            buttonLabel: 'صرف راتب',
            onAction: onPaySalary,
          );
        }
        return Stack(
          children: [
            ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: salaries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _SalaryCard(salary: salaries[i]),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: FilledButton.icon(
                  onPressed: onPaySalary,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('صرف راتب'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator.adaptive()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// بطاقة السلفة
// ═══════════════════════════════════════════════════════════════════════════

class _AdvanceCard extends ConsumerWidget {
  final CashAdvanceModel advance;
  final List<TreasuryModel> treasuries;

  const _AdvanceCard({required this.advance, required this.treasuries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmtNum = NumberFormat('#,##0', 'ar');
    final fmtDate = DateFormat('dd/MM/yyyy', 'ar');

    final statusColor = switch (advance.status) {
      'paid' => Colors.green,
      'partial' => Colors.blue,
      'written_off' => Colors.grey,
      _ => Colors.orange,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        // الضغط يفتح **كيف سُدّدت** — دفعةً دفعة بمصدر كل واحدة
        onTap: () => _showRepaymentDetails(context, ref, advance),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // السطر الأول: المبلغ + الحالة
            Row(
              children: [
                Text(
                  '${fmtNum.format(advance.amount)} ${advance.currency == 'IQD' ? 'د.ع' : '\$'}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade700,
                  ),
                ),
                const Spacer(),
                _SmallBadge(
                  label: advance.statusDisplayName,
                  color: statusColor.withValues(alpha: 0.15),
                  textColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // شريط التقدم
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: advance.repaymentProgress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: statusColor,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            // التفاصيل
            Row(
              children: [
                Text(
                  'مسدَّد: ${fmtNum.format(advance.totalRepaid)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  'متبقي: ${fmtNum.format(advance.remainingAmount)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: advance.remainingAmount > 0
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                  ),
                ),
              ],
            ),
            if (advance.reason.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                advance.reason,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                  fmtDate.format(advance.advanceDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                // زر السداد إذا كانت معلّقة
                if (advance.isPending)
                  TextButton.icon(
                    onPressed: () => _showRepayDialog(context, ref),
                    icon: const Icon(Icons.payments_outlined, size: 14),
                    label: const Text('سداد', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                // 🔑 **إلغاء السلفة** (طلب المالك 2026-08-27): قد يُعيد
                //   الموظف المبلغ في يومه، فيُلغى كل شيء ويعود الرصيد كما
                //   كان. وقبله كان `softDeleteAdvance` موجوداً في الـDAO
                //   **بلا أي زرّ يستدعيه** — أي ميزةٌ غير موجودة.
                TextButton.icon(
                  onPressed: () => _confirmCancelAdvance(context, ref),
                  icon: const Icon(Icons.undo_rounded, size: 14),
                  label: const Text('إلغاء', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  /// **كيف سُدّدت هذه السلفة؟** — دفعةً دفعة بمصدر كل واحدة
  ///
  /// 🔑 بلاغ المالك 2026-08-30: «سلفة مليون سُدّدت على دفعتين: ٥٠٠ ألف
  ///   نقداً و٥٠٠ ألف خصماً من الراتب. أريد عند الضغط عليها أن أرى كيف
  ///   سُدّدت — بأي سند وبرواتب أي شهر.»
  ///
  ///   البيانات كانت كلها في `cash_advance_repayments` منذ البداية؛ ما كان
  ///   ينقص هو **العرض** — نمط ع-٠٦ نفسه بصورة أخفّ.
  Future<void> _showRepaymentDetails(
    BuildContext context,
    WidgetRef ref,
    CashAdvanceModel advance,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _RepaymentDetailsSheet(advance: advance),
    );
  }

  /// إلغاء السلفة — **بسبب مكتوب وكلمة مرور** (ع-٣٨)
  ///
  /// ⚠️ كلمة المرور ليست تشديداً بلا سبب: العملية تُرجع مالاً خرج من
  ///   الخزينة وتمحو دَيناً على موظف. والجلسة المفتوحة تُثبت أن أحداً سجّل
  ///   الدخول، لا أن **صاحبها** هو من يضغط الآن (طلب المالك).
  Future<void> _confirmCancelAdvance(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final money = NumberFormat('#,##0', 'ar');
    var reason = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('إلغاء السلفة'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سيُلغى كل شيء ويعود الرصيد كما كان:\n'
                  '• السلفة (${money.format(advance.amount)} '
                  '${advance.currency == 'IQD' ? 'د.ع' : '\$'}) وسند صرفها\n'
                  '• وأقساطها المسدَّدة وسنداتها',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: reason,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'سبب الإلغاء *',
                    hintText: 'مثال: أعاد المبلغ في يومه',
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
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              onPressed: reason.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('إلغاء السلفة'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // 🔑 تأكيد الهويّة **بعد** جمع السبب وقبل أي كتابة
    final identityOk = await confirmWithPassword(
      context,
      ref,
      action: 'إلغاء سلفة الموظف',
      impact: 'سيرجع ${money.format(advance.amount)} د.ع إلى الخزينة '
          'وتُمحى السلفة وأقساطها.',
    );
    if (!identityOk) return;

    await ref.read(advanceNotifierProvider.notifier).cancelEmployeeAdvance(
          advanceId: advance.id,
          reason: reason,
        );
  }

  Future<void> _showRepayDialog(BuildContext context, WidgetRef ref) async {
    final treasuriesAsync = ref.read(allTreasuriesProvider);
    final active = (treasuriesAsync.valueOrNull ?? [])
        .where((t) => t.isActive)
        .toList();
    if (active.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد خزائن نشطة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => _RepayAdvanceDialog(
        advance: advance,
        treasuries: active,
        onSave: (data) => ref.read(advanceNotifierProvider.notifier).repayAdvance(
              advance: advance,
              treasuryId: data['treasuryId'] as int,
              repaymentAmount: data['amount'] as double,
              repaymentDate: data['repaymentDate'] as DateTime,
              method: data['method'] as String,
              notes: data['notes'] as String,
            ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// بطاقة الراتب
// ═══════════════════════════════════════════════════════════════════════════
