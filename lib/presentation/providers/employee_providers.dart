// ─────────────────────────────────────────────────────────────────────────────
// employee_providers.dart — Providers الموظفين والرواتب والسلف
//
// يُوفّر:
//   - قائمة الموظفين (Stream تفاعلي)
//   - سلف موظف محدد (Stream)
//   - رواتب موظف محدد (Stream)
//   - إجمالي السلف المعلّقة (Future)
//   - EmployeeNotifier  — CRUD الموظفين
//   - SalaryNotifier    — صرف الرواتب (مع إنشاء سند صرف تلقائي)
//   - AdvanceNotifier   — منح السلف + تسجيل الأقساط (مع سندات تلقائية)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/auth/permissions.dart';
import '../../core/constants/employee_status.dart';
import '../../core/services/balance_guard.dart';
import '../../core/utils/audit_logger.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/employees_dao.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/employee_model.dart';
import '../../domain/models/user_model.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'repository_providers.dart';

part 'employee_providers.g.dart';

// ── دوال تحويل Drift → Domain ─────────────────────────────────────────────

EmployeeModel _mapEmployee(Employee e) => EmployeeModel(
      id: e.id,
      fullName: e.fullName,
      phone: e.phone,
      address: e.address,
      basicSalary: e.basicSalary,
      hireDate: e.hireDate,
      treasuryId: e.treasuryId,
      notes: e.notes,
      // 🔴 `position` و`salaryCurrency` **كانتا ساقطتين هنا** منذ v7: طبقة
      //   الرواتب تقرأهما من صفّ Drift مباشرةً، فبقيت شاشة الموظفين عاجزة
      //   عن عرض الصفة، وتكتب «د.ع» تحت راتبٍ بالدولار (ع-٥٣). نمط ع-٥٠:
      //   الرقم صحيح في طرفيه ويسقط في المحطّة الوسطى.
      position: e.position,
      salaryCurrency: e.salaryCurrency,
      status: e.status,
      departmentId: e.departmentId,
      sortOrder: e.sortOrder,
      createdAt: e.createdAt,
    );

DepartmentModel _mapDepartment(Department d) => DepartmentModel(
      id: d.id,
      name: d.name,
      sortOrder: d.sortOrder,
      createdAt: d.createdAt,
    );

CashAdvanceModel _mapAdvance(CashAdvance a) => CashAdvanceModel(
      id: a.id,
      debtorType: a.debtorType,
      employeeId: a.employeeId,
      externalPersonName: a.externalPersonName,
      amount: a.amount,
      currency: a.currency,
      advanceDate: a.advanceDate,
      status: a.status,
      totalRepaid: a.totalRepaid,
      reason: a.reason,
      voucherId: a.voucherId,
      createdAt: a.createdAt,
    );

SalaryPaymentModel _mapSalary(SalaryPayment s) => SalaryPaymentModel(
      id: s.id,
      employeeId: s.employeeId,
      periodLabel: s.periodLabel,
      basicSalary: s.basicSalary,
      additions: s.additions,
      deductions: s.deductions,
      netAmount: s.netAmount,
      paymentDate: s.paymentDate,
      voucherId: s.voucherId,
      notes: s.notes,
    );

// ── قوائم الموظفين التفاعلية ───────────────────────────────────────────────

/// Stream تفاعلي لجميع الموظفين (غير المحذوفين) مرتب أبجدياً
@riverpod
Stream<List<EmployeeModel>> allEmployees(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.employeesDao
      .watchAllEmployees()
      .map((list) => list.map(_mapEmployee).toList());
}

/// أقسام الموظفين مرتَّبة — Reactive Stream (Schema v8)
@riverpod
Stream<List<DepartmentModel>> allDepartments(Ref ref) {
  return ref
      .watch(appDatabaseProvider)
      .employeesDao
      .watchDepartments()
      .map((list) => list.map(_mapDepartment).toList());
}

/// Stream تفاعلي للسلف الممنوحة لموظف محدد
@riverpod
Stream<List<CashAdvanceModel>> advancesByEmployee(Ref ref, int employeeId) {
  final db = ref.watch(appDatabaseProvider);
  return db.employeesDao
      .watchAdvancesByEmployee(employeeId)
      .map((list) => list.map(_mapAdvance).toList());
}

/// أثر الموظف المالي — يُقرأ قبل عرض حوار الحذف ليقول ما يمنعه
@riverpod
Future<({int unpaidAdvances, double advanceBalance, int salaryRows})>
    employeeFootprint(Ref ref, int employeeId) {
  return ref
      .watch(appDatabaseProvider)
      .employeesDao
      .getEmployeeFinancialFootprint(employeeId);
}

/// **تفاصيل تسديد سلفة** — كل قسط بمصدره (سند نقدي أو رواتب شهر)
///
/// بلاغ المالك 2026-08-30: «أريد أن أرى **كيف** سُدّدت السلفة». والبيانات
/// كانت كلها في `cash_advance_repayments` — ينقص العرض فقط.
@riverpod
Future<List<AdvanceRepaymentDetail>> advanceRepaymentDetails(
  Ref ref,
  int advanceId,
) {
  return ref.watch(appDatabaseProvider).employeesDao
      .getRepaymentDetails(advanceId);
}

/// Stream تفاعلي لرواتب موظف محدد
@riverpod
Stream<List<SalaryPaymentModel>> salariesByEmployee(Ref ref, int employeeId) {
  final db = ref.watch(appDatabaseProvider);
  return db.employeesDao
      .watchSalariesByEmployee(employeeId)
      .map((list) => list.map(_mapSalary).toList());
}

/// إجمالي السلف غير المسدَّدة لموظف (للعرض في البطاقة)
@riverpod
Future<double> pendingAdvancesAmount(Ref ref, int employeeId) {
  final db = ref.watch(appDatabaseProvider);
  return db.employeesDao.getTotalPendingAdvancesForEmployee(employeeId);
}

// ═══════════════════════════════════════════════════════════════════════════
// EmployeeNotifier — CRUD الموظفين
// ═══════════════════════════════════════════════════════════════════════════

/// Notifier لإدارة عمليات الموظفين (إضافة / تعديل / حذف / تفعيل)
@riverpod
class EmployeeNotifier extends _$EmployeeNotifier {

  /// نقل موظفي خزينة إلى أخرى — يُستدعى قبل حذف الخزينة
  ///
  /// [toTreasuryId] فارغ ⇒ يبقون بلا مشروع (وهو ما كان يقع صامتاً قبل ع-٣٤)
  Future<int> reassignTreasury({
    required int fromTreasuryId,
    int? toTreasuryId,
  }) async {
    final moved = await ref
        .read(appDatabaseProvider)
        .employeesDao
        .reassignTreasury(
          fromTreasuryId: fromTreasuryId,
          toTreasuryId: toTreasuryId,
        );
    ref.invalidate(allEmployeesProvider);
    return moved;
  }

  @override
  AsyncValue<String?> build() => const AsyncData(null);

  AppDatabase get _db => ref.read(appDatabaseProvider);

  // ── إضافة موظف جديد ────────────────────────────────────────────────────

  Future<bool> createEmployee({
    required String fullName,
    String phone = '',
    String address = '',
    double basicSalary = 0.0,
    DateTime? hireDate,
    String notes = '',
  }) async {
    if (fullName.trim().isEmpty) {
      state = const AsyncError(
        'اسم الموظف لا يمكن أن يكون فارغاً',
        StackTrace.empty,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      await _db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
          fullName: fullName.trim(),
          phone: Value(phone.trim()),
          address: Value(address.trim()),
          basicSalary: Value(basicSalary),
          hireDate: Value(hireDate),
          notes: Value(notes.trim()),
        ),
      );
      state = const AsyncData('تم إضافة الموظف بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── تعديل بيانات موظف ──────────────────────────────────────────────────

  Future<bool> updateEmployee(
    EmployeeModel employee, {
    required String fullName,
    String phone = '',
    String address = '',
    double basicSalary = 0.0,
    DateTime? hireDate,
    String notes = '',
  }) async {
    if (fullName.trim().isEmpty) {
      state = const AsyncError('الاسم لا يمكن أن يكون فارغاً', StackTrace.empty);
      return false;
    }
    state = const AsyncLoading();
    try {
      await _db.employeesDao.updateEmployee(
        EmployeesCompanion(
          id: Value(employee.id),
          fullName: Value(fullName.trim()),
          phone: Value(phone.trim()),
          address: Value(address.trim()),
          basicSalary: Value(basicSalary),
          hireDate: Value(hireDate),
          notes: Value(notes.trim()),
        ),
      );
      state = const AsyncData('تم تحديث بيانات الموظف ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── حالة الموظف (Schema v8) ────────────────────────────────────────────

  /// تغيير حالة الموظف — حالي · منتهية خدمته · في إجازة
  ///
  /// ⚠️ **المنع بلا بديل يُهجّر الخطر لا يُزيله** (درس ع-٣٢): مالكٌ مُنع من
  ///   حذف موظفٍ انتهت خدمته سيجد طريقاً آخر — يُعيد تسميته أو يحذف سطوره.
  ///   وتغيير الحالة بابٌ مشروع: يبقى السجلّ والتقارير، ولا يدخل صاحبه
  ///   كشوف الرواتب الجديدة.
  Future<bool> setStatus(int id, String status) async {
    state = const AsyncLoading();
    try {
      await _db.employeesDao.setEmployeeStatus(id, status);
      state = AsyncData('الحالة الآن: ${EmployeeStatus.label(status)} ✓');
      return true;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── الأقسام والترتيب اليدوي (Schema v8) ────────────────────────────────

  Future<bool> addDepartment(String name) => _guarded(
        () => _db.employeesDao.insertDepartment(name),
        'أُضيف القسم ✓',
      );

  Future<bool> renameDepartment(int id, String name) => _guarded(
        () => _db.employeesDao.renameDepartment(id, name),
        'أُعيدت التسمية ✓',
      );

  /// حذف قسم — الرسالة تقول **كم موظفاً** صار بلا قسم
  Future<bool> removeDepartment(int id) async {
    state = const AsyncLoading();
    try {
      final moved = await _db.employeesDao.deleteDepartment(id);
      state = AsyncData(moved == 0
          ? 'حُذف القسم ✓'
          : 'حُذف القسم · صار $moved موظفاً بلا قسم ✓');
      return true;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> reorderDepartments(List<int> ids) => _guarded(
        () => _db.employeesDao.reorderDepartments(ids),
        'حُفظ ترتيب الأقسام ✓',
      );

  Future<bool> assignDepartment(int employeeId, int? departmentId) => _guarded(
        () => _db.employeesDao.assignDepartment(employeeId, departmentId),
        'نُقل الموظف ✓',
      );

  Future<bool> reorderEmployees(List<int> ids) => _guarded(
        () => _db.employeesDao.reorderEmployees(ids),
        'حُفظ الترتيب ✓',
      );

  /// تنفيذ عملية مع عرض رسالة الحارس العربية كما كُتبت
  ///
  /// الصمت هنا هو عين ع-٢٥: حارسٌ يرفض بحقّ ولا أحد يعرض رسالته.
  Future<bool> _guarded(Future<void> Function() action, String success) async {
    state = const AsyncLoading();
    try {
      await action();
      state = AsyncData(success);
      return true;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── حذف موظف ───────────────────────────────────────────────────────────

  /// حذف موظف — **محروساً بأثره المالي** (بلاغ المالك 2026-08-30)
  ///
  /// يمرّ بـ`deleteEmployeeGuarded` التي ترفض من عليه سلفة غير مسدَّدة أو
  /// له سطور رواتب سابقة، وتوجّه إلى **التعطيل** بديلاً.
  Future<bool> deleteEmployee(int id) async {
    state = const AsyncLoading();
    try {
      await _db.employeesDao.deleteEmployeeGuarded(id);
      state = const AsyncData('تم حذف الموظف ✓');
      return true;
    } on StateError catch (e, st) {
      // رسالة الحارس عربية جاهزة للعرض كما هي
      state = AsyncError(e.message, st);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  void reset() => state = const AsyncData(null);
}

// ═══════════════════════════════════════════════════════════════════════════
// SalaryNotifier — صرف الرواتب
// ═══════════════════════════════════════════════════════════════════════════

/// تُلحَق برسالة النجاح حين يُضاف موظف إلى كشف مُسدَّد بالكامل
///
/// الإخبار هنا **جزء من الأمان لا مجاملة**: المالك قد يكون طبع الكشف
/// ووزّعه، فمعرفتُه أن مجموعه تغيّر تجعله يُعيد الطباعة بدل أن يكتشف
/// الفرق بعد شهور.
const String _kLateAdditionNote =
    '\nملاحظة: كشف هذا الشهر كان مُسدَّداً — أُضيف الموظف إليه وسُجِّل ذلك '
    'في سجل التدقيق.';

/// Notifier لصرف الرواتب
///
/// عند صرف الراتب:
///   1. يُنشئ سند صرف تلقائياً من الخزينة المحددة
///   2. يُسجَّل في جدول SalaryPayments مع ربطه بالسند
@riverpod
class SalaryNotifier extends _$SalaryNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  /// المستخدم الحالي — `null` إن لم يكن مصادَقاً
  UserModel? get _user {
    final s = ref.read(authNotifierProvider);
    return s is AuthAuthenticated ? s.user : null;
  }

  /// صرف راتب موظف واحد — **يقع داخل كشف شهره** (قرار المالك 2026-08-26)
  ///
  /// 🔑 **ما تغيّر ولماذا:** كانت هذه الدالة تُنشئ السند وتكتب سطر راتب
  ///   **بلا كشف**، فيصير في النظام طريقان لتسجيل راتب: واحد داخل الكشوف
  ///   وآخر خارجها. أي تقرير يقرأ أحدهما وينسى الآخر يُخفي مالاً خرج فعلاً
  ///   (ع-٢٨). الآن تُفوَّض بالكامل إلى `PayrollRepository.paySingleEmployee`،
  ///   فالسطر ينتسب لكشف شهره ويظهر في كل تقرير بلا استثناء.
  ///
  /// **والصلاحية صارت `managePayroll` (مدير)** — قرار المالك 2026-08-26.
  ///   كان هذا المسار **بلا أي فحص صلاحية**: أي مستخدم عادي يصرف راتباً
  ///   ويُنشئ سند صرف، بينما تسديد الكشف يحتاج مديراً. ثغرةٌ لا مبرّر لها:
  ///   المسار الذي يُخرج المال هو ما يجب أن يُحرَس، لا الشاشة التي تعرضه.
  ///
  /// [year] و[month] — شهر **الراتب** لا شهر الصرف. إلزاميان: بهما يُنسَب
  /// الراتب إلى كشفه، وبلا كشف لا تقرير ولا تنبيه عند الاستيراد.
  Future<bool> paySalary({
    required int employeeId,
    required String employeeName,
    required int treasuryId,
    required double basicSalary,
    double additions = 0.0,
    double deductions = 0.0,
    required int year,
    required int month,
    required DateTime paymentDate,
    String notes = '',
  }) async {
    final user = _user;
    if (user == null || !user.can(AppPermission.managePayroll)) {
      state = const AsyncError(
        'لا تملك صلاحية صرف الرواتب — هذه العملية للمدير.',
        StackTrace.empty,
      );
      return false;
    }

    state = const AsyncLoading();
    try {
      final result =
          await ref.read(payrollRepositoryProvider).paySingleEmployee(
                employeeId: employeeId,
                year: year,
                month: month,
                treasuryId: treasuryId,
                basicSalary: basicSalary,
                additions: additions,
                deductions: deductions,
                paymentDate: paymentDate,
                notes: notes,
                paidByUserId: user.id,
              );

      // ── الأثر الرقابي ────────────────────────────────────────────────
      await ref.read(auditLoggerProvider).logVoucherCreated(
            userId: user.id,
            username: user.username,
            voucherId: result.voucherId,
            voucherType: 'sarf',
            amount: result.netIqd,
            treasuryId: treasuryId,
          );
      await ref.read(auditLoggerProvider).logPayrollPaid(
            userId: user.id,
            username: user.username,
            periodId: result.periodId,
            periodLabel: result.periodLabel,
            employeeCount: 1,
            totalIqd: result.netIqd,
            voucherId: result.voucherId,
          );

      // ⚠️ حدثٌ مستقلّ حين يُضاف موظف إلى كشف **مُسدَّد بالكامل**: ورقةٌ
      //   اعتُمدت وطُبعت يتغيّر مجموعها، فلا يجوز أن يقع ذلك بلا شاهد
      //   يسمّي الموظف والمبلغ ومن فعلها.
      if (result.addedToPostedSheet) {
        await ref.read(auditLoggerProvider).logPayrollLateAddition(
              userId: user.id,
              username: user.username,
              periodId: result.periodId,
              periodLabel: result.periodLabel,
              employeeName: result.employeeName,
              amountIqd: result.netIqd,
              voucherId: result.voucherId,
            );
      }

      state = AsyncData(
        'صُرف راتب ${result.employeeName} عن ${result.periodLabel} '
        'بسند رقم ${result.voucherNumber} ✓'
        '${result.addedToPostedSheet ? _kLateAdditionNote : ''}',
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

  void reset() => state = const AsyncData(null);
}

// ═══════════════════════════════════════════════════════════════════════════
// AdvanceNotifier — منح السلف وتسجيل الأقساط
// ═══════════════════════════════════════════════════════════════════════════

/// Notifier لإدارة السلف وأقساط السداد
///
/// منح سلفة:
///   يُنشئ سند صرف تلقائياً + يُسجَّل في CashAdvances
///
/// سداد قسط:
///   يُنشئ سند قبض تلقائياً + يُحدَّث رصيد السلفة وحالتها ذرياً
@riverpod
class AdvanceNotifier extends _$AdvanceNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  AppDatabase get _db => ref.read(appDatabaseProvider);

  int? get _userId {
    final s = ref.read(authNotifierProvider);
    return s is AuthAuthenticated ? s.user.id : null;
  }

  String get _username {
    final s = ref.read(authNotifierProvider);
    return s is AuthAuthenticated ? s.user.username : 'system';
  }

  // ── منح سلفة ───────────────────────────────────────────────────────────

  /// منح سلفة لموظف مع إنشاء سند صرف تلقائي
  Future<bool> grantAdvance({
    required int employeeId,
    required String employeeName,
    required int treasuryId,
    required double amount,
    String currency = 'IQD',
    required DateTime advanceDate,
    String reason = '',
  }) async {
    if (amount <= 0) {
      state = const AsyncError(
        'مبلغ السلفة يجب أن يكون أكبر من صفر',
        StackTrace.empty,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      // فحص كفاية رصيد الخزينة (حسب سياسة المنع في الإعدادات)
      final balanceError = await BalanceGuard.checkSufficientBalance(
        _db,
        treasuryId: treasuryId,
        currency: currency,
        amount: amount,
      );
      if (balanceError != null) {
        state = AsyncError(balanceError, StackTrace.empty);
        return false;
      }

      // 1. الفترة المالية
      final period =
          await _db.fiscalPeriodsDao.getFiscalPeriodForDate(advanceDate);
      if (period == null) {
        state = const AsyncError(
          'لا توجد فترة مالية نشطة لهذا التاريخ',
          StackTrace.empty,
        );
        return false;
      }

      // ⚠️ خطوات 2–4 داخل معاملة واحدة (إصلاح السند اليتيم):
      //   السند وسجل السلفة يجب أن يُكتبا معاً أو لا يُكتبا، وإلا يبقى
      //   المال قد خرج من الخزينة بلا سلفة مسجَّلة مقابلة.
      final voucherId = await _db.transaction(() async {
        // 2. رقم السند التالي
        final voucherNumber = await _db.fiscalPeriodsDao.getNextVoucherNumber(
          fiscalPeriodId: period.id,
          voucherType: 'sarf',
        );

        // 3. إنشاء سند الصرف
        final vid = await _db.vouchersDao.insertVoucher(
          VouchersCompanion.insert(
            voucherNumber: voucherNumber,
            voucherType: 'sarf',
            treasuryId: treasuryId,
            fiscalPeriodId: period.id,
            amount: amount,
            currency: Value(currency),
            voucherDate: advanceDate,
            personName: Value(employeeName),
            reason: Value(
              reason.isNotEmpty ? reason : 'سلفة للموظف $employeeName',
            ),
            itemType: const Value('سلفة'),
            linkedEntityId: Value(employeeId),
            createdByUserId: Value(_userId),
          ),
        );

        // 4. تسجيل السلفة
        await _db.employeesDao.insertAdvance(
          CashAdvancesCompanion.insert(
            amount: amount,
            advanceDate: advanceDate,
            employeeId: Value(employeeId),
            currency: Value(currency),
            reason: Value(reason.trim()),
            voucherId: Value(vid),
          ),
        );
        return vid;
      });

      // تحديث مبلغ السلف القائمة في الواجهة + توثيق العملية
      ref.invalidate(pendingAdvancesAmountProvider(employeeId));
      await ref.read(auditLoggerProvider).logVoucherCreated(
            userId: _userId ?? 0,
            username: _username,
            voucherId: voucherId,
            voucherType: 'sarf',
            amount: amount,
            currency: currency,
            treasuryId: treasuryId,
          );

      state = const AsyncData('تم منح السلفة بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── تسجيل قسط سداد ─────────────────────────────────────────────────────

  /// تسجيل قسط سداد سلفة مع إنشاء سند قبض تلقائي
  ///
  /// يُحدَّث رصيد السلفة وحالتها ذرياً في نفس الـ Transaction
  Future<bool> repayAdvance({
    required CashAdvanceModel advance,
    required int treasuryId,
    required double repaymentAmount,
    required DateTime repaymentDate,
    String method = 'cash',
    String notes = '',
  }) async {
    if (repaymentAmount <= 0) {
      state = const AsyncError(
        'مبلغ السداد يجب أن يكون أكبر من صفر',
        StackTrace.empty,
      );
      return false;
    }
    // فحص أوّلي سريع للواجهة (غير مُلزِم) — الفحص المُلزِم داخل المعاملة
    final remaining = advance.remainingAmount;
    if (repaymentAmount > remaining + 0.001) {
      state = AsyncError(
        'مبلغ السداد أكبر من المبلغ المتبقي (${remaining.toStringAsFixed(0)})',
        StackTrace.empty,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      // ═══════════════════════════════════════════════════════════════
      // 🔴 **«خصم من الراتب» ليس تسديداً الآن** (ع-٣٩ — بلاغ المالك)
      //
      //   كان هذا المسار يُنشئ **سند قبض** لكل الطرق — بما فيها الخصم من
      //   الراتب. والمال حينها **لم يدخل الخزينة**: سيخرج راتبٌ أقلّ في
      //   نهاية الشهر. فيتضخّم الرصيد برقم وهمي، ثم يُخصم من الراتب فعلاً
      //   فيُحتسب القسط **مرّتين**.
      //
      //   والخصم الحقيقي يقع في `PayrollDao.recordSalaryDeductions` لحظة
      //   تسديد الراتب — وهو **المسار الوحيد** الذي يسجّله.
      // ═══════════════════════════════════════════════════════════════
      if (method == 'salary_deduction') {
        await _db.employeesDao.markForSalaryDeduction(advanceId: advance.id);
        if (advance.employeeId != null) {
          ref.invalidate(pendingAdvancesAmountProvider(advance.employeeId!));
        }
        state = const AsyncData(
          'سيُخصم المبلغ من راتب الشهر ✓\n'
          'لم يُنشأ سند: المال لم يدخل الخزينة بل سيخرج راتبٌ أقلّ. '
          'وسيظهر تنبيه السلفة في كشف الرواتب ليُخصم هناك مرّة واحدة.',
        );
        return true;
      }

      // 1. الفترة المالية
      final period =
          await _db.fiscalPeriodsDao.getFiscalPeriodForDate(repaymentDate);
      if (period == null) {
        state = const AsyncError(
          'لا توجد فترة مالية نشطة لهذا التاريخ',
          StackTrace.empty,
        );
        return false;
      }

      // 2. اسم الموظف للسند
      final emp = advance.employeeId != null
          ? await _db.employeesDao.getEmployeeById(advance.employeeId!)
          : null;
      final empName = emp?.fullName ?? 'موظف';

      // ⚠️ خطوات 3–6 داخل معاملة واحدة مع إعادة قراءة السلفة (إصلاح H7):
      //   الفحص القديم كان يعتمد على نسخة السلفة الملتقطة في الواجهة، فلو
      //   فُتحت نافذتا سداد على نفس السلفة يمرّان معاً وتُدهَس إحداهما.
      //   هنا نُعيد قراءة total_repaid الطازج داخل المعاملة، ونحسب المجموع
      //   تراكمياً، ونرفض التجاوز — فلا يمكن لسدادين متزامنين أن يتجاوزا المبلغ.
      final voucherId = await _db.transaction(() async {
        // إعادة قراءة السلفة الطازجة داخل المعاملة
        final fresh = await _db.employeesDao.getAdvanceById(advance.id);
        if (fresh == null) {
          throw Exception('لم يُعثَر على السلفة');
        }
        final freshRemaining = fresh.amount - fresh.totalRepaid;
        if (repaymentAmount > freshRemaining + 0.001) {
          throw Exception(
            'مبلغ السداد أكبر من المبلغ المتبقي (${freshRemaining.toStringAsFixed(0)})',
          );
        }

        // 3. رقم سند القبض التالي
        final voucherNumber = await _db.fiscalPeriodsDao.getNextVoucherNumber(
          fiscalPeriodId: period.id,
          voucherType: 'kabd',
        );

        // 4. إنشاء سند القبض
        final vid = await _db.vouchersDao.insertVoucher(
          VouchersCompanion.insert(
            voucherNumber: voucherNumber,
            voucherType: 'kabd',
            treasuryId: treasuryId,
            fiscalPeriodId: period.id,
            amount: repaymentAmount,
            currency: Value(advance.currency),
            voucherDate: repaymentDate,
            personName: Value(empName),
            reason: const Value('سداد سلفة موظف'),
            itemType: const Value('مرتجع صرف'),
            linkedEntityId: Value(advance.employeeId),
            createdByUserId: Value(_userId),
          ),
        );

        // 5. احتساب الحالة الجديدة من البيانات الطازجة
        final newRepaid = fresh.totalRepaid + repaymentAmount;
        final newStatus =
            newRepaid >= fresh.amount - 0.001 ? 'paid' : 'partial';

        // 6. إدراج القسط + تحديث السلفة (insertRepayment له معاملته الداخلية
        //    التي تصبح Savepoint ضمن هذه المعاملة الخارجية)
        await _db.employeesDao.insertRepayment(
          repayment: CashAdvanceRepaymentsCompanion.insert(
            cashAdvanceId: advance.id,
            amount: repaymentAmount,
            repaymentDate: repaymentDate,
            method: Value(method),
            voucherId: Value(vid),
            notes: Value(notes.trim()),
          ),
          advanceId: advance.id,
          newTotalRepaid: newRepaid,
          newStatus: newStatus,
        );
        return vid;
      });

      // تحديث الواجهة + توثيق السداد
      if (advance.employeeId != null) {
        ref.invalidate(pendingAdvancesAmountProvider(advance.employeeId!));
      }
      await ref.read(auditLoggerProvider).logVoucherCreated(
            userId: _userId ?? 0,
            username: _username,
            voucherId: voucherId,
            voucherType: 'kabd',
            amount: repaymentAmount,
            currency: advance.currency,
            treasuryId: treasuryId,
          );

      state = const AsyncData('تم تسجيل السداد بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── إلغاء سلفة موظف (ع-٣٨) ─────────────────────────────────────────────

  /// إلغاء سلفة موظف كاملةً — السلفة وأقساطها وسندها معاً
  ///
  /// 🔑 **سبب وجوده** (طلب المالك 2026-08-27): الموظف قد يُعيد السلفة في
  ///   يومها، فيُلغى كل شيء ويعود الرصيد إلى ما كان عليه بالضبط.
  ///
  /// ⚠️ تُستدعى **بعد** تأكيد كلمة المرور في الواجهة: العملية تُرجع مالاً خرج.
  Future<bool> cancelEmployeeAdvance({
    required int advanceId,
    required String reason,
  }) async {
    state = const AsyncLoading();
    try {
      // يُقرأ **قبل** الإلغاء — بعده يختفي فلا يبقى ما يُوثَّق
      final advance = await _db.employeesDao.getAdvanceById(advanceId);

      await _db.employeesDao.cancelEmployeeAdvance(
        advanceId: advanceId,
        reason: reason,
      );

      if (advance != null) {
        await ref.read(auditLoggerProvider).logEmployeeAdvanceCancelled(
              userId: _userId ?? 0,
              username: _username,
              advanceId: advanceId,
              amount: advance.amount,
              reason: reason.trim(),
            );
        if (advance.employeeId != null) {
          ref.invalidate(pendingAdvancesAmountProvider(advance.employeeId!));
        }
      }

      state = const AsyncData('أُلغيت السلفة ورجع المبلغ إلى الخزينة ✓');
      return true;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  void reset() => state = const AsyncData(null);
}
