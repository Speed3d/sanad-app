// ─────────────────────────────────────────────────────────────────────────────
// payroll_posting_test.dart — تسديد كشف الرواتب: الحرّاس والذرّية
//
// **اللحظة الوحيدة التي تتأثر فيها الخزينة في نظام الرواتب.**
// ما يُتساهَل معه في المسودة يُرفض هنا — التسديد لا رجعة فيه (قرار المالك:
// التعديل بعد التسديد ممنوع، والتصحيح بالحذف وإعادة الإنشاء).
//
// **ما يحرسه هذا الملف:**
//   • **سند واحد بالمجموع** لا سند لكل موظف (قرار المالك 2026-08-24)
//   • الرصيد يُخصَم **مرّة واحدة** بالمبلغ الصحيح
//   • التسديد على **دفعات**: الكشف الشامل لا يصير مُسدَّداً إلا باكتماله
//   • خصم سلفة الموظف يُنشئ **قسط سداد حقيقياً** لا مجرّد رقم في الراتب
//   • لا صافي سالب · لا دولار بلا سعر صرف · لا فترة مُقفَلة · لا تسديد مزدوج
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/services/payroll_calculator.dart';
import 'package:sales_management/core/services/payroll_row_parser.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/payroll_repository.dart';

void main() {
  late AppDatabase db;
  late PayrollRepository repo;
  late int fiscalId;
  late int mainTreasury;
  late int ahmedId;
  late int saraId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PayrollRepository(db);

    fiscalId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2025',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31, 23, 59, 59),
      ),
    );
    mainTreasury = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );

    // تمويل الخزينة بسند قبض — وإلا رفض حارس الرصيد كل تسديد
    final n = await db.fiscalPeriodsDao.getNextVoucherNumber(
      fiscalPeriodId: fiscalId,
      voucherType: 'kabd',
    );
    await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: n,
        voucherType: 'kabd',
        treasuryId: mainTreasury,
        fiscalPeriodId: fiscalId,
        amount: 10000000,
        voucherDate: DateTime(2025, 1, 5),
      ),
    );

    ahmedId = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'أحمد علي',
        position: const Value('سائق'),
        basicSalary: const Value(600000),
        treasuryId: Value(mainTreasury),
      ),
    );
    saraId = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
        fullName: 'سارة حسن',
        position: const Value('محاسبة'),
        basicSalary: const Value(500000),
      ),
    );
  });

  tearDown(() async => db.close());

  // ── مساعدات ─────────────────────────────────────────────────────────────

  Future<int> makePeriod({
    int year = 2025,
    int month = 2,
    double? rate,
  }) {
    return repo.createOrGetPeriod(
      year: year,
      month: month,
      exchangeRate: rate,
    );
  }

  Future<int> addEntry({
    required int periodId,
    required int employeeId,
    required String name,
    double salary = 600000,
    String currency = PayrollCurrency.iqd,
    double? rate,
    double bonus = 0,
    double deduction = 0,
  }) async {
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
            currency: currency,
            exchangeRate: rate,
            bonus: bonus,
            deduction: deduction,
          ),
        ),
      ],
    );
    final entry = await db.payrollDao
        .getEntryForEmployee(periodId: periodId, employeeId: employeeId);
    return entry!.id;
  }

  Future<double> balanceOf(int treasuryId) async {
    final row = await db.treasuriesDao.getTreasuryBalance(treasuryId);
    return row?.balanceIqd ?? 0;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // إنشاء الكشف
  // ═══════════════════════════════════════════════════════════════════════

  group('إنشاء كشف الشهر', () {
    test('يُنشأ مسودة بأيام عمل ٣٠ وينتسب لسنته المالية', () async {
      final id = await makePeriod();
      final p = await db.payrollDao.getPeriodById(id);
      expect(p!.status, PayrollStatusDb.draft);
      expect(p.workingDays, 30);
      expect(p.fiscalPeriodId, fiscalId);
    });

    test('⭐ الاستيراد الثاني للشهر نفسه ينضمّ للكشف القائم', () async {
      final a = await makePeriod(month: 3);
      final b = await makePeriod(month: 3);
      expect(b, a, reason: 'ملف كربلاء ينضمّ لكشف البصرة لا يُنشئ ثانياً');
    });

    test('⭐ شهر بلا سنة مالية يُرفض برسالة تقول ما العمل', () async {
      // بلاغ المالك 2026-08-25: سنته المالية 2026 وحاول بناء كشف أيار 2025.
      // الحارس كان يعمل، والرسالة موجودة — لكنها لم تكن تصل إلى الشاشة.
      await expectLater(
        repo.createOrGetPeriod(year: 2030, month: 5),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          allOf(
            contains('لا توجد سنة مالية'),
            contains('أيار 2030'),
            contains('السنوات المالية'),
          ),
        )),
      );
    });

    test('⭐ السنة المُقفَلة تُنتج رسالة **مختلفة** تسمّيها', () async {
      // ⚠️ اختبار إثبات: `getFiscalPeriodForDate` تفلتر بـ`active`، فكانت
      //   السنة المُقفَلة تُعيد null فتُنتج رسالة «لا توجد سنة مالية» —
      //   وهي كذب يُرسل المالك لينشئ سنة موجودة أصلاً، فيصطدم بقاعدة عدم
      //   التقاطع ولا يفهم لماذا. الرسالتان يجب أن تختلفا.
      await db.fiscalPeriodsDao.closePeriod(fiscalId, 1);
      await expectLater(
        repo.createOrGetPeriod(year: 2025, month: 6),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          allOf(
            contains('مُقفَلة'),
            contains('2025'),
            isNot(contains('لا توجد سنة مالية')),
          ),
        )),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الاستيراد
  // ═══════════════════════════════════════════════════════════════════════

  group('الاستيراد', () {
    test('سطر جديد يُضاف بلقطته والصافي محسوب', () async {
      final pid = await makePeriod();
      await addEntry(
          periodId: pid, employeeId: ahmedId, name: 'أحمد علي', bonus: 50000);

      final entries = await repo.getEntries(pid);
      expect(entries, hasLength(1));
      final e = entries.first;
      expect(e.snapshotName, 'أحمد علي');
      expect(e.netAmount, 650000);
      expect(e.netAmountIqd, 650000);
      expect(e.paymentStatus, PayrollPaymentStatusDb.unpaid);
    });

    test('⭐ إعادة استيراد الموظف نفسه تُحدّث سطره ولا تُضاعفه', () async {
      final pid = await makePeriod();
      await addEntry(periodId: pid, employeeId: ahmedId, name: 'أحمد علي');
      await addEntry(
          periodId: pid, employeeId: ahmedId, name: 'أحمد علي', salary: 700000);

      final entries = await repo.getEntries(pid);
      expect(entries, hasLength(1), reason: 'لا سطران للموظف في شهر واحد');
      expect(entries.first.basicSalary, 700000);
    });

    test('⭐ موظف جديد يُنشأ فقط حين يطلب المستدعي ذلك صراحةً', () async {
      final pid = await makePeriod();
      final before = (await db.employeesDao.getAllEmployees()).length;

      final result = await repo.importRows(
        periodId: pid,
        rows: [
          ResolvedPayrollRow(
            employeeId: null, // ⇒ إنشاء بموافقة المالك
            treasuryId: mainTreasury,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'كريم جبار',
              position: 'حارس',
              basicSalary: 400000,
            ),
          ),
        ],
      );

      expect(result.employeesCreated, 1);
      final after = await db.employeesDao.getAllEmployees();
      expect(after.length, before + 1);
      final created = after.firstWhere((e) => e.fullName == 'كريم جبار');
      expect(created.position, 'حارس');
      expect(created.treasuryId, mainTreasury);
    });

    test('⭐ الفرق بين الصافي المحسوب والمذكور يُعرَض ولا يمنع', () async {
      final pid = await makePeriod();
      final result = await repo.importRows(
        periodId: pid,
        rows: [
          ResolvedPayrollRow(
            employeeId: ahmedId,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'أحمد علي',
              basicSalary: 600000,
              fileNetAmount: 650000, // الملف يقول ٦٥٠ والمحسوب ٦٠٠
            ),
          ),
        ],
      );
      expect(result.netMismatches, hasLength(1));
      expect(result.netMismatches.first, contains('أحمد علي'));
      expect(result.added, 1, reason: 'الفرق تنبيه لا رفض');
    });

    test('⭐⭐ الاستيراد إلى كشف مُسدَّد يُقبل ولا يمسّ سطراً مدفوعاً',
        () async {
      // 🔴 **كان مرفوضاً حتى 2026-08-26، والرفض كان يقفل الشهر.**
      //   بعد توحيد الصرف المباشر داخل الكشوف، صار صرفُ راتب **موظف واحد**
      //   يجعل كشف الشهر «مُسدَّداً» (لا سطر مستحقّ فيه) — فكان استيراد ملف
      //   الشهر بعده يُرفض، أي أن راتباً واحداً يقفل الشهر على بقية موظفيه.
      //
      //   والحماية الحقيقية بقيت: **السطر المدفوع لا يُمَسّ**، فالمال الذي
      //   خرج لا يُعاد حسابه من ملف. المحمي هو السطر لا حالة الكشف.
      final pid = await makePeriod();
      final eid = await addEntry(
          periodId: pid, employeeId: ahmedId, name: 'أحمد علي', salary: 600000);
      await repo.payEntries(
        periodId: pid,
        entryIds: [eid],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );
      final postedAt = (await db.payrollDao.getPeriodById(pid))!.postedAt;
      expect((await db.payrollDao.getPeriodById(pid))!.status,
          PayrollStatusDb.posted);

      // ملف الشهر يصل متأخراً: فيه أحمد بمبلغ مختلف، وسارة لم تكن فيه
      final result = await repo.importRows(
        periodId: pid,
        rows: [
          ResolvedPayrollRow(
            employeeId: ahmedId,
            row: const ParsedPayrollRow(
              rowNumber: 1,
              rowLabel: 'صف 1',
              employeeName: 'أحمد علي',
              basicSalary: 900000,
            ),
          ),
          ResolvedPayrollRow(
            employeeId: saraId,
            row: const ParsedPayrollRow(
              rowNumber: 2,
              rowLabel: 'صف 2',
              employeeName: 'سارة حسن',
              basicSalary: 500000,
            ),
          ),
        ],
      );

      expect(result.added, 1, reason: 'سارة وحدها تُضاف');
      expect(result.updated, 0, reason: 'أحمد مدفوع — لا يُحدَّث');

      final entries = await db.payrollDao.getEntries(pid);
      final ahmed = entries.firstWhere((e) => e.employeeId == ahmedId);
      expect(ahmed.netAmountIqd, 600000,
          reason: 'المال خرج بهذا الرقم — الملف لا يُعيد كتابته');
      expect(ahmed.paymentStatus, PayrollPaymentStatusDb.paid);

      // الحالة تتبع السطور: صار في الكشف سطر مستحقّ فليس مُسدَّداً
      final period = await db.payrollDao.getPeriodById(pid);
      expect(period!.status, PayrollStatusDb.draft);
      expect(period.postedAt, postedAt,
          reason: 'تاريخ الاعتماد الأول يبقى شاهداً — لا يُمحى');
    });

    test('كشفٌ كل سطوره مدفوعة يبقى مُسدَّداً بعد استيراد لا يضيف شيئاً',
        () async {
      final pid = await makePeriod();
      final eid = await addEntry(
          periodId: pid, employeeId: ahmedId, name: 'أحمد علي');
      await repo.payEntries(
        periodId: pid,
        entryIds: [eid],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );

      await repo.importRows(periodId: pid, rows: const []);

      expect((await db.payrollDao.getPeriodById(pid))!.status,
          PayrollStatusDb.posted,
          reason: 'لا سطر مستحقّ دخل — فلا سبب لتغيير الحالة');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الترتيب — بلاغ المالك 2026-08-25
  // ═══════════════════════════════════════════════════════════════════════

  group('ترتيب سطور الكشف', () {
    test('⭐ السطور تظهر بترتيب ملف الإكسل لا أبجدياً', () async {
      // المحاسب يرسل الملف بترتيبه، والمالك يراجع الكشف وورقةُ الملف
      // أمامه. الترتيب الأبجدي يبعثرهما فيتعذّر التطابق سطراً بسطر.
      final pid = await makePeriod(month: 6);

      // أسماء مرتّبة **عكس** الأبجدية عمداً
      final names = ['ياسر هاشم', 'مصطفى نور', 'أحمد علي'];
      final ids = <int>[];
      for (final n in names) {
        ids.add(await db.employeesDao.insertEmployee(
          EmployeesCompanion.insert(fullName: n),
        ));
      }

      await repo.importRows(
        periodId: pid,
        rows: [
          for (var i = 0; i < names.length; i++)
            ResolvedPayrollRow(
              employeeId: ids[i],
              row: ParsedPayrollRow(
                rowNumber: i + 1,
                rowLabel: 'صف ${i + 1}',
                employeeName: names[i],
                basicSalary: 500000,
              ),
            ),
        ],
      );

      final entries = await repo.getEntries(pid);
      expect(entries.map((e) => e.snapshotName).toList(), names,
          reason: 'ترتيب الملف لا الترتيب الأبجدي');
    });

    test('⭐ الاستيراد التراكمي يُلحق الملف الثاني بعد الأول', () async {
      final pid = await makePeriod(month: 7);

      Future<void> importOne(String name) async {
        final id = await db.employeesDao.insertEmployee(
          EmployeesCompanion.insert(fullName: name),
        );
        await repo.importRows(
          periodId: pid,
          rows: [
            ResolvedPayrollRow(
              employeeId: id,
              row: ParsedPayrollRow(
                rowNumber: 1,
                rowLabel: 'صف 1',
                employeeName: name,
                basicSalary: 400000,
              ),
            ),
          ],
        );
      }

      await importOne('زيد البصرة'); // ملف البصرة
      await importOne('أحمد كربلاء'); // ثم ملف كربلاء

      final entries = await repo.getEntries(pid);
      expect(
        entries.map((e) => e.snapshotName).toList(),
        ['زيد البصرة', 'أحمد كربلاء'],
        reason: 'كل ملف بترتيبه، والأول قبل الثاني',
      );
    });

    test('⭐ قائمة الموظفين بترتيب الإضافة لا أبجدياً', () async {
      final names = ['ياسر هاشم', 'مصطفى نور', 'بشار سعد'];
      for (final n in names) {
        await db.employeesDao.insertEmployee(
          EmployeesCompanion.insert(fullName: n),
        );
      }
      final all = await db.employeesDao.getAllEmployees();
      // أحمد وسارة من setUp أولاً ثم الثلاثة بترتيب إضافتهم
      expect(all.map((e) => e.fullName).toList(),
          ['أحمد علي', 'سارة حسن', ...names]);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 🔑 التسديد
  // ═══════════════════════════════════════════════════════════════════════

  group('التسديد', () {
    test('⭐ سند واحد بالمجموع لا سند لكل موظف', () async {
      final pid = await makePeriod();
      final a = await addEntry(
          periodId: pid, employeeId: ahmedId, name: 'أحمد علي');
      final s = await addEntry(
          periodId: pid,
          employeeId: saraId,
          name: 'سارة حسن',
          salary: 500000);

      final before = await db.vouchersDao.getAllVouchers();
      final result = await repo.payEntries(
        periodId: pid,
        entryIds: [a, s],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );

      final after = await db.vouchersDao.getAllVouchers();
      expect(after.length, before.length + 1,
          reason: 'سند واحد لموظفَين — قرار المالك 2026-08-24');
      expect(result.employeeCount, 2);
      expect(result.totalIqd, 1100000);

      final voucher = after.firstWhere((v) => v.id == result.voucherId);
      expect(voucher.amount, 1100000);
      expect(voucher.itemType, 'راتب');
      expect(voucher.reason, contains('شباط'));
    });

    test('⭐ الرصيد يُخصَم مرّة واحدة بالمبلغ الصحيح', () async {
      final pid = await makePeriod();
      final a = await addEntry(
          periodId: pid, employeeId: ahmedId, name: 'أحمد علي');

      final before = await balanceOf(mainTreasury);
      await repo.payEntries(
        periodId: pid,
        entryIds: [a],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );
      final after = await balanceOf(mainTreasury);

      expect(before - after, 600000);
    });

    test('⭐ الكشف لا يصير مُسدَّداً إلا باكتمال سطوره', () async {
      // الكشف شامل والتسديد على دفعات حسب مصدر التمويل
      final pid = await makePeriod();
      final a = await addEntry(
          periodId: pid, employeeId: ahmedId, name: 'أحمد علي');
      final s = await addEntry(
          periodId: pid,
          employeeId: saraId,
          name: 'سارة حسن',
          salary: 500000);

      final first = await repo.payEntries(
        periodId: pid,
        entryIds: [a],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );
      expect(first.periodCompleted, isFalse);
      expect((await db.payrollDao.getPeriodById(pid))!.status,
          PayrollStatusDb.draft);

      final second = await repo.payEntries(
        periodId: pid,
        entryIds: [s],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );
      expect(second.periodCompleted, isTrue);
      expect((await db.payrollDao.getPeriodById(pid))!.status,
          PayrollStatusDb.posted);
    });

    test('⭐ تسديد سطر مسدَّد يُرفض — لا صرف مزدوج', () async {
      final pid = await makePeriod();
      final a = await addEntry(
          periodId: pid, employeeId: ahmedId, name: 'أحمد علي');
      await repo.payEntries(
        periodId: pid,
        entryIds: [a],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );

      await expectLater(
        repo.payEntries(
          periodId: pid,
          entryIds: [a],
          treasuryId: mainTreasury,
          paymentDate: DateTime(2025, 3, 1),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('⭐ صافي سالب يمنع التسديد ويسمّي صاحبه', () async {
      final pid = await makePeriod();
      final a = await addEntry(
        periodId: pid,
        employeeId: ahmedId,
        name: 'أحمد علي',
        deduction: 900000, // أكبر من الراتب
      );

      await expectLater(
        repo.payEntries(
          periodId: pid,
          entryIds: [a],
          treasuryId: mainTreasury,
          paymentDate: DateTime(2025, 3, 1),
        ),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'الرسالة', contains('أحمد علي'))),
      );
    });

    test('⭐ رصيد غير كافٍ يمنع التسديد', () async {
      final empty = await db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(
            name: 'خزنة فارغة', kind: const Value('main')),
      );
      final pid = await makePeriod();
      final a = await addEntry(
          periodId: pid, employeeId: ahmedId, name: 'أحمد علي');

      await expectLater(
        repo.payEntries(
          periodId: pid,
          entryIds: [a],
          treasuryId: empty,
          paymentDate: DateTime(2025, 3, 1),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('⭐ فترة مالية مُقفَلة تمنع التسديد', () async {
      final pid = await makePeriod();
      final a = await addEntry(
          periodId: pid, employeeId: ahmedId, name: 'أحمد علي');
      await db.fiscalPeriodsDao.closePeriod(fiscalId, 1);

      await expectLater(
        repo.payEntries(
          periodId: pid,
          entryIds: [a],
          treasuryId: mainTreasury,
          paymentDate: DateTime(2025, 3, 1),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('⭐ دولار بلا سعر صرف للشهر يمنع التسديد', () async {
      final pid = await makePeriod(month: 4, rate: 1320);
      final a = await addEntry(
        periodId: pid,
        employeeId: ahmedId,
        name: 'أحمد علي',
        salary: 2000,
        currency: PayrollCurrency.usd,
        rate: 1320,
      );
      // نمحو سعر صرف الشهر بعد الاستيراد (محاكاة بيانات وصلت بمسار آخر)
      await db.payrollDao.updatePeriod(
        pid,
        const PayrollPeriodsCompanion(exchangeRate: Value(null)),
      );

      await expectLater(
        repo.payEntries(
          periodId: pid,
          entryIds: [a],
          treasuryId: mainTreasury,
          paymentDate: DateTime(2025, 5, 1),
        ),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'الرسالة', contains('سعر صرف'))),
      );
    });

    test('راتب بالدولار يُصرف بمقابله بالدينار', () async {
      final pid = await makePeriod(month: 4, rate: 1320);
      final a = await addEntry(
        periodId: pid,
        employeeId: ahmedId,
        name: 'أحمد علي',
        salary: 2000,
        currency: PayrollCurrency.usd,
        rate: 1320,
      );

      final before = await balanceOf(mainTreasury);
      final result = await repo.payEntries(
        periodId: pid,
        entryIds: [a],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 5, 1),
      );
      final after = await balanceOf(mainTreasury);

      expect(result.totalIqd, 2640000);
      expect(before - after, 2640000);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // خصم سلفة الموظف — إغلاق دورة كانت نصفها
  // ═══════════════════════════════════════════════════════════════════════

  group('خصم سلفة الموظف', () {
    Future<int> grantAdvance(double amount) async {
      return db.employeesDao.insertAdvance(
        CashAdvancesCompanion.insert(
          amount: amount,
          advanceDate: DateTime(2025, 1, 10),
          employeeId: Value(ahmedId),
        ),
      );
    }

    test('⭐ الخصم يُنشئ قسط سداد حقيقياً ويحدّث السلفة', () async {
      final advId = await grantAdvance(300000);
      final pid = await makePeriod();
      final eid = await addEntry(
          periodId: pid, employeeId: ahmedId, name: 'أحمد علي');

      await repo.updateEntry(
        entryId: eid,
        advanceRepayment: 100000,
        cashAdvanceId: advId,
      );

      final result = await repo.payEntries(
        periodId: pid,
        entryIds: [eid],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );

      expect(result.repaymentCount, 1);
      expect(result.totalIqd, 500000, reason: '٦٠٠ ألف ناقص ١٠٠ ألف خصماً');

      final repayments =
          await db.employeesDao.getRepaymentsByAdvance(advId);
      expect(repayments, hasLength(1));
      expect(repayments.first.amount, 100000);
      expect(repayments.first.method, 'salary_deduction',
          reason: 'قيمة كانت في الجدول بصفر استعمال — وُصلت أخيراً');
      // 🔄 **تغيّر العقد 2026-08-26 (المرحلة ٦):** كان العمود يُترك فارغاً
      //   لأن «لا سند قبض هنا — المال لم يتحرّك بل خرج راتبٌ أقل». وهو
      //   صحيح، لكنه ترك القسط **بلا أثرٍ يربطه بالراتب الذي وُلد منه**،
      //   فتعذّر عكسه عند إلغاء التسديد — فتبقى السلفة منقوصة بمبلغٍ لم
      //   يُدفَع. الآن يُملأ بسند **الصرف** الذي وقع الخصم ضمنه.
      expect(repayments.first.voucherId, isNotNull,
          reason: 'بلا ربطٍ بسنده لا سبيل لعكس القسط عند إلغاء التسديد');

      final advance = await db.employeesDao.getAdvanceById(advId);
      expect(advance!.totalRepaid, 100000);
      expect(advance.status, 'partial');
    });

    test('الخصم الذي يُكمل السلفة يجعلها مسدَّدة', () async {
      final advId = await grantAdvance(100000);
      final pid = await makePeriod();
      final eid = await addEntry(
          periodId: pid, employeeId: ahmedId, name: 'أحمد علي');

      await repo.updateEntry(
        entryId: eid,
        advanceRepayment: 100000,
        cashAdvanceId: advId,
      );
      await repo.payEntries(
        periodId: pid,
        entryIds: [eid],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );

      final advance = await db.employeesDao.getAdvanceById(advId);
      expect(advance!.status, 'paid');
    });

    test('⭐ خصم يتجاوز المتبقي يُرفض ولا يُصرف شيء', () async {
      final advId = await grantAdvance(100000);
      final pid = await makePeriod();
      final eid = await addEntry(
          periodId: pid, employeeId: ahmedId, name: 'أحمد علي');

      await repo.updateEntry(
        entryId: eid,
        advanceRepayment: 250000,
        cashAdvanceId: advId,
      );

      final before = await balanceOf(mainTreasury);
      await expectLater(
        repo.payEntries(
          periodId: pid,
          entryIds: [eid],
          treasuryId: mainTreasury,
          paymentDate: DateTime(2025, 3, 1),
        ),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'الرسالة', contains('يتجاوز المتبقي'))),
      );

      // ⭐ الذرّية: لا سند ولا خصم ولا تغيّر في الرصيد
      expect(await balanceOf(mainTreasury), before);
      final entry = await db.payrollDao.getEntryById(eid);
      expect(entry!.paymentStatus, PayrollPaymentStatusDb.unpaid);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // التعديل والحذف بعد التسديد
  // ═══════════════════════════════════════════════════════════════════════

  group('منع التعديل بعد التسديد', () {
    test('⭐ سطر مسدَّد لا يُعدَّل', () async {
      final pid = await makePeriod();
      final eid = await addEntry(
          periodId: pid, employeeId: ahmedId, name: 'أحمد علي');
      await repo.payEntries(
        periodId: pid,
        entryIds: [eid],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );

      await expectLater(
        repo.updateEntry(entryId: eid, bonus: 100000),
        throwsA(isA<StateError>()),
      );
    });

    test('⭐ كشف مسدَّد لا يُحذف — حذفه يمحو أثر رواتب صُرفت', () async {
      final pid = await makePeriod();
      final eid = await addEntry(
          periodId: pid, employeeId: ahmedId, name: 'أحمد علي');
      await repo.payEntries(
        periodId: pid,
        entryIds: [eid],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );

      await expectLater(
        repo.deletePeriod(pid),
        throwsA(isA<StateError>()),
      );
    });

    test('كشف مسودة يُحذف مع سطوره', () async {
      final pid = await makePeriod();
      await addEntry(periodId: pid, employeeId: ahmedId, name: 'أحمد علي');
      await repo.deletePeriod(pid);

      expect(await repo.getEntries(pid), isEmpty);
      final periods = await db.payrollDao.watchAllPeriods().first;
      expect(periods, isEmpty);
    });

    test('⭐ حذف الكشف يُحرّر الشهر لإعادة بنائه', () async {
      final pid = await makePeriod(month: 7);
      await repo.deletePeriod(pid);
      await expectLater(makePeriod(month: 7), completes);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الإجماليات — مصدر الحقيقة الوحيد
  // ═══════════════════════════════════════════════════════════════════════

  group('إجماليات الكشف', () {
    test('تُقرأ من مصدر واحد وتفصل المسدَّد عن المستحقّ', () async {
      final pid = await makePeriod();
      final a = await addEntry(
          periodId: pid, employeeId: ahmedId, name: 'أحمد علي');
      await addEntry(
          periodId: pid,
          employeeId: saraId,
          name: 'سارة حسن',
          salary: 500000);

      var totals = await repo.getTotals(pid);
      expect(totals.entryCount, 2);
      expect(totals.totalIqd, 1100000);
      expect(totals.unpaidIqd, 1100000);
      expect(totals.isFullyPaid, isFalse);

      await repo.payEntries(
        periodId: pid,
        entryIds: [a],
        treasuryId: mainTreasury,
        paymentDate: DateTime(2025, 3, 1),
      );

      totals = await repo.getTotals(pid);
      expect(totals.paidCount, 1);
      expect(totals.totalIqd, 1100000, reason: 'الإجمالي لا يتغيّر بالتسديد');
      expect(totals.unpaidIqd, 500000, reason: 'المتبقي وحده ينقص');
    });

    test('كشف فيه دولار يُعلَّم — ليُلزَم سعر صرف الشهر', () async {
      final pid = await makePeriod(month: 4, rate: 1320);
      await addEntry(
        periodId: pid,
        employeeId: ahmedId,
        name: 'أحمد علي',
        salary: 2000,
        currency: PayrollCurrency.usd,
        rate: 1320,
      );
      final totals = await repo.getTotals(pid);
      expect(totals.hasForeignCurrency, isTrue);
    });
  });
}
