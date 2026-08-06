// ─────────────────────────────────────────────────────────────────────────────
// app_settings_keys.dart — ثوابت مفاتيح إعدادات التطبيق
//
// جميع مفاتيح جدول AppSettings مُعرَّفة هنا كـ constants.
// يمنع الأخطاء الإملائية ويسهّل البحث والتتبع.
//
// الاستخدام:
//   await settingsRepo.getSetting(AppSettingsKeys.companyName);
//   await settingsRepo.setSetting(AppSettingsKeys.themeMode, 'dark');
// ─────────────────────────────────────────────────────────────────────────────

/// ثوابت مفاتيح إعدادات التطبيق المحفوظة في جدول app_settings
abstract final class AppSettingsKeys {
  // ── بيانات الشركة ──────────────────────────────────────────────────────────

  /// اسم الشركة — يظهر في التقارير والسندات
  static const String companyName = 'company_name';

  /// شعار الشركة — مُخزَّن في جدول app_blobs (ليس هنا)
  static const String companyLogo = 'company_logo';

  // ── المظهر ─────────────────────────────────────────────────────────────────

  /// وضع المظهر: 'light' | 'dark' | 'system'
  static const String themeMode = 'theme';

  /// قيمة لون البذرة الأساسي كـ int (Color.value) — نص يُحوَّل إلى Color
  static const String primaryColor = 'primary_color';

  // ── اللغة والتنسيق ─────────────────────────────────────────────────────────

  /// رمز اللغة: 'ar' | 'en'
  static const String language = 'language';

  // ── العملة والأسعار ────────────────────────────────────────────────────────

  /// العملة الأساسية: 'IQD' | 'USD'
  static const String primaryCurrency = 'primary_currency';

  /// العملة الثانوية: 'USD' | 'IQD' | 'EUR'
  static const String secondaryCurrency = 'secondary_currency';

  /// سعر صرف الدولار مقابل الدينار (نص يُحوَّل لـ double)
  static const String exchangeRate = 'exchange_rate';

  // ── الأمان ─────────────────────────────────────────────────────────────────

  /// مدة الجلسة قبل القفل التلقائي (بالدقائق) — '0' = لا قفل
  static const String autoLockMinutes = 'auto_lock_minutes';

  // ── النسخ الاحتياطي ────────────────────────────────────────────────────────

  /// هل النسخ الاحتياطي التلقائي مفعَّل: 'true' | 'false'
  static const String autoBackupEnabled = 'auto_backup_enabled';

  /// تكرار النسخ الاحتياطي بالأيام: '1' | '7' | '30'
  static const String autoBackupDays = 'auto_backup_days';

  /// تاريخ آخر نسخة احتياطية (ISO 8601)
  static const String lastBackupDate = 'last_backup_date';

  // ── النظام (للاستخدام الداخلي فقط) ───────────────────────────────────────

  /// هل اكتمل الإعداد الأول: 'true' | 'false'
  static const String firstRunComplete = 'first_run_complete';

  /// إصدار قاعدة البيانات — للأرشيف
  static const String dbSchemaVersion = 'db_schema_version';
}
