// ─────────────────────────────────────────────────────────────────────────────
// auth_provider.dart — إدارة حالة المصادقة بـ Riverpod
//
// يحتوي هذا الملف على:
//   1. authServiceProvider  — Provider لـ AuthService (Singleton)
//   2. AuthNotifier         — Notifier رئيسي لحالة المصادقة
//
// دورة حياة المصادقة:
//   App Open → AuthInitial → AuthLoading
//     → (استعادة جلسة محفوظة) → AuthAuthenticated
//     → (لا جلسة / أول تشغيل) → AuthUnauthenticated
//
//   Login:
//     AuthLoading → AuthAuthenticated  (نجاح)
//     AuthLoading → AuthLocked         (5 محاولات فاشلة)
//     AuthLoading → AuthError          (بيانات خاطئة)
//
// قاعدة القفل التلقائي:
//   بعد 5 محاولات فاشلة → قفل لـ 15 دقيقة
//   lockedUntil يُحفَظ في جدول Users ويُعاد قراءته عند كل دخول
//
// ملاحظة أمنية:
//   UserModel لا يحتوي على passwordHash لأسباب أمنية.
//   عند التحقق من كلمة المرور، نقرأ الـ hash مباشرةً من Drift (User data class)
//   ثم نتخلص منه فوراً بعد المقارنة.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/auth_service.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/user_model.dart';
import 'database_provider.dart';
import 'repository_providers.dart';

part 'auth_provider.g.dart';

// ── ثوابت المصادقة ───────────────────────────────────────────────────────────

/// الحد الأقصى لمحاولات الدخول الفاشلة قبل القفل
const _kMaxFailedAttempts = 5;

/// مدة قفل الحساب بعد تجاوز الحد
const _kLockDuration = Duration(minutes: 15);

// ── Provider لـ AuthService ────────────────────────────────────────────────

/// Provider للـ AuthService — يُنشَأ مرة واحدة ويبقى طوال عمر التطبيق
@Riverpod(keepAlive: true)
AuthService authService(Ref ref) => AuthService();

// ── AuthNotifier ───────────────────────────────────────────────────────────

/// Notifier إدارة حالة المصادقة الكاملة
///
/// الاستخدام في الواجهة:
///   final authState = ref.watch(authNotifierProvider);
///   final notifier  = ref.read(authNotifierProvider.notifier);
///   await notifier.login(username, password);
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // نبدأ بالحالة الأولية ثم نُهيّئ في الخلفية
    _initialize();
    return const AuthInitial();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // التهيئة الأولية
  // ══════════════════════════════════════════════════════════════════════════

  /// تهيئة المصادقة عند بدء التطبيق
  ///
  /// الترتيب:
  ///   1. هل أُكمل الإعداد الأول؟ → إذا لا: AuthUnauthenticated(isFirstRun: true)
  ///   2. هل توجد جلسة محفوظة؟  → إذا لا: AuthUnauthenticated()
  ///   3. هل المستخدم المحفوظ لا يزال نشطاً؟ → إذا لا: مسح الجلسة
  ///   4. ✅ استعادة الجلسة → AuthAuthenticated
  Future<void> _initialize() async {
    state = const AuthLoading();

    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final service = ref.read(authServiceProvider);
      final userRepo = ref.read(userRepositoryProvider);

      // ── الخطوة 1: هل أُكمل الإعداد الأول؟ ────────────────────────────
      final isFirstRunDone = await settingsRepo.isFirstRunComplete();
      if (!isFirstRunDone) {
        state = const AuthUnauthenticated(isFirstRun: true);
        return;
      }

      // ── الخطوة 2: هل توجد جلسة محفوظة؟ ──────────────────────────────
      final storedUserId = await service.getStoredUserId();
      if (storedUserId == null) {
        state = const AuthUnauthenticated();
        return;
      }

      // ── الخطوة 3: التحقق من صلاحية الجلسة ────────────────────────────
      final user = await userRepo.getUserById(storedUserId);
      if (user == null || !user.isActive) {
        // المستخدم لم يعد موجوداً أو مُعطَّلاً — مسح الجلسة الفاسدة
        await service.clearSession();
        state = const AuthUnauthenticated();
        return;
      }

      // ── الخطوة 4: ✅ استعادة ناجحة ─────────────────────────────────
      state = AuthAuthenticated(user: user);
    } catch (e) {
      // خطأ غير متوقع — رجوع لحالة آمنة
      state = const AuthUnauthenticated();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // تسجيل الدخول
  // ══════════════════════════════════════════════════════════════════════════

  /// تسجيل الدخول بالاسم وكلمة المرور
  ///
  /// [username] — اسم المستخدم (case-insensitive)
  /// [password] — كلمة المرور النصية
  Future<void> login(String username, String password) async {
    state = const AuthLoading();

    try {
      final service = ref.read(authServiceProvider);
      final userRepo = ref.read(userRepositoryProvider);
      // قراءة من DB مباشرة للحصول على passwordHash (غير موجود في UserModel)
      final db = ref.read(appDatabaseProvider);

      // ── 1. البحث عن المستخدم ──────────────────────────────────────────
      final dbUser = await db.usersDao.getUserByUsername(username.trim());

      if (dbUser == null) {
        // تأخير مصطنع لمنع Timing Attack
        // (المهاجم لا يستطيع معرفة إذا كان المستخدم موجوداً من السرعة)
        await Future.delayed(const Duration(milliseconds: 800));
        state = const AuthError(
          message: 'اسم المستخدم أو كلمة المرور غير صحيحة',
        );
        return;
      }

      // ── 2. تحقق: هل الحساب محذوف؟ ───────────────────────────────────
      if (dbUser.isDeleted) {
        state = const AuthError(message: 'هذا الحساب محذوف. تواصل مع مدير النظام');
        return;
      }

      // ── 3. تحقق: هل الحساب مفعَّل؟ ──────────────────────────────────
      if (!dbUser.isActive) {
        state = const AuthError(message: 'الحساب معطَّل. تواصل مع مدير النظام');
        return;
      }

      // ── 4. تحقق: هل الحساب مقفول؟ ───────────────────────────────────
      if (dbUser.lockedUntil != null &&
          DateTime.now().isBefore(dbUser.lockedUntil!)) {
        state = AuthLocked(lockedUntil: dbUser.lockedUntil!);
        return;
      }

      // ── 5. التحقق من كلمة المرور بـ bcrypt ───────────────────────────
      // تُشغَّل في Isolate منفصل لعدم تجميد الـ UI
      final isValid = await service.verifyPassword(
        password,
        dbUser.passwordHash,
      );

      if (!isValid) {
        // كلمة المرور خاطئة — زيادة عداد المحاولات
        await _handleFailedAttempt(
          userId: dbUser.id,
          currentAttempts: dbUser.failedLoginAttempts,
          userRepo: userRepo,
        );
        return;
      }

      // ── 6. ✅ تسجيل الدخول ناجح ────────────────────────────────────
      // إعادة تعيين عداد المحاولات وتسجيل وقت آخر دخول
      await userRepo.recordSuccessfulLogin(dbUser.id);

      // حفظ الجلسة في التخزين الآمن
      await service.saveSession(
        userId: dbUser.id,
        username: dbUser.username,
      );

      // تحميل نموذج المستخدم (UserModel) من Repository
      final userModel = await userRepo.getUserById(dbUser.id);
      state = AuthAuthenticated(user: userModel!);
    } catch (e) {
      state = AuthError(message: 'حدث خطأ أثناء تسجيل الدخول. حاول مجدداً');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // معالجة المحاولات الفاشلة
  // ══════════════════════════════════════════════════════════════════════════

  /// معالجة محاولة دخول فاشلة: زيادة العداد أو القفل
  Future<void> _handleFailedAttempt({
    required int userId,
    required int currentAttempts,
    required dynamic userRepo,
  }) async {
    final newAttempts = currentAttempts + 1;

    if (newAttempts >= _kMaxFailedAttempts) {
      // تجاوز الحد → قفل الحساب
      final lockUntil = DateTime.now().add(_kLockDuration);
      await userRepo.recordFailedLogin(userId, lockUntil: lockUntil);
      state = AuthLocked(lockedUntil: lockUntil);
    } else {
      // لا يزال هناك محاولات
      await userRepo.recordFailedLogin(userId);
      final remaining = _kMaxFailedAttempts - newAttempts;
      state = AuthError(
        message: 'كلمة المرور غير صحيحة.\nالمحاولات المتبقية: $remaining',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // تسجيل الخروج والمساعدات
  // ══════════════════════════════════════════════════════════════════════════

  /// تسجيل الخروج — مسح الجلسة والعودة لحالة غير مصادَق
  Future<void> logout() async {
    final service = ref.read(authServiceProvider);
    await service.clearSession();
    state = const AuthUnauthenticated();
  }

  /// إعادة تهيئة بعد إتمام الإعداد الأول
  ///
  /// يُستدعى من FirstRunScreen بعد حفظ البيانات وإنشاء حساب مدير النظام
  Future<void> reinitialize() async => _initialize();

  /// المستخدم المصادَق حالياً (null إذا لم يكن مسجَّلاً)
  UserModel? get currentUser {
    final s = state;
    return s is AuthAuthenticated ? s.user : null;
  }

  /// هل يوجد مستخدم مصادَق؟
  bool get isAuthenticated => state is AuthAuthenticated;
}
