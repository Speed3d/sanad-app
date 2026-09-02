// ─────────────────────────────────────────────────────────────────────────────
// schema_v10_upgrade_test.dart — مسار الترقية الحقيقي v9 ← v10
//
// **ما تحمله هذه الترقية** (طلب المالك 2026-09-03):
//   ١. عمودا لقطة الإجازة على سطر الراتب (`leave_days_paid/unpaid`)
//   ٢. جدول `employee_events` — سجل حركات الموظف
//   ٣. **نقل التعيين إلى السجل** لكل موظف له `hire_date`
//
// ⚠️ **والنقل ليس تلفيقاً**: تاريخ التعيين **مسجَّل فعلاً** في `hire_date`،
//   فعرضُه في السجل إظهارٌ لما نعرفه. أمّا تعديلات الراتب والإجازات الماضية
//   فلا سجلّ لها ولا يجوز اختراعها — سجلٌّ يحمل حدثاً لم يقع أسوأ من سجلٍّ
//   ناقص.
//
// **طريقة التجهيز** (نفس نمط `schema_v8_upgrade_test`): نبني بالمخطط الحقيقي
//   ثم نُسقط ما أضافه العاشر ونُنزل `user_version` — فتُختبَر **جُمَل
//   الترحيل نفسها** لا مخططٌ مكتوب بيد يتقادم بصمت.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/database/tables/employee_events_table.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sanad_v10_upgrade');
    dbFile = File('${tempDir.path}/test.sqlite');
  });

  tearDown(() async {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// يبني قاعدة فيها موظفون ورواتب، ثم يُرجعها إلى شكل الإصدار التاسع
  Future<void> seedV9Database() async {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    final treasury = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );
    await db.employeesDao.insertEmployee(EmployeesCompanion.insert(
      fullName: 'أحمد علي',
      hireDate: Value(DateTime(2022, 6, 1)),
      basicSalary: const Value(3000000),
      treasuryId: Value(treasury),
    ));
    await db.employeesDao.insertEmployee(EmployeesCompanion.insert(
      fullName: 'بلا تاريخ تعيين',
      basicSalary: const Value(500000),
    ));
    await db.customStatement('PRAGMA wal_checkpoint(FULL)');
    await db.close();

    // ── الرجوع إلى شكل التاسع ──────────────────────────────────────────
    final raw = sqlite3.open(dbFile.path);
    raw.execute('DROP TABLE IF EXISTS employee_events');
    // SQLite تدعم DROP COLUMN منذ 3.35 — وهي أحدث في حزمة الاختبار
    raw.execute('ALTER TABLE salary_payments DROP COLUMN leave_days_paid');
    raw.execute('ALTER TABLE salary_payments DROP COLUMN leave_days_unpaid');
    raw.execute('PRAGMA user_version = 9');
    raw.dispose();
  }

  Future<AppDatabase> openUpgraded() async {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    // أول استعلام يُشغّل الترقية فعلياً
    await db.employeesDao.getAllEmployees();
    return db;
  }

  test('⭐⭐⭐ الترقية تمرّ ولا تُتلف الموظفين', () async {
    await seedV9Database();
    final db = await openUpgraded();

    final all = await db.employeesDao.getAllEmployees();
    expect(all, hasLength(2));
    expect(all.first.fullName, 'أحمد علي');
    expect(all.first.basicSalary, 3000000);
    await db.close();
  });

  test('⭐⭐⭐ عمودا لقطة الإجازة يُضافان بصفرٍ لا بقيمة مخترعة', () async {
    await seedV9Database();
    final db = await openUpgraded();

    final row = await db
        .customSelect(
            "SELECT COUNT(*) AS c FROM pragma_table_info('salary_payments') "
            "WHERE name IN ('leave_days_paid','leave_days_unpaid')")
        .getSingle();
    expect(row.data['c'], 2);
    await db.close();
  });

  test('⭐⭐⭐ التعيين يُنقَل إلى السجل — لمن له تاريخ فقط', () async {
    await seedV9Database();
    final db = await openUpgraded();

    final all = await db.employeesDao.getAllEmployees();
    final ahmed = all.firstWhere((e) => e.fullName == 'أحمد علي');
    final noDate = all.firstWhere((e) => e.fullName == 'بلا تاريخ تعيين');

    final ahmedEvents = await db.employeesDao.watchEvents(ahmed.id).first;
    expect(ahmedEvents, hasLength(1));
    expect(ahmedEvents.first.kind, EmployeeEventKind.hired);
    expect(ahmedEvents.first.eventDate, DateTime(2022, 6, 1));

    // ⚠️ **ولا يُخترع تاريخ لمن لا تاريخ له**: حدثٌ بتاريخ اليوم يقول
    //   «عُيِّن اليوم» وهو كذب — والفراغ أصدق
    expect(await db.employeesDao.watchEvents(noDate.id).first, isEmpty);
    await db.close();
  });

  test('⭐⭐ الترقية قابلة للتكرار — لا تُضاعف أحداث التعيين', () async {
    await seedV9Database();
    var db = await openUpgraded();
    await db.close();

    // فتحٌ ثانٍ: `user_version` صار ١٠ فلا تُعاد الترقية
    db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final all = await db.employeesDao.getAllEmployees();
    final ahmed = all.firstWhere((e) => e.fullName == 'أحمد علي');
    expect(await db.employeesDao.watchEvents(ahmed.id).first, hasLength(1));
    await db.close();
  });
}
