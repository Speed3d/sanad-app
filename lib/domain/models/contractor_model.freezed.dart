// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contractor_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ContractorModel _$ContractorModelFromJson(Map<String, dynamic> json) {
  return _ContractorModel.fromJson(json);
}

/// @nodoc
mixin _$ContractorModel {
  /// المعرّف الفريد
  int get id => throw _privateConstructorUsedError;

  /// اسم المقاول أو الشركة
  String get name => throw _privateConstructorUsedError;

  /// رقم الهاتف الأول
  String get phone1 => throw _privateConstructorUsedError;

  /// رقم الهاتف الثاني (اختياري)
  String get phone2 => throw _privateConstructorUsedError;

  /// العنوان
  String get address => throw _privateConstructorUsedError;

  /// نوع المقاول: 'individual' | 'company'
  String get contractorType => throw _privateConstructorUsedError;

  /// معرّف الخزينة الخاصة بالمقاول (اختياري)
  int? get treasuryId => throw _privateConstructorUsedError;

  /// ملاحظات
  String get notes => throw _privateConstructorUsedError;

  /// هل المقاول نشط؟
  bool get isActive => throw _privateConstructorUsedError;

  /// تاريخ الإنشاء
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ContractorModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ContractorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContractorModelCopyWith<ContractorModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContractorModelCopyWith<$Res> {
  factory $ContractorModelCopyWith(
          ContractorModel value, $Res Function(ContractorModel) then) =
      _$ContractorModelCopyWithImpl<$Res, ContractorModel>;
  @useResult
  $Res call(
      {int id,
      String name,
      String phone1,
      String phone2,
      String address,
      String contractorType,
      int? treasuryId,
      String notes,
      bool isActive,
      DateTime? createdAt});
}

/// @nodoc
class _$ContractorModelCopyWithImpl<$Res, $Val extends ContractorModel>
    implements $ContractorModelCopyWith<$Res> {
  _$ContractorModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContractorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? phone1 = null,
    Object? phone2 = null,
    Object? address = null,
    Object? contractorType = null,
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
      phone1: null == phone1
          ? _value.phone1
          : phone1 // ignore: cast_nullable_to_non_nullable
              as String,
      phone2: null == phone2
          ? _value.phone2
          : phone2 // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      contractorType: null == contractorType
          ? _value.contractorType
          : contractorType // ignore: cast_nullable_to_non_nullable
              as String,
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
abstract class _$$ContractorModelImplCopyWith<$Res>
    implements $ContractorModelCopyWith<$Res> {
  factory _$$ContractorModelImplCopyWith(_$ContractorModelImpl value,
          $Res Function(_$ContractorModelImpl) then) =
      __$$ContractorModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String phone1,
      String phone2,
      String address,
      String contractorType,
      int? treasuryId,
      String notes,
      bool isActive,
      DateTime? createdAt});
}

/// @nodoc
class __$$ContractorModelImplCopyWithImpl<$Res>
    extends _$ContractorModelCopyWithImpl<$Res, _$ContractorModelImpl>
    implements _$$ContractorModelImplCopyWith<$Res> {
  __$$ContractorModelImplCopyWithImpl(
      _$ContractorModelImpl _value, $Res Function(_$ContractorModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ContractorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? phone1 = null,
    Object? phone2 = null,
    Object? address = null,
    Object? contractorType = null,
    Object? treasuryId = freezed,
    Object? notes = null,
    Object? isActive = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$ContractorModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone1: null == phone1
          ? _value.phone1
          : phone1 // ignore: cast_nullable_to_non_nullable
              as String,
      phone2: null == phone2
          ? _value.phone2
          : phone2 // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      contractorType: null == contractorType
          ? _value.contractorType
          : contractorType // ignore: cast_nullable_to_non_nullable
              as String,
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
class _$ContractorModelImpl implements _ContractorModel {
  const _$ContractorModelImpl(
      {required this.id,
      required this.name,
      this.phone1 = '',
      this.phone2 = '',
      this.address = '',
      this.contractorType = 'individual',
      this.treasuryId,
      this.notes = '',
      this.isActive = true,
      this.createdAt});

  factory _$ContractorModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ContractorModelImplFromJson(json);

  /// المعرّف الفريد
  @override
  final int id;

  /// اسم المقاول أو الشركة
  @override
  final String name;

  /// رقم الهاتف الأول
  @override
  @JsonKey()
  final String phone1;

  /// رقم الهاتف الثاني (اختياري)
  @override
  @JsonKey()
  final String phone2;

  /// العنوان
  @override
  @JsonKey()
  final String address;

  /// نوع المقاول: 'individual' | 'company'
  @override
  @JsonKey()
  final String contractorType;

  /// معرّف الخزينة الخاصة بالمقاول (اختياري)
  @override
  final int? treasuryId;

  /// ملاحظات
  @override
  @JsonKey()
  final String notes;

  /// هل المقاول نشط؟
  @override
  @JsonKey()
  final bool isActive;

  /// تاريخ الإنشاء
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ContractorModel(id: $id, name: $name, phone1: $phone1, phone2: $phone2, address: $address, contractorType: $contractorType, treasuryId: $treasuryId, notes: $notes, isActive: $isActive, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContractorModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone1, phone1) || other.phone1 == phone1) &&
            (identical(other.phone2, phone2) || other.phone2 == phone2) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.contractorType, contractorType) ||
                other.contractorType == contractorType) &&
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
  int get hashCode => Object.hash(runtimeType, id, name, phone1, phone2,
      address, contractorType, treasuryId, notes, isActive, createdAt);

  /// Create a copy of ContractorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContractorModelImplCopyWith<_$ContractorModelImpl> get copyWith =>
      __$$ContractorModelImplCopyWithImpl<_$ContractorModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ContractorModelImplToJson(
      this,
    );
  }
}

abstract class _ContractorModel implements ContractorModel {
  const factory _ContractorModel(
      {required final int id,
      required final String name,
      final String phone1,
      final String phone2,
      final String address,
      final String contractorType,
      final int? treasuryId,
      final String notes,
      final bool isActive,
      final DateTime? createdAt}) = _$ContractorModelImpl;

  factory _ContractorModel.fromJson(Map<String, dynamic> json) =
      _$ContractorModelImpl.fromJson;

  /// المعرّف الفريد
  @override
  int get id;

  /// اسم المقاول أو الشركة
  @override
  String get name;

  /// رقم الهاتف الأول
  @override
  String get phone1;

  /// رقم الهاتف الثاني (اختياري)
  @override
  String get phone2;

  /// العنوان
  @override
  String get address;

  /// نوع المقاول: 'individual' | 'company'
  @override
  String get contractorType;

  /// معرّف الخزينة الخاصة بالمقاول (اختياري)
  @override
  int? get treasuryId;

  /// ملاحظات
  @override
  String get notes;

  /// هل المقاول نشط؟
  @override
  bool get isActive;

  /// تاريخ الإنشاء
  @override
  DateTime? get createdAt;

  /// Create a copy of ContractorModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContractorModelImplCopyWith<_$ContractorModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
