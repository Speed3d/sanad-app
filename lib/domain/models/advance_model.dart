// ─────────────────────────────────────────────────────────────────────────────
// advance_model.dart — نماذج سلفة المشروع في طبقة الـ Domain
//
// ⚠️ تنبيه على التسمية:
//   AdvanceModel (هنا) = سلفة مشروع — مبلغ يُرسَل لمشروع في محافظة ويُصرَف هناك.
//   سلفة الموظف (تُسدَّد من الراتب) كيان مختلف تماماً في جدول cash_advances.
//
// النماذج الثلاثة:
//   AdvanceModel     — السلفة نفسها (الترويسة)
//   AdvanceLineModel — سطر واحد من مسودة مصاريف السلفة
//   AdvanceSummary   — ملخص محسوب: المُرسَل / المصروف / المتبقي أو العجز
//
// دورة الحياة: open → draft → posted   (أو → cancelled في أي وقت)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:freezed_annotation/freezed_annotation.dart';

part 'advance_model.freezed.dart';
part 'advance_model.g.dart';

// ── ثوابت الحالات ────────────────────────────────────────────────────────────

/// حالات السلفة — مصدر واحد للحقيقة بدل نصوص متناثرة في الكود
abstract final class AdvanceStatus {
  /// أُرسل المبلغ للمشروع ولم تصل مصاريفه بعد
  static const String open = 'open';

  /// وصل ملف الإكسل وأُنشئت أسطر المسودة — تحت المراجعة
  static const String draft = 'draft';

  /// اعتُمدت وتحوّلت أسطرها إلى سندات صرف حقيقية
  static const String posted = 'posted';

  /// أُلغيت
  static const String cancelled = 'cancelled';

  /// كل الحالات المعروفة — يطابق قيد CHECK في قاعدة البيانات
  static const List<String> all = [open, draft, posted, cancelled];
}

// ── السلفة ───────────────────────────────────────────────────────────────────

/// نموذج سلفة المشروع
@freezed
abstract class AdvanceModel with _$AdvanceModel {
  const factory AdvanceModel({
    /// المعرّف الفريد
    required int id,

    /// رقم السلفة (نص لدعم ترقيم مثل '23-أ')
    required String advanceNumber,

    /// خزينة المشروع التي أُرسل إليها المبلغ ويُصرَف منها
    required int projectTreasuryId,

    /// الفترة المالية
    required int fiscalPeriodId,

    /// اسم المشروع (للعرض والتقارير)
    @Default('') String projectName,

    /// تاريخ السلفة
    required DateTime advanceDate,

    /// الحالة — راجع [AdvanceStatus]
    @Default(AdvanceStatus.open) String status,

    /// إجمالي المبالغ كما قُرئت من ملف الإكسل قبل أي تعديل (مرجع المطابقة)
    @Default(0.0) double excelTotal,

    /// اسم ملف الإكسل المستورَد
    @Default('') String sourceFileName,

    /// بصمة SHA-256 لمحتوى الملف — لكشف الاستيراد المكرر
    @Default('') String sourceFileHash,

    /// مقدار العجز وقت الاعتماد (0 = لا عجز)
    @Default(0.0) double deficitAmount,

    /// اسم من غطّى العجز من ماله — الدائن على الشركة
    String? deficitCoveredBy,

    /// ملاحظات
    @Default('') String notes,

    /// من أنشأ السلفة ومتى
    int? createdByUserId,
    required DateTime createdAt,

    /// من اعتمدها ومتى
    int? postedByUserId,
    DateTime? postedAt,

    /// من ألغاها ومتى
    int? cancelledByUserId,
    DateTime? cancelledAt,
  }) = _AdvanceModel;

  factory AdvanceModel.fromJson(Map<String, dynamic> json) =>
      _$AdvanceModelFromJson(json);
}

/// امتدادات مساعدة على السلفة
extension AdvanceModelX on AdvanceModel {
  /// هل ما زالت بانتظار وصول مصاريفها؟
  bool get isOpen => status == AdvanceStatus.open;

  /// هل هي مسودة تحت المراجعة؟
  bool get isDraft => status == AdvanceStatus.draft;

  /// هل اعتُمدت؟
  bool get isPosted => status == AdvanceStatus.posted;

  /// هل أُلغيت؟
  bool get isCancelled => status == AdvanceStatus.cancelled;

  /// هل يمكن تعديل أسطرها؟ (المسودة فقط)
  bool get isEditable => isDraft;

  /// هل اعتُمدت بعجز؟ (الشركة مدينة لمن غطّاه)
  bool get hasDeficit => isPosted && deficitAmount > 0;

  /// وصف الحالة بالعربية
  String get statusDisplayName {
    switch (status) {
      case AdvanceStatus.open:
        return 'مفتوحة';
      case AdvanceStatus.draft:
        return 'مسودة';
      case AdvanceStatus.posted:
        return 'معتمدة';
      case AdvanceStatus.cancelled:
        return 'ملغاة';
      default:
        return status;
    }
  }
}

// ── سطر المسودة ──────────────────────────────────────────────────────────────

/// سطر واحد من مسودة مصاريف السلفة (= صف واحد في ملف الإكسل)
@freezed
abstract class AdvanceLineModel with _$AdvanceLineModel {
  const factory AdvanceLineModel({
    /// المعرّف الفريد
    required int id,

    /// السلفة التي ينتمي إليها
    required int advanceId,

    /// رقم الصف في ملف الإكسل الأصلي
    @Default(0) int rowNumber,

    /// تاريخ الصرف
    required DateTime voucherDate,

    /// المبلغ بالدينار (الاستيراد لا يقبل الدولار)
    required double amount,

    /// نوع البند / الفلتر — كهربائيات، بانزين، راتب…
    @Default('') String itemType,

    /// السبب / البيان
    @Default('') String reason,

    /// اسم الشخص المرتبط بالمصروف
    @Default('') String personName,

    /// اسم المشروع كما ورد في الملف
    String? projectName,

    /// رقم الفاتورة أو الوصل
    String? invoiceNumber,

    /// من قام بالصرف فعلياً في الموقع
    String? spentBy,

    /// ── القيم الأصلية من الإكسل (لا تتغير أبداً) ──
    required double originalAmount,
    @Default('') String originalItemType,
    required DateTime originalDate,

    /// هل عُدِّل هذا السطر عن أصله؟
    @Default(false) bool isEdited,

    /// هل استُبعد من الاعتماد؟
    @Default(false) bool isExcluded,

    /// سبب الاستبعاد
    @Default('') String excludeReason,

    /// معرّف السند الناتج بعد الاعتماد — null ما دامت مسودة
    int? voucherId,

    /// كشف الرواتب الذي يسدّده هذا السطر (Schema v7) — null في السطر العادي
    ///
    /// وجوده يعني أن السطر ليس مصروفاً عادياً بل **«تسديد رواتب شهر كذا»**،
    /// فيُستبدَل مبلغه عند الاعتماد بمطابقةٍ محروسة مع مجموع رواتب موظفي
    /// خزينة هذا المشروع. راجع `AdvancesDao.postAdvance`.
    int? payrollPeriodId,
  }) = _AdvanceLineModel;

  factory AdvanceLineModel.fromJson(Map<String, dynamic> json) =>
      _$AdvanceLineModelFromJson(json);
}

/// امتدادات مساعدة على سطر المسودة
extension AdvanceLineModelX on AdvanceLineModel {
  /// هل يدخل هذا السطر في الإجمالي والاعتماد؟
  bool get isCounted => !isExcluded;

  /// هل تغيّر المبلغ عن الأصل؟
  bool get amountChanged => (amount - originalAmount).abs() > 0.001;

  /// هل تغيّر تصنيف البند عن الأصل؟
  bool get itemTypeChanged => itemType != originalItemType;

  /// هل تغيّر التاريخ عن الأصل؟
  bool get dateChanged => !voucherDate.isAtSameMomentAs(originalDate);

  /// هل هذا السطر مربوط بكشف رواتب؟
  bool get isPayrollLinked => payrollPeriodId != null;
}

// ── الملخص المحسوب ───────────────────────────────────────────────────────────

/// ملخص السلفة — الأرقام التي يريد المالك رؤيتها في سطر واحد
///
/// هذا هو جوهر «المطابقة»:
///   أرسلتُ [sent]، صرفوا [spent]، فالمتبقي [remaining] أو العجز [deficit].
@freezed
abstract class AdvanceSummary with _$AdvanceSummary {
  const factory AdvanceSummary({
    /// المبلغ المُرسَل للمشروع — مجموع سندات التحويل الواردة المرتبطة بالسلفة
    @Default(0.0) double sent,

    /// المصروف — مجموع أسطر المسودة غير المستبعدة (قبل الاعتماد)
    /// أو مجموع سندات الصرف المرتبطة (بعد الاعتماد)
    @Default(0.0) double spent,

    /// إجمالي ملف الإكسل كما وصل — مرجع ثابت للمطابقة
    @Default(0.0) double excelTotal,

    /// رصيد خزينة المشروع الحالي
    @Default(0.0) double treasuryBalance,

    /// عدد الأسطر الداخلة في الحساب
    @Default(0) int countedLines,

    /// عدد الأسطر المستبعدة
    @Default(0) int excludedLines,

    /// عدد الأسطر المعدَّلة عن أصلها
    @Default(0) int editedLines,

    /// هل السلفة معتُمدة بالفعل؟
    ///
    /// يغيّر معنى [AdvanceSummaryX.deficit] جذرياً — راجع تعليقه.
    @Default(false) bool isPosted,

    /// العجز المُثبَّت وقت الاعتماد (يُقرأ من السلفة، ذو معنى بعد الاعتماد فقط)
    @Default(0.0) double postedDeficit,
  }) = _AdvanceSummary;

  factory AdvanceSummary.fromJson(Map<String, dynamic> json) =>
      _$AdvanceSummaryFromJson(json);
}

/// امتدادات حسابية على الملخص
extension AdvanceSummaryX on AdvanceSummary {
  /// المتبقي من السلفة (موجب = لم يُصرَف كله)
  double get remaining => sent - spent;

  /// مقدار العجز (0 = لا عجز)
  ///
  /// ⚠️ للمعنى حالتان مختلفتان — والخلط بينهما يعطي رقماً مضلِّلاً:
  ///
  /// **قبل الاعتماد** (مسودة): عجز *متوقَّع* = كم سينقص الرصيد لو اعتمدنا الآن.
  ///   يُحسَب من **رصيد الخزينة** لا من المُرسَل، لأن الخزينة قد تحمل بقايا
  ///   سلف سابقة أو تحويلات أخرى، والاعتماد يخصم منها هي لا من رقم السلفة.
  ///
  /// **بعد الاعتماد**: العجز *الواقع* كما ثُبِّت لحظة الاعتماد. لا يجوز إعادة
  ///   حسابه من الرصيد الحالي: الاعتماد نفسه خفّض الرصيد، فإعادة الحساب تعطي
  ///   رقماً منتفخاً (مثال: أُرسل 3 مليون وصُرف 2.5 بلا أي عجز، لكن بعد
  ///   الاعتماد يصبح الرصيد 0.5 فيُحسَب «عجز» وهمي = 2.5 − 0.5 = 2 مليون).
  ///   كشف هذا اختبارُ «الحالة الطبيعية: صُرف أقل من المُرسَل».
  double get deficit {
    if (isPosted) return postedDeficit;
    final d = spent - treasuryBalance;
    return d > 0.001 ? d : 0.0;
  }

  /// هل سيُنتج الاعتماد رصيداً سالباً؟
  bool get willCauseDeficit => deficit > 0;

  /// هل يطابق إجمالي المسودة إجمالي ملف الإكسل؟
  ///
  /// عدم التطابق ليس خطأً بالضرورة — قد يكون المالك استبعد سطراً أو صحّح
  /// مبلغاً عمداً — لكنه يجب أن يبقى **مرئياً** لا صامتاً.
  bool get matchesExcel => (spent - excelTotal).abs() < 0.001;

  /// الفرق بين المسودة والإكسل (موجب = المسودة أكبر)
  double get excelDifference => spent - excelTotal;
}
