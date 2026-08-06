// ─────────────────────────────────────────────────────────────────────────────
// login_screen.dart — شاشة تسجيل الدخول (مكتملة)
//
// تتعامل مع:
//   - التحقق من المدخلات (validation)
//   - استدعاء AuthNotifier.login()
//   - عرض حالات الخطأ والقفل
//   - GoRouter.redirect يُعيد التوجيه لـ /dashboard عند النجاح
//
// حالات المصادقة المعروضة:
//   AuthError  → رسالة خطأ حمراء بالأسفل
//   AuthLocked → رسالة قفل مع عدّاد الوقت المتبقي
//   AuthLoading → زر معطَّل + دوار تحميل
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/auth_state.dart';
import '../../providers/auth_provider.dart';

/// شاشة تسجيل الدخول
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  /// مفتاح الـ Form للتحقق من المدخلات
  final _formKey = GlobalKey<FormState>();

  /// Controllers الحقول
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  /// حالة إخفاء كلمة المرور
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// محاولة تسجيل الدخول
  Future<void> _tryLogin() async {
    // التحقق من صحة المدخلات
    if (!_formKey.currentState!.validate()) return;

    // استدعاء AuthNotifier — الـ GoRouter سيتولى التوجيه عند النجاح
    await ref.read(authNotifierProvider.notifier).login(
          _usernameCtrl.text.trim(),
          _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 768;

    // قراءة حالة المصادقة الحالية
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 420 : double.infinity,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── الأيقونة والعنوان ────────────────────────────────────
                Icon(
                  Icons.account_balance,
                  size: 64,
                  color: theme.colorScheme.primary,
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                const SizedBox(height: 16),

                Text(
                  'نظام إدارة المبيعات',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),

                Text(
                  'تسجيل الدخول',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 40),

                // ── نموذج الدخول ─────────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // حقل اسم المستخدم
                      TextFormField(
                        controller: _usernameCtrl,
                        textDirection: TextDirection.ltr,
                        enabled: !isLoading,
                        decoration: const InputDecoration(
                          labelText: 'اسم المستخدم',
                          prefixIcon: Icon(Icons.person_outline),
                          hintText: 'أدخل اسم المستخدم',
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
                      ).animate().slideX(
                            begin: -0.1,
                            end: 0,
                            delay: 300.ms,
                            duration: 400.ms,
                          ),

                      const SizedBox(height: 16),

                      // حقل كلمة المرور
                      TextFormField(
                        controller: _passwordCtrl,
                        textDirection: TextDirection.ltr,
                        obscureText: _obscurePassword,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          hintText: 'أدخل كلمة المرور',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'كلمة المرور مطلوبة';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => isLoading ? null : _tryLogin(),
                      ).animate().slideX(
                            begin: 0.1,
                            end: 0,
                            delay: 400.ms,
                            duration: 400.ms,
                          ),

                      const SizedBox(height: 24),

                      // ── رسالة الخطأ أو القفل ─────────────────────────
                      _buildStatusMessage(authState, theme),

                      const SizedBox(height: 8),

                      // ── زر الدخول ───────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: isLoading ? null : _tryLogin,
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
                                  'دخول',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بناء رسالة الحالة (خطأ / قفل / فارغة)
  Widget _buildStatusMessage(AuthState authState, ThemeData theme) {
    // ── رسالة الخطأ ─────────────────────────────────────────────────────
    if (authState is AuthError) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                authState.message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ).animate().shakeX(duration: 400.ms);
    }

    // ── رسالة القفل ─────────────────────────────────────────────────────
    if (authState is AuthLocked) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_clock,
              color: theme.colorScheme.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'الحساب مقفول. حاول بعد ${authState.minutesLeft} دقيقة',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // لا رسالة — إخفاء المساحة
    return const SizedBox.shrink();
  }
}
