// ─────────────────────────────────────────────────────────────────────────────
// voucher_model.dart — نموذج السند في طبقة الـ Domain
//
// السند هو القلب المحاسبي للتطبيق.
// نوعان من النماذج:
//   VoucherModel       — بيانات السند الكاملة
//   AccountStatementModel — سطر في كشف الحساب (سند + رصيد تراكمي)
//
// أنواع السندات:
//   'sarf'            — سند صرف (تخفيض الرصيد)
//   'kabd'            — سند قبض (زيادة الرصيد)
//   'opening_balance' — رصيد افتتاحي
//   'transfer_out'    — تحويل صادر (تخفيض الرصيد)
//   'transfer_in'     — تحويل وارد (زيادة الرصيد)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:freezed_annotation/freezed_annotation.dart';

part 'voucher_model.freezed.dart';
part 'voucher_model.g.dart';

/// نموذج السند الكامل
@freezed
abstract class VoucherModel with _$VoucherModel {
  const factory VoucherModel({
    /// المعرّف الفريد
    required int id,

    /// رقم السند التسلسلي ضمن السنة المالية
    required int voucherNumber,

    /// نوع السند: 'sarf' | 'kabd' | 'opening_balance' | 'transfer_out' | 'transfer_in'
    required String voucherType,

    /// معرّف الخزينة المرتبطة
    required int treasuryId,

    /// معرّف الفترة المالية
    required int fiscalPeriodId,

    /// المبلغ (دائماً موجب)
    required double amount,

    /// العملة: 'IQD' | 'USD'
    required String currency,

    /// سعر الصرف وقت إنشاء السند (للمرجعية التاريخية)
    @Default(1.0) double exchangeRate,

    /// تاريخ السند (قد يختلف عن وقت الإدخال)
    required DateTime voucherDate,

    /// اسم المستلم / الدافع
    @Default('') String personName,

    /// السبب / الوصف
    @Default('') String reason,

    /// نوع البند: راتب / سلفة / إيجار / ...
    @Default('') String itemType,

    /// الرقم المرجعي (رقم شيك، أمر دفع، ...)
    @Default('') String referenceNumber,

    /// هل يُقفَل الصندوق بعد هذا السند؟
    @Default(false) bool closeSafe,

    /// معرّف الخزينة الأخرى في عملية التحويل (اختياري)
    int? linkedTreasuryId,

    /// معرّف الكيان المرتبط (موظف / مقاول / شريك) — اختياري
    int? linkedEntityId,

    /// اسم المشروع أو موقع الصرف (لدعم السلف)
    String? projectName,

    /// رقم الفاتورة أو الوصل
    String? invoiceNumber,

    /// من قام بصرف المبلغ الفعلي
    String? spentBy,

    /// رقم السلفة التي تتبع لها هذه الصرفية (لتجميع السلف)
    String? advanceNumber,

    /// هل تم حذفه ناعماً؟
    @Default(false) bool isDeleted,

    /// وقت الحذف
    DateTime? deletedAt,
  }) = _VoucherModel;

  factory VoucherModel.fromJson(Map<String, dynamic> json) =>
      _$VoucherModelFromJson(json);
}

/// سطر واحد في كشف الحساب
///
/// يجمع بيانات السند مع الرصيد التراكمي حتى هذا السطر
@freezed
abstract class AccountStatementModel with _$AccountStatementModel {
  const factory AccountStatementModel({
    /// بيانات السند
    required VoucherModel voucher,

    /// الرصيد التراكمي بالدينار حتى هذا السطر
    required double runningBalanceIqd,

    /// الرصيد التراكمي بالدولار حتى هذا السطر
    required double runningBalanceUsd,
  }) = _AccountStatementModel;

  factory AccountStatementModel.fromJson(Map<String, dynamic> json) =>
      _$AccountStatementModelFromJson(json);
}

// ── Extensions مساعدة ────────────────────────────────────────────────────────

/// امتدادات لنموذج السند
extension VoucherModelX on VoucherModel {
  /// هل هو سند صرف؟
  bool get isSarf => voucherType == 'sarf';

  /// هل هو سند قبض؟
  bool get isKabd => voucherType == 'kabd';

  /// هل هو سند تحويل؟
  bool get isTransfer =>
      voucherType == 'transfer_out' || voucherType == 'transfer_in';

  /// هل هو سند رصيد افتتاحي؟
  bool get isOpeningBalance => voucherType == 'opening_balance';

  /// هل يزيد هذا السند الرصيد؟
  bool get isCredit =>
      voucherType == 'kabd' ||
      voucherType == 'opening_balance' ||
      voucherType == 'transfer_in';

  /// هل يُخفض هذا السند الرصيد؟
  bool get isDebit =>
      voucherType == 'sarf' || voucherType == 'transfer_out';

  /// وصف نوع السند بالعربية
  String get typeDisplayName {
    switch (voucherType) {
      case 'sarf':
        return 'سند صرف';
      case 'kabd':
        return 'سند قبض';
      case 'opening_balance':
        return 'رصيد افتتاحي';
      case 'transfer_out':
        return 'تحويل صادر';
      case 'transfer_in':
        return 'تحويل وارد';
      default:
        return voucherType;
    }
  }

  /// المبلغ بالإشارة الصحيحة (موجب للقبض، سالب للصرف)
  double get signedAmount => isCredit ? amount : -amount;
}
