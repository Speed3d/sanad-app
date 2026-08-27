// ─────────────────────────────────────────────────────────────────────────────
// payroll_dao.dart — كشوف الرواتب الشهرية وسطورها (Schema v7)
//
// 🔑 **العملية الأخطر هنا: [PayrollDao.payEntries]**
//   تُنشئ **سند صرف واحداً بالمجموع** وتُعلّم سطوره مدفوعة وتُسجّل أقساط
//   سلف الموظفين — كلّه في **معاملة واحدة**. فشل جزئي هنا يعني إما مالاً
//   خرج بلا سجلّ يقابله، أو سطوراً معلَّمة مدفوعة بلا سند — وكلاهما يفسد
//   الدفاتر بصمت.
//
// **لماذا سند واحد لا سند لكل موظف؟** (قرار المالك 2026-08-24)
//   السجل التفصيلي لكل موظف محفوظ في **سطر الكشف بلقطته**، فلا حاجة
//   لتكراره في ٣٦٠ سنداً سنوياً. السند يمثّل **حركة المال**، والكشف يمثّل
//   **التفصيل**.
//
// **لماذا لا توجد نماذج domain لهذا النظام؟**
//   الجداول تُعاد كما هي (`PayrollPeriod` · `SalaryPayment` من Drift)، على
//   نمط `AttachmentsDao` المعتمد في Schema v6. إضافة نموذجَي freezed
//   ومسارَي تحويل بينهما لا تشتري شيئاً هنا: لا مصدر بيانات ثانياً
//   يُستبدَل، والاختبارات تستعمل قاعدة حقيقية أصلاً. وكل سطر تحويل إضافي
//   هو موضعٌ يُنسى فيه حقل — وهي **بالضبط** علّة ب-١ (المستودع كان يُسقط
//   أربعة حقول في ثلاثة مواضع).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/employees_table.dart';
import '../tables/payroll_periods_table.dart';
import '../tables/treasuries_table.dart';
import '../tables/vouchers_table.dart';
import '../../../core/services/payroll_calculator.dart';
import '../../../core/services/payroll_print_data.dart';

part 'payroll_dao.g.dart';
part 'payroll_dao_reports.dart';
part 'payroll_dao_reversals.dart';

/// سنة رواتب مشتقّة — لا جدول لها
///
/// السنوات تُشتقّ بـ`GROUP BY year` على الكشوف. تخزين سنةٍ فارغة يفتح باب
/// سنةٍ بلا أشهر تظهر في القائمة بلا محتوى.
class PayrollYearSummary {
  final int year;

  /// عدد الأشهر التي أُنشئ لها كشف
  final int monthCount;

  /// عدد الأشهر المسدَّدة منها
  final int paidMonthCount;

  /// مجموع صافي الرواتب بالدينار في السنة كلها
  final double totalIqd;

  const PayrollYearSummary({
    required this.year,
    required this.monthCount,
    required this.paidMonthCount,
    required this.totalIqd,
  });
}

/// إجماليات كشف واحد — تُقرأ دفعةً واحدة بدل ثلاثة استعلامات
class PayrollPeriodTotals {
  /// عدد السطور الحيّة
  final int entryCount;

  /// عدد السطور المسدَّدة
  final int paidCount;

  /// مجموع الصافي بالدينار (كل السطور)
  final double totalIqd;

  /// مجموع الصافي بالدينار للسطور **غير المسدَّدة** — وهو ما سيخرج من الخزينة
  final double unpaidIqd;

  /// هل في الكشف سطر واحد على الأقل بالدولار؟ — يُلزم سعر صرف الشهر
  final bool hasForeignCurrency;

  const PayrollPeriodTotals({
    required this.entryCount,
    required this.paidCount,
    required this.totalIqd,
    required this.unpaidIqd,
    required this.hasForeignCurrency,
  });

  /// هل سُدِّد الكشف بالكامل؟
  bool get isFullyPaid => entryCount > 0 && paidCount == entryCount;
}

/// موظف سُدِّد راتبه في شهرٍ بعينه — لتنبيه الاستيراد
///
/// 🔑 **سبب وجوده** (طلب المالك 2026-08-26): يصرف راتب موظف مباشرةً من بطاقته
///   عن شهر ٨، ثم يستورد ملف رواتب الشهر نفسه بعد أسبوعين وقد نسي. فيجب أن
///   يُنبَّه **باسم الموظف وتاريخ صرفه ورقم سنده** قبل الاعتماد، لا أن يكتشفه
///   بعد شهور في كشف حساب.
class PaidEmployeeInMonth {
  final int employeeId;

  /// لقطة الاسم كما سُجِّلت لحظة الصرف
  final String employeeName;

  /// وقت الصرف — `null` لسطرٍ قديم لم يُسجَّل وقته
  final DateTime? paidAt;

  /// رقم سند الصرف — `null` إن حُذف السند أو لم يُربَط
  final int? voucherNumber;

  final double netIqd;

  const PaidEmployeeInMonth({
    required this.employeeId,
    required this.employeeName,
    required this.paidAt,
    required this.voucherNumber,
    required this.netIqd,
  });
}

/// ما سيقع لو حُذف كشف — يُعرَض للمالك قبل أن يقرّر
class PayrollDeletionImpact {
  /// سطور **مدفوعة فعلاً** في الكشف — خرج مالها من الخزينة
  final int paidCount;
  final double paidTotalIqd;

  /// سطور مستحقّة لم يخرج مالها بعد
  final int unpaidCount;

  const PayrollDeletionImpact({
    required this.paidCount,
    required this.paidTotalIqd,
    required this.unpaidCount,
  });

  /// هل في الكشف مالٌ خرج فعلاً؟ — عندها لا يجوز حذفٌ صامت
  bool get hasPaid => paidCount > 0;
}

/// سند رواتب لا يقابله سطرٌ حيّ — **مالٌ خرج بلا سجل**
class OrphanPayrollVoucher {
  final int voucherId;
  final int voucherNumber;
  final double amount;
  final DateTime voucherDate;

  /// اسم المستفيد كما كُتب في السند — يُعرَف منه صاحب المال
  final String personName;

  /// بيان السند («رواتب أيلول 2025») — يُعرَف منه الشهر
  final String reason;

  final String treasuryName;

  const OrphanPayrollVoucher({
    required this.voucherId,
    required this.voucherNumber,
    required this.amount,
    required this.voucherDate,
    required this.personName,
    required this.reason,
    required this.treasuryName,
  });
}

/// ما عُكس من رواتب عند إلغاء سلفة (ع-٣٦)
class AdvancePayrollReversal {
  final int employeeCount;
  final double totalIqd;

  /// عدد أقساط سلف الموظفين التي أُعيدت
  final int reversedRepayments;

  /// أشهر الكشوف المتأثّرة — تُذكَر للمالك قبل الإلغاء وبعده
  final List<String> periodLabels;

  const AdvancePayrollReversal({
    required this.employeeCount,
    required this.totalIqd,
    required this.reversedRepayments,
    required this.periodLabels,
  });

  bool get isEmpty => employeeCount == 0;
}

/// حصيلة إلغاء تسديد راتب موظف
class UnpaySalaryResult {
  final int entryId;
  final String employeeName;
  final double amountIqd;

  /// السند الذي كان السطر مربوطاً به
  final int? voucherId;

  /// هل حُذف السند كلّه؟ (كان لهذا الموظف وحده) أم نقص بحصته فقط؟
  final bool voucherDeleted;

  /// قسط سلفة الموظف الذي أُعيد إليه — صفرٌ حين لا خصم في هذا الراتب
  final double reversedRepayment;

  const UnpaySalaryResult({
    required this.entryId,
    required this.employeeName,
    required this.amountIqd,
    required this.voucherId,
    required this.voucherDeleted,
    required this.reversedRepayment,
  });
}

/// حصيلة تسديد دفعة رواتب
class PayPayrollResult {
  /// معرّف سند الصرف الواحد الذي أُنشئ
  final int voucherId;

  /// رقم السند داخل سنته المالية
  final int voucherNumber;

  /// عدد الموظفين الذين سُدِّدت رواتبهم
  final int employeeCount;

  /// إجمالي ما خرج من الخزينة بالدينار
  final double totalIqd;

  /// عدد أقساط سلف الموظفين التي سُجِّلت ضمن هذه الدفعة
  final int repaymentCount;

  /// هل صار الكشف مسدَّداً بالكامل بهذه الدفعة؟
  final bool periodCompleted;

  const PayPayrollResult({
    required this.voucherId,
    required this.voucherNumber,
    required this.employeeCount,
    required this.totalIqd,
    required this.repaymentCount,
    required this.periodCompleted,
  });
}

@DriftAccessor(
  // `Treasuries` للقراءة وحدها — تقرير السنة يعرض اسم الخزينة التي دفعت
  tables: [PayrollPeriods, SalaryPayments, Employees, CashAdvances,
      CashAdvanceRepayments, Vouchers, Treasuries],
)
class PayrollDao extends DatabaseAccessor<AppDatabase>
    with _$PayrollDaoMixin, PayrollReportQueries, PayrollReversals {
  PayrollDao(super.db);

  // ═══════════════════════════════════════════════════════════════════════
  // قراءة الكشوف
  // ═══════════════════════════════════════════════════════════════════════

  /// السنوات المشتقّة من الكشوف — الأحدث أولاً
  Future<List<PayrollYearSummary>> getYears() async {
    final rows = await customSelect(
      'SELECT p.year AS y, '
      '       COUNT(*) AS months, '
      "       SUM(CASE WHEN p.status = 'posted' THEN 1 ELSE 0 END) AS paid, "
      '       COALESCE(('
      '         SELECT SUM(s.net_amount_iqd) FROM salary_payments s '
      '         INNER JOIN payroll_periods pp ON pp.id = s.payroll_period_id '
      '         WHERE pp.year = p.year AND pp.is_deleted = 0 '
      '           AND s.is_deleted = 0'
      '       ), 0) AS total '
      'FROM payroll_periods p '
      'WHERE p.is_deleted = 0 '
      'GROUP BY p.year '
      'ORDER BY p.year DESC',
      readsFrom: {payrollPeriods, salaryPayments},
    ).get();

    return rows
        .map((r) => PayrollYearSummary(
              year: r.data['y'] as int,
              monthCount: r.data['months'] as int? ?? 0,
              paidMonthCount: (r.data['paid'] as int?) ?? 0,
              totalIqd: (r.data['total'] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();
  }

  /// كشوف سنة بعينها — Reactive
  Stream<List<PayrollPeriod>> watchPeriodsForYear(int year) {
    return (select(payrollPeriods)
          ..where((p) => p.year.equals(year) & p.isDeleted.equals(false))
          ..orderBy([(p) => OrderingTerm.asc(p.month)]))
        .watch();
  }

  /// كل الكشوف — الأحدث أولاً
  Stream<List<PayrollPeriod>> watchAllPeriods() {
    return (select(payrollPeriods)
          ..where((p) => p.isDeleted.equals(false))
          ..orderBy([
            (p) => OrderingTerm.desc(p.year),
            (p) => OrderingTerm.desc(p.month),
          ]))
        .watch();
  }

  /// كشف واحد بالمعرّف — Reactive
  Stream<PayrollPeriod?> watchPeriodById(int id) {
    return (select(payrollPeriods)..where((p) => p.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<PayrollPeriod?> getPeriodById(int id) {
    return (select(payrollPeriods)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// كشف شهر بعينه — المفتاح الطبيعي (سنة، شهر)
  Future<PayrollPeriod?> getPeriodForMonth(int year, int month) {
    return (select(payrollPeriods)
          ..where((p) =>
              p.year.equals(year) &
              p.month.equals(month) &
              p.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// البحث عن كشف استُورد فيه ملف بنفس البصمة — كشف الاستيراد المكرّر
  ///
  /// استيراد الملف نفسه مرّتين يضاعف الرواتب بصمت، وهو خطأ وارد جداً في
  /// العمل الشهري. البصمة تكشفه قبل أن يقع.
  Future<PayrollPeriod?> findByFileHash(String hash) {
    if (hash.isEmpty) return Future.value(null);
    return (select(payrollPeriods)
          ..where((p) =>
              p.sourceFileHash.equals(hash) & p.isDeleted.equals(false))
          ..limit(1))
        .getSingleOrNull();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // كتابة الكشوف
  // ═══════════════════════════════════════════════════════════════════════

  Future<int> insertPeriod(PayrollPeriodsCompanion period) {
    return into(payrollPeriods).insert(period);
  }

  /// تحديث جزئي — `write` لا `replace`
  ///
  /// `replace` تُعيد كل حقل غائب إلى قيمته الافتراضية، فتُحيي كشفاً محذوفاً
  /// وتمسح تاريخ اعتماده. راجع ع-١٥.
  Future<void> updatePeriod(int id, PayrollPeriodsCompanion changes) async {
    await (update(payrollPeriods)..where((p) => p.id.equals(id)))
        .write(changes);
  }

  /// ما سيقع لو حُذف هذا الكشف — يُقرأ **قبل** عرض الحوار
  ///
  /// 🔑 **سبب وجوده** (ع-٣٣ — بلاغ المالك 2026-08-26): كان حذف الكشف يحذف
  ///   سطوره **بما فيها المدفوعة**، فتبقى سنداتها حيّة والمال خارج الخزينة
  ///   بلا سجل يقابله. وكان الحوار يقول للمالك حرفياً «لا أثر مالي» — وهو
  ///   **كذبٌ في أخطر لحظة**.
  Future<PayrollDeletionImpact> getDeletionImpact(int periodId) async {
    final row = await customSelect(
      'SELECT '
      "  SUM(CASE WHEN payment_status = 'paid' THEN 1 ELSE 0 END) AS paid, "
      "  SUM(CASE WHEN payment_status = 'paid' "
      '           THEN net_amount_iqd ELSE 0 END) AS paid_total, '
      "  SUM(CASE WHEN payment_status = 'unpaid' THEN 1 ELSE 0 END) AS unpaid "
      'FROM salary_payments '
      'WHERE payroll_period_id = ? AND is_deleted = 0',
      variables: [Variable.withInt(periodId)],
      readsFrom: {salaryPayments},
    ).getSingle();

    return PayrollDeletionImpact(
      paidCount: (row.data['paid'] as int?) ?? 0,
      paidTotalIqd: (row.data['paid_total'] as num?)?.toDouble() ?? 0.0,
      unpaidCount: (row.data['unpaid'] as int?) ?? 0,
    );
  }

  /// حذف ناعم للسطور **غير المسدَّدة وحدها** — يُبقي المدفوع بسنداته
  ///
  /// يُعيد عدد ما حُذف. الكشف يبقى قائماً بسطوره المدفوعة، فلا يتحوّل مالٌ
  /// خرج فعلاً إلى سجلٍّ لا وجود له.
  Future<int> softDeleteUnpaidEntries(int periodId) async {
    final now = DateTime.now();
    return (update(salaryPayments)
          ..where((s) =>
              s.payrollPeriodId.equals(periodId) &
              s.isDeleted.equals(false) &
              s.paymentStatus.equals(PayrollPaymentStatusDb.unpaid)))
        .write(SalaryPaymentsCompanion(
      isDeleted: const Value(true),
      updatedAt: Value(now),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════
  // سندات الرواتب اليتيمة — شبكة الأمان الأخيرة (ع-٣٣)
  // ═══════════════════════════════════════════════════════════════════════

  /// سندات صرف رواتب **لا يقابلها سطرٌ حيّ** — مالٌ خرج بلا سجل
  ///
  /// 🔑 **لماذا أداة دائمة لا إصلاح لمرّة واحدة؟** لأن هذه الحالة وُلدت من
  ///   بابٍ لم نتوقّعه (حذف الكشف)، وأيّ باب آخر لم نتوقّعه بعدُ سيُنتجها
  ///   ثانيةً. الكشفُ عن **العَرَض** يحمي حتى مما لم يُشخَّص سببه.
  ///
  /// 📌 والمقارنة بـ`item_type = 'راتب'`: هو ما يكتبه [payEntries] في كل سند
  ///   رواتب، فلا تلتقط الأداة سندات الصرف العادية.
  Future<List<OrphanPayrollVoucher>> getOrphanPayrollVouchers() async {
    final rows = await customSelect(
      'SELECT v.id AS vid, v.voucher_number AS num, v.amount AS amt, '
      '       v.voucher_date AS vdate, v.person_name AS person, '
      '       v.reason AS reason, t.name AS tname '
      'FROM vouchers v '
      'LEFT JOIN treasuries t ON t.id = v.treasury_id '
      "WHERE v.is_deleted = 0 AND v.voucher_type = 'sarf' "
      "  AND v.item_type = 'راتب' "
      '  AND NOT EXISTS ('
      '    SELECT 1 FROM salary_payments s '
      '    WHERE s.voucher_id = v.id AND s.is_deleted = 0'
      '  ) '
      'ORDER BY v.voucher_date DESC',
      readsFrom: {vouchers, salaryPayments, treasuries},
    ).get();

    return rows
        .map((r) => OrphanPayrollVoucher(
              voucherId: r.read<int>('vid'),
              voucherNumber: r.read<int>('num'),
              amount: (r.data['amt'] as num?)?.toDouble() ?? 0.0,
              voucherDate: r.read<DateTime>('vdate'),
              personName: r.read<String?>('person') ?? '',
              reason: r.read<String?>('reason') ?? '',
              treasuryName: r.read<String?>('tname') ?? '',
            ))
        .toList();
  }

  /// حذف ناعم للكشف **وسطوره معاً**
  ///
  /// الحذف الناعم للرأس وحده يترك سطوراً حيّة تُحتسب في تقارير الرواتب بلا
  /// كشف يظهرها — رقمٌ في تقرير لا مصدر له في أي شاشة.
  Future<void> softDeletePeriod(int id) async {
    await transaction(() async {
      final now = DateTime.now();
      await (update(salaryPayments)
            ..where((s) => s.payrollPeriodId.equals(id)))
          .write(SalaryPaymentsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(now),
      ));
      await (update(payrollPeriods)..where((p) => p.id.equals(id))).write(
        PayrollPeriodsCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(now),
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // سطور الكشف
  // ═══════════════════════════════════════════════════════════════════════

  /// سطور كشف — **بترتيب ملف الإكسل**، Reactive
  ///
  /// ⚠️ **بالمعرّف لا بالاسم** (بلاغ المالك 2026-08-25):
  ///   الترتيب الأبجدي يبعثر الكشف عن ترتيب الملف الذي أرسله المحاسب، فلا
  ///   يستطيع المالك مطابقة سطرٍ بسطر وهو يراجع ورقةً أمامه. والمعرّف
  ///   تصاعديّ بترتيب الإدراج، والإدراج يقع بترتيب صفوف الملف — فهو
  ///   **ترتيب الملف نفسه** بلا عمود إضافي.
  ///
  /// 📌 والاستيراد التراكمي يحفظ المعنى: موظفو ملف البصرة أولاً ثم موظفو
  ///   ملف كربلاء، كلٌّ بترتيبه الداخلي.
  Stream<List<SalaryPayment>> watchEntries(int periodId) {
    return (select(salaryPayments)
          ..where((s) =>
              s.payrollPeriodId.equals(periodId) & s.isDeleted.equals(false))
          ..orderBy([(s) => OrderingTerm.asc(s.id)]))
        .watch();
  }

  Future<List<SalaryPayment>> getEntries(int periodId) {
    return (select(salaryPayments)
          ..where((s) =>
              s.payrollPeriodId.equals(periodId) & s.isDeleted.equals(false))
          ..orderBy([(s) => OrderingTerm.asc(s.id)]))
        .get();
  }

  @override
  Future<SalaryPayment?> getEntryById(int id) {
    return (select(salaryPayments)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  /// سطر موظف بعينه في كشف بعينه — للاستيراد التراكمي
  ///
  /// وجوده يعني أن الموظف **مُدرَج أصلاً** في هذا الشهر، فلا يُضاف ثانيةً.
  Future<SalaryPayment?> getEntryForEmployee({
    required int periodId,
    required int employeeId,
  }) {
    return (select(salaryPayments)
          ..where((s) =>
              s.payrollPeriodId.equals(periodId) &
              s.employeeId.equals(employeeId) &
              s.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<int> insertEntry(SalaryPaymentsCompanion entry) {
    return into(salaryPayments).insert(entry);
  }

  @override
  Future<void> updateEntry(int id, SalaryPaymentsCompanion changes) async {
    await (update(salaryPayments)..where((s) => s.id.equals(id))).write(
      changes.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  /// حذف ناعم لسطر — لإخراج موظف من كشف الشهر
  Future<void> softDeleteEntry(int id) async {
    await (update(salaryPayments)..where((s) => s.id.equals(id))).write(
      SalaryPaymentsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // الإجماليات
  // ═══════════════════════════════════════════════════════════════════════

  /// إجماليات كشف — استعلام واحد بدل أربعة
  ///
  /// 🔑 **هذه هي القاعدة الوحيدة لمجموع الكشف.** كل شاشة وتقرير وطباعة
  ///   تسأل هنا. توزيع الجمع على المستدعين هو **حرفياً** ما ضرب مشروع DMS:
  ///   كان مكرَّراً في ثمانية مواضع، فأُضيف مخرَجٌ تاسع نسي القاعدة
  ///   واحتُسب راتب لم يُدفع.
  Future<PayrollPeriodTotals> getTotals(int periodId) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS cnt, '
      "       SUM(CASE WHEN payment_status = 'paid' THEN 1 ELSE 0 END) AS paid, "
      '       COALESCE(SUM(net_amount_iqd), 0) AS total, '
      '       COALESCE(SUM(CASE WHEN payment_status = \'unpaid\' '
      '                    THEN net_amount_iqd ELSE 0 END), 0) AS unpaid, '
      "       SUM(CASE WHEN snapshot_currency = 'USD' THEN 1 ELSE 0 END) AS usd "
      'FROM salary_payments '
      'WHERE payroll_period_id = ? AND is_deleted = 0',
      variables: [Variable.withInt(periodId)],
      readsFrom: {salaryPayments},
    ).getSingle();

    return PayrollPeriodTotals(
      entryCount: row.data['cnt'] as int? ?? 0,
      paidCount: (row.data['paid'] as int?) ?? 0,
      totalIqd: (row.data['total'] as num?)?.toDouble() ?? 0.0,
      unpaidIqd: (row.data['unpaid'] as num?)?.toDouble() ?? 0.0,
      hasForeignCurrency: ((row.data['usd'] as int?) ?? 0) > 0,
    );
  }

  /// مجموع صافي سطور بعينها بالدينار — أساس مطابقة سطر السلفة (المرحلة ٣)
  Future<double> getTotalIqdForEntries(List<int> entryIds) async {
    if (entryIds.isEmpty) return 0.0;
    final rows = await (select(salaryPayments)
          ..where((s) => s.id.isIn(entryIds) & s.isDeleted.equals(false)))
        .get();
    return rows.fold<double>(0, (sum, e) => sum + e.netAmountIqd);
  }

  /// موظفو شهرٍ الذين **سُدِّدت** رواتبهم فعلاً — بالسنة والشهر لا بمعرّف كشف
  ///
  /// ⚠️ **بالسنة والشهر عمداً:** معالج الاستيراد يسأل قبل أن يُنشئ الكشف —
  ///   في خطوة المراجعة، حين يكون القرار ما زال ممكناً. السؤال بمعرّف كشفٍ
  ///   لم يوجد بعد لا جواب له.
  Future<List<PaidEmployeeInMonth>> getPaidEmployeesForMonth(
    int year,
    int month,
  ) async {
    final rows = await customSelect(
      'SELECT s.employee_id AS eid, s.snapshot_name AS nm, '
      '       s.paid_at AS pa, s.net_amount_iqd AS net, '
      '       v.voucher_number AS vn '
      'FROM salary_payments s '
      'INNER JOIN payroll_periods p ON p.id = s.payroll_period_id '
      'LEFT JOIN vouchers v ON v.id = s.voucher_id '
      'WHERE p.year = ? AND p.month = ? AND p.is_deleted = 0 '
      "  AND s.is_deleted = 0 AND s.payment_status = 'paid'",
      variables: [Variable.withInt(year), Variable.withInt(month)],
      readsFrom: {payrollPeriods, salaryPayments, vouchers},
    ).get();

    return rows
        .map((r) => PaidEmployeeInMonth(
              employeeId: r.read<int>('eid'),
              employeeName: r.read<String?>('nm') ?? '',
              paidAt: r.read<DateTime?>('pa'),
              voucherNumber: r.read<int?>('vn'),
              netIqd: (r.data['net'] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // تقرير السنة (المرحلة ٤)
  // ═══════════════════════════════════════════════════════════════════════

  /// أشهر سنة بإجمالياتها — استعلام واحد لكل الأشهر
  ///
  /// 🔑 **يجمع العمود نفسه الذي تجمعه [getTotals]** (`net_amount_iqd`)
  ///   وبالشروط نفسها (`is_deleted = 0`)، فلا يمكن أن يختلف مجموع التقرير عن
  ///   مجموع شاشة الكشف. ويحرس التطابقَ اختبارٌ يقارن الرقمين على بيانات
  ///   مزروعة (`payroll_report_test`) — لأن «استعلامان يُفترَض أنهما
  ///   متطابقان» هو بالضبط ما انفرط في المشروع المرجعي DMS.
  ///
  /// `LEFT JOIN` مقصود: الكشف الفارغ يظهر بصفر لا يختفي — «شهرٌ أُنشئ ولم
  /// يُستورَد بعد» معلومة، واختفاؤه يوحي بأنه لم يُنشأ أصلاً.
  Future<List<PayrollYearMonth>> getYearMonths(int year) async {
    final rows = await customSelect(
      'SELECT p.id AS pid, p.month AS m, p.status AS st, '
      '       COUNT(s.id) AS cnt, '
      '       COALESCE(SUM(s.net_amount_iqd), 0) AS total, '
      "       COALESCE(SUM(CASE WHEN s.payment_status = 'paid' "
      '                    THEN s.net_amount_iqd ELSE 0 END), 0) AS paid '
      'FROM payroll_periods p '
      'LEFT JOIN salary_payments s '
      '       ON s.payroll_period_id = p.id AND s.is_deleted = 0 '
      'WHERE p.year = ? AND p.is_deleted = 0 '
      'GROUP BY p.id '
      'ORDER BY p.month',
      variables: [Variable.withInt(year)],
      readsFrom: {payrollPeriods, salaryPayments},
    ).get();

    return rows.map((r) {
      final total = (r.data['total'] as num?)?.toDouble() ?? 0.0;
      final paid = (r.data['paid'] as num?)?.toDouble() ?? 0.0;
      return PayrollYearMonth(
        month: r.data['m'] as int,
        periodId: r.data['pid'] as int,
        employeeCount: r.data['cnt'] as int? ?? 0,
        totalIqd: total,
        paidIqd: paid,
        // المتبقّي يُشتقّ ولا يُجمع ثانيةً: عمودان مجموعان مستقلّان قد
        // يختلفان بفاصلة عائمة فيظهر «متبقٍّ» في كشف مسدَّد بالكامل.
        unpaidIqd: total - paid,
        isPosted: (r.data['st'] as String?) == PayrollStatusDb.posted,
      );
    }).toList();
  }

  /// توزيع رواتب السنة **المسدَّدة** على الخزائن التي دفعتها
  ///
  /// ⚠️ **المسدَّد وحده وبخزينة الدفع لا بمشروع الموظف:**
  ///   السطر غير المسدَّد لم يخرج من أي خزينة، ونسبتُه إلى واحدة اختراعُ
  ///   حركةِ مالٍ لم تقع. ورابط الموظف بمشروعه (`employees.treasury_id`)
  ///   قابل للتغيير غداً، فالبناء عليه يُعيد كتابة تاريخٍ مضى.
  ///
  /// الخزينة الفارغة (`treasury_id IS NULL`) تظهر «غير محدَّدة»: رواتب
  /// أقدم من v7 دُفعت قبل وجود هذا العمود. إخفاؤها يُنقص المجموع بصمت.
  Future<List<PayrollTreasuryShare>> getYearTreasuryShares(int year) async {
    final rows = await customSelect(
      'SELECT s.treasury_id AS tid, t.name AS tname, '
      '       COUNT(s.id) AS cnt, '
      '       COALESCE(SUM(s.net_amount_iqd), 0) AS total '
      'FROM salary_payments s '
      'INNER JOIN payroll_periods p ON p.id = s.payroll_period_id '
      'LEFT JOIN treasuries t ON t.id = s.treasury_id '
      'WHERE p.year = ? AND p.is_deleted = 0 AND s.is_deleted = 0 '
      "  AND s.payment_status = 'paid' "
      'GROUP BY s.treasury_id '
      'ORDER BY total DESC',
      variables: [Variable.withInt(year)],
      readsFrom: {payrollPeriods, salaryPayments, treasuries},
    ).get();

    return rows
        .map((r) => PayrollTreasuryShare(
              treasuryId: r.data['tid'] as int? ?? 0,
              treasuryName:
                  (r.data['tname'] as String?) ?? 'خزينة غير محدَّدة',
              employeeCount: r.data['cnt'] as int? ?? 0,
              totalIqd: (r.data['total'] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();
  }

  /// رواتب صُرفت في السنة **خارج أي كشف** — عددها ومجموعها
  ///
  /// 🔑 **لماذا يسأل التقرير عنها أصلاً؟**
  ///   لأن مسار «صرف راتب» من بطاقة الموظف يكتب سطراً بلا كشف، فلو اقتصر
  ///   التقرير على الكشوف لأخفى مالاً خرج فعلاً — وهو الصنف نفسه من العطل
  ///   الذي ضرب DMS (راتبٌ لم يُحتسب). التقرير يعرضها في شريط منفصل: لا
  ///   تُجمَع مع الكشوف ولا تُخفى.
  ///
  /// السنة هنا **سنة تاريخ الصرف** لا سنة كشف — إذ لا كشف لها.
  ///
  /// ⚠️ **مدى تواريخ لا `strftime`:** Drift تخزّن التاريخ عدداً صحيحاً
  ///   (ثواني يونكس) لا نصّاً، فـ`strftime('%Y', payment_date)` تقرأ العدد
  ///   على أنه يوم يولياني وتُعيد سنة لا علاقة لها بشيء — بصمت وبلا خطأ.
  ///   والمدى المحلّي يحلّ معه فرق التوقيت: `DateTime(year, 1, 1)` تُحوَّل
  ///   بتوقيت بغداد لا بـUTC، فلا يقع راتب أول كانون الثاني في السنة السابقة.
  Future<({int count, double totalIqd})> getOutOfSheetSalaries(int year) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS cnt, COALESCE(SUM(net_amount_iqd), 0) AS total '
      'FROM salary_payments '
      'WHERE payroll_period_id IS NULL AND is_deleted = 0 '
      '  AND payment_date >= ? AND payment_date < ?',
      variables: [
        Variable.withDateTime(DateTime(year, 1, 1)),
        Variable.withDateTime(DateTime(year + 1, 1, 1)),
      ],
      readsFrom: {salaryPayments},
    ).getSingle();

    return (
      count: row.data['cnt'] as int? ?? 0,
      totalIqd: (row.data['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🔑 التسديد — اللحظة الوحيدة التي تتأثر فيها الخزينة
  // ═══════════════════════════════════════════════════════════════════════

  /// حصيلة إلغاء تسديد راتب
  ///
  /// تُعيد ما وقع فعلاً ليُسجَّل في سجل التدقيق ويُعرَض للمالك — إلغاءٌ صامت
  /// لا يقول ماذا لمس أسوأ من عدمه.
  Future<UnpaySalaryResult> unpayEntry({
    required int entryId,
    required String reason,
    int? userId,
  }) async {
    return transaction(() async {
      final entry = await getEntryById(entryId);
      if (entry == null) throw StateError('سطر الراتب غير موجود.');
      if (entry.paymentStatus != PayrollPaymentStatusDb.paid) {
        throw StateError(
          'راتب «${entry.snapshotName}» غير مسدَّد أصلاً — لا شيء يُلغى.',
        );
      }

      // ── 1. عكس قسط سلفة الموظف ───────────────────────────────────────
      //
      // ⚠️ **قبل كل شيء آخر**: الخصم وقع في الصافي المصروف، فإلغاء التسديد
      //   بلا عكسه يترك السلفة منقوصة بمبلغٍ لم يُدفَع — وهو مالٌ يختفي من
      //   الجهة الأخرى بصمت. (نفس منطق «لا تخطٍّ صامت» في `payEntries`.)
      var reversedRepayment = 0.0;
      if (entry.advanceRepaymentAmount > 0 && entry.cashAdvanceId != null) {
        reversedRepayment = await _reverseSalaryDeduction(entry);
      }

      // ── 2. السند: يُحذف إن كان لهذا الموظف وحده، وإلا يُنقَص بحصته ────
      final voucherDeleted = await _detachFromVoucher(
        voucherId: entry.voucherId,
        entryId: entryId,
        share: entry.netAmountIqd,
        userId: userId,
      );

      // ── 3. السطر يعود مستحقّاً ───────────────────────────────────────
      await (update(salaryPayments)..where((s) => s.id.equals(entryId)))
          .write(SalaryPaymentsCompanion(
        paymentStatus: const Value(PayrollPaymentStatusDb.unpaid),
        paidAt: const Value(null),
        voucherId: const Value(null),
        treasuryId: const Value(null),
        advanceId: const Value(null),
        advanceLineId: const Value(null),
        notes: Value(PayrollReversals._appendNote(entry.notes, 'أُلغي التسديد: $reason')),
        updatedAt: Value(DateTime.now()),
      ));

      // ── 4. الكشف يتبع سطوره ──────────────────────────────────────────
      // صار فيه سطر مستحقّ ⇒ ليس مُسدَّداً. و`posted_at` **يبقى** شاهداً
      // على اعتماده الأول — محوُه يمحو تاريخاً وقع فعلاً.
      final periodId = entry.payrollPeriodId;
      if (periodId != null) {
        await (update(payrollPeriods)..where((p) => p.id.equals(periodId)))
            .write(const PayrollPeriodsCompanion(
          status: Value(PayrollStatusDb.draft),
        ));
      }

      return UnpaySalaryResult(
        entryId: entryId,
        employeeName: entry.snapshotName,
        amountIqd: entry.netAmountIqd,
        voucherId: entry.voucherId,
        voucherDeleted: voucherDeleted,
        reversedRepayment: reversedRepayment,
      );
    });
  }

  /// تسديد دفعة رواتب بسند صرف **واحد بالمجموع**
  ///
  /// ⚠️ لا يُجري هذا التابع أي فحص للصلاحيات أو الرصيد أو الفترة المالية —
  ///   تلك مسؤولية `PayrollRepository` الذي يستدعيه. الفصل مقصود: الـ DAO
  ///   يضمن **الذرّية**، والمستودع يضمن **قواعد العمل**. (نمط `postAdvance`.)
  ///
  /// [entryIds]     — السطور الداخلة في هذه الدفعة (غير المسدَّدة)
  /// [treasuryId]   — الخزينة التي يخرج منها المال
  /// [advanceId] / [advanceLineId] — يُملآن حين يقع التسديد عبر سلفة مشروع
  ///
  /// **الترتيب داخل المعاملة:**
  ///   رقم السند ← السند ← تحديث السطور ← أقساط سلف الموظفين ← حالة الكشف
  Future<PayPayrollResult> payEntries({
    required int periodId,
    required List<int> entryIds,
    required int treasuryId,
    required int fiscalPeriodId,
    required DateTime paymentDate,
    required String periodLabel,
    int? paidByUserId,
    int? advanceId,
    int? advanceLineId,
    String? advanceNumber,
    String? projectName,
    /// اسم المستفيد في السند — يُمرَّر حين تكون الدفعة **لموظف واحد**، فيصير
    /// السند باسمه بدل «١ موظفاً». ودفعةُ الكشف تتركه فيُذكَر العدد.
    String? personNameOverride,
  }) async {
    return transaction(() async {
      final entries = await (select(salaryPayments)
            ..where((s) =>
                s.id.isIn(entryIds) &
                s.isDeleted.equals(false) &
                s.paymentStatus.equals(PayrollPaymentStatusDb.unpaid)))
          .get();

      if (entries.isEmpty) {
        throw StateError(
          'لا توجد سطور قابلة للتسديد في هذه الدفعة — '
          'قد تكون سُدِّدت بالفعل.',
        );
      }

      final total = entries.fold<double>(0, (s, e) => s + e.netAmountIqd);

      // اسم الخزينة حين تكون مشروعاً — لفلتر «المشروع» في شاشة السندات
      final treasury = await db.treasuriesDao.getTreasuryById(treasuryId);
      final projectTreasuryName =
          treasury?.kind == 'project' ? treasury?.name : null;

      // ── 1. رقم السند — ذرّي عبر UPSERT في voucher_sequences ──────────
      final voucherNumber = await db.fiscalPeriodsDao.getNextVoucherNumber(
        fiscalPeriodId: fiscalPeriodId,
        voucherType: 'sarf',
      );

      // ── 2. سند الصرف الواحد بالمجموع ─────────────────────────────────
      // البيان يذكر الشهر وعدد الموظفين: سندٌ بمليون دينار بلا بيان يجعل
      // مراجعة الدفاتر بعد سنة تخميناً.
      final voucherId = await into(vouchers).insert(
        VouchersCompanion.insert(
          voucherNumber: voucherNumber,
          voucherType: 'sarf',
          treasuryId: treasuryId,
          fiscalPeriodId: fiscalPeriodId,
          amount: total,
          currency: const Value('IQD'),
          exchangeRate: const Value(1.0),
          voucherDate: paymentDate,
          personName: Value(
              personNameOverride ?? '${entries.length} موظفاً'),
          reason: Value('رواتب $periodLabel'),
          itemType: const Value('راتب'),
          // 🔑 **اسم المشروع يُملأ من الخزينة حين تكون مشروعاً**
          //   (بلاغ المالك 2026-08-26): فلتر «المشروع» في شاشة السندات يقرأ
          //   هذا الحقل النصّي لا الخزينة، فكان سند رواتب البصرة لا يظهر
          //   عند اختيار «البصرة» — والمالك يراهما شيئاً واحداً بحقّ.
          projectName: Value(projectName ?? projectTreasuryName),
          advanceNumber: Value(advanceNumber),
          advanceId: Value(advanceId),
          createdByUserId: Value(paidByUserId),
        ),
      );

      // ── 3. تعليم السطور مدفوعة وربطها بسندها ─────────────────────────
      final now = DateTime.now();
      for (final e in entries) {
        await (update(salaryPayments)..where((s) => s.id.equals(e.id))).write(
          SalaryPaymentsCompanion(
            paymentStatus: const Value(PayrollPaymentStatusDb.paid),
            paidAt: Value(now),
            paymentDate: Value(paymentDate),
            treasuryId: Value(treasuryId),
            voucherId: Value(voucherId),
            advanceId: Value(advanceId),
            advanceLineId: Value(advanceLineId),
            updatedAt: Value(now),
          ),
        );
      }

      // ── 4. أقساط سلف الموظفين المخصومة من هذه الرواتب ────────────────
      final repayments = await recordSalaryDeductions(
        entries: entries,
        paymentDate: paymentDate,
        voucherId: voucherId,
        periodLabel: periodLabel,
      );

      // ── 5. هل اكتمل الكشف؟ ───────────────────────────────────────────
      // يُقرأ بعد التحديث لا قبله — الكشف الشامل يُسدَّد على دفعات، فلا
      // يصير `posted` إلا حين لا يبقى فيه سطر غير مسدَّد.
      final remaining = await customSelect(
        'SELECT COUNT(*) AS c FROM salary_payments '
        "WHERE payroll_period_id = ? AND is_deleted = 0 "
        "AND payment_status = 'unpaid'",
        variables: [Variable.withInt(periodId)],
        readsFrom: {salaryPayments},
      ).getSingle();
      final completed = (remaining.data['c'] as int? ?? 0) == 0;

      if (completed) {
        // ⚠️ **لا يُدهَس تاريخ الاعتماد الأصلي.**
        //   كشفٌ مُسدَّد يُضاف إليه موظف متأخّر (قرار المالك 2026-08-26)
        //   يعود «مكتملاً» في نهاية هذه المعاملة — ولو كتبنا `posted_at`
        //   من جديد لضاع تاريخ اعتماده الحقيقي وبدا كأنه اعتُمد اليوم.
        //   الإضافة المتأخرة يوثّقها سجل التدقيق و`created_at` للسطر.
        final current = await (select(payrollPeriods)
              ..where((p) => p.id.equals(periodId)))
            .getSingleOrNull();
        final wasAlreadyPosted = current?.status == PayrollStatusDb.posted;

        await (update(payrollPeriods)..where((p) => p.id.equals(periodId)))
            .write(PayrollPeriodsCompanion(
          status: const Value(PayrollStatusDb.posted),
          postedAt: wasAlreadyPosted ? const Value.absent() : Value(now),
          postedByUserId: wasAlreadyPosted
              ? const Value.absent()
              : Value(paidByUserId),
        ));
      }

      return PayPayrollResult(
        voucherId: voucherId,
        voucherNumber: voucherNumber,
        employeeCount: entries.length,
        totalIqd: total,
        repaymentCount: repayments,
        periodCompleted: completed,
      );
    });
  }
}
