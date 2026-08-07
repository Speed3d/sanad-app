// ─────────────────────────────────────────────────────────────────────────────
// app_components.dart — مكونات واجهة مشتركة قابلة لإعادة الاستخدام
//
// الغرض:
//   توحيد المكونات التي كانت مكرّرة عبر الشاشات (تدقيق 2026-08-07):
//     - AppEmptyState   — حالة القائمة الفارغة (كانت 7 نسخ)
//     - AppStatusBadge  — شارة حالة/نوع ملوّنة (كانت 6 نسخ)
//     - showConfirmDialog — حوار تأكيد موحّد (كان 9 نسخ يدوية)
//
// الفائدة: مظهر متسق + تقليل التكرار + مكان واحد للتعديل مستقبلاً.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AppEmptyState — حالة القائمة الفارغة
// ═══════════════════════════════════════════════════════════════════════════

/// عنصر موحّد لعرض حالة "لا توجد بيانات" مع أيقونة ورسالة وزر اختياري
class AppEmptyState extends StatelessWidget {
  /// الأيقونة المعروضة
  final IconData icon;

  /// الرسالة الأساسية
  final String message;

  /// رسالة فرعية اختيارية (وصف إضافي)
  final String? subtitle;

  /// نص زر الإجراء الاختياري (مثل: "إضافة")
  final String? actionLabel;

  /// دالة زر الإجراء
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AppStatusBadge — شارة حالة/نوع ملوّنة
// ═══════════════════════════════════════════════════════════════════════════

/// شارة صغيرة ملوّنة لعرض حالة أو نوع (نشط/معطّل، نوع الخزينة، الدور...)
class AppStatusBadge extends StatelessWidget {
  /// النص المعروض
  final String label;

  /// اللون الأساسي (تُشتق منه الخلفية والنص)
  final Color color;

  /// أيقونة اختيارية قبل النص
  final IconData? icon;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// showConfirmDialog — حوار تأكيد موحّد
// ═══════════════════════════════════════════════════════════════════════════

/// يعرض حوار تأكيد موحّداً ويُعيد true إذا أكّد المستخدم، false/null خلاف ذلك
///
/// [title]        — عنوان الحوار
/// [message]      — نص التأكيد
/// [confirmLabel] — نص زر التأكيد (افتراضي: "تأكيد")
/// [cancelLabel]  — نص زر الإلغاء (افتراضي: "إلغاء")
/// [isDestructive]— true يجعل زر التأكيد أحمر (لعمليات الحذف)
///
/// الاستخدام:
///   final ok = await showConfirmDialog(context,
///     title: 'تأكيد الحذف', message: 'هل تريد الحذف؟', isDestructive: true);
///   if (ok == true) { ... }
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'تأكيد',
  String cancelLabel = 'إلغاء',
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
