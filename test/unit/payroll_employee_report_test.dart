// ─────────────────────────────────────────────────────────────────────────────
// payroll_employee_report_test.dart — تقرير رواتب الموظف (طلب المالك 2026-08-26)
//
// **السؤال الذي يحرسه:** «كم دُفع لهذا الموظف خلال هذه الفترة، ولماذا كان
// راتب كل شهر بهذا الرقم؟»
//
// **وما يمسكه تحديداً:**
//   • حدود المدى الشهري — الشهر الأول والأخير **داخلان**، وما قبلهما خارج
//   • فلتر المشروع يُصفّي **موظفي المشروع** لا الرواتب الممولة منه
//   • كل سطر يحمل **الخزينة التي صرفت فعلاً** لا خزينة الموظف
//   • جمعُ الدولار على الدينار **يمرّ بسعر الصرف** ولا يُجمع خاماً
//   • المدى المقلوب يُصحَّح ولا يُعيد تقريراً فارغاً يُقرأ «لا رواتب»
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/services/payroll_calculator.dart';
import 'package:sales_management/core/services/payroll_print_data.dart';
import 'package:sales_management/core/services/payroll_row_parser.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/payroll_repository.dart';

void main() {
  late AppDatabase db;
  late PayrollRepository repo;
  late int fiscalId;
  late int mainTreasury;
  late int basraTreasury;
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
    mainTreasury = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );
    basraTreasury = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(
          name: 'مشروع البصرة', kind: const Value('project')),
    );

    for (final t in [mainTreasury, basraTreasury]) {
      final n = await db.fiscalPeriodsDao.getNextVoucherNumber(
        fiscalPeriodId: fiscalId,
        voucherType: 'kabd',
      );
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: n,
          voucherType: 'kabd',
          treasuryId: t,
          fiscalPeriodId: fiscalId,
          amount: 20000000,
          voucherDate: DateTime(2025, 1, 5),
        ),
      );
    }

    // أحمد يتبع مشروع البصرة · سارة تتبع الرئيسية
    ahmedId = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'أحمد علي',
        position: const Value('سائق'),
        basicSalary: const Value(600000),
        treasuryId: Value(basraTreasury),
      ),
    );
    saraId = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'سارة حسن',
        position: const Value('محاسبة'),
        basicSalary: const Value(500000),
        treasuryId: Value(mainTreasury),
      ),
    );
  });

  tearDown(() async => db.close());

  /// كشف شهر بسطر لموظف — يُسدَّد إن مُرّرت خزينة
  Future<int> sheetFor({
    required int month,
    required int employeeId,
    required String name,
    double salary = 600000,
    double bonus = 0,
    double deduction = 0,
    int? payFrom,
  }) async {
    final periodId = await repo.createOrGetPeriod(year: 2025, month: month);
    await repo.importRows(
      periodId: periodId,
      rows: [
        ResolvedPayrollRow(
          employeeId: employeeId,
          row: ParsedPayrollRow(
            rowNumber: 1,
            rowLabel: 'صف 1',
            employeeName: name,
            basicSalary: salary,
            bonus: bonus,
            deduction: deduction,
          ),
        ),
      ],
    );
    if (payFrom != null) {
      final entries = await db.payrollDao.getEntries(periodId);
      await repo.payEntries(
        periodId: periodId,
        entryIds: entries.map((e) => e.id).toList(),
        treasuryId: payFrom,
        paymentDate: DateTime(2025, month == 12 ? 12 : month + 1, 1),
      );
    }
    return periodId;
  }

  Future<EmployeePayrollReportData> reportFor({
    int? employeeId,
    int? treasuryId,
    int fromMonth = 1,
    int toMonth = 12,
  }) {
    return repo.buildEmployeeReport(
      employeeId: employeeId,
      treasuryId: treasuryId,
      fromYear: 2025,
      fromMonth: fromMonth,
      toYear: 2025,
      toMonth: toMonth,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ١. تفصيل موظف واحد
  // ═══════════════════════════════════════════════════════════════════════

  group('تقرير موظف واحد', () {
    test('⭐⭐ يعرض كل شهر بكل بنوده لا الصافي وحده', () async {
      await sheetFor(
        month: 7,
        employeeId: ahmedId,
        name: 'أحمد علي',
        bonus: 50000,
        deduction: 20000,
        payFrom: mainTreasury,
      );

      final report = await reportFor(employeeId: ahmedId);
      expect(report.months.length, 1);

      final m = report.months.single;
      expect(m.year, 2025);
      expect(m.month, 7);
      expect(m.basicSalary, 600000);
      expect(m.bonus, 50000,
          reason: 'المكافأة بندٌ مستقلّ — الصافي وحده لا يقول لماذا زاد');
      expect(m.deduction, 20000);
      expect(m.netIqd, 630000);
      expect(m.isPaid, isTrue);
      expect(m.voucherNumber, isNotNull,
          reason: 'بلا رقم سند لا يمكن ردّ السطر إلى حركة في الدفاتر');
    });

    test('⭐ كل سطر يحمل **الخزينة التي صرفت فعلاً** لا خزينة الموظف',
        () async {
      // أحمد موظف البصرة، لكن راتب تموز خرج من الرئيسية
      await sheetFor(
        month: 7,
        employeeId: ahmedId,
        name: 'أحمد علي',
        payFrom: mainTreasury,
      );
      await sheetFor(
        month: 8,
        employeeId: ahmedId,
        name: 'أحمد علي',
        payFrom: basraTreasury,
      );

      final report = await reportFor(employeeId: ahmedId);
      expect(report.months.map((m) => m.paidFromTreasury).toList(),
          ['الرئيسية', 'مشروع البصرة'],
          reason: 'قرار المالك: يريد أن يعرف من موّل راتب كل شهر');
    });

    test('الأشهر مرتَّبة زمنياً لا بترتيب الإدخال', () async {
      await sheetFor(month: 9, employeeId: ahmedId, name: 'أحمد علي');
      await sheetFor(month: 3, employeeId: ahmedId, name: 'أحمد علي');
      await sheetFor(month: 6, employeeId: ahmedId, name: 'أحمد علي');

      final report = await reportFor(employeeId: ahmedId);
      expect(report.months.map((m) => m.month).toList(), [3, 6, 9]);
    });

    test('⭐ الإجماليات تُحسَب مرّة واحدة وتطابق مجموع السطور', () async {
      await sheetFor(
          month: 7, employeeId: ahmedId, name: 'أحمد علي', bonus: 50000);
      await sheetFor(
          month: 8,
          employeeId: ahmedId,
          name: 'أحمد علي',
          deduction: 30000,
          payFrom: mainTreasury);

      final report = await reportFor(employeeId: ahmedId);
      expect(report.totalIqd, closeTo(650000 + 570000, 0.001));
      expect(report.paidIqd, closeTo(570000, 0.001),
          reason: 'المصروف فعلاً وحده — لا يُخلَط بالمستحقّ');
      expect(report.unpaidIqd, closeTo(650000, 0.001));
      expect(report.bonusIqd, closeTo(50000, 0.001));
      expect(report.deductionIqd, closeTo(30000, 0.001));
      expect(report.monthCount, 2);
      expect(report.employeeName, 'أحمد علي');
      expect(report.position, 'سائق');
    });

    test('موظف بلا رواتب في الفترة ⇒ تقرير فارغ صريح لا خطأ', () async {
      final report = await reportFor(employeeId: saraId);
      expect(report.isEmpty, isTrue);
      expect(report.totalIqd, 0);
      expect(report.employeeName, 'سارة حسن');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٢. حدود المدى
  // ═══════════════════════════════════════════════════════════════════════

  group('حدود المدى الشهري', () {
    setUp(() async {
      for (final m in [5, 6, 7, 8, 9]) {
        await sheetFor(month: m, employeeId: ahmedId, name: 'أحمد علي');
      }
    });

    test('⭐⭐ الشهر الأول والأخير **داخلان** في المدى', () async {
      final report = await reportFor(
        employeeId: ahmedId,
        fromMonth: 6,
        toMonth: 8,
      );
      expect(report.months.map((m) => m.month).toList(), [6, 7, 8],
          reason: 'حدٌّ حصريّ يُسقط شهراً كاملاً من التقرير بصمت');
    });

    test('ما قبل المدى وما بعده لا يتسرّب', () async {
      final report = await reportFor(
        employeeId: ahmedId,
        fromMonth: 7,
        toMonth: 7,
      );
      expect(report.months.length, 1);
      expect(report.months.single.month, 7);
    });

    test('⭐ المدى المقلوب يُصحَّح ولا يُعيد فراغاً يُقرأ «لا رواتب»',
        () async {
      final report = await repo.buildEmployeeReport(
        employeeId: ahmedId,
        fromYear: 2025,
        fromMonth: 8,
        toYear: 2025,
        toMonth: 6,
      );
      expect(report.months.map((m) => m.month).toList(), [6, 7, 8]);
      expect(report.rangeLabel, 'حزيران 2025 — آب 2025');
    });

    test('المدى عبر سنتين يجمع شهور السنتين بترتيبهما', () async {
      final fiscal2024 = await db.fiscalPeriodsDao.insertPeriod(
        FiscalPeriodsCompanion.insert(
          name: '2024',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31, 23, 59, 59),
        ),
      );
      expect(fiscal2024, isNotNull);

      final periodId =
          await repo.createOrGetPeriod(year: 2024, month: 12);
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

      final report = await repo.buildEmployeeReport(
        employeeId: ahmedId,
        fromYear: 2024,
        fromMonth: 12,
        toYear: 2025,
        toMonth: 5,
      );
      expect(report.months.map((m) => '${m.year}/${m.month}').toList(),
          ['2024/12', '2025/5']);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٣. وضع المجموعة وفلتر المشروع
  // ═══════════════════════════════════════════════════════════════════════

  group('تقرير مجموعة الموظفين', () {
    setUp(() async {
      await sheetFor(
          month: 7,
          employeeId: ahmedId,
          name: 'أحمد علي',
          bonus: 40000,
          payFrom: basraTreasury);
      await sheetFor(
          month: 8, employeeId: ahmedId, name: 'أحمد علي', salary: 600000);
      await sheetFor(
          month: 7,
          employeeId: saraId,
          name: 'سارة حسن',
          salary: 500000,
          payFrom: mainTreasury);
    });

    test('⭐⭐ بلا موظف ⇒ كل الموظفين بمجاميعهم', () async {
      final report = await reportFor();
      expect(report.isSingleEmployee, isFalse);
      expect(report.employees.length, 2);

      final ahmed =
          report.employees.firstWhere((e) => e.employeeId == ahmedId);
      expect(ahmed.monthCount, 2);
      expect(ahmed.totalIqd, closeTo(640000 + 600000, 0.001));
      expect(ahmed.paidIqd, closeTo(640000, 0.001));
      expect(ahmed.bonusIqd, closeTo(40000, 0.001));
    });

    test('⭐ فلتر المشروع يُصفّي **موظفي المشروع**', () async {
      final report = await reportFor(treasuryId: basraTreasury);
      expect(report.employees.length, 1);
      expect(report.employees.single.employeeName, 'أحمد علي');
      expect(report.treasuryName, 'مشروع البصرة');
    });

    test('المجاميع مرتَّبة تنازلياً — الأكبر أولاً', () async {
      final report = await reportFor();
      expect(report.employees.first.employeeId, ahmedId);
    });

    test('إجمالي التقرير = مجموع الموظفين', () async {
      final report = await reportFor();
      final sum = report.employees
          .fold<double>(0, (s, e) => s + e.totalIqd);
      expect(report.totalIqd, closeTo(sum, 0.001));
      expect(report.monthCount, 3, reason: 'ثلاثة سطور رواتب في الفترة');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٤. العملات
  // ═══════════════════════════════════════════════════════════════════════

  group('جمع العملات', () {
    test('⭐⭐ مكافأة بالدولار تُضرب بسعر الصرف قبل الجمع بالدينار', () async {
      final john = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
          fullName: 'جون سميث',
          basicSalary: const Value(1000),
          salaryCurrency: const Value(PayrollCurrency.usd),
          treasuryId: Value(mainTreasury),
        ),
      );

      final periodId = await repo.createOrGetPeriod(
        year: 2025,
        month: 7,
        exchangeRate: 1500,
      );
      await repo.importRows(
        periodId: periodId,
        rows: [
          ResolvedPayrollRow(
            employeeId: john,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'جون سميث',
              basicSalary: 1000,
              currency: PayrollCurrency.usd,
              bonus: 100,
            ),
          ),
        ],
      );

      // تفصيل الموظف: البنود بعملتها والصافي بالدينار أيضاً
      final single = await reportFor(employeeId: john);
      expect(single.months.single.bonus, 100, reason: 'بعملة السطر في التفصيل');
      expect(single.months.single.netIqd, closeTo(1100 * 1500, 0.001));
      expect(single.bonusIqd, closeTo(100 * 1500, 0.001),
          reason: 'المجموع بالدينار — جمع دولارٍ على دينار رقمٌ بلا معنى');

      // المجموعة: كل شيء بالدينار
      final group = await reportFor();
      final row = group.employees.firstWhere((e) => e.employeeId == john);
      expect(row.bonusIqd, closeTo(150000, 0.001));
      expect(row.totalIqd, closeTo(1650000, 0.001));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٥. السطور القديمة بلا كشف
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ سطر قديم بلا كشف يُنسَب لشهر تاريخ صرفه ولا يسقط من التقرير',
      () async {
    // سطرٌ كما كان يكتبه المسار المباشر قبل توحيده (ع-٢٨)
    await db.employeesDao.insertSalaryPayment(
      SalaryPaymentsCompanion.insert(
        employeeId: ahmedId,
        paymentDate: DateTime(2025, 4, 10),
        snapshotName: const Value('أحمد علي'),
        basicSalary: const Value(600000),
        netAmount: const Value(600000),
        netAmountIqd: const Value(600000),
        paymentStatus: const Value(PayrollPaymentStatusDb.paid),
      ),
    );

    final report = await reportFor(employeeId: ahmedId);
    expect(report.months.length, 1,
        reason: 'إسقاطه كان سيُخفي مالاً خرج فعلاً من الخزينة');
    expect(report.months.single.month, 4);
    expect(report.months.single.periodId, isNull);
    expect(report.totalIqd, 600000);
  });
}
