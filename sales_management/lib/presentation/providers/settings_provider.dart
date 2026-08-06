// ─────────────────────────────────────────────────────────────────────────────
// settings_provider.dart — Providers إعدادات التطبيق
//
// يُوفّر Providers تفاعلية لأهم إعدادات التطبيق:
//   - اسم الشركة
//   - اللغة
//   - المظهر (ثيم)
//   - سعر الصرف
//   - العملة الأساسية
//   - حالة الإعداد الأول
//
// الاستخدام في الواجهة:
//   final companyName = ref.watch(companyNameProvider);
//   final theme = ref.watch(appThemeModeProvider);
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'repository_providers.dart';

part 'settings_provider.g.dart';

// ── اسم الشركة ────────────────────────────────────────────────────────────────

/// Provider تفاعلي لاسم الشركة — يتحدث عند تغييره من شاشة الإعدادات
@riverpod
Stream<String?> companyName(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSetting('company_name');
}

// ── اللغة ─────────────────────────────────────────────────────────────────────

/// Provider تفاعلي للغة الحالية: 'ar' | 'en'
///
/// الواجهة تتحدث تلقائياً عند تغيير اللغة من شاشة الإعدادات
@riverpod
Stream<String?> appLanguage(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSetting('language');
}

// ── المظهر ────────────────────────────────────────────────────────────────────

/// Provider تفاعلي للمظهر: 'light' | 'dark' | 'system'
@riverpod
Stream<String?> appThemeMode(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSetting('theme');
}

// ── العملات ───────────────────────────────────────────────────────────────────

/// Provider للعملة الأساسية — 'IQD' افتراضياً
@riverpod
Stream<String?> primaryCurrency(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSetting('primary_currency');
}

/// Provider للعملة الثانوية — 'USD' افتراضياً
@riverpod
Stream<String?> secondaryCurrency(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSetting('secondary_currency');
}

/// Provider تفاعلي لسعر الصرف كـ double
///
/// يُستخدَم في حسابات التحويل بين العملات
/// يستعلم من قاعدة البيانات مباشرةً لتجنب deprecated .stream API
@riverpod
Stream<double> exchangeRate(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  // نُحوّل القيمة النصية مباشرةً في Stream transform
  return repo.watchSetting('exchange_rate').map(
    (raw) => double.tryParse(raw ?? '') ?? 1310.0,
  );
}

// ── اللون الأساسي (البذرة) ────────────────────────────────────────────────────

/// Provider تفاعلي لقيمة لون البذرة المختار (int مُخزَّن كنص)
///
/// يُستخدَم في main.dart لبناء الثيم ديناميكياً:
///   final raw = ref.watch(primaryColorSeedProvider).valueOrNull;
///   final seed = raw != null ? Color(int.parse(raw)) : AppColors.primarySeed;
@riverpod
Stream<String?> primaryColorSeed(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSetting('primary_color');
}

// ── حالة الإعداد الأول ────────────────────────────────────────────────────────

/// Provider تفاعلي لحالة الإعداد الأول
///
/// يُستخدَم في splash_screen لتحديد وجهة التوجيه الأولى:
///   'false' أو null → شاشة الإعداد الأول
///   'true'          → شاشة تسجيل الدخول
@riverpod
Stream<String?> firstRunComplete(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSetting('first_run_complete');
}

// ── جميع الإعدادات دفعةً ─────────────────────────────────────────────────────

/// Provider لجميع الإعدادات كـ Map (للتحميل الأولي عند فتح التطبيق)
@riverpod
Future<Map<String, String>> allSettings(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getAllSettings();
}
