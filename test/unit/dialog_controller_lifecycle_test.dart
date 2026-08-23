// ─────────────────────────────────────────────────────────────────────────────
// dialog_controller_lifecycle_test.dart — حارس دورة حياة متحكّمات النصّ
//
// العطل الذي يمنع عودته (بلاغ المالك 2026-08-23):
//   إنشاء فترة مالية ثانية كان يُظهر شاشة حمراء:
//     'framework.dart': Failed assertion: '_dependents.isEmpty': is not true.
//
//   والسبب الحقيقي لم يكن هذا السطر بل خطأ سبقه:
//     «A TextEditingController was used after being disposed»
//   في fiscal_screen.dart — حقل الملاحظات في حوار إنشاء الفترة.
//
//   العلّة: النمط التالي كان مكرَّراً في **خمسة** مواضع:
//       final notesCtrl = TextEditingController();
//       await showDialog(...);
//       notesCtrl.dispose();     // ← هنا الخطأ
//
//   الـ await ينتهي لحظة استدعاء Navigator.pop، لا لحظة اختفاء الحوار. يبقى
//   الحوار في الشجرة ويُعاد بناؤه طوال أنيميشن الخروج (~200ms). وإعادة البناء
//   تقع فعلاً هنا لأن إنشاء الفترة يُحدِّث allPeriodsProvider فتُعاد بناء
//   الشجرة كلها. فيلمس الحقلُ متحكّماً ميتاً، ويتعطّل بناؤه، فلا تُلغي
//   الودجتات اشتراكها في الودجتات الوراثية عند التفكيك — ومن هنا جاءت
//   «_dependents.isEmpty» كعَرَض ثانوي للسبب الأول.
//
//   الحلّ المطبَّق: إزالة المتحكّم أصلاً واستعمال متغيّر نصّي مع
//   initialValue/onChanged — لا شيء يحتاج تخلّصاً فلا شيء يموت مبكراً.
//
// لماذا اختبار على **المصدر** لا على الواجهة؟
//   لأن إعادة إنتاج العطل في اختبار ودجت تعتمد على توقيت أنيميشن الخروج
//   وتصادفه مع إعادة البناء — فاختبار كهذا يمرّ أحياناً ويفشل أحياناً وهو
//   أسوأ من لا اختبار. أما النمط النصّي فقاطع: إمّا موجود أو لا.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('⭐ لا يُتخلَّص من متحكّم نصّي خارج State.dispose', () {
    final offenders = <String>[];

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.g.dart'))
        .where((f) => !f.path.endsWith('.freezed.dart'));

    // اسم متغيّر ينتهي بـ Ctrl أو Controller ثم .dispose()
    final disposeCall = RegExp(r'\b\w*(Ctrl|Controller)\.dispose\(\)');
    final disposeMethod = RegExp(r'void\s+dispose\s*\(\s*\)');

    for (final file in files) {
      final lines = file.readAsLinesSync();

      // تتبّع بسيط لعمق الأقواس لمعرفة هل نحن داخل جسم dispose()
      var depth = 0;
      var insideDispose = false;
      var disposeDepth = 0;

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];

        if (disposeMethod.hasMatch(line)) {
          insideDispose = true;
          disposeDepth = depth;
        }

        final opens = '{'.allMatches(line).length;
        final closes = '}'.allMatches(line).length;
        depth += opens - closes;

        if (insideDispose && closes > 0 && depth <= disposeDepth) {
          insideDispose = false;
        }

        if (!insideDispose && disposeCall.hasMatch(line)) {
          offenders.add('${file.path}:${i + 1}  ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'متحكّم نصّي يُتخلَّص منه خارج State.dispose:\n'
          '${offenders.join('\n')}\n\n'
          'إن كان هذا بعد showDialog فهو العطل نفسه: الحوار يبقى يُعاد بناؤه\n'
          'طوال أنيميشن خروجه بعد انتهاء الـ await، فيلمس متحكّماً ميتاً.\n'
          'استعمل متغيّراً نصّياً مع initialValue/onChanged، أو اجعل الحوار\n'
          'StatefulWidget يملك متحكّماته ويتخلّص منها في dispose().',
    );
  });
}
