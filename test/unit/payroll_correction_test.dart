// ─────────────────────────────────────────────────────────────────────────────
// payroll_correction_test.dart — تصحيح الرواتب المسدَّدة وإغلاق ثغرة السند
//
// **من أين جاء هذا الملف؟** اختبر المالك النظام يدوياً (2026-08-26) محاولاً
// **الاحتيال عليه عمداً**: دفع راتباً كاملاً لموظف له أيام غياب، ثم حذف سند
// الصرف من شاشة السندات ليلتفّ على قاعدة «المسدَّد لا يُعدَّل».
//
// 🔴 **وما كشفه ذلك الالتفاف أخطر مما قصده:** حذفُ سند الرواتب كان يُعيد المال
//   إلى الخزينة ويترك سطور الرواتب **معلَّمة مسدَّدة**. أي راتبٌ يظهر مصروفاً
//   في كل تقرير ولم يخرج قرشٌ واحد — وهو **معكوس ع-٢٨** تماماً.
//
//   والأسوأ: استيراد ملف الشهر بعدها كان يستبعد الموظف بحجة «مصروف سلفاً»،
//   فلا يُدفع له أبداً بينما الكشف يشهد أنه قبض.
//
// **والدرس الثاني (ع-٣٢):** قاعدة «المسدَّد لا يُعدَّل ولا يُحذف» وُضعت لمنع
//   تزوير التاريخ، فمنعت معها **التصحيح المشروع** — فدفعت المالك إلى الالتفاف
//   على النظام كله. حاجزٌ يدفع صاحبه للالتفاف عليه أسوأ من غيابه.
//
// **ما يحرسه هذا الملف:**
//   • حذف سند رواتب من شاشة السندات **يُرفض** ويوجّه إلى المسار الصحيح
//   • `unpayEntry` يعكس **كل شيء معاً**: السطر · السند · قسط سلفة الموظف
//   • الإلغاء ضمن دفعة يُنقص السند بحصة الموظف **وحده**
//   • التصحيح بحالتيه: خطأ إدخال ⇒ المال يرجع · صُرف زائداً ⇒ سلفة بالفرق
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/services/payroll_calculator.dart';
import 'package:sales_management/core/services/payroll_row_parser.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/payroll_repository.dart';
import 'package:sales_management/data/repositories/voucher_repository.dart';
import 'package:sales_management/domain/models/voucher_model.dart';

void main() {
  late AppDatabase db;
  late PayrollRepository repo;
  late VoucherRepository voucherRepo;
  late int fiscalId;
  late int treasuryId;
  late int hasanId;
  late int saraId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PayrollRepository(db);
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
        amount: 20000000,
        voucherDate: DateTime(2025, 1, 5),
      ),
    );

    hasanId = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'حسن محمد علي جاسم',
        position: const Value('مهندس'),
        basicSalary: const Value(1750000),
        treasuryId: Value(treasuryId),
      ),
    );
    saraId = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'سارة حسن',
        basicSalary: const Value(500000),
        treasuryId: Value(treasuryId),
      ),
    );
  });

  tearDown(() async => db.close());

  Future<double> balance() async =>
      (await db.treasuriesDao.getTreasuryBalance(treasuryId))?.balanceIqd ?? 0;

  /// سيناريو المالك: راتب حسن كاملاً (٣٠ يوماً) صُرف مباشرةً عن أيلول
  Future<PaySingleSalaryResult> payHasanDirectly({double amount = 1750000}) {
    return repo.paySingleEmployee(
      employeeId: hasanId,
      year: 2025,
      month: 9,
      treasuryId: treasuryId,
      basicSalary: amount,
      paymentDate: DateTime(2025, 10, 1),
    );
  }

  /// كشف شهر بموظفَين يُسدَّدان بدفعة واحدة
  Future<({int periodId, int hasanEntry, int saraEntry, int voucherId})>
      payBatch() async {
    final periodId = await repo.createOrGetPeriod(year: 2025, month: 8);
    await repo.importRows(
      periodId: periodId,
      rows: [
        ResolvedPayrollRow(
          employeeId: hasanId,
          row: const ParsedPayrollRow(
            rowNumber: 1,
            rowLabel: 'صف 1',
            employeeName: 'حسن محمد علي جاسم',
            basicSalary: 1750000,
          ),
        ),
        ResolvedPayrollRow(
          employeeId: saraId,
          row: const ParsedPayrollRow(
            rowNumber: 2,
            rowLabel: 'صف 2',
            employeeName: 'سارة حسن',
            basicSalary: 500000,
          ),
        ),
      ],
    );
    final entries = await db.payrollDao.getEntries(periodId);
    final result = await repo.payEntries(
      periodId: periodId,
      entryIds: entries.map((e) => e.id).toList(),
      treasuryId: treasuryId,
      paymentDate: DateTime(2025, 9, 1),
    );
    return (
      periodId: periodId,
      hasanEntry: entries.firstWhere((e) => e.employeeId == hasanId).id,
      saraEntry: entries.firstWhere((e) => e.employeeId == saraId).id,
      voucherId: result.voucherId,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ١. 🔴 ثغرة حذف السند — اختبار الإثبات
  // ═══════════════════════════════════════════════════════════════════════

  group('حذف سند الرواتب من شاشة السندات', () {
    test('⭐⭐ يُرفض ويوجّه إلى شاشة الرواتب — وإلا بقي راتبٌ مصروفاً بلا مال',
        () async {
      final r = await payHasanDirectly();

      await expectLater(
        voucherRepo.deleteVoucher(r.voucherId),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          allOf(
            contains('رواتب'),
            contains('أيلول 2025'),
            contains('إلغاء التسديد'),
          ),
        )),
        reason: 'حذفه كان يُعيد المال ويُبقي السطر «مسدَّداً» — '
            'راتبٌ يظهر مصروفاً ولم يخرج قرش (معكوس ع-٢٨)',
      );

      // ولا شيء تغيّر: السند حيّ والسطر مسدَّد والرصيد ناقص
      final entry = await db.payrollDao.getEntryById(r.entryId);
      expect(entry!.paymentStatus, PayrollPaymentStatusDb.paid);
      expect(await balance(), closeTo(20000000 - 1750000, 0.001));
    });

    test('⭐ تعديل مبلغ سند رواتب يُرفض — يفصله عن كشفه بصمت', () async {
      final r = await payHasanDirectly();
      final voucher = await db.vouchersDao.getVoucherById(r.voucherId);

      await expectLater(
        voucherRepo.updateVoucher(
          VoucherModel(
            id: voucher!.id,
            voucherNumber: voucher.voucherNumber,
            voucherType: voucher.voucherType,
            treasuryId: voucher.treasuryId,
            fiscalPeriodId: voucher.fiscalPeriodId,
            // المبلغ وحده هو ما تغيّر — وهو ما يفصل السند عن كشفه
            amount: 1000000,
            currency: voucher.currency,
            voucherDate: voucher.voucherDate,
          ),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message, 'الرسالة', contains('رواتب'))),
      );
    });

    test('سند عادي لا علاقة له بالرواتب يُحذف كالمعتاد', () async {
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
          amount: 100000,
          voucherDate: DateTime(2025, 5, 1),
        ),
      );
      await voucherRepo.deleteVoucher(id);
      expect((await db.vouchersDao.getVoucherById(id))!.isDeleted, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٢. إلغاء التسديد — المسار المشروع
  // ═══════════════════════════════════════════════════════════════════════

  group('إلغاء تسديد راتب', () {
    test('⭐⭐ راتبٌ دُفع وحده: يُحذف سنده ويعود الرصيد والسطر معاً', () async {
      final r = await payHasanDirectly();
      expect(await balance(), closeTo(18250000, 0.001));

      await repo.unpayEntry(
        entryId: r.entryId,
        reason: 'أُدخل المبلغ خطأً',
      );

      expect(await balance(), closeTo(20000000, 0.001),
          reason: 'المال يرجع كاملاً');
      final entry = await db.payrollDao.getEntryById(r.entryId);
      expect(entry!.paymentStatus, PayrollPaymentStatusDb.unpaid);
      expect(entry.voucherId, isNull);
      expect(entry.paidAt, isNull);
      expect((await db.vouchersDao.getVoucherById(r.voucherId))!.isDeleted,
          isTrue,
          reason: 'سندٌ لموظف واحد لا معنى لبقائه بصفر');

      final period = await db.payrollDao.getPeriodById(r.periodId);
      expect(period!.status, PayrollStatusDb.draft);
      expect(period.postedAt, isNotNull,
          reason: 'تاريخ الاعتماد الأول يبقى شاهداً — لا يُمحى');
    });

    test('⭐⭐ ضمن دفعة: مبلغ السند ينقص بحصته وحده والبقية مسدَّدون', () async {
      final b = await payBatch();
      expect(await balance(), closeTo(20000000 - 2250000, 0.001));

      await repo.unpayEntry(entryId: b.hasanEntry, reason: 'تصحيح');

      final voucher = await db.vouchersDao.getVoucherById(b.voucherId);
      expect(voucher!.isDeleted, isFalse,
          reason: 'السند يغطّي سارة أيضاً — حذفه يُلغي راتبها بلا سبب');
      expect(voucher.amount, closeTo(500000, 0.001));
      expect(await balance(), closeTo(20000000 - 500000, 0.001));

      final sara = await db.payrollDao.getEntryById(b.saraEntry);
      expect(sara!.paymentStatus, PayrollPaymentStatusDb.paid);
      expect(sara.voucherId, b.voucherId);
    });

    test('⭐⭐ قسط سلفة الموظف **يُعكَس** — وإلا بقيت السلفة منقوصة بلا مقابل',
        () async {
      // سلفة ٥٠٠٬٠٠٠ على حسن، يُخصم منها ٢٠٠٬٠٠٠ من راتب آب
      final advanceId = await db.employeesDao.insertAdvance(
        CashAdvancesCompanion.insert(
          employeeId: Value(hasanId),
          amount: 500000,
          advanceDate: DateTime(2025, 7, 1),
        ),
      );

      final periodId = await repo.createOrGetPeriod(year: 2025, month: 8);
      await repo.importRows(
        periodId: periodId,
        rows: [
          ResolvedPayrollRow(
            employeeId: hasanId,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'حسن محمد علي جاسم',
              basicSalary: 1750000,
            ),
          ),
        ],
      );
      final entry = (await db.payrollDao.getEntries(periodId)).single;
      await repo.updateEntry(
        entryId: entry.id,
        advanceRepayment: 200000,
        cashAdvanceId: advanceId,
      );
      await repo.payEntries(
        periodId: periodId,
        entryIds: [entry.id],
        treasuryId: treasuryId,
        paymentDate: DateTime(2025, 9, 1),
      );

      final afterPay = await db.employeesDao.getAdvanceById(advanceId);
      expect(afterPay!.totalRepaid, closeTo(200000, 0.001));
      expect(afterPay.status, 'partial');

      await repo.unpayEntry(entryId: entry.id, reason: 'إلغاء للتصحيح');

      final afterUnpay = await db.employeesDao.getAdvanceById(advanceId);
      expect(afterUnpay!.totalRepaid, closeTo(0, 0.001),
          reason: 'الخصم لم يقع فعلاً — بقاؤه يعني مالاً يختفي من السلفة');
      expect(afterUnpay.status, 'pending');

      final repayments =
          await db.employeesDao.getRepaymentsByAdvance(advanceId);
      expect(repayments, isEmpty, reason: 'القسط نفسه يُحذف لا يُترك يتيماً');
    });

    test('⭐ سبب فارغ يُرفض في الطبقة العميقة', () async {
      final r = await payHasanDirectly();
      await expectLater(
        repo.unpayEntry(entryId: r.entryId, reason: '   '),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'الرسالة', contains('سبب'))),
      );
    });

    test('سطر غير مسدَّد أصلاً يُرفض إلغاؤه', () async {
      final periodId = await repo.createOrGetPeriod(year: 2025, month: 8);
      await repo.importRows(
        periodId: periodId,
        rows: [
          ResolvedPayrollRow(
            employeeId: hasanId,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'حسن محمد علي جاسم',
              basicSalary: 1750000,
            ),
          ),
        ],
      );
      final entry = (await db.payrollDao.getEntries(periodId)).single;
      await expectLater(
        repo.unpayEntry(entryId: entry.id, reason: 'أي سبب'),
        throwsA(isA<StateError>()),
      );
    });

    test('⭐ بعد الإلغاء لا يعود الموظف «مصروفاً سلفاً» في الاستيراد', () async {
      final r = await payHasanDirectly();
      expect(await db.payrollDao.getPaidEmployeesForMonth(2025, 9), hasLength(1));

      await repo.unpayEntry(entryId: r.entryId, reason: 'تصحيح');

      expect(await db.payrollDao.getPaidEmployeesForMonth(2025, 9), isEmpty,
          reason: 'وإلا استُبعد من ملف الشهر فلا يُدفع له أبداً');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٣. تصحيح راتب مسدَّد — سيناريو المالك حرفياً
  // ═══════════════════════════════════════════════════════════════════════

  group('تصحيح راتب مسدَّد', () {
    test('⭐⭐ خطأ إدخال: الفرق يرجع للخزينة وينقص مبلغ السند', () async {
      final r = await payHasanDirectly();

      await repo.correctPaidEntry(
        entryId: r.entryId,
        newBasicSalary: 1750000,
        newAbsenceDays: 4,
        reason: 'نُسي احتساب ٤ أيام غياب',
        mode: PayrollCorrectionMode.dataEntryError,
      );

      final entry = await db.payrollDao.getEntryById(r.entryId);
      expect(entry!.netAmountIqd, closeTo(1516667, 1));
      expect(entry.paymentStatus, PayrollPaymentStatusDb.paid,
          reason: 'التصحيح لا يُلغي الصرف — يُصحّح مبلغه');
      expect(entry.absenceDays, 4);

      final voucher = await db.vouchersDao.getVoucherById(r.voucherId);
      expect(voucher!.amount, closeTo(1516667, 1));
      expect(await balance(), closeTo(20000000 - 1516667, 1),
          reason: 'المال لم يخرج زائداً أصلاً — فيرجع الفرق');

      expect(entry.notes, contains('نُسي احتساب'),
          reason: 'السبب يبقى في السطر لا في سجل التدقيق وحده');
    });

    test('⭐⭐ صُرف زائداً فعلاً: السند كما هو ويُنشأ سلفة بالفرق', () async {
      final r = await payHasanDirectly();

      await repo.correctPaidEntry(
        entryId: r.entryId,
        newBasicSalary: 1750000,
        newAbsenceDays: 4,
        reason: 'استلم المبلغ كاملاً نقداً',
        mode: PayrollCorrectionMode.overpaid,
      );

      final voucher = await db.vouchersDao.getVoucherById(r.voucherId);
      expect(voucher!.amount, closeTo(1750000, 1),
          reason: 'المال خرج فعلاً — تقليل السند يكذب على الخزينة');
      expect(await balance(), closeTo(20000000 - 1750000, 1));

      final advances = (await db.employeesDao.getPendingAdvances())
          .where((a) => a.employeeId == hasanId)
          .toList();
      expect(advances, hasLength(1));
      expect(advances.single.amount, closeTo(233333, 1),
          reason: 'الفرق صار ديناً على الموظف يُخصم من راتب قادم');
      expect(advances.single.reason, contains('أيلول 2025'));
    });

    test('⭐ التصحيح لأكثر يُزيد السند ويمرّ بحارس الرصيد', () async {
      final r = await payHasanDirectly(amount: 1000000);

      await repo.correctPaidEntry(
        entryId: r.entryId,
        newBasicSalary: 1750000,
        reason: 'الراتب الأساسي كان خطأً',
        mode: PayrollCorrectionMode.dataEntryError,
      );

      final voucher = await db.vouchersDao.getVoucherById(r.voucherId);
      expect(voucher!.amount, closeTo(1750000, 1));
      expect(await balance(), closeTo(20000000 - 1750000, 1));
    });

    test('⭐ تصحيح لأكثر بلا رصيد كافٍ يُرفض ولا يترك أثراً', () async {
      final r = await payHasanDirectly();
      final before = await balance();

      await expectLater(
        repo.correctPaidEntry(
          entryId: r.entryId,
          newBasicSalary: 99000000,
          reason: 'مبالغة متعمَّدة',
          mode: PayrollCorrectionMode.dataEntryError,
        ),
        throwsA(isA<StateError>()),
      );

      expect(await balance(), closeTo(before, 0.001));
      final entry = await db.payrollDao.getEntryById(r.entryId);
      expect(entry!.netAmountIqd, closeTo(1750000, 0.001));
    });

    test('⭐ سبب فارغ يُرفض', () async {
      final r = await payHasanDirectly();
      await expectLater(
        repo.correctPaidEntry(
          entryId: r.entryId,
          newBasicSalary: 1500000,
          reason: '',
          mode: PayrollCorrectionMode.dataEntryError,
        ),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'الرسالة', contains('سبب'))),
      );
    });

    test('التصحيح ضمن دفعة يُنقص السند بالفرق ولا يمسّ بقية السطور', () async {
      final b = await payBatch();

      await repo.correctPaidEntry(
        entryId: b.hasanEntry,
        newBasicSalary: 1750000,
        newAbsenceDays: 4,
        reason: 'غياب لم يُحتسب',
        mode: PayrollCorrectionMode.dataEntryError,
      );

      final voucher = await db.vouchersDao.getVoucherById(b.voucherId);
      expect(voucher!.amount, closeTo(1516667 + 500000, 1));

      final sara = await db.payrollDao.getEntryById(b.saraEntry);
      expect(sara!.netAmountIqd, closeTo(500000, 0.001));
      expect(sara.paymentStatus, PayrollPaymentStatusDb.paid);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٤. تفسير الفرق باسم صاحبه — سيناريو المالك حرفياً
  // ═══════════════════════════════════════════════════════════════════════

  group('مقارنة المصروف سلفاً بما يحسبه الملف', () {
    test('⭐⭐ تُعيد المدفوع والمحسوب والفرق **والأيام**', () async {
      await payHasanDirectly();

      final comparison = await repo.comparePaidWithFile(
        year: 2025,
        month: 9,
        rows: [
          (
            employeeId: hasanId,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'حسن محمد علي جاسم',
              basicSalary: 1750000,
              absenceDays: 4,
            ),
          ),
        ],
      );

      expect(comparison, hasLength(1));
      final c = comparison.single;
      expect(c.employeeName, 'حسن محمد علي جاسم');
      expect(c.paidIqd, closeTo(1750000, 1));
      expect(c.fileIqd, closeTo(1516667, 1));
      expect(c.difference, closeTo(233333, 1));
      expect(c.paidDays, 30, reason: 'دُفع له شهر كامل');
      expect(c.fileDays, 26, reason: '٣٠ ناقص ٤ أيام غياب');
      expect(c.isOverpaid, isTrue);
    });

    test('لا فرق ⇒ لا يُذكَر شيء — التنبيه بلا سبب يُدرّب العين على تخطّيه',
        () async {
      await payHasanDirectly(amount: 1750000);

      final comparison = await repo.comparePaidWithFile(
        year: 2025,
        month: 9,
        rows: [
          (
            employeeId: hasanId,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'حسن محمد علي جاسم',
              basicSalary: 1750000,
            ),
          ),
        ],
      );
      expect(comparison.single.difference, closeTo(0, 1));
      expect(comparison.single.hasGap, isFalse);
    });

    test('⭐ رقم الملف يُخزَّن في السطر المسدَّد **بلا مسّ أي مبلغ مالي**',
        () async {
      final r = await payHasanDirectly();

      await repo.importRows(
        periodId: r.periodId,
        rows: [
          ResolvedPayrollRow(
            employeeId: hasanId,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'حسن محمد علي جاسم',
              basicSalary: 1750000,
              absenceDays: 4,
            ),
          ),
        ],
      );

      final entry = await db.payrollDao.getEntryById(r.entryId);
      expect(entry!.netAmountIqd, closeTo(1750000, 0.001),
          reason: 'المال خرج بهذا الرقم — لا يُعاد حسابه من ملف');
      expect(entry.fileNetAmount, closeTo(1516667, 1),
          reason: 'ويبقى رقم الملف محفوظاً ليُفسَّر الفرق في الكشف لاحقاً');
      expect(entry.paymentStatus, PayrollPaymentStatusDb.paid);
      expect(await balance(), closeTo(20000000 - 1750000, 0.001));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٥. 🔴 حذف الكشف — الثغرة الثالثة من البابِ الثالث (ع-٣٣)
  // ═══════════════════════════════════════════════════════════════════════

  group('حذف كشف فيه رواتب مصروفة', () {
    /// سيناريو المالك حرفياً: موظفان دُفع لهما مباشرةً، ثم استُورد ملف الشهر
    /// فأضاف ثالثاً ⇒ الكشف يعود مسودة وفيه مالٌ خرج فعلاً
    Future<({int periodId, int hasanEntry, int saraEntry})> seedMixed() async {
      final h = await payHasanDirectly();
      await repo.paySingleEmployee(
        employeeId: saraId,
        year: 2025,
        month: 9,
        treasuryId: treasuryId,
        basicSalary: 900000,
        paymentDate: DateTime(2025, 10, 1),
      );

      final third = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(fullName: 'موظف ثالث'),
      );
      await repo.importRows(
        periodId: h.periodId,
        rows: [
          ResolvedPayrollRow(
            employeeId: third,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'موظف ثالث',
              basicSalary: 500000,
            ),
          ),
        ],
      );

      final entries = await db.payrollDao.getEntries(h.periodId);
      return (
        periodId: h.periodId,
        hasanEntry: h.entryId,
        saraEntry: entries.firstWhere((e) => e.employeeId == saraId).id,
      );
    }

    test('⭐⭐ الحذف بلا قرار في مصير المال **يُرفض**', () async {
      final seed = await seedMixed();
      final before = await balance();

      await expectLater(
        repo.deletePeriod(seed.periodId),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          allOf(contains('رواتب مصروفة'), contains('2650000')),
        )),
        reason: 'كان يُحذف بصمت فيبقى المال خارج الخزينة بلا سجل — '
            'وإعادة الاستيراد تُدرج أصحابه مستحقّين من جديد',
      );

      expect(await balance(), closeTo(before, 0.001));
      expect(await db.payrollDao.getPeriodById(seed.periodId), isNotNull);
    });

    test('⭐⭐ «ألغِ وأرجِع» يُعيد المال ويحذف السندات والكشف معاً', () async {
      final seed = await seedMixed();
      expect(await balance(), closeTo(20000000 - 2650000, 0.001));

      final result = await repo.deletePeriod(
        seed.periodId,
        mode: PayrollDeleteMode.reverseAndDelete,
        reason: 'الكشف بُني على ملف خاطئ',
      );

      expect(result.deletedPeriod, isTrue);
      expect(result.reversedCount, 2);
      expect(result.reversedTotalIqd, closeTo(2650000, 0.001));

      expect(await balance(), closeTo(20000000, 0.001),
          reason: 'المال يرجع كاملاً — وهو جوهر العطل');

      final live = (await db.vouchersDao.getAllVouchers())
          .where((v) => !v.isDeleted && v.voucherType == 'sarf')
          .toList();
      expect(live, isEmpty, reason: 'سندٌ بلا سطر يقابله = مالٌ بلا سجل');

      expect(await db.payrollDao.getPeriodById(seed.periodId), isNotNull);
      expect((await db.payrollDao.getPeriodById(seed.periodId))!.isDeleted,
          isTrue);
      expect(await repo.getOrphanPayrollVouchers(), isEmpty);
    });

    test('⭐⭐ «احذف المستحقّ فقط» يُبقي المصروف بسنده في كشفه', () async {
      final seed = await seedMixed();

      final result = await repo.deletePeriod(
        seed.periodId,
        mode: PayrollDeleteMode.unpaidOnly,
      );

      expect(result.deletedPeriod, isFalse);
      expect(result.removedUnpaid, 1);

      // المال كما هو — لم يُمَسّ شيء منه
      expect(await balance(), closeTo(20000000 - 2650000, 0.001));

      final entries = await db.payrollDao.getEntries(seed.periodId);
      expect(entries.length, 2);
      expect(entries.every((e) => e.paymentStatus == PayrollPaymentStatusDb.paid),
          isTrue);

      // ⭐ والكشف يبقى ظاهراً للاستيراد ⇒ لا يُدفع الراتب مرّتين
      expect(await db.payrollDao.getPaidEmployeesForMonth(2025, 9),
          hasLength(2));
    });

    test('⭐ «ألغِ وأرجِع» بلا سبب مكتوب يُرفض', () async {
      final seed = await seedMixed();
      await expectLater(
        repo.deletePeriod(seed.periodId,
            mode: PayrollDeleteMode.reverseAndDelete, reason: '  '),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'الرسالة', contains('سبب'))),
      );
      expect(await balance(), closeTo(20000000 - 2650000, 0.001));
    });

    test('كشف بلا مدفوع يُحذف كما كان — بلا حوار ولا سبب', () async {
      final periodId = await repo.createOrGetPeriod(year: 2025, month: 7);
      await repo.importRows(
        periodId: periodId,
        rows: [
          ResolvedPayrollRow(
            employeeId: hasanId,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'حسن محمد علي جاسم',
              basicSalary: 1750000,
            ),
          ),
        ],
      );

      final result = await repo.deletePeriod(periodId);
      expect(result.deletedPeriod, isTrue);
      expect(result.reversedCount, 0);
      expect(await balance(), closeTo(20000000, 0.001));
    });

    test('⭐ أثر الحذف يُقرأ قبل الحوار بأرقامه الصحيحة', () async {
      final seed = await seedMixed();
      final impact = await repo.getDeletionImpact(seed.periodId);

      expect(impact.hasPaid, isTrue);
      expect(impact.paidCount, 2);
      expect(impact.paidTotalIqd, closeTo(2650000, 0.001));
      expect(impact.unpaidCount, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٦. السندات اليتيمة — شبكة الأمان الأخيرة
  // ═══════════════════════════════════════════════════════════════════════

  group('سندات الرواتب اليتيمة', () {
    /// تُصنَع بالحذف الناعم المباشر للسطر — أي بابٍ لم نتوقّعه يُنتج هذا
    Future<int> makeOrphan() async {
      final r = await payHasanDirectly();
      await db.employeesDao.softDeleteSalaryPayment(r.entryId);
      return r.voucherId;
    }

    test('⭐⭐ تُكشَف بمبلغها وبيانها — ولا تلتقط سندات الصرف العادية',
        () async {
      final voucherId = await makeOrphan();

      // سند صرف عادي لا علاقة له بالرواتب
      final n = await db.fiscalPeriodsDao.getNextVoucherNumber(
        fiscalPeriodId: fiscalId,
        voucherType: 'sarf',
      );
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: n,
          voucherType: 'sarf',
          treasuryId: treasuryId,
          fiscalPeriodId: fiscalId,
          amount: 50000,
          voucherDate: DateTime(2025, 5, 1),
          itemType: const Value('بنزين'),
        ),
      );

      final orphans = await repo.getOrphanPayrollVouchers();
      expect(orphans, hasLength(1));
      expect(orphans.single.voucherId, voucherId);
      expect(orphans.single.amount, closeTo(1750000, 0.001));
      expect(orphans.single.personName, 'حسن محمد علي جاسم');
      expect(orphans.single.reason, contains('أيلول 2025'));
      expect(orphans.single.treasuryName, 'خزنة البصرة');
    });

    test('⭐⭐ حذفها يُرجع المال إلى الخزينة', () async {
      final voucherId = await makeOrphan();
      expect(await balance(), closeTo(20000000 - 1750000, 0.001));

      await repo.deleteOrphanPayrollVoucher(
        voucherId: voucherId,
        reason: 'بقي بعد حذف الكشف ولم يُسلَّم',
      );

      expect(await balance(), closeTo(20000000, 0.001));
      expect(await repo.getOrphanPayrollVouchers(), isEmpty);
    });

    test('⭐ سندٌ عاد له سطر حيّ لا يُحذف — الفحص يُعاد لحظة الحذف', () async {
      final r = await payHasanDirectly();
      await expectLater(
        repo.deleteOrphanPayrollVoucher(
          voucherId: r.voucherId,
          reason: 'محاولة',
        ),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'الرسالة', contains('لم يعد يتيماً'))),
      );
      expect(await balance(), closeTo(20000000 - 1750000, 0.001));
    });

    test('سبب فارغ يُرفض', () async {
      final voucherId = await makeOrphan();
      await expectLater(
        repo.deleteOrphanPayrollVoucher(voucherId: voucherId, reason: ''),
        throwsA(isA<StateError>()),
      );
    });

    test('⭐ لا سندات يتيمة في المسار السليم', () async {
      await payHasanDirectly();
      expect(await repo.getOrphanPayrollVouchers(), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٧. اسم المشروع في سند الرواتب (بلاغ المالك)
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ سند رواتب من خزينة مشروع يحمل اسم المشروع — ليجده فلتر السندات',
      () async {
    final r = await payHasanDirectly();
    final voucher = await db.vouchersDao.getVoucherById(r.voucherId);
    expect(voucher!.projectName, 'خزنة البصرة',
        reason: 'كان فارغاً فلا يظهر السند عند فلترة «المشروع: البصرة» — '
            'والمالك يرى الخزينة والمشروع شيئاً واحداً بحقّ');
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٨. إلغاء تسديد الشهر · والكاشف المرآة (ع-٤٠)
  // ═══════════════════════════════════════════════════════════════════════

  group('إلغاء تسديد الشهر كاملاً', () {
    test('⭐⭐ يُعيد كل السطور مستحقّة والكشف مسودة والمال كاملاً', () async {
      // 🔑 بلاغ المالك 2026-08-27: الكشف المُسدَّد كان بلا أي زرّ للتصحيح،
      //   فلجأ إلى الالتفاف — وكشف بذلك ع-٤٠.
      final periodId = await repo.createOrGetPeriod(year: 2025, month: 8);
      await repo.importRows(
        periodId: periodId,
        rows: [
          ResolvedPayrollRow(
            employeeId: hasanId,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'حسن محمد علي جاسم',
              basicSalary: 1750000,
            ),
          ),
          ResolvedPayrollRow(
            employeeId: saraId,
            row: const ParsedPayrollRow(
              rowNumber: 2,
              rowLabel: 'صف 2',
              employeeName: 'سارة حسن',
              basicSalary: 900000,
            ),
          ),
        ],
      );
      final entries = await db.payrollDao.getEntries(periodId);
      await repo.payEntries(
        periodId: periodId,
        entryIds: entries.map((e) => e.id).toList(),
        treasuryId: treasuryId,
        paymentDate: DateTime(2025, 9, 1),
      );
      expect(await balance(), closeTo(20000000 - 2650000, 0.001));

      final result = await repo.unpayPeriod(
        periodId: periodId,
        reason: 'سُدِّد بملف خاطئ',
      );

      expect(result.count, 2);
      expect(result.totalIqd, closeTo(2650000, 0.001));
      expect(await balance(), closeTo(20000000, 0.001));

      final period = await db.payrollDao.getPeriodById(periodId);
      expect(period!.status, PayrollStatusDb.draft);
      expect(period.isDeleted, isFalse,
          reason: '**يبقى الكشف** — الفرق عن «حذف الكشف»');

      final after = await db.payrollDao.getTotals(periodId);
      expect(after.entryCount, 2, reason: 'السطور كما هي لتُصحَّح وتُسدَّد');
      expect(after.paidCount, 0);

      final live = (await db.vouchersDao.getAllVouchers())
          .where((v) => !v.isDeleted && v.voucherType == 'sarf');
      expect(live, isEmpty);
    });

    test('⭐ سبب فارغ يُرفض · وكشفٌ بلا مسدَّد يُرفض', () async {
      final periodId = await repo.createOrGetPeriod(year: 2025, month: 8);
      await repo.importRows(
        periodId: periodId,
        rows: [
          ResolvedPayrollRow(
            employeeId: hasanId,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'حسن محمد علي جاسم',
              basicSalary: 1750000,
            ),
          ),
        ],
      );

      await expectLater(
        repo.unpayPeriod(periodId: periodId, reason: '  '),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        repo.unpayPeriod(periodId: periodId, reason: 'سبب'),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'الرسالة', contains('لا رواتب مسدَّدة'))),
      );
    });
  });

  group('كاشف الرواتب المسدَّدة بسندٍ محذوف', () {
    test('⭐⭐ يلتقط السطور التي فقدت سندها — ولا يلتقط السليمة', () async {
      final r = await payHasanDirectly();
      expect(await repo.getStalePaidPayrolls(), isEmpty,
          reason: 'راتبٌ مسدَّد بسند حيّ ليس عالقاً');

      // نحاكي ما وقع في ع-٤٠: حُذف السند من حيث لا يتوقّع النظام
      await (db.update(db.vouchers)
            ..where((v) => v.id.equals(r.voucherId)))
          .write(VouchersCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
      ));

      final stale = await repo.getStalePaidPayrolls();
      expect(stale, hasLength(1));
      expect(stale.single.periodId, r.periodId);
      expect(stale.single.entryCount, 1);
      expect(stale.single.totalIqd, closeTo(1750000, 0.001));
      expect(stale.single.periodLabel, 'أيلول 2025');
    });

    test('⭐⭐ «أعِدها مستحقّة» تُصلح الحالة وتُفرغ الكاشف', () async {
      final r = await payHasanDirectly();
      await (db.update(db.vouchers)
            ..where((v) => v.id.equals(r.voucherId)))
          .write(VouchersCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
      ));

      final fixed = await repo.restoreStalePaidPayroll(
        periodId: r.periodId,
        reason: 'حُذف سندها عند إلغاء سلفة موظف',
      );

      expect(fixed, 1);
      expect(await repo.getStalePaidPayrolls(), isEmpty);

      final entry = await db.payrollDao.getEntryById(r.entryId);
      expect(entry!.paymentStatus, PayrollPaymentStatusDb.unpaid);
      expect(entry.voucherId, isNull);

      final period = await db.payrollDao.getPeriodById(r.periodId);
      expect(period!.status, PayrollStatusDb.draft);
      expect(period.postedAt, isNotNull,
          reason: 'تاريخ الاعتماد الأول يبقى شاهداً');

      // ⭐ ولا يعود الموظف «مصروفاً سلفاً» فيمنع إعادة الاستيراد
      expect(await db.payrollDao.getPaidEmployeesForMonth(2025, 9), isEmpty);
    });

    test('سبب فارغ يُرفض', () async {
      final r = await payHasanDirectly();
      await expectLater(
        repo.restoreStalePaidPayroll(periodId: r.periodId, reason: ''),
        throwsA(isA<StateError>()),
      );
    });
  });
}
