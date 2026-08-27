// ─────────────────────────────────────────────────────────────────────────────
// payroll_repository_corrections.dart — جزء من مكتبة `payroll_repository.dart`
//
// **عمليات ما بعد التسديد**: إلغاء تسديد راتب · تصحيح مبلغه · مقارنة المصروف
// سلفاً بالملف · تنظيف سندات الرواتب اليتيمة.
//
// 🔑 **لماذا جُمعت في ملف واحد؟** لأنها كلها تلمس **مالاً خرج من الخزينة
//   فعلاً** — وهي أخطر ما في نظام الرواتب. جمعُها في موضع واحد يجعل مراجعتها
//   ككتلة ممكنة: من يريد أن يعرف «ما الذي يمكن أن يغيّر مالاً مصروفاً؟» يقرأ
//   هذا الملف وحده.
//
// **وكلها تمرّ بحرّاس ثلاثة:** سببٌ إلزامي مكتوب · فترة مالية مفتوحة ·
// وصلاحية مدير (في طبقة المزوّد). ولا واحدة منها تلمس المال بنفسها: التنفيذ
// الذرّي كلّه في `PayrollDao`.
// ─────────────────────────────────────────────────────────────────────────────

part of 'payroll_repository.dart';

/// عمليات ما بعد التسديد — تُدمَج في [PayrollRepository] فتبقى واجهتها واحدة
mixin PayrollCorrectionsMixin {
  AppDatabase get _db;
  PayrollDao get _dao;

  // ═══════════════════════════════════════════════════════════════════════
  // 🔑 التصحيح بعد التسديد (المرحلة ٦ — 2026-08-26)
  //
  // **لماذا فُتح ما كان مغلقاً؟** قاعدة «المسدَّد لا يُعدَّل» وُضعت لمنع تزوير
  //   التاريخ، فمنعت معها **التصحيح المشروع** — رقمٌ أُدخل خطأً أو استقطاع
  //   نُسي. فكان الطريق الوحيد أمام المالك أن يحذف سند الصرف من شاشة الخزينة
  //   ويلتفّ على النظام كله (ع-٣١).
  //
  //   **حاجزٌ يدفع صاحبه إلى الالتفاف عليه أسوأ من غيابه.** فالمسار المشروع
  //   هنا محروسٌ ومُوثَّق: سببٌ إلزامي · صلاحية مدير · فترة مالية مفتوحة ·
  //   وأثرٌ في سجل التدقيق. والالتفاف صار ممنوعاً في `VouchersDao`.
  // ═══════════════════════════════════════════════════════════════════════

  /// إلغاء تسديد راتب موظف — **العملية الأساس** التي يُبنى عليها التصحيح
  ///
  /// تعكس كل ما فعله التسديد **معاً**: السطر يعود مستحقّاً · حصته تخرج من
  /// السند (أو يُحذف السند إن كان له وحده) · **قسط سلفته يُعاد** · الكشف يعود
  /// مسودة.
  ///
  /// [reason] إلزامي: إلغاءٌ بلا سبب مكتوب لا يُميَّز عن تلاعب بعد شهور.
  Future<UnpaySalaryResult> unpayEntry({
    required int entryId,
    required String reason,
    int? userId,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw StateError(
        'اكتب سبب إلغاء التسديد — سطرٌ يُلغى بلا سبب لا يُميَّز عن تلاعب '
        'حين يُراجَع بعد شهور.',
      );
    }

    final entry = await _dao.getEntryById(entryId);
    if (entry == null) throw StateError('سطر الراتب غير موجود.');
    if (entry.paymentStatus != PayrollPaymentStatusDb.paid) {
      throw StateError(
        'راتب «${entry.snapshotName}» غير مسدَّد أصلاً — لا شيء يُلغى.',
      );
    }

    await _ensureEntryPeriodActive(entry);

    return _dao.unpayEntry(
      entryId: entryId,
      reason: trimmed,
      userId: userId,
    );
  }

  /// تصحيح مبالغ راتب **مسدَّد** — يبقى مسدَّداً ويتغيّر مبلغه
  ///
  /// **الحالتان تختلفان في أثرهما المالي جذرياً** (قرار المالك 2026-08-26):
  ///
  /// | [mode] | ماذا يعني | الأثر |
  /// |---|---|---|
  /// | `dataEntryError` | المبلغ كُتب خطأً والمال لم يخرج به | يُصحَّح السند فيرجع الفرق للخزينة |
  /// | `overpaid` | المال خرج زائداً بيد الموظف | السند كما هو · والفرق **سلفة عليه** تُخصم لاحقاً |
  ///
  /// وخلطُهما يكذب على الخزينة: تقليلُ سندٍ خرج ماله يُظهر رصيداً غير موجود،
  /// وإبقاءُ سندٍ لم يخرج ماله يُخفي رصيداً موجوداً.
  Future<PayrollCorrectionResult> correctPaidEntry({
    required int entryId,
    required String reason,
    required PayrollCorrectionMode mode,
    double? newBasicSalary,
    int? newEligibleDays,
    int? newAbsenceDays,
    double? newAbsenceDeduction,
    double? newBonus,
    double? newDeduction,
    int? userId,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw StateError(
        'اكتب سبب التصحيح — مبلغٌ مصروف يتغيّر بلا سبب مكتوب لا يُميَّز عن '
        'تلاعب حين يُراجَع بعد شهور.',
      );
    }

    final entry = await _dao.getEntryById(entryId);
    if (entry == null) throw StateError('سطر الراتب غير موجود.');
    if (entry.paymentStatus != PayrollPaymentStatusDb.paid) {
      throw StateError(
        'راتب «${entry.snapshotName}» غير مسدَّد — عدّله من الكشف مباشرةً.',
      );
    }

    final period = await _ensureEntryPeriodActive(entry);

    // ── الحساب — يمرّ بـ`PayrollCalculator` كأي مبلغ في النظام ────────
    final manualDays = newEligibleDays ??
        (entry.eligibleDaysIsManual ? entry.eligibleDays : null);
    final manualAbsence = newAbsenceDeduction ??
        (entry.absenceDeductionIsManual ? entry.absenceDeduction : null);

    final amounts = PayrollCalculator.compute(
      year: period.year,
      month: period.month,
      workingDays: period.workingDays,
      basicSalary: newBasicSalary ?? entry.basicSalary,
      currency: entry.snapshotCurrency,
      exchangeRate: entry.exchangeRate ?? period.exchangeRate,
      hireDate: entry.snapshotHireDate,
      absenceDays: newAbsenceDays ?? entry.absenceDays,
      bonus: newBonus ?? entry.additions,
      deduction: newDeduction ?? entry.deductions,
      advanceRepayment: entry.advanceRepaymentAmount,
      manualEligibleDays: newAbsenceDays != null ? null : manualDays,
      manualAbsenceDeduction: manualAbsence,
    );

    PayrollCalculator.ensurePayable(entry.snapshotName, amounts.netSalary);

    final delta = amounts.netSalaryIqd - entry.netAmountIqd;
    if (delta.abs() < 0.001) {
      throw StateError('المبالغ لم تتغيّر — لا شيء يُصحَّح.');
    }

    // ── الأثر على السند والخزينة ─────────────────────────────────────
    var voucherDelta = delta;
    CashAdvancesCompanion? debtAdvance;

    if (delta < 0 && mode == PayrollCorrectionMode.overpaid) {
      // المال خرج فعلاً ⇒ السند صادق كما هو، والفرق صار **ديناً**
      voucherDelta = 0;
      debtAdvance = CashAdvancesCompanion.insert(
        employeeId: Value(entry.employeeId),
        amount: delta.abs(),
        advanceDate: DateTime.now(),
        reason: Value(
          'فرق راتب ${entry.periodLabel} صُرف زائداً — $trimmed',
        ),
      );
    }

    // ── الرصيد: الزيادة صرفٌ جديد يمرّ بالحارس نفسه ──────────────────
    if (voucherDelta > 0) {
      final treasuryId = entry.treasuryId;
      if (treasuryId == null) {
        throw StateError('السطر بلا خزينة — تعذّر التحقّق من الرصيد.');
      }
      final balanceError = await BalanceGuard.checkSufficientBalance(
        _db,
        treasuryId: treasuryId,
        currency: PayrollCurrency.iqd,
        amount: voucherDelta,
      );
      if (balanceError != null) throw StateError(balanceError);
    }

    await _dao.correctPaidEntry(
      entryId: entryId,
      voucherDelta: voucherDelta,
      debtAdvance: debtAdvance,
      changes: SalaryPaymentsCompanion(
        basicSalary: Value(newBasicSalary ?? entry.basicSalary),
        eligibleDays: Value(amounts.eligibleDays),
        eligibleDaysIsManual:
            Value(entry.eligibleDaysIsManual || newEligibleDays != null),
        absenceDays: Value(newAbsenceDays ?? entry.absenceDays),
        absenceDeduction: Value(amounts.absenceDeduction),
        absenceDeductionIsManual: Value(
            entry.absenceDeductionIsManual || newAbsenceDeduction != null),
        additions: Value(newBonus ?? entry.additions),
        deductions: Value(newDeduction ?? entry.deductions),
        netAmount: Value(amounts.netSalary),
        netAmountIqd: Value(amounts.netSalaryIqd),
        // 🔑 السبب في **السطر نفسه** لا في سجل التدقيق وحده: من يفتح الكشف
        //   بعد سنة يرى لماذا اختلف هذا الرقم بلا أن يفتح شاشة أخرى.
        notes: Value(_appendNote(
          entry.notes,
          'صُحِّح من ${entry.netAmountIqd.round()} إلى '
          '${amounts.netSalaryIqd.round()} — $trimmed'
          '${debtAdvance != null ? ' (سُجِّل الفرق سلفةً على الموظف)' : ''}',
        )),
      ),
    );

    return PayrollCorrectionResult(
      entryId: entryId,
      employeeName: entry.snapshotName,
      oldAmountIqd: entry.netAmountIqd,
      newAmountIqd: amounts.netSalaryIqd,
      voucherDelta: voucherDelta,
      debtRecorded: debtAdvance != null ? delta.abs() : 0,
    );
  }

  /// الفترة المالية لكشف السطر — تُرمى إن كانت مُقفَلة
  Future<PayrollPeriod> _ensureEntryPeriodActive(SalaryPayment entry) async {
    final periodId = entry.payrollPeriodId;
    if (periodId == null) {
      throw StateError(
        'هذا الراتب لا ينتسب إلى كشف شهر (سطرٌ قديم) — لا يمكن تصحيحه هنا.',
      );
    }
    final period = await _dao.getPeriodById(periodId);
    if (period == null) throw StateError('كشف الرواتب غير موجود.');
    await FiscalPeriodGuard.ensureActive(_db, period.fiscalPeriodId);
    return period;
  }

  static String _appendNote(String existing, String addition) {
    final base = existing.trim();
    return base.isEmpty ? addition : '$base\n$addition';
  }

  /// إلغاء تسديد **كل** رواتب كشف — بلا حذفه (بلاغ المالك 2026-08-27)
  ///
  /// يمرّ بـ`unpayEntry` لكل سطر مسدَّد: المال يرجع · السندات تُحذف أو
  /// تُنقَص · أقساط السلف تُعاد · والكشف يعود مسودة بسطوره كاملة.
  ///
  /// 🔑 **يُبقي الكشف** بخلاف `deletePeriod` — فالمالك أراد تصحيح شهرٍ
  ///   اعتُمد خطأً لا محوَه.
  Future<({int count, double totalIqd})> unpayPeriod({
    required int periodId,
    required String reason,
    int? userId,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw StateError(
        'اكتب سبب إلغاء التسديد — إرجاع مالٍ خرج بلا سبب مكتوب لا يُميَّز '
        'عن تلاعب حين يُراجَع بعد شهور.',
      );
    }

    final period = await _dao.getPeriodById(periodId);
    if (period == null) throw StateError('كشف الرواتب غير موجود.');
    await FiscalPeriodGuard.ensureActive(_db, period.fiscalPeriodId);

    final paid = (await _dao.getEntries(periodId))
        .where((e) => e.paymentStatus == PayrollPaymentStatusDb.paid)
        .toList();
    if (paid.isEmpty) {
      throw StateError('لا رواتب مسدَّدة في هذا الكشف.');
    }

    var total = 0.0;
    for (final e in paid) {
      final r = await _dao.unpayEntry(
        entryId: e.id,
        reason: trimmed,
        userId: userId,
      );
      total += r.amountIqd;
    }
    return (count: paid.length, totalIqd: total);
  }

  /// كشوف فيها رواتب «مسدَّدة» بسندٍ محذوف (ع-٤٠)
  Future<List<StalePaidPayroll>> getStalePaidPayrolls() =>
      _dao.getStalePaidPayrolls();

  /// إعادة تلك السطور مستحقّة — يُعيد عددها
  ///
  /// ⚠️ **لا تلمس مالاً**: السند محذوف والمال رجع أصلاً. كل ما تفعله أن
  ///   تجعل السجل يطابق الواقع.
  Future<int> restoreStalePaidPayroll({
    required int periodId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw StateError('اكتب سبب الإصلاح.');
    }
    final period = await _dao.getPeriodById(periodId);
    if (period == null) throw StateError('كشف الرواتب غير موجود.');
    await FiscalPeriodGuard.ensureActive(_db, period.fiscalPeriodId);

    return _dao.restoreStalePaidEntries(
      periodId: periodId,
      reason: reason.trim(),
    );
  }
}
