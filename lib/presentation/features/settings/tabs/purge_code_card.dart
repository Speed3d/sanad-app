// ─────────────────────────────────────────────────────────────────────────────
// purge_code_card.dart — بطاقة تعيين «رمز المحو القسري»
//
// رمز المحو هو **العامل الثاني** المطلوب قبل محو فترة مالية بكل سنداتها محواً
// نهائياً لا رجعة فيه. أُضيف بطلب المالك (2026-08-23) لأن مرحلة الاختبار
// تتطلّب تصفير سنة كاملة وإعادة بنائها، بينما الحذف العادي يرفض — بحقّ — أي
// فترة فيها أثر مالي ولو كان كل سنداتها محذوفة ناعماً.
//
// لماذا رمز منفصل عن كلمة المرور؟
//   كلمة المرور تُكتب يومياً عند الدخول وقد يراها أحد أو تُحفَظ في مدير
//   كلمات مرور. أما هذا الرمز فلا يُستعمل إلا في هذه العملية الواحدة، فبقاؤه
//   سرّاً أسهل. الطبقتان معاً تعنيان أن معرفة إحداهما وحدها لا تكفي.
//
// لماذا لا يُخزَّن صريحاً؟
//   كل الإعدادات الأخرى تُقرأ بوضوح لمن يفتح ملف قاعدة البيانات بمحرّر
//   SQLite. فلو حُفظ الرمز نصّاً صريحاً لسقط الغرض منه كلّه. يُشفَّر بـ bcrypt
//   تماماً كأي كلمة مرور — ويُتحقَّق منه بالمقارنة لا بالقراءة.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_settings_keys.dart';
import '../../../../domain/models/auth_state.dart';
import '../../../../domain/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/database_provider.dart';

/// بطاقة تعيين أو تغيير رمز المحو القسري — لمدير النظام وحده
class PurgeCodeCard extends ConsumerStatefulWidget {
  const PurgeCodeCard({super.key});

  @override
  ConsumerState<PurgeCodeCard> createState() => _PurgeCodeCardState();
}

class _PurgeCodeCardState extends ConsumerState<PurgeCodeCard> {
  // متغيّرات نصّية لا TextEditingController — راجع الحارس في
  // test/unit/dialog_controller_lifecycle_test.dart
  String _code = '';
  String _confirm = '';
  String _password = '';

  bool _saving = false;
  String? _error;
  bool _isSet = false;

  /// يُزاد بعد الحفظ فتتغيّر مفاتيح الحقول فتُبنى فارغةً من جديد
  int _formEpoch = 0;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  /// هل الرمز مُعيَّن أصلاً؟ — لعرض الحالة فقط، لا لكشف الرمز
  Future<void> _loadState() async {
    final hash = await ref
        .read(appDatabaseProvider)
        .appSettingsDao
        .getString(AppSettingsKeys.purgeCodeHash);
    if (mounted) {
      setState(() => _isSet = hash != null && hash.isNotEmpty);
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);

    if (_code.trim().length < 4) {
      setState(() => _error = 'الرمز يجب ألا يقل عن ٤ خانات');
      return;
    }
    if (_code != _confirm) {
      setState(() => _error = 'الرمز وتأكيده غير متطابقين');
      return;
    }

    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;

    setState(() => _saving = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final auth = ref.read(authServiceProvider);

      // تغيير الرمز يتطلّب كلمة المرور — وإلا كفى أن يجد أحدٌ الجهاز مفتوحاً
      // ليضع رمزاً يعرفه ثم يمحو ما يشاء، فيسقط الغرض من العامل الثاني.
      final dbUser = await db.usersDao.getUserById(authState.user.id);
      if (dbUser == null) {
        setState(() => _error = 'تعذّر قراءة بيانات المستخدم');
        return;
      }
      if (!await auth.verifyPassword(_password, dbUser.passwordHash)) {
        setState(() => _error = 'كلمة المرور غير صحيحة');
        return;
      }

      final hash = await auth.hashPassword(_code.trim());
      await db.appSettingsDao.setString(AppSettingsKeys.purgeCodeHash, hash);

      if (!mounted) return;
      setState(() {
        _code = '';
        _confirm = '';
        _password = '';
        _formEpoch++;
        _isSet = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ تم حفظ رمز المحو القسري')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    // العملية كلها لمدير النظام وحده — فلا معنى لعرض البطاقة لغيره
    if (user == null || !user.isSuperAdmin) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.error.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_outlined,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'رمز المحو القسري',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                Chip(
                  label: Text(_isSet ? 'مُعيَّن' : 'غير مُعيَّن'),
                  visualDensity: VisualDensity.compact,
                  labelStyle: theme.textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'العامل الثاني المطلوب قبل محو فترة مالية بكل سنداتها محواً '
              'نهائياً لا رجعة فيه. يُطلب مع كلمة مرورك ومع كتابة اسم الفترة. '
              'بدون تعيينه يبقى المحو القسري معطَّلاً.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: ValueKey('purge_code_$_formEpoch'),
              initialValue: _code,
              onChanged: (v) => _code = v,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'رمز المحو الجديد',
                prefixIcon: Icon(Icons.key_outlined),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('purge_confirm_$_formEpoch'),
              initialValue: _confirm,
              onChanged: (v) => _confirm = v,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'تأكيد الرمز',
                prefixIcon: Icon(Icons.key_outlined),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('purge_pw_$_formEpoch'),
              initialValue: _password,
              onChanged: (v) => _password = v,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة مرورك (للتأكيد)',
                prefixIcon: Icon(Icons.lock_outline),
                isDense: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 16),
              label: Text(_isSet ? 'تغيير الرمز' : 'تعيين الرمز'),
            ),
          ],
        ),
      ),
    );
  }
}
