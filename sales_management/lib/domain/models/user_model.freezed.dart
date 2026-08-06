// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  /// المعرّف الفريد في قاعدة البيانات
  int get id => throw _privateConstructorUsedError;

  /// اسم المستخدم للدخول (فريد، case-insensitive)
  String get username => throw _privateConstructorUsedError;

  /// الاسم الكامل للعرض في الواجهة
  String get fullName => throw _privateConstructorUsedError;

  /// الدور: 'super_admin' | 'admin' | 'user'
  String get role => throw _privateConstructorUsedError;

  /// صلاحيات إضافية مخصصة بصيغة JSON
  /// مثال: {"can_export": true, "can_delete_voucher": false}
  String get permissionsJson => throw _privateConstructorUsedError;

  /// هل الحساب مفعَّل؟
  bool get isActive => throw _privateConstructorUsedError;

  /// عدد محاولات الدخول الفاشلة المتتالية
  int get failedLoginAttempts => throw _privateConstructorUsedError;

  /// وقت رفع القفل (null = غير مقفول)
  DateTime? get lockedUntil => throw _privateConstructorUsedError;

  /// وقت آخر دخول ناجح
  DateTime? get lastLoginAt => throw _privateConstructorUsedError;

  /// وقت إنشاء الحساب
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call(
      {int id,
      String username,
      String fullName,
      String role,
      String permissionsJson,
      bool isActive,
      int failedLoginAttempts,
      DateTime? lockedUntil,
      DateTime? lastLoginAt,
      DateTime? createdAt});
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? fullName = null,
    Object? role = null,
    Object? permissionsJson = null,
    Object? isActive = null,
    Object? failedLoginAttempts = null,
    Object? lockedUntil = freezed,
    Object? lastLoginAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      permissionsJson: null == permissionsJson
          ? _value.permissionsJson
          : permissionsJson // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      failedLoginAttempts: null == failedLoginAttempts
          ? _value.failedLoginAttempts
          : failedLoginAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      lockedUntil: freezed == lockedUntil
          ? _value.lockedUntil
          : lockedUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastLoginAt: freezed == lastLoginAt
          ? _value.lastLoginAt
          : lastLoginAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
          _$UserModelImpl value, $Res Function(_$UserModelImpl) then) =
      __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String username,
      String fullName,
      String role,
      String permissionsJson,
      bool isActive,
      int failedLoginAttempts,
      DateTime? lockedUntil,
      DateTime? lastLoginAt,
      DateTime? createdAt});
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
      _$UserModelImpl _value, $Res Function(_$UserModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? fullName = null,
    Object? role = null,
    Object? permissionsJson = null,
    Object? isActive = null,
    Object? failedLoginAttempts = null,
    Object? lockedUntil = freezed,
    Object? lastLoginAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$UserModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      permissionsJson: null == permissionsJson
          ? _value.permissionsJson
          : permissionsJson // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      failedLoginAttempts: null == failedLoginAttempts
          ? _value.failedLoginAttempts
          : failedLoginAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      lockedUntil: freezed == lockedUntil
          ? _value.lockedUntil
          : lockedUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastLoginAt: freezed == lastLoginAt
          ? _value.lastLoginAt
          : lastLoginAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl implements _UserModel {
  const _$UserModelImpl(
      {required this.id,
      required this.username,
      required this.fullName,
      required this.role,
      this.permissionsJson = '{}',
      this.isActive = true,
      this.failedLoginAttempts = 0,
      this.lockedUntil,
      this.lastLoginAt,
      this.createdAt});

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  /// المعرّف الفريد في قاعدة البيانات
  @override
  final int id;

  /// اسم المستخدم للدخول (فريد، case-insensitive)
  @override
  final String username;

  /// الاسم الكامل للعرض في الواجهة
  @override
  final String fullName;

  /// الدور: 'super_admin' | 'admin' | 'user'
  @override
  final String role;

  /// صلاحيات إضافية مخصصة بصيغة JSON
  /// مثال: {"can_export": true, "can_delete_voucher": false}
  @override
  @JsonKey()
  final String permissionsJson;

  /// هل الحساب مفعَّل؟
  @override
  @JsonKey()
  final bool isActive;

  /// عدد محاولات الدخول الفاشلة المتتالية
  @override
  @JsonKey()
  final int failedLoginAttempts;

  /// وقت رفع القفل (null = غير مقفول)
  @override
  final DateTime? lockedUntil;

  /// وقت آخر دخول ناجح
  @override
  final DateTime? lastLoginAt;

  /// وقت إنشاء الحساب
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, fullName: $fullName, role: $role, permissionsJson: $permissionsJson, isActive: $isActive, failedLoginAttempts: $failedLoginAttempts, lockedUntil: $lockedUntil, lastLoginAt: $lastLoginAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.permissionsJson, permissionsJson) ||
                other.permissionsJson == permissionsJson) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.failedLoginAttempts, failedLoginAttempts) ||
                other.failedLoginAttempts == failedLoginAttempts) &&
            (identical(other.lockedUntil, lockedUntil) ||
                other.lockedUntil == lockedUntil) &&
            (identical(other.lastLoginAt, lastLoginAt) ||
                other.lastLoginAt == lastLoginAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      username,
      fullName,
      role,
      permissionsJson,
      isActive,
      failedLoginAttempts,
      lockedUntil,
      lastLoginAt,
      createdAt);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(
      this,
    );
  }
}

abstract class _UserModel implements UserModel {
  const factory _UserModel(
      {required final int id,
      required final String username,
      required final String fullName,
      required final String role,
      final String permissionsJson,
      final bool isActive,
      final int failedLoginAttempts,
      final DateTime? lockedUntil,
      final DateTime? lastLoginAt,
      final DateTime? createdAt}) = _$UserModelImpl;

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  /// المعرّف الفريد في قاعدة البيانات
  @override
  int get id;

  /// اسم المستخدم للدخول (فريد، case-insensitive)
  @override
  String get username;

  /// الاسم الكامل للعرض في الواجهة
  @override
  String get fullName;

  /// الدور: 'super_admin' | 'admin' | 'user'
  @override
  String get role;

  /// صلاحيات إضافية مخصصة بصيغة JSON
  /// مثال: {"can_export": true, "can_delete_voucher": false}
  @override
  String get permissionsJson;

  /// هل الحساب مفعَّل؟
  @override
  bool get isActive;

  /// عدد محاولات الدخول الفاشلة المتتالية
  @override
  int get failedLoginAttempts;

  /// وقت رفع القفل (null = غير مقفول)
  @override
  DateTime? get lockedUntil;

  /// وقت آخر دخول ناجح
  @override
  DateTime? get lastLoginAt;

  /// وقت إنشاء الحساب
  @override
  DateTime? get createdAt;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
