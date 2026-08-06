// ─────────────────────────────────────────────────────────────────────────────
// contractor_model.dart — نموذج المقاول في طبقة الـ Domain
// ─────────────────────────────────────────────────────────────────────────────

import 'package:freezed_annotation/freezed_annotation.dart';

part 'contractor_model.freezed.dart';
part 'contractor_model.g.dart';

/// نموذج المقاول
@freezed
abstract class ContractorModel with _$ContractorModel {
  const factory ContractorModel({
    /// المعرّف الفريد
    required int id,

    /// اسم المقاول أو الشركة
    required String name,

    /// رقم الهاتف الأول
    @Default('') String phone1,

    /// رقم الهاتف الثاني (اختياري)
    @Default('') String phone2,

    /// العنوان
    @Default('') String address,

    /// نوع المقاول: 'individual' | 'company'
    @Default('individual') String contractorType,

    /// معرّف الخزينة الخاصة بالمقاول (اختياري)
    int? treasuryId,

    /// ملاحظات
    @Default('') String notes,

    /// هل المقاول نشط؟
    @Default(true) bool isActive,

    /// تاريخ الإنشاء
    DateTime? createdAt,
  }) = _ContractorModel;

  factory ContractorModel.fromJson(Map<String, dynamic> json) =>
      _$ContractorModelFromJson(json);
}

// ── Extensions مساعدة ────────────────────────────────────────────────────────

/// امتدادات لنموذج المقاول
extension ContractorModelX on ContractorModel {
  /// هل هو فرد أم شركة؟
  bool get isCompany => contractorType == 'company';

  /// وصف النوع بالعربية
  String get typeDisplayName =>
      contractorType == 'company' ? 'شركة' : 'فرد';

  /// هاتف للعرض (الأول أو الثاني إذا كان الأول فارغاً)
  String get displayPhone => phone1.isNotEmpty ? phone1 : phone2;
}
