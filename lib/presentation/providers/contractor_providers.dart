// ─────────────────────────────────────────────────────────────────────────────
// contractor_providers.dart — Providers المقاولين
//
// يُوفّر:
//   - allContractorsProvider        — Stream تفاعلي لجميع المقاولين
//   - searchContractorsProvider     — Future بحث نصي
//   - ContractorNotifier            — CRUD المقاولين
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/database/app_database.dart';
import '../../domain/models/contractor_model.dart';
import 'database_provider.dart';

part 'contractor_providers.g.dart';

// ── دالة تحويل Drift → Domain ─────────────────────────────────────────────

ContractorModel _mapContractor(Contractor c) => ContractorModel(
      id: c.id,
      name: c.name,
      phone1: c.phone1,
      phone2: c.phone2,
      address: c.address,
      contractorType: c.contractorType,
      treasuryId: c.treasuryId,
      notes: c.notes,
      isActive: c.isActive,
      createdAt: c.createdAt,
    );

// ── قوائم المقاولين التفاعلية ──────────────────────────────────────────────

/// Stream تفاعلي لجميع المقاولين (غير المحذوفين) مرتب أبجدياً
@riverpod
Stream<List<ContractorModel>> allContractors(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.contractorsDao
      .watchAllContractors()
      .map((list) => list.map(_mapContractor).toList());
}

/// بحث نصي في المقاولين
///
/// يُعيد قائمة فارغة إذا كان النص فارغاً
@riverpod
Future<List<ContractorModel>> searchContractors(Ref ref, String query) {
  if (query.trim().isEmpty) return Future.value([]);
  final db = ref.watch(appDatabaseProvider);
  return db.contractorsDao
      .searchContractors(query.trim())
      .then((list) => list.map(_mapContractor).toList());
}

// ═══════════════════════════════════════════════════════════════════════════
// ContractorNotifier — CRUD المقاولين
// ═══════════════════════════════════════════════════════════════════════════

/// Notifier لإدارة عمليات المقاولين
///
/// الحالة:
///   AsyncData(null)      — idle
///   AsyncData('رسالة')   — نجاح
///   AsyncLoading()       — عملية جارية
///   AsyncError(...)      — فشل
@riverpod
class ContractorNotifier extends _$ContractorNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  AppDatabase get _db => ref.read(appDatabaseProvider);

  // ── إضافة مقاول جديد ───────────────────────────────────────────────────

  Future<bool> createContractor({
    required String name,
    String phone1 = '',
    String phone2 = '',
    String address = '',
    String contractorType = 'individual',
    String notes = '',
  }) async {
    if (name.trim().isEmpty) {
      state = const AsyncError(
        'اسم المقاول لا يمكن أن يكون فارغاً',
        StackTrace.empty,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      await _db.contractorsDao.insertContractor(
        ContractorsCompanion.insert(
          name: name.trim(),
          phone1: Value(phone1.trim()),
          phone2: Value(phone2.trim()),
          address: Value(address.trim()),
          contractorType: Value(contractorType),
          notes: Value(notes.trim()),
        ),
      );
      state = const AsyncData('تم إضافة المقاول بنجاح ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── تعديل بيانات مقاول ─────────────────────────────────────────────────

  Future<bool> updateContractor(
    ContractorModel contractor, {
    required String name,
    String phone1 = '',
    String phone2 = '',
    String address = '',
    String contractorType = 'individual',
    String notes = '',
  }) async {
    if (name.trim().isEmpty) {
      state = const AsyncError(
        'الاسم لا يمكن أن يكون فارغاً',
        StackTrace.empty,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      await _db.contractorsDao.updateContractor(
        ContractorsCompanion(
          id: Value(contractor.id),
          name: Value(name.trim()),
          phone1: Value(phone1.trim()),
          phone2: Value(phone2.trim()),
          address: Value(address.trim()),
          contractorType: Value(contractorType),
          notes: Value(notes.trim()),
          isActive: Value(contractor.isActive),
        ),
      );
      state = const AsyncData('تم تحديث بيانات المقاول ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── تفعيل / تعطيل مقاول ────────────────────────────────────────────────

  Future<bool> toggleActive(ContractorModel contractor) async {
    state = const AsyncLoading();
    try {
      await _db.contractorsDao.setContractorActive(
        contractor.id,
        isActive: !contractor.isActive,
      );
      state = AsyncData(
        contractor.isActive ? 'تم تعطيل المقاول ✓' : 'تم تفعيل المقاول ✓',
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── حذف مقاول ──────────────────────────────────────────────────────────

  /// حذف ناعم — يحتفظ بسجل المعاملات التاريخية
  Future<bool> deleteContractor(int id) async {
    state = const AsyncLoading();
    try {
      await _db.contractorsDao.softDeleteContractor(id);
      state = const AsyncData('تم حذف المقاول ✓');
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// إعادة الحالة لـ idle
  void reset() => state = const AsyncData(null);
}
