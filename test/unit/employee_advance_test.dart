// ─────────────────────────────────────────────────────────────────────────────
// employee_advance_test.dart — سلف الموظفين: المنح والتسديد والإلغاء
//
// **من أين جاء هذا الملف؟** جرّب المالك سلف الموظفين (2026-08-27): منح ٥٠٠
// ألف · تسديد · حذف سند المنح من شاشة السندات — فكشف عطلين ماليَّين:
//
// 🔴 **ع-٣٨ — الباب الخامس:** حذف سند منح السلفة يُرجع المال إلى الخزينة
//   **ويترك السلفة قائمة على الموظف**. `softDeleteVoucher` يعرف سلف المشاريع
//   والرواتب — ولا يعرف `cash_advances`. فتزيد الخزينة بمبلغ بلا مقابل.
//
// 🔴 **ع-٣٩ — سندٌ لمالٍ لم يتحرّك:** تسديد سلفة بطريقة «خصم من الراتب» كان
//   يُنشئ **سند قبض** — والمال لم يدخل الخزينة، بل سيخرج راتبٌ أقلّ لاحقاً.
//   فيتضخّم الرصيد بمبلغ وهمي، ثم يُخصم من الراتب فعلاً فيُحتسب **مرّتين**.
//
// **ما يحرسه هذا الملف:**
//   • طريقة التسديد تحدّد الأثر: نقداً/بنكي ⇒ قبض · خصم من الراتب ⇒ لا شيء
//   • لا احتساب مزدوج بين التسديد اليدوي وخصم الراتب
//   • حذف سند سلفة الموظف **يُرفض** ويوجّه إلى إلغاء السلفة
//   • إلغاء السلفة يُرجع كل شيء: السلفة وأقساطها وسندها
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/core/services/payroll_calculator.dart';
import 'package:sales_management/core/services/payroll_row_parser.dart';
import 'package:sales_management/data/repositories/payroll_repository.dart';
import 'package:sales_management/data/repositories/voucher_repository.dart';

void main() {
  late AppDatabase db;
  late VoucherRepository voucherRepo;
  late int fiscalId;
  late int treasuryId;
  late int employeeId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    voucherRepo = VoucherRepository(db);

    fiscalId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2025',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31, 23, 59, 59),
      ),
    );
    treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(
          name: 'خزنة البصرة', kind: const Value('project')),
    );
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
    employeeId = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'حسن محمد',
        basicSalary: const Value(1000000),
        treasuryId: Value(treasuryId),
      ),
    );
  });

  tearDown(() async => db.close());

  Future<double> balance() async =>
      (await db.treasuriesDao.getTreasuryBalance(treasuryId))?.balanceIqd ?? 0;

  /// منح سلفة ٥٠٠ ألف بسند صرف — كما يفعل `grantAdvance`
  Future<({int advanceId, int voucherId})> grant({
    double amount = 500000,
  }) async {
    final number = await db.fiscalPeriodsDao.getNextVoucherNumber(
      fiscalPeriodId: fiscalId,
      voucherType: 'sarf',
    );
    final voucherId = await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: number,
        voucherType: 'sarf',
        treasuryId: treasuryId,
        fiscalPeriodId: fiscalId,
        amount: amount,
        voucherDate: DateTime(2025, 3, 1),
        personName: const Value('حسن محمد'),
        reason: const Value('سلفة للموظف حسن محمد'),
        itemType: const Value('سلفة'),
        linkedEntityId: Value(employeeId),
      ),
    );
    final advanceId = await db.employeesDao.insertAdvance(
      CashAdvancesCompanion.insert(
        amount: amount,
        advanceDate: DateTime(2025, 3, 1),
        employeeId: Value(employeeId),
        voucherId: Value(voucherId),
      ),
    );
    return (advanceId: advanceId, voucherId: voucherId);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ١. 🔴 حذف سند منح السلفة — الباب الخامس (ع-٣٨)
  // ═══════════════════════════════════════════════════════════════════════

  group('حذف سند سلفة الموظف من شاشة السندات', () {
    test('⭐⭐ يُرفض ويوجّه إلى إلغاء السلفة — وإلا زادت الخزينة بلا مقابل',
        () async {
      final g = await grant();
      expect(await balance(), closeTo(10000000 - 500000, 0.001));

      await expectLater(
        voucherRepo.deleteVoucher(g.voucherId),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          allOf(
            contains('سلفة'),
            contains('حسن محمد'),
            contains('ألغِ السلفة'),
          ),
        )),
        reason: 'حذفه كان يُرجع المال ويُبقي السلفة على الموظف — '
            'فيصير في الخزينة مالٌ بلا مقابل',
      );

      // ولا شيء تغيّر
      expect(await balance(), closeTo(10000000 - 500000, 0.001));
      final advance = await db.employeesDao.getAdvanceById(g.advanceId);
      expect(advance!.isDeleted, isFalse);
    });

    test('⭐ تعديل مبلغ سند السلفة يُرفض — يفصله عن سجلّها', () async {
      final g = await grant();
      await expectLater(
        db.vouchersDao.updateVoucher(
          VouchersCompanion(id: Value(g.voucherId), amount: const Value(1)),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('سند صرف عادي لا علاقة له بالسلف يُحذف كالمعتاد', () async {
      final n = await db.fiscalPeriodsDao.getNextVoucherNumber(
        fiscalPeriodId: fiscalId,
        voucherType: 'sarf',
      );
      final id = await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: n,
          voucherType: 'sarf',
          treasuryId: treasuryId,
          fiscalPeriodId: fiscalId,
          amount: 90000,
          voucherDate: DateTime(2025, 4, 1),
          itemType: const Value('بنزين'),
        ),
      );
      await voucherRepo.deleteVoucher(id);
      expect((await db.vouchersDao.getVoucherById(id))!.isDeleted, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٢. إلغاء سلفة الموظف — المسار المشروع
  // ═══════════════════════════════════════════════════════════════════════

  group('إلغاء سلفة موظف', () {
    test('⭐⭐ يُرجع كل شيء: السلفة وسندها والرصيد', () async {
      final g = await grant();

      await db.employeesDao.cancelEmployeeAdvance(
        advanceId: g.advanceId,
        reason: 'أعاد المبلغ في يومه',
      );

      expect(await balance(), closeTo(10000000, 0.001),
          reason: 'المال يرجع كاملاً — لا زيادة ولا نقص');

      final advance = await db.employeesDao.getAdvanceById(g.advanceId);
      expect(advance!.isDeleted, isTrue);
      expect((await db.vouchersDao.getVoucherById(g.voucherId))!.isDeleted,
          isTrue);
      expect(await db.employeesDao.getPendingAdvances(), isEmpty);
    });

    test('⭐ الأقساط النقدية وسنداتها تُلغى معها', () async {
      final g = await grant();

      // قسط نقدي ٢٠٠ ألف بسند قبض
      final kabdNumber = await db.fiscalPeriodsDao.getNextVoucherNumber(
        fiscalPeriodId: fiscalId,
        voucherType: 'kabd',
      );
      final kabdId = await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: kabdNumber,
          voucherType: 'kabd',
          treasuryId: treasuryId,
          fiscalPeriodId: fiscalId,
          amount: 200000,
          voucherDate: DateTime(2025, 3, 10),
          itemType: const Value('مرتجع صرف'),
        ),
      );
      await db.employeesDao.insertRepayment(
        repayment: CashAdvanceRepaymentsCompanion.insert(
          cashAdvanceId: g.advanceId,
          amount: 200000,
          repaymentDate: DateTime(2025, 3, 10),
          voucherId: Value(kabdId),
        ),
        advanceId: g.advanceId,
        newTotalRepaid: 200000,
        newStatus: 'partial',
      );
      expect(await balance(), closeTo(10000000 - 500000 + 200000, 0.001));

      await db.employeesDao.cancelEmployeeAdvance(
        advanceId: g.advanceId,
        reason: 'إلغاء كامل',
      );

      expect(await balance(), closeTo(10000000, 0.001),
          reason: 'السند وقسطه يُلغيان معاً — وإلا بقي أحدهما يُحرّك الرصيد');
      expect(await db.employeesDao.getRepaymentsByAdvance(g.advanceId),
          isEmpty);
    });

    test('سبب فارغ يُرفض', () async {
      final g = await grant();
      await expectLater(
        db.employeesDao
            .cancelEmployeeAdvance(advanceId: g.advanceId, reason: '  '),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٣. 🔴 سندٌ لمالٍ لم يتحرّك (ع-٣٩)
  // ═══════════════════════════════════════════════════════════════════════

  group('طريقة التسديد تحدّد الأثر', () {
    test('⭐⭐ «خصم من الراتب» لا يُنشئ سنداً ولا يمسّ الخزينة', () async {
      final g = await grant();
      final before = await balance();
      final vouchersBefore =
          (await db.vouchersDao.getAllVouchers()).where((v) => !v.isDeleted).length;

      await db.employeesDao.markForSalaryDeduction(
        advanceId: g.advanceId,
      );

      expect(await balance(), closeTo(before, 0.001),
          reason: 'المال لم يدخل الخزينة — سيخرج راتبٌ أقلّ لاحقاً');
      expect(
          (await db.vouchersDao.getAllVouchers())
              .where((v) => !v.isDeleted)
              .length,
          vouchersBefore,
          reason: 'سندٌ لمالٍ لم يتحرّك يُضخّم الرصيد برقم وهمي');

      // ولا قسط يُسجَّل الآن — يُسجَّل عند تسديد الراتب وحده
      expect(await db.employeesDao.getRepaymentsByAdvance(g.advanceId),
          isEmpty);
      final advance = await db.employeesDao.getAdvanceById(g.advanceId);
      expect(advance!.totalRepaid, closeTo(0, 0.001));
      expect(advance.status, 'pending',
          reason: 'ما زالت قائمة حتى يُخصم الراتب فعلاً');
    });

    test('⭐ «نقداً» يُنشئ قبضاً ويزيد الرصيد', () async {
      final g = await grant();
      final before = await balance();

      final n = await db.fiscalPeriodsDao.getNextVoucherNumber(
        fiscalPeriodId: fiscalId,
        voucherType: 'kabd',
      );
      final vid = await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: n,
          voucherType: 'kabd',
          treasuryId: treasuryId,
          fiscalPeriodId: fiscalId,
          amount: 500000,
          voucherDate: DateTime(2025, 3, 15),
          itemType: const Value('مرتجع صرف'),
        ),
      );
      await db.employeesDao.insertRepayment(
        repayment: CashAdvanceRepaymentsCompanion.insert(
          cashAdvanceId: g.advanceId,
          amount: 500000,
          repaymentDate: DateTime(2025, 3, 15),
          method: const Value('cash'),
          voucherId: Value(vid),
        ),
        advanceId: g.advanceId,
        newTotalRepaid: 500000,
        newStatus: 'paid',
      );

      expect(await balance(), closeTo(before + 500000, 0.001));
      expect((await db.employeesDao.getAdvanceById(g.advanceId))!.status,
          'paid');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٤. سلف الموظفين دفعةً واحدة — لتنبيه الاستيراد
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ المتبقّي لكل موظف يُقرأ باستعلام واحد لا باستعلام لكل موظف',
      () async {
    final second = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(fullName: 'علي كريم'),
    );
    final g = await grant();

    // قسط جزئي: المتبقّي ٣٠٠ ألف
    await db.employeesDao.updateRepaymentProgress(
      g.advanceId,
      newRepaid: 200000,
      newStatus: 'partial',
    );

    final map = await db.employeesDao
        .getPendingAdvancesForEmployees([employeeId, second]);

    expect(map[employeeId], closeTo(300000, 0.001),
        reason: 'المتبقّي لا المبلغ الأصلي');
    expect(map.containsKey(second), isFalse, reason: 'بلا سلف = بلا مفتاح');
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٥. 🔴 ع-٤٠ — إلغاء السلفة كان يحذف سند رواتب الشهر كلّه
  // ═══════════════════════════════════════════════════════════════════════

  group('سلفة خُصم منها في راتب مسدَّد', () {
    /// راتب مسدَّد بخصم ٢٥٠ ألف من سلفة الموظف — سيناريو المالك حرفياً
    Future<({int advanceId, int periodId, int entryId, int payrollVoucher})>
        payrollWithDeduction() async {
      final g = await grant();
      final payroll = PayrollRepository(db);

      final periodId = await payroll.createOrGetPeriod(year: 2025, month: 8);
      await payroll.importRows(
        periodId: periodId,
        rows: [
          ResolvedPayrollRow(
            employeeId: employeeId,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'حسن محمد',
              basicSalary: 1000000,
            ),
          ),
        ],
      );
      final entry = (await payroll.getEntries(periodId)).single;
      await payroll.updateEntry(
        entryId: entry.id,
        advanceRepayment: 250000,
        cashAdvanceId: g.advanceId,
      );
      final result = await payroll.payEntries(
        periodId: periodId,
        entryIds: [entry.id],
        treasuryId: treasuryId,
        paymentDate: DateTime(2025, 9, 1),
      );
      return (
        advanceId: g.advanceId,
        periodId: periodId,
        entryId: entry.id,
        payrollVoucher: result.voucherId,
      );
    }

    test('⭐⭐ إلغاء السلفة **يُرفض** — ولا يُمَسّ سند رواتب الشهر', () async {
      // 🔴 **بلاغ المالك 2026-08-27:** إلغاء السلفة حذف **سند رواتب الشهر
      //   كلّه** (يغطّي كل الموظفين) فرجع مالهم إلى الخزينة وبقيت سطورهم
      //   «مسدَّدة». السبب: قسط `salary_deduction` يحمل في `voucher_id`
      //   سندَ الرواتب (رُبط في المرحلة ٦ ليُعكَس بدقّة)، والحلقة كانت
      //   تحذف سند كل قسط ظنّاً أنه سند قبضٍ خاصّ به.
      final seed = await payrollWithDeduction();
      final balanceBefore = await balance();

      await expectLater(
        db.employeesDao.cancelEmployeeAdvance(
          advanceId: seed.advanceId,
          reason: 'محاولة إلغاء',
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          allOf(contains('خُصم'), contains('آب 2025'), contains('ألغِ تسديد')),
        )),
      );

      // ⭐ **سند الرواتب حيّ** — وهذا جوهر العطل
      final voucher = await db.vouchersDao.getVoucherById(seed.payrollVoucher);
      expect(voucher!.isDeleted, isFalse,
          reason: 'حذفه يُرجع رواتب الشهر كلّها ويترك سطورها «مسدَّدة»');
      expect(await balance(), closeTo(balanceBefore, 0.001));

      final entry = await db.payrollDao.getEntryById(seed.entryId);
      expect(entry!.paymentStatus, PayrollPaymentStatusDb.paid);
    });

    test('⭐⭐ المسار المشروع: ألغِ التسديد ⇒ يُعاد القسط ⇒ تُلغى السلفة',
        () async {
      final seed = await payrollWithDeduction();
      final payroll = PayrollRepository(db);

      // ١. إلغاء تسديد الراتب — يعكس القسط تلقائياً
      await payroll.unpayEntry(
        entryId: seed.entryId,
        reason: 'تصحيح',
      );
      final afterUnpay =
          await db.employeesDao.getAdvanceById(seed.advanceId);
      expect(afterUnpay!.totalRepaid, closeTo(0, 0.001));
      expect(await db.employeesDao.getRepaymentsByAdvance(seed.advanceId),
          isEmpty);

      // ٢. الآن تُلغى السلفة بلا اعتراض
      await db.employeesDao.cancelEmployeeAdvance(
        advanceId: seed.advanceId,
        reason: 'أعاد المبلغ',
      );

      expect(await balance(), closeTo(10000000, 0.001),
          reason: 'كل شيء رجع: الراتب والسلفة — بلا زيادة ولا نقص');
      expect((await db.employeesDao.getAdvanceById(seed.advanceId))!.isDeleted,
          isTrue);
    });

    test('⭐ سلفة بقسط **نقديّ** ما زال يُحذف سند قبضه — لا انحدار', () async {
      final g = await grant();
      final n = await db.fiscalPeriodsDao.getNextVoucherNumber(
        fiscalPeriodId: fiscalId,
        voucherType: 'kabd',
      );
      final kabdId = await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: n,
          voucherType: 'kabd',
          treasuryId: treasuryId,
          fiscalPeriodId: fiscalId,
          amount: 100000,
          voucherDate: DateTime(2025, 3, 20),
          itemType: const Value('مرتجع صرف'),
        ),
      );
      await db.employeesDao.insertRepayment(
        repayment: CashAdvanceRepaymentsCompanion.insert(
          cashAdvanceId: g.advanceId,
          amount: 100000,
          repaymentDate: DateTime(2025, 3, 20),
          method: const Value('cash'),
          voucherId: Value(kabdId),
        ),
        advanceId: g.advanceId,
        newTotalRepaid: 100000,
        newStatus: 'partial',
      );

      await db.employeesDao.cancelEmployeeAdvance(
        advanceId: g.advanceId,
        reason: 'إلغاء',
      );

      expect((await db.vouchersDao.getVoucherById(kabdId))!.isDeleted, isTrue,
          reason: 'القسط النقدي له سند قبضٍ خاصّ به — يُحذف معه');
      expect(await balance(), closeTo(10000000, 0.001));
    });
  });
}
