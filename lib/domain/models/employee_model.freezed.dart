// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EmployeeModel _$EmployeeModelFromJson(Map<String, dynamic> json) {
  return _EmployeeModel.fromJson(json);
}

/// @nodoc
mixin _$EmployeeModel {
  /// المعرّف الفريد
  int get id => throw _privateConstructorUsedError;

  /// الاسم الكامل
  String get fullName => throw _privateConstructorUsedError;

  /// رقم الهاتف
  String get phone => throw _privateConstructorUsedError;

  /// العنوان
  String get address => throw _privateConstructorUsedError;

  /// الراتب الأساسي الشهري بالدينار
  double get basicSalary => throw _privateConstructorUsedError;

  /// تاريخ التعيين
  DateTime? get hireDate => throw _privateConstructorUsedError;

  /// معرّف الخزينة الخاصة بالموظف (اختياري)
  int? get treasuryId => throw _privateConstructorUsedError;

  /// ملاحظات
  String get notes => throw _privateConstructorUsedError;

  /// الصفة الوظيفية — مهندس · سائق · محاسب
  ///
  /// 🔴 **كانت ساقطة من هذا النموذج** رغم وجودها في الجدول منذ v7: طبقة
  ///   الرواتب تقرأها من صفّ Drift مباشرةً، فبقيت شاشة الموظفين عاجزة عن
  ///   عرض صفة أيّ موظف. نمط ع-٥٠: الرقم يُحسَب صحيحاً ويسقط في المحطّة
  ///   الوسطى لأن طرفيها سليمان.
  String get position => throw _privateConstructorUsedError;

  /// عملة الراتب: 'IQD' | 'USD'
  ///
  /// 🔴 **كانت ساقطة أيضاً** — فكانت البطاقة تكتب «الراتب: ٥٠٠ د.ع»
  ///   لموظفٍ راتبه ٥٠٠ **دولار**، وتجمع الاثنين في مجموع واحد. راجع
  ///   ع-٥٣.
  String get salaryCurrency => throw _privateConstructorUsedError;

  /// حالة الموظف (Schema v8) — راجع [EmployeeStatus]
  ///
  /// حلّت محلّ `isActive` ولم تُضَف بجوارها: عمودان لمعنى واحد يفترقان
  /// بأول كتابة تنسى أحدهما (نمط ع-٤٠).
  String get status => throw _privateConstructorUsedError;

  /// القسم — `null` يعني «بلا قسم»
  int? get departmentId => throw _privateConstructorUsedError;

  /// ترتيب الموظف داخل قسمه — الأصغر أولاً
  int get sortOrder => throw _privateConstructorUsedError;

  /// تاريخ الإنشاء
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this EmployeeModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EmployeeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EmployeeModelCopyWith<EmployeeModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EmployeeModelCopyWith<$Res> {
  factory $EmployeeModelCopyWith(
          EmployeeModel value, $Res Function(EmployeeModel) then) =
      _$EmployeeModelCopyWithImpl<$Res, EmployeeModel>;
  @useResult
  $Res call(
      {int id,
      String fullName,
      String phone,
      String address,
      double basicSalary,
      DateTime? hireDate,
      int? treasuryId,
      String notes,
      String position,
      String salaryCurrency,
      String status,
      int? departmentId,
      int sortOrder,
      DateTime? createdAt});
}

/// @nodoc
class _$EmployeeModelCopyWithImpl<$Res, $Val extends EmployeeModel>
    implements $EmployeeModelCopyWith<$Res> {
  _$EmployeeModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EmployeeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? phone = null,
    Object? address = null,
    Object? basicSalary = null,
    Object? hireDate = freezed,
    Object? treasuryId = freezed,
    Object? notes = null,
    Object? position = null,
    Object? salaryCurrency = null,
    Object? status = null,
    Object? departmentId = freezed,
    Object? sortOrder = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      basicSalary: null == basicSalary
          ? _value.basicSalary
          : basicSalary // ignore: cast_nullable_to_non_nullable
              as double,
      hireDate: freezed == hireDate
          ? _value.hireDate
          : hireDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      treasuryId: freezed == treasuryId
          ? _value.treasuryId
          : treasuryId // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as String,
      salaryCurrency: null == salaryCurrency
          ? _value.salaryCurrency
          : salaryCurrency // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      departmentId: freezed == departmentId
          ? _value.departmentId
          : departmentId // ignore: cast_nullable_to_non_nullable
              as int?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EmployeeModelImplCopyWith<$Res>
    implements $EmployeeModelCopyWith<$Res> {
  factory _$$EmployeeModelImplCopyWith(
          _$EmployeeModelImpl value, $Res Function(_$EmployeeModelImpl) then) =
      __$$EmployeeModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String fullName,
      String phone,
      String address,
      double basicSalary,
      DateTime? hireDate,
      int? treasuryId,
      String notes,
      String position,
      String salaryCurrency,
      String status,
      int? departmentId,
      int sortOrder,
      DateTime? createdAt});
}

/// @nodoc
class __$$EmployeeModelImplCopyWithImpl<$Res>
    extends _$EmployeeModelCopyWithImpl<$Res, _$EmployeeModelImpl>
    implements _$$EmployeeModelImplCopyWith<$Res> {
  __$$EmployeeModelImplCopyWithImpl(
      _$EmployeeModelImpl _value, $Res Function(_$EmployeeModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of EmployeeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? phone = null,
    Object? address = null,
    Object? basicSalary = null,
    Object? hireDate = freezed,
    Object? treasuryId = freezed,
    Object? notes = null,
    Object? position = null,
    Object? salaryCurrency = null,
    Object? status = null,
    Object? departmentId = freezed,
    Object? sortOrder = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$EmployeeModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      basicSalary: null == basicSalary
          ? _value.basicSalary
          : basicSalary // ignore: cast_nullable_to_non_nullable
              as double,
      hireDate: freezed == hireDate
          ? _value.hireDate
          : hireDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      treasuryId: freezed == treasuryId
          ? _value.treasuryId
          : treasuryId // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as String,
      salaryCurrency: null == salaryCurrency
          ? _value.salaryCurrency
          : salaryCurrency // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      departmentId: freezed == departmentId
          ? _value.departmentId
          : departmentId // ignore: cast_nullable_to_non_nullable
              as int?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EmployeeModelImpl implements _EmployeeModel {
  const _$EmployeeModelImpl(
      {required this.id,
      required this.fullName,
      this.phone = '',
      this.address = '',
      this.basicSalary = 0.0,
      this.hireDate,
      this.treasuryId,
      this.notes = '',
      this.position = '',
      this.salaryCurrency = 'IQD',
      this.status = EmployeeStatus.active,
      this.departmentId,
      this.sortOrder = 0,
      this.createdAt});

  factory _$EmployeeModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$EmployeeModelImplFromJson(json);

  /// المعرّف الفريد
  @override
  final int id;

  /// الاسم الكامل
  @override
  final String fullName;

  /// رقم الهاتف
  @override
  @JsonKey()
  final String phone;

  /// العنوان
  @override
  @JsonKey()
  final String address;

  /// الراتب الأساسي الشهري بالدينار
  @override
  @JsonKey()
  final double basicSalary;

  /// تاريخ التعيين
  @override
  final DateTime? hireDate;

  /// معرّف الخزينة الخاصة بالموظف (اختياري)
  @override
  final int? treasuryId;

  /// ملاحظات
  @override
  @JsonKey()
  final String notes;

  /// الصفة الوظيفية — مهندس · سائق · محاسب
  ///
  /// 🔴 **كانت ساقطة من هذا النموذج** رغم وجودها في الجدول منذ v7: طبقة
  ///   الرواتب تقرأها من صفّ Drift مباشرةً، فبقيت شاشة الموظفين عاجزة عن
  ///   عرض صفة أيّ موظف. نمط ع-٥٠: الرقم يُحسَب صحيحاً ويسقط في المحطّة
  ///   الوسطى لأن طرفيها سليمان.
  @override
  @JsonKey()
  final String position;

  /// عملة الراتب: 'IQD' | 'USD'
  ///
  /// 🔴 **كانت ساقطة أيضاً** — فكانت البطاقة تكتب «الراتب: ٥٠٠ د.ع»
  ///   لموظفٍ راتبه ٥٠٠ **دولار**، وتجمع الاثنين في مجموع واحد. راجع
  ///   ع-٥٣.
  @override
  @JsonKey()
  final String salaryCurrency;

  /// حالة الموظف (Schema v8) — راجع [EmployeeStatus]
  ///
  /// حلّت محلّ `isActive` ولم تُضَف بجوارها: عمودان لمعنى واحد يفترقان
  /// بأول كتابة تنسى أحدهما (نمط ع-٤٠).
  @override
  @JsonKey()
  final String status;

  /// القسم — `null` يعني «بلا قسم»
  @override
  final int? departmentId;

  /// ترتيب الموظف داخل قسمه — الأصغر أولاً
  @override
  @JsonKey()
  final int sortOrder;

  /// تاريخ الإنشاء
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'EmployeeModel(id: $id, fullName: $fullName, phone: $phone, address: $address, basicSalary: $basicSalary, hireDate: $hireDate, treasuryId: $treasuryId, notes: $notes, position: $position, salaryCurrency: $salaryCurrency, status: $status, departmentId: $departmentId, sortOrder: $sortOrder, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EmployeeModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.basicSalary, basicSalary) ||
                other.basicSalary == basicSalary) &&
            (identical(other.hireDate, hireDate) ||
                other.hireDate == hireDate) &&
            (identical(other.treasuryId, treasuryId) ||
                other.treasuryId == treasuryId) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.salaryCurrency, salaryCurrency) ||
                other.salaryCurrency == salaryCurrency) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.departmentId, departmentId) ||
                other.departmentId == departmentId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      fullName,
      phone,
      address,
      basicSalary,
      hireDate,
      treasuryId,
      notes,
      position,
      salaryCurrency,
      status,
      departmentId,
      sortOrder,
      createdAt);

  /// Create a copy of EmployeeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EmployeeModelImplCopyWith<_$EmployeeModelImpl> get copyWith =>
      __$$EmployeeModelImplCopyWithImpl<_$EmployeeModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EmployeeModelImplToJson(
      this,
    );
  }
}

abstract class _EmployeeModel implements EmployeeModel {
  const factory _EmployeeModel(
      {required final int id,
      required final String fullName,
      final String phone,
      final String address,
      final double basicSalary,
      final DateTime? hireDate,
      final int? treasuryId,
      final String notes,
      final String position,
      final String salaryCurrency,
      final String status,
      final int? departmentId,
      final int sortOrder,
      final DateTime? createdAt}) = _$EmployeeModelImpl;

  factory _EmployeeModel.fromJson(Map<String, dynamic> json) =
      _$EmployeeModelImpl.fromJson;

  /// المعرّف الفريد
  @override
  int get id;

  /// الاسم الكامل
  @override
  String get fullName;

  /// رقم الهاتف
  @override
  String get phone;

  /// العنوان
  @override
  String get address;

  /// الراتب الأساسي الشهري بالدينار
  @override
  double get basicSalary;

  /// تاريخ التعيين
  @override
  DateTime? get hireDate;

  /// معرّف الخزينة الخاصة بالموظف (اختياري)
  @override
  int? get treasuryId;

  /// ملاحظات
  @override
  String get notes;

  /// الصفة الوظيفية — مهندس · سائق · محاسب
  ///
  /// 🔴 **كانت ساقطة من هذا النموذج** رغم وجودها في الجدول منذ v7: طبقة
  ///   الرواتب تقرأها من صفّ Drift مباشرةً، فبقيت شاشة الموظفين عاجزة عن
  ///   عرض صفة أيّ موظف. نمط ع-٥٠: الرقم يُحسَب صحيحاً ويسقط في المحطّة
  ///   الوسطى لأن طرفيها سليمان.
  @override
  String get position;

  /// عملة الراتب: 'IQD' | 'USD'
  ///
  /// 🔴 **كانت ساقطة أيضاً** — فكانت البطاقة تكتب «الراتب: ٥٠٠ د.ع»
  ///   لموظفٍ راتبه ٥٠٠ **دولار**، وتجمع الاثنين في مجموع واحد. راجع
  ///   ع-٥٣.
  @override
  String get salaryCurrency;

  /// حالة الموظف (Schema v8) — راجع [EmployeeStatus]
  ///
  /// حلّت محلّ `isActive` ولم تُضَف بجوارها: عمودان لمعنى واحد يفترقان
  /// بأول كتابة تنسى أحدهما (نمط ع-٤٠).
  @override
  String get status;

  /// القسم — `null` يعني «بلا قسم»
  @override
  int? get departmentId;

  /// ترتيب الموظف داخل قسمه — الأصغر أولاً
  @override
  int get sortOrder;

  /// تاريخ الإنشاء
  @override
  DateTime? get createdAt;

  /// Create a copy of EmployeeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EmployeeModelImplCopyWith<_$EmployeeModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DepartmentModel _$DepartmentModelFromJson(Map<String, dynamic> json) {
  return _DepartmentModel.fromJson(json);
}

/// @nodoc
mixin _$DepartmentModel {
  /// المعرّف الفريد
  int get id => throw _privateConstructorUsedError;

  /// اسم القسم — «مهندسون» · «فنيون» · «سواق»
  String get name => throw _privateConstructorUsedError;

  /// ترتيب القسم في القائمة — الأصغر أولاً
  int get sortOrder => throw _privateConstructorUsedError;

  /// تاريخ الإنشاء
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this DepartmentModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DepartmentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DepartmentModelCopyWith<DepartmentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DepartmentModelCopyWith<$Res> {
  factory $DepartmentModelCopyWith(
          DepartmentModel value, $Res Function(DepartmentModel) then) =
      _$DepartmentModelCopyWithImpl<$Res, DepartmentModel>;
  @useResult
  $Res call({int id, String name, int sortOrder, DateTime? createdAt});
}

/// @nodoc
class _$DepartmentModelCopyWithImpl<$Res, $Val extends DepartmentModel>
    implements $DepartmentModelCopyWith<$Res> {
  _$DepartmentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DepartmentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? sortOrder = null,
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
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DepartmentModelImplCopyWith<$Res>
    implements $DepartmentModelCopyWith<$Res> {
  factory _$$DepartmentModelImplCopyWith(_$DepartmentModelImpl value,
          $Res Function(_$DepartmentModelImpl) then) =
      __$$DepartmentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String name, int sortOrder, DateTime? createdAt});
}

/// @nodoc
class __$$DepartmentModelImplCopyWithImpl<$Res>
    extends _$DepartmentModelCopyWithImpl<$Res, _$DepartmentModelImpl>
    implements _$$DepartmentModelImplCopyWith<$Res> {
  __$$DepartmentModelImplCopyWithImpl(
      _$DepartmentModelImpl _value, $Res Function(_$DepartmentModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of DepartmentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? sortOrder = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$DepartmentModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DepartmentModelImpl implements _DepartmentModel {
  const _$DepartmentModelImpl(
      {required this.id,
      required this.name,
      this.sortOrder = 0,
      this.createdAt});

  factory _$DepartmentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DepartmentModelImplFromJson(json);

  /// المعرّف الفريد
  @override
  final int id;

  /// اسم القسم — «مهندسون» · «فنيون» · «سواق»
  @override
  final String name;

  /// ترتيب القسم في القائمة — الأصغر أولاً
  @override
  @JsonKey()
  final int sortOrder;

  /// تاريخ الإنشاء
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'DepartmentModel(id: $id, name: $name, sortOrder: $sortOrder, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DepartmentModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, sortOrder, createdAt);

  /// Create a copy of DepartmentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DepartmentModelImplCopyWith<_$DepartmentModelImpl> get copyWith =>
      __$$DepartmentModelImplCopyWithImpl<_$DepartmentModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DepartmentModelImplToJson(
      this,
    );
  }
}

abstract class _DepartmentModel implements DepartmentModel {
  const factory _DepartmentModel(
      {required final int id,
      required final String name,
      final int sortOrder,
      final DateTime? createdAt}) = _$DepartmentModelImpl;

  factory _DepartmentModel.fromJson(Map<String, dynamic> json) =
      _$DepartmentModelImpl.fromJson;

  /// المعرّف الفريد
  @override
  int get id;

  /// اسم القسم — «مهندسون» · «فنيون» · «سواق»
  @override
  String get name;

  /// ترتيب القسم في القائمة — الأصغر أولاً
  @override
  int get sortOrder;

  /// تاريخ الإنشاء
  @override
  DateTime? get createdAt;

  /// Create a copy of DepartmentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DepartmentModelImplCopyWith<_$DepartmentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CashAdvanceModel _$CashAdvanceModelFromJson(Map<String, dynamic> json) {
  return _CashAdvanceModel.fromJson(json);
}

/// @nodoc
mixin _$CashAdvanceModel {
  /// المعرّف الفريد
  int get id => throw _privateConstructorUsedError;

  /// نوع المدين: 'employee' | 'external'
  String get debtorType => throw _privateConstructorUsedError;

  /// معرّف الموظف (إذا debtorType='employee')
  int? get employeeId => throw _privateConstructorUsedError;

  /// اسم الشخص الخارجي (إذا debtorType='external')
  String? get externalPersonName => throw _privateConstructorUsedError;

  /// مبلغ السلفة (دائماً موجب)
  double get amount => throw _privateConstructorUsedError;

  /// العملة: 'IQD' | 'USD'
  String get currency => throw _privateConstructorUsedError;

  /// تاريخ منح السلفة
  DateTime get advanceDate => throw _privateConstructorUsedError;

  /// الحالة: 'pending' | 'partial' | 'paid' | 'written_off'
  String get status => throw _privateConstructorUsedError;

  /// إجمالي ما تم سداده حتى الآن
  double get totalRepaid => throw _privateConstructorUsedError;

  /// السبب / الغرض
  String get reason => throw _privateConstructorUsedError;

  /// معرّف السند المرتبط
  int? get voucherId => throw _privateConstructorUsedError;

  /// تاريخ الإنشاء
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this CashAdvanceModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CashAdvanceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CashAdvanceModelCopyWith<CashAdvanceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CashAdvanceModelCopyWith<$Res> {
  factory $CashAdvanceModelCopyWith(
          CashAdvanceModel value, $Res Function(CashAdvanceModel) then) =
      _$CashAdvanceModelCopyWithImpl<$Res, CashAdvanceModel>;
  @useResult
  $Res call(
      {int id,
      String debtorType,
      int? employeeId,
      String? externalPersonName,
      double amount,
      String currency,
      DateTime advanceDate,
      String status,
      double totalRepaid,
      String reason,
      int? voucherId,
      DateTime? createdAt});
}

/// @nodoc
class _$CashAdvanceModelCopyWithImpl<$Res, $Val extends CashAdvanceModel>
    implements $CashAdvanceModelCopyWith<$Res> {
  _$CashAdvanceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CashAdvanceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? debtorType = null,
    Object? employeeId = freezed,
    Object? externalPersonName = freezed,
    Object? amount = null,
    Object? currency = null,
    Object? advanceDate = null,
    Object? status = null,
    Object? totalRepaid = null,
    Object? reason = null,
    Object? voucherId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      debtorType: null == debtorType
          ? _value.debtorType
          : debtorType // ignore: cast_nullable_to_non_nullable
              as String,
      employeeId: freezed == employeeId
          ? _value.employeeId
          : employeeId // ignore: cast_nullable_to_non_nullable
              as int?,
      externalPersonName: freezed == externalPersonName
          ? _value.externalPersonName
          : externalPersonName // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      advanceDate: null == advanceDate
          ? _value.advanceDate
          : advanceDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      totalRepaid: null == totalRepaid
          ? _value.totalRepaid
          : totalRepaid // ignore: cast_nullable_to_non_nullable
              as double,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      voucherId: freezed == voucherId
          ? _value.voucherId
          : voucherId // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CashAdvanceModelImplCopyWith<$Res>
    implements $CashAdvanceModelCopyWith<$Res> {
  factory _$$CashAdvanceModelImplCopyWith(_$CashAdvanceModelImpl value,
          $Res Function(_$CashAdvanceModelImpl) then) =
      __$$CashAdvanceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String debtorType,
      int? employeeId,
      String? externalPersonName,
      double amount,
      String currency,
      DateTime advanceDate,
      String status,
      double totalRepaid,
      String reason,
      int? voucherId,
      DateTime? createdAt});
}

/// @nodoc
class __$$CashAdvanceModelImplCopyWithImpl<$Res>
    extends _$CashAdvanceModelCopyWithImpl<$Res, _$CashAdvanceModelImpl>
    implements _$$CashAdvanceModelImplCopyWith<$Res> {
  __$$CashAdvanceModelImplCopyWithImpl(_$CashAdvanceModelImpl _value,
      $Res Function(_$CashAdvanceModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of CashAdvanceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? debtorType = null,
    Object? employeeId = freezed,
    Object? externalPersonName = freezed,
    Object? amount = null,
    Object? currency = null,
    Object? advanceDate = null,
    Object? status = null,
    Object? totalRepaid = null,
    Object? reason = null,
    Object? voucherId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$CashAdvanceModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      debtorType: null == debtorType
          ? _value.debtorType
          : debtorType // ignore: cast_nullable_to_non_nullable
              as String,
      employeeId: freezed == employeeId
          ? _value.employeeId
          : employeeId // ignore: cast_nullable_to_non_nullable
              as int?,
      externalPersonName: freezed == externalPersonName
          ? _value.externalPersonName
          : externalPersonName // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      advanceDate: null == advanceDate
          ? _value.advanceDate
          : advanceDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      totalRepaid: null == totalRepaid
          ? _value.totalRepaid
          : totalRepaid // ignore: cast_nullable_to_non_nullable
              as double,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      voucherId: freezed == voucherId
          ? _value.voucherId
          : voucherId // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CashAdvanceModelImpl implements _CashAdvanceModel {
  const _$CashAdvanceModelImpl(
      {required this.id,
      this.debtorType = 'employee',
      this.employeeId,
      this.externalPersonName,
      required this.amount,
      this.currency = 'IQD',
      required this.advanceDate,
      this.status = 'pending',
      this.totalRepaid = 0.0,
      this.reason = '',
      this.voucherId,
      this.createdAt});

  factory _$CashAdvanceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CashAdvanceModelImplFromJson(json);

  /// المعرّف الفريد
  @override
  final int id;

  /// نوع المدين: 'employee' | 'external'
  @override
  @JsonKey()
  final String debtorType;

  /// معرّف الموظف (إذا debtorType='employee')
  @override
  final int? employeeId;

  /// اسم الشخص الخارجي (إذا debtorType='external')
  @override
  final String? externalPersonName;

  /// مبلغ السلفة (دائماً موجب)
  @override
  final double amount;

  /// العملة: 'IQD' | 'USD'
  @override
  @JsonKey()
  final String currency;

  /// تاريخ منح السلفة
  @override
  final DateTime advanceDate;

  /// الحالة: 'pending' | 'partial' | 'paid' | 'written_off'
  @override
  @JsonKey()
  final String status;

  /// إجمالي ما تم سداده حتى الآن
  @override
  @JsonKey()
  final double totalRepaid;

  /// السبب / الغرض
  @override
  @JsonKey()
  final String reason;

  /// معرّف السند المرتبط
  @override
  final int? voucherId;

  /// تاريخ الإنشاء
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'CashAdvanceModel(id: $id, debtorType: $debtorType, employeeId: $employeeId, externalPersonName: $externalPersonName, amount: $amount, currency: $currency, advanceDate: $advanceDate, status: $status, totalRepaid: $totalRepaid, reason: $reason, voucherId: $voucherId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CashAdvanceModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.debtorType, debtorType) ||
                other.debtorType == debtorType) &&
            (identical(other.employeeId, employeeId) ||
                other.employeeId == employeeId) &&
            (identical(other.externalPersonName, externalPersonName) ||
                other.externalPersonName == externalPersonName) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.advanceDate, advanceDate) ||
                other.advanceDate == advanceDate) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.totalRepaid, totalRepaid) ||
                other.totalRepaid == totalRepaid) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.voucherId, voucherId) ||
                other.voucherId == voucherId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      debtorType,
      employeeId,
      externalPersonName,
      amount,
      currency,
      advanceDate,
      status,
      totalRepaid,
      reason,
      voucherId,
      createdAt);

  /// Create a copy of CashAdvanceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CashAdvanceModelImplCopyWith<_$CashAdvanceModelImpl> get copyWith =>
      __$$CashAdvanceModelImplCopyWithImpl<_$CashAdvanceModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CashAdvanceModelImplToJson(
      this,
    );
  }
}

abstract class _CashAdvanceModel implements CashAdvanceModel {
  const factory _CashAdvanceModel(
      {required final int id,
      final String debtorType,
      final int? employeeId,
      final String? externalPersonName,
      required final double amount,
      final String currency,
      required final DateTime advanceDate,
      final String status,
      final double totalRepaid,
      final String reason,
      final int? voucherId,
      final DateTime? createdAt}) = _$CashAdvanceModelImpl;

  factory _CashAdvanceModel.fromJson(Map<String, dynamic> json) =
      _$CashAdvanceModelImpl.fromJson;

  /// المعرّف الفريد
  @override
  int get id;

  /// نوع المدين: 'employee' | 'external'
  @override
  String get debtorType;

  /// معرّف الموظف (إذا debtorType='employee')
  @override
  int? get employeeId;

  /// اسم الشخص الخارجي (إذا debtorType='external')
  @override
  String? get externalPersonName;

  /// مبلغ السلفة (دائماً موجب)
  @override
  double get amount;

  /// العملة: 'IQD' | 'USD'
  @override
  String get currency;

  /// تاريخ منح السلفة
  @override
  DateTime get advanceDate;

  /// الحالة: 'pending' | 'partial' | 'paid' | 'written_off'
  @override
  String get status;

  /// إجمالي ما تم سداده حتى الآن
  @override
  double get totalRepaid;

  /// السبب / الغرض
  @override
  String get reason;

  /// معرّف السند المرتبط
  @override
  int? get voucherId;

  /// تاريخ الإنشاء
  @override
  DateTime? get createdAt;

  /// Create a copy of CashAdvanceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CashAdvanceModelImplCopyWith<_$CashAdvanceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SalaryPaymentModel _$SalaryPaymentModelFromJson(Map<String, dynamic> json) {
  return _SalaryPaymentModel.fromJson(json);
}

/// @nodoc
mixin _$SalaryPaymentModel {
  /// المعرّف الفريد
  int get id => throw _privateConstructorUsedError;

  /// معرّف الموظف
  int get employeeId => throw _privateConstructorUsedError;

  /// التسمية: 'يناير 2025' أو 'الربع الأول 2025'
  String get periodLabel => throw _privateConstructorUsedError;

  /// الراتب الأساسي
  double get basicSalary => throw _privateConstructorUsedError;

  /// الإضافات (بدلات، مكافآت)
  double get additions => throw _privateConstructorUsedError;

  /// الخصومات (سلف، غيابات)
  double get deductions => throw _privateConstructorUsedError;

  /// الصافي المدفوع = basicSalary + additions - deductions
  double get netAmount => throw _privateConstructorUsedError;

  /// تاريخ الصرف
  DateTime get paymentDate => throw _privateConstructorUsedError;

  /// معرّف السند المُولَّد تلقائياً
  int? get voucherId => throw _privateConstructorUsedError;

  /// ملاحظات
  String get notes => throw _privateConstructorUsedError;

  /// Serializes this SalaryPaymentModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SalaryPaymentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SalaryPaymentModelCopyWith<SalaryPaymentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SalaryPaymentModelCopyWith<$Res> {
  factory $SalaryPaymentModelCopyWith(
          SalaryPaymentModel value, $Res Function(SalaryPaymentModel) then) =
      _$SalaryPaymentModelCopyWithImpl<$Res, SalaryPaymentModel>;
  @useResult
  $Res call(
      {int id,
      int employeeId,
      String periodLabel,
      double basicSalary,
      double additions,
      double deductions,
      double netAmount,
      DateTime paymentDate,
      int? voucherId,
      String notes});
}

/// @nodoc
class _$SalaryPaymentModelCopyWithImpl<$Res, $Val extends SalaryPaymentModel>
    implements $SalaryPaymentModelCopyWith<$Res> {
  _$SalaryPaymentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SalaryPaymentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? employeeId = null,
    Object? periodLabel = null,
    Object? basicSalary = null,
    Object? additions = null,
    Object? deductions = null,
    Object? netAmount = null,
    Object? paymentDate = null,
    Object? voucherId = freezed,
    Object? notes = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      employeeId: null == employeeId
          ? _value.employeeId
          : employeeId // ignore: cast_nullable_to_non_nullable
              as int,
      periodLabel: null == periodLabel
          ? _value.periodLabel
          : periodLabel // ignore: cast_nullable_to_non_nullable
              as String,
      basicSalary: null == basicSalary
          ? _value.basicSalary
          : basicSalary // ignore: cast_nullable_to_non_nullable
              as double,
      additions: null == additions
          ? _value.additions
          : additions // ignore: cast_nullable_to_non_nullable
              as double,
      deductions: null == deductions
          ? _value.deductions
          : deductions // ignore: cast_nullable_to_non_nullable
              as double,
      netAmount: null == netAmount
          ? _value.netAmount
          : netAmount // ignore: cast_nullable_to_non_nullable
              as double,
      paymentDate: null == paymentDate
          ? _value.paymentDate
          : paymentDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      voucherId: freezed == voucherId
          ? _value.voucherId
          : voucherId // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SalaryPaymentModelImplCopyWith<$Res>
    implements $SalaryPaymentModelCopyWith<$Res> {
  factory _$$SalaryPaymentModelImplCopyWith(_$SalaryPaymentModelImpl value,
          $Res Function(_$SalaryPaymentModelImpl) then) =
      __$$SalaryPaymentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int employeeId,
      String periodLabel,
      double basicSalary,
      double additions,
      double deductions,
      double netAmount,
      DateTime paymentDate,
      int? voucherId,
      String notes});
}

/// @nodoc
class __$$SalaryPaymentModelImplCopyWithImpl<$Res>
    extends _$SalaryPaymentModelCopyWithImpl<$Res, _$SalaryPaymentModelImpl>
    implements _$$SalaryPaymentModelImplCopyWith<$Res> {
  __$$SalaryPaymentModelImplCopyWithImpl(_$SalaryPaymentModelImpl _value,
      $Res Function(_$SalaryPaymentModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of SalaryPaymentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? employeeId = null,
    Object? periodLabel = null,
    Object? basicSalary = null,
    Object? additions = null,
    Object? deductions = null,
    Object? netAmount = null,
    Object? paymentDate = null,
    Object? voucherId = freezed,
    Object? notes = null,
  }) {
    return _then(_$SalaryPaymentModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      employeeId: null == employeeId
          ? _value.employeeId
          : employeeId // ignore: cast_nullable_to_non_nullable
              as int,
      periodLabel: null == periodLabel
          ? _value.periodLabel
          : periodLabel // ignore: cast_nullable_to_non_nullable
              as String,
      basicSalary: null == basicSalary
          ? _value.basicSalary
          : basicSalary // ignore: cast_nullable_to_non_nullable
              as double,
      additions: null == additions
          ? _value.additions
          : additions // ignore: cast_nullable_to_non_nullable
              as double,
      deductions: null == deductions
          ? _value.deductions
          : deductions // ignore: cast_nullable_to_non_nullable
              as double,
      netAmount: null == netAmount
          ? _value.netAmount
          : netAmount // ignore: cast_nullable_to_non_nullable
              as double,
      paymentDate: null == paymentDate
          ? _value.paymentDate
          : paymentDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      voucherId: freezed == voucherId
          ? _value.voucherId
          : voucherId // ignore: cast_nullable_to_non_nullable
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
class _$SalaryPaymentModelImpl implements _SalaryPaymentModel {
  const _$SalaryPaymentModelImpl(
      {required this.id,
      required this.employeeId,
      this.periodLabel = '',
      this.basicSalary = 0.0,
      this.additions = 0.0,
      this.deductions = 0.0,
      this.netAmount = 0.0,
      required this.paymentDate,
      this.voucherId,
      this.notes = ''});

  factory _$SalaryPaymentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SalaryPaymentModelImplFromJson(json);

  /// المعرّف الفريد
  @override
  final int id;

  /// معرّف الموظف
  @override
  final int employeeId;

  /// التسمية: 'يناير 2025' أو 'الربع الأول 2025'
  @override
  @JsonKey()
  final String periodLabel;

  /// الراتب الأساسي
  @override
  @JsonKey()
  final double basicSalary;

  /// الإضافات (بدلات، مكافآت)
  @override
  @JsonKey()
  final double additions;

  /// الخصومات (سلف، غيابات)
  @override
  @JsonKey()
  final double deductions;

  /// الصافي المدفوع = basicSalary + additions - deductions
  @override
  @JsonKey()
  final double netAmount;

  /// تاريخ الصرف
  @override
  final DateTime paymentDate;

  /// معرّف السند المُولَّد تلقائياً
  @override
  final int? voucherId;

  /// ملاحظات
  @override
  @JsonKey()
  final String notes;

  @override
  String toString() {
    return 'SalaryPaymentModel(id: $id, employeeId: $employeeId, periodLabel: $periodLabel, basicSalary: $basicSalary, additions: $additions, deductions: $deductions, netAmount: $netAmount, paymentDate: $paymentDate, voucherId: $voucherId, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SalaryPaymentModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.employeeId, employeeId) ||
                other.employeeId == employeeId) &&
            (identical(other.periodLabel, periodLabel) ||
                other.periodLabel == periodLabel) &&
            (identical(other.basicSalary, basicSalary) ||
                other.basicSalary == basicSalary) &&
            (identical(other.additions, additions) ||
                other.additions == additions) &&
            (identical(other.deductions, deductions) ||
                other.deductions == deductions) &&
            (identical(other.netAmount, netAmount) ||
                other.netAmount == netAmount) &&
            (identical(other.paymentDate, paymentDate) ||
                other.paymentDate == paymentDate) &&
            (identical(other.voucherId, voucherId) ||
                other.voucherId == voucherId) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      employeeId,
      periodLabel,
      basicSalary,
      additions,
      deductions,
      netAmount,
      paymentDate,
      voucherId,
      notes);

  /// Create a copy of SalaryPaymentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SalaryPaymentModelImplCopyWith<_$SalaryPaymentModelImpl> get copyWith =>
      __$$SalaryPaymentModelImplCopyWithImpl<_$SalaryPaymentModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SalaryPaymentModelImplToJson(
      this,
    );
  }
}

abstract class _SalaryPaymentModel implements SalaryPaymentModel {
  const factory _SalaryPaymentModel(
      {required final int id,
      required final int employeeId,
      final String periodLabel,
      final double basicSalary,
      final double additions,
      final double deductions,
      final double netAmount,
      required final DateTime paymentDate,
      final int? voucherId,
      final String notes}) = _$SalaryPaymentModelImpl;

  factory _SalaryPaymentModel.fromJson(Map<String, dynamic> json) =
      _$SalaryPaymentModelImpl.fromJson;

  /// المعرّف الفريد
  @override
  int get id;

  /// معرّف الموظف
  @override
  int get employeeId;

  /// التسمية: 'يناير 2025' أو 'الربع الأول 2025'
  @override
  String get periodLabel;

  /// الراتب الأساسي
  @override
  double get basicSalary;

  /// الإضافات (بدلات، مكافآت)
  @override
  double get additions;

  /// الخصومات (سلف، غيابات)
  @override
  double get deductions;

  /// الصافي المدفوع = basicSalary + additions - deductions
  @override
  double get netAmount;

  /// تاريخ الصرف
  @override
  DateTime get paymentDate;

  /// معرّف السند المُولَّد تلقائياً
  @override
  int? get voucherId;

  /// ملاحظات
  @override
  String get notes;

  /// Create a copy of SalaryPaymentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SalaryPaymentModelImplCopyWith<_$SalaryPaymentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
