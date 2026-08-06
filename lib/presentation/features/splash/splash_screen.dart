// ─────────────────────────────────────────────────────────────────────────────
// splash_screen.dart — شاشة البداية
//
// تظهر هذه الشاشة عند كل تشغيل للتطبيق.
// تعمل بالتوازي مع تهيئة AuthNotifier:
//   - تعرض الأنيميشن (2 ثانية على الأقل)
//   - تنتظر حالة المصادقة (AuthNotifier.build())
//   - ثم تُعيد التوجيه للمسار الصحيح
//
// آلية التوجيه:
//   GoRouter.redirect() يتحكم بالتوجيه الفعلي بناءً على AuthState
//   الـ Splash فقط تُطلق التوجيه — القرار عند الـ Router
//
// لذلك: بعد انتهاء الانتظار، نتوجه لـ /dashboard
//   إذا كان المستخدم غير مصادَق → GoRouter يُعيد التوجيه لـ /login أو /first-run
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../domain/models/auth_state.dart';
import '../../providers/auth_provider.dart';

/// شاشة البداية (Splash Screen)
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// هل انتهى الانتظار الأدنى (لعرض الأنيميشن كاملاً)؟
  bool _minDelayDone = false;

  /// هل تهيئة المصادقة جاهزة؟
  bool _authReady = false;

  @override
  void initState() {
    super.initState();
    // بدء الانتظار الأدنى (2 ثانية لعرض الأنيميشن)
    _startMinDelay();
    // مراقبة حالة المصادقة — سيُستدعى من ref.listen في build()
  }

  /// انتظار 2 ثانية كحد أدنى لعرض الأنيميشن كاملاً
  Future<void> _startMinDelay() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    _minDelayDone = true;
    _tryNavigate();
  }

  /// محاولة التوجيه — تُنجَّح فقط عندما يكون الشرطان محققَّين:
  ///   1. انتهى الانتظار الأدنى
  ///   2. تهيئة المصادقة جاهزة
  void _tryNavigate() {
    if (!_minDelayDone || !_authReady) return;
    if (!mounted) return;

    // نتوجه لـ /dashboard — GoRouter.redirect سيُقرر المسار الفعلي
    // بناءً على AuthState الحالية:
    //   AuthAuthenticated → /dashboard (مسموح)
    //   AuthUnauthenticated(isFirstRun: true) → /first-run
    //   AuthUnauthenticated() → /login
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // مراقبة حالة المصادقة
    ref.listen<AuthState>(authNotifierProvider, (previous, current) {
      // الحالة جاهزة عندما تخرج من Initial/Loading
      if (current is! AuthInitial && current is! AuthLoading) {
        _authReady = true;
        _tryNavigate();
      }
    });

    // التحقق الأولي — قد تكون الحالة جاهزة بالفعل
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthInitial && authState is! AuthLoading) {
      _authReady = true;
    }

    return Scaffold(
      // خلفية بلون primaryContainer — يُعطي طابع التطبيق
      backgroundColor: theme.colorScheme.primaryContainer,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── أيقونة التطبيق ────────────────────────────────────────────
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.account_balance,
                size: 52,
                color: theme.colorScheme.onPrimary,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 32),

            // ── اسم التطبيق ───────────────────────────────────────────────
            Text(
              'نظام إدارة المبيعات',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            )
                .animate()
                .slideY(
                  begin: 0.3,
                  end: 0,
                  delay: 300.ms,
                  duration: 500.ms,
                  curve: Curves.easeOut,
                )
                .fadeIn(delay: 300.ms, duration: 500.ms),

            const SizedBox(height: 8),

            Text(
              'إدارة حسابات ذكية وسريعة',
              style: theme.textTheme.bodyLarge?.copyWith(
                color:
                    theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 500.ms),

            const SizedBox(height: 60),

            // ── مؤشر التحميل ─────────────────────────────────────────────
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color:
                    theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
              ),
            ).animate().fadeIn(delay: 800.ms, duration: 400.ms),

            const SizedBox(height: 16),

            // ── نص التحميل ────────────────────────────────────────────────
            Text(
              'جاري التحميل...',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
              ),
            ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
