// ─────────────────────────────────────────────────────────────────────────────
// error_screen.dart — شاشة الأخطاء (404 و 403)
//
// تُستخدَم في حالتين:
//   is404 = true  → الصفحة غير موجودة
//   is404 = false → ليس لديك صلاحية
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';

/// شاشة الخطأ العامة
class ErrorScreen extends StatelessWidget {
  /// رسالة الخطأ
  final String error;

  /// true = 404، false = 403
  final bool is404;

  const ErrorScreen({
    super.key,
    required this.error,
    this.is404 = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // عنوان مناسب لنوع الخطأ
        title: Text(is404 ? 'صفحة غير موجودة' : 'وصول مرفوض'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة الخطأ
              Icon(
                is404 ? Icons.search_off_rounded : Icons.lock_outline_rounded,
                size: 80,
                color: theme.colorScheme.error.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 24),

              // رمز الخطأ
              Text(
                is404 ? '404' : '403',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),

              // رسالة الخطأ
              Text(
                error,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // زر العودة للرئيسية
              FilledButton.icon(
                icon: const Icon(Icons.home_outlined),
                label: const Text('العودة للرئيسية'),
                onPressed: () => context.go(AppRoutes.dashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
