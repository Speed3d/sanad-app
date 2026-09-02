// ─────────────────────────────────────────────────────────────────────────────
// factory_reset_test.dart — تصفير المصنع: محو التطبيق كلّه من الصفر
//
// الميزة التي يحرسها (طلب المالك 2026-08-30):
//   «تصفير كل شيء في البرنامج من اسم مستخدم وبيانات وخزنات وموظفين وصور وكل
//   شيء حتى يكون لدي تطبيق نظيف وجاهز من الصفر» — لأن مرحلة الاختبار تحتاج
//   نقطة بداية مضمونة، لا تصفيراً جزئياً يترك خزائن وموظفين من تجربة سابقة
//   يشوّشون نتيجة التجربة التالية.
//
// ما يحرسه هذا الملف تحديداً — وكلّه من دروس وقعت فعلاً:
//
//   ١. **الترتيب** (ع-٠٩): `employees` و`contractors` و`partners` أبناء
//      `treasuries` بمفاتيح خارجية، و`PRAGMA foreign_keys = ON` مُفعَّل.
//      حذف الخزائن قبلهم يرمي `FOREIGN KEY constraint failed`. الاختبار يزرع
//      الثلاثة **مرتبطين بخزينة** قبل التصفير — بلا ذلك يمرّ الترتيب الخاطئ.
//
//   ٢. **لا جدول منسيّ** (ع-٢٨ · ع-٣١ · ع-٣٣ · ع-٣٦ · ع-٣٨ · ع-٤٠):
//      عائلة الأعطال الأشيع في هذا المشروع هي «كل بابٍ يعرف جدولاً ويجهل
//      الباقي». فالاختبار لا يفحص جدولاً بعينه بل **يمرّ على العشرين كلها**
//      ويطالب بأن تكون فارغة — فأي جدول يُضاف مستقبلاً وينساه `factoryReset`
//      يُسقط هذا الاختبار فوراً.
//
//   ٣. **إعادة البذر**: قاعدة فارغة تماماً ليست «تطبيقاً نظيفاً» بل تطبيقاً
//      معطوباً — بلا عملة أساسية ولا أنواع بنود ولا علَم `first_run_complete`.
//
//   ٤. **الحُرّاس الثلاثة**: صلاحية · كلمة مرور · رمز محو. وحارسٌ لا يمرّ به
//      اختبار ليس حارساً (القانون ٤).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/auth/permissions.dart';
import 'package:sales_management/core/constants/app_settings_keys.dart';
import 'package:sales_management/core/services/auth_service.dart';
import 'package:sales_management/core/services/factory_reset_service.dart';
import 'package:sales_management/core/utils/audit_logger.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/domain/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AuthService auth;

  // bcrypt غالٍ عمداً (١٢ دورة) — نُنتج الـhash مرّة واحدة لكل الملف بدل
  // مرّة في كل setUp، وإلا صار الملف أبطأ من بقية الاختبارات مجتمعة.
  late String passwordHash;
  late String purgeCodeHash;

  const kPassword = 'owner-pass-2026';
  const kPurgeCode = 'burn-it-all';

  setUpAll(() async {
    auth = AuthService();
    passwordHash = await auth.hashPassword(kPassword);
    purgeCodeHash = await auth.hashPassword(kPurgeCode);
  });

  /// كل جداول القاعدة — **مقروءةً من القاعدة نفسها لا مكتوبةً بيد**
  ///
  /// 🔴 **كانت قائمة ثابتة بعشرين اسماً، فتقادمت بصمت** (كُشف 2026-09-01):
  ///   أُضيف جدول `departments` في Schema v8 ولم يُضَف إلى `factoryReset`،
  ///   فكان التصفير يمحو كادر الشركة كلّه ويُبقي الأقسام. والحارس الذي
  ///   وُضع ليمنع هذا **مرّ ناجحاً** لأنه لا يعرف بالجدول أصلاً.
  ///
  /// وهي عين العلّة التي أنتجت ع-٤٧ (ستّ شرائح فلترة من سبع عشرة) وعطل
  /// ب-١ (قوائم البنود الثابتة): **قائمةٌ تعكس مجموعةً في الكود تُشتقّ منها
  /// لا تُنسخ عنها**. و`db.allTables` مصدرها المولِّد نفسه، فلا تتخلّف أبداً.
  List<String> tablesOf(AppDatabase database) =>
      database.allTables.map((t) => t.actualTableName).toList();

  Future<int> countOf(String table) async {
    final row =
        await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
    return row.data['c'] as int? ?? 0;
  }

  late int userId;
  late int treasuryId;
  late int periodId;

  /// المستخدم الذي يضغط الزرّ — مدير نظام بالافتراض
  UserModel actor({String role = 'super_admin'}) => UserModel(
        id: userId,
        username: 'owner',
        fullName: 'المالك',
        role: role,
        createdAt: DateTime(2026, 1, 1),
      );

  AuditLogger audit() => AuditLogger(db.auditLogDao);

  /// يزرع صفّاً في **كل** جدول — الشرط المسبق لاختبار «لا جدول منسيّ»
  ///
  /// الترتيب هنا ترتيب إنشاء لا حذف: الأب قبل الابن.
  Future<void> seedEverything() async {
    // ── المستخدم والإعدادات ──────────────────────────────────────────
    userId = await db.usersDao.insertUser(
      UsersCompanion.insert(
        username: 'owner',
        passwordHash: passwordHash,
        fullName: 'المالك',
        role: const Value('super_admin'),
      ),
    );
    await db.appSettingsDao
        .setString(AppSettingsKeys.purgeCodeHash, purgeCodeHash);
    await db.appSettingsDao.setString(AppSettingsKeys.attachmentsRoot, '');
    // الشعار — «وصور» في طلب المالك
    await db.appSettingsDao
        .setBlob('company_logo', Uint8List.fromList([1, 2, 3, 4]), 'image/png');

    // ── الهيكل المالي ────────────────────────────────────────────────
    periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31, 23, 59, 59),
      ),
    );
    treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );

    // ⚠️ الثلاثة **مرتبطون بالخزينة** عمداً — هذا هو ما يجعل الترتيب الخاطئ
    //    يفشل. بلا الربط يمرّ حذف الخزائن قبلهم بلا شكوى.
    //
    // والموظف **مرتبط بقسم** كذلك (Schema v8): بلا الربط يمرّ حذف الأقسام
    // قبل الموظفين بلا شكوى، فلا يُختبَر الترتيب الذي يحرسه ع-٠٩.
    final departmentId = await db.employeesDao.insertDepartment('مهندسون');
    final seededEmployee = await db.into(db.employees).insert(
          EmployeesCompanion.insert(
            fullName: 'حسن محمد',
            treasuryId: Value(treasuryId),
            departmentId: Value(departmentId),
          ),
        );

    // إجازة (Schema v9) — **بعد** الموظف: `employee_leaves` ابنته، وزرعُها
    // قبله يرمي `FOREIGN KEY constraint failed`. وهو الترتيب نفسه الذي
    // يحرسه هذا الملف في الحذف، معكوساً.
    await db.employeesDao.insertLeave(
      EmployeeLeavesCompanion.insert(
        employeeId: seededEmployee,
        fromDate: DateTime(2026, 3, 1),
        toDate: DateTime(2026, 3, 5),
      ),
    );
    await db.into(db.contractors).insert(
          ContractorsCompanion.insert(
            name: 'مقاول البصرة',
            treasuryId: Value(treasuryId),
          ),
        );
    await db.into(db.partners).insert(
          PartnersCompanion.insert(
            name: 'شريك بغداد',
            treasuryId: Value(treasuryId),
          ),
        );

    // ── الحركة ───────────────────────────────────────────────────────
    final voucherNumber =
        await db.fiscalPeriodsDao.getNextVoucherNumber(
      fiscalPeriodId: periodId,
      voucherType: 'kabd',
    );
    final voucherId = await db.into(db.vouchers).insert(
          VouchersCompanion.insert(
            voucherNumber: voucherNumber,
            voucherType: 'kabd',
            treasuryId: treasuryId,
            fiscalPeriodId: periodId,
            amount: 1000000,
            voucherDate: DateTime(2026, 3, 1),
          ),
        );

    final employeeId = (await db.select(db.employees).getSingle()).id;
    final cashAdvanceId = await db.into(db.cashAdvances).insert(
          CashAdvancesCompanion.insert(
            employeeId: Value(employeeId),
            amount: 500000,
            advanceDate: DateTime(2026, 3, 2),
          ),
        );
    await db.into(db.cashAdvanceRepayments).insert(
          CashAdvanceRepaymentsCompanion.insert(
            cashAdvanceId: cashAdvanceId,
            amount: 250000,
            repaymentDate: DateTime(2026, 3, 20),
          ),
        );

    final payrollId = await db.into(db.payrollPeriods).insert(
          PayrollPeriodsCompanion.insert(
            year: 2026,
            month: 3,
            fiscalPeriodId: periodId,
          ),
        );
    await db.into(db.salaryPayments).insert(
          SalaryPaymentsCompanion.insert(
            employeeId: employeeId,
            periodLabel: const Value('2026-03'),
            basicSalary: const Value(800000),
            netAmount: const Value(800000),
            paymentDate: DateTime(2026, 3, 31),
            payrollPeriodId: Value(payrollId),
            treasuryId: Value(treasuryId),
          ),
        );

    final advanceId = await db.advancesDao.insertAdvance(
      AdvancesCompanion.insert(
        advanceNumber: '23',
        projectTreasuryId: treasuryId,
        fiscalPeriodId: periodId,
        advanceDate: DateTime(2026, 3, 1),
      ),
    );
    await db.advancesDao.insertLines([
      AdvanceLinesCompanion.insert(
        advanceId: advanceId,
        voucherDate: DateTime(2026, 3, 2),
        amount: 50000,
        originalAmount: 50000,
        originalDate: DateTime(2026, 3, 2),
      ),
    ]);

    // ── الملحقات ─────────────────────────────────────────────────────
    await db.into(db.attachments).insert(
          AttachmentsCompanion.insert(
            entityType: 'voucher',
            entityId: voucherId,
            fileName: 'فاتورة.pdf',
            relativePath: '2026/سند-1/فاتورة.pdf',
          ),
        );
    await db.into(db.exchangeRates).insert(
          ExchangeRatesCompanion.insert(
            fromCurrency: 'USD',
            toCurrency: 'IQD',
            rate: 1310,
            effectiveDate: DateTime(2026, 1, 1),
          ),
        );
    await db.auditLogDao.logSimpleAction(
      userId: userId,
      username: 'owner',
      table: AuditTables.system,
      action: AuditActions.login,
    );
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await seedEverything();
  });

  tearDown(() async => db.close());

  // ══════════════════════════════════════════════════════════════════════
  group('تصفير المصنع — المحو', () {
    test('⭐⭐⭐ لا جدول منسيّ — كل جداول القاعدة تُمحى أو تُعاد بذرها',
        () async {
      final allTables = tablesOf(db);

      // الشرط المسبق: كل جدول فيه صفّ فعلاً، وإلا لم يُثبت الاختبار شيئاً
      //
      // ⚠️ **وهو الشرط الذي يجعل الاشتقاق من القاعدة مفيداً**: جدولٌ جديد
      //   يظهر هنا تلقائياً، فيفشل الاختبار **قبل** أن يصل العطل للمالك —
      //   يقول أوّلاً «لم يُزرع» فيُضطرّ كاتبه إلى زرعه، ثم يقول «لم يُمحَ»
      //   إن نُسي في `factoryReset`.
      for (final t in allTables) {
        expect(await countOf(t), greaterThan(0),
            reason: 'الشرط المسبق: الجدول $t يجب أن يُزرع قبل التصفير');
      }

      await db.factoryReset();

      // الجداول التي يُعاد بذرها عمداً — وإلا بدأ التطبيق معطوباً
      const reseeded = {'app_settings', 'item_types'};

      for (final t in allTables) {
        final c = await countOf(t);
        if (reseeded.contains(t)) {
          expect(c, greaterThan(0),
              reason: '$t يجب أن يُعاد بذره لا أن يبقى فارغاً');
        } else {
          expect(c, 0, reason: 'الجدول $t لم يُمحَ — بابٌ نُسي');
        }
      }
    });

    test('⭐⭐ الترتيب لا يرمي قيداً أجنبياً — موظف ومقاول وشريك على خزينة',
        () async {
      // قبل الترتيب الصحيح كان هذا السطر يرمي:
      //   SqliteException(787): FOREIGN KEY constraint failed
      // لأن الثلاثة يشيرون إلى `treasuries.id` المحذوفة قبلهم — عطل ع-٠٩.
      await expectLater(db.factoryReset(), completes);

      expect(await countOf('treasuries'), 0);
      expect(await countOf('employees'), 0);
      expect(await countOf('contractors'), 0);
      expect(await countOf('partners'), 0);
    });

    test('⭐ الشعار يُمحى — «وصور» في طلب المالك', () async {
      expect(await db.appSettingsDao.getBlob('company_logo'), isNotNull,
          reason: 'الشرط المسبق: شعار مرفوع');

      await db.factoryReset();

      expect(await db.appSettingsDao.getBlob('company_logo'), isNull);
    });

    test('⭐ سجل التدقيق يُمحى — بخلاف التصفير العادي الذي يصونه', () async {
      await db.factoryReset();
      expect(await countOf('audit_log'), 0,
          reason: '«تطبيق نظيف بلا أي بيانات» يشمل السجل نفسه');
    });

    test('⭐ العدّادات تصف ما مُحي فعلاً', () async {
      final r = await db.factoryReset();

      expect(r.users, 1);
      expect(r.treasuries, 1);
      expect(r.employees, 1);
      expect(r.vouchers, 1);
      expect(r.periods, 1);
      expect(r.payrolls, 1);
      expect(r.advances, 1);
      expect(r.attachments, 1);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('تصفير المصنع — إعادة البذر', () {
    test('⭐⭐ العودة لشاشة الإعداد الأول: first_run_complete = false',
        () async {
      await db.appSettingsDao.setBool('first_run_complete', true);
      expect(await db.appSettingsDao.getBool('first_run_complete'), isTrue);

      await db.factoryReset();

      expect(await db.appSettingsDao.getBool('first_run_complete'), isFalse,
          reason: 'بدونه يبقى التطبيق على شاشة الدخول بلا مستخدم — طريق مسدود');
    });

    test('⭐ الإعدادات الافتراضية تعود — لا قاعدة فارغة معطوبة', () async {
      await db.factoryReset();

      expect(await db.appSettingsDao.getString('primary_currency'), 'IQD');
      expect(await db.appSettingsDao.getString('secondary_currency'), 'USD');
      expect(await db.appSettingsDao.getString('language'), 'ar');
      expect(await db.appSettingsDao.getString('company_name'), '');
    });

    test('⭐ أنواع البنود تعود — وإلا صارت شاشات السندات بلا بنود', () async {
      await db.factoryReset();

      final count = await countOf('item_types');
      expect(count, greaterThan(15),
          reason: 'البذور الاثنتان والعشرون تعود كاملة');
    });

    test('⭐ رمز المحو نفسه يُمحى — فلا يبقى سرّ من التجربة السابقة', () async {
      await db.factoryReset();

      final code =
          await db.appSettingsDao.getString(AppSettingsKeys.purgeCodeHash);
      expect(code, anyOf(isNull, isEmpty));
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('الحُرّاس الثلاثة — FactoryResetService', () {
    Future<FactoryResetReport> run({
      String password = kPassword,
      String purgeCode = kPurgeCode,
      String role = 'super_admin',
    }) =>
        FactoryResetService.run(
          db: db,
          auth: auth,
          user: actor(role: role),
          password: password,
          purgeCode: purgeCode,
          attachmentsRoot: '',
          audit: audit(),
        );

    test('⭐⭐ الطبقة ١ — غير مدير النظام يُرفض', () async {
      await expectLater(
        run(role: 'admin'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          contains('مدير النظام'),
        )),
      );
      // والأهم: لا شيء مُحي
      expect(await countOf('users'), 1);
      expect(await countOf('vouchers'), 1);
    });

    test('⭐⭐ الطبقة ٢ — كلمة مرور خاطئة تُرفض ولا تمحو شيئاً', () async {
      await expectLater(
        run(password: 'wrong'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          contains('كلمة المرور غير صحيحة'),
        )),
      );
      expect(await countOf('treasuries'), 1);
      expect(await countOf('employees'), 1);
    });

    test('⭐⭐ الطبقة ٣ — رمز محو خاطئ يُرفض ولو صحّت كلمة المرور', () async {
      await expectLater(
        run(purgeCode: 'wrong-code'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          contains('رمز المحو القسري غير صحيح'),
        )),
      );
      expect(await countOf('users'), 1);
    });

    test('⭐⭐ الرمز غير المُعيَّن يُعطّل العملية ويوجّه إلى مكان تعيينه',
        () async {
      await db.appSettingsDao.setString(AppSettingsKeys.purgeCodeHash, '');

      await expectLater(
        run(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'الرسالة',
          allOf(contains('لم يُعيَّن'), contains('الإعدادات')),
        )),
      );
      expect(await countOf('users'), 1);
    });

    test('⭐⭐ المدخلان الصحيحان معاً — ينفّذ ويُعيد الحصيلة', () async {
      final report = await run();

      expect(report.users, 1);
      expect(report.treasuries, 1);
      expect(report.attachments, 1);
      // الجذر فارغ ⇒ لا ملفات على القرص تُمَسّ
      expect(report.filesDeleted, 0);

      expect(await countOf('users'), 0);
      expect(await countOf('audit_log'), 0);
      expect(await db.appSettingsDao.getBool('first_run_complete'), isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('التمييز عن التصفير العادي', () {
    test('⭐⭐ resetFinancialData يُبقي الهيكل — والمصنع يمحوه', () async {
      // التصفير العادي: الحركة تذهب والهيكل يبقى
      await db.resetFinancialData();

      expect(await countOf('vouchers'), 0);
      expect(await countOf('users'), 1, reason: 'المستخدمون يبقون');
      expect(await countOf('treasuries'), 1, reason: 'الخزائن تبقى');
      expect(await countOf('employees'), 1, reason: 'الموظفون يبقون');
      expect(await countOf('audit_log'), greaterThan(0),
          reason: 'سجل التدقيق يبقى شاهداً على التصفير نفسه');

      // ثم تصفير المصنع يمحو ما بقي
      await db.factoryReset();

      expect(await countOf('users'), 0);
      expect(await countOf('treasuries'), 0);
      expect(await countOf('employees'), 0);
    });

    test('⭐ الصلاحيتان منفصلتان — سؤال «من يستطيع؟» يُجاب بصدق', () {
      UserModel u(String role) => UserModel(
            id: 1,
            username: 'u',
            fullName: 'u',
            role: role,
            createdAt: DateTime(2026, 1, 1),
          );

      expect(u('user').can(AppPermission.factoryReset), isFalse);
      expect(u('admin').can(AppPermission.factoryReset), isFalse,
          reason: 'حتى المدير العادي لا يمحو التطبيق');
      expect(u('super_admin').can(AppPermission.factoryReset), isTrue);
    });
  });
}
