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
import '../../providers/database_provider.dart';

// ── أجزاء المكتبة (المرحلة د) ───────────────────────────────────────
// قُسِّم الملف بـ part لا بملفات مستقلة كي تبقى الأصناف خاصة.
part 'employee_detail_sheet.dart';
part 'employee_dialogs.dart';
part 'employee_repayment_sheet.dart';

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

  /// فلتر المشروع — `null` يعني كل المشاريع
  ///
  /// 🔑 بلاغ المالك 2026-08-30: «إذا كان لدينا مشروع البصرة وكركوك وبغداد،
  ///   أريد عند اختيار مشروع أن يظهر موظفوه وحدهم».
  ///
  /// ⚠️ الربط عبر `employees.treasury_id` — وهو **رابط المشروع** بقرار
  ///   المالك: موظفو خزنة البصرة هم موظفو مشروع البصرة. لا حقل مستقلّ.
  int? _projectTreasuryId;

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

  /// **نقل موظفي مشروع إلى آخر دفعةً واحدة** (بلاغ المالك 2026-08-30)
  ///
  /// القدرة كانت موجودة (`reassignTreasury` في الـDAO) لكنها **مدفونة داخل
  /// مسار حذف الخزينة وحده** — تُستدعى حين يحذف المالك خزينةً فيُسأل أين
  /// ينقل موظفيها. فمن أراد النقل بلا حذف لم يجد إليه سبيلاً.
  ///
  /// ⚠️ العدد يُعرَض **قبل** التأكيد: نقلٌ جماعي بلا رقم يجعل المالك يضغط
  ///   على المجهول — وهو ما تجنّبناه في كل عملية جماعية سابقة.
  Future<void> _showBulkReassignDialog(BuildContext context) async {
    final treasuries =
        ref.read(allTreasuriesProvider).valueOrNull ?? const [];
    if (treasuries.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يلزم مشروعان على الأقل لنقل الموظفين بينهما.'),
        ),
      );
      return;
    }

    int? fromId = _projectTreasuryId;
    int? toId;

    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final employees =
              ref.read(allEmployeesProvider).valueOrNull ?? const [];
          final count = fromId == null
              ? 0
              : employees.where((e) => e.treasuryId == fromId).length;

          return AlertDialog(
            title: const Text('نقل موظفي مشروع'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: fromId,
                    decoration: const InputDecoration(
                      labelText: 'من مشروع',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final t in treasuries)
                        DropdownMenuItem(value: t.id, child: Text(t.name)),
                    ],
                    onChanged: (v) => setLocal(() {
                      fromId = v;
                      if (toId == v) toId = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: toId,
                    decoration: const InputDecoration(
                      labelText: 'إلى مشروع',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final t in treasuries)
                        if (t.id != fromId)
                          DropdownMenuItem(value: t.id, child: Text(t.name)),
                    ],
                    onChanged: (v) => setLocal(() => toId = v),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    fromId == null
                        ? 'اختر المشروع المصدر.'
                        : 'سيُنقل $count موظفاً بكل بياناتهم — سلفهم ورواتبهم '
                            'السابقة تبقى كما هي، ويتغيّر مشروعهم فقط.',
                    style: Theme.of(ctx).textTheme.bodySmall,
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
                onPressed: (fromId != null && toId != null && count > 0)
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: Text('انقل $count موظفاً'),
              ),
            ],
          );
        },
      ),
    );

    if (done != true || !mounted) return;

    final moved = await ref
        .read(employeeNotifierProvider.notifier)
        .reassignTreasury(fromTreasuryId: fromId!, toTreasuryId: toId);

    // `context` هنا وسيطٌ مرّر من المستدعي لا `State.context` — فالمحلّل
    // يطلب فحصه هو لا فحص الحالة (قاعدة مرفوعة إلى **خطأ** في هذا المشروع).
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✓ نُقل $moved موظفاً إلى المشروع الجديد')),
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
          // الفلتران يُطبَّقان معاً: البحث النصّي ثم المشروع
          final filtered = employees.where((e) {
            final matchesQuery = _query.isEmpty ||
                e.fullName.toLowerCase().contains(_query.toLowerCase()) ||
                e.phone.contains(_query);
            final matchesProject = _projectTreasuryId == null ||
                e.treasuryId == _projectTreasuryId;
            return matchesQuery && matchesProject;
          }).toList();

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
              // ── فلتر المشروع (الخزينة) + النقل الجماعي ──────────────
              Row(
                children: [
                  Expanded(
                    child: _ProjectFilterBar(
                      selected: _projectTreasuryId,
                      onChanged: (v) =>
                          setState(() => _projectTreasuryId = v),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 28, bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => _showBulkReassignDialog(context),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 17),
                      label: const Text('نقل موظفي مشروع'),
                    ),
                  ),
                ],
              ),

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

    // 🟠 **من عليه سلفة يُلوَّن** (بلاغ المالك 2026-08-30)
    //
    //   المزوّد **مُراقَب هنا أصلاً** (`ref.watch` أعلاه) لعرض المبلغ، فلا
    //   استعلام إضافي — التلوين قراءةٌ ثانية لنفس الرقم.
    //
    //   ولماذا لونٌ لا شارة؟ لأن السؤال «من عليه سلفة؟» يُطرح على **القائمة
    //   كلها** لا على بطاقة بعينها، والعين تمسح الألوان أسرع من النصوص.
    final hasPending = (pendingAsync.valueOrNull ?? 0) > 0;

    return Container(
      decoration: BoxDecoration(
        color: hasPending
            ? const Color(0xFFFFF4E0).withValues(alpha: 0.55)
            : context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: !employee.isActive
              ? Colors.red.withValues(alpha: 0.3)
              : hasPending
                  ? Colors.orange.withValues(alpha: 0.45)
                  : context.colors.border,
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


/// شريط اختيار المشروع — يعزل موظفي مشروع بعينه
///
/// **لماذا شرائح لا قائمة منسدلة؟** المشاريع قليلة (خزينة لكل مشروع)،
/// والشريحة تُظهر الخيارات كلها دفعةً واحدة فيُرى ما هو متاح بلا فتح قائمة.
class _ProjectFilterBar extends ConsumerWidget {
  const _ProjectFilterBar({required this.selected, required this.onChanged});

  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treasuries = ref.watch(allTreasuriesProvider).valueOrNull ?? const [];
    if (treasuries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                label: const Text('كل المشاريع'),
                selected: selected == null,
                onSelected: (_) => onChanged(null),
              ),
            ),
            for (final t in treasuries)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  label: Text(t.name),
                  selected: selected == t.id,
                  onSelected: (_) => onChanged(selected == t.id ? null : t.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
