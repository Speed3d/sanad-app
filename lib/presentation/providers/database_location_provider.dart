// ─────────────────────────────────────────────────────────────────────────────
// database_location_provider.dart — موضع القاعدة في شجرة المزوّدات
//
// المزوّدان **يُحقَنان في main.dart** بعد سؤال `DatabaseLocation.resolve()`
// وقبل `runApp` — فالقاعدة لا تُفتح إلا بعد أن يُعرف موضعها يقيناً. والقيمة
// الافتراضية `null` هي حال الويب (OPFS لا مسار له) والاختبارات.
//
// لماذا مزوّدان مكتوبان بيد لا مولَّدان؟ لأنهما يُحقَنان بـ `overrideWith`
// من main، ومزوّد الحالة البسيط أوضح هنا من Notifier مولَّد.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_location.dart';

/// خدمة الموضع — `null` على الويب (لا ملف ولا نقل)
final databaseLocationProvider = Provider<DatabaseLocation?>((ref) => null);

/// المسار الكامل لملف القاعدة الحيّة — `null` = افتراضيّ drift (الويب)
///
/// **يُراقبه `appDatabaseProvider`**: تغييره بعد النقل يُغلق القاعدة القديمة
/// ويفتح الجديدة بلا إعادة تشغيل. وهو أيضاً ما تقرؤه شاشة النسخ الاحتياطي —
/// فلا يبني أحدٌ المسار بيده بعد اليوم.
final activeDatabasePathProvider = StateProvider<String?>((ref) => null);
