// ─────────────────────────────────────────────────────────────────────────────
// payroll_direct_pay_test.dart — صرف راتب موظف واحد داخل كشف شهره
//
// **التغيير الذي يحرسه** (قرار المالك 2026-08-26):
//   كان «صرف راتب» من بطاقة الموظف يكتب سطراً **بلا كشف**، فيصير في النظام
//   طريقان لتسجيل راتب: واحد داخل الكشوف وآخر خارجها. وأي تقرير يقرأ أحدهما
//   وينسى الآخر يُخفي مالاً خرج فعلاً — وهو الصنف نفسه من العطل الذي ضرب
//   المشروع المرجعي DMS (ع-٢٨).
//
//   الآن يمرّ الصرف المباشر بـ`PayrollRepository.paySingleEmployee`، فينتسب
//   الراتب إلى كشف شهره ويظهر في كل تقرير.
//
// **وما يحرسه تحديداً:**
//   • الراتب المباشر يصير **سطراً في كشف شهره** لا سطراً يتيماً
//   • **لا يُصرف مرّتين** — والرفض يسمّي السند والتاريخ
//   • سطرٌ قائم غير مسدَّد **يُسدَّد هو نفسه** ولا يُنشأ ثانٍ
//   • كشفٌ مُسدَّد يقبل موظفاً متأخراً **بلا أن يُدهَس تاريخ اعتماده**
//   • الحرّاس: العملة · السنة المالية · الرصيد · الصافي الموجب
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/services/payroll_calculator.dart';
import 'package:sales_management/core/services/payroll_row_parser.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/payroll_repository.dart';

void main() {
  late AppDatabase db;
  late PayrollRepository repo;
  late int fiscalId;
  late int treasuryId;
  late int ahmedId;
  late int saraId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PayrollRepository(db);

    fiscalId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2025',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31, 23, 59, 59),
      ),
    );
    treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );

    // تمويل الخزينة — وإلا رفض حارس الرصيد كل صرف
    final n = await db.fiscalPeriodsDao.getNextVoucherNumber(
      fiscalPeriodId: fiscalId,
      voucherType: 'kabd',
    );
    await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: n,
        voucherType: 'kabd',
        treasuryId: treasuryId,
        fiscalPeriodId: fiscalId,
        amount: 10000000,
        voucherDate: DateTime(2025, 1, 5),
      ),
    );

    ahmedId = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'أحمد علي',
        position: const Value('سائق'),
        basicSalary: const Value(600000),
        treasuryId: Value(treasuryId),
      ),
    );
    saraId = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'سارة حسن',
        basicSalary: const Value(500000),
      ),
    );
  });

  tearDown(() async => db.close());

  Future<double> balance() async {
    final row = await db.treasuriesDao.getTreasuryBalance(treasuryId);
    return row?.balanceIqd ?? 0;
  }

  Future<PaySingleSalaryResult> payAhmed({
    int year = 2025,
    int month = 8,
    double basic = 600000,
    double additions = 0,
    double deductions = 0,
    DateTime? date,
  }) {
    return repo.paySingleEmployee(
      employeeId: ahmedId,
      year: year,
      month: month,
      treasuryId: treasuryId,
      basicSalary: basic,
      additions: additions,
      deductions: deductions,
      paymentDate: date ?? DateTime(2025, 9, 1),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ١. التوحيد — الراتب المباشر داخل كشفه
  // ═══════════════════════════════════════════════════════════════════════

  group('الصرف المباشر ينتسب إلى كشف شهره', () {
    test('⭐⭐ يُنشئ كشف الشهر ويكتب سطره فيه — لا سطر يتيم', () async {
      final result = await payAhmed();

      final period = await db.payrollDao.getPeriodForMonth(2025, 8);
      expect(period, isNotNull, reason: 'كشف آب يجب أن يُنشأ تلقائياً');
      expect(result.periodId, period!.id);

      final entries = await db.payrollDao.getEntries(period.id);
      expect(entries.length, 1);
      expect(entries.single.payrollPeriodId, period.id,
          reason: 'بلا انتساب يعود الراتب خارج كل تقرير — وهو ع-٢٨');
      expect(entries.single.paymentStatus, PayrollPaymentStatusDb.paid);
      expect(entries.single.netAmountIqd, 600000);
      expect(entries.single.snapshotName, 'أحمد علي');
      expect(entries.single.snapshotPosition, 'سائق');
      expect(entries.single.treasuryId, treasuryId);
    });

    test('⭐ يظهر في تقرير السنة ولا يُحتسب «خارج الكشوف»', () async {
      await payAhmed();

      final report = await repo.buildYearReport(2025);
      expect(report.months.length, 1);
      expect(report.months.single.month, 8);
      expect(report.months.single.paidIqd, closeTo(600000, 0.001));

      final out = await repo.getOutOfSheetSalaries(2025);
      expect(out.count, 0,
          reason: 'بعد التوحيد لا يبقى راتبٌ خارج الكشوف');
    });

    test('الكشف يصير مُسدَّداً لأن لا سطر مستحقّاً فيه', () async {
      final r = await payAhmed();
      final period = await db.payrollDao.getPeriodById(r.periodId);
      expect(period!.status, PayrollStatusDb.posted);
    });

    test('⭐ السند باسم الموظف لا «١ موظفاً»', () async {
      final r = await payAhmed();
      final voucher = await db.vouchersDao.getVoucherById(r.voucherId);
      expect(voucher!.personName, 'أحمد علي');
      expect(voucher.itemType, 'راتب');
      expect(voucher.amount, 600000);
    });

    test('⭐ الخزينة تنقص بالمبلغ **مرّة واحدة**', () async {
      final before = await balance();
      await payAhmed(basic: 600000, additions: 50000, deductions: 20000);
      expect(await balance(), closeTo(before - 630000, 0.001));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٢. لا صرف مرّتين
  // ═══════════════════════════════════════════════════════════════════════

  group('منع صرف راتب الشهر مرّتين', () {
    test('⭐⭐ الصرف الثاني يُرفض ويسمّي السند والتاريخ', () async {
      final first = await payAhmed(date: DateTime(2025, 9, 1));

      await expectLater(
        payAhmed(date: DateTime(2025, 9, 20)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          allOf(
            contains('أحمد علي'),
            contains('آب 2025'),
            contains('مصروفٌ سلفاً'),
            contains('${first.voucherNumber}'),
          ),
        )),
      );
    });

    test('الرفض لا يترك أثراً — لا سند ولا نقص رصيد', () async {
      await payAhmed();
      final balanceAfterFirst = await balance();
      final vouchersAfterFirst =
          (await db.vouchersDao.getAllVouchers()).length;

      await expectLater(payAhmed(), throwsA(isA<StateError>()));

      expect(await balance(), closeTo(balanceAfterFirst, 0.001));
      expect((await db.vouchersDao.getAllVouchers()).length,
          vouchersAfterFirst);
    });

    test('الشهر التالي يُصرف عادياً — المنع للشهر نفسه لا للموظف', () async {
      await payAhmed(month: 8);
      final r = await payAhmed(month: 9, date: DateTime(2025, 10, 1));
      expect(r.periodLabel, 'أيلول 2025');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٣. الالتقاء بكشف مستورَد
  // ═══════════════════════════════════════════════════════════════════════

  group('الالتقاء بسطر قائم في الكشف', () {
    Future<int> importAhmed({double salary = 600000}) async {
      final periodId = await repo.createOrGetPeriod(year: 2025, month: 8);
      await repo.importRows(
        periodId: periodId,
        rows: [
          ResolvedPayrollRow(
            employeeId: ahmedId,
            row: ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'أحمد علي',
              basicSalary: salary,
            ),
          ),
        ],
      );
      return periodId;
    }

    test('⭐⭐ سطرٌ مستورَد غير مسدَّد **يُسدَّد هو نفسه** — لا سطر ثانٍ',
        () async {
      final periodId = await importAhmed();
      final before = await db.payrollDao.getEntries(periodId);
      expect(before.length, 1);
      expect(before.single.paymentStatus, PayrollPaymentStatusDb.unpaid);

      final r = await payAhmed();

      final after = await db.payrollDao.getEntries(periodId);
      expect(after.length, 1,
          reason: 'سطرٌ ثانٍ للموظف نفسه يعني راتباً مضاعفاً في كل تقرير');
      expect(after.single.id, before.single.id);
      expect(after.single.paymentStatus, PayrollPaymentStatusDb.paid);
      expect(r.joinedExistingEntry, isTrue);
      expect(r.periodId, periodId);
    });

    test('المبلغ المُدخَل في الحوار هو ما يُصرف فعلاً', () async {
      await importAhmed(salary: 600000);
      await payAhmed(basic: 700000);

      final entries = await db.payrollDao.getEntries(
        (await db.payrollDao.getPeriodForMonth(2025, 8))!.id,
      );
      expect(entries.single.netAmountIqd, 700000);
      expect(await balance(), closeTo(10000000 - 700000, 0.001));
    });

    test('استيراد الملف **بعد** الصرف المباشر لا يمسّ السطر المسدَّد',
        () async {
      await payAhmed(basic: 700000);
      final periodId = (await db.payrollDao.getPeriodForMonth(2025, 8))!.id;

      // الملف يقول ٦٠٠٬٠٠٠ — والمصروف فعلاً ٧٠٠٬٠٠٠
      await repo.importRows(
        periodId: periodId,
        rows: [
          ResolvedPayrollRow(
            employeeId: ahmedId,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'أحمد علي',
              basicSalary: 600000,
            ),
          ),
        ],
      );

      final entries = await db.payrollDao.getEntries(periodId);
      expect(entries.single.netAmountIqd, 700000,
          reason: 'المال خرج بهذا الرقم — لا يُعاد حسابه من ملف');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٤. الكشف المُسدَّد يقبل موظفاً متأخراً (قرار المالك: الخيار أ)
  // ═══════════════════════════════════════════════════════════════════════

  group('الإضافة إلى كشف مُسدَّد', () {
    Future<int> postedSheetWithSara() async {
      final periodId = await repo.createOrGetPeriod(year: 2025, month: 8);
      await repo.importRows(
        periodId: periodId,
        rows: [
          ResolvedPayrollRow(
            employeeId: saraId,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'سارة حسن',
              basicSalary: 500000,
            ),
          ),
        ],
      );
      final entries = await db.payrollDao.getEntries(periodId);
      await repo.payEntries(
        periodId: periodId,
        entryIds: [entries.single.id],
        treasuryId: treasuryId,
        paymentDate: DateTime(2025, 9, 1),
      );
      return periodId;
    }

    test('⭐⭐ الموظف المتأخّر يُضاف ويبقى الكشف مكتملاً', () async {
      final periodId = await postedSheetWithSara();
      expect((await db.payrollDao.getPeriodById(periodId))!.status,
          PayrollStatusDb.posted);

      final r = await payAhmed(date: DateTime(2025, 9, 20));

      expect(r.addedToPostedSheet, isTrue);
      expect(r.periodId, periodId);

      final period = await db.payrollDao.getPeriodById(periodId);
      expect(period!.status, PayrollStatusDb.posted,
          reason: 'أُضيف سطرٌ **مسدَّد** فلا يبقى في الكشف مستحقّ');

      final entries = await db.payrollDao.getEntries(periodId);
      expect(entries.length, 2);
    });

    test('⭐⭐ تاريخ الاعتماد الأصلي **لا يُدهَس**', () async {
      final periodId = await postedSheetWithSara();
      final originalPostedAt =
          (await db.payrollDao.getPeriodById(periodId))!.postedAt;
      expect(originalPostedAt, isNotNull);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await payAhmed(date: DateTime(2025, 9, 20));

      final after = await db.payrollDao.getPeriodById(periodId);
      expect(after!.postedAt, originalPostedAt,
          reason: 'دهسُه يجعل كشفاً اعتُمد في أيلول يبدو كأنه اعتُمد اليوم');
    });

    test('⭐ السطر المتأخّر يُعلَّم «أُضيف بعد الاعتماد» في ورقة الطباعة',
        () async {
      final periodId = await postedSheetWithSara();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await payAhmed(date: DateTime(2025, 9, 20));

      final data = await repo.buildSheetPrintData(periodId);
      final sara = data.rows.firstWhere((r) => r.name == 'سارة حسن');
      final ahmed = data.rows.firstWhere((r) => r.name == 'أحمد علي');

      expect(sara.addedAfterPosting, isFalse);
      expect(ahmed.addedAfterPosting, isTrue,
          reason: 'ورقتان بمجموعين مختلفين تبدوان تلاعباً ما لم يُقل السبب');
    });

    test('المجموع يزيد بالمبلغ المضاف — والدفتر يقول الحقيقة', () async {
      final periodId = await postedSheetWithSara();
      await payAhmed();

      final totals = await db.payrollDao.getTotals(periodId);
      expect(totals.totalIqd, closeTo(1100000, 0.001));
      expect(totals.unpaidIqd, closeTo(0, 0.001));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٥. الحرّاس
  // ═══════════════════════════════════════════════════════════════════════

  group('حرّاس الصرف المباشر', () {
    test('⭐ شهر بلا سنة مالية يُرفض — قرار المالك 2026-08-26', () async {
      await expectLater(
        payAhmed(year: 2030, month: 5),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          allOf(contains('لا توجد سنة مالية'), contains('أيار 2030')),
        )),
      );
    });

    test('⭐ السنة المُقفَلة تُنتج رسالة مختلفة تسمّيها', () async {
      await db.fiscalPeriodsDao.closePeriod(fiscalId, 1);
      await expectLater(
        payAhmed(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          allOf(contains('مُقفَلة'), contains('2025')),
        )),
      );
    });

    test('⭐ موظف براتب بالدولار يُوجَّه إلى كشف الرواتب', () async {
      final john = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
          fullName: 'جون سميث',
          basicSalary: const Value(2000),
          salaryCurrency: const Value(PayrollCurrency.usd),
        ),
      );

      await expectLater(
        repo.paySingleEmployee(
          employeeId: john,
          year: 2025,
          month: 8,
          treasuryId: treasuryId,
          basicSalary: 2000,
          paymentDate: DateTime(2025, 9, 1),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          allOf(contains('جون سميث'), contains('كشف الرواتب')),
        )),
      );
    });

    test('الرصيد غير الكافي يمنع الصرف', () async {
      await expectLater(
        payAhmed(basic: 99000000),
        throwsA(isA<StateError>()),
      );
      expect(await db.payrollDao.getPeriodForMonth(2025, 8), isNull,
          reason: 'الحرّاس كلها قبل أي كتابة — فلا يبقى كشف فارغ');
    });

    test('الصافي الصفري يُرفض', () async {
      await expectLater(
        payAhmed(basic: 500000, deductions: 500000),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          contains('صفر'),
        )),
      );
    });

    test('الصافي السالب يُرفض', () async {
      await expectLater(
        payAhmed(basic: 400000, deductions: 500000),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          contains('سالب'),
        )),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٦. تنبيه الاستيراد
  // ═══════════════════════════════════════════════════════════════════════

  group('تنبيه «مصروف سلفاً» لمعالج الاستيراد', () {
    test('⭐⭐ يُعيد الموظف باسمه وتاريخ صرفه ورقم سنده', () async {
      final r = await payAhmed(date: DateTime(2025, 9, 3));

      final paid = await db.payrollDao.getPaidEmployeesForMonth(2025, 8);
      expect(paid.length, 1);
      expect(paid.single.employeeId, ahmedId);
      expect(paid.single.employeeName, 'أحمد علي');
      expect(paid.single.voucherNumber, r.voucherNumber,
          reason: 'تنبيهٌ بلا سند لا يُمكّن المالك من التحقّق فيُتجاهَل');
      expect(paid.single.paidAt, isNotNull);
      expect(paid.single.netIqd, 600000);
    });

    test('لا يشمل سطراً غير مسدَّد — التنبيه للمصروف فعلاً', () async {
      final periodId = await repo.createOrGetPeriod(year: 2025, month: 8);
      await repo.importRows(
        periodId: periodId,
        rows: [
          ResolvedPayrollRow(
            employeeId: ahmedId,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'أحمد علي',
              basicSalary: 600000,
            ),
          ),
        ],
      );

      expect(await db.payrollDao.getPaidEmployeesForMonth(2025, 8), isEmpty);
    });

    test('شهر آخر لا يتسرّب إلى التنبيه', () async {
      await payAhmed(month: 8);
      expect(await db.payrollDao.getPaidEmployeesForMonth(2025, 9), isEmpty);
    });
  });
}
