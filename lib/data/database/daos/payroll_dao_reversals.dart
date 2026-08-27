// ─────────────────────────────────────────────────────────────────────────────
// payroll_dao_reversals.dart — جزء من مكتبة `payroll_dao.dart`
//
// **كل ما يعكس راتباً خرج ماله**: إلغاء التسديد · التصحيح · عكس رواتب سلفة
// مُلغاة · تسجيل أقساط سلف الموظفين وعكسها.
//
// 🔑 **لماذا جُمعت هنا؟** لأن هذه العمليات هي **مصدر خمسة أعطال متتالية**
//   (ع-٢٨ · ع-٣١ · ع-٣٣ · ع-٣٦ · ع-٣٧)، وكلها من علّة واحدة: الراتب المدفوع
//   يعيش في ثلاثة أماكن (سطر الكشف · سند الصرف · قسط السلفة) وكل بابٍ يعرف
//   مكاناً ويجهل الباقي.
//
//   جمعُها في ملف واحد يجعل السؤال «ما الذي يلمس راتباً مدفوعاً؟» له جواب
//   واحد يُقرأ ككتلة — بدل أن يُبحَث عنه في أربعة ملفات.
// ─────────────────────────────────────────────────────────────────────────────

part of 'payroll_dao.dart';

/// عمليات عكس الرواتب — تُدمَج في [PayrollDao]
mixin PayrollReversals on DatabaseAccessor<AppDatabase> {
  // يوفّرها الصنف المُضيف
  Future<SalaryPayment?> getEntryById(int id);
  Future<void> updateEntry(int id, SalaryPaymentsCompanion changes);

  /// تسجيل أقساط سلف الموظفين المخصومة من رواتب سُدِّدت — يُعيد عددها
  ///
  /// لا سند قبض معها: المال لم يتحرّك، بل خرج راتبٌ أقل. ولهذا وُجدت طريقة
  /// `'salary_deduction'` في `cash_advance_repayments` منذ البداية.
  ///
  /// 🔑 **ولماذا تابعٌ عامّ لا كتلة داخل `payEntries`؟** (ع-٣٧ — 2026-08-27)
  ///   لأن للرواتب **مسارَي تسديد**: `payEntries` (من خزينة) و
  ///   `AdvancesDao.postAdvance` (عبر سلفة مشروع). وكان الثاني يُعلّم السطور
  ///   مدفوعة **بلا تسجيل أقساطها** — فيُخصَم من راتب الموظف ولا يُحسَب له،
  ///   وتبقى سلفته كاملةً عليه. مالٌ يختفي من الجهة الأخرى بصمت.
  ///
  ///   كتلةٌ مكرّرة في مسارين كانت ستُصلَح في أحدهما وتُنسى في الآخر — وهي
  ///   علّة ع-٢٨ و ع-٣١ و ع-٣٣ و ع-٣٦ نفسها. **مسارٌ واحد يمرّ به الاثنان.**
  Future<int> recordSalaryDeductions({
    required List<SalaryPayment> entries,
    required DateTime paymentDate,
    required int voucherId,
    required String periodLabel,
  }) async {
    var repayments = 0;
    for (final e in entries) {
      if (e.advanceRepaymentAmount <= 0 || e.cashAdvanceId == null) continue;

      final advance = await db.employeesDao.getAdvanceById(e.cashAdvanceId!);

      // ⚠️ **لا تخطٍّ صامت.** الخصم وقع فعلاً في الصافي المصروف، فلو لم
      //   يُسجَّل قسطه بقيت السلفة كاملةً على الموظف: خُصم من راتبه ولم
      //   يُحسَب له. الفشل هنا يُلغي الدفعة كلها — وهو الصواب.
      if (advance == null || advance.isDeleted) {
        throw StateError(
          'خصم سلفة لـ«${e.snapshotName}» يشير إلى سلفة غير موجودة — '
          'أزل الخصم أو صحّح ربطه قبل التسديد.',
        );
      }

      final newRepaid = advance.totalRepaid + e.advanceRepaymentAmount;
      // قيد `CHECK(total_repaid <= amount)` كان سيرمي رسالة إنجليزية
      // غامضة. نسبقه برسالة تسمّي الموظف والمبلغ الفائض.
      if (newRepaid > advance.amount + 0.001) {
        final remaining = advance.amount - advance.totalRepaid;
        throw StateError(
          'خصم سلفة «${e.snapshotName}» (${e.advanceRepaymentAmount}) '
          'يتجاوز المتبقي من سلفته ($remaining).',
        );
      }

      await db.employeesDao.insertRepayment(
        repayment: CashAdvanceRepaymentsCompanion.insert(
          cashAdvanceId: advance.id,
          amount: e.advanceRepaymentAmount,
          repaymentDate: paymentDate,
          method: const Value('salary_deduction'),
          // 🔑 **يُربَط القسط بسنده** (2026-08-26): بدونه لا سبيل لمعرفة أي
          //   قسطٍ وُلد من أي راتب حين يُلغى التسديد، فيبقى الخصم قائماً بلا
          //   مقابل. والعمود موجود أصلاً في الجدول ولم يكن يُملأ.
          voucherId: Value(voucherId),
          notes: Value('خصم من راتب $periodLabel'),
        ),
        advanceId: advance.id,
        newTotalRepaid: newRepaid,
        // المقارنة بهامش: الفاصلة العائمة تجعل المساواة التامة غير مضمونة
        newStatus: newRepaid >= advance.amount - 0.001 ? 'paid' : 'partial',
      );
      repayments++;
    }
    return repayments;
  }

  /// رواتب سلفة **المسدَّدة حالياً** — تُقرأ قبل الإلغاء لعرض أثره
  Future<List<SalaryPayment>> getPaidEntriesForAdvance(int advanceId) {
    return (select(db.salaryPayments)
          ..where((s) =>
              s.advanceId.equals(advanceId) &
              s.isDeleted.equals(false) &
              s.paymentStatus.equals(PayrollPaymentStatusDb.paid)))
        .get();
  }

  /// عكس **كل** رواتب سلفة مُلغاة — تُستدعى من `AdvancesDao.cancelAdvance`
  ///
  /// 🔴 **العطل الذي وُلدت منه** (ع-٣٦ — بلاغ المالك 2026-08-27): إلغاء سلفة
  ///   معتمدة كان يحذف سنداتها ويُعيد المال إلى الخزينة، **ويترك سطور
  ///   الرواتب مسدَّدة**: الكشف «مُسدَّد» والموظفون يظهرون مستلمين في
  ///   بطاقاتهم وفي كل تقرير — ومالُهم رجع إلى الخزينة.
  ///
  /// ⚠️ **ولماذا لم يحمِ حارس سند الرواتب (ع-٣١)؟** لأن `cancelAdvance`
  ///   يكتب على جدول السندات **مباشرةً** فلا يمرّ بـ`softDeleteVoucher`.
  ///   **الحارس لا يحمي من كاتبٍ لا يمرّ به.**
  ///
  /// 📌 **لا تلمس السندات هنا**: المستدعي يحذفها في المعاملة نفسها. ولو
  ///   حذفناها هنا أيضاً لتضاعف العمل ولاختلف ترتيب الأثر بين المسارين.
  ///
  /// تُعيد ما وقع فعلاً ليُعرَض ويُوثَّق.
  Future<AdvancePayrollReversal> unpayEntriesForAdvance({
    required int advanceId,
    required String reason,
  }) async {
    final entries = await (select(db.salaryPayments)
          ..where((s) =>
              s.advanceId.equals(advanceId) &
              s.isDeleted.equals(false) &
              s.paymentStatus.equals(PayrollPaymentStatusDb.paid)))
        .get();

    if (entries.isEmpty) {
      return const AdvancePayrollReversal(
        employeeCount: 0,
        totalIqd: 0,
        reversedRepayments: 0,
        periodLabels: [],
      );
    }

    final now = DateTime.now();
    var total = 0.0;
    var repayments = 0;
    final periodIds = <int>{};

    for (final e in entries) {
      // ⚠️ قسط سلفة الموظف أولاً — إلغاءٌ بلا عكسه يترك السلفة منقوصة
      //   بمبلغٍ لم يُدفَع (نفس منطق `unpayEntry`)
      if (e.advanceRepaymentAmount > 0 && e.cashAdvanceId != null) {
        final reversed = await _reverseSalaryDeduction(e);
        if (reversed > 0) repayments++;
      }

      await (update(db.salaryPayments)..where((s) => s.id.equals(e.id))).write(
        SalaryPaymentsCompanion(
          paymentStatus: const Value(PayrollPaymentStatusDb.unpaid),
          paidAt: const Value(null),
          voucherId: const Value(null),
          treasuryId: const Value(null),
          advanceId: const Value(null),
          // الرباط بسطر السلفة يُفكّ أيضاً: السلفة ألغيت فلا معنى لبقائه
          advanceLineId: const Value(null),
          notes: Value(_appendNote(e.notes, 'أُلغيت سلفته: $reason')),
          updatedAt: Value(now),
        ),
      );

      total += e.netAmountIqd;
      if (e.payrollPeriodId != null) periodIds.add(e.payrollPeriodId!);
    }

    // ── الكشوف تتبع سطورها ───────────────────────────────────────────
    final labels = <String>[];
    for (final id in periodIds) {
      final period = await (select(db.payrollPeriods)
            ..where((p) => p.id.equals(id)))
          .getSingleOrNull();
      if (period == null) continue;
      labels.add(PayrollCalculator.periodLabel(period.year, period.month));

      // `posted_at` يبقى شاهداً على اعتماده الأول — محوُه يمحو تاريخاً وقع
      await (update(db.payrollPeriods)..where((p) => p.id.equals(id)))
          .write(const PayrollPeriodsCompanion(
        status: Value(PayrollStatusDb.draft),
      ));
    }

    return AdvancePayrollReversal(
      employeeCount: entries.length,
      totalIqd: total,
      reversedRepayments: repayments,
      periodLabels: labels,
    );
  }

  /// تصحيح مبالغ سطر **مسدَّد** — يبقى مسدَّداً ويتغيّر مبلغه
  ///
  /// [voucherDelta] — ما يُضاف إلى مبلغ السند (سالبٌ حين ينقص، وصفرٌ حين
  /// يُترك كما هو لأن المال خرج فعلاً وصار الفرق ديناً على الموظف).
  ///
  /// ⚠️ لا حرّاس هنا — الرصيد والفترة والصلاحية مسؤولية `PayrollRepository`.
  Future<void> correctPaidEntry({
    required int entryId,
    required SalaryPaymentsCompanion changes,
    required double voucherDelta,
    CashAdvancesCompanion? debtAdvance,
  }) async {
    return transaction(() async {
      final entry = await getEntryById(entryId);
      if (entry == null) throw StateError('سطر الراتب غير موجود.');

      await (update(db.salaryPayments)..where((s) => s.id.equals(entryId)))
          .write(changes.copyWith(updatedAt: Value(DateTime.now())));

      if (voucherDelta != 0 && entry.voucherId != null) {
        await _shiftVoucherAmount(entry.voucherId!, voucherDelta);
      }

      // الفرق الذي خرج فعلاً ولم يُستحقّ ⇒ سلفة على الموظف تُخصم لاحقاً
      if (debtAdvance != null) {
        await db.employeesDao.insertAdvance(debtAdvance);
      }
    });
  }

  // ── أدوات داخلية ───────────────────────────────────────────────────────

  /// عكس قسط سلفة وُلد من هذا الراتب — يُعيد المبلغ المعكوس
  ///
  /// **كيف يُعثَر على القسط؟** بسنده أولاً (يُملأ منذ 2026-08-26)، وإلا
  /// بمطابقة السلفة والمبلغ والطريقة — للأقساط التي كُتبت قبل ذلك التاريخ.
  Future<double> _reverseSalaryDeduction(SalaryPayment entry) async {
    final advanceId = entry.cashAdvanceId!;
    final candidates = await db.employeesDao.getRepaymentsByAdvance(advanceId);

    final match = candidates.where((r) =>
        r.method == 'salary_deduction' &&
        (entry.voucherId != null && r.voucherId == entry.voucherId ||
            r.voucherId == null &&
                (r.amount - entry.advanceRepaymentAmount).abs() < 0.001));

    if (match.isEmpty) return 0.0;
    final repayment = match.last;

    final advance = await db.employeesDao.getAdvanceById(advanceId);
    if (advance == null) return 0.0;

    await db.employeesDao.deleteRepayment(repayment.id);

    // الحالة تُشتقّ من الرصيد الجديد لا تُخمَّن: صفرٌ ⇒ لم يُسدَّد شيء بعد
    final newRepaid =
        (advance.totalRepaid - repayment.amount).clamp(0.0, advance.amount);
    await db.employeesDao.updateRepaymentProgress(
      advanceId,
      newRepaid: newRepaid,
      newStatus: newRepaid <= 0.001
          ? 'pending'
          : (newRepaid >= advance.amount - 0.001 ? 'paid' : 'partial'),
    );
    return repayment.amount;
  }

  /// فصل سطر عن سنده — يُعيد `true` إن حُذف السند كلّه
  Future<bool> _detachFromVoucher({
    required int? voucherId,
    required int entryId,
    required double share,
    int? userId,
  }) async {
    if (voucherId == null) return false;

    final voucher = await (select(db.vouchers)
          ..where((v) => v.id.equals(voucherId)))
        .getSingleOrNull();
    if (voucher == null || voucher.isDeleted) return false;

    // هل يغطّي السند سطوراً أخرى ما زالت مسدَّدة؟
    final others = await customSelect(
      'SELECT COUNT(*) AS c FROM salary_payments '
      'WHERE voucher_id = ? AND id != ? AND is_deleted = 0 '
      "  AND payment_status = 'paid'",
      variables: [Variable.withInt(voucherId), Variable.withInt(entryId)],
      readsFrom: {db.salaryPayments},
    ).getSingle();

    if ((others.data['c'] as int? ?? 0) > 0) {
      // 🔑 دفعةٌ جماعية: يُنقَص السند بحصة هذا الموظف **وحدها**.
      //   حذفه كان سيُلغي رواتب من بقي بلا سبب.
      await _shiftVoucherAmount(voucherId, -share);
      return false;
    }

    // آخر سطر فيه ⇒ سندٌ بصفر لا معنى له
    await (update(db.vouchers)..where((v) => v.id.equals(voucherId))).write(
      VouchersCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
        updatedByUserId: Value(userId),
        updatedAt: Value(DateTime.now()),
      ),
    );

    // فكّ ربط سطر سلفة المشروع بهذا السند (نفس علاج ح-٦ في `VouchersDao`)
    // — لا نمرّ بـ`softDeleteVoucher` لأن حارسها يمنع سندات الرواتب.
    if (voucher.advanceId != null) {
      await (update(db.advanceLines)..where((l) => l.voucherId.equals(voucherId)))
          .write(const AdvanceLinesCompanion(voucherId: Value(null)));
    }
    return true;
  }

  /// إزاحة مبلغ سند بمقدار [delta] — الرصيد يتبعه تلقائياً من الـ VIEW
  Future<void> _shiftVoucherAmount(int voucherId, double delta) async {
    final voucher = await (select(db.vouchers)
          ..where((v) => v.id.equals(voucherId)))
        .getSingleOrNull();
    if (voucher == null) return;

    final newAmount = voucher.amount + delta;
    if (newAmount <= 0) {
      throw StateError(
        'تصحيحٌ يجعل مبلغ سند الصرف صفراً أو سالباً — راجع الأرقام.',
      );
    }
    await (update(db.vouchers)..where((v) => v.id.equals(voucherId))).write(
      VouchersCompanion(
        amount: Value(newAmount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// إلحاق سطر بملاحظات موجودة بلا محوها
  static String _appendNote(String existing, String addition) {
    final base = existing.trim();
    return base.isEmpty ? addition : '$base\n$addition';
  }
}
