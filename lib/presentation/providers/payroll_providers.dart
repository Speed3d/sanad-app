// ─────────────────────────────────────────────────────────────────────────────
// payroll_providers.dart — مزوّدات كشوف الرواتب (Schema v7)
//
// **تقسيم المسؤولية:**
//   `PayrollRepository` → قواعد العمل والحرّاس (الرصيد · الفترة · السالب)
//   هذا الملف           → **الصلاحيات** و**سجل التدقيق** وحالة الواجهة
//
// ⚠️ فحص الصلاحية هنا لا في الشاشة: الشاشة تُخفي الزرّ، وهذا يمنع العملية.
//   إخفاء زرٍّ ليس حراسةً — أي مسار آخر يصل للمزوّد يتجاوزه.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/auth/permissions.dart';
import '../../core/services/payroll_calculator.dart';
import '../../core/services/payroll_name_matcher.dart';
import '../../core/utils/audit_logger.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/payroll_dao.dart';
import '../../data/repositories/payroll_repository.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/user_model.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'repository_providers.dart';

part 'payroll_providers.g.dart';

// ═══════════════════════════════════════════════════════════════════════════
// القراءة
// ═══════════════════════════════════════════════════════════════════════════

/// سنوات الرواتب المشتقّة من الكشوف — الأحدث أولاً
@riverpod
Future<List<PayrollYearSummary>> payrollYears(Ref ref) {
  // نراقب الكشوف لتُعاد القراءة عند أي إنشاء أو حذف
  ref.watch(allPayrollPeriodsProvider);
  return ref.watch(payrollRepositoryProvider).getYears();
}

/// كل كشوف الرواتب — Reactive
@riverpod
Stream<List<PayrollPeriod>> allPayrollPeriods(Ref ref) {
  return ref.watch(payrollRepositoryProvider).watchAllPeriods();
}

/// كشوف سنة بعينها
@riverpod
Stream<List<PayrollPeriod>> payrollPeriodsForYear(Ref ref, int year) {
  return ref.watch(payrollRepositoryProvider).watchPeriodsForYear(year);
}

/// كشف واحد بالمعرّف
@riverpod
Stream<PayrollPeriod?> payrollPeriod(Ref ref, int periodId) {
  return ref.watch(payrollRepositoryProvider).watchPeriod(periodId);
}

/// سطور كشف — Reactive
@riverpod
Stream<List<SalaryPayment>> payrollEntries(Ref ref, int periodId) {
  return ref.watch(payrollRepositoryProvider).watchEntries(periodId);
}

/// إجماليات كشف — **مصدر الحقيقة الوحيد** لمجموع الرواتب
///
/// كل شاشة وطباعة وتقرير تسأل هنا. توزيع الجمع على المستدعين هو حرفياً ما
/// ضرب مشروع DMS المرجعي: كان مكرَّراً في ثمانية مواضع فاحتُسب راتب لم يُدفع.
@riverpod
Future<PayrollPeriodTotals> payrollTotals(Ref ref, int periodId) {
  // إعادة الحساب عند أي تغيّر في السطور
  ref.watch(payrollEntriesProvider(periodId));
  return ref.watch(payrollRepositoryProvider).getTotals(periodId);
}

/// موظفو القاعدة بصيغة مرشّحي المطابقة — لمعالج الاستيراد
@riverpod
Future<List<PayrollMatchCandidate>> payrollMatchCandidates(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  final employees = await db.employeesDao.getAllEmployees();
  return employees
      .map((e) => PayrollMatchCandidate(
            employeeId: e.id,
            fullName: e.fullName,
            hireDate: e.hireDate,
          ))
      .toList();
}

/// سلف الموظف غير المسدَّدة — لاقتراح الخصم في شاشة الكشف
@riverpod
Future<List<CashAdvance>> employeePendingAdvances(
  Ref ref,
  int employeeId,
) async {
  final db = ref.watch(appDatabaseProvider);
  final all = await db.employeesDao.getPendingAdvances();
  return all.where((a) => a.employeeId == employeeId).toList();
}

/// حالة السنة المالية التي يقع فيها شهرٌ ما
enum PayrollMonthFiscalState {
  /// سنة مالية مفتوحة تغطّي الشهر — يمكن بناء الكشف
  ready,

  /// لا سنة مالية تغطّي الشهر إطلاقاً
  missing,

  /// السنة موجودة لكنها **مُقفَلة**
  frozen,
}

/// نتيجة فحص السنة المالية لشهر — مع اسم السنة للرسالة
class PayrollMonthFiscalCheck {
  final PayrollMonthFiscalState state;

  /// اسم السنة المالية حين توجد
  final String? fiscalName;

  const PayrollMonthFiscalCheck(this.state, [this.fiscalName]);

  bool get isReady => state == PayrollMonthFiscalState.ready;

  /// رسالة عربية تشرح المانع وتقول ما العمل — أو `null` حين لا مانع
  String? get problem => switch (state) {
        PayrollMonthFiscalState.ready => null,
        PayrollMonthFiscalState.missing =>
          'لا توجد سنة مالية تغطّي هذا الشهر. أنشئها من شاشة «السنوات '
              'المالية» أولاً — وإلا لن يُبنى الكشف.',
        PayrollMonthFiscalState.frozen =>
          'السنة المالية «$fiscalName» مُقفَلة — لا تُضاف إليها رواتب. '
              'أعد فتحها أو اختر شهراً في سنة مفتوحة.',
      };
}

/// فحص السنة المالية لشهر **قبل** أن يبذل المالك عمل تعيين الأعمدة
///
/// 🔑 **سبب وجوده:** الحارس في `PayrollRepository` يرفض بحقّ، لكنه يرفض في
///   **آخر خطوة** — بعد اختيار الملف وتعيين أحد عشر عموداً ومراجعة سبعة
///   وأربعين سطراً. عرضُ المانع في **الخطوة الثانية** يوفّر ذلك كلّه.
///   (بلاغ المالك 2026-08-25: ضغط «بناء الكشف» فلم يحدث شيء — كانت سنته
///   المالية 2026 والكشف لأيار 2025.)
@riverpod
Future<PayrollMonthFiscalCheck> payrollMonthFiscalCheck(
  Ref ref,
  int year,
  int month,
) async {
  final db = ref.watch(appDatabaseProvider);
  final fiscal = await db.fiscalPeriodsDao
      .getAnyPeriodForDate(DateTime(year, month, 15));
  if (fiscal == null) {
    return const PayrollMonthFiscalCheck(PayrollMonthFiscalState.missing);
  }
  if (fiscal.status != 'active') {
    return PayrollMonthFiscalCheck(
      PayrollMonthFiscalState.frozen,
      fiscal.name,
    );
  }
  return PayrollMonthFiscalCheck(
    PayrollMonthFiscalState.ready,
    fiscal.name,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// الكتابة
// ═══════════════════════════════════════════════════════════════════════════

/// Notifier عمليات كشوف الرواتب
///
/// الحالة رسالة نجاح عربية أو خطأ — تُعرَض في شريط سفلي وتُصفَّر بعده.
@riverpod
class PayrollNotifier extends _$PayrollNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  PayrollRepository get _repo => ref.read(payrollRepositoryProvider);

  UserModel? get _user {
    final s = ref.read(authNotifierProvider);
    return s is AuthAuthenticated ? s.user : null;
  }

  /// فحص صلاحية — يضبط الحالة خطأً ويُعيد false عند المنع
  bool _allows(AppPermission permission, String action) {
    final user = _user;
    if (user == null || !user.can(permission)) {
      state = AsyncError(
        'لا تملك صلاحية $action.',
        StackTrace.empty,
      );
      return false;
    }
    return true;
  }

  void reset() => state = const AsyncData(null);

  // ── إنشاء كشف الشهر ────────────────────────────────────────────────────

  /// إنشاء كشف شهر أو إرجاع القائم — يُعيد معرّفه أو `null` عند الفشل
  Future<int?> createOrGetPeriod({
    required int year,
    required int month,
    double? exchangeRate,
    String workingDaysMode = WorkingDaysModeDb.fixed,
    double fileTotal = 0,
    String sourceFileName = '',
    String sourceFileHash = '',
  }) async {
    if (!_allows(AppPermission.preparePayroll, 'تجهيز كشوف الرواتب')) {
      return null;
    }
    state = const AsyncLoading();
    try {
      final id = await _repo.createOrGetPeriod(
        year: year,
        month: month,
        exchangeRate: exchangeRate,
        workingDaysMode: workingDaysMode,
        fileTotal: fileTotal,
        sourceFileName: sourceFileName,
        sourceFileHash: sourceFileHash,
        createdByUserId: _user?.id,
      );
      state = const AsyncData(null);
      return id;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  // ── الاستيراد ──────────────────────────────────────────────────────────

  /// استيراد سطور محسومة المطابقة إلى كشف
  Future<PayrollImportResult?> importRows({
    required int periodId,
    required List<ResolvedPayrollRow> rows,
  }) async {
    if (!_allows(AppPermission.preparePayroll, 'استيراد كشوف الرواتب')) {
      return null;
    }
    state = const AsyncLoading();
    try {
      final result = await _repo.importRows(
        periodId: periodId,
        rows: rows,
        userId: _user?.id,
      );

      // الاستيراد حدث يستحقّ أثراً: من أدخل رواتب أي شهر ومتى وكم سطراً
      final period = await _repo.getPeriod(periodId);
      await ref.read(auditLoggerProvider).logPayrollImported(
            userId: _user?.id ?? 0,
            username: _user?.username ?? 'system',
            periodId: periodId,
            periodLabel: period == null
                ? '$periodId'
                : PayrollCalculator.periodLabel(period.year, period.month),
            added: result.added,
            updated: result.updated,
            employeesCreated: result.employeesCreated,
            fileName: period?.sourceFileName,
          );

      state = AsyncData(
        'تم الاستيراد — ${result.added} سطراً جديداً '
        'و${result.updated} محدَّثاً'
        '${result.employeesCreated > 0 ? ' و${result.employeesCreated} موظفاً جديداً' : ''} ✓',
      );
      return result;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  // ── تعديل سطر ──────────────────────────────────────────────────────────

  Future<bool> updateEntry({
    required int entryId,
    double? basicSalary,
    int? eligibleDays,
    int? absenceDays,
    double? absenceDeduction,
    double? bonus,
    double? deduction,
    double? advanceRepayment,
    int? cashAdvanceId,
    String? notes,
  }) async {
    if (!_allows(AppPermission.preparePayroll, 'تعديل كشوف الرواتب')) {
      return false;
    }
    state = const AsyncLoading();
    try {
      await _repo.updateEntry(
        entryId: entryId,
        basicSalary: basicSalary,
        eligibleDays: eligibleDays,
        absenceDays: absenceDays,
        absenceDeduction: absenceDeduction,
        bonus: bonus,
        deduction: deduction,
        advanceRepayment: advanceRepayment,
        cashAdvanceId: cashAdvanceId,
        notes: notes,
      );
      state = const AsyncData('تم حفظ التعديل ✓');
      return true;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// إخراج موظف من كشف الشهر
  Future<bool> removeEntry(int entryId) async {
    if (!_allows(AppPermission.preparePayroll, 'تعديل كشوف الرواتب')) {
      return false;
    }
    try {
      await _repo.removeEntry(entryId);
      state = const AsyncData('أُخرج الموظف من الكشف ✓');
      return true;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return false;
    }
  }

  /// حذف كشف مسودة
  Future<bool> deletePeriod(int periodId) async {
    if (!_allows(AppPermission.managePayroll, 'حذف كشوف الرواتب')) {
      return false;
    }
    try {
      final period = await _repo.getPeriod(periodId);
      // تُقرأ **قبل** الحذف — بعده تختفي فلا يبقى ما يُوثَّق
      final entries = await _repo.getEntries(periodId);
      await _repo.deletePeriod(periodId);

      if (period != null) {
        await ref.read(auditLoggerProvider).logPayrollDeleted(
              userId: _user?.id ?? 0,
              username: _user?.username ?? 'system',
              periodId: periodId,
              periodLabel:
                  PayrollCalculator.periodLabel(period.year, period.month),
              entryCount: entries.length,
            );
      }

      state = const AsyncData('حُذف الكشف ✓');
      return true;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return false;
    }
  }

  // ── 🔑 التسديد ─────────────────────────────────────────────────────────

  /// تسديد دفعة رواتب — **العملية الوحيدة التي تُخرج مالاً هنا**
  Future<PayPayrollResult?> payEntries({
    required int periodId,
    required List<int> entryIds,
    required int treasuryId,
    required DateTime paymentDate,
  }) async {
    if (!_allows(AppPermission.managePayroll, 'صرف الرواتب')) return null;

    state = const AsyncLoading();
    try {
      final period = await _repo.getPeriod(periodId);
      final result = await _repo.payEntries(
        periodId: periodId,
        entryIds: entryIds,
        treasuryId: treasuryId,
        paymentDate: paymentDate,
        paidByUserId: _user?.id,
      );

      // ── الأثر الرقابي ────────────────────────────────────────────────
      // سند واحد بالمجموع، فلولا هذا السطر لما عُرف كم موظفاً يغطّيه ولا
      // أي شهر — والسند وحده يقول «رواتب شباط» بلا تفصيل.
      await ref.read(auditLoggerProvider).logVoucherCreated(
            userId: _user?.id ?? 0,
            username: _user?.username ?? 'system',
            voucherId: result.voucherId,
            voucherType: 'sarf',
            amount: result.totalIqd,
            treasuryId: treasuryId,
          );
      await ref.read(auditLoggerProvider).logPayrollPaid(
            userId: _user?.id ?? 0,
            username: _user?.username ?? 'system',
            periodId: periodId,
            periodLabel: period == null
                ? '$periodId'
                : PayrollCalculator.periodLabel(period.year, period.month),
            employeeCount: result.employeeCount,
            totalIqd: result.totalIqd,
            voucherId: result.voucherId,
            repaymentCount: result.repaymentCount,
            completed: result.periodCompleted,
          );

      // مسح ذاكرة الرصيد لتُقرأ من جديد بعد الخصم
      ref.invalidate(payrollTotalsProvider(periodId));

      state = AsyncData(
        'تم صرف رواتب ${result.employeeCount} موظفاً '
        'بسند واحد رقم ${result.voucherNumber} ✓'
        '${result.repaymentCount > 0 ? '\nوسُجِّل ${result.repaymentCount} قسط سلفة' : ''}',
      );
      return result;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}
