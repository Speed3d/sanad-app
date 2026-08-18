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
//        recomputeOpeningBalances()  — تنظيف الأرصدة الافتتاحية وإقفال الفترة
//
// منطق Cascade Recompute:
//   عند إعادة فتح فترة مُقفَلة:
//     1. الفترة المُعاد فتحها → active
//     2. جميع الفترات اللاحقة المُقفَلة → frozen_pending_recompute
//   عند إعادة الاحتساب:
//     1. حذف أي سندات رصيد افتتاحي قائمة (النوعين معاً)
//     2. إقفال الفترة مجدداً (frozen)
//
// 📌 مبدأ الرصيد التراكمي (قرار المالك 2026-08-15):
//   الخزينة صندوق نقدي مستمر لا يُصفَّر في 31 ديسمبر. المال الذي فيها آخر
//   ديسمبر هو نفسه أول يناير، فلا حاجة لسند «رصيد افتتاحي» يُعيد إدخاله —
//   بل كان يُضاعف الرصيد لأن v_treasury_balances تراكمي ولا يفلتر بالفترة.
//   لذلك أُوقف إنشاء سندات opening_balance / opening_balance_debit نهائياً.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/audit_logger.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/auth_state.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

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
  /// تنظيف الأرصدة الافتتاحية وإقفال فترة تحتاج مراجعة
  ///
  /// 🔄 أُعيدت كتابة هذه الدالة (2026-08-15) بعد قرار المالك اعتماد
  ///    **الرصيد التراكمي المستمر**. كانت تُنشئ سندات رصيد افتتاحي، وفي
  ///    ذلك ثغرتان مؤكَّدتان:
  ///
  ///    **ح-٣** — الحذف كان يشمل `opening_balance` فقط بينما الإدراج يُنتج
  ///      نوعين (`opening_balance` و`opening_balance_debit` منذ Schema v4).
  ///      فإعادة الاحتساب مرتين تُبقي سند الدَّين القديم وتضيف فوقه ←
  ///      الدَّين محسوب مرتين.
  ///
  ///    **ح-٤** — `v_treasury_balances` لا يفلتر بالفترة المالية إطلاقاً؛
  ///      يجمع كل سندات الخزينة منذ البداية. فسند الرصيد الافتتاحي يمثّل
  ///      **مالاً محسوباً أصلاً** في سندات السنة السابقة، فيُضاف مرة ثانية
  ///      ويتضاعف الرصيد.
  ///
  /// **المبدأ المعتمد:** الخزينة صندوق نقدي مستمر لا يُصفَّر في 31 ديسمبر.
  /// المال الذي فيها آخر ديسمبر هو نفسه الموجود أول يناير — ولا حاجة لسند
  /// يُعيد إدخاله. الرصيد ينتقل طبيعياً لأن الـ VIEW تراكمي أصلاً.
  ///
  /// ما تفعله الدالة الآن:
  ///   1. حذف أي سندات رصيد افتتاحي قائمة (**النوعين معاً** — إصلاح ح-٣)
  ///   2. إقفال الفترة
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

      final pendingPeriod =
          await db.fiscalPeriodsDao.getPeriodById(pendingPeriodId);
      if (pendingPeriod == null) {
        throw Exception('لم يُعثَر على الفترة المطلوبة');
      }

      // ── حذف أي سندات رصيد افتتاحي قائمة ─────────────────────────────
      // النوعان معاً. الحذف فعلي لا ناعم: هذه السندات لا تمثّل حركة مال
      // حقيقية، بل كانت تكراراً محاسبياً لمال محسوب أصلاً.
      final removed = await db.customUpdate(
        "DELETE FROM vouchers "
        "WHERE voucher_type IN ('opening_balance', 'opening_balance_debit') "
        "AND fiscal_period_id = ?",
        variables: [Variable.withInt(pendingPeriodId)],
        updates: {db.vouchers},
      );

      // ── إقفال الفترة ────────────────────────────────────────────────
      await db.fiscalPeriodsDao.closePeriod(
        pendingPeriodId,
        userId,
        notes: 'إقفال بالرصيد التراكمي — لا سندات افتتاحية',
      );

      state = AsyncData(
        removed > 0
            ? 'تم الإقفال ✓ — حُذف $removed سند رصيد افتتاحي مكرر، '
                'والرصيد ينتقل تراكمياً كما هو.'
            : 'تم إقفال الفترة ✓ — الرصيد ينتقل تراكمياً للسنة التالية.',
      );
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
