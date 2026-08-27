// ─────────────────────────────────────────────────────────────────────────────
// payroll_report_test.dart — تقرير الرواتب السنوي ومستنداته (المرحلة ٤)
//
// **ما يحرسه هذا الملف — وكلّها أعطال وقعت فعلاً في مشاريع رواتب حقيقية:**
//
//   ١. 🔑 **مجموع التقرير = مجموع `getTotals` لكل كشف.** استعلامان يجمعان
//      العمود نفسه «يُفترَض» أن يتطابقا — وهذا الافتراض بالضبط هو ما انفرط
//      في المشروع المرجعي DMS: الجمع كان مكرَّراً في ثمانية مواضع، فأُضيف
//      تاسع نسي شرطاً واحداً واحتُسب راتبٌ لم يُدفع.
//
//   ٢. **الرواتب المصروفة خارج الكشوف لا تختفي.** صرفُ راتب من بطاقة الموظف
//      يكتب سطراً بلا كشف؛ تقريرٌ يقتصر على الكشوف يُخفي مالاً خرج فعلاً.
//
//   ٣. 🔴 **ع-٢٨** — حارس «لا راتب بلا مقابله بالدينار»: كان المسار المباشر
//      يكتب `net_amount_iqd = 0` و`payment_status = 'unpaid'` لراتبٍ **صُرف
//      فعلاً بسند حقيقي**، فيظهر في كل تقرير بصفر ومعلَّماً مستحقّاً.
//
//   ٤. **ورقة الطباعة تقول ما تقوله الشاشة.** الإجمالي المطبوع يُقرأ من
//      `getTotals` لا يُجمع في المستند، فلا يمكن أن يختلف الرقمان.
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
      TreasuriesCompanion.insert(name: 'خزنة البصرة', kind: const Value('project')),
    );

    // تمويل الخزينتين — وإلا رفض حارس الرصيد كل تسديد
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

    ahmedId = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'أحمد علي',
        position: const Value('سائق'),
        basicSalary: const Value(600000),
        treasuryId: Value(mainTreasury),
      ),
    );
    saraId = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'سارة حسن',
        position: const Value('محاسبة'),
        basicSalary: const Value(500000),
        treasuryId: Value(basraTreasury),
      ),
    );
  });

  tearDown(() async => db.close());

  // ── مساعدات ─────────────────────────────────────────────────────────────

  Future<int> addEntry({
    required int periodId,
    required int employeeId,
    required String name,
    String position = '',
    double salary = 600000,
    double bonus = 0,
  }) async {
    await repo.importRows(
      periodId: periodId,
      rows: [
        ResolvedPayrollRow(
          employeeId: employeeId,
          row: ParsedPayrollRow(
            rowNumber: 1,
            rowLabel: 'صف 1',
            employeeName: name,
            position: position,
            basicSalary: salary,
            bonus: bonus,
          ),
        ),
      ],
    );
    final entry = await db.payrollDao
        .getEntryForEmployee(periodId: periodId, employeeId: employeeId);
    return entry!.id;
  }

  /// كشف شهر بموظفَين: أحمد (٦٠٠٬٠٠٠) وسارة (٥٥٠٬٠٠٠ بعد مكافأة ٥٠٬٠٠٠)
  Future<({int periodId, int ahmedEntry, int saraEntry})> seedMonth(
    int month,
  ) async {
    final periodId = await repo.createOrGetPeriod(year: 2025, month: month);
    final a = await addEntry(
      periodId: periodId,
      employeeId: ahmedId,
      name: 'أحمد علي',
      position: 'سائق',
    );
    final s = await addEntry(
      periodId: periodId,
      employeeId: saraId,
      name: 'سارة حسن',
      position: 'محاسبة',
      salary: 500000,
      bonus: 50000,
    );
    return (periodId: periodId, ahmedEntry: a, saraEntry: s);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ١. مصدر الحقيقة الواحد
  // ═══════════════════════════════════════════════════════════════════════

  group('تقرير السنة يتّفق مع إجماليات الكشوف', () {
    test('⭐⭐ مجموع أشهر التقرير = مجموع getTotals لكل كشف على حدة',
        () async {
      await seedMonth(1);
      await seedMonth(2);
      await seedMonth(3);

      final report = await repo.buildYearReport(2025);
      expect(report.months.length, 3);

      // المرجع: نسأل مصدر الحقيقة كشفاً كشفاً
      var reference = 0.0;
      for (final m in report.months) {
        final totals = await db.payrollDao.getTotals(m.periodId);
        expect(m.totalIqd, closeTo(totals.totalIqd, 0.001),
            reason: 'مجموع الشهر في التقرير خالف getTotals لكشفه — '
                'هذا هو الانفراط الذي أنتج راتباً وهمياً في DMS');
        expect(m.unpaidIqd, closeTo(totals.unpaidIqd, 0.001));
        expect(m.employeeCount, totals.entryCount);
        reference += totals.totalIqd;
      }

      expect(report.totalIqd, closeTo(reference, 0.001));
      expect(report.totalIqd, closeTo(3 * 1150000, 0.001));
    });

    test('الكشف الفارغ يظهر بصفر ولا يختفي من التقرير', () async {
      // «شهرٌ أُنشئ ولم يُستورَد بعد» معلومة — واختفاؤه يوحي بأنه لم يُنشأ
      await repo.createOrGetPeriod(year: 2025, month: 7);

      final report = await repo.buildYearReport(2025);
      expect(report.months.length, 1);
      expect(report.months.single.employeeCount, 0);
      expect(report.months.single.totalIqd, 0);
    });

    test('الكشف المحذوف لا يدخل التقرير ولا يترك مبلغه', () async {
      final feb = await seedMonth(2);
      await seedMonth(3);

      await repo.deletePeriod(feb.periodId);

      final report = await repo.buildYearReport(2025);
      expect(report.months.length, 1);
      expect(report.months.single.month, 3);
      expect(report.totalIqd, closeTo(1150000, 0.001));
    });

    test('سنة أخرى لا تتسرّب إلى التقرير', () async {
      await db.fiscalPeriodsDao.insertPeriod(
        FiscalPeriodsCompanion.insert(
          name: '2026',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31, 23, 59, 59),
        ),
      );
      await seedMonth(2);
      final other = await repo.createOrGetPeriod(year: 2026, month: 2);
      await addEntry(
          periodId: other, employeeId: ahmedId, name: 'أحمد علي');

      final report = await repo.buildYearReport(2025);
      expect(report.months.length, 1);
      expect(report.totalIqd, closeTo(1150000, 0.001));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٢. المسدَّد والمتبقّي
  // ═══════════════════════════════════════════════════════════════════════

  group('التسديد الجزئي في التقرير', () {
    test('⭐ تسديد موظف واحد يُوزّع المبلغ على مسدَّد ومتبقٍّ', () async {
      final m = await seedMonth(2);
      await repo.payEntries(
        periodId: m.periodId,
        entryIds: [m.ahmedEntry],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );

      final report = await repo.buildYearReport(2025);
      final feb = report.months.single;

      expect(feb.totalIqd, closeTo(1150000, 0.001));
      expect(feb.paidIqd, closeTo(600000, 0.001));
      expect(feb.unpaidIqd, closeTo(550000, 0.001));
      expect(feb.isPosted, isFalse,
          reason: 'الكشف لا يصير مسدَّداً إلا باكتمال سطوره');
    });

    test('تسديد الجميع يجعل المتبقّي صفراً والكشف مُسدَّداً', () async {
      final m = await seedMonth(2);
      await repo.payEntries(
        periodId: m.periodId,
        entryIds: [m.ahmedEntry, m.saraEntry],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );

      final report = await repo.buildYearReport(2025);
      expect(report.months.single.unpaidIqd, closeTo(0, 0.001));
      expect(report.months.single.isPosted, isTrue);
      expect(report.postedMonthCount, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٣. توزيع الخزائن
  // ═══════════════════════════════════════════════════════════════════════

  group('توزيع الرواتب المسدَّدة على الخزائن', () {
    test('⭐ المسدَّد وحده يدخل التوزيع — المستحقّ لم يخرج من خزينة',
        () async {
      final m = await seedMonth(2);
      await repo.payEntries(
        periodId: m.periodId,
        entryIds: [m.ahmedEntry],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );

      final report = await repo.buildYearReport(2025);
      expect(report.treasuryShares.length, 1,
          reason: 'سطر سارة غير مسدَّد فلا خزينة له');
      expect(report.treasuryShares.single.treasuryName, 'الرئيسية');
      expect(report.treasuryShares.single.totalIqd, closeTo(600000, 0.001));
      expect(report.treasuryShares.single.employeeCount, 1);
    });

    test('⭐ خزينتان تدفعان دفعتين فيظهر لكلٍّ نصيبها', () async {
      final m = await seedMonth(2);
      await repo.payEntries(
        periodId: m.periodId,
        entryIds: [m.ahmedEntry],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );
      await repo.payEntries(
        periodId: m.periodId,
        entryIds: [m.saraEntry],
        treasuryId: basraTreasury,
        paymentDate: DateTime(2025, 3, 2),
      );

      final report = await repo.buildYearReport(2025);
      expect(report.treasuryShares.length, 2);
      // مرتّبة تنازلياً بالمبلغ
      expect(report.treasuryShares.first.treasuryName, 'الرئيسية');
      expect(report.treasuryShares.last.treasuryName, 'خزنة البصرة');
      expect(report.treasuryShares.last.totalIqd, closeTo(550000, 0.001));

      final sum = report.treasuryShares
          .fold<double>(0, (s, e) => s + e.totalIqd);
      expect(sum, closeTo(report.paidIqd, 0.001),
          reason: 'مجموع الحصص يجب أن يساوي المسدَّد بالضبط');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٤. الرواتب خارج الكشوف
  // ═══════════════════════════════════════════════════════════════════════

  group('الرواتب المصروفة خارج الكشوف', () {
    /// راتب سُجِّل بالمسار المباشر (بطاقة الموظف) — بلا كشف
    Future<void> payDirectly({
      required int employeeId,
      required String name,
      required double amount,
      required DateTime date,
    }) async {
      await db.employeesDao.insertSalaryPayment(
        SalaryPaymentsCompanion.insert(
          employeeId: employeeId,
          paymentDate: date,
          periodLabel: const Value('راتب مباشر'),
          snapshotName: Value(name),
          basicSalary: Value(amount),
          netAmount: Value(amount),
          netAmountIqd: Value(amount),
          paymentStatus: const Value(PayrollPaymentStatusDb.paid),
          paidAt: Value(date),
          treasuryId: Value(mainTreasury),
        ),
      );
    }

    test('⭐ تُحصى وتُجمَع ولا تختفي من التقرير', () async {
      await seedMonth(2);
      await payDirectly(
        employeeId: ahmedId,
        name: 'أحمد علي',
        amount: 700000,
        date: DateTime(2025, 6, 1),
      );

      final out = await repo.getOutOfSheetSalaries(2025);
      expect(out.count, 1);
      expect(out.totalIqd, closeTo(700000, 0.001));
    });

    test('لا تُحتسَب ضمن أشهر الكشوف — الرقمان منفصلان بوضوح', () async {
      await seedMonth(2);
      await payDirectly(
        employeeId: ahmedId,
        name: 'أحمد علي',
        amount: 700000,
        date: DateTime(2025, 2, 25),
      );

      final report = await repo.buildYearReport(2025);
      expect(report.totalIqd, closeTo(1150000, 0.001),
          reason: 'جدول الأشهر يعرض الكشوف وحدها، والباقي في شريط منفصل');
    });

    test('راتب سنة أخرى لا يُحتسب — المدى محلّي لا UTC', () async {
      // ⚠️ لو استُعمل `strftime` على عدد ثواني يونكس لعاد رقمٌ لا معنى له،
      //   ولو حُسب المدى بـUTC لوقع راتب أول كانون الثاني في السنة السابقة.
      await payDirectly(
        employeeId: ahmedId,
        name: 'أحمد علي',
        amount: 700000,
        date: DateTime(2025, 1, 1),
      );
      await payDirectly(
        employeeId: ahmedId,
        name: 'أحمد علي',
        amount: 900000,
        date: DateTime(2024, 12, 31),
      );

      final out2025 = await repo.getOutOfSheetSalaries(2025);
      expect(out2025.count, 1);
      expect(out2025.totalIqd, closeTo(700000, 0.001));

      final out2024 = await repo.getOutOfSheetSalaries(2024);
      expect(out2024.count, 1);
      expect(out2024.totalIqd, closeTo(900000, 0.001));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٥. 🔴 ع-٢٨ — حارس «لا راتب بلا مقابله بالدينار»
  // ═══════════════════════════════════════════════════════════════════════

  group('حارس المقابل بالدينار (ع-٢٨)', () {
    test('⭐⭐ راتب بصافٍ بلا net_amount_iqd يُرفض عند الكتابة', () async {
      // 🔴 **هذا ما كان يقع فعلاً** حتى 2026-08-26: مسار «صرف راتب» من
      //   بطاقة الموظف يُنشئ سند صرف حقيقياً يُخرج المال، ثم يكتب سطر راتب
      //   بلا هذا العمود. فالنتيجة راتبٌ **صُرف** ويظهر بصفر في كل تقرير.
      await expectLater(
        db.employeesDao.insertSalaryPayment(
          SalaryPaymentsCompanion.insert(
            employeeId: ahmedId,
            paymentDate: DateTime(2025, 3, 1),
            basicSalary: const Value(600000),
            netAmount: const Value(600000),
            // netAmountIqd غائب — كما كان المسار المباشر يكتب تماماً
          ),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          allOf(contains('أحمد علي'), contains('بالدينار')),
        )),
      );
    });

    test('الصافي الصفري مسموح — موظف بلا استحقاق هذا الشهر', () async {
      final id = await db.employeesDao.insertSalaryPayment(
        SalaryPaymentsCompanion.insert(
          employeeId: ahmedId,
          paymentDate: DateTime(2025, 3, 1),
          netAmount: const Value(0),
          netAmountIqd: const Value(0),
        ),
      );
      expect(id, greaterThan(0));
    });

    test('⭐ راتب موظف بالدولار يُرفض في المسار المباشر بالدينار', () async {
      // المسار المباشر يُنشئ سنداً بالدينار، فلو مرّ به موظف راتبه بالدولار
      // لصُرف رقمُه الدولاري ديناراً — كسرٌ صامت لقيمة الراتب.
      final usdEmployee = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
          fullName: 'جون سميث',
          basicSalary: const Value(2000),
          salaryCurrency: const Value(PayrollCurrency.usd),
        ),
      );

      await expectLater(
        db.employeesDao.insertSalaryPayment(
          SalaryPaymentsCompanion.insert(
            employeeId: usdEmployee,
            paymentDate: DateTime(2025, 3, 1),
            snapshotName: const Value('جون سميث'),
            snapshotCurrency: const Value(PayrollCurrency.iqd),
            netAmount: const Value(2000),
            netAmountIqd: const Value(2000),
          ),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          allOf(contains('جون سميث'), contains('كشف الرواتب')),
        )),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٦. بيانات الطباعة
  // ═══════════════════════════════════════════════════════════════════════

  group('بيانات كشف الطباعة', () {
    test('⭐⭐ الإجمالي المطبوع يُقرأ من getTotals لا يُجمع في المستند',
        () async {
      final m = await seedMonth(2);
      final totals = await db.payrollDao.getTotals(m.periodId);
      final data = await repo.buildSheetPrintData(m.periodId);

      expect(data.totalIqd, closeTo(totals.totalIqd, 0.001));
      expect(data.employeeCount, totals.entryCount);
      expect(data.unpaidIqd, closeTo(totals.unpaidIqd, 0.001));
      expect(data.paidIqd, closeTo(totals.totalIqd - totals.unpaidIqd, 0.001));
    });

    test('⭐ السطور بترتيب الملف لا أبجدياً — ليطابقها المالك سطراً بسطر',
        () async {
      final m = await seedMonth(2);
      final data = await repo.buildSheetPrintData(m.periodId);

      expect(data.rows.map((r) => r.name).toList(), ['أحمد علي', 'سارة حسن']);
      expect(data.rows.first.seq, 1);
      expect(data.rows.last.seq, 2);
    });

    test('اللقطة تُطبَع لا البيانات الحالية', () async {
      final m = await seedMonth(2);

      // يتغيّر راتبه وصفته **بعد** إنشاء الكشف
      await db.employeesDao.updateEmployee(
        EmployeesCompanion(
          id: Value(ahmedId),
          basicSalary: const Value(999999),
          position: const Value('مدير'),
        ),
      );

      final data = await repo.buildSheetPrintData(m.periodId);
      final ahmed = data.rows.firstWhere((r) => r.name == 'أحمد علي');
      expect(ahmed.basicSalary, 600000,
          reason: 'تغيير الراتب اليوم لا يُعيد كتابة ورقة شهر مضى');
      expect(ahmed.position, 'سائق');
    });

    test('حالة السطر تنعكس على الورقة بعد التسديد', () async {
      final m = await seedMonth(2);
      await repo.payEntries(
        periodId: m.periodId,
        entryIds: [m.ahmedEntry],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );

      final data = await repo.buildSheetPrintData(m.periodId);
      expect(data.rows.firstWhere((r) => r.name == 'أحمد علي').isPaid, isTrue);
      expect(data.rows.firstWhere((r) => r.name == 'سارة حسن').isPaid, isFalse);
    });

    test('عمود التوقيع خيار لا ثابت', () async {
      final m = await seedMonth(2);
      final without = await repo.buildSheetPrintData(m.periodId);
      final with_ = await repo.buildSheetPrintData(m.periodId,
          withSignatureColumn: true);
      expect(without.withSignatureColumn, isFalse);
      expect(with_.withSignatureColumn, isTrue);
    });

    test('كشف غير موجود يرمي رسالة عربية لا استثناءً غامضاً', () async {
      await expectLater(
        repo.buildSheetPrintData(9999),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('بيانات إيصال الراتب', () {
    test('⭐ الإيصال المسدَّد يحمل رقم سنده واسم خزينته', () async {
      final m = await seedMonth(2);
      final result = await repo.payEntries(
        periodId: m.periodId,
        entryIds: [m.ahmedEntry],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );

      final slip = await repo.buildSlipPrintData(m.ahmedEntry);
      expect(slip, isNotNull);
      expect(slip!.isPaid, isTrue);
      expect(slip.voucherNumber, result.voucherNumber,
          reason: 'إيصالٌ بلا رقم سند لا يمكن ردّه إلى حركة في الدفاتر');
      expect(slip.treasuryName, 'الرئيسية');
      expect(slip.employeeName, 'أحمد علي');
      expect(slip.periodLabel, 'شباط 2025');
    });

    test('الإيصال غير المسدَّد بلا سند ولا خزينة — وهو الصدق', () async {
      final m = await seedMonth(2);
      final slip = await repo.buildSlipPrintData(m.saraEntry);
      expect(slip!.isPaid, isFalse);
      expect(slip.voucherNumber, isNull);
      expect(slip.treasuryName, isNull);
    });

    test('⭐ سطر بلا لقطة اسم يقع على اسم الموظف — لا إيصال بلا اسم',
        () async {
      // سطور ما قبل v7 بلا `snapshot_name`
      final id = await db.employeesDao.insertSalaryPayment(
        SalaryPaymentsCompanion.insert(
          employeeId: saraId,
          paymentDate: DateTime(2025, 3, 1),
          netAmount: const Value(500000),
          netAmountIqd: const Value(500000),
        ),
      );

      final slip = await repo.buildSlipPrintData(id);
      expect(slip!.employeeName, 'سارة حسن');
    });

    test('سطر غير موجود يُعيد null لا يرمي', () async {
      expect(await repo.buildSlipPrintData(9999), isNull);
    });
  });
}
