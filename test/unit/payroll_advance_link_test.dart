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

    test('⭐⭐ خزينة الموظف **لا تؤثّر** في التغطية — الربط بالكشف يكفي',
        () async {
      // 🔄 **تغيّر العقد 2026-08-26** (بلاغ المالك): كانت التغطية تشمل
      //   «موظفي خزينة المشروع» وحدهم، فكسرها أن ٤٦ من ٤٧ موظفاً كانوا
      //   منسوبين إلى خزينة **محذوفة** — فقال البرنامج «لا تطابق» لكشفٍ
      //   مجموعه يساوي سطر السلفة بالضبط.
      //
      //   القاعدة الآن: **ما ربطه المالك بيده هو ما يُغطّى**. لا وسيط في
      //   ملفّ الموظف يمكن أن ينحرف.
      await db.employeesDao.updateEmployee(
        EmployeesCompanion(id: Value(ahmedId), treasuryId: Value(mainTreasury)),
      );
      await db.employeesDao.updateEmployee(
        EmployeesCompanion(
            id: Value(aliId), treasuryId: const Value.absent()),
      );

      final pid = await seedPayroll();
      final advanceId = await seedAdvance();
      final lineId = await payrollLineId(advanceId);

      final count = await advanceRepo.linkLineToPayroll(
          lineId: lineId, payrollPeriodId: pid);

      expect(count, 2,
          reason: 'واحدٌ في خزينة أخرى وآخر بلا خزينة — وكلاهما مشمول');
      final line = await db.advancesDao.getLineById(lineId);
      expect(line!.payrollPeriodId, pid);
    });

    test('⭐ كشف بلا راتب مستحقّ يُرفض ولا يترك رباطاً فارغاً', () async {
      final pid = await seedPayroll();
      final entries = await payrollRepo.getEntries(pid);
      await payrollRepo.payEntries(
        periodId: pid,
        entryIds: entries.map((e) => e.id).toList(),
        treasuryId: basraTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );
      // الكشف صار مُسدَّداً — نُعيده مسودة بسطر مصروف وحده ليُختبَر الرفض
      await db.payrollDao.updatePeriod(
        pid,
        const PayrollPeriodsCompanion(status: Value(PayrollStatusDb.draft)),
      );

      final advanceId = await seedAdvance();
      final lineId = await payrollLineId(advanceId);

      await expectLater(
        advanceRepo.linkLineToPayroll(lineId: lineId, payrollPeriodId: pid),
        throwsA(isA<StateError>().having((e) => e.message, 'الرسالة',
            contains('مستحقّ'))),
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
      // 🔄 **تغيّر العقد 2026-08-27** (بلاغ المالك): كان سندٌ لكل سطر —
      //   فسلفةٌ بـ١٥٠ سطراً تُنتج ١٥٠ سنداً. الآن **سند واحد** لمصاريفها
      //   كلها، والتفصيل يبقى في سطورها ويقرأه تقرير البنود منها مباشرةً.
      expect(outcome.vouchersCreated, 1,
          reason: 'سطران غير مربوطَين برواتب = سندٌ واحد مجمَّع');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // التسديد الجزئي — الكشف الشامل
  // ═══════════════════════════════════════════════════════════════════════

  group('كشف شامل يُسدَّد على دفعات', () {
    test('⭐⭐ التقسيم يقع **بالتسديد قبل الربط** لا بخزينة الموظف', () async {
      // 🔄 **العقد الجديد 2026-08-26:** سطر السلفة يغطّي **كل** مستحقّي
      //   الكشف. فكيف يُقسَّم كشفٌ بين مصدرَي تمويل؟ **بترتيب العمليات**:
      //   يُسدَّد من تُموّله الخزينة الأخرى أولاً، فيخرج من دائرة الاستحقاق،
      //   ثم يُربط سطر السلفة فيغطّي الباقي وحده.
      //
      //   وهذا أصدق من القاعدة القديمة: المال يتبع **قرار الصرف** لا حقلاً
      //   إدارياً في بطاقة الموظف يتغيّر لأسباب أخرى.
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

      // ── موظفة بغداد تُسدَّد أولاً من الخزينة الرئيسية ────────────────
      // تُموَّل الرئيسية أولاً — التقسيم يفترض مصدرَي تمويل حقيقيَّين
      final kabd = await db.fiscalPeriodsDao.getNextVoucherNumber(
        fiscalPeriodId: fiscalId,
        voucherType: 'kabd',
      );
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: kabd,
          voucherType: 'kabd',
          treasuryId: mainTreasury,
          fiscalPeriodId: fiscalId,
          amount: 5000000,
          voucherDate: DateTime(2025, 1, 6),
        ),
      );

      final all = await payrollRepo.getEntries(pid);
      final sara =
          all.firstWhere((e) => e.employeeId == baghdadEmployee);
      await payrollRepo.payEntries(
        periodId: pid,
        entryIds: [sara.id],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );

      final advanceId = await seedAdvance();
      final lineId = await payrollLineId(advanceId);
      final covered = await advanceRepo.linkLineToPayroll(
          lineId: lineId, payrollPeriodId: pid);
      expect(covered, 2,
          reason: 'المسدَّدة سلفاً خارج التغطية — وهذا هو مسار التقسيم');

      final outcome = await advanceRepo.postAdvance(advanceId: advanceId);
      expect(outcome.success, isTrue, reason: outcome.message);
      expect(outcome.payrollEmployeesPaid, 2);

      // ⭐ الكشف اكتمل: الثلاثة مصروفون — كلٌّ من مصدره
      final totals = await payrollRepo.getTotals(pid);
      expect(totals.paidCount, 3);
      expect(totals.unpaidIqd, 0);

      // وكلٌّ خرج من خزينته الصحيحة
      final entries = await payrollRepo.getEntries(pid);
      final saraAfter =
          entries.firstWhere((e) => e.employeeId == baghdadEmployee);
      expect(saraAfter.treasuryId, mainTreasury);
      expect(
        entries
            .where((e) => e.employeeId != baghdadEmployee)
            .every((e) => e.treasuryId == basraTreasury),
        isTrue,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // خزينة الموظف لم تعد تحكم التغطية (ع-٣٤ — بلاغ المالك 2026-08-26)
  // ═══════════════════════════════════════════════════════════════════════

  group('سيناريو المالك: موظفون في خزينة محذوفة', () {
    test('⭐⭐ الكشف يُطابق سطر السلفة ولو كانت خزائن موظفيه محذوفة', () async {
      // 🔴 **الحالة التي وقعت فعلاً:** ٤٦ من ٤٧ موظفاً منسوبون إلى خزينة
      //   حُذفت بعد استيرادهم، فقالت المطابقة «مجموع ١ موظفاً ٢٬٢٥٠٬٠٠٠»
      //   لكشفٍ مجموعه يساوي سطر السلفة بالضبط.
      final ghostTreasury = await db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(
            name: 'خزنة قديمة', kind: const Value('project')),
      );
      await db.treasuriesDao.softDeleteTreasury(ghostTreasury);

      await db.employeesDao.updateEmployee(
        EmployeesCompanion(
            id: Value(ahmedId), treasuryId: Value(ghostTreasury)),
      );
      await db.employeesDao.updateEmployee(
        EmployeesCompanion(
            id: Value(aliId), treasuryId: Value(ghostTreasury)),
      );

      final pid = await seedPayroll();
      final advanceId = await seedAdvance();
      final lineId = await payrollLineId(advanceId);

      final covered = await advanceRepo.linkLineToPayroll(
          lineId: lineId, payrollPeriodId: pid);
      expect(covered, 2, reason: 'خزينةٌ محذوفة لا تُسقط موظفاً من كشفه');

      final previews = await advanceRepo.getPayrollLinkPreviews(advanceId);
      final p = previews.firstWhere((x) => x.lineId == lineId);
      expect(p.employeeCount, 2);
      expect(p.payrollTotal, closeTo(p.lineAmount, 1),
          reason: 'وهذا ما كان يفشل: مجموعٌ يساوي السطر ويُقال «لا تطابق»');
      expect(p.matches, isTrue);
    });

    test('⭐ نقل موظفي خزينة إلى أخرى قبل حذفها', () async {
      final oldTreasury = await db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(
            name: 'خزنة قديمة', kind: const Value('project')),
      );
      for (final id in [ahmedId, aliId]) {
        await db.employeesDao.updateEmployee(
          EmployeesCompanion(id: Value(id), treasuryId: Value(oldTreasury)),
        );
      }

      expect(await db.employeesDao.countEmployeesInTreasury(oldTreasury), 2);

      final moved = await db.employeesDao.reassignTreasury(
        fromTreasuryId: oldTreasury,
        toTreasuryId: basraTreasury,
      );

      expect(moved, 2);
      expect(await db.employeesDao.countEmployeesInTreasury(oldTreasury), 0);
      expect(await db.employeesDao.countEmployeesInTreasury(basraTreasury), 2);
    });

    test('النقل إلى «بلا مشروع» يجرّدهم من الخزينة', () async {
      final moved = await db.employeesDao.reassignTreasury(
        fromTreasuryId: basraTreasury,
        toTreasuryId: null,
      );
      expect(moved, greaterThan(0));
      expect(await db.employeesDao.countEmployeesInTreasury(basraTreasury), 0);

      final ahmed = await db.employeesDao.getEmployeeById(ahmedId);
      expect(ahmed!.treasuryId, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // إلغاء السلفة يسحب رواتبها (ع-٣٦ — بلاغ المالك 2026-08-27)
  // ═══════════════════════════════════════════════════════════════════════

  group('إلغاء سلفة معتمدة فيها رواتب', () {
    /// سلفة معتمدة: سطر مصاريف + سطر رواتب مربوط بكشف شباط
    Future<({int advanceId, int periodId})> postedAdvanceWithPayroll() async {
      final pid = await seedPayroll();
      final advanceId = await seedAdvance();
      final lineId = await payrollLineId(advanceId);
      await advanceRepo.linkLineToPayroll(
          lineId: lineId, payrollPeriodId: pid);
      final outcome = await advanceRepo.postAdvance(advanceId: advanceId);
      expect(outcome.success, isTrue, reason: outcome.message);
      return (advanceId: advanceId, periodId: pid);
    }

    test('⭐⭐ الإلغاء يُعيد السطور مستحقّة والكشف مسودة — لا موظف يظهر مستلماً',
        () async {
      // 🔴 **بلاغ المالك:** بعد إلغاء السلفة رجع المال إلى الخزينة، لكن
      //   الرواتب بقيت «مسدَّدة» في الكشف وفي بطاقة كل موظف وفي كل تقرير.
      //   السبب: `cancelAdvance` يحذف السندات ولا يعرف `salary_payments`.
      //   وحارس سند الرواتب (ع-٣١) لا يحميه لأنه يكتب على الجدول مباشرةً.
      final seed = await postedAdvanceWithPayroll();

      final before = await payrollRepo.getTotals(seed.periodId);
      expect(before.paidCount, 2, reason: 'الاعتماد سدّد الرواتب');

      await advanceRepo.cancelAdvance(advanceId: seed.advanceId);

      final after = await payrollRepo.getTotals(seed.periodId);
      expect(after.paidCount, 0,
          reason: 'مالٌ رجع للخزينة ورواتبه ما زالت مصروفة = دفترٌ يكذب');
      expect(after.unpaidIqd, closeTo(1100000, 0.001));

      final period = await db.payrollDao.getPeriodById(seed.periodId);
      expect(period!.status, PayrollStatusDb.draft);
      expect(period.postedAt, isNotNull,
          reason: 'تاريخ الاعتماد الأول يبقى شاهداً');

      // ولا سطر يشير إلى سلفة أو سند محذوف
      final entries = await payrollRepo.getEntries(seed.periodId);
      for (final e in entries) {
        expect(e.paymentStatus, PayrollPaymentStatusDb.unpaid);
        expect(e.voucherId, isNull);
        expect(e.advanceId, isNull);
        expect(e.paidAt, isNull);
      }
    });

    test('⭐ لا يبقى «مصروف سلفاً» يمنع إعادة الاستيراد', () async {
      final seed = await postedAdvanceWithPayroll();
      expect(await db.payrollDao.getPaidEmployeesForMonth(2025, 2),
          hasLength(2));

      await advanceRepo.cancelAdvance(advanceId: seed.advanceId);

      expect(await db.payrollDao.getPaidEmployeesForMonth(2025, 2), isEmpty);
    });

    test('⭐⭐ قسط سلفة الموظف يُعاد عند إلغاء السلفة', () async {
      final pid = await seedPayroll();

      // سلفة موظف على أحمد، يُخصم منها ١٠٠٬٠٠٠ في راتب شباط
      final empAdvance = await db.employeesDao.insertAdvance(
        CashAdvancesCompanion.insert(
          employeeId: Value(ahmedId),
          amount: 300000,
          advanceDate: DateTime(2025, 1, 5),
        ),
      );
      final entries = await payrollRepo.getEntries(pid);
      final ahmedEntry = entries.firstWhere((e) => e.employeeId == ahmedId);
      await payrollRepo.updateEntry(
        entryId: ahmedEntry.id,
        advanceRepayment: 100000,
        cashAdvanceId: empAdvance,
      );

      // مبلغ سطر السلفة يتبع الصافي بعد الخصم
      final totals = await payrollRepo.getTotals(pid);
      final advanceId = await seedAdvance(
          payrollLineAmount: totals.unpaidIqd);
      final lineId = await payrollLineId(advanceId);
      await advanceRepo.linkLineToPayroll(
          lineId: lineId, payrollPeriodId: pid);
      await advanceRepo.postAdvance(advanceId: advanceId);

      expect((await db.employeesDao.getAdvanceById(empAdvance))!.totalRepaid,
          closeTo(100000, 0.001));

      await advanceRepo.cancelAdvance(advanceId: advanceId);

      final after = await db.employeesDao.getAdvanceById(empAdvance);
      expect(after!.totalRepaid, closeTo(0, 0.001),
          reason: 'الخصم لم يقع فعلاً — بقاؤه يعني مالاً يختفي من السلفة');
      expect(after.status, 'pending');
    });

    test('إلغاء سلفة بلا رواتب يعمل كما كان', () async {
      final advanceId = await advanceRepo.createAdvance(
        advanceNumber: 'بصرة-9',
        projectTreasuryId: basraTreasury,
        advanceDate: DateTime(2025, 3, 1),
        projectName: 'البصرة',
      );
      await advanceRepo.createDraftFromExcel(
        advanceId: advanceId,
        fileName: 'x.xlsx',
        fileHash: 'hash-x',
        lines: [
          ParsedAdvanceLine(
            rowNumber: 1,
            date: DateTime(2025, 2, 10),
            amount: 200000,
            itemType: 'طعام',
            reason: 'مصاريف',
          ),
        ],
      );
      await advanceRepo.postAdvance(advanceId: advanceId);
      final info = await advanceRepo.cancelAdvance(advanceId: advanceId);
      expect(info.reversedAmount, closeTo(200000, 0.001));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // تجميع سندات الاعتماد (بلاغ المالك 2026-08-27)
  // ═══════════════════════════════════════════════════════════════════════

  group('سندات الاعتماد', () {
    test('⭐⭐ سند واحد للمصاريف وسند مستقلّ لكل سطر رواتب', () async {
      // 🔴 **بلاغ المالك:** ١٥٠ سطراً كانت تُنتج ١٥٠ سنداً — وأي تصحيح
      //   لاحق يعني حذفها واحداً واحداً. والرواتب اتُّخذ فيها القرار
      //   المعاكس منذ اليوم الأول: سند واحد والتفصيل في الكشف.
      final pid = await seedPayroll();
      final advanceId = await seedAdvance();
      final lineId = await payrollLineId(advanceId);
      await advanceRepo.linkLineToPayroll(
          lineId: lineId, payrollPeriodId: pid);

      final outcome = await advanceRepo.postAdvance(advanceId: advanceId);
      expect(outcome.success, isTrue, reason: outcome.message);

      final sarf = (await db.vouchersDao.getAllVouchers())
          .where((v) => !v.isDeleted && v.voucherType == 'sarf')
          .toList();
      expect(sarf, hasLength(2),
          reason: 'سطران فقط: مصاريف مجمَّعة + سطر رواتب معزول');

      // مجموع السندات = مجموع السلفة بالضبط
      final total = sarf.fold<double>(0, (s, v) => s + v.amount);
      expect(total, closeTo(450000 + 1100000, 0.001));

      // سند الرواتب يحمل بند «راتب» — به تلتقطه أداة السندات اليتيمة
      final payrollVoucher =
          sarf.firstWhere((v) => v.amount == 1100000);
      expect(payrollVoucher.itemType, 'راتب');

      // ⭐ واسم المستفيد يقول **ما هو السند** لا من كُتب في سطر الملف
      //   (بلاغ المالك 2026-08-27): كان يحمل اسم شخصٍ واحد وهو يغطّي كشف
      //   شهرٍ كامل — فيبدو في كشف الحساب راتبَ ذلك الشخص.
      expect(payrollVoucher.personName, contains('رواتب سلفة'));
      expect(payrollVoucher.personName, contains('بصرة-1'));
    });

    test('⭐ سلفة بلا رواتب: سند واحد لكل سطورها', () async {
      final advanceId = await advanceRepo.createAdvance(
        advanceNumber: 'بصرة-5',
        projectTreasuryId: basraTreasury,
        advanceDate: DateTime(2025, 3, 1),
        projectName: 'البصرة',
      );
      await advanceRepo.createDraftFromExcel(
        advanceId: advanceId,
        fileName: 'many.xlsx',
        fileHash: 'hash-many',
        lines: [
          for (var i = 1; i <= 12; i++)
            ParsedAdvanceLine(
              rowNumber: i,
              date: DateTime(2025, 2, 10),
              amount: 100000,
              itemType: 'بنزين',
              reason: 'مصروف $i',
            ),
        ],
      );

      await advanceRepo.postAdvance(advanceId: advanceId);

      final sarf = (await db.vouchersDao.getAllVouchers())
          .where((v) => !v.isDeleted && v.voucherType == 'sarf')
          .toList();
      expect(sarf, hasLength(1), reason: 'اثنا عشر سطراً = سندٌ واحد');
      expect(sarf.single.amount, closeTo(1200000, 0.001));

      // وكل السطور تشير إليه فيبقى الأثر مزدوج الاتجاه
      final lines = await db.advancesDao.getLines(advanceId);
      expect(lines.every((l) => l.voucherId == sarf.single.id), isTrue);
    });
  });
}
