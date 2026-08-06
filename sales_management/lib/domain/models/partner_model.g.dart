// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PartnerModelImpl _$$PartnerModelImplFromJson(Map<String, dynamic> json) =>
    _$PartnerModelImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      sharePercentage: (json['sharePercentage'] as num?)?.toDouble() ?? 0.0,
      treasuryId: (json['treasuryId'] as num?)?.toInt(),
      notes: json['notes'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$PartnerModelImplToJson(_$PartnerModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'address': instance.address,
      'sharePercentage': instance.sharePercentage,
      'treasuryId': instance.treasuryId,
      'notes': instance.notes,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
