// ─────────────────────────────────────────────────────────────────────────────
// payroll_advance_link_test.dart — ربط سطر السلفة بكشف الرواتب (Schema v7)
//
// 🔑 **هذا الملف يحرس أخطر ما في نظام الرواتب كلّه.**
//
// **السيناريو الحقيقي:** المالك أرسل سلفة تشغيلية إلى البصرة. صرف المشروع
// منها أثاثاً وطعاماً **ورواتب موظفيه**. وصل ملف مصاريف السلفة وفيه سطر
// «تسديد رواتب شباط»، ووصل قبله ملف رواتب الشهر فبُني كشفه.
//
// **الخطر:** لو دخل سطر السلفة الدفاتر كمصروف **و** سُدِّدت رواتب الكشف
// منفصلةً، لخرج المال **مرّتين** من خزنة البصرة. وهو صنف العطل ع-١٣ نفسه
// (الرصيد الافتتاحي كان يُضاعف الرصيد) — ولا يكشفه شيء إلا مطابقة صريحة.
//
// **الحلّ المُختبَر هنا:** سطر السلفة يصير **سنداً واحداً** كالمعتاد، وفي
// المعاملة نفسها تُعلَّم سطور الكشف مسدَّدةً بذلك السند. فالمال يخرج مرّة،
// وسجلّ كل موظف يمتلئ، والمجموعان **لا يمكن أن يختلفا** لأن الحارس يرفض.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/services/payroll_calculator.dart';
import 'package:sales_management/core/services/payroll_row_parser.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/advance_repository.dart';
import 'package:sales_management/data/repositories/payroll_repository.dart';
import 'package:sales_management/domain/repositories/i_advance_repository.dart';

void main() {
  late AppDatabase db;
  late AdvanceRepository advanceRepo;
  late PayrollRepository payrollRepo;
  late int fiscalId;
  late int mainTreasury;
  late int basraTreasury;
  late int ahmedId;
  late int aliId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    advanceRepo = AdvanceRepository(db);
    payrollRepo = PayrollRepository(db);

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
          name: 'خزنة البصرة', kind: const Value('main')),
    );

    // تمويل خزنة البصرة — السلفة تُصرف منها
    final n = await db.fiscalPeriodsDao.getNextVoucherNumber(
      fiscalPeriodId: fiscalId,
      voucherType: 'kabd',
    );
    await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: n,
        voucherType: 'kabd',
        treasuryId: basraTreasury,
        fiscalPeriodId: fiscalId,
        amount: 10000000,
        voucherDate: DateTime(2025, 1, 5),
      ),
    );

    // موظفا البصرة — **خزينتهما هي رابط المشروع** (قرار المالك)
    ahmedId = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'أحمد علي',
        basicSalary: const Value(600000),
        treasuryId: Value(basraTreasury),
      ),
    );
    aliId = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'علي كريم',
        basicSalary: const Value(500000),
        treasuryId: Value(basraTreasury),
      ),
    );
  });

  tearDown(() async => db.close());

  // ── مساعدات ─────────────────────────────────────────────────────────────

  /// كشف رواتب شباط بموظفَي البصرة — المجموع 1,100,000
  Future<int> seedPayroll() async {
    final pid = await payrollRepo.createOrGetPeriod(year: 2025, month: 2);
    await payrollRepo.importRows(
      periodId: pid,
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
        ResolvedPayrollRow(
          employeeId: aliId,
          row: const ParsedPayrollRow(
            rowNumber: 2,
            rowLabel: 'صف 2',
            employeeName: 'علي كريم',
            basicSalary: 500000,
          ),
        ),
      ],
    );
    return pid;
  }

  /// سلفة البصرة بمسودة فيها سطر عادي وسطر رواتب
  Future<int> seedAdvance({double payrollLineAmount = 1100000}) async {
    final advanceId = await advanceRepo.createAdvance(
      advanceNumber: 'بصرة-1',
      projectTreasuryId: basraTreasury,
      advanceDate: DateTime(2025, 3, 1),
      projectName: 'البصرة',
    );
    await advanceRepo.createDraftFromExcel(
      advanceId: advanceId,
      fileName: 'basra.xlsx',
      fileHash: 'hash-basra',
      lines: [
        ParsedAdvanceLine(
          rowNumber: 1,
          date: DateTime(2025, 2, 10),
          amount: 450000,
          itemType: 'طعام',
          reason: 'مصاريف طعام',
        ),
        ParsedAdvanceLine(
          rowNumber: 2,
          date: DateTime(2025, 2, 28),
          amount: payrollLineAmount,
          itemType: 'راتب',
          reason: 'تسديد رواتب شباط',
        ),
      ],
    );
    return advanceId;
  }

  Future<int> payrollLineId(int advanceId) async {
    final lines = await db.advancesDao.getLines(advanceId);
    return lines.firstWhere((l) => l.itemType == 'راتب').id;
  }

  Future<double> balanceOf(int treasuryId) async {
    final row = await db.treasuriesDao.getTreasuryBalance(treasuryId);
    return row?.balanceIqd ?? 0;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // الربط
  // ═══════════════════════════════════════════════════════════════════════

  group('ربط السطر بالكشف', () {
    test('⭐ الربط يشمل موظفي خزينة المشروع وحدهم', () async {
      // موظف في خزينة أخرى يجب ألّا يدخل سلفة البصرة
      await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
          fullName: 'سارة بغداد',
          basicSalary: const Value(700000),
          treasuryId: Value(mainTreasury),
        ),
      );

      final pid = await seedPayroll();
      final advanceId = await seedAdvance();
      final lineId = await payrollLineId(advanceId);

      final count = await advanceRepo.linkLineToPayroll(
        lineId: lineId,
        payrollPeriodId: pid,
      );

      expect(count, 2, reason: 'موظفا البصرة فقط — لا موظفة بغداد');

      final entries = await payrollRepo.getEntries(pid);
      final linked = entries.where((e) => e.advanceLineId == lineId).toList();
      expect(linked, hasLength(2));
    });

    test('⭐ كشف بلا موظف من هذا المشروع يُرفض ولا يترك رباطاً فارغاً',
        () async {
      // موظفو الكشف كلهم في خزينة أخرى
      await db.employeesDao.updateEmployee(
        EmployeesCompanion(id: Value(ahmedId), treasuryId: Value(mainTreasury)),
      );
      await db.employeesDao.updateEmployee(
        EmployeesCompanion(id: Value(aliId), treasuryId: Value(mainTreasury)),
      );

      final pid = await seedPayroll();
      final advanceId = await seedAdvance();
      final lineId = await payrollLineId(advanceId);

      await expectLater(
        advanceRepo.linkLineToPayroll(lineId: lineId, payrollPeriodId: pid),
        throwsA(isA<StateError>().having((e) => e.message, 'الرسالة',
            contains('خزينة'))),
      );

      // ⭐ لا رباط فارغ يبقى ليُفشل الاعتماد لاحقاً بسبب غامض
      final line = await db.advancesDao.getLineById(lineId);
      expect(line!.payrollPeriodId, isNull);
    });

    test('كشف مُسدَّد لا يُربط بسلفة', () async {
      final pid = await seedPayroll();
      final entries = await payrollRepo.getEntries(pid);
      await payrollRepo.payEntries(
        periodId: pid,
        entryIds: entries.map((e) => e.id).toList(),
        treasuryId: basraTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );

      final advanceId = await seedAdvance();
      final lineId = await payrollLineId(advanceId);

      await expectLater(
        advanceRepo.linkLineToPayroll(lineId: lineId, payrollPeriodId: pid),
        throwsA(isA<StateError>()),
      );
    });

    test('فكّ الربط يُنظّف الطرفين', () async {
      final pid = await seedPayroll();
      final advanceId = await seedAdvance();
      final lineId = await payrollLineId(advanceId);

      await advanceRepo.linkLineToPayroll(
          lineId: lineId, payrollPeriodId: pid);
      await advanceRepo.unlinkLineFromPayroll(lineId);

      final line = await db.advancesDao.getLineById(lineId);
      expect(line!.payrollPeriodId, isNull);
      final entries = await payrollRepo.getEntries(pid);
      expect(entries.every((e) => e.advanceLineId == null), isTrue);
    });

    test('المعاينة تقول المبلغين وعدد الموظفين قبل الاعتماد', () async {
      final pid = await seedPayroll();
      final advanceId = await seedAdvance();
      final lineId = await payrollLineId(advanceId);
      await advanceRepo.linkLineToPayroll(
          lineId: lineId, payrollPeriodId: pid);

      final previews = await advanceRepo.getPayrollLinkPreviews(advanceId);
      expect(previews, hasLength(1));
      final p = previews.first;
      expect(p.lineAmount, 1100000);
      expect(p.payrollTotal, 1100000);
      expect(p.employeeCount, 2);
      expect(p.periodLabel, 'شباط 2025');
      expect(p.matches, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 🔑 المطابقة عند الاعتماد
  // ═══════════════════════════════════════════════════════════════════════

  group('حارس المطابقة', () {
    test('⭐ التطابق يمرّ: سند واحد للرواتب والكشف يصير مُسدَّداً', () async {
      final pid = await seedPayroll();
      final advanceId = await seedAdvance();
      final lineId = await payrollLineId(advanceId);
      await advanceRepo.linkLineToPayroll(
          lineId: lineId, payrollPeriodId: pid);

      final outcome = await advanceRepo.postAdvance(advanceId: advanceId);

      expect(outcome.success, isTrue, reason: outcome.message);
      expect(outcome.payrollEmployeesPaid, 2);
      expect(outcome.payrollPeriodsCompleted, contains('شباط 2025'));

      // سطرا السلفة = سندان (طعام + رواتب) — **لا سند لكل موظف**
      final vouchers = await db.vouchersDao.getAllVouchers();
      final sarf = vouchers.where((v) => v.voucherType == 'sarf').toList();
      expect(sarf, hasLength(2));

      // الكشف اكتمل
      final period = await db.payrollDao.getPeriodById(pid);
      expect(period!.status, PayrollStatusDb.posted);

      // كل موظف صار مسدَّداً ومربوطاً بسند سطر الرواتب وبالسلفة
      final entries = await payrollRepo.getEntries(pid);
      final payrollVoucher =
          sarf.firstWhere((v) => v.itemType == 'راتب');
      for (final e in entries) {
        expect(e.paymentStatus, PayrollPaymentStatusDb.paid);
        expect(e.voucherId, payrollVoucher.id);
        expect(e.advanceId, advanceId);
        expect(e.treasuryId, basraTreasury);
      }
    });

    test('⭐ المال يخرج مرّة واحدة — لا مضاعفة', () async {
      final pid = await seedPayroll();
      final advanceId = await seedAdvance();
      final lineId = await payrollLineId(advanceId);
      await advanceRepo.linkLineToPayroll(
          lineId: lineId, payrollPeriodId: pid);

      final before = await balanceOf(basraTreasury);
      await advanceRepo.postAdvance(advanceId: advanceId);
      final after = await balanceOf(basraTreasury);

      // ٤٥٠٬٠٠٠ طعام + ١٬١٠٠٬٠٠٠ رواتب = ١٬٥٥٠٬٠٠٠ — **لا ٢٬٦٥٠٬٠٠٠**
      expect(before - after, 1550000,
          reason: 'الرواتب تُخصَم مرّة واحدة لا مرّتين');
    });

    test('⭐⭐ فرق دينار واحد يمنع الاعتماد ويسمّي الفرق', () async {
      // اختبار الإثبات: بلا الحارس يمرّ الاعتماد ويدخل الدفاتر رقم لا
      // مصدر له — سطر السلفة يقول مبلغاً والكشف يقول آخر.
      final pid = await seedPayroll();
      final advanceId = await seedAdvance(payrollLineAmount: 1100002);
      final lineId = await payrollLineId(advanceId);
      await advanceRepo.linkLineToPayroll(
          lineId: lineId, payrollPeriodId: pid);

      await expectLater(
        advanceRepo.postAdvance(advanceId: advanceId),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          allOf(
            contains('لا تطابق'),
            contains('تسديد رواتب شباط'),
            contains('2'),
          ),
        )),
      );
    });

    test('⭐ الاعتماد المرفوض لا يترك أثراً — ذرّية كاملة', () async {
      final pid = await seedPayroll();
      final advanceId = await seedAdvance(payrollLineAmount: 900000);
      final lineId = await payrollLineId(advanceId);
      await advanceRepo.linkLineToPayroll(
          lineId: lineId, payrollPeriodId: pid);

      final beforeBalance = await balanceOf(basraTreasury);
      final beforeVouchers = (await db.vouchersDao.getAllVouchers()).length;

      await expectLater(
        advanceRepo.postAdvance(advanceId: advanceId),
        throwsA(isA<StateError>()),
      );

      expect(await balanceOf(basraTreasury), beforeBalance,
          reason: 'ولا سند صرف واحد — حتى سطر الطعام السليم');
      expect((await db.vouchersDao.getAllVouchers()).length, beforeVouchers);

      final period = await db.payrollDao.getPeriodById(pid);
      expect(period!.status, PayrollStatusDb.draft);
      final entries = await payrollRepo.getEntries(pid);
      expect(
        entries.every((e) => e.paymentStatus == PayrollPaymentStatusDb.unpaid),
        isTrue,
      );
    });

    test('هامش الدينار يتسامح مع تقريب الملفات اليدوية', () async {
      final pid = await seedPayroll();
      // فرق نصف دينار — تقريبٌ لا خطأ
      final advanceId = await seedAdvance(payrollLineAmount: 1100000.5);
      final lineId = await payrollLineId(advanceId);
      await advanceRepo.linkLineToPayroll(
          lineId: lineId, payrollPeriodId: pid);

      final outcome = await advanceRepo.postAdvance(advanceId: advanceId);
      expect(outcome.success, isTrue, reason: outcome.message);
    });

    test('سلفة بلا ربط رواتب تعمل كما كانت تماماً', () async {
      // حارس انحدار: المرحلة ٣ يجب ألّا تغيّر سلوك السلف العادية
      final advanceId = await seedAdvance();
      final outcome = await advanceRepo.postAdvance(advanceId: advanceId);

      expect(outcome.success, isTrue, reason: outcome.message);
      expect(outcome.payrollEmployeesPaid, 0);
      expect(outcome.payrollPeriodsCompleted, isEmpty);
      expect(outcome.vouchersCreated, 2);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // التسديد الجزئي — الكشف الشامل
  // ═══════════════════════════════════════════════════════════════════════

  group('كشف شامل يُسدَّد على دفعات', () {
    test('⭐ سلفة البصرة تُسدّد موظفيها ويبقى موظفو بغداد مستحقّين', () async {
      // الحالة الواقعية: كشف واحد شامل، والتمويل من مصدرين
      final baghdadEmployee = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
          fullName: 'سارة بغداد',
          basicSalary: const Value(700000),
          treasuryId: Value(mainTreasury),
        ),
      );

      final pid = await payrollRepo.createOrGetPeriod(year: 2025, month: 2);
      await payrollRepo.importRows(
        periodId: pid,
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
          ResolvedPayrollRow(
            employeeId: aliId,
            row: const ParsedPayrollRow(
              rowNumber: 2,
              rowLabel: 'صف 2',
              employeeName: 'علي كريم',
              basicSalary: 500000,
            ),
          ),
          ResolvedPayrollRow(
            employeeId: baghdadEmployee,
            row: const ParsedPayrollRow(
              rowNumber: 3,
              rowLabel: 'صف 3',
              employeeName: 'سارة بغداد',
              basicSalary: 700000,
            ),
          ),
        ],
      );

      final advanceId = await seedAdvance();
      final lineId = await payrollLineId(advanceId);
      await advanceRepo.linkLineToPayroll(
          lineId: lineId, payrollPeriodId: pid);

      final outcome = await advanceRepo.postAdvance(advanceId: advanceId);
      expect(outcome.success, isTrue, reason: outcome.message);
      expect(outcome.payrollEmployeesPaid, 2);

      // ⭐ الكشف **لم** يكتمل: موظفة بغداد ما زالت مستحقّة
      expect(outcome.payrollPeriodsCompleted, isEmpty);
      final period = await db.payrollDao.getPeriodById(pid);
      expect(period!.status, PayrollStatusDb.draft);

      final totals = await payrollRepo.getTotals(pid);
      expect(totals.paidCount, 2);
      expect(totals.unpaidIqd, 700000);
    });
  });
}
