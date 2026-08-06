// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allPartnersHash() => r'78aa4f7fd577e58c8c6fd598ec436c6ebdb02009';

/// Stream تفاعلي لجميع الشركاء (غير المحذوفين) مرتب أبجدياً
///
/// Copied from [allPartners].
@ProviderFor(allPartners)
final allPartnersProvider =
    AutoDisposeStreamProvider<List<PartnerModel>>.internal(
  allPartners,
  name: r'allPartnersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allPartnersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllPartnersRef = AutoDisposeStreamProviderRef<List<PartnerModel>>;
String _$totalSharePercentageHash() =>
    r'dd7a5981587f0e4fb1dbf54582fadcee6a908101';

/// مجموع الحصص المُخصَّصة لجميع الشركاء النشطين
///
/// يُستخدَم للتحقق من أن الحصة الجديدة لا تتجاوز الحد الأقصى 100%
///
/// Copied from [totalSharePercentage].
@ProviderFor(totalSharePercentage)
final totalSharePercentageProvider = AutoDisposeFutureProvider<double>.internal(
  totalSharePercentage,
  name: r'totalSharePercentageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalSharePercentageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalSharePercentageRef = AutoDisposeFutureProviderRef<double>;
String _$searchPartnersHash() => r'2fbcac9d0eb10d3958c712d50646d87a84716525';

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

/// بحث نصي في الشركاء
///
/// يُعيد قائمة فارغة إذا كان النص فارغاً
///
/// Copied from [searchPartners].
@ProviderFor(searchPartners)
const searchPartnersProvider = SearchPartnersFamily();

/// بحث نصي في الشركاء
///
/// يُعيد قائمة فارغة إذا كان النص فارغاً
///
/// Copied from [searchPartners].
class SearchPartnersFamily extends Family<AsyncValue<List<PartnerModel>>> {
  /// بحث نصي في الشركاء
  ///
  /// يُعيد قائمة فارغة إذا كان النص فارغاً
  ///
  /// Copied from [searchPartners].
  const SearchPartnersFamily();

  /// بحث نصي في الشركاء
  ///
  /// يُعيد قائمة فارغة إذا كان النص فارغاً
  ///
  /// Copied from [searchPartners].
  SearchPartnersProvider call(
    String query,
  ) {
    return SearchPartnersProvider(
      query,
    );
  }

  @override
  SearchPartnersProvider getProviderOverride(
    covariant SearchPartnersProvider provider,
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
  String? get name => r'searchPartnersProvider';
}

/// بحث نصي في الشركاء
///
/// يُعيد قائمة فارغة إذا كان النص فارغاً
///
/// Copied from [searchPartners].
class SearchPartnersProvider
    extends AutoDisposeFutureProvider<List<PartnerModel>> {
  /// بحث نصي في الشركاء
  ///
  /// يُعيد قائمة فارغة إذا كان النص فارغاً
  ///
  /// Copied from [searchPartners].
  SearchPartnersProvider(
    String query,
  ) : this._internal(
          (ref) => searchPartners(
            ref as SearchPartnersRef,
            query,
          ),
          from: searchPartnersProvider,
          name: r'searchPartnersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$searchPartnersHash,
          dependencies: SearchPartnersFamily._dependencies,
          allTransitiveDependencies:
              SearchPartnersFamily._allTransitiveDependencies,
          query: query,
        );

  SearchPartnersProvider._internal(
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
    FutureOr<List<PartnerModel>> Function(SearchPartnersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchPartnersProvider._internal(
        (ref) => create(ref as SearchPartnersRef),
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
  AutoDisposeFutureProviderElement<List<PartnerModel>> createElement() {
    return _SearchPartnersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchPartnersProvider && other.query == query;
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
mixin SearchPartnersRef on AutoDisposeFutureProviderRef<List<PartnerModel>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _SearchPartnersProviderElement
    extends AutoDisposeFutureProviderElement<List<PartnerModel>>
    with SearchPartnersRef {
  _SearchPartnersProviderElement(super.provider);

  @override
  String get query => (origin as SearchPartnersProvider).query;
}

String _$partnerNotifierHash() => r'f7a44ddc7ff29cb74db57e956c92e03fbfb22dc0';

/// Notifier لإدارة عمليات الشركاء
///
/// القاعدة الذهبية: مجموع حصص جميع الشركاء ≤ 100%
/// يُتحقَّق منها في createPartner و updatePartner
///
/// الحالة:
///   AsyncData(null)      — idle
///   AsyncData('رسالة')   — نجاح
///   AsyncLoading()       — عملية جارية
///   AsyncError(...)      — فشل
///
/// Copied from [PartnerNotifier].
@ProviderFor(PartnerNotifier)
final partnerNotifierProvider =
    AutoDisposeNotifierProvider<PartnerNotifier, AsyncValue<String?>>.internal(
  PartnerNotifier.new,
  name: r'partnerNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$partnerNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PartnerNotifier = AutoDisposeNotifier<AsyncValue<String?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
