// ─────────────────────────────────────────────────────────────────────────────
// dialog_actions_guard_test.dart — حارس بنية `AlertDialog.actions`
//
// **العطل الذي يمنع عودته (بلاغ المالك 2026-09-03):**
//     Incorrect use of ParentDataWidget.
//     The ParentDataWidget Expanded(flex: 1) wants to apply ParentData of
//     type FlexParentData to a RenderObject, which has been set up to accept
//     ParentData of incompatible type _OverflowBarParentData.
//
// **السبب:** `AlertDialog.actions` تُبنى داخل **`OverflowBar`** لا `Row`.
//   و`Spacer` امتدادٌ لـ`Expanded`، والـ`Expanded` لا يعيش إلا داخل `Flex`.
//   فوضعُه في `actions` يرمي في كل بناء — ووقع في **موضعين** كتبتُهما في
//   اليوم نفسه: حوار تعارض الاستيراد وحوار تعديل سطر الكشف.
//
// ═══ لماذا فحصُ مصدر هنا واختبارُ ودجت في ع-٥٧؟ ═══
//   لأن هذا **نمطٌ نصّي قاطع**: `Spacer` داخل `actions` خطأٌ دائماً بلا
//   استثناء ولا يحتاج سياقاً — بخلاف `ref` بعد `pop` الذي يعتمد على **من
//   يملك** المرجع، وهو ما عجز النصّ عن تمييزه فأنتج إنذارات كاذبة.
//
// ⚠️ وأُثبت أنه **يفشل** عند زرع النمط قبل اعتماده — حارسٌ لا يفشل ليس
//   حارساً (درس ع-٥٦).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('⭐⭐⭐ لا `Spacer` داخل `AlertDialog.actions`', () {
    final offenders = <String>[];

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.g.dart'))
        .where((f) => !f.path.endsWith('.freezed.dart'))
        .toList();

    /// نافذة الفحص بعد `actions: [` — أطول قائمة أزرار في المشروع ستّة
    /// أزرار بتعليقاتها، وأربعون سطراً تسعها بفارق مريح.
    const window = 40;

    for (final file in files) {
      final lines = file.readAsLinesSync();

      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].split('//').first;
        if (!code.contains(RegExp(r'actions\s*:\s*\['))) continue;

        final end = (i + window) < lines.length ? i + window : lines.length;
        var depth = 0;
        for (var j = i; j < end; j++) {
          final next = lines[j].split('//').first;

          if (j > i && RegExp(r'\bSpacer\s*\(').hasMatch(next)) {
            offenders.add('${file.path}:${j + 1}  ${lines[j].trim()}');
          }

          depth += '['.allMatches(next).length - ']'.allMatches(next).length;
          // خرجنا من قائمة الإجراءات
          if (j > i && depth <= 0) break;
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: '`Spacer` داخل `AlertDialog.actions`:\n'
          '${offenders.join('\n')}\n\n'
          'الـ`actions` تُبنى في `OverflowBar` لا `Row`، فيرمي الإطار:\n'
          '  Incorrect use of ParentDataWidget\n\n'
          'والـ`OverflowBar` ترتّب الأزرار وتُنزلها سطراً حين تضيق —\n'
          'فلا حاجة إلى فاصلٍ يدوي. احذف `Spacer` ورتّب الأزرار بترتيبها.',
    );
  });
}
