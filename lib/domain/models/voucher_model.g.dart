// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voucher_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VoucherModelImpl _$$VoucherModelImplFromJson(Map<String, dynamic> json) =>
    _$VoucherModelImpl(
      id: (json['id'] as num).toInt(),
      voucherNumber: (json['voucherNumber'] as num).toInt(),
      voucherType: json['voucherType'] as String,
      treasuryId: (json['treasuryId'] as num).toInt(),
      fiscalPeriodId: (json['fiscalPeriodId'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble() ?? 1.0,
      voucherDate: DateTime.parse(json['voucherDate'] as String),
      personName: json['personName'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      itemType: json['itemType'] as String? ?? '',
      referenceNumber: json['referenceNumber'] as String? ?? '',
      closeSafe: json['closeSafe'] as bool? ?? false,
      linkedTreasuryId: (json['linkedTreasuryId'] as num?)?.toInt(),
      linkedEntityId: (json['linkedEntityId'] as num?)?.toInt(),
      projectName: json['projectName'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      spentBy: json['spentBy'] as String?,
      advanceNumber: json['advanceNumber'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );

Map<String, dynamic> _$$VoucherModelImplToJson(_$VoucherModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'voucherNumber': instance.voucherNumber,
      'voucherType': instance.voucherType,
      'treasuryId': instance.treasuryId,
      'fiscalPeriodId': instance.fiscalPeriodId,
      'amount': instance.amount,
      'currency': instance.currency,
      'exchangeRate': instance.exchangeRate,
      'voucherDate': instance.voucherDate.toIso8601String(),
      'personName': instance.personName,
      'reason': instance.reason,
      'itemType': instance.itemType,
      'referenceNumber': instance.referenceNumber,
      'closeSafe': instance.closeSafe,
      'linkedTreasuryId': instance.linkedTreasuryId,
      'linkedEntityId': instance.linkedEntityId,
      'projectName': instance.projectName,
      'invoiceNumber': instance.invoiceNumber,
      'spentBy': instance.spentBy,
      'advanceNumber': instance.advanceNumber,
      'isDeleted': instance.isDeleted,
      'deletedAt': instance.deletedAt?.toIso8601String(),
    };

_$AccountStatementModelImpl _$$AccountStatementModelImplFromJson(
        Map<String, dynamic> json) =>
    _$AccountStatementModelImpl(
      voucher: VoucherModel.fromJson(json['voucher'] as Map<String, dynamic>),
      runningBalanceIqd: (json['runningBalanceIqd'] as num).toDouble(),
      runningBalanceUsd: (json['runningBalanceUsd'] as num).toDouble(),
    );

Map<String, dynamic> _$$AccountStatementModelImplToJson(
        _$AccountStatementModelImpl instance) =>
    <String, dynamic>{
      'voucher': instance.voucher,
      'runningBalanceIqd': instance.runningBalanceIqd,
      'runningBalanceUsd': instance.runningBalanceUsd,
    };
