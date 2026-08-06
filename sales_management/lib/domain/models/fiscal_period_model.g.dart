// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fiscal_period_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FiscalPeriodModelImpl _$$FiscalPeriodModelImplFromJson(
        Map<String, dynamic> json) =>
    _$FiscalPeriodModelImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      periodType: json['periodType'] as String? ?? 'annual',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: json['status'] as String? ?? 'active',
      closedAt: json['closedAt'] == null
          ? null
          : DateTime.parse(json['closedAt'] as String),
      closedByUserId: (json['closedByUserId'] as num?)?.toInt(),
      notes: json['notes'] as String? ?? '',
    );

Map<String, dynamic> _$$FiscalPeriodModelImplToJson(
        _$FiscalPeriodModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'periodType': instance.periodType,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'status': instance.status,
      'closedAt': instance.closedAt?.toIso8601String(),
      'closedByUserId': instance.closedByUserId,
      'notes': instance.notes,
    };
