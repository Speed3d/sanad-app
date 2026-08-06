// ─────────────────────────────────────────────────────────────────────────────
// repository_providers.dart — Providers لجميع الـ Repositories
//
// هذا الملف يُعرّف Provider واحداً لكل Repository في التطبيق.
// كل Provider يُحقَن فيه AppDatabase من appDatabaseProvider.
//
// نمط الاستخدام في الواجهة:
//   final userRepo = ref.watch(userRepositoryProvider);
//   final users = await userRepo.getAllUsers();
//
// نمط الاستخدام في الـ Notifiers:
//   @override
//   Future<void> build() async {
//     final repo = ref.watch(voucherRepositoryProvider);
//     ...
//   }
//
// لماذا keepAlive: true لجميع Repositories؟
//   الـ Repositories تحتوي على Streams تفاعلية — إذا أُعيد إنشاؤها
//   ستنقطع الـ Streams وتفقد الـ UI تحديثاتها التلقائية.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/user_repository.dart';
import '../../data/repositories/treasury_repository.dart';
import '../../data/repositories/voucher_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../../domain/repositories/i_treasury_repository.dart';
import '../../domain/repositories/i_voucher_repository.dart';
import '../../domain/repositories/i_settings_repository.dart';
import 'database_provider.dart';

part 'repository_providers.g.dart';

// ── مستودع المستخدمين ────────────────────────────────────────────────────────

/// Provider مستودع المستخدمين
///
/// يُعيد [IUserRepository] — الكود يعتمد على الواجهة لا على التنفيذ
@Riverpod(keepAlive: true)
IUserRepository userRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return UserRepository(db);
}

// ── مستودع الخزائن ───────────────────────────────────────────────────────────

/// Provider مستودع الخزائن
@Riverpod(keepAlive: true)
ITreasuryRepository treasuryRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return TreasuryRepository(db);
}

// ── مستودع السندات ───────────────────────────────────────────────────────────

/// Provider مستودع السندات
@Riverpod(keepAlive: true)
IVoucherRepository voucherRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return VoucherRepository(db);
}

// ── مستودع الإعدادات ─────────────────────────────────────────────────────────

/// Provider مستودع الإعدادات
@Riverpod(keepAlive: true)
ISettingsRepository settingsRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return SettingsRepository(db);
}
