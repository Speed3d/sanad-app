// ─────────────────────────────────────────────────────────────────────────────
// i_user_repository.dart — واجهة مستودع المستخدمين (Abstract Interface)
//
// لماذا Abstract Interface؟
//   - Dependency Inversion: طبقة الـ Domain لا تعرف شيئاً عن Drift
//   - Testability: يمكن إنشاء MockUserRepository في الاختبارات بسهولة
//   - قابلية التبديل: لو قررنا تغيير قاعدة البيانات مستقبلاً
//
// التنفيذ الفعلي: lib/data/repositories/user_repository.dart
// ─────────────────────────────────────────────────────────────────────────────

import '../models/user_model.dart';

/// واجهة مستودع المستخدمين
abstract class IUserRepository {
  // ── القراءة ────────────────────────────────────────────────────────────────

  /// Stream تفاعلي لجميع المستخدمين النشطين
  Stream<List<UserModel>> watchAllUsers();

  /// جلب مستخدم بالمعرّف — يُعيد null إذا لم يوجد
  Future<UserModel?> getUserById(int id);

  /// جلب مستخدم بالاسم — للـ Login
  Future<UserModel?> getUserByUsername(String username);

  /// عدد مدراء النظام النشطين — لحماية الأخير من الحذف
  Future<int> countActiveSuperAdmins();

  // ── الكتابة ────────────────────────────────────────────────────────────────

  /// إنشاء مستخدم جديد — يُعيد الـ ID المُولَّد
  Future<int> createUser({
    required String username,
    required String passwordHash,
    required String fullName,
    required String role,
    String permissionsJson,
  });

  /// تحديث بيانات مستخدم (باستثناء كلمة المرور)
  Future<void> updateUser(UserModel user);

  /// حذف ناعم للمستخدم
  Future<void> deleteUser(int id);

  // ── المصادقة ───────────────────────────────────────────────────────────────

  /// تحديث عدد محاولات الدخول الفاشلة
  Future<void> recordFailedLogin(int id, {DateTime? lockUntil});

  /// تسجيل دخول ناجح — يُعيد العداد لصفر ويُسجَّل الوقت
  Future<void> recordSuccessfulLogin(int id);

  /// تغيير كلمة المرور
  Future<void> changePassword(int id, String newPasswordHash);

  /// تحديث الصلاحيات
  Future<void> updatePermissions(int id, String permissionsJson);

  /// تفعيل / تعطيل حساب
  Future<void> setActive(int id, {required bool isActive});
}
