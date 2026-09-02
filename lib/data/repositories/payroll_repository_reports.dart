// ─────────────────────────────────────────────────────────────────────────────
// payroll_repository_reports.dart — جزء من مكتبة `payroll_repository.dart`
//
// بناء بيانات المستندات والتقارير: كشف الشهر · إيصال الراتب · تقرير السنة ·
// تقرير الموظف.
//
// **لماذا فُصلت؟** بلغ الملف الأصل ١٣٨٢ سطراً بعد إضافة التصحيح وإلغاء
// التسديد، فتجاوز حدّ الـ١٢٠٠ الذي يحرسه `tech_debt_guard_test`.
//
// 🔑 **والفصل هنا طبيعي لا اعتباطيّ**: هذه التوابع **تقرأ ولا تكتب** — لا
//   تلمس مالاً ولا حالة. وما بقي في الملف الأصل هو ما يمسّ الدفاتر (التسديد
//   والتصحيح والاستيراد)، فيبقى مجموعاً في موضع واحد يُراجَع كوحدة.
//
// ⚠️ ولا تُعيد هذه التوابع حساب أي مجموع: الإجماليات تأتي من
//   `PayrollDao.getTotals` وحدها — مجموعٌ ثانٍ يعني رقمين يمكن أن يختلفا.
// ─────────────────────────────────────────────────────────────────────────────

part of 'payroll_repository.dart';

/// تقارير الرواتب — يُدمَج في [PayrollRepository] فتبقى واجهتها **واحدة**
///
/// ⚠️ **لماذا `mixin` لا `extension`؟** الامتداد لا يُرى إلا حيث تُستورَد
///   مكتبته صراحةً، فكان كل مستدعٍ للطباعة سيحتاج استيراداً إضافياً —
///   ومَن ينسى الاستيراد يحصل على خطأ «التابع غير معرَّف» بلا سبب ظاهر.
///   الـ`mixin` يجعل التوابع أعضاءً في الصنف نفسه، فلا يتغيّر شيء عند
///   المستدعين ولا يعرف أحدٌ أن الملف قُسِّم أصلاً.
mixin PayrollReportsMixin {
  // يوفّرهما الصنف المُضيف — التقارير تقرأ ولا تكتب
  AppDatabase get _db;
  PayrollDao get _dao;



  /// تجميع كشف شهر جاهزاً للطباعة
  ///
  /// 🔑 **الإجماليات تُقرأ من [PayrollDao.getTotals] ولا تُجمع هنا.**
  ///   لو جمعت الورقةُ سطورَها بنفسها لصار في النظام مجموعان يمكن أن
  ///   يختلفا، ولا يُعرَف عندها أيّهما يُصدَّق: الشاشة أم الورقة المختومة
  ///   المرفوعة للأرشيف. مصدر الحقيقة واحد — والاختبار يحرس تطابقهما.
  ///
  /// [withSignatureColumn] — عمود توقيع الاستلام (قرار المالك 2026-08-26)
  Future<PayrollSheetPrintData> buildSheetPrintData(
    int periodId, {
    bool withSignatureColumn = false,
  }) async {
    final period = await _dao.getPeriodById(periodId);
    if (period == null) throw StateError('كشف الرواتب غير موجود.');

    // بترتيب المعرّف = ترتيب ملف المحاسب، فتُطابَق الورقة بورقته سطراً بسطر
    final entries = await _dao.getEntries(periodId);
    final totals = await _dao.getTotals(periodId);

    return PayrollSheetPrintData(
      periodLabel: PayrollCalculator.periodLabel(period.year, period.month),
      workingDays: period.workingDays,
      exchangeRate: period.exchangeRate,
      isPosted: period.status == PayrollStatusDb.posted,
      employeeCount: totals.entryCount,
      totalIqd: totals.totalIqd,
      paidIqd: totals.totalIqd - totals.unpaidIqd,
      unpaidIqd: totals.unpaidIqd,
      fileTotal: period.fileTotal,
      withSignatureColumn: withSignatureColumn,
      rows: [
        for (var i = 0; i < entries.length; i++)
          _printRow(entries[i], i + 1, period.workingDays, period.postedAt),
      ],
    );
  }

  PayrollSheetPrintRow _printRow(
    SalaryPayment e,
    int seq,
    int workingDays,
    DateTime? postedAt,
  ) {
    return PayrollSheetPrintRow(
      seq: seq,
      name: e.snapshotName,
      position: e.snapshotPosition,
      currency: e.snapshotCurrency,
      basicSalary: e.basicSalary,
      eligibleDays: e.eligibleDays,
      workingDays: workingDays,
      absenceDays: e.absenceDays,
      leaveDaysPaid: e.leaveDaysPaid,
      leaveDaysUnpaid: e.leaveDaysUnpaid,
      absenceDeduction: e.absenceDeduction,
      bonus: e.additions,
      deduction: e.deductions,
      advanceRepayment: e.advanceRepaymentAmount,
      net: e.netAmount,
      netIqd: e.netAmountIqd,
      isPaid: e.paymentStatus == PayrollPaymentStatusDb.paid,
      // أُضيف بعد الاعتماد؟ — يُشتقّ بلا عمود جديد
      //
      // ⚠️ **من `paid_at` لا `created_at`**: العمود الأخير تملؤه قاعدة
      //   البيانات بدقّة **الثانية** (نصّ `2026-08-26 11:55:09`) بينما
      //   `posted_at` يكتبه كودنا بدقّة الميلي ثانية — فمقارنتهما داخل
      //   الثانية نفسها تُعطي «ليس بعده» وهو خطأ. أما `paid_at` و`posted_at`
      //   فيكتبهما كودنا معاً، وفي الدفعة الواحدة هما **القيمة نفسها**
      //   حرفياً (`now` واحدة في `payEntries`) — فالمقارنة دقيقة.
      addedAfterPosting:
          postedAt != null && e.paidAt != null && e.paidAt!.isAfter(postedAt),
    );
  }

  /// تجميع إيصال راتب موظف واحد — `null` حين لا يوجد السطر
  ///
  /// يقرأ **رقم السند واسم الخزينة** حين يكون مسدَّداً: إيصالٌ بلا سند لا
  /// يمكن ردّه إلى حركة في الدفاتر، فيصير ورقةً تدّعي دفعاً بلا أثر.
  Future<SalarySlipPrintData?> buildSlipPrintData(int entryId) async {
    final e = await _dao.getEntryById(entryId);
    if (e == null || e.isDeleted) return null;

    final period = e.payrollPeriodId == null
        ? null
        : await _dao.getPeriodById(e.payrollPeriodId!);

    // ⚠️ **الاسم لا يُترك فارغاً أبداً.** سطور ما قبل v7 (ورواتب صُرفت من
    //   بطاقة الموظف) بلا لقطة اسم، وإيصالٌ بلا اسم ورقةٌ لا تخصّ أحداً.
    //   نقع على الاسم الحالي عندها — وهو أفضل الموجود، لا أفضل الممكن.
    var name = e.snapshotName.trim();
    if (name.isEmpty) {
      final emp = await _db.employeesDao.getEmployeeById(e.employeeId);
      name = emp?.fullName ?? 'موظف #${e.employeeId}';
    }

    int? voucherNumber;
    if (e.voucherId != null) {
      final v = await _db.vouchersDao.getVoucherById(e.voucherId!);
      voucherNumber = v?.voucherNumber;
    }

    String? treasuryName;
    if (e.treasuryId != null) {
      final t = await _db.treasuriesDao.getTreasuryById(e.treasuryId!);
      treasuryName = t?.name;
    }

    return SalarySlipPrintData(
      periodLabel: period != null
          ? PayrollCalculator.periodLabel(period.year, period.month)
          : (e.periodLabel.isEmpty ? '—' : e.periodLabel),
      employeeName: name,
      position: e.snapshotPosition,
      hireDate: e.snapshotHireDate,
      currency: e.snapshotCurrency,
      basicSalary: e.basicSalary,
      eligibleDays: e.eligibleDays,
      workingDays: period?.workingDays ?? PayrollCalculator.defaultWorkingDays,
      absenceDays: e.absenceDays,
      absenceDeduction: e.absenceDeduction,
      bonus: e.additions,
      deduction: e.deductions,
      advanceRepayment: e.advanceRepaymentAmount,
      net: e.netAmount,
      netIqd: e.netAmountIqd,
      exchangeRate: e.exchangeRate ?? period?.exchangeRate,
      isPaid: e.paymentStatus == PayrollPaymentStatusDb.paid,
      voucherNumber: voucherNumber,
      paidAt: e.paidAt,
      treasuryName: treasuryName,
    );
  }

  /// تقرير رواتب سنة — الأشهر وتوزيع المسدَّد على الخزائن
  Future<PayrollYearReportData> buildYearReport(int year) async {
    final months = await _dao.getYearMonths(year);
    final shares = await _dao.getYearTreasuryShares(year);
    return PayrollYearReportData(
      year: year,
      months: months,
      treasuryShares: shares,
    );
  }

  /// رواتب صُرفت في السنة خارج أي كشف — يعرضها التقرير في شريط منفصل
  Future<({int count, double totalIqd})> getOutOfSheetSalaries(int year) =>
      _dao.getOutOfSheetSalaries(year);

  /// مقارنة من صُرف راتبه سلفاً بما يحسبه ملف الشهر
  ///
  /// 🔑 **سبب وجودها** (بلاغ المالك 2026-08-26): صرف راتباً كاملاً (٣٠ يوماً)
  ///   لموظف له أربعة أيام غياب، ثم استورد ملف الشهر — فظهر فرق ٢٣٣٬٣٣٢
  ///   **بلا سبب**. والبرنامج كان يعرف السبب ولا يقوله: الرقمان كلاهما في
  ///   يده لحظة الاستيراد.
  ///
  ///   **تنبيهٌ يذكر رقماً بلا سببه يُدرّب العين على تخطّي ما حوله.**
  ///
  /// تمرّ بـ`PayrollCalculator.compute` نفسها التي يستعملها الاستيراد — فلا
  /// حساب ثانٍ يمكن أن يختلف عن الأول.
  Future<List<PaidVsFileComparison>> comparePaidWithFile({
    required int year,
    required int month,
    required List<({int employeeId, ParsedPayrollRow row})> rows,
  }) async {
    final period = await _dao.getPeriodForMonth(year, month);
    if (period == null) return const [];

    final entries = await _dao.getEntries(period.id);
    final paidByEmployee = {
      for (final e in entries)
        if (e.paymentStatus == PayrollPaymentStatusDb.paid) e.employeeId: e,
    };

    final result = <PaidVsFileComparison>[];
    for (final item in rows) {
      final paid = paidByEmployee[item.employeeId];
      if (paid == null) continue;

      final r = item.row;
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

      result.add(PaidVsFileComparison(
        employeeId: item.employeeId,
        employeeName: paid.snapshotName.isEmpty
            ? r.employeeName
            : paid.snapshotName,
        paidIqd: paid.netAmountIqd,
        fileIqd: amounts.netSalaryIqd,
        paidDays: paid.eligibleDays,
        fileDays: amounts.eligibleDays,
        paidAt: paid.paidAt,
      ));
    }
    return result;
  }
}
