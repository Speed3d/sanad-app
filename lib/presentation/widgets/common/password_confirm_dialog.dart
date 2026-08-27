// ─────────────────────────────────────────────────────────────────────────────
// password_confirm_dialog.dart — تأكيد الهويّة قبل عكس مالٍ خرج
//
// 🔑 **سبب وجوده** (طلب المالك 2026-08-27): «حتى لا يكون هناك تلاعب إذا لم
//   يكن المستخدم قرب الكمبيوتر الخاص به».
//
//   الجلسة المفتوحة تُثبت أن أحداً **سجّل الدخول**، لا أن **صاحبها** هو من
//   يضغط الآن. وبين الاثنين فرقٌ كبير حين تكون العملية إرجاع مالٍ خرج من
//   الخزينة: هي أخطر ما في البرنامج، وأسهل ما يُنكَر.
//
// **القاعدة المعتمدة بلا استثناء:** كل ما يُرجع مالاً خرج يُثبِت صاحبه هويّته.
//   والاستثناءات هي ما يجعل المستخدم يسأل «لماذا هنا ولا هناك؟» فيفقد الثقة
//   بالحاجز كلّه.
//
// ⚠️ **بلا `TextEditingController`** — `initialValue`/`onChanged` وحدهما،
//   فالمتحكّم المُتخلَّص منه بعد `await showDialog` سبّب شاشة حمراء في خمسة
//   مواضع (ع-٠٤).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';

/// يطلب كلمة مرور المستخدم الحالي — يُعيد `true` عند التطابق وحده
///
/// [action] — وصف العملية بلغة المالك («إلغاء سلفة الموظف حسن محمد»)
/// [impact] — سطرٌ يقول ما سيقع مالياً («سيرجع ٥٠٠٬٠٠٠ د.ع إلى الخزينة»)
///
/// 📌 يُعيد `false` عند الإلغاء أو الخطأ — فالمستدعي يتوقّف بلا أن يسأل عن
///   السبب. وأي شكّ يعني **عدم التنفيذ**.
Future<bool> confirmWithPassword(
  BuildContext context,
  WidgetRef ref, {
  required String action,
  String? impact,
}) async {
  final authState = ref.read(authNotifierProvider);
  if (authState is! AuthAuthenticated) return false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PasswordConfirmDialog(
      action: action,
      impact: impact,
      userId: authState.user.id,
      username: authState.user.username,
    ),
  );
  return result == true;
}

class _PasswordConfirmDialog extends ConsumerStatefulWidget {
  const _PasswordConfirmDialog({
    required this.action,
    required this.impact,
    required this.userId,
    required this.username,
  });

  final String action;
  final String? impact;
  final int userId;
  final String username;

  @override
  ConsumerState<_PasswordConfirmDialog> createState() =>
      _PasswordConfirmDialogState();
}

class _PasswordConfirmDialogState
    extends ConsumerState<_PasswordConfirmDialog> {
  String _password = '';
  String? _error;
  bool _busy = false;

  Future<void> _verify() async {
    if (_password.isEmpty) {
      setState(() => _error = 'أدخل كلمة المرور');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final db = ref.read(appDatabaseProvider);
      final auth = ref.read(authServiceProvider);
      final dbUser = await db.usersDao.getUserById(widget.userId);

      if (dbUser == null) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = 'تعذّر قراءة بيانات المستخدم';
        });
        return;
      }

      final ok = await auth.verifyPassword(_password, dbUser.passwordHash);
      if (!mounted) return;

      if (ok) {
        Navigator.pop(context, true);
      } else {
        // ⚠️ رسالة واحدة لكل سبب: «غير صحيحة» لا «المستخدم غير موجود» ولا
        //   «الحرف الثالث خطأ». كل تمييز إضافي معلومةٌ لمن لا يملكها.
        setState(() {
          _busy = false;
          _error = 'كلمة المرور غير صحيحة';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'تعذّر التحقّق — حاول ثانيةً';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 20, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          const Expanded(child: Text('تأكيد الهويّة')),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.action,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
            if (widget.impact != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.impact!,
                style: TextStyle(
                    fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'أدخل كلمة مرور «${widget.username}» للمتابعة — '
              'العملية تُرجع مالاً خرج من الخزينة.',
              style: TextStyle(
                  fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: _password,
              obscureText: true,
              autofocus: true,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                border: const OutlineInputBorder(),
                isDense: true,
                errorText: _error,
                prefixIcon: const Icon(Icons.key_outlined, size: 18),
              ),
              onChanged: (v) => _password = v,
              // الإدخال ثم Enter — أسرع من ملاحقة الزرّ بالفأرة
              onFieldSubmitted: (_) => _busy ? null : _verify(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('تراجع'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error),
          onPressed: _busy ? null : _verify,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('تأكيد'),
        ),
      ],
    );
  }
}
