// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'advance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AdvanceModelImpl _$$AdvanceModelImplFromJson(Map<String, dynamic> json) =>
    _$AdvanceModelImpl(
      id: (json['id'] as num).toInt(),
      advanceNumber: json['advanceNumber'] as String,
      projectTreasuryId: (json['projectTreasuryId'] as num).toInt(),
      fiscalPeriodId: (json['fiscalPeriodId'] as num).toInt(),
      projectName: json['projectName'] as String? ?? '',
      advanceDate: DateTime.parse(json['advanceDate'] as String),
      status: json['status'] as String? ?? AdvanceStatus.open,
      excelTotal: (json['excelTotal'] as num?)?.toDouble() ?? 0.0,
      sourceFileName: json['sourceFileName'] as String? ?? '',
      sourceFileHash: json['sourceFileHash'] as String? ?? '',
      deficitAmount: (json['deficitAmount'] as num?)?.toDouble() ?? 0.0,
      deficitCoveredBy: json['deficitCoveredBy'] as String?,
      notes: json['notes'] as String? ?? '',
      createdByUserId: (json['createdByUserId'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      postedByUserId: (json['postedByUserId'] as num?)?.toInt(),
      postedAt: json['postedAt'] == null
          ? null
          : DateTime.parse(json['postedAt'] as String),
      cancelledByUserId: (json['cancelledByUserId'] as num?)?.toInt(),
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
    );

Map<String, dynamic> _$$AdvanceModelImplToJson(_$AdvanceModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'advanceNumber': instance.advanceNumber,
      'projectTreasuryId': instance.projectTreasuryId,
      'fiscalPeriodId': instance.fiscalPeriodId,
      'projectName': instance.projectName,
      'advanceDate': instance.advanceDate.toIso8601String(),
      'status': instance.status,
      'excelTotal': instance.excelTotal,
      'sourceFileName': instance.sourceFileName,
      'sourceFileHash': instance.sourceFileHash,
      'deficitAmount': instance.deficitAmount,
      'deficitCoveredBy': instance.deficitCoveredBy,
      'notes': instance.notes,
      'createdByUserId': instance.createdByUserId,
      'createdAt': instance.createdAt.toIso8601String(),
      'postedByUserId': instance.postedByUserId,
      'postedAt': instance.postedAt?.toIso8601String(),
      'cancelledByUserId': instance.cancelledByUserId,
      'cancelledAt': instance.cancelledAt?.toIso8601String(),
    };

_$AdvanceLineModelImpl _$$AdvanceLineModelImplFromJson(
        Map<String, dynamic> json) =>
    _$AdvanceLineModelImpl(
      id: (json['id'] as num).toInt(),
      advanceId: (json['advanceId'] as num).toInt(),
      rowNumber: (json['rowNumber'] as num?)?.toInt() ?? 0,
      voucherDate: DateTime.parse(json['voucherDate'] as String),
      amount: (json['amount'] as num).toDouble(),
      itemType: json['itemType'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      personName: json['personName'] as String? ?? '',
      projectName: json['projectName'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      spentBy: json['spentBy'] as String?,
      originalAmount: (json['originalAmount'] as num).toDouble(),
      originalItemType: json['originalItemType'] as String? ?? '',
      originalDate: DateTime.parse(json['originalDate'] as String),
      isEdited: json['isEdited'] as bool? ?? false,
      isExcluded: json['isExcluded'] as bool? ?? false,
      excludeReason: json['excludeReason'] as String? ?? '',
      voucherId: (json['voucherId'] as num?)?.toInt(),
      payrollPeriodId: (json['payrollPeriodId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$AdvanceLineModelImplToJson(
        _$AdvanceLineModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'advanceId': instance.advanceId,
      'rowNumber': instance.rowNumber,
      'voucherDate': instance.voucherDate.toIso8601String(),
      'amount': instance.amount,
      'itemType': instance.itemType,
      'reason': instance.reason,
      'personName': instance.personName,
      'projectName': instance.projectName,
      'invoiceNumber': instance.invoiceNumber,
      'spentBy': instance.spentBy,
      'originalAmount': instance.originalAmount,
      'originalItemType': instance.originalItemType,
      'originalDate': instance.originalDate.toIso8601String(),
      'isEdited': instance.isEdited,
      'isExcluded': instance.isExcluded,
      'excludeReason': instance.excludeReason,
      'voucherId': instance.voucherId,
      'payrollPeriodId': instance.payrollPeriodId,
    };

_$AdvanceSummaryImpl _$$AdvanceSummaryImplFromJson(Map<String, dynamic> json) =>
    _$AdvanceSummaryImpl(
      sent: (json['sent'] as num?)?.toDouble() ?? 0.0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
      excelTotal: (json['excelTotal'] as num?)?.toDouble() ?? 0.0,
      treasuryBalance: (json['treasuryBalance'] as num?)?.toDouble() ?? 0.0,
      countedLines: (json['countedLines'] as num?)?.toInt() ?? 0,
      excludedLines: (json['excludedLines'] as num?)?.toInt() ?? 0,
      editedLines: (json['editedLines'] as num?)?.toInt() ?? 0,
      isPosted: json['isPosted'] as bool? ?? false,
      postedDeficit: (json['postedDeficit'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$AdvanceSummaryImplToJson(
        _$AdvanceSummaryImpl instance) =>
    <String, dynamic>{
      'sent': instance.sent,
      'spent': instance.spent,
      'excelTotal': instance.excelTotal,
      'treasuryBalance': instance.treasuryBalance,
      'countedLines': instance.countedLines,
      'excludedLines': instance.excludedLines,
      'editedLines': instance.editedLines,
      'isPosted': instance.isPosted,
      'postedDeficit': instance.postedDeficit,
    };
