// ─────────────────────────────────────────────────────────────────────────────
// treasury_model.dart — نموذج الخزينة في طبقة الـ Domain
//
// نوعان من الكيانات:
//   TreasuryModel       — بيانات الخزينة الأساسية
//   TreasuryBalanceModel — الخزينة مع رصيدها المحسوب من الـ VIEW
//
// أنواع الخزائن:
//   'main'        — خزينة رئيسية للشركة
//   'contractor'  — خزينة حساب مقاول
//   'partner'     — خزينة حساب شريك
//
// الرصيد:
//   لا يُخزَّن في الجدول — يُحسَب دائماً من الـ VIEW v_treasury_balances
//   يمكن أن يكون سالباً (خزينة مدينة)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:freezed_annotation/freezed_annotation.dart';

part 'treasury_model.freezed.dart';
part 'treasury_model.g.dart';

/// نموذج الخزينة (بدون رصيد)
@freezed
abstract class TreasuryModel with _$TreasuryModel {
  const factory TreasuryModel({
    /// المعرّف الفريد
    required int id,

    /// اسم الخزينة كما يظهر في الواجهة
    required String name,

    /// نوع الخزينة: 'main' | 'contractor' | 'partner'
    required String kind,

    /// معرّف الكيان المرتبط (موظف / مقاول / شريك)
    int? entityId,

    /// نوع الكيان: 'employee' | 'contractor' | 'partner'
    String? entityType,

    /// هل الخزينة نشطة؟
    @Default(true) bool isActive,

    /// هل تم حذفها ناعماً؟
    @Default(false) bool isDeleted,
  }) = _TreasuryModel;

  factory TreasuryModel.fromJson(Map<String, dynamic> json) =>
      _$TreasuryModelFromJson(json);
}

/// نموذج الخزينة مع الرصيد المحسوب من الـ VIEW
///
/// يُستخدَم في قوائم الخزائن وبطاقات الرصيد في الـ Dashboard
@freezed
abstract class TreasuryBalanceModel with _$TreasuryBalanceModel {
  const factory TreasuryBalanceModel({
    /// معرّف الخزينة
    required int treasuryId,

    /// اسم الخزينة
    required String treasuryName,

    /// نوع الخزينة: 'main' | 'contractor' | 'partner'
    required String treasuryKind,

    /// معرّف الكيان المرتبط (اختياري)
    int? entityId,

    /// نوع الكيان المرتبط (اختياري)
    String? entityType,

    /// هل الخزينة نشطة؟
    @Default(true) bool isActive,

    /// الرصيد بالدينار العراقي — يمكن أن يكون سالباً
    @Default(0.0) double balanceIqd,

    /// الرصيد بالدولار الأمريكي
    @Default(0.0) double balanceUsd,

    /// إجمالي عدد السندات في هذه الخزينة
    @Default(0) int totalVouchers,

    /// تاريخ آخر سند (null = لا توجد سندات)
    DateTime? lastVoucherDate,
  }) = _TreasuryBalanceModel;

  factory TreasuryBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$TreasuryBalanceModelFromJson(json);
}

// ── Extensions مساعدة ────────────────────────────────────────────────────────

/// امتدادات لنموذج الخزينة
extension TreasuryModelX on TreasuryModel {
  /// هل هي خزينة رئيسية؟
  bool get isMain => kind == 'main';

  /// هل هي خزينة مقاول؟
  bool get isContractor => kind == 'contractor';

  /// هل هي خزينة شريك؟
  bool get isPartner => kind == 'partner';

  /// وصف النوع بالعربية
  String get kindDisplayName {
    switch (kind) {
      case 'main':
        return 'خزينة رئيسية';
      case 'contractor':
        return 'حساب مقاول';
      case 'partner':
        return 'حساب شريك';
      default:
        return kind;
    }
  }
}

/// امتدادات لنموذج رصيد الخزينة
extension TreasuryBalanceModelX on TreasuryBalanceModel {
  /// هل الرصيد بالدينار سالب؟ (خزينة مدينة)
  bool get isDebtorIqd => balanceIqd < 0;

  /// هل الرصيد بالدولار سالب؟
  bool get isDebtorUsd => balanceUsd < 0;

  /// هل الخزينة خالية (رصيد صفر في كلا العملتين)؟
  bool get isEmpty => balanceIqd == 0 && balanceUsd == 0;
}
