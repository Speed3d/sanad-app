// ─────────────────────────────────────────────────────────────────────────────
// database_location_problem_app.dart — حين لا تُوجد القاعدة حيث يُفترَض
//
// تُعرَض **بدل البرنامج كلّه** إن أشار ملف المؤشّر إلى موضعٍ غاب: قرصٌ خارجي
// غير موصول · مجلدٌ نُقل أو حُذف · ملفٌ أُعيدت تسميته.
//
// ═══ لماذا شاشةٌ كاملة لا تراجعٌ إلى المستندات؟ ═══
//   التراجع الصامت يفتح قاعدةً **أخرى** — فارغةً أو قديمة — فيظنّ المالك أن
//   بياناته ضاعت، أو أسوأ: يُدخل فيها سندات اليوم ويعمل على نسختين متباعدتين
//   لا يجمعهما شيء. وهذا ع-٦١ في أخطر صوره: قرارٌ يُلغي ما يعرفه المالك ويقع
//   بلا كلمة. فهنا يُقال ما حدث، ويختار المالك بعينين مفتوحتين.
//
// ⚠️ تُبنى **قبل** فتح أي قاعدة — فلا Riverpod ولا إعدادات ثيم ولا مستخدم.
//   ولهذا أيضاً لا كلمة مرور هنا: فتحُ قاعدةٍ أخرى يقود إلى شاشة الدخول
//   بحساباتها هي، والعودة إلى الافتراضي تقود إلى قاعدة لا تحوي بيانات أحد.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_location.dart';
import 'database_location_dialogs.dart';

class DatabaseLocationProblemApp extends StatelessWidget {
  const DatabaseLocationProblemApp({
    super.key,
    required this.location,
    required this.resolved,
    required this.onResolved,
  });

  final DatabaseLocation location;
  final ResolvedDatabaseLocation resolved;

  /// يُعيد الإقلاع من أوّله — يُستدعى بعد كل حلّ
  final Future<void> Function() onResolved;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سند',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: DatabaseLocationProblemScreen(
        location: location,
        resolved: resolved,
        onResolved: onResolved,
      ),
    );
  }
}

/// الشاشة نفسها — منفصلةً عن [MaterialApp] لتُختبَر وحدها
class DatabaseLocationProblemScreen extends StatefulWidget {
  const DatabaseLocationProblemScreen({
    super.key,
    required this.location,
    required this.resolved,
    required this.onResolved,
  });

  final DatabaseLocation location;
  final ResolvedDatabaseLocation resolved;
  final Future<void> Function() onResolved;

  @override
  State<DatabaseLocationProblemScreen> createState() =>
      _DatabaseLocationProblemScreenState();
}

class _DatabaseLocationProblemScreenState
    extends State<DatabaseLocationProblemScreen> {
  bool _busy = false;

  /// الشرح بثلاثة أجزاء: ما قبل المسار · المسار نفسه · ما بعده
  ///
  /// المسار **سطرٌ مستقلّ** لا جزءٌ من الفقرة: داخل نصٍّ عربي يُقلَب ترتيب
  /// مقاطعه (كُشف في التشغيل الفعلي 2026-10-12)، ووحدَه يُعرض من اليسار
  /// فيطابق ما في مستكشف الملفات ويُنسخ نظيفاً.
  ({String before, String path, String after}) get _explanation {
    final r = widget.resolved;
    return switch (r.problem) {
      LocationProblem.folderMissing => (
          before: 'البرنامج مضبوط على فتح القاعدة من هذا المجلد:',
          path: r.directory,
          after: 'والمجلد غير موجود الآن.\n'
              'الأسباب الأرجح: قرصٌ خارجي غير موصول · أو المجلد نُقل أو '
              'أُعيدت تسميته.',
        ),
      LocationProblem.databaseMissing => (
          before: 'المجلد موجود:',
          path: r.directory,
          after: 'لكن ملف القاعدة «${DatabaseLocation.databaseFileName}» '
              'ليس فيه.\nربما نُقل الملف أو أُعيدت تسميته يدوياً.',
        ),
      LocationProblem.pointerUnreadable => (
          before: 'ملف إعداد موضع القاعدة تالف أو فارغ:',
          path: widget.location.pointerFile.path,
          after: 'فلا يُعرف أين اخترتَ وضع القاعدة.',
        ),
      null => (before: '', path: '', after: ''),
    };
  }

  Future<void> _retry() async {
    setState(() => _busy = true);
    await widget.onResolved();
  }

  /// اختيار المجلد الذي فيه القاعدة فعلاً
  Future<void> _chooseFolder() async {
    final dir = await pickDatabaseFolder('اختر المجلد الذي فيه قاعدة سند');
    if (dir == null || !mounted) return;

    final check = await widget.location.checkAttachSource(dir);
    if (!mounted) return;
    if (!await presentFolderCheck(context, check, title: 'تنبيه')) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      final candidate = await widget.location.inspect(
        widget.location.databasePathIn(dir),
        appSchemaVersion: AppDatabase.currentSchemaVersion,
      );
      if (!mounted) return;
      setState(() => _busy = false);

      final ok = await confirmAttach(
        context,
        candidate,
        appSchemaVersion: AppDatabase.currentSchemaVersion,
        aboutCurrent: 'سيُضبط البرنامج على فتح القاعدة من هذا المجلد '
            'من الآن فصاعداً.',
      );
      if (!ok || !mounted) return;

      setState(() => _busy = true);
      await widget.location.attach(
        directory: dir,
        appSchemaVersion: AppDatabase.currentSchemaVersion,
      );
      await widget.onResolved();
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await showLocationMessage(
        context,
        title: 'تعذّر فتح القاعدة',
        body: e.message,
        isError: true,
      );
    }
  }

  /// العودة إلى المستندات — بعد تحذيرٍ يقول بالضبط ما سيحدث
  Future<void> _useDefault() async {
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: scheme.error, size: 36),
        title: const Text('البدء من الموضع الافتراضي؟'),
        content: SizedBox(
          width: 480,
          child: Text(
            'سيفتح البرنامج القاعدة من «المستندات»:\n'
            '${DatabaseLocation.bidiPath(widget.location.defaultDirectory)}\n\n'
            '⚠️ إن لم تكن فيها قاعدة فسيبدأ قاعدةً جديدة فارغة — '
            'وهذه ليست بياناتك.\n\n'
            'قاعدتك في:\n${DatabaseLocation.bidiPath(widget.resolved.directory)}\n'
            'لا تُمَسّ. وتعود إليها متى شئت من:\n'
            'الإعدادات ← قاعدة البيانات ← فتح قاعدة موجودة.',
            style: const TextStyle(height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، الموضع الافتراضي'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    await widget.location.writePointer(null);
    await widget.onResolved();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.storage_rounded, size: 56, color: scheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'لم يُعثَر على قاعدة البيانات',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _explanation.before,
                      style: const TextStyle(height: 1.7),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      _explanation.path,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        height: 1.7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _explanation.after,
                      style: const TextStyle(height: 1.7),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'لم يفتح البرنامج أي قاعدة أخرى بدلاً منها — حتى لا '
                        'تُدخل بياناتك في المكان الخطأ دون أن تعلم.',
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_busy)
                      const Center(child: CircularProgressIndicator())
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          // ⚠️ ElevatedButton لا FilledButton: الثيم يعرّف
                          //   الأول وحده (ذهبي)، و`primary` في الوضع الداكن
                          //   كحليٌّ غامق فيصير FilledButton كحلياً على كحلي —
                          //   بدا كأنه معطَّل في التشغيل الفعلي (2026-10-12)
                          ElevatedButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: scheme.secondary,
                              side: BorderSide(color: scheme.secondary),
                            ),
                            onPressed: _chooseFolder,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('اختيار مجلد القاعدة…'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: scheme.onSurfaceVariant,
                            ),
                            onPressed: _useDefault,
                            child: const Text('البدء من الموضع الافتراضي'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
