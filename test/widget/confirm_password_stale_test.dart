// ─────────────────────────────────────────────────────────────────────────────
// confirm_password_stale_test.dart — «غير متطابقتين» في الضغطة الأولى
//
// **البلاغ (المالك 2026-10-15):** في الإعداد الأول يكتب كلمة مرور المدير
//   ثم تأكيدها ويضغط «التالي» ⇒ «كلمتا المرور غير متطابقتين». يضغط مرّة
//   ثانية بلا أي تغيير ⇒ تُقبَل.
//
// **السبب:** `InputValidators.confirmPassword(_passwordCtrl.text)` تُستدعى
//   داخل `build`، فتُغلَق الدالة على **نصّ كلمة المرور لحظة آخر بناء** —
//   والكتابة في الحقل لا تُعيد البناء. فالضغطة الأولى تقارن التأكيد بكلمة
//   مرور فارغة. و`setState` في `_onStepContinue` يُعيد البناء **بعد**
//   التحقّق، فتلتقط الضغطةُ الثانية النصّ الصحيح — فيبدو العطل عشوائياً.
//
// **الإصلاح في المدقّق نفسه:** يأخذ **دالةً تقرأ** كلمة المرور لا قيمتها،
//   فالقراءة تقع لحظة التحقّق. ولم يعد ممكناً كتابة النمط المعطوب: تمرير
//   `String` خطأ ترجمة.
//
// ⚠️ النمط هنا هو نمط `first_run_screen` حرفياً، وأُثبت أنه يفشل بالنسخة
//   القديمة من المدقّق قبل اعتماده.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/utils/input_validators.dart';

class _Harness extends StatefulWidget {
  const _Harness({required this.onResult});
  final void Function(bool) onResult;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              key: const Key('pw'),
              controller: _passwordCtrl,
              validator: InputValidators.password(minLength: 6),
            ),
            TextFormField(
              key: const Key('confirm'),
              controller: _confirmCtrl,
              // كما في first_run_screen: المدقّق يُبنى داخل build.
              validator:
                  InputValidators.confirmPassword(() => _passwordCtrl.text),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {}); // كما يفعل _onStepContinue قبل التحقّق
                widget.onResult(_formKey.currentState!.validate());
              },
              child: const Text('التالي'),
            ),
          ]),
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
      '⭐⭐⭐ كلمة مرور وتأكيدها متطابقان ⇒ تُقبَل من الضغطة الأولى',
      (tester) async {
    final results = <bool>[];
    await tester.pumpWidget(_Harness(onResult: results.add));

    await tester.enterText(find.byKey(const Key('pw')), 'Secret123');
    await tester.enterText(find.byKey(const Key('confirm')), 'Secret123');
    await tester.tap(find.text('التالي'));
    await tester.pump();

    expect(results, [true],
        reason: 'الضغطة الأولى رُفضت — المدقّق يقارن بكلمة مرور قديمة');
    expect(find.text('كلمتا المرور غير متطابقتين'), findsNothing);
  });

  testWidgets('وتغيير كلمة المرور بعد كتابة التأكيد يُكشَف فوراً',
      (tester) async {
    final results = <bool>[];
    await tester.pumpWidget(_Harness(onResult: results.add));

    await tester.enterText(find.byKey(const Key('pw')), 'Secret123');
    await tester.enterText(find.byKey(const Key('confirm')), 'Secret123');
    await tester.enterText(find.byKey(const Key('pw')), 'Other4567');
    await tester.tap(find.text('التالي'));
    await tester.pump();

    expect(results, [false]);
    expect(find.text('كلمتا المرور غير متطابقتين'), findsOneWidget);
  });
}
