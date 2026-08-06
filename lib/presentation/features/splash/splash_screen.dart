// ─────────────────────────────────────────────────────────────────────────────
// splash_screen.dart — شاشة البداية والتحميل (Fintech Splash Screen)
//
// تعليقات توضيحية بالعربية:
// هذه الشاشة تظهر عند تشغيل التطبيق بأعلى درجات التناسق والجمالية مع الهوية المرئية (Fintech Theme):
//   - خلفية تدرج كحلي دافئ عميق (Deep Midnight Navy Gradient)
//   - شعار التطبيق مؤطر باللون الذهبي المشرق مع هالة ضوئية
//   - خط القاهرة العربي الفاخر مع مؤشر التحميل الذهبي المنساب
//   - تضمن الانتظار الأدنى 2 ثانية لعرض المؤثرات الحركية، ثم التوجيه للمسار المناسب
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../domain/models/auth_state.dart';
import '../../providers/auth_provider.dart';

/// شاشة البداية للـ Fintech Theme
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// هل انتهى الانتظار الأدنى (2 ثانية لعرض الأنيميشن)؟
  bool _minDelayDone = false;

  /// منع تكرار التوجيه
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startMinDelay();
  }

  /// انتظار 2000ms كحد أدنى لعرض المؤثرات الحركية
  Future<void> _startMinDelay() async {
    await Future<void>.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    _minDelayDone = true;
    _checkAndNavigate();
  }

  /// محاولة التوجيه تلقائياً بطريقة آمنة خارج إطار الـ Build
  void _checkAndNavigate() {
    if (!_minDelayDone || _hasNavigated || !mounted) return;

    final authState = ref.read(authNotifierProvider);
    if (authState is AuthInitial || authState is AuthLoading) return;

    _hasNavigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go(AppRoutes.dashboard);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // مراقبة حالة المصادقة عند التغيير
    ref.listen<AuthState>(authNotifierProvider, (previous, current) {
      if (current is! AuthInitial && current is! AuthLoading) {
        _checkAndNavigate();
      }
    });

    // محاولة التوجيه الآمنة في حال كانت الحالة جاهزة مسبقاً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate();
    });

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. خلفية التدرج الكحلي الداكن العميق ─────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B1220),
                  Color(0xFF0F172A),
                  Color(0xFF18233A),
                ],
              ),
            ),
          ),

          // ── 2. الهالة الضوئية الذهبية خلف الشعار ────────────────────────────
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE0BC66).withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── 3. المحتوى الرئيسي والشعار والأنيميشن ────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // الشعار الفاخر المؤطر بالذهب
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF18233A),
                        Color(0xFF131B2C),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFE0BC66),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE0BC66).withValues(alpha: 0.25),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 54,
                      color: Color(0xFFE0BC66),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 36),

                // اسم التطبيق بالخط العربي الفاخر
                const Text(
                  'نظام لإدارة المبيعات والخزينة',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    letterSpacing: -0.3,
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

                // الوصف الإضافي الذهبي
                const Text(
                  'نظام مالي وإداري ذكي ومُتقَن · Sanad App',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE0BC66),
                    fontFamily: 'Cairo',
                  ),
                ).animate().fadeIn(delay: 550.ms, duration: 500.ms),

                const SizedBox(height: 64),

                // مؤشر التحميل الذهبي
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    color: Color(0xFFE0BC66),
                  ),
                ).animate().fadeIn(delay: 750.ms, duration: 400.ms),

                const SizedBox(height: 16),

                // نص التهيئة
                Text(
                  'جاري تهيئة النظام السريع...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontFamily: 'Cairo',
                  ),
                ).animate().fadeIn(delay: 850.ms, duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
