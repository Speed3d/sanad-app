// ─────────────────────────────────────────────────────────────────────────────
// cloud_backup_service.dart — خدمة النسخة الاحتياطية الإضافية
//
// ⚠️ توضيح صادق (تصحيح تدقيق 2026-08-06):
//   هذه الخدمة **لا تتصل بأي سحابة**. كانت تُسمّى "مزامنة Google Drive"
//   وتدّعي الواجهة نجاح الرفع، بينما هي في الحقيقة تنسخ الملف إلى مجلد
//   مجاور على **نفس الجهاز ونفس القرص** — فعطل قرص واحد يمحو الأصل والنسخة.
//
//   الوضع الحالي: "نسخة محلية إضافية" (local) فقط.
//   الوضع 'drive' محجوز للمزامنة الفعلية مع Google Drive، ويتطلب إعداد
//   OAuth في Google Cloud (Client ID + شاشة موافقة) لم يُنجَز بعد. عند
//   اختياره تُعيد الخدمة حالة notConfigured بدل ادعاء نجاح كاذب.
//
// الغرض الحالي:
//   - حفظ نسخة إضافية من ملف .smbak في مجلد منفصل على الجهاز
//   - تتبع حجم آخر نسخة وتاريخها وحالتها
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io' as io;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// نمط النسخ الإضافي
enum CloudSyncMode {
  /// نسخة محلية إضافية على الجهاز (المتاح حالياً)
  localCopy,

  /// مزامنة فعلية مع Google Drive (غير مُنجَز — يحتاج إعداد OAuth)
  googleDrive,
}

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

  /// حفظ نسخة إضافية من ملف النسخة الاحتياطية
  ///
  /// [backupFilePath] — المسار المحلي لملف النسخة الاحتياطية .smbak
  /// [mode] — نمط النسخ: نسخة محلية (المتاح) أو Google Drive (غير مُنجَز)
  ///
  /// يُعيد: true إذا حُفظت النسخة الإضافية بنجاح، false خلاف ذلك.
  Future<bool> uploadBackupToCloud(
    String backupFilePath, {
    CloudSyncMode mode = CloudSyncMode.localCopy,
  }) async {
    // وضع Google Drive غير مُنجَز — لا ندّعي نجاحاً كاذباً
    if (mode == CloudSyncMode.googleDrive) {
      _currentStatus = CloudSyncStatus.notConfigured;
      return false;
    }

    _currentStatus = CloudSyncStatus.syncing;
    try {
      final file = io.File(backupFilePath);
      if (!await file.exists()) {
        _currentStatus = CloudSyncStatus.error;
        return false;
      }

      final size = await file.length();
      final name = file.path.split(io.Platform.pathSeparator).last;

      // حفظ نسخة إضافية في مجلد منفصل على نفس الجهاز
      final docDir = await getApplicationDocumentsDirectory();
      final extraDir = io.Directory('${docDir.path}/extra_backups');
      if (!await extraDir.exists()) {
        await extraDir.create(recursive: true);
      }

      final targetPath = '${extraDir.path}/$name';
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

  /// استرجاع قائمة النسخ الإضافية المحفوظة على الجهاز
  }

/// Provider لخدمة النسخ الاحتياطي السحابي
final cloudBackupServiceProvider = Provider<CloudBackupService>((ref) {
  return CloudBackupService();
});
