// ─────────────────────────────────────────────────────────────────────────────
// users_dao.dart — DAO المستخدمين
//
// يوفر جميع عمليات قاعدة البيانات المتعلقة بالمستخدمين وصلاحياتهم.
//
// العمليات الرئيسية:
//   - CRUD كامل للمستخدمين
//   - البحث بالاسم (للـ Login)
//   - تتبع محاولات الدخول الفاشلة وقفل الحساب
//   - حماية "آخر مدير النظام" (لا يمكن حذفه)
//
// الـ Streams (Reactive Queries):
//   watchAllUsers() يُعيد Stream يتحدث تلقائياً عند أي تغيير في جدول Users
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/users_table.dart';

// الملف المُولَّد تلقائياً — لا تعدّله
part 'users_dao.g.dart';

/// DAO المستخدمين — يُستخدَم عبر db.usersDao
@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  // ── استعلامات القراءة (Queries) ───────────────────────────────────────────

  /// جلب جميع المستخدمين النشطين (غير المحذوفين) — Reactive Stream
  ///
  /// يتحدث تلقائياً عند أي تغيير في الجدول
  Stream<List<User>> watchAllUsers() {
    return (select(users)
          ..where((u) => u.isDeleted.equals(false))
          ..orderBy([(u) => OrderingTerm.asc(u.fullName)]))
        .watch();
  }

  /// جلب جميع المستخدمين (Future — للقراءة مرة واحدة)
  Future<List<User>> getAllUsers() {
    return (select(users)
          ..where((u) => u.isDeleted.equals(false))
          ..orderBy([(u) => OrderingTerm.asc(u.fullName)]))
        .get();
  }

  /// جلب مستخدم بالمعرّف — يُعيد null إذا لم يوجد
  Future<User?> getUserById(int id) {
    return (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();
  }

  /// جلب مستخدم بالاسم — يُستخدَم في عملية تسجيل الدخول
  ///
  /// يُقرأ حتى المحذوف (لعرض رسالة "الحساب محذوف" بدلاً من "بيانات خاطئة")
  Future<User?> getUserByUsername(String username) {
    return (select(users)
          ..where((u) => u.username.lower().equals(username.toLowerCase())))
        .getSingleOrNull();
  }

  /// عدد مدراء النظام (Super Admin) النشطين — للحماية من حذف الأخير
  Future<int> countActiveSuperAdmins() async {
    final result = await customSelect(
      // يعدّ فقط المدراء النشطين وغير المحذوفين
      'SELECT COUNT(*) as cnt FROM users '
      "WHERE role = 'super_admin' AND is_active = 1 AND is_deleted = 0",
      readsFrom: {users},
    ).getSingle();
    return result.data['cnt'] as int;
  }

  // ── استعلامات الكتابة (Mutations) ─────────────────────────────────────────

  /// إدراج مستخدم جديد — يُعيد الـ ID المُولَّد
  Future<int> insertUser(UsersCompanion user) {
    return into(users).insert(user);
  }

  /// تحديث بيانات مستخدم
  Future<bool> updateUser(UsersCompanion user) {
    return update(users).replace(user);
  }

  /// حذف ناعم (Soft Delete) — لا يُحذف من DB لأسباب الـ Audit
  Future<void> softDeleteUser(int id) async {
    await (update(users)..where((u) => u.id.equals(id))).write(
      const UsersCompanion(isDeleted: Value(true), isActive: Value(false)),
    );
  }

  // ── عمليات المصادقة ────────────────────────────────────────────────────────

  /// تحديث عدد محاولات الدخول الفاشلة
  ///
  /// [id] — معرّف المستخدم
  /// [attempts] — العدد الجديد (0 عند النجاح، يزيد بالفشل)
  /// [lockUntil] — وقت انتهاء القفل إذا وصل لـ 5 محاولات
  Future<void> updateFailedAttempts(
    int id, {
    required int attempts,
    DateTime? lockUntil,
  }) async {
    await (update(users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(
        failedLoginAttempts: Value(attempts),
        lockedUntil: Value(lockUntil), // null = إلغاء القفل
      ),
    );
  }

  /// تسجيل وقت آخر دخول ناجح وإعادة تعيين محاولات الفشل
  Future<void> recordSuccessfulLogin(int id) async {
    await (update(users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(
        lastLoginAt: Value(DateTime.now()),
        failedLoginAttempts: const Value(0),
        lockedUntil: const Value(null), // رفع القفل
      ),
    );
  }

  /// تغيير كلمة مرور المستخدم
  Future<void> updatePasswordHash(int id, String newHash) async {
    await (update(users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(passwordHash: Value(newHash)),
    );
  }

  /// تحديث صلاحيات المستخدم (permissions JSON)
  Future<void> updatePermissions(int id, String permissionsJson) async {
    await (update(users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(permissionsJson: Value(permissionsJson)),
    );
  }

  /// تفعيل/تعطيل حساب المستخدم
  Future<void> setUserActive(int id, {required bool isActive}) async {
    await (update(users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(isActive: Value(isActive)),
    );
  }
}
