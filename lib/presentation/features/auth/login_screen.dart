// ─────────────────────────────────────────────────────────────────────────────
// login_screen.dart — شاشة تسجيل الدخول الفاخرة (Fintech Login Screen)
//
// تعليقات توضيحية بالعربية:
// هذه الشاشة تتيح للمستخدمين تسجيل الدخول بأعلى درجات التناسق والجمالية مع الهوية المرئية (Fintech Theme):
//   - رأس كحلي فاخر مع شعار ذهبي وهيئة احترافية متوازنة
//   - دعم تفاعلي لحالات التحميل والأخطاء والقفل التلقائي
//   - حقول إدخال موحدة بنفس الأنماط والرموز المستعلمة في أرجاء النظام
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/auth_state.dart';
import '../../providers/auth_provider.dart';

/// شاشة تسجيل الدخول الفاخرة
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryLogin() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).login(
          _usernameCtrl.text.trim(),
          _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 768;

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 440 : double.infinity,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. رأس تسجيل الدخول الفاخر ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF18233A),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0BC66).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFE0BC66),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 32,
                          color: Color(0xFFE0BC66),
                        ),
                      ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                      const SizedBox(height: 16),

                      const Text(
                        'نظام إدارة المبيعات والخزينة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 4),

                      Text(
                        'تسجيل الدخول للنظام',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── 2. بطاقة نموذج تسجيل الدخول ───────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // اسم المستخدم
                        TextFormField(
                          controller: _usernameCtrl,
                          textDirection: TextDirection.ltr,
                          enabled: !isLoading,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? AppColors.textDark : AppColors.textLight,
                          ),
                          decoration: InputDecoration(
                            labelText: 'اسم المستخدم',
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
                            hintText: 'admin',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'اسم المستخدم مطلوب';
                            }
                            if (value.trim().length < 3) {
                              return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 16),

                        // كلمة المرور
                        TextFormField(
                          controller: _passwordCtrl,
                          textDirection: TextDirection.ltr,
                          obscureText: _obscurePassword,
                          enabled: !isLoading,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? AppColors.textDark : AppColors.textLight,
                          ),
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            hintText: '••••••••',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'كلمة المرور مطلوبة';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => isLoading ? null : _tryLogin(),
                        ),

                        const SizedBox(height: 20),

                        // رسالة الحالة
                        _buildStatusMessage(authState),

                        const SizedBox(height: 8),

                        // زر تسجيل الدخول
                        ElevatedButton(
                          onPressed: isLoading ? null : _tryLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFFE0BC66) : AppColors.navy,
                            foregroundColor: isDark ? AppColors.navy : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'دخول النظام',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMessage(AuthState authState) {
    if (authState is AuthError) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade400),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                authState.message,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ).animate().shakeX(duration: 400.ms);
    }

    if (authState is AuthLocked) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade400),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_clock_outlined, color: Colors.red.shade400, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'الحساب مقفول موقتاً. حاول بعد ${authState.minutesLeft} دقيقة',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
