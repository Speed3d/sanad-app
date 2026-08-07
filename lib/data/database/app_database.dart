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
    Employees,
    CashAdvances,
    CashAdvanceRepayments,
    SalaryPayments,

    // ── الأطراف الخارجية ───────────────────────────────────────────────────
    Contractors,
    Partners,

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
  int get schemaVersion => 3;

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

      // ── 2. الترقية إلى الإصدار 2 (دعم نظام السلف) ──────────────────────
      if (from < 2) {
        // إضافة الحقول الجديدة لجدول السندات دون المساس بالبيانات القديمة
        await m.addColumn(vouchers, vouchers.projectName);
        await m.addColumn(vouchers, vouchers.invoiceNumber);
        await m.addColumn(vouchers, vouchers.spentBy);
        await m.addColumn(vouchers, vouchers.advanceNumber);
      }

      // ── الترقية إلى الإصدار 3 (رباط موثوق لسندَي التحويل) ──────────────
      if (from < 3) {
        await m.addColumn(vouchers, vouchers.transferGroupId);
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
    },
  );

  // ── Indexes ───────────────────────────────────────────────────────────────

  /// إنشاء الـ Indexes لتحسين أداء الاستعلامات الشائعة
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

    // CashAdvances: السلف النشطة (الأكثر استعلاماً)
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_cash_advances_status
      ON cash_advances (status, employee_id)
      WHERE is_deleted = 0
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
  
  /// مسح جميع السندات والفترات المالية (لتصفير أرصدة الخزائن) — مخصص لمرحلة التطوير
  Future<void> resetFinancialData() async {
    await transaction(() async {
      await delete(vouchers).go();
      await delete(fiscalPeriods).go();
      // يمكن مسح جداول أخرى هنا إذا لزم الأمر مستقبلاً
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
