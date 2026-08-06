// ─────────────────────────────────────────────────────────────────────────────
// app_text_styles.dart — أنماط النصوص
//
// يحدد هذا الملف أنماط النصوص المخصصة للتطبيق.
// - اللغة العربية: خط Tajawal
// - اللغة الإنجليزية والأرقام: خط Inter
//
// كيفية الاستخدام:
//   Theme.of(context).textTheme.titleLarge — للعناوين
//   AppTextStyles.arabicTitle — لنصوص محددة بدون Theme
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// اسم خط العربية المعرّف للواجهات والتصميم المالي الفاخر
const String _kArabicFont = 'Cairo';

/// اسم خط اللاتينية/الأرقام المُعرَّف في pubspec.yaml
const String _kLatinFont = 'Cairo';

/// أنماط نصوص مخصصة للتطبيق
abstract final class AppTextStyles {
  // ── عناوين عربية ──────────────────────────────────────────────────────────

  /// عنوان رئيسي كبير — مثل: اسم الشاشة في الـ AppBar
  static const TextStyle arabicHeadline = TextStyle(
    fontFamily: _kArabicFont,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 1.4, // ارتفاع السطر مناسب للعربية
  );

  /// عنوان متوسط — مثل: عنوان قسم في الصفحة
  static const TextStyle arabicTitle = TextStyle(
    fontFamily: _kArabicFont,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 1.4,
  );

  /// نص عادي — للمحتوى والتفاصيل
  static const TextStyle arabicBody = TextStyle(
    fontFamily: _kArabicFont,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.6, // ارتفاع سطر أكبر للقراءة المريحة
  );

  /// نص صغير — للملاحظات والـ Labels
  static const TextStyle arabicCaption = TextStyle(
    fontFamily: _kArabicFont,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.5,
  );

  /// نص الأزرار العربية
  static const TextStyle arabicButton = TextStyle(
    fontFamily: _kArabicFont,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    letterSpacing: 0.2,
  );

  // ── أرقام وتنسيق المال ────────────────────────────────────────────────────

  /// الأرقام الكبيرة — مثل: رصيد الخزينة في الـ Dashboard
  static const TextStyle largeAmount = TextStyle(
    fontFamily: _kLatinFont,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    letterSpacing: -0.5,
  );

  /// أرقام متوسطة — مثل: مبلغ السند
  static const TextStyle mediumAmount = TextStyle(
    fontFamily: _kLatinFont,
    fontWeight: FontWeight.w600,
    fontSize: 18,
  );

  /// أرقام صغيرة — للجداول والقوائم
  static const TextStyle smallAmount = TextStyle(
    fontFamily: _kLatinFont,
    fontWeight: FontWeight.w500,
    fontSize: 14,
  );

  /// رقم المستند / الكود
  static const TextStyle documentNumber = TextStyle(
    fontFamily: _kLatinFont,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    letterSpacing: 0.5,
  );
}

/// إنشاء TextTheme كاملة بخط Tajawal للاستخدام مع ThemeData
///
/// يُستخدم في: AppTheme.buildTheme()
TextTheme buildArabicTextTheme(TextTheme base) {
  // نستبدل خط الـ Theme الأساسي بخط Tajawal مع الحفاظ على الأحجام الأصلية
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(
      fontFamily: _kArabicFont,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    displayMedium: base.displayMedium?.copyWith(
      fontFamily: _kArabicFont,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    displaySmall: base.displaySmall?.copyWith(
      fontFamily: _kArabicFont,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    headlineLarge: base.headlineLarge?.copyWith(
      fontFamily: _kArabicFont,
      fontWeight: FontWeight.w700,
      height: 1.4,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontFamily: _kArabicFont,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontFamily: _kArabicFont,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontFamily: _kArabicFont,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontFamily: _kArabicFont,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontFamily: _kArabicFont,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontFamily: _kArabicFont,
      fontWeight: FontWeight.w400,
      height: 1.6,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontFamily: _kArabicFont,
      fontWeight: FontWeight.w400,
      height: 1.6,
    ),
    bodySmall: base.bodySmall?.copyWith(
      fontFamily: _kArabicFont,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontFamily: _kArabicFont,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontFamily: _kArabicFont,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: base.labelSmall?.copyWith(
      fontFamily: _kArabicFont,
      fontWeight: FontWeight.w400,
    ),
  );
}
