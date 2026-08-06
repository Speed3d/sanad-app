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
//   خوارزمية: AES-256-GCM
//   اشتقاق المفتاح: PBKDF2-SHA256 — 100,000 تكرار — مفتاح 32 بايت
//   البادئة في الملف: b"SMBAK1\n" + salt(16) + iv(12) + tag(16) + ciphertext
//
// ملاحظة:
//   يعمل على Android/iOS/Desktop فقط (dart:io).
//   على Web: يُعرض تنبيه بعدم الدعم.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io' as io;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' as pc;

import '../../providers/database_provider.dart';
import '../../../core/services/cloud_backup_service.dart';

// ── ثوابت التشفير ────────────────────────────────────────────────────────────

const _kMagic = 'SMBAK1\n'; // 7 bytes
const _kSaltLen = 16;
const _kIvLen = 12;
const _kTagLen = 16;
const _kKeyLen = 32; // AES-256
const _kPbkdfIterations = 100000;

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

  Future<void> _exportBackup() async {
    final pass = _passwordCtrl.text;
    if (pass.isEmpty) {
      _setStatus('أدخل كلمة المرور أولاً', error: true);
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
      final dbBytes = await dbFile.readAsBytes();

      // 2. التشفير
      final encrypted = _encryptBytes(dbBytes, pass);

      // 3. الحفظ المحلّي
      final now = DateTime.now();
      final fileName =
          'smbak_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
          '_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.smbak';
      final savePath = '${dir.path}/$fileName';
      await io.File(savePath).writeAsBytes(encrypted, flush: true);

      // 4. المزمنة السحابية التلقائية إلى Google Drive
      final cloudService = ref.read(cloudBackupServiceProvider);
      final synced = await cloudService.uploadBackupToCloud(savePath);

      final syncMsg = synced
          ? '\n☁️ تم الرفع والمزامنة التلقائية مع Google Drive بنجاح.'
          : '\n⚠️ تعذر التزامن مع السحابة، تم الحفظ محلياً فقط.';

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

      // 2. فك التشفير
      final decrypted = _decryptBytes(bytes, pass);
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

      // إعادة تحميل المزود
      ref.invalidate(appDatabaseProvider);

      _setStatus(
        '✅ تمت استعادة النسخة الاحتياطية بنجاح.\n'
        'أعد تشغيل التطبيق لتطبيق التغييرات.',
      );
    } catch (e) {
      _setStatus('خطأ أثناء الاستيراد: $e', error: true);
    }
  }

  // ── AES-256-GCM تشفير ────────────────────────────────────────────────────

  Uint8List _encryptBytes(Uint8List plain, String password) {
    final salt = _randomBytes(_kSaltLen);
    final iv = _randomBytes(_kIvLen);
    final key = _deriveKey(password, salt);

    final cipher = pc.GCMBlockCipher(pc.AESEngine())
      ..init(
        true,
        pc.AEADParameters(
          pc.KeyParameter(key),
          _kTagLen * 8,
          iv,
          Uint8List(0),
        ),
      );

    final out = Uint8List(cipher.getOutputSize(plain.length));
    var off = cipher.processBytes(plain, 0, plain.length, out, 0);
    off += cipher.doFinal(out, off);

    // out = ciphertext (off - 16 bytes) + tag (16 bytes)
    final ciphertext = out.sublist(0, off - _kTagLen);
    final tag = out.sublist(off - _kTagLen, off);

    final magic = Uint8List.fromList(_kMagic.codeUnits);
    final result = Uint8List(
      magic.length + _kSaltLen + _kIvLen + _kTagLen + ciphertext.length,
    );
    var pos = 0;
    result.setRange(pos, pos += magic.length, magic);
    result.setRange(pos, pos += _kSaltLen, salt);
    result.setRange(pos, pos += _kIvLen, iv);
    result.setRange(pos, pos += _kTagLen, tag);
    result.setRange(pos, pos + ciphertext.length, ciphertext);
    return result;
  }

  Uint8List? _decryptBytes(Uint8List data, String password) {
    try {
      final magic = Uint8List.fromList(_kMagic.codeUnits);
      if (data.length < magic.length + _kSaltLen + _kIvLen + _kTagLen) {
        return null;
      }
      for (int i = 0; i < magic.length; i++) {
        if (data[i] != magic[i]) return null;
      }
      var pos = magic.length;
      final salt = data.sublist(pos, pos += _kSaltLen);
      final iv = data.sublist(pos, pos += _kIvLen);
      final tag = data.sublist(pos, pos += _kTagLen);
      final ciphertext = data.sublist(pos);

      final key = _deriveKey(password, salt);

      // GCM decrypt — يحتاج ciphertext + tag مُلحَق
      final combined = Uint8List(ciphertext.length + _kTagLen)
        ..setRange(0, ciphertext.length, ciphertext)
        ..setRange(ciphertext.length, ciphertext.length + _kTagLen, tag);

      final cipher = pc.GCMBlockCipher(pc.AESEngine())
        ..init(
          false,
          pc.AEADParameters(
            pc.KeyParameter(key),
            _kTagLen * 8,
            iv,
            Uint8List(0),
          ),
        );

      final plain = Uint8List(cipher.getOutputSize(combined.length));
      var off = cipher.processBytes(combined, 0, combined.length, plain, 0);
      off += cipher.doFinal(plain, off);
      return plain.sublist(0, off);
    } catch (_) {
      return null;
    }
  }

  Uint8List _deriveKey(String password, Uint8List salt) {
    final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64))
      ..init(pc.Pbkdf2Parameters(salt, _kPbkdfIterations, _kKeyLen));
    return pbkdf2.process(Uint8List.fromList(password.codeUnits));
  }

  Uint8List _randomBytes(int length) {
    final rng = pc.SecureRandom('Fortuna')
      ..seed(
        pc.KeyParameter(
          Uint8List.fromList(
            List.generate(
              32,
              (i) => (DateTime.now().microsecondsSinceEpoch >> (i % 8)) & 0xFF,
            ),
          ),
        ),
      );
    return rng.nextBytes(length);
  }

  // ════════════════════════════════════════════════════════════════════════
  // build
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      'بـ PBKDF2-SHA256 (${_kPbkdfIterations ~/ 1000}k تكرار). '
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
                    onPressed: (_working || kIsWeb) ? null : _importBackup,
                    icon: const Icon(Icons.restore_outlined),
                    label: const Text('استعادة نسخة'),
                  ),
                ),
              ],
            ),

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
// _CloudSyncStatusCard — ودجت حالة التزامن السحابي مع Google Drive
// ════════════════════════════════════════════════════════════════════════════

class _CloudSyncStatusCard extends ConsumerWidget {
  const _CloudSyncStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cloudService = ref.watch(cloudBackupServiceProvider);
    final info = cloudService.info;

    final isSynced = info.status == CloudSyncStatus.synced;
    final statusText = isSynced
        ? 'متصل ومُتزامن مع Google Drive'
        : 'جاهز للمزامنة السحابية تلقائياً';

    return Card(
      color: isSynced ? Colors.teal.shade50 : theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_done_outlined,
                  color: isSynced ? Colors.teal.shade700 : theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'المزامنة السحابية (Google Drive)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              statusText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSynced ? Colors.teal.shade900 : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (info.lastSyncTime != null) ...[
              const SizedBox(height: 4),
              Text(
                'آخر رفع سحابي: ${info.lastSyncTime.toString().split('.')[0]} (${info.formattedSize})',
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
