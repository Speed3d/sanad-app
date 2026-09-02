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
import '../../core/services/payroll_print_data.dart';
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

/// موظفو شهرٍ الذين سُدِّدت رواتبهم فعلاً — تنبيه معالج الاستيراد
///
/// 🔑 **سبب وجوده** (طلب المالك 2026-08-26): قد يكون صرف راتب موظف مباشرةً من
///   بطاقته عن شهر ٨، ثم يستورد ملف الشهر نفسه وقد نسي. فيجب أن يراه **باسمه
///   وتاريخ صرفه ورقم سنده** في خطوة المراجعة — حين يكون استبعاده ما زال
///   ممكناً بضغطة، لا بعد أن يخرج المال.
///
/// 📌 والحماية الحقيقية قائمة تحته: الاستيراد لا يمسّ سطراً مسدَّداً، والتسديد
///   لا يدفع إلا `unpaid`. فهذا **إخبارٌ ليقرّر** لا حاجزٌ وحيد.
@riverpod
Future<List<PaidEmployeeInMonth>> payrollPaidEmployeesForMonth(
  Ref ref,
  int year,
  int month,
) {
  ref.watch(allPayrollPeriodsProvider);
  return ref.watch(appDatabaseProvider).payrollDao
      .getPaidEmployeesForMonth(year, month);
}

/// كشوف فيها رواتب «مسدَّدة» بسندٍ محذوف — الكاشف المرآة (ع-٤٠)
@riverpod
Future<List<StalePaidPayroll>> stalePaidPayrolls(Ref ref) {
  ref.watch(allPayrollPeriodsProvider);
  return ref.watch(payrollRepositoryProvider).getStalePaidPayrolls();
}

/// تقرير رواتب سنة — الأشهر وتوزيع المسدَّد على الخزائن (المرحلة ٤)
///
/// 📌 **يجمع أرقاماً حسبها الـ DAO لا يحسبها بنفسه**، ويقرأ العمود نفسه
///   (`net_amount_iqd`) بالشروط نفسها التي تقرأها [payrollTotals]. يحرس
///   تطابقَ الرقمين اختبارٌ مخصّص — «استعلامان يُفترَض أنهما متطابقان» هو
///   بالضبط ما انفرط في المشروع المرجعي DMS.
@riverpod
Future<PayrollYearReportData> payrollYearReport(Ref ref, int year) {
  // إعادة القراءة عند أي إنشاء أو حذف أو اعتماد كشف
  ref.watch(allPayrollPeriodsProvider);
  return ref.watch(payrollRepositoryProvider).buildYearReport(year);
}

/// رواتب صُرفت في السنة **خارج أي كشف** — عددها ومجموعها
///
/// 🔑 يعرضها التقرير في شريط منفصل. مسار «صرف راتب» من بطاقة الموظف يكتب
///   سطراً بلا كشف، فتقريرٌ يقتصر على الكشوف يُخفي مالاً خرج فعلاً — وهو
///   الصنف نفسه من العطل الذي ضرب DMS.
@riverpod
Future<({int count, double totalIqd})> payrollOutOfSheet(Ref ref, int year) {
  ref.watch(allPayrollPeriodsProvider);
  return ref.watch(payrollRepositoryProvider).getOutOfSheetSalaries(year);
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

/// المتبقّي من سلف مجموعة موظفين — **استعلام واحد** (طلب المالك 2026-08-27)
///
/// 🔑 يُستعمل في معالج الاستيراد وفي كشف الشهر: «هذا الموظف عليه سلفة
///   متبقّية ٥٠٠٬٠٠٠». وبدونه كان المالك يستورد الكشف ويسدّده وقد نسي
///   الخصم — فتبقى السلفة كاملةً على الموظف بلا سبب.
///
/// 📌 والخريطة **لا تحوي مفتاحاً لمن لا سلفة عليه** — فالغياب نفسه جواب.
@riverpod
Future<Map<int, double>> pendingAdvancesForEmployees(
  Ref ref,
  List<int> employeeIds,
) {
  return ref
      .watch(appDatabaseProvider)
      .employeesDao
      .getPendingAdvancesForEmployees(employeeIds);
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

/// معاملات تقرير الموظف — كائن واحد بدل ستّة معاملات في مزوّد عائلي
///
/// ⚠️ **ولماذا `==` و`hashCode` بيدنا؟** لأن المزوّد العائلي يُخزّن نتيجته
///   بمفتاح المعامل. كائنٌ بلا مساواةٍ قيمية يُنتج مفتاحاً جديداً في **كل
///   بناء**، فيُعاد الاستعلام بلا انقطاع ولا ينتهي التحميل — وهو نفس العطل
///   الذي سبّبه `DateTime.now()` مفتاحاً (ع-٠٦).
class EmployeeReportQuery {
  final int? employeeId;
  final int? treasuryId;
  final int fromYear;
  final int fromMonth;
  final int toYear;
  final int toMonth;

  const EmployeeReportQuery({
    this.employeeId,
    this.treasuryId,
    required this.fromYear,
    required this.fromMonth,
    required this.toYear,
    required this.toMonth,
  });

  @override
  bool operator ==(Object other) =>
      other is EmployeeReportQuery &&
      other.employeeId == employeeId &&
      other.treasuryId == treasuryId &&
      other.fromYear == fromYear &&
      other.fromMonth == fromMonth &&
      other.toYear == toYear &&
      other.toMonth == toMonth;

  @override
  int get hashCode =>
      Object.hash(employeeId, treasuryId, fromYear, fromMonth, toYear, toMonth);
}

/// تقرير رواتب موظف أو مجموعة خلال مدى أشهر (طلب المالك 2026-08-26)
@riverpod
Future<EmployeePayrollReportData> employeePayrollReport(
  Ref ref,
  EmployeeReportQuery query,
) {
  // يُعاد بناؤه عند أي تغيّر في الكشوف — راتبٌ صُرف اليوم يظهر فوراً
  ref.watch(allPayrollPeriodsProvider);
  return ref.watch(payrollRepositoryProvider).buildEmployeeReport(
        employeeId: query.employeeId,
        treasuryId: query.treasuryId,
        fromYear: query.fromYear,
        fromMonth: query.fromMonth,
        toYear: query.toYear,
        toMonth: query.toMonth,
      );
}

/// كل الموظفين لقائمة اختيار التقرير — الاسم والصفة وخزينته
@riverpod
Future<List<Employee>> payrollReportEmployees(Ref ref) {
  return ref.watch(appDatabaseProvider).employeesDao.getAllEmployees();
}

/// سندات رواتب لا يقابلها سطرٌ حيّ — **مالٌ خرج بلا سجل** (ع-٣٣)
///
/// 🔑 شبكة أمان تكشف **العَرَض** لا السبب: هذه الحالة وُلدت من بابٍ لم
///   نتوقّعه (حذف الكشف)، وأيّ باب آخر لم يُشخَّص بعدُ سيُنتجها ثانيةً.
@riverpod
Future<List<OrphanPayrollVoucher>> orphanPayrollVouchers(Ref ref) {
  ref.watch(allPayrollPeriodsProvider);
  return ref.watch(payrollRepositoryProvider).getOrphanPayrollVouchers();
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
  /// تعارضات الخدمة قبل الاستيراد — **قراءةٌ لا تكتب شيئاً**
  ///
  /// تُسأل قبل `importRows` ليقرّر المالك: يعتمد الملف كما هو أم يُطبَّق
  /// حساب البرنامج. راجع `PayrollServiceConflict`.
  Future<List<PayrollServiceConflict>> previewServiceConflicts({
    required int periodId,
    required List<ResolvedPayrollRow> rows,
  }) {
    return _repo.previewServiceConflicts(periodId: periodId, rows: rows);
  }

  Future<PayrollImportResult?> importRows({
    required int periodId,
    required List<ResolvedPayrollRow> rows,
    bool applyComputedDays = false,
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
        applyComputedDays: applyComputedDays,
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

  /// حذف كشف — [mode] إلزامي حين يكون فيه رواتب مصروفة (ع-٣٣)
  Future<bool> deletePeriod(
    int periodId, {
    PayrollDeleteMode? mode,
    String reason = '',
  }) async {
    if (!_allows(AppPermission.managePayroll, 'حذف كشوف الرواتب')) {
      return false;
    }
    try {
      final period = await _repo.getPeriod(periodId);
      // تُقرأ **قبل** الحذف — بعده تختفي فلا يبقى ما يُوثَّق
      final entries = await _repo.getEntries(periodId);
      final result = await _repo.deletePeriod(
        periodId,
        mode: mode,
        reason: reason,
        userId: _user?.id,
      );

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

      // ⚠️ حدث تدقيق مستقلّ حين رجع مالٌ فعلاً — لا يكفي «حُذف الكشف»
      if (result.reversedCount > 0 && period != null) {
        await ref.read(auditLoggerProvider).logPayrollReversal(
              userId: _user?.id ?? 0,
              username: _user?.username ?? 'system',
              entryId: periodId,
              event: 'payroll_period_reversed',
              employeeName: '${result.reversedCount} موظفاً',
              periodLabel:
                  PayrollCalculator.periodLabel(period.year, period.month),
              reason: reason.trim(),
              oldAmountIqd: result.reversedTotalIqd,
            );
      }

      state = AsyncData(
        result.deletedPeriod
            ? 'حُذف الكشف ✓'
                '${result.reversedCount > 0 ? '\nوأُلغي تسديد ${result.reversedCount} راتباً ورجع ${result.reversedTotalIqd.round()} د.ع إلى الخزينة' : ''}'
            : 'حُذفت ${result.removedUnpaid} سطراً مستحقّاً ✓'
                '\nوالرواتب المصروفة بقيت في الكشف بسنداتها',
      );
      return true;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return false;
    }
  }

  /// إلغاء تسديد كل رواتب الشهر — بلا حذف الكشف
  Future<bool> unpayPeriod({
    required int periodId,
    required String reason,
  }) async {
    if (!_allows(AppPermission.managePayroll, 'إلغاء تسديد الرواتب')) {
      return false;
    }
    state = const AsyncLoading();
    try {
      final period = await _repo.getPeriod(periodId);
      final result = await _repo.unpayPeriod(
        periodId: periodId,
        reason: reason,
        userId: _user?.id,
      );

      if (period != null) {
        await ref.read(auditLoggerProvider).logPayrollReversal(
              userId: _user?.id ?? 0,
              username: _user?.username ?? 'system',
              entryId: periodId,
              event: 'payroll_period_unpaid',
              employeeName: '${result.count} موظفاً',
              periodLabel:
                  PayrollCalculator.periodLabel(period.year, period.month),
              reason: reason.trim(),
              oldAmountIqd: result.totalIqd,
            );
      }

      ref.invalidate(payrollTotalsProvider(periodId));
      state = AsyncData(
        'أُلغي تسديد ${result.count} راتباً ورجع '
        '${result.totalIqd.round()} د.ع إلى الخزينة ✓\n'
        'الكشف صار مسودة — صحّحه ثم سدّده من جديد.',
      );
      return true;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// إعادة رواتب فقدت سندها إلى «مستحقّة» (ع-٤٠)
  Future<bool> restoreStalePaidPayroll({
    required int periodId,
    required String reason,
  }) async {
    if (!_allows(AppPermission.managePayroll, 'تصحيح كشوف الرواتب')) {
      return false;
    }
    state = const AsyncLoading();
    try {
      final count = await _repo.restoreStalePaidPayroll(
        periodId: periodId,
        reason: reason,
      );
      ref.invalidate(stalePaidPayrollsProvider);
      ref.invalidate(payrollTotalsProvider(periodId));
      state = AsyncData('أُعيد $count راتباً إلى «مستحقّ» وعاد الكشف مسودة ✓');
      return true;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// حذف سند رواتب يتيم وإرجاع ماله إلى الخزينة (ع-٣٣)
  Future<bool> deleteOrphanVoucher({
    required int voucherId,
    required String reason,
  }) async {
    if (!_allows(AppPermission.managePayroll, 'حذف سندات الرواتب')) {
      return false;
    }
    state = const AsyncLoading();
    try {
      // يُقرأ **قبل** الحذف — مبلغه جزءٌ من الأثر الرقابي ويختفي بعده
      final voucher = await ref
          .read(appDatabaseProvider)
          .vouchersDao
          .getVoucherById(voucherId);

      await _repo.deleteOrphanPayrollVoucher(
        voucherId: voucherId,
        reason: reason,
        userId: _user?.id,
      );
      await ref.read(auditLoggerProvider).logVoucherDeleted(
            userId: _user?.id ?? 0,
            username: _user?.username ?? 'system',
            voucherId: voucherId,
            amount: voucher?.amount ?? 0,
          );
      ref.invalidate(orphanPayrollVouchersProvider);
      state = const AsyncData('حُذف السند اليتيم ورجع مبلغه إلى الخزينة ✓');
      return true;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── 🔑 الإلغاء والتصحيح بعد التسديد (المرحلة ٦) ────────────────────────

  /// إلغاء تسديد راتب — يعكس السطر والسند وقسط السلفة **معاً**
  ///
  /// صلاحية **مدير** كالتسديد نفسه: العملية تُعيد مالاً إلى الخزينة وتُبطل
  /// سنداً، فهي بخطورة الصرف لا بخفّة التعديل.
  Future<bool> unpayEntry({
    required int entryId,
    required String reason,
  }) async {
    if (!_allows(AppPermission.managePayroll, 'إلغاء تسديد الرواتب')) {
      return false;
    }
    state = const AsyncLoading();
    try {
      final entry = await ref.read(appDatabaseProvider).payrollDao
          .getEntryById(entryId);
      final result = await _repo.unpayEntry(
        entryId: entryId,
        reason: reason,
        userId: _user?.id,
      );

      await ref.read(auditLoggerProvider).logPayrollReversal(
            userId: _user?.id ?? 0,
            username: _user?.username ?? 'system',
            entryId: entryId,
            event: 'payroll_unpaid',
            employeeName: result.employeeName,
            periodLabel: entry?.periodLabel ?? '',
            reason: reason.trim(),
            oldAmountIqd: result.amountIqd,
            voucherId: result.voucherId,
            voucherDeleted: result.voucherDeleted,
            reversedRepayment: result.reversedRepayment,
          );

      if (entry?.payrollPeriodId != null) {
        ref.invalidate(payrollTotalsProvider(entry!.payrollPeriodId!));
      }

      state = AsyncData(
        'أُلغي تسديد راتب ${result.employeeName} ✓'
        '${result.voucherDeleted ? '\nوحُذف سنده لأنه كان له وحده' : '\nونقص مبلغ سند الدفعة بحصته'}'
        '${result.reversedRepayment > 0 ? '\nوأُعيد قسط سلفة بمبلغ ${result.reversedRepayment.round()}' : ''}',
      );
      return true;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// تصحيح مبلغ راتب مسدَّد — يبقى مسدَّداً ويتغيّر رقمه
  Future<bool> correctPaidEntry({
    required int entryId,
    required String reason,
    required PayrollCorrectionMode mode,
    double? basicSalary,
    int? eligibleDays,
    int? absenceDays,
    double? absenceDeduction,
    double? bonus,
    double? deduction,
  }) async {
    if (!_allows(AppPermission.managePayroll, 'تصحيح الرواتب المسدَّدة')) {
      return false;
    }
    state = const AsyncLoading();
    try {
      final entry = await ref.read(appDatabaseProvider).payrollDao
          .getEntryById(entryId);
      final result = await _repo.correctPaidEntry(
        entryId: entryId,
        reason: reason,
        mode: mode,
        newBasicSalary: basicSalary,
        newEligibleDays: eligibleDays,
        newAbsenceDays: absenceDays,
        newAbsenceDeduction: absenceDeduction,
        newBonus: bonus,
        newDeduction: deduction,
        userId: _user?.id,
      );

      await ref.read(auditLoggerProvider).logPayrollReversal(
            userId: _user?.id ?? 0,
            username: _user?.username ?? 'system',
            entryId: entryId,
            event: 'payroll_corrected',
            employeeName: result.employeeName,
            periodLabel: entry?.periodLabel ?? '',
            reason: reason.trim(),
            oldAmountIqd: result.oldAmountIqd,
            newAmountIqd: result.newAmountIqd,
            voucherId: entry?.voucherId,
            debtRecorded: result.debtRecorded,
          );

      if (entry?.payrollPeriodId != null) {
        ref.invalidate(payrollTotalsProvider(entry!.payrollPeriodId!));
      }

      state = AsyncData(
        'صُحِّح راتب ${result.employeeName} من '
        '${result.oldAmountIqd.round()} إلى ${result.newAmountIqd.round()} ✓'
        '${result.debtRecorded > 0 ? '\nوسُجِّل الفرق ${result.debtRecorded.round()} سلفةً على الموظف تُخصم من راتب قادم' : '\nورجع الفرق إلى الخزينة'}',
      );
      return true;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
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
