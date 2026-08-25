// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userRepositoryHash() => r'326f276b40aa8f0d5f365428a1ae302c7550186e';

/// Provider مستودع المستخدمين
///
/// يُعيد [IUserRepository] — الكود يعتمد على الواجهة لا على التنفيذ
///
/// Copied from [userRepository].
@ProviderFor(userRepository)
final userRepositoryProvider = Provider<IUserRepository>.internal(
  userRepository,
  name: r'userRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserRepositoryRef = ProviderRef<IUserRepository>;
String _$treasuryRepositoryHash() =>
    r'257ca3ede09610d5e2d3ff8f3c2e89d7e9218f82';

/// Provider مستودع الخزائن
///
/// Copied from [treasuryRepository].
@ProviderFor(treasuryRepository)
final treasuryRepositoryProvider = Provider<ITreasuryRepository>.internal(
  treasuryRepository,
  name: r'treasuryRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$treasuryRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TreasuryRepositoryRef = ProviderRef<ITreasuryRepository>;
String _$voucherRepositoryHash() => r'6895a766fc3b99a4ffeff478e6db27f35b7affc6';

/// Provider مستودع السندات
///
/// Copied from [voucherRepository].
@ProviderFor(voucherRepository)
final voucherRepositoryProvider = Provider<IVoucherRepository>.internal(
  voucherRepository,
  name: r'voucherRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$voucherRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VoucherRepositoryRef = ProviderRef<IVoucherRepository>;
String _$settingsRepositoryHash() =>
    r'0664ce8dd6cb0e2b2179992820c239e20825a5e1';

/// Provider مستودع الإعدادات
///
/// Copied from [settingsRepository].
@ProviderFor(settingsRepository)
final settingsRepositoryProvider = Provider<ISettingsRepository>.internal(
  settingsRepository,
  name: r'settingsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SettingsRepositoryRef = ProviderRef<ISettingsRepository>;
String _$advanceRepositoryHash() => r'7f453a79c5e68c02d62cfec1d9907dab37ff4998';

/// Provider مستودع سلف المشاريع
///
/// ⚠️ سلف المشاريع (Advances) ≠ سلف الموظفين (CashAdvances) التي يديرها
/// EmployeesDao — راجع advances_table.dart
///
/// Copied from [advanceRepository].
@ProviderFor(advanceRepository)
final advanceRepositoryProvider = Provider<IAdvanceRepository>.internal(
  advanceRepository,
  name: r'advanceRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$advanceRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdvanceRepositoryRef = ProviderRef<IAdvanceRepository>;
String _$payrollRepositoryHash() => r'e05a611c4c9d25b2c6a28fd32ad9f84539ae9f0d';

/// Provider مستودع كشوف الرواتب (Schema v7)
///
/// ⚠️ **بلا واجهة `domain` عمداً** — بخلاف بقية المستودعات هنا. الكشف
/// وسطوره يُعادان كجداول Drift مباشرةً، على نمط `AttachmentsDao` المعتمد
/// في Schema v6: لا مصدر بيانات ثانياً يُستبدَل، والاختبارات تستعمل قاعدة
/// حقيقية أصلاً. وكل طبقة تحويل إضافية موضعٌ يُنسى فيه حقل — وهي **علّة
/// ب-١ بعينها** (المستودع كان يُسقط أربعة حقول في ثلاثة مواضع).
///
/// Copied from [payrollRepository].
@ProviderFor(payrollRepository)
final payrollRepositoryProvider = Provider<PayrollRepository>.internal(
  payrollRepository,
  name: r'payrollRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$payrollRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PayrollRepositoryRef = ProviderRef<PayrollRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
