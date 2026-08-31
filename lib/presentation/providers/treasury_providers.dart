// ─────────────────────────────────────────────────────────────────────────────
// treasury_providers.dart — Providers الخزائن
//
// يُوفّر Providers تفاعلية لقوائم الخزائن وأرصدتها:
//   - قائمة أرصدة جميع الخزائن (للـ Dashboard وشاشة الخزائن)
//   - رصيد خزينة واحدة (لشاشة التفاصيل)
//   - إجمالي الرصيد (للـ Dashboard السريع)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/treasury_model.dart';
import '../../domain/repositories/i_treasury_repository.dart';
import 'repository_providers.dart';

part 'treasury_providers.g.dart';

// ── قوائم الخزائن ─────────────────────────────────────────────────────────────

/// Stream تفاعلي لجميع أرصدة الخزائن
///
/// يتحدث تلقائياً عند أي تغيير في جداول Treasuries أو Vouchers
/// يُستخدَم في شاشة الخزائن والـ Dashboard
@riverpod
Stream<List<TreasuryBalanceModel>> treasuryBalances(Ref ref) {
  final repo = ref.watch(treasuryRepositoryProvider);
  return repo.watchTreasuryBalances();
}

/// Stream تفاعلي لرصيد خزينة واحدة
///
/// [treasuryId] — معرّف الخزينة المطلوبة
@riverpod
Stream<TreasuryBalanceModel?> treasuryBalance(
  Ref ref,
  int treasuryId,
) {
  final repo = ref.watch(treasuryRepositoryProvider);
  return repo.watchTreasuryBalance(treasuryId);
}

/// إجمالي رصيد جميع الخزائن (Future — للقراءة لمرة واحدة)
///
/// يُستخدَم في بطاقة الإجمالي في الـ Dashboard
@riverpod
Future<({double totalIqd, double totalUsd})> totalTreasuryBalance(Ref ref) {
  final repo = ref.watch(treasuryRepositoryProvider);
  return repo.getTotalBalance();
}

/// جميع الخزائن النشطة (Future — للـ Dropdowns)
@riverpod
Future<List<TreasuryModel>> allTreasuries(Ref ref) {
  final repo = ref.watch(treasuryRepositoryProvider);
  return repo.getAllTreasuries();
}

// ═══════════════════════════════════════════════════════════════════════════
// TreasuryNotifier — إدارة عمليات CRUD للخزائن
// ═══════════════════════════════════════════════════════════════════════════

/// Notifier لعمليات إنشاء / تعديل / حذف / تفعيل الخزائن
///
/// الحالة:
///   AsyncData(null)      — لا عملية جارية
///   AsyncData('رسالة')   — نجاح
///   AsyncLoading()       — عملية جارية
///   AsyncError(...)      — خطأ
@riverpod
class TreasuryNotifier extends _$TreasuryNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  ITreasuryRepository get _repo => ref.read(treasuryRepositoryProvider);

  /// إبطال مزوّدات قوائم الخزائن (Future) بعد أي كتابة
  ///
  /// ⚠️ بدون هذا لا تظهر الخزينة الجديدة/المعدَّلة في القوائم المنسدلة
  /// (سندات، رواتب، سلف، تقارير) إلا بعد إعادة تشغيل التطبيق. تدقيق 2026-08-06.
  void _invalidateTreasuryLists() {
    ref.invalidate(allTreasuriesProvider);
    ref.invalidate(totalTreasuryBalanceProvider);
  }

  // ── إنشاء خزينة جديدة ────────────────────────────────────────────────
  /// إنشاء خزينة رئيسية جديدة
  ///
  /// ملاحظة: خزائن المقاولين والشركاء تُنشَأ تلقائياً عند إنشاء الكيان
  Future<bool> createTreasury({
    required String name,
    String kind = 'main',
  }) async {
    if (name.trim().isEmpty) {
      state = const AsyncError('اسم الخزينة لا يمكن أن يكون فارغاً', StackTrace.empty);
      return false;
    }
    state = const AsyncLoading();
    try {
      await _repo.createTreasury(name: name.trim(), kind: kind);
      _invalidateTreasuryLists();
      state = const AsyncData('تم إنشاء الخزينة بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── تعديل اسم خزينة ──────────────────────────────────────────────────
  /// تحديث اسم الخزينة
  Future<bool> renameTreasury(TreasuryModel treasury, String newName) async {
    if (newName.trim().isEmpty) {
      state = const AsyncError('الاسم لا يمكن أن يكون فارغاً', StackTrace.empty);
      return false;
    }
    if (newName.trim() == treasury.name) {
      state = const AsyncData(null);
      return true;
    }
    state = const AsyncLoading();
    try {
      await _repo.updateTreasury(treasury.copyWith(name: newName.trim()));
      _invalidateTreasuryLists();
      state = const AsyncData('تم تحديث اسم الخزينة بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── تفعيل / تعطيل خزينة ──────────────────────────────────────────────
  /// تفعيل أو تعطيل خزينة مؤقتاً
  Future<bool> toggleActive(int id, {required bool isActive}) async {
    state = const AsyncLoading();
    try {
      await _repo.setActive(id, isActive: isActive);
      _invalidateTreasuryLists();
      state = AsyncData(isActive ? 'تم تفعيل الخزينة ✓' : 'تم تعطيل الخزينة ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── حذف خزينة (ناعم) ─────────────────────────────────────────────────
  /// حذف ناعم للخزينة مع التحقق من عدم وجود سندات
  ///
  /// [totalVouchers] — عدد السندات من الـ VIEW (للتحقق قبل الحذف)
  Future<bool> deleteTreasury(int id, {required int totalVouchers}) async {
    if (totalVouchers > 0) {
      state = const AsyncError(
        'لا يمكن حذف خزينة تحتوي على سندات — عطّلها بدلاً من ذلك',
        StackTrace.empty,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      await _repo.deleteTreasury(id);
      _invalidateTreasuryLists();
      state = const AsyncData('تم حذف الخزينة بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// إعادة الحالة لـ idle بعد عرض الرسالة
  void reset() => state = const AsyncData(null);
}
