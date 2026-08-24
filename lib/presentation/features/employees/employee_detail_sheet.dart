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
    _tabCtrl = TabController(length: 2, vsync: this);
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

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الموظف'),
        content: Text(
          'هل أنت متأكد من حذف "${emp.fullName}"؟\n'
          'سيُحفَظ سجل رواتبه وسلفه.',
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
        await ref.read(allTreasuriesProvider.future);
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
                periodLabel: data['periodLabel'] as String,
                paymentDate: data['paymentDate'] as DateTime,
                notes: data['notes'] as String,
              );
        },
      ),
    );
  }

  // ── حوار منح سلفة ────────────────────────────────────────────────────────

  Future<void> _showGrantAdvanceDialog() async {
    final treasuries = await ref.read(allTreasuriesProvider.future);
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
                      _SmallBadge(
                        label: emp.isActive ? 'نشط' : 'موقوف',
                        color: emp.isActive
                            ? Colors.green.shade100
                            : theme.colorScheme.errorContainer,
                        textColor: emp.isActive
                            ? Colors.green.shade800
                            : theme.colorScheme.onErrorContainer,
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
                      case 'toggle':
                        await ref
                            .read(employeeNotifierProvider.notifier)
                            .toggleActive(
                              emp.id,
                              isActive: !emp.isActive,
                            );
                      case 'delete':
                        await _confirmDelete();
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
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            emp.isActive
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(emp.isActive ? 'إيقاف' : 'تفعيل'),
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
              ],
            ),
          ],
        ),
      ),
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

class _SalaryCard extends StatelessWidget {
  final SalaryPaymentModel salary;

  const _SalaryCard({required this.salary});

  @override
  Widget build(BuildContext context) {
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
