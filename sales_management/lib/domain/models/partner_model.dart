// ─────────────────────────────────────────────────────────────────────────────
// partner_model.dart — نموذج الشريك في طبقة الـ Domain
// ─────────────────────────────────────────────────────────────────────────────

import 'package:freezed_annotation/freezed_annotation.dart';

part 'partner_model.freezed.dart';
part 'partner_model.g.dart';

/// نموذج الشريك
@freezed
abstract class PartnerModel with _$PartnerModel {
  const factory PartnerModel({
    /// المعرّف الفريد
    required int id,

    /// اسم الشريك
    required String name,

    /// رقم الهاتف
    @Default('') String phone,

    /// العنوان
    @Default('') String address,

    /// نسبة الحصة في الشركة (0.0 إلى 100.0)
    @Default(0.0) double sharePercentage,

    /// معرّف الخزينة الخاصة بالشريك (اختياري)
    int? treasuryId,

    /// ملاحظات
    @Default('') String notes,

    /// هل الشريك نشط؟
    @Default(true) bool isActive,

    /// تاريخ الإنشاء
    DateTime? createdAt,
  }) = _PartnerModel;

  factory PartnerModel.fromJson(Map<String, dynamic> json) =>
      _$PartnerModelFromJson(json);
}

// ── Extensions مساعدة ────────────────────────────────────────────────────────

/// امتدادات لنموذج الشريك
extension PartnerModelX on PartnerModel {
  /// النسبة بصيغة نصية للعرض: "25.5%"
  String get shareDisplayText =>
      '${sharePercentage.toStringAsFixed(sharePercentage == sharePercentage.roundToDouble() ? 0 : 1)}%';

  /// هل الشريك صاحب الحصة الأكبر؟ (يحتاج قائمة الشركاء للمقارنة)
  bool hasLargerShareThan(double otherShare) => sharePercentage > otherShare;
}
