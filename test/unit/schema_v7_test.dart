// ─────────────────────────────────────────────────────────────────────────────
// schema_v7_test.dart — كشوف الرواتب وقيودها (Schema v7)
//
// يغطّي قاعدة **جديدة** تُنشأ بـ `onCreate`. أما ما يحدث لقاعدة المالك
// القائمة حين تُرقَّى فذاك في `schema_v7_upgrade_test.dart` — وهو المسار
// الوحيد الذي يمكن أن يُتلف بياناته.
//
// **أخطر ما يحرسه هذا الملف — فهرسان يمنعان مضاعفة المال:**
//   ١. `(year, month)` فريد ⇒ لا كشفان لشهر واحد، فلا تُصرف رواتبه مرّتين
//   ٢. `(payroll_period_id, employee_id)` فريد ⇒ استيراد الملف مرّتين لا
//      يُنتج سطرين للموظف نفسه، فلا يتضاعف راتبه داخل الشهر
//
// **وترتيب الحذف:** `payroll_periods` ابنٌ للفترة المالية وأبٌ لسطوره.
// أي خلل في ترتيب مسحه يُعيد العطل ع-٠٩ (زرّ التصفير الذي لم يعمل قط).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/services/payroll_calculator.dart';
import 'package:sales_management/data/database/app_database.dart';

void main() {
  late AppDatabase db;
  late int periodId;
  late int treasuryId;
  late int employeeId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2025',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31, 23, 59, 59),
      ),
    );
    treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'خزنة البصرة', kind: const Value('main')),
    );
    employeeId = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'أحمد علي',
        position: const Value('سائق'),
        basicSalary: const Value(600000),
        treasuryId: Value(treasuryId),
      ),
    );
  });

  tearDown(() async => db.close());

  // ── مساعدات ─────────────────────────────────────────────────────────────

  Future<int> addPeriod({
    int year = 2025,
    int month = 2,
    String status = PayrollStatusDb.draft,
    double? rate,
    double fileTotal = 0,
    String hash = '',
  }) {
    return db.into(db.payrollPeriods).insert(
          PayrollPeriodsCompanion.insert(
            year: year,
            month: month,
            fiscalPeriodId: periodId,
            status: Value(status),
            exchangeRate: Value(rate),
            fileTotal: Value(fileTotal),
            sourceFileHash: Value(hash),
          ),
        );
  }

  Future<int> addEntry({
    required int payrollId,
    int? employee,
    double net = 600000,
    double netIqd = 600000,
    String currency = PayrollCurrency.iqd,
    String status = PayrollPaymentStatusDb.unpaid,
  }) {
    return db.into(db.salaryPayments).insert(
          SalaryPaymentsCompanion.insert(
            employeeId: employee ?? employeeId,
            paymentDate: DateTime(2025, 3, 1),
            payrollPeriodId: Value(payrollId),
            snapshotName: const Value('أحمد علي'),
            snapshotCurrency: Value(currency),
            netAmount: Value(net),
            netAmountIqd: Value(netIqd),
            paymentStatus: Value(status),
          ),
        );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // إصدار الـ Schema — الحارس على الرقم الحالي بالضبط
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ إصدار الـ Schema صار 7', () {
    // تغييرُه بلا ترقية يعني قاعدةً ناقصة عند المالك. وهذا الحارس هو
    // الموضع **الوحيد** الذي يثبّت الرقم الحالي — راجع تعليق
    // `schema_v6_test.dart` عن سبب تحويل حارسه إلى «٦ فأعلى».
    expect(db.schemaVersion, 7);
  });

  // ═══════════════════════════════════════════════════════════════════════
  // جدول كشوف الرواتب
  // ═══════════════════════════════════════════════════════════════════════

  group('كشف الشهر', () {
    test('⭐ الإنشاء والقراءة يعملان بالقيم الافتراضية الصحيحة', () async {
      final id = await addPeriod();
      final row = await (db.select(db.payrollPeriods)
            ..where((p) => p.id.equals(id)))
          .getSingle();

      expect(row.year, 2025);
      expect(row.month, 2);
      expect(row.status, PayrollStatusDb.draft,
          reason: 'الكشف يُولد مسودة — لا يمسّ خزينة حتى يُسدَّد');
      expect(row.workingDays, 30, reason: 'الشهر ثلاثون عرفاً');
      expect(row.workingDaysMode, WorkingDaysModeDb.fixed);
      expect(row.isDeleted, isFalse);
    });

    test('⭐ لا كشفان لشهر واحد — فلا تُصرف رواتبه مرّتين', () async {
      await addPeriod(month: 2);
      await expectLater(
        addPeriod(month: 2),
        throwsA(isA<Exception>()),
      );
      // شهر آخر يمرّ بلا مشكلة
      await expectLater(addPeriod(month: 3), completes);
    });

    test('حذف كشف خاطئ يُحرّر شهره لإعادة بنائه', () async {
      final id = await addPeriod(month: 5);
      await (db.update(db.payrollPeriods)..where((p) => p.id.equals(id)))
          .write(const PayrollPeriodsCompanion(isDeleted: Value(true)));

      // الفهرس جزئي على is_deleted = 0، فالشهر متاح من جديد
      await expectLater(addPeriod(month: 5), completes);
    });

    test('شهر خارج المدى مرفوض على مستوى الجدول', () async {
      await expectLater(addPeriod(month: 13), throwsA(isA<Exception>()));
      await expectLater(addPeriod(month: 0), throwsA(isA<Exception>()));
    });

    test('حالة غير معروفة مرفوضة — فلا يضيع كشف بخطأ إملائي', () async {
      // 'postd' بدل 'posted' كان سيجعل الكشف لا يظهر في أي قائمة
      await expectLater(
        addPeriod(status: 'postd'),
        throwsA(isA<Exception>()),
      );
    });

    test('سعر صرف صفر أو سالب مرفوض', () async {
      await expectLater(addPeriod(rate: 0), throwsA(isA<Exception>()));
      await expectLater(addPeriod(rate: -1), throwsA(isA<Exception>()));
      await expectLater(addPeriod(rate: 1320), completes);
    });

    test('مجموع الملف لا يكون سالباً', () async {
      await expectLater(addPeriod(fileTotal: -1), throwsA(isA<Exception>()));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // سطور الكشف
  // ═══════════════════════════════════════════════════════════════════════

  group('سطر الكشف', () {
    test('اللقطة والمحسوب يُحفظان ويُقرآن', () async {
      final pid = await addPeriod();
      final id = await addEntry(payrollId: pid);
      final row = await (db.select(db.salaryPayments)
            ..where((s) => s.id.equals(id)))
          .getSingle();

      expect(row.snapshotName, 'أحمد علي');
      expect(row.netAmountIqd, 600000);
      expect(row.paymentStatus, PayrollPaymentStatusDb.unpaid);
      expect(row.payrollPeriodId, pid);
    });

    test('⭐ الموظف لا يتكرّر في الكشف الواحد — فلا يتضاعف راتبه', () async {
      // الاستيراد تراكمي: ملف يُستورَد مرّتين كان سيُنتج سطرين للموظف نفسه
      final pid = await addPeriod();
      await addEntry(payrollId: pid);
      await expectLater(
        addEntry(payrollId: pid),
        throwsA(isA<Exception>()),
      );
    });

    test('الموظف نفسه يظهر في شهرين مختلفين بلا تعارض', () async {
      final feb = await addPeriod(month: 2);
      final mar = await addPeriod(month: 3);
      await addEntry(payrollId: feb);
      await expectLater(addEntry(payrollId: mar), completes);
    });

    test('عملة غير معروفة مرفوضة على مستوى الجدول', () async {
      final pid = await addPeriod();
      await expectLater(
        addEntry(payrollId: pid, currency: 'EUR'),
        throwsA(isA<Exception>()),
      );
    });

    test('حالة دفع غير معروفة مرفوضة', () async {
      final pid = await addPeriod();
      await expectLater(
        addEntry(payrollId: pid, status: 'مدفوع'),
        throwsA(isA<Exception>()),
      );
    });

    test('⭐ الصافي السالب مقبول في القاعدة — الرفض عند التسديد لا الحفظ',
        () async {
      // المسودة تحتمله ليُصحَّح. قيد `net_amount > 0` كان سيمنع استيراد
      // ملف فيه خطأ خصم بدل أن يُظهره للمالك ليصحّحه.
      final pid = await addPeriod();
      await expectLater(
        addEntry(payrollId: pid, net: -50000, netIqd: -50000),
        completes,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الموظف — الصفة والعملة
  // ═══════════════════════════════════════════════════════════════════════

  group('حقول الموظف الجديدة', () {
    test('الصفة والعملة تُحفظان', () async {
      final row = await db.employeesDao.getEmployeeById(employeeId);
      expect(row!.position, 'سائق');
      expect(row.salaryCurrency, PayrollCurrency.iqd,
          reason: 'الافتراض الدينار — لا يتغيّر سلوك الموظفين القدامى');
    });

    test('راتب بالدولار يُحفظ بعملته', () async {
      final id = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
          fullName: 'جون سميث',
          basicSalary: const Value(2000),
          salaryCurrency: const Value(PayrollCurrency.usd),
        ),
      );
      final row = await db.employeesDao.getEmployeeById(id);
      expect(row!.salaryCurrency, PayrollCurrency.usd);
    });

    test('عملة غير معروفة مرفوضة', () async {
      await expectLater(
        db.employeesDao.insertEmployee(
          EmployeesCompanion.insert(
            fullName: 'اختبار',
            salaryCurrency: const Value('EUR'),
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ترتيب الحذف — درس ع-٠٩
  // ═══════════════════════════════════════════════════════════════════════

  group('حذف الفترة المالية وكشوف رواتبها', () {
    test('⭐ فترة فيها كشف رواتب لا تُحذف — والرسالة تسمّي المانع', () async {
      await addPeriod();

      await expectLater(
        db.fiscalPeriodsDao.deleteEmptyPeriod(periodId),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'الرسالة تذكر كشف الرواتب',
            contains('كشف رواتب'),
          ),
        ),
      );
    });

    test('⭐ المحو القسري يمسح الكشوف وسطورها ويُعيد عددها', () async {
      final pid = await addPeriod();
      await addEntry(payrollId: pid);

      final purged =
          await db.fiscalPeriodsDao.purgeFiscalPeriodCompletely(periodId);

      expect(purged.payrolls, 1, reason: 'الشاهد يقول ما مُحي فعلاً');

      final left = await db
          .customSelect('SELECT COUNT(*) AS c FROM payroll_periods')
          .getSingle();
      expect(left.data['c'], 0);

      final entries = await db
          .customSelect('SELECT COUNT(*) AS c FROM salary_payments')
          .getSingle();
      expect(entries.data['c'], 0, reason: 'السطور تُمحى مع كشفها');
    });

    test('⭐ التصفير يمسح كشوف الرواتب ويعدّها', () async {
      final pid = await addPeriod();
      await addEntry(payrollId: pid);

      final removed = await db.resetFinancialData();
      expect(removed.payrolls, 1);

      final left = await db
          .customSelect('SELECT COUNT(*) AS c FROM payroll_periods')
          .getSingle();
      expect(left.data['c'], 0);
    });

    test('التصفير لا يمسّ الموظفين — يمحو الحركة لا الهيكل', () async {
      final pid = await addPeriod();
      await addEntry(payrollId: pid);
      await db.resetFinancialData();

      final employees = await db.employeesDao.getAllEmployees();
      expect(employees, hasLength(1),
          reason: 'بطاقة الموظف ليست حركة مالية');
    });
  });
}
