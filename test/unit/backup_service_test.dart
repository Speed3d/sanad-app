// ─────────────────────────────────────────────────────────────────────────────
// backup_service_test.dart — النسخة الشاملة: التصدير والفحص والاستعادة
//
// **لماذا هذا الملف أهمّ من حجمه:** النسخة الاحتياطية لا تُجرَّب إلا يوم
// الكارثة. وقبل اليوم كان منطقها كلّه (٨١٧ سطراً) داخل ودجت **بلا اختبار
// واحد** — وهناك بالضبط عاش ع-٤١: النسخة الشاملة لم تنسخ أيّ مرفق طوال
// حياتها، وأبلغت بالنجاح في كل مرّة.
//
// النمط المتَّبع (نفس `attachment_service_test.dart`): **قرص حقيقي** عبر
// `Directory.systemTemp.createTemp` مع `tearDown` ينظّف — لا محاكاة. وقاعدة
// البيانات **ملفّية** لا في الذاكرة، وإلا لم تُختبَر الاستعادة أصلاً: جوهرها
// دهسُ ملفٍ على القرص.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/services/attachment_service.dart';
import 'package:sales_management/core/services/backup_crypto_service.dart';
import 'package:sales_management/core/services/backup_service.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/domain/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late String dbPath;
  late String attachmentsRoot;
  late String backupsRoot;
  late AppDatabase db;

  const kPassword = 'sanad-backup-2026';

  UserModel actor({String role = 'super_admin'}) => UserModel(
        id: 1,
        username: 'owner',
        fullName: 'المالك',
        role: role,
        createdAt: DateTime(2026, 1, 1),
      );

  /// يفتح قاعدة **ملفّية** على [dbPath] — الاستعادة تدهس ملفاً، فلا معنى
  /// لاختبارها على قاعدة في الذاكرة.
  AppDatabase openDb() => AppDatabase.forTesting(NativeDatabase(File(dbPath)));

  /// يزرع مرفقاً حقيقياً: ملف على القرص **وصفّ في الفهرس** — والاثنان معاً
  /// شرط، فالتصدير ينسخ من الفهرس ويتحقّق من وجود الملف.
  Future<void> seedAttachment(String relativePath, {int size = 64}) async {
    final bytes = Uint8List.fromList(List.generate(size, (i) => i % 256));
    final f = File(AttachmentService.absolutePathOf(
      root: attachmentsRoot,
      relativePath: relativePath,
    ));
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes, flush: true);

    await db.into(db.attachments).insert(
          AttachmentsCompanion.insert(
            entityType: 'voucher',
            entityId: 1,
            fileName: relativePath.split('/').last,
            relativePath: relativePath,
            sizeBytes: Value(bytes.length),
            sha256: Value(AttachmentService.hashBytes(bytes)),
          ),
        );
  }

  /// يزرع خزينة — علامةٌ نتحقّق من عودتها بعد الاستعادة
  Future<int> seedTreasury(String name) => db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(name: name, kind: const Value('main')),
      );

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('sanad_backup_test');
    dbPath = '${tmp.path}/sales_management_db.sqlite';
    attachmentsRoot = '${tmp.path}/attachments_store';
    backupsRoot = '${tmp.path}/backups';
    await Directory(attachmentsRoot).create(recursive: true);
    await Directory(backupsRoot).create(recursive: true);
    db = openDb();
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {
      // قد تكون أُغلقت داخل الاستعادة — وهو المتوقَّع
    }
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  // ══════════════════════════════════════════════════════════════════════
  group('التصدير الشامل', () {
    test('⭐⭐ ينسخ المرفقات فعلاً — إثبات ع-٤١', () async {
      await seedTreasury('الرئيسية');
      await seedAttachment('2026/سند-1/فاتورة.pdf');
      await seedAttachment('2026/سند-2/وصل.pdf');

      final report = await BackupService.exportFull(
        db: db,
        dbFilePath: dbPath,
        destinationDir: backupsRoot,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
      );

      // 🔴 قبل الإصلاح كان الجذر يُقرأ من مزوّد autoDispose غير مُراقَب
      //   فيعود `''` دائماً ⇒ صفر مرفق، والرسالة تقول «تمّت النسخة الشاملة».
      expect(report.attachmentsCopied, 2,
          reason: 'النسخة الشاملة يجب أن تحوي المرفقات فعلاً');
      expect(report.attachmentsMissing, 0);

      expect(
        File('${report.path}/${BackupLayout.databaseFile}').existsSync(),
        isTrue,
      );
      expect(
        File('${report.path}/${BackupLayout.attachmentsDir}/'
                '2026/سند-1/فاتورة.pdf')
            .existsSync(),
        isTrue,
        reason: 'الملف نفسه على القرص لا مجرّد عدّاد',
      );
      expect(
        File('${report.path}/${BackupLayout.manifestFile}').existsSync(),
        isTrue,
      );
      expect(
        File('${report.path}/${BackupLayout.readmeFile}').existsSync(),
        isTrue,
      );
    });

    test('⭐⭐ مرفقات في الفهرس بلا جذر مُعيَّن ⇒ رفض لا صمت', () async {
      await seedAttachment('2026/سند-1/فاتورة.pdf');

      // الصمت هو ما جعل ع-٤١ يعيش: «نسخة شاملة» بلا مرفق واحد تُبلّغ بالنجاح.
      await expectLater(
        BackupService.exportFull(
          db: db,
          dbFilePath: dbPath,
          destinationDir: backupsRoot,
          attachmentsRoot: '',
          password: kPassword,
        ),
        throwsA(isA<StateError>().having((e) => e.message, 'الرسالة',
            allOf(contains('مجلد المرفقات'), contains('الإعدادات')))),
      );
    });

    test('⭐ المرفق المفقود من القرص يُعدّ ولا يُفشل النسخة', () async {
      await seedAttachment('2026/سند-1/موجود.pdf');
      // صفّ في الفهرس بلا ملف — يقع حين يحذف المستخدم الملف يدوياً
      await db.into(db.attachments).insert(
            AttachmentsCompanion.insert(
              entityType: 'voucher',
              entityId: 2,
              fileName: 'مفقود.pdf',
              relativePath: '2026/سند-9/مفقود.pdf',
            ),
          );

      final report = await BackupService.exportFull(
        db: db,
        dbFilePath: dbPath,
        destinationDir: backupsRoot,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
      );

      expect(report.attachmentsCopied, 1);
      expect(report.attachmentsMissing, 1,
          reason: 'يُقال للمالك لا يُبتلع');
    });

    test('⭐ البيان الآليّ يحمل إصدار المخطط وقائمة المرفقات', () async {
      await seedAttachment('2026/سند-1/فاتورة.pdf');
      final report = await BackupService.exportFull(
        db: db,
        dbFilePath: dbPath,
        destinationDir: backupsRoot,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
      );

      final manifest = await BackupService.inspect(report.path);
      expect(manifest.isLegacy, isFalse);
      expect(manifest.schemaVersion, db.schemaVersion);
      expect(manifest.attachments, hasLength(1));
      expect(manifest.attachments.single.relativePath,
          '2026/سند-1/فاتورة.pdf');
      expect(manifest.attachments.single.sha256, isNotEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('الفحص قبل الاستعادة', () {
    test('⭐⭐ مجلد ليس نسخة ⇒ StateError موجِّه', () async {
      await expectLater(
        BackupService.inspect(backupsRoot),
        throwsA(isA<StateError>().having((e) => e.message, 'الرسالة',
            contains(BackupLayout.databaseFile))),
      );
    });

    test('⭐ مجلد غير موجود ⇒ StateError', () async {
      await expectLater(
        BackupService.inspect('${tmp.path}/لا-وجود-له'),
        throwsA(isA<StateError>()),
      );
    });

    test('⭐ نسخة قديمة بلا بيان آليّ تُقبَل وتُعلَّم legacy', () async {
      await seedTreasury('الرئيسية');
      final report = await BackupService.exportFull(
        db: db,
        dbFilePath: dbPath,
        destinationDir: backupsRoot,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
      );
      // محاكاة نسخةٍ أُخذت قبل 2026-08-30
      await File('${report.path}/${BackupLayout.manifestFile}').delete();

      final manifest = await BackupService.inspect(report.path);
      expect(manifest.isLegacy, isTrue);
      expect(manifest.schemaVersion, isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('الاستعادة الشاملة', () {
    test('⭐⭐⭐ الدورة الكاملة: صدّر ⇒ امحُ ⇒ استعد ⇒ عاد كل شيء', () async {
      // ── ١) بيانات وملفات ───────────────────────────────────────────
      await seedTreasury('خزنة بغداد');
      await seedTreasury('خزنة البصرة');
      await seedAttachment('2026/سند-1/فاتورة.pdf');
      await seedAttachment('2026/سلفة-23/وصل.pdf');

      final report = await BackupService.exportFull(
        db: db,
        dbFilePath: dbPath,
        destinationDir: backupsRoot,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
      );
      expect(report.attachmentsCopied, 2);

      // ── ٢) محوٌ كامل: القاعدة والملفات معاً ────────────────────────
      await db.factoryReset();
      await Directory(attachmentsRoot).delete(recursive: true);
      await Directory(attachmentsRoot).create(recursive: true);

      expect(await db.treasuriesDao.watchAllTreasuries().first, isEmpty,
          reason: 'الشرط المسبق: القاعدة صارت فارغة');

      // ── ٣) الاستعادة ───────────────────────────────────────────────
      final restore = await BackupService.restoreFull(
        db: db,
        dbFilePath: dbPath,
        backupDir: report.path,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
        user: actor(),
      );

      expect(restore.attachmentsRestored, 2);
      expect(restore.attachmentsSkipped, 0);
      expect(File(restore.safetyCopyPath).existsSync(), isTrue,
          reason: 'نسخة أمان من القاعدة الممحوّة قبل دهسها');

      // ── ٤) الملفات عادت إلى القرص ──────────────────────────────────
      for (final rel in const ['2026/سند-1/فاتورة.pdf', '2026/سلفة-23/وصل.pdf']) {
        expect(
          File(AttachmentService.absolutePathOf(
            root: attachmentsRoot,
            relativePath: rel,
          )).existsSync(),
          isTrue,
          reason: 'المرفق $rel يجب أن يعود إلى القرص',
        );
      }

      // ── ٥) الصفوف عادت إلى القاعدة ─────────────────────────────────
      // القاعدة أُغلقت داخل الاستعادة — نفتح اتصالاً جديداً على الملف
      // المُستعاد، وهو نفسه ما يفعله التطبيق بعد إعادة التشغيل.
      db = openDb();
      final treasuries = await db.treasuriesDao.watchAllTreasuries().first;
      expect(treasuries.map((t) => t.name), containsAll(
        ['خزنة بغداد', 'خزنة البصرة'],
      ));
      expect(await db.attachmentsDao.getAll(), hasLength(2),
          reason: 'فهرس المرفقات عاد مع القاعدة');
    });

    test('⭐⭐ كلمة مرور خاطئة ⇒ لا تُلمس القاعدة الحالية', () async {
      await seedTreasury('الأصلية');
      final report = await BackupService.exportFull(
        db: db,
        dbFilePath: dbPath,
        destinationDir: backupsRoot,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
      );

      // نغيّر القاعدة بعد النسخة، فلو وقعت استعادةٌ لضاع التغيير
      await seedTreasury('بعد النسخة');

      await expectLater(
        BackupService.restoreFull(
          db: db,
          dbFilePath: dbPath,
          backupDir: report.path,
          attachmentsRoot: attachmentsRoot,
          password: 'كلمة-خاطئة',
          user: actor(),
        ),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'الرسالة', contains('كلمة المرور غير صحيحة'))),
      );

      // الفشل وقع **قبل** أي كتابة: القاعدة كما تركناها
      final names =
          (await db.treasuriesDao.watchAllTreasuries().first).map((t) => t.name);
      expect(names, contains('بعد النسخة'),
          reason: 'كلمة مرور خاطئة يجب ألّا تكلّف المالك شيئاً');
    });

    test('⭐⭐ غير مدير النظام يُرفض قبل أي فحص', () async {
      // Drift ينشئ ملف القاعدة عند **أول استعلام** لا عند فتح الاتصال —
      // فبلا كتابةٍ أولى لا يوجد ملف يُصدَّر أصلاً.
      await seedTreasury('الرئيسية');
      final report = await BackupService.exportFull(
        db: db,
        dbFilePath: dbPath,
        destinationDir: backupsRoot,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
      );

      await expectLater(
        BackupService.restoreFull(
          db: db,
          dbFilePath: dbPath,
          backupDir: report.path,
          attachmentsRoot: attachmentsRoot,
          password: kPassword,
          user: actor(role: 'admin'),
        ),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'الرسالة', contains('مدير النظام'))),
      );
    });

    test('⭐⭐ مخطط أحدث من التطبيق ⇒ رفض بلا كسر', () async {
      await seedTreasury('الرئيسية');
      final report = await BackupService.exportFull(
        db: db,
        dbFilePath: dbPath,
        destinationDir: backupsRoot,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
      );

      // محاكاة نسخة أُخذت بإصدار مستقبليّ
      final mf = File('${report.path}/${BackupLayout.manifestFile}');
      await mf.writeAsString(
        (await mf.readAsString()).replaceFirst(
          '"schemaVersion": ${db.schemaVersion}',
          '"schemaVersion": ${db.schemaVersion + 1}',
        ),
      );

      await expectLater(
        BackupService.restoreFull(
          db: db,
          dbFilePath: dbPath,
          backupDir: report.path,
          attachmentsRoot: attachmentsRoot,
          password: kPassword,
          user: actor(),
        ),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'الرسالة', contains('أحدث من التطبيق'))),
      );
    });

    test('⭐⭐ نسخة بمرفقات وجذرٌ غير مُعيَّن ⇒ رفض موجِّه', () async {
      await seedAttachment('2026/سند-1/فاتورة.pdf');
      final report = await BackupService.exportFull(
        db: db,
        dbFilePath: dbPath,
        destinationDir: backupsRoot,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
      );

      await expectLater(
        BackupService.restoreFull(
          db: db,
          dbFilePath: dbPath,
          backupDir: report.path,
          attachmentsRoot: '',
          password: kPassword,
          user: actor(),
        ),
        throwsA(isA<StateError>().having((e) => e.message, 'الرسالة',
            allOf(contains('مجلد المرفقات'), contains('الإعدادات')))),
      );
    });

    test('⭐⭐ الملف الموجود يُتخطّى ولا يُدهَس', () async {
      await seedAttachment('2026/سند-1/فاتورة.pdf');
      final report = await BackupService.exportFull(
        db: db,
        dbFilePath: dbPath,
        destinationDir: backupsRoot,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
      );

      // ملفٌ أحدث في نفس المسار — الدهس يفقده بلا رجعة
      final live = File(AttachmentService.absolutePathOf(
        root: attachmentsRoot,
        relativePath: '2026/سند-1/فاتورة.pdf',
      ));
      await live.writeAsString('نسخة أحدث لا يجوز دهسها', flush: true);

      final restore = await BackupService.restoreFull(
        db: db,
        dbFilePath: dbPath,
        backupDir: report.path,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
        user: actor(),
      );

      expect(restore.attachmentsSkipped, 1);
      expect(restore.attachmentsRestored, 0);
      expect(await live.readAsString(), 'نسخة أحدث لا يجوز دهسها',
          reason: 'التخطّي يُبلَّغ عنه — والدهس لا رجعة فيه');
    });

    // ── ع-٤٤: بلاغ المالك 2026-08-30 ────────────────────────────────
    //
    // ظهر عند الاستعادة الحقيقية على ويندوز:
    //   PathAccessException: Cannot delete file … sales_management_db.sqlite-wal
    //   (The process cannot access the file … errno = 32)
    // والاستعادة كانت قد **نجحت فعلاً** — فبدت فاشلة وهي ناجحة.
    //
    // السبب: `drift_flutter` يفتح القاعدة في isolate منفصل، و`close()` لا
    // ينتظر تحرير مقبض الملف على مستوى نظام التشغيل.

    test('⭐⭐ ملفا -wal و-shm يُحذفان مع الاستعادة (ع-٤٤)', () async {
      await seedTreasury('الرئيسية');
      final report = await BackupService.exportFull(
        db: db,
        dbFilePath: dbPath,
        destinationDir: backupsRoot,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
      );

      // سايدكار قائم لحظة الاستعادة — الحالة الواقعية تماماً
      final wal = File('$dbPath-wal');
      final shm = File('$dbPath-shm');
      if (!wal.existsSync()) await wal.writeAsBytes(const [], flush: true);
      if (!shm.existsSync()) await shm.writeAsBytes(const [], flush: true);

      final restore = await BackupService.restoreFull(
        db: db,
        dbFilePath: dbPath,
        backupDir: report.path,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
        user: actor(),
      );

      expect(wal.existsSync(), isFalse, reason: '-wal لا يبقى فوق قاعدة مستعادة');
      expect(shm.existsSync(), isFalse);
      expect(restore.warning, isNull,
          reason: 'لا تحذير حين يُحرَّر السايدكار كما يجب');
    });

    test('⭐⭐ الاستعادة تنجح ولا ترمي على تعثّر السايدكار (ع-٤٤)', () async {
      await seedTreasury('قبل النسخة');
      final report = await BackupService.exportFull(
        db: db,
        dbFilePath: dbPath,
        destinationDir: backupsRoot,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
      );
      await db.factoryReset();

      // 🔴 قبل الإصلاح: الدهس يقع أولاً ثم يُحذف السايدكار — فرمية القفل
      //   تخرج **بعد** نجاح الاستعادة، فيرى المالك «خطأ» على عملية تمّت.
      //   بعده: التحرير قبل الدهس، والفشل غير القاتل تحذيرٌ لا استثناء.
      await expectLater(
        BackupService.restoreFull(
          db: db,
          dbFilePath: dbPath,
          backupDir: report.path,
          attachmentsRoot: attachmentsRoot,
          password: kPassword,
          user: actor(),
        ),
        completes,
      );

      db = openDb();
      final names =
          (await db.treasuriesDao.watchAllTreasuries().first).map((t) => t.name);
      expect(names, contains('قبل النسخة'));
    });

    test('⭐ ملفٌ فُكّ تشفيره وليس قاعدة ⇒ رفض قبل الدهس', () async {
      await seedTreasury('الأصلية');
      final report = await BackupService.exportFull(
        db: db,
        dbFilePath: dbPath,
        destinationDir: backupsRoot,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
      );

      // نستبدل القاعدة المشفَّرة بنصّ مشفَّر بنفس كلمة المرور — يفكّ بنجاح
      // ثم يتبيّن أنه ليس SQLite. لولا فحص الترويسة لدُهست القاعدة به.
      final fake = await BackupService.exportFull(
        db: db,
        dbFilePath: dbPath,
        destinationDir: backupsRoot,
        attachmentsRoot: attachmentsRoot,
        password: kPassword,
      );
      await File('${fake.path}/${BackupLayout.databaseFile}')
          .writeAsBytes(await _encryptedGarbage(kPassword), flush: true);

      await expectLater(
        BackupService.restoreFull(
          db: db,
          dbFilePath: dbPath,
          backupDir: fake.path,
          attachmentsRoot: attachmentsRoot,
          password: kPassword,
          user: actor(),
        ),
        throwsA(isA<StateError>().having((e) => e.message, 'الرسالة',
            contains('ليس قاعدة بيانات سليمة'))),
      );

      expect(report.path, isNotEmpty); // النسخة السليمة ما زالت قائمة
    });
  });
}

/// بايتات مشفَّرة بكلمة المرور نفسها — تفكّ بنجاح ثم يتبيّن أنها ليست قاعدة
///
/// هذه هي الحالة التي يحرسها فحص ترويسة SQLite: التشفير سليم والتوقيع صحيح،
/// فلا يمسكها فكُّ التشفير — ولولا الفحص لدُهست القاعدة بها.
Future<Uint8List> _encryptedGarbage(String password) async {
  final plain = Uint8List.fromList(List.generate(2048, (i) => (i * 7) % 256));
  return BackupCryptoService.encrypt(plain, password);
}
