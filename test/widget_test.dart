// ─────────────────────────────────────────────────────────────────────────────
// widget_test.dart — اختبار أساسي للتطبيق
//
// يتحقق من أن التطبيق يبدأ بدون أخطاء.
// الاختبارات التفصيلية ستُضاف في Sprint 14.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sales_management/main.dart';

void main() {
  testWidgets('التطبيق يبدأ بدون أخطاء', (WidgetTester tester) async {
    // بناء التطبيق مغلّفاً بـ ProviderScope كما هو في main()
    await tester.pumpWidget(
      const ProviderScope(
        child: SalesManagementApp(),
      ),
    );

    // التحقق من أن شاشة البداية تظهر (Splash Screen)
    expect(find.byType(MaterialApp), findsOneWidget);

    // ── تصفية المؤقتات المعلّقة ──────────────────────────────────────────
    // شاشة البداية تُنشئ مؤقتاً مدته 2000ms في initState (_startMinDelay).
    // لو لم ننتظر انقضاءه يفشل الاختبار برسالة "Pending timers".
    // ننتظر أكثر من مدة المؤقت لضمان إطلاقه ثم نترك الأنيميشن يستقر.
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump();
  });
}
