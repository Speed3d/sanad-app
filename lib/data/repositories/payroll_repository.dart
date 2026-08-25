// ─────────────────────────────────────────────────────────────────────────────
// payroll_repository.dart — قواعد عمل كشوف الرواتب (Schema v7)
//
// **تقسيم المسؤولية** (نمط `AdvanceRepository` القائم):
//   `PayrollDao`        → يضمن **الذرّية**: إما تُكتب العملية كلها أو لا شيء
//   `PayrollRepository` → يضمن **قواعد العمل**: الفترة مفتوحة · الرصيد كافٍ ·
//                          لا صافي سالب · لا دولار بلا سعر صرف
//
// 🔑 **كل الحرّاس هنا لا في الشاشة** (القانون ٤): حارسٌ في طبقة العرض
//   يُلتَفّ عليه بأي مستدعٍ جديد، **ولا يمرّ به أي اختبار** — وقد كلّفنا
//   عطلاً كاملاً حين عاشت قاعدة عدم تقاطع الفترات في `FiscalNotifier`.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

import '../../core/services/balance_guard.dart';
import '../../core/services/fiscal_period_guard.dart';
import '../../core/services/payroll_calculator.dart';
import '../../core/services/payroll_row_parser.dart';
import '../database/app_database.dart';
import '../database/daos/payroll_dao.dart';

/// سطر ملف بعد أن بتّ المالك في مطابقته بموظف
///
/// الشاشة تعرض المطابقة، والمالك يوافق أو يصحّح، ثم يصل السطر هنا **محسوماً**:
/// إما بمعرّف موظف قائم أو بطلب إنشاء صريح. لا ربط صامت ولا إنشاء صامت
/// (قرار المالك 2026-08-24).
class ResolvedPayrollRow {
  final ParsedPayrollRow row;

  /// معرّف الموظف المطابَق · `null` ⇒ يُنشأ موظف جديد بموافقة المالك
  final int? employeeId;

  /// الخزينة/المشروع الذي يُنسَب إليه الموظف الجديد
  final int? treasuryId;

  const ResolvedPayrollRow({
    required this.row,
    this.employeeId,
    this.treasuryId,
  });

  bool get createsEmployee => employeeId == null;
}

/// حصيلة استيراد ملف رواتب إلى كشف شهر
class PayrollImportResult {
  /// معرّف الكشف الذي استُورد إليه
  final int periodId;

  /// سطور أُضيفت لأول مرة
  final int added;

  /// سطور كانت موجودة فحُدِّثت
  final int updated;

  /// موظفون أُنشئوا بموافقة المالك
  final int employeesCreated;

  /// فروق بين الصافي المحسوب والمذكور في الملف — تُعرَض ولا تمنع
  final List<String> netMismatches;

  const PayrollImportResult({
    required this.periodId,
    required this.added,
    required this.updated,
    required this.employeesCreated,
    required this.netMismatches,
  });
}

/// مستودع كشوف الرواتب
class PayrollRepository {
  PayrollRepository(this._db);

  final AppDatabase _db;

  PayrollDao get _dao => _db.payrollDao;

  // ═══════════════════════════════════════════════════════════════════════
  // قراءة
  // ═══════════════════════════════════════════════════════════════════════

  Future<List<PayrollYearSummary>> getYears() => _dao.getYears();

  Stream<List<PayrollPeriod>> watchPeriodsForYear(int year) =>
      _dao.watchPeriodsForYear(year);

  Stream<List<PayrollPeriod>> watchAllPeriods() => _dao.watchAllPeriods();

  Stream<PayrollPeriod?> watchPeriod(int id) => _dao.watchPeriodById(id);

  Future<PayrollPeriod?> getPeriod(int id) => _dao.getPeriodById(id);

  Future<PayrollPeriod?> getPeriodForMonth(int year, int month) =>
      _dao.getPeriodForMonth(year, month);

  Stream<List<SalaryPayment>> watchEntries(int periodId) =>
      _dao.watchEntries(periodId);

  Future<List<SalaryPayment>> getEntries(int periodId) =>
      _dao.getEntries(periodId);

  Future<PayrollPeriodTotals> getTotals(int periodId) =>
      _dao.getTotals(periodId);

  Future<PayrollPeriod?> findByFileHash(String hash) =>
      _dao.findByFileHash(hash);

  // ═══════════════════════════════════════════════════════════════════════
  // إنشاء كشف الشهر
  // ═══════════════════════════════════════════════════════════════════════

  /// إنشاء كشف شهر أو إرجاع القائم — **تراكميّ لا مُعيد بناء**
  ///
  /// استيراد ملف ثانٍ للشهر نفسه (ملف كربلاء بعد ملف البصرة) ينضمّ إلى
  /// الكشف القائم ولا يُنشئ ثانياً. الفهرس الفريد `(سنة، شهر)` يحرس هذا
  /// على مستوى القاعدة أيضاً.
  ///
  /// يرمي [StateError] إن لم توجد سنة مالية تغطّي الشهر، أو كانت مُقفَلة.
  Future<int> createOrGetPeriod({
    required int year,
    required int month,
    double? exchangeRate,
    String workingDaysMode = WorkingDaysModeDb.fixed,
    int? workingDays,
    double fileTotal = 0,
    String sourceFileName = '',
    String sourceFileHash = '',
    int? createdByUserId,
  }) async {
    final existing = await _dao.getPeriodForMonth(year, month);
    if (existing != null) {
      // ⚠️ الكشف المُسدَّد لا يُضاف إليه (قرار المالك: منع التعديل بعد
      //   التسديد). لولا هذا الحارس لأمكن حقن موظف في شهر أُقفلت حساباته.
      if (existing.status == PayrollStatusDb.posted) {
        throw StateError(
          'كشف رواتب ${PayrollCalculator.periodLabel(year, month)} '
          'مُسدَّد — لا يُعدَّل. للتصحيح: احذفه وأعد إنشاءه.',
        );
      }
      // سعر الصرف يُحدَّث إن وصل مع الملف الجديد ولم يكن مضبوطاً
      if (exchangeRate != null && existing.exchangeRate == null) {
        await _dao.updatePeriod(
          existing.id,
          PayrollPeriodsCompanion(exchangeRate: Value(exchangeRate)),
        );
      }
      return existing.id;
    }

    // ── السنة المالية التي يقع فيها الشهر ────────────────────────────
    // نستعمل منتصف الشهر لا أوّله: بعض السنوات المالية تبدأ في منتصف يوم،
    // ومنتصف الشهر يقع داخل النطاق يقيناً أياً كانت حدوده.
    final anchor = DateTime(year, month, 15);
    final label = PayrollCalculator.periodLabel(year, month);

    // ⚠️ نبحث عن الفترة **أياً كانت حالتها** ثم نُميّز السبب.
    //   `getFiscalPeriodForDate` تفلتر بـ`active`، فكانت الفترة المُقفَلة
    //   تُنتج رسالة «لا توجد سنة مالية» — وهي كذب يُرسل المالك لينشئ سنة
    //   موجودة أصلاً، فيصطدم بقاعدة عدم التقاطع ولا يفهم لماذا.
    //   (بلاغ المالك 2026-08-25.)
    final fiscal = await _db.fiscalPeriodsDao.getAnyPeriodForDate(anchor);
    if (fiscal == null) {
      throw StateError(
        'لا توجد سنة مالية تغطّي $label.\n'
        'أنشئ السنة المالية من شاشة «السنوات المالية» أولاً، '
        'ثم أعد الاستيراد.',
      );
    }
    if (fiscal.status != 'active') {
      throw StateError(
        'السنة المالية «${fiscal.name}» التي يقع فيها $label **مُقفَلة** — '
        'لا تُضاف إليها رواتب.\n'
        'أعد فتحها من شاشة «السنوات المالية» أو اختر شهراً في سنة مفتوحة.',
      );
    }

    final days = workingDays ??
        PayrollCalculator.resolveWorkingDays(
          workingDaysMode,
          PayrollCalculator.defaultWorkingDays,
          year,
          month,
        );

    return _dao.insertPeriod(
      PayrollPeriodsCompanion.insert(
        year: year,
        month: month,
        fiscalPeriodId: fiscal.id,
        workingDays: Value(days),
        workingDaysMode: Value(workingDaysMode),
        exchangeRate: Value(exchangeRate),
        fileTotal: Value(fileTotal),
        sourceFileName: Value(sourceFileName),
        sourceFileHash: Value(sourceFileHash),
        createdByUserId: Value(createdByUserId),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // الاستيراد
  // ═══════════════════════════════════════════════════════════════════════

  /// استيراد سطور محسومة المطابقة إلى كشف شهر
  ///
  /// **تراكميّ**: الموظف الموجود في الكشف يُحدَّث سطره، والغائب يُضاف.
  /// ولا يُمَسّ سطرٌ مسدَّد إطلاقاً — المال خرج فعلاً فلا يُعاد حسابه.
  ///
  /// يرمي [StateError] إن كان الكشف مُسدَّداً.
  Future<PayrollImportResult> importRows({
    required int periodId,
    required List<ResolvedPayrollRow> rows,
    int? userId,
  }) async {
    final period = await _dao.getPeriodById(periodId);
    if (period == null) throw StateError('كشف الرواتب غير موجود.');
    if (period.status == PayrollStatusDb.posted) {
      throw StateError('الكشف مُسدَّد — لا يُستورَد إليه.');
    }
    await FiscalPeriodGuard.ensureActive(_db, period.fiscalPeriodId);

    var added = 0;
    var updated = 0;
    var created = 0;
    final mismatches = <String>[];

    for (final resolved in rows) {
      final r = resolved.row;

      // ── 1. الموظف: قائم أم يُنشأ بموافقة صريحة ──────────────────────
      int employeeId;
      if (resolved.employeeId != null) {
        employeeId = resolved.employeeId!;
      } else {
        employeeId = await _db.employeesDao.insertEmployee(
          EmployeesCompanion.insert(
            fullName: r.employeeName,
            position: Value(r.position),
            basicSalary: Value(r.basicSalary),
            salaryCurrency: Value(r.currency),
            hireDate: Value(r.hireDate),
            treasuryId: Value(resolved.treasuryId),
          ),
        );
        created++;
      }

      // ── 2. الحساب — يمرّ من `PayrollCalculator` دائماً ───────────────
      // لا مسار يُخزَّن فيه صافٍ لم يُحسب هنا، حتى لو ذكر الملف صافيه.
      final amounts = PayrollCalculator.compute(
        year: period.year,
        month: period.month,
        workingDays: period.workingDays,
        basicSalary: r.basicSalary,
        currency: r.currency,
        exchangeRate: r.exchangeRate ?? period.exchangeRate,
        hireDate: r.hireDate,
        absenceDays: r.absenceDays,
        bonus: r.bonus,
        deduction: r.deduction,
        manualEligibleDays: r.eligibleDays,
      );

      // ── 3. الفرق بين المحسوب والمذكور — يُعرَض ولا يمنع ──────────────
      final mismatch = PayrollRowParser.describeNetMismatch(
        employeeName: r.employeeName,
        fileNet: r.fileNetAmount,
        computedNet: amounts.netSalary,
      );
      if (mismatch != null) mismatches.add(mismatch);

      // ── 4. الإدراج أو التحديث ────────────────────────────────────────
      final existing = await _dao.getEntryForEmployee(
        periodId: periodId,
        employeeId: employeeId,
      );

      final companion = SalaryPaymentsCompanion(
        payrollPeriodId: Value(periodId),
        employeeId: Value(employeeId),
        periodLabel:
            Value(PayrollCalculator.periodLabel(period.year, period.month)),
        snapshotName: Value(r.employeeName),
        snapshotPosition: Value(r.position),
        snapshotCurrency: Value(r.currency),
        snapshotHireDate: Value(r.hireDate),
        basicSalary: Value(r.basicSalary),
        eligibleDays: Value(amounts.eligibleDays),
        eligibleDaysIsManual: Value(r.eligibleDays != null),
        absenceDays: Value(r.absenceDays),
        absenceDeduction: Value(amounts.absenceDeduction),
        additions: Value(r.bonus),
        deductions: Value(r.deduction),
        netAmount: Value(amounts.netSalary),
        netAmountIqd: Value(amounts.netSalaryIqd),
        exchangeRate: Value(r.exchangeRate ?? period.exchangeRate),
        fileNetAmount: Value(r.fileNetAmount),
        paymentDate: Value(DateTime(period.year, period.month, 1)),
      );

      if (existing == null) {
        await _dao.insertEntry(companion);
        added++;
      } else if (existing.paymentStatus == PayrollPaymentStatusDb.paid) {
        // سطر مسدَّد لا يُعاد حسابه — المال خرج فعلاً بهذا الرقم
        continue;
      } else {
        await _dao.updateEntry(existing.id, companion);
        updated++;
      }
    }

    return PayrollImportResult(
      periodId: periodId,
      added: added,
      updated: updated,
      employeesCreated: created,
      netMismatches: mismatches,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // تعديل سطر
  // ═══════════════════════════════════════════════════════════════════════

  /// تعديل سطر في المسودة وإعادة حساب صافيه
  ///
  /// **علَما «يدوي»** يُضبطان حين يمرّر المستدعي القيمة صراحةً، فتُصان من
  /// إعادة الحساب لاحقاً. «قيمة موجودة» ليست «قيمة اختارها إنسان».
  Future<void> updateEntry({
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
    final entry = await _dao.getEntryById(entryId);
    if (entry == null) throw StateError('سطر الراتب غير موجود.');
    if (entry.paymentStatus == PayrollPaymentStatusDb.paid) {
      throw StateError(
        'راتب «${entry.snapshotName}» مُسدَّد — لا يُعدَّل. '
        'للتصحيح: احذف الكشف وأعد إنشاءه.',
      );
    }

    final period = await _dao.getPeriodById(entry.payrollPeriodId!);
    if (period == null) throw StateError('كشف الرواتب غير موجود.');
    await FiscalPeriodGuard.ensureActive(_db, period.fiscalPeriodId);

    final newBasic = basicSalary ?? entry.basicSalary;
    final newAbsenceDays = absenceDays ?? entry.absenceDays;
    final newRepayment = advanceRepayment ?? entry.advanceRepaymentAmount;

    final manualDays =
        eligibleDays ?? (entry.eligibleDaysIsManual ? entry.eligibleDays : null);
    final manualAbsence = absenceDeduction ??
        (entry.absenceDeductionIsManual ? entry.absenceDeduction : null);

    final amounts = PayrollCalculator.compute(
      year: period.year,
      month: period.month,
      workingDays: period.workingDays,
      basicSalary: newBasic,
      currency: entry.snapshotCurrency,
      exchangeRate: entry.exchangeRate ?? period.exchangeRate,
      hireDate: entry.snapshotHireDate,
      absenceDays: newAbsenceDays,
      bonus: bonus ?? entry.additions,
      deduction: deduction ?? entry.deductions,
      advanceRepayment: newRepayment,
      manualEligibleDays: manualDays,
      manualAbsenceDeduction: manualAbsence,
    );

    await _dao.updateEntry(
      entryId,
      SalaryPaymentsCompanion(
        basicSalary: Value(newBasic),
        eligibleDays: Value(amounts.eligibleDays),
        eligibleDaysIsManual:
            Value(entry.eligibleDaysIsManual || eligibleDays != null),
        absenceDays: Value(newAbsenceDays),
        absenceDeduction: Value(amounts.absenceDeduction),
        absenceDeductionIsManual: Value(
            entry.absenceDeductionIsManual || absenceDeduction != null),
        additions: Value(bonus ?? entry.additions),
        deductions: Value(deduction ?? entry.deductions),
        advanceRepaymentAmount: Value(newRepayment),
        cashAdvanceId: Value(cashAdvanceId ?? entry.cashAdvanceId),
        netAmount: Value(amounts.netSalary),
        netAmountIqd: Value(amounts.netSalaryIqd),
        notes: notes == null ? const Value.absent() : Value(notes),
      ),
    );
  }

  /// إخراج موظف من كشف الشهر (حذف ناعم لسطره)
  Future<void> removeEntry(int entryId) async {
    final entry = await _dao.getEntryById(entryId);
    if (entry == null) return;
    if (entry.paymentStatus == PayrollPaymentStatusDb.paid) {
      throw StateError(
        'راتب «${entry.snapshotName}» مُسدَّد — لا يُحذف من الكشف.',
      );
    }
    await _dao.softDeleteEntry(entryId);
  }

  /// حذف كشف — المسودة فقط
  Future<void> deletePeriod(int periodId) async {
    final period = await _dao.getPeriodById(periodId);
    if (period == null) return;
    if (period.status == PayrollStatusDb.posted) {
      throw StateError(
        'كشف ${PayrollCalculator.periodLabel(period.year, period.month)} '
        'مُسدَّد — حذفه يمحو أثر رواتب صُرفت فعلاً.',
      );
    }
    await _dao.softDeletePeriod(periodId);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🔑 التسديد — الحرّاس قبل الذرّية
  // ═══════════════════════════════════════════════════════════════════════

  /// تسديد دفعة رواتب من خزينة
  ///
  /// [entryIds] — السطور الداخلة في هذه الدفعة. الكشف شامل، والتسديد يقع
  /// على دفعات حسب مصدر التمويل (موظفو البصرة من سلفتها ومن في بغداد من
  /// الرئيسية).
  ///
  /// **ترتيب الحرّاس مقصود** — كلها قبل أي كتابة:
  ///   1. الكشف مسودة (يمنع التسديد المزدوج)
  ///   2. الفترة المالية مفتوحة
  ///   3. لا دولار بلا سعر صرف
  ///   4. لا صافي سالب
  ///   5. رصيد الخزينة كافٍ
  Future<PayPayrollResult> payEntries({
    required int periodId,
    required List<int> entryIds,
    required int treasuryId,
    required DateTime paymentDate,
    int? paidByUserId,
    int? advanceId,
    int? advanceLineId,
    String? advanceNumber,
    String? projectName,
  }) async {
    if (entryIds.isEmpty) {
      throw StateError('لم تُحدَّد أي رواتب للتسديد.');
    }

    final period = await _dao.getPeriodById(periodId);
    if (period == null) throw StateError('كشف الرواتب غير موجود.');

    // ── 1. الحالة ────────────────────────────────────────────────────
    if (period.status == PayrollStatusDb.posted) {
      throw StateError(
        'كشف ${PayrollCalculator.periodLabel(period.year, period.month)} '
        'مُسدَّد بالكامل — لا يُسدَّد مرّتين.',
      );
    }

    // ── 2. الفترة المالية ────────────────────────────────────────────
    await FiscalPeriodGuard.ensureActive(_db, period.fiscalPeriodId);

    // ── 3+4. سلامة السطور ────────────────────────────────────────────
    final all = await _dao.getEntries(periodId);
    final selected = all
        .where((e) =>
            entryIds.contains(e.id) &&
            e.paymentStatus == PayrollPaymentStatusDb.unpaid)
        .toList();

    if (selected.isEmpty) {
      throw StateError(
        'كل الرواتب المحدَّدة مسدَّدة بالفعل — لا شيء ليُصرف.',
      );
    }

    PayrollCalculator.ensureRateSet(
      hasForeignCurrency:
          selected.any((e) => e.snapshotCurrency == PayrollCurrency.usd),
      rate: period.exchangeRate,
    );
    for (final e in selected) {
      PayrollCalculator.ensurePayable(e.snapshotName, e.netAmount);
    }

    final total = selected.fold<double>(0, (s, e) => s + e.netAmountIqd);
    if (total <= 0) {
      throw StateError('إجمالي الدفعة صفر أو سالب — راجع السطور المحدَّدة.');
    }

    // ── 5. رصيد الخزينة ──────────────────────────────────────────────
    // نمرّ بالحارس نفسه الذي يمرّ به الصرف العادي، فلا يختلف الرقمان.
    final balanceError = await BalanceGuard.checkSufficientBalance(
      _db,
      treasuryId: treasuryId,
      currency: 'IQD',
      amount: total,
    );
    if (balanceError != null) throw StateError(balanceError);

    // ── التنفيذ الذرّي ───────────────────────────────────────────────
    return _dao.payEntries(
      periodId: periodId,
      entryIds: selected.map((e) => e.id).toList(),
      treasuryId: treasuryId,
      fiscalPeriodId: period.fiscalPeriodId,
      paymentDate: paymentDate,
      periodLabel:
          PayrollCalculator.periodLabel(period.year, period.month),
      paidByUserId: paidByUserId,
      advanceId: advanceId,
      advanceLineId: advanceLineId,
      advanceNumber: advanceNumber,
      projectName: projectName,
    );
  }
}
