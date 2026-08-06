// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$companyNameHash() => r'7d948b89006ce36158871a92546d1ed834393ae8';

/// Provider تفاعلي لاسم الشركة — يتحدث عند تغييره من شاشة الإعدادات
///
/// Copied from [companyName].
@ProviderFor(companyName)
final companyNameProvider = AutoDisposeStreamProvider<String?>.internal(
  companyName,
  name: r'companyNameProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$companyNameHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CompanyNameRef = AutoDisposeStreamProviderRef<String?>;
String _$appLanguageHash() => r'c20fe0dab5283c2cc7235adb21de70f977a6860a';

/// Provider تفاعلي للغة الحالية: 'ar' | 'en'
///
/// الواجهة تتحدث تلقائياً عند تغيير اللغة من شاشة الإعدادات
///
/// Copied from [appLanguage].
@ProviderFor(appLanguage)
final appLanguageProvider = AutoDisposeStreamProvider<String?>.internal(
  appLanguage,
  name: r'appLanguageProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appLanguageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppLanguageRef = AutoDisposeStreamProviderRef<String?>;
String _$appThemeModeHash() => r'5f6d67c567bb9cc528c53a9299e2fd3d57888e7d';

/// Provider تفاعلي للمظهر: 'light' | 'dark' | 'system'
///
/// Copied from [appThemeMode].
@ProviderFor(appThemeMode)
final appThemeModeProvider = AutoDisposeStreamProvider<String?>.internal(
  appThemeMode,
  name: r'appThemeModeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appThemeModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppThemeModeRef = AutoDisposeStreamProviderRef<String?>;
String _$primaryCurrencyHash() => r'370b23abf05e473d56d213a29fcd75420135dbfa';

/// Provider للعملة الأساسية — 'IQD' افتراضياً
///
/// Copied from [primaryCurrency].
@ProviderFor(primaryCurrency)
final primaryCurrencyProvider = AutoDisposeStreamProvider<String?>.internal(
  primaryCurrency,
  name: r'primaryCurrencyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$primaryCurrencyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PrimaryCurrencyRef = AutoDisposeStreamProviderRef<String?>;
String _$secondaryCurrencyHash() => r'41c0b19a0db7197db54ab50c13b070d5892d9461';

/// Provider للعملة الثانوية — 'USD' افتراضياً
///
/// Copied from [secondaryCurrency].
@ProviderFor(secondaryCurrency)
final secondaryCurrencyProvider = AutoDisposeStreamProvider<String?>.internal(
  secondaryCurrency,
  name: r'secondaryCurrencyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$secondaryCurrencyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SecondaryCurrencyRef = AutoDisposeStreamProviderRef<String?>;
String _$exchangeRateHash() => r'da7b4c17ddc549b8cdb1bdefccf6afbc0a952a10';

/// Provider تفاعلي لسعر الصرف كـ double
///
/// يُستخدَم في حسابات التحويل بين العملات
/// يستعلم من قاعدة البيانات مباشرةً لتجنب deprecated .stream API
///
/// Copied from [exchangeRate].
@ProviderFor(exchangeRate)
final exchangeRateProvider = AutoDisposeStreamProvider<double>.internal(
  exchangeRate,
  name: r'exchangeRateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$exchangeRateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExchangeRateRef = AutoDisposeStreamProviderRef<double>;
String _$primaryColorSeedHash() => r'8226328fbbd0e19a0b2f1e75624401747f3cdbd1';

/// Provider تفاعلي لقيمة لون البذرة المختار (int مُخزَّن كنص)
///
/// يُستخدَم في main.dart لبناء الثيم ديناميكياً:
///   final raw = ref.watch(primaryColorSeedProvider).valueOrNull;
///   final seed = raw != null ? Color(int.parse(raw)) : AppColors.primarySeed;
///
/// Copied from [primaryColorSeed].
@ProviderFor(primaryColorSeed)
final primaryColorSeedProvider = AutoDisposeStreamProvider<String?>.internal(
  primaryColorSeed,
  name: r'primaryColorSeedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$primaryColorSeedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PrimaryColorSeedRef = AutoDisposeStreamProviderRef<String?>;
String _$firstRunCompleteHash() => r'c6e71981d98e9b397bf3f180917273e693810be8';

/// Provider تفاعلي لحالة الإعداد الأول
///
/// يُستخدَم في splash_screen لتحديد وجهة التوجيه الأولى:
///   'false' أو null → شاشة الإعداد الأول
///   'true'          → شاشة تسجيل الدخول
///
/// Copied from [firstRunComplete].
@ProviderFor(firstRunComplete)
final firstRunCompleteProvider = AutoDisposeStreamProvider<String?>.internal(
  firstRunComplete,
  name: r'firstRunCompleteProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$firstRunCompleteHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirstRunCompleteRef = AutoDisposeStreamProviderRef<String?>;
String _$allSettingsHash() => r'de7ab0a7305cf2076274309510d51ac1be46304a';

/// Provider لجميع الإعدادات كـ Map (للتحميل الأولي عند فتح التطبيق)
///
/// Copied from [allSettings].
@ProviderFor(allSettings)
final allSettingsProvider =
    AutoDisposeFutureProvider<Map<String, String>>.internal(
  allSettings,
  name: r'allSettingsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allSettingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllSettingsRef = AutoDisposeFutureProviderRef<Map<String, String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
