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
import 'package:sales_management/data/database/tables/employee_events_table.dart';
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

  // ═══════════════════════════════════════════════════════════════════════
  // البند أ — التنبيه والخيار عند تعارض الملف مع خدمة الموظف
  // ═══════════════════════════════════════════════════════════════════════

  group('تعارض الملف مع الخدمة — بلاغ ياسر', () {
    /// سطرٌ محسوم المطابقة كما يصل من شاشة الاستيراد
    ResolvedPayrollRow rowFor(int employeeId, String name, {int? fileDays}) =>
        ResolvedPayrollRow(
          employeeId: employeeId,
          row: ParsedPayrollRow(
            rowNumber: 1,
            rowLabel: 'صف 1',
            employeeName: name,
            basicSalary: 3000000,
            eligibleDays: fileDays,
          ),
        );

    test('⭐⭐⭐ حالة ياسر: الملف ٣٠ والبرنامج يومان — يُكشف قبل الكتابة',
        () async {
      final id = await newEmployee(
          name: 'ياسر ناصر خلف', hireDate: DateTime(2022, 6, 1));
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 9, 2),
        reference: 'الكتاب ١٢٠',
      );
      final periodId = await repo.createOrGetPeriod(year: 2026, month: 9);

      final conflicts = await repo.previewServiceConflicts(
        periodId: periodId,
        rows: [rowFor(id, 'ياسر ناصر خلف', fileDays: 30)],
      );

      // 🔴 قبل الإصلاح: لا كاشف أصلاً — يمرّ الملف صامتاً ويُلغي اليومين
      expect(conflicts, hasLength(1));
      expect(conflicts.first.fileDays, 30);
      expect(conflicts.first.computedDays, 2);
      expect(conflicts.first.reason, contains('أُنهيت خدمته'));
      expect(conflicts.first.employeeName, 'ياسر ناصر خلف');
    });

    test('⭐⭐⭐ «طبّق حساب البرنامج» يُسقط عمود الملف فيُحتسب يومان',
        () async {
      final id = await newEmployee(name: 'ياسر ناصر خلف');
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 9, 2),
      );
      final periodId = await repo.createOrGetPeriod(year: 2026, month: 9);

      await repo.importRows(
        periodId: periodId,
        rows: [rowFor(id, 'ياسر ناصر خلف', fileDays: 30)],
        applyComputedDays: true,
      );

      final entry = (await db.payrollDao.getEntries(periodId)).first;
      expect(entry.eligibleDays, 2);
    });

    test('⭐⭐⭐ «اعتمد الملف» يُبقي ٣٠ — القرار للمالك لا للبرنامج', () async {
      final id = await newEmployee(name: 'ياسر ناصر خلف');
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 9, 2),
      );
      final periodId = await repo.createOrGetPeriod(year: 2026, month: 9);

      await repo.importRows(
        periodId: periodId,
        rows: [rowFor(id, 'ياسر ناصر خلف', fileDays: 30)],
        applyComputedDays: false,
      );

      final entry = (await db.payrollDao.getEntries(periodId)).first;
      expect(entry.eligibleDays, 30,
          reason: 'اعتماد الملف يجب أن يبقى ممكناً — المحاسب قد طرحها أصلاً');
    });

    test('⭐⭐ الإجازة بلا راتب تُكشف كذلك', () async {
      final id = await newEmployee();
      await db.employeesDao.insertLeave(
        EmployeeLeavesCompanion.insert(
          employeeId: id,
          fromDate: DateTime(2026, 7, 5),
          toDate: DateTime(2026, 7, 14),
          kind: const Value(LeaveKind.unpaid),
        ),
      );
      final periodId = await repo.createOrGetPeriod(year: 2026, month: 7);

      final conflicts = await repo.previewServiceConflicts(
        periodId: periodId,
        rows: [rowFor(id, 'أحمد علي', fileDays: 30)],
      );

      expect(conflicts, hasLength(1));
      expect(conflicts.first.computedDays, 20);
      expect(conflicts.first.reason, contains('إجازة بلا راتب'));
    });

    test('⭐⭐ ملفٌ بلا عمود أيام لا يُنتج تعارضاً — الحساب يقع وحده', () async {
      final id = await newEmployee();
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 9, 2),
      );
      final periodId = await repo.createOrGetPeriod(year: 2026, month: 9);

      final conflicts = await repo.previewServiceConflicts(
        periodId: periodId,
        rows: [rowFor(id, 'أحمد علي')],
      );
      expect(conflicts, isEmpty);
    });

    test('⭐⭐ موظفٌ بلا خدمة استثنائية لا يظهر في التعارضات', () async {
      final id = await newEmployee();
      final periodId = await repo.createOrGetPeriod(year: 2026, month: 7);

      final conflicts = await repo.previewServiceConflicts(
        periodId: periodId,
        rows: [rowFor(id, 'أحمد علي', fileDays: 25)],
      );
      // ٢٥ في الملف قرارٌ محاسبي لا شأن له بالخدمة — لا يُسأل عنه
      expect(conflicts, isEmpty);
    });

    test('⭐⭐⭐ «طبّق البرنامج» لا يمسّ سطراً بلا سياق خدمة', () async {
      final terminated = await newEmployee(name: 'ياسر');
      await db.employeesDao.terminateEmployee(
        employeeId: terminated,
        terminationDate: DateTime(2026, 9, 2),
      );
      final normal = await newEmployee(name: 'أحمد');
      final periodId = await repo.createOrGetPeriod(year: 2026, month: 9);

      await repo.importRows(
        periodId: periodId,
        rows: [
          rowFor(terminated, 'ياسر', fileDays: 30),
          ResolvedPayrollRow(
            employeeId: normal,
            row: const ParsedPayrollRow(
              rowNumber: 2,
              rowLabel: 'صف 2',
              employeeName: 'أحمد',
              basicSalary: 600000,
              eligibleDays: 25,
            ),
          ),
        ],
        applyComputedDays: true,
      );

      final entries = await db.payrollDao.getEntries(periodId);
      final y = entries.firstWhere((e) => e.snapshotName == 'ياسر');
      final a = entries.firstWhere((e) => e.snapshotName == 'أحمد');

      expect(y.eligibleDays, 2, reason: 'المتعارض يُعاد حسابه');
      // ⚠️ **وهذا جوهر القرار**: ٢٥ في سطر أحمد قرارٌ محاسبي لا علاقة له
      //   بالخدمة، وإلغاءُ العمود عن الجميع يُعيد حساب ما لم يُسأل عنه
      expect(a.eligibleDays, 25, reason: 'غير المتعارض يبقى كما ذكر الملف');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // البند ج — «في إجازة» مصدرٌ واحد
  // ═══════════════════════════════════════════════════════════════════════

  group('حالة «في إجازة» تُشتقّ من الجدول', () {
    Future<String> statusOf(int id) async =>
        (await db.employeesDao.getEmployeeById(id))!.status;

    Future<int> leaveCovering(int id, {required bool today}) {
      final now = DateTime.now();
      final from = today
          ? DateTime(now.year, now.month, now.day).subtract(const Duration(days: 2))
          : DateTime(2020, 1, 1);
      final to = today
          ? DateTime(now.year, now.month, now.day).add(const Duration(days: 2))
          : DateTime(2020, 1, 10);
      return db.employeesDao.insertLeave(
        EmployeeLeavesCompanion.insert(
          employeeId: id,
          fromDate: from,
          toDate: to,
          kind: const Value(LeaveKind.unpaid),
        ),
      );
    }

    test('⭐⭐⭐ تسجيل إجازة تشمل اليوم يجعله «في إجازة»', () async {
      final id = await newEmployee();
      expect(await statusOf(id), EmployeeStatus.active, reason: 'الشرط المسبق');

      await leaveCovering(id, today: true);

      // 🔴 بلاغ المالك: «أسجّل إجازة ثم أضغط فلتر «في إجازة» فلا يظهر اسمه»
      //   — لأن الجدول والحالة كانا مصدرين منفصلين.
      expect(await statusOf(id), EmployeeStatus.leave);
    });

    test('⭐⭐⭐ إجازةٌ انقضت لا تجعله «في إجازة»', () async {
      final id = await newEmployee();
      await leaveCovering(id, today: false);
      expect(await statusOf(id), EmployeeStatus.active);
    });

    test('⭐⭐⭐ انقضاء الإجازة يُعيده «حالياً» عند إعادة الاشتقاق', () async {
      final id = await newEmployee();
      final leaveId = await leaveCovering(id, today: true);
      expect(await statusOf(id), EmployeeStatus.leave);

      // الحذف يُعيد الاشتقاق — كما يفعل انقضاء المدّة عند فتح الشاشة
      await db.employeesDao.softDeleteLeave(leaveId);
      expect(await statusOf(id), EmployeeStatus.active);
    });

    test('⭐⭐⭐ منتهي الخدمة لا تُمَسّ حالته بإجازة — الإنهاء أقوى', () async {
      final id = await newEmployee();
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 5, 1),
      );

      await leaveCovering(id, today: true);

      // ⚠️ إعادته «حالياً» أو «في إجازة» تُدخِله كشوف الرواتب من جديد —
      //   عطلٌ مالي لا تجميلي
      expect(await statusOf(id), EmployeeStatus.terminated);
    });

    test('⭐⭐ إعادة الاشتقاق الشاملة تُصحّح من تخلّفت حالته', () async {
      final id = await newEmployee();
      await leaveCovering(id, today: true);
      // نُفسِد الحالة يدوياً كما لو تخلّفت
      await db.employeesDao.setEmployeeStatus(id, EmployeeStatus.active);
      expect(await statusOf(id), EmployeeStatus.active);

      await db.employeesDao.refreshAllLeaveStatuses();
      expect(await statusOf(id), EmployeeStatus.leave);
    });

    test('⭐⭐ «في إجازة» ليست من الحالات التي تُضبط بيد', () {
      // مصدرٌ واحد للمعنى: من أراد إجازةً يسجّلها بتاريخيها
      expect(EmployeeStatus.manuallySettable, isNot(contains(EmployeeStatus.leave)));
      expect(EmployeeStatus.all, contains(EmployeeStatus.leave));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // البند ب — لقطة الإجازة على سطر الراتب
  // ═══════════════════════════════════════════════════════════════════════

  group('لقطة الإجازة تُفسّر الأيام', () {
    test('⭐⭐⭐ الإجازة بلا راتب تُكتَب على السطر لا تُحسب وتُنسى', () async {
      final id = await newEmployee();
      await db.employeesDao.insertLeave(
        EmployeeLeavesCompanion.insert(
          employeeId: id,
          fromDate: DateTime(2026, 7, 5),
          toDate: DateTime(2026, 7, 14),
          kind: const Value(LeaveKind.unpaid),
        ),
      );

      final entry = await importInto(
          employeeId: id, name: 'أحمد علي', year: 2026, month: 7);

      expect(entry.eligibleDays, 20);
      // 🔴 قبل الإصلاح: الكشف يعرض ٢٠ يوماً بلا سبب مكتوب فيبدو خطأً
      expect(entry.leaveDaysUnpaid, 10);
      expect(entry.leaveDaysPaid, 0);
    });

    test('⭐⭐⭐ الإجازة براتب تُكتَب وإن لم تُغيّر رقماً', () async {
      final id = await newEmployee();
      await db.employeesDao.insertLeave(
        EmployeeLeavesCompanion.insert(
          employeeId: id,
          fromDate: DateTime(2026, 7, 3),
          toDate: DateTime(2026, 7, 7),
          kind: const Value(LeaveKind.paid),
        ),
      );

      final entry = await importInto(
          employeeId: id, name: 'أحمد علي', year: 2026, month: 7);

      // الراتب كامل — وهذا صحيح
      expect(entry.eligibleDays, 30);
      expect(entry.netAmount, 600000);
      // 🔴 وقبل الإصلاح كانت تختفي تماماً: لا أثر لها في أي رقم ولا حقل
      expect(entry.leaveDaysPaid, 5);
    });

    test('⭐⭐ اللقطة تُحدَّث مع إعادة الحساب', () async {
      final id = await newEmployee();
      final entry = await importInto(
          employeeId: id, name: 'أحمد علي', year: 2026, month: 7);
      expect(entry.leaveDaysUnpaid, 0);

      await db.employeesDao.insertLeave(
        EmployeeLeavesCompanion.insert(
          employeeId: id,
          fromDate: DateTime(2026, 7, 5),
          toDate: DateTime(2026, 7, 9),
          kind: const Value(LeaveKind.unpaid),
        ),
      );
      await repo.updateEntry(entryId: entry.id);

      final after = await db.payrollDao.getEntryById(entry.id);
      expect(after!.leaveDaysUnpaid, 5);
      expect(after.eligibleDays, 25);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // البند د — سجل حركات الموظف
  // ═══════════════════════════════════════════════════════════════════════

  group('سجل الحركات', () {
    Future<List<EmployeeEvent>> eventsOf(int id) =>
        db.employeesDao.watchEvents(id).first;

    test('⭐⭐⭐ تعديل الراتب يُسجَّل بقيمتيه — وكان بلا أثر في القاعدة كلها',
        () async {
      final id = await newEmployee(salary: 2500000);

      await db.employeesDao.logEvent(
        employeeId: id,
        kind: EmployeeEventKind.salaryChanged,
        description: 'تعديل الراتب من 2,500,000 إلى 3,000,000',
        oldValue: 2500000,
        newValue: 3000000,
      );

      final events = await eventsOf(id);
      final salary =
          events.firstWhere((e) => e.kind == EmployeeEventKind.salaryChanged);
      // 🔑 القيمتان مفصولتان عن النصّ: التقرير قد يريد الفرق رقماً
      expect(salary.oldValue, 2500000);
      expect(salary.newValue, 3000000);
      expect(salary.description, contains('3,000,000'));
    });

    test('⭐⭐⭐ الإجازة تُسجَّل حدثاً بتاريخ وقوعها لا تسجيلها', () async {
      final id = await newEmployee();
      await db.employeesDao.insertLeave(
        EmployeeLeavesCompanion.insert(
          employeeId: id,
          fromDate: DateTime(2026, 7, 5),
          toDate: DateTime(2026, 7, 9),
          kind: const Value(LeaveKind.unpaid),
          reference: const Value('الكتاب ٧٧'),
        ),
      );

      final events = await eventsOf(id);
      final e = events.firstWhere((x) => x.kind == EmployeeEventKind.leaveAdded);
      // إجازةٌ تُسجَّل اليوم عن الشهر الماضي حدثُها الشهر الماضي
      expect(e.eventDate, DateTime(2026, 7, 5));
      expect(e.description, contains('بلا راتب'));
      expect(e.description, contains('5 أيام'));
      expect(e.reference, 'الكتاب ٧٧');
    });

    test('⭐⭐⭐ إنهاء الخدمة يُسجَّل بسنده وتاريخه', () async {
      final id = await newEmployee();
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 9, 2),
        reference: 'الأمر الإداري ١٢٠',
        notes: 'بطلبه',
      );

      final e = (await eventsOf(id))
          .firstWhere((x) => x.kind == EmployeeEventKind.terminated);
      expect(e.eventDate, DateTime(2026, 9, 2));
      expect(e.reference, 'الأمر الإداري ١٢٠');
      expect(e.notes, 'بطلبه');
    });

    test('⭐⭐ العودة إلى الخدمة تُسجَّل كذلك — والسجل يروي الرحلة كاملة',
        () async {
      final id = await newEmployee();
      await db.employeesDao.terminateEmployee(
        employeeId: id,
        terminationDate: DateTime(2026, 9, 2),
      );
      await db.employeesDao.reinstateEmployee(id);

      final kinds = (await eventsOf(id)).map((e) => e.kind).toList();
      expect(kinds, contains(EmployeeEventKind.terminated));
      expect(kinds, contains(EmployeeEventKind.reinstated));
    });

    test('⭐⭐ الأحدث أولاً — والسجل يُقرأ من الأعلى', () async {
      final id = await newEmployee();
      await db.employeesDao.logEvent(
        employeeId: id,
        kind: EmployeeEventKind.statusChanged,
        eventDate: DateTime(2026, 1, 1),
        description: 'قديم',
      );
      await db.employeesDao.logEvent(
        employeeId: id,
        kind: EmployeeEventKind.statusChanged,
        eventDate: DateTime(2026, 12, 1),
        description: 'حديث',
      );

      final events = await eventsOf(id);
      expect(events.first.description, 'حديث');
    });

    test('⭐⭐⭐ فشل تسجيل حدثٍ لا يُفشل العملية التي نجحت', () async {
      // موظفٌ لا وجود له ⇒ المفتاح الأجنبي يرفض الحدث
      await db.employeesDao.logEvent(
        employeeId: 999999,
        kind: EmployeeEventKind.salaryChanged,
        description: 'حدثٌ ليتيم',
      );
      // ⚠️ لا استثناء يخرج: السجل يخدم القراءة، والعملية المالية أولى منه
      expect(await eventsOf(999999), isEmpty);
    });

    test('⭐⭐ سجل موظفٍ لا يختلط بسجل غيره', () async {
      final a = await newEmployee(name: 'أ');
      final b = await newEmployee(name: 'ب');
      await db.employeesDao.logEvent(
          employeeId: a, kind: EmployeeEventKind.hired, description: 'أ');

      expect(await eventsOf(a), hasLength(1));
      expect(await eventsOf(b), isEmpty);
    });
  });
}
