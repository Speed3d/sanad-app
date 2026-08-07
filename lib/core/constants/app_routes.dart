// ─────────────────────────────────────────────────────────────────────────────
// app_routes.dart — ثوابت مسارات التنقل
//
// جميع مسارات التطبيق مُعرَّفة هنا كـ constants.
// هذا يمنع الأخطاء الإملائية ويسهّل إعادة التسمية.
//
// هيكل المسارات:
//   /splash              — شاشة البداية
//   /first-run           — شاشة الإعداد الأول (عند أول تشغيل)
//   /login               — تسجيل الدخول
//   /                    — Shell Route (الإطار الرئيسي مع Navigation Rail)
//     /dashboard          — لوحة التحكم
//     /vouchers           — قائمة السندات
//       /vouchers/sarf    — سند الصرف
//       /vouchers/kabd    — سند القبض
//     /treasury           — الخزائن
//     /advances           — سلف المشاريع
//       /advances/:id     — مراجعة مسودة سلفة أو عرض تفاصيلها
//     /employees          — الموظفون
//     /contractors        — المقاولون
//     /partners           — الشركاء
//     /reports            — التقارير
//     /fiscal             — السنوات المالية
//     /backup             — النسخ الاحتياطي
//     /settings           — الإعدادات
//     /audit              — سجل المراجعة
// ─────────────────────────────────────────────────────────────────────────────

/// ثوابت مسارات التطبيق
abstract final class AppRoutes {
  // ── مسارات خارج الـ Shell (لا تحتوي Navigation) ──────────────────────────

  /// شاشة البداية (Splash)
  static const String splash = '/splash';

  /// شاشة الإعداد الأول (يظهر مرة واحدة فقط)
  static const String firstRun = '/first-run';

  /// شاشة تسجيل الدخول
  static const String login = '/login';

  // ── المسارات داخل الـ Shell (تحتوي Navigation Rail/Bar) ─────────────────

  /// الجذر — يُعيد توجيه إلى dashboard
  static const String root = '/';

  /// لوحة التحكم
  static const String dashboard = '/dashboard';

  /// قائمة السندات
  static const String vouchers = '/vouchers';

  /// سند الصرف (إنشاء جديد)
  static const String voucherSarf = '/vouchers/sarf';

  /// سند الصرف (تعديل) — :id = معرّف السند
  static const String voucherSarfEdit = '/vouchers/sarf/:id';

  /// سند القبض (إنشاء جديد)
  static const String voucherKabd = '/vouchers/kabd';

  /// سند التحويل
  static const String voucherTransfer = '/vouchers/transfer';

  /// سند القبض (تعديل) — :id = معرّف السند
  static const String voucherKabdEdit = '/vouchers/kabd/:id';

  /// الخزائن
  static const String treasury = '/treasury';

  /// تفاصيل خزينة — :id = معرّف الخزينة
  static const String treasuryDetail = '/treasury/:id';

  /// الموظفون
  static const String employees = '/employees';

  /// تفاصيل موظف — :id = معرّف الموظف
  static const String employeeDetail = '/employees/:id';

  /// سلف الموظفين
  static const String loans = '/employees/loans';

  /// الرواتب
  static const String salaries = '/employees/salaries';

  /// المقاولون
  static const String contractors = '/contractors';

  /// تفاصيل مقاول — :id = معرّف المقاول
  static const String contractorDetail = '/contractors/:id';

  /// الشركاء
  static const String partners = '/partners';

  /// تفاصيل شريك — :id = معرّف الشريك
  static const String partnerDetail = '/partners/:id';

  /// التقارير وكشوف الحساب
  static const String reports = '/reports';

  /// استيراد Excel (مصاريف سلفة)
  static const String excelImport = '/reports/excel-import';

  /// سلف المشاريع (≠ سلف الموظفين في /employees/loans)
  static const String advances = '/advances';

  /// مراجعة/تفاصيل سلفة — :id = معرّف السلفة
  static const String advanceDetail = '/advances/:id';

  /// السنوات المالية
  static const String fiscal = '/fiscal';

  /// النسخ الاحتياطي والاستعادة
  static const String backup = '/backup';

  /// الإعدادات
  static const String settings = '/settings';

  /// إدارة المستخدمين والصلاحيات
  static const String users = '/settings/users';

  /// سجل المراجعة
  static const String audit = '/audit';

  /// صفحة 403 — ليس لديك صلاحية
  static const String forbidden = '/403';

  /// صفحة 404 — الصفحة غير موجودة
  static const String notFound = '/404';
}
