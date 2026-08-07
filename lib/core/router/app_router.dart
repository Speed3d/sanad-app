// ─────────────────────────────────────────────────────────────────────────────
// app_router.dart — إعداد التوجيه الرئيسي (go_router)
//
// يستخدم هذا الملف go_router لإدارة التنقل بين الشاشات.
//
// آلية الحماية (Route Guards):
//   كل طلب تنقل يمر عبر _RouterNotifier.redirect()
//   ┌─ AuthInitial / AuthLoading → انتظار على splash
//   ├─ AuthUnauthenticated(isFirstRun: true) → /first-run
//   ├─ AuthUnauthenticated()                 → /login
//   ├─ AuthAuthenticated + محاولة login/splash → /dashboard
//   └─ AuthAuthenticated + أي مسار محمي      → السماح
//
// refreshListenable:
//   _RouterNotifier يستمع لـ authNotifierProvider
//   وعند تغيير الحالة (دخول/خروج) يُبلّغ GoRouter فيُعيد تقييم الـ redirect
//
// Shell Route:
//   جميع الشاشات الداخلية تُحاط بـ AppShell الذي يحتوي:
//   - NavigationRail (شاشات كبيرة)
//   - NavigationBar  (موبايل)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/app_routes.dart';
import '../auth/permissions.dart';
import '../../domain/models/auth_state.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/features/splash/splash_screen.dart';
import '../../presentation/features/auth/login_screen.dart';
import '../../presentation/features/auth/first_run_screen.dart';
import '../../presentation/features/dashboard/dashboard_screen.dart';
import '../../presentation/features/vouchers/voucher_kabd_screen.dart';
import '../../presentation/features/vouchers/voucher_sarf_screen.dart';
import '../../presentation/features/vouchers/voucher_transfer_screen.dart';
import '../../presentation/features/vouchers/vouchers_list_screen.dart';
import '../../presentation/features/treasury/treasuries_screen.dart';
import '../../presentation/features/employees/employees_screen.dart';
import '../../presentation/features/contractors/contractors_screen.dart';
import '../../presentation/features/partners/partners_screen.dart';
import '../../presentation/features/reports/reports_screen.dart';
import '../../presentation/features/excel/excel_import_screen.dart';
import '../../presentation/features/advances/advances_list_screen.dart';
import '../../presentation/features/advances/advance_review_screen.dart';
import '../../presentation/features/fiscal/fiscal_screen.dart';
import '../../presentation/features/backup/backup_screen.dart';
import '../../presentation/features/settings/settings_screen.dart';
import '../../presentation/features/audit/audit_screen.dart';
import '../../presentation/widgets/common/app_shell.dart';
import '../../presentation/widgets/common/error_screen.dart';

part 'app_router.g.dart';

// ── RouterNotifier — الجسر بين Riverpod و GoRouter ─────────────────────────

/// يستمع لتغيرات حالة المصادقة ويُخبر GoRouter بإعادة تقييم الـ redirect
///
/// بدونه لن يتحدث GoRouter عند تسجيل الدخول أو الخروج
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    // الاستماع لتغييرات حالة المصادقة
    _ref.listen<AuthState>(
      authNotifierProvider,
      (previous, next) {
        // إبلاغ GoRouter بأن هناك تغييراً يستوجب إعادة تقييم redirect
        notifyListeners();
      },
    );
  }

  /// منطق الحماية — يُستدعى عند كل تنقل
  ///
  /// يُعيد:
  ///   null    → السماح بالتنقل للمسار المطلوب
  ///   String  → إعادة التوجيه لهذا المسار بدلاً من المطلوب
  String? redirect(GoRouterState routerState) {
    final authState = _ref.read(authNotifierProvider);
    final currentLocation = routerState.matchedLocation;

    // ── Splash: مسموح دائماً (لعرض الأنيميشن الأولية) ──────────────────
    if (currentLocation == AppRoutes.splash) return null;

    // ── جاري التهيئة: العودة لـ Splash لعدم تفليش شاشة غير جاهزة ────────
    if (authState is AuthInitial || authState is AuthLoading) {
      return AppRoutes.splash;
    }

    // ── أول تشغيل: توجيه لشاشة الإعداد ────────────────────────────────
    if (authState is AuthUnauthenticated && authState.isFirstRun) {
      return currentLocation == AppRoutes.firstRun ? null : AppRoutes.firstRun;
    }

    // ── غير مصادَق: السماح فقط لصفحة تسجيل الدخول ──────────────────────
    if (authState is! AuthAuthenticated) {
      if (currentLocation == AppRoutes.login ||
          currentLocation == AppRoutes.firstRun) {
        return null; // السماح بالوصول لصفحتَي الدخول والإعداد
      }
      return AppRoutes.login; // إعادة توجيه لتسجيل الدخول
    }

    // ── مصادَق: منع العودة لصفحات المصادقة ─────────────────────────────
    if (currentLocation == AppRoutes.login ||
        currentLocation == AppRoutes.firstRun) {
      return AppRoutes.dashboard;
    }

    // ── حماية المسارات الحساسة حسب دور المستخدم (RBAC) ─────────────────
    // كل مسار حساس يتطلب صلاحية محددة؛ من لا يملكها يُحوَّل لصفحة 403.
    // هذا هو الحاجز الأقوى لأنه يمنع الوصول للشاشة كاملةً لا مجرد إخفاء زر.
    final required = _routePermission(currentLocation);
    if (required != null && !authState.user.can(required)) {
      return AppRoutes.forbidden;
    }

    // ── السماح لجميع المسارات الأخرى (الشاشات المحمية) ────────────────
    return null;
  }

  /// الصلاحية المطلوبة لمسار معيّن — null إذا كان متاحاً لأي مستخدم مصادَق
  AppPermission? _routePermission(String location) {
    // نستخدم startsWith لتغطية المسارات الفرعية (مثل /reports/excel-import)
    if (location.startsWith(AppRoutes.excelImport)) {
      return AppPermission.importExcel;
    }
    // شاشات السلف: العرض والتحرير بلا أثر مالي — الحاجز الحقيقي على الاعتماد
    // نفسه داخل AdvanceNotifier (postAdvance / postAdvanceWithDeficit)، لا على
    // المسار. حجب المسار كان سيمنع المحاسب من تجهيز المسودة أصلاً.
    if (location.startsWith(AppRoutes.advances)) {
      return AppPermission.prepareAdvance;
    }
    if (location.startsWith(AppRoutes.backup)) {
      return AppPermission.createBackup;
    }
    if (location.startsWith(AppRoutes.audit)) {
      return AppPermission.viewAudit;
    }
    if (location.startsWith(AppRoutes.users)) {
      return AppPermission.manageUsers;
    }
    // ملاحظة: /fiscal غير محمي هنا عمداً — شاشة الفترات المالية تُطبّق
    // صلاحياتها داخلياً بدقة (إغلاق=admin، إعادة فتح/إعادة احتساب=super_admin)،
    // وعرض الفترات مسموح لأي مستخدم. حجب المسار كان سيُنشئ عنصر تنقل معطوباً.
    return null;
  }
}

// ── Provider المولَّد بـ Riverpod Generator ──────────────────────────────────

/// Provider لـ GoRouter — يُستخدَم في MaterialApp.router
@Riverpod(keepAlive: true)
// ignore: deprecated_member_use
GoRouter appRouter(ProviderRef<GoRouter> ref) {
  // إنشاء الـ Notifier الذي يُبلّغ GoRouter عند تغيير حالة المصادقة
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    // المسار الابتدائي — دائماً Splash
    initialLocation: AppRoutes.splash,

    // الجسر بين Riverpod والـ Router: يُحدَّث GoRouter عند تغيير authState
    refreshListenable: notifier,

    // دالة الحماية — تُستدعى عند كل تنقل
    redirect: (context, state) => notifier.redirect(state),

    // تسجيل أخطاء التوجيه في وضع التطوير فقط
    debugLogDiagnostics: true,

    // معالجة أخطاء التوجيه (مسار غير موجود)
    errorBuilder: (context, state) => ErrorScreen(
      error: state.error?.message ?? 'الصفحة غير موجودة',
      is404: true,
    ),

    routes: [
      // ══════════════════════════════════════════════════════════════════
      // مسارات خارج الـ Shell (لا NavigationRail فيها)
      // ══════════════════════════════════════════════════════════════════

      /// شاشة البداية — تظهر للحظة ثم تُعاد التوجيه حسب حالة المصادقة
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      /// شاشة الإعداد الأول (أول تشغيل)
      GoRoute(
        path: AppRoutes.firstRun,
        name: 'first-run',
        builder: (context, state) => const FirstRunScreen(),
      ),

      /// شاشة تسجيل الدخول
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ══════════════════════════════════════════════════════════════════
      // Shell Route — جميع الشاشات الداخلية المحمية
      // تُحاط بـ AppShell الذي يحتوي على NavigationRail/Bar
      // ══════════════════════════════════════════════════════════════════

      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),

        routes: [
          /// لوحة التحكم الرئيسية
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          /// السندات — مع مسارات فرعية للإضافة والتعديل
          GoRoute(
            path: AppRoutes.vouchers,
            name: 'vouchers',
            builder: (context, state) => const VouchersListScreen(),
            routes: [
              /// سند صرف جديد
              GoRoute(
                path: 'sarf',
                name: 'voucher-sarf',
                builder: (context, state) => const VoucherSarfScreen(),
              ),
              /// تعديل سند صرف
              GoRoute(
                path: 'sarf/:id',
                name: 'voucher-sarf-edit',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  return VoucherSarfScreen(editId: id);
                },
              ),
              /// سند قبض جديد
              GoRoute(
                path: 'kabd',
                name: 'voucher-kabd',
                builder: (context, state) => const VoucherKabdScreen(),
              ),
              /// سند التحويل بين الخزائن
              GoRoute(
                path: 'transfer',
                name: 'voucher-transfer',
                builder: (context, state) => const VoucherTransferScreen(),
              ),
              /// تعديل سند قبض
              GoRoute(
                path: 'kabd/:id',
                name: 'voucher-kabd-edit',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  return VoucherKabdScreen(editId: id);
                },
              ),
            ],
          ),

          GoRoute(
            path: AppRoutes.treasury,
            name: 'treasury',
            builder: (context, state) => const TreasuriesScreen(),
          ),
          GoRoute(
            path: AppRoutes.employees,
            name: 'employees',
            builder: (context, state) => const EmployeesScreen(),
          ),
          GoRoute(
            path: AppRoutes.contractors,
            name: 'contractors',
            builder: (context, state) => const ContractorsScreen(),
          ),
          GoRoute(
            path: AppRoutes.partners,
            name: 'partners',
            builder: (context, state) => const PartnersScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.excelImport,
            name: 'excel-import',
            builder: (context, state) => const ExcelImportScreen(),
          ),

          /// سلف المشاريع — القائمة ومراجعة المسودة
          GoRoute(
            path: AppRoutes.advances,
            name: 'advances',
            builder: (context, state) => const AdvancesListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'advance-detail',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const ErrorScreen(
                      error: 'معرّف السلفة غير صحيح',
                      is404: true,
                    );
                  }
                  return AdvanceReviewScreen(advanceId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.fiscal,
            name: 'fiscal',
            builder: (context, state) => const FiscalScreen(),
          ),
          GoRoute(
            path: AppRoutes.backup,
            name: 'backup',
            builder: (context, state) => const BackupScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.audit,
            name: 'audit',
            builder: (context, state) => const AuditScreen(),
          ),
        ],
      ),

      // ══════════════════════════════════════════════════════════════════
      // صفحات الأخطاء
      // ══════════════════════════════════════════════════════════════════

      GoRoute(
        path: AppRoutes.forbidden,
        name: 'forbidden',
        builder: (context, state) => const ErrorScreen(
          error: 'ليس لديك صلاحية للوصول لهذه الصفحة',
          is404: false,
        ),
      ),
      GoRoute(
        path: AppRoutes.notFound,
        name: 'not-found',
        builder: (context, state) => const ErrorScreen(
          error: 'الصفحة المطلوبة غير موجودة',
          is404: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.root,
        redirect: (_, __) => AppRoutes.dashboard,
      ),
    ],
  );
}
