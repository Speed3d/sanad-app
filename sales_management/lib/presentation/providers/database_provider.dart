// ─────────────────────────────────────────────────────────────────────────────
// database_provider.dart — Provider قاعدة البيانات الرئيسية
//
// هذا الـ Provider هو نقطة الدخول الوحيدة لـ AppDatabase في التطبيق.
// جميع الـ Repository Providers تعتمد عليه.
//
// لماذا keepAlive: true؟
//   قاعدة البيانات يجب أن تبقى مفتوحة طوال عمر التطبيق.
//   إذا أُغلقت وأُعيد فتحها، سيكون هناك تأخير وقد تُفقَد بيانات غير مُحفَظة.
//
// الاستخدام:
//   final db = ref.watch(appDatabaseProvider);
//   final users = await db.usersDao.getAllUsers();
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/database/app_database.dart';

part 'database_provider.g.dart';

/// Provider لـ AppDatabase — حياته طوال عمر التطبيق
///
/// يُنشَأ مرة واحدة عند أول استخدام ويبقى حياً حتى إغلاق التطبيق.
/// جميع الـ DAOs تُستدعى عبر هذا الـ Provider.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  // إنشاء قاعدة البيانات — drift_flutter يختار المسار المناسب
  final db = AppDatabase();

  // تنظيف: عند تدمير الـ Provider (عند إنهاء التطبيق) نُغلق الاتصال
  ref.onDispose(db.close);

  return db;
}
