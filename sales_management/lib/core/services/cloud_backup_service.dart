// ─────────────────────────────────────────────────────────────────────────────
// cloud_backup_service.dart — خدمة النسخ الاحتياطي السحابي (Google Drive Sync)
//
// الغرض:
//   يوفر هذا الملف خدمة مركزية لإدارة النسخ الاحتياطي السحابي، بما في ذلك:
//   - التزامن مع Google Drive / المجلدات السحابية
//   - التحقق من حالة النسخ المرفوعة وحجمها وتاريخ آخر مزامنة
//   - رفع الملفات المشفَّرة b"SMBAK1" تلقائياً بعد كل عملية تصدير
//
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io' as io;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// حالة النسخ الاحتياطي السحابي
enum CloudSyncStatus {
  /// غير مهيأ / غير متصل
  notConfigured,

  /// خامل / جاهز
  idle,

  /// جاري المزامنة والرفع
  syncing,

  /// نجحت المزامنة
  synced,

  /// حدث خطأ أثناء المزامنة
  error,
}

/// نموذج معلومات النسخة السحابية
class CloudBackupInfo {
  /// تاريخ آخر مزامنة سحابية
  final DateTime? lastSyncTime;

  /// اسم آخر ملف تم رفعه
  final String? lastFileName;

  /// حجم الملف بالبايت
  final int fileSizeBytes;

  /// حالة الاتصال والمزامنة
  final CloudSyncStatus status;

  /// رسالة الخطأ إن وجدت
  final String? errorMessage;

  const CloudBackupInfo({
    this.lastSyncTime,
    this.lastFileName,
    this.fileSizeBytes = 0,
    this.status = CloudSyncStatus.notConfigured,
    this.errorMessage,
  });

  /// نص منسق لحجم الملف
  String get formattedSize {
    if (fileSizeBytes <= 0) return '0 ك.ب';
    final kb = fileSizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} ك.ب';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} م.ب';
  }
}

/// خدمة إدارة وتزامن النسخ الاحتياطي السحابي
class CloudBackupService {
  CloudSyncStatus _currentStatus = CloudSyncStatus.idle;
  DateTime? _lastSync;
  String? _lastFile;
  int _lastSize = 0;

  /// جلب معلومات حالة المزامنة الحالية
  CloudBackupInfo get info => CloudBackupInfo(
        lastSyncTime: _lastSync,
        lastFileName: _lastFile,
        fileSizeBytes: _lastSize,
        status: _currentStatus,
      );

  /// رفع وتزامن ملف النسخة الاحتياطية المشفَّرة إلى المجلد السحابي المحاكي / Google Drive
  ///
  /// [backupFilePath] — المسار المحلي لملف النسخة الاحتياطية .smbak
  Future<bool> uploadBackupToCloud(String backupFilePath) async {
    _currentStatus = CloudSyncStatus.syncing;
    try {
      final file = io.File(backupFilePath);
      if (!await file.exists()) {
        _currentStatus = CloudSyncStatus.error;
        return false;
      }

      final size = await file.length();
      final name = file.path.split(io.Platform.pathSeparator).last;

      // محاكاة رفع الملف وحفظ النسخة المزامنة في المجلد السحابي المخصص
      final docDir = await getApplicationDocumentsDirectory();
      final cloudDir = io.Directory('${docDir.path}/cloud_sync');
      if (!await cloudDir.exists()) {
        await cloudDir.create(recursive: true);
      }

      final targetPath = '${cloudDir.path}/$name';
      await file.copy(targetPath);

      _lastSync = DateTime.now();
      _lastFile = name;
      _lastSize = size;
      _currentStatus = CloudSyncStatus.synced;
      return true;
    } catch (e) {
      _currentStatus = CloudSyncStatus.error;
      return false;
    }
  }

  /// استرجاع قائمة النسخ الاحتياطية المتاحة في السحابة
  Future<List<String>> listCloudBackups() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final cloudDir = io.Directory('${docDir.path}/cloud_sync');
      if (!await cloudDir.exists()) return [];

      final files = await cloudDir.list().toList();
      return files
          .whereType<io.File>()
          .where((f) => f.path.endsWith('.smbak'))
          .map((f) => f.path.split(io.Platform.pathSeparator).last)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// Provider لخدمة النسخ الاحتياطي السحابي
final cloudBackupServiceProvider = Provider<CloudBackupService>((ref) {
  return CloudBackupService();
});
