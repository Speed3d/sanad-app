// ─────────────────────────────────────────────────────────────────────────────
// advance_providers.dart — مزوّدات سلف المشاريع
//
// ⚠️ سلف المشاريع (Advances) ≠ سلف الموظفين (CashAdvances) — الثانية في
//    employee_providers.dart
//
// المزوّدات هنا تغطي دورة السلفة كاملة:
//   قراءة: القوائم، الأسطر، الملخص، أنواع البنود
//   كتابة: AdvanceNotifier — إنشاء، استيراد مسودة، تحرير، اعتماد، إلغاء
//
// فحص الصلاحيات يقع **هنا** لا في المستودع: المستودع لا يعرف من المستخدم
// الحالي، والـ Notifier هو أول موضع تجتمع فيه الهوية مع العملية.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/auth/permissions.dart';
import '../../core/utils/audit_logger.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/advances_dao.dart'
    show PayrollLinkPreview;
import '../../domain/models/advance_model.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/i_advance_repository.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'repository_providers.dart';
import 'treasury_providers.dart';

part 'advance_providers.g.dart';

// ═══════════════════════════════════════════════════════════════════════════
// مزوّدات القراءة
// ═══════════════════════════════════════════════════════════════════════════

/// السلف حسب الحالة — Reactive Stream
///
/// [status] — 'open' | 'draft' | 'posted' | 'cancelled' | null للكل
@riverpod
Stream<List<AdvanceModel>> advancesByStatus(Ref ref, String? status) {
  return ref.watch(advanceRepositoryProvider).watchAdvances(status: status);
}

/// سلفة واحدة — Reactive Stream
@riverpod
Stream<AdvanceModel?> advanceById(Ref ref, int advanceId) {
  return ref.watch(advanceRepositoryProvider).watchAdvance(advanceId);
}

/// أسطر مسودة سلفة — Reactive Stream
@riverpod
Stream<List<AdvanceLineModel>> advanceLines(Ref ref, int advanceId) {
  return ref.watch(advanceRepositoryProvider).watchLines(advanceId);
}

/// السلف التي فيها بندٌ يطابق [query] — مفتاحها `advance_id`
///
/// يخدم أمرين معاً في تقرير السلف (الدفعة ج — بلاغ المالك 2026-08-30):
///   ١. **الفلترة**: «وقود» تُبقي السلف التي صُرف فيها وقود
///   ٢. **الشارة**: «وقود: ٣ مصاريف · ١٬٢٠٠٬٠٠٠ د.ع» على كل بطاقة
///
/// ⚠️ استعلامٌ واحد للأمرين لا اثنان: رقمان يُقرآن من مصدرين قد يفترقان،
///   وقائمةٌ تقول «مطابِقة» وشارةٌ تقول «صفر» تُفقد الثقة بالبحث كلّه.
@riverpod
Future<Map<int, ({int count, double total})>> advancesByItemType(
  Ref ref,
  String query,
) {
  if (query.trim().isEmpty) {
    return Future.value(const <int, ({int count, double total})>{});
  }
  return ref.watch(advanceRepositoryProvider).searchByItemType(query);
}

/// ملخص السلفة: المُرسَل / المصروف / المتبقي أو العجز
///
/// يُعاد حسابه تلقائياً عند تغيّر الأسطر أو الأرصدة، لأنه يراقب
/// [advanceLinesProvider] و[treasuryBalancesProvider].
@riverpod
Future<AdvanceSummary> advanceSummary(Ref ref, int advanceId) async {
  // مراقبة مصادر التغيير حتى يتحدّث شريط المطابقة فوراً مع كل تعديل
  ref.watch(advanceLinesProvider(advanceId));
  ref.watch(treasuryBalancesProvider);
  return ref.watch(advanceRepositoryProvider).getSummary(advanceId);
}

/// السلف المفتوحة والمسودات لخزينة مشروع (لاختيارها عند الاستيراد)
@riverpod
Future<List<AdvanceModel>> activeAdvancesForTreasury(
  Ref ref,
  int treasuryId,
) {
  return ref
      .watch(advanceRepositoryProvider)
      .getActiveAdvancesForTreasury(treasuryId);
}

/// مجموع مصاريف المسودات المعلّقة لكل خزينة — للتحذير المبكر
///
/// المفتاح = معرّف الخزينة، القيمة = مجموع المصاريف التي وصلت وتنتظر الاعتماد.
@riverpod
Stream<Map<int, double>> pendingDraftTotals(Ref ref) {
  return ref.watch(appDatabaseProvider).advancesDao.watchPendingDraftTotals();
}

/// أنواع البنود النشطة — Reactive Stream
///
/// [kind] — 'sarf' | 'kabd' | null. البنود المُعلَّمة 'both' تظهر دائماً.
@riverpod
Stream<List<ItemType>> itemTypes(Ref ref, String? kind) {
  return ref.watch(appDatabaseProvider).advancesDao.watchItemTypes(kind: kind);
}

/// أسماء أنواع البنود فقط — للقوائم المنسدلة في شاشات السندات والمسودة
///
/// نشتق من الـ DAO مباشرة لا من [itemTypesProvider]`.stream` (مهجور في
/// Riverpod 3)، وتكلفة الاستعلام مهملة لأن الجدول صغير ومُفهرَس.
@riverpod
Stream<List<String>> itemTypeNames(Ref ref, String? kind) {
  return ref
      .watch(appDatabaseProvider)
      .advancesDao
      .watchItemTypes(kind: kind)
      .map((list) => list.map((t) => t.name).toList());
}

// ═══════════════════════════════════════════════════════════════════════════
// AdvanceNotifier — عمليات الكتابة
// ═══════════════════════════════════════════════════════════════════════════

/// مدير عمليات السلف
///
/// الحالة: AsyncData(رسالة نجاح) | AsyncError(رسالة خطأ) | AsyncLoading
/// معاينة مطابقة أسطر الرواتب في سلفة — **تُقرأ قبل الاعتماد**
///
/// تُعاد قراءتها عند أي تغيّر في أسطر المسودة، فيرى المالك أثر تعديله على
/// المطابقة فوراً بدل أن يكتشف الفرق عند الرفض.
@riverpod
Future<List<PayrollLinkPreview>> payrollLinkPreviews(
  Ref ref,
  int advanceId,
) {
  ref.watch(advanceLinesProvider(advanceId));
  return ref.watch(advanceRepositoryProvider).getPayrollLinkPreviews(advanceId);
}

@riverpod
class AdvanceNotifier extends _$AdvanceNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  IAdvanceRepository get _repo => ref.read(advanceRepositoryProvider);
  AppDatabase get _db => ref.read(appDatabaseProvider);

  UserModel? get _user {
    final s = ref.read(authNotifierProvider);
    return s is AuthAuthenticated ? s.user : null;
  }

  /// إبطال كل ما يتأثر باعتماد أو إلغاء سلفة
  void _invalidateAll(int advanceId) {
    ref.invalidate(advanceByIdProvider(advanceId));
    ref.invalidate(advanceLinesProvider(advanceId));
    ref.invalidate(advanceSummaryProvider(advanceId));
    ref.invalidate(advancesByStatusProvider);
    ref.invalidate(treasuryBalancesProvider);
    ref.invalidate(totalTreasuryBalanceProvider);
  }

  void reset() => state = const AsyncData(null);

  // ── إنشاء سلفة ──────────────────────────────────────────────────────────

  /// إنشاء سلفة جديدة بحالة `open` — يُعيد المعرّف أو null عند الفشل
  Future<int?> createAdvance({
    required String advanceNumber,
    required int projectTreasuryId,
    required DateTime advanceDate,
    String projectName = '',
    String notes = '',
  }) async {
    state = const AsyncLoading();
    try {
      final id = await _repo.createAdvance(
        advanceNumber: advanceNumber,
        projectTreasuryId: projectTreasuryId,
        advanceDate: advanceDate,
        projectName: projectName,
        notes: notes,
        createdByUserId: _user?.id,
      );
      ref.invalidate(advancesByStatusProvider);
      ref.invalidate(activeAdvancesForTreasuryProvider);
      state = AsyncData('تم إنشاء السلفة رقم $advanceNumber ✓');
      return id;
    } catch (e, st) {
      state = AsyncError(_msg(e), st);
      return null;
    }
  }

  /// ربط سندات تحويل بسلفة (لاحتساب المبلغ المُرسَل)
  Future<bool> linkTransfers({
    required int advanceId,
    required List<int> voucherIds,
  }) async {
    try {
      await _repo.linkTransferVouchers(
        advanceId: advanceId,
        voucherIds: voucherIds,
      );
      _invalidateAll(advanceId);
      return true;
    } catch (e, st) {
      state = AsyncError(_msg(e), st);
      return false;
    }
  }

  // ── بناء المسودة ────────────────────────────────────────────────────────

  /// إنشاء مسودة من أسطر ملف إكسل — لا يمسّ رصيد أي خزينة
  Future<bool> createDraft({
    required int advanceId,
    required List<ParsedAdvanceLine> lines,
    required String fileName,
    required String fileHash,
    bool replaceExisting = false,
  }) async {
    final user = _user;
    if (user == null || !user.can(AppPermission.prepareAdvance)) {
      state = const AsyncError(
        'ليست لديك صلاحية تجهيز مسودات سلف المشاريع.',
        StackTrace.empty,
      );
      return false;
    }

    state = const AsyncLoading();
    try {
      await _repo.createDraftFromExcel(
        advanceId: advanceId,
        lines: lines,
        fileName: fileName,
        fileHash: fileHash,
        replaceExisting: replaceExisting,
      );
      _invalidateAll(advanceId);
      state = AsyncData(
        'تم تجهيز مسودة بـ ${lines.length} سطر — راجعها ثم اعتمدها.',
      );
      return true;
    } catch (e, st) {
      state = AsyncError(_msg(e), st);
      return false;
    }
  }

  // ── تحرير المسودة ───────────────────────────────────────────────────────

  /// تعديل سطر في المسودة
  Future<bool> updateLine({
    required int advanceId,
    required int lineId,
    DateTime? date,
    double? amount,
    String? itemType,
    String? reason,
    String? personName,
    String? projectName,
    String? invoiceNumber,
    String? spentBy,
  }) async {
    final user = _user;
    if (user == null || !user.can(AppPermission.prepareAdvance)) {
      state = const AsyncError(
        'ليست لديك صلاحية تعديل مسودات السلف.',
        StackTrace.empty,
      );
      return false;
    }

    try {
      await _repo.updateLine(
        lineId: lineId,
        date: date,
        amount: amount,
        itemType: itemType,
        reason: reason,
        personName: personName,
        projectName: projectName,
        invoiceNumber: invoiceNumber,
        spentBy: spentBy,
      );
      _invalidateAll(advanceId);
      return true;
    } catch (e, st) {
      state = AsyncError(_msg(e), st);
      return false;
    }
  }

  // ── ربط الرواتب (Schema v7) ───────────────────────────────────────────

  /// ربط سطر مسودة بكشف رواتب شهر
  ///
  /// **لا يمسّ مالاً** — السلفة مسودة والكشف مسودة. الرباط يُقرأ عند
  /// الاعتماد حيث يحرس تطابق المبلغين.
  Future<bool> linkLineToPayroll({
    required int advanceId,
    required int lineId,
    required int payrollPeriodId,
  }) async {
    final user = _user;
    if (user == null || !user.can(AppPermission.prepareAdvance)) {
      state = const AsyncError(
        'ليست لديك صلاحية تعديل مسودات السلف.',
        StackTrace.empty,
      );
      return false;
    }
    try {
      final count = await _repo.linkLineToPayroll(
        lineId: lineId,
        payrollPeriodId: payrollPeriodId,
      );
      _invalidateAll(advanceId);
      ref.invalidate(payrollLinkPreviewsProvider(advanceId));
      state = AsyncData('رُبط السطر بـ$count موظفاً من كشف الرواتب ✓');
      return true;
    } on StateError catch (e, st) {
      state = AsyncError(e.message, st);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// فكّ ربط سطر عن كشف الرواتب
  Future<bool> unlinkLineFromPayroll({
    required int advanceId,
    required int lineId,
  }) async {
    final user = _user;
    if (user == null || !user.can(AppPermission.prepareAdvance)) {
      state = const AsyncError(
        'ليست لديك صلاحية تعديل مسودات السلف.',
        StackTrace.empty,
      );
      return false;
    }
    try {
      await _repo.unlinkLineFromPayroll(lineId);
      _invalidateAll(advanceId);
      ref.invalidate(payrollLinkPreviewsProvider(advanceId));
      state = const AsyncData('فُكّ الربط بكشف الرواتب ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// استبعاد سطر من الاعتماد أو إعادته
  Future<bool> setLineExcluded({
    required int advanceId,
    required int lineId,
    required bool excluded,
    String reason = '',
  }) async {
    final user = _user;
    if (user == null || !user.can(AppPermission.prepareAdvance)) {
      state = const AsyncError(
        'ليست لديك صلاحية تعديل مسودات السلف.',
        StackTrace.empty,
      );
      return false;
    }

    try {
      await _repo.setLineExcluded(
        lineId: lineId,
        excluded: excluded,
        reason: reason,
      );
      _invalidateAll(advanceId);
      return true;
    } catch (e, st) {
      state = AsyncError(_msg(e), st);
      return false;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 🔑 الاعتماد
  // ═════════════════════════════════════════════════════════════════════════

  /// اعتماد سلفة — يحوّل المسودة إلى سندات صرف
  ///
  /// فحص الصلاحية هنا على مستويين:
  ///   [AppPermission.postAdvance]            — الاعتماد أصلاً
  ///   [AppPermission.postAdvanceWithDeficit] — الاعتماد بعجز (رصيد سالب)
  ///
  /// يُعيد [PostAdvanceOutcome] كما هي، ليتمكن الحوار في الواجهة من التمييز
  /// بين «رُفض لأنه يحتاج قرارك» و«فشل».
  Future<PostAdvanceOutcome> postAdvance({
    required int advanceId,
    bool allowDeficit = false,
    String? deficitCoveredBy,
  }) async {
    final user = _user;
    if (user == null || !user.can(AppPermission.postAdvance)) {
      const msg = 'اعتماد سلف المشاريع يتطلب صلاحية مدير — راجع مدير النظام.';
      state = const AsyncError(msg, StackTrace.empty);
      return const PostAdvanceOutcome(success: false, message: msg);
    }
    if (allowDeficit && !user.can(AppPermission.postAdvanceWithDeficit)) {
      const msg = 'اعتماد سلفة بعجز (رصيد سالب) يتطلب صلاحية مدير.';
      state = const AsyncError(msg, StackTrace.empty);
      return const PostAdvanceOutcome(success: false, message: msg);
    }

    state = const AsyncLoading();
    try {
      final advance = await _repo.getAdvance(advanceId);
      final outcome = await _repo.postAdvance(
        advanceId: advanceId,
        allowDeficit: allowDeficit,
        deficitCoveredBy: deficitCoveredBy,
        postedByUserId: user.id,
      );

      if (outcome.success && advance != null) {
        final treasury = await _db.treasuriesDao
            .getTreasuryById(advance.projectTreasuryId);
        await ref.read(auditLoggerProvider).logAdvancePosted(
              userId: user.id,
              username: user.username,
              advanceId: advanceId,
              advanceNumber: advance.advanceNumber,
              vouchersCreated: outcome.vouchersCreated,
              totalAmount: 0, // يُقرأ من الملخص أدناه
              treasuryId: advance.projectTreasuryId,
              treasuryName: treasury?.name ?? '',
              deficit: outcome.deficit,
              deficitCoveredBy: deficitCoveredBy,
            );
        _invalidateAll(advanceId);
        state = AsyncData(outcome.message);
      } else if (!outcome.needsDeficitConfirmation) {
        // رفض نهائي (لا قرار ينتظر المستخدم) — يظهر كخطأ
        state = AsyncError(outcome.message, StackTrace.empty);
      } else {
        // بانتظار قرار المستخدم في نافذة العجز — ليست حالة خطأ
        state = const AsyncData(null);
      }
      return outcome;
    } catch (e, st) {
      final msg = _msg(e);
      state = AsyncError(msg, st);
      return PostAdvanceOutcome(success: false, message: msg);
    }
  }

  /// إلغاء سلفة — يعكس سندات صرفها ويُعيد المبلغ للخزينة
  Future<bool> cancelAdvance(int advanceId) async {
    final user = _user;
    if (user == null || !user.can(AppPermission.cancelAdvance)) {
      state = const AsyncError(
        'إلغاء سلف المشاريع يتطلب صلاحية مدير.',
        StackTrace.empty,
      );
      return false;
    }

    state = const AsyncLoading();
    try {
      final info = await _repo.cancelAdvance(
        advanceId: advanceId,
        cancelledByUserId: user.id,
      );

      await ref.read(auditLoggerProvider).logAdvanceCancelled(
            userId: user.id,
            username: user.username,
            advanceId: advanceId,
            advanceNumber: info.advanceNumber,
            previousStatus: info.previousStatus,
            vouchersReversed: info.vouchersReversed,
            reversedAmount: info.reversedAmount,
          );

      _invalidateAll(advanceId);
      state = AsyncData(
        'أُلغيت السلفة رقم ${info.advanceNumber}'
        '${info.vouchersReversed > 0 ? ' — عُكِس ${info.vouchersReversed} سند صرف' : ''} ✓',
      );
      return true;
    } catch (e, st) {
      state = AsyncError(_msg(e), st);
      return false;
    }
  }

  /// استخراج رسالة عربية مفهومة من الاستثناء
  ///
  /// StateError يحمل رسائلنا العربية الجاهزة؛ غيره يُعرَض كما هو.
  String _msg(Object e) => e is StateError ? e.message : e.toString();
}
