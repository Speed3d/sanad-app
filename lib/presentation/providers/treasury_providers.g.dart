// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'treasury_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$treasuryBalancesHash() => r'5bedc0d35ac03a64ea50af21b81be9afb151657f';

/// Stream تفاعلي لجميع أرصدة الخزائن
///
/// يتحدث تلقائياً عند أي تغيير في جداول Treasuries أو Vouchers
/// يُستخدَم في شاشة الخزائن والـ Dashboard
///
/// Copied from [treasuryBalances].
@ProviderFor(treasuryBalances)
final treasuryBalancesProvider =
    AutoDisposeStreamProvider<List<TreasuryBalanceModel>>.internal(
  treasuryBalances,
  name: r'treasuryBalancesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$treasuryBalancesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TreasuryBalancesRef
    = AutoDisposeStreamProviderRef<List<TreasuryBalanceModel>>;
String _$treasuryBalanceHash() => r'bfacfa871442bc9428816376378d58750330f76e';

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

/// Stream تفاعلي لرصيد خزينة واحدة
///
/// [treasuryId] — معرّف الخزينة المطلوبة
///
/// Copied from [treasuryBalance].
@ProviderFor(treasuryBalance)
const treasuryBalanceProvider = TreasuryBalanceFamily();

/// Stream تفاعلي لرصيد خزينة واحدة
///
/// [treasuryId] — معرّف الخزينة المطلوبة
///
/// Copied from [treasuryBalance].
class TreasuryBalanceFamily extends Family<AsyncValue<TreasuryBalanceModel?>> {
  /// Stream تفاعلي لرصيد خزينة واحدة
  ///
  /// [treasuryId] — معرّف الخزينة المطلوبة
  ///
  /// Copied from [treasuryBalance].
  const TreasuryBalanceFamily();

  /// Stream تفاعلي لرصيد خزينة واحدة
  ///
  /// [treasuryId] — معرّف الخزينة المطلوبة
  ///
  /// Copied from [treasuryBalance].
  TreasuryBalanceProvider call(
    int treasuryId,
  ) {
    return TreasuryBalanceProvider(
      treasuryId,
    );
  }

  @override
  TreasuryBalanceProvider getProviderOverride(
    covariant TreasuryBalanceProvider provider,
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
  String? get name => r'treasuryBalanceProvider';
}

/// Stream تفاعلي لرصيد خزينة واحدة
///
/// [treasuryId] — معرّف الخزينة المطلوبة
///
/// Copied from [treasuryBalance].
class TreasuryBalanceProvider
    extends AutoDisposeStreamProvider<TreasuryBalanceModel?> {
  /// Stream تفاعلي لرصيد خزينة واحدة
  ///
  /// [treasuryId] — معرّف الخزينة المطلوبة
  ///
  /// Copied from [treasuryBalance].
  TreasuryBalanceProvider(
    int treasuryId,
  ) : this._internal(
          (ref) => treasuryBalance(
            ref as TreasuryBalanceRef,
            treasuryId,
          ),
          from: treasuryBalanceProvider,
          name: r'treasuryBalanceProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$treasuryBalanceHash,
          dependencies: TreasuryBalanceFamily._dependencies,
          allTransitiveDependencies:
              TreasuryBalanceFamily._allTransitiveDependencies,
          treasuryId: treasuryId,
        );

  TreasuryBalanceProvider._internal(
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
    Stream<TreasuryBalanceModel?> Function(TreasuryBalanceRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TreasuryBalanceProvider._internal(
        (ref) => create(ref as TreasuryBalanceRef),
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
  AutoDisposeStreamProviderElement<TreasuryBalanceModel?> createElement() {
    return _TreasuryBalanceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TreasuryBalanceProvider && other.treasuryId == treasuryId;
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
mixin TreasuryBalanceRef
    on AutoDisposeStreamProviderRef<TreasuryBalanceModel?> {
  /// The parameter `treasuryId` of this provider.
  int get treasuryId;
}

class _TreasuryBalanceProviderElement
    extends AutoDisposeStreamProviderElement<TreasuryBalanceModel?>
    with TreasuryBalanceRef {
  _TreasuryBalanceProviderElement(super.provider);

  @override
  int get treasuryId => (origin as TreasuryBalanceProvider).treasuryId;
}

String _$totalTreasuryBalanceHash() =>
    r'a9f53064eabf1b97c23493477d416a0dbbaa52e4';

/// إجمالي رصيد جميع الخزائن (Future — للقراءة لمرة واحدة)
///
/// يُستخدَم في بطاقة الإجمالي في الـ Dashboard
///
/// Copied from [totalTreasuryBalance].
@ProviderFor(totalTreasuryBalance)
final totalTreasuryBalanceProvider =
    AutoDisposeFutureProvider<({double totalIqd, double totalUsd})>.internal(
  totalTreasuryBalance,
  name: r'totalTreasuryBalanceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalTreasuryBalanceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalTreasuryBalanceRef
    = AutoDisposeFutureProviderRef<({double totalIqd, double totalUsd})>;
String _$allTreasuriesHash() => r'e0b7e04f7426fbd24eb336b52d8cb801c6fc5fa7';

/// جميع الخزائن النشطة (Future — للـ Dropdowns)
///
/// Copied from [allTreasuries].
@ProviderFor(allTreasuries)
final allTreasuriesProvider =
    AutoDisposeFutureProvider<List<TreasuryModel>>.internal(
  allTreasuries,
  name: r'allTreasuriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allTreasuriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllTreasuriesRef = AutoDisposeFutureProviderRef<List<TreasuryModel>>;
String _$treasuryNotifierHash() => r'da36bbcd3f13c2482f44cf493fa049114aea2c4f';

/// Notifier لعمليات إنشاء / تعديل / حذف / تفعيل الخزائن
///
/// الحالة:
///   AsyncData(null)      — لا عملية جارية
///   AsyncData('رسالة')   — نجاح
///   AsyncLoading()       — عملية جارية
///   AsyncError(...)      — خطأ
///
/// Copied from [TreasuryNotifier].
@ProviderFor(TreasuryNotifier)
final treasuryNotifierProvider =
    AutoDisposeNotifierProvider<TreasuryNotifier, AsyncValue<String?>>.internal(
  TreasuryNotifier.new,
  name: r'treasuryNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$treasuryNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TreasuryNotifier = AutoDisposeNotifier<AsyncValue<String?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
