// ─────────────────────────────────────────────────────────────────────────────
// service_context_paths_test.dart — كل مسارٍ يحسب راتباً يعرف خدمة صاحبه
//
// **بلاغ المالك من جولة الاختبار الميداني (2026-10-14)**، ثلاثة بنود:
//   ١٫٥  «كان لديه ٢٨ يوماً وأعطيته مكافأة — رجعت الأيام إلى ٣٠»
//   ١٫٧  «أعطيته إجازة براتب ولم يظهر في تبويب "في إجازة"»
//   ١٫١٣ «إجازة من ١ إلى ١٣ وإنهاء خدمة في ١٢ — احتُسبت الإجازة وتُخطّي الإنهاء»
//
// ═══ وما كشفه التشخيص ═══
//   ١. **ثلاثة مسارات تحسب الراتب بلا تاريخ الإنهاء والإجازة**: تصحيح السطر
//      المسدَّد · معاينة حوار التصحيح · مقارنة المدفوع بالملف. ع-٣٧ للمرّة
//      الثالثة — فصارت معاملات الخدمة **إلزامية** في الحاسبة.
//   ٢. **الإجازة لا تُقصّ بحدود الخدمة**: إجازةٌ بعد الإنهاء طُرحت من أيام
//      العمل — عمل ١٢ يوماً فاستحقّ **يوماً واحداً**. أخطر من البلاغ نفسه.
//   ٣. «في إجازة» كانت تعني «اليوم»، والمالك يقرؤها «هذا الشهر» — قراره.
//
// ⚠️ **هذه الاختبارات مكتوبة بواجهاتٍ كانت موجودة قبل الإصلاح** عمداً:
//   شُغِّلت على الكود القديم ففشلت، ثم على الجديد فنجحت (القانون ٢).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/constants/employee_status.dart';
import 'package:sales_management/core/services/payroll_row_parser.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/database/tables/employee_leaves_table.dart';
import 'package:sales_management/data/repositories/payroll_repository.dart';

void main() {
  late AppDatabase db;
  late PayrollRepository repo;
  late int treasuryId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PayrollRepository(db);
    final fiscalId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31, 23, 59, 59),
      ),
    );
    treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
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
        amount: 50000000,
        voucherDate: DateTime(2026, 1, 5),
      ),
    );
  });

  tearDown(() async => db.close());

  // ── مساعدات ──────────────────────────────────────────────────────────────

  Future<int> employee(String name, {DateTime? hireDate}) =>
      db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
          fullName: name,
          basicSalary: const Value(600000),
          hireDate: Value(hireDate),
          treasuryId: Value(treasuryId),
        ),
      );

  Future<void> leave(int id, DateTime from, DateTime to, String kind) =>
      db.employeesDao.insertLeave(
        EmployeeLeavesCompanion.insert(
          employeeId: id,
          fromDate: from,
          toDate: to,
          kind: Value(kind),
        ),
      );

  ParsedPayrollRow fileRow(String name, {int? days}) => ParsedPayrollRow(
        rowNumber: 1,
        rowLabel: 'صف 1',
        employeeName: name,
        basicSalary: 600000,
        eligibleDays: days,
      );

  Future<SalaryPayment> importOne(int id, String name, int month,
      {int? days}) async {
    final pid = await repo.createOrGetPeriod(year: 2026, month: month);
    await repo.importRows(
      periodId: pid,
      rows: [ResolvedPayrollRow(employeeId: id, row: fileRow(name, days: days))],
    );
    return (await db.payrollDao.getEntries(pid))
        .firstWhere((e) => e.employeeId == id);
  }

  Future<SalaryPayment> pay(SalaryPayment e) async {
    await repo.payEntries(
      periodId: e.payrollPeriodId!,
      entryIds: [e.id],
      treasuryId: treasuryId,
      paymentDate: DateTime(2026, 9, 30),
    );
    return (await db.payrollDao.getEntryById(e.id))!;
  }

  // ═══════════════════════════════════════════════════════════════════════
  group('١٫٥ — التصحيح بعد التسديد يعرف الخدمة', () {
    test('⭐⭐⭐ أُنهيت خدمته في ٢٨ ⇒ مكافأةٌ على راتبه المسدَّد تُبقي ٢٨ يوماً',
        () async {
      final id = await employee('ياسر');
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 9, 28),
      );
      final paid = await pay(await importOne(id, 'ياسر', 9));
      expect(paid.eligibleDays, 28);

      await repo.correctPaidEntry(
        entryId: paid.id,
        newBonus: 50000,
        reason: 'مكافأة',
        mode: PayrollCorrectionMode.dataEntryError,
      );

      final after = (await db.payrollDao.getEntryById(paid.id))!;
      // 🔴 قبل الإصلاح: ٣٠ — الشهر كاملاً لمن عمل ٢٨ يوماً
      expect(after.eligibleDays, 28);
      // 600,000 × 28 ÷ 30 + 50,000
      expect(after.netAmount, closeTo(610000, 0.5));
    });

    test('⭐⭐ أيام الملف («اعتمد الملف») تبقى حين يُمرَّر الغياب بلا تغيير',
        () async {
      // الحوار يمرّر أيام الغياب في كل تصحيح ولو لم تُمسّ — وكان وجودها
      // وحده يُسقط الأيام اليدوية فيُعاد حسابها شهراً كاملاً
      final id = await employee('سعد');
      final paid = await pay(await importOne(id, 'سعد', 9, days: 25));
      expect(paid.eligibleDays, 25);

      await repo.correctPaidEntry(
        entryId: paid.id,
        newBonus: 10000,
        newAbsenceDays: paid.absenceDays, // كما يمرّره الحوار حرفياً
        reason: 'مكافأة',
        mode: PayrollCorrectionMode.dataEntryError,
      );
      expect((await db.payrollDao.getEntryById(paid.id))!.eligibleDays, 25);
    });

    test('⭐ تغيير الغياب فعلاً يُعيد حساب الأيام — القاعدة القديمة باقية',
        () async {
      final id = await employee('كريم');
      final paid = await pay(await importOne(id, 'كريم', 9, days: 25));

      await repo.correctPaidEntry(
        entryId: paid.id,
        newAbsenceDays: 3,
        reason: 'غياب ثلاثة أيام',
        mode: PayrollCorrectionMode.dataEntryError,
      );
      expect((await db.payrollDao.getEntryById(paid.id))!.eligibleDays, 27);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  group('١٫١٣ — الإجازة تُقصّ بحدود الخدمة', () {
    test('⭐⭐⭐ إجازةٌ بلا راتب **بعد** الإنهاء لا تُنقِص أيام العمل', () async {
      final id = await employee('مهدي');
      await leave(id, DateTime(2026, 8, 20), DateTime(2026, 8, 30),
          LeaveKind.unpaid);
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 8, 12),
      );

      final e = await importOne(id, 'مهدي', 8);
      // 🔴 قبل الإصلاح: يومٌ واحد — طُرحت ١١ يوماً من ١٢ عملها فعلاً
      expect(e.eligibleDays, 12);
      expect(e.leaveDaysUnpaid, 0);
    });

    test('⭐⭐ سيناريو المالك: إجازة ١–١٣ وإنهاء في ١٢ ⇒ الإجازة ١٢ لا ١٣',
        () async {
      final id = await employee('علي');
      await leave(id, DateTime(2026, 8, 1), DateTime(2026, 8, 13),
          LeaveKind.paid);
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 8, 12),
      );

      final e = await importOne(id, 'علي', 8);
      expect(e.eligibleDays, 12);
      // 🔴 قبل الإصلاح: ١٣ — عمود الإجازة أطول من الخدمة فبدا الإنهاء متجاهَلاً
      expect(e.leaveDaysPaid, 12);
    });

    test('⭐⭐ وقبل التعيين كذلك: عُيِّن في العاشر وإجازته من الأول', () async {
      final id = await employee('حيدر', hireDate: DateTime(2026, 8, 10));
      await leave(id, DateTime(2026, 8, 1), DateTime(2026, 8, 15),
          LeaveKind.unpaid);

      final e = await importOne(id, 'حيدر', 8);
      // خدمته ١٠–٣٠ = ٢١ يوماً، منها ١٠–١٥ إجازة = ٦ ⇒ ١٥
      // 🔴 قبل الإصلاح: ٦ — طُرحت ١٥ يوماً منها تسعةٌ قبل أن يُعيَّن
      expect(e.eligibleDays, 15);
      expect(e.leaveDaysUnpaid, 6);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  group('مقارنة المدفوع بالملف تعرف الخدمة', () {
    test('⭐⭐ لا «فرق» وهميّ لمن أُنهيت خدمته والملف بلا عمود أيام', () async {
      final id = await employee('زيد');
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 9, 20),
      );
      await pay(await importOne(id, 'زيد', 9));

      final cmp = await repo.comparePaidWithFile(
        year: 2026,
        month: 9,
        rows: [(employeeId: id, row: fileRow('زيد'))],
      );
      // 🔴 قبل الإصلاح: الملف «٣٠ يوماً» مقابل ٢٠ مصروفة — فرقٌ لم يقع
      expect(cmp.single.fileDays, 20);
      expect(cmp.single.fileIqd, closeTo(cmp.single.paidIqd, 0.5));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  group('١٫٧ — «في إجازة» = إجازة في الشهر الحالي (قرار المالك 2026-10-14)', () {
    final now = DateTime.now();
    // يومٌ من هذا الشهر **غير اليوم** — فالتعريف القديم («تشمل اليوم») يرسب
    final otherDay = now.day == 1 ? 2 : 1;
    final thisMonthNotToday = DateTime(now.year, now.month, otherDay);

    test('⭐⭐⭐ إجازة براتب في يومٍ مضى من هذا الشهر ⇒ «في إجازة»', () async {
      final id = await employee('سلمان');
      await leave(id, thisMonthNotToday, thisMonthNotToday, LeaveKind.paid);
      // 🔴 قبل الإصلاح: «حالي» — لأن الإجازة لا تشمل اليوم
      expect((await db.employeesDao.getEmployeeById(id))!.status,
          EmployeeStatus.leave);
    });

    test('⭐⭐ النوعان سواء — بلا راتب في اليوم نفسه ⇒ «في إجازة»', () async {
      final id = await employee('ماجد');
      await leave(id, thisMonthNotToday, thisMonthNotToday, LeaveKind.unpaid);
      expect((await db.employeesDao.getEmployeeById(id))!.status,
          EmployeeStatus.leave);
    });

    test('⭐ إجازة الشهر الماضي أو القادم ⇒ «حالي»', () async {
      final a = await employee('فارس');
      final lastMonth = DateTime(now.year, now.month - 1, 10);
      await leave(a, lastMonth, lastMonth, LeaveKind.paid);
      expect((await db.employeesDao.getEmployeeById(a))!.status,
          EmployeeStatus.active);

      final b = await employee('نزار');
      final nextMonth = DateTime(now.year, now.month + 1, 10);
      await leave(b, nextMonth, nextMonth, LeaveKind.paid);
      expect((await db.employeesDao.getEmployeeById(b))!.status,
          EmployeeStatus.active);
    });

    test('⭐ منتهي الخدمة لا تُمسّ حالته ولو أُجيز هذا الشهر', () async {
      final id = await employee('رعد');
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: thisMonthNotToday,
      );
      await leave(id, thisMonthNotToday, thisMonthNotToday, LeaveKind.paid);
      expect((await db.employeesDao.getEmployeeById(id))!.status,
          EmployeeStatus.terminated);
    });
  });
}
