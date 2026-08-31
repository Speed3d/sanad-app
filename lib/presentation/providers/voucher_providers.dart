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
import '../../core/services/balance_guard.dart';
import '../../core/utils/audit_logger.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/advances_dao.dart';
import '../../data/database/daos/treasuries_dao.dart';
import '../../data/database/daos/vouchers_dao.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/voucher_model.dart';
import '../../domain/repositories/i_voucher_repository.dart';
import 'advance_providers.dart';
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
Future<
    ({
      double totalSarf,
      double totalKabd,
      double totalSarfUsd,
      double totalKabdUsd,
    })> dailySummary(
  Ref ref,
  DateTime date,
) {
  final repo = ref.watch(voucherRepositoryProvider);
  return repo.getDailySummary(date);
}

/// نقطة سيولة يومية واحدة لمخطط آخر 7 أيام
class DailyLiquidityPoint {
  /// تاريخ اليوم
  final DateTime date;

  /// إجمالي القبض في هذا اليوم (IQD)
  final double kabd;

  /// إجمالي الصرف في هذا اليوم (IQD)
  final double sarf;

  const DailyLiquidityPoint({
    required this.date,
    required this.kabd,
    required this.sarf,
  });
}

/// اتجاه السيولة لآخر 7 أيام — بيانات حقيقية للمخطط في لوحة التحكم
///
/// كان المخطط يعرض أرقاماً ثابتة مُلفَّقة (تدقيق 2026-08-06). الآن يجمع
/// ملخص كل يوم من الأيام السبعة الأخيرة فعلياً من قاعدة البيانات.
@riverpod
Future<List<DailyLiquidityPoint>> weeklyLiquidity(Ref ref) async {
  final repo = ref.watch(voucherRepositoryProvider);
  final now = DateTime.now();
  final points = <DailyLiquidityPoint>[];

  // من قبل 6 أيام حتى اليوم (7 نقاط بترتيب زمني تصاعدي)
  for (var i = 6; i >= 0; i--) {
    final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
    final summary = await repo.getDailySummary(day);
    points.add(DailyLiquidityPoint(
      date: day,
      kabd: summary.totalKabd,
      sarf: summary.totalSarf,
    ));
  }
  return points;
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


// ── تقارير ب-٢ ──────────────────────────────────────────────────────────────

/// المصروفات مجمَّعة حسب البند خلال فترة
///
/// سندات الصرف وحدها — التحويلات ليست مصروفاً. راجع
/// `VouchersDao.getExpensesByItemType` لشرح القرارات المحاسبية الثلاثة.
@riverpod
Future<List<ItemTypeExpenseRow>> expensesByItemType(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
  int? treasuryId,
  String? projectName,
}) {
  return ref.watch(appDatabaseProvider).vouchersDao.getExpensesByItemType(
        from: startDate,
        to: endDate,
        treasuryId: treasuryId,
        projectName: projectName,
      );
}

/// أرصدة كل الخزائن — تفاعلي، يُستعمَل في تقرير العجز
@riverpod
Stream<List<TreasuryBalanceRow>> allTreasuryBalances(Ref ref) {
  return ref.watch(appDatabaseProvider).treasuriesDao.watchTreasuryBalances();
}

/// من تدين لهم الشركة مقابل تغطيتهم عجز سلف معتمدة
@riverpod
Future<List<DeficitCreditorRow>> deficitCreditors(Ref ref) {
  return ref.watch(appDatabaseProvider).advancesDao.getDeficitCreditors();
}

// ── قيم الفلترة المتاحة ─────────────────────────────────────────────────────

/// أنواع البنود المستعملة فعلاً — لقائمة الفلترة في شاشة السندات
///
/// تعرض المستعمَل فقط لا كل البنود المتاحة، فكل خيار مضمون أن يُظهر نتيجة.
@riverpod
Stream<List<String>> usedItemTypes(Ref ref) {
  return ref.watch(appDatabaseProvider).vouchersDao.watchUsedItemTypes();
}

/// أسماء المشاريع المستعملة فعلاً — لقائمة الفلترة في شاشة السندات
@riverpod
Stream<List<String>> usedProjects(Ref ref) {
  return ref.watch(appDatabaseProvider).vouchersDao.watchUsedProjects();
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
    // حقول تتبّع المصروفات — كانت تُسقَط هنا فتفتح شاشة التعديل فارغة
    // ثم يحفظ المستخدم فيمحوها دون أن يشعر (ب-١ — 2026-08-23)
    projectName: v.projectName,
    invoiceNumber: v.invoiceNumber,
    spentBy: v.spentBy,
    advanceNumber: v.advanceNumber,
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

  String get _username {
    final s = ref.read(authNotifierProvider);
    return s is AuthAuthenticated ? s.user.username : 'system';
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
    // ── تتبّع المصروفات (ب-١) ────────────────────────────────────────
    String? projectName,
    String? invoiceNumber,
    String? spentBy,
    String? advanceNumber,
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
      // فحص كفاية رصيد الخزينة (حسب سياسة المنع في الإعدادات)
      final balanceError = await BalanceGuard.checkSufficientBalance(
        _db,
        treasuryId: treasuryId,
        currency: currency,
        amount: amount,
      );
      if (balanceError != null) {
        state = AsyncError(balanceError, StackTrace.empty);
        return false;
      }

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
      final voucherId = await _repo.createVoucher(
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
        projectName: projectName,
        invoiceNumber: invoiceNumber,
        spentBy: spentBy,
        advanceNumber: advanceNumber,
      );
      // توثيق إنشاء السند في سجل التدقيق
      await ref.read(auditLoggerProvider).logVoucherCreated(
            userId: _userId ?? 0,
            username: _username,
            voucherId: voucherId,
            voucherType: 'sarf',
            amount: amount,
            currency: currency,
            treasuryId: treasuryId,
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
    String? projectName,
    String? invoiceNumber,
    String? spentBy,
    String? advanceNumber,
  }) async {
    if (amount <= 0) {
      state = const AsyncError(
        'المبلغ يجب أن يكون أكبر من صفر',
        StackTrace.empty,
      );
      return false;
    }
    // ── فحص أثر التعديل على الرصيد (إصلاح ح-٢) ──────────────────────
    // الإنشاء كان محروساً والتعديل لا — فكان يمكن تعديل سند صرف من
    // 100 ألف إلى 100 مليون والالتفاف على المنع بالكامل.
    final original = await _db.vouchersDao.getVoucherById(voucher.id);
    if (original != null) {
      final balanceError = await BalanceGuard.checkEditImpact(
        _db,
        original: original,
        newTreasuryId: treasuryId,
        newCurrency: currency,
        newAmount: amount,
      );
      if (balanceError != null) {
        state = AsyncError(balanceError, StackTrace.empty);
        return false;
      }
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
          projectName: projectName,
          invoiceNumber: invoiceNumber,
          spentBy: spentBy,
          advanceNumber: advanceNumber,
        ),
        updatedByUserId: _userId,
      );
      // توثيق التعديل بالقيم قبل وبعد (إصلاح ث-٢) — يُنفَّذ بعد نجاح
      // التحديث لا قبله، كي لا يوثَّق تعديلٌ رفضه أحد الحُرّاس.
      if (original != null) {
        await ref.read(auditLoggerProvider).logVoucherUpdated(
              userId: _userId ?? 0,
              username: _username,
              voucherId: voucher.id,
              voucherType: original.voucherType,
              oldAmount: original.amount,
              newAmount: amount,
              oldCurrency: original.currency,
              newCurrency: currency,
              oldTreasuryId: original.treasuryId,
              newTreasuryId: treasuryId,
              oldDate: original.voucherDate,
              newDate: voucherDate,
            );
      }
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
      // قراءة السند قبل حذفه لتوثيق مبلغه في سجل التدقيق
      final voucher = await _db.vouchersDao.getVoucherById(id);
      await _repo.deleteVoucher(id, deletedByUserId: _userId);
      if (voucher != null) {
        await ref.read(auditLoggerProvider).logVoucherDeleted(
              userId: _userId ?? 0,
              username: _username,
              voucherId: id,
              amount: voucher.amount,
              currency: voucher.currency,
            );
      }
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

  String get _username {
    final s = ref.read(authNotifierProvider);
    return s is AuthAuthenticated ? s.user.username : 'system';
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
    // ── رقم الفاتورة (ب-١) ──────────────────────────────────────────
    // مفهوم مختلف عن «الرقم المرجعي»: هذا رقم فاتورة الشركة الصادرة،
    // وذاك رقم الشيك أو أمر الدفع. كلاهما قد يوجد في السند نفسه.
    String? invoiceNumber,
    String? projectName,
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
      final voucherId = await _repo.createVoucher(
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
        invoiceNumber: invoiceNumber,
        projectName: projectName,
      );
      // توثيق إنشاء السند في سجل التدقيق
      await ref.read(auditLoggerProvider).logVoucherCreated(
            userId: _userId ?? 0,
            username: _username,
            voucherId: voucherId,
            voucherType: 'kabd',
            amount: amount,
            currency: currency,
            treasuryId: treasuryId,
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
    String? invoiceNumber,
    String? projectName,
  }) async {
    if (amount <= 0) {
      state = const AsyncError(
        'المبلغ يجب أن يكون أكبر من صفر',
        StackTrace.empty,
      );
      return false;
    }
    // ── فحص أثر التعديل على الرصيد (إصلاح ح-٢) ──────────────────────
    // الإنشاء كان محروساً والتعديل لا — فكان يمكن تعديل سند صرف من
    // 100 ألف إلى 100 مليون والالتفاف على المنع بالكامل.
    final original = await _db.vouchersDao.getVoucherById(voucher.id);
    if (original != null) {
      final balanceError = await BalanceGuard.checkEditImpact(
        _db,
        original: original,
        newTreasuryId: treasuryId,
        newCurrency: currency,
        newAmount: amount,
      );
      if (balanceError != null) {
        state = AsyncError(balanceError, StackTrace.empty);
        return false;
      }
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
          invoiceNumber: invoiceNumber,
          projectName: projectName,
        ),
        updatedByUserId: _userId,
      );
      // توثيق التعديل بالقيم قبل وبعد (إصلاح ث-٢) — راجع التعليق في updateSarf
      if (original != null) {
        await ref.read(auditLoggerProvider).logVoucherUpdated(
              userId: _userId ?? 0,
              username: _username,
              voucherId: voucher.id,
              voucherType: original.voucherType,
              oldAmount: original.amount,
              newAmount: amount,
              oldCurrency: original.currency,
              newCurrency: currency,
              oldTreasuryId: original.treasuryId,
              newTreasuryId: treasuryId,
              oldDate: original.voucherDate,
              newDate: voucherDate,
            );
      }
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
      // قراءة السند قبل حذفه لتوثيق مبلغه في سجل التدقيق
      final voucher = await _db.vouchersDao.getVoucherById(id);
      await _repo.deleteVoucher(id, deletedByUserId: _userId);
      if (voucher != null) {
        await ref.read(auditLoggerProvider).logVoucherDeleted(
              userId: _userId ?? 0,
              username: _username,
              voucherId: id,
              amount: voucher.amount,
              currency: voucher.currency,
            );
      }
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

// ملاحظة (2026-08-07): حُذف من هنا `AdvanceDeleteNotifier` القديم الذي كان
// يحذف السندات بمطابقة نصية على `advance_number`. حلّ محلّه
// `AdvanceNotifier.cancelAdvance` في advance_providers.dart، وهو يعمل على
// كيان السلفة بمفتاح خارجي، ويحفظ سندات التحويل (فالمال انتقل فعلاً)، ويكتب
// في سجل التدقيق. الطريقة القديمة كانت تحذف التمويل مع المصاريف.

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

  String get _username {
    final s = ref.read(authNotifierProvider);
    return s is AuthAuthenticated ? s.user.username : 'system';
  }

  Future<bool> createTransfer({
    required int fromTreasuryId,
    required int toTreasuryId,
    required double amount,
    required String currency,
    required DateTime voucherDate,
    String reason = '',
    double exchangeRate = 1.0,
    /// السلفة التي يموّلها هذا التحويل — null = تحويل عادي غير مرتبط بسلفة
    int? advanceId,
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
      // فحص كفاية رصيد الخزينة المصدر (حسب سياسة المنع في الإعدادات)
      final balanceError = await BalanceGuard.checkSufficientBalance(
        _db,
        treasuryId: fromTreasuryId,
        currency: currency,
        amount: amount,
      );
      if (balanceError != null) {
        state = AsyncError(balanceError, StackTrace.empty);
        return false;
      }

      final period =
          await _db.fiscalPeriodsDao.getFiscalPeriodForDate(voucherDate);
      if (period == null) {
        state = const AsyncError(
          'لا توجد فترة مالية نشطة لهذا التاريخ',
          StackTrace.empty,
        );
        return false;
      }

      final ids = await _repo.createTransfer(
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

      // ربط طرفَي التحويل بالسلفة (إن حُدِّدت) — بهذا يُحتسَب «المُرسَل» في
      // تقرير السلفة. نربط الطرفين معاً لا الوارد وحده، ليبقى أثر التمويل
      // ظاهراً على الخزينتين، وحساب المُرسَل يفلتر على خزينة المشروع.
      if (advanceId != null) {
        await ref.read(advanceRepositoryProvider).linkTransferVouchers(
              advanceId: advanceId,
              voucherIds: [ids.outId, ids.inId],
            );
        ref.invalidate(advanceSummaryProvider(advanceId));
        ref.invalidate(advanceByIdProvider(advanceId));
        ref.invalidate(advancesByStatusProvider);
      }

      // توثيق التحويل في سجل التدقيق (يشمل معرّفي طرفَي التحويل)
      await ref.read(auditLoggerProvider).logVoucherCreated(
            userId: _userId ?? 0,
            username: _username,
            voucherId: ids.outId,
            voucherType: 'transfer',
            amount: amount,
            currency: currency,
            treasuryId: fromTreasuryId,
          );

      state = AsyncData(
        advanceId != null
            ? 'تم التحويل وربطه بالسلفة ✓'
            : 'تم التحويل بين الخزائن بنجاح ✓',
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  void reset() => state = const AsyncData(null);
}

