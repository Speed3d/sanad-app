// ─────────────────────────────────────────────────────────────────────────────
// first_run_screen.dart — شاشة الإعداد الأول والترحيب (Fintech First Run Setup)
//
// تعليقات توضيحية بالعربية:
// هذه الشاشة تظهر مرة واحدة فقط عند تشغيل التطبيق لأول مرة لإعداد النظام:
//   الخطوة 1: بيانات الشركة واسمها وسعر الصرف الابتدائي
//   الخطوة 2: حساب مدير النظام الرئيسي (Super Admin) وتشفير كلمة المرور بـ bcrypt
//   الخطوة 3: المراجعة والتأكيد النهائي وتطبيق التغييرات تلقائياً
//
// مصممة بأسلوب مالي فاخر (Fintech Luxury Theme) متناسق مع شاشات اللوحة والخزائن والسندات.
// ─────────────────────────────────────────────────────────────────────────────

import '../../../core/utils/input_validators.dart';
import '../../../core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/repository_providers.dart';

/// شاشة الإعداد الأول الفاخرة لوحة التحكم
class FirstRunScreen extends ConsumerStatefulWidget {
  const FirstRunScreen({super.key});

  @override
  ConsumerState<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends ConsumerState<FirstRunScreen> {
  int _currentStep = 0;

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  final _companyNameCtrl = TextEditingController();
  final _exchangeRateCtrl = TextEditingController(text: '1310');

  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

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

  void _onStepContinue() {
    setState(() => _errorMessage = null);

    if (_currentStep == 0) {
      if (_step1Key.currentState?.validate() != true) return;
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_step2Key.currentState?.validate() != true) return;
      setState(() => _currentStep = 2);
    } else {
      _finish();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

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

      // 1. حفظ إعدادات الشركة وسعر الصرف
      await settingsRepo.setCompanyName(_companyNameCtrl.text.trim());

      final rateText = _exchangeRateCtrl.text.trim();
      final rate = double.tryParse(rateText);
      if (rate != null && rate > 0) {
        await settingsRepo.setExchangeRate(rate);
        await db.exchangeRatesDao.setUsdToIqdRate(rate);
      }

      // 2. تشفير كلمة المرور وتوليد المستخدم الرئيسي
      final passwordHash = await service.hashPassword(_passwordCtrl.text);

      final userId = await userRepo.createUser(
        username: _usernameCtrl.text.trim().toLowerCase(),
        passwordHash: passwordHash,
        fullName: _fullNameCtrl.text.trim(),
        role: 'super_admin',
      );

      // 3. تعليم الإعداد المكتمل وحفظ الجلسة
      await settingsRepo.markFirstRunComplete();
      await service.saveSession(
        userId: userId,
        username: _usernameCtrl.text.trim().toLowerCase(),
      );

      await ref.read(authNotifierProvider.notifier).reinitialize();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'فشل إعداد التطبيق: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. بطاقة الترحب والرويس القيادي ───────────────────────────
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
                  child: Stack(
                    children: [
                      // الهالة الذهبية
                      Positioned(
                        top: -50,
                        left: -30,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFE0BC66).withValues(alpha: 0.22),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0BC66).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE0BC66),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.waving_hand_rounded,
                              size: 34,
                              color: Color(0xFFE0BC66),
                            ),
                          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                          const SizedBox(height: 16),

                          const Text(
                            'أهلاً بك في نظام سند',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Cairo',
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 200.ms),

                          const SizedBox(height: 6),

                          Text(
                            'دعنا نقوم بإعداد نظام إدارة المبيعات والخزينة الخاص بك خطوة بخطوة',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                              fontFamily: 'Cairo',
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 350.ms),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── 2. رسالة الخطأ ────────────────────────────────────────────
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade400),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // ── 3. بطاقة الـ Stepper الفاخرة ──────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.colors.border,
                    ),
                  ),
                  child: Theme(
                    data: theme.copyWith(
                      colorScheme: theme.colorScheme.copyWith(
                        primary: context.colors.gold,
                      ),
                    ),
                    child: Stepper(
                      currentStep: _currentStep,
                      onStepTapped: (step) {
                        if (step < _currentStep) setState(() => _currentStep = step);
                      },
                      onStepContinue: _isLoading ? null : _onStepContinue,
                      onStepCancel: _isLoading ? null : _onStepCancel,
                      controlsBuilder: (context, details) => Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading ? null : details.onStepContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colors.gold,
                                foregroundColor: context.colors.onGold,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
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
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                            ),
                            if (_currentStep > 0) ...[
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: _isLoading ? null : details.onStepCancel,
                                child: Text(
                                  'السابق',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.subtext,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      steps: [
                        _buildStep1(isDark),
                        _buildStep2(isDark),
                        _buildStep3(isDark),
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

  // ── الخطوة 1: بيانات الشركة ──────────────────────────────────────────────

  Step _buildStep1(bool isDark) {
    return Step(
      title: Text(
        'بيانات الشركة',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: context.colors.text,
        ),
      ),
      subtitle: Text(
        'اسم المؤسسة وسعر الصرف',
        style: TextStyle(
          fontSize: 11.5,
          color: context.colors.subtext,
        ),
      ),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _step1Key,
        child: Column(
          children: [
            const SizedBox(height: 8),
            TextFormField(
              controller: _companyNameCtrl,
              style: TextStyle(
                fontSize: 13.5,
                color: context.colors.text,
              ),
              decoration: InputDecoration(
                labelText: 'اسم الشركة *',
                prefixIcon: const Icon(Icons.business_outlined, size: 20),
                hintText: 'مثال: شركة النور للتجارة المقاولات العامة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'اسم الشركة مطلوب';
                if (v.trim().length < 2) return 'اسم قصير جداً';
                return null;
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _exchangeRateCtrl,
              textDirection: TextDirection.ltr,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 13.5,
                color: context.colors.text,
              ),
              decoration: InputDecoration(
                labelText: 'سعر الصرف (IQD مقابل 1 USD)',
                prefixIcon: const Icon(Icons.currency_exchange, size: 20),
                hintText: '1310',
                suffixText: 'IQD',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                final rate = double.tryParse(v ?? '');
                if (rate == null || rate <= 0) return 'سعر الصرف يجب أن يكون أكبر من صفر';
                return null;
              },
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.colors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.colors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 20,
                    color: context.colors.gold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'العملة الأساسية للنظام',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.colors.subtext,
                          ),
                        ),
                        Text(
                          'الدينار العراقي (IQD) مع دعم الدولار الأمريكي (\$)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.colors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── الخطوة 2: حساب المدير ────────────────────────────────────────────────

  Step _buildStep2(bool isDark) {
    return Step(
      title: Text(
        'حساب مدير النظام',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: context.colors.text,
        ),
      ),
      subtitle: Text(
        'صلاحيات كاملة — Super Admin',
        style: TextStyle(
          fontSize: 11.5,
          color: context.colors.subtext,
        ),
      ),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _step2Key,
        child: Column(
          children: [
            const SizedBox(height: 8),
            TextFormField(
              controller: _fullNameCtrl,
              style: TextStyle(
                fontSize: 13.5,
                color: context.colors.text,
              ),
              decoration: InputDecoration(
                labelText: 'الاسم الكامل *',
                prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                hintText: 'مثال: محمد أحمد علي',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'الاسم الكامل مطلوب';
                return null;
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _usernameCtrl,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 13.5,
                color: context.colors.text,
              ),
              decoration: InputDecoration(
                labelText: 'اسم المستخدم *',
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                hintText: 'مثال: admin',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              // مدقّق مشترك — نفس القواعد بالضبط (المرحلة د)
              validator: InputValidators.username,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _passwordCtrl,
              textDirection: TextDirection.ltr,
              obscureText: _obscurePassword,
              style: TextStyle(
                fontSize: 13.5,
                color: context.colors.text,
              ),
              decoration: InputDecoration(
                labelText: 'كلمة المرور *',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: InputValidators.password(minLength: 6),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _confirmPasswordCtrl,
              textDirection: TextDirection.ltr,
              obscureText: _obscureConfirm,
              style: TextStyle(
                fontSize: 13.5,
                color: context.colors.text,
              ),
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور *',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator:
                  InputValidators.confirmPassword(_passwordCtrl.text),
            ),
          ],
        ),
      ),
    );
  }

  // ── الخطوة 3: مراجعة وتأكيد ─────────────────────────────────────────────

  Step _buildStep3(bool isDark) {
    return Step(
      title: Text(
        'مراجعة وتأكيد',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: context.colors.text,
        ),
      ),
      subtitle: Text(
        'تحقق من البيانات قبل الإنهاء',
        style: TextStyle(
          fontSize: 11.5,
          color: context.colors.subtext,
        ),
      ),
      isActive: _currentStep >= 2,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _SummaryTile(
            icon: Icons.business_outlined,
            label: 'اسم الشركة',
            value: _companyNameCtrl.text.trim().isEmpty ? '—' : _companyNameCtrl.text.trim(),
            isDark: isDark,
          ),
          _SummaryTile(
            icon: Icons.currency_exchange,
            label: 'سعر الصرف الابتدائي',
            value: '${_exchangeRateCtrl.text} IQD = 1 USD',
            isDark: isDark,
          ),
          _SummaryTile(
            icon: Icons.badge_outlined,
            label: 'اسم المدير الكامل',
            value: _fullNameCtrl.text.trim().isEmpty ? '—' : _fullNameCtrl.text.trim(),
            isDark: isDark,
          ),
          _SummaryTile(
            icon: Icons.person_outline,
            label: 'اسم المستخدم',
            value: _usernameCtrl.text.trim().isEmpty ? '—' : _usernameCtrl.text.trim(),
            isDark: isDark,
          ),
          _SummaryTile(
            icon: Icons.verified_user_outlined,
            label: 'الدور والصلاحية',
            value: 'مدير النظام (Super Admin)',
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFFE0BC66).withValues(alpha: 0.12) : AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFFE0BC66).withValues(alpha: 0.3) : AppColors.navy.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: context.colors.gold,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'يمكنك تعديل بيانات الشركة وسعر الصرف لاحقاً من شاشة الإعدادات.\nكلمة المرور يمكن تغييرها دائماً من إدارة المستخدمين.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: context.colors.text,
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
  final bool isDark;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: context.colors.subtext,
          ),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: context.colors.subtext,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: context.colors.text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
