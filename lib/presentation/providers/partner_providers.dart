// ─────────────────────────────────────────────────────────────────────────────
// partner_providers.dart — Providers الشركاء
//
// يُوفّر:
//   - allPartnersProvider           — Stream تفاعلي لجميع الشركاء
//   - totalSharePercentageProvider  — Future مجموع الحصص المُخصَّصة
//   - searchPartnersProvider        — Future بحث نصي
//   - PartnerNotifier               — CRUD الشركاء (مع التحقق من مجموع الحصص)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/database/app_database.dart';
import '../../domain/models/partner_model.dart';
import 'database_provider.dart';

part 'partner_providers.g.dart';

// ── دالة تحويل Drift → Domain ─────────────────────────────────────────────

PartnerModel _mapPartner(Partner p) => PartnerModel(
      id: p.id,
      name: p.name,
      phone: p.phone,
      address: p.address,
      sharePercentage: p.sharePercentage,
      treasuryId: p.treasuryId,
      notes: p.notes,
      isActive: p.isActive,
      createdAt: p.createdAt,
    );

// ── قوائم الشركاء التفاعلية ────────────────────────────────────────────────

/// Stream تفاعلي لجميع الشركاء (غير المحذوفين) مرتب أبجدياً
@riverpod
Stream<List<PartnerModel>> allPartners(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.partnersDao
      .watchAllPartners()
      .map((list) => list.map(_mapPartner).toList());
}

/// مجموع الحصص المُخصَّصة لجميع الشركاء النشطين
///
/// يُستخدَم للتحقق من أن الحصة الجديدة لا تتجاوز الحد الأقصى 100%
@riverpod
Future<double> totalSharePercentage(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.partnersDao.getTotalSharePercentage();
}

/// بحث نصي في الشركاء
///
/// يُعيد قائمة فارغة إذا كان النص فارغاً
@riverpod
Future<List<PartnerModel>> searchPartners(Ref ref, String query) {
  if (query.trim().isEmpty) return Future.value([]);
  final db = ref.watch(appDatabaseProvider);
  return db.partnersDao
      .searchPartners(query.trim())
      .then((list) => list.map(_mapPartner).toList());
}

// ═══════════════════════════════════════════════════════════════════════════
// PartnerNotifier — CRUD الشركاء
// ═══════════════════════════════════════════════════════════════════════════

/// Notifier لإدارة عمليات الشركاء
///
/// القاعدة الذهبية: مجموع حصص جميع الشركاء ≤ 100%
/// يُتحقَّق منها في createPartner و updatePartner
///
/// الحالة:
///   AsyncData(null)      — idle
///   AsyncData('رسالة')   — نجاح
///   AsyncLoading()       — عملية جارية
///   AsyncError(...)      — فشل
@riverpod
class PartnerNotifier extends _$PartnerNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  AppDatabase get _db => ref.read(appDatabaseProvider);

  /// إبطال مزوّد مجموع نسب الحصص بعد أي كتابة — وإلا يبقى شريط توزيع
  /// الحصص قديماً بعد كل إضافة/تعديل/حذف. تدقيق 2026-08-06 (H3).
  void _invalidateShareTotal() => ref.invalidate(totalSharePercentageProvider);

  // ── إضافة شريك جديد ────────────────────────────────────────────────────

  Future<bool> createPartner({
    required String name,
    String phone = '',
    String address = '',
    double sharePercentage = 0.0,
    String notes = '',
    bool createTreasury = true,
    int? existingTreasuryId,
  }) async {
    if (name.trim().isEmpty) {
      state = const AsyncError(
        'اسم الشريك لا يمكن أن يكون فارغاً',
        StackTrace.empty,
      );
      return false;
    }
    if (sharePercentage < 0 || sharePercentage > 100) {
      state = const AsyncError(
        'نسبة الحصة يجب أن تكون بين 0 و 100',
        StackTrace.empty,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      // التحقق من مجموع الحصص
      final currentTotal = await _db.partnersDao.getTotalSharePercentage();
      if (currentTotal + sharePercentage > 100.001) {
        state = AsyncError(
          'مجموع الحصص سيتجاوز 100%\n'
          'الحصص المُخصَّصة حالياً: ${currentTotal.toStringAsFixed(1)}%\n'
          'الحد الأقصى المتاح: ${(100 - currentTotal).toStringAsFixed(1)}%',
          StackTrace.empty,
        );
        return false;
      }
      // 🔑 الخزينة تُنشَأ أو تُربَط هنا — راجع `createContractor` للشرح
      final clean = name.trim();
      await _db.partnersDao.insertPartnerWithTreasury(
        PartnersCompanion.insert(
          name: clean,
          phone: Value(phone.trim()),
          address: Value(address.trim()),
          sharePercentage: Value(sharePercentage),
          notes: Value(notes.trim()),
        ),
        treasuryName: existingTreasuryId == null && createTreasury
            ? 'شريك: $clean'
            : null,
        existingTreasuryId: existingTreasuryId,
      );
      _invalidateShareTotal();
      state = AsyncData(existingTreasuryId != null || createTreasury
          ? 'تم إضافة الشريك وخزينته ✓'
          : 'تم إضافة الشريك بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── تعديل بيانات شريك ──────────────────────────────────────────────────

  Future<bool> updatePartner(
    PartnerModel partner, {
    required String name,
    String phone = '',
    String address = '',
    double sharePercentage = 0.0,
    String notes = '',
  }) async {
    if (name.trim().isEmpty) {
      state = const AsyncError(
        'الاسم لا يمكن أن يكون فارغاً',
        StackTrace.empty,
      );
      return false;
    }
    if (sharePercentage < 0 || sharePercentage > 100) {
      state = const AsyncError(
        'نسبة الحصة يجب أن تكون بين 0 و 100',
        StackTrace.empty,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      // التحقق من مجموع الحصص (مع استثناء الحصة الحالية لهذا الشريك)
      final currentTotal = await _db.partnersDao.getTotalSharePercentage();
      final otherTotal = currentTotal - partner.sharePercentage;
      if (otherTotal + sharePercentage > 100.001) {
        state = AsyncError(
          'مجموع الحصص سيتجاوز 100%\n'
          'حصص الشركاء الآخرين: ${otherTotal.toStringAsFixed(1)}%\n'
          'الحد الأقصى المتاح: ${(100 - otherTotal).toStringAsFixed(1)}%',
          StackTrace.empty,
        );
        return false;
      }
      await _db.partnersDao.updatePartner(
        PartnersCompanion(
          id: Value(partner.id),
          name: Value(name.trim()),
          phone: Value(phone.trim()),
          address: Value(address.trim()),
          sharePercentage: Value(sharePercentage),
          notes: Value(notes.trim()),
          isActive: Value(partner.isActive),
        ),
      );
      _invalidateShareTotal();
      state = const AsyncData('تم تحديث بيانات الشريك ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── تفعيل / تعطيل شريك ─────────────────────────────────────────────────

  Future<bool> toggleActive(PartnerModel partner) async {
    state = const AsyncLoading();
    try {
      await _db.partnersDao.setPartnerActive(
        partner.id,
        isActive: !partner.isActive,
      );
      state = AsyncData(
        partner.isActive ? 'تم تعطيل الشريك ✓' : 'تم تفعيل الشريك ✓',
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── حذف شريك ───────────────────────────────────────────────────────────

  /// حذف ناعم — يحتفظ بسجل المعاملات والتوزيعات التاريخية
  Future<bool> deletePartner(int id) async {
    state = const AsyncLoading();
    try {
      await _db.partnersDao.softDeletePartner(id);
      _invalidateShareTotal();
      state = const AsyncData('تم حذف الشريك ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// إعادة الحالة لـ idle
  void reset() => state = const AsyncData(null);
}
