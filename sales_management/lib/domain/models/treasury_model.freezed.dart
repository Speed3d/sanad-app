// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'treasury_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TreasuryModel _$TreasuryModelFromJson(Map<String, dynamic> json) {
  return _TreasuryModel.fromJson(json);
}

/// @nodoc
mixin _$TreasuryModel {
  /// المعرّف الفريد
  int get id => throw _privateConstructorUsedError;

  /// اسم الخزينة كما يظهر في الواجهة
  String get name => throw _privateConstructorUsedError;

  /// نوع الخزينة: 'main' | 'contractor' | 'partner'
  String get kind => throw _privateConstructorUsedError;

  /// معرّف الكيان المرتبط (موظف / مقاول / شريك)
  int? get entityId => throw _privateConstructorUsedError;

  /// نوع الكيان: 'employee' | 'contractor' | 'partner'
  String? get entityType => throw _privateConstructorUsedError;

  /// هل الخزينة نشطة؟
  bool get isActive => throw _privateConstructorUsedError;

  /// هل تم حذفها ناعماً؟
  bool get isDeleted => throw _privateConstructorUsedError;

  /// Serializes this TreasuryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TreasuryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TreasuryModelCopyWith<TreasuryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TreasuryModelCopyWith<$Res> {
  factory $TreasuryModelCopyWith(
          TreasuryModel value, $Res Function(TreasuryModel) then) =
      _$TreasuryModelCopyWithImpl<$Res, TreasuryModel>;
  @useResult
  $Res call(
      {int id,
      String name,
      String kind,
      int? entityId,
      String? entityType,
      bool isActive,
      bool isDeleted});
}

/// @nodoc
class _$TreasuryModelCopyWithImpl<$Res, $Val extends TreasuryModel>
    implements $TreasuryModelCopyWith<$Res> {
  _$TreasuryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TreasuryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? kind = null,
    Object? entityId = freezed,
    Object? entityType = freezed,
    Object? isActive = null,
    Object? isDeleted = null,
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      entityId: freezed == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as int?,
      entityType: freezed == entityType
          ? _value.entityType
          : entityType // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TreasuryModelImplCopyWith<$Res>
    implements $TreasuryModelCopyWith<$Res> {
  factory _$$TreasuryModelImplCopyWith(
          _$TreasuryModelImpl value, $Res Function(_$TreasuryModelImpl) then) =
      __$$TreasuryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String kind,
      int? entityId,
      String? entityType,
      bool isActive,
      bool isDeleted});
}

/// @nodoc
class __$$TreasuryModelImplCopyWithImpl<$Res>
    extends _$TreasuryModelCopyWithImpl<$Res, _$TreasuryModelImpl>
    implements _$$TreasuryModelImplCopyWith<$Res> {
  __$$TreasuryModelImplCopyWithImpl(
      _$TreasuryModelImpl _value, $Res Function(_$TreasuryModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of TreasuryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? kind = null,
    Object? entityId = freezed,
    Object? entityType = freezed,
    Object? isActive = null,
    Object? isDeleted = null,
  }) {
    return _then(_$TreasuryModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      entityId: freezed == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as int?,
      entityType: freezed == entityType
          ? _value.entityType
          : entityType // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TreasuryModelImpl implements _TreasuryModel {
  const _$TreasuryModelImpl(
      {required this.id,
      required this.name,
      required this.kind,
      this.entityId,
      this.entityType,
      this.isActive = true,
      this.isDeleted = false});

  factory _$TreasuryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TreasuryModelImplFromJson(json);

  /// المعرّف الفريد
  @override
  final int id;

  /// اسم الخزينة كما يظهر في الواجهة
  @override
  final String name;

  /// نوع الخزينة: 'main' | 'contractor' | 'partner'
  @override
  final String kind;

  /// معرّف الكيان المرتبط (موظف / مقاول / شريك)
  @override
  final int? entityId;

  /// نوع الكيان: 'employee' | 'contractor' | 'partner'
  @override
  final String? entityType;

  /// هل الخزينة نشطة؟
  @override
  @JsonKey()
  final bool isActive;

  /// هل تم حذفها ناعماً؟
  @override
  @JsonKey()
  final bool isDeleted;

  @override
  String toString() {
    return 'TreasuryModel(id: $id, name: $name, kind: $kind, entityId: $entityId, entityType: $entityType, isActive: $isActive, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TreasuryModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.entityType, entityType) ||
                other.entityType == entityType) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, kind, entityId, entityType, isActive, isDeleted);

  /// Create a copy of TreasuryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TreasuryModelImplCopyWith<_$TreasuryModelImpl> get copyWith =>
      __$$TreasuryModelImplCopyWithImpl<_$TreasuryModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TreasuryModelImplToJson(
      this,
    );
  }
}

abstract class _TreasuryModel implements TreasuryModel {
  const factory _TreasuryModel(
      {required final int id,
      required final String name,
      required final String kind,
      final int? entityId,
      final String? entityType,
      final bool isActive,
      final bool isDeleted}) = _$TreasuryModelImpl;

  factory _TreasuryModel.fromJson(Map<String, dynamic> json) =
      _$TreasuryModelImpl.fromJson;

  /// المعرّف الفريد
  @override
  int get id;

  /// اسم الخزينة كما يظهر في الواجهة
  @override
  String get name;

  /// نوع الخزينة: 'main' | 'contractor' | 'partner'
  @override
  String get kind;

  /// معرّف الكيان المرتبط (موظف / مقاول / شريك)
  @override
  int? get entityId;

  /// نوع الكيان: 'employee' | 'contractor' | 'partner'
  @override
  String? get entityType;

  /// هل الخزينة نشطة؟
  @override
  bool get isActive;

  /// هل تم حذفها ناعماً؟
  @override
  bool get isDeleted;

  /// Create a copy of TreasuryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TreasuryModelImplCopyWith<_$TreasuryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TreasuryBalanceModel _$TreasuryBalanceModelFromJson(Map<String, dynamic> json) {
  return _TreasuryBalanceModel.fromJson(json);
}

/// @nodoc
mixin _$TreasuryBalanceModel {
  /// معرّف الخزينة
  int get treasuryId => throw _privateConstructorUsedError;

  /// اسم الخزينة
  String get treasuryName => throw _privateConstructorUsedError;

  /// نوع الخزينة: 'main' | 'contractor' | 'partner'
  String get treasuryKind => throw _privateConstructorUsedError;

  /// معرّف الكيان المرتبط (اختياري)
  int? get entityId => throw _privateConstructorUsedError;

  /// نوع الكيان المرتبط (اختياري)
  String? get entityType => throw _privateConstructorUsedError;

  /// هل الخزينة نشطة؟
  bool get isActive => throw _privateConstructorUsedError;

  /// الرصيد بالدينار العراقي — يمكن أن يكون سالباً
  double get balanceIqd => throw _privateConstructorUsedError;

  /// الرصيد بالدولار الأمريكي
  double get balanceUsd => throw _privateConstructorUsedError;

  /// إجمالي عدد السندات في هذه الخزينة
  int get totalVouchers => throw _privateConstructorUsedError;

  /// تاريخ آخر سند (null = لا توجد سندات)
  DateTime? get lastVoucherDate => throw _privateConstructorUsedError;

  /// Serializes this TreasuryBalanceModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TreasuryBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TreasuryBalanceModelCopyWith<TreasuryBalanceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TreasuryBalanceModelCopyWith<$Res> {
  factory $TreasuryBalanceModelCopyWith(TreasuryBalanceModel value,
          $Res Function(TreasuryBalanceModel) then) =
      _$TreasuryBalanceModelCopyWithImpl<$Res, TreasuryBalanceModel>;
  @useResult
  $Res call(
      {int treasuryId,
      String treasuryName,
      String treasuryKind,
      int? entityId,
      String? entityType,
      bool isActive,
      double balanceIqd,
      double balanceUsd,
      int totalVouchers,
      DateTime? lastVoucherDate});
}

/// @nodoc
class _$TreasuryBalanceModelCopyWithImpl<$Res,
        $Val extends TreasuryBalanceModel>
    implements $TreasuryBalanceModelCopyWith<$Res> {
  _$TreasuryBalanceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TreasuryBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? treasuryId = null,
    Object? treasuryName = null,
    Object? treasuryKind = null,
    Object? entityId = freezed,
    Object? entityType = freezed,
    Object? isActive = null,
    Object? balanceIqd = null,
    Object? balanceUsd = null,
    Object? totalVouchers = null,
    Object? lastVoucherDate = freezed,
  }) {
    return _then(_value.copyWith(
      treasuryId: null == treasuryId
          ? _value.treasuryId
          : treasuryId // ignore: cast_nullable_to_non_nullable
              as int,
      treasuryName: null == treasuryName
          ? _value.treasuryName
          : treasuryName // ignore: cast_nullable_to_non_nullable
              as String,
      treasuryKind: null == treasuryKind
          ? _value.treasuryKind
          : treasuryKind // ignore: cast_nullable_to_non_nullable
              as String,
      entityId: freezed == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as int?,
      entityType: freezed == entityType
          ? _value.entityType
          : entityType // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      balanceIqd: null == balanceIqd
          ? _value.balanceIqd
          : balanceIqd // ignore: cast_nullable_to_non_nullable
              as double,
      balanceUsd: null == balanceUsd
          ? _value.balanceUsd
          : balanceUsd // ignore: cast_nullable_to_non_nullable
              as double,
      totalVouchers: null == totalVouchers
          ? _value.totalVouchers
          : totalVouchers // ignore: cast_nullable_to_non_nullable
              as int,
      lastVoucherDate: freezed == lastVoucherDate
          ? _value.lastVoucherDate
          : lastVoucherDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TreasuryBalanceModelImplCopyWith<$Res>
    implements $TreasuryBalanceModelCopyWith<$Res> {
  factory _$$TreasuryBalanceModelImplCopyWith(_$TreasuryBalanceModelImpl value,
          $Res Function(_$TreasuryBalanceModelImpl) then) =
      __$$TreasuryBalanceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int treasuryId,
      String treasuryName,
      String treasuryKind,
      int? entityId,
      String? entityType,
      bool isActive,
      double balanceIqd,
      double balanceUsd,
      int totalVouchers,
      DateTime? lastVoucherDate});
}

/// @nodoc
class __$$TreasuryBalanceModelImplCopyWithImpl<$Res>
    extends _$TreasuryBalanceModelCopyWithImpl<$Res, _$TreasuryBalanceModelImpl>
    implements _$$TreasuryBalanceModelImplCopyWith<$Res> {
  __$$TreasuryBalanceModelImplCopyWithImpl(_$TreasuryBalanceModelImpl _value,
      $Res Function(_$TreasuryBalanceModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of TreasuryBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? treasuryId = null,
    Object? treasuryName = null,
    Object? treasuryKind = null,
    Object? entityId = freezed,
    Object? entityType = freezed,
    Object? isActive = null,
    Object? balanceIqd = null,
    Object? balanceUsd = null,
    Object? totalVouchers = null,
    Object? lastVoucherDate = freezed,
  }) {
    return _then(_$TreasuryBalanceModelImpl(
      treasuryId: null == treasuryId
          ? _value.treasuryId
          : treasuryId // ignore: cast_nullable_to_non_nullable
              as int,
      treasuryName: null == treasuryName
          ? _value.treasuryName
          : treasuryName // ignore: cast_nullable_to_non_nullable
              as String,
      treasuryKind: null == treasuryKind
          ? _value.treasuryKind
          : treasuryKind // ignore: cast_nullable_to_non_nullable
              as String,
      entityId: freezed == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as int?,
      entityType: freezed == entityType
          ? _value.entityType
          : entityType // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      balanceIqd: null == balanceIqd
          ? _value.balanceIqd
          : balanceIqd // ignore: cast_nullable_to_non_nullable
              as double,
      balanceUsd: null == balanceUsd
          ? _value.balanceUsd
          : balanceUsd // ignore: cast_nullable_to_non_nullable
              as double,
      totalVouchers: null == totalVouchers
          ? _value.totalVouchers
          : totalVouchers // ignore: cast_nullable_to_non_nullable
              as int,
      lastVoucherDate: freezed == lastVoucherDate
          ? _value.lastVoucherDate
          : lastVoucherDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TreasuryBalanceModelImpl implements _TreasuryBalanceModel {
  const _$TreasuryBalanceModelImpl(
      {required this.treasuryId,
      required this.treasuryName,
      required this.treasuryKind,
      this.entityId,
      this.entityType,
      this.isActive = true,
      this.balanceIqd = 0.0,
      this.balanceUsd = 0.0,
      this.totalVouchers = 0,
      this.lastVoucherDate});

  factory _$TreasuryBalanceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TreasuryBalanceModelImplFromJson(json);

  /// معرّف الخزينة
  @override
  final int treasuryId;

  /// اسم الخزينة
  @override
  final String treasuryName;

  /// نوع الخزينة: 'main' | 'contractor' | 'partner'
  @override
  final String treasuryKind;

  /// معرّف الكيان المرتبط (اختياري)
  @override
  final int? entityId;

  /// نوع الكيان المرتبط (اختياري)
  @override
  final String? entityType;

  /// هل الخزينة نشطة؟
  @override
  @JsonKey()
  final bool isActive;

  /// الرصيد بالدينار العراقي — يمكن أن يكون سالباً
  @override
  @JsonKey()
  final double balanceIqd;

  /// الرصيد بالدولار الأمريكي
  @override
  @JsonKey()
  final double balanceUsd;

  /// إجمالي عدد السندات في هذه الخزينة
  @override
  @JsonKey()
  final int totalVouchers;

  /// تاريخ آخر سند (null = لا توجد سندات)
  @override
  final DateTime? lastVoucherDate;

  @override
  String toString() {
    return 'TreasuryBalanceModel(treasuryId: $treasuryId, treasuryName: $treasuryName, treasuryKind: $treasuryKind, entityId: $entityId, entityType: $entityType, isActive: $isActive, balanceIqd: $balanceIqd, balanceUsd: $balanceUsd, totalVouchers: $totalVouchers, lastVoucherDate: $lastVoucherDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TreasuryBalanceModelImpl &&
            (identical(other.treasuryId, treasuryId) ||
                other.treasuryId == treasuryId) &&
            (identical(other.treasuryName, treasuryName) ||
                other.treasuryName == treasuryName) &&
            (identical(other.treasuryKind, treasuryKind) ||
                other.treasuryKind == treasuryKind) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.entityType, entityType) ||
                other.entityType == entityType) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.balanceIqd, balanceIqd) ||
                other.balanceIqd == balanceIqd) &&
            (identical(other.balanceUsd, balanceUsd) ||
                other.balanceUsd == balanceUsd) &&
            (identical(other.totalVouchers, totalVouchers) ||
                other.totalVouchers == totalVouchers) &&
            (identical(other.lastVoucherDate, lastVoucherDate) ||
                other.lastVoucherDate == lastVoucherDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      treasuryId,
      treasuryName,
      treasuryKind,
      entityId,
      entityType,
      isActive,
      balanceIqd,
      balanceUsd,
      totalVouchers,
      lastVoucherDate);

  /// Create a copy of TreasuryBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TreasuryBalanceModelImplCopyWith<_$TreasuryBalanceModelImpl>
      get copyWith =>
          __$$TreasuryBalanceModelImplCopyWithImpl<_$TreasuryBalanceModelImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TreasuryBalanceModelImplToJson(
      this,
    );
  }
}

abstract class _TreasuryBalanceModel implements TreasuryBalanceModel {
  const factory _TreasuryBalanceModel(
      {required final int treasuryId,
      required final String treasuryName,
      required final String treasuryKind,
      final int? entityId,
      final String? entityType,
      final bool isActive,
      final double balanceIqd,
      final double balanceUsd,
      final int totalVouchers,
      final DateTime? lastVoucherDate}) = _$TreasuryBalanceModelImpl;

  factory _TreasuryBalanceModel.fromJson(Map<String, dynamic> json) =
      _$TreasuryBalanceModelImpl.fromJson;

  /// معرّف الخزينة
  @override
  int get treasuryId;

  /// اسم الخزينة
  @override
  String get treasuryName;

  /// نوع الخزينة: 'main' | 'contractor' | 'partner'
  @override
  String get treasuryKind;

  /// معرّف الكيان المرتبط (اختياري)
  @override
  int? get entityId;

  /// نوع الكيان المرتبط (اختياري)
  @override
  String? get entityType;

  /// هل الخزينة نشطة؟
  @override
  bool get isActive;

  /// الرصيد بالدينار العراقي — يمكن أن يكون سالباً
  @override
  double get balanceIqd;

  /// الرصيد بالدولار الأمريكي
  @override
  double get balanceUsd;

  /// إجمالي عدد السندات في هذه الخزينة
  @override
  int get totalVouchers;

  /// تاريخ آخر سند (null = لا توجد سندات)
  @override
  DateTime? get lastVoucherDate;

  /// Create a copy of TreasuryBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TreasuryBalanceModelImplCopyWith<_$TreasuryBalanceModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
