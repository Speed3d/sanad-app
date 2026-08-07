// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fiscal_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allPeriodsHash() => r'17803330f4cd4b7cd892c7aaa84ee19e0921c6a3';

/// Stream تفاعلي بجميع الفترات المالية مرتبةً من الأحدث للأقدم
///
/// يتحدث تلقائياً عند أي تغيير في جدول fiscal_periods
///
/// Copied from [allPeriods].
@ProviderFor(allPeriods)
final allPeriodsProvider =
    AutoDisposeStreamProvider<List<FiscalPeriod>>.internal(
  allPeriods,
  name: r'allPeriodsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allPeriodsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllPeriodsRef = AutoDisposeStreamProviderRef<List<FiscalPeriod>>;
String _$periodVoucherCountHash() =>
    r'398e9bb7764ae5017a91b2516bf0feef2065f103';

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

/// عدد السندات النشطة (غير المحذوفة) لفترة مالية محددة
///
/// يُستخدَم في بطاقة الفترة لعرض الإحصائيات
///
/// Copied from [periodVoucherCount].
@ProviderFor(periodVoucherCount)
const periodVoucherCountProvider = PeriodVoucherCountFamily();

/// عدد السندات النشطة (غير المحذوفة) لفترة مالية محددة
///
/// يُستخدَم في بطاقة الفترة لعرض الإحصائيات
///
/// Copied from [periodVoucherCount].
class PeriodVoucherCountFamily extends Family<AsyncValue<int>> {
  /// عدد السندات النشطة (غير المحذوفة) لفترة مالية محددة
  ///
  /// يُستخدَم في بطاقة الفترة لعرض الإحصائيات
  ///
  /// Copied from [periodVoucherCount].
  const PeriodVoucherCountFamily();

  /// عدد السندات النشطة (غير المحذوفة) لفترة مالية محددة
  ///
  /// يُستخدَم في بطاقة الفترة لعرض الإحصائيات
  ///
  /// Copied from [periodVoucherCount].
  PeriodVoucherCountProvider call(
    int periodId,
  ) {
    return PeriodVoucherCountProvider(
      periodId,
    );
  }

  @override
  PeriodVoucherCountProvider getProviderOverride(
    covariant PeriodVoucherCountProvider provider,
  ) {
    return call(
      provider.periodId,
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
  String? get name => r'periodVoucherCountProvider';
}

/// عدد السندات النشطة (غير المحذوفة) لفترة مالية محددة
///
/// يُستخدَم في بطاقة الفترة لعرض الإحصائيات
///
/// Copied from [periodVoucherCount].
class PeriodVoucherCountProvider extends AutoDisposeFutureProvider<int> {
  /// عدد السندات النشطة (غير المحذوفة) لفترة مالية محددة
  ///
  /// يُستخدَم في بطاقة الفترة لعرض الإحصائيات
  ///
  /// Copied from [periodVoucherCount].
  PeriodVoucherCountProvider(
    int periodId,
  ) : this._internal(
          (ref) => periodVoucherCount(
            ref as PeriodVoucherCountRef,
            periodId,
          ),
          from: periodVoucherCountProvider,
          name: r'periodVoucherCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$periodVoucherCountHash,
          dependencies: PeriodVoucherCountFamily._dependencies,
          allTransitiveDependencies:
              PeriodVoucherCountFamily._allTransitiveDependencies,
          periodId: periodId,
        );

  PeriodVoucherCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.periodId,
  }) : super.internal();

  final int periodId;

  @override
  Override overrideWith(
    FutureOr<int> Function(PeriodVoucherCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PeriodVoucherCountProvider._internal(
        (ref) => create(ref as PeriodVoucherCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        periodId: periodId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _PeriodVoucherCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PeriodVoucherCountProvider && other.periodId == periodId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, periodId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PeriodVoucherCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `periodId` of this provider.
  int get periodId;
}

class _PeriodVoucherCountProviderElement
    extends AutoDisposeFutureProviderElement<int> with PeriodVoucherCountRef {
  _PeriodVoucherCountProviderElement(super.provider);

  @override
  int get periodId => (origin as PeriodVoucherCountProvider).periodId;
}

String _$fiscalNotifierHash() => r'e5500f93cd603ec754819b3c538eb5d79c895045';

/// حالة عملية الفترة المالية
///
/// AsyncData(null)     — لا عملية جارية
/// AsyncData('رسالة') — نجاح (مع رسالة للعرض)
/// AsyncLoading()      — عملية جارية
/// AsyncError(...)     — خطأ
///
/// Copied from [FiscalNotifier].
@ProviderFor(FiscalNotifier)
final fiscalNotifierProvider =
    AutoDisposeNotifierProvider<FiscalNotifier, AsyncValue<String?>>.internal(
  FiscalNotifier.new,
  name: r'fiscalNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fiscalNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FiscalNotifier = AutoDisposeNotifier<AsyncValue<String?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
