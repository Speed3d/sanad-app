// ─────────────────────────────────────────────────────────────────────────────
// database_location_test.dart — موضع القاعدة: المؤشّر · النقل · فتح قاعدة أخرى
//
// قرار المالك (2026-10-12): «مجلد تختاره أنت». والاختبارات هنا تحرس ما يجعل
// الميزة آمنة لا ما يجعلها تعمل فقط:
//   • لا تراجعَ صامت حين يغيب الموضع المحفوظ
//   • النقل الفاشل لا يمسّ شيئاً — والناجح يُطابق كل جدول
//   • الفحص لا يكتب في ما يفحصه
//   • لا يُبنى مسار القاعدة خارج DatabaseLocation (حارس مصدر)
//
// كلها على **ملفات حقيقية** في مجلد مؤقّت — النقل يعمل على أقراص، ولا معنى
// لاختباره في الذاكرة.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sales_management/core/constants/app_settings_keys.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/database/database_location.dart';
import 'package:sales_management/data/database/probe_database.dart';

void main() {
  late Directory tmp;
  late String docs; // «المستندات» — الموضع الافتراضي
  late String pointerDir; // «AppData\Sanad»
  late String installDir; // مجلد البرنامج المثبَّت
  late DriveKind fakeDrive;

  /// قاعدة فحص على ملف حقيقي — NativeDatabase لا driftDatabase (لا plugins هنا)
  Future<ProbeDatabase> testProbe() async {
    final parent = Directory(p.join(tmp.path, 'probes'));
    await parent.create(recursive: true);
    final d = await parent.createTemp('p');
    return ProbeDatabase(NativeDatabase(File(p.join(d.path, 'probe.sqlite'))),
        scratch: d);
  }

  DatabaseLocation service() => DatabaseLocation(
        defaultDirectory: docs,
        pointerDirectory: pointerDir,
        installDirectory: installDir,
        openProbe: testProbe,
        driveKind: (_) async => fakeDrive,
        clock: () => DateTime(2026, 10, 12, 18, 30, 5),
      );

  /// قاعدة سند حقيقية مزروعة — خزينتان واسم شركة
  Future<String> seedSanadDb(String dir, {String company = 'شركة الاختبار'}) async {
    await Directory(dir).create(recursive: true);
    final path = p.join(dir, DatabaseLocation.databaseFileName);
    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    await db.appSettingsDao.setString(AppSettingsKeys.companyName, company);
    await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );
    await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'البصرة', kind: const Value('main')),
    );
    await db.close();
    return path;
  }

  /// بايتات الملف كاملة — «لم يتغيّر» تعني بايتاً ببايت لا حجماً ولا تاريخاً
  List<int> hashOf(String path) => File(path).readAsBytesSync();

  Future<int> countWhere(String dbPath, String sql) async {
    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    try {
      final r = await db.customSelect(sql).getSingle();
      return r.data.values.first as int;
    } finally {
      await db.close();
    }
  }

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('sanad_location_test');
    docs = p.join(tmp.path, 'Documents');
    pointerDir = p.join(tmp.path, 'AppData', 'Sanad');
    installDir = p.join(tmp.path, 'Programs', 'Sanad');
    await Directory(docs).create(recursive: true);
    await Directory(installDir).create(recursive: true);
    fakeDrive = DriveKind.fixed;
  });

  tearDown(() async {
    for (var i = 0; i < 8; i++) {
      try {
        if (tmp.existsSync()) tmp.deleteSync(recursive: true);
        return;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
  });

  // ══════════════════════════════════════════════════════════════════════
  group('أين القاعدة؟ — resolve', () {
    test('بلا مؤشّر: المستندات — والقواعد القائمة قبل الميزة تعمل كما هي', () {
      final r = service().resolve();
      expect(r.isUsable, isTrue);
      expect(r.isCustom, isFalse);
      expect(r.databasePath, p.join(docs, 'sales_management_db.sqlite'));
    });

    test('مؤشّرٌ إلى مجلدٍ فيه القاعدة: يُعتمَد', () async {
      final dir = p.join(tmp.path, 'D', 'SanadData');
      await seedSanadDb(dir);
      await service().writePointer(dir);

      final r = service().resolve();
      expect(r.isUsable, isTrue);
      expect(r.isCustom, isTrue);
      expect(r.databasePath, p.join(dir, DatabaseLocation.databaseFileName));
    });

    test('⭐⭐⭐ مجلدٌ غائب (قرصٌ مفصول): مشكلةٌ تُقال — **لا تراجع صامت ولا إنشاء**',
        () async {
      final dir = p.join(tmp.path, 'E', 'Unplugged');
      await service().writePointer(dir);
      // نسخةٌ في المستندات **موجودة** — والتراجع إليها هو الخطر بعينه
      await seedSanadDb(docs, company: 'نسخة قديمة');

      final r = service().resolve();
      expect(r.isUsable, isFalse);
      expect(r.problem, LocationProblem.folderMissing);
      expect(r.databasePath, isNot(p.join(docs, DatabaseLocation.databaseFileName)),
          reason: 'لو عاد إلى المستندات لعمل المالك على النسخة القديمة');
      expect(Directory(dir).existsSync(), isFalse,
          reason: 'السؤال لا يُنشئ المجلد الغائب');
    });

    test('⭐⭐ المجلد موجود والملف غائب: مشكلة — لا قاعدة جديدة فارغة', () async {
      final dir = p.join(tmp.path, 'D', 'Empty');
      await Directory(dir).create(recursive: true);
      await service().writePointer(dir);

      final r = service().resolve();
      expect(r.problem, LocationProblem.databaseMissing);
      expect(File(p.join(dir, DatabaseLocation.databaseFileName)).existsSync(),
          isFalse);
    });

    test('⭐ مؤشّرٌ فارغ أو تالف: مشكلة — لا يُعامَل كأنه غائب', () async {
      await Directory(pointerDir).create(recursive: true);
      File(p.join(pointerDir, DatabaseLocation.pointerFileName))
          .writeAsStringSync('   \n');
      expect(service().resolve().problem, LocationProblem.pointerUnreadable);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('المؤشّر', () {
    test('⭐ مسارٌ عربي يُكتَب ويُقرأ كما هو — والكتابة الثانية تستبدل الأولى',
        () async {
      final a = p.join(tmp.path, 'بيانات سند', 'أ');
      final b = p.join(tmp.path, 'بيانات سند', 'ب');
      await seedSanadDb(a);
      await seedSanadDb(b);

      await service().writePointer(a);
      await service().writePointer(b); // إعادة التسمية فوق ملفٍ قائم
      expect(service().resolve().directory, b);
    });

    test('الموضع الافتراضي يحذف المؤشّر بدل أن يكتب المستندات فيه', () async {
      final dir = p.join(tmp.path, 'D', 'X');
      await service().writePointer(dir);
      expect(service().pointerFile.existsSync(), isTrue);

      await service().writePointer(docs);
      expect(service().pointerFile.existsSync(), isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('فحص الوجهة', () {
    late String target;
    setUp(() async {
      target = p.join(tmp.path, 'D', 'SanadData');
      await Directory(target).create(recursive: true);
    });

    Future<FolderCheck> check(String t) => service()
        .checkMoveTarget(t, currentDirectory: docs);

    test('مجلدٌ سليم: مقبول بلا تحذير', () async {
      final c = await check(target);
      expect(c.isAllowed, isTrue);
      expect(c.warnings, isEmpty);
    });

    test('⭐⭐ مسار شبكة \\\\server: مرفوض — SQLite يُفسد القاعدة عليه', () async {
      expect((await check(r'\\server\share\sanad')).isAllowed, isFalse);
    });

    test('⭐⭐ قرص شبكة مُعيَّن بحرف (Z:): مرفوض بسؤال نوع القرص', () async {
      fakeDrive = DriveKind.network;
      expect((await check(target)).isAllowed, isFalse);
    });

    test('قرصٌ قابل للفصل: يُحذَّر ولا يُمنع', () async {
      fakeDrive = DriveKind.removable;
      final c = await check(target);
      expect(c.isAllowed, isTrue);
      expect(c.warnings, isNotEmpty);
    });

    test('مجلد OneDrive: يُحذَّر ولا يُمنع', () async {
      final od = p.join(tmp.path, 'OneDrive - Company', 'Sanad');
      await Directory(od).create(recursive: true);
      final c = await check(od);
      expect(c.isAllowed, isTrue);
      expect(c.warnings.single, contains('OneDrive'));
    });

    test('⭐⭐ داخل مجلد البرنامج: مرفوض — المثبِّت يمحو {app}\\data', () async {
      final inside = p.join(installDir, 'data');
      await Directory(inside).create(recursive: true);
      expect((await check(inside)).isAllowed, isFalse);
    });

    test('⭐⭐ مجلدٌ فيه قاعدة سند أخرى: مرفوض — النقل لا يدهس', () async {
      await seedSanadDb(target);
      final c = await check(target);
      expect(c.isAllowed, isFalse);
      expect(c.errors.single, contains('فتح قاعدة موجودة'));
    });

    test('المجلد الحالي نفسه · مسارٌ نسبي · مجلدٌ غائب: مرفوضة', () async {
      expect((await check(docs)).isAllowed, isFalse);
      expect((await check(r'SanadData')).isAllowed, isFalse);
      expect((await check(p.join(tmp.path, 'nope'))).isAllowed, isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('النقل', () {
    late String source;
    late String target;
    var closed = false;

    setUp(() async {
      source = await seedSanadDb(docs);
      target = p.join(tmp.path, 'D', 'SanadData');
      await Directory(target).create(recursive: true);
      closed = false;
    });

    Future<MoveReport> doMove() => service().move(
          targetDirectory: target,
          sourceDatabasePath: source,
          closeLiveDatabase: () async => closed = true,
          actor: const LocationActor(userId: 1, username: 'admin'),
        );

    test('⭐⭐⭐ النقل الناجح: البيانات كلها هناك · المؤشّر يشير · القديم مُقاعَد',
        () async {
      final report = await doMove();
      final moved = p.join(target, DatabaseLocation.databaseFileName);

      expect(closed, isTrue, reason: 'القاعدة الحيّة تُغلق قبل النسخ');
      expect(report.newDatabasePath, moved);
      expect(service().resolve().databasePath, moved);

      // البيانات وصلت — تُفتح بـ AppDatabase نفسه وتُقرأ
      final db = AppDatabase.forTesting(NativeDatabase(File(moved)));
      final names = (await db.treasuriesDao.getAllTreasuries())
          .map((t) => t.name)
          .toSet();
      expect(names, containsAll(['الرئيسية', 'البصرة']));
      expect(await db.appSettingsDao.getString(AppSettingsKeys.companyName),
          'شركة الاختبار');
      await db.close();

      // القديم لا يُحذف ولا يبقى باسمه
      expect(File(source).existsSync(), isFalse,
          reason: 'لو بقي باسمه لفُتح بصمت إن ضاع المؤشّر');
      expect(report.retiredPaths, isNotEmpty);
      expect(report.retiredPaths.first, endsWith('.moved_20261012_183005'));
      expect(File(report.retiredPaths.first).existsSync(), isTrue);
      expect(File('$moved.partial').existsSync(), isFalse);
    });

    test('⭐⭐ سطر التدقيق في المنقولة وحدها — القديمة لا تزعم نقلاً', () async {
      final report = await doMove();
      const q = "SELECT count(*) AS c FROM audit_log WHERE action = 'DATABASE_MOVE'";
      expect(await countWhere(report.newDatabasePath, q), 1);
      expect(await countWhere(report.retiredPaths.first, q), 0);
    });

    test('⭐⭐⭐ النقل الفاشل لا يمسّ شيئاً: القاعدة كما هي · لا مؤشّر · لا بقايا',
        () async {
      // ملفٌ تالف في مكان القاعدة — يفشل النسخ بعد الإغلاق، أي في أخطر نقطة
      File(source).writeAsStringSync('ليست قاعدة بيانات');
      final before = hashOf(source);

      await expectLater(doMove(), throwsA(isA<StateError>().having(
          (e) => e.message, 'message', contains('لم تُمَسّ'))));

      expect(hashOf(source), before);
      expect(service().pointerFile.existsSync(), isFalse);
      expect(Directory(target).listSync(), isEmpty,
          reason: 'لا .partial ولا نسخة نصفية في الوجهة');
      expect(service().resolve().databasePath, source);
    });

    test('⭐ الوجهة المرفوضة تُرفض **قبل** إغلاق القاعدة الحيّة', () async {
      fakeDrive = DriveKind.network;
      await expectLater(doMove(), throwsA(isA<StateError>()));
      expect(closed, isFalse, reason: 'الحارس في الخدمة لا في الواجهة وحدها');
    });

    test('الإعادة إلى المستندات: نقلٌ عكسي يحذف المؤشّر', () async {
      await doMove();
      final movedPath = p.join(target, DatabaseLocation.databaseFileName);

      await service().move(
        targetDirectory: docs,
        sourceDatabasePath: movedPath,
        closeLiveDatabase: () async {},
        actor: const LocationActor(userId: 1, username: 'admin'),
      );
      expect(service().pointerFile.existsSync(), isFalse);
      final r = service().resolve();
      expect(r.isCustom, isFalse);
      expect(File(r.databasePath).existsSync(), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('فحص قاعدة مرشّحة — لا يكتب فيما يفحصه', () {
    test('⭐⭐⭐ لماذا قاعدة فحص؟ — AppDatabase **يكتب جداول سند** في ملفٍ أجنبي',
        () async {
      // هذا الاختبار يُثبت الخطر الذي بُنيت ProbeDatabase من أجله. فإن
      // «بسّطها» أحدٌ يوماً إلى فتح المرشّح بـ AppDatabase، فهذا ما سيقع.
      final foreign = p.join(tmp.path, 'foreign.sqlite');
      final raw = ProbeDatabase(NativeDatabase(File(foreign)));
      await raw.customStatement('CREATE TABLE notes (body TEXT)');
      await raw.customStatement('PRAGMA user_version = 0');
      await raw.close();

      final db = AppDatabase.forTesting(NativeDatabase(File(foreign)));
      await db.customSelect('SELECT 1').get(); // أي استعلام يُطلق الترحيل
      await db.close();

      expect(await countWhere(foreign,
              "SELECT count(*) AS c FROM sqlite_master WHERE name = 'users'"),
          1, reason: 'فتحُه بـ AppDatabase أنشأ جدول users في ملفٍ ليس لنا');
    });

    test('⭐⭐⭐ ملف SQLite أجنبي: يُرفض **ويبقى كما هو بايتاً ببايت**', () async {
      final dir = p.join(tmp.path, 'Other');
      await Directory(dir).create();
      final foreign = p.join(dir, DatabaseLocation.databaseFileName);
      final raw = ProbeDatabase(NativeDatabase(File(foreign)));
      await raw.customStatement('CREATE TABLE notes (body TEXT)');
      await raw.close();
      final before = hashOf(foreign);

      await expectLater(
        service().inspect(foreign, appSchemaVersion: 10),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'message', contains('ليس قاعدة سند'))),
      );
      expect(hashOf(foreign), before);
    });

    test('⭐⭐ قاعدة من إصدارٍ أحدث: تُرفض', () async {
      final path = await seedSanadDb(p.join(tmp.path, 'Newer'));
      final raw = ProbeDatabase(NativeDatabase(File(path)));
      await raw.customStatement('PRAGMA user_version = 99');
      await raw.close();

      await expectLater(
        service().inspect(path, appSchemaVersion: 10),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'message', contains('أحدث'))),
      );
    });

    test('ملفٌ ليس SQLite أصلاً: يُرفض من ترويسته', () async {
      final f = File(p.join(tmp.path, 'x.sqlite'))..writeAsStringSync('hello');
      await expectLater(service().inspect(f.path, appSchemaVersion: 10),
          throwsA(isA<StateError>()));
    });

    test('⭐ قاعدة سند سليمة: يُعرَض ما فيها قبل القرار', () async {
      final path = await seedSanadDb(p.join(tmp.path, 'Good'), company: 'سند للمقاولات');
      final before = hashOf(path);

      final c = await service().inspect(path, appSchemaVersion: 10);
      expect(c.companyName, 'سند للمقاولات');
      expect(c.schemaVersion, AppDatabase.currentSchemaVersion);
      expect(hashOf(path), before, reason: 'الفحص قراءةٌ فقط');
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('فتح قاعدة موجودة — النجاة من إعادة تثبيت ويندوز', () {
    test('⭐⭐⭐ ويندوز جديد: قاعدة فارغة في المستندات ⇒ تُفتح D:\\ وتُقاعَد الفارغة',
        () async {
      // بعد إعادة التثبيت: المؤشّر ممحوّ، وأول فتحٍ أنشأ قاعدةً فارغة هنا
      final fresh = await seedSanadDb(docs, company: '');
      final saved = p.join(tmp.path, 'D', 'SanadData');
      await seedSanadDb(saved, company: 'بياناتي الحقيقية');

      final c = await service().attach(
        directory: saved,
        appSchemaVersion: 10,
        currentDirectory: docs,
      );
      expect(c.companyName, 'بياناتي الحقيقية');
      expect(service().resolve().directory, saved);
      expect(File(fresh).existsSync(), isFalse,
          reason: 'الفارغة تُقاعَد كي لا تُفتح بصمت إن ضاع المؤشّر ثانيةً');
    });

    test('⭐ القاعدة المفتوحة الآن نفسها: تُرفض', () async {
      await seedSanadDb(docs);
      await expectLater(
        service().attach(directory: docs, appSchemaVersion: 10, currentDirectory: docs),
        throwsA(isA<StateError>()),
      );
    });

    test('⭐⭐ مرشّحٌ مرفوض: لا تُغلق القاعدة الحيّة ولا يُكتب مؤشّر', () async {
      final bad = p.join(tmp.path, 'Bad');
      await Directory(bad).create();
      File(p.join(bad, DatabaseLocation.databaseFileName)).writeAsStringSync('x');
      var closed = false;

      await expectLater(
        service().attach(
          directory: bad,
          appSchemaVersion: 10,
          currentDirectory: docs,
          closeLiveDatabase: () async => closed = true,
        ),
        throwsA(isA<StateError>()),
      );
      expect(closed, isFalse);
      expect(service().pointerFile.existsSync(), isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('تقاعد النسخة المتخلّفة عند الإقلاع', () {
    test('⭐⭐ المؤشّر يشير إلى D:\\ ونسخةٌ باقية في المستندات: تُعاد تسميتها',
        () async {
      final stale = await seedSanadDb(docs, company: 'قديمة');
      final live = p.join(tmp.path, 'D', 'SanadData');
      await seedSanadDb(live);
      await service().writePointer(live);

      final renamed =
          await service().retireStaleDefaultCopy(service().resolve());
      expect(File(stale).existsSync(), isFalse);
      expect(renamed.single, endsWith('.inactive_20261012_183005'));
    });

    test('بلا مؤشّر: لا يُمسّ شيء — المستندات هي القاعدة الحيّة', () async {
      final live = await seedSanadDb(docs);
      final renamed =
          await service().retireStaleDefaultCopy(service().resolve());
      expect(renamed, isEmpty);
      expect(File(live).existsSync(), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  test('⭐⭐⭐ حارس المصدر: اسم ملف القاعدة لا يُبنى خارج DatabaseLocation', () {
    // كان المسار يُبنى في خمسة مواضع مستقلّة حتى 2026-10-12، فمن يغيّر موضع
    // القاعدة في واحدٍ تصير الاستعادة تكتب في ملفٍ لا يُقرأ — وتُبلّغ بالنجاح.
    // التعليقات مستثناة: ذكر الاسم شرحاً ليس بناءً له.
    final offenders = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))) {
      if (p.basename(f.path) == 'database_location.dart') continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].split('//').first;
        if (code.contains('sales_management_db')) {
          offenders.add('${f.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'اسأل DatabaseLocation أو activeDatabasePathProvider:\n'
            '${offenders.join('\n')}');
  });
}
