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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
