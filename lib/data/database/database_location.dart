// ─────────────────────────────────────────────────────────────────────────────
// database_location.dart — موضع قاعدة البيانات: المصدر الوحيد ونقله وفتح غيره
//
// ═══ لماذا وُجد هذا الملف (قرار المالك 2026-10-12) ═══
//   سأل المالك: «هل أستطيع تغيير مكان sales_management_db.sqlite؟». فكشف
//   الفحص أن الموضع لم يكن قراراً قط بل **افتراضيّ** `driftDatabase`
//   (Documents)، وأن المسار مكتوب في **خمسة مواضع مستقلّة**: فتح القاعدة،
//   وثلاثة في شاشة النسخ الاحتياطي، والمثبِّت. فمن يغيّر واحداً تصير
//   الاستعادة تكتب في ملفٍ لا يقرؤه البرنامج — **وتُبلّغ بالنجاح** (نمط ع-٦٠:
//   معنىً واحد في أماكن متعدّدة).
//
//   فهذا الملف هو المصدر الوحيد للمسار، ويحرسه اختبار يفحص المصدر:
//   `sales_management_db` لا يظهر في شيفرة خارجه.
//
// ═══ كيف يُحفَظ الموضع ═══
//   لا يمكن حفظه **داخل** القاعدة — نحتاجه لنعرف أين القاعدة. فيُحفَظ في
//   «ملف مؤشّر» نصّي صغير:
//       %LOCALAPPDATA%\Sanad\db_location.txt   ← سطرٌ واحد: مسار المجلد
//   • LOCAL لا ROAMING: المسار خاصّ بهذا الجهاز (D:\ قد لا يوجد على غيره)
//   • غيابه = الموضع الافتراضي (Documents) — فالقواعد القائمة تعمل كما هي
//   • والمثبِّت يقرؤه ليجد القاعدة فينسخها احتياطياً (installer/sanad.iss)
//
// ═══ القاعدة الذهبية: لا تراجعَ صامت ═══
//   إن أشار المؤشّر إلى مجلدٍ غاب (قرصٌ خارجي فُصل، مجلدٌ حُذف) فالبرنامج
//   **لا يعود إلى Documents بصمت**. لو فعل لفتح قاعدةً فارغة (أو نسخةً
//   قديمة) فيظنّ المالك أن بياناته ضاعت — أو أسوأ: يُدخل فيها ويعمل على
//   نسختين متباعدتين. بل تظهر شاشةٌ تقول ما حدث وتعرض الخيارات (نمط ع-٦١:
//   القاعدة التي تُلغي ما يعرفه المالك يجب أن **تُقال** لا أن تقع).
//
// ═══ ولهذا أيضاً «تقاعد» النسخة الافتراضية ═══
//   بعد النقل تُعاد تسمية الملف القديم (`.moved_…`) **ولا يُحذف**. لو بقي
//   باسمه ثم ضاع المؤشّر (إعادة تثبيت ويندوز تمحو AppData) لفتح البرنامج
//   تلك النسخة القديمة **بصمت** كأنها الحالية. والاسم الجديد يمنع ذلك
//   ويبقي البيانات قابلة للاسترجاع.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_settings_keys.dart';
import 'probe_database.dart';

// ══════════════════════════════════════════════════════════════════════════
// الأنواع
// ══════════════════════════════════════════════════════════════════════════

/// لماذا تعذّر استعمال الموضع المحفوظ
enum LocationProblem {
  /// المؤشّر يشير إلى مجلدٍ غير موجود (قرص مفصول · مجلد محذوف أو منقول)
  folderMissing,

  /// المجلد موجود وملف القاعدة ليس فيه
  databaseMissing,

  /// ملف المؤشّر موجود ولا يُقرأ أو فارغ
  pointerUnreadable,
}

/// نتيجة سؤال «أين القاعدة الآن؟»
class ResolvedDatabaseLocation {
  const ResolvedDatabaseLocation({
    required this.directory,
    required this.databasePath,
    required this.isCustom,
    this.problem,
  });

  /// المجلد الذي يحوي القاعدة
  final String directory;

  /// المسار الكامل لملف القاعدة
  final String databasePath;

  /// هل هو مجلدٌ اختاره المالك (لا الافتراضي)؟
  final bool isCustom;

  /// سبب تعذّر الاستعمال — `null` يعني أن الموضع صالح
  final LocationProblem? problem;

  bool get isUsable => problem == null;
}

/// نوع القرص — يُسأل عنه قبل قبول مجلدٍ للقاعدة
enum DriveKind { fixed, removable, network, unknown }

/// يسأل نظام التشغيل عن نوع القرص — يُحقَن في الاختبارات
typedef DriveKindProbe = Future<DriveKind> Function(String path);

/// حصيلة فحص مجلد: ما يمنع (أخطاء) وما يستحقّ التنبيه (تحذيرات)
class FolderCheck {
  const FolderCheck({this.errors = const [], this.warnings = const []});

  final List<String> errors;
  final List<String> warnings;

  bool get isAllowed => errors.isEmpty;
}

/// ما وُجد داخل قاعدة سند مرشّحة للفتح — يُعرَض على المالك قبل القرار
class DatabaseCandidate {
  const DatabaseCandidate({
    required this.path,
    required this.schemaVersion,
    required this.companyName,
    required this.userCount,
    required this.voucherCount,
  });

  final String path;
  final int schemaVersion;
  final String? companyName;
  final int userCount;
  final int voucherCount;
}

/// من نفّذ النقل — يُكتَب في سجل التدقيق داخل القاعدة المنقولة
class LocationActor {
  const LocationActor({required this.userId, required this.username});

  final int? userId;
  final String username;
}

/// حصيلة النقل
class MoveReport {
  const MoveReport({
    required this.newDatabasePath,
    required this.retiredPaths,
    this.warning,
  });

  final String newDatabasePath;

  /// الملفات القديمة بعد إعادة تسميتها (لا تُحذف)
  final List<String> retiredPaths;

  /// تحذير غير قاتل — النقل نجح وبقي ما يُقال
  final String? warning;
}

// ══════════════════════════════════════════════════════════════════════════
// الخدمة
// ══════════════════════════════════════════════════════════════════════════

class DatabaseLocation {
  DatabaseLocation({
    required this.defaultDirectory,
    required this.pointerDirectory,
    this.installDirectory,
    ProbeOpener? openProbe,
    DriveKindProbe? driveKind,
    DateTime Function()? clock,
  })  : openProbe = openProbe ?? openDefaultProbe,
        driveKind = driveKind ?? windowsDriveKind,
        _clock = clock ?? DateTime.now;

  /// اسم القاعدة كما يمرّره `driftDatabase(name:)` — **الموضع الوحيد** لهذا
  /// الاسم في الشيفرة. والمثبِّت يحمل نسخةً منه (`DbFileName` في sanad.iss).
  static const String databaseName = 'sales_management_db';

  /// اسم ملف القاعدة على القرص
  static const String databaseFileName = '$databaseName.sqlite';

  /// ملفّا SQLite المرافقان — يُنقلان ويُعاد تسميتهما مع الملف دائماً
  static const List<String> sidecarSuffixes = ['-wal', '-shm'];

  /// اسم ملف المؤشّر — والمثبِّت يقرؤه بالاسم نفسه
  static const String pointerFileName = 'db_location.txt';

  /// الجداول التي لا تكون القاعدة قاعدةَ سند بدونها
  static const List<String> requiredTables = [
    'users',
    'vouchers',
    'treasuries',
    'app_settings',
    'audit_log',
  ];

  /// المجلد الافتراضي — Documents، وهو ما يختاره drift_flutter بلا مؤشّر
  final String defaultDirectory;

  /// مجلد ملف المؤشّر — %LOCALAPPDATA%\Sanad
  final String pointerDirectory;

  /// مجلد البرنامج المثبَّت — تُرفَض القاعدة داخله (المثبِّت يمحو {app}\data)
  final String? installDirectory;

  final ProbeOpener openProbe;
  final DriveKindProbe driveKind;
  final DateTime Function() _clock;

  /// النسخة الحقيقية على هذا الجهاز
  static Future<DatabaseLocation> forPlatform() async {
    // ⚠️ يجب أن يطابق ما يختاره drift_flutter بلا خيارات — وإلا ضاعت قواعد
    //   كل من ثبّت قبل هذه الميزة. drift يستعمل getApplicationDocumentsDirectory
    //   حرفياً (drift_flutter/lib/src/native.dart).
    final docs = (await getApplicationDocumentsDirectory()).path;

    final local = Platform.environment['LOCALAPPDATA'];
    final pointerDir = (Platform.isWindows && local != null && local.isNotEmpty)
        ? p.join(local, 'Sanad')
        : p.join((await getApplicationSupportDirectory()).path, 'Sanad');

    return DatabaseLocation(
      defaultDirectory: docs,
      pointerDirectory: pointerDir,
      installDirectory: File(Platform.resolvedExecutable).parent.path,
    );
  }

  File get pointerFile => File(p.join(pointerDirectory, pointerFileName));

  String databasePathIn(String directory) =>
      p.join(directory, databaseFileName);

  // ── القراءة ──────────────────────────────────────────────────────────────

  /// أين القاعدة؟ — **لا يُنشئ شيئاً ولا يتراجع صامتاً**
  ResolvedDatabaseLocation resolve() {
    final pointer = pointerFile;
    if (!pointer.existsSync()) {
      return ResolvedDatabaseLocation(
        directory: defaultDirectory,
        databasePath: databasePathIn(defaultDirectory),
        isCustom: false,
      );
    }

    String? dir;
    try {
      dir = _cleanLine(pointer.readAsStringSync());
    } catch (_) {
      dir = null;
    }
    if (dir == null || dir.isEmpty) {
      // مؤشّرٌ تالف ليس «لا مؤشّر»: المالك اختار موضعاً ولا نعرفه الآن.
      // العودة إلى الافتراضي هنا هي التراجع الصامت بعينه.
      return ResolvedDatabaseLocation(
        directory: '',
        databasePath: '',
        isCustom: true,
        problem: LocationProblem.pointerUnreadable,
      );
    }

    final dbPath = databasePathIn(dir);
    final custom = !samePath(dir, defaultDirectory);
    if (!Directory(dir).existsSync()) {
      return ResolvedDatabaseLocation(
        directory: dir,
        databasePath: dbPath,
        isCustom: custom,
        problem: LocationProblem.folderMissing,
      );
    }
    if (!File(dbPath).existsSync()) {
      return ResolvedDatabaseLocation(
        directory: dir,
        databasePath: dbPath,
        isCustom: custom,
        problem: LocationProblem.databaseMissing,
      );
    }
    return ResolvedDatabaseLocation(
      directory: dir,
      databasePath: dbPath,
      isCustom: custom,
    );
  }

  // ── الكتابة ──────────────────────────────────────────────────────────────

  /// يكتب المؤشّر — أو يحذفه إن كان الموضع هو الافتراضي (أو `null`)
  ///
  /// الكتابة في ملف مؤقّت ثم إعادة تسمية: انقطاع الكهرباء في منتصفها يترك
  /// المؤشّر القديم سليماً أو الجديد كاملاً — لا نصف مسار.
  Future<void> writePointer(String? directory) async {
    final pointer = pointerFile;
    if (directory == null || samePath(directory, defaultDirectory)) {
      if (pointer.existsSync()) await pointer.delete();
      return;
    }
    await Directory(pointerDirectory).create(recursive: true);
    final tmp = File('${pointer.path}.tmp');
    // UTF-8 بلا BOM — والمثبِّت يقرأ الصيغتين (جُرِّب 2026-10-12 بمسارٍ عربي)
    await tmp.writeAsString(p.normalize(directory), encoding: utf8, flush: true);
    await _retry(() => tmp.rename(pointer.path));
  }

  /// يُقاعد نسخة الموضع الافتراضي إن كان المؤشّر يشير إلى غيره
  ///
  /// تُستدعى عند كل إقلاع. وجودُ قاعدةٍ في Documents بينما المؤشّر يشير إلى
  /// غيرها يعني أن تقاعدها بعد النقل لم يكتمل (انقطاعٌ بين كتابة المؤشّر
  /// وإعادة التسمية، أو قفل ملفٍ لم يُحرَّر — ع-٤٤). وبقاؤها لغمٌ: إن ضاع
  /// المؤشّر يوماً فُتحت هي **بصمت** كأنها الحالية.
  ///
  /// يُعيد المسارات الجديدة، أو قائمة فارغة إن لم يكن ثمّة ما يُقاعَد.
  Future<List<String>> retireStaleDefaultCopy(
    ResolvedDatabaseLocation resolved,
  ) async {
    if (!resolved.isUsable || !resolved.isCustom) return const [];
    if (!File(databasePathIn(defaultDirectory)).existsSync()) return const [];
    return _retire(defaultDirectory, 'inactive');
  }

  // ── فحص المجلدات ─────────────────────────────────────────────────────────

  /// هل يصلح [target] وجهةً لنقل القاعدة إليه؟
  ///
  /// يُستدعى مرّتين: من الواجهة لعرض التحذيرات قبل القرار، ومن [move] نفسها
  /// قبل أي لمس — فالحارس في أعمق طبقة (القانون ٤).
  Future<FolderCheck> checkMoveTarget(
    String target, {
    required String currentDirectory,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];

    final base = _checkCommon(target, errors);
    if (base == null) return FolderCheck(errors: errors);

    if (samePath(base, currentDirectory)) {
      errors.add('هذا هو المجلد الذي فيه القاعدة الآن.');
    }
    if (!Directory(base).existsSync()) {
      errors.add('المجلد غير موجود:\n${bidiPath(base)}');
      return FolderCheck(errors: errors);
    }
    if (_holdsDatabase(base)) {
      errors.add(
        'في هذا المجلد قاعدة سند أخرى — والنقل لا يدهسها.\n'
        'إن أردت العمل عليها فاختر «فتح قاعدة موجودة» بدلاً من النقل.',
      );
    }
    if (!_isWritable(base)) {
      errors.add('لا يمكن الكتابة في هذا المجلد — تحقّق من الصلاحيات.');
    }

    await _checkDrive(base, errors, warnings);
    _checkSyncFolder(base, warnings);
    return FolderCheck(errors: errors, warnings: warnings);
  }

  /// هل يصلح [directory] مصدراً لـ«فتح قاعدة موجودة»؟
  Future<FolderCheck> checkAttachSource(String directory) async {
    final errors = <String>[];
    final warnings = <String>[];

    final base = _checkCommon(directory, errors);
    if (base == null) return FolderCheck(errors: errors);

    if (!Directory(base).existsSync()) {
      errors.add('المجلد غير موجود:\n${bidiPath(base)}');
      return FolderCheck(errors: errors);
    }
    if (!File(databasePathIn(base)).existsSync()) {
      errors.add(
        'لا توجد قاعدة سند في هذا المجلد.\n'
        'ابحث عن مجلدٍ فيه الملف «$databaseFileName».',
      );
    }

    await _checkDrive(base, errors, warnings);
    _checkSyncFolder(base, warnings);
    return FolderCheck(errors: errors, warnings: warnings);
  }

  /// الفحوص المشتركة بين الوجهة والمصدر — يُعيد المسار المطبَّع أو `null`
  String? _checkCommon(String raw, List<String> errors) {
    final path = raw.trim();
    if (path.isEmpty) {
      errors.add('لم يُحدَّد مجلد.');
      return null;
    }
    // ⚠️ مسارات الشبكة مرفوضة رفضاً قاطعاً: SQLite في وضع WAL يعتمد على
    //   ذاكرة مشتركة (-shm) لا تعمل عبر الشبكة، فتفسد القاعدة — وتوثيق
    //   SQLite نفسه يحذّر من ذلك صراحةً.
    if (path.startsWith(r'\\') || path.startsWith('//')) {
      errors.add(
        'مجلدات الشبكة غير مسموحة — SQLite يُفسد القاعدة عليها.\n'
        'اختر مجلداً على قرصٍ في هذا الحاسوب.',
      );
      return null;
    }
    if (!p.isAbsolute(path)) {
      errors.add('المسار يجب أن يكون كاملاً (يبدأ بحرف القرص).');
      return null;
    }
    final normalized = p.normalize(path);
    final install = installDirectory;
    if (install != null &&
        (samePath(normalized, install) || p.isWithin(install, normalized))) {
      // المثبِّت يمحو {app}\data قبل كل تحديث، وإلغاء التثبيت يمحو مجلد
      // البرنامج — قاعدةٌ هنا تُمحى مع أول تحديث.
      errors.add(
        'لا يجوز وضع القاعدة داخل مجلد البرنامج نفسه —\n'
        'تحديث البرنامج أو إلغاء تثبيته قد يمحوها.',
      );
    }
    return normalized;
  }

  Future<void> _checkDrive(
    String path,
    List<String> errors,
    List<String> warnings,
  ) async {
    switch (await driveKind(path)) {
      case DriveKind.network:
        errors.add(
          'هذا القرص قرص شبكة (Network Drive) — SQLite يُفسد القاعدة عليه.\n'
          'اختر قرصاً محلياً في هذا الحاسوب.',
        );
      case DriveKind.removable:
        warnings.add(
          'هذا قرصٌ قابل للفصل (فلاش أو قرص خارجي). إن فُصل والبرنامج مفتوح '
          'قد تتلف القاعدة، وإن فُصل وهو مغلق فلن يفتح البرنامج حتى يُوصَل.',
        );
      case DriveKind.fixed:
      case DriveKind.unknown:
        break;
    }
  }

  /// مجلدات المزامنة السحابية تُحذَّر منها ولا تُمنع
  ///
  /// المزامنة تنسخ الملف **أثناء** كتابة SQLite فيه، فتُنتج نسخاً متعارضة
  /// وقد تُعيد ملفاً قديماً فوق الجديد. ولا تُمنع لأن المالك قد يملك سبباً
  /// (حاسوبٌ بلا قرص ثانٍ) — لكنه يجب أن يعرف.
  void _checkSyncFolder(String path, List<String> warnings) {
    const markers = ['onedrive', 'dropbox', 'google drive', 'googledrive',
        'icloud drive', 'iclouddrive'];
    final segments = p.split(path).map((s) => s.toLowerCase());
    final hit = segments.any((s) => markers.any(s.startsWith));
    if (hit) {
      warnings.add(
        'هذا المجلد تُزامنه خدمة سحابية (OneDrive أو Dropbox أو غيرهما).\n'
        'المزامنة أثناء الكتابة قد تُتلف القاعدة أو تُعيد نسخةً قديمة فوقها.\n'
        'الأسلم: مجلدٌ عادي، والنسخ الاحتياطي إلى السحابة من شاشة النسخ.',
      );
    }
  }

  bool _holdsDatabase(String dir) {
    final db = databasePathIn(dir);
    if (File(db).existsSync()) return true;
    return sidecarSuffixes.any((s) => File('$db$s').existsSync());
  }

  bool _isWritable(String dir) {
    final probe = File(p.join(dir, '.sanad_write_test_$pid'));
    try {
      probe.writeAsStringSync('ok', flush: true);
      probe.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── فحص قاعدة مرشّحة ─────────────────────────────────────────────────────

  /// يفحص قاعدةً **بلا أن يكتب فيها شيئاً** — راجع رأس probe_database.dart
  ///
  /// يرمي [StateError] برسالة عربية إن لم تكن قاعدة سند صالحة لهذا الإصدار.
  Future<DatabaseCandidate> inspect(
    String databasePath, {
    required int appSchemaVersion,
  }) async {
    final file = File(databasePath);
    if (!file.existsSync()) {
      throw StateError('الملف غير موجود:\n${bidiPath(databasePath)}');
    }
    if (!_hasSqliteHeader(file)) {
      throw StateError('الملف ليس قاعدة بيانات SQLite — ربما تالف أو ليس لسند.');
    }

    final probe = await openProbe();
    try {
      await probe.attach(databasePath, 'cand');
      try {
        final check = await probe.scalar('PRAGMA cand.integrity_check');
        if (check != 'ok') {
          throw StateError('القاعدة تالفة (فحص السلامة: $check).');
        }

        final tables = (await probe
                .customSelect(
                  "SELECT name FROM cand.sqlite_master WHERE type = 'table'",
                )
                .get())
            .map((r) => r.read<String>('name'))
            .toSet();
        final missing =
            requiredTables.where((t) => !tables.contains(t)).toList();
        if (missing.isNotEmpty) {
          throw StateError(
            'هذا الملف ليس قاعدة سند — تنقصه الجداول: ${missing.join('، ')}.',
          );
        }

        final version = _asInt(await probe.scalar('PRAGMA cand.user_version'));
        if (version <= 0) {
          throw StateError('هذا الملف ليس قاعدة سند (لا رقم إصدار فيه).');
        }
        if (version > appSchemaVersion) {
          // قاعدة أحدث على برنامج أقدم تنكسر بلا تشخيص مفهوم — كما في
          // الاستعادة (BackupService.restoreFull · الطبقة ٣)
          throw StateError(
            'هذه القاعدة من إصدارٍ أحدث من البرنامج '
            '(مخطط $version مقابل $appSchemaVersion).\n'
            'حدّث البرنامج أولاً ثم افتحها.',
          );
        }

        final company = await probe.scalar(
          'SELECT value FROM cand.app_settings WHERE key = ?',
          [AppSettingsKeys.companyName],
        );
        return DatabaseCandidate(
          path: databasePath,
          schemaVersion: version,
          companyName: company is String && company.trim().isNotEmpty
              ? company.trim()
              : null,
          userCount: _asInt(await probe.scalar('SELECT count(*) FROM cand.users')),
          voucherCount: _asInt(
            await probe.scalar('SELECT count(*) FROM cand.vouchers'),
          ),
        );
      } finally {
        await probe.detach('cand');
      }
    } on StateError {
      rethrow;
    } catch (e) {
      throw StateError('تعذّر فحص القاعدة: $e');
    } finally {
      await probe.dispose();
    }
  }

  // ── النقل ────────────────────────────────────────────────────────────────

  /// ينقل القاعدة الحيّة إلى [targetDirectory]
  ///
  /// [closeLiveDatabase] — يُغلق اتصال البرنامج بالقاعدة (بعد دمج WAL).
  ///   **يُستدعى قبل النسخ**: بعدها لا كاتب على الملف، فالنسخة متّسقة يقيناً
  ///   لا «على الأرجح». على المستدعي إعادة فتح القاعدة بعدها — في الفشل من
  ///   موضعها القديم، وفي النجاح من الجديد.
  ///
  /// الترتيب مقصود — كل ما يفشل يقع **قبل** نقطة اللارجعة (ع-٤٤):
  ///   ١. الفحص                 ← فشلٌ هنا: لا شيء مُسّ
  ///   ٢. إغلاق القاعدة الحيّة
  ///   ٣. `VACUUM INTO` نسخةٌ مؤقّتة `.partial`
  ///   ٤. التحقّق: السلامة · رقم الإصدار · **عدد صفوف كل جدول**
  ///   ٥. سطر تدقيق في النسخة الجديدة وحدها
  ///   ٦. `.partial` ← الاسم النهائي
  ///   ٧. كتابة المؤشّر          ← **نقطة اللارجعة**
  ///   ٨. تقاعد القديم بإعادة تسمية — فشلُه تحذير لا خطأ (الإقلاع يُكمله)
  ///
  /// يرمي [StateError] برسالة عربية. وكل رميٍ قبل الخطوة ٧ يترك القاعدة
  /// القديمة كما هي والمؤشّر كما هو.
  Future<MoveReport> move({
    required String targetDirectory,
    required String sourceDatabasePath,
    required Future<void> Function() closeLiveDatabase,
    required LocationActor actor,
  }) async {
    final sourceDir = p.dirname(sourceDatabasePath);

    // ── ١. الفحص ───────────────────────────────────────────────────────────
    final check =
        await checkMoveTarget(targetDirectory, currentDirectory: sourceDir);
    if (!check.isAllowed) throw StateError(check.errors.join('\n\n'));
    if (!File(sourceDatabasePath).existsSync()) {
      throw StateError(
        'ملف القاعدة الحالية غير موجود:\n${bidiPath(sourceDatabasePath)}',
      );
    }

    final target = p.normalize(targetDirectory.trim());
    final finalPath = databasePathIn(target);
    final partial = File('$finalPath.partial');

    // ── ٢. إغلاق القاعدة الحيّة ────────────────────────────────────────────
    await closeLiveDatabase();

    // ── ٣–٦. النسخ والتحقّق ────────────────────────────────────────────────
    try {
      if (partial.existsSync()) await _retry(partial.delete);
      await _copyAndVerify(
        sourcePath: sourceDatabasePath,
        copyPath: partial.path,
        actor: actor,
        targetDirectory: target,
      );
      await _retry(() => partial.rename(finalPath));
    } catch (e) {
      // النسخة المؤقّتة وحدها تُحذف — والقديمة لم تُلمَس أصلاً
      try {
        if (partial.existsSync()) await _retry(partial.delete);
      } catch (_) {}
      final why = e is StateError ? e.message : '$e';
      throw StateError('لم يتمّ النقل — قاعدتك لم تُمَسّ وما زالت في موضعها.\n\n$why');
    }

    // ── ٧. نقطة اللارجعة ───────────────────────────────────────────────────
    await writePointer(target);

    // ── ٨. تقاعد القديم ────────────────────────────────────────────────────
    List<String> retired = const [];
    String? warning;
    try {
      retired = await _retire(sourceDir, 'moved');
    } catch (e) {
      warning = 'نُقلت القاعدة بنجاح، لكن تعذّرت إعادة تسمية النسخة القديمة '
          'في:\n${bidiPath(sourceDir)}\n'
          'سيُكملها البرنامج عند الإقلاع التالي. ($e)';
    }

    return MoveReport(
      newDatabasePath: finalPath,
      retiredPaths: retired,
      warning: warning,
    );
  }

  /// `VACUUM INTO` ثم التحقّق ثم سطر التدقيق — كلّه عبر قاعدة الفحص
  Future<void> _copyAndVerify({
    required String sourcePath,
    required String copyPath,
    required LocationActor actor,
    required String targetDirectory,
  }) async {
    final probe = await openProbe();
    try {
      await probe.attach(sourcePath, 'src');

      // لماذا VACUUM INTO لا نسخ الملف؟ لأن SQLite نفسه يكتب النسخة من
      // الصفحات المنطقية: يدمج ما بقي في -wal، ويُخرج ملفاً واحداً متّسقاً
      // ومضغوطاً. ونسخ البايتات يحتاج الملفات الثلاثة معاً وصدق أنها متزامنة.
      await probe.customStatement('VACUUM src INTO ?', [copyPath]);

      await probe.attach(copyPath, 'dst');
      try {
        final check = await probe.scalar('PRAGMA dst.integrity_check');
        if (check != 'ok') {
          throw StateError('النسخة الجديدة لم تجتز فحص السلامة ($check).');
        }

        final vSrc = _asInt(await probe.scalar('PRAGMA src.user_version'));
        final vDst = _asInt(await probe.scalar('PRAGMA dst.user_version'));
        if (vSrc != vDst) {
          throw StateError('رقم إصدار المخطط اختلف بعد النسخ ($vSrc ⇐ $vDst).');
        }

        // ⚠️ عدد صفوف **كل** جدول — مشتقّاً من sqlite_master لا من قائمة
        //   مكتوبة بيد، وإلا تخلّف الحارس عن أول جدولٍ جديد (ع-٥٦).
        final tables = (await probe
                .customSelect(
                  "SELECT name FROM src.sqlite_master "
                  "WHERE type = 'table' AND name NOT LIKE 'sqlite_%' "
                  'ORDER BY name',
                )
                .get())
            .map((r) => r.read<String>('name'))
            .toList();
        for (final t in tables) {
          final q = t.replaceAll('"', '""');
          final a = _asInt(await probe.scalar('SELECT count(*) FROM src."$q"'));
          final b = _asInt(await probe.scalar('SELECT count(*) FROM dst."$q"'));
          if (a != b) {
            throw StateError('عدد صفوف الجدول «$t» اختلف بعد النسخ ($a ⇐ $b).');
          }
        }

        // سطر التدقيق يُكتب في **النسخة الجديدة وحدها** وبعد التحقّق: فإن
        // فشل النقل لم يبقَ في القاعدة القديمة سطرٌ يزعم نقلاً لم يقع.
        await probe.customStatement(
          'INSERT INTO dst.audit_log '
          '(user_id, username, affected_table, action, meta_json) '
          'VALUES (?, ?, ?, ?, ?)',
          [
            actor.userId,
            actor.username,
            'system',
            'DATABASE_MOVE',
            jsonEncode({'from': p.dirname(sourcePath), 'to': targetDirectory}),
          ],
        );
      } finally {
        await probe.detach('dst');
      }
      await probe.detach('src');
    } finally {
      await probe.dispose();
    }
  }

  // ── فتح قاعدة موجودة ─────────────────────────────────────────────────────

  /// يجعل البرنامج يفتح القاعدة الموجودة في [directory] من الإقلاع التالي
  ///
  /// **هذا ما يحقّق الغاية من الميزة**: المؤشّر في AppData يُمحى مع إعادة
  /// تثبيت ويندوز، فبدون هذا الباب يفتح البرنامج على قاعدة فارغة ولا يعرف
  /// أن البيانات في D:\ — فتكون «النجاة من إعادة التثبيت» وعداً بلا طريق.
  ///
  /// [closeLiveDatabase] — اختياري: من شاشة خطأ الإقلاع لا قاعدة مفتوحة.
  ///
  /// لا يمسّ القاعدة الحالية إلا بالتقاعد إن كانت في الموضع الافتراضي —
  /// لأن الافتراضي هو ما يُفتح بصمت إن ضاع المؤشّر. أما قاعدةٌ في مجلدٍ
  /// مخصّص فتبقى باسمها: ليست نسخةً قديمة بل قاعدةٌ بديلة قد يعود إليها.
  Future<DatabaseCandidate> attach({
    required String directory,
    required int appSchemaVersion,
    String? currentDirectory,
    Future<void> Function()? closeLiveDatabase,
  }) async {
    final check = await checkAttachSource(directory);
    if (!check.isAllowed) throw StateError(check.errors.join('\n\n'));

    final dir = p.normalize(directory.trim());
    if (currentDirectory != null && samePath(dir, currentDirectory)) {
      throw StateError('هذه هي القاعدة المفتوحة الآن.');
    }

    final candidate = await inspect(
      databasePathIn(dir),
      appSchemaVersion: appSchemaVersion,
    );

    if (closeLiveDatabase != null) await closeLiveDatabase();

    await writePointer(dir);

    if (!samePath(dir, defaultDirectory) &&
        File(databasePathIn(defaultDirectory)).existsSync()) {
      try {
        await _retire(defaultDirectory, 'inactive');
      } catch (_) {
        // يُكمله retireStaleDefaultCopy عند الإقلاع التالي
      }
    }
    return candidate;
  }

  // ── مساعدات ──────────────────────────────────────────────────────────────

  /// يُعيد تسمية القاعدة وملفّيها المرافقين — **لا حذف**
  ///
  /// الاسم الجديد: `sales_management_db.sqlite.<tag>_<yyyyMMdd_HHmmss>`
  Future<List<String>> _retire(String directory, String tag) async {
    final base = databasePathIn(directory);
    final stamp = _stamp(_clock());
    final renamed = <String>[];
    for (final suffix in ['', ...sidecarSuffixes]) {
      final f = File('$base$suffix');
      if (!f.existsSync()) continue;
      final dest = '$base.${tag}_$stamp$suffix';
      await _retry(() => f.rename(dest));
      renamed.add(dest);
    }
    return renamed;
  }

  /// إعادة محاولة لعمليات الملفات — مقبض SQLite لا يُحرَّر فوراً بعد
  /// `close()` لأن drift يفتح القاعدة في isolate منفصل (ع-٤٤)
  static Future<T> _retry<T>(Future<T> Function() op) async {
    Object? last;
    for (var attempt = 0; attempt < 12; attempt++) {
      try {
        return await op();
      } catch (e) {
        last = e;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
    throw StateError('$last');
  }

  static String _stamp(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}_'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }

  /// أول سطر غير فارغ بلا BOM ولا مسافات
  static String? _cleanLine(String text) {
    for (final line in text.replaceAll('\uFEFF', '').split(RegExp(r'\r?\n'))) {
      final t = line.trim();
      if (t.isNotEmpty) return t;
    }
    return null;
  }

  static bool _hasSqliteHeader(File f) {
    try {
      final raf = f.openSync();
      try {
        final head = raf.readSync(16);
        return String.fromCharCodes(head) == 'SQLite format 3\u0000';
      } finally {
        raf.closeSync();
      }
    } catch (_) {
      return false;
    }
  }

  static int _asInt(Object? v) => switch (v) {
        final int i => i,
        final String s => int.tryParse(s) ?? 0,
        _ => 0,
      };

  /// يعزل مساراً داخل نصّ عربي باتجاهه (من اليسار)
  ///
  /// 🔴 **بلا عزل يُقلَب المسار** (كُشف في التشغيل الفعلي 2026-10-12):
  ///   `Q:\قرص غائب\SanadData` داخل فقرةٍ عربية ظهر بأجزاءٍ معكوسة لأن محرّك
  ///   الاتجاه يرتّب كل مقطع على حدة — فيرى المالك مساراً لا يطابق ما في
  ///   مستكشف الملفات. LRI…PDI (U+2066/U+2069) يجعل المسار كتلةً واحدة من
  ///   اليسار مهما كان حوله — وهو ما يفعله ويندوز نفسه.
  ///
  /// ⚠️ للمسار **داخل جملة** فقط. المسار المعروض وحده يُعرض بـ
  ///   `textDirection: TextDirection.ltr` بلا هذين المحرفين: نسخُه يُدرجهما
  ///   خفيّين فيرفضه مستكشف الملفات عند لصقه.
  static String bidiPath(String path) => '\u2066$path\u2069';

  /// مقارنة مسارَين على ويندوز: بلا حساسية لحالة الأحرف ولا للفاصل الأخير
  static bool samePath(String a, String b) {
    String norm(String x) {
      var n = p.normalize(p.absolute(x.trim()));
      if (n.length > 3 && (n.endsWith(r'\') || n.endsWith('/'))) {
        n = n.substring(0, n.length - 1);
      }
      return Platform.isWindows ? n.toLowerCase() : n;
    }

    return norm(a) == norm(b);
  }
}

// ══════════════════════════════════════════════════════════════════════════
// نوع القرص على ويندوز
// ══════════════════════════════════════════════════════════════════════════

/// يسأل ويندوز عن نوع القرص عبر PowerShell — **بلا FFI**
///
/// لماذا لا `GetDriveTypeW` مباشرةً؟ لأن dart:ffi يكسر بناء الويب، وحزمة
/// `ffi` لتحويل النصوص تبعيةٌ جديدة تحتاج موافقة المالك (القانون ٦). والسؤال
/// يُطرح مرّة عند اختيار مجلد، فثانيةٌ من PowerShell ثمنٌ مقبول.
///
/// الفشل يُعيد [DriveKind.unknown] — فلا يمنع ولا يحذّر، ويبقى الحارس
/// المطلق (رفض `\\`) قائماً لأنه لا يعتمد على هذا.
Future<DriveKind> windowsDriveKind(String path) async {
  if (!Platform.isWindows) return DriveKind.unknown;
  final m = RegExp(r'^([A-Za-z]):').firstMatch(path.trim());
  if (m == null) return DriveKind.unknown;
  // الحرف وحده يدخل الأمر — ومحروس بالتعبير أعلاه فلا حقن
  final letter = m.group(1)!.toUpperCase();
  try {
    final r = await Process.run('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      "(Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='$letter:'\").DriveType",
    ]).timeout(const Duration(seconds: 10));
    return switch (int.tryParse('${r.stdout}'.trim())) {
      2 || 5 => DriveKind.removable, // ٢ قابل للفصل · ٥ قرص ضوئي
      3 => DriveKind.fixed,
      4 => DriveKind.network,
      _ => DriveKind.unknown,
    };
  } catch (_) {
    return DriveKind.unknown;
  }
}
