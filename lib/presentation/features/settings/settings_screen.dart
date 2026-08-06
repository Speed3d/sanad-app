// ─────────────────────────────────────────────────────────────────────────────
// settings_screen.dart — شاشة الإعدادات الرئيسية (8 أقسام)
//
// تخطيطان:
//   ديسكتوب (>= 768px): لوحة يمنى (قائمة الأقسام) + لوحة يسرى (المحتوى)
//   موبايل (< 768px):   قائمة الأقسام — اختيار قسم → عرضه كاملاً
//
// الأقسام الثمانية:
//   0. بيانات الشركة     — الاسم + الشعار
//   1. المظهر            — الثيم + اللون الأساسي
//   2. اللغة والتنسيق   — العربية / الإنجليزية
//   3. العملة والأسعار  — IQD/USD + سعر الصرف
//   4. الأمان            — تغيير كلمة المرور + القفل التلقائي
//   5. المستخدمون        — إدارة الحسابات والصلاحيات
//   6. النسخ الاحتياطي  — إعدادات الحفظ التلقائي
//   7. معلومات النظام    — الإصدار + إحصائيات قاعدة البيانات
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tabs/company_tab.dart';
import 'tabs/appearance_tab.dart';
import 'tabs/language_tab.dart';
import 'tabs/currency_tab.dart';
import 'tabs/security_tab.dart';
import 'tabs/users_tab.dart';
import 'tabs/backup_tab.dart';
import 'tabs/system_info_tab.dart';

// ── بيانات قسم الإعدادات ──────────────────────────────────────────────────────

/// نموذج بيانات قسم واحد في قائمة الإعدادات
class _SettingsSection {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function() builder;

  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });
}

/// الأقسام الثمانية مرتَّبة حسب الأهمية
final List<_SettingsSection> _sections = [
  _SettingsSection(
    title: 'بيانات الشركة',
    subtitle: 'الاسم التجاري والشعار',
    icon: Icons.business_outlined,
    builder: () => const CompanyTab(),
  ),
  _SettingsSection(
    title: 'المظهر',
    subtitle: 'الثيم واللون الأساسي',
    icon: Icons.palette_outlined,
    builder: () => const AppearanceTab(),
  ),
  _SettingsSection(
    title: 'اللغة والتنسيق',
    subtitle: 'العربية / الإنجليزية',
    icon: Icons.language_outlined,
    builder: () => const LanguageTab(),
  ),
  _SettingsSection(
    title: 'العملة والأسعار',
    subtitle: 'IQD / USD وسعر الصرف',
    icon: Icons.currency_exchange_outlined,
    builder: () => const CurrencyTab(),
  ),
  _SettingsSection(
    title: 'الأمان',
    subtitle: 'كلمة المرور والقفل التلقائي',
    icon: Icons.security_outlined,
    builder: () => const SecurityTab(),
  ),
  _SettingsSection(
    title: 'المستخدمون',
    subtitle: 'الحسابات والصلاحيات',
    icon: Icons.manage_accounts_outlined,
    builder: () => const UsersTab(),
  ),
  _SettingsSection(
    title: 'النسخ الاحتياطي',
    subtitle: 'الحفظ التلقائي والاستعادة',
    icon: Icons.backup_outlined,
    builder: () => const BackupTab(),
  ),
  _SettingsSection(
    title: 'معلومات النظام',
    subtitle: 'الإصدار وإحصائيات قاعدة البيانات',
    icon: Icons.info_outline,
    builder: () => const SystemInfoTab(),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// شاشة الإعدادات الرئيسية
// ─────────────────────────────────────────────────────────────────────────────

/// شاشة الإعدادات — تتكيّف مع حجم الشاشة (Responsive)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// رقم القسم المحدد حالياً
  /// null على الموبايل = نعرض قائمة الأقسام (لم يُختَر بعد)
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    // على الديسكتوب نختار القسم الأول افتراضياً تلقائياً
    if (isDesktop && _selectedIndex == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() => _selectedIndex = 0),
      );
    }

    return isDesktop
        ? _buildDesktopLayout(context)
        : _buildMobileLayout(context);
  }

  // ── تخطيط الديسكتوب ────────────────────────────────────────────────────────

  Widget _buildDesktopLayout(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIdx = _selectedIndex ?? 0;

    return Scaffold(
      body: Row(
        children: [
          // ── الشريط الجانبي الأيسر (قائمة الأقسام) ───────────────────────
          // ملاحظة: في RTL الأيسر هو الـ trailing — وضعناه هنا لأنه لوحة ثانوية
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(
                left: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // عنوان الشاشة داخل الشريط الجانبي
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'الإعدادات',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Divider(height: 1),
                // قائمة الأقسام القابلة للتمرير
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _sections.length,
                    itemBuilder: (context, index) => _SectionTile(
                      section: _sections[index],
                      isSelected: index == selectedIdx,
                      onTap: () => setState(() => _selectedIndex = index),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── محتوى القسم المحدد ────────────────────────────────────────────
          Expanded(
            child: _sections[selectedIdx].builder(),
          ),
        ],
      ),
    );
  }

  // ── تخطيط الموبايل ─────────────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context) {
    // لم يُختَر قسم → عرض قائمة الأقسام
    if (_selectedIndex == null) {
      return _buildMobileList(context);
    }
    // تم اختيار قسم → عرض محتواه مع AppBar
    return _buildMobileSection(context, _selectedIndex!);
  }

  Widget _buildMobileList(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final section = _sections[index];
          return Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  section.icon,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              title: Text(
                section.title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(section.subtitle),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => setState(() => _selectedIndex = index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileSection(BuildContext context, int index) {
    final section = _sections[index];
    return Scaffold(
      appBar: AppBar(
        title: Text(section.title),
        centerTitle: false,
        leading: BackButton(
          onPressed: () => setState(() => _selectedIndex = null),
        ),
      ),
      body: section.builder(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// عنصر قسم واحد في الشريط الجانبي (ديسكتوب)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTile extends StatelessWidget {
  final _SettingsSection section;
  final bool isSelected;
  final VoidCallback onTap;

  const _SectionTile({
    required this.section,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  section.icon,
                  size: 20,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
