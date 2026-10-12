// ─────────────────────────────────────────────────────────────────────────────
// database_tab.dart — موضع قاعدة البيانات: عرضه ونقله وفتح قاعدة أخرى
//
// قرار المالك (2026-10-12): «مجلد تختاره أنت» — لتنجو القاعدة من إعادة
// تثبيت ويندوز إن وُضعت على قرصٍ آخر (D:\ مثلاً).
//
// ═══ ثلاثة أبواب، ولكلٍّ معناه ═══
//   • نقل      — البيانات **نفسها** إلى مجلد آخر. يكفيه تبديل المسار، فلا
//                إعادة تشغيل: `activeDatabasePathProvider` يُعيد فتح القاعدة.
//   • فتح قاعدة موجودة — بيانات **أخرى** (القاعدة على D:\ بعد إعادة تثبيت
//                ويندوز). المستخدمون والجلسة يتغيّرون فيُعاد تشغيل البرنامج.
//   • الإعادة إلى المستندات — نقلٌ وجهته الموضع الافتراضي.
//
// ⚠️ **حاوية المزوّدات تُلتقط قبل أي `await`** لا `ref`: النقل يُغلق القاعدة،
//   وما بين الإغلاق وإعادة الفتح قد تُعاد بناء الشاشة فيموت `ref` (ع-٥٧) —
//   فتبقى القاعدة مغلقة والبرنامج معطَّلاً. الحاوية تعيش بعد الودجت.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../core/auth/permissions.dart';
import '../../../../core/utils/app_relauncher.dart';
import '../../../../core/utils/audit_logger.dart';
import '../../../../domain/models/auth_state.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/database/database_location.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/database_location_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../widgets/common/password_confirm_dialog.dart';
import '../../database_location/database_location_dialogs.dart';

/// تبويب موضع قاعدة البيانات
class DatabaseTab extends ConsumerStatefulWidget {
  const DatabaseTab({super.key});

  @override
  ConsumerState<DatabaseTab> createState() => _DatabaseTabState();
}

class _DatabaseTabState extends ConsumerState<DatabaseTab> {
  bool _working = false;

  /// يُغلق القاعدة الحيّة بعد دمج WAL — يُمرَّر إلى الخدمة
  ///
  /// دمج WAL أولاً: الإغلاق يفعله عادةً، لكن الخدمة تنسخ الملف بعده مباشرةً،
  /// والدمج الصريح يجعل الملف الرئيسي كاملاً قبل أي شيء.
  Future<void> Function() _closer(ProviderContainer container) => () async {
        final db = container.read(appDatabaseProvider);
        await db.checkpointWal();
        await db.close();
      };

  // ── النقل ────────────────────────────────────────────────────────────────

  /// ينقل القاعدة إلى [target] — أو يسأل عن المجلد إن كان `null`
  Future<void> _move({String? target, required bool toDefault}) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final location = container.read(databaseLocationProvider);
    final current = container.read(activeDatabasePathProvider);
    if (location == null || current == null) return;
    final currentDir = p.dirname(current);

    final dest = target ??
        await pickDatabaseFolder('اختر المجلد الجديد لقاعدة البيانات');
    if (dest == null || !mounted) return;

    final check =
        await location.checkMoveTarget(dest, currentDirectory: currentDir);
    if (!mounted) return;
    if (!await presentFolderCheck(context, check, title: 'تنبيه قبل النقل')) {
      return;
    }
    if (!mounted) return;

    final ok = await _confirmMove(from: currentDir, to: dest);
    if (!ok || !mounted) return;

    final identityOk = await confirmWithPassword(
      context,
      ref,
      action: toDefault
          ? 'إعادة قاعدة البيانات إلى المستندات'
          : 'نقل قاعدة البيانات',
      impact: 'من:\n${DatabaseLocation.bidiPath(currentDir)}\n'
          'إلى:\n${DatabaseLocation.bidiPath(dest)}',
    );
    if (!identityOk || !mounted) return;

    final actor = container.read(authNotifierProvider.notifier).currentUser;
    final closeProgress =
        showBlockingProgress(context, 'جارٍ نقل القاعدة والتحقّق من كل جدول…');
    setState(() => _working = true);

    try {
      final report = await location.move(
        targetDirectory: dest,
        sourceDatabasePath: current,
        closeLiveDatabase: _closer(container),
        actor: LocationActor(
          userId: actor?.id,
          username: actor?.username ?? 'system',
        ),
      );
      closeProgress();
      // تبديل المسار يُعيد بناء appDatabaseProvider فيفتح القاعدة من موضعها
      // الجديد — والبيانات نفسها، فلا حاجة لإعادة تشغيل
      container.read(activeDatabasePathProvider.notifier).state =
          report.newDatabasePath;

      if (!mounted) return;
      final retired = report.retiredPaths.isEmpty
          ? ''
          : '\n\nالملف القديم لم يُحذف — أُعيدت تسميته إلى:\n'
              '${DatabaseLocation.bidiPath(report.retiredPaths.first)}';
      final warn = report.warning == null ? '' : '\n\n⚠️ ${report.warning}';
      await showLocationMessage(
        context,
        title: 'نُقلت القاعدة',
        body: 'القاعدة الآن في:\n'
            '${DatabaseLocation.bidiPath(report.newDatabasePath)}\n\n'
            'تُحقِّق من سلامتها ومن عدد صفوف كل جدول قبل اعتمادها.'
            '$retired$warn',
      );
    } on StateError catch (e) {
      closeProgress();
      // القاعدة أُغلقت داخل الخدمة — تُفتح ثانيةً من موضعها القديم (لم يتغيّر)
      container.invalidate(appDatabaseProvider);
      if (!mounted) return;
      await showLocationMessage(
        context,
        title: 'لم يتمّ النقل',
        body: e.message,
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<bool> _confirmMove({required String from, required String to}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.drive_file_move_outline, size: 36),
        title: const Text('نقل قاعدة البيانات'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Text(
              'من:\n${DatabaseLocation.bidiPath(from)}\n\n'
              'إلى:\n${DatabaseLocation.bidiPath(to)}\n\n'
              'ما سيحدث بالترتيب:\n'
              '١. تُغلَق القاعدة لحظات — لا تُدخل شيئاً أثناءها.\n'
              '٢. تُنسَخ إلى المجلد الجديد ويُتحقَّق من سلامتها ومن عدد صفوف '
              'كل جدول.\n'
              '٣. إن نجح التحقّق يبدأ البرنامج العمل منها فوراً. وإن فشل '
              'لا يتغيّر شيء.\n'
              '٤. الملف القديم لا يُحذف — يُعاد تسميته حتى لا يُفتح '
              'بالخطأ كأنه الحالي.\n\n'
              '📌 النسخة الاحتياطية التلقائية التي يأخذها المثبِّت قبل كل '
              'تحديث ستُحفَظ بعد اليوم في مجلد Sanad-Backups بجوار القاعدة.',
              style: const TextStyle(height: 1.6),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('انقلها'),
          ),
        ],
      ),
    );
    return result == true;
  }

  // ── فتح قاعدة موجودة ─────────────────────────────────────────────────────

  Future<void> _attach() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final location = container.read(databaseLocationProvider);
    final current = container.read(activeDatabasePathProvider);
    if (location == null || current == null) return;
    final currentDir = p.dirname(current);

    final dir = await pickDatabaseFolder('اختر المجلد الذي فيه قاعدة سند');
    if (dir == null || !mounted) return;

    final check = await location.checkAttachSource(dir);
    if (!mounted) return;
    if (!await presentFolderCheck(context, check, title: 'تنبيه')) return;
    if (!mounted) return;
    if (DatabaseLocation.samePath(dir, currentDir)) {
      await showLocationMessage(
        context,
        title: 'هي نفسها',
        body: 'هذه هي القاعدة المفتوحة الآن.',
      );
      return;
    }

    final DatabaseCandidate candidate;
    try {
      candidate = await location.inspect(
        location.databasePathIn(dir),
        appSchemaVersion: AppDatabase.currentSchemaVersion,
      );
    } on StateError catch (e) {
      if (!mounted) return;
      await showLocationMessage(
        context,
        title: 'لا تصلح هذه القاعدة',
        body: e.message,
        isError: true,
      );
      return;
    }
    if (!mounted) return;

    final currentIsDefault =
        DatabaseLocation.samePath(currentDir, location.defaultDirectory);
    final ok = await confirmAttach(
      context,
      candidate,
      appSchemaVersion: AppDatabase.currentSchemaVersion,
      aboutCurrent: currentIsDefault
          ? 'قاعدتك الحالية في المستندات لا تُحذف: يُعاد تسمية ملفها '
              '(…inactive_التاريخ) حتى لا يفتحه البرنامج يوماً بالخطأ.'
          : 'قاعدتك الحالية في:\n${DatabaseLocation.bidiPath(currentDir)}\n'
              'تبقى كما هي باسمها، وتعود '
              'إليها متى شئت من هذا التبويب.',
    );
    if (!ok || !mounted) return;

    final identityOk = await confirmWithPassword(
      context,
      ref,
      action: 'فتح قاعدة بيانات أخرى',
      impact: 'كل ما تراه سيُستبدَل ببيانات:\n${DatabaseLocation.bidiPath(dir)}',
    );
    if (!identityOk || !mounted) return;

    // يُسجَّل في القاعدة **المتروكة** قبل إغلاقها — فإن عاد إليها المالك
    // رأى متى تُركت وإلى أين
    final actor = container.read(authNotifierProvider.notifier).currentUser;
    if (actor != null) {
      await container.read(auditLoggerProvider).logDatabaseAttach(
            userId: actor.id,
            username: actor.username,
            fromDirectory: currentDir,
            targetDirectory: dir,
          );
    }
    if (!mounted) return;

    final closeProgress = showBlockingProgress(context, 'جارٍ التحضير…');
    setState(() => _working = true);
    try {
      await location.attach(
        directory: dir,
        appSchemaVersion: AppDatabase.currentSchemaVersion,
        currentDirectory: currentDir,
        closeLiveDatabase: _closer(container),
      );
      closeProgress();
      if (mounted) {
        await showLocationMessage(
          context,
          title: 'جاهز',
          body: 'سيُعاد تشغيل البرنامج الآن ليفتح القاعدة من:\n'
              '${DatabaseLocation.bidiPath(dir)}',
          button: 'إعادة التشغيل',
        );
      }
      await relaunchApp();
    } on StateError catch (e) {
      closeProgress();
      container.invalidate(appDatabaseProvider);
      if (!mounted) return;
      setState(() => _working = false);
      await showLocationMessage(
        context,
        title: 'لم يتغيّر شيء',
        body: e.message,
        isError: true,
      );
    }
  }

  // ── العرض ────────────────────────────────────────────────────────────────

  String _size(String path) {
    var bytes = 0;
    for (final s in ['', ...DatabaseLocation.sidecarSuffixes]) {
      final f = File('$path$s');
      if (f.existsSync()) bytes += f.lengthSync();
    }
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} كيلوبايت';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ميغابايت';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = ref.watch(databaseLocationProvider);
    final current = ref.watch(activeDatabasePathProvider);

    if (kIsWeb || location == null || current == null) {
      return const Center(
        child: Text('موضع القاعدة لا يُغيَّر على هذه المنصّة.'),
      );
    }

    final dir = p.dirname(current);
    final isCustom = !DatabaseLocation.samePath(dir, location.defaultDirectory);
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final allowed =
        user?.can(AppPermission.changeDatabaseLocation) ?? false;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('موضع قاعدة البيانات', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'الملف الذي يحمل كل بياناتك: السندات والخزائن والرواتب والمستخدمين.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),

        // ── الموضع الحالي ─────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.storage_rounded,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      // مسارٌ وحده: اتجاهٌ صريح لا محارف عزل — راجع bidiPath
                      child: SelectableText(
                        dir,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      label: Text(isCustom
                          ? 'مجلد اخترتَه أنت'
                          : 'الموضع الافتراضي (المستندات)'),
                      visualDensity: VisualDensity.compact,
                    ),
                    Text(
                      'الحجم: ${_size(current)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Process.run('explorer', [dir]),
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: const Text('فتح المجلد'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── الأبواب ───────────────────────────────────────────────────────
        if (!allowed)
          Card(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.4),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'نقل القاعدة وفتح قاعدة أخرى لمدير النظام الأعلى وحده.',
              ),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // ElevatedButton لا FilledButton — راجع شاشة خطأ الإقلاع:
              // FilledButton كحليٌّ على كحلي في الوضع الداكن
              ElevatedButton.icon(
                onPressed:
                    _working ? null : () => _move(toDefault: false),
                icon: const Icon(Icons.drive_file_move_outline, size: 18),
                label: const Text('نقل القاعدة إلى مجلد آخر…'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.secondary,
                  side: BorderSide(color: theme.colorScheme.secondary),
                ),
                onPressed: _working ? null : _attach,
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('فتح قاعدة موجودة…'),
              ),
              if (isCustom)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: _working
                      ? null
                      : () => _move(
                            target: location.defaultDirectory,
                            toDefault: true,
                          ),
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('إعادتها إلى المستندات'),
                ),
            ],
          ),

        const SizedBox(height: 20),

        // ── شرح صريح ──────────────────────────────────────────────────────
        Card(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.4),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 17, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('متى تنقلها ولماذا',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                const _Bullet(
                  'وضعها على قرصٍ غير قرص ويندوز (مثل D:) يحميها حين يُعاد '
                  'تثبيت ويندوز أو يُهيَّأ القرص C.',
                ),
                const _Bullet(
                  'بعد إعادة تثبيت ويندوز: ثبّت سند، ثم في شاشة الإعداد الأول '
                  'اختر «لديّ قاعدة بيانات سابقة» وأشر إلى مجلدها — فالبرنامج '
                  'لا يتذكّر الموضع بعد إعادة التثبيت.',
                ),
                const _Bullet(
                  'إن غاب المجلد يوماً (قرصٌ مفصول) لا يفتح البرنامج قاعدةً '
                  'أخرى بدلها بصمت، بل يقول لك ما حدث ويعرض الخيارات.',
                ),
                const _Bullet(
                  'مجلدات الشبكة مرفوضة — SQLite يُفسد القاعدة عليها. ومجلدات '
                  'OneDrive وDropbox تُحذَّر منها: المزامنة أثناء الكتابة قد '
                  'تُتلفها.',
                ),
                const _Bullet(
                  'المثبِّت يأخذ نسخة احتياطية تلقائية قبل كل تحديث إلى مجلد '
                  'Sanad-Backups بجوار القاعدة.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// نقطة في قائمة الشرح
class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: theme.textTheme.bodySmall),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
