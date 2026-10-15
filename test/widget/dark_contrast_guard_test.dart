// ─────────────────────────────────────────────────────────────────────────────
// dark_contrast_guard_test.dart — ع-٦٧: نصّ الأزرار في الوضع الداكن
//
// **البلاغ (المالك 2026-10-15):** في الوضع الليلي نصّ الأزرار لا يُقرأ:
//   «إنشاء» في حوار الخزينة · «إضافة أول موظف» · نقل الموظفين والأقسام ·
//   استيراد ملف الرواتب و«اختيار ملف» · «إضافة» مقاول/شريك · «إنشاء فترة
//   مالية» · وأغلب أقسام الإعدادات. والنهاري سليم.
//
// **السبب:** `colorScheme.primary` كان الكحلي **في الوضعين**، وخلفية الداكن
//   كحليّة — فكلّ `FilledButton`/`OutlinedButton`/`TextButton` كحليٌّ على
//   كحلي. وثلاثون زرّاً تضع خلفيتها بيدها (أحمر للحذف…) وتترك النصّ للثيم.
//
// **الحرّاس الثلاثة:**
//   ١. التباين **المرسوم** (لا خاصية الثيم — درس ع-٦٦) لكل نوع زرّ في الداكن
//      على السطح والخلفية ≥ ٣:١.
//   ٢. الفاتح لم يتغيّر: الزرّ الممتلئ كحليٌّ بنصٍّ أبيض.
//   ٣. لا `styleFrom` يضع `backgroundColor` بلا `foregroundColor`.
//
// ⚠️ أُثبت أن الأوّل يفشل بالثيم القديم قبل اعتماده.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/theme/app_colors.dart';
import 'package:sales_management/core/theme/app_theme.dart';
import 'package:sales_management/core/theme/app_theme_extension.dart';

/// يرسم الزرّ على خلفية [bg] ويُعيد (لون النصّ، لون ما خلفه فعلاً).
Future<(Color, Color)> _measure(
  WidgetTester tester,
  ThemeData theme,
  Color bg,
  Widget button,
) async {
  await tester.pumpWidget(MaterialApp(
    theme: theme,
    home: Scaffold(
      backgroundColor: bg,
      body: Center(child: button),
    ),
  ));
  await tester.pumpAndSettle();

  final textEl = tester.element(find.text('زرّ'));
  final fg = DefaultTextStyle.of(textEl).style.color!;

  final material = tester.widget<Material>(find
      .ancestor(of: find.text('زرّ'), matching: find.byType(Material))
      .first);
  final btnBg = material.color;
  final behind = (btnBg == null || btnBg.a == 0) ? bg : btnBg;
  return (fg, behind);
}

void main() {
  final dark = AppTheme.dark;
  final light = AppTheme.light;

  final buttons = <String, Widget>{
    'FilledButton': FilledButton(onPressed: () {}, child: const Text('زرّ')),
    'FilledButton.tonal':
        FilledButton.tonal(onPressed: () {}, child: const Text('زرّ')),
    'OutlinedButton':
        OutlinedButton(onPressed: () {}, child: const Text('زرّ')),
    'TextButton': TextButton(onPressed: () {}, child: const Text('زرّ')),
    'ElevatedButton':
        ElevatedButton(onPressed: () {}, child: const Text('زرّ')),
  };

  group('⭐⭐⭐ ع-٦٧ — الأزرار مقروءة في الوضع الداكن', () {
    for (final surface in {
      'الخلفية': AppColors.bgDark,
      'البطاقة/الحوار': AppColors.surfaceDark,
    }.entries) {
      for (final b in buttons.entries) {
        testWidgets('${b.key} على ${surface.key}', (tester) async {
          final (fg, behind) =
              await _measure(tester, dark, surface.value, b.value);
          final ratio = contrastRatio(fg, behind);
          expect(ratio, greaterThanOrEqualTo(3.0),
              reason: '${b.key}: نصّ $fg على $behind — تباين '
                  '${ratio.toStringAsFixed(2)}:1 (ع-٦٧ كحليٌّ على كحلي)');
        });
      }
    }
  });

  testWidgets('⭐⭐ الوضع الفاتح لم يتغيّر — الزرّ الممتلئ كحليّ بنصٍّ أبيض',
      (tester) async {
    final (fg, behind) = await _measure(tester, light, AppColors.bgLight,
        buttons['FilledButton']!);
    expect(behind, AppColors.navy);
    expect(fg, Colors.white);
  });

  test('⭐⭐ readableText: الأبيض ما دام مقروءاً، وإلا الكحلي', () {
    // ألوانٌ مستعملةٌ فعلاً خلفيةً لأزرار في البرنامج
    expect(Colors.red.readableText, Colors.white); // الفاتح كما كان
    expect(AppColors.redLight.readableText, Colors.white);
    expect(Colors.green.shade700.readableText, Colors.white);
    expect(AppColors.redDark.readableText, AppColors.navy); // أحمر الداكن
    expect(AppColors.goldDark.readableText, AppColors.navy);
    for (final c in [Colors.red, Colors.orange, AppColors.redDark,
        AppColors.goldDark, Colors.indigo, Colors.green.shade700]) {
      expect(contrastRatio(c, c.readableText), greaterThanOrEqualTo(3.0),
          reason: '$c');
    }
  });

  test('⭐⭐ لا `styleFrom` يضع خلفيةً ويترك النصّ للثيم', () {
    final offenders = <String>[];
    final start =
        RegExp(r'(FilledButton|ElevatedButton|TextButton)\.styleFrom\(');
    for (final f in Directory('lib/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final s = f.readAsStringSync();
      for (final m in start.allMatches(s)) {
        var i = m.end, depth = 1;
        while (depth > 0) {
          final c = s[i++];
          if (c == '(') depth++;
          if (c == ')') depth--;
        }
        final body = s.substring(m.end, i - 1);
        if (RegExp(r'\bbackgroundColor\s*:').hasMatch(body) &&
            !RegExp(r'\bforegroundColor\s*:').hasMatch(body)) {
          final line = '\n'.allMatches(s.substring(0, m.start)).length + 1;
          offenders.add('${f.path}:$line');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'زرٌّ بخلفيةٍ يدوية ونصٍّ من الثيم:\n${offenders.join('\n')}\n'
            'الثيم يعطي نصّاً صُمّم للذهبي لا لخلفيتك — أضف\n'
            '  foregroundColor: <الخلفية>.readableText');
  });
}
