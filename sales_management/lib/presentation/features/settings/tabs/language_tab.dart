// ─────────────────────────────────────────────────────────────────────────────
// language_tab.dart — قسم اللغة والتنسيق
//
// يتيح للمستخدم اختيار لغة الواجهة: العربية (RTL) أو الإنجليزية (LTR)
// التأثير فوري — main.dart يراقب appLanguageProvider ويُحدّث الـ locale
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_settings_keys.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/settings_provider.dart';
import 'settings_shared.dart';

/// قسم إعدادات اللغة
class LanguageTab extends ConsumerWidget {
  const LanguageTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentLang = ref.watch(appLanguageProvider).valueOrNull ?? 'ar';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader(
            icon: Icons.language_outlined,
            title: 'اللغة والتنسيق',
            subtitle: 'لغة واجهة التطبيق واتجاه النص',
          ),

          const SizedBox(height: 32),

          Text(
            'لغة الواجهة',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'يُطبَّق التغيير فوراً دون إعادة تشغيل التطبيق',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          _LanguageCard(
            language: 'ar',
            title: 'العربية',
            subtitle: 'من اليمين إلى اليسار (RTL)',
            flagEmoji: '🇮🇶',
            isSelected: currentLang == 'ar',
            onTap: () => _saveLanguage(ref, 'ar'),
          ),

          const SizedBox(height: 12),

          _LanguageCard(
            language: 'en',
            title: 'English',
            subtitle: 'Left to Right (LTR)',
            flagEmoji: '🇺🇸',
            isSelected: currentLang == 'en',
            onTap: () => _saveLanguage(ref, 'en'),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          Text(
            'تنسيق الأرقام والتواريخ',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          _FormatComparisonTable(currentLang: currentLang),
        ],
      ),
    );
  }

  Future<void> _saveLanguage(WidgetRef ref, String langCode) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setString(AppSettingsKeys.language, langCode);
  }
}

// ── بطاقة اختيار اللغة ────────────────────────────────────────────────────────

class _LanguageCard extends StatelessWidget {
  final String language;
  final String title;
  final String subtitle;
  final String flagEmoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.title,
    required this.subtitle,
    required this.flagEmoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flagEmoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ── جدول مقارنة التنسيق ───────────────────────────────────────────────────────

class _FormatComparisonTable extends StatelessWidget {
  final String currentLang;

  const _FormatComparisonTable({required this.currentLang});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rows = const [
      _FormatRow('التاريخ', '٢٠٢٤/٠١/١٥', '2024/01/15'),
      _FormatRow('الوقت', '٠٩:٣٠ صباحاً', '09:30 AM'),
      _FormatRow('الأرقام الكبيرة', '١،٢٥٠،٠٠٠', '1,250,000'),
      _FormatRow('العملة', '١،٢٥٠ د.ع', '1,250 IQD'),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Table(
        border: TableBorder.symmetric(
          inside: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.5),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            children: [
              _TableCell('النوع', isHeader: true),
              _TableCell('العربية', isHeader: true,
                  isHighlighted: currentLang == 'ar'),
              _TableCell('English', isHeader: true,
                  isHighlighted: currentLang == 'en'),
            ],
          ),
          ...rows.map(
            (row) => TableRow(children: [
              _TableCell(row.label),
              _TableCell(row.arabic, isHighlighted: currentLang == 'ar'),
              _TableCell(row.english, isHighlighted: currentLang == 'en'),
            ]),
          ),
        ],
      ),
    );
  }
}

class _FormatRow {
  final String label;
  final String arabic;
  final String english;
  const _FormatRow(this.label, this.arabic, this.english);
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isHighlighted;

  const _TableCell(this.text, {this.isHeader = false, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight:
              isHeader || isHighlighted ? FontWeight.w600 : null,
          color: isHighlighted ? theme.colorScheme.primary : null,
        ),
      ),
    );
  }
}
