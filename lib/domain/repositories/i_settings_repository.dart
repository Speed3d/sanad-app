// ─────────────────────────────────────────────────────────────────────────────
// i_settings_repository.dart — واجهة مستودع الإعدادات
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:typed_data';

/// واجهة مستودع إعدادات التطبيق
abstract class ISettingsRepository {
  // ── قراءة وحفظ الإعدادات ─────────────────────────────────────────────────

  /// قراءة إعداد نصي — يُعيد null إذا لم يوجد
  Future<String?> getString(String key);

  /// قراءة إعداد نصي مع قيمة افتراضية
  Future<String> getStringOrDefault(String key, String defaultValue);

  /// حفظ إعداد نصي
  Future<void> setString(String key, String value);

  /// Stream لمتابعة تغيير إعداد في الوقت الفعلي
  Stream<String?> watchSetting(String key);

  /// قراءة قيمة منطقية
  Future<bool> getBool(String key, {bool defaultValue = false});

  /// حفظ قيمة منطقية
  Future<void> setBool(String key, bool value);

  /// قراءة قيمة عشرية
  Future<double> getDouble(String key, {double defaultValue = 0.0});

  /// حفظ قيمة عشرية
  Future<void> setDouble(String key, double value);

  /// جميع الإعدادات دفعةً كـ Map
  Future<Map<String, String>> getAllSettings();

  // ── البيانات الثنائية (شعار الشركة) ────────────────────────────────────────

  /// قراءة صورة / بيانات ثنائية
  Future<Uint8List?> getBlob(String key);

  /// حفظ صورة / بيانات ثنائية
  Future<void> setBlob(String key, Uint8List data, String mimeType);

  /// حذف بيانات ثنائية
  Future<void> deleteBlob(String key);

  // ── إعدادات مهمة مُختصَرة ──────────────────────────────────────────────────

  /// اسم الشركة
  Future<String> getCompanyName();

  /// تعيين اسم الشركة
  Future<void> setCompanyName(String name);

  /// هل اكتمل الإعداد الأول؟
  Future<bool> isFirstRunComplete();

  /// تعليم الإعداد الأول كمكتمل
  Future<void> markFirstRunComplete();

  /// سعر الصرف الحالي (IQD per 1 USD)
  Future<double> getExchangeRate();

  /// تعيين سعر الصرف
  Future<void> setExchangeRate(double rate);
}
