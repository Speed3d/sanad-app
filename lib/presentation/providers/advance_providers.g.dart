// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'advance_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$advancesByStatusHash() => r'20178c1950277daee01738e62169332cd022bbf4';

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

/// السلف حسب الحالة — Reactive Stream
///
/// [status] — 'open' | 'draft' | 'posted' | 'cancelled' | null للكل
///
/// Copied from [advancesByStatus].
@ProviderFor(advancesByStatus)
const advancesByStatusProvider = AdvancesByStatusFamily();

/// السلف حسب الحالة — Reactive Stream
///
/// [status] — 'open' | 'draft' | 'posted' | 'cancelled' | null للكل
///
/// Copied from [advancesByStatus].
class AdvancesByStatusFamily extends Family<AsyncValue<List<AdvanceModel>>> {
  /// السلف حسب الحالة — Reactive Stream
  ///
  /// [status] — 'open' | 'draft' | 'posted' | 'cancelled' | null للكل
  ///
  /// Copied from [advancesByStatus].
  const AdvancesByStatusFamily();

  /// السلف حسب الحالة — Reactive Stream
  ///
  /// [status] — 'open' | 'draft' | 'posted' | 'cancelled' | null للكل
  ///
  /// Copied from [advancesByStatus].
  AdvancesByStatusProvider call(
    String? status,
  ) {
    return AdvancesByStatusProvider(
      status,
    );
  }

  @override
  AdvancesByStatusProvider getProviderOverride(
    covariant AdvancesByStatusProvider provider,
  ) {
    return call(
      provider.status,
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
  String? get name => r'advancesByStatusProvider';
}

/// السلف حسب الحالة — Reactive Stream
///
/// [status] — 'open' | 'draft' | 'posted' | 'cancelled' | null للكل
///
/// Copied from [advancesByStatus].
class AdvancesByStatusProvider
    extends AutoDisposeStreamProvider<List<AdvanceModel>> {
  /// السلف حسب الحالة — Reactive Stream
  ///
  /// [status] — 'open' | 'draft' | 'posted' | 'cancelled' | null للكل
  ///
  /// Copied from [advancesByStatus].
  AdvancesByStatusProvider(
    String? status,
  ) : this._internal(
          (ref) => advancesByStatus(
            ref as AdvancesByStatusRef,
            status,
          ),
          from: advancesByStatusProvider,
          name: r'advancesByStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$advancesByStatusHash,
          dependencies: AdvancesByStatusFamily._dependencies,
          allTransitiveDependencies:
              AdvancesByStatusFamily._allTransitiveDependencies,
          status: status,
        );

  AdvancesByStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.status,
  }) : super.internal();

  final String? status;

  @override
  Override overrideWith(
    Stream<List<AdvanceModel>> Function(AdvancesByStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AdvancesByStatusProvider._internal(
        (ref) => create(ref as AdvancesByStatusRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<AdvanceModel>> createElement() {
    return _AdvancesByStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdvancesByStatusProvider && other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AdvancesByStatusRef on AutoDisposeStreamProviderRef<List<AdvanceModel>> {
  /// The parameter `status` of this provider.
  String? get status;
}

class _AdvancesByStatusProviderElement
    extends AutoDisposeStreamProviderElement<List<AdvanceModel>>
    with AdvancesByStatusRef {
  _AdvancesByStatusProviderElement(super.provider);

  @override
  String? get status => (origin as AdvancesByStatusProvider).status;
}

String _$advanceByIdHash() => r'0631ce49071ad8ca4194b8b30afe262423c0ffe5';

/// سلفة واحدة — Reactive Stream
///
/// Copied from [advanceById].
@ProviderFor(advanceById)
const advanceByIdProvider = AdvanceByIdFamily();

/// سلفة واحدة — Reactive Stream
///
/// Copied from [advanceById].
class AdvanceByIdFamily extends Family<AsyncValue<AdvanceModel?>> {
  /// سلفة واحدة — Reactive Stream
  ///
  /// Copied from [advanceById].
  const AdvanceByIdFamily();

  /// سلفة واحدة — Reactive Stream
  ///
  /// Copied from [advanceById].
  AdvanceByIdProvider call(
    int advanceId,
  ) {
    return AdvanceByIdProvider(
      advanceId,
    );
  }

  @override
  AdvanceByIdProvider getProviderOverride(
    covariant AdvanceByIdProvider provider,
  ) {
    return call(
      provider.advanceId,
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
  String? get name => r'advanceByIdProvider';
}

/// سلفة واحدة — Reactive Stream
///
/// Copied from [advanceById].
class AdvanceByIdProvider extends AutoDisposeStreamProvider<AdvanceModel?> {
  /// سلفة واحدة — Reactive Stream
  ///
  /// Copied from [advanceById].
  AdvanceByIdProvider(
    int advanceId,
  ) : this._internal(
          (ref) => advanceById(
            ref as AdvanceByIdRef,
            advanceId,
          ),
          from: advanceByIdProvider,
          name: r'advanceByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$advanceByIdHash,
          dependencies: AdvanceByIdFamily._dependencies,
          allTransitiveDependencies:
              AdvanceByIdFamily._allTransitiveDependencies,
          advanceId: advanceId,
        );

  AdvanceByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.advanceId,
  }) : super.internal();

  final int advanceId;

  @override
  Override overrideWith(
    Stream<AdvanceModel?> Function(AdvanceByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AdvanceByIdProvider._internal(
        (ref) => create(ref as AdvanceByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        advanceId: advanceId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<AdvanceModel?> createElement() {
    return _AdvanceByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdvanceByIdProvider && other.advanceId == advanceId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, advanceId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AdvanceByIdRef on AutoDisposeStreamProviderRef<AdvanceModel?> {
  /// The parameter `advanceId` of this provider.
  int get advanceId;
}

class _AdvanceByIdProviderElement
    extends AutoDisposeStreamProviderElement<AdvanceModel?>
    with AdvanceByIdRef {
  _AdvanceByIdProviderElement(super.provider);

  @override
  int get advanceId => (origin as AdvanceByIdProvider).advanceId;
}

String _$advanceLinesHash() => r'e48f65dcf5def30a1cfc69735a5105a22c195078';

/// أسطر مسودة سلفة — Reactive Stream
///
/// Copied from [advanceLines].
@ProviderFor(advanceLines)
const advanceLinesProvider = AdvanceLinesFamily();

/// أسطر مسودة سلفة — Reactive Stream
///
/// Copied from [advanceLines].
class AdvanceLinesFamily extends Family<AsyncValue<List<AdvanceLineModel>>> {
  /// أسطر مسودة سلفة — Reactive Stream
  ///
  /// Copied from [advanceLines].
  const AdvanceLinesFamily();

  /// أسطر مسودة سلفة — Reactive Stream
  ///
  /// Copied from [advanceLines].
  AdvanceLinesProvider call(
    int advanceId,
  ) {
    return AdvanceLinesProvider(
      advanceId,
    );
  }

  @override
  AdvanceLinesProvider getProviderOverride(
    covariant AdvanceLinesProvider provider,
  ) {
    return call(
      provider.advanceId,
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
  String? get name => r'advanceLinesProvider';
}

/// أسطر مسودة سلفة — Reactive Stream
///
/// Copied from [advanceLines].
class AdvanceLinesProvider
    extends AutoDisposeStreamProvider<List<AdvanceLineModel>> {
  /// أسطر مسودة سلفة — Reactive Stream
  ///
  /// Copied from [advanceLines].
  AdvanceLinesProvider(
    int advanceId,
  ) : this._internal(
          (ref) => advanceLines(
            ref as AdvanceLinesRef,
            advanceId,
          ),
          from: advanceLinesProvider,
          name: r'advanceLinesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$advanceLinesHash,
          dependencies: AdvanceLinesFamily._dependencies,
          allTransitiveDependencies:
              AdvanceLinesFamily._allTransitiveDependencies,
          advanceId: advanceId,
        );

  AdvanceLinesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.advanceId,
  }) : super.internal();

  final int advanceId;

  @override
  Override overrideWith(
    Stream<List<AdvanceLineModel>> Function(AdvanceLinesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AdvanceLinesProvider._internal(
        (ref) => create(ref as AdvanceLinesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        advanceId: advanceId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<AdvanceLineModel>> createElement() {
    return _AdvanceLinesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdvanceLinesProvider && other.advanceId == advanceId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, advanceId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AdvanceLinesRef on AutoDisposeStreamProviderRef<List<AdvanceLineModel>> {
  /// The parameter `advanceId` of this provider.
  int get advanceId;
}

class _AdvanceLinesProviderElement
    extends AutoDisposeStreamProviderElement<List<AdvanceLineModel>>
    with AdvanceLinesRef {
  _AdvanceLinesProviderElement(super.provider);

  @override
  int get advanceId => (origin as AdvanceLinesProvider).advanceId;
}

String _$advancesByItemTypeHash() =>
    r'a1b3c8e904c4a843be37423809ce91f50303c4fd';

/// السلف التي فيها بندٌ يطابق [query] — مفتاحها `advance_id`
///
/// يخدم أمرين معاً في تقرير السلف (الدفعة ج — بلاغ المالك 2026-08-30):
///   ١. **الفلترة**: «وقود» تُبقي السلف التي صُرف فيها وقود
///   ٢. **الشارة**: «وقود: ٣ مصاريف · ١٬٢٠٠٬٠٠٠ د.ع» على كل بطاقة
///
/// ⚠️ استعلامٌ واحد للأمرين لا اثنان: رقمان يُقرآن من مصدرين قد يفترقان،
///   وقائمةٌ تقول «مطابِقة» وشارةٌ تقول «صفر» تُفقد الثقة بالبحث كلّه.
///
/// Copied from [advancesByItemType].
@ProviderFor(advancesByItemType)
const advancesByItemTypeProvider = AdvancesByItemTypeFamily();

/// السلف التي فيها بندٌ يطابق [query] — مفتاحها `advance_id`
///
/// يخدم أمرين معاً في تقرير السلف (الدفعة ج — بلاغ المالك 2026-08-30):
///   ١. **الفلترة**: «وقود» تُبقي السلف التي صُرف فيها وقود
///   ٢. **الشارة**: «وقود: ٣ مصاريف · ١٬٢٠٠٬٠٠٠ د.ع» على كل بطاقة
///
/// ⚠️ استعلامٌ واحد للأمرين لا اثنان: رقمان يُقرآن من مصدرين قد يفترقان،
///   وقائمةٌ تقول «مطابِقة» وشارةٌ تقول «صفر» تُفقد الثقة بالبحث كلّه.
///
/// Copied from [advancesByItemType].
class AdvancesByItemTypeFamily
    extends Family<AsyncValue<Map<int, ({int count, double total})>>> {
  /// السلف التي فيها بندٌ يطابق [query] — مفتاحها `advance_id`
  ///
  /// يخدم أمرين معاً في تقرير السلف (الدفعة ج — بلاغ المالك 2026-08-30):
  ///   ١. **الفلترة**: «وقود» تُبقي السلف التي صُرف فيها وقود
  ///   ٢. **الشارة**: «وقود: ٣ مصاريف · ١٬٢٠٠٬٠٠٠ د.ع» على كل بطاقة
  ///
  /// ⚠️ استعلامٌ واحد للأمرين لا اثنان: رقمان يُقرآن من مصدرين قد يفترقان،
  ///   وقائمةٌ تقول «مطابِقة» وشارةٌ تقول «صفر» تُفقد الثقة بالبحث كلّه.
  ///
  /// Copied from [advancesByItemType].
  const AdvancesByItemTypeFamily();

  /// السلف التي فيها بندٌ يطابق [query] — مفتاحها `advance_id`
  ///
  /// يخدم أمرين معاً في تقرير السلف (الدفعة ج — بلاغ المالك 2026-08-30):
  ///   ١. **الفلترة**: «وقود» تُبقي السلف التي صُرف فيها وقود
  ///   ٢. **الشارة**: «وقود: ٣ مصاريف · ١٬٢٠٠٬٠٠٠ د.ع» على كل بطاقة
  ///
  /// ⚠️ استعلامٌ واحد للأمرين لا اثنان: رقمان يُقرآن من مصدرين قد يفترقان،
  ///   وقائمةٌ تقول «مطابِقة» وشارةٌ تقول «صفر» تُفقد الثقة بالبحث كلّه.
  ///
  /// Copied from [advancesByItemType].
  AdvancesByItemTypeProvider call(
    String query,
  ) {
    return AdvancesByItemTypeProvider(
      query,
    );
  }

  @override
  AdvancesByItemTypeProvider getProviderOverride(
    covariant AdvancesByItemTypeProvider provider,
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
  String? get name => r'advancesByItemTypeProvider';
}

/// السلف التي فيها بندٌ يطابق [query] — مفتاحها `advance_id`
///
/// يخدم أمرين معاً في تقرير السلف (الدفعة ج — بلاغ المالك 2026-08-30):
///   ١. **الفلترة**: «وقود» تُبقي السلف التي صُرف فيها وقود
///   ٢. **الشارة**: «وقود: ٣ مصاريف · ١٬٢٠٠٬٠٠٠ د.ع» على كل بطاقة
///
/// ⚠️ استعلامٌ واحد للأمرين لا اثنان: رقمان يُقرآن من مصدرين قد يفترقان،
///   وقائمةٌ تقول «مطابِقة» وشارةٌ تقول «صفر» تُفقد الثقة بالبحث كلّه.
///
/// Copied from [advancesByItemType].
class AdvancesByItemTypeProvider
    extends AutoDisposeFutureProvider<Map<int, ({int count, double total})>> {
  /// السلف التي فيها بندٌ يطابق [query] — مفتاحها `advance_id`
  ///
  /// يخدم أمرين معاً في تقرير السلف (الدفعة ج — بلاغ المالك 2026-08-30):
  ///   ١. **الفلترة**: «وقود» تُبقي السلف التي صُرف فيها وقود
  ///   ٢. **الشارة**: «وقود: ٣ مصاريف · ١٬٢٠٠٬٠٠٠ د.ع» على كل بطاقة
  ///
  /// ⚠️ استعلامٌ واحد للأمرين لا اثنان: رقمان يُقرآن من مصدرين قد يفترقان،
  ///   وقائمةٌ تقول «مطابِقة» وشارةٌ تقول «صفر» تُفقد الثقة بالبحث كلّه.
  ///
  /// Copied from [advancesByItemType].
  AdvancesByItemTypeProvider(
    String query,
  ) : this._internal(
          (ref) => advancesByItemType(
            ref as AdvancesByItemTypeRef,
            query,
          ),
          from: advancesByItemTypeProvider,
          name: r'advancesByItemTypeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$advancesByItemTypeHash,
          dependencies: AdvancesByItemTypeFamily._dependencies,
          allTransitiveDependencies:
              AdvancesByItemTypeFamily._allTransitiveDependencies,
          query: query,
        );

  AdvancesByItemTypeProvider._internal(
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
    FutureOr<Map<int, ({int count, double total})>> Function(
            AdvancesByItemTypeRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AdvancesByItemTypeProvider._internal(
        (ref) => create(ref as AdvancesByItemTypeRef),
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
  AutoDisposeFutureProviderElement<Map<int, ({int count, double total})>>
      createElement() {
    return _AdvancesByItemTypeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdvancesByItemTypeProvider && other.query == query;
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
mixin AdvancesByItemTypeRef
    on AutoDisposeFutureProviderRef<Map<int, ({int count, double total})>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _AdvancesByItemTypeProviderElement
    extends AutoDisposeFutureProviderElement<
        Map<int, ({int count, double total})>> with AdvancesByItemTypeRef {
  _AdvancesByItemTypeProviderElement(super.provider);

  @override
  String get query => (origin as AdvancesByItemTypeProvider).query;
}

String _$advanceSummaryHash() => r'baadd5433a51154303056d4d28ddf9ce849dd3c8';

/// ملخص السلفة: المُرسَل / المصروف / المتبقي أو العجز
///
/// يُعاد حسابه تلقائياً عند تغيّر الأسطر أو الأرصدة، لأنه يراقب
/// [advanceLinesProvider] و[treasuryBalancesProvider].
///
/// Copied from [advanceSummary].
@ProviderFor(advanceSummary)
const advanceSummaryProvider = AdvanceSummaryFamily();

/// ملخص السلفة: المُرسَل / المصروف / المتبقي أو العجز
///
/// يُعاد حسابه تلقائياً عند تغيّر الأسطر أو الأرصدة، لأنه يراقب
/// [advanceLinesProvider] و[treasuryBalancesProvider].
///
/// Copied from [advanceSummary].
class AdvanceSummaryFamily extends Family<AsyncValue<AdvanceSummary>> {
  /// ملخص السلفة: المُرسَل / المصروف / المتبقي أو العجز
  ///
  /// يُعاد حسابه تلقائياً عند تغيّر الأسطر أو الأرصدة، لأنه يراقب
  /// [advanceLinesProvider] و[treasuryBalancesProvider].
  ///
  /// Copied from [advanceSummary].
  const AdvanceSummaryFamily();

  /// ملخص السلفة: المُرسَل / المصروف / المتبقي أو العجز
  ///
  /// يُعاد حسابه تلقائياً عند تغيّر الأسطر أو الأرصدة، لأنه يراقب
  /// [advanceLinesProvider] و[treasuryBalancesProvider].
  ///
  /// Copied from [advanceSummary].
  AdvanceSummaryProvider call(
    int advanceId,
  ) {
    return AdvanceSummaryProvider(
      advanceId,
    );
  }

  @override
  AdvanceSummaryProvider getProviderOverride(
    covariant AdvanceSummaryProvider provider,
  ) {
    return call(
      provider.advanceId,
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
  String? get name => r'advanceSummaryProvider';
}

/// ملخص السلفة: المُرسَل / المصروف / المتبقي أو العجز
///
/// يُعاد حسابه تلقائياً عند تغيّر الأسطر أو الأرصدة، لأنه يراقب
/// [advanceLinesProvider] و[treasuryBalancesProvider].
///
/// Copied from [advanceSummary].
class AdvanceSummaryProvider extends AutoDisposeFutureProvider<AdvanceSummary> {
  /// ملخص السلفة: المُرسَل / المصروف / المتبقي أو العجز
  ///
  /// يُعاد حسابه تلقائياً عند تغيّر الأسطر أو الأرصدة، لأنه يراقب
  /// [advanceLinesProvider] و[treasuryBalancesProvider].
  ///
  /// Copied from [advanceSummary].
  AdvanceSummaryProvider(
    int advanceId,
  ) : this._internal(
          (ref) => advanceSummary(
            ref as AdvanceSummaryRef,
            advanceId,
          ),
          from: advanceSummaryProvider,
          name: r'advanceSummaryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$advanceSummaryHash,
          dependencies: AdvanceSummaryFamily._dependencies,
          allTransitiveDependencies:
              AdvanceSummaryFamily._allTransitiveDependencies,
          advanceId: advanceId,
        );

  AdvanceSummaryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.advanceId,
  }) : super.internal();

  final int advanceId;

  @override
  Override overrideWith(
    FutureOr<AdvanceSummary> Function(AdvanceSummaryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AdvanceSummaryProvider._internal(
        (ref) => create(ref as AdvanceSummaryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        advanceId: advanceId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<AdvanceSummary> createElement() {
    return _AdvanceSummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdvanceSummaryProvider && other.advanceId == advanceId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, advanceId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AdvanceSummaryRef on AutoDisposeFutureProviderRef<AdvanceSummary> {
  /// The parameter `advanceId` of this provider.
  int get advanceId;
}

class _AdvanceSummaryProviderElement
    extends AutoDisposeFutureProviderElement<AdvanceSummary>
    with AdvanceSummaryRef {
  _AdvanceSummaryProviderElement(super.provider);

  @override
  int get advanceId => (origin as AdvanceSummaryProvider).advanceId;
}

String _$activeAdvancesForTreasuryHash() =>
    r'f17aa2d7a13bdfa67077e227e1822ba36985dd78';

/// السلف المفتوحة والمسودات لخزينة مشروع (لاختيارها عند الاستيراد)
///
/// Copied from [activeAdvancesForTreasury].
@ProviderFor(activeAdvancesForTreasury)
const activeAdvancesForTreasuryProvider = ActiveAdvancesForTreasuryFamily();

/// السلف المفتوحة والمسودات لخزينة مشروع (لاختيارها عند الاستيراد)
///
/// Copied from [activeAdvancesForTreasury].
class ActiveAdvancesForTreasuryFamily
    extends Family<AsyncValue<List<AdvanceModel>>> {
  /// السلف المفتوحة والمسودات لخزينة مشروع (لاختيارها عند الاستيراد)
  ///
  /// Copied from [activeAdvancesForTreasury].
  const ActiveAdvancesForTreasuryFamily();

  /// السلف المفتوحة والمسودات لخزينة مشروع (لاختيارها عند الاستيراد)
  ///
  /// Copied from [activeAdvancesForTreasury].
  ActiveAdvancesForTreasuryProvider call(
    int treasuryId,
  ) {
    return ActiveAdvancesForTreasuryProvider(
      treasuryId,
    );
  }

  @override
  ActiveAdvancesForTreasuryProvider getProviderOverride(
    covariant ActiveAdvancesForTreasuryProvider provider,
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
  String? get name => r'activeAdvancesForTreasuryProvider';
}

/// السلف المفتوحة والمسودات لخزينة مشروع (لاختيارها عند الاستيراد)
///
/// Copied from [activeAdvancesForTreasury].
class ActiveAdvancesForTreasuryProvider
    extends AutoDisposeFutureProvider<List<AdvanceModel>> {
  /// السلف المفتوحة والمسودات لخزينة مشروع (لاختيارها عند الاستيراد)
  ///
  /// Copied from [activeAdvancesForTreasury].
  ActiveAdvancesForTreasuryProvider(
    int treasuryId,
  ) : this._internal(
          (ref) => activeAdvancesForTreasury(
            ref as ActiveAdvancesForTreasuryRef,
            treasuryId,
          ),
          from: activeAdvancesForTreasuryProvider,
          name: r'activeAdvancesForTreasuryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$activeAdvancesForTreasuryHash,
          dependencies: ActiveAdvancesForTreasuryFamily._dependencies,
          allTransitiveDependencies:
              ActiveAdvancesForTreasuryFamily._allTransitiveDependencies,
          treasuryId: treasuryId,
        );

  ActiveAdvancesForTreasuryProvider._internal(
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
    FutureOr<List<AdvanceModel>> Function(ActiveAdvancesForTreasuryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveAdvancesForTreasuryProvider._internal(
        (ref) => create(ref as ActiveAdvancesForTreasuryRef),
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
  AutoDisposeFutureProviderElement<List<AdvanceModel>> createElement() {
    return _ActiveAdvancesForTreasuryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveAdvancesForTreasuryProvider &&
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
mixin ActiveAdvancesForTreasuryRef
    on AutoDisposeFutureProviderRef<List<AdvanceModel>> {
  /// The parameter `treasuryId` of this provider.
  int get treasuryId;
}

class _ActiveAdvancesForTreasuryProviderElement
    extends AutoDisposeFutureProviderElement<List<AdvanceModel>>
    with ActiveAdvancesForTreasuryRef {
  _ActiveAdvancesForTreasuryProviderElement(super.provider);

  @override
  int get treasuryId =>
      (origin as ActiveAdvancesForTreasuryProvider).treasuryId;
}

String _$pendingDraftTotalsHash() =>
    r'232f7395f745284a57b7bb9be6b57b0aebea1df2';

/// مجموع مصاريف المسودات المعلّقة لكل خزينة — للتحذير المبكر
///
/// المفتاح = معرّف الخزينة، القيمة = مجموع المصاريف التي وصلت وتنتظر الاعتماد.
///
/// Copied from [pendingDraftTotals].
@ProviderFor(pendingDraftTotals)
final pendingDraftTotalsProvider =
    AutoDisposeStreamProvider<Map<int, double>>.internal(
  pendingDraftTotals,
  name: r'pendingDraftTotalsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingDraftTotalsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingDraftTotalsRef = AutoDisposeStreamProviderRef<Map<int, double>>;
String _$itemTypesHash() => r'c6842890dbd82872b5f9fc5e961cfddcffee17e2';

/// أنواع البنود النشطة — Reactive Stream
///
/// [kind] — 'sarf' | 'kabd' | null. البنود المُعلَّمة 'both' تظهر دائماً.
///
/// Copied from [itemTypes].
@ProviderFor(itemTypes)
const itemTypesProvider = ItemTypesFamily();

/// أنواع البنود النشطة — Reactive Stream
///
/// [kind] — 'sarf' | 'kabd' | null. البنود المُعلَّمة 'both' تظهر دائماً.
///
/// Copied from [itemTypes].
class ItemTypesFamily extends Family<AsyncValue<List<ItemType>>> {
  /// أنواع البنود النشطة — Reactive Stream
  ///
  /// [kind] — 'sarf' | 'kabd' | null. البنود المُعلَّمة 'both' تظهر دائماً.
  ///
  /// Copied from [itemTypes].
  const ItemTypesFamily();

  /// أنواع البنود النشطة — Reactive Stream
  ///
  /// [kind] — 'sarf' | 'kabd' | null. البنود المُعلَّمة 'both' تظهر دائماً.
  ///
  /// Copied from [itemTypes].
  ItemTypesProvider call(
    String? kind,
  ) {
    return ItemTypesProvider(
      kind,
    );
  }

  @override
  ItemTypesProvider getProviderOverride(
    covariant ItemTypesProvider provider,
  ) {
    return call(
      provider.kind,
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
  String? get name => r'itemTypesProvider';
}

/// أنواع البنود النشطة — Reactive Stream
///
/// [kind] — 'sarf' | 'kabd' | null. البنود المُعلَّمة 'both' تظهر دائماً.
///
/// Copied from [itemTypes].
class ItemTypesProvider extends AutoDisposeStreamProvider<List<ItemType>> {
  /// أنواع البنود النشطة — Reactive Stream
  ///
  /// [kind] — 'sarf' | 'kabd' | null. البنود المُعلَّمة 'both' تظهر دائماً.
  ///
  /// Copied from [itemTypes].
  ItemTypesProvider(
    String? kind,
  ) : this._internal(
          (ref) => itemTypes(
            ref as ItemTypesRef,
            kind,
          ),
          from: itemTypesProvider,
          name: r'itemTypesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$itemTypesHash,
          dependencies: ItemTypesFamily._dependencies,
          allTransitiveDependencies: ItemTypesFamily._allTransitiveDependencies,
          kind: kind,
        );

  ItemTypesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.kind,
  }) : super.internal();

  final String? kind;

  @override
  Override overrideWith(
    Stream<List<ItemType>> Function(ItemTypesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ItemTypesProvider._internal(
        (ref) => create(ref as ItemTypesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        kind: kind,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ItemType>> createElement() {
    return _ItemTypesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ItemTypesProvider && other.kind == kind;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, kind.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ItemTypesRef on AutoDisposeStreamProviderRef<List<ItemType>> {
  /// The parameter `kind` of this provider.
  String? get kind;
}

class _ItemTypesProviderElement
    extends AutoDisposeStreamProviderElement<List<ItemType>> with ItemTypesRef {
  _ItemTypesProviderElement(super.provider);

  @override
  String? get kind => (origin as ItemTypesProvider).kind;
}

String _$itemTypeNamesHash() => r'70672f08b7106a225cf66558074768369fc1cf8f';

/// أسماء أنواع البنود فقط — للقوائم المنسدلة في شاشات السندات والمسودة
///
/// نشتق من الـ DAO مباشرة لا من [itemTypesProvider]`.stream` (مهجور في
/// Riverpod 3)، وتكلفة الاستعلام مهملة لأن الجدول صغير ومُفهرَس.
///
/// Copied from [itemTypeNames].
@ProviderFor(itemTypeNames)
const itemTypeNamesProvider = ItemTypeNamesFamily();

/// أسماء أنواع البنود فقط — للقوائم المنسدلة في شاشات السندات والمسودة
///
/// نشتق من الـ DAO مباشرة لا من [itemTypesProvider]`.stream` (مهجور في
/// Riverpod 3)، وتكلفة الاستعلام مهملة لأن الجدول صغير ومُفهرَس.
///
/// Copied from [itemTypeNames].
class ItemTypeNamesFamily extends Family<AsyncValue<List<String>>> {
  /// أسماء أنواع البنود فقط — للقوائم المنسدلة في شاشات السندات والمسودة
  ///
  /// نشتق من الـ DAO مباشرة لا من [itemTypesProvider]`.stream` (مهجور في
  /// Riverpod 3)، وتكلفة الاستعلام مهملة لأن الجدول صغير ومُفهرَس.
  ///
  /// Copied from [itemTypeNames].
  const ItemTypeNamesFamily();

  /// أسماء أنواع البنود فقط — للقوائم المنسدلة في شاشات السندات والمسودة
  ///
  /// نشتق من الـ DAO مباشرة لا من [itemTypesProvider]`.stream` (مهجور في
  /// Riverpod 3)، وتكلفة الاستعلام مهملة لأن الجدول صغير ومُفهرَس.
  ///
  /// Copied from [itemTypeNames].
  ItemTypeNamesProvider call(
    String? kind,
  ) {
    return ItemTypeNamesProvider(
      kind,
    );
  }

  @override
  ItemTypeNamesProvider getProviderOverride(
    covariant ItemTypeNamesProvider provider,
  ) {
    return call(
      provider.kind,
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
  String? get name => r'itemTypeNamesProvider';
}

/// أسماء أنواع البنود فقط — للقوائم المنسدلة في شاشات السندات والمسودة
///
/// نشتق من الـ DAO مباشرة لا من [itemTypesProvider]`.stream` (مهجور في
/// Riverpod 3)، وتكلفة الاستعلام مهملة لأن الجدول صغير ومُفهرَس.
///
/// Copied from [itemTypeNames].
class ItemTypeNamesProvider extends AutoDisposeStreamProvider<List<String>> {
  /// أسماء أنواع البنود فقط — للقوائم المنسدلة في شاشات السندات والمسودة
  ///
  /// نشتق من الـ DAO مباشرة لا من [itemTypesProvider]`.stream` (مهجور في
  /// Riverpod 3)، وتكلفة الاستعلام مهملة لأن الجدول صغير ومُفهرَس.
  ///
  /// Copied from [itemTypeNames].
  ItemTypeNamesProvider(
    String? kind,
  ) : this._internal(
          (ref) => itemTypeNames(
            ref as ItemTypeNamesRef,
            kind,
          ),
          from: itemTypeNamesProvider,
          name: r'itemTypeNamesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$itemTypeNamesHash,
          dependencies: ItemTypeNamesFamily._dependencies,
          allTransitiveDependencies:
              ItemTypeNamesFamily._allTransitiveDependencies,
          kind: kind,
        );

  ItemTypeNamesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.kind,
  }) : super.internal();

  final String? kind;

  @override
  Override overrideWith(
    Stream<List<String>> Function(ItemTypeNamesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ItemTypeNamesProvider._internal(
        (ref) => create(ref as ItemTypeNamesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        kind: kind,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<String>> createElement() {
    return _ItemTypeNamesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ItemTypeNamesProvider && other.kind == kind;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, kind.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ItemTypeNamesRef on AutoDisposeStreamProviderRef<List<String>> {
  /// The parameter `kind` of this provider.
  String? get kind;
}

class _ItemTypeNamesProviderElement
    extends AutoDisposeStreamProviderElement<List<String>>
    with ItemTypeNamesRef {
  _ItemTypeNamesProviderElement(super.provider);

  @override
  String? get kind => (origin as ItemTypeNamesProvider).kind;
}

String _$payrollLinkPreviewsHash() =>
    r'dd76abc7525a9507ee90ce539570aa5d796d2612';

/// مدير عمليات السلف
///
/// الحالة: AsyncData(رسالة نجاح) | AsyncError(رسالة خطأ) | AsyncLoading
/// معاينة مطابقة أسطر الرواتب في سلفة — **تُقرأ قبل الاعتماد**
///
/// تُعاد قراءتها عند أي تغيّر في أسطر المسودة، فيرى المالك أثر تعديله على
/// المطابقة فوراً بدل أن يكتشف الفرق عند الرفض.
///
/// Copied from [payrollLinkPreviews].
@ProviderFor(payrollLinkPreviews)
const payrollLinkPreviewsProvider = PayrollLinkPreviewsFamily();

/// مدير عمليات السلف
///
/// الحالة: AsyncData(رسالة نجاح) | AsyncError(رسالة خطأ) | AsyncLoading
/// معاينة مطابقة أسطر الرواتب في سلفة — **تُقرأ قبل الاعتماد**
///
/// تُعاد قراءتها عند أي تغيّر في أسطر المسودة، فيرى المالك أثر تعديله على
/// المطابقة فوراً بدل أن يكتشف الفرق عند الرفض.
///
/// Copied from [payrollLinkPreviews].
class PayrollLinkPreviewsFamily
    extends Family<AsyncValue<List<PayrollLinkPreview>>> {
  /// مدير عمليات السلف
  ///
  /// الحالة: AsyncData(رسالة نجاح) | AsyncError(رسالة خطأ) | AsyncLoading
  /// معاينة مطابقة أسطر الرواتب في سلفة — **تُقرأ قبل الاعتماد**
  ///
  /// تُعاد قراءتها عند أي تغيّر في أسطر المسودة، فيرى المالك أثر تعديله على
  /// المطابقة فوراً بدل أن يكتشف الفرق عند الرفض.
  ///
  /// Copied from [payrollLinkPreviews].
  const PayrollLinkPreviewsFamily();

  /// مدير عمليات السلف
  ///
  /// الحالة: AsyncData(رسالة نجاح) | AsyncError(رسالة خطأ) | AsyncLoading
  /// معاينة مطابقة أسطر الرواتب في سلفة — **تُقرأ قبل الاعتماد**
  ///
  /// تُعاد قراءتها عند أي تغيّر في أسطر المسودة، فيرى المالك أثر تعديله على
  /// المطابقة فوراً بدل أن يكتشف الفرق عند الرفض.
  ///
  /// Copied from [payrollLinkPreviews].
  PayrollLinkPreviewsProvider call(
    int advanceId,
  ) {
    return PayrollLinkPreviewsProvider(
      advanceId,
    );
  }

  @override
  PayrollLinkPreviewsProvider getProviderOverride(
    covariant PayrollLinkPreviewsProvider provider,
  ) {
    return call(
      provider.advanceId,
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
  String? get name => r'payrollLinkPreviewsProvider';
}

/// مدير عمليات السلف
///
/// الحالة: AsyncData(رسالة نجاح) | AsyncError(رسالة خطأ) | AsyncLoading
/// معاينة مطابقة أسطر الرواتب في سلفة — **تُقرأ قبل الاعتماد**
///
/// تُعاد قراءتها عند أي تغيّر في أسطر المسودة، فيرى المالك أثر تعديله على
/// المطابقة فوراً بدل أن يكتشف الفرق عند الرفض.
///
/// Copied from [payrollLinkPreviews].
class PayrollLinkPreviewsProvider
    extends AutoDisposeFutureProvider<List<PayrollLinkPreview>> {
  /// مدير عمليات السلف
  ///
  /// الحالة: AsyncData(رسالة نجاح) | AsyncError(رسالة خطأ) | AsyncLoading
  /// معاينة مطابقة أسطر الرواتب في سلفة — **تُقرأ قبل الاعتماد**
  ///
  /// تُعاد قراءتها عند أي تغيّر في أسطر المسودة، فيرى المالك أثر تعديله على
  /// المطابقة فوراً بدل أن يكتشف الفرق عند الرفض.
  ///
  /// Copied from [payrollLinkPreviews].
  PayrollLinkPreviewsProvider(
    int advanceId,
  ) : this._internal(
          (ref) => payrollLinkPreviews(
            ref as PayrollLinkPreviewsRef,
            advanceId,
          ),
          from: payrollLinkPreviewsProvider,
          name: r'payrollLinkPreviewsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$payrollLinkPreviewsHash,
          dependencies: PayrollLinkPreviewsFamily._dependencies,
          allTransitiveDependencies:
              PayrollLinkPreviewsFamily._allTransitiveDependencies,
          advanceId: advanceId,
        );

  PayrollLinkPreviewsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.advanceId,
  }) : super.internal();

  final int advanceId;

  @override
  Override overrideWith(
    FutureOr<List<PayrollLinkPreview>> Function(PayrollLinkPreviewsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PayrollLinkPreviewsProvider._internal(
        (ref) => create(ref as PayrollLinkPreviewsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        advanceId: advanceId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PayrollLinkPreview>> createElement() {
    return _PayrollLinkPreviewsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PayrollLinkPreviewsProvider && other.advanceId == advanceId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, advanceId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PayrollLinkPreviewsRef
    on AutoDisposeFutureProviderRef<List<PayrollLinkPreview>> {
  /// The parameter `advanceId` of this provider.
  int get advanceId;
}

class _PayrollLinkPreviewsProviderElement
    extends AutoDisposeFutureProviderElement<List<PayrollLinkPreview>>
    with PayrollLinkPreviewsRef {
  _PayrollLinkPreviewsProviderElement(super.provider);

  @override
  int get advanceId => (origin as PayrollLinkPreviewsProvider).advanceId;
}

String _$advanceNotifierHash() => r'92163fe89277090f0fa7dd5f8a3b48a8c29f88c3';

/// See also [AdvanceNotifier].
@ProviderFor(AdvanceNotifier)
final advanceNotifierProvider =
    AutoDisposeNotifierProvider<AdvanceNotifier, AsyncValue<String?>>.internal(
  AdvanceNotifier.new,
  name: r'advanceNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$advanceNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AdvanceNotifier = AutoDisposeNotifier<AsyncValue<String?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
