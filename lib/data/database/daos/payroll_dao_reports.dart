// ─────────────────────────────────────────────────────────────────────────────
// payroll_dao_reports.dart — جزء من مكتبة `payroll_dao.dart`
//
// **استعلامات القراءة فقط**: تقرير الموظف · تقرير السنة · الرواتب خارج الكشوف.
//
// 🔑 **لماذا فُصلت؟** بلغ الملف الأصل حدّ الـ١٢٠٠ سطر الذي يحرسه
//   `tech_debt_guard_test`. والفصل هنا طبيعي: **لا سطر منها يكتب شيئاً**، وما
//   بقي في الأصل هو ما يلمس الدفاتر — فيُراجَع كوحدة.
//
// ⚠️ ولا تحسب هذه الاستعلامات مجموعاً موازياً: مجموع الكشف مصدره
//   `PayrollDao.getTotals` وحدها.
// ─────────────────────────────────────────────────────────────────────────────

part of 'payroll_dao.dart';

/// استعلامات تقارير الرواتب — تُدمَج في [PayrollDao]
///
/// **`db.` أمام أسماء الجداول** لأن الـmixin لا يرى مولَّد الـDAO
/// (`_$PayrollDaoMixin`)، وقاعدة البيانات تعرض الجداول كلها.
mixin PayrollReportQueries on DatabaseAccessor<AppDatabase> {
  // ═══════════════════════════════════════════════════════════════════════
  // تقرير الموظف (طلب المالك 2026-08-26)
  // ═══════════════════════════════════════════════════════════════════════

  /// شرط المدى الشهري — يشمل السطور القديمة التي لا كشف لها
  ///
  /// 🔑 **لماذا فرعان؟** السطر المنتسب لكشف يُقاس بشهر كشفه (وهو الصواب:
  ///   راتب آب راتبُ آب ولو صُرف في أيلول). أما السطر القديم الذي كُتب قبل
  ///   توحيد الصرف المباشر فلا كشف له، فيُقاس بتاريخ صرفه — وإسقاطه كان
  ///   سيُخفي مالاً خرج فعلاً.
  static const String _rangeCondition =
      '((p.id IS NOT NULL AND (p.year * 12 + p.month) BETWEEN ? AND ?) '
      ' OR (p.id IS NULL AND s.payment_date >= ? AND s.payment_date < ?))';

  /// مبلغٌ بعملة السطر مضروباً بسعر صرفه — يُوحّد الجمع بالدينار
  ///
  /// ⚠️ جمعُ مكافأةٍ بالدولار على أخرى بالدينار يُنتج رقماً بلا معنى.
  ///   نفس الطريقة التي يُحسب بها `net_amount_iqd` لحظة الحفظ.
  static String _toIqd(String column) =>
      "($column * CASE WHEN s.snapshot_currency = 'USD' "
      'THEN COALESCE(s.exchange_rate, 0) ELSE 1 END)';

  List<Variable> _rangeVars(
    int fromYear,
    int fromMonth,
    int toYear,
    int toMonth,
  ) {
    return [
      Variable.withInt(fromYear * 12 + fromMonth),
      Variable.withInt(toYear * 12 + toMonth),
      Variable.withDateTime(DateTime(fromYear, fromMonth, 1)),
      // أوّل الشهر التالي — الحدّ الأعلى **حصريّ**
      //
      // ⚠️ لا تُزح بـ`Duration(days: 1)` لمحاكاة `<=`: تُزيح ٨٦٬٤٠٠ ثانية
      //   لا لحظة، فتبتلع يوماً كاملاً من الشهر التالي (الدرس ع-٠٩).
      Variable.withDateTime(DateTime(toYear, toMonth + 1, 1)),
    ];
  }

  /// رواتب موظف واحد شهراً شهراً خلال مدى — **بكل تفاصيل كل شهر**
  Future<List<EmployeePayrollMonth>> getEmployeeMonths({
    required int employeeId,
    required int fromYear,
    required int fromMonth,
    required int toYear,
    required int toMonth,
  }) async {
    final rows = await customSelect(
      'SELECT p.year AS y, p.month AS m, p.working_days AS wd, '
      '       s.payroll_period_id AS pid, s.snapshot_currency AS cur, '
      '       s.basic_salary AS basic, s.eligible_days AS days, '
      '       s.absence_days AS absd, s.absence_deduction AS absded, '
      '       s.additions AS bonus, s.deductions AS ded, '
      '       s.advance_repayment_amount AS adv, '
      '       s.net_amount AS net, s.net_amount_iqd AS netiqd, '
      '       s.payment_status AS st, s.paid_at AS pa, '
      '       s.payment_date AS pd, t.name AS tname, '
      '       v.voucher_number AS vn '
      'FROM salary_payments s '
      'LEFT JOIN payroll_periods p '
      '       ON p.id = s.payroll_period_id AND p.is_deleted = 0 '
      'LEFT JOIN treasuries t ON t.id = s.treasury_id '
      'LEFT JOIN vouchers v ON v.id = s.voucher_id '
      'WHERE s.is_deleted = 0 AND s.employee_id = ? AND $_rangeCondition '
      'ORDER BY COALESCE(p.year * 12 + p.month, 0), s.id',
      variables: [
        Variable.withInt(employeeId),
        ..._rangeVars(fromYear, fromMonth, toYear, toMonth),
      ],
      readsFrom: {db.salaryPayments, db.payrollPeriods, db.treasuries, db.vouchers},
    ).get();

    return rows.map((r) {
      // السطر بلا كشف يُنسَب لشهر **تاريخ صرفه**
      final fallback = r.read<DateTime?>('pd');
      return EmployeePayrollMonth(
        year: r.read<int?>('y') ?? fallback?.toLocal().year ?? 0,
        month: r.read<int?>('m') ?? fallback?.toLocal().month ?? 0,
        periodId: r.read<int?>('pid'),
        currency: r.read<String?>('cur') ?? PayrollCurrency.iqd,
        basicSalary: (r.data['basic'] as num?)?.toDouble() ?? 0.0,
        eligibleDays: r.read<int?>('days') ?? 0,
        workingDays: r.read<int?>('wd') ?? 0,
        absenceDays: r.read<int?>('absd') ?? 0,
        absenceDeduction: (r.data['absded'] as num?)?.toDouble() ?? 0.0,
        bonus: (r.data['bonus'] as num?)?.toDouble() ?? 0.0,
        deduction: (r.data['ded'] as num?)?.toDouble() ?? 0.0,
        advanceRepayment: (r.data['adv'] as num?)?.toDouble() ?? 0.0,
        net: (r.data['net'] as num?)?.toDouble() ?? 0.0,
        netIqd: (r.data['netiqd'] as num?)?.toDouble() ?? 0.0,
        isPaid: r.read<String?>('st') == PayrollPaymentStatusDb.paid,
        paidAt: r.read<DateTime?>('pa'),
        paidFromTreasury: r.read<String?>('tname'),
        voucherNumber: r.read<int?>('vn'),
      );
    }).toList();
  }

  /// مجاميع كل موظف خلال مدى — مع فلتر المشروع (خزينة الموظف)
  ///
  /// [treasuryId] — `null` يعني كل الموظفين
  Future<List<EmployeePayrollSummaryRow>> getEmployeesSummary({
    int? treasuryId,
    required int fromYear,
    required int fromMonth,
    required int toYear,
    required int toMonth,
  }) async {
    final rows = await customSelect(
      'SELECT s.employee_id AS eid, e.full_name AS nm, e.position AS pos, '
      '       COUNT(*) AS months, '
      '       COALESCE(SUM(s.net_amount_iqd), 0) AS total, '
      "       COALESCE(SUM(CASE WHEN s.payment_status = 'paid' "
      '                    THEN s.net_amount_iqd ELSE 0 END), 0) AS paid, '
      '       COALESCE(SUM(${_toIqd('s.additions')}), 0) AS bonus, '
      '       COALESCE(SUM(${_toIqd('s.deductions + s.absence_deduction')}), 0)'
      '         AS ded, '
      '       COALESCE(SUM(${_toIqd('s.advance_repayment_amount')}), 0) AS adv '
      'FROM salary_payments s '
      'INNER JOIN employees e ON e.id = s.employee_id '
      'LEFT JOIN payroll_periods p '
      '       ON p.id = s.payroll_period_id AND p.is_deleted = 0 '
      'WHERE s.is_deleted = 0 AND $_rangeCondition '
      '  AND (? = 0 OR e.treasury_id = ?) '
      'GROUP BY s.employee_id '
      'ORDER BY total DESC',
      variables: [
        ..._rangeVars(fromYear, fromMonth, toYear, toMonth),
        Variable.withInt(treasuryId ?? 0),
        Variable.withInt(treasuryId ?? 0),
      ],
      readsFrom: {db.salaryPayments, db.payrollPeriods, db.employees},
    ).get();

    return rows
        .map((r) => EmployeePayrollSummaryRow(
              employeeId: r.read<int>('eid'),
              employeeName: r.read<String?>('nm') ?? '',
              position: r.read<String?>('pos') ?? '',
              monthCount: r.read<int?>('months') ?? 0,
              totalIqd: (r.data['total'] as num?)?.toDouble() ?? 0.0,
              paidIqd: (r.data['paid'] as num?)?.toDouble() ?? 0.0,
              bonusIqd: (r.data['bonus'] as num?)?.toDouble() ?? 0.0,
              deductionIqd: (r.data['ded'] as num?)?.toDouble() ?? 0.0,
              advanceRepaymentIqd: (r.data['adv'] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // الكاشف المرآة — رواتب «مسدَّدة» بسندٍ محذوف (ع-٤٠)
  // ═══════════════════════════════════════════════════════════════════════

  /// رواتب «مسدَّدة» فقدت سندها
  ///
  /// السطر مسدَّد وحيّ، وسنده **محذوف أو مفقود**: المال رجع إلى الخزينة
  /// والكشف والتقارير وبطاقات الموظفين تقول «مصروف».
  ///
  /// 🔑 **مرآة كاشف السندات اليتيمة**: ذاك يبحث عن سندٍ بلا سطور، وهذا عن
  ///   سطورٍ بلا سند. ويكشف **العَرَض لا السبب** — فيلتقط أي بابٍ سابع.
  Future<List<StalePaidPayroll>> getStalePaidPayrolls() async {
    final rows = await customSelect(
      'SELECT p.id AS pid, p.year AS y, p.month AS m, '
      '       COUNT(*) AS cnt, COALESCE(SUM(s.net_amount_iqd), 0) AS total '
      'FROM salary_payments s '
      'INNER JOIN payroll_periods p ON p.id = s.payroll_period_id '
      'LEFT JOIN vouchers v ON v.id = s.voucher_id '
      'WHERE s.is_deleted = 0 AND p.is_deleted = 0 '
      "  AND s.payment_status = 'paid' "
      '  AND (v.id IS NULL OR v.is_deleted = 1) '
      'GROUP BY p.id '
      'ORDER BY p.year DESC, p.month DESC',
      readsFrom: {db.salaryPayments, db.payrollPeriods, db.vouchers},
    ).get();

    return rows
        .map((r) => StalePaidPayroll(
              periodId: r.read<int>('pid'),
              periodLabel: PayrollCalculator.periodLabel(
                  r.read<int>('y'), r.read<int>('m')),
              entryCount: r.read<int?>('cnt') ?? 0,
              totalIqd: (r.data['total'] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();
  }

  /// إعادة سطور كشفٍ فقدت سندها إلى «مستحقّة» — إصلاح الحالة العالقة
  ///
  /// ⚠️ **لا يلمس مالاً**: السند محذوف أصلاً والمال رجع. كل ما يفعله أن
  ///   يجعل **السجل يطابق الواقع**.
  Future<int> restoreStalePaidEntries({
    required int periodId,
    required String reason,
  }) async {
    return transaction(() async {
      final now = DateTime.now();

      final stale = await customSelect(
        'SELECT s.id AS sid FROM salary_payments s '
        'LEFT JOIN vouchers v ON v.id = s.voucher_id '
        'WHERE s.payroll_period_id = ? AND s.is_deleted = 0 '
        "  AND s.payment_status = 'paid' "
        '  AND (v.id IS NULL OR v.is_deleted = 1)',
        variables: [Variable.withInt(periodId)],
        readsFrom: {db.salaryPayments, db.vouchers},
      ).get();

      for (final row in stale) {
        await (update(db.salaryPayments)
              ..where((s) => s.id.equals(row.read<int>('sid'))))
            .write(SalaryPaymentsCompanion(
          paymentStatus: const Value(PayrollPaymentStatusDb.unpaid),
          paidAt: const Value(null),
          voucherId: const Value(null),
          treasuryId: const Value(null),
          advanceId: const Value(null),
          advanceLineId: const Value(null),
          updatedAt: Value(now),
        ));
      }

      if (stale.isNotEmpty) {
        // الكشف يتبع سطوره — و`posted_at` يبقى شاهداً على اعتماده الأول
        await (update(db.payrollPeriods)..where((p) => p.id.equals(periodId)))
            .write(const PayrollPeriodsCompanion(
          status: Value(PayrollStatusDb.draft),
        ));
      }
      return stale.length;
    });
  }
}
