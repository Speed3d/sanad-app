// ─────────────────────────────────────────────────────────────────────────────
// app_theme.dart — ثيم التطبيق الرئيسي
//
// يوفر هذا الملف:
//   - ثيم فاتح (Light) بألوان Material 3
//   - ثيم داكن (Dark) بنفس الألوان لكن معكوسة
//
// الألوان الأساسية:
//   - Seed اللون: أخضر زمردي داكن (مناسب للمال والمحاسبة)
//
// الاستخدام في MaterialApp:
//   theme: AppTheme.light,
//   darkTheme: AppTheme.dark,
//   themeMode: ThemeMode.system, // أو Light/Dark حسب إعداد المستخدم
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// الثيم الرئيسي للتطبيق — Light و Dark
abstract final class AppTheme {
  // ── الثيم الفاتح ───────────────────────────────────────────────────────────

  /// الثيم الفاتح — باللون الأساسي الثابت (للاستخدام قبل تحميل الإعدادات)
  static ThemeData get light => _buildTheme(Brightness.light, AppColors.primarySeed);

  /// الثيم الفاتح بلون بذرة مخصص — يُستخدم مع الإعدادات الديناميكية
  static ThemeData lightWithSeed(Color seed) => _buildTheme(Brightness.light, seed);

  // ── الثيم الداكن ───────────────────────────────────────────────────────────

  /// الثيم الداكن — باللون الأساسي الثابت
  static ThemeData get dark => _buildTheme(Brightness.dark, AppColors.primarySeed);

  /// الثيم الداكن بلون بذرة مخصص — يُستخدم مع الإعدادات الديناميكية
  static ThemeData darkWithSeed(Color seed) => _buildTheme(Brightness.dark, seed);

  // ── ألوان البذور المتاحة للمستخدم ─────────────────────────────────────────

  /// قائمة ألوان البذور القابلة للاختيار في شاشة المظهر
  ///
  /// المفتاح: Color.value (int) — يُخزَّن في الإعدادات كنص
  /// القيمة: اسم اللون بالعربية
  static const Map<int, String> availableSeedColors = {
    0xFF1B5E20: 'أخضر زمردي',   // الافتراضي — مناسب للمحاسبة
    0xFF1A237E: 'نيلي داكن',
    0xFF01579B: 'أزرق ملكي',
    0xFF880E4F: 'خمري',
    0xFF4A148C: 'بنفسجي',
    0xFFBF360C: 'برتقالي داكن',
    0xFF37474F: 'رمادي أزرق',
    0xFF3E2723: 'بني داكن',
  };

  // ── بناء الثيم ─────────────────────────────────────────────────────────────

  /// دالة بناء الثيم الداخلية
  /// [brightness] — نوع الثيم: فاتح أو داكن
  /// [seedColor]  — لون البذرة الذي يُولِّد Tonal Palette كاملة تلقائياً
  static ThemeData _buildTheme(Brightness brightness, Color seedColor) {
    // إنشاء ColorScheme من اللون الأساسي تلقائياً (Material 3 Tonal Palette)
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    // الثيم الأساسي من ColorScheme
    final base = ThemeData(
      useMaterial3: true, // تفعيل Material 3 (مطلوب)
      colorScheme: colorScheme,
      brightness: brightness,
    );

    // تطبيق الخط العربي على TextTheme الأساسية
    final arabicTextTheme = buildArabicTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: arabicTextTheme,

      // ── AppBar ───────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false, // في RTL التوسيط غير مناسب
        titleTextStyle: arabicTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
        scrolledUnderElevation: 2,
        shadowColor: colorScheme.shadow,
      ),

      // ── NavigationRail (الشريط الجانبي للويب) ────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: arabicTextTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: arabicTextTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        elevation: 1,
        useIndicator: true,
        indicatorColor: colorScheme.primaryContainer,
      ),

      // ── NavigationBar (شريط التنقل السفلي للموبايل) ──────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.onPrimaryContainer);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final style = arabicTextTheme.labelSmall;
          if (states.contains(WidgetState.selected)) {
            return style?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            );
          }
          return style?.copyWith(color: colorScheme.onSurfaceVariant);
        }),
        elevation: 2,
      ),

      // ── ElevatedButton ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(120, 48), // حجم مناسب للضغط باللمس
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          textStyle: arabicTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(120, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: arabicTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: arabicTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── InputDecoration (حقول الإدخال) ────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha:0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha:0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: arabicTextTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: arabicTextTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha:0.7),
        ),
        errorStyle: arabicTextTheme.bodySmall?.copyWith(
          color: colorScheme.error,
        ),
        floatingLabelStyle: arabicTextTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),

      // ── Card ───────────────────────────────────────────────────────────────
      // Flutter 3.x: CardTheme أصبح CardThemeData
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Dialog ─────────────────────────────────────────────────────────────
      // Flutter 3.x: DialogTheme أصبح DialogThemeData
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: arabicTextTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: arabicTextTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // ── SnackBar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentTextStyle: arabicTextTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ── ListTile ───────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        titleTextStyle: arabicTextTheme.bodyLarge,
        subtitleTextStyle: arabicTextTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        labelStyle: arabicTextTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // ── FloatingActionButton ───────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── ProgressIndicator ─────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primaryContainer,
        circularTrackColor: colorScheme.primaryContainer,
      ),

      // ── Scaffold ───────────────────────────────────────────────────────────
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }
}
