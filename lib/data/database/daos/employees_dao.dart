// ─────────────────────────────────────────────────────────────────────────────
// employees_dao.dart — DAO الموظفين والسلف والرواتب
//
// يُدير هذا الـ DAO أربعة كيانات متشابكة:
//   1. Employees          — بيانات الموظفين الأساسية
//   2. CashAdvances       — السلف الممنوحة (للموظفين والخارجيين)
//   3. CashAdvanceRepayments — أقساط سداد السلف
//   4. SalaryPayments     — مدفوعات الرواتب الشهرية
//
// آلية السلف (Cash Advances):
//   كل سلفة تُنشئ سند صرف (Voucher) من الخزينة.
//   كل قسط سداد يُنشئ سند قبض (Voucher).
//   `totalRepaid` يُحدَّث تلقائياً بعد كل سداد.
//   عند totalRepaid >= amount → يتحوّل status إلى 'paid'.
//
// آلية الرواتب:
//   netAmount = basicSalary + additions - deductions
//   كل دفعة راتب تُنشئ سند صرف تلقائياً من الخزينة.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/employees_table.dart';

part 'employees_dao.g.dart';

// ── نموذج ملخص سلفة الموظف ────────────────────────────────────────────────

/// ملخص حالة سلفة: المبلغ الأصلي، المسدَّد، والمتبقي
class CashAdvanceSummary {
  /// معرّف السلفة
  final int advanceId;

  /// المبلغ الأصلي للسلفة
  final double originalAmount;

  /// إجمالي ما تم سداده حتى الآن
  final double totalRepaid;

  /// المبلغ المتبقي (originalAmount - totalRepaid)
  final double remainingAmount;

  /// حالة السلفة: pending | partial | paid | written_off
  final String status;

  const CashAdvanceSummary({
    required this.advanceId,
    required this.originalAmount,
    required this.totalRepaid,
    required this.remainingAmount,
    required this.status,
  });
}

/// DAO الموظفين والسلف والرواتب
@DriftAccessor(tables: [Employees, CashAdvances, CashAdvanceRepayments, SalaryPayments])
class EmployeesDao extends DatabaseAccessor<AppDatabase>
    with _$EmployeesDaoMixin {
  EmployeesDao(super.db);

  // ══════════════════════════════════════════════════════════════════════════
  // قسم 1: الموظفون (Employees)
  // ══════════════════════════════════════════════════════════════════════════

  /// جميع الموظفين النشطين — Reactive Stream مرتب أبجدياً
  ///
  /// يتحدث تلقائياً عند أي إضافة أو تعديل أو حذف
  Stream<List<Employee>> watchAllEmployees() {
    return (select(employees)
          ..where((e) => e.isDeleted.equals(false))
          ..orderBy([(e) => OrderingTerm.asc(e.fullName)]))
        .watch();
  }

  /// جميع الموظفين النشطين (Future — للقراءة لمرة واحدة)
  Future<List<Employee>> getAllEmployees() {
    return (select(employees)
          ..where((e) => e.isDeleted.equals(false))
          ..orderBy([(e) => OrderingTerm.asc(e.fullName)]))
        .get();
  }

  /// موظف واحد بالمعرّف
  Future<Employee?> getEmployeeById(int id) {
    return (select(employees)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  /// بحث نصي في أسماء الموظفين وأرقام هواتفهم
  Future<List<Employee>> searchEmployees(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(employees)
          ..where(
            (e) =>
                e.isDeleted.equals(false) &
                (e.fullName.lower().like(q) | e.phone.lower().like(q)),
          )
          ..orderBy([(e) => OrderingTerm.asc(e.fullName)])
          ..limit(50))
        .get();
  }

  /// الموظفون المرتبطون بخزينة محددة
  ///
  /// يُستخدَم عند حذف خزينة للتحقق من عدم وجود موظفين مرتبطين
  Future<List<Employee>> getEmployeesByTreasury(int treasuryId) {
    return (select(employees)
          ..where(
            (e) =>
                e.treasuryId.equals(treasuryId) & e.isDeleted.equals(false),
          ))
        .get();
  }

  /// إضافة موظف جديد — يُعيد الـ ID المُولَّد
  Future<int> insertEmployee(EmployeesCompanion employee) {
    return into(employees).insert(employee);
  }

  /// تحديث بيانات موظف — تحديث جزئي للحقول الحاضرة فقط
  ///
  /// write بدل replace: يمنع إعادة is_active/is_deleted/created_at إلى قيمها
  /// الافتراضية (تعديل موظف معطَّل كان يُعيد تفعيله). راجع تدقيق 2026-08-06.
  Future<bool> updateEmployee(EmployeesCompanion employee) async {
    final count = await (update(employees)
          ..where((e) => e.id.equals(employee.id.value)))
        .write(employee);
    return count > 0;
  }

  /// حذف ناعم للموظف — لا يُحذَف فعلياً لحفظ سجل الرواتب والسلف
  Future<void> softDeleteEmployee(int id) async {
    await (update(employees)..where((e) => e.id.equals(id))).write(
      const EmployeesCompanion(
        isDeleted: Value(true),
        isActive: Value(false),
      ),
    );
  }

  /// تفعيل / تعطيل موظف
  Future<void> setEmployeeActive(int id, {required bool isActive}) async {
    await (update(employees)..where((e) => e.id.equals(id))).write(
      EmployeesCompanion(isActive: Value(isActive)),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // قسم 2: السلف (Cash Advances)
  // ══════════════════════════════════════════════════════════════════════════

  /// سلف موظف معين — Reactive Stream
  ///
  /// مرتبة من الأحدث للأقدم
  Stream<List<CashAdvance>> watchAdvancesByEmployee(int employeeId) {
    return (select(cashAdvances)
          ..where(
            (a) =>
                a.employeeId.equals(employeeId) & a.isDeleted.equals(false),
          )
          ..orderBy([(a) => OrderingTerm.desc(a.advanceDate)]))
        .watch();
  }

  /// جميع السلف غير المسدَّدة بالكامل — للتقارير والمتابعة
  ///
  /// تشمل: pending + partial فقط
  Future<List<CashAdvance>> getPendingAdvances() {
    return (select(cashAdvances)
          ..where(
            (a) =>
                a.isDeleted.equals(false) &
                (a.status.equals('pending') | a.status.equals('partial')),
          )
          ..orderBy([(a) => OrderingTerm.asc(a.advanceDate)]))
        .get();
  }

  /// سلفة واحدة بالمعرّف
  Future<CashAdvance?> getAdvanceById(int id) {
    return (select(cashAdvances)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  /// ملخص حالة السلفة: المبلغ الأصلي والمسدَّد والمتبقي
  Future<CashAdvanceSummary?> getAdvanceSummary(int advanceId) async {
    final advance = await getAdvanceById(advanceId);
    if (advance == null) return null;

    final remaining = advance.amount - advance.totalRepaid;
    return CashAdvanceSummary(
      advanceId: advance.id,
      originalAmount: advance.amount,
      totalRepaid: advance.totalRepaid,
      remainingAmount: remaining < 0 ? 0 : remaining,
      status: advance.status,
    );
  }

  /// إجمالي السلف المستحقة لموظف معين (بالدينار)
  Future<double> getTotalPendingAdvancesForEmployee(int employeeId) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount - total_repaid), 0) as total '
      'FROM cash_advances '
      "WHERE employee_id = ? AND status IN ('pending','partial') "
      'AND is_deleted = 0',
      variables: [Variable.withInt(employeeId)],
      readsFrom: {cashAdvances},
    ).getSingle();
    return (result.data['total'] as num).toDouble();
  }

  /// تسجيل سلفة جديدة — يُعيد الـ ID المُولَّد
  Future<int> insertAdvance(CashAdvancesCompanion advance) {
    return into(cashAdvances).insert(advance);
  }

  /// تحديث بيانات السلفة (مثلاً: تحديث `totalRepaid` و`status`)
  ///
  /// write بدل replace: يمنع إعادة is_deleted/created_at إلى قيمها الافتراضية.
  Future<bool> updateAdvance(CashAdvancesCompanion advance) async {
    final count = await (update(cashAdvances)
          ..where((a) => a.id.equals(advance.id.value)))
        .write(advance);
    return count > 0;
  }

  /// تحديث إجمالي المسدَّد وحالة السلفة بعد كل قسط
  ///
  /// [advanceId]   — معرّف السلفة
  /// [newRepaid]   — المجموع الجديد للمبلغ المسدَّد
  /// [newStatus]   — الحالة الجديدة بعد الحساب
  Future<void> updateRepaymentProgress(
    int advanceId, {
    required double newRepaid,
    required String newStatus,
  }) async {
    await (update(cashAdvances)..where((a) => a.id.equals(advanceId))).write(
      CashAdvancesCompanion(
        totalRepaid: Value(newRepaid),
        status: Value(newStatus),
      ),
    );
  }

  /// حذف ناعم للسلفة
  Future<void> softDeleteAdvance(int id) async {
    await (update(cashAdvances)..where((a) => a.id.equals(id))).write(
      const CashAdvancesCompanion(isDeleted: Value(true)),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // قسم 3: أقساط سداد السلف (Cash Advance Repayments)
  // ══════════════════════════════════════════════════════════════════════════

  /// أقساط سداد سلفة معينة — مرتبة من الأقدم للأحدث
  Future<List<CashAdvanceRepayment>> getRepaymentsByAdvance(int advanceId) {
    return (select(cashAdvanceRepayments)
          ..where((r) => r.cashAdvanceId.equals(advanceId))
          ..orderBy([(r) => OrderingTerm.asc(r.repaymentDate)]))
        .get();
  }

  /// Reactive Stream لأقساط سلفة معينة
  Stream<List<CashAdvanceRepayment>> watchRepaymentsByAdvance(int advanceId) {
    return (select(cashAdvanceRepayments)
          ..where((r) => r.cashAdvanceId.equals(advanceId))
          ..orderBy([(r) => OrderingTerm.asc(r.repaymentDate)]))
        .watch();
  }

  /// تسجيل قسط سداد جديد والتحديث الذري لحالة السلفة
  ///
  /// يُنفَّذ في Transaction واحدة:
  ///   1. إدراج قسط السداد
  ///   2. تحديث `totalRepaid` و`status` في السلفة
  ///
  /// يُعيد: معرّف القسط المُدرَج
  Future<int> insertRepayment({
    required CashAdvanceRepaymentsCompanion repayment,
    required int advanceId,
    required double newTotalRepaid,
    required String newStatus,
  }) async {
    return db.transaction(() async {
      // إدراج القسط
      final repaymentId = await into(cashAdvanceRepayments).insert(repayment);

      // تحديث حالة السلفة مباشرةً في نفس الـ Transaction
      await updateRepaymentProgress(
        advanceId,
        newRepaid: newTotalRepaid,
        newStatus: newStatus,
      );

      return repaymentId;
    });
  }

  /// حذف قسط سداد (للتصحيح — Super Admin فقط)
  Future<void> deleteRepayment(int id) async {
    await (delete(cashAdvanceRepayments)..where((r) => r.id.equals(id))).go();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // قسم 4: الرواتب (Salary Payments)
  // ══════════════════════════════════════════════════════════════════════════

  /// رواتب موظف معين — Reactive Stream مرتب من الأحدث للأقدم
  Stream<List<SalaryPayment>> watchSalariesByEmployee(int employeeId) {
    return (select(salaryPayments)
          ..where(
            (s) =>
                s.employeeId.equals(employeeId) & s.isDeleted.equals(false),
          )
          ..orderBy([(s) => OrderingTerm.desc(s.paymentDate)]))
        .watch();
  }

  /// رواتب ضمن فترة زمنية — للتقارير الشهرية
  Future<List<SalaryPayment>> getSalariesByDateRange({
    required DateTime from,
    required DateTime to,
    int? employeeId,
  }) {
    return (select(salaryPayments)
          ..where((s) {
            // الشرط الأساسي: نطاق التاريخ وليس محذوفاً
            Expression<bool> condition =
                s.paymentDate.isBetweenValues(from, to) &
                    s.isDeleted.equals(false);

            // فلتر موظف محدد (اختياري)
            if (employeeId != null) {
              condition = condition & s.employeeId.equals(employeeId);
            }
            return condition;
          })
          ..orderBy([(s) => OrderingTerm.asc(s.paymentDate)]))
        .get();
  }

  /// إجمالي الرواتب المدفوعة لموظف في سنة معينة
  Future<double> getTotalSalariesForEmployee(
    int employeeId,
    int year,
  ) async {
    final from = DateTime(year, 1, 1);
    final to = DateTime(year, 12, 31, 23, 59, 59);

    final result = await customSelect(
      'SELECT COALESCE(SUM(net_amount), 0) as total '
      'FROM salary_payments '
      'WHERE employee_id = ? AND payment_date BETWEEN ? AND ? '
      'AND is_deleted = 0',
      variables: [
        Variable.withInt(employeeId),
        Variable.withDateTime(from),
        Variable.withDateTime(to),
      ],
      readsFrom: {salaryPayments},
    ).getSingle();

    return (result.data['total'] as num).toDouble();
  }

  /// تسجيل دفعة راتب جديدة — يُعيد الـ ID المُولَّد
  Future<int> insertSalaryPayment(SalaryPaymentsCompanion payment) {
    return into(salaryPayments).insert(payment);
  }

  /// تحديث بيانات دفعة راتب (للتصحيح قبل الإقفال المالي)
  ///
  /// write بدل replace: يمنع إعادة is_deleted/created_at إلى قيمها الافتراضية.
  Future<bool> updateSalaryPayment(SalaryPaymentsCompanion payment) async {
    final count = await (update(salaryPayments)
          ..where((s) => s.id.equals(payment.id.value)))
        .write(payment);
    return count > 0;
  }

  /// حذف ناعم لدفعة راتب
  Future<void> softDeleteSalaryPayment(int id) async {
    await (update(salaryPayments)..where((s) => s.id.equals(id))).write(
      const SalaryPaymentsCompanion(isDeleted: Value(true)),
    );
  }

  /// ربط دفعة راتب بسند صرف (بعد إنشاء السند في الخزينة)
  ///
  /// [paymentId] — معرّف الدفعة
  /// [voucherId] — معرّف السند المُنشَأ
  Future<void> linkSalaryPaymentToVoucher(
    int paymentId,
    int voucherId,
  ) async {
    await (update(salaryPayments)..where((s) => s.id.equals(paymentId))).write(
      SalaryPaymentsCompanion(voucherId: Value(voucherId)),
    );
  }
}
