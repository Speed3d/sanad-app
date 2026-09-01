// ─────────────────────────────────────────────────────────────────────────────
// employees_departments_test.dart — شاشة الموظفين بالأقسام والحالة (Schema v8)
//
// **لماذا اختبار ودجت وقد نجحت ٢٧ وحدةً؟**
//   لأن اختبارات الوحدة تُثبت أن الترتيب يصل **من القاعدة** صحيحاً، وهذا
//   يُثبت أنه **يُعرَض**. والدرس د-٣ في هذا المشروع: ١٨٥ اختباراً نجحت
//   بينما الميزة معطوبة كلياً — كانت في طبقة العرض.
//
// **وما يمسكه تحديداً:**
//   • أي استثناء أثناء البناء (شاشة حمراء)
//   • **تجاوز عرض** — وهو ما وقع فعلاً في الدفعة ج (ع-٥١) عند إضافة زرّ
//   • ظهور عناوين الأقسام وشارة الحالة فعلاً لا في القاعدة فقط
//   • **مقبض السحب**: `SliverReorderableList` لا تُضيفه بنفسها، وغيابه
//     يجعل الترتيب يبدو معطَّلاً وهو مفعَّل — عطلٌ صامت في الواجهة
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/constants/employee_status.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/presentation/features/employees/employees_screen.dart';
import 'package:sales_management/presentation/providers/database_provider.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  /// ضخّ إطارات — لا `pumpAndSettle`: مؤشّر التحميل أنيميشن لا ينتهي
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  }

  Widget wrap(Widget child) => ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('ar'),
          home: Directionality(textDirection: TextDirection.rtl, child: child),
        ),
      );

  Future<int> addEmployee(String name, {int? dept, String? status}) {
    return db.employeesDao.insertEmployee(EmployeesCompanion.insert(
      fullName: name,
      departmentId: Value(dept),
      status: Value(status ?? EmployeeStatus.active),
      basicSalary: const Value(600000),
    ));
  }

  testWidgets('⭐⭐ عناوين الأقسام تظهر والموظفون تحتها', (tester) async {
    final eng = await db.employeesDao.insertDepartment('مهندسون');
    await db.employeesDao.insertDepartment('فنيون');
    await addEmployee('مهندس واحد', dept: eng);
    await addEmployee('بلا قسم له');

    await tester.pumpWidget(wrap(const EmployeesScreen()));
    await settle(tester);

    expect(find.text('مهندسون'), findsOneWidget);
    expect(find.text('بلا قسم'), findsOneWidget);
    expect(find.text('مهندس واحد'), findsOneWidget);
    // قسمٌ بلا موظفين لا يُعرَض عنوانه — عنوانٌ فوق فراغ يُوهم بضياع أحد
    expect(find.text('فنيون'), findsNothing);

    await disposeTree(tester);
  });

  testWidgets('⭐⭐ شارة الحالة تظهر لغير «حالي» وحده', (tester) async {
    await addEmployee('عامل حالي');
    await addEmployee('عامل سابق', status: EmployeeStatus.terminated);
    await addEmployee('عامل مجاز', status: EmployeeStatus.leave);

    await tester.pumpWidget(wrap(const EmployeesScreen()));
    await settle(tester);

    // الشرائح تعرض التسميات الثلاث دائماً، والشارات تُضاف فوقها
    expect(find.text('منتهية خدمته'), findsNWidgets(2));
    expect(find.text('في إجازة'), findsNWidgets(2));
    // «حالي» شريحةٌ واحدة فقط — لا شارة على البطاقة
    expect(find.text('حالي'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('⭐⭐⭐ مقبض السحب موجود بلا فلاتر — وغيابه يُخفي الميزة كلها',
      (tester) async {
    final dept = await db.employeesDao.insertDepartment('سواق');
    await addEmployee('سائق أول', dept: dept);
    await addEmployee('سائق ثانٍ', dept: dept);

    await tester.pumpWidget(wrap(const EmployeesScreen()));
    await settle(tester);

    expect(find.byIcon(Icons.drag_indicator), findsNWidgets(2));

    // ومع فلترٍ فعّال يختفي المقبض **ويُقال السبب** — لا صمتٌ يبدو عطلاً.
    // والفلتر «حالي» يُبقي السائقَين معروضين، فيُختبَر السببُ المعروض لا
    // شاشةُ الفراغ.
    await tester.tap(find.text('حالي'));
    await settle(tester);

    expect(find.byIcon(Icons.drag_indicator), findsNothing);
    expect(find.textContaining('الترتيب اليدوي متاح بلا فلاتر'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('⭐ الشاشة تُبنى بلا استثناء ولا تجاوز عرض', (tester) async {
    final dept = await db.employeesDao.insertDepartment('مهندسون');
    for (var i = 1; i <= 5; i++) {
      await addEmployee('موظف رقم $i', dept: i.isEven ? dept : null);
    }

    await tester.pumpWidget(wrap(const EmployeesScreen()));
    await settle(tester);

    expect(tester.takeException(), isNull);
    await disposeTree(tester);
  });
}
