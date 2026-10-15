// ─────────────────────────────────────────────────────────────────────────────
// fab_shape_guard_test.dart — حارس شكل أزرار الإضافة العائمة
//
// **البلاغ (المالك 2026-10-15):** أزرار «خزينة جديدة» · «إضافة موظف جديد» ·
//   «مقاول جديد» · «شريك جديد» · «بند جديد» دائرية الشكل ولا تشبه بقية
//   أزرار البرنامج.
//
// **السبب:** الثيم يفرض `CircleBorder` على `FloatingActionButton`، وكل
//   أزرارنا من نوع `.extended` (أيقونة + نصّ) — فيُرسم الزرّ العريض قرصاً.
//   و«إضافة موظف» وحده كان يحمل ألوانه وخطّه بيده فيختلف عن إخوته أيضاً.
//
// **الحارسان:**
//   ١. الشكل المرسوم فعلاً (لا خاصية الثيم وحدها — درس ع-٦٦: اختبر الرسم)
//      مستطيلٌ بزوايا ١٢ كـ`ElevatedButton`، في الفاتح والداكن.
//   ٢. لا شاشة تمرّر `shape:` أو `backgroundColor:` لزرٍّ عائم — المصدر واحد.
//
// ⚠️ أُثبت أن الأوّل يفشل مع `CircleBorder` قبل الإصلاح.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/theme/app_theme.dart';

void main() {
  for (final entry in {'الفاتح': AppTheme.light, 'الداكن': AppTheme.dark}.entries) {
    testWidgets('⭐⭐ زرّ الإضافة العائم مستطيلٌ بزوايا ١٢ — ${entry.key}',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: entry.value,
        home: Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('خزينة جديدة'),
          ),
        ),
      ));

      final material = tester.widget<Material>(find.descendant(
        of: find.byType(FloatingActionButton),
        matching: find.byType(Material),
      ).first);

      expect(material.shape, isNot(isA<CircleBorder>()),
          reason: 'الشكل الدائري على زرٍّ بنصّ يُرسَم قرصاً — بلاغ المالك');
      expect(material.shape, isA<RoundedRectangleBorder>());
      expect(
        (material.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(12),
        reason: 'الزوايا نفسها كـ`ElevatedButton` في الثيم',
      );
    });
  }

  test('⭐⭐ لا شاشة تتجاوز شكل الزرّ العائم أو لونه', () {
    final offenders = <String>[];
    final files = Directory('lib/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains(RegExp(r'FloatingActionButton(\.extended)?\('))) {
          continue;
        }
        // الوسائط المباشرة للزرّ في الأسطر التالية حتى إغلاقه.
        var depth = 0;
        for (var j = i; j < lines.length && j < i + 40; j++) {
          final code = lines[j].split('//').first;
          if (j > i &&
              depth == 1 &&
              RegExp(r'^\s*(shape|backgroundColor|foregroundColor)\s*:')
                  .hasMatch(code)) {
            offenders.add('${file.path}:${j + 1}  ${lines[j].trim()}');
          }
          depth += '('.allMatches(code).length - ')'.allMatches(code).length;
          if (j >= i && depth <= 0) break;
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'زرٌّ عائم يتجاوز الثيم:\n${offenders.join('\n')}\n\n'
            'الشكل والألوان في `floatingActionButtonTheme` وحده — '
            'وإلا اختلف زرٌّ عن إخوته كما اختلف «إضافة موظف».');
  });
}
