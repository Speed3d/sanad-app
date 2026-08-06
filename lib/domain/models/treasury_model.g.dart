// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'treasury_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TreasuryModelImpl _$$TreasuryModelImplFromJson(Map<String, dynamic> json) =>
    _$TreasuryModelImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      kind: json['kind'] as String,
      entityId: (json['entityId'] as num?)?.toInt(),
      entityType: json['entityType'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );

Map<String, dynamic> _$$TreasuryModelImplToJson(_$TreasuryModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'kind': instance.kind,
      'entityId': instance.entityId,
      'entityType': instance.entityType,
      'isActive': instance.isActive,
      'isDeleted': instance.isDeleted,
    };

_$TreasuryBalanceModelImpl _$$TreasuryBalanceModelImplFromJson(
        Map<String, dynamic> json) =>
    _$TreasuryBalanceModelImpl(
      treasuryId: (json['treasuryId'] as num).toInt(),
      treasuryName: json['treasuryName'] as String,
      treasuryKind: json['treasuryKind'] as String,
      entityId: (json['entityId'] as num?)?.toInt(),
      entityType: json['entityType'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      balanceIqd: (json['balanceIqd'] as num?)?.toDouble() ?? 0.0,
      balanceUsd: (json['balanceUsd'] as num?)?.toDouble() ?? 0.0,
      totalVouchers: (json['totalVouchers'] as num?)?.toInt() ?? 0,
      lastVoucherDate: json['lastVoucherDate'] == null
          ? null
          : DateTime.parse(json['lastVoucherDate'] as String),
    );

Map<String, dynamic> _$$TreasuryBalanceModelImplToJson(
        _$TreasuryBalanceModelImpl instance) =>
    <String, dynamic>{
      'treasuryId': instance.treasuryId,
      'treasuryName': instance.treasuryName,
      'treasuryKind': instance.treasuryKind,
      'entityId': instance.entityId,
      'entityType': instance.entityType,
      'isActive': instance.isActive,
      'balanceIqd': instance.balanceIqd,
      'balanceUsd': instance.balanceUsd,
      'totalVouchers': instance.totalVouchers,
      'lastVoucherDate': instance.lastVoucherDate?.toIso8601String(),
    };
