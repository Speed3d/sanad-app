// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recentAuditLogsHash() => r'cc8ca0fd7d6cda70b24dcb62225c43c47beed0aa';

/// آخر 100 سجل مراجعة — يتحدث تلقائياً
///
/// Copied from [recentAuditLogs].
@ProviderFor(recentAuditLogs)
final recentAuditLogsProvider =
    AutoDisposeStreamProvider<List<AuditLogData>>.internal(
  recentAuditLogs,
  name: r'recentAuditLogsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recentAuditLogsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecentAuditLogsRef = AutoDisposeStreamProviderRef<List<AuditLogData>>;
String _$auditLogsByFilterHash() => r'1543f686171c7b920fa5667460f2b003c00195f2';

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

/// سجلات ضمن نطاق تاريخ وفلاتر اختيارية
///
/// Copied from [auditLogsByFilter].
@ProviderFor(auditLogsByFilter)
const auditLogsByFilterProvider = AuditLogsByFilterFamily();

/// سجلات ضمن نطاق تاريخ وفلاتر اختيارية
///
/// Copied from [auditLogsByFilter].
class AuditLogsByFilterFamily extends Family<AsyncValue<List<AuditLogData>>> {
  /// سجلات ضمن نطاق تاريخ وفلاتر اختيارية
  ///
  /// Copied from [auditLogsByFilter].
  const AuditLogsByFilterFamily();

  /// سجلات ضمن نطاق تاريخ وفلاتر اختيارية
  ///
  /// Copied from [auditLogsByFilter].
  AuditLogsByFilterProvider call({
    required DateTime startDate,
    required DateTime endDate,
    String? action,
    int limit = 500,
    int offset = 0,
  }) {
    return AuditLogsByFilterProvider(
      startDate: startDate,
      endDate: endDate,
      action: action,
      limit: limit,
      offset: offset,
    );
  }

  @override
  AuditLogsByFilterProvider getProviderOverride(
    covariant AuditLogsByFilterProvider provider,
  ) {
    return call(
      startDate: provider.startDate,
      endDate: provider.endDate,
      action: provider.action,
      limit: provider.limit,
      offset: provider.offset,
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
  String? get name => r'auditLogsByFilterProvider';
}

/// سجلات ضمن نطاق تاريخ وفلاتر اختيارية
///
/// Copied from [auditLogsByFilter].
class AuditLogsByFilterProvider
    extends AutoDisposeFutureProvider<List<AuditLogData>> {
  /// سجلات ضمن نطاق تاريخ وفلاتر اختيارية
  ///
  /// Copied from [auditLogsByFilter].
  AuditLogsByFilterProvider({
    required DateTime startDate,
    required DateTime endDate,
    String? action,
    int limit = 500,
    int offset = 0,
  }) : this._internal(
          (ref) => auditLogsByFilter(
            ref as AuditLogsByFilterRef,
            startDate: startDate,
            endDate: endDate,
            action: action,
            limit: limit,
            offset: offset,
          ),
          from: auditLogsByFilterProvider,
          name: r'auditLogsByFilterProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$auditLogsByFilterHash,
          dependencies: AuditLogsByFilterFamily._dependencies,
          allTransitiveDependencies:
              AuditLogsByFilterFamily._allTransitiveDependencies,
          startDate: startDate,
          endDate: endDate,
          action: action,
          limit: limit,
          offset: offset,
        );

  AuditLogsByFilterProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.startDate,
    required this.endDate,
    required this.action,
    required this.limit,
    required this.offset,
  }) : super.internal();

  final DateTime startDate;
  final DateTime endDate;
  final String? action;
  final int limit;
  final int offset;

  @override
  Override overrideWith(
    FutureOr<List<AuditLogData>> Function(AuditLogsByFilterRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AuditLogsByFilterProvider._internal(
        (ref) => create(ref as AuditLogsByFilterRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        startDate: startDate,
        endDate: endDate,
        action: action,
        limit: limit,
        offset: offset,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<AuditLogData>> createElement() {
    return _AuditLogsByFilterProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AuditLogsByFilterProvider &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.action == action &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);
    hash = _SystemHash.combine(hash, action.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, offset.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AuditLogsByFilterRef on AutoDisposeFutureProviderRef<List<AuditLogData>> {
  /// The parameter `startDate` of this provider.
  DateTime get startDate;

  /// The parameter `endDate` of this provider.
  DateTime get endDate;

  /// The parameter `action` of this provider.
  String? get action;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `offset` of this provider.
  int get offset;
}

class _AuditLogsByFilterProviderElement
    extends AutoDisposeFutureProviderElement<List<AuditLogData>>
    with AuditLogsByFilterRef {
  _AuditLogsByFilterProviderElement(super.provider);

  @override
  DateTime get startDate => (origin as AuditLogsByFilterProvider).startDate;
  @override
  DateTime get endDate => (origin as AuditLogsByFilterProvider).endDate;
  @override
  String? get action => (origin as AuditLogsByFilterProvider).action;
  @override
  int get limit => (origin as AuditLogsByFilterProvider).limit;
  @override
  int get offset => (origin as AuditLogsByFilterProvider).offset;
}

String _$auditLogCountHash() => r'46254b8f3b9fbaa7b9e2a2c1580d4c7af70e117d';

/// عدد السجلات الكلي — للـ Pagination
///
/// Copied from [auditLogCount].
@ProviderFor(auditLogCount)
final auditLogCountProvider = AutoDisposeFutureProvider<int>.internal(
  auditLogCount,
  name: r'auditLogCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$auditLogCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuditLogCountRef = AutoDisposeFutureProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
