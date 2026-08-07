// ─────────────────────────────────────────────────────────────────────────────
// i_advance_repository.dart — واجهة مستودع سلف المشاريع
//
// تعريف العقد فقط — التنفيذ في data/repositories/advance_repository.dart
//
// ⚠️ Advances (سلفة مشروع) ≠ CashAdvances (سلفة موظف تُسدَّد من الراتب)
//
// مسار العمل الذي تخدمه هذه الواجهة:
//   createAdvance    → السلفة مفتوحة (أُرسل المبلغ للمشروع)
//   createDraft…     → وصل ملف الإكسل فصارت مسودة
//   updateLine/…     → مراجعة وتصحيح تصنيف المصروفات
//   postAdvance      → الاعتماد: هنا فقط تتأثر الخزينة
// ─────────────────────────────────────────────────────────────────────────────

import '../models/advance_model.dart';

/// بيانات سطر واحد قادم من ملف الإكسل (قبل الحفظ في قاعدة البيانات)
class ParsedAdvanceLine {
  final int rowNumber;
  final DateTime date;
  final double amount;
  final String itemType;
  final String reason;
  final String personName;
  final String? projectName;
  final String? invoiceNumber;
  final String? spentBy;

  const ParsedAdvanceLine({
    required this.rowNumber,
    required this.date,
    required this.amount,
    this.itemType = '',
    this.reason = '',
    this.personName = '',
    this.projectName,
    this.invoiceNumber,
    this.spentBy,
  });
}

/// نتيجة محاولة اعتماد سلفة
///
/// نُعيد نتيجة صريحة بدل رمي استثناء للحالات المتوقعة (عجز يحتاج قراراً،
/// اسم مفقود)، لأنها ليست أخطاء برمجية بل خطوات في حوار مع المستخدم.
class PostAdvanceOutcome {
  /// هل تم الاعتماد فعلاً؟
  final bool success;

  /// رسالة عربية للعرض (نجاح أو سبب الرفض)
  final String message;

  /// مقدار العجز المكتشَف (0 = لا عجز)
  final double deficit;

  /// هل سبب الرفض هو أن العجز يحتاج تأكيداً صريحاً من المستخدم؟
  final bool needsDeficitConfirmation;

  /// عدد السندات التي أُنشئت عند النجاح
  final int vouchersCreated;

  const PostAdvanceOutcome({
    required this.success,
    required this.message,
    this.deficit = 0,
    this.needsDeficitConfirmation = false,
    this.vouchersCreated = 0,
  });
}

/// ما تراجعنا عنه فعلاً عند إلغاء سلفة
///
/// تُعيدها [IAdvanceRepository.cancelAdvance] لتغذية سجل التدقيق: بعد الحذف
/// الناعم لا يمكن قراءة حجم ما عُكِس، فيجب التقاطه لحظة الإلغاء.
class CancelAdvanceInfo {
  final String advanceNumber;
  final String previousStatus;
  final int vouchersReversed;
  final double reversedAmount;

  const CancelAdvanceInfo({
    required this.advanceNumber,
    required this.previousStatus,
    this.vouchersReversed = 0,
    this.reversedAmount = 0,
  });
}

/// واجهة مستودع سلف المشاريع
abstract class IAdvanceRepository {
  // ── قراءة ────────────────────────────────────────────────────────────────

  /// متابعة السلف حسب الحالة (null = الكل)
  Stream<List<AdvanceModel>> watchAdvances({String? status});

  /// متابعة سلفة واحدة
  Stream<AdvanceModel?> watchAdvance(int id);

  /// جلب سلفة بالمعرّف
  Future<AdvanceModel?> getAdvance(int id);

  /// السلف المفتوحة والمسودات لخزينة مشروع (لاختيارها عند الاستيراد)
  Future<List<AdvanceModel>> getActiveAdvancesForTreasury(int treasuryId);

  /// متابعة أسطر مسودة سلفة
  Stream<List<AdvanceLineModel>> watchLines(int advanceId);

  /// ملخص السلفة: المُرسَل / المصروف / المتبقي أو العجز
  Future<AdvanceSummary> getSummary(int advanceId);

  /// البحث عن سلفة استُورد فيها ملف بنفس البصمة (كشف التكرار)
  Future<AdvanceModel?> findByFileHash(String hash);

  // ── كتابة ────────────────────────────────────────────────────────────────

  /// إنشاء سلفة جديدة بحالة `open`
  ///
  /// يرمي [StateError] إذا كان الرقم مستعملاً في نفس الفترة المالية.
  Future<int> createAdvance({
    required String advanceNumber,
    required int projectTreasuryId,
    required DateTime advanceDate,
    String projectName,
    String notes,
    int? createdByUserId,
  });

  /// ربط سندات تحويل بسلفة (لاحتساب المبلغ المُرسَل)
  Future<void> linkTransferVouchers({
    required int advanceId,
    required List<int> voucherIds,
  });

  /// إنشاء مسودة من أسطر ملف إكسل — ينقل السلفة إلى حالة `draft`
  ///
  /// ⚠️ لا يُنشئ أي سند ولا يمسّ رصيد أي خزينة.
  Future<void> createDraftFromExcel({
    required int advanceId,
    required List<ParsedAdvanceLine> lines,
    required String fileName,
    required String fileHash,
    bool replaceExisting,
  });

  /// تعديل سطر في المسودة — يضبط علامة «معدَّل» تلقائياً
  Future<void> updateLine({
    required int lineId,
    DateTime? date,
    double? amount,
    String? itemType,
    String? reason,
    String? personName,
    String? projectName,
    String? invoiceNumber,
    String? spentBy,
  });

  /// استبعاد سطر من الاعتماد أو إعادته
  Future<void> setLineExcluded({
    required int lineId,
    required bool excluded,
    String reason,
  });

  /// اعتماد السلفة — يحوّل الأسطر إلى سندات صرف
  ///
  /// [allowDeficit] — لا بد أن يكون true (مع [deficitCoveredBy]) لاعتماد
  /// سلفة مصاريفها تتجاوز رصيد الخزينة. فحص **الصلاحية** مسؤولية الطبقة
  /// الأعلى (Notifier) قبل الاستدعاء.
  Future<PostAdvanceOutcome> postAdvance({
    required int advanceId,
    bool allowDeficit,
    String? deficitCoveredBy,
    int? postedByUserId,
  });

  /// إلغاء سلفة — يحذف **سندات صرفها** حذفاً ناعماً فيرتدّ المبلغ للخزينة
  ///
  /// سندات التحويل التي موّلت السلفة لا تُمَسّ: المال انتقل فعلاً إلى خزنة
  /// المشروع وما زال هناك. الإلغاء يتراجع عن تسجيل المصاريف لا عن حركة المال.
  ///
  /// يُعيد وصفاً لما عُكِس، لتغذية سجل التدقيق.
  Future<CancelAdvanceInfo> cancelAdvance({
    required int advanceId,
    int? cancelledByUserId,
  });
}
