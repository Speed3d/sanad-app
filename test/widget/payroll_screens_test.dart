// ─────────────────────────────────────────────────────────────────────────────
// payroll_screens_test.dart — اختبار عرض شاشات الرواتب (Schema v7)
//
// **لماذا اختبار ودجت وقد نجحت اختبارات الوحدة كلها؟**
//   لأن أخطر أعطال هذا المشروع كانت **في العرض وحده** والأرقام المخزَّنة
//   صحيحة تماماً: التوقيت UTC · المؤشّر الذي لا يتوقّف · الشاشة الحمراء من
//   متحكّم ميت. ولم يكشفها اختبار وحدة واحد — كشفها المالك في أول دقيقة
//   استعمال (الدرس د-٣).
//
// **وما يمسكه هذا الملف تحديداً:**
//   • أي استثناء أثناء البناء (شاشة حمراء)
//   • **تجاوز عرض الجدول** — Flutter يرمي على `RenderFlex overflow` في
//     الاختبار، وهو العطل الذي حجب أسماء الموظفين في المشروع المرجعي DMS
//   • ظهور الأرقام الصحيحة فعلاً على الشاشة لا في القاعدة فقط
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/services/payroll_row_parser.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/payroll_repository.dart';
import 'package:sales_management/presentation/features/reports/employee_payroll_report_tab.dart';
import 'package:sales_management/presentation/features/payroll/payroll_periods_screen.dart';
import 'package:sales_management/presentation/features/payroll/payroll_sheet_screen.dart';
import 'package:sales_management/presentation/features/reports/payroll_report_tab.dart';
import 'package:sales_management/presentation/providers/database_provider.dart';

void main() {
  late AppDatabase db;
  late PayrollRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PayrollRepository(db);
  });

  tearDown(() async => db.close());

  /// ضخّ إطارات حتى تُحلَّ المزوّدات غير المتزامنة
  ///
  /// ⚠️ **لا `pumpAndSettle` هنا**: الشاشات تعرض `CircularProgressIndicator`
  ///   أثناء التحميل، وهو أنيميشن **لا ينتهي أبداً** — فتظلّ `pumpAndSettle`
  ///   تضخّ حتى مهلتها الداخلية (عشر دقائق) ثم ترمي، فيبدو الاختبار معلَّقاً
  ///   بلا سبب ظاهر. الضخّ الصريح ينتظر القدر الكافي ثم يمضي.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  /// تفكيك شجرة الودجتات **داخل** جسم الاختبار
  ///
  /// ⚠️ **بدونه يفشل كل اختبار برسالة «A Timer is still pending»**:
  ///   استعلامات Drift التفاعلية تجدول مؤقّتاً صفريّاً عند إلغاء اشتراكها
  ///   (`StreamQueryStore.markAsClosed`)، والإلغاء يقع حين يُفكَّك
  ///   `ProviderScope` — أي **بعد** انتهاء الاختبار، فيرصد الإطارُ مؤقّتاً
  ///   معلّقاً ويعتبره تسريباً.
  ///   نفكّ الشجرة بأنفسنا ثم نضخّ إطاراً، فتنطلق المؤقّتات وهي ما زالت
  ///   داخل نطاق الاختبار.
  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // ⚠️ **بمدّة لا بلا مدّة**: `pump()` بلا مدّة تجدول إطاراً ولا تُقدّم
    //   الساعة الوهمية، فالمؤقّت الصفريّ يبقى معلَّقاً. تقديم الساعة ولو
    //   بميلي ثانية واحدة يُطلقه.
    await tester.pump(const Duration(milliseconds: 50));
  }

  /// يغلّف الشاشة بما يلزمها: حقن قاعدة الاختبار + اتجاه RTL + ثيم التطبيق
  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        locale: const Locale('ar'),
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );
  }

  /// السنة الحالية — الشاشة تفتح عليها افتراضياً، فالزرع فيها لا في سنة
  /// ثابتة، وإلا بدت الشاشة فارغة والاختبار يفشل بلا علاقة بالكود.
  final year = DateTime.now().year;

  /// يبني سنة مالية وخزينة وموظفَين وكشف شباط بسطرين
  Future<int> seedSheet() async {
    await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '$year',
        startDate: DateTime(year, 1, 1),
        endDate: DateTime(year, 12, 31, 23, 59, 59),
      ),
    );
    final treasury = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );
    final ahmed = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'أحمد علي',
        position: const Value('سائق'),
        basicSalary: const Value(600000),
        treasuryId: Value(treasury),
      ),
    );
    final sara = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'سارة حسن',
        position: const Value('محاسبة'),
        basicSalary: const Value(500000),
      ),
    );

    final periodId = await repo.createOrGetPeriod(year: year, month: 2);
    await repo.importRows(
      periodId: periodId,
      rows: [
        ResolvedPayrollRow(
          employeeId: ahmed,
          row: const ParsedPayrollRow(
            rowNumber: 1,
            rowLabel: 'صف 1',
            employeeName: 'أحمد علي',
            position: 'سائق',
            basicSalary: 600000,
          ),
        ),
        ResolvedPayrollRow(
          employeeId: sara,
          row: const ParsedPayrollRow(
            rowNumber: 2,
            rowLabel: 'صف 2',
            employeeName: 'سارة حسن',
            position: 'محاسبة',
            basicSalary: 500000,
            bonus: 50000,
          ),
        ),
      ],
    );
    return periodId;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // شبكة الأشهر
  // ═══════════════════════════════════════════════════════════════════════

  group('شاشة أشهر الرواتب', () {
    testWidgets('⭐ تعرض الأشهر الاثني عشر كلها ولو لم يُنشأ أيّها',
        (tester) async {
      await tester.pumpWidget(wrap(const PayrollPeriodsScreen()));
      await settle(tester);

      // الشهر الفارغ معلومة لا فراغ: «لم يُستورَد بعد» هو ما يريد المالك رؤيته
      expect(find.text('كانون الثاني'), findsOneWidget);
      expect(find.text('شباط'), findsOneWidget);
      expect(find.text('كانون الأول'), findsOneWidget);
      expect(find.text('لم يُستورَد بعد'), findsNWidgets(12));

      await disposeTree(tester);
    });

    testWidgets('الشهر المُنشأ يعرض إجماليه وعدد موظفيه', (tester) async {
      await seedSheet();
      await tester.pumpWidget(wrap(const PayrollPeriodsScreen()));
      await settle(tester);

      expect(find.text('مسودة'), findsOneWidget);
      expect(find.text('1,150,000 د.ع'), findsOneWidget);
      expect(find.text('2 موظفاً'), findsOneWidget);
      expect(find.text('لم يُستورَد بعد'), findsNWidgets(11));

      await disposeTree(tester);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // كشف الشهر
  // ═══════════════════════════════════════════════════════════════════════

  group('شاشة كشف الشهر', () {
    testWidgets('⭐ الجدول يُبنى بلا تجاوز عرض ويعرض السطور', (tester) async {
      // شاشة عريضة كشاشة سطح مكتب حقيقية
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final id = await seedSheet();
      await tester.pumpWidget(wrap(PayrollSheetScreen(periodId: id)));
      await settle(tester);

      // ⚠️ لو تجاوز عرض الجدول مجموع أعمدته لرمى Flutter هنا — وهو العطل
      //   الذي حجب أسماء الموظفين في المشروع المرجعي
      expect(tester.takeException(), isNull);

      expect(find.text('رواتب شباط $year'), findsOneWidget);
      expect(find.text('أحمد علي'), findsOneWidget);
      expect(find.text('سارة حسن'), findsOneWidget);
      expect(find.text('سائق'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('⭐ الإجماليات تظهر على الشاشة لا في القاعدة فقط',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final id = await seedSheet();
      await tester.pumpWidget(wrap(PayrollSheetScreen(periodId: id)));
      await settle(tester);

      expect(find.text('إجمالي الكشف'), findsOneWidget);
      expect(find.text('المستحقّ للصرف'), findsOneWidget);
      // ٦٠٠٬٠٠٠ + ٥٥٠٬٠٠٠ = ١٬١٥٠٬٠٠٠
      expect(find.text('1,150,000 د.ع'), findsNWidgets(2));
      expect(find.text('2'), findsWidgets);

      await disposeTree(tester);
    });

    testWidgets('⭐⭐ كشف بأربعين موظفاً يُمرَّر عمودياً بلا تجاوز',
        (tester) async {
      // 🔴 بلاغ المالك 2026-08-25: «عند فتح المسودة لا أستطيع النزول —
      //   Bottom Overflowed by 1839 pixels». كشفٌ فيه ٤٧ موظفاً يحتاج
      //   ٢٬٢٠٩ بكسل والمتاح ٤١٥.
      //
      // ⚠️ **ولماذا لم تمسكه الاختبارات السابقة؟** لأنها تزرع **موظفَين**
      //   فلا تتجاوز الارتفاع أبداً. فحصُ العرض وحده ترك الاتجاه الآخر
      //   مكشوفاً — **وحجم البيانات في الاختبار جزءٌ من الاختبار**.
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await db.fiscalPeriodsDao.insertPeriod(
        FiscalPeriodsCompanion.insert(
          name: '$year',
          startDate: DateTime(year, 1, 1),
          endDate: DateTime(year, 12, 31, 23, 59, 59),
        ),
      );
      final id = await repo.createOrGetPeriod(year: year, month: 5);

      final rows = <ResolvedPayrollRow>[];
      for (var i = 1; i <= 40; i++) {
        final empId = await db.employeesDao.insertEmployee(
          EmployeesCompanion.insert(fullName: 'موظف رقم $i'),
        );
        rows.add(ResolvedPayrollRow(
          employeeId: empId,
          row: ParsedPayrollRow(
            rowNumber: i,
            rowLabel: 'صف $i',
            employeeName: 'موظف رقم $i',
            basicSalary: 500000,
          ),
        ));
      }
      await repo.importRows(periodId: id, rows: rows);

      await tester.pumpWidget(wrap(PayrollSheetScreen(periodId: id)));
      await settle(tester);

      // لا تجاوز في أي اتجاه
      expect(tester.takeException(), isNull);

      // الأوّل ظاهر، والأخير خارج الشاشة لكنه موجود في الشجرة القابلة للتمرير
      expect(find.text('موظف رقم 1'), findsOneWidget);
      expect(find.byType(ListView), findsWidgets,
          reason: 'السطور في قائمة قابلة للتمرير لا في عمود ثابت');

      // التمرير للأسفل يُظهر آخر الموظفين
      await tester.drag(
          find.byType(ListView).first, const Offset(0, -1500));
      await settle(tester);
      expect(tester.takeException(), isNull);

      await disposeTree(tester);
    });

    testWidgets('⭐ كل سطر يحمل أيقونة إيصاله والترويسة زرّ طباعة الكشف',
        (tester) async {
      // المرحلة ٤: الإيصال متاح للمسدَّد وغير المسدَّد معاً. وعمود «الحالة»
      // وُسِّع لأجل الأيقونة — واختبار التجاوز أعلاه هو ما يحرس أن التوسيع
      // كافٍ، تماماً كما أمسك نصف البكسل يوم أُضيفت أيقونة القلم.
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final id = await seedSheet();
      await tester.pumpWidget(wrap(PayrollSheetScreen(periodId: id)));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('طباعة الكشف'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsNWidgets(2),
          reason: 'أيقونة إيصال لكل سطر من سطرَي الكشف');

      await disposeTree(tester);
    });

    testWidgets('كشف بلا سطور يعرض حالة فارغة تشرح الخطوة التالية',
        (tester) async {
      await db.fiscalPeriodsDao.insertPeriod(
        FiscalPeriodsCompanion.insert(
          name: '$year',
          startDate: DateTime(year, 1, 1),
          endDate: DateTime(year, 12, 31, 23, 59, 59),
        ),
      );
      final id = await repo.createOrGetPeriod(year: year, month: 4);

      await tester.pumpWidget(wrap(PayrollSheetScreen(periodId: id)));
      await settle(tester);

      expect(find.text('الكشف فارغ'), findsOneWidget);
      expect(find.textContaining('استورد ملف رواتب'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('كشف غير موجود لا يُسقط الشاشة', (tester) async {
      await tester.pumpWidget(wrap(const PayrollSheetScreen(periodId: 999)));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('كشف الرواتب غير موجود'), findsOneWidget);

      await disposeTree(tester);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // تبويب تقرير الرواتب (المرحلة ٤)
  // ═══════════════════════════════════════════════════════════════════════

  group('تبويب تقرير الرواتب', () {
    /// سنة مالية + خزينتان ممولتان + كشوف [months] شهراً بموظفَين لكلٍّ
    Future<void> seedYear({required int months}) async {
      final fiscalId = await db.fiscalPeriodsDao.insertPeriod(
        FiscalPeriodsCompanion.insert(
          name: '$year',
          startDate: DateTime(year, 1, 1),
          endDate: DateTime(year, 12, 31, 23, 59, 59),
        ),
      );
      final main = await db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
      );
      final basra = await db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(
            name: 'خزنة البصرة', kind: const Value('project')),
      );
      for (final t in [main, basra]) {
        final n = await db.fiscalPeriodsDao.getNextVoucherNumber(
          fiscalPeriodId: fiscalId,
          voucherType: 'kabd',
        );
        await db.vouchersDao.insertVoucher(
          VouchersCompanion.insert(
            voucherNumber: n,
            voucherType: 'kabd',
            treasuryId: t,
            fiscalPeriodId: fiscalId,
            amount: 500000000,
            voucherDate: DateTime(year, 1, 2),
          ),
        );
      }

      final emp1 = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
            fullName: 'أحمد علي', treasuryId: Value(main)),
      );
      final emp2 = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
            fullName: 'سارة حسن', treasuryId: Value(basra)),
      );

      for (var m = 1; m <= months; m++) {
        final pid = await repo.createOrGetPeriod(year: year, month: m);
        await repo.importRows(
          periodId: pid,
          rows: [
            ResolvedPayrollRow(
              employeeId: emp1,
              row: ParsedPayrollRow(
                rowNumber: 1,
                rowLabel: 'صف 1',
                employeeName: 'أحمد علي',
                basicSalary: 600000,
              ),
            ),
            ResolvedPayrollRow(
              employeeId: emp2,
              row: ParsedPayrollRow(
                rowNumber: 2,
                rowLabel: 'صف 2',
                employeeName: 'سارة حسن',
                basicSalary: 500000,
              ),
            ),
          ],
        );

        // الشهر الأول يُسدَّد من خزينتين مختلفتين ليظهر التوزيع
        if (m == 1) {
          final entries = await db.payrollDao.getEntries(pid);
          await repo.payEntries(
            periodId: pid,
            entryIds: [entries.first.id],
            treasuryId: main,
            paymentDate: DateTime(year, 2, 1),
          );
          await repo.payEntries(
            periodId: pid,
            entryIds: [entries.last.id],
            treasuryId: basra,
            paymentDate: DateTime(year, 2, 2),
          );
        }
      }
    }

    testWidgets('لا كشوف ⇒ رسالة تشرح الخطوة التالية بدل شاشة فارغة',
        (tester) async {
      await tester.pumpWidget(wrap(const PayrollReportTab()));
      await settle(tester);

      expect(find.textContaining('لا توجد كشوف رواتب بعد'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeTree(tester);
    });

    testWidgets('⭐ يعرض أشهر السنة وإجماليها وتوزيع الخزائن',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await seedYear(months: 2);
      await tester.pumpWidget(wrap(const PayrollReportTab()));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('كانون الثاني'), findsOneWidget);
      expect(find.text('شباط'), findsOneWidget);
      // شهران × (٦٠٠٬٠٠٠ + ٥٠٠٬٠٠٠) = ٢٬٢٠٠٬٠٠٠
      expect(find.text('2,200,000 د.ع'), findsOneWidget);
      // الشهر الأول سُدِّد من خزينتين
      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text('خزنة البصرة'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('⭐⭐ سنة كاملة باثني عشر شهراً تُعرض وتُمرَّر بلا تجاوز',
        (tester) async {
      // **حجم البيانات في الاختبار جزءٌ من الاختبار** (ع-٢٧): تبويبٌ
      // يُختبَر بشهرٍ واحد لا يمرّ بمسار التمرير إطلاقاً، والمالك يفتحه
      // على سنة كاملة.
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await seedYear(months: 12);
      await tester.pumpWidget(wrap(const PayrollReportTab()));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(ListView), findsWidgets,
          reason: 'المحتوى في قائمة قابلة للتمرير لا في عمود ثابت');

      // النزول يُظهر آخر الأشهر وتوزيع الخزائن أسفله
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await settle(tester);
      expect(tester.takeException(), isNull);

      await disposeTree(tester);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // تبويب تقرير الموظف (طلب المالك 2026-08-26)
  // ═══════════════════════════════════════════════════════════════════════

  group('تبويب تقرير الموظف', () {
    /// موظف واحد بـ[months] شهراً في السنة الجارية، مسدَّدة كلها
    Future<void> seedEmployee({required int months}) async {
      final fiscalId = await db.fiscalPeriodsDao.insertPeriod(
        FiscalPeriodsCompanion.insert(
          name: '$year',
          startDate: DateTime(year, 1, 1),
          endDate: DateTime(year, 12, 31, 23, 59, 59),
        ),
      );
      final main = await db.treasuriesDao.insertTreasury(
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
          treasuryId: main,
          fiscalPeriodId: fiscalId,
          amount: 500000000,
          voucherDate: DateTime(year, 1, 2),
        ),
      );

      final emp = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
          fullName: 'أحمد علي',
          position: const Value('سائق'),
          treasuryId: Value(main),
        ),
      );

      for (var m = 1; m <= months; m++) {
        final pid = await repo.createOrGetPeriod(year: year, month: m);
        await repo.importRows(
          periodId: pid,
          rows: [
            ResolvedPayrollRow(
              employeeId: emp,
              row: const ParsedPayrollRow(
                rowNumber: 1,
                rowLabel: 'صف 1',
                employeeName: 'أحمد علي',
                basicSalary: 600000,
                bonus: 50000,
              ),
            ),
          ],
        );
        final entries = await db.payrollDao.getEntries(pid);
        await repo.payEntries(
          periodId: pid,
          entryIds: [entries.single.id],
          treasuryId: main,
          paymentDate: DateTime(year, m, 28),
        );
      }
    }

    testWidgets('بلا رواتب ⇒ رسالة تشرح بدل شاشة فارغة', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const EmployeePayrollReportTab()));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('لا رواتب في'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('⭐ وضع المجموعة يعرض الموظفين بمجاميعهم', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // الافتراضي: من كانون الثاني إلى الشهر السابق
      await seedEmployee(months: 2);
      await tester.pumpWidget(wrap(const EmployeePayrollReportTab()));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('أحمد علي'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('⭐⭐ تفصيل سنة كاملة يُعرض ويُمرَّر بلا تجاوز', (tester) async {
      // **حجم البيانات جزءٌ من الاختبار** (ع-٢٧): تفصيلٌ بشهر واحد لا يمرّ
      // بمسار التمرير، والمالك يفتحه على سنة كاملة بأربعة عشر عموداً.
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await seedEmployee(months: 11);
      await tester.pumpWidget(wrap(const EmployeePayrollReportTab()));
      await settle(tester);

      expect(tester.takeException(), isNull,
          reason: 'تجاوزٌ عمودي أو أفقي يرمي هنا قبل أن يصل إلى المالك');

      await disposeTree(tester);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // التصحيح بعد التسديد (المرحلة ٦ — بلاغ المالك 2026-08-26)
  // ═══════════════════════════════════════════════════════════════════════

  group('شاشة الكشف — الفرق وإجراءات السطر المسدَّد', () {
    /// سيناريو المالك حرفياً: راتب ١٬٧٥٠٬٠٠٠ صُرف كاملاً (٣٠ يوماً)، والملف
    /// يحسب ٢٦ يوماً — فرقُ ٢٣٣٬٣٣٣
    Future<int> seedOverpaidMonth() async {
      final fiscalId = await db.fiscalPeriodsDao.insertPeriod(
        FiscalPeriodsCompanion.insert(
          name: '$year',
          startDate: DateTime(year, 1, 1),
          endDate: DateTime(year, 12, 31, 23, 59, 59),
        ),
      );
      final t = await db.treasuriesDao.insertTreasury(
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
          treasuryId: t,
          fiscalPeriodId: fiscalId,
          amount: 50000000,
          voucherDate: DateTime(year, 1, 2),
        ),
      );
      final emp = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
          fullName: 'حسن محمد',
          basicSalary: const Value(1750000),
          treasuryId: Value(t),
        ),
      );

      // صُرف كاملاً مباشرةً من بطاقة الموظف
      final paid = await repo.paySingleEmployee(
        employeeId: emp,
        year: year,
        month: 5,
        treasuryId: t,
        basicSalary: 1750000,
        paymentDate: DateTime(year, 6, 1),
      );

      // ثم وصل ملف الشهر: أربعة أيام غياب · ومجموعه ما يحسبه لهذا الموظف
      await repo.importRows(
        periodId: paid.periodId,
        rows: [
          ResolvedPayrollRow(
            employeeId: emp,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'حسن محمد',
              basicSalary: 1750000,
              absenceDays: 4,
            ),
          ),
        ],
      );
      await db.payrollDao.updatePeriod(
        paid.periodId,
        const PayrollPeriodsCompanion(fileTotal: Value(1516667)),
      );
      return paid.periodId;
    }

    testWidgets('⭐⭐ لافتة الفرق تقول **سببه باسم صاحبه** لا رقماً يتيماً',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final periodId = await seedOverpaidMonth();
      await tester.pumpWidget(wrap(PayrollSheetScreen(periodId: periodId)));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('حسن محمد: صُرف'),
        findsOneWidget,
        reason: 'رقمٌ بلا سببه يُدرّب العين على تخطّي ما حوله — '
            'والبرنامج يعرف السبب: صُرف ٣٠ يوماً والملف يحسب ٢٦',
      );
      expect(find.textContaining('زيادة'), findsWidgets);

      await disposeTree(tester);
    });

    testWidgets('⭐ الضغط على سطر مسدَّد يفتح التصحيح وإلغاء التسديد',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final periodId = await seedOverpaidMonth();
      await tester.pumpWidget(wrap(PayrollSheetScreen(periodId: periodId)));
      await settle(tester);

      await tester.tap(find.text('حسن محمد').first);
      await settle(tester);

      expect(tester.takeException(), isNull);
      // بلا مستخدم مصادَق تظهر رسالة الصلاحية — وهي **الحارس نفسه** الذي
      // يمنع العملية لا مجرّد إخفاء زرّ
      expect(
        find.textContaining('للمدير وحده'),
        findsOneWidget,
        reason: 'تصحيح مبلغٍ خرج من الخزينة بخطورة الصرف نفسه',
      );

      await disposeTree(tester);
    });
  });
}
