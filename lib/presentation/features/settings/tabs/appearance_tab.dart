// ─────────────────────────────────────────────────────────────────────────────
// appearance_tab.dart — قسم المظهر
//
// يتيح للمستخدم:
//   - اختيار وضع المظهر: تلقائي / فاتح / داكن
//   - اختيار اللون الأساسي من 8 ألوان محددة مسبقاً
//
// الحفظ الفوري:
//   - 'theme'         → 'system' | 'light' | 'dark'
//   - 'primary_color' → Color.toARGB32() كنص
//
// التأثير الفوري:
//   main.dart يراقب primaryColorSeedProvider و appThemeModeProvider
//   ويُعيد بناء MaterialApp فور التغيير
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_settings_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/settings_provider.dart';
import 'settings_shared.dart';

/// قسم إعدادات المظهر
class AppearanceTab extends ConsumerWidget {
  const AppearanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // قراءة الإعدادات الحالية من الـ Streams
    final themeModeRaw = ref.watch(appThemeModeProvider).valueOrNull ?? 'system';
    final colorRaw = ref.watch(primaryColorSeedProvider).valueOrNull;

    // تحليل قيمة اللون المخزَّنة — استخدم الافتراضي إذا كانت القيمة غير صالحة
    final currentColorValue = int.tryParse(colorRaw ?? '') ??
        AppColors.primarySeed.toARGB32();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── عنوان القسم ────────────────────────────────────────────────────
          const SettingsSectionHeader(
            icon: Icons.palette_outlined,
            title: 'المظهر',
            subtitle: 'الثيم واللون الأساسي للتطبيق',
          ),

          const SizedBox(height: 32),

          // ── وضع المظهر ─────────────────────────────────────────────────────
          Text(
            'وضع العرض',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'يُطبَّق التغيير فوراً دون إعادة تشغيل',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          // بطاقات وضع المظهر الثلاثة
          Row(
            children: [
              _ThemeModeCard(
                label: 'تلقائي',
                icon: Icons.brightness_auto_outlined,
                value: 'system',
                selected: themeModeRaw == 'system',
                onTap: () => _saveThemeMode(ref, 'system'),
              ),
              const SizedBox(width: 12),
              _ThemeModeCard(
                label: 'فاتح',
                icon: Icons.light_mode_outlined,
                value: 'light',
                selected: themeModeRaw == 'light',
                onTap: () => _saveThemeMode(ref, 'light'),
              ),
              const SizedBox(width: 12),
              _ThemeModeCard(
                label: 'داكن',
                icon: Icons.dark_mode_outlined,
                value: 'dark',
                selected: themeModeRaw == 'dark',
                onTap: () => _saveThemeMode(ref, 'dark'),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // ── اللون الأساسي ──────────────────────────────────────────────────
          Text(
            'اللون الأساسي',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'يُطبَّق على الأزرار والعناصر البارزة عبر التطبيق',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          // شبكة ألوان البذور
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AppTheme.availableSeedColors.entries.map((entry) {
              final colorValue = entry.key;
              final colorName = entry.value;
              final isSelected = colorValue == currentColorValue;

              return _ColorSwatch(
                colorValue: colorValue,
                label: colorName,
                isSelected: isSelected,
                onTap: () => _savePrimaryColor(ref, colorValue),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // معاينة اللون المحدد
          _ColorPreview(selectedColorValue: currentColorValue),
        ],
      ),
    );
  }

  /// حفظ وضع المظهر في الإعدادات
  Future<void> _saveThemeMode(WidgetRef ref, String mode) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setString(AppSettingsKeys.themeMode, mode);
  }

  /// حفظ لون البذرة المختار في الإعدادات
  Future<void> _savePrimaryColor(WidgetRef ref, int colorValue) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setString(AppSettingsKeys.primaryColor, colorValue.toString());
  }
}

// ── بطاقة وضع المظهر ──────────────────────────────────────────────────────────

class _ThemeModeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeModeCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: selected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── دائرة اللون (اختيار لون البذرة) ──────────────────────────────────────────

class _ColorSwatch extends StatelessWidget {
  final int colorValue;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.colorValue,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);

    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 22)
              : null,
        ),
      ),
    );
  }
}

// ── معاينة اللون المحدد ────────────────────────────────────────────────────────

class _ColorPreview extends StatelessWidget {
  final int selectedColorValue;

  const _ColorPreview({required this.selectedColorValue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorName =
        AppTheme.availableSeedColors[selectedColorValue] ?? 'مخصص';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Color(selectedColorValue),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اللون المحدد: $colorName',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'يُطبَّق فوراً عند الاختيار',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: Color(selectedColorValue),
              minimumSize: const Size(80, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('معاينة'),
          ),
        ],
      ),
    );
  }
}
