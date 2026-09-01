// ─────────────────────────────────────────────────────────────────────────────
// app_database.dart — قاعدة البيانات الرئيسية (Drift)
//
// هذا الملف هو نقطة الدخول الوحيدة لقاعدة البيانات.
// يُعرّف جميع الجداول، الـ DAOs، والـ Migrations.
//
// طريقة توليد الكود:
//   dart run build_runner build --delete-conflicting-outputs
//
// الملفات المُولَّدة:
//   app_database.g.dart — لا تعدّل هذا الملف يدوياً
//
// الـ Schema Version:
//   عند أي تغيير في الجداول:
//     1. زد schemaVersion بمقدار 1
//     2. أضف MigrationStep في دالة migration
//     3. لا تحذف الـ Steps القديمة (مطلوبة للترقية التدريجي)
//
// الـ VIEW (v_treasury_balances):
//   يُنشَأ عبر customStatement في onCreate
//   ويُعاد بناؤه في كل migration يتأثر بجداول الخزائن أو السندات
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/users_table.dart';
import 'tables/app_settings_table.dart';
import 'tables/fiscal_periods_table.dart';
import 'tables/treasuries_table.dart';
import 'tables/vouchers_table.dart';
import 'tables/employees_table.dart';
import 'tables/contractors_table.dart';
import 'tables/partners_table.dart';
import 'tables/audit_log_table.dart';
import 'tables/exchange_rates_table.dart';
import 'tables/advances_table.dart';
import 'tables/advance_lines_table.dart';
import 'tables/item_types_table.dart';
import 'tables/attachments_table.dart';
import 'tables/payroll_periods_table.dart';
import 'tables/departments_table.dart';
// ⚠️ **مستورَدة هنا صراحةً وإن لم يستعملها هذا الملف**: `app_database.g.dart`
//   جزءٌ من هذه المكتبة، ويولّد `const Constant(EmployeeStatus.active)` قيمةً
//   افتراضية لعمود الحالة. والجزء لا يرى إلا واردات مكتبته — وبدون هذا
//   السطر يترجم المحلّل بلا شكوى ويرفض المصرِّف بـ«Not a constant expression»،
//   فتفشل **كل** الاختبارات بينما `flutter analyze` يقول صفر مشاكل.
// ignore: unused_import
import '../../core/constants/employee_status.dart';
import 'views/treasury_balance_view.dart';

// ── استيراد الـ DAOs ──────────────────────────────────────────────────────────
import 'daos/users_dao.dart';
import 'daos/app_settings_dao.dart';
import 'daos/fiscal_periods_dao.dart';
import 'daos/treasuries_dao.dart';
import 'daos/vouchers_dao.dart';
import 'daos/employees_dao.dart';
import 'daos/contractors_dao.dart';
import 'daos/partners_dao.dart';
import 'daos/audit_log_dao.dart';
import 'daos/exchange_rates_dao.dart';
import 'daos/advances_dao.dart';
import 'daos/attachments_dao.dart';
import 'daos/payroll_dao.dart';

// الملف المُولَّد تلقائياً بواسطة build_runner — لا تعدّله
part 'app_database.g.dart';

/// قاعدة البيانات الرئيسية للتطبيق
///
/// كيفية الاستخدام مع Riverpod:
///   ref.watch(appDatabaseProvider)
///
/// كيفية الاستخدام المباشر (للاختبار فقط):
///   final db = AppDatabase();
///   final users = await db.usersDao.getAllUsers();
@DriftDatabase(
  tables: [
    // ── إدارة النظام ───────────────────────────────────────────────────────
    Users,
    AppSettings,
    AppBlobs,

    // ── المالية الأساسية ───────────────────────────────────────────────────
    FiscalPeriods,
    VoucherSequences,
    Treasuries,
    Vouchers,

    // ── الموارد البشرية ────────────────────────────────────────────────────
    // ⚠️ ترتيب الإعلان لا يفرض ترتيب الإنشاء (Drift يحلّ الاعتماديات)، لكن
    //    PayrollPeriods قبل SalaryPayments يعكس العلاقة: الكشف أبٌ لسطوره.
    Departments,
    Employees,
    CashAdvances,
    CashAdvanceRepayments,
    PayrollPeriods,
    SalaryPayments,

    // ── الأطراف الخارجية ───────────────────────────────────────────────────
    Contractors,
    Partners,

    // ── سلف المشاريع (Schema v5) ───────────────────────────────────────────
    // ⚠️ Advances ≠ CashAdvances: الأولى سلفة مشروع، الثانية سلفة موظف
    Advances,
    AdvanceLines,
    ItemTypes,

    // ── المرفقات (Schema v6) ───────────────────────────────────────────────
    Attachments,

    // ── المساعد ────────────────────────────────────────────────────────────
    ExchangeRates,
    AuditLog,
  ],
  daos: [
    // ── DAOs مسجَّلة — Drift يولّد getter لكل منها تلقائياً ─────────────
    UsersDao,
    AppSettingsDao,
    FiscalPeriodsDao,
    TreasuriesDao,
    VouchersDao,
    EmployeesDao,
    ContractorsDao,
    PartnersDao,
    AuditLogDao,
    ExchangeRatesDao,
    AdvancesDao,
    AttachmentsDao,
    PayrollDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  // ── المُنشئ ─────────────────────────────────────────────────────────────

  /// مُنشئ الإنتاج — يستخدم driftDatabase الذي يحدد المسار تلقائياً
  /// (Documents على Mobile، IndexedDB/OPFS على Web)
  AppDatabase() : super(_openConnection());

  /// مُنشئ الاختبار — يستخدم قاعدة بيانات في الذاكرة (In-Memory)
  AppDatabase.forTesting(super.executor);

  // ── إصدار الـ Schema ─────────────────────────────────────────────────────

  /// رقم إصدار قاعدة البيانات الحالية
  /// يجب زيادته بمقدار 1 عند أي تغيير في الـ Schema
  @override
  int get schemaVersion => 8;

  // ── الـ Migration ─────────────────────────────────────────────────────────

  @override
  MigrationStrategy get migration => MigrationStrategy(
    /// يُنفَّذ عند أول تشغيل للتطبيق (إنشاء قاعدة البيانات من الصفر)
    onCreate: (Migrator m) async {
      // إنشاء جميع الجداول
      await m.createAll();

      // إنشاء الـ VIEW (لا يدعمه Drift API مباشرة)
      await customStatement(kCreateTreasuryBalancesView);

      // إنشاء الـ Indexes لتحسين أداء الاستعلامات
      await _createIndexes();

      // إدراج البيانات الأولية (Seed Data)
      await _seedInitialData();

      // بذور أنواع البنود الموحّدة
      await _seedItemTypes();
    },

    /// يُنفَّذ عند ترقية الإصدار (schemaVersion تغيّر)
    ///
    /// ⚠️ قاعدة إلزامية (درس مستفاد من تدقيق 2026-08-06):
    ///   كل ما يُنشَأ في onCreate يجب أن يُنشَأ في onUpgrade أيضاً.
    ///   لو أضفنا جدولاً جديداً ونسينا إنشاءه هنا، فإن المستخدم الذي
    ///   يُرقّي نسخته القديمة يحصل على قاعدة بيانات ناقصة، ويتعطل
    ///   التطبيق برسالة "no such table" عند فتح الشاشة المعنية فقط —
    ///   وهو أصعب أنواع الأعطال في التشخيص.
    onUpgrade: (Migrator m, int from, int to) async {
      // ── 1. إنشاء أي جدول جديد لم يكن موجوداً في النسخة القديمة ────────
      // createAll تُصدر CREATE TABLE IF NOT EXISTS فهي آمنة وقابلة للتكرار،
      // ولا تمسّ الجداول الموجودة ولا بياناتها إطلاقاً.
      await m.createAll();

      // ⚠️ **كل إضافة عمود أدناه تمرّ بـ [_addColumnIfMissing] لا بـ
      //   `m.addColumn` مباشرةً** (Schema v7):
      //
      //   `ALTER TABLE ADD COLUMN` في SQLite بلا `IF NOT EXISTS`، فتشغيل
      //   الترقية على قاعدة يوجد فيها العمود يرمي `duplicate column name`
      //   ويُجهض **بقية** الترقية — فتبقى القاعدة نصف مُرقّاة: جداول جديدة
      //   بلا أعمدتها، وترحيل بيانات لم يقع. وهو أسوأ من الفشل الكامل لأنه
      //   يبدو ناجحاً حتى تُفتح الشاشة المعنية.
      //
      //   ويحدث هذا فعلاً في حالتين واقعيتين:
      //     • قاعدة أُنشئت بمخطط حديث ثم فُتحت برقم إصدار أقدم
      //       (استعادة نسخة احتياطية · اختبارات الترقية نفسها)
      //     • ترقية تعثّرت في منتصفها ثم أُعيدت
      //
      //   كشفه اختبار `schema_v6_upgrade_test` لحظة إضافة الإصدار السابع:
      //   `duplicate column name: position`. راجع [_addColumnIfMissing].

      // ── 2. الترقية إلى الإصدار 2 (دعم نظام السلف) ──────────────────────
      if (from < 2) {
        // إضافة الحقول الجديدة لجدول السندات دون المساس بالبيانات القديمة
        await _addColumnIfMissing(m, vouchers, vouchers.projectName);
        await _addColumnIfMissing(m, vouchers, vouchers.invoiceNumber);
        await _addColumnIfMissing(m, vouchers, vouchers.spentBy);
        await _addColumnIfMissing(m, vouchers, vouchers.advanceNumber);
      }

      // ── الترقية إلى الإصدار 3 (رباط موثوق لسندَي التحويل) ──────────────
      if (from < 3) {
        await _addColumnIfMissing(m, vouchers, vouchers.transferGroupId);
      }

      // ── الترقية إلى الإصدار 4 (قيد CHECK على تسديد السلف) ─────────────
      if (from < 4) {
        // إضافة قيد CHECK(total_repaid <= amount) يتطلب إعادة بناء الجدول
        // في SQLite. alterTable مع TableMigration تُعيد بناءه مع الحفاظ على
        // البيانات. (نوع الرصيد الافتتاحي المدين وتغيير VIEW يُطبَّقان تلقائياً
        // عبر إعادة بناء الـ VIEW أدناه — لا يحتاجان تغييراً في الجداول.)
        // ignore: experimental_member_use
        await m.alterTable(TableMigration(cashAdvances));
      }

      // ── الترقية إلى الإصدار 5 (نظام سلف المشاريع بالمسودة) ────────────
      if (from < 5) {
        // جداول advances و advance_lines و item_types أُنشئت أعلاه عبر
        // createAll() — يبقى العمود الجديد على جدول السندات القائم.
        await _addColumnIfMissing(m, vouchers, vouchers.advanceId);

        // بذور أنواع البنود — idempotent (insertOrIgnore) فلا تُكرّر شيئاً
        // لو نُفِّذت الترقية أكثر من مرة أو كان الجدول مبذوراً أصلاً.
        await _seedItemTypes();
      }

      // ── الترقية إلى الإصدار 6 (المرفقات + تمييز سلفة الموظف) ──────────
      if (from < 6) {
        // جدول attachments أُنشئ أعلاه عبر createAll().

        // ── ترحيل نوع البند: 'سلفة' ← 'سلفة موظف' ────────────────────────
        //
        // **لماذا الترحيل ضروري؟** (قرار المالك 2026-08-24)
        //   `Advances` (سلفة مشروع) و`CashAdvances` (سلفة موظف) يحملان الاسم
        //   نفسه بالعربية. سندات سلف الموظفين كانت تُنشأ بنوع بند `'سلفة'`
        //   حرفياً، فيظهر في تقرير «المصروفات حسب البند» باسم غامض لا يدلّ
        //   على أنه يخصّ الموظفين.
        //
        //   تغيير القيمة في الكود وحده كان سيُنتج **قيمتين لمعنى واحد**:
        //   السندات القديمة `'سلفة'` والجديدة `'سلفة موظف'` — فينقسم البند
        //   في التقرير صفّين. لهذا يجب أن يمشي الترحيل مع تغيير الكود معاً.
        //
        //   نُحدّث السندات القديمة كلها، ثم نُصحّح صفّ البند في `item_types`.
        await customStatement(
          "UPDATE vouchers SET item_type = 'سلفة موظف' "
          "WHERE item_type = 'سلفة'",
        );

        // الصفّ القديم يُحذف بعد نقل السندات — لا نتركه ليُختار من جديد.
        // insertOrIgnore في _seedItemTypes سيضيف 'سلفة موظف' تلقائياً.
        await customStatement(
          "DELETE FROM item_types WHERE name = 'سلفة'",
        );
        await _seedItemTypes();
      }

      // ── الترقية إلى الإصدار 7 (نظام الموظفين والرواتب) ─────────────────
      if (from < 7) {
        // جدول payroll_periods أُنشئ أعلاه عبر createAll().

        // ── أعمدة الموظف الجديدة ─────────────────────────────────────────
        await _addColumnIfMissing(m, employees, employees.position);
        await _addColumnIfMissing(m, employees, employees.salaryCurrency);

        // ── أعمدة سطر كشف الرواتب ────────────────────────────────────────
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.payrollPeriodId);
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.snapshotName);
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.snapshotPosition);
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.snapshotCurrency);
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.snapshotHireDate);
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.eligibleDays);
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.eligibleDaysIsManual);
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.absenceDays);
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.absenceDeduction);
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.absenceDeductionIsManual);
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.advanceRepaymentAmount);
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.cashAdvanceId);
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.exchangeRate);
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.netAmountIqd);
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.fileNetAmount);
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.paymentStatus);
        await _addColumnIfMissing(m, salaryPayments, salaryPayments.paidAt);
        await _addColumnIfMissing(m, salaryPayments, salaryPayments.treasuryId);
        await _addColumnIfMissing(
            m, salaryPayments, salaryPayments.advanceLineId);
        await _addColumnIfMissing(m, salaryPayments, salaryPayments.advanceId);
        await _addColumnIfMissing(m, salaryPayments, salaryPayments.updatedAt);
        // ── ربط سطر السلفة بكشف الرواتب ──────────────────────────────────
        await _addColumnIfMissing(m, advanceLines, advanceLines.payrollPeriodId);

        // ═══════════════════════════════════════════════════════════════
        // ترحيل البيانات القائمة — **ليست ترقية أعمدة فارغة**
        // ═══════════════════════════════════════════════════════════════
        //
        // كل راتب أُدخل قبل v7 يفتقر إلى ثلاثة أشياء تجعله يبدو خاطئاً في
        // الشاشات الجديدة. تركُها لقيمها الافتراضية ليس حياداً بل تشويه:
        //
        //   1. **`net_amount_iqd` صفر** ⇒ كل تقرير رواتب جديد يجمع أصفاراً،
        //      فتظهر رواتب المالك السابقة كأنها لم تُصرف قط. وهي بالدينار
        //      قطعاً — لم تكن هناك عملة للراتب قبل v7 أصلاً.
        //
        //   2. **اللقطة فارغة** ⇒ كشف قديم يُعرض بلا اسم. نملؤها من جدول
        //      الموظفين: أدقّ ما يمكن معرفته أثراً رجعياً، وهو صادق لأن
        //      الاسم نادراً ما يتغيّر بخلاف الراتب.
        //      ⚠️ ولا ننسخ `basic_salary` من الموظف الحالي: هو مخزَّن في
        //      الصفّ أصلاً بقيمته وقت الصرف، ونسخُ الحالي فوقه يُزوّر التاريخ.
        //
        //   3. **`payment_status = 'unpaid'`** ⇒ رواتب صُرفت فعلاً تظهر
        //      كمستحقّة، فيُصرف بعضها مرتين. كل صفّ هنا نتج عن صرف فعليّ
        //      بسنده، فحالته الصحيحة `paid`، وتاريخ دفعه `payment_date`.
        await customStatement(
          'UPDATE salary_payments SET '
          'net_amount_iqd = net_amount, '
          'exchange_rate = 1.0, '
          "payment_status = 'paid', "
          'paid_at = payment_date, '
          // eligible_days و absence_* لا تُذكر هنا: `addColumn` تملأ الصفوف
          // القائمة بقيمها الافتراضية (30 يوماً · صفر غياب) وهي الصحيحة.
          'snapshot_name = COALESCE('
          '  (SELECT e.full_name FROM employees e '
          '   WHERE e.id = salary_payments.employee_id), '
          "  ''"
          ') '
          "WHERE snapshot_name = ''",
        );
      }

      // ── الترقية إلى الإصدار 8 (الأقسام وحالة الموظف) ───────────────────
      //
      // بلاغ المالك 2026-08-30 (الدفعة د): «حالة الموظف: حالي · منتهية
      // خدمته · إجازة» و«أقسام بترتيب يدوي: مهندسون ١–٧ · فنيون ٨–١٩…».
      //
      // جدول `departments` أُنشئ أعلاه عبر createAll().
      if (from < 8) {
        // ⚠️ **إعادة بناء لا `ALTER TABLE ADD COLUMN`** — وهذا مقصود لسببين:
        //
        //   ١. **حذف `is_active`.** كان يحمل حالتين والواقع ثلاث، و«الموقوف»
        //      تعني في الاستعمال «منتهية خدمته». وإبقاؤه بجوار `status`
        //      يُنتج عمودين لمعنى واحد يفترقان بأول كتابة تنسى أحدهما
        //      (نمط ع-٤٠). و`DROP COLUMN` في SQLite يحتاج إعادة بناء.
        //
        //   ٢. **قيد `CHECK` على الحالة.** القيود على مستوى الجدول تُكتَب
        //      عند `CREATE TABLE` وحده، فـ`addColumn` تُنتج قاعدةً مُرقّاة
        //      **بلا الحارس** الذي تحمله القاعدة الجديدة — وهما قاعدتان
        //      مختلفتان تحت اسم واحد.
        //
        // والفحص قبل البناء يجعلها **قابلة للتكرار**: ترقيةٌ تعثّرت في
        // منتصفها ثم أُعيدت لا تنهار على عمودٍ لم يعد موجوداً (نفس سبب
        // `_addColumnIfMissing`).
        if (await _hasColumn('employees', 'is_active')) {
          // ignore: experimental_member_use
          await m.alterTable(TableMigration(
            employees,
            columnTransformer: {
              // قرار إيقافٍ اتّخذه المالك سابقاً لا يضيع — يصير «منتهية خدمته»
              employees.status: const CustomExpression<String>(
                "CASE WHEN is_active = 0 THEN 'terminated' ELSE 'active' END",
              ),
            },
            newColumns: [
              employees.status,
              employees.departmentId,
              employees.sortOrder,
            ],
          ));
        } else {
          // قاعدة بُنيت بمخطط v8 أصلاً ثم فُتحت برقم أقدم — الأعمدة موجودة
          await _addColumnIfMissing(m, employees, employees.status);
          await _addColumnIfMissing(m, employees, employees.departmentId);
          await _addColumnIfMissing(m, employees, employees.sortOrder);
        }
      }

      // ── 3. إعادة إنشاء الفهارس ─────────────────────────────────────────
      // كلها CREATE INDEX IF NOT EXISTS — آمنة للتكرار.
      // بدون هذا السطر تبقى قواعد البيانات المُرقّاة بلا فهارس إلى الأبد
      // فتتباطأ الاستعلامات تدريجياً مع نمو البيانات.
      await _createIndexes();

      // ── 4. إعادة بناء الـ VIEW عند كل ترقية (لضمان تحديثه) ────────────
      await customStatement(kDropTreasuryBalancesView);
      await customStatement(kCreateTreasuryBalancesView);
    },

    /// يُنفَّذ قبل فتح قاعدة البيانات — للتحقق من سلامتها
    beforeOpen: (OpeningDetails details) async {
      // تفعيل Foreign Keys (معطّل افتراضياً في SQLite)
      await customStatement('PRAGMA foreign_keys = ON');
      // تفعيل WAL mode لأداء أفضل في الكتابة المتزامنة
      await customStatement('PRAGMA journal_mode = WAL');
      // تفعيل الحذف التلقائي للصفحات الفارغة (يقلل حجم الملف)
      await customStatement('PRAGMA auto_vacuum = INCREMENTAL');

      // ── تشخيص استمرارية التخزين ──────────────────────────────────────
      // يطبع «علامة الإقلاع» السابقة إن وُجدت. إن ظهر «قاعدة بيانات جديدة»
      // في كل تشغيل فالتخزين لا يستمر — وأشيع سبب لذلك على الويب أن
      // flutter run فتح منفذاً عشوائياً جديداً، وتخزين المتصفح مرتبط
      // بالأصل (المضيف:المنفذ). راجع .vscode/launch.json.
      await _logStoragePersistence();
    },
  );


  // ── تشخيص استمرارية التخزين ──────────────────────────────────────────────

  /// يكشف ما إذا كانت قاعدة البيانات تحفظ فعلاً بين تشغيل وآخر
  ///
  /// **لماذا؟** أعطال «ضياع البيانات» يصعب تشخيصها لأن التطبيق يعمل بشكل
  /// طبيعي تماماً داخل الجلسة الواحدة — ولا يُكتشف الخلل إلا بعد إعادة
  /// التشغيل وفقدان كل شيء. هذا الفحص يجعل الخلل مرئياً في **أول ثانية**.
  ///
  /// الآلية: يقرأ علامة الإقلاع السابقة ثم يكتب علامة جديدة. فإن ظهرت
  /// «قاعدة بيانات جديدة» في كل تشغيل فالتخزين لا يستمر.
  ///
  /// أشيع سبب على الويب: `flutter run` بلا `--web-port` يفتح منفذاً عشوائياً
  /// في كل مرة، وتخزين المتصفح (OPFS/IndexedDB) مرتبط بالأصل
  /// (المضيف:المنفذ) — فكل تشغيل أصلٌ جديد بقاعدة فارغة.
  Future<void> _logStoragePersistence() async {
    const key = 'last_boot_at';
    try {
      final rows = await customSelect(
        'SELECT value FROM app_settings WHERE key = ?',
        variables: [Variable.withString(key)],
      ).get();

      final previous = rows.isEmpty ? null : rows.first.data['value'] as String?;
      final now = DateTime.now().toIso8601String();

      if (previous == null || previous.isEmpty) {
        // ignore: avoid_print
        print('[التخزين] ⚠️ لا توجد علامة إقلاع سابقة — قاعدة بيانات جديدة.\n'
            '          إن تكرّر هذا في كل تشغيل فالبيانات لا تُحفَظ.\n'
            '          على الويب: شغّل بمنفذ ثابت (--web-port=5000).');
      } else {
        // ignore: avoid_print
        print('[التخزين] ✅ البيانات محفوظة — آخر إقلاع مسجَّل: $previous');
      }

      await customStatement(
        'INSERT INTO app_settings (key, value) VALUES (?, ?) '
        'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
        [key, now],
      );
    } catch (e) {
      // التشخيص ثانوي — لا يجوز أن يمنع فتح قاعدة البيانات
      // ignore: avoid_print
      print('[التخزين] تعذّر فحص الاستمرارية: $e');
    }
  }
  // ── Indexes ───────────────────────────────────────────────────────────────

  /// إنشاء الـ Indexes لتحسين أداء الاستعلامات الشائعة
  // ── مساعدات الترقية ───────────────────────────────────────────────────────

  /// هل يحوي هذا الجدول عموداً بهذا الاسم؟ — يُقرأ من مخطط SQLite نفسه
  Future<bool> _hasColumn(String tableName, String columnName) async {
    final rows = await customSelect("PRAGMA table_info('$tableName')").get();
    return rows.any((r) => r.data['name'] == columnName);
  }

  /// إضافة عمود **إن لم يكن موجوداً** — بديل آمن عن `Migrator.addColumn`
  ///
  /// SQLite لا يدعم `ALTER TABLE ADD COLUMN IF NOT EXISTS`، فالإضافة على
  /// عمود قائم ترمي وتُجهض بقية الترقية. نفحص المخطط أولاً فتصير الترقية
  /// **قابلة لإعادة التشغيل** كما هي `createAll()` أصلاً.
  ///
  /// 📌 استعملها في كل ترقية جديدة — لا `m.addColumn` مباشرةً.
  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo<Table, dynamic> table,
    GeneratedColumn<Object> column,
  ) async {
    if (await _hasColumn(table.actualTableName, column.name)) return;
    await m.addColumn(table, column);
  }

  Future<void> _createIndexes() async {
    // Vouchers: البحث الأكثر شيوعاً — حسب الخزينة والتاريخ
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_vouchers_treasury_date
      ON vouchers (treasury_id, voucher_date)
      WHERE is_deleted = 0
    ''');

    // Vouchers: البحث حسب الفترة المالية
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_vouchers_fiscal_period
      ON vouchers (fiscal_period_id, voucher_type)
      WHERE is_deleted = 0
    ''');

    // Vouchers: الحذف الناعم — Partial Index يُسرّع استعلامات is_deleted=0
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_vouchers_not_deleted
      ON vouchers (id)
      WHERE is_deleted = 0
    ''');

    // AuditLog: البحث التاريخي
    // ملاحظة: العمود مُسمَّى affected_table (وليس table_name) لتجنب كلمات SQL المحجوزة
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_audit_table_record
      ON audit_log (affected_table, record_id, created_at)
    ''');

    // Users: البحث بالاسم (للـ Login)
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_users_username
      ON users (username)
      WHERE is_deleted = 0
    ''');

    // Employees: الحذف الناعم
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_employees_active
      ON employees (id)
      WHERE is_deleted = 0
    ''');

    // Departments: **فرادة الاسم على غير المحذوف** (Schema v8)
    //
    // ⚠️ فهرس جزئي لا قيد `UNIQUE` على العمود: الحذف ناعم (القانون ٨)،
    //   فقيدٌ مطلق يمنع إعادة إنشاء قسمٍ حُذف بالاسم نفسه **إلى الأبد** —
    //   والمالك سيحذف «سواق» بالخطأ ثم يريدها مرّة أخرى.
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_departments_name_unique
      ON departments (name)
      WHERE is_deleted = 0
    ''');

    // Employees: ترتيب العرض (القسم ثم الترتيب داخله) — Schema v8
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_employees_department_order
      ON employees (department_id, sort_order)
      WHERE is_deleted = 0
    ''');

    // CashAdvances: السلف النشطة (الأكثر استعلاماً)
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_cash_advances_status
      ON cash_advances (status, employee_id)
      WHERE is_deleted = 0
    ''');

    // ── فهارس سلف المشاريع (Schema v5) ──────────────────────────────────

    // منع تكرار رقم السلفة داخل نفس السنة المالية.
    // جزئي (WHERE status != 'cancelled') عمداً: إلغاء سلفة يُحرّر رقمها
    // لإعادة الاستعمال، وإلا لبقي الرقم محجوزاً للأبد بسبب خطأ أُلغي.
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_advances_number_unique
      ON advances (fiscal_period_id, advance_number)
      WHERE status != 'cancelled'
    ''');

    // قوائم السلف: الفلترة حسب الحالة والخزينة (الاستعلام الأشيع في الشاشة)
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_advances_status_treasury
      ON advances (status, project_treasury_id)
    ''');

    // كشف الاستيراد المكرر: البحث ببصمة الملف
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_advances_file_hash
      ON advances (source_file_hash)
      WHERE source_file_hash != ''
    ''');

    // أسطر المسودة: تُقرأ دائماً بالكامل لسلفة واحدة
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_advance_lines_advance
      ON advance_lines (advance_id, row_number)
    ''');

    // ── فهرس المرفقات (Schema v6) ───────────────────────────────────────
    // الاستعلام الوحيد تقريباً: «أعطني مرفقات هذا الكيان» — مركّب لأن
    // entity_id وحده يتكرّر بين الجدولين (سلفة رقم ٣ وسند رقم ٣).
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_attachments_entity
      ON attachments (entity_type, entity_id, created_at)
    ''');

    // كشف الملف المكرّر على الكيان نفسه ببصمته
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_attachments_sha
      ON attachments (sha256)
      WHERE sha256 != ''
    ''');

    // السندات المرتبطة بسلفة — لحساب المُرسَل والمصروف
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_vouchers_advance
      ON vouchers (advance_id)
      WHERE advance_id IS NOT NULL AND is_deleted = 0
    ''');

    // ── فهارس الرواتب (Schema v7) ───────────────────────────────────────

    // 🔑 **كشف واحد لكل شهر — لا كشفان.**
    //   بدون هذا الفهرس يستطيع استيرادان متتاليان لنفس الشهر إنشاء كشفين،
    //   فتُصرف رواتب شباط مرّتين ولا يشتكي شيء. وهو جزئي (`is_deleted = 0`)
    //   عمداً: حذف كشف خاطئ يجب أن يُحرّر الشهر لإعادة بنائه — وإلا بقي
    //   الشهر محجوزاً للأبد بسبب استيراد أُلغي (نفس علّة رقم السلفة أعلاه).
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_payroll_periods_month_unique
      ON payroll_periods (year, month)
      WHERE is_deleted = 0
    ''');

    // كشف استيراد ملف الرواتب المكرّر ببصمته
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_payroll_periods_file_hash
      ON payroll_periods (source_file_hash)
      WHERE source_file_hash != ''
    ''');

    // سطور الكشف: تُقرأ دائماً بالكامل لكشف واحد
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_salary_payments_period
      ON salary_payments (payroll_period_id)
      WHERE is_deleted = 0
    ''');

    // 🔑 **موظف واحد مرّة واحدة في الكشف الواحد.**
    //   الاستيراد تراكمي (ملف البصرة ثم ملف كربلاء على الكشف نفسه)، فبدون
    //   هذا الفهرس يُنتج ملفٌّ أُعيد استيراده سطراً ثانياً للموظف نفسه —
    //   فيتضاعف راتبه في مجموع الشهر بصمت.
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_salary_payments_period_employee
      ON salary_payments (payroll_period_id, employee_id)
      WHERE payroll_period_id IS NOT NULL AND is_deleted = 0
    ''');

    // سطور الرواتب المسدَّدة من سلفة — لمطابقة سطر السلفة بمجموع رواتبه
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_salary_payments_advance_line
      ON salary_payments (advance_line_id)
      WHERE advance_line_id IS NOT NULL AND is_deleted = 0
    ''');
  }

  // ── نقطة تفتيش WAL ──────────────────────────────────────────────────────

  /// دمج سجل WAL في ملف قاعدة البيانات الرئيسي وتفريغه
  ///
  /// ⚠️ ضروري قبل أخذ نسخة احتياطية (إصلاح تدقيق 2026-08-06):
  ///   في وضع WAL تبقى المعاملات المُثبَّتة حديثاً في ملف `-wal` المنفصل،
  ///   ولا تظهر في `sales_management_db.sqlite` إلا بعد نقطة تفتيش. نسخ
  ///   الملف الرئيسي وحده كان يفقد آخر السندات المُثبَّتة. TRUNCATE يدمج
  ///   كل شيء في الملف الرئيسي ثم يُفرّغ الـ WAL.
  Future<void> checkpointWal() async {
    await customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
  }

  // ── تصفير الحسابات ────────────────────────────────────────────────────────

  /// مسح كل الحركة المالية مع الإبقاء على البيانات الأساسية
  ///
  /// ⚠️ أُعيدت كتابتها بالكامل (إصلاح ث-١ — تدقيق 2026-08-23).
  ///
  /// **ما كان معطوباً:** كانت تحذف `vouchers` ثم `fiscal_periods` فقط. لكن
  /// `voucher_sequences.fiscal_period_id` و`advances.fiscal_period_id`
  /// مفتاحان خارجيان إلى `fiscal_periods`، و`PRAGMA foreign_keys = ON`
  /// مُفعَّل في `beforeOpen`. وصف التسلسل يُنشأ عند **أول سند** في حياة
  /// القاعدة — فبعد أول سند يصير حذف الفترات مستحيلاً ويرمي قيداً أجنبياً،
  /// أي أن الزر كان يفشل دائماً في كل استعمال حقيقي.
  /// وحتى لو نجح، كان يترك `voucher_sequences` قائماً (فالترقيم يستأنف من
  /// حيث توقّف بدل أن يبدأ من ١) ويترك سلف المشاريع يتيمة تشير إلى فترات
  /// محذوفة.
  ///
  /// **ترتيب المسح إلزامي** — من الابن إلى الأب، وإلا فشل القيد الأجنبي:
  ///   advance_lines → advances → cash_advance_repayments → cash_advances
  ///   → salary_payments → **payroll_periods** → vouchers
  ///   → voucher_sequences → fiscal_periods
  ///
  /// ⚠️ **موضع `payroll_periods` في هذه السلسلة ليس اعتباطياً** (Schema v7):
  ///   `salary_payments.payroll_period_id` و`advance_lines.payroll_period_id`
  ///   يشيران إليه، و`payroll_periods.fiscal_period_id` يشير إلى الفترة.
  ///   فهو **ابنٌ للفترة وأبٌ للسطور** — تقديمه على سطوره أو تأخيره عن
  ///   الفترة يُعيد العطل ع-٠٩ حرفياً.
  ///
  /// **ما لا يُمسّ عمداً:** الموظفون والخزائن والمقاولون والشركاء والمستخدمون
  /// والإعدادات وسجل التدقيق. التصفير يمحو **الحركة** لا **الهيكل** — ولو
  /// مُحي سجل التدقيق لضاع أثر التصفير نفسه.
  ///
  /// يُعيد عدّادات ما مُحي فعلاً، ليوثّقها المستدعي في سجل التدقيق.
  Future<({int vouchers, int periods, int advances, int payrolls})>
      resetFinancialData() async {
    return transaction(() async {
      // القراءة قبل المسح — بعده تختفي الأرقام فلا يبقى ما يُوثَّق
      final counts = await _countMovement();
      await _wipeMovementTables();
      return counts;
    });
  }

  /// عدّاد صفوف جدول واحد — مساعد مشترك بين التصفيرين
  Future<int> _countRows(String table) async {
    final row =
        await customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
    return row.data['c'] as int? ?? 0;
  }

  /// عدّادات الحركة المالية قبل مسحها
  Future<({int vouchers, int periods, int advances, int payrolls})>
      _countMovement() async {
    return (
      vouchers: await _countRows('vouchers'),
      periods: await _countRows('fiscal_periods'),
      advances: await _countRows('advances'),
      payrolls: await _countRows('payroll_periods'),
    );
  }

  /// مسح **جداول الحركة** بالترتيب الآمن — الابن قبل الأب
  ///
  /// 🔑 **لماذا دالة مستقلّة ولماذا يمرّ بها التصفيران معاً؟**
  ///   هذا الترتيب هو نفسه سببُ العطل ع-٠٩، وقد صُحّح مرّة واحدة بعناية.
  ///   نسخُه في `factoryReset` كان سيعني أن أي جدول جديد يُضاف مستقبلاً
  ///   يُذكَر في نسخة ويُنسى في الأخرى — وهي **حرفياً** عائلة الأعطال التي
  ///   ضربت هذا المشروع ستّ مرّات (ع-٢٨ · ع-٣١ · ع-٣٣ · ع-٣٦ · ع-٣٨ · ع-٤٠):
  ///   «كل بابٍ يعرف جدولاً ويجهل الباقي». فالمسار واحد لا مساران.
  ///
  /// ⚠️ تُستدعى **داخل معاملة** دائماً — لا تستدعها مباشرةً.
  Future<void> _wipeMovementTables() async {
    // المرفقات أولاً: صفوفها تشير إلى سلف وسندات على وشك الحذف
    await delete(attachments).go();
    await delete(advanceLines).go();
    await delete(advances).go();
    await delete(cashAdvanceRepayments).go();
    await delete(cashAdvances).go();
    await delete(salaryPayments).go();
    // كشوف الرواتب بعد سطورها وقبل الفترة المالية — راجع تعليق resetFinancialData
    await delete(payrollPeriods).go();
    await delete(vouchers).go();
    // بدون هذا السطر يستأنف ترقيم السندات من آخر رقم قبل التصفير
    await delete(voucherSequences).go();
    await delete(fiscalPeriods).go();
  }

  // ── تصفير المصنع ──────────────────────────────────────────────────────────

  /// 🔥 **تصفير المصنع** — يُعيد القاعدة إلى حالة أول تشغيل تماماً
  ///
  /// أُضيفت بطلب صريح من المالك (2026-08-30): مرحلة التطوير والاختبار تتطلّب
  /// البدء من تطبيق نظيف بلا أي بيانات — لا مستخدم ولا خزينة ولا موظف ولا
  /// شعار — لا مجرّد مسح الحركة.
  ///
  /// **الفرق عن [resetFinancialData]:**
  ///   `resetFinancialData` يمحو **الحركة** ويُبقي **الهيكل** (موظفون ·
  ///   خزائن · مستخدمون · إعدادات · سجل تدقيق) — وهو الصحيح لتصفير سنة
  ///   تجريبية مع الاحتفاظ بمن أنشأها.
  ///   `factoryReset` يمحو **الاثنين معاً** ثم يُعيد بذر الإعدادات
  ///   الافتراضية وأنواع البنود، فيعود التطبيق إلى **شاشة الإعداد الأول**.
  ///
  /// ⚠️ **سجل التدقيق يُمحى أيضاً** — بخلاف التصفير العادي الذي يصونه عمداً.
  ///   هذا ليس سهواً: «تطبيق نظيف بلا أي بيانات» يشمله. ولهذا يكتب المستدعي
  ///   سطر التدقيق **قبل** الاستدعاء لا بعده — فيبقى شاهداً إن فشل المسح
  ///   في منتصفه، ويُمحى مع الباقي إن نجح.
  ///
  /// **ترتيب المسح إلزامي** — جداول الحركة أولاً عبر [_wipeMovementTables]
  /// (فهي أبناء الخزائن والفترات)، ثم الهيكل من الابن إلى الأب:
  ///   employees · contractors · partners → **treasuries**
  /// فالثلاثة تشير إلى `treasuries.id` بمفاتيح خارجية، وحذف الخزائن قبلهم
  /// يرمي `FOREIGN KEY constraint failed` — وهو العطل ع-٠٩ نفسه بثوب جديد.
  ///
  /// **ما يُعاد بذره بعد المسح:** الإعدادات الثمانية الافتراضية (ومنها
  /// `first_run_complete = false` وهو ما يُعيد التطبيق لشاشة الإعداد) وأنواع
  /// البنود الاثنان والعشرون. بدونه تبدأ القاعدة **فارغة تماماً** فلا يجد
  /// التطبيق حتى العملة الأساسية.
  ///
  /// 📌 `user_version` في SQLite لا يُمَسّ — القاعدة تبقى على Schema v7 فلا
  ///   يُعاد تشغيل أي ترحيل.
  ///
  /// يُعيد عدّادات ما مُحي، ليعرضها المستدعي على المالك.
  Future<
      ({
        int vouchers,
        int periods,
        int advances,
        int payrolls,
        int users,
        int treasuries,
        int employees,
        int attachments,
      })> factoryReset() async {
    return transaction(() async {
      // ── القراءة قبل المسح ────────────────────────────────────────────
      final movement = await _countMovement();
      final userCount = await _countRows('users');
      final treasuryCount = await _countRows('treasuries');
      final employeeCount = await _countRows('employees');
      final attachmentCount = await _countRows('attachments');

      // ── ١) الحركة — نفس المسار المحروس لا نسخة منه ───────────────────
      await _wipeMovementTables();

      // ── ٢) الهيكل — الابن قبل الأب ───────────────────────────────────
      // الثلاثة أبناء `treasuries` عبر مفاتيح خارجية
      await delete(employees).go();
      await delete(contractors).go();
      await delete(partners).go();
      await delete(treasuries).go();

      // ── ٣) ما لا يرتبط بشيء ──────────────────────────────────────────
      await delete(itemTypes).go();
      await delete(exchangeRates).go();
      await delete(auditLog).go();
      await delete(users).go();
      // الشعار يعيش هنا — «وصور» في طلب المالك
      await delete(appBlobs).go();
      await delete(appSettings).go();

      // ── ٤) إعادة البذر — وإلا بدأ التطبيق بلا عملة ولا بنود ──────────
      await _seedInitialData();
      await _seedItemTypes();

      return (
        vouchers: movement.vouchers,
        periods: movement.periods,
        advances: movement.advances,
        payrolls: movement.payrolls,
        users: userCount,
        treasuries: treasuryCount,
        employees: employeeCount,
        attachments: attachmentCount,
      );
    });
  }

  // ── Seed Data ─────────────────────────────────────────────────────────────

  /// إدراج البيانات الأولية عند أول تشغيل
  Future<void> _seedInitialData() async {
    // إعدادات النظام الافتراضية
    await batch((batch) {
      batch.insertAll(appSettings, [
        // اسم الشركة (فارغ — يُدخله المستخدم في شاشة الإعداد الأول)
        AppSettingsCompanion.insert(
          key: 'company_name',
          value: const Value(''),
          description: const Value('اسم الشركة — يظهر في الفاتورة'),
        ),
        // اللغة الافتراضية: العربية
        AppSettingsCompanion.insert(
          key: 'language',
          value: const Value('ar'),
          description: const Value('لغة الواجهة: ar | en'),
        ),
        // المظهر الافتراضي: تلقائي حسب النظام
        AppSettingsCompanion.insert(
          key: 'theme',
          value: const Value('system'),
          description: const Value('مظهر التطبيق: light | dark | system'),
        ),
        // العملة الأساسية
        AppSettingsCompanion.insert(
          key: 'primary_currency',
          value: const Value('IQD'),
          description: const Value('العملة الأساسية للتطبيق'),
        ),
        // العملة الثانوية
        AppSettingsCompanion.insert(
          key: 'secondary_currency',
          value: const Value('USD'),
          description: const Value('العملة الثانوية للتطبيق'),
        ),
        // سعر الصرف الافتراضي
        AppSettingsCompanion.insert(
          key: 'exchange_rate',
          value: const Value('1310'),
          description: const Value('سعر صرف الدولار مقابل الدينار'),
        ),
        // هل اكتمل الإعداد الأول؟
        AppSettingsCompanion.insert(
          key: 'first_run_complete',
          value: const Value('false'),
          description: const Value('true بعد اكتمال إعداد الحساب الأول'),
        ),
        // نسخة قاعدة البيانات للأرشيف
        AppSettingsCompanion.insert(
          key: 'db_schema_version',
          value: const Value('1'),
          description: const Value('إصدار الـ Schema — للاستخدام الداخلي فقط'),
        ),
      ]);
    });
  }

  /// بذور أنواع البنود الموحّدة (Schema v5)
  ///
  /// تجمع القوائم الثابتة التي كانت مبعثرة في شاشتَي الصرف والقبض، وتضيف
  /// إليها بنود مصاريف المشاريع الفعلية التي ترد في جداول الإكسل القادمة من
  /// المحافظات (كهربائيات، بانزين، إنترنت، طعام…).
  ///
  /// **idempotent**: تستخدم `InsertMode.insertOrIgnore` مع قيد التفرّد على
  /// `name`، فتكرار تنفيذها (في onCreate ثم onUpgrade مثلاً) لا يُنشئ نسخاً
  /// مكررة ولا يرمي استثناءً، ولا يمسّ بنداً عدّله المالك أو عطّله.
  Future<void> _seedItemTypes() async {
    // (الاسم، النوع، ترتيب العرض)
    const seeds = <({String name, String kind, int order})>[
      // ── بنود صرف المشاريع (الأشيع في جداول الإكسل الواردة) ──────────
      (name: 'مشتريات', kind: 'sarf', order: 10),
      (name: 'كهربائيات', kind: 'sarf', order: 20),
      (name: 'بانزين', kind: 'sarf', order: 30),
      (name: 'نقل', kind: 'sarf', order: 40),
      (name: 'طعام', kind: 'sarf', order: 50),
      (name: 'إنترنت', kind: 'sarf', order: 60),
      (name: 'صيانة', kind: 'sarf', order: 70),
      (name: 'قرطاسية', kind: 'sarf', order: 80),
      // ── بنود صرف إدارية ─────────────────────────────────────────────
      (name: 'راتب', kind: 'sarf', order: 90),
      (name: 'أجور عمال', kind: 'sarf', order: 100),
      (name: 'إيجار', kind: 'sarf', order: 110),
      (name: 'مصاريف تشغيل', kind: 'sarf', order: 120),
      (name: 'رسوم وضرائب', kind: 'sarf', order: 130),
      // «سلفة موظف» صراحةً لا «سلفة» — تمييزاً عن سلفة المشروع
      (name: 'سلفة موظف', kind: 'sarf', order: 140),
      // ── بنود القبض ──────────────────────────────────────────────────
      (name: 'رأس مال', kind: 'kabd', order: 200),
      (name: 'دفعة عميل', kind: 'kabd', order: 210),
      (name: 'إيراد بيع', kind: 'kabd', order: 220),
      (name: 'قرض وارد', kind: 'kabd', order: 230),
      (name: 'مرتجع صرف', kind: 'kabd', order: 240),
      (name: 'إيرادات أخرى', kind: 'kabd', order: 250),
      // ── عام ─────────────────────────────────────────────────────────
      (name: 'أخرى', kind: 'both', order: 999),
    ];

    await batch((batch) {
      batch.insertAll(
        itemTypes,
        seeds
            .map(
              (s) => ItemTypesCompanion.insert(
                name: s.name,
                kind: Value(s.kind),
                sortOrder: Value(s.order),
              ),
            )
            .toList(),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }
}

// ── اتصال قاعدة البيانات ──────────────────────────────────────────────────────

/// فتح اتصال قاعدة البيانات
///
/// drift_flutter يختار المسار المناسب تلقائياً:
///   - Android/iOS: مجلد Documents (ملف sales_management_db.sqlite)
///   - Desktop: مجلد التطبيق
///   - Web: IndexedDB / OPFS عبر WasmDatabase
///
/// مهم للويب:
///   يجب وجود الملفّين التاليين في مجلد `web/`:
///     - web/sqlite3.wasm     (من حزمة sqlite3 — مطابق للإصدار)
///     - web/drift_worker.js  (من حزمة drift — مطابق للإصدار)
///   بدونهما تَرمي driftDatabase() ArgumentError ويتجمد التطبيق على Splash.
QueryExecutor _openConnection() {
  return driftDatabase(
    // اسم ملف / مخزن قاعدة البيانات
    name: 'sales_management_db',
    // إعدادات الويب — إلزامية عند التجميع للويب
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
