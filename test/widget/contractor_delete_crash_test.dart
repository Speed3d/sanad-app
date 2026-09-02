// ─────────────────────────────────────────────────────────────────────────────
// contractor_delete_crash_test.dart — ع-٥٧: انهيار حذف المقاول
//
// **بلاغ المالك (2026-09-02):** «أضفتُ مقاولاً... وبعدها ذهبتُ لحذف المقاول
//   فتوقّف البرنامج عن العمل في هذه الشاشة:
//     Bad state: Cannot use "ref" after the widget was disposed.»
//
// **السبب الجذري:** ورقة التفاصيل تُغلق نفسها ثم تفتح حوار التأكيد:
//     Navigator.pop(context);              // ← تتخلّص من الورقة
//     showDialog(... onConfirm: () => ref.read(...));   // ← ref ماتَ معها
//   فالإغلاق (closure) يحمل مرجعاً إلى ودجتٍ فُكّت من الشجرة.
//
// ═══ لماذا اختبار ودجت هنا، واختبارُ **المصدر** في ع-٠٤؟ ═══
//   لأن العطلين يختلفان في طبيعتهما لا في شكلهما:
//     • ع-٠٤ يعتمد على **توقيت** أنيميشن الخروج وتصادفه مع إعادة البناء —
//       فاختبار الودجت له يمرّ أحياناً ويفشل أحياناً، وهو أسوأ من لا اختبار.
//     • وهذا **حتميّ**: الـ`ref` ميتٌ لحظة الـpop، فالضغط على «حذف» يرمي
//       في كل مرّة بلا استثناء.
//
//   وجُرّب الحارس النصّي أولاً فأُسقط عمداً: لا يستطيع نصٌّ أن يُميّز بين
//   **شاشةٍ تُغلق حواراً فتحته** (سليم تماماً وشائع في كل الملفات) و**ورقةٍ
//   تُغلق نفسها** (العطل). فأنتج عشرات الإنذارات الكاذبة — وحارسٌ يُنذر
//   كذباً يُعلَّم الناسُ تجاهلَه.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/presentation/features/contractors/contractors_screen.dart';
import 'package:sales_management/presentation/providers/database_provider.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  }

  Widget wrap(Widget child) => ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('ar'),
          home: Directionality(textDirection: TextDirection.rtl, child: child),
        ),
      );

  /// مقاول بخزينته — كما يُنشئه المالك تماماً
  Future<int> seedContractor() => db.contractorsDao.insertContractorWithTreasury(
        ContractorsCompanion.insert(name: 'مقاول البصرة'),
        treasuryName: 'خزنة مقاول البصرة',
      );

  testWidgets('⭐⭐⭐ حذف مقاول من ورقة تفاصيله لا يُسقط التطبيق',
      (tester) async {
    await seedContractor();

    await tester.pumpWidget(wrap(const ContractorsScreen()));
    await settle(tester);

    // فتح ورقة التفاصيل بالضغط على بطاقة المقاول
    await tester.tap(find.text('مقاول البصرة').first);
    await settle(tester);

    // قائمة الإجراءات ثم «حذف»
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await settle(tester);
    await tester.tap(find.text('حذف').last);
    await settle(tester);

    // 🔴 هنا كان الانهيار: الورقة أُغلقت، فصار `ref` داخل الحوار ميتاً
    expect(find.text('تأكيد الحذف'), findsOneWidget,
        reason: 'حوار التأكيد لم يُفتح بعد إغلاق الورقة');

    await tester.tap(find.widgetWithText(FilledButton, 'حذف'));
    await settle(tester);

    expect(tester.takeException(), isNull,
        reason: 'Bad state: Cannot use "ref" after the widget was disposed');

    // والحذف وقع فعلاً — لا «لم ينهَر ولم يفعل شيئاً»
    final remaining = await db.contractorsDao.getAllContractors();
    expect(remaining, isEmpty);

    await disposeTree(tester);
  });

  testWidgets('⭐⭐ حوار التأكيد ينبّه أن الخزينة ستُحذف معه', (tester) async {
    await seedContractor();

    await tester.pumpWidget(wrap(const ContractorsScreen()));
    await settle(tester);
    await tester.tap(find.text('مقاول البصرة').first);
    await settle(tester);
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await settle(tester);
    await tester.tap(find.text('حذف').last);
    await settle(tester);

    // حذفٌ يمسّ حساب مالٍ لا يجوز أن يقع بلا أن يعرف صاحبه أنه يمسّه
    expect(find.textContaining('ستُحذف خزينته معه'), findsOneWidget);

    await disposeTree(tester);
  });
}
