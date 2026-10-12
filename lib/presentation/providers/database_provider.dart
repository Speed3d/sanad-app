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
import 'database_location_provider.dart';

part 'database_provider.g.dart';

/// Provider لـ AppDatabase — حياته طوال عمر التطبيق
///
/// يُنشَأ مرة واحدة عند أول استخدام ويبقى حياً حتى إغلاق التطبيق.
/// جميع الـ DAOs تُستدعى عبر هذا الـ Provider.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  // المسار من DatabaseLocation (حُقن في main) — و`null` على الويب حيث
  // يختار drift مخزن OPFS بنفسه. **يُراقَب لا يُقرأ**: تغييره بعد نقل
  // القاعدة يُعيد بناء هذا المزوّد فيُغلق القديمة ويفتح الجديدة.
  final path = ref.watch(activeDatabasePathProvider);
  final db = path == null ? AppDatabase() : AppDatabase.atPath(path);

  // تنظيف: عند تدمير الـ Provider (عند إنهاء التطبيق) نُغلق الاتصال
  ref.onDispose(db.close);

  return db;
}
