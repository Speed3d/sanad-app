// ─────────────────────────────────────────────────────────────────────────────
// payroll_repository_models.dart — نماذج مدخلات ومخرجات مستودع الرواتب
//
// **لماذا جزءٌ مستقلّ؟** `payroll_repository.dart` تجاوز سقف
//   `tech_debt_guard_test` (١٢٠٠ سطر) بعد توصيل دورة حياة الخدمة
//   (Schema v9). والفصل هنا **بحسب الطبيعة لا بحسب الحجم**: هذه أصنافُ
//   بياناتٍ خالصة بلا منطق، وتلك قواعدُ عملٍ وحرّاس.
//
// 📌 وحارس الدين التقني أسقط البناء **قبل الدمج** — للمرّة الخامسة.
// ─────────────────────────────────────────────────────────────────────────────

part of 'payroll_repository.dart';

/// سطر ملف بعد أن بتّ المالك في مطابقته بموظف
///
/// الشاشة تعرض المطابقة، والمالك يوافق أو يصحّح، ثم يصل السطر هنا **محسوماً**:
/// إما بمعرّف موظف قائم أو بطلب إنشاء صريح. لا ربط صامت ولا إنشاء صامت
/// (قرار المالك 2026-08-24).
class ResolvedPayrollRow {
  final ParsedPayrollRow row;

  /// معرّف الموظف المطابَق · `null` ⇒ يُنشأ موظف جديد بموافقة المالك
  final int? employeeId;

  /// الخزينة/المشروع الذي يُنسَب إليه الموظف الجديد
  final int? treasuryId;

  const ResolvedPayrollRow({
    required this.row,
    this.employeeId,
    this.treasuryId,
  });

  bool get createsEmployee => employeeId == null;
}

/// حصيلة استيراد ملف رواتب إلى كشف شهر
class PayrollImportResult {
  /// معرّف الكشف الذي استُورد إليه
  final int periodId;

  /// سطور أُضيفت لأول مرة
  final int added;

  /// سطور كانت موجودة فحُدِّثت
  final int updated;

  /// موظفون أُنشئوا بموافقة المالك
  final int employeesCreated;

  /// فروق بين الصافي المحسوب والمذكور في الملف — تُعرَض ولا تمنع
  final List<String> netMismatches;

  /// أسماء من **انتهت خدمتهم** فلم تُدرَج صفوفهم (Schema v8)
  ///
  /// ⚠️ **تُعرَض ولا تُبتلَع.** استبعادٌ صامت لسطر راتب هو نصف العطل الذي
  ///   طاردناه في ع-٣٣: عمليةٌ لم تقع والمالك يظنّها وقعت. وقد يكون
  ///   المحاسب محقّاً — فيُعيد المالك حالة الموظف ويستورد ثانيةً.
  final List<String> skippedTerminated;

  const PayrollImportResult({
    required this.periodId,
    required this.added,
    required this.updated,
    required this.employeesCreated,
    required this.netMismatches,
    this.skippedTerminated = const [],
  });
}

/// كيف يُحذف كشفٌ فيه رواتب مصروفة (قرار المالك 2026-08-26)
enum PayrollDeleteMode {
  /// يُحذف المستحقّ وحده · ويبقى المدفوع بسنداته في كشفه
  ///
  /// 📌 وهذا بديلُ ما طلبه المالك أولاً («احذف الكشف وأبقِ السندات») — فذاك
  ///   هو العطل نفسه: مالٌ خارج الخزينة بلا سجل. وهذا يحقّق مقصده (تنظيف
  ///   المسودة) بلا كسر الدفاتر.
  unpaidOnly,

  /// تُعكَس التسديدات (يرجع المال وتُحذف السندات وتُعاد أقساط السلف)
  /// ثم يُحذف الكشف كلّه
  reverseAndDelete,
}

/// حصيلة حذف كشف — تُعرَض للمالك ليعرف ما وقع فعلاً
class PayrollDeleteResult {
  final bool deletedPeriod;
  final int reversedCount;
  final double reversedTotalIqd;
  final int removedUnpaid;

  const PayrollDeleteResult({
    required this.deletedPeriod,
    required this.reversedCount,
    required this.reversedTotalIqd,
    required this.removedUnpaid,
  });
}

/// طبيعة تصحيح راتب مسدَّد — **تحدّد أثره المالي بالكامل**
enum PayrollCorrectionMode {
  /// المبلغ كُتب خطأً والمال **لم يخرج** به ⇒ يُصحَّح السند فيرجع الفرق
  dataEntryError,

  /// المال **خرج فعلاً** زائداً بيد الموظف ⇒ الفرق دينٌ عليه يُخصم لاحقاً
  overpaid,
}

/// حصيلة تصحيح راتب مسدَّد
class PayrollCorrectionResult {
  final int entryId;
  final String employeeName;
  final double oldAmountIqd;
  final double newAmountIqd;

  /// ما تغيّر في مبلغ سند الصرف — صفرٌ حين سُجِّل الفرق سلفةً
  final double voucherDelta;

  /// الفرق الذي سُجِّل **سلفةً على الموظف** — صفرٌ حين رجع للخزينة
  final double debtRecorded;

  const PayrollCorrectionResult({
    required this.entryId,
    required this.employeeName,
    required this.oldAmountIqd,
    required this.newAmountIqd,
    required this.voucherDelta,
    required this.debtRecorded,
  });
}

/// مقارنة راتبٍ مصروفٍ سلفاً بما يحسبه ملف الشهر
class PaidVsFileComparison {
  final int employeeId;
  final String employeeName;

  /// ما صُرف فعلاً · وما يحسبه الملف — كلاهما بالدينار
  final double paidIqd;
  final double fileIqd;

  /// الأيام المستحقّة في كلٍّ منهما — **هي ما يشرح الفرق للمالك**
  final int paidDays;
  final int fileDays;

  final DateTime? paidAt;

  const PaidVsFileComparison({
    required this.employeeId,
    required this.employeeName,
    required this.paidIqd,
    required this.fileIqd,
    required this.paidDays,
    required this.fileDays,
    required this.paidAt,
  });

  /// موجبٌ حين صُرف أكثر مما يستحقّ
  double get difference => paidIqd - fileIqd;

  /// هامش الدينار الواحد — ما دونه ضجيج فاصلة عائمة (نفس هامش المطابقة)
  bool get hasGap => difference.abs() > 1;

  bool get isOverpaid => difference > 1;
}

/// حصيلة صرف راتب موظف واحد مباشرةً
class PaySingleSalaryResult {
  final int periodId;
  final int entryId;
  final String periodLabel;
  final String employeeName;
  final double netIqd;
  final int voucherId;
  final int voucherNumber;

  /// أُضيف إلى كشف كان **مُسدَّداً بالكامل** — يستحقّ أثراً في سجل التدقيق
  final bool addedToPostedSheet;

  /// سُدِّد سطرٌ كان قائماً في الكشف (استُورد الملف قبلاً) لا سطرٌ جديد
  final bool joinedExistingEntry;

  const PaySingleSalaryResult({
    required this.periodId,
    required this.entryId,
    required this.periodLabel,
    required this.employeeName,
    required this.netIqd,
    required this.voucherId,
    required this.voucherNumber,
    required this.addedToPostedSheet,
    required this.joinedExistingEntry,
  });
}
