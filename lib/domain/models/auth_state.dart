// ─────────────────────────────────────────────────────────────────────────────
// auth_state.dart — حالة المصادقة (Sealed Class — Dart 3)
//
// يُمثّل هذا الملف جميع حالات المصادقة الممكنة في التطبيق.
// نستخدم Sealed Class من Dart 3 بدلاً من Freezed لتجنب Code Generation
// إضافي — Pattern Matching مدعوم مباشرةً في Dart 3.
//
// دورة حياة الحالة:
//   AuthInitial  → (بدء التطبيق)
//   AuthLoading  → (تحقق من الجلسة المحفوظة)
//   AuthAuthenticated | AuthUnauthenticated | AuthLocked | AuthError
//
// الاستخدام في الواجهة:
//   switch (authState) {
//     case AuthAuthenticated(:final user) => عرض البيانات
//     case AuthUnauthenticated()          => شاشة الدخول
//     case AuthLocked(:final lockedUntil) => رسالة القفل
//     ...
//   }
// ─────────────────────────────────────────────────────────────────────────────

import 'user_model.dart';

/// الحالة الأساسية — جميع الحالات ترثها
sealed class AuthState {
  const AuthState();
}

/// الحالة الأولية عند بدء التطبيق — قبل أي عملية تحقق
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// جاري التحقق من الجلسة المحفوظة أو تسجيل الدخول
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// مستخدم مصادَق وجاهز — يُعطي الوصول للشاشات المحمية
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});

  /// بيانات المستخدم المسجَّل
  final UserModel user;
}

/// غير مصادَق — يُحوَّل لشاشة الدخول
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({
    // true إذا كانت أول تشغيل للتطبيق — يُحوَّل لشاشة الإعداد الأول
    this.isFirstRun = false,
  });

  final bool isFirstRun;
}

/// الحساب مقفول بسبب محاولات دخول فاشلة متكررة
final class AuthLocked extends AuthState {
  const AuthLocked({required this.lockedUntil});

  /// الوقت الذي ترتفع فيه القفلة
  final DateTime lockedUntil;

  /// الدقائق المتبقية قبل رفع القفل (يُعاد حسابه عند الوصول)
  int get minutesLeft {
    final remaining = lockedUntil.difference(DateTime.now()).inMinutes + 1;
    return remaining < 0 ? 0 : remaining;
  }
}

/// خطأ في عملية المصادقة
final class AuthError extends AuthState {
  const AuthError({required this.message});

  /// رسالة الخطأ بالعربية
  final String message;
}
