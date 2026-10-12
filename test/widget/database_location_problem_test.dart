// ─────────────────────────────────────────────────────────────────────────────
// database_location_problem_test.dart — شاشة «لم يُعثَر على القاعدة»
//
// تحرس عطلين كشفهما **التشغيل الفعلي** لا أي اختبار (2026-10-12):
//   ١. المسار داخل الفقرة العربية ظهر بمقاطع مقلوبة — فصار سطراً مستقلاً
//      باتجاهٍ من اليسار.
//   ٢. الأزرار بدت معطَّلة في الوضع الداكن (FilledButton كحلي على كحلي).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sales_management/core/theme/app_theme.dart';
import 'package:sales_management/data/database/database_location.dart';
import 'package:sales_management/presentation/features/database_location/database_location_problem_app.dart';

/// أول RenderEditable تحت [r] — محرّك الرسم الفعلي لـ SelectableText
RenderEditable? _editable(RenderObject r) {
  if (r is RenderEditable) return r;
  RenderEditable? out;
  r.visitChildren((c) => out ??= _editable(c));
  return out;
}

void main() {
  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('sanad_problem'));
  tearDown(() async {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<void> pump(WidgetTester tester, ThemeData theme) async {
    final missing = p.join(tmp.path, 'قرص غائب', 'SanadData');
    final location = DatabaseLocation(
      defaultDirectory: tmp.path,
      pointerDirectory: p.join(tmp.path, 'ptr'),
    );
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: DatabaseLocationProblemScreen(
          location: location,
          resolved: ResolvedDatabaseLocation(
            directory: missing,
            databasePath: p.join(missing, DatabaseLocation.databaseFileName),
            isCustom: true,
            problem: LocationProblem.folderMissing,
          ),
          onResolved: () async {},
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('⭐⭐ المسار سطرٌ مستقلّ باتجاهٍ من اليسار — لا يُقلَب داخل الفقرة',
      (tester) async {
    await pump(tester, AppTheme.light);
    final missing = p.join(tmp.path, 'قرص غائب', 'SanadData');

    final pathWidget = tester.widget<SelectableText>(
      find.byWidgetPredicate((w) => w is SelectableText && w.data == missing),
    );
    expect(pathWidget.textDirection, TextDirection.ltr);

    // ⚠️ الخاصية وحدها لا تكفي (د-٦: افحص ما بداخل الناتج لا شكله) —
    //   يُقاس **موضع الحرف الأول من الرسم الفعلي**: من اليسار يجب أن يقع
    //   أول المسار (حرف القرص) يسار آخره. بلا الإصلاح يقع يمينه.
    final re = _editable(tester.renderObject(find.byWidget(pathWidget)))!;
    final startX = re.getLocalRectForCaret(const TextPosition(offset: 1)).left;
    final endX =
        re.getLocalRectForCaret(TextPosition(offset: missing.length)).left;
    expect(startX, lessThan(endX),
        reason: 'حرف القرص يجب أن يُرسم يسار نهاية المسار كما في المستكشف');
    expect(missing.contains('\u2066'), isFalse,
        reason: 'المسار المستقلّ بلا محارف عزل — وإلا لُصق في المستكشف فرُفض');
    expect(find.text('لم يُعثَر على قاعدة البيانات'), findsOneWidget);
  });

  testWidgets('⭐⭐ الزرّ الرئيسي ElevatedButton — مقروء في الوضع الداكن', (tester) async {
    await pump(tester, AppTheme.dark);
    expect(find.widgetWithText(ElevatedButton, 'إعادة المحاولة'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing,
        reason: 'FilledButton كحليٌّ على كحلي في الوضع الداكن — بدا معطَّلاً');
    expect(find.text('اختيار مجلد القاعدة…'), findsOneWidget);
    expect(find.text('البدء من الموضع الافتراضي'), findsOneWidget);
  });

  test('bidiPath يعزل المسار داخل جملة عربية', () {
    expect(DatabaseLocation.bidiPath(r'D:\a'), '\u2066D:\\a\u2069');
  });
}
