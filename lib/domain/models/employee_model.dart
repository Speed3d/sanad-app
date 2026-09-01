// ─────────────────────────────────────────────────────────────────────────────
// employee_model.dart — نماذج الموظف والسلفة والراتب في طبقة الـ Domain
//
// أربعة نماذج متشابكة:
//   DepartmentModel    — قسم الموظفين (Schema v8)
//   EmployeeModel      — بيانات الموظف الأساسية
//   CashAdvanceModel   — سلفة ممنوحة لموظف أو خارجي
//   SalaryPaymentModel — دفعة راتب لموظف
// ─────────────────────────────────────────────────────────────────────────────

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/constants/employee_status.dart';

part 'employee_model.freezed.dart';
part 'employee_model.g.dart';

/// نموذج الموظف
@freezed
abstract class EmployeeModel with _$EmployeeModel {
  const factory EmployeeModel({
    /// المعرّف الفريد
    required int id,

    /// الاسم الكامل
    required String fullName,

    /// رقم الهاتف
    @Default('') String phone,

    /// العنوان
    @Default('') String address,

    /// الراتب الأساسي الشهري بالدينار
    @Default(0.0) double basicSalary,

    /// تاريخ التعيين
    DateTime? hireDate,

    /// معرّف الخزينة الخاصة بالموظف (اختياري)
    int? treasuryId,

    /// ملاحظات
    @Default('') String notes,

    /// الصفة الوظيفية — مهندس · سائق · محاسب
    ///
    /// 🔴 **كانت ساقطة من هذا النموذج** رغم وجودها في الجدول منذ v7: طبقة
    ///   الرواتب تقرأها من صفّ Drift مباشرةً، فبقيت شاشة الموظفين عاجزة عن
    ///   عرض صفة أيّ موظف. نمط ع-٥٠: الرقم يُحسَب صحيحاً ويسقط في المحطّة
    ///   الوسطى لأن طرفيها سليمان.
    @Default('') String position,

    /// عملة الراتب: 'IQD' | 'USD'
    ///
    /// 🔴 **كانت ساقطة أيضاً** — فكانت البطاقة تكتب «الراتب: ٥٠٠ د.ع»
    ///   لموظفٍ راتبه ٥٠٠ **دولار**، وتجمع الاثنين في مجموع واحد. راجع
    ///   ع-٥٣.
    @Default('IQD') String salaryCurrency,

    /// حالة الموظف (Schema v8) — راجع [EmployeeStatus]
    ///
    /// حلّت محلّ `isActive` ولم تُضَف بجوارها: عمودان لمعنى واحد يفترقان
    /// بأول كتابة تنسى أحدهما (نمط ع-٤٠).
    @Default(EmployeeStatus.active) String status,

    /// القسم — `null` يعني «بلا قسم»
    int? departmentId,

    /// ترتيب الموظف داخل قسمه — الأصغر أولاً
    @Default(0) int sortOrder,

    /// تاريخ الإنشاء
    DateTime? createdAt,
  }) = _EmployeeModel;

  factory EmployeeModel.fromJson(Map<String, dynamic> json) =>
      _$EmployeeModelFromJson(json);
}

/// نموذج قسم الموظفين (Schema v8)
@freezed
abstract class DepartmentModel with _$DepartmentModel {
  const factory DepartmentModel({
    /// المعرّف الفريد
    required int id,

    /// اسم القسم — «مهندسون» · «فنيون» · «سواق»
    required String name,

    /// ترتيب القسم في القائمة — الأصغر أولاً
    @Default(0) int sortOrder,

    /// تاريخ الإنشاء
    DateTime? createdAt,
  }) = _DepartmentModel;

  factory DepartmentModel.fromJson(Map<String, dynamic> json) =>
      _$DepartmentModelFromJson(json);
}

/// نموذج السلفة (Cash Advance)
@freezed
abstract class CashAdvanceModel with _$CashAdvanceModel {
  const factory CashAdvanceModel({
    /// المعرّف الفريد
    required int id,

    /// نوع المدين: 'employee' | 'external'
    @Default('employee') String debtorType,

    /// معرّف الموظف (إذا debtorType='employee')
    int? employeeId,

    /// اسم الشخص الخارجي (إذا debtorType='external')
    String? externalPersonName,

    /// مبلغ السلفة (دائماً موجب)
    required double amount,

    /// العملة: 'IQD' | 'USD'
    @Default('IQD') String currency,

    /// تاريخ منح السلفة
    required DateTime advanceDate,

    /// الحالة: 'pending' | 'partial' | 'paid' | 'written_off'
    @Default('pending') String status,

    /// إجمالي ما تم سداده حتى الآن
    @Default(0.0) double totalRepaid,

    /// السبب / الغرض
    @Default('') String reason,

    /// معرّف السند المرتبط
    int? voucherId,

    /// تاريخ الإنشاء
    DateTime? createdAt,
  }) = _CashAdvanceModel;

  factory CashAdvanceModel.fromJson(Map<String, dynamic> json) =>
      _$CashAdvanceModelFromJson(json);
}

/// نموذج دفعة الراتب
@freezed
abstract class SalaryPaymentModel with _$SalaryPaymentModel {
  const factory SalaryPaymentModel({
    /// المعرّف الفريد
    required int id,

    /// معرّف الموظف
    required int employeeId,

    /// التسمية: 'يناير 2025' أو 'الربع الأول 2025'
    @Default('') String periodLabel,

    /// الراتب الأساسي
    @Default(0.0) double basicSalary,

    /// الإضافات (بدلات، مكافآت)
    @Default(0.0) double additions,

    /// الخصومات (سلف، غيابات)
    @Default(0.0) double deductions,

    /// الصافي المدفوع = basicSalary + additions - deductions
    @Default(0.0) double netAmount,

    /// تاريخ الصرف
    required DateTime paymentDate,

    /// معرّف السند المُولَّد تلقائياً
    int? voucherId,

    /// ملاحظات
    @Default('') String notes,
  }) = _SalaryPaymentModel;

  factory SalaryPaymentModel.fromJson(Map<String, dynamic> json) =>
      _$SalaryPaymentModelFromJson(json);
}

// ── Extensions مساعدة ────────────────────────────────────────────────────────

/// امتدادات لنموذج السلفة
extension CashAdvanceModelX on CashAdvanceModel {
  /// المبلغ المتبقي (لم يُسدَّد بعد)
  double get remainingAmount {
    final r = amount - totalRepaid;
    return r < 0 ? 0 : r;
  }

  /// نسبة السداد من 0 إلى 1
  double get repaymentProgress => amount > 0 ? (totalRepaid / amount).clamp(0.0, 1.0) : 0.0;

  /// هل السلفة مسدَّدة بالكامل؟
  bool get isPaid => status == 'paid';

  /// هل السلفة قيد الانتظار أو السداد الجزئي؟
  bool get isPending => status == 'pending' || status == 'partial';

  /// وصف الحالة بالعربية
  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'معلّقة';
      case 'partial':
        return 'سداد جزئي';
      case 'paid':
        return 'مسدَّدة';
      case 'written_off':
        return 'مشطوبة';
      default:
        return status;
    }
  }
}
