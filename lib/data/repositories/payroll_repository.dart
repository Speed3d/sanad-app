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

import '../../core/constants/employee_status.dart';
import '../../core/services/balance_guard.dart';
import '../../core/services/fiscal_period_guard.dart';
import '../../core/services/payroll_calculator.dart';
import '../../core/services/payroll_print_data.dart';
import '../../core/services/payroll_row_parser.dart';
import '../database/app_database.dart';
import '../database/daos/payroll_dao.dart';

part 'payroll_repository_models.dart';
part 'payroll_repository_reports.dart';
part 'payroll_repository_corrections.dart';

/// مستودع كشوف الرواتب
class PayrollRepository
    with PayrollReportsMixin, PayrollCorrectionsMixin {
  PayrollRepository(this._db);

  @override
  final AppDatabase _db;

  @override
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
      // 🔴 **كان هنا حارسٌ يرفض الكشف المُسدَّد — وأُزيل 2026-08-26.**
      //
      //   بعد توحيد الصرف المباشر داخل الكشوف، صار صرفُ راتب **موظف واحد**
      //   مباشرةً يُنشئ كشف الشهر ويجعله «مُسدَّداً» (لا سطر مستحقّ فيه).
      //   فكان الحارس يرفض بعدها **استيراد ملف الشهر كلّه** — أي أن صرف
      //   راتب واحد يقفل الشهر على سبعة وأربعين موظفاً.
      //
      //   كشفه اختبار «استيراد الملف بعد الصرف المباشر» قبل أن يصل للمالك.
      //
      //   **والحماية الحقيقية لم تُمَسّ:** `importRows` لا تلمس سطراً
      //   مسدَّداً أبداً (المال خرج بذلك الرقم)، والكشف يعود «مسودة» ما دام
      //   فيه سطر مستحقّ. المحمي هو **السطر المدفوع** لا حالة الكشف.
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
    await FiscalPeriodGuard.ensureActive(_db, period.fiscalPeriodId);

    // 📌 الكشف المُسدَّد **يُستورَد إليه** (2026-08-26): «مُسدَّد» تعني «لا
    //   سطر مستحقّ فيه» لا «مُقفَل للأبد». وقد صار الوصول إليها ممكناً بصرف
    //   راتب موظف واحد مباشرةً — فرفضُ الاستيراد بعدها كان يقفل الشهر على
    //   بقية الموظفين. السطور المسدَّدة لا تُمَسّ، والحالة تُراجَع في النهاية.

    var added = 0;
    var updated = 0;
    var created = 0;
    final mismatches = <String>[];
    final skipped = <String>[];

    for (final resolved in rows) {
      final r = resolved.row;

      // ── 0. منتهي الخدمة لا يدخل كشفاً جديداً (Schema v8) ─────────────
      //
      // 🔴 **الوعد كان مكتوباً ولا حارس يحقّقه.** رسالة حارس الحذف تقول منذ
      //   الدفعة ب: «عطّله بدل ذلك — يبقى سجلّه ولا يظهر في كشوف الرواتب
      //   الجديدة». و`is_active` لم يكن يقرؤه **أي** مسار رواتب: فالتعطيل
      //   كان يغيّر شارةً على الشاشة ولا شيء غيرها (نمط ع-٠٦، لكن في ثوب
      //   أخطر: وعدٌ صريح للمالك لا يقع).
      //
      // ⚠️ **والاستبعاد هنا لا في المطابقة**: إخراجه من مرشّحي المطابقة
      //   كان يجعل اسمه في الملف يبدو **موظفاً جديداً**، فيُنشَأ نسخةً
      //   ثانية بسلفه وتاريخه المفقود. المطابقة تقع، ثم يُستبعَد الصفّ
      //   ويُقال ذلك صراحةً.
      if (resolved.employeeId != null) {
        final existingEmp =
            await _db.employeesDao.getEmployeeById(resolved.employeeId!);
        // ⚠️ **بحسب الشهر لا مطلقاً** (Schema v9): من أُنهيت خدمته في ٢٤
        //   تموز يدخل كشف تموز بواحدٍ وعشرين يوماً، ويُستبعَد من آب فصاعداً.
        //   الاستبعاد المطلق كان يحرمه راتب أيامٍ عملها فعلاً.
        if (existingEmp != null &&
            !EmployeeStatus.joinsPayrollMonth(
              status: existingEmp.status,
              terminationDate: existingEmp.terminationDate,
              year: period.year,
              month: period.month,
            )) {
          skipped.add(existingEmp.fullName);
          continue;
        }
      }

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

      // ── ١-ب. سياق الخدمة **من سجلّ الموظف** (Schema v9) ──────────────
      //
      // تواريخ التعيين والإنهاء وأيام الإجازة — تُجمَع في الـDAO لا هنا،
      // فهي قراءةُ بياناتٍ لا قاعدةَ عمل. راجع
      // `EmployeesDao.payrollServiceContext` لشرح ما كان معطوباً.
      final ctx = await _db.employeesDao.payrollServiceContext(
        employeeId: employeeId,
        year: period.year,
        month: period.month,
        workingDays: period.workingDays,
      );
      final effectiveHireDate = ctx.hireDate ?? r.hireDate;

      // ── 2. الحساب — يمرّ من `PayrollCalculator` دائماً ───────────────
      // لا مسار يُخزَّن فيه صافٍ لم يُحسب هنا، حتى لو ذكر الملف صافيه.
      final amounts = PayrollCalculator.compute(
        year: period.year,
        month: period.month,
        workingDays: period.workingDays,
        basicSalary: r.basicSalary,
        currency: r.currency,
        exchangeRate: r.exchangeRate ?? period.exchangeRate,
        hireDate: effectiveHireDate,
        terminationDate: ctx.terminationDate,
        absenceDays: r.absenceDays,
        unpaidLeaveDays: ctx.unpaidLeaveDays,
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
        // اللقطة تحمل التاريخ **المستعمَل في الحساب** لا ما ذكره الملف —
        // وإلا شرح الإيصالُ استحقاقاً بتاريخٍ لم يُبنَ عليه
        snapshotHireDate: Value(effectiveHireDate),
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
        // ── سطر مسدَّد: المال خرج بهذا الرقم فلا يُعاد حسابه ──────────────
        //
        // 🔑 **لكن رقم الملف يُحفَظ** (بلاغ المالك 2026-08-26): بلا حفظه
        //   يظهر فرقُ مجموع الكشف **يتيماً بلا سبب** بعد إغلاق المعالج —
        //   والبرنامج يعرف سببه (راتبٌ صُرف لـ٣٠ يوماً والملف يحسب ٢٦).
        //
        // ⚠️ **ولا يُمَسّ أي مبلغ مالي هنا**: `file_net_amount` عمود مقارنة
        //   لا عمود مال. الصافي والمصروف والسند كما هي.
        await _dao.updateEntry(
          existing.id,
          SalaryPaymentsCompanion(
            fileNetAmount: Value(r.fileNetAmount ?? amounts.netSalary),
          ),
        );
        continue;
      } else {
        await _dao.updateEntry(existing.id, companion);
        updated++;
      }
    }

    // ── الحالة تتبع السطور لا العكس ──────────────────────────────────
    // كشفٌ صار فيه سطر مستحقّ **ليس مُسدَّداً** مهما كانت حالته قبل قليل.
    // وتاريخ الاعتماد الأصلي يبقى محفوظاً — فلا يضيع أثر اعتماده الأول.
    if (period.status == PayrollStatusDb.posted) {
      final totals = await _dao.getTotals(periodId);
      if (totals.paidCount < totals.entryCount) {
        await _dao.updatePeriod(
          periodId,
          const PayrollPeriodsCompanion(status: Value(PayrollStatusDb.draft)),
        );
      }
    }

    return PayrollImportResult(
      periodId: periodId,
      added: added,
      updated: updated,
      employeesCreated: created,
      netMismatches: mismatches,
      skippedTerminated: skipped,
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

    // ⚠️ **سياق الخدمة يُقرأ هنا كما يُقرأ في الاستيراد** (Schema v9):
    //   إعادةُ حسابٍ بلا تاريخ الإنهاء وبلا الإجازة **تُعيد الشهر كاملاً**
    //   لمن أُنهيت خدمته في منتصفه — فتعديلُ مكافأةٍ يقفز براتبه من ٢١
    //   يوماً إلى ٣٠. وهو ع-٣٧ حرفياً: منطقٌ مالي في مسارين أحدهما ينسى.
    final ctx = await _db.employeesDao.payrollServiceContext(
      employeeId: entry.employeeId,
      year: period.year,
      month: period.month,
      workingDays: period.workingDays,
    );

    final amounts = PayrollCalculator.compute(
      year: period.year,
      month: period.month,
      workingDays: period.workingDays,
      basicSalary: newBasic,
      currency: entry.snapshotCurrency,
      exchangeRate: entry.exchangeRate ?? period.exchangeRate,
      // اللقطة لا السجلّ: تاريخ التعيين المجمَّد هو ما بُني عليه الكشف
      hireDate: entry.snapshotHireDate,
      terminationDate: ctx.terminationDate,
      absenceDays: newAbsenceDays,
      unpaidLeaveDays: ctx.unpaidLeaveDays,
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

  /// ما سيقع لو حُذف الكشف — تُقرأ **قبل** عرض الحوار
  Future<PayrollDeletionImpact> getDeletionImpact(int periodId) =>
      _dao.getDeletionImpact(periodId);

  /// حذف كشف — **وأخطر ما فيه ما كان يقع بصمت** (ع-٣٣)
  ///
  /// 🔴 **العطل الذي وُلدت منه هذه الدالة** (بلاغ المالك 2026-08-26):
  ///   كان الحذف يمسح سطور الكشف **بما فيها المدفوعة فعلاً**، فتبقى سنداتها
  ///   حيّة والمال خارج الخزينة **بلا أي سجل يقابله**:
  ///
  ///   • الرصيد ناقص · والسندات حيّة · ولا أثر في بطاقة الموظف ولا التقرير
  ///   • و«مصروف سلفاً» يعود صفراً ⇒ إعادة الاستيراد تُدرجهم **مستحقّين**،
  ///     فيُصرف المال **مرّتين** لنفس الشهر
  ///   • والفهارس الفريدة لا تمنع: كلها مشروطة بـ`is_deleted = 0`
  ///
  ///   ولم يكن الحذف يمرّ بأي حارس لأن الكشف **مسودة** — والحالة تصف
  ///   السطور المستحقّة لا المدفوعة.
  ///
  /// **[mode] إلزامي حين يوجد مدفوع** (قرار المالك):
  ///   • `reverseAndDelete` — تُلغى تسديداتها فيرجع المال وتُحذف سنداتها
  ///     وتُعاد أقساط السلف، ثم يُحذف الكشف
  ///   • `unpaidOnly` — يُحذف المستحقّ وحده ويبقى المدفوع بسنداته في كشفه
  ///
  /// وبلا [mode] يُرفض الحذف: **قرارٌ ماليّ لا يُفترَض عن صاحبه**.
  Future<PayrollDeleteResult> deletePeriod(
    int periodId, {
    PayrollDeleteMode? mode,
    String reason = '',
    int? userId,
  }) async {
    final period = await _dao.getPeriodById(periodId);
    if (period == null) {
      return const PayrollDeleteResult(
        deletedPeriod: false,
        reversedCount: 0,
        reversedTotalIqd: 0,
        removedUnpaid: 0,
      );
    }

    final label = PayrollCalculator.periodLabel(period.year, period.month);
    final impact = await _dao.getDeletionImpact(periodId);

    // ── لا مدفوع ⇒ حذفٌ بلا أثر مالي، كما كان ────────────────────────
    if (!impact.hasPaid) {
      await _dao.softDeletePeriod(periodId);
      return PayrollDeleteResult(
        deletedPeriod: true,
        reversedCount: 0,
        reversedTotalIqd: 0,
        removedUnpaid: impact.unpaidCount,
      );
    }

    if (mode == null) {
      throw StateError(
        'كشف $label فيه ${impact.paidCount} '
        '${impact.paidCount == 1 ? 'راتباً مصروفاً' : 'رواتب مصروفة'} '
        'بمجموع ${impact.paidTotalIqd.round()} د.ع — '
        'لا يُحذف بلا قرار في مصير ذلك المال.',
      );
    }

    await FiscalPeriodGuard.ensureActive(_db, period.fiscalPeriodId);

    // ── (ب) حذف المستحقّ وحده ────────────────────────────────────────
    if (mode == PayrollDeleteMode.unpaidOnly) {
      final removed = await _dao.softDeleteUnpaidEntries(periodId);
      return PayrollDeleteResult(
        deletedPeriod: false,
        reversedCount: 0,
        reversedTotalIqd: 0,
        removedUnpaid: removed,
      );
    }

    // ── (أ) عكس التسديدات ثم حذف الكشف ───────────────────────────────
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw StateError(
        'اكتب سبب حذف الكشف — إرجاع مالٍ خرج فعلاً بلا سبب مكتوب '
        'لا يُميَّز عن تلاعب حين يُراجَع بعد شهور.',
      );
    }

    final entries = await _dao.getEntries(periodId);
    final paid = entries
        .where((e) => e.paymentStatus == PayrollPaymentStatusDb.paid)
        .toList();

    var reversedTotal = 0.0;
    for (final e in paid) {
      // كلٌّ منها معاملة ذرّية تعكس السطر والسند وقسط السلفة معاً
      final r = await _dao.unpayEntry(
        entryId: e.id,
        reason: 'حذف كشف $label — $trimmed',
        userId: userId,
      );
      reversedTotal += r.amountIqd;
    }

    await _dao.softDeletePeriod(periodId);

    return PayrollDeleteResult(
      deletedPeriod: true,
      reversedCount: paid.length,
      reversedTotalIqd: reversedTotal,
      removedUnpaid: impact.unpaidCount,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // سندات الرواتب اليتيمة — شبكة الأمان الأخيرة (ع-٣٣)
  // ═══════════════════════════════════════════════════════════════════════

  /// سندات رواتب لا يقابلها سطرٌ حيّ — **مالٌ خرج بلا سجل**
  Future<List<OrphanPayrollVoucher>> getOrphanPayrollVouchers() =>
      _dao.getOrphanPayrollVouchers();

  /// حذف سند رواتب يتيم وإرجاع ماله إلى الخزينة
  ///
  /// ⚠️ **يُعاد التحقّق من يُتمه هنا** لا في الشاشة: قد يكون سطرٌ رُبط به
  ///   بين لحظة العرض ولحظة الضغط، وحذفه عندها يُنتج بالضبط العطل الذي
  ///   جاءت هذه الأداة لتنظّفه (ع-٣١).
  Future<void> deleteOrphanPayrollVoucher({
    required int voucherId,
    required String reason,
    int? userId,
  }) async {
    if (reason.trim().isEmpty) {
      throw StateError('اكتب سبب حذف السند اليتيم.');
    }

    final orphans = await _dao.getOrphanPayrollVouchers();
    if (!orphans.any((o) => o.voucherId == voucherId)) {
      throw StateError(
        'هذا السند لم يعد يتيماً — صار له سطر راتب حيّ يقابله.\n'
        'أعد فتح القائمة لتراها محدَّثة.',
      );
    }

    final voucher = await _db.vouchersDao.getVoucherById(voucherId);
    if (voucher == null || voucher.isDeleted) return;
    await FiscalPeriodGuard.ensureActive(_db, voucher.fiscalPeriodId);

    // يمرّ بالمسار العادي: لا سطور حيّة فلن يعترض حارس الرواتب،
    // ونكسب معه فكّ ربط سطر السلفة وحذف توأم التحويل إن وُجدا.
    await _db.vouchersDao.softDeleteVoucher(voucherId, deletedByUser: userId);
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

  /// تقرير رواتب موظف واحد أو كل موظفي مشروع خلال **مدى أشهر**
  ///
  /// **وضعان** (قرار المالك 2026-08-26):
  ///   • [employeeId] محدَّد ⇒ شهرٌ شهراً بكل تفاصيل الراتب
  ///   • [employeeId] فارغ  ⇒ كل الموظفين (أو موظفو [treasuryId]) بمجاميعهم
  ///
  /// 🔑 **الإجماليات تُحسَب هنا مرّة واحدة** ويقرأها العرضُ والورقةُ معاً —
  ///   لا يجمع أيٌّ منهما شيئاً بنفسه. رقمان لنفس السؤال يعنيان أن أحدهما
  ///   خاطئ ولا يُعرَف أيّهما.
  ///
  /// **والمدى يُصحَّح إن جاء مقلوباً** بدل أن يُعيد تقريراً فارغاً: مدىً
  /// معكوس خطأُ إدخالٍ شائع، ونتيجتُه الفارغة تُقرأ «لا رواتب لهذا الموظف»
  /// — وهي كذبة خطرة.
  Future<EmployeePayrollReportData> buildEmployeeReport({
    int? employeeId,
    int? treasuryId,
    required int fromYear,
    required int fromMonth,
    required int toYear,
    required int toMonth,
  }) async {
    // ترتيب المدى — الأصغر أولاً مهما أُدخل
    var (fy, fm, ty, tm) = (fromYear, fromMonth, toYear, toMonth);
    if (fy * 12 + fm > ty * 12 + tm) {
      (fy, fm, ty, tm) = (ty, tm, fy, fm);
    }

    final rangeLabel = '${PayrollCalculator.periodLabel(fy, fm)} — '
        '${PayrollCalculator.periodLabel(ty, tm)}';

    String? treasuryName;
    if (treasuryId != null) {
      final t = await _db.treasuriesDao.getTreasuryById(treasuryId);
      treasuryName = t?.name;
    }

    // ── الوضع الأول: موظف واحد ───────────────────────────────────────
    if (employeeId != null) {
      final employee = await _db.employeesDao.getEmployeeById(employeeId);
      final months = await _dao.getEmployeeMonths(
        employeeId: employeeId,
        fromYear: fy,
        fromMonth: fm,
        toYear: ty,
        toMonth: tm,
      );

      // الجمع بالدينار: مبالغ الدولار تُضرب بسعر صرف شهرها قبل الجمع،
      // وإلا جُمع دولارٌ على دينار فخرج رقم بلا معنى.
      double iqd(double value, EmployeePayrollMonth m) =>
          m.currency == PayrollCurrency.usd
              ? value * (m.netIqd == 0 || m.net == 0 ? 0 : m.netIqd / m.net)
              : value;

      var total = 0.0, paid = 0.0, bonus = 0.0, ded = 0.0, adv = 0.0;
      for (final m in months) {
        total += m.netIqd;
        if (m.isPaid) paid += m.netIqd;
        bonus += iqd(m.bonus, m);
        ded += iqd(m.deduction + m.absenceDeduction, m);
        adv += iqd(m.advanceRepayment, m);
      }

      return EmployeePayrollReportData(
        rangeLabel: rangeLabel,
        employeeName: employee?.fullName ?? '—',
        position: employee?.position ?? '',
        treasuryName: treasuryName,
        months: months,
        employees: const [],
        monthCount: months.length,
        totalIqd: total,
        paidIqd: paid,
        bonusIqd: bonus,
        deductionIqd: ded,
        advanceRepaymentIqd: adv,
      );
    }

    // ── الوضع الثاني: مجموعة موظفين ──────────────────────────────────
    final employees = await _dao.getEmployeesSummary(
      treasuryId: treasuryId,
      fromYear: fy,
      fromMonth: fm,
      toYear: ty,
      toMonth: tm,
    );

    return EmployeePayrollReportData(
      rangeLabel: rangeLabel,
      employeeName: null,
      position: null,
      treasuryName: treasuryName,
      months: const [],
      employees: employees,
      monthCount: employees.fold<int>(0, (sum, e) => sum + e.monthCount),
      totalIqd: employees.fold<double>(0, (sum, e) => sum + e.totalIqd),
      paidIqd: employees.fold<double>(0, (sum, e) => sum + e.paidIqd),
      bonusIqd: employees.fold<double>(0, (sum, e) => sum + e.bonusIqd),
      deductionIqd:
          employees.fold<double>(0, (sum, e) => sum + e.deductionIqd),
      advanceRepaymentIqd:
          employees.fold<double>(0, (sum, e) => sum + e.advanceRepaymentIqd),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🔑 صرف راتب موظف واحد — **داخل كشف شهره** (قرار المالك 2026-08-26)
  // ═══════════════════════════════════════════════════════════════════════

  /// صرف راتب موظف واحد عن شهر بعينه
  ///
  /// 🔑 **لماذا يمرّ بكشف الشهر بدل أن يكتب سطراً حرّاً؟**
  ///   كان المسار المباشر يكتب سطراً بلا `payroll_period_id`، فيصير في النظام
  ///   **طريقان** لتسجيل راتب: واحد داخل الكشوف وآخر خارجها. وأي تقرير يقرأ
  ///   أحدهما وينسى الآخر يُخفي مالاً خرج فعلاً — وهو الصنف نفسه من العطل
  ///   الذي ضرب المشروع المرجعي DMS، وهو ما ولّد ع-٢٨.
  ///
  ///   بعد التوحيد: الراتب المباشر **سطرٌ في كشف شهره**، فيراه الكشف والتقرير
  ///   السنوي وتقرير الموظف بلا استثناء، ويمنع الفهرس الفريد `(كشف، موظف)`
  ///   ازدواجَه بنيوياً.
  ///
  /// **الحرّاس بالترتيب — كلها قبل أي كتابة:**
  ///   1. الموظف موجود · وعملة راتبه **دينار** (هذا المسار يُنشئ سنداً بالدينار)
  ///   2. سنة مالية **موجودة ومفتوحة** تغطّي شهر الراتب *(قرار المالك)*
  ///   3. الصافي موجب
  ///   4. الموظف **غير مسدَّد** في هذا الشهر — وإلا رُفض بذكر سنده وتاريخه
  ///   5. رصيد الخزينة كافٍ
  ///
  /// **والكشف المُسدَّد يُقبل** *(قرار المالك: الخيار أ)*: الموظف الذي التحق
  /// متأخراً أو نُسي يُضاف سطراً **مسدَّداً** فيبقى الكشف مكتملاً ويقول الدفتر
  /// الحقيقة. ولا يقع تسديد مزدوج: الـ DAO لا يدفع إلا سطراً `unpaid`.
  Future<PaySingleSalaryResult> paySingleEmployee({
    required int employeeId,
    required int year,
    required int month,
    required int treasuryId,
    required double basicSalary,
    double additions = 0,
    double deductions = 0,
    required DateTime paymentDate,
    String notes = '',
    int? paidByUserId,
  }) async {
    final label = PayrollCalculator.periodLabel(year, month);

    // ── 1. الموظف وعملته ─────────────────────────────────────────────
    final employee = await _db.employeesDao.getEmployeeById(employeeId);
    if (employee == null || employee.isDeleted) {
      throw StateError('الموظف غير موجود.');
    }
    if (employee.salaryCurrency != PayrollCurrency.iqd) {
      throw StateError(
        'راتب «${employee.fullName}» بعملة ${employee.salaryCurrency} — '
        'اصرفه من كشف الرواتب حيث يُثبَّت سعر صرف الشهر.\n'
        'الصرف المباشر من بطاقة الموظف يفترض الدينار.',
      );
    }

    // ── 2. السنة المالية لشهر **الراتب** لا لتاريخ الدفع ─────────────
    // منتصف الشهر يقع داخل النطاق يقيناً أياً كانت حدوده.
    final fiscal = await _db.fiscalPeriodsDao
        .getAnyPeriodForDate(DateTime(year, month, 15));
    if (fiscal == null) {
      throw StateError(
        'لا توجد سنة مالية تغطّي $label.\n'
        'أنشئ السنة المالية من شاشة «السنوات المالية» أولاً — '
        'فراتبٌ بلا سنة مالية راتبٌ بلا كشف ولا تقرير.',
      );
    }
    if (fiscal.status != 'active') {
      throw StateError(
        'السنة المالية «${fiscal.name}» التي يقع فيها $label **مُقفَلة** — '
        'لا تُضاف إليها رواتب.',
      );
    }

    // ── 3. الصافي ────────────────────────────────────────────────────
    final net = basicSalary + additions - deductions;
    PayrollCalculator.ensurePayable(employee.fullName, net);
    if (net <= 0) {
      throw StateError(
        'صافي راتب «${employee.fullName}» صفر — لا شيء ليُصرف.',
      );
    }

    // ── 4. هل سُدِّد راتب هذا الشهر أصلاً؟ ────────────────────────────
    final paidAlready = await _dao.getPaidEmployeesForMonth(year, month);
    for (final p in paidAlready) {
      if (p.employeeId != employeeId) continue;
      final when = p.paidAt == null ? '' : ' بتاريخ ${_shortDate(p.paidAt!)}';
      final voucher =
          p.voucherNumber == null ? '' : ' بسند صرف رقم ${p.voucherNumber}';
      throw StateError(
        'راتب «${employee.fullName}» عن $label مصروفٌ سلفاً$when$voucher.\n'
        'لا يُصرف الراتب مرّتين — راجع كشف الشهر.',
      );
    }

    // ── 5. رصيد الخزينة — نفس حارس الصرف العادي ──────────────────────
    final balanceError = await BalanceGuard.checkSufficientBalance(
      _db,
      treasuryId: treasuryId,
      currency: PayrollCurrency.iqd,
      amount: net,
    );
    if (balanceError != null) throw StateError(balanceError);

    // ── التنفيذ الذرّي ───────────────────────────────────────────────
    // إدراج السطر ثم تسديده في **معاملة واحدة**: لا لحظة يظهر فيها كشفٌ
    // مُسدَّد وقد صار «مسودة» بسطر مستحقّ.
    return _db.transaction(() async {
      var period = await _dao.getPeriodForMonth(year, month);
      final wasPosted = period?.status == PayrollStatusDb.posted;

      if (period == null) {
        final id = await _dao.insertPeriod(
          PayrollPeriodsCompanion.insert(
            year: year,
            month: month,
            fiscalPeriodId: fiscal.id,
            createdByUserId: Value(paidByUserId),
            notes: const Value('أُنشئ تلقائياً عند صرف راتب مباشر'),
          ),
        );
        period = await _dao.getPeriodById(id);
      }

      // سطر الموظف: قائمٌ غير مسدَّد (استُورد الملف قبلاً) أم يُنشأ الآن؟
      final existing = await _dao.getEntryForEmployee(
        periodId: period!.id,
        employeeId: employeeId,
      );

      final int entryId;
      if (existing != null) {
        // ⚠️ **يُسدَّد السطر القائم نفسه** لا يُنشأ ثانٍ: الفهرس الفريد
        //   يمنع الثاني أصلاً، والمبلغ المُدخَل هنا هو ما يُصرف فعلاً.
        entryId = existing.id;
        await _dao.updateEntry(
          existing.id,
          SalaryPaymentsCompanion(
            basicSalary: Value(basicSalary),
            additions: Value(additions),
            deductions: Value(deductions),
            netAmount: Value(net),
            netAmountIqd: Value(net),
            notes: notes.trim().isEmpty
                ? const Value.absent()
                : Value(notes.trim()),
          ),
        );
      } else {
        entryId = await _dao.insertEntry(
          SalaryPaymentsCompanion(
            payrollPeriodId: Value(period.id),
            employeeId: Value(employeeId),
            periodLabel: Value(label),
            // اللقطة: حالته لحظة الصرف لا اليوم
            snapshotName: Value(employee.fullName),
            snapshotPosition: Value(employee.position),
            snapshotCurrency: const Value(PayrollCurrency.iqd),
            snapshotHireDate: Value(employee.hireDate),
            basicSalary: Value(basicSalary),
            eligibleDays: Value(period.workingDays),
            additions: Value(additions),
            deductions: Value(deductions),
            netAmount: Value(net),
            netAmountIqd: Value(net),
            paymentDate: Value(paymentDate),
            notes: Value(notes.trim()),
          ),
        );
      }

      final result = await _dao.payEntries(
        periodId: period.id,
        entryIds: [entryId],
        treasuryId: treasuryId,
        fiscalPeriodId: period.fiscalPeriodId,
        paymentDate: paymentDate,
        periodLabel: label,
        paidByUserId: paidByUserId,
        // السند باسم الموظف لا «١ موظفاً» — الدفعة لشخص بعينه
        personNameOverride: employee.fullName,
      );

      return PaySingleSalaryResult(
        periodId: period.id,
        entryId: entryId,
        periodLabel: label,
        employeeName: employee.fullName,
        netIqd: net,
        voucherId: result.voucherId,
        voucherNumber: result.voucherNumber,
        addedToPostedSheet: wasPosted,
        joinedExistingEntry: existing != null,
      );
    });
  }

  /// تاريخ مختصر للرسائل — بلا حزمة تنسيق في طبقة البيانات
  String _shortDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}';
}
