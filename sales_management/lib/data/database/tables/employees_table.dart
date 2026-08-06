// ─────────────────────────────────────────────────────────────────────────────
// employees_table.dart — جداول الموظفين والسلف والرواتب
//
// يحتوي هذا الملف على 3 جداول:
//   1. Employees     — بيانات الموظفين
//   2. CashAdvances  — السلف (كانت تُسمى Employee Loans في النظام القديم)
//   3. CashAdvanceRepayments — أقساط سداد السلف
//
// لماذا "CashAdvances" وليس "EmployeeLoans"؟
//   المصطلح المحاسبي الصحيح هو "سلفة" (Cash Advance) وليس "قرض"
//   لأن الشركة هي الدائنة والموظف هو المدين.
//   حقل `debtor_type` يسمح بتسجيل سلف لأشخاص خارجيين أيضاً.
//
// جدول SalaryPayments:
//   يُسجَّل كل صرف راتب هنا مع تفاصيل الخصومات والإضافات.
//   الراتب المُصرَف يُنشئ تلقائياً سند صرف (Voucher) في الخزينة.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import 'treasuries_table.dart';

/// جدول الموظفين
class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();

  // الاسم الكامل
  TextColumn get fullName => text().withLength(min: 1, max: 100).named('full_name')();

  // رقم الهاتف
  TextColumn get phone => text().withDefault(const Constant(''))();

  // العنوان
  TextColumn get address => text().withDefault(const Constant(''))();

  // الراتب الأساسي (بالدينار العراقي)
  RealColumn get basicSalary =>
      real().named('basic_salary').withDefault(const Constant(0.0))();

  // تاريخ التعيين
  DateTimeColumn get hireDate => dateTime().named('hire_date').nullable()();

  // الخزينة الخاصة بهذا الموظف (اختياري)
  IntColumn get treasuryId =>
      integer().named('treasury_id').references(Treasuries, #id).nullable()();

  // ملاحظات
  TextColumn get notes => text().withDefault(const Constant(''))();

  // هل الموظف نشط؟
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  // وقت الإنشاء
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  // حذف ناعم
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
}

/// جدول السلف (Cash Advances)
///
/// يدعم سلف للموظفين وسلف لأشخاص خارجيين.
/// CHECK constraint يضمن اتساق البيانات:
///   - إذا debtor_type='employee': employee_id لا يكون null
///   - إذا debtor_type='external': external_person_name لا يكون null
class CashAdvances extends Table {
  IntColumn get id => integer().autoIncrement()();

  // نوع المدين: 'employee' | 'external'
  TextColumn get debtorType =>
      text().named('debtor_type').withDefault(const Constant('employee'))();

  // معرّف الموظف (إذا debtor_type='employee')
  IntColumn get employeeId =>
      integer().named('employee_id').references(Employees, #id).nullable()();

  // اسم الشخص الخارجي (إذا debtor_type='external')
  TextColumn get externalPersonName =>
      text().named('external_person_name').nullable()();

  // مبلغ السلفة (دائماً موجب) — CHECK constraint عبر customConstraint
  RealColumn get amount => real().customConstraint('NOT NULL CHECK(amount > 0)')();

  // العملة: 'IQD' | 'USD'
  TextColumn get currency =>
      text().withDefault(const Constant('IQD'))();

  // تاريخ منح السلفة
  DateTimeColumn get advanceDate => dateTime().named('advance_date')();

  // حالة السلفة: pending | partial | paid | written_off
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  // مجموع ما تم سداده
  RealColumn get totalRepaid =>
      real().named('total_repaid').withDefault(const Constant(0.0))();

  // السبب / الغرض من السلفة
  TextColumn get reason => text().withDefault(const Constant(''))();

  // معرّف السند المرتبط (في جدول Vouchers)
  IntColumn get voucherId =>
      integer().named('voucher_id').nullable()();

  // وقت الإنشاء
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  // حذف ناعم
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
}

/// جدول أقساط سداد السلف
///
/// كل سداد جزئي أو كلي يُسجَّل هنا.
/// عند اكتمال السداد، يتحوّل `status` في CashAdvances إلى 'paid'.
class CashAdvanceRepayments extends Table {
  IntColumn get id => integer().autoIncrement()();

  // معرّف السلفة المرتبطة
  IntColumn get cashAdvanceId =>
      integer().named('cash_advance_id').references(CashAdvances, #id)();

  // مبلغ القسط — CHECK constraint عبر customConstraint
  RealColumn get amount => real().customConstraint('NOT NULL CHECK(amount > 0)')();

  // تاريخ السداد
  DateTimeColumn get repaymentDate => dateTime().named('repayment_date')();

  // طريقة السداد: 'cash' | 'salary_deduction' | 'bank_transfer'
  TextColumn get method =>
      text().withDefault(const Constant('cash'))();

  // معرّف السند المرتبط (إذا كان سداداً عبر سند قبض)
  IntColumn get voucherId =>
      integer().named('voucher_id').nullable()();

  // ملاحظات
  TextColumn get notes => text().withDefault(const Constant(''))();

  // وقت الإنشاء
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}

/// جدول مدفوعات الرواتب
///
/// كل دفعة راتب تُسجَّل هنا مع تفاصيل الخصومات والإضافات.
/// تُولّد تلقائياً سند صرف من الخزينة.
class SalaryPayments extends Table {
  IntColumn get id => integer().autoIncrement()();

  // الموظف المستفيد
  IntColumn get employeeId =>
      integer().named('employee_id').references(Employees, #id)();

  // الفترة التي يغطيها الراتب
  TextColumn get periodLabel =>
      text().named('period_label').withDefault(const Constant(''))();

  // الراتب الأساسي
  RealColumn get basicSalary =>
      real().named('basic_salary').withDefault(const Constant(0.0))();

  // إضافات (بدلات، مكافآت)
  RealColumn get additions => real().withDefault(const Constant(0.0))();

  // خصومات (سلف، غيابات)
  RealColumn get deductions => real().withDefault(const Constant(0.0))();

  // الصافي المدفوع = basicSalary + additions - deductions
  RealColumn get netAmount =>
      real().named('net_amount').withDefault(const Constant(0.0))();

  // تاريخ الصرف
  DateTimeColumn get paymentDate => dateTime().named('payment_date')();

  // معرّف السند المُولَّد
  IntColumn get voucherId =>
      integer().named('voucher_id').nullable()();

  // ملاحظات
  TextColumn get notes => text().withDefault(const Constant(''))();

  // وقت الإنشاء
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  // حذف ناعم
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
}
