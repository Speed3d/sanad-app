// ─────────────────────────────────────────────────────────────────────────────
// app_shell.dart — إطار التطبيق الرئيسي والتنقل (Fintech Shell & Sidebar)
//
// يغلّف جميع شاشات التطبيق ويوفر:
//   - الشريط الجانبي المطور (Sidebar بعرض ثابت 256px) للشاشات الكبيرة
//   - زر تحويل الوضع الليلي/الفاتح التفاعلي في تذييل السايدبار
//   - الشريط العلوي الموحد (Topbar 72px) مع التاريخ واسم الشاشة والـ Avatar
//   - التنقل السفلي المطور للموبايل
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';
import 'global_search_dialog.dart';

/// نقطة الفصل بين تخطيط الموبايل والشاشات الكبيرة (ويب / تابلت)
const double _kMobileBreakpoint = 880.0;

/// عنصر تنقل في الشريط الجانبي
class _NavItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const _NavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

/// قائمة عناصر التنقل الرئيسية الـ 9
final List<_NavItem> _navItems = [
  const _NavItem(
    id: 'dashboard',
    label: 'لوحة التحكم',
    icon: Icons.grid_view_rounded,
    selectedIcon: Icons.grid_view_rounded,
    route: AppRoutes.dashboard,
  ),
  const _NavItem(
    id: 'vouchers',
    label: 'السندات',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
    route: AppRoutes.vouchers,
  ),
  const _NavItem(
    id: 'treasury',
    label: 'الخزائن',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet_rounded,
    route: AppRoutes.treasury,
  ),
  const _NavItem(
    id: 'employees',
    label: 'الموظفون',
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
    route: AppRoutes.employees,
  ),
  const _NavItem(
    id: 'contractors',
    label: 'المقاولون',
    icon: Icons.construction_outlined,
    selectedIcon: Icons.construction_rounded,
    route: AppRoutes.contractors,
  ),
  const _NavItem(
    id: 'partners',
    label: 'الشركاء',
    icon: Icons.handshake_outlined,
    selectedIcon: Icons.handshake_rounded,
    route: AppRoutes.partners,
  ),
  const _NavItem(
    id: 'reports',
    label: 'التقارير',
    icon: Icons.bar_chart_rounded,
    selectedIcon: Icons.bar_chart_rounded,
    route: AppRoutes.reports,
  ),
  const _NavItem(
    id: 'fiscal',
    label: 'السنوات المالية',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
    route: AppRoutes.fiscal,
  ),
  const _NavItem(
    id: 'settings',
    label: 'الإعدادات',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    route: AppRoutes.settings,
  ),
];

/// الإطار الرئيسي للتطبيق
class AppShell extends ConsumerWidget {
  /// الصفحة الحالية التي يعرضها go_router ShellRoute
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kMobileBreakpoint;

    if (isDesktop) {
      return _DesktopShell(child: child);
    } else {
      return _MobileShell(child: child);
    }
  }

  /// حساب index العناصر النشطة
  static int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) return i;
    }
    return 0;
  }

  /// تنقل آمن يمنع تكرار التنقل لنفس المسار ويُؤجّل التوجيه لإطار ما بعد الرسم
  static void safeNavigate(BuildContext context, String route) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == route) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go(route);
      }
    });
  }
}

// ── تخطيط الشاشات الكبيرة (Desktop Shell) ─────────────────────────────────

class _DesktopShell extends ConsumerWidget {
  final Widget child;
  const _DesktopShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = AppShell._selectedIndex(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final companyNameAsync = ref.watch(companyNameProvider);
    final companyName = companyNameAsync.valueOrNull ?? 'شركة إدارة المبيعات';

    // سجل المراجعة متاح لمن يملك صلاحية عرضه فقط (admin فأعلى)
    final currentUser = ref.watch(authNotifierProvider.notifier).currentUser;
    final canViewAudit =
        currentUser != null && currentUser.can(AppPermission.viewAudit);

    return Scaffold(
      body: Row(
        children: [
          // ── 1. الشريط الجانبي المطور (Sidebar 256px) ───────────────────────
          Container(
            width: 256,
            color: isDark ? AppColors.navySidebarDark : AppColors.navySidebarLight,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── رأس الشريط الجانبي (اللوجو واسم الشركة) ─────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, right: 4, left: 4),
                  child: Row(
                    children: [
                      // شعار الشركة الدائري
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border.all(
                            color: const Color(0xFFE0BC66).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.account_balance_rounded,
                            color: Color(0xFFF5D98B),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // اسم الشركة والفرع
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              companyName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF5F1E6),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'إدارة المبيعات والخزينة',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE0BC66),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── قائمة التصفح الـ 9 ─────────────────────────────────────
                Expanded(
                  child: ListView.separated(
                    itemCount: _navItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final isActive = index == selectedIndex;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => AppShell.safeNavigate(context, item.route),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFE0BC66).withValues(alpha: 0.14)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  child: Icon(
                                    isActive ? item.selectedIcon : item.icon,
                                    size: 18,
                                    color: isActive
                                        ? const Color(0xFFF5D98B)
                                        : Colors.white.withValues(alpha: 0.72),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                                    color: isActive
                                        ? const Color(0xFFF5D98B)
                                        : Colors.white.withValues(alpha: 0.72),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── تذييل الشريط الجانبي (سجل المراجعة ومفتاح الثيم) ────────
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                  ),
                  child: Column(
                    children: [
                      // زر سجل المراجعة — يظهر لمن يملك صلاحية العرض فقط
                      if (canViewAudit) ...[
                        InkWell(
                          onTap: () =>
                              AppShell.safeNavigate(context, AppRoutes.audit),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  child: Icon(
                                    Icons.history_rounded,
                                    size: 18,
                                    color: Colors.white.withValues(alpha: 0.72),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'سجل المراجعة',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.72),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],

                      // مفتاح الوضع الليلي (Dark Mode Switch)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'الوضع الليلي',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _toggleTheme(ref, isDark),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 46,
                                height: 25,
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  color: isDark
                                      ? const Color(0xFFE0BC66).withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.15),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 200),
                                  alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFE0BC66),
                                    ),
                                    child: Icon(
                                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                      size: 12,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 2. المحتوى الرئيسي مع الشريط العلوي Topbar ───────────────────────
          Expanded(
            child: Column(
              children: [
                // الشريط العلوي (Topbar 72px)
                _DesktopTopbar(
                  title: _navItems[selectedIndex].label,
                  isDashboard: selectedIndex == 0,
                ),
                // محتوى الشاشة الفعلي
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// تبديل الوضع الليلي والنهاري
  Future<void> _toggleTheme(WidgetRef ref, bool isDark) async {
    final repo = ref.read(settingsRepositoryProvider);
    final newMode = isDark ? 'light' : 'dark';
    await repo.setString('theme', newMode);
  }
}

// ── الشريط العلوي للشاشات الكبيرة (Desktop Topbar 72px) ────────────────────

class _DesktopTopbar extends StatelessWidget {
  final String title;
  final bool isDashboard;

  const _DesktopTopbar({
    required this.title,
    required this.isDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final todayLabel = _formatTodayArabicDate();

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // عنوان الشاشة والتاريخ
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              if (isDashboard) ...[
                const SizedBox(height: 2),
                Text(
                  todayLabel,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),

          // الأزرار والتنبيهات والـ Avatar
          Row(
            children: [
              // زر البحث الشامل
              _TopbarIconButton(
                icon: Icons.search_rounded,
                tooltip: 'البحث الشامل',
                onPressed: () => showGlobalSearchDialog(context),
              ),
              const SizedBox(width: 10),

              // زر التنبيهات
              _TopbarIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'التنبيهات',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لا توجد إشعارات غير مقروءة حالياً'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 14),

              // صورة المستخدم الشخصية (Avatar)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 22,
                    color: Color(0xFFE0BC66),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// تنسيق تاريخ اليوم بالعربية (مثل: "الأربعاء، 6 أغسطس 2026")
  static String _formatTodayArabicDate() {
    final now = DateTime.now();
    final dayNames = [
      'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
    ];
    final monthNames = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];

    final dayName = dayNames[(now.weekday - 1) % 7];
    final monthName = monthNames[(now.month - 1) % 12];

    return '$dayName، ${now.day} $monthName ${now.year}';
  }
}

/// زر أيقونة مربع للشريط العلوي
class _TopbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _TopbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
          ),
        ),
      ),
    );
  }
}

// ── تخطيط الموبايل (Mobile Shell) ─────────────────────────────────────────

class _MobileShell extends ConsumerWidget {
  final Widget child;
  const _MobileShell({required this.child});

  List<_NavItem> get _mobileItems => [
    _navItems[0], // Dashboard
    _navItems[1], // Vouchers
    _navItems[2], // Treasury
    _navItems[3], // Employees
    _navItems[8], // Settings
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    int selectedIndex = 0;
    for (var i = 0; i < _mobileItems.length; i++) {
      if (location.startsWith(_mobileItems[i].route)) {
        selectedIndex = i;
        break;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_mobileItems[selectedIndex].label),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () {
              final repo = ref.read(settingsRepositoryProvider);
              repo.setString('theme', isDark ? 'light' : 'dark');
            },
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          AppShell.safeNavigate(context, _mobileItems[index].route);
        },
        destinations: _mobileItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

