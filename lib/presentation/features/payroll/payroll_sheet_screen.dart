// ─────────────────────────────────────────────────────────────────────────────
// payroll_sheet_screen.dart — كشف رواتب شهر واحد (Schema v7)
//
// أثقل شاشة في نظام الرواتب: جدول تحرير حيّ + التسديد.
//
// **مقسَّمة بـ`part` منذ البداية** لا بعد أن تتضخّم: الجدول والحوارات في
// `payroll_sheet_widgets.dart`. الأصناف تبقى خاصة (`_X`) ولا تتسرّب، ويحرس
// الحدَّ (١٢٠٠ سطر) `tech_debt_guard_test`.
//
// **قرارات الواجهة هنا وأسبابها:**
//   • **عرض الجدول يُحسَب من تعداد الأعمدة لا يُكتب رقماً** — في مشروع DMS
//     المرجعي كان الرقم مكتوباً بيد (1476) بينما مجموع الأعمدة 1538، فتجاوزه
//     بـ٩٤ بكسل وظهر «RIGHT OVERFLOWED» فوق عمود الاسم **فحجب أسماء
//     الموظفين**. وأخطأ فيه كاتبه مرّتين.
//   • **لا `TextEditingController` يُتخلَّص منه بعد `await showDialog`** —
//     الـ await ينتهي لحظة `Navigator.pop` لا لحظة اختفاء الحوار (ع-٠٤).
//     الحوارات هنا تستعمل `initialValue`/`onChanged` بلا متحكّمات.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/payroll_calculator.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/payroll_dao.dart';
import '../../../domain/models/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payroll_providers.dart';
import '../../providers/treasury_providers.dart';
import '../../widgets/common/app_components.dart';

part 'payroll_sheet_widgets.dart';

class PayrollSheetScreen extends ConsumerWidget {
  final int periodId;

  const PayrollSheetScreen({super.key, required this.periodId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final periodAsync = ref.watch(payrollPeriodProvider(periodId));
    final entriesAsync = ref.watch(payrollEntriesProvider(periodId));
    final totalsAsync = ref.watch(payrollTotalsProvider(periodId));

    // رسائل النجاح والخطأ من المزوّد — تُعرَض مرّة وتُصفَّر
    ref.listen(payrollNotifierProvider, (prev, next) {
      next.whenOrNull(
        data: (msg) {
          if (msg == null) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
          ref.read(payrollNotifierProvider.notifier).reset();
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$e'),
              backgroundColor: colors.danger,
              duration: const Duration(seconds: 6),
            ),
          );
          ref.read(payrollNotifierProvider.notifier).reset();
        },
      );
    });

    return Scaffold(
      backgroundColor: colors.bg,
      body: periodAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (period) {
          if (period == null) {
            return AppEmptyState(
              icon: Icons.search_off_rounded,
              message: 'كشف الرواتب غير موجود',
              subtitle: 'قد يكون حُذف. عُد إلى قائمة الأشهر.',
              actionLabel: 'رجوع',
              onAction: () => _goBack(context),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetHeader(
                period: period,
                totals: totalsAsync.valueOrNull,
              ),
              Expanded(
                child: entriesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (entries) => entries.isEmpty
                      ? AppEmptyState(
                          icon: Icons.people_outline_rounded,
                          message: 'الكشف فارغ',
                          subtitle:
                              'استورد ملف رواتب هذا الشهر لتظهر سطوره.',
                          actionLabel: 'استيراد ملف',
                          onAction: () =>
                              context.push(AppRoutes.payrollImport),
                        )
                      : _EntriesTable(
                          period: period,
                          entries: entries,
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// رجوع بوجهة احتياطية صريحة
  ///
  /// ⚠️ `context.pop()` وحدها تفشل صامتةً حين يُفتح المسار بـ`go` لا `push`
  /// — فلا شيء مكدَّس تحته (العطل ع-٠٧).
  static void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.payroll);
    }
  }
}
