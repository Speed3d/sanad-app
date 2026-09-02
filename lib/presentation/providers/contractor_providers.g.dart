// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contractor_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allContractorsHash() => r'5fc23ae5b709956c0bfe8d39f2f136f18633366c';

/// Stream تفاعلي لجميع المقاولين (غير المحذوفين) مرتب أبجدياً
///
/// Copied from [allContractors].
@ProviderFor(allContractors)
final allContractorsProvider =
    AutoDisposeStreamProvider<List<ContractorModel>>.internal(
  allContractors,
  name: r'allContractorsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allContractorsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllContractorsRef = AutoDisposeStreamProviderRef<List<ContractorModel>>;
String _$searchContractorsHash() => r'593f4c28fe0ffc731ffe2c7dc135ef6612f85ee9';

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

/// بحث نصي في المقاولين
///
/// يُعيد قائمة فارغة إذا كان النص فارغاً
///
/// Copied from [searchContractors].
@ProviderFor(searchContractors)
const searchContractorsProvider = SearchContractorsFamily();

/// بحث نصي في المقاولين
///
/// يُعيد قائمة فارغة إذا كان النص فارغاً
///
/// Copied from [searchContractors].
class SearchContractorsFamily
    extends Family<AsyncValue<List<ContractorModel>>> {
  /// بحث نصي في المقاولين
  ///
  /// يُعيد قائمة فارغة إذا كان النص فارغاً
  ///
  /// Copied from [searchContractors].
  const SearchContractorsFamily();

  /// بحث نصي في المقاولين
  ///
  /// يُعيد قائمة فارغة إذا كان النص فارغاً
  ///
  /// Copied from [searchContractors].
  SearchContractorsProvider call(
    String query,
  ) {
    return SearchContractorsProvider(
      query,
    );
  }

  @override
  SearchContractorsProvider getProviderOverride(
    covariant SearchContractorsProvider provider,
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
  String? get name => r'searchContractorsProvider';
}

/// بحث نصي في المقاولين
///
/// يُعيد قائمة فارغة إذا كان النص فارغاً
///
/// Copied from [searchContractors].
class SearchContractorsProvider
    extends AutoDisposeFutureProvider<List<ContractorModel>> {
  /// بحث نصي في المقاولين
  ///
  /// يُعيد قائمة فارغة إذا كان النص فارغاً
  ///
  /// Copied from [searchContractors].
  SearchContractorsProvider(
    String query,
  ) : this._internal(
          (ref) => searchContractors(
            ref as SearchContractorsRef,
            query,
          ),
          from: searchContractorsProvider,
          name: r'searchContractorsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$searchContractorsHash,
          dependencies: SearchContractorsFamily._dependencies,
          allTransitiveDependencies:
              SearchContractorsFamily._allTransitiveDependencies,
          query: query,
        );

  SearchContractorsProvider._internal(
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
    FutureOr<List<ContractorModel>> Function(SearchContractorsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchContractorsProvider._internal(
        (ref) => create(ref as SearchContractorsRef),
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
  AutoDisposeFutureProviderElement<List<ContractorModel>> createElement() {
    return _SearchContractorsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchContractorsProvider && other.query == query;
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
mixin SearchContractorsRef
    on AutoDisposeFutureProviderRef<List<ContractorModel>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _SearchContractorsProviderElement
    extends AutoDisposeFutureProviderElement<List<ContractorModel>>
    with SearchContractorsRef {
  _SearchContractorsProviderElement(super.provider);

  @override
  String get query => (origin as SearchContractorsProvider).query;
}

String _$contractorNotifierHash() =>
    r'4467d652024c64d32a97f5559deb109f65faf872';

/// Notifier لإدارة عمليات المقاولين
///
/// الحالة:
///   AsyncData(null)      — idle
///   AsyncData('رسالة')   — نجاح
///   AsyncLoading()       — عملية جارية
///   AsyncError(...)      — فشل
///
/// Copied from [ContractorNotifier].
@ProviderFor(ContractorNotifier)
final contractorNotifierProvider = AutoDisposeNotifierProvider<
    ContractorNotifier, AsyncValue<String?>>.internal(
  ContractorNotifier.new,
  name: r'contractorNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$contractorNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ContractorNotifier = AutoDisposeNotifier<AsyncValue<String?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
