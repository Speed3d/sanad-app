// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voucher_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$vouchersByTreasuryHash() =>
    r'13ab267cab5a80cdd9d2161ad60debb636a02f78';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Stream تفاعلي لسندات خزينة محددة
///
/// يتحدث تلقائياً عند إضافة / تعديل / حذف أي سند في هذه الخزينة
///
/// Copied from [vouchersByTreasury].
@ProviderFor(vouchersByTreasury)
const vouchersByTreasuryProvider = VouchersByTreasuryFamily();

/// Stream تفاعلي لسندات خزينة محددة
///
/// يتحدث تلقائياً عند إضافة / تعديل / حذف أي سند في هذه الخزينة
///
/// Copied from [vouchersByTreasury].
class VouchersByTreasuryFamily extends Family<AsyncValue<List<VoucherModel>>> {
  /// Stream تفاعلي لسندات خزينة محددة
  ///
  /// يتحدث تلقائياً عند إضافة / تعديل / حذف أي سند في هذه الخزينة
  ///
  /// Copied from [vouchersByTreasury].
  const VouchersByTreasuryFamily();

  /// Stream تفاعلي لسندات خزينة محددة
  ///
  /// يتحدث تلقائياً عند إضافة / تعديل / حذف أي سند في هذه الخزينة
  ///
  /// Copied from [vouchersByTreasury].
  VouchersByTreasuryProvider call(
    int treasuryId,
  ) {
    return VouchersByTreasuryProvider(
      treasuryId,
    );
  }

  @override
  VouchersByTreasuryProvider getProviderOverride(
    covariant VouchersByTreasuryProvider provider,
  ) {
    return call(
      provider.treasuryId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'vouchersByTreasuryProvider';
}

/// Stream تفاعلي لسندات خزينة محددة
///
/// يتحدث تلقائياً عند إضافة / تعديل / حذف أي سند في هذه الخزينة
///
/// Copied from [vouchersByTreasury].
class VouchersByTreasuryProvider
    extends AutoDisposeStreamProvider<List<VoucherModel>> {
  /// Stream تفاعلي لسندات خزينة محددة
  ///
  /// يتحدث تلقائياً عند إضافة / تعديل / حذف أي سند في هذه الخزينة
  ///
  /// Copied from [vouchersByTreasury].
  VouchersByTreasuryProvider(
    int treasuryId,
  ) : this._internal(
          (ref) => vouchersByTreasury(
            ref as VouchersByTreasuryRef,
            treasuryId,
          ),
          from: vouchersByTreasuryProvider,
          name: r'vouchersByTreasuryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$vouchersByTreasuryHash,
          dependencies: VouchersByTreasuryFamily._dependencies,
          allTransitiveDependencies:
              VouchersByTreasuryFamily._allTransitiveDependencies,
          treasuryId: treasuryId,
        );

  VouchersByTreasuryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.treasuryId,
  }) : super.internal();

  final int treasuryId;

  @override
  Override overrideWith(
    Stream<List<VoucherModel>> Function(VouchersByTreasuryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VouchersByTreasuryProvider._internal(
        (ref) => create(ref as VouchersByTreasuryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        treasuryId: treasuryId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<VoucherModel>> createElement() {
    return _VouchersByTreasuryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VouchersByTreasuryProvider &&
        other.treasuryId == treasuryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, treasuryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VouchersByTreasuryRef
    on AutoDisposeStreamProviderRef<List<VoucherModel>> {
  /// The parameter `treasuryId` of this provider.
  int get treasuryId;
}

class _VouchersByTreasuryProviderElement
    extends AutoDisposeStreamProviderElement<List<VoucherModel>>
    with VouchersByTreasuryRef {
  _VouchersByTreasuryProviderElement(super.provider);

  @override
  int get treasuryId => (origin as VouchersByTreasuryProvider).treasuryId;
}

String _$vouchersByTypeHash() => r'ec0294497faa8af272cfd8398bb2a69f7c42bc29';

/// Stream تفاعلي لسندات حسب نوعها ('sarf' | 'kabd')
///
/// Copied from [vouchersByType].
@ProviderFor(vouchersByType)
const vouchersByTypeProvider = VouchersByTypeFamily();

/// Stream تفاعلي لسندات حسب نوعها ('sarf' | 'kabd')
///
/// Copied from [vouchersByType].
class VouchersByTypeFamily extends Family<AsyncValue<List<VoucherModel>>> {
  /// Stream تفاعلي لسندات حسب نوعها ('sarf' | 'kabd')
  ///
  /// Copied from [vouchersByType].
  const VouchersByTypeFamily();

  /// Stream تفاعلي لسندات حسب نوعها ('sarf' | 'kabd')
  ///
  /// Copied from [vouchersByType].
  VouchersByTypeProvider call(
    String voucherType,
  ) {
    return VouchersByTypeProvider(
      voucherType,
    );
  }

  @override
  VouchersByTypeProvider getProviderOverride(
    covariant VouchersByTypeProvider provider,
  ) {
    return call(
      provider.voucherType,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'vouchersByTypeProvider';
}

/// Stream تفاعلي لسندات حسب نوعها ('sarf' | 'kabd')
///
/// Copied from [vouchersByType].
class VouchersByTypeProvider
    extends AutoDisposeStreamProvider<List<VoucherModel>> {
  /// Stream تفاعلي لسندات حسب نوعها ('sarf' | 'kabd')
  ///
  /// Copied from [vouchersByType].
  VouchersByTypeProvider(
    String voucherType,
  ) : this._internal(
          (ref) => vouchersByType(
            ref as VouchersByTypeRef,
            voucherType,
          ),
          from: vouchersByTypeProvider,
          name: r'vouchersByTypeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$vouchersByTypeHash,
          dependencies: VouchersByTypeFamily._dependencies,
          allTransitiveDependencies:
              VouchersByTypeFamily._allTransitiveDependencies,
          voucherType: voucherType,
        );

  VouchersByTypeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.voucherType,
  }) : super.internal();

  final String voucherType;

  @override
  Override overrideWith(
    Stream<List<VoucherModel>> Function(VouchersByTypeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VouchersByTypeProvider._internal(
        (ref) => create(ref as VouchersByTypeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        voucherType: voucherType,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<VoucherModel>> createElement() {
    return _VouchersByTypeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VouchersByTypeProvider && other.voucherType == voucherType;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, voucherType.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VouchersByTypeRef on AutoDisposeStreamProviderRef<List<VoucherModel>> {
  /// The parameter `voucherType` of this provider.
  String get voucherType;
}

class _VouchersByTypeProviderElement
    extends AutoDisposeStreamProviderElement<List<VoucherModel>>
    with VouchersByTypeRef {
  _VouchersByTypeProviderElement(super.provider);

  @override
  String get voucherType => (origin as VouchersByTypeProvider).voucherType;
}

String _$vouchersByDateRangeHash() =>
    r'faa05737cbbc5cd9e1e40e2d9452a50bd2755360';

/// سندات ضمن نطاق تاريخ مع فلاتر اختيارية
///
/// استخدام تسمية startDate/endDate بدلاً من from/to
/// لتجنب التعارض مع Riverpod Family.from API
///
/// Copied from [vouchersByDateRange].
@ProviderFor(vouchersByDateRange)
const vouchersByDateRangeProvider = VouchersByDateRangeFamily();

/// سندات ضمن نطاق تاريخ مع فلاتر اختيارية
///
/// استخدام تسمية startDate/endDate بدلاً من from/to
/// لتجنب التعارض مع Riverpod Family.from API
///
/// Copied from [vouchersByDateRange].
class VouchersByDateRangeFamily extends Family<AsyncValue<List<VoucherModel>>> {
  /// سندات ضمن نطاق تاريخ مع فلاتر اختيارية
  ///
  /// استخدام تسمية startDate/endDate بدلاً من from/to
  /// لتجنب التعارض مع Riverpod Family.from API
  ///
  /// Copied from [vouchersByDateRange].
  const VouchersByDateRangeFamily();

  /// سندات ضمن نطاق تاريخ مع فلاتر اختيارية
  ///
  /// استخدام تسمية startDate/endDate بدلاً من from/to
  /// لتجنب التعارض مع Riverpod Family.from API
  ///
  /// Copied from [vouchersByDateRange].
  VouchersByDateRangeProvider call({
    required DateTime startDate,
    required DateTime endDate,
    int? treasuryId,
    String? voucherType,
    int? fiscalPeriodId,
  }) {
    return VouchersByDateRangeProvider(
      startDate: startDate,
      endDate: endDate,
      treasuryId: treasuryId,
      voucherType: voucherType,
      fiscalPeriodId: fiscalPeriodId,
    );
  }

  @override
  VouchersByDateRangeProvider getProviderOverride(
    covariant VouchersByDateRangeProvider provider,
  ) {
    return call(
      startDate: provider.startDate,
      endDate: provider.endDate,
      treasuryId: provider.treasuryId,
      voucherType: provider.voucherType,
      fiscalPeriodId: provider.fiscalPeriodId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'vouchersByDateRangeProvider';
}

/// سندات ضمن نطاق تاريخ مع فلاتر اختيارية
///
/// استخدام تسمية startDate/endDate بدلاً من from/to
/// لتجنب التعارض مع Riverpod Family.from API
///
/// Copied from [vouchersByDateRange].
class VouchersByDateRangeProvider
    extends AutoDisposeFutureProvider<List<VoucherModel>> {
  /// سندات ضمن نطاق تاريخ مع فلاتر اختيارية
  ///
  /// استخدام تسمية startDate/endDate بدلاً من from/to
  /// لتجنب التعارض مع Riverpod Family.from API
  ///
  /// Copied from [vouchersByDateRange].
  VouchersByDateRangeProvider({
    required DateTime startDate,
    required DateTime endDate,
    int? treasuryId,
    String? voucherType,
    int? fiscalPeriodId,
  }) : this._internal(
          (ref) => vouchersByDateRange(
            ref as VouchersByDateRangeRef,
            startDate: startDate,
            endDate: endDate,
            treasuryId: treasuryId,
            voucherType: voucherType,
            fiscalPeriodId: fiscalPeriodId,
          ),
          from: vouchersByDateRangeProvider,
          name: r'vouchersByDateRangeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$vouchersByDateRangeHash,
          dependencies: VouchersByDateRangeFamily._dependencies,
          allTransitiveDependencies:
              VouchersByDateRangeFamily._allTransitiveDependencies,
          startDate: startDate,
          endDate: endDate,
          treasuryId: treasuryId,
          voucherType: voucherType,
          fiscalPeriodId: fiscalPeriodId,
        );

  VouchersByDateRangeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.startDate,
    required this.endDate,
    required this.treasuryId,
    required this.voucherType,
    required this.fiscalPeriodId,
  }) : super.internal();

  final DateTime startDate;
  final DateTime endDate;
  final int? treasuryId;
  final String? voucherType;
  final int? fiscalPeriodId;

  @override
  Override overrideWith(
    FutureOr<List<VoucherModel>> Function(VouchersByDateRangeRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VouchersByDateRangeProvider._internal(
        (ref) => create(ref as VouchersByDateRangeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        startDate: startDate,
        endDate: endDate,
        treasuryId: treasuryId,
        voucherType: voucherType,
        fiscalPeriodId: fiscalPeriodId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<VoucherModel>> createElement() {
    return _VouchersByDateRangeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VouchersByDateRangeProvider &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.treasuryId == treasuryId &&
        other.voucherType == voucherType &&
        other.fiscalPeriodId == fiscalPeriodId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);
    hash = _SystemHash.combine(hash, treasuryId.hashCode);
    hash = _SystemHash.combine(hash, voucherType.hashCode);
    hash = _SystemHash.combine(hash, fiscalPeriodId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VouchersByDateRangeRef
    on AutoDisposeFutureProviderRef<List<VoucherModel>> {
  /// The parameter `startDate` of this provider.
  DateTime get startDate;

  /// The parameter `endDate` of this provider.
  DateTime get endDate;

  /// The parameter `treasuryId` of this provider.
  int? get treasuryId;

  /// The parameter `voucherType` of this provider.
  String? get voucherType;

  /// The parameter `fiscalPeriodId` of this provider.
  int? get fiscalPeriodId;
}

class _VouchersByDateRangeProviderElement
    extends AutoDisposeFutureProviderElement<List<VoucherModel>>
    with VouchersByDateRangeRef {
  _VouchersByDateRangeProviderElement(super.provider);

  @override
  DateTime get startDate => (origin as VouchersByDateRangeProvider).startDate;
  @override
  DateTime get endDate => (origin as VouchersByDateRangeProvider).endDate;
  @override
  int? get treasuryId => (origin as VouchersByDateRangeProvider).treasuryId;
  @override
  String? get voucherType =>
      (origin as VouchersByDateRangeProvider).voucherType;
  @override
  int? get fiscalPeriodId =>
      (origin as VouchersByDateRangeProvider).fiscalPeriodId;
}

String _$accountStatementHash() => r'a07756b50829ee563af964636e412cc139655d87';

/// كشف الحساب لخزينة في نطاق تاريخ محدد
///
/// Copied from [accountStatement].
@ProviderFor(accountStatement)
const accountStatementProvider = AccountStatementFamily();

/// كشف الحساب لخزينة في نطاق تاريخ محدد
///
/// Copied from [accountStatement].
class AccountStatementFamily
    extends Family<AsyncValue<List<AccountStatementModel>>> {
  /// كشف الحساب لخزينة في نطاق تاريخ محدد
  ///
  /// Copied from [accountStatement].
  const AccountStatementFamily();

  /// كشف الحساب لخزينة في نطاق تاريخ محدد
  ///
  /// Copied from [accountStatement].
  AccountStatementProvider call({
    required int treasuryId,
    required DateTime startDate,
    required DateTime endDate,
    double openingBalanceIqd = 0,
    double openingBalanceUsd = 0,
  }) {
    return AccountStatementProvider(
      treasuryId: treasuryId,
      startDate: startDate,
      endDate: endDate,
      openingBalanceIqd: openingBalanceIqd,
      openingBalanceUsd: openingBalanceUsd,
    );
  }

  @override
  AccountStatementProvider getProviderOverride(
    covariant AccountStatementProvider provider,
  ) {
    return call(
      treasuryId: provider.treasuryId,
      startDate: provider.startDate,
      endDate: provider.endDate,
      openingBalanceIqd: provider.openingBalanceIqd,
      openingBalanceUsd: provider.openingBalanceUsd,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'accountStatementProvider';
}

/// كشف الحساب لخزينة في نطاق تاريخ محدد
///
/// Copied from [accountStatement].
class AccountStatementProvider
    extends AutoDisposeFutureProvider<List<AccountStatementModel>> {
  /// كشف الحساب لخزينة في نطاق تاريخ محدد
  ///
  /// Copied from [accountStatement].
  AccountStatementProvider({
    required int treasuryId,
    required DateTime startDate,
    required DateTime endDate,
    double openingBalanceIqd = 0,
    double openingBalanceUsd = 0,
  }) : this._internal(
          (ref) => accountStatement(
            ref as AccountStatementRef,
            treasuryId: treasuryId,
            startDate: startDate,
            endDate: endDate,
            openingBalanceIqd: openingBalanceIqd,
            openingBalanceUsd: openingBalanceUsd,
          ),
          from: accountStatementProvider,
          name: r'accountStatementProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$accountStatementHash,
          dependencies: AccountStatementFamily._dependencies,
          allTransitiveDependencies:
              AccountStatementFamily._allTransitiveDependencies,
          treasuryId: treasuryId,
          startDate: startDate,
          endDate: endDate,
          openingBalanceIqd: openingBalanceIqd,
          openingBalanceUsd: openingBalanceUsd,
        );

  AccountStatementProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.treasuryId,
    required this.startDate,
    required this.endDate,
    required this.openingBalanceIqd,
    required this.openingBalanceUsd,
  }) : super.internal();

  final int treasuryId;
  final DateTime startDate;
  final DateTime endDate;
  final double openingBalanceIqd;
  final double openingBalanceUsd;

  @override
  Override overrideWith(
    FutureOr<List<AccountStatementModel>> Function(AccountStatementRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AccountStatementProvider._internal(
        (ref) => create(ref as AccountStatementRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        treasuryId: treasuryId,
        startDate: startDate,
        endDate: endDate,
        openingBalanceIqd: openingBalanceIqd,
        openingBalanceUsd: openingBalanceUsd,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<AccountStatementModel>>
      createElement() {
    return _AccountStatementProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AccountStatementProvider &&
        other.treasuryId == treasuryId &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.openingBalanceIqd == openingBalanceIqd &&
        other.openingBalanceUsd == openingBalanceUsd;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, treasuryId.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);
    hash = _SystemHash.combine(hash, openingBalanceIqd.hashCode);
    hash = _SystemHash.combine(hash, openingBalanceUsd.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AccountStatementRef
    on AutoDisposeFutureProviderRef<List<AccountStatementModel>> {
  /// The parameter `treasuryId` of this provider.
  int get treasuryId;

  /// The parameter `startDate` of this provider.
  DateTime get startDate;

  /// The parameter `endDate` of this provider.
  DateTime get endDate;

  /// The parameter `openingBalanceIqd` of this provider.
  double get openingBalanceIqd;

  /// The parameter `openingBalanceUsd` of this provider.
  double get openingBalanceUsd;
}

class _AccountStatementProviderElement
    extends AutoDisposeFutureProviderElement<List<AccountStatementModel>>
    with AccountStatementRef {
  _AccountStatementProviderElement(super.provider);

  @override
  int get treasuryId => (origin as AccountStatementProvider).treasuryId;
  @override
  DateTime get startDate => (origin as AccountStatementProvider).startDate;
  @override
  DateTime get endDate => (origin as AccountStatementProvider).endDate;
  @override
  double get openingBalanceIqd =>
      (origin as AccountStatementProvider).openingBalanceIqd;
  @override
  double get openingBalanceUsd =>
      (origin as AccountStatementProvider).openingBalanceUsd;
}

String _$dailySummaryHash() => r'a42e4a0abe3d498303a00bb73bd4e75d160aa901';

/// ملخص الصرف والقبض ليوم محدد — للـ Dashboard
///
/// Copied from [dailySummary].
@ProviderFor(dailySummary)
const dailySummaryProvider = DailySummaryFamily();

/// ملخص الصرف والقبض ليوم محدد — للـ Dashboard
///
/// Copied from [dailySummary].
class DailySummaryFamily
    extends Family<AsyncValue<({double totalSarf, double totalKabd})>> {
  /// ملخص الصرف والقبض ليوم محدد — للـ Dashboard
  ///
  /// Copied from [dailySummary].
  const DailySummaryFamily();

  /// ملخص الصرف والقبض ليوم محدد — للـ Dashboard
  ///
  /// Copied from [dailySummary].
  DailySummaryProvider call(
    DateTime date,
  ) {
    return DailySummaryProvider(
      date,
    );
  }

  @override
  DailySummaryProvider getProviderOverride(
    covariant DailySummaryProvider provider,
  ) {
    return call(
      provider.date,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'dailySummaryProvider';
}

/// ملخص الصرف والقبض ليوم محدد — للـ Dashboard
///
/// Copied from [dailySummary].
class DailySummaryProvider
    extends AutoDisposeFutureProvider<({double totalSarf, double totalKabd})> {
  /// ملخص الصرف والقبض ليوم محدد — للـ Dashboard
  ///
  /// Copied from [dailySummary].
  DailySummaryProvider(
    DateTime date,
  ) : this._internal(
          (ref) => dailySummary(
            ref as DailySummaryRef,
            date,
          ),
          from: dailySummaryProvider,
          name: r'dailySummaryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dailySummaryHash,
          dependencies: DailySummaryFamily._dependencies,
          allTransitiveDependencies:
              DailySummaryFamily._allTransitiveDependencies,
          date: date,
        );

  DailySummaryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final DateTime date;

  @override
  Override overrideWith(
    FutureOr<({double totalSarf, double totalKabd})> Function(
            DailySummaryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DailySummaryProvider._internal(
        (ref) => create(ref as DailySummaryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<({double totalSarf, double totalKabd})>
      createElement() {
    return _DailySummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DailySummaryProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DailySummaryRef
    on AutoDisposeFutureProviderRef<({double totalSarf, double totalKabd})> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _DailySummaryProviderElement extends AutoDisposeFutureProviderElement<
    ({double totalSarf, double totalKabd})> with DailySummaryRef {
  _DailySummaryProviderElement(super.provider);

  @override
  DateTime get date => (origin as DailySummaryProvider).date;
}

String _$searchVouchersHash() => r'7ca46a6e917e091690dc58d45aa7ca1ff92e1b20';

/// بحث في السندات بنص حر
///
/// يُعيد قائمة فارغة فوراً إذا كان النص فارغاً
///
/// Copied from [searchVouchers].
@ProviderFor(searchVouchers)
const searchVouchersProvider = SearchVouchersFamily();

/// بحث في السندات بنص حر
///
/// يُعيد قائمة فارغة فوراً إذا كان النص فارغاً
///
/// Copied from [searchVouchers].
class SearchVouchersFamily extends Family<AsyncValue<List<VoucherModel>>> {
  /// بحث في السندات بنص حر
  ///
  /// يُعيد قائمة فارغة فوراً إذا كان النص فارغاً
  ///
  /// Copied from [searchVouchers].
  const SearchVouchersFamily();

  /// بحث في السندات بنص حر
  ///
  /// يُعيد قائمة فارغة فوراً إذا كان النص فارغاً
  ///
  /// Copied from [searchVouchers].
  SearchVouchersProvider call(
    String query,
  ) {
    return SearchVouchersProvider(
      query,
    );
  }

  @override
  SearchVouchersProvider getProviderOverride(
    covariant SearchVouchersProvider provider,
  ) {
    return call(
      provider.query,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'searchVouchersProvider';
}

/// بحث في السندات بنص حر
///
/// يُعيد قائمة فارغة فوراً إذا كان النص فارغاً
///
/// Copied from [searchVouchers].
class SearchVouchersProvider
    extends AutoDisposeFutureProvider<List<VoucherModel>> {
  /// بحث في السندات بنص حر
  ///
  /// يُعيد قائمة فارغة فوراً إذا كان النص فارغاً
  ///
  /// Copied from [searchVouchers].
  SearchVouchersProvider(
    String query,
  ) : this._internal(
          (ref) => searchVouchers(
            ref as SearchVouchersRef,
            query,
          ),
          from: searchVouchersProvider,
          name: r'searchVouchersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$searchVouchersHash,
          dependencies: SearchVouchersFamily._dependencies,
          allTransitiveDependencies:
              SearchVouchersFamily._allTransitiveDependencies,
          query: query,
        );

  SearchVouchersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<VoucherModel>> Function(SearchVouchersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchVouchersProvider._internal(
        (ref) => create(ref as SearchVouchersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<VoucherModel>> createElement() {
    return _SearchVouchersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchVouchersProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchVouchersRef on AutoDisposeFutureProviderRef<List<VoucherModel>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _SearchVouchersProviderElement
    extends AutoDisposeFutureProviderElement<List<VoucherModel>>
    with SearchVouchersRef {
  _SearchVouchersProviderElement(super.provider);

  @override
  String get query => (origin as SearchVouchersProvider).query;
}

String _$advanceReportsHash() => r'5c7ab8eef0746ae9b0f25a4fb4feefd9195a05b1';

/// تقرير السلف (يبحث في السندات التي تحتوي على رقم سلفة)
///
/// Copied from [advanceReports].
@ProviderFor(advanceReports)
const advanceReportsProvider = AdvanceReportsFamily();

/// تقرير السلف (يبحث في السندات التي تحتوي على رقم سلفة)
///
/// Copied from [advanceReports].
class AdvanceReportsFamily extends Family<AsyncValue<List<VoucherModel>>> {
  /// تقرير السلف (يبحث في السندات التي تحتوي على رقم سلفة)
  ///
  /// Copied from [advanceReports].
  const AdvanceReportsFamily();

  /// تقرير السلف (يبحث في السندات التي تحتوي على رقم سلفة)
  ///
  /// Copied from [advanceReports].
  AdvanceReportsProvider call({
    String? advanceNumber,
    String? projectName,
    String? invoiceNumber,
  }) {
    return AdvanceReportsProvider(
      advanceNumber: advanceNumber,
      projectName: projectName,
      invoiceNumber: invoiceNumber,
    );
  }

  @override
  AdvanceReportsProvider getProviderOverride(
    covariant AdvanceReportsProvider provider,
  ) {
    return call(
      advanceNumber: provider.advanceNumber,
      projectName: provider.projectName,
      invoiceNumber: provider.invoiceNumber,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'advanceReportsProvider';
}

/// تقرير السلف (يبحث في السندات التي تحتوي على رقم سلفة)
///
/// Copied from [advanceReports].
class AdvanceReportsProvider
    extends AutoDisposeFutureProvider<List<VoucherModel>> {
  /// تقرير السلف (يبحث في السندات التي تحتوي على رقم سلفة)
  ///
  /// Copied from [advanceReports].
  AdvanceReportsProvider({
    String? advanceNumber,
    String? projectName,
    String? invoiceNumber,
  }) : this._internal(
          (ref) => advanceReports(
            ref as AdvanceReportsRef,
            advanceNumber: advanceNumber,
            projectName: projectName,
            invoiceNumber: invoiceNumber,
          ),
          from: advanceReportsProvider,
          name: r'advanceReportsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$advanceReportsHash,
          dependencies: AdvanceReportsFamily._dependencies,
          allTransitiveDependencies:
              AdvanceReportsFamily._allTransitiveDependencies,
          advanceNumber: advanceNumber,
          projectName: projectName,
          invoiceNumber: invoiceNumber,
        );

  AdvanceReportsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.advanceNumber,
    required this.projectName,
    required this.invoiceNumber,
  }) : super.internal();

  final String? advanceNumber;
  final String? projectName;
  final String? invoiceNumber;

  @override
  Override overrideWith(
    FutureOr<List<VoucherModel>> Function(AdvanceReportsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AdvanceReportsProvider._internal(
        (ref) => create(ref as AdvanceReportsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        advanceNumber: advanceNumber,
        projectName: projectName,
        invoiceNumber: invoiceNumber,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<VoucherModel>> createElement() {
    return _AdvanceReportsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdvanceReportsProvider &&
        other.advanceNumber == advanceNumber &&
        other.projectName == projectName &&
        other.invoiceNumber == invoiceNumber;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, advanceNumber.hashCode);
    hash = _SystemHash.combine(hash, projectName.hashCode);
    hash = _SystemHash.combine(hash, invoiceNumber.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AdvanceReportsRef on AutoDisposeFutureProviderRef<List<VoucherModel>> {
  /// The parameter `advanceNumber` of this provider.
  String? get advanceNumber;

  /// The parameter `projectName` of this provider.
  String? get projectName;

  /// The parameter `invoiceNumber` of this provider.
  String? get invoiceNumber;
}

class _AdvanceReportsProviderElement
    extends AutoDisposeFutureProviderElement<List<VoucherModel>>
    with AdvanceReportsRef {
  _AdvanceReportsProviderElement(super.provider);

  @override
  String? get advanceNumber => (origin as AdvanceReportsProvider).advanceNumber;
  @override
  String? get projectName => (origin as AdvanceReportsProvider).projectName;
  @override
  String? get invoiceNumber => (origin as AdvanceReportsProvider).invoiceNumber;
}

String _$activeFiscalPeriodHash() =>
    r'25aeb79a3583ff14a26dacfd04e6aa4e8002bce7';

/// الفترة المالية النشطة لتاريخ اليوم
///
/// يُستخدَم في شاشة سند الصرف/القبض لعرض الفترة الحالية
///
/// Copied from [activeFiscalPeriod].
@ProviderFor(activeFiscalPeriod)
final activeFiscalPeriodProvider =
    AutoDisposeFutureProvider<FiscalPeriod?>.internal(
  activeFiscalPeriod,
  name: r'activeFiscalPeriodProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeFiscalPeriodHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveFiscalPeriodRef = AutoDisposeFutureProviderRef<FiscalPeriod?>;
String _$fiscalPeriodForDateHash() =>
    r'9321209d08424230ed9dc8fe166d80b4825c7acc';

/// الفترة المالية المناسبة لتاريخ محدد
///
/// يتغيّر تلقائياً عند تغيير التاريخ في النموذج
///
/// Copied from [fiscalPeriodForDate].
@ProviderFor(fiscalPeriodForDate)
const fiscalPeriodForDateProvider = FiscalPeriodForDateFamily();

/// الفترة المالية المناسبة لتاريخ محدد
///
/// يتغيّر تلقائياً عند تغيير التاريخ في النموذج
///
/// Copied from [fiscalPeriodForDate].
class FiscalPeriodForDateFamily extends Family<AsyncValue<FiscalPeriod?>> {
  /// الفترة المالية المناسبة لتاريخ محدد
  ///
  /// يتغيّر تلقائياً عند تغيير التاريخ في النموذج
  ///
  /// Copied from [fiscalPeriodForDate].
  const FiscalPeriodForDateFamily();

  /// الفترة المالية المناسبة لتاريخ محدد
  ///
  /// يتغيّر تلقائياً عند تغيير التاريخ في النموذج
  ///
  /// Copied from [fiscalPeriodForDate].
  FiscalPeriodForDateProvider call(
    DateTime date,
  ) {
    return FiscalPeriodForDateProvider(
      date,
    );
  }

  @override
  FiscalPeriodForDateProvider getProviderOverride(
    covariant FiscalPeriodForDateProvider provider,
  ) {
    return call(
      provider.date,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fiscalPeriodForDateProvider';
}

/// الفترة المالية المناسبة لتاريخ محدد
///
/// يتغيّر تلقائياً عند تغيير التاريخ في النموذج
///
/// Copied from [fiscalPeriodForDate].
class FiscalPeriodForDateProvider
    extends AutoDisposeFutureProvider<FiscalPeriod?> {
  /// الفترة المالية المناسبة لتاريخ محدد
  ///
  /// يتغيّر تلقائياً عند تغيير التاريخ في النموذج
  ///
  /// Copied from [fiscalPeriodForDate].
  FiscalPeriodForDateProvider(
    DateTime date,
  ) : this._internal(
          (ref) => fiscalPeriodForDate(
            ref as FiscalPeriodForDateRef,
            date,
          ),
          from: fiscalPeriodForDateProvider,
          name: r'fiscalPeriodForDateProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fiscalPeriodForDateHash,
          dependencies: FiscalPeriodForDateFamily._dependencies,
          allTransitiveDependencies:
              FiscalPeriodForDateFamily._allTransitiveDependencies,
          date: date,
        );

  FiscalPeriodForDateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final DateTime date;

  @override
  Override overrideWith(
    FutureOr<FiscalPeriod?> Function(FiscalPeriodForDateRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FiscalPeriodForDateProvider._internal(
        (ref) => create(ref as FiscalPeriodForDateRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<FiscalPeriod?> createElement() {
    return _FiscalPeriodForDateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FiscalPeriodForDateProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FiscalPeriodForDateRef on AutoDisposeFutureProviderRef<FiscalPeriod?> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _FiscalPeriodForDateProviderElement
    extends AutoDisposeFutureProviderElement<FiscalPeriod?>
    with FiscalPeriodForDateRef {
  _FiscalPeriodForDateProviderElement(super.provider);

  @override
  DateTime get date => (origin as FiscalPeriodForDateProvider).date;
}

String _$voucherByIdHash() => r'7ae878d0803c0933e047b55593050a07952d17ff';

/// تفاصيل سند واحد — يُستخدَم في وضع التعديل
///
/// Copied from [voucherById].
@ProviderFor(voucherById)
const voucherByIdProvider = VoucherByIdFamily();

/// تفاصيل سند واحد — يُستخدَم في وضع التعديل
///
/// Copied from [voucherById].
class VoucherByIdFamily extends Family<AsyncValue<VoucherModel?>> {
  /// تفاصيل سند واحد — يُستخدَم في وضع التعديل
  ///
  /// Copied from [voucherById].
  const VoucherByIdFamily();

  /// تفاصيل سند واحد — يُستخدَم في وضع التعديل
  ///
  /// Copied from [voucherById].
  VoucherByIdProvider call(
    int id,
  ) {
    return VoucherByIdProvider(
      id,
    );
  }

  @override
  VoucherByIdProvider getProviderOverride(
    covariant VoucherByIdProvider provider,
  ) {
    return call(
      provider.id,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'voucherByIdProvider';
}

/// تفاصيل سند واحد — يُستخدَم في وضع التعديل
///
/// Copied from [voucherById].
class VoucherByIdProvider extends AutoDisposeFutureProvider<VoucherModel?> {
  /// تفاصيل سند واحد — يُستخدَم في وضع التعديل
  ///
  /// Copied from [voucherById].
  VoucherByIdProvider(
    int id,
  ) : this._internal(
          (ref) => voucherById(
            ref as VoucherByIdRef,
            id,
          ),
          from: voucherByIdProvider,
          name: r'voucherByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$voucherByIdHash,
          dependencies: VoucherByIdFamily._dependencies,
          allTransitiveDependencies:
              VoucherByIdFamily._allTransitiveDependencies,
          id: id,
        );

  VoucherByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final int id;

  @override
  Override overrideWith(
    FutureOr<VoucherModel?> Function(VoucherByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VoucherByIdProvider._internal(
        (ref) => create(ref as VoucherByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<VoucherModel?> createElement() {
    return _VoucherByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VoucherByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VoucherByIdRef on AutoDisposeFutureProviderRef<VoucherModel?> {
  /// The parameter `id` of this provider.
  int get id;
}

class _VoucherByIdProviderElement
    extends AutoDisposeFutureProviderElement<VoucherModel?>
    with VoucherByIdRef {
  _VoucherByIdProviderElement(super.provider);

  @override
  int get id => (origin as VoucherByIdProvider).id;
}

String _$voucherSarfNotifierHash() =>
    r'1332cc4171b77582df041cf4ea1430251ef253f4';

/// Notifier لعمليات إنشاء / تعديل / حذف سندات الصرف
///
/// الحالة:
///   AsyncData(null)      — لا عملية جارية (idle)
///   AsyncData('رسالة')   — نجاح العملية
///   AsyncLoading()       — عملية جارية
///   AsyncError(...)      — فشل العملية
///
/// Copied from [VoucherSarfNotifier].
@ProviderFor(VoucherSarfNotifier)
final voucherSarfNotifierProvider = AutoDisposeNotifierProvider<
    VoucherSarfNotifier, AsyncValue<String?>>.internal(
  VoucherSarfNotifier.new,
  name: r'voucherSarfNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$voucherSarfNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VoucherSarfNotifier = AutoDisposeNotifier<AsyncValue<String?>>;
String _$voucherKabdNotifierHash() =>
    r'0d8376115b36e160bf282f1aa8ee2a23c397004f';

/// Notifier لعمليات إنشاء / تعديل / حذف سندات القبض
///
/// الحالة:
///   AsyncData(null)      — لا عملية جارية (idle)
///   AsyncData('رسالة')   — نجاح العملية
///   AsyncLoading()       — عملية جارية
///   AsyncError(...)      — فشل العملية
///
/// Copied from [VoucherKabdNotifier].
@ProviderFor(VoucherKabdNotifier)
final voucherKabdNotifierProvider = AutoDisposeNotifierProvider<
    VoucherKabdNotifier, AsyncValue<String?>>.internal(
  VoucherKabdNotifier.new,
  name: r'voucherKabdNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$voucherKabdNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VoucherKabdNotifier = AutoDisposeNotifier<AsyncValue<String?>>;
String _$advanceDeleteNotifierHash() =>
    r'4187ff2b5a4ada0e2d21cda123be462ebf1bcb7e';

/// See also [AdvanceDeleteNotifier].
@ProviderFor(AdvanceDeleteNotifier)
final advanceDeleteNotifierProvider = AutoDisposeNotifierProvider<
    AdvanceDeleteNotifier, AsyncValue<String?>>.internal(
  AdvanceDeleteNotifier.new,
  name: r'advanceDeleteNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$advanceDeleteNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AdvanceDeleteNotifier = AutoDisposeNotifier<AsyncValue<String?>>;
String _$voucherTransferNotifierHash() =>
    r'46370f75ce694906eeaa4f09a992a57b4b5d8afe';

/// See also [VoucherTransferNotifier].
@ProviderFor(VoucherTransferNotifier)
final voucherTransferNotifierProvider = AutoDisposeNotifierProvider<
    VoucherTransferNotifier, AsyncValue<String?>>.internal(
  VoucherTransferNotifier.new,
  name: r'voucherTransferNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$voucherTransferNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VoucherTransferNotifier = AutoDisposeNotifier<AsyncValue<String?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
