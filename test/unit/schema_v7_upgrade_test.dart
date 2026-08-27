// ─────────────────────────────────────────────────────────────────────────────
// schema_v7_upgrade_test.dart — مسار الترقية الحقيقي v6 ← v7
//
// **لماذا ملف منفصل عن `schema_v7_test.dart`؟**
//   ذاك يختبر قاعدة **جديدة** تُنشأ بـ `onCreate`. وهذا يختبر ما يحدث لقاعدة
//   المالك **القائمة فيها بيانات** حين تُرقَّى — وهو المسار الذي ستمرّ به
//   قاعدته على جهازه، والوحيد الذي يمكن أن يُتلف بياناته (الدرس د-٩).
//
// **ثلاثة أشياء يفعلها هذا الترحيل ولا يجوز أن يفشل أيّها:**
//
//   ١. **`net_amount_iqd` ← `net_amount`** — بدونه تُجمَع أصفارٌ في كل تقرير
//      رواتب جديد، فتظهر رواتب المالك السابقة كأنها لم تُصرف قط. وهي
//      بالدينار قطعاً: لم تكن للراتب عملة قبل v7 أصلاً.
//
//   ٢. **`payment_status = 'paid'`** — كل صفّ قديم نتج عن صرف فعليّ بسنده.
//      تركُه `'unpaid'` يجعل رواتب مصروفة تظهر مستحقّة، **فتُصرف مرّتين**.
//
//   ٣. **اللقطة تُملأ من جدول الموظفين** — وإلا عُرض كشفٌ قديم بلا اسم.
//      ⚠️ ولا يُنسَخ `basic_salary` من الموظف الحالي: هو مخزَّن في الصفّ
//      بقيمته وقت الصرف، ونسخُ الحالي فوقه **يُزوّر التاريخ**.
//
// **طريقة التجهيز:** نبني بالمخطط الحقيقي، ثم نُعيد الأعمدة الجديدة إلى
//   حالتها قبل الترحيل ونُنزل `user_version`. المخطط المكتوب يدوياً يتقادم
//   بصمت ويختبر شيئاً لم يعد موجوداً، بينما هذه الطريقة تختبر **جُمَل
//   الترحيل نفسها** وهي المقصودة.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/services/payroll_calculator.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sanad_v7_upgrade');
    dbFile = File('${tempDir.path}/test.sqlite');
  });

  tearDown(() async {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// يبني قاعدة كاملة بأثر مالي حقيقي، ثم يُرجعها إلى حالة الإصدار ٦
  Future<void> seedLegacyDatabase() async {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    final periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2025',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31, 23, 59, 59),
      ),
    );
    final treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );

    // موظفان — أحدهما براتب تغيّر لاحقاً لنثبت أن اللقطة لا تُزوّر التاريخ
    final ahmed = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'أحمد علي',
        basicSalary: const Value(700000), // راتبه **اليوم** بعد زيادة
        treasuryId: Value(treasuryId),
      ),
    );
    final sara = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'سارة حسن',
        basicSalary: const Value(500000),
      ),
    );

    // سند صرف راتب — كما كان النظام يفعل قبل v7 (سند لكل موظف)
    final voucherNumber = await db.fiscalPeriodsDao.getNextVoucherNumber(
      fiscalPeriodId: periodId,
      voucherType: 'sarf',
    );
    final voucherId = await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: voucherNumber,
        voucherType: 'sarf',
        treasuryId: treasuryId,
        fiscalPeriodId: periodId,
        amount: 600000,
        voucherDate: DateTime(2025, 3, 1),
        itemType: const Value('راتب'),
        personName: const Value('أحمد علي'),
      ),
    );

    // رواتب مصروفة فعلاً بالصيغة القديمة
    //
    // 📌 `netAmountIqd` مملوء هنا **لإرضاء حارس الكتابة الجديد** وحده
    //   (المرحلة ٤: لا راتب يُكتب بلا مقابله بالدينار). وهو لا يُضعف
    //   الاختبار: جملة `UPDATE` أدناه تُفرّغه فعلياً، وهي ما يُنشئ حالة v6
    //   التي يُختبَر الترحيل عليها.
    await db.employeesDao.insertSalaryPayment(
      SalaryPaymentsCompanion.insert(
        employeeId: ahmed,
        paymentDate: DateTime(2025, 3, 1),
        periodLabel: const Value('شباط 2025'),
        basicSalary: const Value(600000), // راتبه **وقتها** قبل الزيادة
        netAmount: const Value(600000),
        netAmountIqd: const Value(600000),
        voucherId: Value(voucherId),
      ),
    );
    await db.employeesDao.insertSalaryPayment(
      SalaryPaymentsCompanion.insert(
        employeeId: sara,
        paymentDate: DateTime(2025, 3, 1),
        periodLabel: const Value('شباط 2025'),
        basicSalary: const Value(500000),
        additions: const Value(50000),
        deductions: const Value(20000),
        netAmount: const Value(530000),
        netAmountIqd: const Value(530000),
      ),
    );

    await db.close();

    // ── إعادة الحالة إلى ما قبل الترقية ────────────────────────────────
    // نُفرّغ الأعمدة التي يملؤها ترحيل v7 لتصير الصفوف كما كانت في v6،
    // ونُنزل رقم الإصدار فيُشغّل الفتح التالي onUpgrade(6 → 7).
    final raw = sqlite3.open(dbFile.path);
    raw.execute(
      "UPDATE salary_payments SET snapshot_name = '', net_amount_iqd = 0, "
      "payment_status = 'unpaid', paid_at = NULL, exchange_rate = NULL",
    );
    raw.execute('PRAGMA user_version = 6');
    raw.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ الترقية تملأ المقابل بالدينار — لا تظهر الرواتب القديمة بصفر',
      () async {
    await seedLegacyDatabase();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final rows = await db.select(db.salaryPayments).get();

    expect(rows, hasLength(2));
    for (final r in rows) {
      expect(r.netAmountIqd, r.netAmount,
          reason: 'كل راتب قبل v7 بالدينار — والصفر يُخفيه من كل تقرير');
      expect(r.netAmountIqd, greaterThan(0));
      expect(r.exchangeRate, 1.0);
    }

    await db.close();
  });

  test('⭐ الترقية تُعلّم الرواتب القديمة مدفوعة — فلا تُصرف مرّتين', () async {
    await seedLegacyDatabase();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final rows = await db.select(db.salaryPayments).get();

    for (final r in rows) {
      expect(r.paymentStatus, PayrollPaymentStatusDb.paid,
          reason: 'راتب صُرف بسنده فعلاً — بقاؤه «مستحقّاً» يعني صرفه ثانيةً');
      expect(r.paidAt, r.paymentDate);
    }

    await db.close();
  });

  test('⭐ اللقطة تُملأ بالاسم ولا تُزوّر الراتب التاريخي', () async {
    await seedLegacyDatabase();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final rows = await db.select(db.salaryPayments).get();

    final ahmedRow = rows.firstWhere((r) => r.snapshotName == 'أحمد علي');
    expect(ahmedRow.snapshotName, 'أحمد علي');

    // 🔑 راتبه اليوم ٧٠٠٬٠٠٠ بعد زيادة، وسطر شباط يجب أن يبقى ٦٠٠٬٠٠٠.
    //   نسخُ الراتب الحالي فوق الصفّ كان سيُعيد كتابة التاريخ.
    expect(ahmedRow.basicSalary, 600000,
        reason: 'الترحيل ينسخ الاسم لا الراتب — التاريخ لا يُزوَّر');

    final sarahRow = rows.firstWhere((r) => r.snapshotName == 'سارة حسن');
    expect(sarahRow.netAmount, 530000);
    expect(sarahRow.additions, 50000);
    expect(sarahRow.deductions, 20000);

    await db.close();
  });

  test('⭐ جدول كشوف الرواتب يُنشأ في القاعدة المُرقّاة', () async {
    await seedLegacyDatabase();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    // لو نُسي إنشاؤه لتعطّلت شاشة الرواتب وحدها بـ «no such table» —
    // وهو أصعب أنواع الأعطال تشخيصاً
    final row = await db
        .customSelect('SELECT COUNT(*) AS c FROM payroll_periods')
        .getSingle();
    expect(row.data['c'], 0);

    await db.close();
  });

  test('⭐ أعمدة الموظف الجديدة تُضاف بقيم افتراضية آمنة', () async {
    await seedLegacyDatabase();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final employees = await db.employeesDao.getAllEmployees();

    expect(employees, hasLength(2));
    for (final e in employees) {
      expect(e.position, '');
      expect(e.salaryCurrency, PayrollCurrency.iqd,
          reason: 'لا عملة قبل v7 — فالافتراض الدينار لا فراغ يكسر الحساب');
    }

    await db.close();
  });

  test('⭐ عمود ربط سطر السلفة بكشف الرواتب يُضاف', () async {
    await seedLegacyDatabase();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final cols =
        await db.customSelect("PRAGMA table_info('advance_lines')").get();
    final names = cols.map((r) => r.data['name']).toList();
    expect(names, contains('payroll_period_id'));

    await db.close();
  });

  test('⭐ الترقية لا تفقد أي بيانات قائمة', () async {
    await seedLegacyDatabase();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    final vouchers = await db.vouchersDao.getAllVouchers();
    expect(vouchers, hasLength(1));
    expect(vouchers.first.amount, 600000);

    final periods = await db.fiscalPeriodsDao.watchAllPeriods().first;
    expect(periods, hasLength(1));

    final treasuries = await db.treasuriesDao.watchAllTreasuries().first;
    expect(treasuries, hasLength(1));

    await db.close();
  });

  test('⭐ رصيد الخزينة لا يتغيّر بالترقية', () async {
    await seedLegacyDatabase();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final balance = await db.treasuriesDao.getTreasuryBalance(1);

    // سند صرف واحد بـ ٦٠٠٬٠٠٠ ولا قبض — فالرصيد سالب بمقداره.
    // أي تغيّر هنا يعني أن الترقية لمست السندات، وهي لا يجوز أن تلمسها.
    expect(balance?.balanceIqd, -600000);

    await db.close();
  });

  test('إعادة فتح القاعدة بعد الترقية لا تُعيد الترحيل ولا تُفسده', () async {
    await seedLegacyDatabase();

    // الفتح الأول يُرقّي
    final first = AppDatabase.forTesting(NativeDatabase(dbFile));
    await first.select(first.salaryPayments).get();
    await first.close();

    // الثاني لا يُشغّل onUpgrade أصلاً (الإصدار صار ٧)
    final second = AppDatabase.forTesting(NativeDatabase(dbFile));
    final rows = await second.select(second.salaryPayments).get();

    expect(rows, hasLength(2), reason: 'لا تكرار ولا فقدان');
    for (final r in rows) {
      expect(r.netAmountIqd, r.netAmount);
      expect(r.paymentStatus, PayrollPaymentStatusDb.paid);
    }

    await second.close();
  });

  test('⭐ ترقية تُعاد على قاعدة مُرقّاة أصلاً لا ترمي', () async {
    // الحالة الواقعية: استعادة نسخة احتياطية بمخطط حديث ورقم إصدار أقدم،
    // أو ترقية تعثّرت في منتصفها. `ALTER TABLE ADD COLUMN` بلا حارس كان
    // يرمي `duplicate column name` ويُجهض بقية الترقية — فتبقى القاعدة
    // نصف مُرقّاة وتبدو ناجحة. راجع `_addColumnIfMissing`.
    await seedLegacyDatabase();

    final first = AppDatabase.forTesting(NativeDatabase(dbFile));
    await first.select(first.salaryPayments).get();
    await first.close();

    // نُنزل الإصدار من جديد على قاعدة تحوي كل الأعمدة أصلاً
    final raw = sqlite3.open(dbFile.path);
    raw.execute('PRAGMA user_version = 6');
    raw.dispose();

    final again = AppDatabase.forTesting(NativeDatabase(dbFile));
    final rows = await again.select(again.salaryPayments).get();
    expect(rows, hasLength(2));
    // الترحيل محروس بـ `WHERE snapshot_name = ''` فلا يُعيد كتابة شيء
    expect(rows.every((r) => r.snapshotName.isNotEmpty), isTrue);

    await again.close();
  });
}
