// ─────────────────────────────────────────────────────────────────────────────
// payroll_import_test.dart — تحليل ملف الرواتب ومطابقة أسماء موظفيه
//
// **ما يحرسه هذا الملف قراران للمالك (2026-08-24):**
//   ٣. **لا يُحفَظ رقم بلا مقابله بالدينار** ⇒ الدولار بلا سعر صرف يُرفض
//      **عند الاستيراد** لا عند التسديد
//   ١٠+١١. **لا ربط صامت ولا إنشاء صامت** ⇒ كل غموض يُعرَض للبتّ، ولا رقم
//      موظف في ملفات المالك فالمطابقة بالاسم المُطبَّع وتاريخ التعيين
//
// والاسم العربي هشّ: «أحمد علي» و«احمد علي» و«أحمَد  علي» شخص واحد يكتبه
// ثلاثة محاسبين بثلاث طرق. المطابقة الحرفية تُنتج ثلاثة موظفين وتقسّم
// تاريخه الوظيفي بينهم.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/services/payroll_calculator.dart';
import 'package:sales_management/core/services/payroll_name_matcher.dart';
import 'package:sales_management/core/services/payroll_row_parser.dart';
import 'package:sales_management/core/utils/sheet_value_parser.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════
  // تطبيع الاسم العربي
  // ═══════════════════════════════════════════════════════════════════════

  group('تطبيع الاسم', () {
    test('⭐ أشكال الهمزة كلها اسم واحد', () {
      const forms = ['أحمد علي', 'احمد علي', 'إحمد علي', 'آحمد علي'];
      final normalized = forms.map(PayrollNameMatcher.normalize).toSet();
      expect(normalized, hasLength(1),
          reason: 'أربعة أشكال لشخص واحد — تركُها يُنتج أربعة موظفين');
    });

    test('التاء المربوطة والهاء سواء', () {
      expect(PayrollNameMatcher.sameName('فاطمة حسن', 'فاطمه حسن'), isTrue);
    });

    test('الألف المقصورة والياء سواء', () {
      expect(PayrollNameMatcher.sameName('يحيى كريم', 'يحيي كريم'), isTrue);
    });

    test('التشكيل والتطويل يُحذفان', () {
      expect(PayrollNameMatcher.sameName('أحمَد عليّ', 'احمد علي'), isTrue);
      expect(PayrollNameMatcher.sameName('محمـــد', 'محمد'), isTrue);
    });

    test('المسافات الزائدة تُضغط', () {
      expect(PayrollNameMatcher.sameName('أحمد  علي', ' احمد علي '), isTrue);
    });

    test('⭐ محرف اتجاه غير مرئي لا يكسر المطابقة', () {
      // يتسرّب من النسخ من مستندات عربية ولا يُرى في أي محرّر
      expect(
        PayrollNameMatcher.sameName('أحمد‏علي'.replaceAll('‏', ' '),
            'احمد علي'),
        isTrue,
      );
      expect(PayrollNameMatcher.normalize('احمد​علي'), 'احمد علي');
    });

    test('⭐ «ال» التعريف لا تُحذف — «العلي» ليس «علي»', () {
      expect(PayrollNameMatcher.sameName('علي حسن', 'العلي حسن'), isFalse);
    });

    test('⭐ الاسم لا يُختصر — الإخوة لا يُدمجون', () {
      expect(
        PayrollNameMatcher.sameName('أحمد علي حسن', 'أحمد علي كريم'),
        isFalse,
        reason: 'اختصار الاسم لجزأين كان يدمج إخوةً',
      );
    });

    test('الفارغ يبقى فارغاً', () {
      expect(PayrollNameMatcher.normalize('   '), '');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // مطابقة الموظف
  // ═══════════════════════════════════════════════════════════════════════

  group('مطابقة الموظف', () {
    final ahmed = PayrollMatchCandidate(
      employeeId: 1,
      fullName: 'أحمد علي',
      hireDate: DateTime(2020, 3, 1),
    );
    final sara = PayrollMatchCandidate(
      employeeId: 2,
      fullName: 'سارة حسن',
      hireDate: DateTime(2021, 5, 10),
    );

    test('🟢 اسم مطابق وتاريخ تعيين مطابق', () {
      final m = PayrollNameMatcher.match(
        fileName: 'احمد علي',
        fileHireDate: DateTime(2020, 3, 1),
        employees: [ahmed, sara],
      );
      expect(m.isMatched, isTrue);
      expect(m.employee!.employeeId, 1);
    });

    test('🟢 الملف بلا تاريخ تعيين ومرشّح واحد ⇒ مطابَق', () {
      final m = PayrollNameMatcher.match(
        fileName: 'أحمد علي',
        employees: [ahmed, sara],
      );
      expect(m.isMatched, isTrue);
    });

    test('🟢 المسجَّل بلا تاريخ تعيين ⇒ لا تعارض', () {
      final m = PayrollNameMatcher.match(
        fileName: 'كريم جبار',
        fileHireDate: DateTime(2023, 1, 1),
        employees: [
          const PayrollMatchCandidate(employeeId: 9, fullName: 'كريم جبار'),
        ],
      );
      expect(m.isMatched, isTrue);
    });

    test('🔵 اسم غير موجود ⇒ جديد', () {
      final m = PayrollNameMatcher.match(
        fileName: 'حسن محمود',
        employees: [ahmed, sara],
      );
      expect(m.isNew, isTrue);
      expect(m.employee, isNull);
    });

    test('⭐🟠 تاريخ تعيين مختلف ⇒ غامض لا مطابَق', () {
      // شخصان بالاسم نفسه أحدهما عُيِّن لاحقاً — الربط الصامت كان يُدخل
      // راتب أحدهما في سجلّ الآخر
      final m = PayrollNameMatcher.match(
        fileName: 'أحمد علي',
        fileHireDate: DateTime(2024, 9, 1),
        employees: [ahmed],
      );
      expect(m.isAmbiguous, isTrue);
      expect(m.reason, contains('تاريخ تعيين مختلف'));
    });

    test('⭐🟠 موظفان بالاسم نفسه ⇒ غامض', () {
      final twin = PayrollMatchCandidate(
        employeeId: 3,
        fullName: 'أحمد علي',
        hireDate: DateTime(2022, 1, 1),
      );
      final m = PayrollNameMatcher.match(
        fileName: 'احمد علي',
        employees: [ahmed, twin],
      );
      expect(m.isAmbiguous, isTrue);
      expect(m.candidates, hasLength(2));
    });

    test('⭐ تاريخ التعيين يحسم بين متشابهي الاسم', () {
      final twin = PayrollMatchCandidate(
        employeeId: 3,
        fullName: 'أحمد علي',
        hireDate: DateTime(2022, 1, 1),
      );
      final m = PayrollNameMatcher.match(
        fileName: 'احمد علي',
        fileHireDate: DateTime(2022, 1, 1),
        employees: [ahmed, twin],
      );
      expect(m.isMatched, isTrue);
      expect(m.employee!.employeeId, 3);
    });

    test('اسم فارغ ⇒ غامض لا جديد — لا يُنشأ موظف بلا اسم', () {
      final m = PayrollNameMatcher.match(fileName: '  ', employees: [ahmed]);
      expect(m.isAmbiguous, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // تحليل قيم الخلايا
  // ═══════════════════════════════════════════════════════════════════════

  group('قيم الخلايا', () {
    test('الفاصلة العربية واللاتينية سواء', () {
      expect(SheetValueParser.parseAmount('1,200,000'), 1200000);
      expect(SheetValueParser.parseAmount('1،200،000'), 1200000);
    });

    test('المبلغ الموجب فقط في parseAmount', () {
      expect(SheetValueParser.parseAmount('0'), isNull);
      expect(SheetValueParser.parseAmount('-5'), isNull);
      expect(SheetValueParser.parseAmount('نص'), isNull);
    });

    test('⭐ parseSignedAmount تقبل الصفر — «خصم = 0» قيمة لا خانة فارغة', () {
      expect(SheetValueParser.parseSignedAmount('0'), 0);
      expect(SheetValueParser.parseSignedAmount(''), isNull);
    });

    test('⭐ الأرقام العربية-الهندية تُقرأ — لا تبدو «غير صالحة»', () {
      // ملفات تُكتَب على أجهزة معرَّبة تحمل ١٥٠٠ بدل 1500
      expect(SheetValueParser.parseAmount('٦٠٠٠٠٠'), 600000);
      expect(SheetValueParser.parseAmount('١,٢٠٠,٠٠٠'), 1200000);
    });

    test('⭐ رمز العملة داخل الرقم لا يُفسده', () {
      expect(SheetValueParser.parseAmount(r'1500$'), 1500);
      expect(SheetValueParser.parseAmount('600000 دينار'), 600000);
    });

    test('الفاصلة العشرية العربية تصير نقطة', () {
      expect(SheetValueParser.parseAmount('1500٫5'), 1500.5);
    });

    test('التاريخ بصيغتيه', () {
      expect(SheetValueParser.parseDate('2025/03/01'), DateTime(2025, 3, 1));
      expect(SheetValueParser.parseDate('01-03-2025'), DateTime(2025, 3, 1));
      expect(SheetValueParser.parseDate('2025/02/31'), isNull,
          reason: 'تاريخ مستحيل يُرفض ولا يُصحَّح صامتاً');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // تحليل صف الراتب
  // ═══════════════════════════════════════════════════════════════════════

  group('تحليل صف الراتب', () {
    ({ParsedPayrollRow? row, String? error}) parse({
      String name = 'أحمد علي',
      String salary = '600000',
      String currency = '',
      String rate = '',
      String position = 'سائق',
      String hire = '2020/03/01',
      String days = '',
      String bonus = '',
      String deduction = '',
      String absence = '',
      String net = '',
    }) {
      return PayrollRowParser.parseRow(
        rowNumber: 1,
        rowLabel: 'صف ٢',
        nameRaw: name,
        salaryRaw: salary,
        currencyRaw: currency,
        exchangeRateRaw: rate,
        positionRaw: position,
        hireDateRaw: hire,
        eligibleDaysRaw: days,
        bonusRaw: bonus,
        deductionRaw: deduction,
        absenceDaysRaw: absence,
        netAmountRaw: net,
      );
    }

    test('صف سليم بالدينار', () {
      final r = parse().row!;
      expect(r.employeeName, 'أحمد علي');
      expect(r.position, 'سائق');
      expect(r.basicSalary, 600000);
      expect(r.currency, PayrollCurrency.iqd);
      expect(r.hireDate, DateTime(2020, 3, 1));
    });

    test('صف فارغ تماماً يُتجاهَل بلا خطأ', () {
      final r = parse(name: '', salary: '', position: '', hire: '');
      expect(r.row, isNull);
      expect(r.error, isNull, reason: 'الصفوف الفاصلة لا تُغرق المالك بأخطاء');
    });

    test('اسم فارغ مع بيانات ⇒ خطأ', () {
      final r = parse(name: '');
      expect(r.row, isNull);
      expect(r.error, contains('اسم الموظف فارغ'));
    });

    test('راتب غير صالح ⇒ خطأ يسمّي الموظف', () {
      final r = parse(salary: 'غير معروف');
      expect(r.error, contains('أحمد علي'));
      expect(r.error, contains('صف ٢'));
    });

    test('⭐ الدولار بلا سعر صرف يُرفض عند الاستيراد', () {
      final r = parse(salary: '2000', currency: 'دولار');
      expect(r.row, isNull);
      expect(r.error, contains('بالدولار بلا سعر صرف'));
    });

    test('الدولار مع سعر صرف يمرّ', () {
      final r = parse(salary: '2000', currency: 'USD', rate: '1320').row!;
      expect(r.currency, PayrollCurrency.usd);
      expect(r.exchangeRate, 1320);
    });

    test('⭐ علامة الدولار داخل خانة الراتب تُكشَف بلا عمود عملة', () {
      // «1500$» بلا عمود عملة كان يُسجَّل ١٥٠٠ ديناراً
      final r = parse(salary: r'1500$', rate: '1320').row!;
      expect(r.currency, PayrollCurrency.usd);
    });

    test('عمود العملة «دينار» يغلب علامة داخل النصّ', () {
      final r = parse(salary: '600000', currency: 'دينار').row!;
      expect(r.currency, PayrollCurrency.iqd);
    });

    test('المكافأة والخصم والغياب تُقرأ', () {
      final r =
          parse(bonus: '50,000', deduction: '20000', absence: '3').row!;
      expect(r.bonus, 50000);
      expect(r.deduction, 20000);
      expect(r.absenceDays, 3);
    });

    test('⭐ الصافي المذكور يُحفَظ للمقارنة لا للحساب', () {
      final r = parse(net: '630000').row!;
      expect(r.fileNetAmount, 630000);
    });

    test('أيام عمل مستحيلة تُرفض', () {
      final r = parse(days: '45');
      expect(r.error, contains('أكبر من طول أي شهر'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // مقارنة الصافي المحسوب بالمذكور
  // ═══════════════════════════════════════════════════════════════════════

  group('مطابقة الصافي مع الملف', () {
    test('التطابق لا يُنتج رسالة', () {
      expect(
        PayrollRowParser.describeNetMismatch(
            employeeName: 'أحمد', fileNet: 600000, computedNet: 600000),
        isNull,
      );
    });

    test('ملف بلا صافي مذكور لا يُنتج رسالة', () {
      expect(
        PayrollRowParser.describeNetMismatch(
            employeeName: 'أحمد', fileNet: null, computedNet: 600000),
        isNull,
      );
    });

    test('⭐ الفرق يُوصَف ويُسمّى صاحبه', () {
      final msg = PayrollRowParser.describeNetMismatch(
        employeeName: 'أحمد علي',
        fileNet: 600000,
        computedNet: 540000,
      );
      expect(msg, contains('أحمد علي'));
      expect(msg, contains('أقل'));
      expect(msg, contains('60000'));
    });

    test('فرق أصغر من فلس يُتجاهَل — ضجيج فاصلة عائمة', () {
      expect(
        PayrollRowParser.describeNetMismatch(
            employeeName: 'أحمد', fileNet: 600000, computedNet: 600000.004),
        isNull,
      );
    });
  });
}
