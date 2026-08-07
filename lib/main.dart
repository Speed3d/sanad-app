// ─────────────────────────────────────────────────────────────────────────────
// main.dart — نقطة الدخول الرئيسية للتطبيق
//
// هذا الملف يقوم بـ:
//   1. تهيئة Flutter binding
//   2. تسجيل الـ Providers (Riverpod ProviderScope)
//   3. تشغيل التطبيق بالثيم واللغة الصحيحين (ديناميكيين من قاعدة البيانات)
//
// دعم الثيم الديناميكي:
//   appThemeModeProvider  → Stream<String?> → ThemeMode (light/dark/system)
//   primaryColorSeedProvider → Stream<String?> → Color (لون البذرة المخصص)
//
// دعم اللغة الديناميكية:
//   appLanguageProvider → Stream<String?> → Locale ('ar' | 'en')
//   يُطبَّق التغيير فوراً دون إعادة تشغيل التطبيق
//
// دعم الويب (OPFS):
//   drift_flutter يختار OPFS تلقائياً على الويب الحديث
//   للإنتاج: يجب ضبط COOP/COEP headers على الخادم:
//     Cross-Origin-Opener-Policy: same-origin
//     Cross-Origin-Embedder-Policy: require-corp
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/settings_provider.dart';

/// نقطة الدخول الرئيسية
void main() async {
  // تأكد من تهيئة Flutter binding قبل أي عملية غير متزامنة
  WidgetsFlutterBinding.ensureInitialized();

  // ضبط اتجاهات الشاشة المسموح بها — عمودي وأفقي (للتابلت والويب)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // تشغيل التطبيق مغلَّفاً بـ ProviderScope (الـ DI Container لـ Riverpod)
  runApp(
    const ProviderScope(
      child: SalesManagementApp(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// الكلاس الجذري للتطبيق
// ─────────────────────────────────────────────────────────────────────────────

/// الكلاس الجذري — يُراقب إعدادات الثيم واللغة ديناميكياً
///
/// ConsumerWidget يسمح بمراقبة Riverpod Providers مباشرةً.
/// أي تغيير في الثيم أو اللغة من شاشة الإعدادات يُطبَّق فوراً
/// دون إعادة تشغيل التطبيق.
class SalesManagementApp extends ConsumerWidget {
  const SalesManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── التوجيه ───────────────────────────────────────────────────────────────
    final router = ref.watch(appRouterProvider);

    // ── المظهر الديناميكي ────────────────────────────────────────────────────
    // نقرأ حالة المظهر من الإعدادات — القيمة الافتراضية 'system' إذا لم تُحمَّل بعد
    final themeStr = ref.watch(appThemeModeProvider).valueOrNull;
    final themeMode = switch (themeStr) {
      'light'  => ThemeMode.light,
      'dark'   => ThemeMode.dark,
      _        => ThemeMode.system, // system = تلقائي حسب إعداد الجهاز
    };

    // ── لون البذرة الديناميكي ─────────────────────────────────────────────────
    // نقرأ لون البذرة المختار من الإعدادات ونحوّله من String إلى Color
    final colorStr = ref.watch(primaryColorSeedProvider).valueOrNull;
    final seedColor = _parseSeedColor(colorStr);

    // ── اللغة ────────────────────────────────────────────────────────────────
    // مثبَّتة على العربية (RTL) حالياً — الترجمة الإنجليزية غير موصولة بعد،
    // وقُفل تبديل اللغة (قرار المالك 2026-08-07) لتفادي واجهة نصفها مقلوب.
    // يُعاد التبديل عند ربط l10n فعلياً.
    const locale = Locale('ar');

    return MaterialApp.router(
      // ── التوجيه (go_router) ──────────────────────────────────────────────
      routerConfig: router,

      // ── إعدادات عامة ────────────────────────────────────────────────────
      title: 'نظام إدارة المبيعات',
      debugShowCheckedModeBanner: false,

      // ── الثيم (Material 3 + Dynamic Color) ──────────────────────────────
      // يُبنى الثيم ديناميكياً بناءً على اللون المختار في الإعدادات
      theme:     AppTheme.lightWithSeed(seedColor),
      darkTheme: AppTheme.darkWithSeed(seedColor),
      themeMode: themeMode,

      // ── التوطين والترجمة ─────────────────────────────────────────────────
      locale: locale,
      supportedLocales: const [
        Locale('ar'), // العربية — اللغة الافتراضية (RTL)
        Locale('en'), // الإنجليزية (LTR)
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,  // مكونات Material المترجمة
        GlobalWidgetsLocalizations.delegate,   // اتجاه النص RTL/LTR
        GlobalCupertinoLocalizations.delegate, // مكونات iOS style
      ],
    );
  }

  /// تحليل نص لون البذرة إلى Color
  ///
  /// [colorStr] — قيمة Color.value مُخزَّنة كنص في الإعدادات
  /// يُعيد اللون الافتراضي (الأخضر الزمردي) إذا كانت القيمة غير صالحة
  Color _parseSeedColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return AppColors.primarySeed;
    final value = int.tryParse(colorStr);
    if (value == null) return AppColors.primarySeed;
    return Color(value);
  }
}
