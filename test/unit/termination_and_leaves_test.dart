// ─────────────────────────────────────────────────────────────────────────────
// termination_and_leaves_test.dart — إنهاء الخدمة والإجازات (Schema v9)
//
// **طلب المالك (2026-09-02)** بسيناريوهين حرفيّين:
//   ١. عُيِّن 2026-07-04 وأُنهيت خدمته 2026-07-24 ⇒ يُحتسب له ما بين
//      التاريخين لا شهرٌ كامل ولا صفر.
//   ٢. عُيِّن 2026-03-05 وأُنهيت خدمته 2026-08-26 ⇒ في **آب** يُحتسب من ١
//      إلى ٢٦، وفي الشهور السابقة شهرٌ كامل.
//
// **وما كان معطوباً:** `PayrollCalculator.eligibleDays` تحسب هذا حساباً
//   صحيحاً **منذ اليوم الأول** ومحروسةً بأربعٍ وعشرين إشارة اختبار — و
//   `terminationDate` **لا عمود له في القاعدة إطلاقاً**، و`hireDate` يُقرأ
//   من عمودٍ في ملف الإكسل لا من سجلّ الموظف.
//
//   فالمنطق سليم ونصفه الآخر لم يُبنَ: **ع-٠٦ في أنقى صوره**.
//
// ⚠️ ولهذا يفحص هذا الملف **المسار كلّه** لا الدالة وحدها: من سجلّ الموظف
//   إلى سطر الراتب المخزَّن. فحصُ الدالة وحدها كان سيمرّ ناجحاً طوال الوقت
//   بينما الميزة معطَّلة — وهو درس ع-٥٥ حرفياً.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/constants/employee_status.dart';
import 'package:sales_management/core/services/payroll_calculator.dart';
import 'package:sales_management/core/services/payroll_row_parser.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/database/tables/employee_leaves_table.dart';
import 'package:sales_management/data/repositories/payroll_repository.dart';

void main() {
  late AppDatabase db;
  late PayrollRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PayrollRepository(db);
    await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31, 23, 59, 59),
      ),
    );
  });

  tearDown(() async => db.close());

  // ── مساعدات ──────────────────────────────────────────────────────────────

  Future<int> newEmployee({
    String name = 'أحمد علي',
    DateTime? hireDate,
    double salary = 600000,
  }) =>
      db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
          fullName: name,
          basicSalary: Value(salary),
          hireDate: Value(hireDate),
        ),
      );

  /// يستورد الموظف في كشف شهرٍ ويُعيد سطره المخزَّن
  Future<SalaryPayment> importInto({
    required int employeeId,
    required String name,
    required int year,
    required int month,
    double salary = 600000,
    int absence = 0,
    int? manualDays,
  }) async {
    final periodId = await repo.createOrGetPeriod(year: year, month: month);
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
            absenceDays: absence,
            eligibleDays: manualDays,
          ),
        ),
      ],
    );
    final entries = await db.payrollDao.getEntries(periodId);
    return entries.first;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // سيناريوها المالك — من سجلّ الموظف إلى سطر الراتب
  // ═══════════════════════════════════════════════════════════════════════

  group('إنهاء الخدمة — سيناريوها المالك', () {
    test('⭐⭐⭐ س١: عُيِّن 07-04 وأُنهيت خدمته 07-24 ⇒ ٢١ يوماً في تموز',
        () async {
      final id = await newEmployee(hireDate: DateTime(2026, 7, 4));
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 7, 24),
        reference: 'الكتاب المرقّم ٣٤٥',
      );

      final entry = await importInto(
          employeeId: id, name: 'أحمد علي', year: 2026, month: 7);

      // 🔴 قبل الإصلاح: ٣٠ يوماً — شهرٌ كامل لمن عمل عشرين يوماً
      expect(entry.eligibleDays, 21);
      // والراتب بالتناسب: 600,000 × 21 ÷ 30
      expect(entry.netAmount, 420000);
    });

    test('⭐⭐⭐ س٢: عُيِّن 03-05 وأُنهيت 08-26 ⇒ آب ٢٦ يوماً', () async {
      final id = await newEmployee(hireDate: DateTime(2026, 3, 5));
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 8, 26),
      );

      final entry = await importInto(
          employeeId: id, name: 'أحمد علي', year: 2026, month: 8);
      expect(entry.eligibleDays, 26);
    });

    test('⭐⭐ وفي الشهور التي بين التعيين والإنهاء: شهرٌ كامل', () async {
      final id = await newEmployee(hireDate: DateTime(2026, 3, 5));
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 8, 26),
      );

      final entry = await importInto(
          employeeId: id, name: 'أحمد علي', year: 2026, month: 7);
      expect(entry.eligibleDays, 30,
          reason: 'موظفٌ مستمرّ طوال تموز يستحقّه كاملاً');
    });

    test('⭐⭐⭐ وبعد شهر الإنهاء: يُستبعَد من الكشف ويُقال باسمه', () async {
      final id = await newEmployee(hireDate: DateTime(2026, 3, 5));
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 8, 26),
      );

      final periodId = await repo.createOrGetPeriod(year: 2026, month: 9);
      final outcome = await repo.importRows(
        periodId: periodId,
        rows: [
          ResolvedPayrollRow(
            employeeId: id,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'أحمد علي',
              basicSalary: 600000,
            ),
          ),
        ],
      );

      // ⚠️ **الاستبعاد أصدق من سطرٍ بصفر**: صفٌّ صفريّ في الكشف يُوهم بأنه
      //   ما زال على الملاك ولم يُصرف له، والاستبعاد يقول الحقيقة — وقد
      //   طلب المالك أن يُذكر الاسم لا أن يختفي بصمت.
      expect(outcome.skippedTerminated, contains('أحمد علي'));
      expect(await db.payrollDao.getEntries(periodId), isEmpty);
    });

    test('⭐⭐ التاريخ يُقرأ من **سجلّ الموظف** لا من الملف (قرار المالك)',
        () async {
      // السجلّ يقول ٤ تموز — والملف لا يذكر تاريخاً إطلاقاً
      final id = await newEmployee(hireDate: DateTime(2026, 7, 4));

      final entry = await importInto(
          employeeId: id, name: 'أحمد علي', year: 2026, month: 7);

      // 🔴 قبل الإصلاح: `r.hireDate` من الملف = null ⇒ ٣٠ يوماً
      expect(entry.eligibleDays, 27, reason: 'من ٤ إلى ٣٠ = ٢٧ يوماً');
      expect(entry.snapshotHireDate, DateTime(2026, 7, 4),
          reason: 'اللقطة تحمل التاريخ الذي بُني عليه الحساب');
    });

    test('⭐⭐ إعادة الموظف للخدمة تمحو التاريخ فلا يقصّ راتبه بعدها',
        () async {
      final id = await newEmployee();
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 7, 10),
        reference: 'كتاب ١',
        notes: 'استقالة',
      );
      await db.employeesDao.reinstateEmployee(id);

      final row = await db.employeesDao.getEmployeeById(id);
      expect(row!.status, EmployeeStatus.active);
      expect(row.terminationDate, isNull);
      expect(row.terminationReference, '');

      final entry = await importInto(
          employeeId: id, name: 'أحمد علي', year: 2026, month: 7);
      expect(entry.eligibleDays, 30);
    });

    test('⭐⭐ الحالة والتاريخ يُكتبان معاً — لا عمودان يفترقان', () async {
      final id = await newEmployee();
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 7, 24),
        reference: 'الكتاب ٣٤٥',
        notes: 'انتهاء عقد',
      );

      final row = await db.employeesDao.getEmployeeById(id);
      expect(row!.status, EmployeeStatus.terminated);
      expect(row.terminationDate, DateTime(2026, 7, 24));
      expect(row.terminationReference, 'الكتاب ٣٤٥');
      expect(row.terminationNotes, 'انتهاء عقد');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الإجازات
  // ═══════════════════════════════════════════════════════════════════════

  group('الإجازات', () {
    Future<int> addLeave(
      int employeeId,
      DateTime from,
      DateTime to, {
      String kind = LeaveKind.unpaid,
    }) =>
        db.employeesDao.insertLeave(
          EmployeeLeavesCompanion.insert(
            employeeId: employeeId,
            fromDate: from,
            toDate: to,
            kind: Value(kind),
          ),
        );

    test('⭐⭐⭐ إجازة بلا راتب تُنقِص أيام الاستحقاق', () async {
      final id = await newEmployee();
      // عشرة أيام: من ٥ إلى ١٤ شاملةً الطرفين
      await addLeave(id, DateTime(2026, 7, 5), DateTime(2026, 7, 14));

      final entry = await importInto(
          employeeId: id, name: 'أحمد علي', year: 2026, month: 7);

      expect(entry.eligibleDays, 20, reason: '٣٠ − ١٠');
      expect(entry.netAmount, 400000, reason: '600,000 × 20 ÷ 30');
    });

    test('⭐⭐⭐ إجازة **براتب** لا تمسّ الاستحقاق إطلاقاً', () async {
      final id = await newEmployee();
      await addLeave(id, DateTime(2026, 7, 5), DateTime(2026, 7, 14),
          kind: LeaveKind.paid);

      final entry = await importInto(
          employeeId: id, name: 'أحمد علي', year: 2026, month: 7);

      expect(entry.eligibleDays, 30);
      expect(entry.netAmount, 600000);
    });

    test('⭐⭐⭐ إجازة تعبر شهرين تُقسَّم على شهريها لا تُحمَّل على أحدهما',
        () async {
      final id = await newEmployee();
      // من ٢٨ تموز إلى ٥ آب: أربعة في تموز وخمسة في آب
      await addLeave(id, DateTime(2026, 7, 28), DateTime(2026, 8, 5));

      final july = await db.employeesDao.unpaidLeaveDaysInMonth(
          employeeId: id, year: 2026, month: 7, workingDays: 30);
      final august = await db.employeesDao.unpaidLeaveDaysInMonth(
          employeeId: id, year: 2026, month: 8, workingDays: 30);

      // 🔑 هذا ما يمنعه تخزين «٩ أيام» رقماً مجرّداً: لا يعرف أيّ شهر يخصّ
      expect(july, 4, reason: '٢٨ · ٢٩ · ٣٠ · ٣١ تموز');
      expect(august, 5, reason: '١ إلى ٥ آب');
    });

    test('⭐⭐ الغياب والإجازة يجتمعان بلا أن يصير الاستحقاق سالباً',
        () async {
      final id = await newEmployee();
      await addLeave(id, DateTime(2026, 7, 1), DateTime(2026, 7, 25));

      final entry = await importInto(
        employeeId: id,
        name: 'أحمد علي',
        year: 2026,
        month: 7,
        absence: 10, // أكثر مما بقي
      );

      expect(entry.eligibleDays, 0);
      expect(entry.netAmount, 0, reason: 'صفر لا سالب');
    });

    test('⭐⭐⭐ الملف حين يذكر الأيام صراحةً: لا تُطرح الإجازة ثانيةً (ع-٢٦)',
        () async {
      final id = await newEmployee();
      await addLeave(id, DateTime(2026, 7, 5), DateTime(2026, 7, 14));

      final entry = await importInto(
        employeeId: id,
        name: 'أحمد علي',
        year: 2026,
        month: 7,
        manualDays: 20, // المحاسب طرح الإجازة أصلاً
      );

      // ⚠️ لو طُرحت ثانيةً لصارت ١٠ — وهو عين ع-٢٦ (خصم مرّتين)
      expect(entry.eligibleDays, 20);
    });

    test('⭐⭐ إجازة محذوفة لا تُخصم', () async {
      final id = await newEmployee();
      final leaveId =
          await addLeave(id, DateTime(2026, 7, 5), DateTime(2026, 7, 14));
      await db.employeesDao.softDeleteLeave(leaveId);

      final days = await db.employeesDao.unpaidLeaveDaysInMonth(
          employeeId: id, year: 2026, month: 7, workingDays: 30);
      expect(days, 0);
    });

    test('⭐ إجازة أطول من الشهر تُقصّ بأيام العمل', () async {
      final id = await newEmployee();
      await addLeave(id, DateTime(2026, 6, 1), DateTime(2026, 9, 30));

      final days = await db.employeesDao.unpaidLeaveDaysInMonth(
          employeeId: id, year: 2026, month: 7, workingDays: 30);
      expect(days, 30, reason: 'لا ٣١ — وإلا صار الاستحقاق سالباً');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الحاسبة النقيّة — الحدود
  // ═══════════════════════════════════════════════════════════════════════

  group('الحاسبة', () {
    test('⭐⭐ الإجازة تُبلَّغ في النتيجة فيعرضها الكشف مستقلّةً عن الغياب',
        () {
      final a = PayrollCalculator.compute(
        year: 2026,
        month: 7,
        workingDays: 30,
        basicSalary: 600000,
        currency: PayrollCurrency.iqd,
        unpaidLeaveDays: 10,
        absenceDays: 2,
      );
      expect(a.unpaidLeaveDays, 10);
      expect(a.eligibleDays, 18, reason: '٣٠ − ١٠ إجازة − ٢ غياب');
    });

    test('⭐⭐ إجازة تتجاوز استحقاق شهر الإنهاء تُقصّ به لا بأيام العمل', () {
      final a = PayrollCalculator.compute(
        year: 2026,
        month: 7,
        workingDays: 30,
        basicSalary: 600000,
        currency: PayrollCurrency.iqd,
        terminationDate: DateTime(2026, 7, 10), // استحقاقه ١٠ أيام
        unpaidLeaveDays: 25,
      );
      expect(a.eligibleDays, 0);
      expect(a.unpaidLeaveDays, 10, reason: 'لا يُخصم ما لم يكن مستحقّاً');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // التعديل — المسار الثاني الذي كان ينسى ما يعرفه الاستيراد
  // ═══════════════════════════════════════════════════════════════════════

  group('تعديل السطر يحترم الخدمة والإجازة', () {
    test('⭐⭐⭐ تعديل مكافأة لا يُعيد الشهر كاملاً لمن أُنهيت خدمته', () async {
      final id = await newEmployee(hireDate: DateTime(2026, 7, 4));
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 7, 24),
      );
      final entry = await importInto(
          employeeId: id, name: 'أحمد علي', year: 2026, month: 7);
      expect(entry.eligibleDays, 21, reason: 'الشرط المسبق');

      // المالك يعدّل المكافأة وحدها — لا علاقة لها بالأيام
      await repo.updateEntry(entryId: entry.id, bonus: 50000);

      final after = await db.payrollDao.getEntryById(entry.id);
      // 🔴 قبل الإصلاح: ٣٠ — `updateEntry` كانت تُعيد الحساب بلا تاريخ
      //   الإنهاء، فيقفز راتب الشهر الأخير من ٢١ يوماً إلى ٣٠ بضغطة زرّ.
      expect(after!.eligibleDays, 21);
      expect(after.additions, 50000);
    });

    test('⭐⭐⭐ تسجيل إجازة ثم إعادة الحساب تُنقِص الأيام فوراً', () async {
      final id = await newEmployee();
      final entry = await importInto(
          employeeId: id, name: 'أحمد علي', year: 2026, month: 7);
      expect(entry.eligibleDays, 30, reason: 'الشرط المسبق');

      // هذا ما يفعله زرّ «تسجيل إجازة» في سطر الكشف
      await db.employeesDao.insertLeave(
        EmployeeLeavesCompanion.insert(
          employeeId: id,
          fromDate: DateTime(2026, 7, 5),
          toDate: DateTime(2026, 7, 14),
          kind: const Value(LeaveKind.unpaid),
        ),
      );
      await repo.updateEntry(entryId: entry.id);

      final after = await db.payrollDao.getEntryById(entry.id);
      // 🔑 بلا إعادة الحساب يسجّل المالك إجازةً ولا يرى أثرها فيظنّ
      //   الميزة معطَّلة — وهو نمط ع-٠٦ من جديد
      expect(after!.eligibleDays, 20);
      expect(after.netAmount, 400000);
    });

    test('⭐⭐ والبابان يكتبان في المخزن نفسه — لا حقلَ إجازةٍ ثانٍ', () async {
      final id = await newEmployee();
      await db.employeesDao.insertLeave(
        EmployeeLeavesCompanion.insert(
          employeeId: id,
          fromDate: DateTime(2026, 7, 5),
          toDate: DateTime(2026, 7, 9),
          kind: const Value(LeaveKind.unpaid),
        ),
      );

      // ما يراه تبويب البطاقة هو نفسه ما يقرؤه حساب الكشف
      final visible = await db.employeesDao.watchLeaves(id).first;
      final counted = await db.employeesDao.unpaidLeaveDaysInMonth(
          employeeId: id, year: 2026, month: 7, workingDays: 30);

      expect(visible, hasLength(1));
      expect(counted, 5);
    });
  });
}
