// ─────────────────────────────────────────────────────────────────────────────
// batch_b_employees_test.dart — الدفعة ب من ملاحظات المالك (2026-09-01)
//
// سبعة بنود في منطقة الموظفين، نُفِّذت معاً لا متفرّقة — والدرس المتكرّر في
// هذا المشروع أن تفريق العمل على منطقةٍ واحدة يُنتج «كل بابٍ يعرف قاعدة
// ويجهل الباقي».
//
// ما يحرسه هذا الملف:
//   ٥. تعريب سجل التدقيق — والمجهول يُعرَض كما هو لا يُخفى
//   ٦. حذف الموظف محروساً بأثره المالي، والتعطيل بديلاً
//   ٨. تفاصيل تسديد السلفة — كل قسط بمصدره
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/constants/employee_status.dart';
import 'package:sales_management/core/utils/audit_labels.dart';
import 'package:sales_management/data/database/app_database.dart';

void main() {
  late AppDatabase db;
  late int employeeId;
  late int periodId;
  late int treasuryId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31, 23, 59, 59),
      ),
    );
    treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'بغداد', kind: const Value('main')),
    );
    employeeId = await db.into(db.employees).insert(
          EmployeesCompanion.insert(
            fullName: 'حسن محمد',
            treasuryId: Value(treasuryId),
          ),
        );
  });

  tearDown(() async => db.close());

  Future<int> grantAdvance({double amount = 1000000}) =>
      db.into(db.cashAdvances).insert(
            CashAdvancesCompanion.insert(
              employeeId: Value(employeeId),
              amount: amount,
              advanceDate: DateTime(2026, 3, 1),
            ),
          );

  // ══════════════════════════════════════════════════════════════════════
  group('٥ — تعريب سجل التدقيق', () {
    test('⭐⭐ العمليات والجداول تُعرَض بالعربية — بلاغ المالك', () {
      // 🔴 كانت الشاشة تعرض ثوابت الكود: INSERT · salary_payments
      expect(AuditLabels.action('INSERT'), 'إضافة');
      expect(AuditLabels.action('FISCAL_CLOSE'), 'إقفال سنة');
      expect(AuditLabels.table('salary_payments'), 'الرواتب');
      expect(AuditLabels.table('vouchers'), 'السندات');
    });

    test('⭐⭐ التمييز بين سلف الموظفين وسلف المشاريع محفوظ', () {
      // اللفظ العربي واحد، والخلط بينهما كلّفنا أعطالاً
      expect(AuditLabels.table('cash_advances'), 'سلف الموظفين');
      expect(AuditLabels.table('advances'), 'سلف المشاريع');
    });

    test('⭐⭐ المجهول يُعرَض كما هو لا يُخفى', () {
      // إخفاؤه يُضيّع معلومةً حقيقية من **سجل رقابي** — وهو آخر ما يجوز
      // العبث به. والظهور بالإنجليزية تذكيرٌ بأن الترجمة ناقصة.
      expect(AuditLabels.action('SOMETHING_NEW'), 'SOMETHING_NEW');
      expect(AuditLabels.table('future_table'), 'future_table');
    });

    test('⭐⭐ الفلاتر تغطّي كل العمليات لا ستّاً منها', () {
      // كانت الشاشة تعرض ٦ شرائح بينما `AuditActions` يعرّف ١٧ نوعاً —
      // فأحد عشر نوعاً لا تصل إليها شريحة إطلاقاً.
      expect(AuditLabels.allActions.length, greaterThanOrEqualTo(17));
      for (final a in AuditLabels.allActions) {
        expect(AuditLabels.action(a), isNot(a),
            reason: 'كل عملية في قائمة الفلاتر يجب أن تكون مُعرَّبة: $a');
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('٦ — حذف الموظف محروساً', () {
    test('⭐⭐⭐ من عليه سلفة غير مسدَّدة لا يُحذف — بلاغ المالك', () async {
      await grantAdvance();

      await expectLater(
        db.employeesDao.deleteEmployeeGuarded(employeeId),
        throwsA(isA<StateError>().having((e) => e.message, 'الرسالة',
            allOf(contains('سلفة غير مسدَّدة'), contains('عطّل')))),
      );

      final e = await db.employeesDao.getEmployeeById(employeeId);
      expect(e!.isDeleted, isFalse, reason: 'لم يُمَسّ');
    });

    test('⭐⭐⭐ من له سطر راتب سابق لا يُحذف — التقارير تقرؤه', () async {
      await db.into(db.salaryPayments).insert(
            SalaryPaymentsCompanion.insert(
              employeeId: employeeId,
              paymentDate: DateTime(2026, 3, 31),
              netAmount: const Value(800000),
            ),
          );

      await expectLater(
        db.employeesDao.deleteEmployeeGuarded(employeeId),
        throwsA(isA<StateError>().having((e) => e.message, 'الرسالة',
            allOf(contains('سطر راتب'), contains('عطّل')))),
      );
    });

    test('⭐⭐ الموظف بلا أثر مالي يُحذف بلا اعتراض', () async {
      await expectLater(
        db.employeesDao.deleteEmployeeGuarded(employeeId),
        completes,
      );
      final e = await db.employeesDao.getEmployeeById(employeeId);
      expect(e!.isDeleted, isTrue);
    });

    test('⭐⭐ السلفة المسدَّدة بالكامل لا تمنع الحذف', () async {
      final id = await grantAdvance(amount: 500000);
      await (db.update(db.cashAdvances)..where((a) => a.id.equals(id))).write(
        const CashAdvancesCompanion(
          totalRepaid: Value(500000),
          status: Value('paid'),
        ),
      );

      // الدَّين انتهى — فلا سبب للمنع
      await expectLater(
        db.employeesDao.deleteEmployeeGuarded(employeeId),
        completes,
      );
    });

    test('⭐⭐ التعطيل هو البديل — والمنع بلا بديل يُهجّر الخطر', () async {
      await grantAdvance();
      // 🔄 Schema v8: حلّ `status` محلّ `is_active`، و«التعطيل» صار
      //   «منتهية خدمته» — الحالة التي كان العمود الثنائي يعنيها فعلاً.
      await db.employeesDao
          .setEmployeeStatus(employeeId, EmployeeStatus.terminated);

      final e = await db.employeesDao.getEmployeeById(employeeId);
      expect(e!.status, EmployeeStatus.terminated);
      expect(e.isDeleted, isFalse,
          reason: 'يبقى سجلّه وتقاريره — يختفي من الكشوف الجديدة فقط');
    });

    test('⭐ الأثر المالي يُقرأ بدقّة قبل الحوار', () async {
      await grantAdvance(amount: 1000000);
      await db.into(db.salaryPayments).insert(
            SalaryPaymentsCompanion.insert(
              employeeId: employeeId,
              paymentDate: DateTime(2026, 3, 31),
            ),
          );

      final f = await db.employeesDao.getEmployeeFinancialFootprint(employeeId);
      expect(f.unpaidAdvances, 1);
      expect(f.advanceBalance, 1000000);
      expect(f.salaryRows, 1);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('٨ — تفاصيل تسديد السلفة', () {
    test('⭐⭐⭐ الدفعتان تظهران بمصدر كلٍّ منهما — بلاغ المالك', () async {
      // سيناريو المالك حرفياً: سلفة مليون، ٥٠٠ نقداً و٥٠٠ خصماً من الراتب
      final advanceId = await grantAdvance();

      // ── الدفعة الأولى: نقدية بسند قبض ──────────────────────────────
      final vNum = await db.fiscalPeriodsDao
          .getNextVoucherNumber(fiscalPeriodId: periodId, voucherType: 'kabd');
      final voucherId = await db.into(db.vouchers).insert(
            VouchersCompanion.insert(
              voucherNumber: vNum,
              voucherType: 'kabd',
              treasuryId: treasuryId,
              fiscalPeriodId: periodId,
              amount: 500000,
              voucherDate: DateTime(2026, 3, 10),
            ),
          );
      await db.into(db.cashAdvanceRepayments).insert(
            CashAdvanceRepaymentsCompanion.insert(
              cashAdvanceId: advanceId,
              amount: 500000,
              repaymentDate: DateTime(2026, 3, 10),
              method: const Value('cash'),
              voucherId: Value(voucherId),
            ),
          );

      // ── الدفعة الثانية: خصم من رواتب أيار ──────────────────────────
      final payrollId = await db.into(db.payrollPeriods).insert(
            PayrollPeriodsCompanion.insert(
              year: 2026,
              month: 5,
              fiscalPeriodId: periodId,
            ),
          );
      final payNum = await db.fiscalPeriodsDao
          .getNextVoucherNumber(fiscalPeriodId: periodId, voucherType: 'sarf');
      final payrollVoucherId = await db.into(db.vouchers).insert(
            VouchersCompanion.insert(
              voucherNumber: payNum,
              voucherType: 'sarf',
              treasuryId: treasuryId,
              fiscalPeriodId: periodId,
              amount: 3000000,
              voucherDate: DateTime(2026, 5, 31),
            ),
          );
      await db.into(db.salaryPayments).insert(
            SalaryPaymentsCompanion.insert(
              employeeId: employeeId,
              payrollPeriodId: Value(payrollId),
              cashAdvanceId: Value(advanceId),
              advanceRepaymentAmount: const Value(500000),
              voucherId: Value(payrollVoucherId),
              paymentDate: DateTime(2026, 5, 31),
            ),
          );
      await db.into(db.cashAdvanceRepayments).insert(
            CashAdvanceRepaymentsCompanion.insert(
              cashAdvanceId: advanceId,
              amount: 500000,
              repaymentDate: DateTime(2026, 5, 31),
              method: const Value('salary_deduction'),
              voucherId: Value(payrollVoucherId),
            ),
          );

      // ── ما يراه المالك ─────────────────────────────────────────────
      final details = await db.employeesDao.getRepaymentDetails(advanceId);

      expect(details, hasLength(2), reason: 'دفعتان لا رقمٌ إجمالي واحد');

      final cash = details.first;
      expect(cash.method, 'cash');
      expect(cash.voucherNumber, vNum,
          reason: 'رقم سند القبض — ليعرف المالك أيّ سند');
      expect(cash.periodYear, isNull);

      final salary = details.last;
      expect(salary.method, 'salary_deduction');
      expect(salary.periodYear, 2026);
      expect(salary.periodMonth, 5,
          reason: 'رواتب **أيار** — وهذا بالضبط ما طلبه المالك');
    });

    test('⭐⭐ لا تكرار حين يشترك سند الرواتب بين موظفين', () async {
      // ⚠️ سند رواتب الشهر **مشترك بين كل موظفيه**. فـ`LEFT JOIN` على
      //   `salary_payments` كان سيُكرّر القسط مرّاتٍ بعدد سطور الكشف.
      final advanceId = await grantAdvance();
      final payrollId = await db.into(db.payrollPeriods).insert(
            PayrollPeriodsCompanion.insert(
              year: 2026,
              month: 5,
              fiscalPeriodId: periodId,
            ),
          );
      final vNum = await db.fiscalPeriodsDao
          .getNextVoucherNumber(fiscalPeriodId: periodId, voucherType: 'sarf');
      final voucherId = await db.into(db.vouchers).insert(
            VouchersCompanion.insert(
              voucherNumber: vNum,
              voucherType: 'sarf',
              treasuryId: treasuryId,
              fiscalPeriodId: periodId,
              amount: 5000000,
              voucherDate: DateTime(2026, 5, 31),
            ),
          );

      // ثلاثة موظفين على السند نفسه — وواحد منهم صاحب السلفة
      for (var i = 0; i < 3; i++) {
        final empId = i == 0
            ? employeeId
            : await db.into(db.employees).insert(
                  EmployeesCompanion.insert(fullName: 'زميل $i'),
                );
        await db.into(db.salaryPayments).insert(
              SalaryPaymentsCompanion.insert(
                employeeId: empId,
                payrollPeriodId: Value(payrollId),
                cashAdvanceId: i == 0 ? Value(advanceId) : const Value.absent(),
                voucherId: Value(voucherId),
                paymentDate: DateTime(2026, 5, 31),
              ),
            );
      }

      await db.into(db.cashAdvanceRepayments).insert(
            CashAdvanceRepaymentsCompanion.insert(
              cashAdvanceId: advanceId,
              amount: 250000,
              repaymentDate: DateTime(2026, 5, 31),
              method: const Value('salary_deduction'),
              voucherId: Value(voucherId),
            ),
          );

      final details = await db.employeesDao.getRepaymentDetails(advanceId);
      expect(details, hasLength(1),
          reason: 'قسطٌ واحد مهما كثرت سطور الكشف حوله');
      expect(details.single.periodMonth, 5);
    });

    test('⭐ سلفة بلا أقساط تُعيد قائمة فارغة', () async {
      final id = await grantAdvance();
      expect(await db.employeesDao.getRepaymentDetails(id), isEmpty);
    });
  });
}
