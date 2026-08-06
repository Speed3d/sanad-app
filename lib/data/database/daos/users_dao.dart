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

  /// تحديث بيانات مستخدم — تحديث جزئي للحقول الحاضرة فقط
  ///
  /// ⚠️ لماذا write وليس replace؟ (إصلاح ثغرة تدقيق 2026-08-06)
  ///   replace كان يرمي استثناءً في كل استدعاء! لأنه يستدعي
  ///   validateIntegrity(isInserting: true) فيشترط حضور password_hash
  ///   (غير موجود في UserModel)، فيفشل تغيير الدور دائماً بينما تعرض
  ///   الواجهة نجاحاً كاذباً. write لا يُجري فحص الإدراج، ولا يُعيد
  ///   is_deleted/created_at/failed_login_attempts إلى قيمها الافتراضية.
  Future<bool> updateUser(UsersCompanion user) async {
    final count = await (update(users)..where((u) => u.id.equals(user.id.value)))
        .write(user);
    return count > 0;
  }

  /// حذف ناعم (Soft Delete) — لا يُحذف من DB لأسباب الـ Audit
  Future<void> softDeleteUser(int id) async {
    await (update(users)..where((u) => u.id.equals(id))).write(
      const UsersCompanion(isDeleted: Value(true), isActive: Value(false)),
    );
  }

  // ── عمليات المصادقة ────────────────────────────────────────────────────────

  /// تسجيل محاولة دخول فاشلة — يزيد العدّاد ذرياً ويقفل الحساب عند بلوغ الحد
  ///
  /// ⚠️ لماذا الزيادة داخل SQL وليس في Dart؟
  ///   الطريقة القديمة كانت: تقرأ العدّاد في Dart، تزيده بواحد، ثم تكتبه.
  ///   هذا النمط (read-modify-write) فيه عيبان:
  ///     1. سباق (race): محاولتان متزامنتان تقرآن نفس القيمة فتضيع إحداهما.
  ///     2. اعتماد على المستدعي في تمرير القيمة الصحيحة — وهو بالضبط
  ///        سبب الثغرة التي عُطّل بها القفل بالكامل (كان يُمرَّر 0 دائماً).
  ///   الحل: `SET failed_login_attempts = failed_login_attempts + 1` داخل
  ///   قاعدة البيانات نفسها، فلا يمكن لأي مستدعٍ أن يُفسدها.
  ///
  /// [id] — معرّف المستخدم
  /// [maxAttempts] — الحد الأقصى للمحاولات قبل القفل
  /// [lockDuration] — مدة القفل عند بلوغ الحد
  ///
  /// يُعيد: العدد الجديد للمحاولات، ووقت انتهاء القفل (null إذا لم يُقفَل)
  Future<({int attempts, DateTime? lockedUntil})> registerFailedLogin(
    int id, {
    required int maxAttempts,
    required Duration lockDuration,
  }) async {
    // كل الخطوات داخل معاملة واحدة حتى لا تتداخل مع محاولة أخرى
    return transaction(() async {
      // ── 1. الزيادة الذرية للعدّاد ───────────────────────────────────────
      await customStatement(
        'UPDATE users SET failed_login_attempts = failed_login_attempts + 1 '
        'WHERE id = ?',
        [id],
      );

      // ── 2. قراءة العدد الجديد بعد الزيادة ───────────────────────────────
      final row = await (select(users)..where((u) => u.id.equals(id)))
          .getSingleOrNull();
      final newAttempts = row?.failedLoginAttempts ?? 0;

      // ── 3. القفل إذا بلغ العدّاد الحد الأقصى ────────────────────────────
      DateTime? lockedUntil;
      if (newAttempts >= maxAttempts) {
        lockedUntil = DateTime.now().add(lockDuration);
        await (update(users)..where((u) => u.id.equals(id))).write(
          UsersCompanion(lockedUntil: Value(lockedUntil)),
        );
      }

      return (attempts: newAttempts, lockedUntil: lockedUntil);
    });
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
