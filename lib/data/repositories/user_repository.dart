// ─────────────────────────────────────────────────────────────────────────────
// user_repository.dart — تنفيذ مستودع المستخدمين باستخدام Drift
//
// هذا الملف هو الجسر بين:
//   - طبقة الـ Domain (UserModel, IUserRepository)
//   - طبقة البيانات (UsersDao + Drift)
//
// مهمته:
//   1. تحويل بيانات Drift (User) إلى نماذج Domain (UserModel)
//   2. تحويل نماذج Domain إلى بيانات Drift عند الكتابة
//   3. تطبيق قواعد العمل البسيطة قبل الكتابة
//
// قواعد العمل المطبَّقة هنا:
//   - لا تحتاج تحقق: الـ DAO يتولى التحقق من الـ Schema
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

import '../../domain/models/user_model.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../database/app_database.dart';
// UsersCompanion و User مُولَّدان في app_database.g.dart — لا حاجة لاستيراد users_table.dart

/// تنفيذ مستودع المستخدمين باستخدام Drift
class UserRepository implements IUserRepository {
  /// مرجع لقاعدة البيانات — يُحقَن عبر Riverpod
  final AppDatabase _db;

  const UserRepository(this._db);

  // ── تحويل البيانات ────────────────────────────────────────────────────────

  /// تحويل من نموذج Drift إلى نموذج Domain
  UserModel _toModel(User user) {
    return UserModel(
      id: user.id,
      username: user.username,
      fullName: user.fullName,
      role: user.role,
      permissionsJson: user.permissionsJson,
      isActive: user.isActive,
      failedLoginAttempts: user.failedLoginAttempts,
      lockedUntil: user.lockedUntil,
      lastLoginAt: user.lastLoginAt,
      createdAt: user.createdAt,
    );
  }

  // ── تنفيذ الواجهة ─────────────────────────────────────────────────────────

  @override
  Stream<List<UserModel>> watchAllUsers() {
    // تحويل Stream<List<User>> إلى Stream<List<UserModel>>
    return _db.usersDao.watchAllUsers().map(
          (users) => users.map(_toModel).toList(),
        );
  }

  @override
  Future<UserModel?> getUserById(int id) async {
    final user = await _db.usersDao.getUserById(id);
    return user == null ? null : _toModel(user);
  }

  @override
  Future<UserModel?> getUserByUsername(String username) async {
    final user = await _db.usersDao.getUserByUsername(username);
    return user == null ? null : _toModel(user);
  }

  @override
  Future<int> countActiveSuperAdmins() {
    return _db.usersDao.countActiveSuperAdmins();
  }

  @override
  Future<int> createUser({
    required String username,
    required String passwordHash,
    required String fullName,
    required String role,
    String permissionsJson = '{}',
  }) {
    return _db.usersDao.insertUser(
      UsersCompanion.insert(
        username: username,
        passwordHash: passwordHash,
        fullName: fullName,
        // role له قيمة افتراضية 'user' في الجدول → يجب تغليفه بـ Value()
        role: Value(role),
        permissionsJson: Value(permissionsJson),
      ),
    );
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _db.usersDao.updateUser(
      UsersCompanion(
        id: Value(user.id),
        username: Value(user.username),
        fullName: Value(user.fullName),
        role: Value(user.role),
        permissionsJson: Value(user.permissionsJson),
        isActive: Value(user.isActive),
      ),
    );
  }

  @override
  Future<void> deleteUser(int id) {
    return _db.usersDao.softDeleteUser(id);
  }

  @override
  Future<({int attempts, DateTime? lockedUntil})> recordFailedLogin(
    int id, {
    required int maxAttempts,
    required Duration lockDuration,
  }) {
    // الزيادة والقفل يحدثان ذرياً داخل قاعدة البيانات — لا حساب في Dart
    return _db.usersDao.registerFailedLogin(
      id,
      maxAttempts: maxAttempts,
      lockDuration: lockDuration,
    );
  }

  @override
  Future<void> recordSuccessfulLogin(int id) {
    return _db.usersDao.recordSuccessfulLogin(id);
  }

  @override
  Future<void> changePassword(int id, String newPasswordHash) {
    return _db.usersDao.updatePasswordHash(id, newPasswordHash);
  }

  @override
  Future<void> updatePermissions(int id, String permissionsJson) {
    return _db.usersDao.updatePermissions(id, permissionsJson);
  }

  @override
  Future<void> setActive(int id, {required bool isActive}) {
    return _db.usersDao.setUserActive(id, isActive: isActive);
  }
}
