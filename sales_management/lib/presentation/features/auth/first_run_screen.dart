// ─────────────────────────────────────────────────────────────────────────────
// first_run_screen.dart — شاشة الإعداد الأول (مكتملة)
//
// تظهر مرة واحدة فقط عند أول تشغيل للتطبيق.
// 3 خطوات:
//   1. بيانات الشركة (اسم + سعر الصرف الابتدائي)
//   2. حساب مدير النظام (Super Admin) — يُشفَّر بـ bcrypt
//   3. مراجعة وتأكيد — حفظ كل شيء في قاعدة البيانات
//
// عند الإنهاء:
//   - تُحفَظ 'first_run_complete' = 'true' في AppSettings
//   - يُنشَأ حساب مدير النظام في جدول Users
//   - يُنشَأ سجل في سعر الصرف (إذا أُدخِل)
//   - يُستدعى AuthNotifier.reinitialize() → AuthAuthenticated
//   - GoRouter يُعيد التوجيه لـ /dashboard تلقائياً
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/repository_providers.dart';

/// شاشة الإعداد الأول
class FirstRunScreen extends ConsumerStatefulWidget {
  const FirstRunScreen({super.key});

  @override
  ConsumerState<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends ConsumerState<FirstRunScreen> {
  /// الخطوة الحالية في الـ Stepper (0, 1, 2)
  int _currentStep = 0;

  /// مفاتيح الـ Form لكل خطوة
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  /// Controllers الخطوة 1: بيانات الشركة
  final _companyNameCtrl = TextEditingController();
  final _exchangeRateCtrl = TextEditingController(text: '1310');

  /// Controllers الخطوة 2: حساب المدير
  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  /// حالة الشاشة
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _exchangeRateCtrl.dispose();
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // ── التنقل بين الخطوات ────────────────────────────────────────────────────

  /// الانتقال للخطوة التالية مع التحقق من المدخلات
  void _onStepContinue() {
    setState(() => _errorMessage = null);

    if (_currentStep == 0) {
      // التحقق من بيانات الشركة
      if (_step1Key.currentState?.validate() != true) return;
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      // التحقق من بيانات المدير
      if (_step2Key.currentState?.validate() != true) return;
      setState(() => _currentStep = 2);
    } else {
      // الخطوة الأخيرة — إنهاء الإعداد
      _finish();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  // ── إنهاء الإعداد ─────────────────────────────────────────────────────────

  /// حفظ جميع البيانات في قاعدة البيانات وإنهاء الإعداد
  Future<void> _finish() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(authServiceProvider);
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final db = ref.read(appDatabaseProvider);

      // ── 1. حفظ إعدادات الشركة ─────────────────────────────────────────
      await settingsRepo.setCompanyName(_companyNameCtrl.text.trim());

      // حفظ سعر الصرف إذا أُدخِل
      final rateText = _exchangeRateCtrl.text.trim();
      final rate = double.tryParse(rateText);
      if (rate != null && rate > 0) {
        await settingsRepo.setExchangeRate(rate);
        // حفظ في جدول ExchangeRates أيضاً للسجل التاريخي
        await db.exchangeRatesDao.setUsdToIqdRate(rate);
      }

      // ── 2. تشفير كلمة المرور بـ bcrypt ───────────────────────────────
      final passwordHash = await service.hashPassword(
        _passwordCtrl.text,
      );

      // ── 3. إنشاء حساب مدير النظام ────────────────────────────────────
      final userId = await userRepo.createUser(
        username: _usernameCtrl.text.trim().toLowerCase(),
        passwordHash: passwordHash,
        fullName: _fullNameCtrl.text.trim(),
        role: 'super_admin',
      );

      // ── 4. تعليم الإعداد الأول كمكتمل ────────────────────────────────
      await settingsRepo.markFirstRunComplete();

      // ── 5. تسجيل الدخول تلقائياً ─────────────────────────────────────
      // حفظ الجلسة في التخزين الآمن مباشرةً
      await service.saveSession(
        userId: userId,
        username: _usernameCtrl.text.trim().toLowerCase(),
      );

      // إعادة تهيئة المصادقة — GoRouter سيُعيد التوجيه لـ /dashboard
      await ref.read(authNotifierProvider.notifier).reinitialize();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'فشل إعداد التطبيق: ${e.toString()}';
      });
    }
    // ملاحظة: لا نُعيد isLoading = false عند النجاح
    // لأن التطبيق سيُعيد التوجيه لـ /dashboard تلقائياً
  }

  // ── بناء الواجهة ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // ── الترحيب ──────────────────────────────────────────────
                Icon(
                  Icons.waving_hand_rounded,
                  size: 56,
                  color: theme.colorScheme.primary,
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                const SizedBox(height: 16),

                Text(
                  'مرحباً بك!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),

                Text(
                  'سنقوم بإعداد النظام خطوة بخطوة',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 32),

                // ── رسالة خطأ إن وجدت ────────────────────────────────────
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),

                // ── Stepper ───────────────────────────────────────────────
                Stepper(
                  currentStep: _currentStep,
                  onStepTapped: (step) {
                    // السماح بالرجوع للخطوات السابقة فقط
                    if (step < _currentStep) setState(() => _currentStep = step);
                  },
                  onStepContinue: _isLoading ? null : _onStepContinue,
                  onStepCancel: _isLoading ? null : _onStepCancel,
                  controlsBuilder: (context, details) => Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        FilledButton(
                          onPressed: _isLoading ? null : details.onStepContinue,
                          child: _isLoading && _currentStep == 2
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _currentStep == 2 ? 'إنهاء الإعداد' : 'التالي',
                                ),
                        ),
                        if (_currentStep > 0) ...[
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: _isLoading ? null : details.onStepCancel,
                            child: const Text('السابق'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  steps: [
                    _buildStep1(theme),
                    _buildStep2(theme),
                    _buildStep3(theme),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── الخطوة 1: بيانات الشركة ──────────────────────────────────────────────

  Step _buildStep1(ThemeData theme) {
    return Step(
      title: const Text('بيانات الشركة'),
      subtitle: const Text('اسم الشركة والعملة'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _step1Key,
        child: Column(
          children: [
            // اسم الشركة
            TextFormField(
              controller: _companyNameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم الشركة *',
                prefixIcon: Icon(Icons.business_outlined),
                hintText: 'مثال: شركة النور للتجارة',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'اسم الشركة مطلوب';
                if (v.trim().length < 2) return 'اسم قصير جداً';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // سعر الصرف الابتدائي
            TextFormField(
              controller: _exchangeRateCtrl,
              textDirection: TextDirection.ltr,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'سعر الصرف (IQD مقابل 1 USD)',
                prefixIcon: Icon(Icons.currency_exchange),
                hintText: '1310',
                suffixText: 'IQD',
              ),
              validator: (v) {
                final rate = double.tryParse(v ?? '');
                if (rate == null || rate <= 0) return 'سعر الصرف يجب أن يكون أكبر من صفر';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // العملة الأساسية (ثابتة)
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('العملة الأساسية'),
              subtitle: const Text('دينار عراقي (IQD)'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ── الخطوة 2: حساب المدير ────────────────────────────────────────────────

  Step _buildStep2(ThemeData theme) {
    return Step(
      title: const Text('حساب مدير النظام'),
      subtitle: const Text('صلاحيات كاملة — لا يمكن حذفه'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _step2Key,
        child: Column(
          children: [
            // الاسم الكامل
            TextFormField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل *',
                prefixIcon: Icon(Icons.badge_outlined),
                hintText: 'مثال: محمد أحمد',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'الاسم الكامل مطلوب';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // اسم المستخدم
            TextFormField(
              controller: _usernameCtrl,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم *',
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'مثال: admin',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'اسم المستخدم مطلوب';
                if (v.trim().length < 3) return 'يجب أن يكون 3 أحرف على الأقل';
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                  return 'يُسمح فقط بالأحرف الإنجليزية والأرقام و _';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // كلمة المرور
            TextFormField(
              controller: _passwordCtrl,
              textDirection: TextDirection.ltr,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور *',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                if (v.length < 6) return 'يجب أن تكون 6 أحرف على الأقل';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // تأكيد كلمة المرور
            TextFormField(
              controller: _confirmPasswordCtrl,
              textDirection: TextDirection.ltr,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور *',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'تأكيد كلمة المرور مطلوب';
                if (v != _passwordCtrl.text) return 'كلمتا المرور غير متطابقتين';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── الخطوة 3: مراجعة وتأكيد ─────────────────────────────────────────────

  Step _buildStep3(ThemeData theme) {
    return Step(
      title: const Text('مراجعة وتأكيد'),
      subtitle: const Text('تحقق من البيانات قبل الإنهاء'),
      isActive: _currentStep >= 2,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ملخص البيانات
          _SummaryTile(
            icon: Icons.business_outlined,
            label: 'اسم الشركة',
            value: _companyNameCtrl.text.trim().isEmpty
                ? '—'
                : _companyNameCtrl.text.trim(),
          ),
          _SummaryTile(
            icon: Icons.currency_exchange,
            label: 'سعر الصرف',
            value: '${_exchangeRateCtrl.text} IQD = 1 USD',
          ),
          _SummaryTile(
            icon: Icons.badge_outlined,
            label: 'الاسم الكامل للمدير',
            value: _fullNameCtrl.text.trim().isEmpty
                ? '—'
                : _fullNameCtrl.text.trim(),
          ),
          _SummaryTile(
            icon: Icons.person_outline,
            label: 'اسم المستخدم',
            value: _usernameCtrl.text.trim().isEmpty
                ? '—'
                : _usernameCtrl.text.trim(),
          ),
          _SummaryTile(
            icon: Icons.verified_user_outlined,
            label: 'الدور',
            value: 'مدير النظام (Super Admin)',
          ),

          const SizedBox(height: 12),

          // تنبيه مهم
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'يمكنك تعديل بيانات الشركة لاحقاً من شاشة الإعدادات.\n'
                    'كلمة المرور يمكن تغييرها من إدارة المستخدمين.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget مساعد: صف الملخص ──────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
