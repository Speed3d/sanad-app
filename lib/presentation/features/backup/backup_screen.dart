// ─────────────────────────────────────────────────────────────────────────────
// backup_screen.dart — شاشة النسخ الاحتياطي
//
// الميزات:
//   - تصدير قاعدة البيانات مشفّرة بـ AES-256-GCM
//   - استيراد نسخة احتياطية مشفّرة واستعادتها
//   - حقل كلمة المرور لتشفير / فك التشفير
//   - مؤشر تقدم أثناء العمليات
//
// التشفير:
//   منطق التشفير كله في core/services/backup_crypto_service.dart
//   خوارزمية: AES-256-GCM
//   اشتقاق المفتاح: PBKDF2-SHA256 — 100,000 تكرار — مفتاح 32 بايت
//   البادئة في الملف: b"SMBAK2\n" + salt(16) + iv(12) + tag(16) + ciphertext
//   (الملفات القديمة SMBAK1 لا تزال تُفتَح للتوافق)
//
// ملاحظة:
//   يعمل على Android/iOS/Desktop فقط (dart:io).
//   على Web: يُعرض تنبيه بعدم الدعم.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io' as io;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/constants/app_settings_keys.dart';
import '../../../core/services/backup_crypto_service.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/cloud_backup_service.dart';
import '../../../core/utils/audit_logger.dart';

// ── دوال التشفير داخل Isolate ────────────────────────────────────────────────
//
// compute() يتطلب دوالّ من المستوى الأعلى (top-level) أو static،
// لأن الـ Isolate لا يستطيع الوصول إلى حالة الودجت.

/// نقطة دخول التشفير داخل Isolate منفصل
Uint8List _encryptInIsolate(({Uint8List bytes, String password}) args) {
  return BackupCryptoService.encrypt(args.bytes, args.password);
}

/// نقطة دخول فك التشفير داخل Isolate منفصل
Uint8List? _decryptInIsolate(({Uint8List bytes, String password}) args) {
  return BackupCryptoService.decrypt(args.bytes, args.password);
}

/// الحد الأدنى لطول كلمة مرور النسخة الاحتياطية
const _kMinBackupPasswordLen = 8;

// ════════════════════════════════════════════════════════════════════════════
// BackupScreen
// ════════════════════════════════════════════════════════════════════════════

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _working = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _setStatus(String msg, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _statusMessage = msg;
      _isError = error;
      _working = false;
    });
  }

  // ── تصدير النسخة الاحتياطية ──────────────────────────────────────────────

  /// نسخة احتياطية **شاملة**: قاعدة البيانات + ملفات المرفقات
  ///
  /// ═══ لماذا مجلد لا ملف مضغوط؟ (قرار المالك 2026-08-23) ═══
  ///   الضغط يتطلّب إعلان حزمة `archive` صراحةً في `pubspec.yaml` — وهو ما
  ///   يقع تحت شرط «لا تبعية جديدة بلا موافقة». والمجلد أبسط وأشفّ: يراه
  ///   المالك ويتصفّحه ويضغطه بنقرة يمين إن أراد، ولا يحتاج البرنامج لفكّه
  ///   عند الاستعادة.
  ///
  /// ═══ ⚠️ ملاحظة صدق ═══
  ///   قاعدة البيانات داخل النسخة **مشفَّرة** بكلمة المرور، أما ملفات
  ///   المرفقات فتُنسَخ **كما هي بلا تشفير** — لأن تشفير كل ملف على حدة
  ///   يعني أن المالك لا يستطيع فتح فاتورته إلا عبر البرنامج، وهو ثمن باهظ.
  ///   نقول ذلك صراحةً في ملف البيان وفي رسالة النتيجة بدل تركه يُفترَض.
  Future<void> _exportFullBackup() async {
    final pass = _passwordCtrl.text;
    if (!_validateExportPassword(pass)) return;

    // وجهةٌ يختارها المالك بدل الكتابة في «المستندات» صامتاً — النسخة
    // الحقيقية تُحفَظ على قرص خارجي لا على نفس القرص الذي قد يتلف.
    final dest = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'اختر مجلد حفظ النسخة الشاملة',
    );
    if (dest == null) return;

    setState(() => _working = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final root =
          await db.appSettingsDao.getString(AppSettingsKeys.attachmentsRoot) ??
              '';

      final report = await BackupService.exportFull(
        db: db,
        dbFilePath: await _dbFilePath(),
        destinationDir: dest,
        attachmentsRoot: root,
        password: pass,
      );

      final actor = ref.read(authNotifierProvider.notifier).currentUser;
      if (actor != null) {
        await ref.read(auditLoggerProvider).logBackupCreated(
              userId: actor.id,
              username: actor.username,
              filePath: report.path,
            );
      }

      final mb = (report.attachmentBytes / (1024 * 1024)).toStringAsFixed(1);
      final warn = report.attachmentsMissing > 0
          ? '\n⚠️ ${report.attachmentsMissing} مرفقاً مفقوداً من القرص لم يُنسَخ.'
          : '';
      _setStatus(
        '✅ نسخة شاملة في:\n${report.path}\n'
        'قاعدة البيانات (مشفَّرة) + ${report.attachmentsCopied} مرفقاً '
        '($mb ميغابايت)\n'
        'ℹ️ المرفقات منسوخة بلا تشفير — راجع «${BackupLayout.readmeFile}».$warn',
      );
    } on StateError catch (e) {
      _setStatus(e.message, error: true);
    } catch (e) {
      _setStatus('تعذّر إنشاء النسخة الشاملة: $e', error: true);
    } finally {
      if (mounted && _working) setState(() => _working = false);
    }
  }

  // ── استعادة النسخة الشاملة ────────────────────────────────────────────────

  /// استعادة مجلد نسخة شاملة: قاعدة البيانات **والمرفقات** معاً
  ///
  /// كانت النسخة الشاملة تُصدَّر ولا تُستعاد: البيان يوجّه المالك إلى نسخ
  /// المرفقات **يدوياً** من مستكشف الملفات. الترتيب داخل
  /// [BackupService.restoreFull] مقصود — المرفقات أولاً ثم القاعدة، عكس
  /// ترتيب الحذف. راجع تعليق رأس الخدمة.
  Future<void> _restoreFullBackup() async {
    final pass = _passwordCtrl.text;
    if (pass.isEmpty) {
      _setStatus('أدخل كلمة المرور أولاً', error: true);
      return;
    }

    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'اختر مجلد النسخة الشاملة (sanad_backup_…)',
    );
    if (dir == null) return;

    // ── الفحص قبل أي لمس ────────────────────────────────────────────
    // يرى المالك ما سيستعيده **قبل** أن يقرّر — لا بعد أن يقع.
    final BackupManifest manifest;
    try {
      manifest = await BackupService.inspect(dir);
    } on StateError catch (e) {
      _setStatus(e.message, error: true);
      return;
    } catch (e) {
      _setStatus('تعذّر فحص المجلد: $e', error: true);
      return;
    }

    if (!mounted) return;
    final created = manifest.createdAt?.toLocal().toString().split('.').first;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة نسخة شاملة'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المجلد:\n$dir\n'),
              Text('تاريخ النسخة: ${created ?? 'غير معروف'}'),
              Text('المرفقات فيها: ${manifest.attachments.length}'),
              if (manifest.isLegacy)
                const Text(
                  '\n⚠️ نسخة قديمة بلا بيان آليّ — لا يمكن التحقّق من إصدار '
                  'مخططها، وقد تكون بلا مرفقات.',
                ),
              const Text(
                '\nستُستبدَل قاعدة بياناتك الحالية بالكامل.\n'
                'تُحفَظ نسخة أمان منها تلقائياً قبل الاستبدال، '
                'والمرفقات الموجودة بنفس الاسم لا تُدهَس.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('استعد الآن'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final actor = ref.read(authNotifierProvider.notifier).currentUser;
    if (actor == null) return;

    setState(() => _working = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final root =
          await db.appSettingsDao.getString(AppSettingsKeys.attachmentsRoot) ??
              '';

      final report = await BackupService.restoreFull(
        db: db,
        dbFilePath: await _dbFilePath(),
        backupDir: dir,
        attachmentsRoot: root,
        password: pass,
        user: actor,
      );

      // القاعدة أُغلقت داخل الخدمة قبل الدهس — نُبطل المزوّد ليُعاد فتحها
      ref.invalidate(appDatabaseProvider);

      await ref.read(auditLoggerProvider).logBackupRestored(
            userId: actor.id,
            username: actor.username,
            filePath: dir,
          );

      final skipped = report.attachmentsSkipped > 0
          ? '\nℹ️ ${report.attachmentsSkipped} مرفقاً موجوداً مسبقاً لم يُدهَس.'
          : '';
      final missing = report.attachmentsMissing > 0
          ? '\n⚠️ ${report.attachmentsMissing} مرفقاً في البيان ومفقوداً من النسخة.'
          : '';
      // تحذيرٌ غير قاتل: الاستعادة نجحت ومع ذلك بقي ما يُقال (ع-٤٤)
      final note = report.warning != null ? '\nℹ️ ${report.warning}' : '';
      _setStatus(
        '✅ تمت الاستعادة الشاملة.\n'
        'المرفقات المستعادة: ${report.attachmentsRestored}$skipped$missing\n'
        'نسخة الأمان من قاعدتك السابقة:\n${report.safetyCopyPath}$note\n\n'
        '⚠️ أعد تشغيل التطبيق لتطبيق التغييرات.',
      );
    } on StateError catch (e) {
      _setStatus(e.message, error: true);
    } catch (e) {
      _setStatus('خطأ أثناء الاستعادة: $e', error: true);
    } finally {
      if (mounted && _working) setState(() => _working = false);
    }
  }

  // ── مساعدات مشتركة ────────────────────────────────────────────────────────

  /// مسار ملف قاعدة البيانات — موضع واحد بدل تكراره في ثلاث دوال
  Future<String> _dbFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/sales_management_db.sqlite';
  }

  /// تحقّقات كلمة مرور التصدير الثلاثة — كانت مكرّرة حرفياً في دالتين
  bool _validateExportPassword(String pass) {
    if (pass.isEmpty) {
      _setStatus('أدخل كلمة المرور أولاً', error: true);
      return false;
    }
    if (pass.length < _kMinBackupPasswordLen) {
      _setStatus(
        'كلمة المرور قصيرة جداً — يجب ألا تقل عن $_kMinBackupPasswordLen أحرف',
        error: true,
      );
      return false;
    }
    if (pass != _confirmCtrl.text) {
      _setStatus('كلمتا المرور غير متطابقتين', error: true);
      return false;
    }
    return true;
  }

  Future<void> _exportBackup() async {
    final pass = _passwordCtrl.text;
    if (pass.isEmpty) {
      _setStatus('أدخل كلمة المرور أولاً', error: true);
      return;
    }
    // حد أدنى لطول كلمة المرور — تحمي هذه الكلمة قاعدة البيانات كاملةً،
    // فكلمة من حرف واحد تجعل التشفير بلا قيمة عملياً.
    if (pass.length < _kMinBackupPasswordLen) {
      _setStatus(
        'كلمة المرور قصيرة جداً — يجب ألا تقل عن $_kMinBackupPasswordLen أحرف',
        error: true,
      );
      return;
    }
    if (pass != _confirmCtrl.text) {
      _setStatus('كلمتا المرور غير متطابقتين', error: true);
      return;
    }
    setState(() => _working = true);

    try {
      // 1. مسار قاعدة البيانات
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/sales_management_db.sqlite';
      final dbFile = io.File(dbPath);
      if (!dbFile.existsSync()) {
        _setStatus('لم يُعثَر على ملف قاعدة البيانات', error: true);
        return;
      }

      // دمج سجل WAL في الملف الرئيسي قبل النسخ — وإلا تضيع آخر السندات
      // المُثبَّتة التي لا تزال في ملف -wal المنفصل.
      await ref.read(appDatabaseProvider).checkpointWal();

      final dbBytes = await dbFile.readAsBytes();

      // 2. التشفير (على خيط منفصل حتى لا تتجمد الواجهة)
      final encrypted = await _encryptBytes(dbBytes, pass);

      // 3. الحفظ المحلّي
      final now = DateTime.now();
      final fileName =
          'smbak_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
          '_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.smbak';
      final savePath = '${dir.path}/$fileName';
      await io.File(savePath).writeAsBytes(encrypted, flush: true);

      // توثيق إنشاء النسخة في سجل التدقيق
      final actor = ref.read(authNotifierProvider.notifier).currentUser;
      if (actor != null) {
        await ref.read(auditLoggerProvider).logBackupCreated(
              userId: actor.id,
              username: actor.username,
              filePath: savePath,
            );
      }

      // 4. حفظ نسخة إضافية حسب النمط المختار في الإعدادات
      final modeStr =
          ref.read(cloudSyncModeProvider).valueOrNull ?? 'local';
      final mode = modeStr == 'drive'
          ? CloudSyncMode.googleDrive
          : CloudSyncMode.localCopy;
      final cloudService = ref.read(cloudBackupServiceProvider);
      final synced = await cloudService.uploadBackupToCloud(savePath, mode: mode);

      // رسائل صادقة: نسخة محلية إضافية (لا ادعاء سحابي كاذب)
      final String syncMsg;
      if (mode == CloudSyncMode.googleDrive) {
        syncMsg = '\nℹ️ مزامنة Google Drive غير مُفعَّلة بعد (تحتاج إعداداً). '
            'حُفظت النسخة محلياً فقط.';
      } else if (synced) {
        syncMsg = '\n🗂️ حُفظت نسخة إضافية على الجهاز أيضاً.';
      } else {
        syncMsg = '\n⚠️ تعذّر حفظ النسخة الإضافية، تم الحفظ الأساسي فقط.';
      }

      _setStatus('✅ تم حفظ النسخة الاحتياطية:\n$savePath$syncMsg');
    } catch (e) {
      _setStatus('خطأ أثناء التصدير: $e', error: true);
    }
  }

  // ── استيراد النسخة الاحتياطية ────────────────────────────────────────────

  Future<void> _importBackup() async {
    final pass = _passwordCtrl.text;
    if (pass.isEmpty) {
      _setStatus('أدخل كلمة المرور أولاً', error: true);
      return;
    }
    setState(() => _working = true);

    try {
      // 1. اختيار الملف
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['smbak'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _working = false);
        return;
      }
      final bytes = result.files.first.bytes;
      if (bytes == null) {
        _setStatus('تعذّر قراءة الملف', error: true);
        return;
      }

      // 2. فك التشفير (على خيط منفصل حتى لا تتجمد الواجهة)
      final decrypted = await _decryptBytes(bytes, pass);
      if (decrypted == null) {
        _setStatus('كلمة المرور غير صحيحة أو الملف تالف', error: true);
        return;
      }

      // 3. أغلق قاعدة البيانات واستبدل الملف
      final db = ref.read(appDatabaseProvider);
      await db.close();

      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/sales_management_db.sqlite';
      await io.File(dbPath).writeAsBytes(decrypted, flush: true);

      // ⚠️ حذف ملفَّي WAL القديمَين (إصلاح تدقيق 2026-08-06):
      //   بعد استبدال الملف الرئيسي، لو بقي ملف -wal قديم قد يُعيد SQLite
      //   تشغيله فوق الملف المُستعاد فيُفسده. نحذف السايدكار لضمان نظافة
      //   الاستعادة.
      for (final suffix in const ['-wal', '-shm']) {
        final sidecar = io.File('$dbPath$suffix');
        if (sidecar.existsSync()) {
          await sidecar.delete();
        }
      }

      // إعادة تحميل المزود
      ref.invalidate(appDatabaseProvider);

      // توثيق الاستعادة في سجل التدقيق — يُكتَب في قاعدة البيانات المُستعادة
      // (auditLoggerProvider يُعاد بناؤه على النسخة الجديدة بعد invalidate)
      final actor = ref.read(authNotifierProvider.notifier).currentUser;
      if (actor != null) {
        await ref.read(auditLoggerProvider).logBackupRestored(
              userId: actor.id,
              username: actor.username,
              filePath: result.files.first.name,
            );
      }

      _setStatus(
        '✅ تمت استعادة النسخة الاحتياطية بنجاح.\n'
        'أعد تشغيل التطبيق لتطبيق التغييرات.',
      );
    } catch (e) {
      _setStatus('خطأ أثناء الاستيراد: $e', error: true);
    }
  }

  // ── التشفير ──────────────────────────────────────────────────────────────
  //
  // منطق التشفير كله انتقل إلى BackupCryptoService حتى يصبح قابلاً للاختبار
  // (كان دوالّ خاصة داخل ودجت، فيستحيل اختباره) وقابلاً للتشغيل في Isolate.
  //
  // التشفير وفك التشفير يعملان الآن داخل compute() على خيط منفصل، لأن
  // 100,000 دورة PBKDF2 مع AES على ملف قاعدة بيانات كامل كانت تُجمّد
  // الواجهة لثوانٍ على الخيط الرئيسي.

  /// تشفير بيانات قاعدة البيانات على خيط منفصل
  Future<Uint8List> _encryptBytes(Uint8List plain, String password) {
    return compute(_encryptInIsolate, (bytes: plain, password: password));
  }

  /// فك تشفير ملف نسخة احتياطية على خيط منفصل
  Future<Uint8List?> _decryptBytes(Uint8List data, String password) {
    return compute(_decryptInIsolate, (bytes: data, password: password));
  }

  // ════════════════════════════════════════════════════════════════════════
  // build
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // الاستعادة عملية كارثية (تمسح قاعدة البيانات) → super_admin فقط.
    // التصدير متاح لأي admin (الموجّه يضمن أن الوصول للشاشة admin فأعلى).
    final currentUser = ref.read(authNotifierProvider.notifier).currentUser;
    final canRestore =
        currentUser != null && currentUser.can(AppPermission.restoreBackup);

    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── تنبيه Web ──────────────────────────────────────────
            if (kIsWeb)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'النسخ الاحتياطي متاح على Android/iOS/Desktop فقط.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (kIsWeb) const SizedBox(height: 12),

            // ── شرح التشفير ──────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('تشفير AES-256-GCM', style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تُشفَّر النسخة بـ AES-256-GCM مع اشتقاق المفتاح '
                      'بـ PBKDF2-SHA256 (${BackupFormat.pbkdfIterations ~/ 1000}k تكرار). '
                      'احتفظ بكلمة المرور — لا يمكن الاستعادة بدونها.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── حالة المزامنة السحابية (Google Drive) ──────────────────────────
            const _CloudSyncStatusCard(),
            const SizedBox(height: 16),

            // ── كلمة المرور ──────────────────────────────────────
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'كلمة المرور *',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscure,
              decoration: const InputDecoration(
                labelText: 'تأكيد كلمة المرور (للتصدير)',
                prefixIcon: Icon(Icons.lock_reset_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // ── أزرار ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (_working || kIsWeb) ? null : _exportBackup,
                    icon: const Icon(Icons.backup_outlined),
                    label: const Text('تصدير نسخة'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    // معطّل لغير super_admin (يظهر لكن لا يعمل مع تلميح)
                    onPressed: (_working || kIsWeb || !canRestore)
                        ? null
                        : _importBackup,
                    icon: const Icon(Icons.restore_outlined),
                    label: const Text('استعادة نسخة'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── النسخة الشاملة (المرحلة ج) ───────────────────────────
            // منفصلة عن التصدير العادي لأنها أبطأ وأكبر بكثير — لا يجوز
            // أن تُفاجئ من أراد نسخة سريعة لقاعدة البيانات وحدها.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    (_working || kIsWeb) ? null : _exportFullBackup,
                icon: const Icon(Icons.folder_zip_outlined),
                label: const Text('نسخة شاملة (قاعدة البيانات + المرفقات)'),
              ),
            ),
            const SizedBox(height: 12),

            // ── استعادة النسخة الشاملة ───────────────────────────────
            // كانت النسخة الشاملة تُصدَّر ولا تُستعاد: البيان يوجّه المالك
            // إلى نسخ المرفقات **يدوياً** من مستكشف الملفات. ونسخةٌ استعادتها
            // نصف يدوية تُكتشف قيمتها يوم الكارثة وحده.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: (_working || kIsWeb || !canRestore)
                    ? null
                    : _restoreFullBackup,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                  ),
                ),
                icon: const Icon(Icons.restore_page_outlined),
                label: const Text('استعادة نسخة شاملة (اختر المجلد)'),
              ),
            ),

            if (!canRestore) ...[
              const SizedBox(height: 6),
              Text(
                'الاستعادة متاحة لمدير النظام فقط',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            // ── مؤشر التقدم ───────────────────────────────────
            if (_working) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(child: Text('جارٍ المعالجة…')),
            ],

            // ── رسالة الحالة ───────────────────────────────────
            if (_statusMessage != null && _statusMessage!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isError ? Colors.red.shade200 : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _isError ? Icons.error_outline : Icons.check_circle_outline,
                      color: _isError ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _isError
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── تعليمات ──────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('تعليمات', style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InstructionItem(
                      '1',
                      'للتصدير: أدخل كلمة المرور وتأكيدها ثم اضغط "تصدير نسخة".',
                    ),
                    _InstructionItem(
                      '2',
                      'للاستعادة: أدخل كلمة المرور المستخدمة في التصدير ثم اضغط "استعادة نسخة".',
                    ),
                    _InstructionItem(
                      '3',
                      'يُحفَظ ملف النسخة بامتداد .smbak في مجلد مستندات التطبيق.',
                    ),
                    _InstructionItem(
                      '4',
                      'بعد الاستعادة أعد تشغيل التطبيق لتطبيق قاعدة البيانات الجديدة.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets مساعدة
// ════════════════════════════════════════════════════════════════════════════

class _InstructionItem extends StatelessWidget {
  const _InstructionItem(this.number, this.text);
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _CloudSyncStatusCard — بطاقة النسخة الإضافية (نسخة محلية / Google Drive)
//
// صادقة: تعرض النمط الحالي بوضوح ولا تدّعي اتصالاً سحابياً غير موجود.
// ════════════════════════════════════════════════════════════════════════════

class _CloudSyncStatusCard extends ConsumerWidget {
  const _CloudSyncStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cloudService = ref.watch(cloudBackupServiceProvider);
    final info = cloudService.info;

    // النمط المختار من الإعدادات
    final modeStr = ref.watch(cloudSyncModeProvider).valueOrNull ?? 'local';
    final isDriveMode = modeStr == 'drive';

    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDriveMode ? Icons.cloud_outlined : Icons.save_alt_outlined,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'نسخة احتياطية إضافية',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── مبدّل النمط ──────────────────────────────────────────────
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'local',
                  label: Text('نسخة محلية'),
                  icon: Icon(Icons.save_alt_outlined, size: 16),
                ),
                ButtonSegment(
                  value: 'drive',
                  label: Text('Google Drive'),
                  icon: Icon(Icons.cloud_outlined, size: 16),
                ),
              ],
              selected: {modeStr},
              onSelectionChanged: (sel) async {
                await ref
                    .read(settingsRepositoryProvider)
                    .setString(AppSettingsKeys.cloudSyncMode, sel.first);
              },
              showSelectedIcon: false,
            ),
            const SizedBox(height: 10),

            // ── وصف صادق للنمط الحالي ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isDriveMode
                        ? Icons.info_outline
                        : Icons.check_circle_outline,
                    size: 18,
                    color: isDriveMode
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isDriveMode
                          ? 'مزامنة Google Drive غير مُفعَّلة بعد — تحتاج إعداد '
                              'حساب Google لاحقاً. حالياً تُحفَظ نسخة محلية فقط.'
                          : 'تُحفَظ نسخة إضافية على هذا الجهاز في مجلد منفصل. '
                              'للحماية من تعطّل الجهاز، انسخ ملف .smbak إلى '
                              'وسيط خارجي أيضاً.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (info.lastSyncTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'آخر نسخة إضافية: ${info.lastSyncTime.toString().split('.')[0]} (${info.formattedSize})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
