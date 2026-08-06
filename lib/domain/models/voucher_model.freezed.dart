// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'voucher_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VoucherModel _$VoucherModelFromJson(Map<String, dynamic> json) {
  return _VoucherModel.fromJson(json);
}

/// @nodoc
mixin _$VoucherModel {
  /// المعرّف الفريد
  int get id => throw _privateConstructorUsedError;

  /// رقم السند التسلسلي ضمن السنة المالية
  int get voucherNumber => throw _privateConstructorUsedError;

  /// نوع السند: 'sarf' | 'kabd' | 'opening_balance' | 'transfer_out' | 'transfer_in'
  String get voucherType => throw _privateConstructorUsedError;

  /// معرّف الخزينة المرتبطة
  int get treasuryId => throw _privateConstructorUsedError;

  /// معرّف الفترة المالية
  int get fiscalPeriodId => throw _privateConstructorUsedError;

  /// المبلغ (دائماً موجب)
  double get amount => throw _privateConstructorUsedError;

  /// العملة: 'IQD' | 'USD'
  String get currency => throw _privateConstructorUsedError;

  /// سعر الصرف وقت إنشاء السند (للمرجعية التاريخية)
  double get exchangeRate => throw _privateConstructorUsedError;

  /// تاريخ السند (قد يختلف عن وقت الإدخال)
  DateTime get voucherDate => throw _privateConstructorUsedError;

  /// اسم المستلم / الدافع
  String get personName => throw _privateConstructorUsedError;

  /// السبب / الوصف
  String get reason => throw _privateConstructorUsedError;

  /// نوع البند: راتب / سلفة / إيجار / ...
  String get itemType => throw _privateConstructorUsedError;

  /// الرقم المرجعي (رقم شيك، أمر دفع، ...)
  String get referenceNumber => throw _privateConstructorUsedError;

  /// هل يُقفَل الصندوق بعد هذا السند؟
  bool get closeSafe => throw _privateConstructorUsedError;

  /// معرّف الخزينة الأخرى في عملية التحويل (اختياري)
  int? get linkedTreasuryId => throw _privateConstructorUsedError;

  /// معرّف الكيان المرتبط (موظف / مقاول / شريك) — اختياري
  int? get linkedEntityId => throw _privateConstructorUsedError;

  /// اسم المشروع أو موقع الصرف (لدعم السلف)
  String? get projectName => throw _privateConstructorUsedError;

  /// رقم الفاتورة أو الوصل
  String? get invoiceNumber => throw _privateConstructorUsedError;

  /// من قام بصرف المبلغ الفعلي
  String? get spentBy => throw _privateConstructorUsedError;

  /// رقم السلفة التي تتبع لها هذه الصرفية (لتجميع السلف)
  String? get advanceNumber => throw _privateConstructorUsedError;

  /// هل تم حذفه ناعماً؟
  bool get isDeleted => throw _privateConstructorUsedError;

  /// وقت الحذف
  DateTime? get deletedAt => throw _privateConstructorUsedError;

  /// Serializes this VoucherModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VoucherModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VoucherModelCopyWith<VoucherModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VoucherModelCopyWith<$Res> {
  factory $VoucherModelCopyWith(
          VoucherModel value, $Res Function(VoucherModel) then) =
      _$VoucherModelCopyWithImpl<$Res, VoucherModel>;
  @useResult
  $Res call(
      {int id,
      int voucherNumber,
      String voucherType,
      int treasuryId,
      int fiscalPeriodId,
      double amount,
      String currency,
      double exchangeRate,
      DateTime voucherDate,
      String personName,
      String reason,
      String itemType,
      String referenceNumber,
      bool closeSafe,
      int? linkedTreasuryId,
      int? linkedEntityId,
      String? projectName,
      String? invoiceNumber,
      String? spentBy,
      String? advanceNumber,
      bool isDeleted,
      DateTime? deletedAt});
}

/// @nodoc
class _$VoucherModelCopyWithImpl<$Res, $Val extends VoucherModel>
    implements $VoucherModelCopyWith<$Res> {
  _$VoucherModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VoucherModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? voucherNumber = null,
    Object? voucherType = null,
    Object? treasuryId = null,
    Object? fiscalPeriodId = null,
    Object? amount = null,
    Object? currency = null,
    Object? exchangeRate = null,
    Object? voucherDate = null,
    Object? personName = null,
    Object? reason = null,
    Object? itemType = null,
    Object? referenceNumber = null,
    Object? closeSafe = null,
    Object? linkedTreasuryId = freezed,
    Object? linkedEntityId = freezed,
    Object? projectName = freezed,
    Object? invoiceNumber = freezed,
    Object? spentBy = freezed,
    Object? advanceNumber = freezed,
    Object? isDeleted = null,
    Object? deletedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      voucherNumber: null == voucherNumber
          ? _value.voucherNumber
          : voucherNumber // ignore: cast_nullable_to_non_nullable
              as int,
      voucherType: null == voucherType
          ? _value.voucherType
          : voucherType // ignore: cast_nullable_to_non_nullable
              as String,
      treasuryId: null == treasuryId
          ? _value.treasuryId
          : treasuryId // ignore: cast_nullable_to_non_nullable
              as int,
      fiscalPeriodId: null == fiscalPeriodId
          ? _value.fiscalPeriodId
          : fiscalPeriodId // ignore: cast_nullable_to_non_nullable
              as int,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      exchangeRate: null == exchangeRate
          ? _value.exchangeRate
          : exchangeRate // ignore: cast_nullable_to_non_nullable
              as double,
      voucherDate: null == voucherDate
          ? _value.voucherDate
          : voucherDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      personName: null == personName
          ? _value.personName
          : personName // ignore: cast_nullable_to_non_nullable
              as String,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      itemType: null == itemType
          ? _value.itemType
          : itemType // ignore: cast_nullable_to_non_nullable
              as String,
      referenceNumber: null == referenceNumber
          ? _value.referenceNumber
          : referenceNumber // ignore: cast_nullable_to_non_nullable
              as String,
      closeSafe: null == closeSafe
          ? _value.closeSafe
          : closeSafe // ignore: cast_nullable_to_non_nullable
              as bool,
      linkedTreasuryId: freezed == linkedTreasuryId
          ? _value.linkedTreasuryId
          : linkedTreasuryId // ignore: cast_nullable_to_non_nullable
              as int?,
      linkedEntityId: freezed == linkedEntityId
          ? _value.linkedEntityId
          : linkedEntityId // ignore: cast_nullable_to_non_nullable
              as int?,
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
      advanceNumber: freezed == advanceNumber
          ? _value.advanceNumber
          : advanceNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VoucherModelImplCopyWith<$Res>
    implements $VoucherModelCopyWith<$Res> {
  factory _$$VoucherModelImplCopyWith(
          _$VoucherModelImpl value, $Res Function(_$VoucherModelImpl) then) =
      __$$VoucherModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int voucherNumber,
      String voucherType,
      int treasuryId,
      int fiscalPeriodId,
      double amount,
      String currency,
      double exchangeRate,
      DateTime voucherDate,
      String personName,
      String reason,
      String itemType,
      String referenceNumber,
      bool closeSafe,
      int? linkedTreasuryId,
      int? linkedEntityId,
      String? projectName,
      String? invoiceNumber,
      String? spentBy,
      String? advanceNumber,
      bool isDeleted,
      DateTime? deletedAt});
}

/// @nodoc
class __$$VoucherModelImplCopyWithImpl<$Res>
    extends _$VoucherModelCopyWithImpl<$Res, _$VoucherModelImpl>
    implements _$$VoucherModelImplCopyWith<$Res> {
  __$$VoucherModelImplCopyWithImpl(
      _$VoucherModelImpl _value, $Res Function(_$VoucherModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of VoucherModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? voucherNumber = null,
    Object? voucherType = null,
    Object? treasuryId = null,
    Object? fiscalPeriodId = null,
    Object? amount = null,
    Object? currency = null,
    Object? exchangeRate = null,
    Object? voucherDate = null,
    Object? personName = null,
    Object? reason = null,
    Object? itemType = null,
    Object? referenceNumber = null,
    Object? closeSafe = null,
    Object? linkedTreasuryId = freezed,
    Object? linkedEntityId = freezed,
    Object? projectName = freezed,
    Object? invoiceNumber = freezed,
    Object? spentBy = freezed,
    Object? advanceNumber = freezed,
    Object? isDeleted = null,
    Object? deletedAt = freezed,
  }) {
    return _then(_$VoucherModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      voucherNumber: null == voucherNumber
          ? _value.voucherNumber
          : voucherNumber // ignore: cast_nullable_to_non_nullable
              as int,
      voucherType: null == voucherType
          ? _value.voucherType
          : voucherType // ignore: cast_nullable_to_non_nullable
              as String,
      treasuryId: null == treasuryId
          ? _value.treasuryId
          : treasuryId // ignore: cast_nullable_to_non_nullable
              as int,
      fiscalPeriodId: null == fiscalPeriodId
          ? _value.fiscalPeriodId
          : fiscalPeriodId // ignore: cast_nullable_to_non_nullable
              as int,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      exchangeRate: null == exchangeRate
          ? _value.exchangeRate
          : exchangeRate // ignore: cast_nullable_to_non_nullable
              as double,
      voucherDate: null == voucherDate
          ? _value.voucherDate
          : voucherDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      personName: null == personName
          ? _value.personName
          : personName // ignore: cast_nullable_to_non_nullable
              as String,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      itemType: null == itemType
          ? _value.itemType
          : itemType // ignore: cast_nullable_to_non_nullable
              as String,
      referenceNumber: null == referenceNumber
          ? _value.referenceNumber
          : referenceNumber // ignore: cast_nullable_to_non_nullable
              as String,
      closeSafe: null == closeSafe
          ? _value.closeSafe
          : closeSafe // ignore: cast_nullable_to_non_nullable
              as bool,
      linkedTreasuryId: freezed == linkedTreasuryId
          ? _value.linkedTreasuryId
          : linkedTreasuryId // ignore: cast_nullable_to_non_nullable
              as int?,
      linkedEntityId: freezed == linkedEntityId
          ? _value.linkedEntityId
          : linkedEntityId // ignore: cast_nullable_to_non_nullable
              as int?,
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
      advanceNumber: freezed == advanceNumber
          ? _value.advanceNumber
          : advanceNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VoucherModelImpl implements _VoucherModel {
  const _$VoucherModelImpl(
      {required this.id,
      required this.voucherNumber,
      required this.voucherType,
      required this.treasuryId,
      required this.fiscalPeriodId,
      required this.amount,
      required this.currency,
      this.exchangeRate = 1.0,
      required this.voucherDate,
      this.personName = '',
      this.reason = '',
      this.itemType = '',
      this.referenceNumber = '',
      this.closeSafe = false,
      this.linkedTreasuryId,
      this.linkedEntityId,
      this.projectName,
      this.invoiceNumber,
      this.spentBy,
      this.advanceNumber,
      this.isDeleted = false,
      this.deletedAt});

  factory _$VoucherModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VoucherModelImplFromJson(json);

  /// المعرّف الفريد
  @override
  final int id;

  /// رقم السند التسلسلي ضمن السنة المالية
  @override
  final int voucherNumber;

  /// نوع السند: 'sarf' | 'kabd' | 'opening_balance' | 'transfer_out' | 'transfer_in'
  @override
  final String voucherType;

  /// معرّف الخزينة المرتبطة
  @override
  final int treasuryId;

  /// معرّف الفترة المالية
  @override
  final int fiscalPeriodId;

  /// المبلغ (دائماً موجب)
  @override
  final double amount;

  /// العملة: 'IQD' | 'USD'
  @override
  final String currency;

  /// سعر الصرف وقت إنشاء السند (للمرجعية التاريخية)
  @override
  @JsonKey()
  final double exchangeRate;

  /// تاريخ السند (قد يختلف عن وقت الإدخال)
  @override
  final DateTime voucherDate;

  /// اسم المستلم / الدافع
  @override
  @JsonKey()
  final String personName;

  /// السبب / الوصف
  @override
  @JsonKey()
  final String reason;

  /// نوع البند: راتب / سلفة / إيجار / ...
  @override
  @JsonKey()
  final String itemType;

  /// الرقم المرجعي (رقم شيك، أمر دفع، ...)
  @override
  @JsonKey()
  final String referenceNumber;

  /// هل يُقفَل الصندوق بعد هذا السند؟
  @override
  @JsonKey()
  final bool closeSafe;

  /// معرّف الخزينة الأخرى في عملية التحويل (اختياري)
  @override
  final int? linkedTreasuryId;

  /// معرّف الكيان المرتبط (موظف / مقاول / شريك) — اختياري
  @override
  final int? linkedEntityId;

  /// اسم المشروع أو موقع الصرف (لدعم السلف)
  @override
  final String? projectName;

  /// رقم الفاتورة أو الوصل
  @override
  final String? invoiceNumber;

  /// من قام بصرف المبلغ الفعلي
  @override
  final String? spentBy;

  /// رقم السلفة التي تتبع لها هذه الصرفية (لتجميع السلف)
  @override
  final String? advanceNumber;

  /// هل تم حذفه ناعماً؟
  @override
  @JsonKey()
  final bool isDeleted;

  /// وقت الحذف
  @override
  final DateTime? deletedAt;

  @override
  String toString() {
    return 'VoucherModel(id: $id, voucherNumber: $voucherNumber, voucherType: $voucherType, treasuryId: $treasuryId, fiscalPeriodId: $fiscalPeriodId, amount: $amount, currency: $currency, exchangeRate: $exchangeRate, voucherDate: $voucherDate, personName: $personName, reason: $reason, itemType: $itemType, referenceNumber: $referenceNumber, closeSafe: $closeSafe, linkedTreasuryId: $linkedTreasuryId, linkedEntityId: $linkedEntityId, projectName: $projectName, invoiceNumber: $invoiceNumber, spentBy: $spentBy, advanceNumber: $advanceNumber, isDeleted: $isDeleted, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoucherModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.voucherNumber, voucherNumber) ||
                other.voucherNumber == voucherNumber) &&
            (identical(other.voucherType, voucherType) ||
                other.voucherType == voucherType) &&
            (identical(other.treasuryId, treasuryId) ||
                other.treasuryId == treasuryId) &&
            (identical(other.fiscalPeriodId, fiscalPeriodId) ||
                other.fiscalPeriodId == fiscalPeriodId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.exchangeRate, exchangeRate) ||
                other.exchangeRate == exchangeRate) &&
            (identical(other.voucherDate, voucherDate) ||
                other.voucherDate == voucherDate) &&
            (identical(other.personName, personName) ||
                other.personName == personName) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.itemType, itemType) ||
                other.itemType == itemType) &&
            (identical(other.referenceNumber, referenceNumber) ||
                other.referenceNumber == referenceNumber) &&
            (identical(other.closeSafe, closeSafe) ||
                other.closeSafe == closeSafe) &&
            (identical(other.linkedTreasuryId, linkedTreasuryId) ||
                other.linkedTreasuryId == linkedTreasuryId) &&
            (identical(other.linkedEntityId, linkedEntityId) ||
                other.linkedEntityId == linkedEntityId) &&
            (identical(other.projectName, projectName) ||
                other.projectName == projectName) &&
            (identical(other.invoiceNumber, invoiceNumber) ||
                other.invoiceNumber == invoiceNumber) &&
            (identical(other.spentBy, spentBy) || other.spentBy == spentBy) &&
            (identical(other.advanceNumber, advanceNumber) ||
                other.advanceNumber == advanceNumber) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        voucherNumber,
        voucherType,
        treasuryId,
        fiscalPeriodId,
        amount,
        currency,
        exchangeRate,
        voucherDate,
        personName,
        reason,
        itemType,
        referenceNumber,
        closeSafe,
        linkedTreasuryId,
        linkedEntityId,
        projectName,
        invoiceNumber,
        spentBy,
        advanceNumber,
        isDeleted,
        deletedAt
      ]);

  /// Create a copy of VoucherModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VoucherModelImplCopyWith<_$VoucherModelImpl> get copyWith =>
      __$$VoucherModelImplCopyWithImpl<_$VoucherModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VoucherModelImplToJson(
      this,
    );
  }
}

abstract class _VoucherModel implements VoucherModel {
  const factory _VoucherModel(
      {required final int id,
      required final int voucherNumber,
      required final String voucherType,
      required final int treasuryId,
      required final int fiscalPeriodId,
      required final double amount,
      required final String currency,
      final double exchangeRate,
      required final DateTime voucherDate,
      final String personName,
      final String reason,
      final String itemType,
      final String referenceNumber,
      final bool closeSafe,
      final int? linkedTreasuryId,
      final int? linkedEntityId,
      final String? projectName,
      final String? invoiceNumber,
      final String? spentBy,
      final String? advanceNumber,
      final bool isDeleted,
      final DateTime? deletedAt}) = _$VoucherModelImpl;

  factory _VoucherModel.fromJson(Map<String, dynamic> json) =
      _$VoucherModelImpl.fromJson;

  /// المعرّف الفريد
  @override
  int get id;

  /// رقم السند التسلسلي ضمن السنة المالية
  @override
  int get voucherNumber;

  /// نوع السند: 'sarf' | 'kabd' | 'opening_balance' | 'transfer_out' | 'transfer_in'
  @override
  String get voucherType;

  /// معرّف الخزينة المرتبطة
  @override
  int get treasuryId;

  /// معرّف الفترة المالية
  @override
  int get fiscalPeriodId;

  /// المبلغ (دائماً موجب)
  @override
  double get amount;

  /// العملة: 'IQD' | 'USD'
  @override
  String get currency;

  /// سعر الصرف وقت إنشاء السند (للمرجعية التاريخية)
  @override
  double get exchangeRate;

  /// تاريخ السند (قد يختلف عن وقت الإدخال)
  @override
  DateTime get voucherDate;

  /// اسم المستلم / الدافع
  @override
  String get personName;

  /// السبب / الوصف
  @override
  String get reason;

  /// نوع البند: راتب / سلفة / إيجار / ...
  @override
  String get itemType;

  /// الرقم المرجعي (رقم شيك، أمر دفع، ...)
  @override
  String get referenceNumber;

  /// هل يُقفَل الصندوق بعد هذا السند؟
  @override
  bool get closeSafe;

  /// معرّف الخزينة الأخرى في عملية التحويل (اختياري)
  @override
  int? get linkedTreasuryId;

  /// معرّف الكيان المرتبط (موظف / مقاول / شريك) — اختياري
  @override
  int? get linkedEntityId;

  /// اسم المشروع أو موقع الصرف (لدعم السلف)
  @override
  String? get projectName;

  /// رقم الفاتورة أو الوصل
  @override
  String? get invoiceNumber;

  /// من قام بصرف المبلغ الفعلي
  @override
  String? get spentBy;

  /// رقم السلفة التي تتبع لها هذه الصرفية (لتجميع السلف)
  @override
  String? get advanceNumber;

  /// هل تم حذفه ناعماً؟
  @override
  bool get isDeleted;

  /// وقت الحذف
  @override
  DateTime? get deletedAt;

  /// Create a copy of VoucherModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VoucherModelImplCopyWith<_$VoucherModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AccountStatementModel _$AccountStatementModelFromJson(
    Map<String, dynamic> json) {
  return _AccountStatementModel.fromJson(json);
}

/// @nodoc
mixin _$AccountStatementModel {
  /// بيانات السند
  VoucherModel get voucher => throw _privateConstructorUsedError;

  /// الرصيد التراكمي بالدينار حتى هذا السطر
  double get runningBalanceIqd => throw _privateConstructorUsedError;

  /// الرصيد التراكمي بالدولار حتى هذا السطر
  double get runningBalanceUsd => throw _privateConstructorUsedError;

  /// Serializes this AccountStatementModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AccountStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountStatementModelCopyWith<AccountStatementModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountStatementModelCopyWith<$Res> {
  factory $AccountStatementModelCopyWith(AccountStatementModel value,
          $Res Function(AccountStatementModel) then) =
      _$AccountStatementModelCopyWithImpl<$Res, AccountStatementModel>;
  @useResult
  $Res call(
      {VoucherModel voucher,
      double runningBalanceIqd,
      double runningBalanceUsd});

  $VoucherModelCopyWith<$Res> get voucher;
}

/// @nodoc
class _$AccountStatementModelCopyWithImpl<$Res,
        $Val extends AccountStatementModel>
    implements $AccountStatementModelCopyWith<$Res> {
  _$AccountStatementModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? voucher = null,
    Object? runningBalanceIqd = null,
    Object? runningBalanceUsd = null,
  }) {
    return _then(_value.copyWith(
      voucher: null == voucher
          ? _value.voucher
          : voucher // ignore: cast_nullable_to_non_nullable
              as VoucherModel,
      runningBalanceIqd: null == runningBalanceIqd
          ? _value.runningBalanceIqd
          : runningBalanceIqd // ignore: cast_nullable_to_non_nullable
              as double,
      runningBalanceUsd: null == runningBalanceUsd
          ? _value.runningBalanceUsd
          : runningBalanceUsd // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }

  /// Create a copy of AccountStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VoucherModelCopyWith<$Res> get voucher {
    return $VoucherModelCopyWith<$Res>(_value.voucher, (value) {
      return _then(_value.copyWith(voucher: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AccountStatementModelImplCopyWith<$Res>
    implements $AccountStatementModelCopyWith<$Res> {
  factory _$$AccountStatementModelImplCopyWith(
          _$AccountStatementModelImpl value,
          $Res Function(_$AccountStatementModelImpl) then) =
      __$$AccountStatementModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {VoucherModel voucher,
      double runningBalanceIqd,
      double runningBalanceUsd});

  @override
  $VoucherModelCopyWith<$Res> get voucher;
}

/// @nodoc
class __$$AccountStatementModelImplCopyWithImpl<$Res>
    extends _$AccountStatementModelCopyWithImpl<$Res,
        _$AccountStatementModelImpl>
    implements _$$AccountStatementModelImplCopyWith<$Res> {
  __$$AccountStatementModelImplCopyWithImpl(_$AccountStatementModelImpl _value,
      $Res Function(_$AccountStatementModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AccountStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? voucher = null,
    Object? runningBalanceIqd = null,
    Object? runningBalanceUsd = null,
  }) {
    return _then(_$AccountStatementModelImpl(
      voucher: null == voucher
          ? _value.voucher
          : voucher // ignore: cast_nullable_to_non_nullable
              as VoucherModel,
      runningBalanceIqd: null == runningBalanceIqd
          ? _value.runningBalanceIqd
          : runningBalanceIqd // ignore: cast_nullable_to_non_nullable
              as double,
      runningBalanceUsd: null == runningBalanceUsd
          ? _value.runningBalanceUsd
          : runningBalanceUsd // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AccountStatementModelImpl implements _AccountStatementModel {
  const _$AccountStatementModelImpl(
      {required this.voucher,
      required this.runningBalanceIqd,
      required this.runningBalanceUsd});

  factory _$AccountStatementModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccountStatementModelImplFromJson(json);

  /// بيانات السند
  @override
  final VoucherModel voucher;

  /// الرصيد التراكمي بالدينار حتى هذا السطر
  @override
  final double runningBalanceIqd;

  /// الرصيد التراكمي بالدولار حتى هذا السطر
  @override
  final double runningBalanceUsd;

  @override
  String toString() {
    return 'AccountStatementModel(voucher: $voucher, runningBalanceIqd: $runningBalanceIqd, runningBalanceUsd: $runningBalanceUsd)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountStatementModelImpl &&
            (identical(other.voucher, voucher) || other.voucher == voucher) &&
            (identical(other.runningBalanceIqd, runningBalanceIqd) ||
                other.runningBalanceIqd == runningBalanceIqd) &&
            (identical(other.runningBalanceUsd, runningBalanceUsd) ||
                other.runningBalanceUsd == runningBalanceUsd));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, voucher, runningBalanceIqd, runningBalanceUsd);

  /// Create a copy of AccountStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountStatementModelImplCopyWith<_$AccountStatementModelImpl>
      get copyWith => __$$AccountStatementModelImplCopyWithImpl<
          _$AccountStatementModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AccountStatementModelImplToJson(
      this,
    );
  }
}

abstract class _AccountStatementModel implements AccountStatementModel {
  const factory _AccountStatementModel(
      {required final VoucherModel voucher,
      required final double runningBalanceIqd,
      required final double runningBalanceUsd}) = _$AccountStatementModelImpl;

  factory _AccountStatementModel.fromJson(Map<String, dynamic> json) =
      _$AccountStatementModelImpl.fromJson;

  /// بيانات السند
  @override
  VoucherModel get voucher;

  /// الرصيد التراكمي بالدينار حتى هذا السطر
  @override
  double get runningBalanceIqd;

  /// الرصيد التراكمي بالدولار حتى هذا السطر
  @override
  double get runningBalanceUsd;

  /// Create a copy of AccountStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountStatementModelImplCopyWith<_$AccountStatementModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
