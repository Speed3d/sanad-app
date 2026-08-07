// ─────────────────────────────────────────────────────────────────────────────
// fiscal_providers.dart — Providers إدارة الفترات المالية
//
// يوفر:
//   1. allPeriodsProvider          — Stream تفاعلي بجميع الفترات المالية
//   2. periodVoucherCountProvider  — عدد السندات لفترة محددة (family)
//   3. FiscalNotifier              — Notifier لجميع عمليات الفترات:
//        createPeriod()              — إنشاء فترة جديدة
//        closePeriod()               — إقفال فترة (frozen)
//        reopenPeriod()              — إعادة فتح فترة + تحديد اللاحقة للاحتساب
//        recomputeOpeningBalances()  — إعادة احتساب الأرصدة الافتتاحية
//
// منطق Cascade Recompute:
//   عند إعادة فتح فترة مُقفَلة:
//     1. الفترة المُعاد فتحها → active
//     2. جميع الفترات اللاحقة المُقفَلة → frozen_pending_recompute
//   عند إعادة الاحتساب:
//     1. احتساب الرصيد الختامي لكل خزينة من الفترة السابقة
//     2. حذف سندات opening_balance القديمة
//     3. إدراج سندات opening_balance محدَّثة
//     4. إقفال الفترة مجدداً (frozen)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/audit_logger.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/auth_state.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'settings_provider.dart';

part 'fiscal_providers.g.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Provider: جميع الفترات المالية (Reactive Stream)
// ═══════════════════════════════════════════════════════════════════════════

/// Stream تفاعلي بجميع الفترات المالية مرتبةً من الأحدث للأقدم
///
/// يتحدث تلقائياً عند أي تغيير في جدول fiscal_periods
@riverpod
Stream<List<FiscalPeriod>> allPeriods(Ref ref) {
  return ref.watch(appDatabaseProvider).fiscalPeriodsDao.watchAllPeriods();
}

// ═══════════════════════════════════════════════════════════════════════════
// Provider: عدد سندات فترة محددة
// ═══════════════════════════════════════════════════════════════════════════

/// عدد السندات النشطة (غير المحذوفة) لفترة مالية محددة
///
/// يُستخدَم في بطاقة الفترة لعرض الإحصائيات
@riverpod
Future<int> periodVoucherCount(Ref ref, int periodId) async {
  final db = ref.watch(appDatabaseProvider);
  final result = await db
      .customSelect(
        'SELECT COUNT(*) AS cnt FROM vouchers '
        'WHERE fiscal_period_id = ? AND is_deleted = 0',
        variables: [Variable.withInt(periodId)],
        readsFrom: {db.vouchers},
      )
      .getSingle();
  return result.data['cnt'] as int? ?? 0;
}

// ═══════════════════════════════════════════════════════════════════════════
// FiscalNotifier — إدارة عمليات الفترات المالية
// ═══════════════════════════════════════════════════════════════════════════

/// حالة عملية الفترة المالية
///
/// AsyncData(null)     — لا عملية جارية
/// AsyncData('رسالة') — نجاح (مع رسالة للعرض)
/// AsyncLoading()      — عملية جارية
/// AsyncError(...)     — خطأ
@riverpod
class FiscalNotifier extends _$FiscalNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  // ── مساعدات خاصة ───────────────────────────────────────────────────────

  AppDatabase get _db => ref.read(appDatabaseProvider);

  /// معرّف المستخدم الحالي — null إذا لم يكن مسجَّلاً
  int? get _currentUserId {
    final authState = ref.read(authNotifierProvider);
    return authState is AuthAuthenticated ? authState.user.id : null;
  }

  /// اسم المستخدم الحالي — 'system' إذا لم يكن مسجَّلاً
  String get _currentUsername {
    final authState = ref.read(authNotifierProvider);
    return authState is AuthAuthenticated ? authState.user.username : 'system';
  }

  // ══════════════════════════════════════════════════════════════════════
  // إنشاء فترة مالية جديدة
  // ══════════════════════════════════════════════════════════════════════

  /// إنشاء فترة مالية جديدة
  ///
  /// [name]       — اسم الفترة (مثل: '2025' أو '2025-Q1')
  /// [periodType] — نوع الفترة: 'yearly' | 'quarterly' | 'monthly'
  /// [startDate]  — تاريخ البداية
  /// [endDate]    — تاريخ النهاية
  /// [notes]      — ملاحظات اختيارية
  ///
  /// يُعيد: true عند النجاح، false عند الفشل
  Future<bool> createPeriod({
    required String name,
    required String periodType,
    required DateTime startDate,
    required DateTime endDate,
    String notes = '',
  }) async {
    state = const AsyncLoading();
    try {
      // التحقق من عدم التداخل مع فترات موجودة
      final existing = await _db.fiscalPeriodsDao.watchAllPeriods().first;
      final hasOverlap = existing.any(
        (p) =>
            startDate.isBefore(p.endDate.add(const Duration(days: 1))) &&
            endDate.isAfter(p.startDate.subtract(const Duration(days: 1))),
      );

      if (hasOverlap) {
        state = const AsyncError(
          'يتداخل نطاق التواريخ مع فترة مالية موجودة',
          StackTrace.empty,
        );
        return false;
      }

      await _db.fiscalPeriodsDao.insertPeriod(
        FiscalPeriodsCompanion.insert(
          name: name,
          startDate: startDate,
          endDate: endDate,
          status: const Value('active'),
          notes: Value(notes),
          periodType: Value(periodType),
        ),
      );

      state = const AsyncData('تم إنشاء الفترة المالية بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // إقفال فترة مالية
  // ══════════════════════════════════════════════════════════════════════

  /// إقفال فترة مالية (تحويلها إلى frozen)
  ///
  /// [periodId] — معرّف الفترة
  /// [notes]    — ملاحظات الإقفال (اختياري)
  ///
  /// يُعيد: true عند النجاح
  Future<bool> closePeriod(int periodId, {String notes = ''}) async {
    final userId = _currentUserId;
    if (userId == null) {
      state = const AsyncError('يجب تسجيل الدخول أولاً', StackTrace.empty);
      return false;
    }

    state = const AsyncLoading();
    try {
      await _db.fiscalPeriodsDao.closePeriod(periodId, userId, notes: notes);
      // توثيق إقفال الفترة في سجل التدقيق (عملية مالية حساسة)
      final period = await _db.fiscalPeriodsDao.getPeriodById(periodId);
      await ref.read(auditLoggerProvider).logFiscalClose(
            userId: userId,
            username: _currentUsername,
            fiscalPeriodId: periodId,
            periodName: period?.name ?? '#$periodId',
          );
      state = const AsyncData('تم إقفال الفترة المالية بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // إعادة فتح فترة مُقفَلة (Super Admin فقط)
  // ══════════════════════════════════════════════════════════════════════

  /// إعادة فتح فترة مُقفَلة وتحديد الفترات اللاحقة للاحتساب
  ///
  /// [periodId] — معرّف الفترة المُراد إعادة فتحها
  ///
  /// يُعيد: true عند النجاح
  ///
  /// الأثر الجانبي:
  ///   جميع الفترات المُقفَلة التي تبدأ بعد نهاية هذه الفترة
  ///   تُحدَّد بـ frozen_pending_recompute
  Future<bool> reopenPeriod(int periodId) async {
    state = const AsyncLoading();
    try {
      final db = _db;

      // 1. إعادة تفعيل الفترة
      await db.fiscalPeriodsDao.reopenPeriod(periodId);

      // 2. الحصول على الفترة المُعاد فتحها
      final reopenedPeriod = await db.fiscalPeriodsDao.getPeriodById(periodId);
      if (reopenedPeriod == null) throw Exception('لم يُعثَر على الفترة');

      // 3. تحديد الفترات اللاحقة المُقفَلة وتحديد حالتها
      final allPeriods = await db.fiscalPeriodsDao.watchAllPeriods().first;
      final subsequentFrozen = allPeriods.where(
        (p) =>
            p.startDate.isAfter(reopenedPeriod.endDate) &&
            p.status == 'frozen',
      );

      for (final period in subsequentFrozen) {
        await db.fiscalPeriodsDao.markPeriodPendingRecompute(period.id);
      }

      final affectedCount = subsequentFrozen.length;

      // توثيق إعادة الفتح في سجل التدقيق (عملية مالية حساسة جداً)
      await ref.read(auditLoggerProvider).logFiscalReopen(
            userId: _currentUserId ?? 0,
            username: _currentUsername,
            fiscalPeriodId: periodId,
            periodName: reopenedPeriod.name,
          );

      final msg = affectedCount > 0
          ? 'تم إعادة فتح الفترة — $affectedCount فترة تحتاج إعادة احتساب ✓'
          : 'تم إعادة فتح الفترة المالية بنجاح ✓';

      state = AsyncData(msg);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // إعادة احتساب الأرصدة الافتتاحية (Cascade Recompute)
  // ══════════════════════════════════════════════════════════════════════

  /// إعادة احتساب الأرصدة الافتتاحية لفترة تحتاج مراجعة
  ///
  /// الخوارزمية:
  ///   1. إيجاد الفترة السابقة مباشرةً
  ///   2. احتساب الرصيد الختامي لكل خزينة من الفترة السابقة
  ///   3. حذف سندات opening_balance القديمة من هذه الفترة
  ///   4. إدراج سندات opening_balance محدَّثة لكل خزينة لها رصيد
  ///   5. إقفال الفترة (frozen) — انتهاء إعادة الاحتساب
  ///
  /// [pendingPeriodId] — معرّف الفترة التي تحتاج إعادة احتساب
  ///
  /// يُعيد: true عند النجاح
  Future<bool> recomputeOpeningBalances(int pendingPeriodId) async {
    final userId = _currentUserId;
    if (userId == null) {
      state = const AsyncError('يجب تسجيل الدخول أولاً', StackTrace.empty);
      return false;
    }

    state = const AsyncLoading();
    try {
      final db = _db;

      // ── 1. جلب الفترة التي تحتاج إعادة احتساب ───────────────────────
      final pendingPeriod =
          await db.fiscalPeriodsDao.getPeriodById(pendingPeriodId);
      if (pendingPeriod == null) {
        throw Exception('لم يُعثَر على الفترة المطلوبة');
      }

      // ── 2. إيجاد الفترة السابقة (التي ينتقل رصيدها الختامي) ─────────
      final allPeriods = await db.fiscalPeriodsDao.watchAllPeriods().first;
      final sortedPrev = allPeriods
          .where(
            (p) =>
                p.id != pendingPeriodId &&
                !p.startDate.isAfter(pendingPeriod.startDate),
          )
          .toList()
        ..sort((a, b) => b.endDate.compareTo(a.endDate));

      final previousPeriod = sortedPrev.isEmpty ? null : sortedPrev.first;

      // ── 3. حذف سندات الافتتاح القديمة ────────────────────────────────
      await db.customStatement(
        "DELETE FROM vouchers "
        "WHERE voucher_type = 'opening_balance' AND fiscal_period_id = ?",
        [pendingPeriodId],
      );

      if (previousPeriod == null) {
        // لا توجد فترة سابقة — أقفل الفترة بدون سندات افتتاح
        await db.fiscalPeriodsDao.closePeriod(
          pendingPeriodId,
          userId,
          notes: 'إعادة احتساب: لا فترة سابقة — لا أرصدة افتتاحية',
        );
        state = const AsyncData(
          'تم الاحتساب: لا فترة سابقة، مسح الأرصدة الافتتاحية ✓',
        );
        return true;
      }

      // ── 4. جلب سندات الفترة السابقة ────────────────────────────────
      final prevVouchers = await db.vouchersDao.getVouchersByDateRange(
        from: previousPeriod.startDate,
        to: previousPeriod.endDate,
        fiscalPeriodId: previousPeriod.id,
      );

      // ── 5. احتساب الرصيد الختامي لكل خزينة ────────────────────────
      // معادلة الرصيد: Σ(kabd + opening_balance + transfer_in) - Σ(sarf + transfer_out)
      final Map<int, double> closingIqd = {};
      final Map<int, double> closingUsd = {};

      for (final v in prevVouchers) {
        // السندات المحذوفة لا تؤثر في الرصيد
        if (v.isDeleted) continue;

        final double delta;
        switch (v.voucherType) {
          case 'kabd':
          case 'opening_balance':
          case 'transfer_in':
            delta = v.amount; // دائن +
          case 'sarf':
          case 'transfer_out':
          case 'opening_balance_debit':
            delta = -v.amount; // مدين - (يشمل الرصيد الافتتاحي المدين)
          default:
            continue; // نوع غير معروف — تجاهل
        }

        if (v.currency == 'IQD') {
          closingIqd[v.treasuryId] =
              (closingIqd[v.treasuryId] ?? 0.0) + delta;
        } else if (v.currency == 'USD') {
          closingUsd[v.treasuryId] =
              (closingUsd[v.treasuryId] ?? 0.0) + delta;
        }
      }

      // ── 6. إدراج سندات الافتتاح الجديدة ────────────────────────────
      final allTreasuryIds = {
        ...closingIqd.keys,
        ...closingUsd.keys,
      };

      // الحصول على سعر الصرف الحالي للأرشفة التاريخية
      final exchangeRate =
          ref.read(exchangeRateProvider).valueOrNull ?? 1310.0;

      // نحتسب عدد سندات الافتتاح الحالية لتحديد البداية
      int localCounter = 0;

      await db.transaction(() async {
        // دالة مساعدة تُدرج سند افتتاح بالنوع الصحيح حسب إشارة الرصيد
        //   الرصيد الموجب → opening_balance (دائن)
        //   الرصيد السالب → opening_balance_debit (مدين، مبلغ موجب) ← إصلاح H9
        // بهذا لا يختفي دَين الخزينة المدينة عند بداية السنة الجديدة.
        Future<void> insertOpening({
          required int treasuryId,
          required double balance,
          required String currency,
        }) async {
          if (balance.abs() <= 0.001) return; // رصيد صفري — لا سند
          localCounter++;
          final isDebit = balance < 0;
          await db.vouchersDao.insertVoucher(
            VouchersCompanion.insert(
              voucherNumber: localCounter,
              voucherType:
                  isDebit ? 'opening_balance_debit' : 'opening_balance',
              treasuryId: treasuryId,
              fiscalPeriodId: pendingPeriodId,
              amount: balance.abs(), // دائماً موجب (قيد CHECK)
              currency: Value(currency),
              exchangeRate:
                  currency == 'USD' ? Value(exchangeRate) : const Value(1.0),
              voucherDate: pendingPeriod.startDate,
              notes: Value(
                '${isDebit ? 'رصيد افتتاحي مدين' : 'رصيد افتتاحي'} '
                'منقول من فترة: ${previousPeriod.name}',
              ),
              createdByUserId: Value(userId),
            ),
          );
        }

        for (final treasuryId in allTreasuryIds) {
          await insertOpening(
            treasuryId: treasuryId,
            balance: closingIqd[treasuryId] ?? 0.0,
            currency: 'IQD',
          );
          await insertOpening(
            treasuryId: treasuryId,
            balance: closingUsd[treasuryId] ?? 0.0,
            currency: 'USD',
          );
        }
      });

      // ── 7. إقفال الفترة — انتهاء إعادة الاحتساب ────────────────────
      await db.fiscalPeriodsDao.closePeriod(
        pendingPeriodId,
        userId,
        notes: 'إعادة احتساب تلقائي من فترة: ${previousPeriod.name}',
      );

      final skippedNegative = allTreasuryIds
          .where(
            (id) =>
                (closingIqd[id] ?? 0) < -0.001 ||
                (closingUsd[id] ?? 0) < -0.001,
          )
          .length;

      final msg = skippedNegative > 0
          ? 'تم إعادة الاحتساب ✓\nتحذير: $skippedNegative خزينة برصيد سالب — تحتاج مراجعة يدوية'
          : 'تم إعادة الاحتساب بنجاح ✓ ($localCounter سند افتتاحي)';

      state = AsyncData(msg);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // مساعدات الحالة
  // ══════════════════════════════════════════════════════════════════════

  /// إعادة الحالة لـ idle (بعد عرض رسالة النجاح أو الخطأ)
  void reset() => state = const AsyncData(null);
}
