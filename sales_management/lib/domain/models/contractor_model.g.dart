// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contractor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ContractorModelImpl _$$ContractorModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ContractorModelImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      phone1: json['phone1'] as String? ?? '',
      phone2: json['phone2'] as String? ?? '',
      address: json['address'] as String? ?? '',
      contractorType: json['contractorType'] as String? ?? 'individual',
      treasuryId: (json['treasuryId'] as num?)?.toInt(),
      notes: json['notes'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ContractorModelImplToJson(
        _$ContractorModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone1': instance.phone1,
      'phone2': instance.phone2,
      'address': instance.address,
      'contractorType': instance.contractorType,
      'treasuryId': instance.treasuryId,
      'notes': instance.notes,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
