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

import '../../../core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/payroll_calculator.dart';
import '../../../domain/models/employee_model.dart';
import '../../../domain/models/treasury_model.dart';
import '../../providers/employee_providers.dart';
import '../../providers/payroll_providers.dart';
import '../../widgets/common/password_confirm_dialog.dart';
import '../../providers/provider_read_once.dart';
import '../../providers/treasury_providers.dart';
import '../payroll/payroll_print_actions.dart';

// ── أجزاء المكتبة (المرحلة د) ───────────────────────────────────────
// قُسِّم الملف بـ part لا بملفات مستقلة كي تبقى الأصناف خاصة.
part 'employee_detail_sheet.dart';
part 'employee_dialogs.dart';

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

    final employeesAsync = ref.watch(allEmployeesProvider);


    return Scaffold(
      backgroundColor: context.colors.bg,
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
                    color: context.colors.text,
                  ),
                  decoration: InputDecoration(
                    hintText: 'البحث باسم الموظف أو رقم الهاتف...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: context.colors.subtext,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: context.colors.subtext,
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
                    fillColor: context.colors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: context.colors.border,
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
        backgroundColor: context.colors.gold,
        foregroundColor: context.colors.onGold,
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
    final fmtNum = NumberFormat('#,##0');
    final pendingAsync = ref.watch(pendingAdvancesAmountProvider(employee.id));

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: employee.isActive
              ? (context.colors.border)
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
                    color: context.colors.surface2,
                    border: Border.all(
                      color: context.colors.border,
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
                                color: context.colors.text,
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
                            color: context.colors.subtext,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'الراتب: ${fmtNum.format(employee.basicSalary)} د.ع',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: context.colors.subtext,
                            ),
                          ),
                          if (employee.phone.isNotEmpty) ...[
                            const SizedBox(width: 14),
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: context.colors.subtext,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              employee.phone,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.colors.subtext,
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
                  color: context.colors.subtext,
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
