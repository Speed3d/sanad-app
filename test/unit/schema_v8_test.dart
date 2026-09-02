// ─────────────────────────────────────────────────────────────────────────────
// schema_v8_test.dart — الأقسام وحالة الموظف والترتيب اليدوي (Schema v8)
//
// **البلاغ** (المالك 2026-08-30 · الدفعة د):
//   «حالة الموظف: حالي · منتهية خدمته · إجازة» و«أقسام بترتيب يدوي:
//   مهندسون ١–٧ · فنيون ٨–١٩ · سواق ٢٠–٣٥».
//
// ═══ ما يحرسه هذا الملف ═══
//   ١. **`status` حلّ محلّ `is_active` ولم يُضَف بجواره** — عمودان لمعنى
//      واحد يفترقان بأول كتابة تنسى أحدهما (نمط ع-٤٠).
//   ٢. **الترتيب**: القسم ثم الموظف داخله ثم **المعرّف** — لا الاسم.
//      فضُّ التعادل بالاسم كان يُعيد الترتيب الأبجدي المرفوض صراحةً من
//      الباب الخلفي (بلاغ المالك 2026-08-25).
//   ٣. **الوعد المكتوب صار حارساً**: «منتهي الخدمة لا يظهر في كشوف الرواتب
//      الجديدة» كان مكتوباً في رسالة حارس الحذف منذ الدفعة ب، و`is_active`
//      **لا يقرؤه أي مسار رواتب** — وعدٌ للمالك لا يقع (نمط ع-٠٦).
//   ٤. **حذف القسم يفكّ ربط موظفيه** — وإلا بقي انتماءٌ شبحيّ لا يراه أحد.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/constants/employee_status.dart';
import 'package:sales_management/core/services/payroll_row_parser.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/payroll_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<int> addEmployee(String name, {int? dept, int order = 0}) {
    return db.employeesDao.insertEmployee(EmployeesCompanion.insert(
      fullName: name,
      departmentId: Value(dept),
      sortOrder: Value(order),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════
  // المخطَّط
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ إصدار الـ Schema صار 8', () {
    // الموضع **الوحيد** الذي يثبّت الرقم الحالي
    // يُحدَّث مع كل إصدار — والاختبار هنا يحرس أن الرقم لم يُنسَ
    expect(db.schemaVersion, 10);
  });

  test('⭐⭐ `is_active` حُذف من جدول الموظفين ولم يبقَ بجوار `status`', () async {
    final cols = await db
        .customSelect('PRAGMA table_info(employees)')
        .get()
        .then((rows) => rows.map((r) => r.data['name'] as String).toSet());

    expect(cols, contains('status'));
    expect(cols, contains('department_id'));
    expect(cols, contains('sort_order'));
    // 🔑 عمودان لمعنى واحد يفترقان بأول كتابة تنسى أحدهما (ع-٤٠)
    expect(cols, isNot(contains('is_active')));
  });

  test('⭐⭐ قيد CHECK يرفض حالة رابعة — الحارس في القاعدة لا في الشاشة',
      () async {
    await expectLater(
      db.customStatement(
        "INSERT INTO employees (full_name, status) VALUES ('فلان', 'ghost')",
      ),
      throwsA(anything),
    );
  });

  test('⭐ الحالة الافتراضية «حالي»', () async {
    final id = await addEmployee('أحمد');
    final e = await db.employeesDao.getEmployeeById(id);
    expect(e!.status, EmployeeStatus.active);
  });

  test('⭐⭐ الـDAO يرفض حالة غير معروفة برسالة عربية', () async {
    final id = await addEmployee('أحمد');
    await expectLater(
      db.employeesDao.setEmployeeStatus(id, 'ghost'),
      throwsA(isA<StateError>()),
    );
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الأقسام
  // ═══════════════════════════════════════════════════════════════════════

  group('الأقسام', () {
    test('⭐ القسم الجديد يقع آخر القائمة', () async {
      await db.employeesDao.insertDepartment('مهندسون');
      await db.employeesDao.insertDepartment('فنيون');
      await db.employeesDao.insertDepartment('سواق');

      final list = await db.employeesDao.getDepartments();
      expect(list.map((d) => d.name).toList(), ['مهندسون', 'فنيون', 'سواق']);
    });

    test('⭐⭐ الاسم المكرَّر يُرفَض برسالة عربية لا برسالة SQLite', () async {
      await db.employeesDao.insertDepartment('فنيون');
      await expectLater(
        db.employeesDao.insertDepartment('  فنيون  '),
        throwsA(isA<StateError>()),
      );
    });

    test('⭐⭐ قسمٌ حُذف يمكن إنشاؤه من جديد — الفرادة على غير المحذوف', () async {
      final id = await db.employeesDao.insertDepartment('سواق');
      await db.employeesDao.deleteDepartment(id);

      // 🔴 قيدُ `UNIQUE` مطلقاً كان سيمنع هذا **إلى الأبد**
      await expectLater(db.employeesDao.insertDepartment('سواق'), completes);
    });

    test('⭐⭐⭐ حذف القسم يفكّ ربط موظفيه صراحةً — لا انتماء شبحيّ', () async {
      final dept = await db.employeesDao.insertDepartment('فنيون');
      await addEmployee('علي', dept: dept);
      await addEmployee('حسن', dept: dept);

      final moved = await db.employeesDao.deleteDepartment(dept);
      expect(moved, 2);

      final all = await db.employeesDao.getAllEmployees();
      expect(all.every((e) => e.departmentId == null), isTrue);
      expect(all, hasLength(2), reason: 'لا يُحذف أحد منهم');
    });

    test('⭐ إعادة الترتيب تُسنِد ٠..ن بترتيب المُمرَّر', () async {
      final a = await db.employeesDao.insertDepartment('مهندسون');
      final b = await db.employeesDao.insertDepartment('فنيون');
      final c = await db.employeesDao.insertDepartment('سواق');

      await db.employeesDao.reorderDepartments([c, a, b]);

      final list = await db.employeesDao.getDepartments();
      expect(list.map((d) => d.name).toList(), ['سواق', 'مهندسون', 'فنيون']);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الترتيب
  // ═══════════════════════════════════════════════════════════════════════

  group('ترتيب الموظفين', () {
    test('⭐⭐⭐ بلا أقسام ولا ترتيب: **ترتيب الإضافة** لا الأبجدي', () async {
      // 🔴 هذا ما كسره فضُّ التعادل بالاسم — والترتيب الأبجدي مرفوضٌ
      //   صراحةً منذ 2026-08-25: المالك يطابق القائمة بورقة المحاسب.
      await addEmployee('ياسر هاشم');
      await addEmployee('مصطفى نور');
      await addEmployee('بشار سعد');

      final all = await db.employeesDao.getAllEmployees();
      expect(all.map((e) => e.fullName).toList(),
          ['ياسر هاشم', 'مصطفى نور', 'بشار سعد']);
    });

    test('⭐⭐⭐ القسم أولاً ثم الترتيب داخله — ومن بلا قسم في الآخر', () async {
      final eng = await db.employeesDao.insertDepartment('مهندسون');
      final tech = await db.employeesDao.insertDepartment('فنيون');

      await addEmployee('بلا قسم');
      await addEmployee('فنيّ ٢', dept: tech, order: 1);
      await addEmployee('مهندس ٢', dept: eng, order: 1);
      await addEmployee('فنيّ ١', dept: tech, order: 0);
      await addEmployee('مهندس ١', dept: eng, order: 0);

      final all = await db.employeesDao.getAllEmployees();
      expect(all.map((e) => e.fullName).toList(), [
        'مهندس ١',
        'مهندس ٢',
        'فنيّ ١',
        'فنيّ ٢',
        'بلا قسم',
      ]);
    });

    test('⭐⭐ ترتيب الأقسام يقود ترتيب الموظفين', () async {
      final eng = await db.employeesDao.insertDepartment('مهندسون');
      final tech = await db.employeesDao.insertDepartment('فنيون');
      await addEmployee('مهندس', dept: eng);
      await addEmployee('فنيّ', dept: tech);

      await db.employeesDao.reorderDepartments([tech, eng]);

      final all = await db.employeesDao.getAllEmployees();
      expect(all.map((e) => e.fullName).toList(), ['فنيّ', 'مهندس']);
    });

    test('⭐⭐ النقل إلى قسم يضع الموظف **آخره** لا أوّله', () async {
      final dept = await db.employeesDao.insertDepartment('فنيون');
      await addEmployee('الأول', dept: dept, order: 0);
      await addEmployee('الثاني', dept: dept, order: 1);
      final newcomer = await addEmployee('القادم');

      await db.employeesDao.assignDepartment(newcomer, dept);

      final all = await db.employeesDao.getAllEmployees();
      expect(all.map((e) => e.fullName).toList(),
          ['الأول', 'الثاني', 'القادم']);
    });

    test('⭐ إعادة ترتيب الموظفين تُسنِد ٠..ن', () async {
      final dept = await db.employeesDao.insertDepartment('فنيون');
      final a = await addEmployee('أ', dept: dept);
      final b = await addEmployee('ب', dept: dept);
      final c = await addEmployee('ج', dept: dept);

      await db.employeesDao.reorderEmployees([c, b, a]);

      final all = await db.employeesDao.getAllEmployees();
      expect(all.map((e) => e.fullName).toList(), ['ج', 'ب', 'أ']);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 🔑 الوعد المكتوب صار حارساً
  // ═══════════════════════════════════════════════════════════════════════

  group('منتهي الخدمة لا يدخل كشفاً جديداً', () {
    late PayrollRepository repo;
    late int periodId;
    final year = DateTime.now().year;

    setUp(() async {
      repo = PayrollRepository(db);
      await db.fiscalPeriodsDao.insertPeriod(FiscalPeriodsCompanion.insert(
        name: '$year',
        startDate: DateTime(year, 1, 1),
        endDate: DateTime(year, 12, 31, 23, 59, 59),
      ));
      periodId = await repo.createOrGetPeriod(year: year, month: 3);
    });

    ResolvedPayrollRow rowFor(int employeeId, String name) => ResolvedPayrollRow(
          employeeId: employeeId,
          row: ParsedPayrollRow(
            rowNumber: 1,
            rowLabel: 'صف 1',
            employeeName: name,
            basicSalary: 600000,
          ),
        );

    test('⭐⭐⭐ صفّه لا يُدرَج — وكان الوعد مكتوباً بلا حارس', () async {
      final id = await addEmployee('هادي كريم');
      await db.employeesDao
          .setEmployeeStatus(id, EmployeeStatus.terminated);

      final result = await repo.importRows(
        periodId: periodId,
        rows: [rowFor(id, 'هادي كريم')],
      );

      expect(result.added, 0);
      expect(result.skippedTerminated, ['هادي كريم']);
      expect(await repo.getEntries(periodId), isEmpty);
    });

    test('⭐⭐⭐ ولا يُنشَأ نسخةً ثانية — المطابقة تقع ثم يُستبعَد', () async {
      final id = await addEmployee('هادي كريم');
      await db.employeesDao
          .setEmployeeStatus(id, EmployeeStatus.terminated);

      await repo.importRows(
        periodId: periodId,
        rows: [rowFor(id, 'هادي كريم')],
      );

      // 🔴 إخراجه من **مرشّحي المطابقة** كان سيجعله «موظفاً جديداً»
      //   فيُنشَأ مرّة ثانية بسلفه وتاريخه المفقود
      final all = await db.employeesDao.getAllEmployees();
      expect(all, hasLength(1));
    });

    test('⭐⭐ والمُجاز **يبقى**: الإجازة قد تكون مدفوعة والبرنامج لا يعرف',
        () async {
      final id = await addEmployee('سعد جبار');
      await db.employeesDao.setEmployeeStatus(id, EmployeeStatus.leave);

      final result = await repo.importRows(
        periodId: periodId,
        rows: [rowFor(id, 'سعد جبار')],
      );

      expect(result.added, 1);
      expect(result.skippedTerminated, isEmpty);
    });
  });
}
