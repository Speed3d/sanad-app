// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$attachmentsRootHash() => r'fd0e190d4b9aef664f2afbe222f3bada211add7c';

/// جذر مجلد المرفقات — فارغ يعني «لم يُعيَّن بعد»
///
/// Copied from [attachmentsRoot].
@ProviderFor(attachmentsRoot)
final attachmentsRootProvider = AutoDisposeStreamProvider<String?>.internal(
  attachmentsRoot,
  name: r'attachmentsRootProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$attachmentsRootHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AttachmentsRootRef = AutoDisposeStreamProviderRef<String?>;
String _$attachmentsForHash() => r'8c868fc8c45471bb482619ff0f979a2034e2c23e';

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

/// مرفقات كيان محدَّد — تدفّق تفاعلي
///
/// Copied from [attachmentsFor].
@ProviderFor(attachmentsFor)
const attachmentsForProvider = AttachmentsForFamily();

/// مرفقات كيان محدَّد — تدفّق تفاعلي
///
/// Copied from [attachmentsFor].
class AttachmentsForFamily extends Family<AsyncValue<List<Attachment>>> {
  /// مرفقات كيان محدَّد — تدفّق تفاعلي
  ///
  /// Copied from [attachmentsFor].
  const AttachmentsForFamily();

  /// مرفقات كيان محدَّد — تدفّق تفاعلي
  ///
  /// Copied from [attachmentsFor].
  AttachmentsForProvider call({
    required String entityType,
    required int entityId,
  }) {
    return AttachmentsForProvider(
      entityType: entityType,
      entityId: entityId,
    );
  }

  @override
  AttachmentsForProvider getProviderOverride(
    covariant AttachmentsForProvider provider,
  ) {
    return call(
      entityType: provider.entityType,
      entityId: provider.entityId,
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
  String? get name => r'attachmentsForProvider';
}

/// مرفقات كيان محدَّد — تدفّق تفاعلي
///
/// Copied from [attachmentsFor].
class AttachmentsForProvider
    extends AutoDisposeStreamProvider<List<Attachment>> {
  /// مرفقات كيان محدَّد — تدفّق تفاعلي
  ///
  /// Copied from [attachmentsFor].
  AttachmentsForProvider({
    required String entityType,
    required int entityId,
  }) : this._internal(
          (ref) => attachmentsFor(
            ref as AttachmentsForRef,
            entityType: entityType,
            entityId: entityId,
          ),
          from: attachmentsForProvider,
          name: r'attachmentsForProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$attachmentsForHash,
          dependencies: AttachmentsForFamily._dependencies,
          allTransitiveDependencies:
              AttachmentsForFamily._allTransitiveDependencies,
          entityType: entityType,
          entityId: entityId,
        );

  AttachmentsForProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.entityType,
    required this.entityId,
  }) : super.internal();

  final String entityType;
  final int entityId;

  @override
  Override overrideWith(
    Stream<List<Attachment>> Function(AttachmentsForRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AttachmentsForProvider._internal(
        (ref) => create(ref as AttachmentsForRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        entityType: entityType,
        entityId: entityId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Attachment>> createElement() {
    return _AttachmentsForProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AttachmentsForProvider &&
        other.entityType == entityType &&
        other.entityId == entityId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, entityType.hashCode);
    hash = _SystemHash.combine(hash, entityId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AttachmentsForRef on AutoDisposeStreamProviderRef<List<Attachment>> {
  /// The parameter `entityType` of this provider.
  String get entityType;

  /// The parameter `entityId` of this provider.
  int get entityId;
}

class _AttachmentsForProviderElement
    extends AutoDisposeStreamProviderElement<List<Attachment>>
    with AttachmentsForRef {
  _AttachmentsForProviderElement(super.provider);

  @override
  String get entityType => (origin as AttachmentsForProvider).entityType;
  @override
  int get entityId => (origin as AttachmentsForProvider).entityId;
}

String _$attachmentsTotalSizeHash() =>
    r'08e2c7446bc5c2eafd13fc9cde609ecdb6aa22c0';

/// إجمالي حجم كل المرفقات — يُعرَض قبل النسخة الاحتياطية الشاملة
///
/// Copied from [attachmentsTotalSize].
@ProviderFor(attachmentsTotalSize)
final attachmentsTotalSizeProvider = AutoDisposeFutureProvider<int>.internal(
  attachmentsTotalSize,
  name: r'attachmentsTotalSizeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$attachmentsTotalSizeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AttachmentsTotalSizeRef = AutoDisposeFutureProviderRef<int>;
String _$attachmentNotifierHash() =>
    r'358d511ec0dac9d5d4d15f5d1a9f0fcc43199bab';

/// See also [AttachmentNotifier].
@ProviderFor(AttachmentNotifier)
final attachmentNotifierProvider = AutoDisposeNotifierProvider<
    AttachmentNotifier, AsyncValue<String?>>.internal(
  AttachmentNotifier.new,
  name: r'attachmentNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$attachmentNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AttachmentNotifier = AutoDisposeNotifier<AsyncValue<String?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
