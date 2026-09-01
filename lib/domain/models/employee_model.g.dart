// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EmployeeModelImpl _$$EmployeeModelImplFromJson(Map<String, dynamic> json) =>
    _$EmployeeModelImpl(
      id: (json['id'] as num).toInt(),
      fullName: json['fullName'] as String,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      basicSalary: (json['basicSalary'] as num?)?.toDouble() ?? 0.0,
      hireDate: json['hireDate'] == null
          ? null
          : DateTime.parse(json['hireDate'] as String),
      treasuryId: (json['treasuryId'] as num?)?.toInt(),
      notes: json['notes'] as String? ?? '',
      position: json['position'] as String? ?? '',
      salaryCurrency: json['salaryCurrency'] as String? ?? 'IQD',
      status: json['status'] as String? ?? EmployeeStatus.active,
      departmentId: (json['departmentId'] as num?)?.toInt(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$EmployeeModelImplToJson(_$EmployeeModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'phone': instance.phone,
      'address': instance.address,
      'basicSalary': instance.basicSalary,
      'hireDate': instance.hireDate?.toIso8601String(),
      'treasuryId': instance.treasuryId,
      'notes': instance.notes,
      'position': instance.position,
      'salaryCurrency': instance.salaryCurrency,
      'status': instance.status,
      'departmentId': instance.departmentId,
      'sortOrder': instance.sortOrder,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$DepartmentModelImpl _$$DepartmentModelImplFromJson(
        Map<String, dynamic> json) =>
    _$DepartmentModelImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$DepartmentModelImplToJson(
        _$DepartmentModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sortOrder': instance.sortOrder,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$CashAdvanceModelImpl _$$CashAdvanceModelImplFromJson(
        Map<String, dynamic> json) =>
    _$CashAdvanceModelImpl(
      id: (json['id'] as num).toInt(),
      debtorType: json['debtorType'] as String? ?? 'employee',
      employeeId: (json['employeeId'] as num?)?.toInt(),
      externalPersonName: json['externalPersonName'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'IQD',
      advanceDate: DateTime.parse(json['advanceDate'] as String),
      status: json['status'] as String? ?? 'pending',
      totalRepaid: (json['totalRepaid'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String? ?? '',
      voucherId: (json['voucherId'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CashAdvanceModelImplToJson(
        _$CashAdvanceModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'debtorType': instance.debtorType,
      'employeeId': instance.employeeId,
      'externalPersonName': instance.externalPersonName,
      'amount': instance.amount,
      'currency': instance.currency,
      'advanceDate': instance.advanceDate.toIso8601String(),
      'status': instance.status,
      'totalRepaid': instance.totalRepaid,
      'reason': instance.reason,
      'voucherId': instance.voucherId,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$SalaryPaymentModelImpl _$$SalaryPaymentModelImplFromJson(
        Map<String, dynamic> json) =>
    _$SalaryPaymentModelImpl(
      id: (json['id'] as num).toInt(),
      employeeId: (json['employeeId'] as num).toInt(),
      periodLabel: json['periodLabel'] as String? ?? '',
      basicSalary: (json['basicSalary'] as num?)?.toDouble() ?? 0.0,
      additions: (json['additions'] as num?)?.toDouble() ?? 0.0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      voucherId: (json['voucherId'] as num?)?.toInt(),
      notes: json['notes'] as String? ?? '',
    );

Map<String, dynamic> _$$SalaryPaymentModelImplToJson(
        _$SalaryPaymentModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'employeeId': instance.employeeId,
      'periodLabel': instance.periodLabel,
      'basicSalary': instance.basicSalary,
      'additions': instance.additions,
      'deductions': instance.deductions,
      'netAmount': instance.netAmount,
      'paymentDate': instance.paymentDate.toIso8601String(),
      'voucherId': instance.voucherId,
      'notes': instance.notes,
    };
