// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fiscal_period_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FiscalPeriodModel _$FiscalPeriodModelFromJson(Map<String, dynamic> json) {
  return _FiscalPeriodModel.fromJson(json);
}

/// @nodoc
mixin _$FiscalPeriodModel {
  /// المعرّف الفريد
  int get id => throw _privateConstructorUsedError;

  /// اسم الفترة (مثال: '2025', 'Q1 2025')
  String get name => throw _privateConstructorUsedError;

  /// نوع الفترة: 'annual' | 'quarterly' | 'monthly'
  String get periodType => throw _privateConstructorUsedError;

  /// تاريخ بداية الفترة
  DateTime get startDate => throw _privateConstructorUsedError;

  /// تاريخ نهاية الفترة
  DateTime get endDate => throw _privateConstructorUsedError;

  /// الحالة: 'active' | 'frozen' | 'frozen_pending_recompute'
  String get status => throw _privateConstructorUsedError;

  /// وقت الإقفال (null إذا لم تُقفَل بعد)
  DateTime? get closedAt => throw _privateConstructorUsedError;

  /// معرّف المستخدم الذي أقفل الفترة
  int? get closedByUserId => throw _privateConstructorUsedError;

  /// ملاحظات الإقفال
  String get notes => throw _privateConstructorUsedError;

  /// Serializes this FiscalPeriodModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FiscalPeriodModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FiscalPeriodModelCopyWith<FiscalPeriodModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FiscalPeriodModelCopyWith<$Res> {
  factory $FiscalPeriodModelCopyWith(
          FiscalPeriodModel value, $Res Function(FiscalPeriodModel) then) =
      _$FiscalPeriodModelCopyWithImpl<$Res, FiscalPeriodModel>;
  @useResult
  $Res call(
      {int id,
      String name,
      String periodType,
      DateTime startDate,
      DateTime endDate,
      String status,
      DateTime? closedAt,
      int? closedByUserId,
      String notes});
}

/// @nodoc
class _$FiscalPeriodModelCopyWithImpl<$Res, $Val extends FiscalPeriodModel>
    implements $FiscalPeriodModelCopyWith<$Res> {
  _$FiscalPeriodModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FiscalPeriodModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? periodType = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? status = null,
    Object? closedAt = freezed,
    Object? closedByUserId = freezed,
    Object? notes = null,
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
      periodType: null == periodType
          ? _value.periodType
          : periodType // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      closedAt: freezed == closedAt
          ? _value.closedAt
          : closedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      closedByUserId: freezed == closedByUserId
          ? _value.closedByUserId
          : closedByUserId // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FiscalPeriodModelImplCopyWith<$Res>
    implements $FiscalPeriodModelCopyWith<$Res> {
  factory _$$FiscalPeriodModelImplCopyWith(_$FiscalPeriodModelImpl value,
          $Res Function(_$FiscalPeriodModelImpl) then) =
      __$$FiscalPeriodModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String periodType,
      DateTime startDate,
      DateTime endDate,
      String status,
      DateTime? closedAt,
      int? closedByUserId,
      String notes});
}

/// @nodoc
class __$$FiscalPeriodModelImplCopyWithImpl<$Res>
    extends _$FiscalPeriodModelCopyWithImpl<$Res, _$FiscalPeriodModelImpl>
    implements _$$FiscalPeriodModelImplCopyWith<$Res> {
  __$$FiscalPeriodModelImplCopyWithImpl(_$FiscalPeriodModelImpl _value,
      $Res Function(_$FiscalPeriodModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of FiscalPeriodModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? periodType = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? status = null,
    Object? closedAt = freezed,
    Object? closedByUserId = freezed,
    Object? notes = null,
  }) {
    return _then(_$FiscalPeriodModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      periodType: null == periodType
          ? _value.periodType
          : periodType // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      closedAt: freezed == closedAt
          ? _value.closedAt
          : closedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      closedByUserId: freezed == closedByUserId
          ? _value.closedByUserId
          : closedByUserId // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FiscalPeriodModelImpl implements _FiscalPeriodModel {
  const _$FiscalPeriodModelImpl(
      {required this.id,
      required this.name,
      this.periodType = 'annual',
      required this.startDate,
      required this.endDate,
      this.status = 'active',
      this.closedAt,
      this.closedByUserId,
      this.notes = ''});

  factory _$FiscalPeriodModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FiscalPeriodModelImplFromJson(json);

  /// المعرّف الفريد
  @override
  final int id;

  /// اسم الفترة (مثال: '2025', 'Q1 2025')
  @override
  final String name;

  /// نوع الفترة: 'annual' | 'quarterly' | 'monthly'
  @override
  @JsonKey()
  final String periodType;

  /// تاريخ بداية الفترة
  @override
  final DateTime startDate;

  /// تاريخ نهاية الفترة
  @override
  final DateTime endDate;

  /// الحالة: 'active' | 'frozen' | 'frozen_pending_recompute'
  @override
  @JsonKey()
  final String status;

  /// وقت الإقفال (null إذا لم تُقفَل بعد)
  @override
  final DateTime? closedAt;

  /// معرّف المستخدم الذي أقفل الفترة
  @override
  final int? closedByUserId;

  /// ملاحظات الإقفال
  @override
  @JsonKey()
  final String notes;

  @override
  String toString() {
    return 'FiscalPeriodModel(id: $id, name: $name, periodType: $periodType, startDate: $startDate, endDate: $endDate, status: $status, closedAt: $closedAt, closedByUserId: $closedByUserId, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FiscalPeriodModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.periodType, periodType) ||
                other.periodType == periodType) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.closedAt, closedAt) ||
                other.closedAt == closedAt) &&
            (identical(other.closedByUserId, closedByUserId) ||
                other.closedByUserId == closedByUserId) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, periodType, startDate,
      endDate, status, closedAt, closedByUserId, notes);

  /// Create a copy of FiscalPeriodModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FiscalPeriodModelImplCopyWith<_$FiscalPeriodModelImpl> get copyWith =>
      __$$FiscalPeriodModelImplCopyWithImpl<_$FiscalPeriodModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FiscalPeriodModelImplToJson(
      this,
    );
  }
}

abstract class _FiscalPeriodModel implements FiscalPeriodModel {
  const factory _FiscalPeriodModel(
      {required final int id,
      required final String name,
      final String periodType,
      required final DateTime startDate,
      required final DateTime endDate,
      final String status,
      final DateTime? closedAt,
      final int? closedByUserId,
      final String notes}) = _$FiscalPeriodModelImpl;

  factory _FiscalPeriodModel.fromJson(Map<String, dynamic> json) =
      _$FiscalPeriodModelImpl.fromJson;

  /// المعرّف الفريد
  @override
  int get id;

  /// اسم الفترة (مثال: '2025', 'Q1 2025')
  @override
  String get name;

  /// نوع الفترة: 'annual' | 'quarterly' | 'monthly'
  @override
  String get periodType;

  /// تاريخ بداية الفترة
  @override
  DateTime get startDate;

  /// تاريخ نهاية الفترة
  @override
  DateTime get endDate;

  /// الحالة: 'active' | 'frozen' | 'frozen_pending_recompute'
  @override
  String get status;

  /// وقت الإقفال (null إذا لم تُقفَل بعد)
  @override
  DateTime? get closedAt;

  /// معرّف المستخدم الذي أقفل الفترة
  @override
  int? get closedByUserId;

  /// ملاحظات الإقفال
  @override
  String get notes;

  /// Create a copy of FiscalPeriodModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FiscalPeriodModelImplCopyWith<_$FiscalPeriodModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
