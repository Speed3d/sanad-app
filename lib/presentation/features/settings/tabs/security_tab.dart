// ─────────────────────────────────────────────────────────────────────────────
// security_tab.dart — قسم الأمان
//
// يتيح للمستخدم المصادَق:
//   1. تغيير كلمة مروره
//      - التحقق من كلمة المرور القديمة بـ bcrypt (عبر AppDatabase مباشرةً)
//      - تشفير الجديدة بـ bcrypt وحفظها
//   2. ضبط القفل التلقائي بالدقائق
//
// لماذا نقرأ من DB مباشرة؟
//   UserModel لا يحتوي passwordHash لأسباب أمنية.
//   للتحقق من كلمة المرور القديمة نحتاج الـ hash — لذا نقرأ مباشرة من DB.
//   هذا مقبول أمنياً لأن المستخدم مُصادَق بالفعل.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_settings_keys.dart';
import '../../../../domain/models/auth_state.dart';
import '../../../../domain/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/settings_provider.dart';
import 'settings_shared.dart';

/// خيارات القفل التلقائي
const List<_LockOption> _lockOptions = [
  _LockOption(minutes: 0, label: 'بلا قفل'),
  _LockOption(minutes: 5, label: '5 دقائق'),
  _LockOption(minutes: 15, label: '15 دقيقة'),
  _LockOption(minutes: 30, label: '30 دقيقة'),
  _LockOption(minutes: 60, label: 'ساعة كاملة'),
];

class _LockOption {
  final int minutes;
  final String label;
  const _LockOption({required this.minutes, required this.label});
}

/// قسم الأمان
class SecurityTab extends ConsumerStatefulWidget {
  const SecurityTab({super.key});

  @override
  ConsumerState<SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends ConsumerState<SecurityTab> {
  // ── حقول تغيير كلمة المرور ─────────────────────────────────────────────────
  final _passwordFormKey = GlobalKey<FormState>();
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSavingPassword = false;
  String? _passwordError;

  // ── القفل التلقائي ─────────────────────────────────────────────────────────
  int _selectedLockMinutes = 0;
  bool _isSavingLock = false;

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// تغيير كلمة المرور
  ///
  /// 1. نقرأ الـ hash من DB مباشرة (المستخدم مُصادَق بالفعل — آمن)
  /// 2. نتحقق من كلمة المرور القديمة بـ bcrypt
  /// 3. نشفر الجديدة بـ bcrypt ونحفظها
  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isSavingPassword = true;
      _passwordError = null;
    });

    try {
      final authState = ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        setState(() => _passwordError = 'يجب تسجيل الدخول أولاً');
        return;
      }

      final service = ref.read(authServiceProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final db = ref.read(appDatabaseProvider);

      // ── قراءة الـ hash من DB للتحقق من كلمة المرور القديمة ──────────────
      final dbUser = await db.usersDao.getUserById(authState.user.id);
      if (dbUser == null) {
        setState(() => _passwordError = 'لم يُعثَر على بيانات المستخدم');
        return;
      }

      // ── التحقق من كلمة المرور القديمة بـ bcrypt ──────────────────────────
      final isValid = await service.verifyPassword(
        _oldPasswordCtrl.text,
        dbUser.passwordHash,
      );

      if (!isValid) {
        setState(() => _passwordError = 'كلمة المرور الحالية غير صحيحة');
        return;
      }

      // ── تشفير الجديدة وحفظها ──────────────────────────────────────────────
      final newHash = await service.hashPassword(_newPasswordCtrl.text);
      await userRepo.changePassword(authState.user.id, newHash);

      if (mounted) {
        _oldPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ تم تغيير كلمة المرور بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _passwordError = 'حدث خطأ: $e');
      }
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  /// حفظ إعداد القفل التلقائي
  Future<void> _saveLockSetting() async {
    setState(() => _isSavingLock = true);
    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.setString(
        AppSettingsKeys.autoLockMinutes,
        _selectedLockMinutes.toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedLockMinutes == 0
                  ? '✓ القفل التلقائي معطَّل'
                  : '✓ القفل التلقائي بعد $_selectedLockMinutes دقيقة',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingLock = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final UserModel? currentUser =
        authState is AuthAuthenticated ? authState.user : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader(
            icon: Icons.security_outlined,
            title: 'الأمان',
            subtitle: 'كلمة المرور وإعدادات القفل التلقائي',
          ),

          const SizedBox(height: 16),

          // ── معلومات الحساب الحالي ──────────────────────────────────────────
          if (currentUser != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      currentUser.fullName.isNotEmpty
                          ? currentUser.fullName[0]
                          : '?',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser.fullName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        // استخدام extension UserModelX.roleDisplayName
                        currentUser.roleDisplayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 28),

          // ── تغيير كلمة المرور ─────────────────────────────────────────────
          Text(
            'تغيير كلمة المرور',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Form(
            key: _passwordFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _oldPasswordCtrl,
                  obscureText: _obscureOld,
                  textDirection: TextDirection.ltr,
                  enabled: !_isSavingPassword,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الحالية',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureOld
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureOld = !_obscureOld),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'كلمة المرور الحالية مطلوبة'
                      : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _newPasswordCtrl,
                  obscureText: _obscureNew,
                  textDirection: TextDirection.ltr,
                  enabled: !_isSavingPassword,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'كلمة المرور الجديدة مطلوبة';
                    if (v.length < 6) return 'الحد الأدنى 6 أحرف';
                    if (v == _oldPasswordCtrl.text) {
                      return 'يجب أن تختلف عن كلمة المرور الحالية';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  textDirection: TextDirection.ltr,
                  enabled: !_isSavingPassword,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور الجديدة',
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'تأكيد كلمة المرور مطلوب';
                    if (v != _newPasswordCtrl.text) {
                      return 'كلمتا المرور غير متطابقتين';
                    }
                    return null;
                  },
                ),

                // رسالة الخطأ
                if (_passwordError != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: theme.colorScheme.onErrorContainer,
                            size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _passwordError!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isSavingPassword ? null : _changePassword,
                    icon: _isSavingPassword
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_reset_outlined),
                    label: const Text('تغيير كلمة المرور'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // ── سياسة الرصيد المدين ────────────────────────────────────────────
          const _BalancePolicyCard(),

          const SizedBox(height: 24),

          // ── القفل التلقائي ─────────────────────────────────────────────────
          Text(
            'القفل التلقائي',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'يُقفَل التطبيق تلقائياً عند عدم الاستخدام',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _lockOptions.map((opt) {
              return ChoiceChip(
                label: Text(opt.label),
                selected: opt.minutes == _selectedLockMinutes,
                onSelected: (_) =>
                    setState(() => _selectedLockMinutes = opt.minutes),
                selectedColor: theme.colorScheme.primaryContainer,
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isSavingLock ? null : _saveLockSetting,
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ إعداد القفل'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BalancePolicyCard — بطاقة سياسة الرصيد المدين
//
// تتحكم في إعداد enforce_balance_check: هل يُمنع الصرف فوق رصيد الخزينة
// منعاً باتّاً، أم يُسمح بالرصيد المدين؟ الافتراضي: منع.
// ─────────────────────────────────────────────────────────────────────────────

class _BalancePolicyCard extends ConsumerWidget {
  const _BalancePolicyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // القيمة الحالية — null أو 'true' تعني المنع (الافتراضي)
    final raw = ref.watch(enforceBalanceCheckProvider).valueOrNull;
    final enforce = raw == null || raw == 'true';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'سياسة الرصيد المدين',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: enforce,
            title: Text(
              enforce ? 'منع الصرف فوق الرصيد' : 'السماح بالرصيد المدين',
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: Text(
              enforce
                  ? 'لا يمكن صرف مبلغ يتجاوز رصيد الخزينة المتاح.'
                  : 'يُسمح بأن يصبح رصيد الخزينة سالباً (مديناً).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            onChanged: (v) async {
              // نُخزّن 'true'/'false' نصاً في الإعدادات
              await ref
                  .read(settingsRepositoryProvider)
                  .setString(AppSettingsKeys.enforceBalanceCheck, v.toString());
            },
          ),
        ],
      ),
    );
  }
}
