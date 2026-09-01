// ─────────────────────────────────────────────────────────────────────────────
// schema_v8_upgrade_test.dart — مسار الترقية الحقيقي v7 ← v8
//
// **لماذا ملف منفصل عن `schema_v8_test.dart`؟**
//   ذاك يختبر قاعدة **جديدة** تُنشأ بـ`onCreate`. وهذا يختبر ما يقع لقاعدة
//   المالك **القائمة فيها بيانات** حين تُرقَّى — وهو المسار الوحيد الذي يمكن
//   أن يُتلف بياناته (الدرس د-٩).
//
// ⚠️ **وهذه الترقية أخطر من سابقاتها**: كلها كانت `ADD COLUMN` تُضيف ولا
//   تمسّ. وهذه **تُعيد بناء جدول الموظفين كلّه** — تُنشئ جدولاً جديداً وتنسخ
//   إليه ثم تُسقط القديم. أيُّ خطأ فيها يمحو كادر الشركة.
//
// ═══ ما يجب أن يقع بالضبط ═══
//   ١. **`is_active = 0` ⇒ `status = 'terminated'`** — قرارُ إيقافٍ اتّخذه
//      المالك سابقاً لا يضيع في الترجمة.
//   ٢. **`is_active = 1` ⇒ `status = 'active'`**.
//   ٣. **كل حقل آخر يبقى كما هو** — الاسم والراتب والعملة وربط الخزينة.
//   ٤. **`is_active` يختفي** — عمودان لمعنى واحد يفترقان (ع-٤٠).
//   ٥. **قيد CHECK يُطبَّق على القاعدة المُرقّاة أيضاً** — وهذا سبب إعادة
//      البناء أصلاً: `ADD COLUMN` تُنتج قاعدةً بلا الحارس الذي تحمله
//      القاعدة الجديدة، أي قاعدتين مختلفتين تحت اسم واحد.
//   ٦. **السلف وسطور الرواتب تبقى مرتبطة** بموظفيها بعد إسقاط الجدول.
//
// **طريقة التجهيز:** نبني بالمخطط الحقيقي، ثم نُعيد جدول الموظفين إلى شكل
//   v7 بـSQL خام ونُنزل `user_version`. المخطط المكتوب يدوياً بالكامل يتقادم
//   بصمت، وهذه الطريقة تختبر **جُمَل الترحيل نفسها**.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/constants/employee_status.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sanad_v8_upgrade');
    dbFile = File('${tempDir.path}/test.sqlite');
  });

  tearDown(() async {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// يبني قاعدة بأثر مالي حقيقي ثم يُرجع جدول الموظفين إلى شكل الإصدار ٧
  Future<void> seedLegacyDatabase() async {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    final treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );

    // ثلاثة موظفين: قائم · موقوف · وثالث بالدولار لنثبت بقاء كل حقل
    final ahmed = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'أحمد علي',
        position: const Value('سائق'),
        basicSalary: const Value(600000),
        treasuryId: Value(treasuryId),
        hireDate: Value(DateTime(2024, 5, 1)),
      ),
    );
    final hadi = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'هادي كريم',
        basicSalary: const Value(450000),
      ),
    );
    await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'سعد جبار',
        basicSalary: const Value(500),
        salaryCurrency: const Value('USD'),
      ),
    );

    // سلفة على الموقوف — لنثبت بقاء الربط بعد إعادة بناء الجدول
    await db.employeesDao.insertAdvance(
      CashAdvancesCompanion.insert(
        employeeId: Value(hadi),
        amount: 200000,
        advanceDate: DateTime(2025, 6, 1),
      ),
    );

    // سطر راتب على القائم
    await db.employeesDao.insertSalaryPayment(
      SalaryPaymentsCompanion.insert(
        employeeId: ahmed,
        paymentDate: DateTime(2025, 3, 1),
        periodLabel: const Value('شباط 2025'),
        basicSalary: const Value(600000),
        netAmount: const Value(600000),
        netAmountIqd: const Value(600000),
      ),
    );

    await db.close();

    // ── إعادة جدول الموظفين إلى شكل v7 ────────────────────────────────
    final raw = sqlite3.open(dbFile.path);

    // ⚠️ **`legacy_alter_table` ضروري**: منذ SQLite 3.25 تُحدِّث
    //   `RENAME TO` مراجعَ المفاتيح الأجنبية في الجداول الأخرى تلقائياً،
    //   فتصير `cash_advances` تشير إلى `employees_old` — وهو ما يُفسد
    //   التجهيز نفسه لا الترحيل المُختبَر.
    raw.execute('PRAGMA legacy_alter_table = ON');
    raw.execute('ALTER TABLE employees RENAME TO employees_old');
    raw.execute('''
      CREATE TABLE employees (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        address TEXT NOT NULL DEFAULT '',
        position TEXT NOT NULL DEFAULT '',
        basic_salary REAL NOT NULL DEFAULT 0.0,
        salary_currency TEXT NOT NULL DEFAULT 'IQD',
        hire_date INTEGER NULL,
        treasury_id INTEGER NULL REFERENCES treasuries (id),
        notes TEXT NOT NULL DEFAULT '',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
        is_deleted INTEGER NOT NULL DEFAULT 0,
        CHECK (salary_currency IN ('IQD', 'USD'))
      )
    ''');
    raw.execute('''
      INSERT INTO employees (id, full_name, phone, address, position,
        basic_salary, salary_currency, hire_date, treasury_id, notes,
        is_active, created_at, is_deleted)
      SELECT id, full_name, phone, address, position, basic_salary,
        salary_currency, hire_date, treasury_id, notes, 1, created_at,
        is_deleted
      FROM employees_old
    ''');
    raw.execute('DROP TABLE employees_old');
    raw.execute('DROP TABLE departments');

    // المالك أوقف «هادي كريم» بالزرّ القديم
    raw.execute("UPDATE employees SET is_active = 0 WHERE full_name = 'هادي كريم'");

    raw.execute('PRAGMA user_version = 7');
    raw.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════

  test('⭐⭐⭐ الموقوف سابقاً يصير «منتهية خدمته» — القرار لا يضيع', () async {
    await seedLegacyDatabase();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final all = await db.employeesDao.getAllEmployees();

    final hadi = all.firstWhere((e) => e.fullName == 'هادي كريم');
    expect(hadi.status, EmployeeStatus.terminated);

    for (final e in all.where((e) => e.fullName != 'هادي كريم')) {
      expect(e.status, EmployeeStatus.active);
    }

    await db.close();
  });

  test('⭐⭐⭐ كل حقل آخر يبقى كما هو — إعادة البناء لا تُتلف شيئاً', () async {
    await seedLegacyDatabase();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final all = await db.employeesDao.getAllEmployees();

    expect(all, hasLength(3));

    final ahmed = all.firstWhere((e) => e.fullName == 'أحمد علي');
    expect(ahmed.position, 'سائق');
    expect(ahmed.basicSalary, 600000);
    expect(ahmed.treasuryId, isNotNull);
    expect(ahmed.hireDate, DateTime(2024, 5, 1));

    final saad = all.firstWhere((e) => e.fullName == 'سعد جبار');
    expect(saad.salaryCurrency, 'USD');
    expect(saad.basicSalary, 500);

    await db.close();
  });

  test('⭐⭐ الأعمدة الجديدة موجودة و`is_active` اختفى', () async {
    await seedLegacyDatabase();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final cols = await db
        .customSelect('PRAGMA table_info(employees)')
        .get()
        .then((rows) => rows.map((r) => r.data['name'] as String).toSet());

    expect(cols, containsAll(['status', 'department_id', 'sort_order']));
    expect(cols, isNot(contains('is_active')));

    await db.close();
  });

  test('⭐⭐⭐ قيد CHECK يعمل على القاعدة المُرقّاة — لا قاعدتان تحت اسم واحد',
      () async {
    await seedLegacyDatabase();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    // 🔴 لو كانت الترقية `ADD COLUMN` لمرّت هذه الجملة على قاعدة المالك
    //   ورُفضت على قاعدةٍ جديدة — نفس البرنامج بحارسين مختلفين.
    await expectLater(
      db.customStatement(
        "INSERT INTO employees (full_name, status) VALUES ('فلان', 'ghost')",
      ),
      throwsA(anything),
    );

    await db.close();
  });

  test('⭐⭐⭐ السلف وسطور الرواتب تبقى مرتبطة بعد إسقاط الجدول', () async {
    await seedLegacyDatabase();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final all = await db.employeesDao.getAllEmployees();
    final hadi = all.firstWhere((e) => e.fullName == 'هادي كريم');
    final ahmed = all.firstWhere((e) => e.fullName == 'أحمد علي');

    final footprint =
        await db.employeesDao.getEmployeeFinancialFootprint(hadi.id);
    expect(footprint.unpaidAdvances, 1);
    expect(footprint.advanceBalance, 200000);

    final ahmedPrint =
        await db.employeesDao.getEmployeeFinancialFootprint(ahmed.id);
    expect(ahmedPrint.salaryRows, 1);

    await db.close();
  });

  test('⭐⭐ جدول الأقسام يُنشأ في الترقية — لا «no such table» بعد شهر',
      () async {
    await seedLegacyDatabase();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    await expectLater(db.employeesDao.insertDepartment('مهندسون'), completes);
    expect(await db.employeesDao.getDepartments(), hasLength(1));

    await db.close();
  });

  test('⭐⭐ الترقية قابلة للتكرار — ترقيةٌ تعثّرت ثم أُعيدت لا تنهار',
      () async {
    await seedLegacyDatabase();

    // فتحٌ أول يُرقّي
    var db = AppDatabase.forTesting(NativeDatabase(dbFile));
    await db.employeesDao.getAllEmployees();
    await db.close();

    // ثم نُنزل الرقم بلا إرجاع الأعمدة — كما يقع بعد استعادة نسخة أو تعثّر
    final raw = sqlite3.open(dbFile.path);
    raw.execute('PRAGMA user_version = 7');
    raw.dispose();

    db = AppDatabase.forTesting(NativeDatabase(dbFile));
    await expectLater(db.employeesDao.getAllEmployees(), completes);
    expect(await db.employeesDao.getAllEmployees(), hasLength(3));
    await db.close();
  });
}
