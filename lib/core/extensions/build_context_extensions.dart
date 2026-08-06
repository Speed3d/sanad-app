// ─────────────────────────────────────────────────────────────────────────────
// build_context_extensions.dart — امتدادات BuildContext المساعدة
//
// هذا الملف يُضيف دوالاً مساعدة على BuildContext لتقليل الكود المكرر
// في الشاشات والويدجتس.
//
// الغرض:
//   بدلاً من كتابة Theme.of(context).colorScheme في كل مكان،
//   يمكن كتابة context.colorScheme مباشرة.
//
// كيفية الاستخدام:
//   // الثيم
//   context.theme          → ThemeData
//   context.colorScheme    → ColorScheme
//   context.textTheme      → TextTheme
//
//   // معلومات الشاشة
//   context.screenWidth    → double
//   context.screenHeight   → double
//   context.isTablet       → bool (عرض >= 768px)
//   context.isDesktop      → bool (عرض >= 1200px)
//   context.isRtl          → bool (هل الاتجاه من اليمين لليسار؟)
//
//   // الإشعارات السريعة
//   context.showSuccess('تم الحفظ بنجاح')
//   context.showError('حدث خطأ')
//   context.showInfo('يرجى الانتظار')
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// امتدادات BuildContext — اختصارات للثيم والشاشة والإشعارات
extension BuildContextExtensions on BuildContext {
  // ── اختصارات الثيم ───────────────────────────────────────────────────────

  /// الثيم الكامل للتطبيق
  ThemeData get theme => Theme.of(this);

  /// لوحة الألوان (Material 3 ColorScheme)
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// أنماط النصوص (TextTheme)
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// هل التطبيق في وضع الظلام؟
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ── معلومات الشاشة ────────────────────────────────────────────────────────

  /// عرض الشاشة بالبكسل المنطقي
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// ارتفاع الشاشة بالبكسل المنطقي
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// هل الشاشة في وضع تابلت أو ويب؟ (عرض >= 768 بكسل)
  /// يُستخدم لتحديد نوع شريط التنقل (NavigationRail vs NavigationBar)
  bool get isTablet => MediaQuery.sizeOf(this).width >= 768;

  /// هل الشاشة في وضع سطح المكتب؟ (عرض >= 1200 بكسل)
  bool get isDesktop => MediaQuery.sizeOf(this).width >= 1200;

  /// هل الشاشة في وضع الهاتف؟ (عرض < 768 بكسل)
  bool get isMobile => MediaQuery.sizeOf(this).width < 768;

  // ── اتجاه النص ────────────────────────────────────────────────────────────

  /// هل اتجاه النص من اليمين لليسار؟ (العربية = true)
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// اتجاه النص الحالي
  TextDirection get textDirection => Directionality.of(this);

  // ── الحشوة والهامش الآمن ─────────────────────────────────────────────────

  /// المناطق الآمنة (Notch، شريط الحالة، شريط التنقل)
  EdgeInsets get safeAreaPadding => MediaQuery.paddingOf(this);

  /// ارتفاع شريط الحالة (Status Bar)
  double get statusBarHeight => MediaQuery.paddingOf(this).top;

  // ── دوال الإشعارات السريعة (SnackBar) ────────────────────────────────────

  /// عرض رسالة نجاح باللون الأخضر
  ///
  /// [message] — النص العربي الذي يظهر للمستخدم
  /// [duration] — مدة الظهور (افتراضي: 3 ثوانٍ)
  void showSuccess(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.green.shade700,
      icon: Icons.check_circle_outline_rounded,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// عرض رسالة خطأ باللون الأحمر
  ///
  /// [message] — النص العربي الذي يظهر للمستخدم
  /// [duration] — مدة الظهور (افتراضي: 4 ثوانٍ)
  void showError(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.red.shade700,
      icon: Icons.error_outline_rounded,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// عرض رسالة معلوماتية باللون الأزرق
  ///
  /// [message] — النص العربي الذي يظهر للمستخدم
  /// [duration] — مدة الظهور (افتراضي: 3 ثوانٍ)
  void showInfo(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.blue.shade700,
      icon: Icons.info_outline_rounded,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// عرض رسالة تحذير باللون البرتقالي
  ///
  /// [message] — النص العربي الذي يظهر للمستخدم
  void showWarning(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.orange.shade700,
      icon: Icons.warning_amber_rounded,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  // ── الدالة الداخلية للـ SnackBar ─────────────────────────────────────────

  /// عرض SnackBar مخصص — تُستدعى داخلياً فقط
  ///
  /// [message]         — نص الرسالة
  /// [backgroundColor] — لون الخلفية
  /// [icon]            — أيقونة الرسالة
  /// [duration]        — مدة الظهور
  void _showSnackBar({
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    // إخفاء أي SnackBar حالي أولاً لتجنب التراكم
    ScaffoldMessenger.of(this).clearSnackBars();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        // محتوى الرسالة مع الأيقونة
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Tajawal', // خط عربي للوضوح
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating, // يطفو فوق المحتوى
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        elevation: 6,
      ),
    );
  }

  // ── مساعدات Dialog ────────────────────────────────────────────────────────

  /// عرض نافذة تأكيد بسيطة (نعم / لا)
  ///
  /// [title]   — عنوان النافذة
  /// [message] — محتوى الرسالة
  /// [confirmText] — نص زر التأكيد (افتراضي: "تأكيد")
  /// [cancelText]  — نص زر الإلغاء (افتراضي: "إلغاء")
  ///
  /// يُعيد: true عند الضغط على "تأكيد"، false عند الإلغاء
  Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    bool isDestructive = false, // هل الإجراء خطير (حذف)؟
  }) async {
    final result = await showDialog<bool>(
      context: this,
      barrierDismissible: false, // لا يُغلق بالضغط خارج النافذة
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          // زر الإلغاء دائماً على اليسار
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          // زر التأكيد — أحمر إذا كان الإجراء خطيراً
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: isDestructive
                ? ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
