// ─────────────────────────────────────────────────────────────────────────────
// system_info_tab.dart — قسم معلومات النظام
//
// يعرض:
//   - إصدار التطبيق وتاريخ البناء
//   - إحصائيات قاعدة البيانات (عدد السندات، المستخدمين، إلخ)
//   - نسخة قاعدة البيانات (Schema Version)
//   - زر تسجيل الخروج مع تأكيد
//
// هذا القسم للعرض فقط — لا حفظ مطلوب
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../domain/models/auth_state.dart';
import '../../../../domain/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/settings_provider.dart';
import 'settings_shared.dart';

// ── Provider إحصائيات قاعدة البيانات ─────────────────────────────────────────

/// Provider لجلب إحصائيات قاعدة البيانات
final _dbStatsProvider = FutureProvider<_DbStats>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final settings = ref.watch(allSettingsProvider).valueOrNull ?? {};

  // جلب الإحصائيات بشكل متوازٍ
  final results = await Future.wait([
    db.usersDao.watchAllUsers().first,
    db.vouchersDao.getVouchersByDateRange(
      from: DateTime(2000),
      to: DateTime(2100),
    ),
    db.treasuriesDao.watchAllTreasuries().first,
    db.employeesDao.watchAllEmployees().first,
  ]);

  return _DbStats(
    usersCount: (results[0] as List).length,
    vouchersCount: (results[1] as List).length,
    treasuriesCount: (results[2] as List).length,
    employeesCount: (results[3] as List).length,
    schemaVersion: settings['db_schema_version'] ?? '1',
  );
});

class _DbStats {
  final int usersCount;
  final int vouchersCount;
  final int treasuriesCount;
  final int employeesCount;
  final String schemaVersion;

  const _DbStats({
    required this.usersCount,
    required this.vouchersCount,
    required this.treasuriesCount,
    required this.employeesCount,
    required this.schemaVersion,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// قسم معلومات النظام
// ─────────────────────────────────────────────────────────────────────────────

/// قسم معلومات النظام
class SystemInfoTab extends ConsumerWidget {
  const SystemInfoTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final currentUser =
        authState is AuthAuthenticated ? authState.user : null;
    final dbStatsAsync = ref.watch(_dbStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── عنوان القسم ────────────────────────────────────────────────────
          const SettingsSectionHeader(
            icon: Icons.info_outline,
            title: 'معلومات النظام',
            subtitle: 'إصدار التطبيق وإحصائيات قاعدة البيانات',
          ),

          const SizedBox(height: 24),

          // ── معلومات التطبيق ────────────────────────────────────────────────
          _InfoSection(
            title: 'التطبيق',
            children: [
              _InfoRow(label: 'اسم التطبيق', value: 'نظام إدارة المبيعات'),
              _InfoRow(label: 'الإصدار', value: '1.0.0'),
              _InfoRow(label: 'رقم البناء', value: '1'),
              _InfoRow(label: 'Flutter SDK', value: '3.35.6'),
              _InfoRow(label: 'Dart SDK', value: '3.9.2'),
            ],
          ),

          const SizedBox(height: 16),

          // ── إحصائيات قاعدة البيانات ───────────────────────────────────────
          Text(
            'إحصائيات قاعدة البيانات',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          dbStatsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('خطأ في تحميل الإحصائيات: $e'),
            ),
            data: (stats) => _InfoSection(
              title: '',
              showTitle: false,
              children: [
                _InfoRow(
                  label: 'نسخة الـ Schema',
                  value: 'الإصدار ${stats.schemaVersion}',
                ),
                _InfoRow(
                  label: 'المستخدمون',
                  value: '${stats.usersCount} حساب',
                ),
                _InfoRow(
                  label: 'السندات',
                  value: '${stats.vouchersCount} سند',
                ),
                _InfoRow(
                  label: 'الخزائن',
                  value: '${stats.treasuriesCount} خزينة',
                ),
                _InfoRow(
                  label: 'الموظفون',
                  value: '${stats.employeesCount} موظف',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── معلومات المستخدم الحالي ────────────────────────────────────────
          if (currentUser != null)
            _InfoSection(
              title: 'الجلسة الحالية',
              children: [
                _InfoRow(label: 'المستخدم', value: currentUser.fullName),
                _InfoRow(label: 'الدور', value: currentUser.roleDisplayName),
                _InfoRow(label: 'اسم الدخول', value: '@${currentUser.username}'),
                if (currentUser.lastLoginAt != null)
                  _InfoRow(
                    label: 'آخر دخول',
                    value: _formatDate(currentUser.lastLoginAt!),
                  ),
              ],
            ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // ── نسخ معلومات التشخيص ────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text: _buildDiagnosticsText(dbStatsAsync.valueOrNull),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ تم نسخ معلومات التشخيص')),
              );
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('نسخ معلومات التشخيص'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          const SizedBox(height: 12),

          // ── تصفير الحسابات (للتطوير) ───────────────────────────────────────
          // عملية كارثية — super_admin فقط عبر نظام الصلاحيات المركزي.
          // (كان الفحص `role == 'admin'` مقلوباً: يمنع super_admin ويسمح لـ admin)
          if (currentUser != null &&
              currentUser.can(AppPermission.resetFinancialData)) ...[
            FilledButton.icon(
              onPressed: () => _confirmResetData(context, ref),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('تصفير الحسابات (للتطوير)'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── تسجيل الخروج ───────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout_outlined),
            label: const Text('تسجيل الخروج'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  /// تأكيد تصفير الحسابات
  Future<void> _confirmResetData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصفير الحسابات'),
        content: const Text(
          'تحذير خطير: سيتم مسح جميع السندات المالية وتصفير أرصدة الخزائن بالكامل!\n\n'
          'هل أنت متأكد من هذا الإجراء؟ لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، مسح وتصفير'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(appDatabaseProvider);
      try {
        await db.resetFinancialData();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ تم تصفير جميع السندات والأرصدة بنجاح')),
          );
          // إعادة تحميل الإحصائيات
          ref.invalidate(_dbStatsProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: $e')),
          );
        }
      }
    }
  }

  /// تأكيد تسجيل الخروج
  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من الحساب الحالي؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
      // GoRouter سيُعيد التوجيه تلقائياً لـ /login عبر redirect guard
    }
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// بناء نص معلومات التشخيص
  String _buildDiagnosticsText(_DbStats? stats) {
    return '''
نظام إدارة المبيعات — تقرير التشخيص
=====================================
الإصدار: 1.0.0 (بناء: 1)
Flutter: 3.35.6 | Dart: 3.9.2
قاعدة البيانات: Schema v${stats?.schemaVersion ?? 'N/A'}
المستخدمون: ${stats?.usersCount ?? 'N/A'}
السندات: ${stats?.vouchersCount ?? 'N/A'}
الخزائن: ${stats?.treasuriesCount ?? 'N/A'}
الموظفون: ${stats?.employeesCount ?? 'N/A'}
التاريخ: ${DateTime.now().toIso8601String()}
''';
  }
}

// ── مجموعة معلومات ────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool showTitle;

  const _InfoSection({
    required this.title,
    required this.children,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle && title.isNotEmpty) ...[
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: theme.colorScheme.outlineVariant,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── صف معلومة واحدة ───────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}
