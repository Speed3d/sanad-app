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
import 'app_theme_extension.dart';
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
    0xFF0F172A: 'أزرق ملكي فاخر (Fintech)', // الافتراضي الحديث
    0xFF1E3A8A: 'أزرق ساطع',
    0xFF064E3B: 'زمردي تايتانيوم',
    0xFF312E81: 'نيلي ملوكي',
    0xFF880E4F: 'خمري ملكي',
    0xFF1B5E20: 'أخضر كلاسيكي',
  };

  // ── بناء الثيم ─────────────────────────────────────────────────────────────

  /// دالة بناء الثيم الداخلية المخصصة للنظام اللوني الفاخر
  /// [brightness] — نوع الثيم: فاتح أو داكن
  /// [seedColor]  — لون البذرة الأساسي
  static ThemeData _buildTheme(Brightness brightness, Color seedColor) {
    final isDark = brightness == Brightness.dark;

    // ⚠️ ع-٦٧ (بلاغ المالك 2026-10-15): `primary` كان **الكحلي في الوضعين**،
    //   وخلفية الوضع الداكن كحليّة أيضاً — فكلّ ما يأخذ لونه من `primary`
    //   صار كحلياً على كحلي: `FilledButton` (١٥٣ موضعاً) و`OutlinedButton`
    //   و`TextButton` وأيقونات العناوين ونصوصها في الإعدادات والسنوات
    //   المالية والرواتب. لا يُصلَح زرّاً زرّاً — المصدر واحد، فالإصلاح هنا.
    //   في الداكن: `primary` ذهبيّ و`onPrimary` كحلي — كـ`ElevatedButton`
    //   تماماً. والفاتح **لم يُمَسّ** (المالك: «في النهاري كل شيء جيد»).
    //   يحرسه `dark_contrast_guard_test`.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      primary: isDark ? AppColors.goldDark : AppColors.navy,
      onPrimary: isDark ? AppColors.navy : null,
      secondary: isDark ? AppColors.goldDark : AppColors.goldLight,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      error: isDark ? AppColors.redDark : AppColors.redLight,
      outline: isDark ? AppColors.borderDark : AppColors.borderLight,
      outlineVariant: isDark ? AppColors.borderDark : AppColors.borderLight,
    );

    // الثيم الأساسي من ColorScheme
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      // ── ألوان سند كامتداد ثيم (المرحلة د) ──────────────────────────
      // تُقرأ في الودجتات عبر `context.colors` بدل ١٣٨ شرط
      // `isDark ? xDark : xLight` كانت موزّعة على ٨ ملفات.
      extensions: [
        brightness == Brightness.dark ? AppPalette.dark : AppPalette.light,
      ],
    );

    // تطبيق الخط العربي (Cairo) على TextTheme الأساسية
    final arabicTextTheme = buildArabicTextTheme(base.textTheme);

    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderCol = isDark ? AppColors.borderDark : AppColors.borderLight;
    final scaffoldBg = isDark ? AppColors.bgDark : AppColors.bgLight;

    return base.copyWith(
      textTheme: arabicTextTheme,
      scaffoldBackgroundColor: scaffoldBg,

      // ── AppBar ───────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: cardBg,
        foregroundColor: isDark ? AppColors.textDark : AppColors.textLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: arabicTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        iconTheme: IconThemeData(color: isDark ? AppColors.subtextDark : AppColors.subtextLight),
        scrolledUnderElevation: 1,
        shadowColor: colorScheme.shadow,
      ),

      // ── NavigationRail (الشريط الجانبي) ───────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? AppColors.navySidebarDark : AppColors.navySidebarLight,
        selectedIconTheme: const IconThemeData(color: Color(0xFFF5D98B)),
        unselectedIconTheme: const IconThemeData(color: Colors.white70),
        selectedLabelTextStyle: arabicTextTheme.labelMedium?.copyWith(
          color: const Color(0xFFF5D98B),
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: arabicTextTheme.labelMedium?.copyWith(
          color: Colors.white70,
        ),
        useIndicator: true,
        indicatorColor: Colors.white.withValues(alpha: 0.12),
      ),

      // ── ElevatedButton ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.goldDark : AppColors.goldLight,
          foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          minimumSize: const Size(120, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: arabicTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── FloatingActionButton ───────────────────────────────────────────────
      // لماذا ليس CircleBorder (بلاغ المالك 2026-10-15): كل أزرار الإضافة في
      // البرنامج من نوع `FloatingActionButton.extended` (أيقونة + نصّ)، والشكل
      // الدائري يُفرَض على زرٍّ عريض فيصير قرصاً بيضاوياً لا يشبه أيّ زرّ آخر
      // في التطبيق. فالشكل هنا هو نفسه شكل `ElevatedButton` أعلاه — مستطيلٌ
      // بزوايا ١٢ — والظلّ أخفّ ليجلس الزرّ مع البطاقات لا فوقها.
      // المصدر واحد: الثيم. لا تُمرَّر `shape` في الشاشات — يحرسه
      // `fab_shape_guard_test`.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? AppColors.goldDark : AppColors.goldLight,
        foregroundColor: const Color(0xFF1A1204),
        elevation: 2,
        focusElevation: 3,
        hoverElevation: 3,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
        extendedTextStyle: arabicTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),

      // ── Card ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: borderCol,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        clipBehavior: Clip.antiAlias,
      ),

      // ── InputDecoration (حقول الإدخال) ────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderCol),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderCol),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.goldDark : AppColors.goldLight,
            width: 2,
          ),
        ),
      ),

      // ── Dialog ─────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── SnackBar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
