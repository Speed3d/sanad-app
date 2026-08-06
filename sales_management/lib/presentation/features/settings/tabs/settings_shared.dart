// ─────────────────────────────────────────────────────────────────────────────
// settings_shared.dart — مكونات مشتركة بين تبويبات الإعدادات
//
// يحتوي هذا الملف على:
//   - SettingsSectionHeader: عنوان مشترك مع أيقونة وعنوان فرعي
//
// يُستخدَم في جميع تبويبات الإعدادات الثمانية لضمان التناسق البصري
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// عنوان قسم الإعدادات مع أيقونة وعنوان فرعي
///
/// يُستخدَم في أعلى كل تبويب من تبويبات الإعدادات لتوحيد الشكل
class SettingsSectionHeader extends StatelessWidget {
  /// أيقونة القسم
  final IconData icon;

  /// عنوان القسم الرئيسي
  final String title;

  /// عنوان فرعي وصفي
  final String subtitle;

  const SettingsSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // أيقونة في خلفية ملوّنة
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimaryContainer,
            size: 26,
          ),
        ),
        const SizedBox(width: 16),
        // العنوانان
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
