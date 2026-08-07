// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'advance_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AdvanceModel _$AdvanceModelFromJson(Map<String, dynamic> json) {
  return _AdvanceModel.fromJson(json);
}

/// @nodoc
mixin _$AdvanceModel {
  /// المعرّف الفريد
  int get id => throw _privateConstructorUsedError;

  /// رقم السلفة (نص لدعم ترقيم مثل '23-أ')
  String get advanceNumber => throw _privateConstructorUsedError;

  /// خزينة المشروع التي أُرسل إليها المبلغ ويُصرَف منها
  int get projectTreasuryId => throw _privateConstructorUsedError;

  /// الفترة المالية
  int get fiscalPeriodId => throw _privateConstructorUsedError;

  /// اسم المشروع (للعرض والتقارير)
  String get projectName => throw _privateConstructorUsedError;

  /// تاريخ السلفة
  DateTime get advanceDate => throw _privateConstructorUsedError;

  /// الحالة — راجع [AdvanceStatus]
  String get status => throw _privateConstructorUsedError;

  /// إجمالي المبالغ كما قُرئت من ملف الإكسل قبل أي تعديل (مرجع المطابقة)
  double get excelTotal => throw _privateConstructorUsedError;

  /// اسم ملف الإكسل المستورَد
  String get sourceFileName => throw _privateConstructorUsedError;

  /// بصمة SHA-256 لمحتوى الملف — لكشف الاستيراد المكرر
  String get sourceFileHash => throw _privateConstructorUsedError;

  /// مقدار العجز وقت الاعتماد (0 = لا عجز)
  double get deficitAmount => throw _privateConstructorUsedError;

  /// اسم من غطّى العجز من ماله — الدائن على الشركة
  String? get deficitCoveredBy => throw _privateConstructorUsedError;

  /// ملاحظات
  String get notes => throw _privateConstructorUsedError;

  /// من أنشأ السلفة ومتى
  int? get createdByUserId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// من اعتمدها ومتى
  int? get postedByUserId => throw _privateConstructorUsedError;
  DateTime? get postedAt => throw _privateConstructorUsedError;

  /// من ألغاها ومتى
  int? get cancelledByUserId => throw _privateConstructorUsedError;
  DateTime? get cancelledAt => throw _privateConstructorUsedError;

  /// Serializes this AdvanceModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdvanceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdvanceModelCopyWith<AdvanceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdvanceModelCopyWith<$Res> {
  factory $AdvanceModelCopyWith(
          AdvanceModel value, $Res Function(AdvanceModel) then) =
      _$AdvanceModelCopyWithImpl<$Res, AdvanceModel>;
  @useResult
  $Res call(
      {int id,
      String advanceNumber,
      int projectTreasuryId,
      int fiscalPeriodId,
      String projectName,
      DateTime advanceDate,
      String status,
      double excelTotal,
      String sourceFileName,
      String sourceFileHash,
      double deficitAmount,
      String? deficitCoveredBy,
      String notes,
      int? createdByUserId,
      DateTime createdAt,
      int? postedByUserId,
      DateTime? postedAt,
      int? cancelledByUserId,
      DateTime? cancelledAt});
}

/// @nodoc
class _$AdvanceModelCopyWithImpl<$Res, $Val extends AdvanceModel>
    implements $AdvanceModelCopyWith<$Res> {
  _$AdvanceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdvanceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? advanceNumber = null,
    Object? projectTreasuryId = null,
    Object? fiscalPeriodId = null,
    Object? projectName = null,
    Object? advanceDate = null,
    Object? status = null,
    Object? excelTotal = null,
    Object? sourceFileName = null,
    Object? sourceFileHash = null,
    Object? deficitAmount = null,
    Object? deficitCoveredBy = freezed,
    Object? notes = null,
    Object? createdByUserId = freezed,
    Object? createdAt = null,
    Object? postedByUserId = freezed,
    Object? postedAt = freezed,
    Object? cancelledByUserId = freezed,
    Object? cancelledAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      advanceNumber: null == advanceNumber
          ? _value.advanceNumber
          : advanceNumber // ignore: cast_nullable_to_non_nullable
              as String,
      projectTreasuryId: null == projectTreasuryId
          ? _value.projectTreasuryId
          : projectTreasuryId // ignore: cast_nullable_to_non_nullable
              as int,
      fiscalPeriodId: null == fiscalPeriodId
          ? _value.fiscalPeriodId
          : fiscalPeriodId // ignore: cast_nullable_to_non_nullable
              as int,
      projectName: null == projectName
          ? _value.projectName
          : projectName // ignore: cast_nullable_to_non_nullable
              as String,
      advanceDate: null == advanceDate
          ? _value.advanceDate
          : advanceDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      excelTotal: null == excelTotal
          ? _value.excelTotal
          : excelTotal // ignore: cast_nullable_to_non_nullable
              as double,
      sourceFileName: null == sourceFileName
          ? _value.sourceFileName
          : sourceFileName // ignore: cast_nullable_to_non_nullable
              as String,
      sourceFileHash: null == sourceFileHash
          ? _value.sourceFileHash
          : sourceFileHash // ignore: cast_nullable_to_non_nullable
              as String,
      deficitAmount: null == deficitAmount
          ? _value.deficitAmount
          : deficitAmount // ignore: cast_nullable_to_non_nullable
              as double,
      deficitCoveredBy: freezed == deficitCoveredBy
          ? _value.deficitCoveredBy
          : deficitCoveredBy // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
      createdByUserId: freezed == createdByUserId
          ? _value.createdByUserId
          : createdByUserId // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      postedByUserId: freezed == postedByUserId
          ? _value.postedByUserId
          : postedByUserId // ignore: cast_nullable_to_non_nullable
              as int?,
      postedAt: freezed == postedAt
          ? _value.postedAt
          : postedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelledByUserId: freezed == cancelledByUserId
          ? _value.cancelledByUserId
          : cancelledByUserId // ignore: cast_nullable_to_non_nullable
              as int?,
      cancelledAt: freezed == cancelledAt
          ? _value.cancelledAt
          : cancelledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdvanceModelImplCopyWith<$Res>
    implements $AdvanceModelCopyWith<$Res> {
  factory _$$AdvanceModelImplCopyWith(
          _$AdvanceModelImpl value, $Res Function(_$AdvanceModelImpl) then) =
      __$$AdvanceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String advanceNumber,
      int projectTreasuryId,
      int fiscalPeriodId,
      String projectName,
      DateTime advanceDate,
      String status,
      double excelTotal,
      String sourceFileName,
      String sourceFileHash,
      double deficitAmount,
      String? deficitCoveredBy,
      String notes,
      int? createdByUserId,
      DateTime createdAt,
      int? postedByUserId,
      DateTime? postedAt,
      int? cancelledByUserId,
      DateTime? cancelledAt});
}

/// @nodoc
class __$$AdvanceModelImplCopyWithImpl<$Res>
    extends _$AdvanceModelCopyWithImpl<$Res, _$AdvanceModelImpl>
    implements _$$AdvanceModelImplCopyWith<$Res> {
  __$$AdvanceModelImplCopyWithImpl(
      _$AdvanceModelImpl _value, $Res Function(_$AdvanceModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdvanceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? advanceNumber = null,
    Object? projectTreasuryId = null,
    Object? fiscalPeriodId = null,
    Object? projectName = null,
    Object? advanceDate = null,
    Object? status = null,
    Object? excelTotal = null,
    Object? sourceFileName = null,
    Object? sourceFileHash = null,
    Object? deficitAmount = null,
    Object? deficitCoveredBy = freezed,
    Object? notes = null,
    Object? createdByUserId = freezed,
    Object? createdAt = null,
    Object? postedByUserId = freezed,
    Object? postedAt = freezed,
    Object? cancelledByUserId = freezed,
    Object? cancelledAt = freezed,
  }) {
    return _then(_$AdvanceModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      advanceNumber: null == advanceNumber
          ? _value.advanceNumber
          : advanceNumber // ignore: cast_nullable_to_non_nullable
              as String,
      projectTreasuryId: null == projectTreasuryId
          ? _value.projectTreasuryId
          : projectTreasuryId // ignore: cast_nullable_to_non_nullable
              as int,
      fiscalPeriodId: null == fiscalPeriodId
          ? _value.fiscalPeriodId
          : fiscalPeriodId // ignore: cast_nullable_to_non_nullable
              as int,
      projectName: null == projectName
          ? _value.projectName
          : projectName // ignore: cast_nullable_to_non_nullable
              as String,
      advanceDate: null == advanceDate
          ? _value.advanceDate
          : advanceDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      excelTotal: null == excelTotal
          ? _value.excelTotal
          : excelTotal // ignore: cast_nullable_to_non_nullable
              as double,
      sourceFileName: null == sourceFileName
          ? _value.sourceFileName
          : sourceFileName // ignore: cast_nullable_to_non_nullable
              as String,
      sourceFileHash: null == sourceFileHash
          ? _value.sourceFileHash
          : sourceFileHash // ignore: cast_nullable_to_non_nullable
              as String,
      deficitAmount: null == deficitAmount
          ? _value.deficitAmount
          : deficitAmount // ignore: cast_nullable_to_non_nullable
              as double,
      deficitCoveredBy: freezed == deficitCoveredBy
          ? _value.deficitCoveredBy
          : deficitCoveredBy // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
      createdByUserId: freezed == createdByUserId
          ? _value.createdByUserId
          : createdByUserId // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      postedByUserId: freezed == postedByUserId
          ? _value.postedByUserId
          : postedByUserId // ignore: cast_nullable_to_non_nullable
              as int?,
      postedAt: freezed == postedAt
          ? _value.postedAt
          : postedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelledByUserId: freezed == cancelledByUserId
          ? _value.cancelledByUserId
          : cancelledByUserId // ignore: cast_nullable_to_non_nullable
              as int?,
      cancelledAt: freezed == cancelledAt
          ? _value.cancelledAt
          : cancelledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdvanceModelImpl implements _AdvanceModel {
  const _$AdvanceModelImpl(
      {required this.id,
      required this.advanceNumber,
      required this.projectTreasuryId,
      required this.fiscalPeriodId,
      this.projectName = '',
      required this.advanceDate,
      this.status = AdvanceStatus.open,
      this.excelTotal = 0.0,
      this.sourceFileName = '',
      this.sourceFileHash = '',
      this.deficitAmount = 0.0,
      this.deficitCoveredBy,
      this.notes = '',
      this.createdByUserId,
      required this.createdAt,
      this.postedByUserId,
      this.postedAt,
      this.cancelledByUserId,
      this.cancelledAt});

  factory _$AdvanceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdvanceModelImplFromJson(json);

  /// المعرّف الفريد
  @override
  final int id;

  /// رقم السلفة (نص لدعم ترقيم مثل '23-أ')
  @override
  final String advanceNumber;

  /// خزينة المشروع التي أُرسل إليها المبلغ ويُصرَف منها
  @override
  final int projectTreasuryId;

  /// الفترة المالية
  @override
  final int fiscalPeriodId;

  /// اسم المشروع (للعرض والتقارير)
  @override
  @JsonKey()
  final String projectName;

  /// تاريخ السلفة
  @override
  final DateTime advanceDate;

  /// الحالة — راجع [AdvanceStatus]
  @override
  @JsonKey()
  final String status;

  /// إجمالي المبالغ كما قُرئت من ملف الإكسل قبل أي تعديل (مرجع المطابقة)
  @override
  @JsonKey()
  final double excelTotal;

  /// اسم ملف الإكسل المستورَد
  @override
  @JsonKey()
  final String sourceFileName;

  /// بصمة SHA-256 لمحتوى الملف — لكشف الاستيراد المكرر
  @override
  @JsonKey()
  final String sourceFileHash;

  /// مقدار العجز وقت الاعتماد (0 = لا عجز)
  @override
  @JsonKey()
  final double deficitAmount;

  /// اسم من غطّى العجز من ماله — الدائن على الشركة
  @override
  final String? deficitCoveredBy;

  /// ملاحظات
  @override
  @JsonKey()
  final String notes;

  /// من أنشأ السلفة ومتى
  @override
  final int? createdByUserId;
  @override
  final DateTime createdAt;

  /// من اعتمدها ومتى
  @override
  final int? postedByUserId;
  @override
  final DateTime? postedAt;

  /// من ألغاها ومتى
  @override
  final int? cancelledByUserId;
  @override
  final DateTime? cancelledAt;

  @override
  String toString() {
    return 'AdvanceModel(id: $id, advanceNumber: $advanceNumber, projectTreasuryId: $projectTreasuryId, fiscalPeriodId: $fiscalPeriodId, projectName: $projectName, advanceDate: $advanceDate, status: $status, excelTotal: $excelTotal, sourceFileName: $sourceFileName, sourceFileHash: $sourceFileHash, deficitAmount: $deficitAmount, deficitCoveredBy: $deficitCoveredBy, notes: $notes, createdByUserId: $createdByUserId, createdAt: $createdAt, postedByUserId: $postedByUserId, postedAt: $postedAt, cancelledByUserId: $cancelledByUserId, cancelledAt: $cancelledAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdvanceModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.advanceNumber, advanceNumber) ||
                other.advanceNumber == advanceNumber) &&
            (identical(other.projectTreasuryId, projectTreasuryId) ||
                other.projectTreasuryId == projectTreasuryId) &&
            (identical(other.fiscalPeriodId, fiscalPeriodId) ||
                other.fiscalPeriodId == fiscalPeriodId) &&
            (identical(other.projectName, projectName) ||
                other.projectName == projectName) &&
            (identical(other.advanceDate, advanceDate) ||
                other.advanceDate == advanceDate) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.excelTotal, excelTotal) ||
                other.excelTotal == excelTotal) &&
            (identical(other.sourceFileName, sourceFileName) ||
                other.sourceFileName == sourceFileName) &&
            (identical(other.sourceFileHash, sourceFileHash) ||
                other.sourceFileHash == sourceFileHash) &&
            (identical(other.deficitAmount, deficitAmount) ||
                other.deficitAmount == deficitAmount) &&
            (identical(other.deficitCoveredBy, deficitCoveredBy) ||
                other.deficitCoveredBy == deficitCoveredBy) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdByUserId, createdByUserId) ||
                other.createdByUserId == createdByUserId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.postedByUserId, postedByUserId) ||
                other.postedByUserId == postedByUserId) &&
            (identical(other.postedAt, postedAt) ||
                other.postedAt == postedAt) &&
            (identical(other.cancelledByUserId, cancelledByUserId) ||
                other.cancelledByUserId == cancelledByUserId) &&
            (identical(other.cancelledAt, cancelledAt) ||
                other.cancelledAt == cancelledAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        advanceNumber,
        projectTreasuryId,
        fiscalPeriodId,
        projectName,
        advanceDate,
        status,
        excelTotal,
        sourceFileName,
        sourceFileHash,
        deficitAmount,
        deficitCoveredBy,
        notes,
        createdByUserId,
        createdAt,
        postedByUserId,
        postedAt,
        cancelledByUserId,
        cancelledAt
      ]);

  /// Create a copy of AdvanceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdvanceModelImplCopyWith<_$AdvanceModelImpl> get copyWith =>
      __$$AdvanceModelImplCopyWithImpl<_$AdvanceModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdvanceModelImplToJson(
      this,
    );
  }
}

abstract class _AdvanceModel implements AdvanceModel {
  const factory _AdvanceModel(
      {required final int id,
      required final String advanceNumber,
      required final int projectTreasuryId,
      required final int fiscalPeriodId,
      final String projectName,
      required final DateTime advanceDate,
      final String status,
      final double excelTotal,
      final String sourceFileName,
      final String sourceFileHash,
      final double deficitAmount,
      final String? deficitCoveredBy,
      final String notes,
      final int? createdByUserId,
      required final DateTime createdAt,
      final int? postedByUserId,
      final DateTime? postedAt,
      final int? cancelledByUserId,
      final DateTime? cancelledAt}) = _$AdvanceModelImpl;

  factory _AdvanceModel.fromJson(Map<String, dynamic> json) =
      _$AdvanceModelImpl.fromJson;

  /// المعرّف الفريد
  @override
  int get id;

  /// رقم السلفة (نص لدعم ترقيم مثل '23-أ')
  @override
  String get advanceNumber;

  /// خزينة المشروع التي أُرسل إليها المبلغ ويُصرَف منها
  @override
  int get projectTreasuryId;

  /// الفترة المالية
  @override
  int get fiscalPeriodId;

  /// اسم المشروع (للعرض والتقارير)
  @override
  String get projectName;

  /// تاريخ السلفة
  @override
  DateTime get advanceDate;

  /// الحالة — راجع [AdvanceStatus]
  @override
  String get status;

  /// إجمالي المبالغ كما قُرئت من ملف الإكسل قبل أي تعديل (مرجع المطابقة)
  @override
  double get excelTotal;

  /// اسم ملف الإكسل المستورَد
  @override
  String get sourceFileName;

  /// بصمة SHA-256 لمحتوى الملف — لكشف الاستيراد المكرر
  @override
  String get sourceFileHash;

  /// مقدار العجز وقت الاعتماد (0 = لا عجز)
  @override
  double get deficitAmount;

  /// اسم من غطّى العجز من ماله — الدائن على الشركة
  @override
  String? get deficitCoveredBy;

  /// ملاحظات
  @override
  String get notes;

  /// من أنشأ السلفة ومتى
  @override
  int? get createdByUserId;
  @override
  DateTime get createdAt;

  /// من اعتمدها ومتى
  @override
  int? get postedByUserId;
  @override
  DateTime? get postedAt;

  /// من ألغاها ومتى
  @override
  int? get cancelledByUserId;
  @override
  DateTime? get cancelledAt;

  /// Create a copy of AdvanceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdvanceModelImplCopyWith<_$AdvanceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdvanceLineModel _$AdvanceLineModelFromJson(Map<String, dynamic> json) {
  return _AdvanceLineModel.fromJson(json);
}

/// @nodoc
mixin _$AdvanceLineModel {
  /// المعرّف الفريد
  int get id => throw _privateConstructorUsedError;

  /// السلفة التي ينتمي إليها
  int get advanceId => throw _privateConstructorUsedError;

  /// رقم الصف في ملف الإكسل الأصلي
  int get rowNumber => throw _privateConstructorUsedError;

  /// تاريخ الصرف
  DateTime get voucherDate => throw _privateConstructorUsedError;

  /// المبلغ بالدينار (الاستيراد لا يقبل الدولار)
  double get amount => throw _privateConstructorUsedError;

  /// نوع البند / الفلتر — كهربائيات، بانزين، راتب…
  String get itemType => throw _privateConstructorUsedError;

  /// السبب / البيان
  String get reason => throw _privateConstructorUsedError;

  /// اسم الشخص المرتبط بالمصروف
  String get personName => throw _privateConstructorUsedError;

  /// اسم المشروع كما ورد في الملف
  String? get projectName => throw _privateConstructorUsedError;

  /// رقم الفاتورة أو الوصل
  String? get invoiceNumber => throw _privateConstructorUsedError;

  /// من قام بالصرف فعلياً في الموقع
  String? get spentBy => throw _privateConstructorUsedError;

  /// ── القيم الأصلية من الإكسل (لا تتغير أبداً) ──
  double get originalAmount => throw _privateConstructorUsedError;
  String get originalItemType => throw _privateConstructorUsedError;
  DateTime get originalDate => throw _privateConstructorUsedError;

  /// هل عُدِّل هذا السطر عن أصله؟
  bool get isEdited => throw _privateConstructorUsedError;

  /// هل استُبعد من الاعتماد؟
  bool get isExcluded => throw _privateConstructorUsedError;

  /// سبب الاستبعاد
  String get excludeReason => throw _privateConstructorUsedError;

  /// معرّف السند الناتج بعد الاعتماد — null ما دامت مسودة
  int? get voucherId => throw _privateConstructorUsedError;

  /// Serializes this AdvanceLineModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdvanceLineModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdvanceLineModelCopyWith<AdvanceLineModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdvanceLineModelCopyWith<$Res> {
  factory $AdvanceLineModelCopyWith(
          AdvanceLineModel value, $Res Function(AdvanceLineModel) then) =
      _$AdvanceLineModelCopyWithImpl<$Res, AdvanceLineModel>;
  @useResult
  $Res call(
      {int id,
      int advanceId,
      int rowNumber,
      DateTime voucherDate,
      double amount,
      String itemType,
      String reason,
      String personName,
      String? projectName,
      String? invoiceNumber,
      String? spentBy,
      double originalAmount,
      String originalItemType,
      DateTime originalDate,
      bool isEdited,
      bool isExcluded,
      String excludeReason,
      int? voucherId});
}

/// @nodoc
class _$AdvanceLineModelCopyWithImpl<$Res, $Val extends AdvanceLineModel>
    implements $AdvanceLineModelCopyWith<$Res> {
  _$AdvanceLineModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdvanceLineModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? advanceId = null,
    Object? rowNumber = null,
    Object? voucherDate = null,
    Object? amount = null,
    Object? itemType = null,
    Object? reason = null,
    Object? personName = null,
    Object? projectName = freezed,
    Object? invoiceNumber = freezed,
    Object? spentBy = freezed,
    Object? originalAmount = null,
    Object? originalItemType = null,
    Object? originalDate = null,
    Object? isEdited = null,
    Object? isExcluded = null,
    Object? excludeReason = null,
    Object? voucherId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      advanceId: null == advanceId
          ? _value.advanceId
          : advanceId // ignore: cast_nullable_to_non_nullable
              as int,
      rowNumber: null == rowNumber
          ? _value.rowNumber
          : rowNumber // ignore: cast_nullable_to_non_nullable
              as int,
      voucherDate: null == voucherDate
          ? _value.voucherDate
          : voucherDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      itemType: null == itemType
          ? _value.itemType
          : itemType // ignore: cast_nullable_to_non_nullable
              as String,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      personName: null == personName
          ? _value.personName
          : personName // ignore: cast_nullable_to_non_nullable
              as String,
      projectName: freezed == projectName
          ? _value.projectName
          : projectName // ignore: cast_nullable_to_non_nullable
              as String?,
      invoiceNumber: freezed == invoiceNumber
          ? _value.invoiceNumber
          : invoiceNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      spentBy: freezed == spentBy
          ? _value.spentBy
          : spentBy // ignore: cast_nullable_to_non_nullable
              as String?,
      originalAmount: null == originalAmount
          ? _value.originalAmount
          : originalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      originalItemType: null == originalItemType
          ? _value.originalItemType
          : originalItemType // ignore: cast_nullable_to_non_nullable
              as String,
      originalDate: null == originalDate
          ? _value.originalDate
          : originalDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isEdited: null == isEdited
          ? _value.isEdited
          : isEdited // ignore: cast_nullable_to_non_nullable
              as bool,
      isExcluded: null == isExcluded
          ? _value.isExcluded
          : isExcluded // ignore: cast_nullable_to_non_nullable
              as bool,
      excludeReason: null == excludeReason
          ? _value.excludeReason
          : excludeReason // ignore: cast_nullable_to_non_nullable
              as String,
      voucherId: freezed == voucherId
          ? _value.voucherId
          : voucherId // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdvanceLineModelImplCopyWith<$Res>
    implements $AdvanceLineModelCopyWith<$Res> {
  factory _$$AdvanceLineModelImplCopyWith(_$AdvanceLineModelImpl value,
          $Res Function(_$AdvanceLineModelImpl) then) =
      __$$AdvanceLineModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int advanceId,
      int rowNumber,
      DateTime voucherDate,
      double amount,
      String itemType,
      String reason,
      String personName,
      String? projectName,
      String? invoiceNumber,
      String? spentBy,
      double originalAmount,
      String originalItemType,
      DateTime originalDate,
      bool isEdited,
      bool isExcluded,
      String excludeReason,
      int? voucherId});
}

/// @nodoc
class __$$AdvanceLineModelImplCopyWithImpl<$Res>
    extends _$AdvanceLineModelCopyWithImpl<$Res, _$AdvanceLineModelImpl>
    implements _$$AdvanceLineModelImplCopyWith<$Res> {
  __$$AdvanceLineModelImplCopyWithImpl(_$AdvanceLineModelImpl _value,
      $Res Function(_$AdvanceLineModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdvanceLineModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? advanceId = null,
    Object? rowNumber = null,
    Object? voucherDate = null,
    Object? amount = null,
    Object? itemType = null,
    Object? reason = null,
    Object? personName = null,
    Object? projectName = freezed,
    Object? invoiceNumber = freezed,
    Object? spentBy = freezed,
    Object? originalAmount = null,
    Object? originalItemType = null,
    Object? originalDate = null,
    Object? isEdited = null,
    Object? isExcluded = null,
    Object? excludeReason = null,
    Object? voucherId = freezed,
  }) {
    return _then(_$AdvanceLineModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      advanceId: null == advanceId
          ? _value.advanceId
          : advanceId // ignore: cast_nullable_to_non_nullable
              as int,
      rowNumber: null == rowNumber
          ? _value.rowNumber
          : rowNumber // ignore: cast_nullable_to_non_nullable
              as int,
      voucherDate: null == voucherDate
          ? _value.voucherDate
          : voucherDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      itemType: null == itemType
          ? _value.itemType
          : itemType // ignore: cast_nullable_to_non_nullable
              as String,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      personName: null == personName
          ? _value.personName
          : personName // ignore: cast_nullable_to_non_nullable
              as String,
      projectName: freezed == projectName
          ? _value.projectName
          : projectName // ignore: cast_nullable_to_non_nullable
              as String?,
      invoiceNumber: freezed == invoiceNumber
          ? _value.invoiceNumber
          : invoiceNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      spentBy: freezed == spentBy
          ? _value.spentBy
          : spentBy // ignore: cast_nullable_to_non_nullable
              as String?,
      originalAmount: null == originalAmount
          ? _value.originalAmount
          : originalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      originalItemType: null == originalItemType
          ? _value.originalItemType
          : originalItemType // ignore: cast_nullable_to_non_nullable
              as String,
      originalDate: null == originalDate
          ? _value.originalDate
          : originalDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isEdited: null == isEdited
          ? _value.isEdited
          : isEdited // ignore: cast_nullable_to_non_nullable
              as bool,
      isExcluded: null == isExcluded
          ? _value.isExcluded
          : isExcluded // ignore: cast_nullable_to_non_nullable
              as bool,
      excludeReason: null == excludeReason
          ? _value.excludeReason
          : excludeReason // ignore: cast_nullable_to_non_nullable
              as String,
      voucherId: freezed == voucherId
          ? _value.voucherId
          : voucherId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdvanceLineModelImpl implements _AdvanceLineModel {
  const _$AdvanceLineModelImpl(
      {required this.id,
      required this.advanceId,
      this.rowNumber = 0,
      required this.voucherDate,
      required this.amount,
      this.itemType = '',
      this.reason = '',
      this.personName = '',
      this.projectName,
      this.invoiceNumber,
      this.spentBy,
      required this.originalAmount,
      this.originalItemType = '',
      required this.originalDate,
      this.isEdited = false,
      this.isExcluded = false,
      this.excludeReason = '',
      this.voucherId});

  factory _$AdvanceLineModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdvanceLineModelImplFromJson(json);

  /// المعرّف الفريد
  @override
  final int id;

  /// السلفة التي ينتمي إليها
  @override
  final int advanceId;

  /// رقم الصف في ملف الإكسل الأصلي
  @override
  @JsonKey()
  final int rowNumber;

  /// تاريخ الصرف
  @override
  final DateTime voucherDate;

  /// المبلغ بالدينار (الاستيراد لا يقبل الدولار)
  @override
  final double amount;

  /// نوع البند / الفلتر — كهربائيات، بانزين، راتب…
  @override
  @JsonKey()
  final String itemType;

  /// السبب / البيان
  @override
  @JsonKey()
  final String reason;

  /// اسم الشخص المرتبط بالمصروف
  @override
  @JsonKey()
  final String personName;

  /// اسم المشروع كما ورد في الملف
  @override
  final String? projectName;

  /// رقم الفاتورة أو الوصل
  @override
  final String? invoiceNumber;

  /// من قام بالصرف فعلياً في الموقع
  @override
  final String? spentBy;

  /// ── القيم الأصلية من الإكسل (لا تتغير أبداً) ──
  @override
  final double originalAmount;
  @override
  @JsonKey()
  final String originalItemType;
  @override
  final DateTime originalDate;

  /// هل عُدِّل هذا السطر عن أصله؟
  @override
  @JsonKey()
  final bool isEdited;

  /// هل استُبعد من الاعتماد؟
  @override
  @JsonKey()
  final bool isExcluded;

  /// سبب الاستبعاد
  @override
  @JsonKey()
  final String excludeReason;

  /// معرّف السند الناتج بعد الاعتماد — null ما دامت مسودة
  @override
  final int? voucherId;

  @override
  String toString() {
    return 'AdvanceLineModel(id: $id, advanceId: $advanceId, rowNumber: $rowNumber, voucherDate: $voucherDate, amount: $amount, itemType: $itemType, reason: $reason, personName: $personName, projectName: $projectName, invoiceNumber: $invoiceNumber, spentBy: $spentBy, originalAmount: $originalAmount, originalItemType: $originalItemType, originalDate: $originalDate, isEdited: $isEdited, isExcluded: $isExcluded, excludeReason: $excludeReason, voucherId: $voucherId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdvanceLineModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.advanceId, advanceId) ||
                other.advanceId == advanceId) &&
            (identical(other.rowNumber, rowNumber) ||
                other.rowNumber == rowNumber) &&
            (identical(other.voucherDate, voucherDate) ||
                other.voucherDate == voucherDate) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.itemType, itemType) ||
                other.itemType == itemType) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.personName, personName) ||
                other.personName == personName) &&
            (identical(other.projectName, projectName) ||
                other.projectName == projectName) &&
            (identical(other.invoiceNumber, invoiceNumber) ||
                other.invoiceNumber == invoiceNumber) &&
            (identical(other.spentBy, spentBy) || other.spentBy == spentBy) &&
            (identical(other.originalAmount, originalAmount) ||
                other.originalAmount == originalAmount) &&
            (identical(other.originalItemType, originalItemType) ||
                other.originalItemType == originalItemType) &&
            (identical(other.originalDate, originalDate) ||
                other.originalDate == originalDate) &&
            (identical(other.isEdited, isEdited) ||
                other.isEdited == isEdited) &&
            (identical(other.isExcluded, isExcluded) ||
                other.isExcluded == isExcluded) &&
            (identical(other.excludeReason, excludeReason) ||
                other.excludeReason == excludeReason) &&
            (identical(other.voucherId, voucherId) ||
                other.voucherId == voucherId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      advanceId,
      rowNumber,
      voucherDate,
      amount,
      itemType,
      reason,
      personName,
      projectName,
      invoiceNumber,
      spentBy,
      originalAmount,
      originalItemType,
      originalDate,
      isEdited,
      isExcluded,
      excludeReason,
      voucherId);

  /// Create a copy of AdvanceLineModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdvanceLineModelImplCopyWith<_$AdvanceLineModelImpl> get copyWith =>
      __$$AdvanceLineModelImplCopyWithImpl<_$AdvanceLineModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdvanceLineModelImplToJson(
      this,
    );
  }
}

abstract class _AdvanceLineModel implements AdvanceLineModel {
  const factory _AdvanceLineModel(
      {required final int id,
      required final int advanceId,
      final int rowNumber,
      required final DateTime voucherDate,
      required final double amount,
      final String itemType,
      final String reason,
      final String personName,
      final String? projectName,
      final String? invoiceNumber,
      final String? spentBy,
      required final double originalAmount,
      final String originalItemType,
      required final DateTime originalDate,
      final bool isEdited,
      final bool isExcluded,
      final String excludeReason,
      final int? voucherId}) = _$AdvanceLineModelImpl;

  factory _AdvanceLineModel.fromJson(Map<String, dynamic> json) =
      _$AdvanceLineModelImpl.fromJson;

  /// المعرّف الفريد
  @override
  int get id;

  /// السلفة التي ينتمي إليها
  @override
  int get advanceId;

  /// رقم الصف في ملف الإكسل الأصلي
  @override
  int get rowNumber;

  /// تاريخ الصرف
  @override
  DateTime get voucherDate;

  /// المبلغ بالدينار (الاستيراد لا يقبل الدولار)
  @override
  double get amount;

  /// نوع البند / الفلتر — كهربائيات، بانزين، راتب…
  @override
  String get itemType;

  /// السبب / البيان
  @override
  String get reason;

  /// اسم الشخص المرتبط بالمصروف
  @override
  String get personName;

  /// اسم المشروع كما ورد في الملف
  @override
  String? get projectName;

  /// رقم الفاتورة أو الوصل
  @override
  String? get invoiceNumber;

  /// من قام بالصرف فعلياً في الموقع
  @override
  String? get spentBy;

  /// ── القيم الأصلية من الإكسل (لا تتغير أبداً) ──
  @override
  double get originalAmount;
  @override
  String get originalItemType;
  @override
  DateTime get originalDate;

  /// هل عُدِّل هذا السطر عن أصله؟
  @override
  bool get isEdited;

  /// هل استُبعد من الاعتماد؟
  @override
  bool get isExcluded;

  /// سبب الاستبعاد
  @override
  String get excludeReason;

  /// معرّف السند الناتج بعد الاعتماد — null ما دامت مسودة
  @override
  int? get voucherId;

  /// Create a copy of AdvanceLineModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdvanceLineModelImplCopyWith<_$AdvanceLineModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdvanceSummary _$AdvanceSummaryFromJson(Map<String, dynamic> json) {
  return _AdvanceSummary.fromJson(json);
}

/// @nodoc
mixin _$AdvanceSummary {
  /// المبلغ المُرسَل للمشروع — مجموع سندات التحويل الواردة المرتبطة بالسلفة
  double get sent => throw _privateConstructorUsedError;

  /// المصروف — مجموع أسطر المسودة غير المستبعدة (قبل الاعتماد)
  /// أو مجموع سندات الصرف المرتبطة (بعد الاعتماد)
  double get spent => throw _privateConstructorUsedError;

  /// إجمالي ملف الإكسل كما وصل — مرجع ثابت للمطابقة
  double get excelTotal => throw _privateConstructorUsedError;

  /// رصيد خزينة المشروع الحالي
  double get treasuryBalance => throw _privateConstructorUsedError;

  /// عدد الأسطر الداخلة في الحساب
  int get countedLines => throw _privateConstructorUsedError;

  /// عدد الأسطر المستبعدة
  int get excludedLines => throw _privateConstructorUsedError;

  /// عدد الأسطر المعدَّلة عن أصلها
  int get editedLines => throw _privateConstructorUsedError;

  /// هل السلفة معتُمدة بالفعل؟
  ///
  /// يغيّر معنى [AdvanceSummaryX.deficit] جذرياً — راجع تعليقه.
  bool get isPosted => throw _privateConstructorUsedError;

  /// العجز المُثبَّت وقت الاعتماد (يُقرأ من السلفة، ذو معنى بعد الاعتماد فقط)
  double get postedDeficit => throw _privateConstructorUsedError;

  /// Serializes this AdvanceSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdvanceSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdvanceSummaryCopyWith<AdvanceSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdvanceSummaryCopyWith<$Res> {
  factory $AdvanceSummaryCopyWith(
          AdvanceSummary value, $Res Function(AdvanceSummary) then) =
      _$AdvanceSummaryCopyWithImpl<$Res, AdvanceSummary>;
  @useResult
  $Res call(
      {double sent,
      double spent,
      double excelTotal,
      double treasuryBalance,
      int countedLines,
      int excludedLines,
      int editedLines,
      bool isPosted,
      double postedDeficit});
}

/// @nodoc
class _$AdvanceSummaryCopyWithImpl<$Res, $Val extends AdvanceSummary>
    implements $AdvanceSummaryCopyWith<$Res> {
  _$AdvanceSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdvanceSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sent = null,
    Object? spent = null,
    Object? excelTotal = null,
    Object? treasuryBalance = null,
    Object? countedLines = null,
    Object? excludedLines = null,
    Object? editedLines = null,
    Object? isPosted = null,
    Object? postedDeficit = null,
  }) {
    return _then(_value.copyWith(
      sent: null == sent
          ? _value.sent
          : sent // ignore: cast_nullable_to_non_nullable
              as double,
      spent: null == spent
          ? _value.spent
          : spent // ignore: cast_nullable_to_non_nullable
              as double,
      excelTotal: null == excelTotal
          ? _value.excelTotal
          : excelTotal // ignore: cast_nullable_to_non_nullable
              as double,
      treasuryBalance: null == treasuryBalance
          ? _value.treasuryBalance
          : treasuryBalance // ignore: cast_nullable_to_non_nullable
              as double,
      countedLines: null == countedLines
          ? _value.countedLines
          : countedLines // ignore: cast_nullable_to_non_nullable
              as int,
      excludedLines: null == excludedLines
          ? _value.excludedLines
          : excludedLines // ignore: cast_nullable_to_non_nullable
              as int,
      editedLines: null == editedLines
          ? _value.editedLines
          : editedLines // ignore: cast_nullable_to_non_nullable
              as int,
      isPosted: null == isPosted
          ? _value.isPosted
          : isPosted // ignore: cast_nullable_to_non_nullable
              as bool,
      postedDeficit: null == postedDeficit
          ? _value.postedDeficit
          : postedDeficit // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdvanceSummaryImplCopyWith<$Res>
    implements $AdvanceSummaryCopyWith<$Res> {
  factory _$$AdvanceSummaryImplCopyWith(_$AdvanceSummaryImpl value,
          $Res Function(_$AdvanceSummaryImpl) then) =
      __$$AdvanceSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double sent,
      double spent,
      double excelTotal,
      double treasuryBalance,
      int countedLines,
      int excludedLines,
      int editedLines,
      bool isPosted,
      double postedDeficit});
}

/// @nodoc
class __$$AdvanceSummaryImplCopyWithImpl<$Res>
    extends _$AdvanceSummaryCopyWithImpl<$Res, _$AdvanceSummaryImpl>
    implements _$$AdvanceSummaryImplCopyWith<$Res> {
  __$$AdvanceSummaryImplCopyWithImpl(
      _$AdvanceSummaryImpl _value, $Res Function(_$AdvanceSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdvanceSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sent = null,
    Object? spent = null,
    Object? excelTotal = null,
    Object? treasuryBalance = null,
    Object? countedLines = null,
    Object? excludedLines = null,
    Object? editedLines = null,
    Object? isPosted = null,
    Object? postedDeficit = null,
  }) {
    return _then(_$AdvanceSummaryImpl(
      sent: null == sent
          ? _value.sent
          : sent // ignore: cast_nullable_to_non_nullable
              as double,
      spent: null == spent
          ? _value.spent
          : spent // ignore: cast_nullable_to_non_nullable
              as double,
      excelTotal: null == excelTotal
          ? _value.excelTotal
          : excelTotal // ignore: cast_nullable_to_non_nullable
              as double,
      treasuryBalance: null == treasuryBalance
          ? _value.treasuryBalance
          : treasuryBalance // ignore: cast_nullable_to_non_nullable
              as double,
      countedLines: null == countedLines
          ? _value.countedLines
          : countedLines // ignore: cast_nullable_to_non_nullable
              as int,
      excludedLines: null == excludedLines
          ? _value.excludedLines
          : excludedLines // ignore: cast_nullable_to_non_nullable
              as int,
      editedLines: null == editedLines
          ? _value.editedLines
          : editedLines // ignore: cast_nullable_to_non_nullable
              as int,
      isPosted: null == isPosted
          ? _value.isPosted
          : isPosted // ignore: cast_nullable_to_non_nullable
              as bool,
      postedDeficit: null == postedDeficit
          ? _value.postedDeficit
          : postedDeficit // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdvanceSummaryImpl implements _AdvanceSummary {
  const _$AdvanceSummaryImpl(
      {this.sent = 0.0,
      this.spent = 0.0,
      this.excelTotal = 0.0,
      this.treasuryBalance = 0.0,
      this.countedLines = 0,
      this.excludedLines = 0,
      this.editedLines = 0,
      this.isPosted = false,
      this.postedDeficit = 0.0});

  factory _$AdvanceSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdvanceSummaryImplFromJson(json);

  /// المبلغ المُرسَل للمشروع — مجموع سندات التحويل الواردة المرتبطة بالسلفة
  @override
  @JsonKey()
  final double sent;

  /// المصروف — مجموع أسطر المسودة غير المستبعدة (قبل الاعتماد)
  /// أو مجموع سندات الصرف المرتبطة (بعد الاعتماد)
  @override
  @JsonKey()
  final double spent;

  /// إجمالي ملف الإكسل كما وصل — مرجع ثابت للمطابقة
  @override
  @JsonKey()
  final double excelTotal;

  /// رصيد خزينة المشروع الحالي
  @override
  @JsonKey()
  final double treasuryBalance;

  /// عدد الأسطر الداخلة في الحساب
  @override
  @JsonKey()
  final int countedLines;

  /// عدد الأسطر المستبعدة
  @override
  @JsonKey()
  final int excludedLines;

  /// عدد الأسطر المعدَّلة عن أصلها
  @override
  @JsonKey()
  final int editedLines;

  /// هل السلفة معتُمدة بالفعل؟
  ///
  /// يغيّر معنى [AdvanceSummaryX.deficit] جذرياً — راجع تعليقه.
  @override
  @JsonKey()
  final bool isPosted;

  /// العجز المُثبَّت وقت الاعتماد (يُقرأ من السلفة، ذو معنى بعد الاعتماد فقط)
  @override
  @JsonKey()
  final double postedDeficit;

  @override
  String toString() {
    return 'AdvanceSummary(sent: $sent, spent: $spent, excelTotal: $excelTotal, treasuryBalance: $treasuryBalance, countedLines: $countedLines, excludedLines: $excludedLines, editedLines: $editedLines, isPosted: $isPosted, postedDeficit: $postedDeficit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdvanceSummaryImpl &&
            (identical(other.sent, sent) || other.sent == sent) &&
            (identical(other.spent, spent) || other.spent == spent) &&
            (identical(other.excelTotal, excelTotal) ||
                other.excelTotal == excelTotal) &&
            (identical(other.treasuryBalance, treasuryBalance) ||
                other.treasuryBalance == treasuryBalance) &&
            (identical(other.countedLines, countedLines) ||
                other.countedLines == countedLines) &&
            (identical(other.excludedLines, excludedLines) ||
                other.excludedLines == excludedLines) &&
            (identical(other.editedLines, editedLines) ||
                other.editedLines == editedLines) &&
            (identical(other.isPosted, isPosted) ||
                other.isPosted == isPosted) &&
            (identical(other.postedDeficit, postedDeficit) ||
                other.postedDeficit == postedDeficit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      sent,
      spent,
      excelTotal,
      treasuryBalance,
      countedLines,
      excludedLines,
      editedLines,
      isPosted,
      postedDeficit);

  /// Create a copy of AdvanceSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdvanceSummaryImplCopyWith<_$AdvanceSummaryImpl> get copyWith =>
      __$$AdvanceSummaryImplCopyWithImpl<_$AdvanceSummaryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdvanceSummaryImplToJson(
      this,
    );
  }
}

abstract class _AdvanceSummary implements AdvanceSummary {
  const factory _AdvanceSummary(
      {final double sent,
      final double spent,
      final double excelTotal,
      final double treasuryBalance,
      final int countedLines,
      final int excludedLines,
      final int editedLines,
      final bool isPosted,
      final double postedDeficit}) = _$AdvanceSummaryImpl;

  factory _AdvanceSummary.fromJson(Map<String, dynamic> json) =
      _$AdvanceSummaryImpl.fromJson;

  /// المبلغ المُرسَل للمشروع — مجموع سندات التحويل الواردة المرتبطة بالسلفة
  @override
  double get sent;

  /// المصروف — مجموع أسطر المسودة غير المستبعدة (قبل الاعتماد)
  /// أو مجموع سندات الصرف المرتبطة (بعد الاعتماد)
  @override
  double get spent;

  /// إجمالي ملف الإكسل كما وصل — مرجع ثابت للمطابقة
  @override
  double get excelTotal;

  /// رصيد خزينة المشروع الحالي
  @override
  double get treasuryBalance;

  /// عدد الأسطر الداخلة في الحساب
  @override
  int get countedLines;

  /// عدد الأسطر المستبعدة
  @override
  int get excludedLines;

  /// عدد الأسطر المعدَّلة عن أصلها
  @override
  int get editedLines;

  /// هل السلفة معتُمدة بالفعل؟
  ///
  /// يغيّر معنى [AdvanceSummaryX.deficit] جذرياً — راجع تعليقه.
  @override
  bool get isPosted;

  /// العجز المُثبَّت وقت الاعتماد (يُقرأ من السلفة، ذو معنى بعد الاعتماد فقط)
  @override
  double get postedDeficit;

  /// Create a copy of AdvanceSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdvanceSummaryImplCopyWith<_$AdvanceSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
