// ─────────────────────────────────────────────────────────────────────────────
// provider_read_once.dart — قراءة نتيجة مزوّد غير متزامن **مرّة واحدة** بأمان
//
// 🔴 **العطل الذي وُلد منه هذا الملف** (ع-٣٥ — بلاغ المالك 2026-08-27):
//   أسقط التطبيقَ حذفُ خزينة، بالاستثناء:
//   > `Bad state: The provider ... was disposed during loading state,
//   >  yet no value could be emitted.`
//
//   السبب: `await ref.read(someProvider.future)` داخل دالة async.
//   المزوّدات المولَّدة بـ`@riverpod` كلها **`autoDispose`**، و`ref.read`
//   **لا يضيف مستمعاً**. فيُنشَأ المزوّد ويبدأ استعلامه، ثم يجد المجدوِل أن
//   لا أحد يستمع إليه فيتخلّص منه — **قبل أن يصل الجواب**.
//
// ⚠️ **وأخطر ما فيه أنه سباق لا عطلٌ ثابت:** ينجح حين يسبق الاستعلامُ دورةَ
//   التخلّص، ويفشل حين يتأخّر جزءاً من ألف ثانية. فبدا أنه «يعمل مع خزينة
//   ويُسقط التطبيق مع التالية» — وهذا صنف الأعطال الذي يمرّ من كل اختبار
//   ويظهر عند المالك وحده.
//
// **العلاج:** اشتراكٌ يدويّ يُبقي المزوّد حيّاً حتى يصل الجواب، ثم يُغلَق.
// يحرس النمطَ `tech_debt_guard_test`.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// قراءة نتيجة مزوّد غير متزامن مرّة واحدة — **بلا خطر التخلّص أثناء التحميل**
///
/// ```dart
/// final treasuries = await ref.readOnce(
///   allTreasuriesProvider, allTreasuriesProvider.future);
/// ```
///
/// **لماذا يُمرَّر المزوّد مرّتين؟** لأن الاشتراك يحتاج المزوّد نفسه
/// (`ProviderListenable<AsyncValue<T>>`) بينما الانتظار يحتاج مستقبله
/// (`.future`) — وهما نوعان مختلفان في Riverpod، فلا سبيل لاشتقاق أحدهما
/// من الآخر بلا فقدان النوع.
///
/// 📌 **ومتى لا تحتاجه؟** حين يكون الاستعلام لمرّة واحدة أصلاً — عندها اقرأ
/// من المستودع أو الـDAO مباشرةً بلا مزوّد. المزوّد للحالة المُراقَبة.
extension ProviderReadOnce on WidgetRef {
  Future<T> readOnce<T>(
    ProviderListenable<AsyncValue<T>> provider,
    ProviderListenable<Future<T>> future,
  ) async {
    // الاشتراك يُبقيه حيّاً · و`finally` يُغلقه ولو رمى الاستعلام
    final subscription = listenManual(provider, (_, __) {});
    try {
      return await read(future);
    } finally {
      subscription.close();
    }
  }
}
