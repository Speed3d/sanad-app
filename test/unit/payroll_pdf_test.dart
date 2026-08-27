// ─────────────────────────────────────────────────────────────────────────────
// payroll_pdf_test.dart — مستندات الرواتب المطبوعة (المرحلة ٤)
//
// **الدرس الذي وُلد منه هذا الملف** (ع-٠٥ — «العربي غير مفهوم»):
//   `company_identity_test` كان يتحقّق أن الناتج **ملف PDF صالح** فقط. وهو
//   صالح تماماً — ومع ذلك كان كل نصّ عريض فيه يُرسَم بـHelvetica-Bold التي
//   لا تحوي حرفاً عربياً واحداً. **الملف السليم شكلياً والفارغ معنىً يمرّ من
//   كل فحصٍ لا ينظر إلى محتواه.**
//
//   ولأن مستندات الرواتب الثلاثة تمرّ بمسار الخطوط نفسه، فهي تحتاج الحراسة
//   نفسها — وامتدادُها في `part` لا خدمةٌ ثانية هو ما يجعل ذلك المسار واحداً.
//
// **وما يمسكه أيضاً:** أن الكشف يُطبع **عرضياً**. خمسة عشر عموداً على ورقة
//   طولية تنضغط حتى تُقتطع الأسماء — وهو نفس أثر العطل الذي حجب أسماء
//   الموظفين في المشروع المرجعي DMS، لكن بسبب مختلف.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sales_management/core/services/payroll_print_data.dart';
import 'package:sales_management/core/services/pdf_service.dart';

void main() {
  /// تحميل خط من القرص — `rootBundle` لا يعمل خارج تطبيق حيّ
  pw.Font load(String name) => pw.Font.ttf(
        File('assets/fonts/$name').readAsBytesSync().buffer.asByteData(),
      );

  late PdfService service;

  setUp(() {
    service = PdfService(
      regular: load('Tajawal-Regular.ttf'),
      bold: load('Tajawal-Bold.ttf'),
    );
  });

  /// أسماء الخطوط المضمَّنة داخل ملف PDF
  Set<String> embeddedFonts(Uint8List pdf) {
    final text = String.fromCharCodes(pdf);
    return RegExp(r'/BaseFont\s*/([A-Za-z0-9+\-,._]+)')
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet();
  }

  /// عدد صفحات المستند — تُحصى من كائنات الصفحات في بنية الملف
  int pageCount(Uint8List pdf) {
    final text = String.fromCharCodes(pdf);
    return RegExp(r'/Type\s*/Page[^s]').allMatches(text).length;
  }

  bool isValidPdf(Uint8List pdf) =>
      String.fromCharCodes(pdf.take(4)) == '%PDF' && pdf.length > 1000;

  // ── بيانات نموذجية ─────────────────────────────────────────────────────

  PayrollSheetPrintRow row(
    int seq,
    String name, {
    String currency = 'IQD',
    double basic = 600000,
    double net = 600000,
    double netIqd = 600000,
    bool paid = false,
  }) =>
      PayrollSheetPrintRow(
        seq: seq,
        name: name,
        position: 'سائق',
        currency: currency,
        basicSalary: basic,
        eligibleDays: 30,
        workingDays: 30,
        absenceDays: 0,
        absenceDeduction: 0,
        bonus: 0,
        deduction: 0,
        advanceRepayment: 0,
        net: net,
        netIqd: netIqd,
        isPaid: paid,
      );

  PayrollSheetPrintData sheet({
    List<PayrollSheetPrintRow>? rows,
    bool withSignature = false,
    double fileTotal = 0,
    double? exchangeRate,
  }) {
    final list = rows ??
        [
          row(1, 'أحمد علي الجبوري'),
          row(2, 'سارة حسن عبد الله', net: 550000, netIqd: 550000, paid: true),
        ];
    return PayrollSheetPrintData(
      periodLabel: 'شباط 2026',
      workingDays: 30,
      exchangeRate: exchangeRate,
      isPosted: false,
      employeeCount: list.length,
      // 🔑 من `getTotals` في الإنتاج — يُمرَّر هنا كما يُمرَّر هناك
      totalIqd: list.fold<double>(0, (s, r) => s + r.netIqd),
      paidIqd: 550000,
      unpaidIqd: 600000,
      fileTotal: fileTotal,
      rows: list,
      withSignatureColumn: withSignature,
    );
  }

  SalarySlipPrintData slip({
    String currency = 'IQD',
    bool paid = true,
  }) =>
      SalarySlipPrintData(
        periodLabel: 'شباط 2026',
        employeeName: 'أحمد علي الجبوري',
        position: 'سائق',
        hireDate: DateTime(2023, 5, 1),
        currency: currency,
        basicSalary: currency == 'IQD' ? 600000 : 2000,
        eligibleDays: 28,
        workingDays: 30,
        absenceDays: 2,
        absenceDeduction: currency == 'IQD' ? 40000 : 133.33,
        bonus: currency == 'IQD' ? 50000 : 100,
        deduction: 0,
        advanceRepayment: currency == 'IQD' ? 100000 : 0,
        net: currency == 'IQD' ? 510000 : 1966.67,
        netIqd: currency == 'IQD' ? 510000 : 2950005,
        exchangeRate: currency == 'IQD' ? null : 1500,
        isPaid: paid,
        voucherNumber: paid ? 47 : null,
        paidAt: paid ? DateTime(2026, 3, 1) : null,
        treasuryName: paid ? 'خزنة البصرة' : null,
      );

  PayrollYearReportData yearReport() => PayrollYearReportData(
        year: 2026,
        months: [
          for (var m = 1; m <= 12; m++)
            PayrollYearMonth(
              month: m,
              periodId: m,
              employeeCount: 47,
              totalIqd: 62038334,
              paidIqd: m < 6 ? 62038334 : 0,
              unpaidIqd: m < 6 ? 0 : 62038334,
              isPosted: m < 6,
            ),
        ],
        treasuryShares: const [
          PayrollTreasuryShare(
            treasuryId: 1,
            treasuryName: 'الخزينة الرئيسية',
            employeeCount: 120,
            totalIqd: 200000000,
          ),
          PayrollTreasuryShare(
            treasuryId: 2,
            treasuryName: 'خزنة البصرة',
            employeeCount: 115,
            totalIqd: 110191670,
          ),
        ],
      );

  EmployeePayrollMonth reportMonth(int month, {bool paid = true}) =>
      EmployeePayrollMonth(
        year: 2026,
        month: month,
        periodId: month,
        currency: 'IQD',
        basicSalary: 600000,
        eligibleDays: 30,
        workingDays: 30,
        absenceDays: month.isEven ? 2 : 0,
        absenceDeduction: month.isEven ? 40000 : 0,
        bonus: 50000,
        deduction: 10000,
        advanceRepayment: 100000,
        net: month.isEven ? 500000 : 540000,
        netIqd: month.isEven ? 500000 : 540000,
        isPaid: paid,
        paidAt: paid ? DateTime(2026, month, 28) : null,
        paidFromTreasury: paid ? 'خزنة البصرة' : null,
        voucherNumber: paid ? 40 + month : null,
      );

  /// تقرير موظف واحد بـ[months] شهراً
  EmployeePayrollReportData employeeReport({int months = 12}) {
    final rows = [for (var m = 1; m <= months; m++) reportMonth(m)];
    return EmployeePayrollReportData(
      rangeLabel: 'كانون الثاني 2026 — كانون الأول 2026',
      employeeName: 'أحمد علي حسين',
      position: 'سائق',
      treasuryName: 'مشروع البصرة',
      months: rows,
      employees: const [],
      monthCount: rows.length,
      totalIqd: rows.fold<double>(0, (s, m) => s + m.netIqd),
      paidIqd: rows.fold<double>(0, (s, m) => s + (m.isPaid ? m.netIqd : 0)),
      bonusIqd: rows.fold<double>(0, (s, m) => s + m.bonus),
      deductionIqd:
          rows.fold<double>(0, (s, m) => s + m.deduction + m.absenceDeduction),
      advanceRepaymentIqd:
          rows.fold<double>(0, (s, m) => s + m.advanceRepayment),
    );
  }

  /// تقرير مجموعة موظفين
  EmployeePayrollReportData groupReport({int count = 25}) {
    final rows = [
      for (var i = 1; i <= count; i++)
        EmployeePayrollSummaryRow(
          employeeId: i,
          employeeName: 'موظف رقم $i',
          position: 'عامل',
          monthCount: 12,
          totalIqd: 6000000.0 + i,
          paidIqd: 5000000.0 + i,
          bonusIqd: 300000,
          deductionIqd: 120000,
          advanceRepaymentIqd: 900000,
        ),
    ];
    return EmployeePayrollReportData(
      rangeLabel: 'كانون الثاني 2026 — كانون الأول 2026',
      employeeName: null,
      position: null,
      treasuryName: 'مشروع البصرة',
      months: const [],
      employees: rows,
      monthCount: rows.fold<int>(0, (s, e) => s + e.monthCount),
      totalIqd: rows.fold<double>(0, (s, e) => s + e.totalIqd),
      paidIqd: rows.fold<double>(0, (s, e) => s + e.paidIqd),
      bonusIqd: rows.fold<double>(0, (s, e) => s + e.bonusIqd),
      deductionIqd: rows.fold<double>(0, (s, e) => s + e.deductionIqd),
      advanceRepaymentIqd:
          rows.fold<double>(0, (s, e) => s + e.advanceRepaymentIqd),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ١. الخطوط العربية — الحارس الأهم
  // ═══════════════════════════════════════════════════════════════════════

  group('الخط العربي في مستندات الرواتب', () {
    test('⭐⭐ كشف الشهر لا يُضمِّن Helvetica إطلاقاً', () async {
      final pdf = await service.generatePayrollSheet(sheet());
      final fonts = embeddedFonts(pdf);
      expect(fonts.any((f) => f.contains('Helvetica')), isFalse,
          reason: 'وجود Helvetica يعني نصّاً عربياً رُسم بخط بلا عربية.\n'
              'الخطوط المضمَّنة: $fonts');
      expect(fonts.any((f) => f.contains('Tajawal') && f.contains('Bold')),
          isTrue,
          reason: 'ترويسة الجدول وسطر المجموع عريضان — بلا Tajawal-Bold '
              'يخرجان فارغين');
    });

    test('⭐ إيصال الراتب لا يُضمِّن Helvetica', () async {
      final pdf = await service.generateSalarySlip(slip());
      expect(embeddedFonts(pdf).any((f) => f.contains('Helvetica')), isFalse);
    });

    test('⭐ تقرير السنة لا يُضمِّن Helvetica', () async {
      final pdf = await service.generatePayrollYearReport(yearReport());
      expect(embeddedFonts(pdf).any((f) => f.contains('Helvetica')), isFalse);
    });

    test('⭐ تقرير الموظف لا يُضمِّن Helvetica — بوضعَيه معاً', () async {
      for (final pdf in [
        await service.generateEmployeePayrollReport(employeeReport()),
        await service.generateEmployeePayrollReport(groupReport()),
      ]) {
        final fonts = embeddedFonts(pdf);
        expect(fonts.any((f) => f.contains('Helvetica')), isFalse,
            reason: 'أسماء الموظفين وترويسة الجدول عربية — '
                'الخطوط المضمَّنة: $fonts');
        expect(fonts.any((f) => f.contains('Tajawal') && f.contains('Bold')),
            isTrue,
            reason: 'سطر المجموع وشريط الإجماليات عريضان');
      }
    });

    test('ترويسة الشركة العربية لا تكسر الخطوط في أي مستند', () async {
      const header = PdfCompanyHeader(companyName: 'شركة سند للمقاولات العامة');
      for (final pdf in [
        await service.generatePayrollSheet(sheet(), header: header),
        await service.generateSalarySlip(slip(), header: header),
        await service.generatePayrollYearReport(yearReport(), header: header),
      ]) {
        expect(embeddedFonts(pdf).any((f) => f.contains('Helvetica')), isFalse);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٢. بنية الورقة
  // ═══════════════════════════════════════════════════════════════════════

  group('بنية كشف الشهر', () {
    test('⭐ يُطبع عرضياً — خمسة عشر عموداً لا تسع ورقة طولية', () async {
      final pdf = await service.generatePayrollSheet(sheet());
      final text = String.fromCharCodes(pdf);
      // A4 عرضيّ: العرض ٨٤١٫٨٩ والارتفاع ٥٩٥٫٢٨ — والطولي عكسهما
      final box = RegExp(r'/MediaBox\s*\[[^\]]*\]').firstMatch(text);
      expect(box, isNotNull, reason: 'لا حدود صفحة في الناتج؟');
      expect(box!.group(0), contains('841.88'),
          reason: 'الكشف على ورقة طولية تنضغط أعمدته حتى تُقتطع الأسماء.\n'
              'الحدود: ${box.group(0)}');
    });

    test('⭐⭐ كشف بخمسين موظفاً يمتدّ لأكثر من صفحة ولا يرمي', () async {
      // **حجم البيانات في الاختبار جزءٌ من الاختبار** (ع-٢٧): كشف المالك
      // الحقيقي فيه ٤٧ موظفاً، واختبارٌ بسطرين لا يمرّ بمسار تقسيم الصفحات
      // إطلاقاً.
      final rows = [
        for (var i = 1; i <= 50; i++) row(i, 'موظف رقم $i العراقي الطويل'),
      ];
      final pdf = await service.generatePayrollSheet(sheet(rows: rows));

      expect(isValidPdf(pdf), isTrue);
      expect(pageCount(pdf), greaterThan(1),
          reason: 'خمسون سطراً لا تسع صفحة واحدة — يجب أن تُقسَّم');
    });

    test('عمود التوقيع يُضيف عموداً ولا يُخرج الجدول عن الورقة', () async {
      // العرض نِسَبٌ لا بكسلات، فإضافة عمود تُضيّق البقية تلقائياً
      final withSig =
          await service.generatePayrollSheet(sheet(withSignature: true));
      final without = await service.generatePayrollSheet(sheet());

      expect(isValidPdf(withSig), isTrue);
      expect(withSig.length, greaterThan(without.length),
          reason: 'عمود إضافي يعني محتوى أكبر — لو تساوى الحجمان لما طُبع');
    });

    test('فرق مجموع الملف يُطبع على الورقة ولا يمنع التوليد', () async {
      // الورقة المؤرشفة تحمل الرقمين معاً، فالفرق يُكتشف بعد شهور أيضاً
      final data = sheet(fileTotal: 1200000);
      expect(data.fileTotalGap, isNotNull);
      expect(isValidPdf(await service.generatePayrollSheet(data)), isTrue);
    });

    test('مجموع ملف مطابق لا يُنتج تحذيراً — هامش الدينار', () async {
      final data = sheet(fileTotal: 1150000.4);
      expect(data.fileTotalGap, isNull,
          reason: 'ما دون الدينار ضجيجُ فاصلة عائمة لا فرقٌ حقيقي');
    });

    test('كشف بلا سطور يُنتج ورقة صالحة — الحارس في الواجهة لا هنا',
        () async {
      final pdf = await service.generatePayrollSheet(sheet(rows: []));
      expect(isValidPdf(pdf), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٣. الإيصال والتقرير
  // ═══════════════════════════════════════════════════════════════════════

  group('إيصال الراتب', () {
    test('الإيصال المسدَّد وغير المسدَّد كلاهما يُطبع', () async {
      expect(isValidPdf(await service.generateSalarySlip(slip())), isTrue);
      expect(isValidPdf(await service.generateSalarySlip(slip(paid: false))),
          isTrue);
    });

    test('⭐ راتب بالدولار يُطبع بالعملتين بلا استثناء', () async {
      final data = slip(currency: 'USD');
      expect(data.isForeign, isTrue);
      expect(isValidPdf(await service.generateSalarySlip(data)), isTrue);
    });

    test('صفحة واحدة — الإيصال قصاصة تُسلَّم لا تقرير', () async {
      final pdf = await service.generateSalarySlip(slip());
      expect(pageCount(pdf), 1);
    });
  });

  group('تقرير السنة', () {
    test('اثنا عشر شهراً وتوزيع الخزائن يُطبعان معاً', () async {
      final pdf = await service.generatePayrollYearReport(yearReport());
      expect(isValidPdf(pdf), isTrue);
    });

    test('سنة بلا خزائن مسدَّدة تُطبع بجدول الأشهر وحده', () async {
      final data = PayrollYearReportData(
        year: 2026,
        months: yearReport().months,
        treasuryShares: const [],
      );
      expect(isValidPdf(await service.generatePayrollYearReport(data)), isTrue);
    });

    test('⭐ إجماليات التقرير تُشتقّ من أشهره لا من مصدر ثالث', () async {
      final data = yearReport();
      expect(data.totalIqd, closeTo(12 * 62038334, 0.001));
      expect(data.paidIqd, closeTo(5 * 62038334, 0.001));
      expect(data.unpaidIqd, closeTo(7 * 62038334, 0.001));
      expect(data.postedMonthCount, 5);
    });
  });

  group('تقرير الموظف', () {
    test('⭐ تفصيل موظف يُطبع **عرضياً** — أربعة عشر عموداً', () async {
      final pdf = await service.generateEmployeePayrollReport(employeeReport());
      final box = RegExp(r'/MediaBox\s*\[[^\]]*\]')
          .firstMatch(String.fromCharCodes(pdf));
      expect(box, isNotNull);
      expect(box!.group(0), contains('841.88'),
          reason: 'ورقة طولية تضغط أربعة عشر عموداً حتى تُقتطع الأرقام.\n'
              'الحدود: ${box.group(0)}');
    });

    test('⭐ تقرير المجموعة يُطبع **طولياً** — ثمانية أعمدة تسعه', () async {
      final pdf = await service.generateEmployeePayrollReport(groupReport());
      final text = String.fromCharCodes(pdf);
      final box = RegExp(r'/MediaBox\s*\[[^\]]*\]').firstMatch(text);
      expect(box!.group(0), startsWith('/MediaBox[0 0 595'),
          reason: 'الحدود: ${box.group(0)}');
    });

    test('⭐⭐ مئة موظف يمتدّون لأكثر من صفحة ولا يرمون', () async {
      final pdf =
          await service.generateEmployeePayrollReport(groupReport(count: 100));
      expect(isValidPdf(pdf), isTrue);
      expect(pageCount(pdf), greaterThan(1),
          reason: 'جدول لا يتجاوز صفحة واحدة يعني أن سطوره اقتُطعت');
    });

    test('تقرير فارغ يُنتج ورقة صالحة — الحارس في الواجهة لا هنا', () async {
      const empty = EmployeePayrollReportData(
        rangeLabel: 'آب 2026 — آب 2026',
        employeeName: 'أحمد علي',
        position: '',
        treasuryName: null,
        months: [],
        employees: [],
        monthCount: 0,
        totalIqd: 0,
        paidIqd: 0,
        bonusIqd: 0,
        deductionIqd: 0,
        advanceRepaymentIqd: 0,
      );
      expect(isValidPdf(await service.generateEmployeePayrollReport(empty)),
          isTrue);
    });

    test('⭐ الإجماليات تُطبع كما وصلت — لا تُجمع في الورقة', () async {
      // الورقة تقرأ `totalIqd` من الكائن. لو جمعت سطورها بنفسها لصار في
      // النظام مجموعان لنفس السؤال — وهو ما ضرب المشروع المرجعي DMS.
      final data = employeeReport(months: 3);
      expect(data.totalIqd, closeTo(540000 + 500000 + 540000, 0.001));
      expect(data.unpaidIqd, closeTo(0, 0.001));
      expect(data.isSingleEmployee, isTrue);
      expect(groupReport().isSingleEmployee, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٤. الخطوط تُحمَّل مرة واحدة
  // ═══════════════════════════════════════════════════════════════════════

  test('الخطوط تُعاد استعمالها بين المستندات الثلاثة', () async {
    // بلا التخزين يُعاد تحليل ستين كيلوبايت من بيانات الخط عند كل طباعة
    final a = await service.generatePayrollSheet(sheet());
    final b = await service.generateSalarySlip(slip());
    expect(embeddedFonts(a), equals(embeddedFonts(b)));
  });
}
