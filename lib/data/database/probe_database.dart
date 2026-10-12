// ─────────────────────────────────────────────────────────────────────────────
// probe_database.dart — اتصال SQLite مؤقّت يفحص قواعد أخرى **ولا يكتب فيها**
//
// لماذا لا نفتح القاعدة المفحوصة بـ AppDatabase مباشرةً؟
//
//   فتحُ أي ملف بـ AppDatabase يُشغّل الترحيل تلقائياً قبل أول استعلام:
//     • ملف SQLite أجنبي (user_version = 0) ⇒ يُعامَل كقاعدة جديدة فيُشغَّل
//       onCreate ويُنشئ **جداول سند داخل ملف ليس لنا**
//     • قاعدة سند أقدم ⇒ تُرحَّل **قبل** أن يوافق المالك على فتحها
//     • ثم beforeOpen يكتب علامة الإقلاع فيها
//   أي أن «الفحص» نفسه يُعدّل ما يفحصه.
//
// الحلّ: قاعدة فارغة في مجلد مؤقّت (لا تحمل جدولاً واحداً)، و**تُلحَق** بها
// القاعدة المفحوصة بـ `ATTACH`. والإلحاق لا يكتب شيئاً في الملف المُلحَق —
// والاستعلامات عليه بادئةٌ باسمه (`cand.users`) فلا التباس.
//
// ولماذا drift لا حزمة sqlite3 مباشرةً؟
//   `package:sqlite3` مبنية على dart:ffi الذي لا يُترجَم للويب، وقاعدة هذا
//   المشروع: «الويب يبقى يبني ولا نكسره». و`driftDatabase` يتولّى ذلك داخلياً.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// قاعدة بلا جداول — وظيفتها الوحيدة أن تكون منصّةً لـ `ATTACH`
///
/// ⚠️ **مكتوبة يدوياً بلا build_runner عمداً**: لا جدول فيها يحتاج توليداً،
///   ووجودها خارج `@DriftDatabase` يمنع أي ترحيل أو بذور من الوصول إليها.
class ProbeDatabase extends GeneratedDatabase {
  /// [scratch] — المجلد المؤقّت الذي يحمل ملف الفحص، يُحذف في [dispose]
  ProbeDatabase(super.executor, {this.scratch});

  final Directory? scratch;

  /// يُغلق الاتصال ثم يحذف المجلد المؤقّت
  ///
  /// فشلُ الحذف يُبتلَع: ملفٌ مؤقّت متخلّف في Temp لا يستحقّ أن يُفشل
  /// نقلاً نجح (درس ع-٤٤ — لا تجعل التنظيف يُفشل عمليةً تمّت).
  Future<void> dispose() async {
    await close();
    final dir = scratch;
    if (dir == null) return;
    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        if (dir.existsSync()) await dir.delete(recursive: true);
        return;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  int get schemaVersion => 1;

  /// كل خطوات الترحيل فارغة — فلا يُكتَب في ملف الفحص المؤقّت إلا
  /// `user_version = 1` الذي يكتبه drift نفسه، وهو ملفٌ يُحذف بعد الفحص.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (_) async {},
        onUpgrade: (_, __, ___) async {},
        beforeOpen: (_) async {},
      );

  /// يُلحق ملف قاعدة باسمٍ مستعار — المسار يُمرَّر **معاملاً** لا نصّاً
  /// مدموجاً، فلا يكسره مسارٌ فيه علامة اقتباس أو حروف عربية
  Future<void> attach(String path, String alias) =>
      customStatement('ATTACH DATABASE ? AS $alias', [path]);

  /// يفكّ الإلحاق — **إلزامي قبل نقل الملف أو إعادة تسميته**: ما دام
  /// مُلحَقاً فمقبضه مفتوح، وويندوز يرفض إعادة تسمية ملفٍ مفتوح
  Future<void> detach(String alias) =>
      customStatement('DETACH DATABASE $alias');

  /// قيمة واحدة من استعلام — اختصارٌ لكثرة استعماله في الفحص
  Future<Object?> scalar(String sql, [List<Object?> args = const []]) async {
    final rows = await customSelect(
      sql,
      variables: [for (final a in args) Variable(a)],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.data.values.first;
  }
}

/// يفتح قاعدة فحصٍ مؤقّتة — **يملكها المستدعي ويجب أن يستدعي [ProbeDatabase.dispose]**
typedef ProbeOpener = Future<ProbeDatabase> Function();

/// الفاتح الافتراضي: ملفٌ فارغ في مجلد مؤقّت جديد عبر `driftDatabase`
///
/// ⚠️ `tempDirectoryPath` يُمرَّر صراحةً: بدونه يسأل drift_flutter
///   `path_provider` عن المجلد المؤقّت، فيرمي `MissingPluginException` حين
///   تُستعمَل هذه الدالة خارج تطبيقٍ كامل (من شاشة خطأ الإقلاع مثلاً).
Future<ProbeDatabase> openDefaultProbe() async {
  final dir = await Directory.systemTemp.createTemp('sanad_probe_');
  return ProbeDatabase(
    driftDatabase(
      name: 'sanad_probe',
      native: DriftNativeOptions(
        databasePath: () async =>
            '${dir.path}${Platform.pathSeparator}probe.sqlite',
        tempDirectoryPath: () async => dir.path,
      ),
    ),
    scratch: dir,
  );
}
