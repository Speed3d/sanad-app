// ─────────────────────────────────────────────────────────────────────────────
// app_settings_dao.dart — DAO إعدادات التطبيق
//
// يتعامل مع جدولين:
//   1. AppSettings  — إعدادات نصية (مفتاح → قيمة)
//   2. AppBlobs     — البيانات الثنائية (شعار الشركة)
//
// نمط الوصول:
//   - getString(key)  / setString(key, value) — للإعدادات النصية
//   - getBool(key)    / setBool(key, value)   — للقيم المنطقية
//   - getInt(key)     / setInt(key, value)    — للأرقام الصحيحة
//   - getDouble(key)  / setDouble(key, value) — للأرقام العشرية
//   - getBlob(key)    / setBlob(...)          — للصور والبيانات الثنائية
//   - watchSetting(key) — Reactive Stream لإعداد واحد
//
// المفاتيح المهمة (راجع AppSettingsKeys في core/constants):
//   'company_name', 'language', 'theme', 'primary_currency',
//   'secondary_currency', 'exchange_rate', 'first_run_complete'
// ─────────────────────────────────────────────────────────────────────────────

// dart:typed_data مُدرَج ضمن package:drift/drift.dart — لا حاجة لاستيراده منفرداً
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_settings_table.dart';

part 'app_settings_dao.g.dart';

/// DAO إعدادات التطبيق والبيانات الثنائية
@DriftAccessor(tables: [AppSettings, AppBlobs])
class AppSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$AppSettingsDaoMixin {
  AppSettingsDao(super.db);

  // ── إعدادات نصية ──────────────────────────────────────────────────────────

  /// قراءة إعداد نصي — يُعيد null إذا لم يوجد المفتاح
  Future<String?> getString(String key) async {
    final row = await (select(appSettings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// قراءة إعداد نصي مع قيمة افتراضية
  Future<String> getStringOrDefault(String key, String defaultValue) async {
    return (await getString(key)) ?? defaultValue;
  }

  /// حفظ إعداد نصي — يُنشئ أو يُحدَّث (UPSERT)
  Future<void> setString(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(
        key: Value(key),
        value: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Stream لمتابعة تغيير إعداد معين في الوقت الفعلي
  ///
  /// مفيد لمتابعة تغيير اللغة أو الثيم فور حفظه
  Stream<String?> watchSetting(String key) {
    return (select(appSettings)..where((s) => s.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  // ── اختصارات للأنواع الشائعة ──────────────────────────────────────────────

  /// قراءة قيمة منطقية من الإعدادات ('true'/'false')
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final val = await getString(key);
    if (val == null) return defaultValue;
    return val.toLowerCase() == 'true';
  }

  /// حفظ قيمة منطقية
  Future<void> setBool(String key, bool value) {
    return setString(key, value.toString());
  }

  /// قراءة قيمة صحيحة
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final val = await getString(key);
    return int.tryParse(val ?? '') ?? defaultValue;
  }

  /// حفظ قيمة صحيحة
  Future<void> setInt(String key, int value) {
    return setString(key, value.toString());
  }

  /// قراءة قيمة عشرية
  Future<double> getDouble(String key, {double defaultValue = 0.0}) async {
    final val = await getString(key);
    return double.tryParse(val ?? '') ?? defaultValue;
  }

  /// حفظ قيمة عشرية
  Future<void> setDouble(String key, double value) {
    return setString(key, value.toString());
  }

  // ── البيانات الثنائية (الصور) ──────────────────────────────────────────────

  /// قراءة بيانات ثنائية (مثل شعار الشركة) — يُعيد null إذا لم يوجد
  Future<Uint8List?> getBlob(String key) async {
    final row = await (select(appBlobs)..where((b) => b.key.equals(key)))
        .getSingleOrNull();
    if (row == null) return null;
    // تحويل من List<int> إلى Uint8List
    return Uint8List.fromList(row.data);
  }

  /// حفظ بيانات ثنائية — يُنشئ أو يُحدَّث (UPSERT)
  ///
  /// [key]      — المفتاح (مثال: 'company_logo')
  /// [data]     — البيانات الثنائية (صورة PNG/JPEG)
  /// [mimeType] — نوع الملف (مثال: 'image/png')
  Future<void> setBlob(String key, Uint8List data, String mimeType) async {
    await into(appBlobs).insertOnConflictUpdate(
      AppBlobsCompanion(
        key: Value(key),
        data: Value(data),
        mimeType: Value(mimeType),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// حذف بيانات ثنائية
  Future<void> deleteBlob(String key) async {
    await (delete(appBlobs)..where((b) => b.key.equals(key))).go();
  }

  /// التحقق من وجود بيانات ثنائية
  Future<bool> hasBlob(String key) async {
    final row = await (select(appBlobs)..where((b) => b.key.equals(key)))
        .getSingleOrNull();
    return row != null;
  }

  // ── حزمة الإعدادات ────────────────────────────────────────────────────────

  /// قراءة جميع الإعدادات دفعةً واحدة كـ Map
  ///
  /// مفيد عند تحميل التطبيق لأول مرة
  Future<Map<String, String>> getAllSettings() async {
    final rows = await select(appSettings).get();
    return {for (final row in rows) row.key: row.value};
  }
}
