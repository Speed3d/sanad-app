// ─────────────────────────────────────────────────────────────────────────────
// auth_lockout_test.dart — اختبارات قفل الحساب بعد المحاولات الفاشلة
//
// لماذا هذا الملف؟
//   كشف تدقيق 2026-08-06 أن آلية قفل الحساب كانت **معطّلة بالكامل**:
//   دالة recordFailedLogin كانت تكتب `attempts: 0` في كل محاولة فاشلة،
//   فالعدّاد لا يتجاوز 1 أبداً ولا يصل للحد (5) — أي تخمين لا نهائي
//   لكلمة المرور بلا أي قفل، بينما تعرض الواجهة "المحاولات المتبقية: 4"
//   إلى الأبد.
//
//   اختبار واحد بسيط من هذا الملف كان كفيلاً بكشف الثغرة يوم كتابتها.
//   هذه الاختبارات هي الحارس الدائم ضد عودتها.
//
// ما يُختبَر هنا:
//   1. زيادة العدّاد فعلياً مع كل محاولة فاشلة
//   2. القفل عند بلوغ الحد الأقصى تحديداً (لا قبله)
//   3. رفع القفل وتصفير العدّاد عند الدخول الناجح
//   4. ذرية الزيادة (لا تضيع محاولة عند التزامن)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';

void main() {
  late AppDatabase db;
  late int userId;

  // الحد الأقصى ومدة القفل — نفس القيم المستخدمة في auth_provider.dart
  const maxAttempts = 5;
  const lockDuration = Duration(minutes: 15);

  setUp(() async {
    // قاعدة بيانات في الذاكرة لكل اختبار لضمان العزل التام
    db = AppDatabase.forTesting(NativeDatabase.memory());

    // إنشاء مستخدم تجريبي نبدأ به كل اختبار
    userId = await db.usersDao.insertUser(
      UsersCompanion.insert(
        username: 'testuser',
        passwordHash: r'$2a$12$fakehashfortestingpurposesonly',
        fullName: 'مستخدم اختبار',
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('قفل الحساب بعد المحاولات الفاشلة', () {
    test('العدّاد يزيد فعلياً مع كل محاولة فاشلة (لا يبقى صفراً)', () async {
      // المحاولة الأولى
      final first = await db.usersDao.registerFailedLogin(
        userId,
        maxAttempts: maxAttempts,
        lockDuration: lockDuration,
      );
      expect(first.attempts, equals(1), reason: 'أول محاولة يجب أن تُسجَّل 1');
      expect(first.lockedUntil, isNull, reason: 'لا قفل بعد محاولة واحدة');

      // المحاولة الثانية — هنا كانت الثغرة: كان العدّاد يعود إلى 1
      final second = await db.usersDao.registerFailedLogin(
        userId,
        maxAttempts: maxAttempts,
        lockDuration: lockDuration,
      );
      expect(second.attempts, equals(2), reason: 'العدّاد يجب أن يتراكم لا أن يُصفَّر');
      expect(second.lockedUntil, isNull);
    });

    test('الحساب يُقفَل عند بلوغ الحد الأقصى (5 محاولات) وليس قبله', () async {
      // المحاولات الأربع الأولى: يجب ألا تُسبب قفلاً
      for (var i = 1; i <= maxAttempts - 1; i++) {
        final result = await db.usersDao.registerFailedLogin(
          userId,
          maxAttempts: maxAttempts,
          lockDuration: lockDuration,
        );
        expect(result.attempts, equals(i));
        expect(
          result.lockedUntil,
          isNull,
          reason: 'يجب ألا يُقفل الحساب عند المحاولة رقم $i',
        );
      }

      // المحاولة الخامسة: يجب أن تُسبب القفل
      final fifth = await db.usersDao.registerFailedLogin(
        userId,
        maxAttempts: maxAttempts,
        lockDuration: lockDuration,
      );
      expect(fifth.attempts, equals(maxAttempts));
      expect(
        fifth.lockedUntil,
        isNotNull,
        reason: 'يجب قفل الحساب عند المحاولة رقم $maxAttempts',
      );

      // القفل يجب أن يكون في المستقبل (خلال مدة القفل تقريباً)
      expect(fifth.lockedUntil!.isAfter(DateTime.now()), isTrue);

      // والقفل يجب أن يكون محفوظاً فعلياً في قاعدة البيانات
      final stored = await db.usersDao.getUserById(userId);
      expect(stored!.lockedUntil, isNotNull);
      expect(stored.failedLoginAttempts, equals(maxAttempts));
    });

    test('الدخول الناجح يرفع القفل ويُصفّر العدّاد', () async {
      // نصل بالحساب إلى حالة القفل
      for (var i = 0; i < maxAttempts; i++) {
        await db.usersDao.registerFailedLogin(
          userId,
          maxAttempts: maxAttempts,
          lockDuration: lockDuration,
        );
      }
      final locked = await db.usersDao.getUserById(userId);
      expect(locked!.lockedUntil, isNotNull);

      // دخول ناجح
      await db.usersDao.recordSuccessfulLogin(userId);

      final after = await db.usersDao.getUserById(userId);
      expect(after!.failedLoginAttempts, equals(0), reason: 'يجب تصفير العدّاد');
      expect(after.lockedUntil, isNull, reason: 'يجب رفع القفل');
      expect(after.lastLoginAt, isNotNull, reason: 'يجب تسجيل وقت الدخول');
    });

    test('الزيادة ذرية — محاولات متزامنة لا تضيع أيٌّ منها', () async {
      // إطلاق 5 محاولات فاشلة بالتوازي.
      // مع النمط القديم (قراءة ثم تعديل ثم كتابة في Dart) كانت المحاولات
      // المتزامنة تقرأ نفس القيمة فتضيع بعضها. الزيادة داخل SQL تمنع ذلك.
      await Future.wait([
        for (var i = 0; i < maxAttempts; i++)
          db.usersDao.registerFailedLogin(
            userId,
            maxAttempts: maxAttempts,
            lockDuration: lockDuration,
          ),
      ]);

      final stored = await db.usersDao.getUserById(userId);
      expect(
        stored!.failedLoginAttempts,
        equals(maxAttempts),
        reason: 'كل المحاولات الخمس يجب أن تُحتسَب رغم التزامن',
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // ع-٤٣ — انقضاء القفل يجب أن يُعيد المحاولات الخمس
  // ══════════════════════════════════════════════════════════════════════

  group('ع-٤٣ — القفل عقوبة مؤقّتة لا دائمة', () {
    /// يُرجع وقت انتهاء القفل إلى الماضي — محاكاةُ انقضاء الدقائق الخمس عشرة
    /// بلا انتظارها فعلياً في الاختبار.
    Future<void> expireLock() async {
      await (db.update(db.users)..where((u) => u.id.equals(userId))).write(
        UsersCompanion(
          lockedUntil: Value(DateTime.now().subtract(const Duration(minutes: 1))),
        ),
      );
    }

    test('⭐⭐ بعد انقضاء القفل، خطأٌ واحد لا يُعيد القفل', () async {
      // ١) استنفاد المحاولات حتى القفل
      for (var i = 0; i < maxAttempts; i++) {
        await db.usersDao.registerFailedLogin(
          userId,
          maxAttempts: maxAttempts,
          lockDuration: lockDuration,
        );
      }
      final locked = await db.usersDao.getUserById(userId);
      expect(locked!.lockedUntil, isNotNull, reason: 'الشرط المسبق: قُفل فعلاً');

      // ٢) انقضاء المدّة
      await expireLock();

      // ٣) خطأ واحد بعد الانقضاء
      final result = await db.usersDao.registerFailedLogin(
        userId,
        maxAttempts: maxAttempts,
        lockDuration: lockDuration,
      );

      // 🔴 قبل إصلاح ع-٤٣ كان العدّاد يبقى ٥ فيصير ٦ ≥ ٥ ⇒ قفلٌ فوريّ.
      //   فيخسر المستخدم محاولاته الخمس إلى الأبد ويصير له محاولة واحدة
      //   كل ربع ساعة — وهي عقوبة دائمة لا مؤقّتة.
      expect(result.lockedUntil, isNull,
          reason: 'انقضاء المدّة يجب أن يُعيد الحال — لا قفل من خطأ واحد');
      expect(result.attempts, 1,
          reason: 'العدّاد يبدأ من جديد بعد انقضاء العقوبة');
    });

    test('⭐ القفل المُنقضي يُرفع فلا يبقى أثره في الصفّ', () async {
      for (var i = 0; i < maxAttempts; i++) {
        await db.usersDao.registerFailedLogin(
          userId,
          maxAttempts: maxAttempts,
          lockDuration: lockDuration,
        );
      }
      await expireLock();
      await db.usersDao.registerFailedLogin(
        userId,
        maxAttempts: maxAttempts,
        lockDuration: lockDuration,
      );

      final after = await db.usersDao.getUserById(userId);
      expect(after!.lockedUntil, isNull);
      expect(after.failedLoginAttempts, 1);
    });

    test('⭐⭐ القفل الساري لا يُمَسّ — العدّاد يواصل التراكم', () async {
      // الحارس المعاكس: لو صفّرنا بلا شرط انقضاء لصار القفل بلا معنى،
      // إذ تكفي محاولةٌ أخرى لمحوه. الشرط `locked_until <= now` هو ما يفرّق.
      for (var i = 0; i < maxAttempts; i++) {
        await db.usersDao.registerFailedLogin(
          userId,
          maxAttempts: maxAttempts,
          lockDuration: lockDuration,
        );
      }

      final result = await db.usersDao.registerFailedLogin(
        userId,
        maxAttempts: maxAttempts,
        lockDuration: lockDuration,
      );

      expect(result.attempts, maxAttempts + 1,
          reason: 'القفل ما زال ساريًا فلا تصفير');
      expect(result.lockedUntil, isNotNull, reason: 'ويبقى مقفولاً');
    });

    test('⭐ من لم يُقفَل قط تتراكم محاولاته كالمعتاد', () async {
      // شرط `lockedUntil.isNotNull()` يمنع مساس من لا قفل له —
      // وإلا لصُفِّر العدّاد في كل محاولة فلم يبلغ الحدّ أبداً.
      for (var i = 1; i <= 3; i++) {
        final r = await db.usersDao.registerFailedLogin(
          userId,
          maxAttempts: maxAttempts,
          lockDuration: lockDuration,
        );
        expect(r.attempts, i, reason: 'المحاولة رقم $i تُحتسَب');
      }
    });
  });
}
