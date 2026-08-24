// ─────────────────────────────────────────────────────────────────────────────
// attachment_providers.dart — مزوّدات المرفقات (المرحلة ج)
//
// يربط بين الطبقتين المنفصلتين عمداً:
//   `AttachmentsDao`     → الفهرس في قاعدة البيانات
//   `AttachmentService`  → الملفات على القرص
//
// **ترتيب العمليات هنا هو جوهر السلامة:**
//   الإرفاق: انسخ الملف **ثم** سجّل الصفّ — فشل النسخ لا يترك فهرساً كاذباً
//   الحذف:   احذف الصفّ **ثم** امحُ الملف — فشل المحو يترك ملفاً معلّقاً فقط
//
// في الحالتين، الخطأ الأسوأ (فهرس يشير إلى ملف غير موجود) مستحيل بنيوياً.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/auth/permissions.dart';
import '../../core/constants/app_settings_keys.dart';
import '../../core/services/attachment_service.dart';
import '../../core/utils/audit_logger.dart';
import '../../data/database/app_database.dart';

import '../../domain/models/auth_state.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'repository_providers.dart';

part 'attachment_providers.g.dart';

// ── الإعداد ─────────────────────────────────────────────────────────────────

/// جذر مجلد المرفقات — فارغ يعني «لم يُعيَّن بعد»
@riverpod
Stream<String?> attachmentsRoot(Ref ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchSetting(AppSettingsKeys.attachmentsRoot);
}

// ── القراءة ─────────────────────────────────────────────────────────────────

/// مرفقات كيان محدَّد — تدفّق تفاعلي
@riverpod
Stream<List<Attachment>> attachmentsFor(
  Ref ref, {
  required String entityType,
  required int entityId,
}) {
  return ref.watch(appDatabaseProvider).attachmentsDao.watchForEntity(
        entityType: entityType,
        entityId: entityId,
      );
}

/// إجمالي حجم كل المرفقات — يُعرَض قبل النسخة الاحتياطية الشاملة
@riverpod
Future<int> attachmentsTotalSize(Ref ref) {
  return ref.watch(appDatabaseProvider).attachmentsDao.totalSizeBytes();
}

// ═══════════════════════════════════════════════════════════════════════════
// AttachmentNotifier — الإرفاق والحذف والفتح
// ═══════════════════════════════════════════════════════════════════════════

/// نتيجة عملية مرفق — رسالة عربية جاهزة للعرض
typedef AttachmentOutcome = ({bool ok, String message});

@riverpod
class AttachmentNotifier extends _$AttachmentNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  AppDatabase get _db => ref.read(appDatabaseProvider);

  int? get _userId {
    final s = ref.read(authNotifierProvider);
    return s is AuthAuthenticated ? s.user.id : null;
  }

  String get _username {
    final s = ref.read(authNotifierProvider);
    return s is AuthAuthenticated ? s.user.username : 'system';
  }

  /// الجذر المُعيَّن حالياً — يرمي رسالة عربية إن لم يُعيَّن
  Future<String> _requireRoot() async {
    final root = await ref
        .read(settingsRepositoryProvider)
        .getString(AppSettingsKeys.attachmentsRoot);
    if (root == null || root.trim().isEmpty) {
      throw const AttachmentException(
        'لم يُحدَّد مجلد المرفقات بعد.\n'
        'عيّنه من: الإعدادات ← المرفقات.',
      );
    }
    return root;
  }

  // ── الإرفاق ───────────────────────────────────────────────────────────────

  /// إرفاق ملف بكيان
  ///
  /// [folderName] — اسم المجلد داخل سنة المرفق (يُبنى من رقم السلفة أو السند)
  /// [year]       — سنة الكيان، لتنظيم المجلدات كتنظيم الملفات الورقية
  ///
  /// **الترتيب:** ينسخ الملف أولاً ثم يسجّل الصفّ. لو فُعل العكس وفشل النسخ
  /// لبقي في الفهرس صفّ يشير إلى ملف غير موجود.
  Future<AttachmentOutcome> attach({
    required String entityType,
    required int entityId,
    required String sourcePath,
    required int year,
    required String folderName,
    String notes = '',
  }) async {
    state = const AsyncLoading();
    try {
      final root = await _requireRoot();

      // ١) نسخ الملف إلى مخزن المرفقات
      final prepared = await AttachmentService.copyIntoStore(
        root: root,
        sourcePath: sourcePath,
        year: year,
        folderName: folderName,
      );

      // ٢) كشف التكرار — بعد النسخ لأن البصمة تُحسَب من المحتوى
      final duplicate = await _db.attachmentsDao.findDuplicate(
        entityType: entityType,
        entityId: entityId,
        sha256: prepared.sha256,
      );
      if (duplicate != null) {
        // نتراجع عن النسخة الزائدة كي لا يمتلئ المخزن بنسخ متطابقة
        await AttachmentService.deleteFile(
          root: root,
          relativePath: prepared.relativePath,
        );
        state = const AsyncData(null);
        return (
          ok: false,
          message: 'هذا الملف مرفق سابقاً باسم «${duplicate.fileName}».',
        );
      }

      // ٣) تسجيل الصفّ
      await _db.attachmentsDao.insertAttachment(
        AttachmentsCompanion.insert(
          entityType: entityType,
          entityId: entityId,
          fileName: prepared.fileName,
          relativePath: prepared.relativePath,
          mimeType: Value(prepared.mimeType),
          sizeBytes: Value(prepared.sizeBytes),
          sha256: Value(prepared.sha256),
          uploadedByUserId: Value(_userId),
          notes: Value(notes.trim()),
        ),
      );

      await ref.read(auditLoggerProvider).logAttachmentAdded(
            userId: _userId ?? 0,
            username: _username,
            entityType: entityType,
            entityId: entityId,
            fileName: prepared.fileName,
            sizeBytes: prepared.sizeBytes,
          );

      state = const AsyncData('تم إرفاق الملف ✓');
      return (ok: true, message: 'تم إرفاق «${prepared.fileName}» ✓');
    } on AttachmentException catch (e) {
      state = AsyncError(e.message, StackTrace.empty);
      return (ok: false, message: e.message);
    } catch (e, st) {
      state = AsyncError(e, st);
      return (ok: false, message: 'تعذّر إرفاق الملف: $e');
    }
  }

  // ── الحذف ─────────────────────────────────────────────────────────────────

  /// حذف مرفق — يتطلّب صلاحية حذف السندات
  ///
  /// **الترتيب:** يحذف الصفّ أولاً ثم الملف. لو فُعل العكس وفشل حذف الصفّ
  /// لبقي فهرس يشير إلى ملف محذوف — وهو أسوأ من ملف معلّق لا يشير إليه شيء.
  Future<AttachmentOutcome> remove(int attachmentId) async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated ||
        !auth.user.can(AppPermission.deleteVoucher)) {
      return (ok: false, message: 'حذف المرفقات يتطلّب صلاحية مدير.');
    }

    state = const AsyncLoading();
    try {
      final row = await _db.attachmentsDao.getById(attachmentId);
      if (row == null) {
        state = const AsyncData(null);
        return (ok: false, message: 'المرفق غير موجود.');
      }

      await _db.attachmentsDao.deleteAttachment(attachmentId);

      final root = await ref
          .read(settingsRepositoryProvider)
          .getString(AppSettingsKeys.attachmentsRoot);
      if (root != null && root.trim().isNotEmpty) {
        await AttachmentService.deleteFile(
          root: root,
          relativePath: row.relativePath,
        );
      }

      await ref.read(auditLoggerProvider).logAttachmentDeleted(
            userId: _userId ?? 0,
            username: _username,
            entityType: row.entityType,
            entityId: row.entityId,
            fileName: row.fileName,
          );

      state = const AsyncData('تم حذف المرفق ✓');
      return (ok: true, message: 'تم حذف «${row.fileName}» ✓');
    } catch (e, st) {
      state = AsyncError(e, st);
      return (ok: false, message: 'تعذّر حذف المرفق: $e');
    }
  }

  // ── الفتح ─────────────────────────────────────────────────────────────────

  /// فتح مرفق بالتطبيق الافتراضي
  Future<AttachmentOutcome> open(Attachment attachment) async {
    try {
      final root = await _requireRoot();
      await AttachmentService.openFile(
        root: root,
        relativePath: attachment.relativePath,
      );
      return (ok: true, message: '');
    } on AttachmentException catch (e) {
      return (ok: false, message: e.message);
    } catch (e) {
      return (ok: false, message: 'تعذّر فتح الملف: $e');
    }
  }

  /// إظهار المرفق في مستكشف الملفات
  Future<AttachmentOutcome> reveal(Attachment attachment) async {
    try {
      final root = await _requireRoot();
      await AttachmentService.revealInExplorer(
        root: root,
        relativePath: attachment.relativePath,
      );
      return (ok: true, message: '');
    } on AttachmentException catch (e) {
      return (ok: false, message: e.message);
    }
  }

  void reset() => state = const AsyncData(null);
}
