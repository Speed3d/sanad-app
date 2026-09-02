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
import '../../../core/constants/employee_status.dart';
import '../../../core/services/payroll_calculator.dart';
import '../app_database.dart';
import '../tables/departments_table.dart';
import '../tables/employee_leaves_table.dart';
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
/// قسط سداد سلفة موظف مع مصدره — لعرض «كيف سُدّدت»
///
/// [periodYear]/[periodMonth] تُملأ للأقساط المخصومة من الراتب وحدها.
typedef AdvanceRepaymentDetail = ({
  int id,
  double amount,
  DateTime date,
  String method,
  int? voucherId,
  int? voucherNumber,
  int? periodYear,
  int? periodMonth,
  String notes,
});

@DriftAccessor(
    tables: [Departments, Employees, EmployeeLeaves, CashAdvances, CashAdvanceRepayments, SalaryPayments])
class EmployeesDao extends DatabaseAccessor<AppDatabase>
    with _$EmployeesDaoMixin {
  EmployeesDao(super.db);

  // ══════════════════════════════════════════════════════════════════════════
  // قسم 1: الموظفون (Employees)
  // ══════════════════════════════════════════════════════════════════════════

  /// جميع الموظفين النشطين — **بترتيب الإضافة** لا أبجدياً
  ///
  /// ⚠️ **لماذا بالمعرّف لا بالاسم؟** (بلاغ المالك 2026-08-25)
  ///   الموظفون يُنشَؤون دفعةً واحدة من ملف رواتب الشهر، بترتيب صفوف الملف
  ///   الذي كتبه المحاسب. والترتيب الأبجدي يبعثرهم عن ذلك الترتيب، فيتعذّر
  ///   على المالك مطابقة القائمة بالورقة التي أمامه.
  ///   والمعرّف تصاعديّ بترتيب الإدراج، فهو **ترتيب الملف نفسه** بلا عمود
  ///   إضافي ولا تغيير في المخطط.
  ///
  /// 📌 والبحث في الشاشة يغطّي حاجة «أين فلان؟» التي كان الترتيب الأبجدي
  ///   يخدمها. ولو احتاج المالك ترتيباً يدوياً لاحقاً فيلزمه عمود ترتيب
  ///   صريح — وهو تغيير مخطط يحتاج قراره (القانون ٦).
  ///
  /// 🔄 **وصار الترتيب يدوياً في Schema v8** (بلاغ المالك 2026-08-30):
  ///   القسم أولاً بترتيبه، ثم الموظف بترتيبه **داخل قسمه**، ثم الاسم لفضّ
  ///   التعادل. ومن بلا قسم يقع في الآخر لا في الأول — فقائمةٌ تبدأ بمن لم
  ///   يُصنَّف بعدُ تُخفي البنية التي أنشأها المالك.
  ///
  ///   وقاعدةٌ لم يُرتَّب فيها شيء تُعرَض كما كانت: `sort_order` صفرٌ للجميع
  ///   فيفضّ التعادلَ الاسمُ.
  Stream<List<Employee>> watchAllEmployees() {
    return _orderedEmployees().watch().map(_readEmployees);
  }

  /// جميع الموظفين النشطين (Future — للقراءة لمرة واحدة)
  ///
  /// بالترتيب نفسه لنظيرتها التفاعلية — راجع [watchAllEmployees].
  Future<List<Employee>> getAllEmployees() {
    return _orderedEmployees().get().then(_readEmployees);
  }

  /// استعلام الموظفين مرتَّباً — **نقطة الترتيب الوحيدة**
  ///
  /// ⚠️ نسختان من الترتيب (تفاعلية وفورية) تفترقان بأول تعديل يمسّ إحداهما،
  ///   فتُعرَض القائمة بترتيبين مختلفين في شاشتين (نمط ع-٣٧).
  JoinedSelectStatement<HasResultSet, dynamic> _orderedEmployees() {
    return select(employees).join([
      leftOuterJoin(
          departments, departments.id.equalsExp(employees.departmentId)),
    ])
      ..where(employees.isDeleted.equals(false))
      ..orderBy([
        // بلا قسم في الآخر: `false` = 0 تسبق `true` = 1 في SQLite
        OrderingTerm.asc(departments.sortOrder.isNull()),
        OrderingTerm.asc(departments.sortOrder),
        OrderingTerm.asc(employees.sortOrder),
        // ⚠️ **المعرّف لا الاسم** يفضّ التعادل الأخير — وهذا ليس تفصيلاً:
        //   الترتيب الأبجدي كان مرفوضاً صراحةً (بلاغ المالك 2026-08-25)،
        //   لأن الموظفين يُنشَؤون بترتيب ملف المحاسب والمالك يطابق القائمة
        //   بالورقة التي أمامه. وفضُّ التعادل بالاسم كان **يُعيد الترتيب
        //   الأبجدي من الباب الخلفي** لقاعدةٍ لم يُرتَّب فيها شيء بعد.
        //   كشفه `payroll_posting_test` لحظة التغيير.
        OrderingTerm.asc(employees.id),
      ]);
  }

  List<Employee> _readEmployees(List<TypedResult> rows) =>
      rows.map((r) => r.readTable(employees)).toList();

  /// موظف واحد بالمعرّف
  Future<Employee?> getEmployeeById(int id) {
    return (select(employees)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  /// بحث نصي في أسماء الموظفين وأرقام هواتفهم
    /// الموظفون المرتبطون بخزينة محددة
  ///
  /// يُستخدَم عند حذف خزينة للتحقق من عدم وجود موظفين مرتبطين
  /// نقل موظفي خزينة إلى أخرى — أو تجريدهم من الخزينة بـ`null`
  ///
  /// 🔑 **سبب وجوده** (ع-٣٤ — بلاغ المالك 2026-08-26): حُذفت خزينة «البصرة»
  ///   وبقي ٤٦ موظفاً منسوبين إليها. لم يشتكِ النظام، لكن كل ما يعتمد على
  ///   «مشروع الموظف» صار يقرأ خزينةً لا وجود لها — ومنه تقرير الموظف
  ///   بالمشروع.
  ///
  /// يُعيد عدد من نُقلوا.
  Future<int> reassignTreasury({
    required int fromTreasuryId,
    int? toTreasuryId,
  }) {
    return (update(employees)
          ..where((e) =>
              e.treasuryId.equals(fromTreasuryId) & e.isDeleted.equals(false)))
        .write(EmployeesCompanion(treasuryId: Value(toTreasuryId)));
  }

  /// عدد الموظفين الأحياء المنسوبين إلى خزينة — لتنبيه الحذف
  Future<int> countEmployeesInTreasury(int treasuryId) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM employees '
      'WHERE treasury_id = ? AND is_deleted = 0',
      variables: [Variable.withInt(treasuryId)],
      readsFrom: {employees},
    ).getSingle();
    return row.data['c'] as int? ?? 0;
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
  /// **أثر الموظف المالي** — ما يمنع حذفه
  ///
  /// 🔑 بلاغ المالك 2026-08-30: «زرّ حذف الموظفين بالكامل، مع التحقّق بعدم
  ///   قبول الحذف إذا كان الموظف لديه سلفة لم تُسدَّد أو استلم راتباً سابقاً
  ///   — في هذه الحالة لا يُحذف بل **يُعطَّل** حتى لا يظهر في الرواتب».
  ///
  /// ⚠️ **لماذا الراتب المستلَم يمنع الحذف؟** لأن سطر الراتب يحمل **لقطة**
  ///   الموظف لحظة الشهر (الاسم · الصفة · الأساسي)، لكن التقارير تربطه
  ///   بـ`employee_id`. وحذف الموظف — ولو ناعماً — يجعل تقرير الموظف وتقرير
  ///   السنة يقرآن سطوراً لصاحبٍ لا وجود له.
  ///
  ///   والسلفة غير المسدَّدة أوضح: دَينٌ على الشركة لا يُمحى بحذف صاحبه.
  Future<({int unpaidAdvances, double advanceBalance, int salaryRows})>
      getEmployeeFinancialFootprint(int id) async {
    final adv = await customSelect(
      'SELECT COUNT(*) AS c, COALESCE(SUM(amount - total_repaid), 0) AS bal '
      'FROM cash_advances '
      "WHERE employee_id = ? AND is_deleted = 0 AND status != 'paid' "
      'AND (amount - total_repaid) > 0.001',
      variables: [Variable.withInt(id)],
      readsFrom: {cashAdvances},
    ).getSingle();

    final sal = await customSelect(
      'SELECT COUNT(*) AS c FROM salary_payments '
      'WHERE employee_id = ? AND is_deleted = 0',
      variables: [Variable.withInt(id)],
      readsFrom: {salaryPayments},
    ).getSingle();

    return (
      unpaidAdvances: adv.data['c'] as int? ?? 0,
      advanceBalance: (adv.data['bal'] as num?)?.toDouble() ?? 0,
      salaryRows: sal.data['c'] as int? ?? 0,
    );
  }

  /// حذف موظف **بعد التحقّق من خلوّه من أي أثر مالي**
  ///
  /// يرمي [StateError] برسالة عربية تسمّي المانع وتقترح البديل (التعطيل).
  /// والحارس هنا لا في الحوار: حوارٌ تتجاوزه أي شاشة أخرى ليس حارساً
  /// (القانون ٤).
  Future<void> deleteEmployeeGuarded(int id) async {
    final f = await getEmployeeFinancialFootprint(id);

    if (f.unpaidAdvances > 0) {
      throw StateError(
        'لا يمكن حذف هذا الموظف — عليه ${f.unpaidAdvances} سلفة غير مسدَّدة '
        'بمتبقٍّ ${f.advanceBalance.toStringAsFixed(0)}.\n'
        'سدّد السلفة أو ألغِها أولاً، أو **عطّل** الموظف بدل حذفه فلا يظهر '
        'في كشوف الرواتب.',
      );
    }

    if (f.salaryRows > 0) {
      throw StateError(
        'لا يمكن حذف هذا الموظف — له ${f.salaryRows} سطر راتب في كشوف سابقة، '
        'وحذفه يجعل التقارير تقرأ رواتب لصاحبٍ لا وجود له.\n'
        '**عطّله** بدل ذلك: يبقى سجلّه وتقاريره، ولا يظهر في كشوف الرواتب '
        'الجديدة.',
      );
    }

    await softDeleteEmployee(id);
  }

  Future<void> softDeleteEmployee(int id) async {
    await (update(employees)..where((e) => e.id.equals(id))).write(
      const EmployeesCompanion(
        isDeleted: Value(true),
        status: Value(EmployeeStatus.terminated),
      ),
    );
  }

  /// تغيير حالة الموظف — حالي · منتهية خدمته · في إجازة (Schema v8)
  ///
  /// ⚠️ **حلّت محلّ `setEmployeeActive`** ولم تُضَف بجوارها: مبدّلٌ ثنائي
  ///   وحقلُ حالةٍ ثلاثيّ على المعنى نفسه يفترقان بأول كتابة تنسى أحدهما.
  ///
  /// والقيمة تُفحَص **هنا** لا في الشاشة: قيمةٌ رابعة تجعل الموظف يختفي من
  /// كل شريحة فلترة بصمت، ورسالةُ قيد القاعدة إنجليزية لا يفهمها المالك.
  Future<void> setEmployeeStatus(int id, String status) async {
    if (!EmployeeStatus.all.contains(status)) {
      throw StateError('حالة موظف غير معروفة: $status');
    }
    await (update(employees)..where((e) => e.id.equals(id))).write(
      EmployeesCompanion(status: Value(status)),
    );
  }

  // ── الأقسام (Schema v8) ───────────────────────────────────────────────────

  /// أقسام الموظفين مرتَّبة — Reactive Stream
  Stream<List<Department>> watchDepartments() {
    return (_departmentsQuery()).watch();
  }

  /// أقسام الموظفين مرتَّبة (قراءة فورية)
  Future<List<Department>> getDepartments() => _departmentsQuery().get();

  SimpleSelectStatement<$DepartmentsTable, Department> _departmentsQuery() {
    return select(departments)
      ..where((d) => d.isDeleted.equals(false))
      ..orderBy([
        (d) => OrderingTerm.asc(d.sortOrder),
        (d) => OrderingTerm.asc(d.name),
      ]);
  }

  /// إنشاء قسم — يقع **آخر** القائمة، ويرمي [StateError] عند تكرار الاسم
  ///
  /// ⚠️ **الفحص هنا لا في الحوار** (القانون ٤): الفهرس الجزئي في القاعدة
  ///   يمنع التكرار فعلاً، لكنه يرمي رسالة SQLite إنجليزية لا يفهمها
  ///   المالك — والحارس يترجمها قبل أن تصل.
  Future<int> insertDepartment(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) {
      throw StateError('اسم القسم لا يكون فارغاً.');
    }

    final existing = await (select(departments)
          ..where((d) => d.isDeleted.equals(false) & d.name.equals(clean)))
        .getSingleOrNull();
    if (existing != null) {
      throw StateError('القسم «$clean» موجود أصلاً.');
    }

    final last = await (select(departments)
          ..orderBy([(d) => OrderingTerm.desc(d.sortOrder)])
          ..limit(1))
        .getSingleOrNull();

    return into(departments).insert(DepartmentsCompanion.insert(
      name: clean,
      sortOrder: Value((last?.sortOrder ?? 0) + 1),
    ));
  }

  /// إعادة تسمية قسم — بالحارس نفسه
  Future<void> renameDepartment(int id, String name) async {
    final clean = name.trim();
    if (clean.isEmpty) {
      throw StateError('اسم القسم لا يكون فارغاً.');
    }
    final clash = await (select(departments)
          ..where((d) =>
              d.isDeleted.equals(false) &
              d.name.equals(clean) &
              d.id.equals(id).not()))
        .getSingleOrNull();
    if (clash != null) {
      throw StateError('القسم «$clean» موجود أصلاً.');
    }
    await (update(departments)..where((d) => d.id.equals(id)))
        .write(DepartmentsCompanion(name: Value(clean)));
  }

  /// حذف قسم — **ويُفكّ ربط موظفيه صراحةً**. يُعيد عدد من نُقل
  ///
  /// ⚠️ تركُهم يشيرون إلى قسمٍ محذوف يجعلهم «بلا قسم» في العرض بينما
  ///   القاعدة تقول غير ذلك، وإن أُعيد إنشاء قسمٍ بالاسم نفسه لم يعودوا
  ///   إليه. كلتا الحالتين انتماءٌ شبحيّ لا يراه أحد.
  Future<int> deleteDepartment(int id) async {
    final moved = await (update(employees)
          ..where((e) => e.departmentId.equals(id)))
        .write(const EmployeesCompanion(departmentId: Value(null)));
    await (update(departments)..where((d) => d.id.equals(id)))
        .write(const DepartmentsCompanion(isDeleted: Value(true)));
    return moved;
  }

  /// إعادة ترتيب الأقسام — بترتيب [idsInOrder] حرفياً
  Future<void> reorderDepartments(List<int> idsInOrder) async {
    await batch((b) {
      for (var i = 0; i < idsInOrder.length; i++) {
        b.update(
          departments,
          DepartmentsCompanion(sortOrder: Value(i)),
          where: ($DepartmentsTable d) => d.id.equals(idsInOrder[i]),
        );
      }
    });
  }

  /// نقل موظف إلى قسم (أو إلى «بلا قسم» بـ`null`) — يقع آخر القسم الجديد
  Future<void> assignDepartment(int employeeId, int? departmentId) async {
    final last = await (select(employees)
          ..where((e) =>
              e.isDeleted.equals(false) &
              (departmentId == null
                  ? e.departmentId.isNull()
                  : e.departmentId.equals(departmentId)))
          ..orderBy([(e) => OrderingTerm.desc(e.sortOrder)])
          ..limit(1))
        .getSingleOrNull();

    await (update(employees)..where((e) => e.id.equals(employeeId))).write(
      EmployeesCompanion(
        departmentId: Value(departmentId),
        sortOrder: Value((last?.sortOrder ?? 0) + 1),
      ),
    );
  }

  /// إعادة ترتيب موظفين — بترتيب [idsInOrder] حرفياً
  ///
  /// المستدعي يمرّر موظفي **قسمٍ واحد**: الترتيب يعيش داخل القسم، وخلطُ
  /// قسمين في نداء واحد يجعل أرقام الترتيب تتصادم بلا معنى.
  Future<void> reorderEmployees(List<int> idsInOrder) async {
    await batch((b) {
      for (var i = 0; i < idsInOrder.length; i++) {
        b.update(
          employees,
          EmployeesCompanion(sortOrder: Value(i)),
          where: ($EmployeesTable e) => e.id.equals(idsInOrder[i]),
        );
      }
    });
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

  /// إلغاء سلفة موظف كاملةً — **السلفة وأقساطها وسندها معاً** (ع-٣٨)
  ///
  /// 🔑 **سبب وجوده** (طلب المالك 2026-08-27): «ممكن أن يُعيد الموظف السلفة
  ///   بنفس اليوم فتُلغى ويرجع كل شيء إلى ما كان عليه».
  ///
  /// ⚠️ **ولماذا معاملة واحدة؟** لأن السلفة تعيش في **ثلاثة أماكن**: سجلّها
  ///   · أقساطها · وسند منحها (وسندات أقساطها النقدية). إلغاءٌ يلمس بعضها
  ///   يترك الباقي يُحرّك الرصيد بلا مقابل — وهو العطل نفسه الذي تكرّر خمس
  ///   مرّات في هذا المشروع (ع-٢٨ · ع-٣١ · ع-٣٣ · ع-٣٦ · ع-٣٨).
  Future<void> cancelEmployeeAdvance({
    required int advanceId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw StateError(
        'اكتب سبب إلغاء السلفة — إلغاءٌ يُرجع مالاً بلا سبب مكتوب لا '
        'يُميَّز عن تلاعب حين يُراجَع بعد شهور.',
      );
    }

    // ⚠️ **حارسٌ قبل أي كتابة** (قرار المالك 2026-08-27): سلفةٌ خُصم منها
    //   في راتبٍ **مسدَّد** صارت جزءاً من عملية مالية مكتملة — إلغاؤها
    //   يعني أن الموظف خُصم منه بلا سلفة، فيستحقّ الفرق.
    //
    //   والمسار المشروع قائم: `PayrollDao.unpayEntry` يعكس القسط تلقائياً.
    //   فالمنع هنا **بمسارٍ بديل محروس** لا منعٌ يُهجّر الخطر (درس ع-٣٢).
    final salaryDeductions = (await getRepaymentsByAdvance(advanceId))
        .where((r) => r.method == 'salary_deduction')
        .toList();
    if (salaryDeductions.isNotEmpty) {
      final total =
          salaryDeductions.fold<double>(0, (sum, r) => sum + r.amount);
      final months = <String>{};
      for (final r in salaryDeductions) {
        final entry = await (select(db.salaryPayments)
              ..where((sp) =>
                  sp.voucherId.equals(r.voucherId ?? -1) &
                  sp.cashAdvanceId.equals(advanceId) &
                  sp.isDeleted.equals(false)))
            .getSingleOrNull();
        if (entry != null && entry.periodLabel.isNotEmpty) {
          months.add(entry.periodLabel);
        }
      }

      throw StateError(
        'خُصم من هذه السلفة ${total.round()} '
        '${months.isEmpty ? 'في راتبٍ مسدَّد' : 'في راتب ${months.join(' و')} المسدَّد'}.\n'
        'ألغِ تسديد راتب الموظف من كشف الشهر أولاً — يُعاد القسط تلقائياً — '
        'ثم ألغِ السلفة.',
      );
    }

    await transaction(() async {
      final advance = await getAdvanceById(advanceId);
      if (advance == null || advance.isDeleted) return;

      final now = DateTime.now();

      // ── 1. الأقساط ──────────────────────────────────────────────────
      //
      // 🔴 **ع-٤٠ — العطل الذي وقع هنا (2026-08-27):** كانت الحلقة تحذف
      //   سندَ **كل** قسط له `voucher_id`، بناءً على تعليقٍ كتبتُه يقول إن
      //   قسط `salary_deduction` «بلا سند». **وذلك التعليق كان كاذباً**:
      //   العمود يُملأ منذ المرحلة ٦ بـ**سند رواتب الشهر** ليمكن عكس القسط
      //   بدقّة عند إلغاء التسديد.
      //
      //   فحُذف سند رواتب الشهر كلّه — يغطّي كل الموظفين — بسبب إلغاء سلفة
      //   موظفٍ واحد. رجع مال الجميع إلى الخزينة وبقيت سطورهم «مسدَّدة».
      //
      // 🔑 **والفلترة الآن بالطريقة لا بوجود `voucher_id`:**
      //   | الطريقة | ما يعنيه `voucher_id` |
      //   |---|---|
      //   | `cash` · `bank_transfer` | سند **قبضٍ خاصّ بهذا القسط** ⇒ يُحذف معه |
      //   | `salary_deduction` | سند **رواتب الشهر** يغطّي عشرات الموظفين ⇒ **لا يُمَسّ** |
      //
      //   عمودٌ واحد بمعنيين مختلفين حسب حقلٍ آخر — وهذا ما يجب أن يُقرأ
      //   صراحةً لا أن يُفترَض.
      final repayments = await getRepaymentsByAdvance(advanceId);
      for (final r in repayments) {
        if (r.method != 'salary_deduction' && r.voucherId != null) {
          await (update(db.vouchers)..where((v) => v.id.equals(r.voucherId!)))
              .write(VouchersCompanion(
            isDeleted: const Value(true),
            deletedAt: Value(now),
            updatedAt: Value(now),
          ));
        }
        await deleteRepayment(r.id);
      }

      // ── 2. سند المنح ────────────────────────────────────────────────
      if (advance.voucherId != null) {
        await (update(db.vouchers)
              ..where((v) => v.id.equals(advance.voucherId!)))
            .write(VouchersCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(now),
          updatedAt: Value(now),
        ));
      }

      // ── 3. السلفة نفسها ─────────────────────────────────────────────
      await (update(cashAdvances)..where((a) => a.id.equals(advanceId)))
          .write(CashAdvancesCompanion(
        isDeleted: const Value(true),
        totalRepaid: const Value(0),
        // 📌 الحالة تبقى كما هي: الحذف الناعم هو ما يُخرجها من كل استعلام،
        //   و`CHECK` الجدول لا يعرف قيمة «ملغاة». والسبب يُحفظ في `reason`.
        reason: Value('أُلغيت: ${reason.trim()}'),
      ));
    });
  }

  /// تعليم سلفة بأنها ستُخصم من الراتب — **بلا سند ولا قسط** (ع-٣٩)
  ///
  /// 🔴 **العطل الذي وُلدت منه:** كان تسديد السلفة بطريقة «خصم من الراتب»
  ///   يُنشئ **سند قبض** كأي تسديد نقدي — والمال **لم يدخل الخزينة**، بل
  ///   سيخرج راتبٌ أقلّ في نهاية الشهر. فيتضخّم الرصيد برقم وهمي، ثم يُخصم
  ///   من الراتب فعلاً فيُحتسب القسط **مرّتين**.
  ///
  /// 📌 **ولماذا لا تُسجّل قسطاً أيضاً؟** لأن القسط يُسجَّل تلقائياً لحظة
  ///   تسديد الراتب (`PayrollDao.recordSalaryDeductions`). تسجيلُه هنا هو
  ///   الاحتساب المزدوج بعينه.
  ///
  /// كل ما تفعله: تُثبِت النيّة في ملاحظات السلفة ليقرأها من يفتحها لاحقاً.
  /// والتنبيه في كشف الرواتب يُشتقّ من **وجود سلفة غير مسدَّدة** لا من علامة.
  Future<void> markForSalaryDeduction({
    required int advanceId,
    String note = 'سيُخصم من الراتب',
  }) async {
    final advance = await getAdvanceById(advanceId);
    if (advance == null || advance.isDeleted) return;

    final existing = advance.reason.trim();
    await (update(cashAdvances)..where((a) => a.id.equals(advanceId))).write(
      CashAdvancesCompanion(
        reason: Value(existing.isEmpty ? note : '$existing — $note'),
      ),
    );
  }

  /// المتبقّي من سلف كل موظف — **باستعلام واحد** لا واحدٍ لكل موظف
  ///
  /// 🔑 معالج الاستيراد يعرض سبعة وأربعين موظفاً؛ استعلامٌ لكل واحد يعني
  ///   سبعة وأربعين رحلةً إلى القاعدة في كل فتح للخطوة. والخريطة الراجعة
  ///   **لا تحوي مفتاحاً لمن لا سلفة عليه** — فالغياب نفسه جواب.
  Future<Map<int, double>> getPendingAdvancesForEmployees(
    List<int> employeeIds,
  ) async {
    if (employeeIds.isEmpty) return {};

    final rows = await customSelect(
      'SELECT employee_id AS eid, '
      '       SUM(amount - total_repaid) AS remaining '
      'FROM cash_advances '
      'WHERE is_deleted = 0 AND employee_id IN ('
      '${List.filled(employeeIds.length, '?').join(',')}) '
      "  AND status IN ('pending', 'partial') "
      'GROUP BY employee_id '
      'HAVING remaining > 0.001',
      variables: [for (final id in employeeIds) Variable.withInt(id)],
      readsFrom: {cashAdvances},
    ).get();

    return {
      for (final r in rows)
        r.read<int>('eid'): (r.data['remaining'] as num?)?.toDouble() ?? 0.0,
    };
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

  /// **تفاصيل تسديد سلفة** — كل قسط بمصدره الحقيقي
  ///
  /// 🔑 **البلاغ (المالك 2026-08-30):** «سلفة مليون سُدّدت على دفعتين: ٥٠٠
  ///   ألف نقداً و٥٠٠ ألف خصماً من الراتب. أريد عند الضغط عليها أن أرى
  ///   **كيف** سُدّدت — بأي سند وبرواتب أي شهر.»
  ///
  ///   والبيانات كانت كلها موجودة في `cash_advance_repayments` منذ البداية
  ///   (المبلغ · التاريخ · الطريقة · السند) — **ينقص العرض فقط**.
  ///
  /// ⚠️ **لماذا استعلامات فرعية لا `LEFT JOIN`؟** سطر الراتب قد يتعدّد على
  ///   السند الواحد (سند رواتب الشهر مشترك بين كل موظفيه)، فالضمّ يُكرّر
  ///   القسط مرّاتٍ بعدد سطور الكشف. والاستعلام الفرعي بـ`LIMIT 1` يُعيد
  ///   صفّاً واحداً لكل قسط مهما كثر ما حوله.
  ///
  /// `periodYear`/`periodMonth` تُملأ للأقساط المخصومة من الراتب وحدها —
  /// وهي التي يريد المالك أن يعرف شهرها.
  Future<List<AdvanceRepaymentDetail>> getRepaymentDetails(
    int advanceId,
  ) async {
    final rows = await customSelect(
      '''
      SELECT
        r.id              AS id,
        r.amount          AS amount,
        r.repayment_date  AS repayment_date,
        r.method          AS method,
        r.voucher_id      AS voucher_id,
        r.notes           AS notes,
        (SELECT v.voucher_number FROM vouchers v
          WHERE v.id = r.voucher_id)                        AS voucher_number,
        (SELECT pp.year FROM salary_payments sp
           JOIN payroll_periods pp ON pp.id = sp.payroll_period_id
          WHERE sp.cash_advance_id = r.cash_advance_id
            AND sp.voucher_id = r.voucher_id
            AND sp.is_deleted = 0
          LIMIT 1)                                          AS period_year,
        (SELECT pp.month FROM salary_payments sp
           JOIN payroll_periods pp ON pp.id = sp.payroll_period_id
          WHERE sp.cash_advance_id = r.cash_advance_id
            AND sp.voucher_id = r.voucher_id
            AND sp.is_deleted = 0
          LIMIT 1)                                          AS period_month
      FROM cash_advance_repayments r
      WHERE r.cash_advance_id = ?
      ORDER BY r.repayment_date ASC, r.id ASC
      ''',
      variables: [Variable.withInt(advanceId)],
      readsFrom: {
        cashAdvanceRepayments,
        salaryPayments,
        db.vouchers,
        db.payrollPeriods,
      },
    ).get();

    return [
      for (final r in rows)
        (
          id: r.data['id'] as int,
          amount: (r.data['amount'] as num).toDouble(),
          // ⚠️ `r.read<DateTime>` لا التحويل اليدوي: Drift قد يخزّن التاريخ
          //   نصّاً ISO أو ثوانيَ يونكس حسب الإعداد، والتحويل اليدوي يفترض
          //   أحدهما فينكسر على الآخر.
          date: r.read<DateTime>('repayment_date'),
          method: r.data['method'] as String? ?? 'cash',
          voucherId: r.data['voucher_id'] as int?,
          voucherNumber: r.data['voucher_number'] as int?,
          periodYear: r.data['period_year'] as int?,
          periodMonth: r.data['period_month'] as int?,
          notes: r.data['notes'] as String? ?? '',
        ),
    ];
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
  ///
  /// 🔑 **حارسان قبل أي كتابة** (المرحلة ٤ — 2026-08-26):
  ///
  ///   ١. **لا راتب بلا مقابله بالدينار.** `net_amount_iqd` هو العمود الذي
  ///      تجمعه كل التقارير؛ صفرٌ فيه مع صافٍ غير صفري يعني راتباً يختفي من
  ///      كل تقرير بينما المال خرج من الخزينة فعلاً.
  ///
  ///   ٢. **لقطة العملة تطابق عملة راتب الموظف.** مسار «صرف راتب» من بطاقة
  ///      الموظف يُنشئ سند صرف **بالدينار حصراً**، فلو مرّ به موظفٌ راتبه
  ///      بالدولار لصُرف رقمُه الدولاري ديناراً — أي كسرٌ صامت لقيمة الراتب.
  ///      الرفض هنا يوجّهه إلى كشف الرواتب حيث سعر الصرف مثبَّت على الشهر.
  ///
  /// **ولماذا في الـ DAO لا في الشاشة؟** لأن هذا المسار يعيش في `Notifier`
  /// بلا مستودع، وحارسٌ في الواجهة لا يمرّ به اختبار ولا يحمي مستدعياً
  /// جديداً (القانون ٤).
  Future<int> insertSalaryPayment(SalaryPaymentsCompanion payment) async {
    final employeeId = payment.employeeId.present ? payment.employeeId.value : 0;
    final snapshotName = payment.snapshotName.present
        ? payment.snapshotName.value.trim()
        : '';

    final employee = await getEmployeeById(employeeId);
    final displayName = snapshotName.isNotEmpty
        ? snapshotName
        : (employee?.fullName ?? 'موظف #$employeeId');

    PayrollCalculator.ensureIqdRecorded(
      employeeName: displayName,
      netSalary: payment.netAmount.present ? payment.netAmount.value : 0,
      netSalaryIqd:
          payment.netAmountIqd.present ? payment.netAmountIqd.value : 0,
    );

    final rowCurrency = payment.snapshotCurrency.present
        ? payment.snapshotCurrency.value
        : PayrollCurrency.iqd;
    if (employee != null && employee.salaryCurrency != rowCurrency) {
      throw StateError(
        'راتب «$displayName» بعملة ${employee.salaryCurrency} '
        'ويُسجَّل هنا بعملة $rowCurrency.\n'
        'اصرفه من كشف الرواتب حيث يُثبَّت سعر صرف الشهر — '
        'فالصرف المباشر من بطاقة الموظف يفترض الدينار.',
      );
    }

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

  // ══════════════════════════════════════════════════════════════════════
  // الإجازات وإنهاء الخدمة (Schema v9 — طلب المالك 2026-09-02)
  // ══════════════════════════════════════════════════════════════════════

  /// إجازات موظف — الأحدث أولاً
  Stream<List<EmployeeLeave>> watchLeaves(int employeeId) {
    return (select(employeeLeaves)
          ..where((l) =>
              l.employeeId.equals(employeeId) & l.isDeleted.equals(false))
          ..orderBy([(l) => OrderingTerm.desc(l.fromDate)]))
        .watch();
  }

  /// تسجيل إجازة — يُعيد معرّفها
  Future<int> insertLeave(EmployeeLeavesCompanion leave) =>
      into(employeeLeaves).insert(leave);

  /// حذف ناعم لإجازة
  ///
  /// ناعمٌ لا صلب (القانون ٨): الإجازة **غيّرت راتباً مضى**، وبقاء أثرها
  /// هو ما يفسّر الفرق بين كشفٍ طُبع أمس وكشفٍ يُطبع اليوم.
  Future<void> softDeleteLeave(int id) async {
    await (update(employeeLeaves)..where((l) => l.id.equals(id)))
        .write(const EmployeeLeavesCompanion(isDeleted: Value(true)));
  }

  /// أيام الإجازة **بلا راتب** لموظف داخل شهرٍ بعينه
  ///
  /// ═══ لماذا يُحسب التقاطع هنا لا يُخزَّن رقماً؟ ═══
  ///   لأن الإجازة **واقعة بمدىً**، وعددُ أيامها في شهرٍ ما نتيجةٌ تُشتقّ.
  ///   إجازةٌ من ٢٨ تموز إلى ٥ آب هي أربعة أيام في تموز وخمسة في آب —
  ///   ورقمٌ مخزَّن «٩ أيام» لا يعرف أيّهما، فيُحمَّل كلّه على شهر.
  ///
  ///   وهو المبدأ الحاكم للمشروع كلّه: **الأرصدة لا تُخزَّن، تُحسَب من
  ///   الواقعة.** الإجازة هنا كالسند هناك.
  ///
  /// ⚠️ **والحساب على أيام الشهر التقويمي ثم يُقصّ بأيام العمل**: موظفٌ في
  ///   شهرٍ من ٣١ يوماً وأيام عمله ٣٠ لا يجوز أن تُنقِص إجازتُه ٣١ يوماً
  ///   فيصير استحقاقه سالباً.
  Future<int> unpaidLeaveDaysInMonth({
    required int employeeId,
    required int year,
    required int month,
    required int workingDays,
  }) async {
    final firstOfMonth = DateTime(year, month, 1);
    final lastOfMonth =
        DateTime(year, month, PayrollCalculator.daysInMonth(year, month));

    final rows = await (select(employeeLeaves)
          ..where((l) =>
              l.employeeId.equals(employeeId) &
              l.isDeleted.equals(false) &
              l.kind.equals(LeaveKind.unpaid) &
              l.fromDate.isSmallerOrEqualValue(lastOfMonth) &
              l.toDate.isBiggerOrEqualValue(firstOfMonth)))
        .get();

    var days = 0;
    for (final l in rows) {
      final from = l.fromDate.isBefore(firstOfMonth) ? firstOfMonth : l.fromDate;
      final to = l.toDate.isAfter(lastOfMonth) ? lastOfMonth : l.toDate;
      // الطرفان **شاملان** — قرار المالك نفسه في إنهاء الخدمة (٤→٢٤ = ٢١)
      days += to.difference(DateTime(from.year, from.month, from.day)).inDays + 1;
    }
    return days > workingDays ? workingDays : days;
  }

  /// إنهاء خدمة موظف — التاريخ والسند والملاحظات والحالة في كتابة واحدة
  ///
  /// ⚠️ **الحالة والتاريخ يُكتَبان معاً دائماً**: `status = terminated` بلا
  ///   تاريخ تجعل الراتب يُحسب شهراً كاملاً لمن خرج في اليوم الخامس، و
  ///   تاريخٌ بلا حالة يجعله يظهر في فلتر «الحاليون». عمودان لمعنىً واحد
  ///   يفترقان بأول كتابة تنسى أحدهما — نمط ع-٤٠.
  Future<void> terminateEmployee({
    required int employeeId,
    required DateTime terminationDate,
    String reference = '',
    String notes = '',
  }) async {
    await (update(employees)..where((e) => e.id.equals(employeeId))).write(
      EmployeesCompanion(
        status: const Value(EmployeeStatus.terminated),
        terminationDate: Value(terminationDate),
        terminationReference: Value(reference),
        terminationNotes: Value(notes),
      ),
    );
  }

  /// إعادة موظف إلى الخدمة — تمحو التاريخ والسند معاً
  ///
  /// وإلا بقي تاريخُ إنهاءٍ قديم يقصّ راتبه في كل شهر بعد عودته.
  Future<void> reinstateEmployee(int employeeId) async {
    await (update(employees)..where((e) => e.id.equals(employeeId))).write(
      const EmployeesCompanion(
        status: Value(EmployeeStatus.active),
        terminationDate: Value(null),
        terminationReference: Value(''),
        terminationNotes: Value(''),
      ),
    );
  }

  /// سياق خدمة الموظف اللازم لحساب راتب شهرٍ بعينه (Schema v9)
  ///
  /// 🔴 **ما كان معطوباً (طلب المالك 2026-09-02):**
  ///   ١. التناسب كان يعتمد على `hireDate` **من ملف الإكسل** وحده. فإن خلا
  ///      الملف من العمود — وهو الغالب — لم يقع تناسبٌ أصلاً، ومن عُيِّن في
  ///      اليوم العشرين أخذ راتب شهرٍ كامل.
  ///   ٢. و`terminationDate` **لا عمود له في القاعدة إطلاقاً**، فالدالة التي
  ///      تحسبه — مكتوبةً ومحروسةً بالاختبارات منذ اليوم الأول — لم تُستدعَ
  ///      بقيمةٍ قطّ. نمط ع-٠٦ في أنقى صوره.
  ///
  /// **وسجلّ الموظف هو مصدر الحقيقة** (قرار المالك): البرنامج يعرف تاريخ
  /// التعيين، والملف الشهري قد يخلو منه أو يحمل خطأً مطبعياً. والمستدعي
  /// يستعمل تاريخ الملف **فقط** حين يعود [hireDate] فارغاً.
  ///
  /// 📌 **ولماذا رَكوردٌ واحد لا ثلاث قراءات؟** لأن الثلاثة تصف حالةً واحدة
  ///   في لحظة واحدة، وتفريقُها يجعل مستدعياً لاحقاً يقرأ اثنتين وينسى
  ///   الثالثة — وهو النمط الذي أنتج ع-٥٠ (الدولار يسقط في المحطّة الوسطى).
  Future<({DateTime? hireDate, DateTime? terminationDate, int unpaidLeaveDays})>
      payrollServiceContext({
    required int employeeId,
    required int year,
    required int month,
    required int workingDays,
  }) async {
    final row = await getEmployeeById(employeeId);
    final leave = await unpaidLeaveDaysInMonth(
      employeeId: employeeId,
      year: year,
      month: month,
      workingDays: workingDays,
    );
    return (
      hireDate: row?.hireDate,
      terminationDate: row?.terminationDate,
      unpaidLeaveDays: leave,
    );
  }
}
