// ─────────────────────────────────────────────────────────────────────────────
// voucher_providers.dart — Providers السندات
//
// يُوفّر Providers تفاعلية لقوائم السندات وكشف الحساب:
//   - سندات خزينة محددة (Stream)
//   - سندات حسب النوع (Stream)
//   - كشف الحساب لخزينة (Future)
//   - ملخص اليوم للـ Dashboard (Future)
//   - بحث في السندات (Future)
//   - الفترة المالية النشطة (Future)
//   - سند بالمعرّف (Future — للتعديل)
//   - VoucherSarfNotifier — CRUD سندات الصرف
//
// ملاحظة مهمة:
//   تم تسمية معاملات التاريخ بـ startDate/endDate بدلاً من from/to
//   لأن `from` اسم محجوز في Riverpod Family API
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/voucher_model.dart';
import '../../domain/repositories/i_voucher_repository.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'repository_providers.dart';

part 'voucher_providers.g.dart';

// ── قوائم السندات التفاعلية ────────────────────────────────────────────────

/// Stream تفاعلي لسندات خزينة محددة
///
/// يتحدث تلقائياً عند إضافة / تعديل / حذف أي سند في هذه الخزينة
@riverpod
Stream<List<VoucherModel>> vouchersByTreasury(Ref ref, int treasuryId) {
  final repo = ref.watch(voucherRepositoryProvider);
  return repo.watchVouchersByTreasury(treasuryId);
}

/// Stream تفاعلي لسندات حسب نوعها ('sarf' | 'kabd')
@riverpod
Stream<List<VoucherModel>> vouchersByType(Ref ref, String voucherType) {
  final repo = ref.watch(voucherRepositoryProvider);
  return repo.watchVouchersByType(voucherType);
}

// ── استعلامات لمرة واحدة ───────────────────────────────────────────────────

/// سندات ضمن نطاق تاريخ مع فلاتر اختيارية
///
/// استخدام تسمية startDate/endDate بدلاً من from/to
/// لتجنب التعارض مع Riverpod Family.from API
@riverpod
Future<List<VoucherModel>> vouchersByDateRange(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
  int? treasuryId,
  String? voucherType,
  int? fiscalPeriodId,
}) {
  final repo = ref.watch(voucherRepositoryProvider);
  return repo.getVouchersByDateRange(
    from: startDate,
    to: endDate,
    treasuryId: treasuryId,
    voucherType: voucherType,
    fiscalPeriodId: fiscalPeriodId,
  );
}

/// كشف الحساب لخزينة في نطاق تاريخ محدد
@riverpod
Future<List<AccountStatementModel>> accountStatement(
  Ref ref, {
  required int treasuryId,
  required DateTime startDate,
  required DateTime endDate,
  double openingBalanceIqd = 0,
  double openingBalanceUsd = 0,
}) {
  final repo = ref.watch(voucherRepositoryProvider);
  return repo.getAccountStatement(
    treasuryId: treasuryId,
    from: startDate,
    to: endDate,
    openingBalanceIqd: openingBalanceIqd,
    openingBalanceUsd: openingBalanceUsd,
  );
}

/// ملخص الصرف والقبض ليوم محدد — للـ Dashboard
@riverpod
Future<({double totalSarf, double totalKabd})> dailySummary(
  Ref ref,
  DateTime date,
) {
  final repo = ref.watch(voucherRepositoryProvider);
  return repo.getDailySummary(date);
}

/// بحث في السندات بنص حر
///
/// يُعيد قائمة فارغة فوراً إذا كان النص فارغاً
@riverpod
Future<List<VoucherModel>> searchVouchers(Ref ref, String query) {
  if (query.trim().isEmpty) return Future.value([]);
  final repo = ref.watch(voucherRepositoryProvider);
  return repo.searchVouchers(query.trim());
}

/// تقرير السلف (يبحث في السندات التي تحتوي على رقم سلفة)
@riverpod
Future<List<VoucherModel>> advanceReports(
  Ref ref, {
  String? advanceNumber,
  String? projectName,
  String? invoiceNumber,
}) async {
  final db = ref.watch(appDatabaseProvider);
  final rows = await db.vouchersDao.searchAdvanceVouchers(
    advanceNumber: advanceNumber,
    projectName: projectName,
    invoiceNumber: invoiceNumber,
  );
  return rows
      .map((v) => VoucherModel(
            id: v.id,
            voucherNumber: v.voucherNumber,
            voucherType: v.voucherType,
            treasuryId: v.treasuryId,
            fiscalPeriodId: v.fiscalPeriodId,
            amount: v.amount,
            currency: v.currency,
            exchangeRate: v.exchangeRate,
            voucherDate: v.voucherDate,
            personName: v.personName,
            reason: v.reason,
            itemType: v.itemType,
            referenceNumber: v.referenceNumber,
            closeSafe: v.closeSafe,
            linkedTreasuryId: v.linkedTreasuryId,
            linkedEntityId: v.linkedEntityId,
            projectName: v.projectName,
            invoiceNumber: v.invoiceNumber,
            spentBy: v.spentBy,
            advanceNumber: v.advanceNumber,
            isDeleted: v.isDeleted,
            deletedAt: v.deletedAt,
          ))
      .toList();
}

// ── الفترات المالية المساعدة ────────────────────────────────────────────────

/// الفترة المالية النشطة لتاريخ اليوم
///
/// يُستخدَم في شاشة سند الصرف/القبض لعرض الفترة الحالية
@riverpod
Future<FiscalPeriod?> activeFiscalPeriod(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.fiscalPeriodsDao.getFiscalPeriodForDate(DateTime.now());
}

/// الفترة المالية المناسبة لتاريخ محدد
///
/// يتغيّر تلقائياً عند تغيير التاريخ في النموذج
@riverpod
Future<FiscalPeriod?> fiscalPeriodForDate(Ref ref, DateTime date) {
  final db = ref.watch(appDatabaseProvider);
  return db.fiscalPeriodsDao.getFiscalPeriodForDate(date);
}

// ── سند بالمعرّف (للتعديل) ──────────────────────────────────────────────────

/// تفاصيل سند واحد — يُستخدَم في وضع التعديل
@riverpod
Future<VoucherModel?> voucherById(Ref ref, int id) async {
  final db = ref.watch(appDatabaseProvider);
  final v = await db.vouchersDao.getVoucherById(id);
  if (v == null) return null;
  return VoucherModel(
    id: v.id,
    voucherNumber: v.voucherNumber,
    voucherType: v.voucherType,
    treasuryId: v.treasuryId,
    fiscalPeriodId: v.fiscalPeriodId,
    amount: v.amount,
    currency: v.currency,
    exchangeRate: v.exchangeRate,
    voucherDate: v.voucherDate,
    personName: v.personName,
    reason: v.reason,
    itemType: v.itemType,
    referenceNumber: v.referenceNumber,
    closeSafe: v.closeSafe,
    linkedTreasuryId: v.linkedTreasuryId,
    linkedEntityId: v.linkedEntityId,
    isDeleted: v.isDeleted,
    deletedAt: v.deletedAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// VoucherSarfNotifier — إدارة عمليات سندات الصرف
// ═══════════════════════════════════════════════════════════════════════════

/// Notifier لعمليات إنشاء / تعديل / حذف سندات الصرف
///
/// الحالة:
///   AsyncData(null)      — لا عملية جارية (idle)
///   AsyncData('رسالة')   — نجاح العملية
///   AsyncLoading()       — عملية جارية
///   AsyncError(...)      — فشل العملية
@riverpod
class VoucherSarfNotifier extends _$VoucherSarfNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  IVoucherRepository get _repo => ref.read(voucherRepositoryProvider);
  AppDatabase get _db => ref.read(appDatabaseProvider);

  int? get _userId {
    final s = ref.read(authNotifierProvider);
    return s is AuthAuthenticated ? s.user.id : null;
  }

  // ── إنشاء سند صرف جديد ─────────────────────────────────────────────────

  /// إنشاء سند صرف جديد مع الكشف التلقائي للفترة المالية
  Future<bool> createSarf({
    required int treasuryId,
    required double amount,
    required String currency,
    required DateTime voucherDate,
    String personName = '',
    String reason = '',
    String itemType = '',
    String referenceNumber = '',
    bool closeSafe = false,
    double exchangeRate = 1.0,
  }) async {
    if (amount <= 0) {
      state = const AsyncError(
        'المبلغ يجب أن يكون أكبر من صفر',
        StackTrace.empty,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      // الكشف التلقائي عن الفترة المالية حسب تاريخ السند
      final period =
          await _db.fiscalPeriodsDao.getFiscalPeriodForDate(voucherDate);
      if (period == null) {
        state = const AsyncError(
          'لا توجد فترة مالية نشطة لهذا التاريخ\nتحقق من إعدادات الفترات المالية',
          StackTrace.empty,
        );
        return false;
      }
      await _repo.createVoucher(
        fiscalPeriodId: period.id,
        voucherType: 'sarf',
        treasuryId: treasuryId,
        amount: amount,
        currency: currency,
        voucherDate: voucherDate,
        personName: personName,
        reason: reason,
        itemType: itemType,
        referenceNumber: referenceNumber,
        closeSafe: closeSafe,
        exchangeRate: exchangeRate,
        createdByUserId: _userId,
      );
      state = const AsyncData('تم إنشاء سند الصرف بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── تعديل سند صرف ──────────────────────────────────────────────────────

  /// تحديث بيانات سند صرف موجود
  Future<bool> updateSarf(
    VoucherModel voucher, {
    required int treasuryId,
    required double amount,
    required String currency,
    required DateTime voucherDate,
    String personName = '',
    String reason = '',
    String itemType = '',
    String referenceNumber = '',
    bool closeSafe = false,
    double exchangeRate = 1.0,
  }) async {
    if (amount <= 0) {
      state = const AsyncError(
        'المبلغ يجب أن يكون أكبر من صفر',
        StackTrace.empty,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      await _repo.updateVoucher(
        voucher.copyWith(
          treasuryId: treasuryId,
          amount: amount,
          currency: currency,
          voucherDate: voucherDate,
          personName: personName,
          reason: reason,
          itemType: itemType,
          referenceNumber: referenceNumber,
          closeSafe: closeSafe,
          exchangeRate: exchangeRate,
        ),
      );
      state = const AsyncData('تم تحديث السند بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── حذف سند صرف ────────────────────────────────────────────────────────

  /// حذف ناعم لسند الصرف
  Future<bool> deleteSarf(int id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteVoucher(id, deletedByUserId: _userId);
      state = const AsyncData('تم حذف السند ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// إعادة الحالة لـ idle
  void reset() => state = const AsyncData(null);
}

// ═══════════════════════════════════════════════════════════════════════════
// VoucherKabdNotifier — إدارة عمليات سندات القبض
// ═══════════════════════════════════════════════════════════════════════════

/// Notifier لعمليات إنشاء / تعديل / حذف سندات القبض
///
/// الحالة:
///   AsyncData(null)      — لا عملية جارية (idle)
///   AsyncData('رسالة')   — نجاح العملية
///   AsyncLoading()       — عملية جارية
///   AsyncError(...)      — فشل العملية
@riverpod
class VoucherKabdNotifier extends _$VoucherKabdNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  IVoucherRepository get _repo => ref.read(voucherRepositoryProvider);
  AppDatabase get _db => ref.read(appDatabaseProvider);

  int? get _userId {
    final s = ref.read(authNotifierProvider);
    return s is AuthAuthenticated ? s.user.id : null;
  }

  // ── إنشاء سند قبض جديد ─────────────────────────────────────────────────

  /// إنشاء سند قبض جديد مع الكشف التلقائي للفترة المالية
  Future<bool> createKabd({
    required int treasuryId,
    required double amount,
    required String currency,
    required DateTime voucherDate,
    String personName = '',
    String reason = '',
    String itemType = '',
    String referenceNumber = '',
    double exchangeRate = 1.0,
  }) async {
    if (amount <= 0) {
      state = const AsyncError(
        'المبلغ يجب أن يكون أكبر من صفر',
        StackTrace.empty,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      final period =
          await _db.fiscalPeriodsDao.getFiscalPeriodForDate(voucherDate);
      if (period == null) {
        state = const AsyncError(
          'لا توجد فترة مالية نشطة لهذا التاريخ\nتحقق من إعدادات الفترات المالية',
          StackTrace.empty,
        );
        return false;
      }
      await _repo.createVoucher(
        fiscalPeriodId: period.id,
        voucherType: 'kabd',
        treasuryId: treasuryId,
        amount: amount,
        currency: currency,
        voucherDate: voucherDate,
        personName: personName,
        reason: reason,
        itemType: itemType,
        referenceNumber: referenceNumber,
        exchangeRate: exchangeRate,
        createdByUserId: _userId,
      );
      state = const AsyncData('تم إنشاء سند القبض بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── تعديل سند قبض ──────────────────────────────────────────────────────

  /// تحديث بيانات سند قبض موجود
  Future<bool> updateKabd(
    VoucherModel voucher, {
    required int treasuryId,
    required double amount,
    required String currency,
    required DateTime voucherDate,
    String personName = '',
    String reason = '',
    String itemType = '',
    String referenceNumber = '',
    double exchangeRate = 1.0,
  }) async {
    if (amount <= 0) {
      state = const AsyncError(
        'المبلغ يجب أن يكون أكبر من صفر',
        StackTrace.empty,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      await _repo.updateVoucher(
        voucher.copyWith(
          treasuryId: treasuryId,
          amount: amount,
          currency: currency,
          voucherDate: voucherDate,
          personName: personName,
          reason: reason,
          itemType: itemType,
          referenceNumber: referenceNumber,
          exchangeRate: exchangeRate,
        ),
      );
      state = const AsyncData('تم تحديث السند بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── حذف سند قبض ────────────────────────────────────────────────────────

  /// حذف ناعم لسند القبض
  Future<bool> deleteKabd(int id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteVoucher(id, deletedByUserId: _userId);
      state = const AsyncData('تم حذف السند ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// إعادة الحالة لـ idle
  void reset() => state = const AsyncData(null);
}

// ═══════════════════════════════════════════════════════════════════════════
// AdvanceDeleteNotifier — إلغاء وتراجع عن السلف
// ═══════════════════════════════════════════════════════════════════════════

@riverpod
class AdvanceDeleteNotifier extends _$AdvanceDeleteNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  Future<bool> deleteAdvance(String advanceNumber) async {
    state = const AsyncLoading();
    try {
      final db = ref.read(appDatabaseProvider);
      final s = ref.read(authNotifierProvider);
      final userId = s is AuthAuthenticated ? s.user.id : null;

      await db.vouchersDao.softDeleteAdvance(
        advanceNumber,
        deletedByUser: userId,
      );

      // تنشيط Providers المتعلقة بالتقارير لتحديث الواجهة تلقائياً
      ref.invalidate(advanceReportsProvider);
      ref.invalidate(accountStatementProvider);
      ref.invalidate(vouchersByTypeProvider);

      state = const AsyncData('تم إلغاء السلفة واسترداد المبالغ بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VoucherTransferNotifier — إدارة عمليات التحويل بين الخزائن
// ═══════════════════════════════════════════════════════════════════════════

@riverpod
class VoucherTransferNotifier extends _$VoucherTransferNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  IVoucherRepository get _repo => ref.read(voucherRepositoryProvider);
  AppDatabase get _db => ref.read(appDatabaseProvider);

  int? get _userId {
    final s = ref.read(authNotifierProvider);
    return s is AuthAuthenticated ? s.user.id : null;
  }

  Future<bool> createTransfer({
    required int fromTreasuryId,
    required int toTreasuryId,
    required double amount,
    required String currency,
    required DateTime voucherDate,
    String reason = '',
    double exchangeRate = 1.0,
  }) async {
    if (fromTreasuryId == toTreasuryId) {
      state = const AsyncError(
        'لا يمكن التحويل لنفس الخزينة',
        StackTrace.empty,
      );
      return false;
    }
    if (amount <= 0) {
      state = const AsyncError(
        'المبلغ يجب أن يكون أكبر من صفر',
        StackTrace.empty,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      final period =
          await _db.fiscalPeriodsDao.getFiscalPeriodForDate(voucherDate);
      if (period == null) {
        state = const AsyncError(
          'لا توجد فترة مالية نشطة لهذا التاريخ',
          StackTrace.empty,
        );
        return false;
      }

      await _repo.createTransfer(
        fromTreasuryId: fromTreasuryId,
        toTreasuryId: toTreasuryId,
        amount: amount,
        currency: currency,
        fiscalPeriodId: period.id,
        voucherDate: voucherDate,
        reason: reason,
        exchangeRate: exchangeRate,
        createdByUserId: _userId,
      );

      state = const AsyncData('تم التحويل بين الخزائن بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  void reset() => state = const AsyncData(null);
}

