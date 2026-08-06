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

import '../../data/database/app_database.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/employee_model.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

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
      isActive: e.isActive,
      createdAt: e.createdAt,
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

/// Stream تفاعلي للسلف الممنوحة لموظف محدد
@riverpod
Stream<List<CashAdvanceModel>> advancesByEmployee(Ref ref, int employeeId) {
  final db = ref.watch(appDatabaseProvider);
  return db.employeesDao
      .watchAdvancesByEmployee(employeeId)
      .map((list) => list.map(_mapAdvance).toList());
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

  // ── تفعيل / إيقاف موظف ─────────────────────────────────────────────────

  Future<bool> toggleActive(int id, {required bool isActive}) async {
    state = const AsyncLoading();
    try {
      await _db.employeesDao.setEmployeeActive(id, isActive: isActive);
      state = AsyncData(isActive ? 'تم تفعيل الموظف ✓' : 'تم إيقاف الموظف ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── حذف موظف ───────────────────────────────────────────────────────────

  Future<bool> deleteEmployee(int id) async {
    state = const AsyncLoading();
    try {
      await _db.employeesDao.softDeleteEmployee(id);
      state = const AsyncData('تم حذف الموظف ✓');
      return true;
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

/// Notifier لصرف الرواتب
///
/// عند صرف الراتب:
///   1. يُنشئ سند صرف تلقائياً من الخزينة المحددة
///   2. يُسجَّل في جدول SalaryPayments مع ربطه بالسند
@riverpod
class SalaryNotifier extends _$SalaryNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  AppDatabase get _db => ref.read(appDatabaseProvider);

  int? get _userId {
    final s = ref.read(authNotifierProvider);
    return s is AuthAuthenticated ? s.user.id : null;
  }

  /// صرف راتب موظف مع إنشاء سند صرف تلقائي
  Future<bool> paySalary({
    required int employeeId,
    required String employeeName,
    required int treasuryId,
    required double basicSalary,
    double additions = 0.0,
    double deductions = 0.0,
    required String periodLabel,
    required DateTime paymentDate,
    String notes = '',
  }) async {
    final netAmount = basicSalary + additions - deductions;
    if (netAmount <= 0) {
      state = const AsyncError(
        'الراتب الصافي يجب أن يكون أكبر من صفر',
        StackTrace.empty,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      // 1. الفترة المالية
      final period =
          await _db.fiscalPeriodsDao.getFiscalPeriodForDate(paymentDate);
      if (period == null) {
        state = const AsyncError(
          'لا توجد فترة مالية نشطة لهذا التاريخ',
          StackTrace.empty,
        );
        return false;
      }

      // 2. رقم السند التالي
      final voucherNumber = await _db.fiscalPeriodsDao.getNextVoucherNumber(
        fiscalPeriodId: period.id,
        voucherType: 'sarf',
      );

      // 3. إنشاء سند الصرف
      final voucherId = await _db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: voucherNumber,
          voucherType: 'sarf',
          treasuryId: treasuryId,
          fiscalPeriodId: period.id,
          amount: netAmount,
          currency: const Value('IQD'),
          voucherDate: paymentDate,
          personName: Value(employeeName),
          reason: Value('راتب $periodLabel'),
          itemType: const Value('راتب'),
          linkedEntityId: Value(employeeId),
          createdByUserId: Value(_userId),
        ),
      );

      // 4. تسجيل دفعة الراتب مرتبطة بالسند
      await _db.employeesDao.insertSalaryPayment(
        SalaryPaymentsCompanion.insert(
          employeeId: employeeId,
          paymentDate: paymentDate,
          periodLabel: Value(periodLabel),
          basicSalary: Value(basicSalary),
          additions: Value(additions),
          deductions: Value(deductions),
          netAmount: Value(netAmount),
          voucherId: Value(voucherId),
          notes: Value(notes.trim()),
        ),
      );

      state = const AsyncData('تم صرف الراتب بنجاح ✓');
      return true;
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

      // 2. رقم السند التالي
      final voucherNumber = await _db.fiscalPeriodsDao.getNextVoucherNumber(
        fiscalPeriodId: period.id,
        voucherType: 'sarf',
      );

      // 3. إنشاء سند الصرف
      final voucherId = await _db.vouchersDao.insertVoucher(
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
          voucherId: Value(voucherId),
        ),
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

      // 3. رقم سند القبض التالي
      final voucherNumber = await _db.fiscalPeriodsDao.getNextVoucherNumber(
        fiscalPeriodId: period.id,
        voucherType: 'kabd',
      );

      // 4. إنشاء سند القبض
      final voucherId = await _db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: voucherNumber,
          voucherType: 'kabd',
          treasuryId: treasuryId,
          fiscalPeriodId: period.id,
          amount: repaymentAmount,
          currency: Value(advance.currency),
          voucherDate: repaymentDate,
          personName: Value(empName),
          reason: const Value('سداد سلفة'),
          itemType: const Value('مرتجع صرف'),
          linkedEntityId: Value(advance.employeeId),
          createdByUserId: Value(_userId),
        ),
      );

      // 5. احتساب الحالة الجديدة
      final newRepaid = advance.totalRepaid + repaymentAmount;
      final newStatus =
          newRepaid >= advance.amount - 0.001 ? 'paid' : 'partial';

      // 6. إدراج القسط + تحديث السلفة ذرياً
      await _db.employeesDao.insertRepayment(
        repayment: CashAdvanceRepaymentsCompanion.insert(
          cashAdvanceId: advance.id,
          amount: repaymentAmount,
          repaymentDate: repaymentDate,
          method: Value(method),
          voucherId: Value(voucherId),
          notes: Value(notes.trim()),
        ),
        advanceId: advance.id,
        newTotalRepaid: newRepaid,
        newStatus: newStatus,
      );

      state = const AsyncData('تم تسجيل السداد بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  void reset() => state = const AsyncData(null);
}
