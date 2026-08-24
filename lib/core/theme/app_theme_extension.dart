// ─────────────────────────────────────────────────────────────────────────────
// app_theme_extension.dart — ألوان المشروع كامتداد ثيم (المرحلة د)
//
// **المشكلة التي يحلّها:**
//   كان المشروع يحوي **١٣٨ شرطاً** من الشكل:
//   ```dart
//   color: isDark ? AppColors.textDark : AppColors.textLight
//   ```
//   موزّعة على ٨ ملفات. ولهذا ثلاثة أثمان:
//     ١. كل ودجت يحتاج `final isDark = Theme.of(context).brightness == ...`
//        قبل أن يلوّن أي شيء
//     ٢. إضافة لون جديد تعني تعديل عشرات المواضع لا موضعاً واحداً
//     ٣. **نسيان أحد الطرفين لا يشتكي منه المحلّل** — يظهر نصّ أسود على
//        خلفية سوداء في الوضع الداكن ولا يُكتشف إلا بالعين
//
// **الحل:** الثيم نفسه يحمل الألوان الصحيحة لوضعه، فيصير:
//   ```dart
//   color: context.colors.text
//   ```
//
// الأزواج التسعة أدناه مستخرَجة **من الاستعمال الفعلي** لا مخترعة — كل واحد
// منها كان يتكرّر في الكود بصيغته الشرطية.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ألوان سند الخاصة — تُقرأ من الثيم فتحمل قيم الوضع الحالي تلقائياً
///
/// تُسجَّل في `AppTheme` عبر `extensions: [AppPalette.light]` أو `.dark`،
/// وتُقرأ في الودجتات عبر `context.colors`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  /// خلفية التطبيق العامة
  final Color bg;

  /// أسطح البطاقات والكروت
  final Color surface;

  /// الأسطح الثانوية والتقسيمات
  final Color surface2;

  /// النص الرئيسي
  final Color text;

  /// النص الفرعي والتلميحات
  final Color subtext;

  /// حدود البطاقات وعناصر الواجهة
  final Color border;

  /// اللون الذهبي المميّز (الأزرار الرئيسية والشارات)
  final Color gold;

  /// لون النصّ فوق الخلفية الذهبية
  ///
  /// ليس مشتقاً من [gold] بل زوج مستقلّ: في الوضع الفاتح الذهب داكن فالنصّ
  /// أبيض، وفي الداكن الذهب فاتح فالنصّ كحلي. اشتقاقه آلياً كان سيُنتج
  /// تبايناً ضعيفاً في أحد الوضعين.
  final Color onGold;

  /// خلفية الشريط الجانبي
  final Color sidebar;

  /// الأحمر التحذيري (العجز · الحذف · الصرف)
  final Color danger;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.text,
    required this.subtext,
    required this.border,
    required this.gold,
    required this.onGold,
    required this.sidebar,
    required this.danger,
  });

  /// لوحة الوضع الفاتح
  static const AppPalette light = AppPalette(
    bg: AppColors.bgLight,
    surface: AppColors.surfaceLight,
    surface2: AppColors.surface2Light,
    text: AppColors.textLight,
    subtext: AppColors.subtextLight,
    border: AppColors.borderLight,
    gold: AppColors.goldLight,
    // الذهب الفاتح داكن نسبياً → نصّ أبيض
    onGold: Colors.white,
    sidebar: AppColors.navySidebarLight,
    danger: AppColors.redLight,
  );

  /// لوحة الوضع الداكن
  static const AppPalette dark = AppPalette(
    bg: AppColors.bgDark,
    surface: AppColors.surfaceDark,
    surface2: AppColors.surface2Dark,
    text: AppColors.textDark,
    subtext: AppColors.subtextDark,
    border: AppColors.borderDark,
    gold: AppColors.goldDark,
    // الذهب الداكن ساطع → نصّ كحلي
    onGold: AppColors.navy,
    sidebar: AppColors.navySidebarDark,
    danger: AppColors.redDark,
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? text,
    Color? subtext,
    Color? border,
    Color? gold,
    Color? onGold,
    Color? sidebar,
    Color? danger,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      text: text ?? this.text,
      subtext: subtext ?? this.subtext,
      border: border ?? this.border,
      gold: gold ?? this.gold,
      onGold: onGold ?? this.onGold,
      sidebar: sidebar ?? this.sidebar,
      danger: danger ?? this.danger,
    );
  }

  /// المزج عند الانتقال بين الوضعين — يجعل تبديل الثيم متدرّجاً لا قافزاً
  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      text: Color.lerp(text, other.text, t)!,
      subtext: Color.lerp(subtext, other.subtext, t)!,
      border: Color.lerp(border, other.border, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

/// اختصار قراءة اللوحة من السياق
///
/// ```dart
/// color: context.colors.text        // بدل isDark ? textDark : textLight
/// ```
extension AppPaletteX on BuildContext {
  /// ألوان سند للوضع الحالي
  ///
  /// تتراجع إلى لوحة الوضع الفاتح إن لم تُسجَّل — فلا تُسقط الشاشة بـ `!`
  /// في اختبار ودجت يبني `MaterialApp` بثيم افتراضي.
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
