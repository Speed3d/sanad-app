// ─────────────────────────────────────────────────────────────────────────────
// audit_logger.dart — مساعد سجل التدقيق المركزي
//
// هذا الملف يوفر واجهة بسيطة وموحدة لتسجيل أحداث النظام في سجل التدقيق.
//
// الغرض:
//   بدلاً من استدعاء AuditLogDao مباشرة من كل Repository أو Provider،
//   يُستخدم هذا المساعد الذي يوحّد أسماء الجداول وأنواع العمليات
//   ويُبسّط عملية التسجيل.
//
// كيفية الاستخدام:
//   // في أي Repository أو Provider:
//   final logger = ref.read(auditLoggerProvider);
//
//   // تسجيل تسجيل دخول
//   await logger.logLogin(userId: 1, username: 'admin');
//
//   // تسجيل إنشاء سند
//   await logger.logVoucherCreated(userId: 1, username: 'admin', voucherId: 42, amount: 150000);
//
//   // تسجيل استيراد Excel
//   await logger.logExcelImport(userId: 1, username: 'admin', rowCount: 50, vaultName: 'الخزينة الرئيسية');
//
// ثوابت أنواع العمليات المدعومة:
//   AuditActions.login         → 'LOGIN'
//   AuditActions.logout        → 'LOGOUT'
//   AuditActions.voucherInsert → 'INSERT'
//   AuditActions.voucherDelete → 'DELETE'
//   AuditActions.fiscalClose   → 'FISCAL_CLOSE'
//   AuditActions.backupCreate  → 'BACKUP_CREATE'
//   AuditActions.excelImport   → 'EXCEL_IMPORT'
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/daos/audit_log_dao.dart';
import '../../../presentation/providers/database_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ثوابت أسماء الجداول (Tables)
// ─────────────────────────────────────────────────────────────────────────────

/// أسماء الجداول المستخدمة في سجل التدقيق
///
/// يجب استخدام هذه الثوابت دائماً بدلاً من كتابة الأسماء يدوياً
/// لتجنب الأخطاء الإملائية وضمان الاتساق
abstract final class AuditTables {
  /// جدول المستخدمين
  static const String users = 'users';

  /// جدول السندات (قبض + صرف + تحويل + افتتاحي)
  static const String vouchers = 'vouchers';

  /// جدول الخزائن
  static const String treasuries = 'treasuries';

  /// جدول الموظفين
  static const String employees = 'employees';

  /// جدول السلف النقدية
  static const String cashAdvances = 'cash_advances';

  /// جدول الرواتب
  static const String salaryPayments = 'salary_payments';

  /// جدول المقاولين
  static const String contractors = 'contractors';

  /// جدول الشركاء
  static const String partners = 'partners';

  /// جدول الفترات المالية
  static const String fiscalPeriods = 'fiscal_periods';

  /// جدول الإعدادات
  static const String appSettings = 'app_settings';

  /// جدول سلف المشاريع (≠ cash_advances سلف الموظفين)
  static const String advances = 'advances';

  /// جدول المرفقات (Schema v6)
  static const String attachments = 'attachments';

  /// حدث على مستوى النظام (لا يرتبط بجدول محدد)
  static const String system = 'system';
}

// ─────────────────────────────────────────────────────────────────────────────
// ثوابت أنواع العمليات (Actions)
// ─────────────────────────────────────────────────────────────────────────────

/// أنواع العمليات المسجَّلة في سجل التدقيق
abstract final class AuditActions {
  // ── المصادقة ─────────────────────────────────────────────────────────────

  /// تسجيل الدخول
  static const String login = 'LOGIN';

  /// تسجيل الخروج
  static const String logout = 'LOGOUT';

  // ── عمليات CRUD ───────────────────────────────────────────────────────────

  /// إدراج سجل جديد
  static const String insert = 'INSERT';

  /// تحديث سجل موجود
  static const String update = 'UPDATE';

  /// حذف سجل (ناعم أو فعلي)
  static const String delete = 'DELETE';

  // ── العمليات المالية ──────────────────────────────────────────────────────

  /// إغلاق الفترة المالية
  static const String fiscalClose = 'FISCAL_CLOSE';

  /// إعادة فتح الفترة المالية
  static const String fiscalReopen = 'FISCAL_REOPEN';

  /// إنشاء رصيد افتتاحي
  static const String openingBalance = 'OPENING_BALANCE';

  /// تحويل بين الخزائن
  static const String transfer = 'TRANSFER';

  /// اعتماد سلفة مشروع (تحويل المسودة إلى سندات صرف)
  static const String advancePost = 'ADVANCE_POST';

  /// إلغاء سلفة مشروع (حذف ناعم لسندات صرفها)
  static const String advanceCancel = 'ADVANCE_CANCEL';

  // ── عمليات النسخ الاحتياطي ───────────────────────────────────────────────

  /// إنشاء نسخة احتياطية
  static const String backupCreate = 'BACKUP_CREATE';

  /// استعادة نسخة احتياطية
  static const String backupRestore = 'BACKUP_RESTORE';

  /// رفع للسحابة
  static const String cloudUpload = 'CLOUD_UPLOAD';

  // ── عمليات الاستيراد والتصدير ────────────────────────────────────────────

  /// استيراد ملف Excel
  static const String excelImport = 'EXCEL_IMPORT';

  /// تصدير ملف Excel
  static const String excelExport = 'EXCEL_EXPORT';

  /// تصدير تقرير PDF
  static const String pdfExport = 'PDF_EXPORT';

  // ── إعدادات النظام ────────────────────────────────────────────────────────

  /// تغيير إعداد في النظام
  static const String settingChanged = 'SETTING_CHANGED';
}

// ─────────────────────────────────────────────────────────────────────────────
// كلاس مساعد سجل التدقيق
// ─────────────────────────────────────────────────────────────────────────────

/// مساعد سجل التدقيق — واجهة بسيطة لتسجيل الأحداث
///
/// يُحقَن عبر Riverpod باستخدام [auditLoggerProvider]
class AuditLogger {
  // ── المُنشئ ───────────────────────────────────────────────────────────────

  /// [_dao] — كائن الوصول لجدول سجل التدقيق
  const AuditLogger(this._dao);

  final AuditLogDao _dao;

  // ── أحداث المصادقة ────────────────────────────────────────────────────────

  /// تسجيل حدث تسجيل الدخول
  ///
  /// [userId]   — معرّف المستخدم الذي سجّل الدخول
  /// [username] — اسم المستخدم
  Future<void> logLogin({
    required int userId,
    required String username,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.users,
          action: AuditActions.login,
          recordId: userId,
          meta: _toMeta({'event': 'user_login'}),
        ));
  }

  /// تسجيل حدث تسجيل الخروج
  ///
  /// [userId]   — معرّف المستخدم
  /// [username] — اسم المستخدم
  Future<void> logLogout({
    required int userId,
    required String username,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.users,
          action: AuditActions.logout,
          recordId: userId,
          meta: _toMeta({'event': 'user_logout'}),
        ));
  }

  /// تسجيل محاولة دخول فاشلة (كلمة مرور خاطئة)
  ///
  /// [userId]    — معرّف المستخدم المستهدَف (إن وُجد)
  /// [username]  — اسم المستخدم المُدخَل
  /// [attempts]  — رقم المحاولة الحالية
  Future<void> logLoginFailed({
    int? userId,
    required String username,
    required int attempts,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.users,
          action: AuditActions.login,
          recordId: userId,
          meta: _toMeta({'event': 'login_failed', 'attempts': attempts}),
        ));
  }

  /// تسجيل قفل حساب بعد تجاوز حد المحاولات الفاشلة
  ///
  /// [userId]      — معرّف المستخدم المقفول
  /// [username]    — اسم المستخدم
  /// [lockedUntil] — وقت انتهاء القفل
  Future<void> logAccountLocked({
    int? userId,
    required String username,
    required DateTime lockedUntil,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.users,
          action: AuditActions.login,
          recordId: userId,
          meta: _toMeta({
            'event': 'account_locked',
            'locked_until': lockedUntil.toIso8601String(),
          }),
        ));
  }

  /// تسجيل حذف/أرشفة سجلات التدقيق نفسها (عملية حساسة يجب أن تُوثَّق)
  ///
  /// [userId]       — معرّف المستخدم المنفِّذ
  /// [username]     — اسم المستخدم
  /// [deletedCount] — عدد السجلات المحذوفة
  /// [cutoffDate]   — التاريخ الذي حُذف ما قبله
  Future<void> logAuditPurge({
    required int userId,
    required String username,
    required int deletedCount,
    required DateTime cutoffDate,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.system,
          action: AuditActions.delete,
          meta: _toMeta({
            'event': 'audit_purge',
            'deleted_count': deletedCount,
            'cutoff_date': cutoffDate.toIso8601String(),
          }),
        ));
  }

  /// تسجيل **تصفير جميع البيانات المالية** — أخطر عملية في التطبيق
  ///
  /// ⚠️ لماذا؟ (إصلاح ث-١ — تدقيق 2026-08-23)
  ///   هذه العملية تمحو كل السندات والفترات والسلف دفعةً واحدة، وكانت
  ///   تُنفَّذ **بلا أي أثر في سجل التدقيق**. فلو ضغطها أحدهم لما بقي في
  ///   النظام ما يدل على أن شيئاً كان موجوداً أصلاً — ولا من محاه.
  ///   نسجّل العدّادات **قبل** المسح لأنها تختفي بعده.
  ///
  /// [vouchersDeleted] / [periodsDeleted] / [advancesDeleted] — ما مُحي فعلاً
  Future<void> logFinancialDataReset({
    required int userId,
    required String username,
    required int vouchersDeleted,
    required int periodsDeleted,
    required int advancesDeleted,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.system,
          action: AuditActions.delete,
          meta: _toMeta({
            'event': 'financial_data_reset',
            'vouchers_deleted': vouchersDeleted,
            'periods_deleted': periodsDeleted,
            'advances_deleted': advancesDeleted,
          }),
        ));
  }

  // ── أحداث السندات ─────────────────────────────────────────────────────────

  /// تسجيل إنشاء سند جديد
  ///
  /// [userId]      — معرّف المستخدم المنشئ
  /// [username]    — اسم المستخدم
  /// [voucherId]   — معرّف السند الجديد
  /// [voucherType] — نوع السند ('sarf', 'kabd', 'transfer', ...)
  /// [amount]      — مبلغ السند
  /// [currency]    — العملة ('IQD' أو 'USD')
  /// [treasuryId]  — معرّف الخزينة المؤثرة
  Future<void> logVoucherCreated({
    required int userId,
    required String username,
    required int voucherId,
    required String voucherType,
    required double amount,
    String currency = 'IQD',
    int? treasuryId,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.vouchers,
          action: AuditActions.insert,
          recordId: voucherId,
          meta: _toMeta({
            'voucher_type': voucherType,
            'amount': amount,
            'currency': currency,
            if (treasuryId != null) 'treasury_id': treasuryId,
          }),
        ));
  }

  /// تسجيل **تعديل** سند قائم — مع القيم قبل التعديل وبعده
  ///
  /// ⚠️ لماذا هذه الدالة ضرورية؟ (إصلاح ث-٢ — تدقيق 2026-08-23)
  ///   كان السجل يوثّق الإنشاء والحذف فقط، والتعديل يمرّ صامتاً تماماً —
  ///   رغم أنه **أخطر العمليات الثلاث** محاسبياً: السند المُنشأ والمحذوف
  ///   يظهران في القوائم فيلاحظهما المالك، أما تغيير مبلغ سند قائم من
  ///   ١٠٠ ألف إلى ٩٠٠ ألف فلا يترك أثراً يميّزه عن سند أُدخل صحيحاً منذ
  ///   البداية. كانت هذه فجوة في إصلاح CRIT-4 نفسه.
  ///
  /// نسجّل **القيمة السابقة والجديدة معاً** لا الجديدة وحدها، وإلا لما أمكن
  /// معرفة حجم التغيير عند المراجعة — وهو بيت القصيد.
  ///
  /// [voucherId]     — معرّف السند المعدَّل
  /// [voucherType]   — نوع السند ('sarf' | 'kabd')
  /// [oldAmount] / [newAmount]     — المبلغ قبل وبعد
  /// [oldCurrency] / [newCurrency] — العملة قبل وبعد
  /// [oldTreasuryId] / [newTreasuryId] — الخزينة قبل وبعد (النقل يغيّر رصيدين)
  /// [oldDate] / [newDate]         — تاريخ السند قبل وبعد
  Future<void> logVoucherUpdated({
    required int userId,
    required String username,
    required int voucherId,
    required String voucherType,
    required double oldAmount,
    required double newAmount,
    required String oldCurrency,
    required String newCurrency,
    required int oldTreasuryId,
    required int newTreasuryId,
    DateTime? oldDate,
    DateTime? newDate,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.vouchers,
          action: AuditActions.update,
          recordId: voucherId,
          meta: _toMeta({
            'voucher_type': voucherType,
            'old_amount': oldAmount,
            'new_amount': newAmount,
            // الفرق مُحتسَب مسبقاً ليقرأه المراجع مباشرة دون حساب ذهني
            'amount_delta': newAmount - oldAmount,
            'old_currency': oldCurrency,
            'new_currency': newCurrency,
            'old_treasury_id': oldTreasuryId,
            'new_treasury_id': newTreasuryId,
            if (oldDate != null) 'old_date': oldDate.toIso8601String(),
            if (newDate != null) 'new_date': newDate.toIso8601String(),
          }),
        ));
  }

  /// تسجيل حذف سند
  ///
  /// [userId]     — معرّف المستخدم الذي أجرى الحذف
  /// [username]   — اسم المستخدم
  /// [voucherId]  — معرّف السند المحذوف
  /// [amount]     — مبلغ السند المحذوف (لمراجعة تأثير الحذف على الرصيد)
  Future<void> logVoucherDeleted({
    required int userId,
    required String username,
    required int voucherId,
    required double amount,
    String currency = 'IQD',
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.vouchers,
          action: AuditActions.delete,
          recordId: voucherId,
          meta: _toMeta({
            'deleted_amount': amount,
            'currency': currency,
            'note': 'soft_delete',
          }),
        ));
  }

  // ── أحداث المرفقات (Schema v6) ────────────────────────────────────────────

  /// تسجيل إرفاق ملف بسلفة أو سند
  ///
  /// المرفق دليل مادّي على السند — فإرفاقه وحذفه حدثان يستحقّان الأثر تماماً
  /// كتعديل مبلغ. ومن دون التسجيل لا يُعرف من أرفق فاتورة ولا من أزالها.
  Future<void> logAttachmentAdded({
    required int userId,
    required String username,
    required String entityType,
    required int entityId,
    required String fileName,
    required int sizeBytes,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.attachments,
          action: AuditActions.insert,
          recordId: entityId,
          meta: _toMeta({
            'entity_type': entityType,
            'file_name': fileName,
            'size_bytes': sizeBytes,
          }),
        ));
  }

  /// تسجيل حذف مرفق
  ///
  /// نحفظ اسم الملف لأنه يختفي من الفهرس بعد الحذف — فيبقى في السجل أثرٌ
  /// لما أُزيل لا مجرّد أن شيئاً أُزيل.
  Future<void> logAttachmentDeleted({
    required int userId,
    required String username,
    required String entityType,
    required int entityId,
    required String fileName,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.attachments,
          action: AuditActions.delete,
          recordId: entityId,
          meta: _toMeta({
            'entity_type': entityType,
            'file_name': fileName,
          }),
        ));
  }

  // ── أحداث استيراد Excel ───────────────────────────────────────────────────

  /// تسجيل استيراد ملف Excel
  ///
  /// [userId]      — معرّف المستخدم المستورِد
  /// [username]    — اسم المستخدم
  /// [rowCount]    — عدد صفوف البيانات المستوردة
  /// [treasuryId]  — معرّف الخزينة التي خُصم منها المبلغ
  /// [treasuryName]— اسم الخزينة
  /// [totalAmount] — المبلغ الإجمالي المستورد
  Future<void> logExcelImport({
    required int userId,
    required String username,
    required int rowCount,
    required int treasuryId,
    required String treasuryName,
    required double totalAmount,
    String? fileName,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.vouchers,
          action: AuditActions.excelImport,
          meta: _toMeta({
            'row_count': rowCount,
            'treasury_id': treasuryId,
            'treasury_name': treasuryName,
            'total_amount': totalAmount,
            if (fileName != null) 'file_name': fileName,
          }),
        ));
  }

  // ── أحداث سلف المشاريع ────────────────────────────────────────────────────

  /// تسجيل اعتماد سلفة مشروع
  ///
  /// أهم حدث في نظام السلف: اللحظة التي تتحوّل فيها المسودة إلى سندات وتتأثر
  /// الخزينة. يُسجَّل معه **مقدار العجز واسم من غطّاه** لأنه دَين على الشركة
  /// يجب أن يبقى له أثر مستقل عن جدول السلف نفسه.
  ///
  /// [advanceId]       — معرّف السلفة
  /// [advanceNumber]   — رقمها المعروض
  /// [vouchersCreated] — عدد سندات الصرف المُنشأة
  /// [totalAmount]     — إجمالي المبلغ المُرحَّل
  /// [deficit]         — مقدار العجز (0 = لا عجز)
  /// [deficitCoveredBy]— من غطّى العجز من ماله
  Future<void> logAdvancePosted({
    required int userId,
    required String username,
    required int advanceId,
    required String advanceNumber,
    required int vouchersCreated,
    required double totalAmount,
    required int treasuryId,
    String treasuryName = '',
    double deficit = 0,
    String? deficitCoveredBy,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.advances,
          action: AuditActions.advancePost,
          recordId: advanceId,
          meta: _toMeta({
            'advance_number': advanceNumber,
            'vouchers_created': vouchersCreated,
            'total_amount': totalAmount,
            'treasury_id': treasuryId,
            if (treasuryName.isNotEmpty) 'treasury_name': treasuryName,
            'deficit': deficit,
            if (deficit > 0 && deficitCoveredBy != null)
              'deficit_covered_by': deficitCoveredBy,
          }),
        ));
  }

  /// تسجيل إلغاء سلفة مشروع
  ///
  /// [vouchersReversed] — عدد سندات الصرف التي حُذفت حذفاً ناعماً
  Future<void> logAdvanceCancelled({
    required int userId,
    required String username,
    required int advanceId,
    required String advanceNumber,
    required String previousStatus,
    int vouchersReversed = 0,
    double reversedAmount = 0,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.advances,
          action: AuditActions.advanceCancel,
          recordId: advanceId,
          meta: _toMeta({
            'advance_number': advanceNumber,
            'previous_status': previousStatus,
            'vouchers_reversed': vouchersReversed,
            'reversed_amount': reversedAmount,
          }),
        ));
  }

  // ── أحداث النسخ الاحتياطي ─────────────────────────────────────────────────

  /// تسجيل إنشاء نسخة احتياطية
  ///
  /// [userId]   — معرّف المستخدم
  /// [username] — اسم المستخدم
  /// [filePath] — مسار ملف النسخة الاحتياطية
  Future<void> logBackupCreated({
    required int userId,
    required String username,
    required String filePath,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.system,
          action: AuditActions.backupCreate,
          meta: _toMeta({'file_path': filePath}),
        ));
  }

  /// تسجيل استعادة نسخة احتياطية
  ///
  /// [userId]   — معرّف المستخدم
  /// [username] — اسم المستخدم
  /// [filePath] — مسار ملف النسخة المستعادة
  Future<void> logBackupRestored({
    required int userId,
    required String username,
    required String filePath,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.system,
          action: AuditActions.backupRestore,
          meta: _toMeta({'file_path': filePath}),
        ));
  }

  // ── أحداث الفترات المالية ─────────────────────────────────────────────────

  /// تسجيل إغلاق فترة مالية
  ///
  /// [userId]         — معرّف المستخدم المغلِق
  /// [username]       — اسم المستخدم
  /// [fiscalPeriodId] — معرّف الفترة المالية
  /// [periodName]     — اسم الفترة (مثال: 'السنة المالية 2025')
  Future<void> logFiscalClose({
    required int userId,
    required String username,
    required int fiscalPeriodId,
    required String periodName,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.fiscalPeriods,
          action: AuditActions.fiscalClose,
          recordId: fiscalPeriodId,
          meta: _toMeta({'period_name': periodName}),
        ));
  }

  /// تسجيل إعادة فتح فترة مالية
  ///
  /// [userId]         — معرّف المستخدم
  /// [username]       — اسم المستخدم
  /// [fiscalPeriodId] — معرّف الفترة المالية
  /// [periodName]     — اسم الفترة
  /// تسجيل **المحو القسري** لفترة مالية بكل سنداتها
  ///
  /// ⚠️ هذا السطر هو **الأثر الوحيد الباقي** بعد العملية — البيانات نفسها
  ///   تُمحى نهائياً. لولاه لصار في البرنامج زرٌّ يمحو الدفاتر بلا شاهد،
  ///   ولا يُعرَف بعدها أن سنةً كانت موجودة أصلاً ولا من محاها.
  ///   لهذا لا يُمسّ سجل التدقيق في المحو مهما كان. (قرار المالك 2026-08-23.)
  Future<void> logFiscalPurged({
    required int userId,
    required String username,
    required String periodName,
    required int vouchersPurged,
    required int advancesPurged,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.fiscalPeriods,
          action: AuditActions.delete,
          meta: _toMeta({
            'event': 'fiscal_period_purged',
            'period_name': periodName,
            'vouchers_purged': vouchersPurged,
            'advances_purged': advancesPurged,
            'note': 'hard_delete_irreversible',
          }),
        ));
  }

  /// تسجيل حذف فترة مالية خالية
  ///
  /// الفترة الخالية لا أثر مالي لها، لكن حذفها قرار إداري يجب أن يبقى له
  /// شاهد: من حذف أي سنة ومتى — وإلا اختفى السجلّ بلا ذكر.
  Future<void> logFiscalDeleted({
    required int userId,
    required String username,
    required int fiscalPeriodId,
    required String periodName,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.fiscalPeriods,
          action: AuditActions.delete,
          recordId: fiscalPeriodId,
          meta: _toMeta({
            'period_name': periodName,
            'note': 'empty_period_deleted',
          }),
        ));
  }

  Future<void> logFiscalReopen({
    required int userId,
    required String username,
    required int fiscalPeriodId,
    required String periodName,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.fiscalPeriods,
          action: AuditActions.fiscalReopen,
          recordId: fiscalPeriodId,
          meta: _toMeta({'period_name': periodName}),
        ));
  }

  // ── أحداث المستخدمين ──────────────────────────────────────────────────────

  /// تسجيل إنشاء مستخدم جديد
  ///
  /// [adminId]       — معرّف المدير المنشئ
  /// [adminUsername] — اسم المدير
  /// [newUserId]     — معرّف المستخدم الجديد
  /// [newUsername]   — اسم المستخدم الجديد
  /// [role]          — دور المستخدم الجديد
  Future<void> logUserCreated({
    required int adminId,
    required String adminUsername,
    required int newUserId,
    required String newUsername,
    required String role,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: adminId,
          username: adminUsername,
          table: AuditTables.users,
          action: AuditActions.insert,
          recordId: newUserId,
          meta: _toMeta({
            'new_username': newUsername,
            'role': role,
          }),
        ));
  }

  // ── أحداث الإعدادات ───────────────────────────────────────────────────────

  /// تسجيل تغيير إعداد في النظام
  ///
  /// [userId]   — معرّف المستخدم
  /// [username] — اسم المستخدم
  /// [key]      — مفتاح الإعداد
  /// [oldValue] — القيمة القديمة
  /// [newValue] — القيمة الجديدة
  Future<void> logSettingChanged({
    required int userId,
    required String username,
    required String key,
    required String oldValue,
    required String newValue,
  }) async {
    await _safeLog(() => _dao.logSimpleAction(
          userId: userId,
          username: username,
          table: AuditTables.appSettings,
          action: AuditActions.settingChanged,
          meta: _toMeta({
            'key': key,
            'old_value': oldValue,
            'new_value': newValue,
          }),
        ));
  }

  // ── الدوال الداخلية المساعدة ──────────────────────────────────────────────

  /// تحويل Map إلى JSON String آمن للتخزين في الـ meta_json
  String _toMeta(Map<String, dynamic> data) {
    try {
      return jsonEncode(data);
    } catch (_) {
      return '{}'; // في حالة فشل التحويل، أعد JSON فارغ
    }
  }

  /// تسجيل آمن — يبتلع الاستثناءات لئلا يعطّل العملية الأصلية
  ///
  /// سجل التدقيق لا يجب أبداً أن يُفشل العملية الأصلية.
  /// إذا فشل التسجيل، نطبعه في الـ Console فقط.
  Future<void> _safeLog(Future<void> Function() logAction) async {
    try {
      await logAction();
    } catch (e) {
      // لا نرمي الاستثناء — التسجيل ثانوي والعملية الأصلية أهم
      // ignore: avoid_print
      print('[AuditLogger] ⚠️ فشل تسجيل حدث التدقيق: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod Provider
// ─────────────────────────────────────────────────────────────────────────────

/// مُزوِّد مساعد سجل التدقيق
///
/// يُقرأ من خلاله في أي Repository أو Notifier:
///   final logger = ref.read(auditLoggerProvider);
final auditLoggerProvider = Provider<AuditLogger>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AuditLogger(db.auditLogDao);
});
