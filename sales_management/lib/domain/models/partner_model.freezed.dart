// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'partner_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PartnerModel _$PartnerModelFromJson(Map<String, dynamic> json) {
  return _PartnerModel.fromJson(json);
}

/// @nodoc
mixin _$PartnerModel {
  /// المعرّف الفريد
  int get id => throw _privateConstructorUsedError;

  /// اسم الشريك
  String get name => throw _privateConstructorUsedError;

  /// رقم الهاتف
  String get phone => throw _privateConstructorUsedError;

  /// العنوان
  String get address => throw _privateConstructorUsedError;

  /// نسبة الحصة في الشركة (0.0 إلى 100.0)
  double get sharePercentage => throw _privateConstructorUsedError;

  /// معرّف الخزينة الخاصة بالشريك (اختياري)
  int? get treasuryId => throw _privateConstructorUsedError;

  /// ملاحظات
  String get notes => throw _privateConstructorUsedError;

  /// هل الشريك نشط؟
  bool get isActive => throw _privateConstructorUsedError;

  /// تاريخ الإنشاء
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this PartnerModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PartnerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PartnerModelCopyWith<PartnerModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PartnerModelCopyWith<$Res> {
  factory $PartnerModelCopyWith(
          PartnerModel value, $Res Function(PartnerModel) then) =
      _$PartnerModelCopyWithImpl<$Res, PartnerModel>;
  @useResult
  $Res call(
      {int id,
      String name,
      String phone,
      String address,
      double sharePercentage,
      int? treasuryId,
      String notes,
      bool isActive,
      DateTime? createdAt});
}

/// @nodoc
class _$PartnerModelCopyWithImpl<$Res, $Val extends PartnerModel>
    implements $PartnerModelCopyWith<$Res> {
  _$PartnerModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PartnerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? phone = null,
    Object? address = null,
    Object? sharePercentage = null,
    Object? treasuryId = freezed,
    Object? notes = null,
    Object? isActive = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      sharePercentage: null == sharePercentage
          ? _value.sharePercentage
          : sharePercentage // ignore: cast_nullable_to_non_nullable
              as double,
      treasuryId: freezed == treasuryId
          ? _value.treasuryId
          : treasuryId // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PartnerModelImplCopyWith<$Res>
    implements $PartnerModelCopyWith<$Res> {
  factory _$$PartnerModelImplCopyWith(
          _$PartnerModelImpl value, $Res Function(_$PartnerModelImpl) then) =
      __$$PartnerModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String phone,
      String address,
      double sharePercentage,
      int? treasuryId,
      String notes,
      bool isActive,
      DateTime? createdAt});
}

/// @nodoc
class __$$PartnerModelImplCopyWithImpl<$Res>
    extends _$PartnerModelCopyWithImpl<$Res, _$PartnerModelImpl>
    implements _$$PartnerModelImplCopyWith<$Res> {
  __$$PartnerModelImplCopyWithImpl(
      _$PartnerModelImpl _value, $Res Function(_$PartnerModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of PartnerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? phone = null,
    Object? address = null,
    Object? sharePercentage = null,
    Object? treasuryId = freezed,
    Object? notes = null,
    Object? isActive = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$PartnerModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      sharePercentage: null == sharePercentage
          ? _value.sharePercentage
          : sharePercentage // ignore: cast_nullable_to_non_nullable
              as double,
      treasuryId: freezed == treasuryId
          ? _value.treasuryId
          : treasuryId // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PartnerModelImpl implements _PartnerModel {
  const _$PartnerModelImpl(
      {required this.id,
      required this.name,
      this.phone = '',
      this.address = '',
      this.sharePercentage = 0.0,
      this.treasuryId,
      this.notes = '',
      this.isActive = true,
      this.createdAt});

  factory _$PartnerModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PartnerModelImplFromJson(json);

  /// المعرّف الفريد
  @override
  final int id;

  /// اسم الشريك
  @override
  final String name;

  /// رقم الهاتف
  @override
  @JsonKey()
  final String phone;

  /// العنوان
  @override
  @JsonKey()
  final String address;

  /// نسبة الحصة في الشركة (0.0 إلى 100.0)
  @override
  @JsonKey()
  final double sharePercentage;

  /// معرّف الخزينة الخاصة بالشريك (اختياري)
  @override
  final int? treasuryId;

  /// ملاحظات
  @override
  @JsonKey()
  final String notes;

  /// هل الشريك نشط؟
  @override
  @JsonKey()
  final bool isActive;

  /// تاريخ الإنشاء
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'PartnerModel(id: $id, name: $name, phone: $phone, address: $address, sharePercentage: $sharePercentage, treasuryId: $treasuryId, notes: $notes, isActive: $isActive, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PartnerModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.sharePercentage, sharePercentage) ||
                other.sharePercentage == sharePercentage) &&
            (identical(other.treasuryId, treasuryId) ||
                other.treasuryId == treasuryId) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, phone, address,
      sharePercentage, treasuryId, notes, isActive, createdAt);

  /// Create a copy of PartnerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PartnerModelImplCopyWith<_$PartnerModelImpl> get copyWith =>
      __$$PartnerModelImplCopyWithImpl<_$PartnerModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PartnerModelImplToJson(
      this,
    );
  }
}

abstract class _PartnerModel implements PartnerModel {
  const factory _PartnerModel(
      {required final int id,
      required final String name,
      final String phone,
      final String address,
      final double sharePercentage,
      final int? treasuryId,
      final String notes,
      final bool isActive,
      final DateTime? createdAt}) = _$PartnerModelImpl;

  factory _PartnerModel.fromJson(Map<String, dynamic> json) =
      _$PartnerModelImpl.fromJson;

  /// المعرّف الفريد
  @override
  int get id;

  /// اسم الشريك
  @override
  String get name;

  /// رقم الهاتف
  @override
  String get phone;

  /// العنوان
  @override
  String get address;

  /// نسبة الحصة في الشركة (0.0 إلى 100.0)
  @override
  double get sharePercentage;

  /// معرّف الخزينة الخاصة بالشريك (اختياري)
  @override
  int? get treasuryId;

  /// ملاحظات
  @override
  String get notes;

  /// هل الشريك نشط؟
  @override
  bool get isActive;

  /// تاريخ الإنشاء
  @override
  DateTime? get createdAt;

  /// Create a copy of PartnerModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PartnerModelImplCopyWith<_$PartnerModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
