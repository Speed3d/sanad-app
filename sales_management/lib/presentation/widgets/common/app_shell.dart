// ─────────────────────────────────────────────────────────────────────────────
// app_shell.dart — الإطار الرئيسي للتطبيق
//
// يغلّف جميع الشاشات الداخلية ويوفر:
//   - NavigationRail على الشاشات الكبيرة (عرض >= 768px) — الويب والتابلت
//   - NavigationBar في الأسفل على الموبايل (عرض < 768px)
//   - AppBar مشترك مع اسم الصفحة الحالية
//
// الـ breakpoint:
//   768px — حد الفصل بين تخطيط الموبايل والشاشات الكبيرة
//
// الـ child:
//   الصفحة الحالية التي يعرضها go_router
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import 'global_search_dialog.dart';

/// نقطة الفصل بين تخطيط الموبايل والشاشات الكبيرة
const double _kMobileBreakpoint = 768.0;

/// عنصر تنقل في الـ Navigation
class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

/// قائمة عناصر التنقل الرئيسية
// ملاحظة: لا يمكن أن تكون const لأن IconData لا تدعم const في بعض الإصدارات
final List<_NavItem> _navItems = [
  _NavItem(
    label: 'لوحة التحكم',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    route: AppRoutes.dashboard,
  ),
  _NavItem(
    label: 'السندات',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    route: AppRoutes.vouchers,
  ),
  _NavItem(
    label: 'الخزائن',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet,
    route: AppRoutes.treasury,
  ),
  _NavItem(
    label: 'الموظفون',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    route: AppRoutes.employees,
  ),
  _NavItem(
    label: 'المقاولون',
    icon: Icons.construction_outlined,
    selectedIcon: Icons.construction,
    route: AppRoutes.contractors,
  ),
  _NavItem(
    label: 'الشركاء',
    icon: Icons.handshake_outlined,
    selectedIcon: Icons.handshake,
    route: AppRoutes.partners,
  ),
  _NavItem(
    label: 'التقارير',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
    route: AppRoutes.reports,
  ),
  _NavItem(
    label: 'السنوات المالية',
    icon: Icons.date_range_outlined,
    selectedIcon: Icons.date_range,
    route: AppRoutes.fiscal,
  ),
  _NavItem(
    label: 'الإعدادات',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    route: AppRoutes.settings,
  ),
];

/// الإطار الرئيسي للتطبيق
class AppShell extends StatelessWidget {
  /// الصفحة الحالية (تأتي من go_router ShellRoute)
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kMobileBreakpoint;

    if (isDesktop) {
      // ── تخطيط الشاشات الكبيرة (ويب / تابلت) ─────────────────────────
      return _DesktopShell(child: child);
    } else {
      // ── تخطيط الموبايل ────────────────────────────────────────────────
      return _MobileShell(child: child);
    }
  }

  /// تحديد index العنصر المحدد حسب المسار الحالي
  static int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) return i;
    }
    return 0;
  }
}

// ── تخطيط الشاشات الكبيرة ─────────────────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  final Widget child;
  const _DesktopShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = AppShell._selectedIndex(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // ── NavigationRail الجانبية ──────────────────────────────────
          NavigationRail(
            // إظهار التسميات دائماً على الشاشات الكبيرة
            labelType: NavigationRailLabelType.all,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              context.go(_navItems[index].route);
            },
            // اللوجو / عنوان التطبيق في الأعلى
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            // أزرار إضافية في الأسفل (الخروج)
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  // زر البحث الشامل
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    tooltip: 'البحث الشامل',
                    onPressed: () => showGlobalSearchDialog(context),
                  ),
                  // زر سجل المراجعة
                  IconButton(
                    icon: const Icon(Icons.history),
                    tooltip: 'سجل المراجعة',
                    onPressed: () => context.go(AppRoutes.audit),
                  ),
                ],
              ),
            ),
            destinations: _navItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ))
                .toList(),
          ),

          // خط فاصل رفيع
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant,
          ),

          // ── محتوى الصفحة ────────────────────────────────────────────
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── تخطيط الموبايل ────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  final Widget child;
  const _MobileShell({required this.child});

  // عناصر الـ NavigationBar للموبايل (5 عناصر فقط) — تُبنى من _navItems
  List<_NavItem> get _mobileItems => [
    _navItems[0], // Dashboard
    _navItems[1], // Vouchers
    _navItems[2], // Treasury
    _navItems[3], // Employees
    _navItems[7], // Settings
  ];

  @override
  Widget build(BuildContext context) {
    // حساب index للـ NavigationBar (5 عناصر فقط)
    final location = GoRouterState.of(context).matchedLocation;
    int selectedIndex = 0;
    for (var i = 0; i < _mobileItems.length; i++) {
      if (location.startsWith(_mobileItems[i].route)) {
        selectedIndex = i;
        break;
      }
    }

    return Scaffold(
      body: child,
      // NavigationBar في الأسفل
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          context.go(_mobileItems[index].route);
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
