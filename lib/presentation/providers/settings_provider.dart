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

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/app_settings_keys.dart';
import '../../core/services/pdf_service.dart';
import 'repository_providers.dart';

part 'settings_provider.g.dart';

// ── اسم الشركة ────────────────────────────────────────────────────────────────

/// Provider تفاعلي لاسم الشركة — يتحدث عند تغييره من شاشة الإعدادات
@riverpod
Stream<String?> companyName(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSetting('company_name');
}

// ── شعار الشركة (ب-٣) ───────────────────────────────────────────────────────

/// بايتات شعار الشركة — null إن لم يُرفَع شعار
///
/// **لماذا وُجد هذا المزوّد؟** (ب-٣ — 2026-08-23)
///   كان الشعار يُرفَع ويُخزَّن في `app_blobs` عبر `setBlob`، و**`getBlob`
///   لا تُستدعى في أي مكان في المشروع كلّه**. أي أن المالك يرفع شعاره ولا
///   يراه أبداً — لا في الإعدادات ولا في أي مستند. ميزة كاملة مكتوبة
///   نصفها ومعطَّلة بصمت.
///
/// يُبطَل يدوياً بعد الرفع أو الحذف عبر `ref.invalidate(companyLogoProvider)`
/// — الصورة blob لا تدفّق تفاعلياً كبقية الإعدادات.
@riverpod
Future<Uint8List?> companyLogo(Ref ref) {
  return ref.watch(settingsRepositoryProvider).getBlob(
        AppSettingsKeys.companyLogo,
      );
}

/// هوية الشركة الجاهزة لترويسة الـ PDF — الاسم والشعار معاً
///
/// يجمع مصدرين مختلفين (`app_settings` للاسم و`app_blobs` للشعار) في كائن
/// واحد يفهمه `PdfService` بلا أن يعرف شيئاً عن قاعدة البيانات.
///
/// **لا يفشل أبداً:** أي خطأ في القراءة يُعيد ترويسة فارغة فيُطبَع المستند
/// بلا ترويسة. تعطيل الطباعة بسبب شعار غير مقروء ثمن باهظ بلا مقابل.
@riverpod
Future<PdfCompanyHeader> pdfCompanyHeader(Ref ref) async {
  try {
    final repo = ref.watch(settingsRepositoryProvider);
    final name = await repo.getString(AppSettingsKeys.companyName) ?? '';
    final logo = await repo.getBlob(AppSettingsKeys.companyLogo);
    return PdfCompanyHeader(companyName: name, logoBytes: logo);
  } catch (_) {
    return PdfCompanyHeader.empty;
  }
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

/// Provider تفاعلي لسياسة منع الصرف فوق الرصيد
///
/// القيمة: 'true' = منع باتّ (الافتراضي) | 'false' = سماح بالرصيد المدين.
/// null يعني غياب المفتاح، ويُعامَل كـ 'true' (منع) في الواجهة.
@riverpod
Stream<String?> enforceBalanceCheck(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSetting('enforce_balance_check');
}

/// Provider تفاعلي لنمط المزامنة السحابية
///
/// القيمة: 'local' = نسخة محلية إضافية (الافتراضي) | 'drive' = Google Drive.
@riverpod
Stream<String?> cloudSyncMode(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSetting('cloud_sync_mode');
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
