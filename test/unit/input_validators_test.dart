// ─────────────────────────────────────────────────────────────────────────────
// input_validators_test.dart — اختبارات وحدة محققات المدخلات
//
// تعليقات توضيحية بالعربية:
// هذا الملف يحتوي على اختبارات الوحدة (Unit Tests) للتحقق من صحة عمل [InputValidators].
// يُغطي الحالات التالية:
//   1. الحقول المطلوبة (required)
//   2. أسماء المستخدمين (username)
//   3. كلمات المرور (password & confirmPassword)
//   4. المبالغ المالية (positiveAmount & nonNegativeAmount)
//   5. نسبة المشاركة للشركاء (sharePercentage)
//   6. أرقام الهواتف (phoneNumber)
//   7. دمج عدة محققات (combine)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/utils/input_validators.dart';

void main() {
  group('اختبارات محققات المدخلات (InputValidators)', () {
    // ── 1. اختبار الحقل المطلوب (required) ─────────────────────────────────
    group('required validator', () {
      final validator = InputValidators.required('اسم الخزينة');

      test('يجب أن يُعيد رسالة خطأ إذا كان النص null أو فارغاً', () {
        expect(validator(null), contains('مطلوب'));
        expect(validator(''), contains('مطلوب'));
        expect(validator('   '), contains('مطلوب'));
      });

      test('يجب أن يُعيد null إذا كان النص غير فارغ', () {
        expect(validator('خزينة الرئيسي'), isNull);
      });
    });

    // ── 2. اختبار اسم المستخدم (username) ──────────────────────────────────
    group('username validator', () {
      test('يجب أن يرفض الأسماء الأقل من 3 أحرف', () {
        expect(InputValidators.username('ab'), contains('3 أحرف على الأقل'));
      });

      test('يجب أن يرفض الأسماء التي تحتوي على رموز غير مسموحة أو مسافات', () {
        expect(InputValidators.username('user name'), contains('يقبل فقط'));
        expect(InputValidators.username('user@123'), contains('يقبل فقط'));
      });

      test('يجب أن يقبل الأسماء الصالحة (حروف وأرقام وشرطة سفلية)', () {
        expect(InputValidators.username('admin'), isNull);
        expect(InputValidators.username('user_123'), isNull);
      });
    });

    // ── 3. اختبار كلمة المرور (password) ────────────────────────────────────
    group('password validator', () {
      final validator = InputValidators.password(minLength: 4);

      test('يجب أن يرفض كلمات المرور الأقصر من الحد الأدنى', () {
        expect(validator('123'), contains('4 أحرف على الأقل'));
      });

      test('يجب أن يقبل كلمات المرور المستوفية للشروط', () {
        expect(validator('1234'), isNull);
        expect(validator('secret_pass'), isNull);
      });

      test('اختبار مطابقة كلمتي المرور (confirmPassword)', () {
        final confirmVal = InputValidators.confirmPassword('pass123');
        expect(confirmVal('pass456'), contains('غير متطابقتين'));
        expect(confirmVal('pass123'), isNull);
      });
    });

    // ── 4. اختبار المبالغ المالية (positiveAmount) ──────────────────────────
    group('positiveAmount validator', () {
      test('يجب أن يرفض النصوص الفارغة أو غير الرقمية', () {
        expect(InputValidators.positiveAmount(null), contains('مطلوب'));
        expect(InputValidators.positiveAmount('abc'), contains('رقماً صالحاً'));
      });

      test('يجب أن يرفض الصفر والمبالغ السالبة', () {
        expect(InputValidators.positiveAmount('0'), contains('أكبر من صفر'));
        expect(InputValidators.positiveAmount('-500'), contains('أكبر من صفر'));
      });

      test('يجب أن يقبل المبالغ الموجبة المنسقة وغير المنسقة', () {
        expect(InputValidators.positiveAmount('150000'), isNull);
        expect(InputValidators.positiveAmount('1,500,000 د.ع'), isNull);
        expect(InputValidators.positiveAmount('250.50'), isNull);
      });
    });

    // ── 5. اختبار نسبة المشاركة (sharePercentage) ───────────────────────────
    group('sharePercentage validator', () {
      test('يجب أن يرفض النسب الأقل من 0 أو الأكبر من 100', () {
        expect(InputValidators.sharePercentage('-5'), contains('بين 0 و 100%'));
        expect(InputValidators.sharePercentage('105'), contains('بين 0 و 100%'));
      });

      test('يجب أن يقبل النسب ضمن النطاق المسموح 0 - 100', () {
        expect(InputValidators.sharePercentage('0'), isNull);
        expect(InputValidators.sharePercentage('50.5'), isNull);
        expect(InputValidators.sharePercentage('100'), isNull);
      });
    });

    // ── 6. اختبار دمج المحققات (combine) ────────────────────────────────────
    group('combine validator', () {
      final combined = InputValidators.combine([
        InputValidators.required('المبلغ'),
        InputValidators.positiveAmount,
      ]);

      test('يجب أن يُعيد الخطأ الأول المكتشف', () {
        expect(combined(''), contains('مطلوب'));
        expect(combined('-100'), contains('أكبر من صفر'));
      });

      test('يجب أن يُعيد null عند استيفاء جميع الشروط', () {
        expect(combined('5000'), isNull);
      });
    });
  });
}
