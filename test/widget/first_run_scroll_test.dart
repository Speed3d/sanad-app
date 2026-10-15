// ─────────────────────────────────────────────────────────────────────────────
// first_run_scroll_test.dart — شاشة الإعداد الأول في نافذةٍ صغيرة
//
// **البلاغ (المالك 2026-10-15):** في الإعداد الأول لا يتحرّك المحتوى
//   بارتياح، وإن صُغّرت النافذة اختفت الأزرار والحقول السفلية ولا يُوصَل
//   إليها إلا بتكبير النافذة.
//
// يقيس الاختبار ما يفعله المالك بالضبط: **عجلة الفأرة فوق النموذج** في
//   نافذةٍ قصيرة، ثم هل زرّ «التالي» صار مرئياً وقابلاً للضغط.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/theme/app_theme.dart';
import 'package:sales_management/presentation/features/auth/first_run_screen.dart';

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: FirstRunScreen(),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _wheel(WidgetTester tester, Offset at, double dy) async {
  final pointer = TestPointer(1, PointerDeviceKind.mouse);
  await tester.sendEventToBinding(pointer.hover(at));
  await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('⭐⭐⭐ عجلة الفأرة فوق حقول النموذج تُنزل الصفحة إلى «التالي»',
      (tester) async {
    await _pump(tester, const Size(900, 520));

    // الـStepper يبني أزرار كل الخطوات — الأولى هي الخطوة النشطة.
    final next = find.text('التالي').first;
    final viewH = tester.view.physicalSize.height;
    expect(tester.getTopLeft(next).dy, greaterThan(viewH),
        reason: 'الافتراض: الزرّ خارج النافذة القصيرة قبل التمرير');

    // فوق حقل «اسم الشركة» — وسط النموذج لا هامشه.
    await _wheel(tester, tester.getCenter(find.byType(TextFormField).first),
        600);

    expect(tester.getBottomLeft(next).dy, lessThanOrEqualTo(viewH),
        reason: 'العجلة فوق النموذج لم تحرّك الصفحة');
    await tester.tap(next); // قابلٌ للضغط فعلاً
  });

  testWidgets('⭐⭐ والعجلة في الهامش الجانبي تحرّك الصفحة أيضاً',
      (tester) async {
    await _pump(tester, const Size(1400, 520));

    // الـStepper يبني أزرار كل الخطوات — الأولى هي الخطوة النشطة.
    final next = find.text('التالي').first;
    // ٢٠ بكسل من حافة النافذة — خارج عمود الـ٦٨٠ بكسل.
    await _wheel(tester, const Offset(20, 260), 600);

    expect(tester.getBottomLeft(next).dy,
        lessThanOrEqualTo(tester.view.physicalSize.height),
        reason: 'الهامش خارج منطقة التمرير');
  });
}
