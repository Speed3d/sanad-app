// ─────────────────────────────────────────────────────────────────────────────
// batch_c_reports_test.dart — الدفعة ج من ملاحظات المالك (2026-08-30)
//
// أربعة بنود كلها في **التقارير والتصدير**، وثلاثة منها من صنف واحد:
// بياناتٌ موجودة في القاعدة لا يصل منها إلى المالك شيء.
//
//   ج-١ **الدولار في لوحة التحكم**: `getDailySummary` تُعيد الدولار منذ
//        المرحلة ١٦، و`DailyLiquidityPoint` كانت **تُسقطه في الطريق** —
//        فالمخطّط والكروت بالدينار حصراً. نمط ع-٠٦.
//
//   ج-٢ **البحث بالبند**: البنود في `advance_lines.item_type` والبطاقة
//        تعرضها مجمَّعة، والبحث على رقم السلفة واسم المشروع فقط.
//
//   ج-٣ **تصدير السلفة بتفاصيلها**: التصدير يُخرج المبلغ الكلي لكل سلفة،
//        فالورقة تقول «٨٬٤٠٠٬٠٠٠» ولا تقول على ماذا.
//
//   ج-٤ **كشف الرواتب Excel**: يُطبَع PDF ولا يُحفَظ Excel، والبنية جاهزة.
//
// ⚠️ **والقاعدة المحروسة هنا في ج-٤ تحديداً:** الصفر يُكتَب **صفراً** لا
//   «—». الشرطة أوضح على الورق، وفي Excel تجعل الخليّة نصّاً فينكسر جمع
//   العمود — وهو الغرض الوحيد من التصدير.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/services/excel_export_service.dart';
import 'package:sales_management/core/services/payroll_print_data.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/advance_repository.dart';
import 'package:sales_management/data/repositories/voucher_repository.dart';
import 'package:sales_management/domain/repositories/i_advance_repository.dart';
import 'package:sales_management/presentation/features/reports/report_table_builders.dart';
import 'package:sales_management/presentation/providers/database_provider.dart';
import 'package:sales_management/presentation/providers/voucher_providers.dart';

void main() {
  late AppDatabase db;
  late AdvanceRepository advances;
  late VoucherRepository vouchers;
  late int periodId;
  late int mainTreasury;
  late int projectTreasury;

  final from = DateTime(2026, 1, 1);
  final to = DateTime(2026, 12, 31, 23, 59, 59);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    advances = AdvanceRepository(db);
    vouchers = VoucherRepository(db);

    periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
          name: '2026', startDate: from, endDate: to),
    );
    mainTreasury = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );
    projectTreasury = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'البصرة', kind: const Value('main')),
    );
  });

  tearDown(() async => db.close());

  // ── مساعدات ──────────────────────────────────────────────────────────────

  /// سلفة بمسودة مصاريفها — كل سطر (البند، المبلغ)
  Future<int> seedAdvance(
    String number,
    List<(String item, double amount)> lines, {
    String project = 'مشروع البصرة',
  }) async {
    final id = await advances.createAdvance(
      advanceNumber: number,
      projectTreasuryId: projectTreasury,
      projectName: project,
      advanceDate: DateTime(2026, 3, 1),
    );
    await advances.createDraftFromExcel(
      advanceId: id,
      lines: [
        for (var i = 0; i < lines.length; i++)
          ParsedAdvanceLine(
            rowNumber: i + 1,
            date: DateTime(2026, 3, 10 + i),
            amount: lines[i].$2,
            itemType: lines[i].$1,
            reason: 'مصروف ${lines[i].$1}',
            personName: 'أبو علي',
            invoiceNumber: 'F${i + 1}',
          ),
      ],
      fileName: '$number.xlsx',
      fileHash: 'hash_$number',
    );
    return id;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ج-١ — الدولار لا يُسقَط في طريقه إلى لوحة التحكم
  // ═══════════════════════════════════════════════════════════════════════

  group('ج-١ · الدولار في بيانات لوحة التحكم', () {
    /// حاوية مزوّدات على قاعدة الاختبار — لا شاشة، فالمقصود مسار البيانات
    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('⭐⭐⭐ يومٌ بالدولار وحده لا يصل المخطَّط صفراً', () async {
      final today = DateTime.now();
      await vouchers.createVoucher(
        fiscalPeriodId: periodId,
        voucherType: 'kabd',
        treasuryId: mainTreasury,
        amount: 500,
        currency: 'USD',
        exchangeRate: 1310,
        voucherDate: DateTime(today.year, today.month, today.day, 10),
      );

      final points = await container().read(weeklyLiquidityProvider.future);
      final todayPoint = points.last;

      // 🔴 قبل الإصلاح: `DailyLiquidityPoint` بلا حقل دولار إطلاقاً،
      //   فالنقطة تصل بالدينار صفراً والمخطَّط يرسم خطّاً مسطّحاً.
      expect(todayPoint.kabdUsd, 500);
      expect(todayPoint.kabd, 0);
      expect(todayPoint.hasUsd, isTrue);
    });

    test('⭐⭐ يومٌ بالدينار وحده لا يُظهر مبدّل العملة', () async {
      final today = DateTime.now();
      await vouchers.createVoucher(
        fiscalPeriodId: periodId,
        voucherType: 'kabd',
        treasuryId: mainTreasury,
        amount: 2000000,
        currency: 'IQD',
        voucherDate: DateTime(today.year, today.month, today.day, 10),
      );

      final points = await container().read(weeklyLiquidityProvider.future);

      // `hasUsd` هو شرط ظهور المبدّل — ومبدّلٌ إلى عملة لا حركة فيها
      // يعرض ورقة فارغة ويُوهم بأن البيانات ناقصة
      expect(points.any((p) => p.hasUsd), isFalse);
      expect(points.last.kabd, 2000000);
    });

    test('⭐ سبع نقاط دائماً — والأخيرة هي اليوم', () async {
      final points = await container().read(weeklyLiquidityProvider.future);
      expect(points, hasLength(7));
      final now = DateTime.now();
      expect(points.last.date, DateTime(now.year, now.month, now.day));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ج-٢ — البحث بالبند داخل السلفة
  // ═══════════════════════════════════════════════════════════════════════

  group('ج-٢ · البحث بالبند', () {
    test('⭐⭐⭐ «وقود» تجد السلفة التي صُرف فيها وقود — بعدده ومجموعه',
        () async {
      final a = await seedAdvance('23', [
        ('وقود', 300000),
        ('كهربائيات', 500000),
        ('وقود', 200000),
      ]);
      await seedAdvance('24', [('مشتريات', 800000)]);

      final hits = await db.advancesDao.searchByItemType('وقود');

      // 🔴 قبل الإصلاح: البحث على رقم السلفة واسم المشروع فقط، فهذا
      //   السؤال بلا جواب إلا بفتح كل سلفة على حدة.
      expect(hits.keys, [a]);
      expect(hits[a]!.count, 2);
      expect(hits[a]!.total, 500000);
    });

    test('⭐⭐ المستبعَد لا يُعدّ — وإلا ناقضت الشارةُ البطاقةَ تحتها',
        () async {
      final a = await seedAdvance('25', [
        ('وقود', 300000),
        ('وقود', 200000),
      ]);
      final lines = await db.advancesDao.getLines(a);
      await advances.setLineExcluded(
        lineId: lines.last.id,
        excluded: true,
        reason: 'فاتورة مكرّرة',
      );

      final hits = await db.advancesDao.searchByItemType('وقود');
      expect(hits[a]!.count, 1);
      expect(hits[a]!.total, 300000);
    });

    test('⭐⭐ المطابقة جزئية وبلا حساسية لحالة الأحرف', () async {
      final a = await seedAdvance('26', [('Fuel وقود المولّدة', 100000)]);

      expect((await db.advancesDao.searchByItemType('وقود')).containsKey(a),
          isTrue);
      expect((await db.advancesDao.searchByItemType('fuel')).containsKey(a),
          isTrue);
      expect((await db.advancesDao.searchByItemType('FUEL')).containsKey(a),
          isTrue);
    });

    test('⭐ بحثٌ فارغ يُعيد خريطة فارغة لا كل السلف', () async {
      await seedAdvance('27', [('وقود', 100000)]);
      expect(await db.advancesDao.searchByItemType(''), isEmpty);
      expect(await db.advancesDao.searchByItemType('   '), isEmpty);
    });

    test('⭐ بندٌ لا وجود له يُعيد فراغاً', () async {
      await seedAdvance('28', [('وقود', 100000)]);
      expect(await db.advancesDao.searchByItemType('طيران'), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ج-٣ — تصدير السلف بتفاصيلها
  // ═══════════════════════════════════════════════════════════════════════

  group('ج-٣ · سطور السلف', () {
    test('⭐⭐ أسطر عدّة سلف باستعلام واحد — مرتّبة بالسلفة ثم بترتيب الملف',
        () async {
      final a = await seedAdvance('30', [('وقود', 100000), ('خبز', 50000)]);
      final b = await seedAdvance('31', [('مشتريات', 700000)]);

      final lines = await advances.getLinesForAdvances([a, b]);
      expect(lines, hasLength(3));
      expect(lines.map((l) => l.advanceId), [a, a, b]);
      expect(lines.first.rowNumber, 1);
    });

    test('⭐ قائمة فارغة لا تنفجر ولا تُعيد كل الأسطر', () async {
      await seedAdvance('32', [('وقود', 100000)]);
      expect(await advances.getLinesForAdvances([]), isEmpty);
    });

    test('⭐⭐⭐ جدول التفاصيل: سطرٌ لكل مصروف لا لكل سلفة', () async {
      final a = await seedAdvance('33', [
        ('وقود', 300000),
        ('كهربائيات', 500000),
      ]);
      final list = [
        (await advances.getAdvance(a))!,
      ];
      final lines = await advances.getLinesForAdvances([a]);

      final table = buildAdvanceLinesTable(
        statusLabel: 'الكل',
        query: '',
        itemQuery: '',
        advances: list,
        lines: lines,
      );

      // 🔴 قبل الإصلاح: `buildAdvancesListTable` تُخرج **صفّاً واحداً**
      //   بالمبلغ الكلي، فالورقة لا تقول على ماذا صُرف.
      expect(table.rows, hasLength(2));
      expect(table.rows[0][0], '33'); // رقم السلفة على كل سطر
      expect(table.rows[0][3], 'وقود'); // عمود البند
      expect(table.rows[1][3], 'كهربائيات');
      expect(table.landscape, isTrue);
    });

    test('⭐⭐⭐ المستبعَد يظهر ولا يدخل المجموع — إخفاؤه تزييفٌ بالحذف',
        () async {
      final a = await seedAdvance('34', [
        ('وقود', 300000),
        ('وقود', 200000),
      ]);
      final all = await db.advancesDao.getLines(a);
      await advances.setLineExcluded(
        lineId: all.last.id,
        excluded: true,
        reason: 'مكرّر',
      );

      final table = buildAdvanceLinesTable(
        statusLabel: 'الكل',
        query: '',
        itemQuery: '',
        advances: [(await advances.getAdvance(a))!],
        lines: await advances.getLinesForAdvances([a]),
      );

      expect(table.rows, hasLength(2)); // الاثنان معروضان
      expect(table.rows.last.last, 'مستبعَد'); // عمود الحالة يقول ذلك
      expect(
        table.summary.firstWhere((s) => s.label == 'المجموع المحتسَب').value,
        contains('300,000'), // لا 500,000
      );
      expect(table.summary.any((s) => s.label == 'مصاريف مستبعَدة'), isTrue);
    });

    test('⭐⭐ الورقة المفلترة بالبند تقول ذلك في ترويستها وذيلها', () async {
      final a = await seedAdvance('35', [('وقود', 300000)]);
      final table = buildAdvanceLinesTable(
        statusLabel: 'معتمدة',
        query: 'وقود',
        itemQuery: 'وقود',
        advances: [(await advances.getAdvance(a))!],
        lines: await advances.getLinesForAdvances([a]),
      );

      // ورقةٌ فيها الوقود وحده بلا ذكر الفلتر تبدو كشفاً كاملاً للسلفة
      expect(table.subtitle, contains('البند: «وقود»'));
      expect(table.footerNote, contains('ليست كشف السلفة كاملاً'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ج-٤ — كشف الرواتب إلى Excel
  // ═══════════════════════════════════════════════════════════════════════

  group('ج-٤ · كشف الرواتب Excel', () {
    PayrollSheetPrintRow row({
      int seq = 1,
      String name = 'أحمد علي',
      String currency = 'IQD',
      double basic = 600000,
      int absence = 0,
      double absenceDeduction = 0,
      double bonus = 0,
      double deduction = 0,
      double advance = 0,
      double net = 600000,
      double netIqd = 600000,
      bool paid = false,
    }) =>
        PayrollSheetPrintRow(
          seq: seq,
          name: name,
          position: 'سائق',
          currency: currency,
          basicSalary: basic,
          eligibleDays: 30,
          workingDays: 30,
          absenceDays: absence,
          absenceDeduction: absenceDeduction,
          bonus: bonus,
          deduction: deduction,
          advanceRepayment: advance,
          net: net,
          netIqd: netIqd,
          isPaid: paid,
        );

    PayrollSheetPrintData sheet(List<PayrollSheetPrintRow> rows,
            {double? rate, double fileTotal = 0}) =>
        PayrollSheetPrintData(
          periodLabel: 'آذار 2026',
          workingDays: 30,
          exchangeRate: rate,
          isPosted: false,
          employeeCount: rows.length,
          totalIqd: rows.fold<double>(0, (s, r) => s + r.netIqd),
          paidIqd: rows
              .where((r) => r.isPaid)
              .fold<double>(0, (s, r) => s + r.netIqd),
          unpaidIqd: rows
              .where((r) => !r.isPaid)
              .fold<double>(0, (s, r) => s + r.netIqd),
          fileTotal: fileTotal,
          rows: rows,
        );

    test('⭐⭐ صفٌّ لكل موظف بأعمدة ورقة الطباعة نفسها', () {
      final table = buildPayrollSheetTable(
          sheet([row(), row(seq: 2, name: 'سارة حسن')]));

      expect(table.columns, hasLength(14));
      expect(table.columns.first, '#');
      expect(table.rows, hasLength(2));
      expect(table.rows[1][1], 'سارة حسن');
      // عمود التوقيع لا يُصدَّر — خانةٌ تُوقَّع باليد لا معنى لها في ملف
      expect(table.columns, isNot(contains('التوقيع')));
    });

    test('⭐⭐⭐ الصفر يُكتَب صفراً لا «—» — وإلا انكسر جمع العمود', () {
      final table = buildPayrollSheetTable(sheet([row()]));

      // أعمدة: خصم الغياب ٧ · مكافأة ٨ · خصم ٩ · خصم سلفة ١٠
      for (final c in [7, 8, 9, 10]) {
        expect(table.rows.first[c], '0',
            reason: 'العمود $c كتب «${table.rows.first[c]}» بدل صفر');
      }
    });

    test('⭐⭐⭐ الأرقام تخرج أرقاماً في ملف Excel لا نصوصاً', () {
      final table = buildPayrollSheetTable(sheet([row(bonus: 50000)]));
      final book = Excel.decodeBytes(
          ExcelExportService.build(table, companyName: 'شركة سند'));
      final sheetObj = book.tables[book.getDefaultSheet()!]!;

      // نبحث عن خليّة الراتب الأساس في صفوف الجدول
      final numeric = <double>[];
      for (final r in sheetObj.rows) {
        for (final cell in r) {
          if (cell?.value is DoubleCellValue) {
            numeric.add((cell!.value as DoubleCellValue).value);
          } else if (cell?.value is IntCellValue) {
            numeric.add((cell!.value as IntCellValue).value.toDouble());
          }
        }
      }
      expect(numeric, contains(600000.0)); // الأساسي رقمٌ يُجمع
      expect(numeric, contains(50000.0)); // والمكافأة كذلك
      expect(numeric, contains(30.0)); // والأيام أرقام تُجمع وتُفرَز
    });

    test('⭐⭐ فرق مجموع الملف يُذكر في الملخّص والذيل معاً', () {
      final table =
          buildPayrollSheetTable(sheet([row()], fileTotal: 550000));

      expect(table.summary.any((s) => s.label == 'الفرق عن الملف'), isTrue);
      expect(table.footerNote, contains('يخالف مجموع ملف المحاسب'));
    });

    test('⭐⭐ الدولار: عمود «بالدينار» يُفسَّر بسعر الشهر المجمَّد', () {
      final table = buildPayrollSheetTable(sheet(
        [row(currency: 'USD', basic: 500, net: 500, netIqd: 655000)],
        rate: 1310,
      ));

      expect(table.subtitle, contains('سعر الصرف'));
      expect(table.footerNote, contains('سعر صرف الشهر المجمَّد'));
      expect(table.rows.first[3], '\$');
    });

    test('⭐ اسم ملف Excel يحمل الشهر فيُعرَف بعد شهور', () {
      final name =
          ExcelExportService.fileNameFor(buildPayrollSheetTable(sheet([row()])));
      expect(name, contains('آذار 2026'));
      expect(name, endsWith('.xlsx'));
    });
  });
}
