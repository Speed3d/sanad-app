// ─────────────────────────────────────────────────────────────────────────────
// permissions.dart — نظام الصلاحيات المركزي (RBAC)
//
// الغرض:
//   مصدر واحد للحقيقة يحدد "من يستطيع فعل ماذا" حسب الدور، بدلاً من تناثر
//   فحوص `role == 'admin'` عبر الشاشات (وهو ما أدى لثغرة الحاجز المقلوب
//   في system_info_tab حيث مُنع super_admin وسُمح لـ admin).
//
// الأدوار (من user_model.dart):
//   super_admin — صلاحيات كاملة، بما فيها العمليات الكارثية (استعادة نسخة،
//                 تصفير الحسابات، إعادة فتح فترة مالية، حذف سجل التدقيق)
//   admin       — إدارة العمليات اليومية (سندات، خزائن، موظفون، تقارير،
//                 استيراد، إنشاء نسخة احتياطية، عرض التدقيق، إغلاق فترة)
//   user        — قراءة وإدخال البيانات فقط (سندات، كيانات) بلا عمليات مدمّرة
//
// الاستخدام:
//   if (user.can(AppPermission.restoreBackup)) { ... }
//   final gate = ref.watch(permissionProvider);  // من permission_provider.dart
// ─────────────────────────────────────────────────────────────────────────────

import '../../domain/models/user_model.dart';

/// العمليات القابلة للتحكم بالصلاحيات
///
/// كل عملية حساسة في التطبيق لها قيمة هنا، ويُحدَّد الدور المطلوب لها
/// في الدالة [_requiredLevel] أدناه.
enum AppPermission {
  // ── عمليات القراءة/الإدخال العادية (أي مستخدم مصادَق) ──────────────────
  /// إنشاء سند قبض/صرف/تحويل
  createVoucher,

  /// إدارة الكيانات (موظفون، مقاولون، شركاء) — إضافة/تعديل
  manageEntities,

  /// استيراد جماعي من Excel (مصاريف سلفة)
  ///
  /// 📌 نزلت من `admin` إلى `user` بقرار المالك (2026-08-07)، بعد إعادة كتابة
  ///    شاشة الاستيراد فعلياً:
  ///      قبل — تُدرج سندات صرف مباشرة في الدفاتر متجاوزةً `BalanceGuard`.
  ///      بعد — تُنتج **مسودة** لا تمسّ رصيد أي خزينة، والأثر المالي كله انتقل
  ///            إلى [postAdvance] المحمية بـ admin.
  ///    النتيجة المقصودة: المحاسب يجهّز المسودة ويصحّح تصنيف المصروفات،
  ///    والمدير وحده يعتمد.
  importExcel,

  /// تجهيز مسودة سلفة وتحريرها (تعديل البنود، الاستبعاد)
  ///
  /// بمستوى user لأنها بلا أثر مالي إطلاقاً — أسطر المسودة ليست سندات.
  prepareAdvance,

  /// تجهيز كشف رواتب الشهر وتحريره (استيراد الملف، تصحيح السطور)
  ///
  /// بمستوى user لنفس سبب [prepareAdvance]: **الكشف في حالة مسودة لا يمسّ
  /// رصيد أي خزينة إطلاقاً**. الأثر المالي كلّه في التسديد المحمي بـ
  /// [managePayroll]. النتيجة المقصودة: المحاسب يجهّز الكشف ويصحّح فروقه،
  /// والمدير وحده يصرف.
  preparePayroll,

  // ── عمليات إدارية (admin و super_admin) ────────────────────────────────
  /// حذف سند (حذف ناعم)
  deleteVoucher,

  /// إدارة الخزائن (إنشاء/تعديل/حذف)
  manageTreasuries,

  /// تغيير سعر الصرف (يؤثر رجعياً على تقييمات الدولار)
  manageExchangeRate,

  /// إنشاء نسخة احتياطية (تصدير)
  createBackup,

  /// عرض سجل التدقيق
  viewAudit,

  /// إغلاق فترة مالية
  closeFiscalPeriod,

  /// إدارة المستخدمين (إنشاء/تعطيل)
  manageUsers,

  /// صرف رواتب ومنح سلف (عمليات مالية على الموظفين)
  managePayroll,

  /// إلغاء سلفة كاملة (حذف جماعي + عكس أرصدة)
  cancelAdvance,

  /// اعتماد سلفة مشروع — تحويل أسطر المسودة إلى سندات صرف حقيقية
  ///
  /// هذه هي اللحظة الوحيدة التي تتأثر فيها الخزينة في نظام السلف، فهي
  /// الحاجز الحقيقي لا الاستيراد.
  postAdvance,

  /// اعتماد سلفة يتجاوز مصروفها رصيد الخزينة (يجعل الرصيد سالباً)
  ///
  /// مفصولة عن postAdvance عمداً: قد يُقرَّر مستقبلاً رفعها إلى super_admin
  /// وحده دون المساس بالاعتماد العادي.
  postAdvanceWithDeficit,

  // ── عمليات كارثية (super_admin فقط) ────────────────────────────────────
  /// استعادة قاعدة البيانات كاملة من ملف (تمسح كل شيء)
  restoreBackup,

  /// تصفير جميع البيانات المالية
  resetFinancialData,

  /// إعادة فتح فترة مالية مُقفَلة
  reopenFiscalPeriod,

  /// إعادة احتساب الأرصدة الافتتاحية
  recomputeBalances,

  /// حذف/أرشفة سجل التدقيق نهائياً
  purgeAuditLog,

  /// حذف مستخدم
  deleteUser,

  /// **محو** فترة مالية بكل سنداتها محواً نهائياً لا رجعة فيه
  ///
  /// ⚠️ أخطر عملية في التطبيق كلّه — تمحو سندات حقيقية لا سجلاً فارغاً.
  ///   الصلاحية وحدها لا تكفي: العملية محروسة أيضاً بكلمة مرور المستخدم
  ///   ورمز محو منفصل وكتابة اسم الفترة. راجع FiscalNotifier.purgePeriod.
  purgeFiscalPeriod,

  /// حذف فترة مالية **خالية** من أي سند أو سلفة
  ///
  /// مفصولة عن closeFiscalPeriod عمداً: الإقفال يحفظ الأثر، والحذف يمحو
  /// السجلّ. وإن كان الحذف مقيَّداً بالفترات الخالية (فلا أثر مالي يضيع)،
  /// يبقى تصحيحاً لخطأ إداري لا عملية يومية.
  deleteFiscalPeriod,
}

/// مستوى الصلاحية المطلوب — تدرّج تصاعدي
enum _Level { user, admin, superAdmin }

/// الدور المطلوب لكل عملية
_Level _requiredLevel(AppPermission p) {
  switch (p) {
    // أي مستخدم مصادَق — عمليات بلا أثر مالي مباشر
    case AppPermission.createVoucher:
    case AppPermission.manageEntities:
    case AppPermission.importExcel:
    case AppPermission.prepareAdvance:
    case AppPermission.preparePayroll:
      return _Level.user;

    // admin فأعلى
    case AppPermission.deleteVoucher:
    case AppPermission.manageTreasuries:
    case AppPermission.manageExchangeRate:
    case AppPermission.createBackup:
    case AppPermission.viewAudit:
    case AppPermission.closeFiscalPeriod:
    case AppPermission.manageUsers:
    case AppPermission.managePayroll:
    case AppPermission.cancelAdvance:
    case AppPermission.postAdvance:
    case AppPermission.postAdvanceWithDeficit:
      return _Level.admin;

    // super_admin فقط — العمليات الكارثية
    case AppPermission.restoreBackup:
    case AppPermission.resetFinancialData:
    case AppPermission.reopenFiscalPeriod:
    case AppPermission.recomputeBalances:
    case AppPermission.purgeAuditLog:
    case AppPermission.deleteUser:
    case AppPermission.deleteFiscalPeriod:
    case AppPermission.purgeFiscalPeriod:
      return _Level.superAdmin;
  }
}

/// مستوى المستخدم الحالي حسب دوره
_Level _levelOf(UserModel user) {
  if (user.isSuperAdmin) return _Level.superAdmin;
  if (user.isAdmin) return _Level.admin;
  return _Level.user;
}

/// امتداد فحص الصلاحيات على نموذج المستخدم
extension UserPermissionX on UserModel {
  /// هل يملك هذا المستخدم صلاحية تنفيذ العملية [permission]؟
  bool can(AppPermission permission) {
    return _levelOf(this).index >= _requiredLevel(permission).index;
  }
}
