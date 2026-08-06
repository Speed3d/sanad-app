// ─────────────────────────────────────────────────────────────────────────────
// fiscal_period_model.dart — نموذج الفترة المالية في طبقة الـ Domain
//
// حالات الفترة المالية:
//   'active'                  — مفتوحة وقيد العمل
//   'frozen'                  — مُقفَلة (لا تعديل)
//   'frozen_pending_recompute' — مُقفَلة لكن تحتاج إعادة احتساب
//
// دورة حياة الفترة:
//   active → (إقفال بواسطة مدير النظام) → frozen
//   frozen → (إعادة فتح — Super Admin فقط) → active
//   active → (تأثير تعديل فترة سابقة) → frozen_pending_recompute
// ─────────────────────────────────────────────────────────────────────────────

import 'package:freezed_annotation/freezed_annotation.dart';

part 'fiscal_period_model.freezed.dart';
part 'fiscal_period_model.g.dart';

/// نموذج الفترة المالية
@freezed
abstract class FiscalPeriodModel with _$FiscalPeriodModel {
  const factory FiscalPeriodModel({
    /// المعرّف الفريد
    required int id,

    /// اسم الفترة (مثال: '2025', 'Q1 2025')
    required String name,

    /// نوع الفترة: 'annual' | 'quarterly' | 'monthly'
    @Default('annual') String periodType,

    /// تاريخ بداية الفترة
    required DateTime startDate,

    /// تاريخ نهاية الفترة
    required DateTime endDate,

    /// الحالة: 'active' | 'frozen' | 'frozen_pending_recompute'
    @Default('active') String status,

    /// وقت الإقفال (null إذا لم تُقفَل بعد)
    DateTime? closedAt,

    /// معرّف المستخدم الذي أقفل الفترة
    int? closedByUserId,

    /// ملاحظات الإقفال
    @Default('') String notes,
  }) = _FiscalPeriodModel;

  factory FiscalPeriodModel.fromJson(Map<String, dynamic> json) =>
      _$FiscalPeriodModelFromJson(json);
}

// ── Extensions مساعدة ────────────────────────────────────────────────────────

/// امتدادات لنموذج الفترة المالية
extension FiscalPeriodModelX on FiscalPeriodModel {
  /// هل الفترة مفتوحة وقيد العمل؟
  bool get isActive => status == 'active';

  /// هل الفترة مُقفَلة؟
  bool get isFrozen =>
      status == 'frozen' || status == 'frozen_pending_recompute';

  /// هل تحتاج إعادة احتساب؟
  bool get needsRecompute => status == 'frozen_pending_recompute';

  /// هل يمكن إنشاء سندات في هذه الفترة؟
  bool get canCreateVouchers => isActive;

  /// وصف الحالة بالعربية
  String get statusDisplayName {
    switch (status) {
      case 'active':
        return 'نشطة';
      case 'frozen':
        return 'مُقفَلة';
      case 'frozen_pending_recompute':
        return 'مُقفَلة (تحتاج مراجعة)';
      default:
        return status;
    }
  }

  /// مدة الفترة بالأيام
  int get durationInDays => endDate.difference(startDate).inDays + 1;

  /// هل التاريخ المُعطى يقع ضمن هذه الفترة؟
  bool containsDate(DateTime date) =>
      !date.isBefore(startDate) && !date.isAfter(endDate);
}
