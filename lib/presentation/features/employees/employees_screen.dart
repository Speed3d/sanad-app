// ─────────────────────────────────────────────────────────────────────────────
// employees_screen.dart — شاشة الموظفين الكاملة
//
// الميزات:
//   - قائمة تفاعلية بجميع الموظفين مع بحث
//   - بطاقة لكل موظف: الاسم، الراتب، الهاتف، حالة النشاط
//   - ورقة تفاصيل (DraggableScrollableSheet) مع:
//       تبويب السلف  — قائمة + منح سلفة + سداد قسط
//       تبويب الرواتب — قائمة + صرف راتب
//   - حوارات: إضافة موظف، تعديل، صرف راتب، منح سلفة، سداد سلفة
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/employee_model.dart';
import '../../../domain/models/treasury_model.dart';
import '../../providers/employee_providers.dart';
import '../../providers/treasury_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// الشاشة الرئيسية
// ═══════════════════════════════════════════════════════════════════════════

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── الاستماع لنتائج العمليات ─────────────────────────────────────────────

  void _listenNotifiers() {
    ref.listen<AsyncValue<String?>>(employeeNotifierProvider, (_, next) {
      _handleResult(next);
    });
    ref.listen<AsyncValue<String?>>(salaryNotifierProvider, (_, next) {
      _handleResult(next);
    });
    ref.listen<AsyncValue<String?>>(advanceNotifierProvider, (_, next) {
      _handleResult(next);
    });
  }

  void _handleResult(AsyncValue<String?> value) {
    value.whenOrNull(
      data: (msg) {
        if (msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.read(employeeNotifierProvider.notifier).reset();
          ref.read(salaryNotifierProvider.notifier).reset();
          ref.read(advanceNotifierProvider.notifier).reset();
        }
      },
      error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(employeeNotifierProvider.notifier).reset();
        ref.read(salaryNotifierProvider.notifier).reset();
        ref.read(advanceNotifierProvider.notifier).reset();
      },
    );
  }

  // ── حوار إضافة موظف ─────────────────────────────────────────────────────

  Future<void> _showCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _EmployeeFormDialog(
        title: 'إضافة موظف جديد',
        onSave: (data) async {
          final ok = await ref.read(employeeNotifierProvider.notifier).createEmployee(
            fullName: data['fullName']!,
            phone: data['phone'] ?? '',
            address: data['address'] ?? '',
            basicSalary: double.tryParse(data['basicSalary'] ?? '0') ?? 0.0,
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

  // ── ورقة التفاصيل ────────────────────────────────────────────────────────

  void _showDetail(EmployeeModel emp) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => _EmployeeDetailSheet(
          employee: emp,
          scrollController: scrollCtrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _listenNotifiers();

    final theme = Theme.of(context);
    final employeesAsync = ref.watch(allEmployeesProvider);

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: employeesAsync.when(
        data: (employees) {
          final filtered = _query.isEmpty
              ? employees
              : employees
                  .where((e) =>
                      e.fullName
                          .toLowerCase()
                          .contains(_query.toLowerCase()) ||
                      e.phone.contains(_query))
                  .toList();

          return Column(
            children: [
              // ── 1. بطاقة ملخص الموظفين الهيروكية ──────────────────────────
              _HeroEmployeeSummaryBar(employees: employees),

              // ── 2. حقل البحث الفوري ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                  decoration: InputDecoration(
                    hintText: 'البحث باسم الموظف أو رقم الهاتف...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE0BC66),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // ── 3. قائمة الموظفين ──────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(
                        isSearch: _query.isNotEmpty,
                        onAdd: _showCreateDialog,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _EmployeeCard(
                          employee: filtered[i],
                          onTap: () => _showDetail(filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: isDark ? const Color(0xFFE0BC66) : AppColors.navy,
        foregroundColor: isDark ? AppColors.navy : Colors.white,
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: const Text(
          'إضافة موظف جديد',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _HeroEmployeeSummaryBar — شريط الملخص الهيروكي للموظفين
// ═══════════════════════════════════════════════════════════════════════════

class _HeroEmployeeSummaryBar extends StatelessWidget {
  final List<EmployeeModel> employees;
  const _HeroEmployeeSummaryBar({required this.employees});

  @override
  Widget build(BuildContext context) {
    int activeCount = 0;
    double totalSalary = 0;

    for (final e in employees) {
      if (e.isActive) {
        activeCount++;
        totalSalary += e.basicSalary;
      }
    }

    final fmtNum = NumberFormat('#,##0');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF18233A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'إجمالي كادر الموظفين',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$activeCount',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE0BC66),
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: 'موظف نشط',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجمالي كتل الأجور الشهرية',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${fmtNum.format(totalSalary)} د.ع',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
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
// بطاقة الموظف في القائمة
// ═══════════════════════════════════════════════════════════════════════════

class _EmployeeCard extends ConsumerWidget {
  final EmployeeModel employee;
  final VoidCallback onTap;

  const _EmployeeCard({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmtNum = NumberFormat('#,##0');
    final pendingAsync = ref.watch(pendingAdvancesAmountProvider(employee.id));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: employee.isActive
              ? (isDark ? AppColors.borderDark : AppColors.borderLight)
              : Colors.red.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                // Avatar الفاخر بالاسم
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      employee.fullName.isNotEmpty ? employee.fullName[0] : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Color(0xFFE0BC66),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // البيانات الرئيسية
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              employee.fullName,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textDark : AppColors.textLight,
                              ),
                            ),
                          ),
                          if (!employee.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'موقوف',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 14,
                            color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'الراتب: ${fmtNum.format(employee.basicSalary)} د.ع',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                            ),
                          ),
                          if (employee.phone.isNotEmpty) ...[
                            const SizedBox(width: 14),
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              employee.phone,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                      pendingAsync.whenOrNull(
                            data: (amt) => amt > 0
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          size: 14,
                                          color: Color(0xFFE0BC66),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'سُلف قائمة: ${fmtNum.format(amt)} د.ع',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFFE0BC66),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : null,
                          ) ??
                          const SizedBox.shrink(),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
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
              Tab(text: 'السلف', icon: Icon(Icons.money_off, size: 16)),
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
// حوار نموذج الموظف (إضافة / تعديل)
// ═══════════════════════════════════════════════════════════════════════════

class _EmployeeFormDialog extends StatefulWidget {
  final String title;
  final Map<String, String?>? initialData;
  final Future<bool> Function(Map<String, String?>) onSave;

  const _EmployeeFormDialog({
    required this.title,
    this.initialData,
    required this.onSave,
  });

  @override
  State<_EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<_EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _salaryCtrl;
  late final TextEditingController _notesCtrl;
  DateTime? _hireDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nameCtrl = TextEditingController(text: d?['fullName'] ?? '');
    _phoneCtrl = TextEditingController(text: d?['phone'] ?? '');
    _addressCtrl = TextEditingController(text: d?['address'] ?? '');
    _salaryCtrl = TextEditingController(text: d?['basicSalary'] ?? '');
    _notesCtrl = TextEditingController(text: d?['notes'] ?? '');
    if (d?['hireDate'] != null) {
      _hireDate = DateTime.tryParse(d!['hireDate']!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _salaryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickHireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hireDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
      helpText: 'تاريخ التعيين',
    );
    if (picked != null && mounted) setState(() => _hireDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await widget.onSave({
      'fullName': _nameCtrl.text,
      'phone': _phoneCtrl.text,
      'address': _addressCtrl.text,
      'basicSalary': _salaryCtrl.text,
      'notes': _notesCtrl.text,
      'hireDate': _hireDate?.toIso8601String(),
    });
    if (ok && mounted) Navigator.pop(context);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmtDate = DateFormat('dd/MM/yyyy', 'ar');
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل *',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'الاسم مطلوب'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _salaryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الراتب الأساسي (د.ع)',
                    prefixIcon: Icon(Icons.payments_outlined, size: 20),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'))
                  ],
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                // تاريخ التعيين
                GestureDetector(
                  onTap: _pickHireDate,
                  // InputDecorator بدل TextFormField+Controller — بلا تسريب
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ التعيين',
                      prefixIcon:
                          Icon(Icons.calendar_today_outlined, size: 20),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      _hireDate != null ? fmtDate.format(_hireDate!) : '',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    prefixIcon: Icon(Icons.notes_outlined, size: 20),
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// حوار صرف الراتب
// ═══════════════════════════════════════════════════════════════════════════

class _PaySalaryDialog extends StatefulWidget {
  final EmployeeModel employee;
  final List<TreasuryModel> treasuries;
  final Future<bool> Function(Map<String, dynamic>) onSave;

  const _PaySalaryDialog({
    required this.employee,
    required this.treasuries,
    required this.onSave,
  });

  @override
  State<_PaySalaryDialog> createState() => _PaySalaryDialogState();
}

class _PaySalaryDialogState extends State<_PaySalaryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _basicCtrl;
  final _additionsCtrl = TextEditingController(text: '0');
  final _deductionsCtrl = TextEditingController(text: '0');
  final _periodCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int? _treasuryId;
  DateTime _paymentDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _basicCtrl = TextEditingController(
      text: widget.employee.basicSalary > 0
          ? widget.employee.basicSalary.toStringAsFixed(0)
          : '',
    );
    // افتراضي للفترة: الشهر الحالي
    final now = DateTime.now();
    final months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    _periodCtrl.text = '${months[now.month]} ${now.year}';
  }

  @override
  void dispose() {
    _basicCtrl.dispose();
    _additionsCtrl.dispose();
    _deductionsCtrl.dispose();
    _periodCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _net =>
      (double.tryParse(_basicCtrl.text) ?? 0) +
      (double.tryParse(_additionsCtrl.text) ?? 0) -
      (double.tryParse(_deductionsCtrl.text) ?? 0);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_treasuryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('اختر الخزينة'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.onSave({
      'treasuryId': _treasuryId,
      'basicSalary': double.tryParse(_basicCtrl.text) ?? 0.0,
      'additions': double.tryParse(_additionsCtrl.text) ?? 0.0,
      'deductions': double.tryParse(_deductionsCtrl.text) ?? 0.0,
      'periodLabel': _periodCtrl.text.trim(),
      'paymentDate': _paymentDate,
      'notes': _notesCtrl.text.trim(),
    });
    if (ok && mounted) Navigator.pop(context);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmtNum = NumberFormat('#,##0', 'ar');
    final fmtDate = DateFormat('dd/MM/yyyy', 'ar');

    return AlertDialog(
      title: Text('صرف راتب: ${widget.employee.fullName}'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // الفترة
                TextFormField(
                  controller: _periodCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الفترة *',
                    hintText: 'مثال: يناير 2025',
                    prefixIcon: Icon(Icons.event_note_outlined, size: 20),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'الفترة مطلوبة' : null,
                ),
                const SizedBox(height: 12),
                // الخزينة
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  hint: const Text('اختر الخزينة'),
                  decoration: const InputDecoration(
                    labelText: 'الخزينة *',
                    prefixIcon: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20),
                  ),
                  items: widget.treasuries
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _treasuryId = v),
                  validator: (v) =>
                      v == null ? 'اختر الخزينة' : null,
                ),
                const SizedBox(height: 12),
                // الراتب الأساسي
                TextFormField(
                  controller: _basicCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الراتب الأساسي (د.ع) *',
                    prefixIcon: Icon(Icons.attach_money, size: 20),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'))
                  ],
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    if (val == null) return 'رقم غير صالح';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // الإضافات والخصومات
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _additionsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'إضافات',
                          prefixIcon: Icon(Icons.add_circle_outline,
                              size: 20, color: Colors.green),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'))
                        ],
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _deductionsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'خصومات',
                          prefixIcon: Icon(Icons.remove_circle_outline,
                              size: 20, color: Colors.red),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'))
                        ],
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // الصافي
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الصافي:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${fmtNum.format(_net)} د.ع',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _net > 0
                              ? Theme.of(context).colorScheme.primary
                              : Colors.red,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // التاريخ
                GestureDetector(
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _paymentDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      locale: const Locale('ar'),
                    );
                    if (p != null && mounted) {
                      setState(() => _paymentDate = p);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الصرف',
                      prefixIcon:
                          Icon(Icons.calendar_today_outlined, size: 20),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(fmtDate.format(_paymentDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    prefixIcon: Icon(Icons.notes_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('صرف الراتب'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// حوار منح سلفة
// ═══════════════════════════════════════════════════════════════════════════

class _GrantAdvanceDialog extends StatefulWidget {
  final EmployeeModel employee;
  final List<TreasuryModel> treasuries;
  final Future<bool> Function(Map<String, dynamic>) onSave;

  const _GrantAdvanceDialog({
    required this.employee,
    required this.treasuries,
    required this.onSave,
  });

  @override
  State<_GrantAdvanceDialog> createState() => _GrantAdvanceDialogState();
}

class _GrantAdvanceDialogState extends State<_GrantAdvanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  int? _treasuryId;
  String _currency = 'IQD';
  DateTime _advanceDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_treasuryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('اختر الخزينة'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.onSave({
      'treasuryId': _treasuryId,
      'amount': double.tryParse(_amountCtrl.text) ?? 0.0,
      'currency': _currency,
      'advanceDate': _advanceDate,
      'reason': _reasonCtrl.text.trim(),
    });
    if (ok && mounted) Navigator.pop(context);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmtDate = DateFormat('dd/MM/yyyy', 'ar');
    return AlertDialog(
      title: Text('منح سلفة: ${widget.employee.fullName}'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // الخزينة
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  hint: const Text('اختر الخزينة'),
                  decoration: const InputDecoration(
                    labelText: 'الخزينة *',
                    prefixIcon: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20),
                  ),
                  items: widget.treasuries
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _treasuryId = v),
                  validator: (v) =>
                      v == null ? 'اختر الخزينة' : null,
                ),
                const SizedBox(height: 12),
                // المبلغ + العملة
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _amountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'المبلغ *',
                          prefixIcon:
                              Icon(Icons.attach_money, size: 20),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,3}'))
                        ],
                        validator: (v) {
                          final val = double.tryParse(v ?? '');
                          if (val == null || val <= 0) {
                            return 'أدخل مبلغاً صالحاً';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          const SizedBox(height: 4),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                  value: 'IQD', label: Text('د.ع')),
                              ButtonSegment(
                                  value: 'USD', label: Text('\$')),
                            ],
                            selected: {_currency},
                            onSelectionChanged: (s) =>
                                setState(() => _currency = s.first),
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // التاريخ
                GestureDetector(
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _advanceDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      locale: const Locale('ar'),
                    );
                    if (p != null && mounted) {
                      setState(() => _advanceDate = p);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ السلفة',
                      prefixIcon:
                          Icon(Icons.calendar_today_outlined, size: 20),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(fmtDate.format(_advanceDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'السبب / الغرض',
                    prefixIcon: Icon(Icons.notes_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('منح السلفة'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// حوار سداد سلفة
// ═══════════════════════════════════════════════════════════════════════════

class _RepayAdvanceDialog extends StatefulWidget {
  final CashAdvanceModel advance;
  final List<TreasuryModel> treasuries;
  final Future<bool> Function(Map<String, dynamic>) onSave;

  const _RepayAdvanceDialog({
    required this.advance,
    required this.treasuries,
    required this.onSave,
  });

  @override
  State<_RepayAdvanceDialog> createState() => _RepayAdvanceDialogState();
}

class _RepayAdvanceDialogState extends State<_RepayAdvanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  final _notesCtrl = TextEditingController();
  int? _treasuryId;
  String _method = 'cash';
  DateTime _repaymentDate = DateTime.now();
  bool _saving = false;

  static const _methods = {
    'cash': 'نقداً',
    'salary_deduction': 'خصم من الراتب',
    'bank_transfer': 'تحويل بنكي',
  };

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.advance.remainingAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_treasuryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('اختر الخزينة'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.onSave({
      'treasuryId': _treasuryId,
      'amount': double.tryParse(_amountCtrl.text) ?? 0.0,
      'repaymentDate': _repaymentDate,
      'method': _method,
      'notes': _notesCtrl.text.trim(),
    });
    if (ok && mounted) Navigator.pop(context);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmtNum = NumberFormat('#,##0', 'ar');
    final fmtDate = DateFormat('dd/MM/yyyy', 'ar');

    return AlertDialog(
      title: const Text('تسجيل سداد سلفة'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // معلومات السلفة
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المتبقي:',
                          style: TextStyle(
                              color: Colors.orange.shade800)),
                      Text(
                        '${fmtNum.format(widget.advance.remainingAmount)} ${widget.advance.currency == 'IQD' ? 'د.ع' : '\$'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // الخزينة
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  hint: const Text('اختر الخزينة'),
                  decoration: const InputDecoration(
                    labelText: 'الخزينة *',
                    prefixIcon: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20),
                  ),
                  items: widget.treasuries
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _treasuryId = v),
                  validator: (v) =>
                      v == null ? 'اختر الخزينة' : null,
                ),
                const SizedBox(height: 12),
                // مبلغ السداد
                TextFormField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'مبلغ السداد *',
                    prefixIcon: Icon(Icons.attach_money, size: 20),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,3}'))
                  ],
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    if (val == null || val <= 0) return 'مبلغ غير صالح';
                    if (val > widget.advance.remainingAmount + 0.001) {
                      return 'أكبر من المبلغ المتبقي';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // طريقة السداد
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'طريقة السداد',
                    prefixIcon:
                        Icon(Icons.payment_outlined, size: 20),
                  ),
                  items: _methods.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _method = v ?? 'cash'),
                ),
                const SizedBox(height: 12),
                // التاريخ
                GestureDetector(
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _repaymentDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      locale: const Locale('ar'),
                    );
                    if (p != null && mounted) {
                      setState(() => _repaymentDate = p);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ السداد',
                      prefixIcon: Icon(
                          Icons.calendar_today_outlined,
                          size: 20),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(fmtDate.format(_repaymentDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    prefixIcon: Icon(Icons.notes_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green.shade700,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('تسجيل السداد'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// مكونات مساعدة
// ═══════════════════════════════════════════════════════════════════════════

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _SmallBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  final VoidCallback onAdd;

  const _EmptyState({required this.isSearch, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'لا نتائج للبحث' : 'لا يوجد موظفون بعد',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!isSearch) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('إضافة أول موظف'),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onAction;

  const _TabEmptyState({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add, size: 18),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
