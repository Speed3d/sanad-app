// ─────────────────────────────────────────────────────────────────────────────
// backup_tab.dart — قسم النسخ الاحتياطي
//
// يتيح للمستخدم:
//   - تفعيل/تعطيل النسخ الاحتياطي التلقائي
//   - اختيار تكرار النسخ: يومياً / أسبوعياً / شهرياً
//   - عرض تاريخ آخر نسخة احتياطية
//   - رابط لصفحة النسخ الاحتياطي الكاملة (/backup)
//
// ملاحظة:
//   صفحة /backup تحتوي العمليات الفعلية (إنشاء نسخة، استعادة، رفع Google Drive)
//   هذا القسم هو إعدادات النسخ التلقائي فقط
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_settings_keys.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/settings_provider.dart';
import 'settings_shared.dart';

/// خيارات تكرار النسخ الاحتياطي
const List<_FrequencyOption> _frequencies = [
  _FrequencyOption(days: 1, label: 'يومياً'),
  _FrequencyOption(days: 7, label: 'أسبوعياً'),
  _FrequencyOption(days: 30, label: 'شهرياً'),
];

class _FrequencyOption {
  final int days;
  final String label;
  const _FrequencyOption({required this.days, required this.label});
}

/// قسم إعدادات النسخ الاحتياطي
class BackupTab extends ConsumerStatefulWidget {
  const BackupTab({super.key});

  @override
  ConsumerState<BackupTab> createState() => _BackupTabState();
}

class _BackupTabState extends ConsumerState<BackupTab> {
  bool _autoBackupEnabled = false;
  int _selectedDays = 7; // أسبوعياً افتراضياً
  bool _isSaving = false;
  bool _settingsLoaded = false;

  /// تحميل الإعدادات الحالية من الإعدادات
  Future<void> _loadSettings() async {
    if (_settingsLoaded) return;
    _settingsLoaded = true;

    final repo = ref.read(settingsRepositoryProvider);
    final settings = await repo.getAllSettings();

    if (mounted) {
      setState(() {
        _autoBackupEnabled = settings[AppSettingsKeys.autoBackupEnabled] == 'true';
        _selectedDays =
            int.tryParse(settings[AppSettingsKeys.autoBackupDays] ?? '7') ?? 7;
      });
    }
  }

  /// حفظ إعدادات النسخ الاحتياطي التلقائي
  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.setString(
        AppSettingsKeys.autoBackupEnabled,
        _autoBackupEnabled.toString(),
      );
      await repo.setString(
        AppSettingsKeys.autoBackupDays,
        _selectedDays.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _autoBackupEnabled
                  ? '✓ النسخ الاحتياطي التلقائي مفعَّل (كل ${_frequencyLabel()})'
                  : '✓ تم إيقاف النسخ الاحتياطي التلقائي',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _frequencyLabel() {
    return _frequencies
            .firstWhere(
              (f) => f.days == _selectedDays,
              orElse: () => const _FrequencyOption(days: 7, label: 'أسبوعياً'),
            )
            .label;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // تحميل الإعدادات عند البناء الأول
    _loadSettings();

    // آخر نسخة احتياطية من الإعدادات
    final lastBackupRaw =
        ref.watch(allSettingsProvider).valueOrNull?[AppSettingsKeys.lastBackupDate];
    final lastBackupDate = lastBackupRaw != null
        ? DateTime.tryParse(lastBackupRaw)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── عنوان القسم ────────────────────────────────────────────────────
          const SettingsSectionHeader(
            icon: Icons.backup_outlined,
            title: 'النسخ الاحتياطي',
            subtitle: 'إعدادات الحفظ التلقائي للبيانات',
          ),

          const SizedBox(height: 24),

          // ── آخر نسخة احتياطية ─────────────────────────────────────────────
          _LastBackupCard(lastBackupDate: lastBackupDate),

          const SizedBox(height: 24),

          // ── روابط النسخ الاحتياطي ─────────────────────────────────────────
          Text(
            'إدارة النسخ الاحتياطية',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // زر فتح صفحة النسخ الاحتياطي
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.backup),
            icon: const Icon(Icons.open_in_new_outlined),
            label: const Text('فتح صفحة النسخ الاحتياطي'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // ── النسخ الاحتياطي التلقائي ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'النسخ الاحتياطي التلقائي',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'حفظ نسخة احتياطية تلقائياً بشكل دوري',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _autoBackupEnabled,
                onChanged: (v) => setState(() => _autoBackupEnabled = v),
              ),
            ],
          ),

          // ── التكرار (يظهر فقط عند التفعيل) ───────────────────────────────
          if (_autoBackupEnabled) ...[
            const SizedBox(height: 20),

            Text(
              'تكرار النسخ',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: _frequencies.map((f) {
                return ChoiceChip(
                  label: Text(f.label),
                  selected: f.days == _selectedDays,
                  onSelected: (_) => setState(() => _selectedDays = f.days),
                  selectedColor: theme.colorScheme.primaryContainer,
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ستُحفَظ نسخة احتياطية ${_frequencyLabel()} تلقائياً',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── زر الحفظ ───────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('حفظ الإعدادات'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── بطاقة آخر نسخة ────────────────────────────────────────────────────────────

class _LastBackupCard extends StatelessWidget {
  final DateTime? lastBackupDate;
  const _LastBackupCard({required this.lastBackupDate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String dateText;
    Color bgColor;
    IconData icon;

    if (lastBackupDate == null) {
      dateText = 'لم تُنشَأ نسخة احتياطية بعد';
      bgColor = theme.colorScheme.errorContainer.withValues(alpha: 0.3);
      icon = Icons.warning_amber_outlined;
    } else {
      final diff = DateTime.now().difference(lastBackupDate!);
      final fmt = DateFormat('dd/MM/yyyy — HH:mm');
      dateText = 'آخر نسخة: ${fmt.format(lastBackupDate!)}';

      // تحذير إذا مضى أكثر من 7 أيام
      if (diff.inDays > 7) {
        bgColor = theme.colorScheme.errorContainer.withValues(alpha: 0.3);
        icon = Icons.warning_amber_outlined;
      } else {
        bgColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
        icon = Icons.check_circle_outline;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dateText,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
