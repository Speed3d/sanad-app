// ─────────────────────────────────────────────────────────────────────────────
// settings_repository.dart — تنفيذ مستودع الإعدادات باستخدام Drift
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:typed_data';

import '../../domain/repositories/i_settings_repository.dart';
import '../database/app_database.dart';

/// تنفيذ مستودع الإعدادات باستخدام Drift
class SettingsRepository implements ISettingsRepository {
  final AppDatabase _db;

  const SettingsRepository(this._db);

  // ── تفويض مباشر إلى AppSettingsDao ──────────────────────────────────────

  @override
  Future<String?> getString(String key) => _db.appSettingsDao.getString(key);

  @override
  Future<String> getStringOrDefault(String key, String defaultValue) =>
      _db.appSettingsDao.getStringOrDefault(key, defaultValue);

  @override
  Future<void> setString(String key, String value) =>
      _db.appSettingsDao.setString(key, value);

  @override
  Stream<String?> watchSetting(String key) =>
      _db.appSettingsDao.watchSetting(key);

  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) =>
      _db.appSettingsDao.getBool(key, defaultValue: defaultValue);

  @override
  Future<void> setBool(String key, bool value) =>
      _db.appSettingsDao.setBool(key, value);

  @override
  Future<double> getDouble(String key, {double defaultValue = 0.0}) =>
      _db.appSettingsDao.getDouble(key, defaultValue: defaultValue);

  @override
  Future<void> setDouble(String key, double value) =>
      _db.appSettingsDao.setDouble(key, value);

  @override
  Future<Map<String, String>> getAllSettings() =>
      _db.appSettingsDao.getAllSettings();

  @override
  Future<Uint8List?> getBlob(String key) => _db.appSettingsDao.getBlob(key);

  @override
  Future<void> setBlob(String key, Uint8List data, String mimeType) =>
      _db.appSettingsDao.setBlob(key, data, mimeType);

  @override
  Future<void> deleteBlob(String key) => _db.appSettingsDao.deleteBlob(key);

  // ── اختصارات الإعدادات الشائعة ──────────────────────────────────────────

  @override
  Future<String> getCompanyName() =>
      _db.appSettingsDao.getStringOrDefault('company_name', '');

  @override
  Future<void> setCompanyName(String name) =>
      _db.appSettingsDao.setString('company_name', name);

  @override
  Future<bool> isFirstRunComplete() =>
      _db.appSettingsDao.getBool('first_run_complete');

  @override
  Future<void> markFirstRunComplete() =>
      _db.appSettingsDao.setBool('first_run_complete', true);

  @override
  Future<double> getExchangeRate() =>
      _db.appSettingsDao.getDouble('exchange_rate', defaultValue: 1310.0);

  @override
  Future<void> setExchangeRate(double rate) =>
      _db.appSettingsDao.setDouble('exchange_rate', rate);
}
