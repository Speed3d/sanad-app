// ─────────────────────────────────────────────────────────────────────────────
// auth_service.dart — خدمة المصادقة الأساسية
//
// تتولى هذه الخدمة:
//   1. تشفير كلمات المرور بـ bcrypt (عبر isolate منفصل لعدم تجميد الواجهة)
//   2. التحقق من كلمة المرور
//   3. حفظ الجلسة في flutter_secure_storage (مشفّر في Keychain/Keystore)
//   4. قراءة الجلسة المحفوظة عند إعادة فتح التطبيق
//   5. مسح الجلسة عند تسجيل الخروج
//
// آلية bcrypt:
//   logRounds = 12 → ~300ms على هاتف متوسط (توازن بين الأمان والسرعة)
//   نستخدم compute() لتشغيله في Isolate منفصل كي لا يُجمَّد الـ UI
//
// flutter_secure_storage:
//   Android: EncryptedSharedPreferences (AES-256)
//   iOS/macOS: Keychain
//   Web: localStorage (مقبول لأن هذا تطبيق داخلي)
//
// القفل التلقائي:
//   5 محاولات فاشلة → قفل لـ 15 دقيقة
//   هذه القاعدة مُطبَّقة في AuthNotifier وليس هنا
// ─────────────────────────────────────────────────────────────────────────────

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ── مفاتيح التخزين الآمن ───────────────────────────────────────────────────

/// مفتاح معرّف المستخدم المحفوظ في الجلسة
const _kStorageKeyUserId = 'auth_user_id';

/// مفتاح اسم المستخدم المحفوظ (للعرض السريع بدون DB)
const _kStorageKeyUsername = 'auth_username';

// ── دوال الـ Isolate (يجب أن تكون Top-Level) ─────────────────────────────────

/// تشفير كلمة المرور — يُشغَّل في Isolate منفصل
String _hashPasswordIsolate(String password) {
  // logRounds: كلما زاد كان أبطأ وأكثر أماناً
  // 12 = ~300ms — توازن ممتاز للتطبيقات التجارية
  final salt = BCrypt.gensalt(logRounds: 12);
  return BCrypt.hashpw(password, salt);
}

/// التحقق من كلمة المرور — يُشغَّل في Isolate منفصل
bool _verifyPasswordIsolate(({String password, String hash}) args) {
  return BCrypt.checkpw(args.password, args.hash);
}

// ── خدمة المصادقة ─────────────────────────────────────────────────────────

/// خدمة المصادقة — تُحقَن عبر Provider
class AuthService {
  /// التخزين الآمن — Android: EncryptedSharedPreferences | iOS: Keychain
  final FlutterSecureStorage _storage;

  AuthService() : _storage = const FlutterSecureStorage(
    // تفعيل التشفير الكامل على Android
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    // macOS/iOS: استخدام Keychain
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── تشفير وتحقق كلمة المرور ───────────────────────────────────────────────

  /// تشفير كلمة المرور بـ bcrypt — يُعيد الـ hash الآمن
  ///
  /// يُشغَّل في Isolate منفصل عبر compute() لعدم تجميد الـ UI
  Future<String> hashPassword(String password) async {
    // compute() يُشغّل الدالة في isolate منفصل تلقائياً
    return compute(_hashPasswordIsolate, password);
  }

  /// التحقق من تطابق كلمة المرور مع الـ hash
  ///
  /// [password] — كلمة المرور المُدخَلة
  /// [hash]     — الـ hash المُخزَّن في قاعدة البيانات
  Future<bool> verifyPassword(String password, String hash) async {
    return compute(_verifyPasswordIsolate, (password: password, hash: hash));
  }

  // ── إدارة الجلسة ─────────────────────────────────────────────────────────

  /// حفظ بيانات الجلسة بعد تسجيل الدخول الناجح
  ///
  /// [userId]   — معرّف المستخدم في قاعدة البيانات
  /// [username] — اسم المستخدم (للعرض السريع)
  Future<void> saveSession({
    required int userId,
    required String username,
  }) async {
    await _storage.write(key: _kStorageKeyUserId, value: userId.toString());
    await _storage.write(key: _kStorageKeyUsername, value: username);
  }

  /// قراءة معرّف المستخدم من الجلسة المحفوظة
  ///
  /// يُعيد null إذا لم تكن هناك جلسة محفوظة (أول تشغيل أو بعد تسجيل خروج)
  Future<int?> getStoredUserId() async {
    final raw = await _storage.read(key: _kStorageKeyUserId);
    return raw == null ? null : int.tryParse(raw);
  }

  /// مسح الجلسة المحفوظة (تسجيل الخروج)
  Future<void> clearSession() async {
    await _storage.delete(key: _kStorageKeyUserId);
    await _storage.delete(key: _kStorageKeyUsername);
  }
}
