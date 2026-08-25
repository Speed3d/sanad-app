// ─────────────────────────────────────────────────────────────────────────────
// payroll_calculator_test.dart — حرّاس حساب الرواتب (Schema v7)
//
// **لماذا هذا الملف بلا قاعدة بيانات؟**
//   `PayrollCalculator` منطق نقيّ عمداً، فاختباره لا يحتاج قاعدة ولا واجهة.
//   والنتيجة أن الحالات الحدّية — التي تُهمَل عادةً لأن تجهيزها مكلف — صارت
//   سطرين لكل واحدة: شباط · شهر ٣١ يوماً · تعيين في اليوم ٣١ · خصم يتجاوز
//   الراتب · دولار بلا سعر صرف.
//
// **ما يحرسه هذا الملف ليس كوداً بل قرارات مالية:**
//   ١. الشهر ثلاثون عرفاً — فلا يُنقَص راتب شباط
//   ٢. الأيام تُسقَط لا تُعدّ — فتتساوى معاملة شباط وتموز
//   ٣. لا رقم بلا مقابل بالدينار — فالدولار بلا سعر صرف يُرفض بصوت عالٍ
//   ٤. المسودة تحتمل السالب والتسديد يرفضه
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/services/payroll_calculator.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════
  // أيام العمل
  // ═══════════════════════════════════════════════════════════════════════

  group('أيام الشهر وأيام العمل', () {
    test('طول الشهر التقويمي يُحتسَب صحيحاً بما فيه شباط الكبيس', () {
      expect(PayrollCalculator.daysInMonth(2025, 2), 28);
      expect(PayrollCalculator.daysInMonth(2024, 2), 29, reason: 'سنة كبيسة');
      expect(PayrollCalculator.daysInMonth(2025, 4), 30);
      expect(PayrollCalculator.daysInMonth(2025, 12), 31,
          reason: 'كانون الأول يمرّ عبر الشهر ١٣ في الحساب');
    });

    test('الوضع الثابت يُعيد العدد المعتمد مهما كان الشهر', () {
      expect(
        PayrollCalculator.resolveWorkingDays(
            WorkingDaysModeDb.fixed, 30, 2025, 2),
        30,
      );
      expect(
        PayrollCalculator.resolveWorkingDays(
            WorkingDaysModeDb.fixed, 30, 2025, 12),
        30,
      );
    });

    test('الوضع التقويمي يتبع طول الشهر الفعلي', () {
      expect(
        PayrollCalculator.resolveWorkingDays(
            WorkingDaysModeDb.calendar, 30, 2025, 2),
        28,
      );
      expect(
        PayrollCalculator.resolveWorkingDays(
            WorkingDaysModeDb.calendar, 30, 2025, 12),
        31,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الأيام المستحقّة — أخطر دالة في الملف
  // ═══════════════════════════════════════════════════════════════════════

  group('الأيام المستحقّة', () {
    test('الموظف المستقرّ يأخذ الشهر كاملاً', () {
      final days = PayrollCalculator.eligibleDays(
        year: 2025,
        month: 6,
        workingDays: 30,
        hireDate: DateTime(2020, 1, 1),
      );
      expect(days, 30);
    });

    test('الموظف بلا تاريخ تعيين مسجَّل يأخذ الشهر كاملاً', () {
      // كثير من موظفي المالك مسجَّلون بلا تاريخ تعيين. معاملتهم كمن عُيِّن
      // اليوم كانت ستُنقص رواتبهم كلها بصمت.
      final days = PayrollCalculator.eligibleDays(
        year: 2025,
        month: 6,
        workingDays: 30,
      );
      expect(days, 30);
    });

    test('⭐ شباط لا يُنقص راتب من داوم الشهر كلّه', () {
      // العطل الذي وقع في DMS: العدّ كان يُعطي ٢٨ يوماً من ٣٠ فيُصرف
      // 28/30 من الراتب لمن داوم شباط كلّه.
      final days = PayrollCalculator.eligibleDays(
        year: 2025,
        month: 2,
        workingDays: 30,
        hireDate: DateTime(2020, 1, 1),
      );
      expect(days, 30, reason: 'الشهر ثلاثون عرفاً مهما كان طوله التقويمي');
    });

    test('⭐ الشهر ذو ٣١ يوماً لا يزيد الراتب أيضاً', () {
      final days = PayrollCalculator.eligibleDays(
        year: 2025,
        month: 12,
        workingDays: 30,
        hireDate: DateTime(2020, 1, 1),
      );
      expect(days, 30, reason: 'السقف يحمي من الأعلى كما يحمي الإسقاط من الأسفل');
    });

    test('⭐ من عُيِّن في منتصف الشهر يأخذ نصفه — في شباط وتموز سواءً', () {
      // جوهر «الإسقاط لا العدّ»: الجهد نفسه يُنتج الاستحقاق نفسه.
      final feb = PayrollCalculator.eligibleDays(
        year: 2025,
        month: 2,
        workingDays: 30,
        hireDate: DateTime(2025, 2, 16),
      );
      final jul = PayrollCalculator.eligibleDays(
        year: 2025,
        month: 7,
        workingDays: 30,
        hireDate: DateTime(2025, 7, 16),
      );
      expect(feb, 15);
      expect(jul, 15);
      expect(feb, jul, reason: 'العدّ كان يعطي ١٣ في شباط و١٦ في تموز');
    });

    test('من عُيِّن في اليوم ٣١ يأخذ يوماً واحداً لا صفراً', () {
      final days = PayrollCalculator.eligibleDays(
        year: 2025,
        month: 12,
        workingDays: 30,
        hireDate: DateTime(2025, 12, 31),
      );
      expect(days, 1, reason: 'اليوم ٣١ يُسقَط على اليوم ٣٠ لا خارج المدى');
    });

    test('من عُيِّن بعد نهاية الشهر لا يستحقّ شيئاً', () {
      final days = PayrollCalculator.eligibleDays(
        year: 2025,
        month: 2,
        workingDays: 30,
        hireDate: DateTime(2025, 3, 1),
      );
      expect(days, 0);
    });

    test('من أُنهيت خدمته قبل بداية الشهر لا يستحقّ شيئاً', () {
      final days = PayrollCalculator.eligibleDays(
        year: 2025,
        month: 6,
        workingDays: 30,
        hireDate: DateTime(2020, 1, 1),
        terminationDate: DateTime(2025, 5, 20),
      );
      expect(days, 0);
    });

    test('من أُنهيت خدمته منتصف الشهر يأخذ ما مضى منه', () {
      final days = PayrollCalculator.eligibleDays(
        year: 2025,
        month: 6,
        workingDays: 30,
        hireDate: DateTime(2020, 1, 1),
        terminationDate: DateTime(2025, 6, 10),
      );
      expect(days, 10);
    });

    test('⭐ من أُنهيت خدمته آخر يوم في شباط يأخذ الشهر كاملاً', () {
      // ٢٨ شباط هو آخر الشهر تقويمياً — فالخدمة كاملة، ولا يجوز أن يُحسب
      // ٢٨/٣٠ لمجرّد أن الشهر أقصر من أيام العمل المعتمدة.
      final days = PayrollCalculator.eligibleDays(
        year: 2025,
        month: 2,
        workingDays: 30,
        hireDate: DateTime(2020, 1, 1),
        terminationDate: DateTime(2025, 2, 28),
      );
      expect(days, 30);
    });

    test('التعيين والإنهاء في الشهر نفسه', () {
      final days = PayrollCalculator.eligibleDays(
        year: 2025,
        month: 6,
        workingDays: 30,
        hireDate: DateTime(2025, 6, 10),
        terminationDate: DateTime(2025, 6, 20),
      );
      expect(days, 11, reason: 'من اليوم ١٠ إلى ٢٠ ضمناً');
    });

    test('الوضع التقويمي يعود إلى الأيام الحقيقية بلا فرع خاص', () {
      final days = PayrollCalculator.eligibleDays(
        year: 2025,
        month: 2,
        workingDays: 28,
        hireDate: DateTime(2020, 1, 1),
      );
      expect(days, 28);
    });

    test('أيام عمل صفر تُعيد صفراً بلا رمي', () {
      expect(
        PayrollCalculator.eligibleDays(
            year: 2025, month: 6, workingDays: 0),
        0,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // خصم الغياب
  // ═══════════════════════════════════════════════════════════════════════

  group('خصم الغياب المقترَح', () {
    test('يوم غياب من شهر ثلاثيني = ثلث عُشر الراتب', () {
      final d = PayrollCalculator.suggestAbsenceDeduction(
        basicSalary: 600000,
        absenceDays: 1,
        workingDays: 30,
      );
      expect(d, 20000);
    });

    test('بلا غياب لا خصم', () {
      expect(
        PayrollCalculator.suggestAbsenceDeduction(
            basicSalary: 600000, absenceDays: 0, workingDays: 30),
        0,
      );
    });

    test('⭐ الغياب لا يتجاوز الشهر مهما أُدخل', () {
      // خطأ إدخال (٤٠ يوم غياب في شهر) كان سيُنتج خصماً أكبر من الراتب
      final d = PayrollCalculator.suggestAbsenceDeduction(
        basicSalary: 600000,
        absenceDays: 40,
        workingDays: 30,
      );
      expect(d, 600000, reason: 'السقف الراتب كلّه لا أكثر');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الصافي
  // ═══════════════════════════════════════════════════════════════════════

  group('صافي الراتب', () {
    test('شهر كامل بلا إضافات ولا خصومات = الراتب الأساسي', () {
      final net = PayrollCalculator.netSalary(
        basicSalary: 750000,
        eligibleDays: 30,
        workingDays: 30,
      );
      expect(net, 750000);
    });

    test('المكافأة تُضاف والخصومات تُطرح', () {
      final net = PayrollCalculator.netSalary(
        basicSalary: 600000,
        eligibleDays: 30,
        workingDays: 30,
        bonus: 50000,
        deduction: 20000,
        absenceDeduction: 20000,
        advanceRepayment: 100000,
      );
      expect(net, 510000, reason: '600 + 50 − 20 − 20 − 100 (بالألف)');
    });

    test('نصف شهر = نصف الراتب', () {
      final net = PayrollCalculator.netSalary(
        basicSalary: 600000,
        eligibleDays: 15,
        workingDays: 30,
      );
      expect(net, 300000);
    });

    test('⭐ الصافي قد يكون سالباً — والمسودة تحتمله', () {
      // الحساب يقول الحقيقة. حصرُ السالب في الصفر كان يُخفي خطأ إدخال.
      final net = PayrollCalculator.netSalary(
        basicSalary: 300000,
        eligibleDays: 30,
        workingDays: 30,
        deduction: 500000,
      );
      expect(net, -200000);
    });

    test('أيام عمل صفر ترمي بدل القسمة على صفر', () {
      expect(
        () => PayrollCalculator.netSalary(
            basicSalary: 100, eligibleDays: 0, workingDays: 0),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // التحويل إلى الدينار — قرار المالك الثالث
  // ═══════════════════════════════════════════════════════════════════════

  group('المقابل بالدينار', () {
    test('الدينار يمرّ كما هو ولا يحتاج سعر صرف', () {
      expect(PayrollCalculator.toIqd(750000, PayrollCurrency.iqd, null),
          750000);
    });

    test('الدولار يُحوَّل بسعر الشهر', () {
      expect(PayrollCalculator.toIqd(2000, PayrollCurrency.usd, 1320),
          2640000);
    });

    test('⭐ الدولار بلا سعر صرف يرمي — ولا يُعيد صفراً', () {
      // قرار المالك 2026-08-24: «لا يُحفَظ شيء إلا بمقابله بالدينار».
      // الصفر الصامت كان يُدخل راتب ٢٠٠٠$ إلى الدفاتر بصفر دينار.
      expect(
        () => PayrollCalculator.toIqd(2000, PayrollCurrency.usd, null),
        throwsA(isA<StateError>()),
      );
      expect(
        () => PayrollCalculator.toIqd(2000, PayrollCurrency.usd, 0),
        throwsA(isA<StateError>()),
      );
    });

    test('hasUsableRate تسبق الرمي فتُتيح للواجهة التحذير مبكّراً', () {
      expect(PayrollCalculator.hasUsableRate(PayrollCurrency.iqd, null), isTrue);
      expect(PayrollCalculator.hasUsableRate(PayrollCurrency.usd, null), isFalse);
      expect(PayrollCalculator.hasUsableRate(PayrollCurrency.usd, 1320), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // حرّاس التسديد
  // ═══════════════════════════════════════════════════════════════════════

  group('حرّاس التسديد', () {
    test('⭐ الصافي السالب يُرفض عند التسديد ويُسمّي الموظف', () {
      expect(
        () => PayrollCalculator.ensurePayable('أحمد علي', -50000),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'الرسالة تسمّي الموظف',
            contains('أحمد علي'),
          ),
        ),
      );
    });

    test('الصافي الموجب أو الصفر يمرّ', () {
      expect(() => PayrollCalculator.ensurePayable('علي', 0), returnsNormally);
      expect(
          () => PayrollCalculator.ensurePayable('علي', 1), returnsNormally);
    });

    test('⭐ كشف فيه دولار بلا سعر صرف لا يُسدَّد', () {
      expect(
        () => PayrollCalculator.ensureRateSet(
            hasForeignCurrency: true, rate: null),
        throwsA(isA<StateError>()),
      );
    });

    test('كشف كلّه بالدينار يُسدَّد بلا سعر صرف', () {
      expect(
        () => PayrollCalculator.ensureRateSet(
            hasForeignCurrency: false, rate: null),
        returnsNormally,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الحساب الكامل
  // ═══════════════════════════════════════════════════════════════════════

  group('الحساب الكامل لسطر', () {
    test('موظف بالدينار — شهر كامل', () {
      final r = PayrollCalculator.compute(
        year: 2025,
        month: 2,
        workingDays: 30,
        basicSalary: 600000,
        currency: PayrollCurrency.iqd,
        hireDate: DateTime(2020, 1, 1),
      );
      expect(r.eligibleDays, 30);
      expect(r.netSalary, 600000);
      expect(r.netSalaryIqd, 600000);
    });

    test('موظف بالدولار — الصافي بعملته والمقابل بالدينار', () {
      final r = PayrollCalculator.compute(
        year: 2025,
        month: 2,
        workingDays: 30,
        basicSalary: 2000,
        currency: PayrollCurrency.usd,
        exchangeRate: 1320,
        hireDate: DateTime(2020, 1, 1),
      );
      expect(r.netSalary, 2000, reason: 'الصافي يبقى بعملة الموظف');
      expect(r.netSalaryIqd, 2640000);
    });

    test('⭐ الأيام اليدوية تُحترَم ولا يُعاد حسابها من تاريخ التعيين', () {
      // الأيام تصل من ملف الإكسل الذي دقّقه المالك. إعادة حسابها فوقه
      // تعني أن ما راجعه بيده لا أثر له.
      final r = PayrollCalculator.compute(
        year: 2025,
        month: 2,
        workingDays: 30,
        basicSalary: 600000,
        currency: PayrollCurrency.iqd,
        hireDate: DateTime(2020, 1, 1),
        manualEligibleDays: 20,
      );
      expect(r.eligibleDays, 20);
      expect(r.netSalary, 400000);
    });

    test('⭐ خصم الغياب اليدوي يُصان من إعادة الحساب', () {
      final r = PayrollCalculator.compute(
        year: 2025,
        month: 2,
        workingDays: 30,
        basicSalary: 600000,
        currency: PayrollCurrency.iqd,
        hireDate: DateTime(2020, 1, 1),
        absenceDays: 3,
        manualAbsenceDeduction: 10000,
      );
      expect(r.absenceDeduction, 10000,
          reason: 'المقترَح ٦٠٬٠٠٠ لكن المحاسب اختار ١٠٬٠٠٠');
      expect(r.netSalary, 590000);
    });

    test('⭐ الغياب بلا تعديل يدوي يُطبَّق **بالأيام** لا بمبلغ', () {
      final r = PayrollCalculator.compute(
        year: 2025,
        month: 2,
        workingDays: 30,
        basicSalary: 600000,
        currency: PayrollCurrency.iqd,
        hireDate: DateTime(2020, 1, 1),
        absenceDays: 3,
      );
      expect(r.eligibleDays, 27, reason: '٣٠ ناقص ٣ أيام غياب');
      expect(r.absenceDeduction, 0,
          reason: 'الغياب خُصم بالأيام — خصمُه مبلغاً أيضاً تكرار');
      expect(r.netSalary, 540000);
    });

    // ═══════════════════════════════════════════════════════════════════
    // 🔴 حارس الخصم المزدوج — بلاغ المالك 2026-08-25
    // ═══════════════════════════════════════════════════════════════════
    //
    // ملف المحاسب يذكر **أيام العمل الصافية** و**أيام الغياب** معاً، وكلاهما
    // تعبيرٌ عن الواقعة نفسها. والحساب القديم كان يطبّق الاثنين فيخصم الغياب
    // مرّتين — وعلى ٤٧ موظفاً بلغ الفرق ٣٬٦٦١٬٦٦٧ د.ع في كشف واحد.

    test('⭐⭐ مثال المالك: أساسي ٣ مليون · داوم ٢٥ · غاب ٥ ⇒ ٢٬٥٠٠٬٠٠٠', () {
      final r = PayrollCalculator.compute(
        year: 2025,
        month: 5,
        workingDays: 30,
        basicSalary: 3000000,
        currency: PayrollCurrency.iqd,
        manualEligibleDays: 25, // عمود «أيام العمل» في الملف
        absenceDays: 5, // وعمود «أيام الغياب» في الملف نفسه
      );
      expect(r.netSalary, 2500000,
          reason: 'العمودان يصفان الواقعة نفسها — الخصم مرّة واحدة');
      expect(r.absenceDeduction, 0);
    });

    test('⭐ المسارات الثلاثة تُعطي الرقم نفسه', () {
      double net({int? days, int absence = 0, double? manualDeduction}) {
        return PayrollCalculator.compute(
          year: 2025,
          month: 5,
          workingDays: 30,
          basicSalary: 3000000,
          currency: PayrollCurrency.iqd,
          manualEligibleDays: days,
          absenceDays: absence,
          manualAbsenceDeduction: manualDeduction,
        ).netSalary;
      }

      expect(net(days: 25, absence: 5), 2500000, reason: 'الأيام + الغياب');
      expect(net(days: 25), 2500000, reason: 'الأيام وحدها');
      expect(net(absence: 5), 2500000, reason: 'الغياب وحده');
      expect(net(manualDeduction: 500000), 2500000, reason: 'مبلغ يدوي');
    });

    test('⭐ المبلغ اليدوي يُلغي خصم الأيام — لا يُجمع معه', () {
      final r = PayrollCalculator.compute(
        year: 2025,
        month: 5,
        workingDays: 30,
        basicSalary: 3000000,
        currency: PayrollCurrency.iqd,
        absenceDays: 5,
        manualAbsenceDeduction: 200000, // المالك خفّف الجزاء
      );
      expect(r.eligibleDays, 30, reason: 'الأيام كاملة حين يُختار المبلغ');
      expect(r.absenceDeduction, 200000);
      expect(r.netSalary, 2800000);
    });

    test('غياب أكثر من أيام الاستحقاق لا يجعل الصافي سالباً بالأيام', () {
      final r = PayrollCalculator.compute(
        year: 2025,
        month: 5,
        workingDays: 30,
        basicSalary: 3000000,
        currency: PayrollCurrency.iqd,
        absenceDays: 45,
      );
      expect(r.eligibleDays, 0);
      expect(r.netSalary, 0);
    });

    test('⭐ سطر بالدولار بلا سعر صرف يرمي عند الحساب لا عند التسديد', () {
      expect(
        () => PayrollCalculator.compute(
          year: 2025,
          month: 2,
          workingDays: 30,
          basicSalary: 2000,
          currency: PayrollCurrency.usd,
          hireDate: DateTime(2020, 1, 1),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('⭐ مجموع سطور مقرَّبة يساوي المجموع بالضبط', () {
      // المطابقة مع سطر السلفة تقارن مجموعين. فرقُ فلسٍ واحد من تراكم
      // الفاصلة العائمة يكفي لمنع اعتماد سلفة صحيحة.
      final salaries = [333333.33, 333333.33, 333333.34];
      var total = 0.0;
      for (final s in salaries) {
        final r = PayrollCalculator.compute(
          year: 2025,
          month: 3,
          workingDays: 30,
          basicSalary: s,
          currency: PayrollCurrency.iqd,
        );
        total += r.netSalaryIqd;
      }
      expect(total, closeTo(1000000, 0.01));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // أسماء الشهور
  // ═══════════════════════════════════════════════════════════════════════

  group('تسمية الشهر', () {
    test('الأسماء عراقية سريانية لا مصرية', () {
      expect(PayrollCalculator.arabicMonth(2), 'شباط');
      expect(PayrollCalculator.arabicMonth(7), 'تموز');
      expect(PayrollCalculator.arabicMonth(12), 'كانون الأول');
    });

    test('التسمية الكاملة تجمع الشهر والسنة', () {
      expect(PayrollCalculator.periodLabel(2025, 2), 'شباط 2025');
    });

    test('شهر خارج المدى لا يرمي — يُعيد رقمه', () {
      expect(PayrollCalculator.arabicMonth(0), '0');
      expect(PayrollCalculator.arabicMonth(13), '13');
    });
  });
}
