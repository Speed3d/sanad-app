// ─────────────────────────────────────────────────────────────────────────────
// expense_reports_test.dart — تقريرا المصروفات والمستحقات (ب-٢)
//
// هذه الاختبارات تحرس **قرارات محاسبية** لا مجرّد كود. كل قرار منها لو انعكس
// لأنتج تقريراً يكذب على المالك برقم يبدو معقولاً — وهو أخطر من عُطل ظاهر:
//
//   ١. التحويلات ليست مصروفاً. `transfer_out` نقل مال بين خزائن الشركة نفسها،
//      واحتسابه يُضخّم الإنفاق مرّتين (عند التحويل وعند الصرف الفعلي).
//   ٢. البند الفارغ يظهر «غير محدد» ولا يُستبعَد — وإلا لما طابق مجموع
//      التقرير إجمالي صرف الفترة، فيفقد المالك الثقة في الرقم وهو محقّ.
//   ٣. الدولار يُحوَّل بسعر صرف **سنده** لا بسعر اليوم — فالتقرير التاريخي
//      لا يتغيّر كلما تحرّك السعر.
//   ٤. السند المحذوف ناعماً خارج التقرير تماماً.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/database/daos/vouchers_dao.dart';
import 'package:sales_management/data/repositories/voucher_repository.dart';

void main() {
  late AppDatabase db;
  late VoucherRepository repo;
  late int periodId;
  late int mainTreasury;
  late int projectTreasury;

  final from = DateTime(2026, 1, 1);
  final to = DateTime(2026, 12, 31, 23, 59, 59);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = VoucherRepository(db);
    periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: from,
        endDate: to,
      ),
    );
    mainTreasury = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );
    projectTreasury = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'البصرة', kind: const Value('main')),
    );
    // تمويل يسمح بالصرف
    await repo.createVoucher(
      fiscalPeriodId: periodId,
      voucherType: 'kabd',
      treasuryId: mainTreasury,
      amount: 100000000,
      currency: 'IQD',
      voucherDate: DateTime(2026, 1, 5),
    );
  });

  tearDown(() async => db.close());

  Future<int> sarf({
    required double amount,
    String item = '',
    String currency = 'IQD',
    double rate = 1.0,
    int? treasury,
    String? project,
    DateTime? date,
  }) {
    return repo.createVoucher(
      fiscalPeriodId: periodId,
      voucherType: 'sarf',
      treasuryId: treasury ?? mainTreasury,
      amount: amount,
      currency: currency,
      exchangeRate: rate,
      voucherDate: date ?? DateTime(2026, 3, 1),
      itemType: item,
      projectName: project,
    );
  }

  Future<List<ItemTypeExpenseRow>> report({
    int? treasuryId,
    String? project,
    DateTime? start,
    DateTime? end,
  }) {
    return db.vouchersDao.getExpensesByItemType(
      from: start ?? from,
      to: end ?? to,
      treasuryId: treasuryId,
      projectName: project,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // القرار ١ — التحويلات ليست مصروفاً
  // ═══════════════════════════════════════════════════════════════════════

  group('القرار المحاسبي: التحويلات ليست مصروفاً', () {
    test('⭐ التحويل بين الخزائن لا يظهر في تقرير المصروفات', () async {
      await sarf(amount: 500000, item: 'بانزين');

      // تحويل ٥ مليون إلى خزينة المشروع — مال انتقل لا مال صُرف
      await repo.createTransfer(
        fromTreasuryId: mainTreasury,
        toTreasuryId: projectTreasury,
        amount: 5000000,
        currency: 'IQD',
        fiscalPeriodId: periodId,
        voucherDate: DateTime(2026, 3, 2),
      );

      final rows = await report();
      final total = rows.fold<double>(0, (a, r) => a + r.totalEquivalentIqd);

      expect(total, 500000,
          reason: 'احتساب التحويل يُضخّم الإنفاق ٥ مليون من العدم');
      expect(rows, hasLength(1));
      expect(rows.first.itemType, 'بانزين');
    });

    test('سندات القبض لا تظهر في تقرير المصروفات', () async {
      await sarf(amount: 300000, item: 'نقل');
      await repo.createVoucher(
        fiscalPeriodId: periodId,
        voucherType: 'kabd',
        treasuryId: mainTreasury,
        amount: 9000000,
        currency: 'IQD',
        voucherDate: DateTime(2026, 3, 3),
        itemType: 'دفعة عميل',
      );

      final rows = await report();
      expect(rows.map((r) => r.itemType), ['نقل']);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // القرار ٢ — البند الفارغ يظهر ولا يُستبعَد
  // ═══════════════════════════════════════════════════════════════════════

  group('القرار المحاسبي: البند غير المحدد يظهر', () {
    test('⭐ مجموع التقرير يطابق إجمالي صرف الفترة تماماً', () async {
      await sarf(amount: 1000000, item: 'بانزين');
      await sarf(amount: 250000, item: 'نقل');
      await sarf(amount: 750000, item: ''); // بلا بند

      final rows = await report();
      final total = rows.fold<double>(0, (a, r) => a + r.totalEquivalentIqd);

      expect(total, 2000000,
          reason: 'استبعاد غير المحدد يجعل التقرير لا يطابق الدفاتر');
    });

    test('البند الفارغ يُعرَض «غير محدد» لا فراغاً', () async {
      await sarf(amount: 750000, item: '');
      final rows = await report();
      expect(rows.first.itemType, '');
      expect(rows.first.displayName, 'غير محدد');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // القرار ٣ — الدولار بسعر سنده
  // ═══════════════════════════════════════════════════════════════════════

  group('القرار المحاسبي: الدولار بسعر صرف سنده', () {
    test('⭐ كل سند يُحوَّل بسعره هو لا بسعر موحّد', () async {
      // سندان بالدولار بسعرين مختلفين — كما يحدث عبر السنة فعلاً
      await sarf(amount: 100, item: 'مشتريات', currency: 'USD', rate: 1300);
      await sarf(amount: 100, item: 'مشتريات', currency: 'USD', rate: 1500);

      final rows = await report();
      expect(rows, hasLength(1));
      // 100×1300 + 100×1500 = 280,000 — لا 100×2×(أي سعر موحّد)
      expect(rows.first.totalEquivalentIqd, 280000);
      expect(rows.first.totalUsd, 200);
      expect(rows.first.totalIqd, 0);
    });

    test('⭐ العملتان تبقيان منفصلتين ولا يختفي أن جزءاً كان بالدولار', () async {
      await sarf(amount: 500000, item: 'مشتريات');
      await sarf(amount: 100, item: 'مشتريات', currency: 'USD', rate: 1310);

      final rows = await report();
      final r = rows.first;
      expect(r.totalIqd, 500000);
      expect(r.totalUsd, 100);
      expect(r.totalEquivalentIqd, 500000 + 131000);
      expect(r.hasUsd, isTrue, reason: 'الواجهة تعرض تنبيه التحويل بناءً عليه');
    });

    test('بند بالدينار فقط لا يُعلَّم كمحتوٍ على دولار', () async {
      await sarf(amount: 500000, item: 'نقل');
      final rows = await report();
      expect(rows.first.hasUsd, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // القرار ٤ — المحذوف خارج التقرير
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ السند المحذوف ناعماً يخرج من التقرير فوراً', () async {
    final id = await sarf(amount: 900000, item: 'بانزين');
    await sarf(amount: 100000, item: 'بانزين');

    expect((await report()).first.totalEquivalentIqd, 1000000);

    await repo.deleteVoucher(id);

    final rows = await report();
    expect(rows.first.totalEquivalentIqd, 100000);
    expect(rows.first.voucherCount, 1);
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الترتيب والفلاتر
  // ═══════════════════════════════════════════════════════════════════════

  group('الترتيب والفلاتر', () {
    test('⭐ الترتيب تنازلي بالمعادل — أكبر بند إنفاقاً أولاً', () async {
      await sarf(amount: 100000, item: 'قرطاسية');
      await sarf(amount: 9000000, item: 'أجور عمال');
      await sarf(amount: 500000, item: 'بانزين');

      final rows = await report();
      expect(rows.map((r) => r.itemType).toList(),
          ['أجور عمال', 'بانزين', 'قرطاسية']);
    });

    test('الفلترة بالخزينة تعزل مصروفات مشروع واحد', () async {
      await sarf(amount: 700000, item: 'بانزين', treasury: mainTreasury);
      await repo.createVoucher(
        fiscalPeriodId: periodId,
        voucherType: 'kabd',
        treasuryId: projectTreasury,
        amount: 5000000,
        currency: 'IQD',
        voucherDate: DateTime(2026, 2, 1),
      );
      await sarf(amount: 200000, item: 'بانزين', treasury: projectTreasury);

      final rows = await report(treasuryId: projectTreasury);
      expect(rows.first.totalEquivalentIqd, 200000);
    });

    test('الفلترة بالمشروع تعمل على العمود لا على البحث النصّي', () async {
      await sarf(amount: 400000, item: 'نقل', project: 'مشروع البصرة');
      await sarf(amount: 600000, item: 'نقل', project: 'مشروع كربلاء');

      final rows = await report(project: 'مشروع البصرة');
      expect(rows, hasLength(1));
      expect(rows.first.totalEquivalentIqd, 400000);
    });

    test('نطاق التاريخ يشمل الطرفين', () async {
      await sarf(amount: 111, item: 'نقل', date: DateTime(2026, 5, 1));
      await sarf(amount: 222, item: 'نقل', date: DateTime(2026, 5, 31));
      await sarf(amount: 999, item: 'نقل', date: DateTime(2026, 6, 1));

      final rows = await report(
        start: DateTime(2026, 5, 1),
        end: DateTime(2026, 5, 31, 23, 59, 59),
      );
      expect(rows.first.totalEquivalentIqd, 333,
          reason: 'اليوم الأول والأخير داخل النطاق');
    });

    test('فترة بلا مصروفات تُعيد قائمة فارغة لا صفراً وهمياً', () async {
      final rows = await report(
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 31),
      );
      expect(rows, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // تقرير المستحقات
  // ═══════════════════════════════════════════════════════════════════════

  group('تقرير المستحقات — من تدين لهم الشركة', () {
    Future<int> advanceWithDeficit({
      required String number,
      required double deficit,
      required String coveredBy,
      String status = 'posted',
    }) async {
      final id = await db.advancesDao.insertAdvance(
        AdvancesCompanion.insert(
          advanceNumber: number,
          projectTreasuryId: projectTreasury,
          fiscalPeriodId: periodId,
          advanceDate: DateTime(2026, 3, 1),
        ),
      );
      await db.advancesDao.updateAdvance(
        AdvancesCompanion(
          id: Value(id),
          status: Value(status),
          deficitAmount: Value(deficit),
          deficitCoveredBy: Value(coveredBy),
        ),
      );
      return id;
    }

    test('⭐ يجمع ما غطّاه الشخص الواحد عبر عدة سلف', () async {
      await advanceWithDeficit(
          number: '23', deficit: 500000, coveredBy: 'أبو علي');
      await advanceWithDeficit(
          number: '24', deficit: 300000, coveredBy: 'أبو علي');
      await advanceWithDeficit(
          number: '25', deficit: 900000, coveredBy: 'أبو حسن');

      final rows = await db.advancesDao.getDeficitCreditors();
      expect(rows, hasLength(2));
      // مرتَّب تنازلياً — أكبر دَين أولاً
      expect(rows.first.coveredBy, 'أبو حسن');
      expect(rows.first.totalCovered, 900000);
      expect(rows[1].coveredBy, 'أبو علي');
      expect(rows[1].totalCovered, 800000);
      expect(rows[1].advanceCount, 2);
    });

    test('⭐ السلفة الملغاة لا تُنتج دَيناً — سنداتها عُكست', () async {
      await advanceWithDeficit(
        number: '30',
        deficit: 700000,
        coveredBy: 'أبو علي',
        status: 'cancelled',
      );
      final rows = await db.advancesDao.getDeficitCreditors();
      expect(rows, isEmpty);
    });

    test('المسودة لا تُنتج دَيناً — العجز يُثبَّت لحظة الاعتماد', () async {
      await advanceWithDeficit(
        number: '31',
        deficit: 400000,
        coveredBy: 'أبو علي',
        status: 'draft',
      );
      expect(await db.advancesDao.getDeficitCreditors(), isEmpty);
    });

    test('سلفة معتمدة بلا عجز لا تظهر', () async {
      await advanceWithDeficit(number: '32', deficit: 0, coveredBy: '');
      expect(await db.advancesDao.getDeficitCreditors(), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الخزائن بالعجز
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ الخزينة السالبة تظهر بعجزها الحقيقي', () async {
    // السماح بالرصيد المدين لمحاكاة اعتماد سلفة بعجز
    await db.appSettingsDao.setBool('enforce_balance_check', false);
    await repo.createVoucher(
      fiscalPeriodId: periodId,
      voucherType: 'kabd',
      treasuryId: projectTreasury,
      amount: 1000000,
      currency: 'IQD',
      voucherDate: DateTime(2026, 2, 1),
    );
    await sarf(amount: 1500000, item: 'أجور عمال', treasury: projectTreasury);

    final balances = await db.treasuriesDao.watchTreasuryBalances().first;
    final basra = balances.firstWhere((b) => b.treasuryId == projectTreasury);

    expect(basra.balanceIqd, -500000);
    final inDeficit = balances.where((b) => b.balanceIqd < 0).toList();
    expect(inDeficit, hasLength(1));
    expect(inDeficit.first.treasuryName, 'البصرة');
  });
}
