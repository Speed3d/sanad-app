// ─────────────────────────────────────────────────────────────────────────────
// schema_v6_upgrade_test.dart — مسار الترقية الحقيقي v5 ← v6
//
// **لماذا ملف منفصل عن `schema_v6_test.dart`؟**
//   ذاك يختبر قاعدة **جديدة** تُنشأ بـ `onCreate`. وهذا يختبر ما يحدث
//   لقاعدة **قائمة فيها بيانات** حين تُرقَّى — وهو المسار الذي ستمرّ به
//   قاعدة المالك على جهازه، والوحيد الذي يمكن أن يُتلف بياناته.
//
// **الثغرة التي يسدّها:** كل اختبارات المخطط السابقة (v4 · v5) تفحص قواعد
// جديدة فقط. أي أن `onUpgrade` **لم يُختبَر قط في هذا المشروع** رغم أنه
// الشيفرة الوحيدة التي تلمس بيانات موجودة.
//
// الترحيل المُختبَر هنا: `item_type = 'سلفة'` ← «سلفة موظف»
// (قرار المالك 2026-08-24). لو فشل، انقسم البند في تقرير «المصروفات حسب
// البند» إلى صفّين لمعنى واحد — أو الأسوأ: ضاعت قيمة البند كلياً.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sanad_v6_upgrade');
    dbFile = File('${tempDir.path}/test.sqlite');
  });

  tearDown(() async {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// يبني قاعدة كاملة ثم يُرجعها إلى الإصدار ٥ ويزرع فيها بيانات قديمة
  ///
  /// نبني بالمخطط الحقيقي ثم نُنزل `user_version` بدل كتابة مخطط v5 يدوياً:
  /// المخطط المكتوب يدوياً يتقادم بصمت ويختبر شيئاً لم يعد موجوداً، بينما
  /// هذه الطريقة تختبر **جُمَل الترحيل نفسها** وهي المقصودة.
  Future<void> seedLegacyDatabase() async {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31, 23, 59, 59),
      ),
    );
    final treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );

    // سندات بالقيمة القديمة الغامضة — كما هي في قاعدة المالك
    for (var i = 1; i <= 3; i++) {
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: i,
          voucherType: 'sarf',
          treasuryId: treasuryId,
          fiscalPeriodId: periodId,
          amount: 100000.0 * i,
          voucherDate: DateTime(2026, 3, i),
          itemType: const Value('سلفة'),
        ),
      );
    }
    // سند ببند آخر — يجب ألّا يمسّه الترحيل
    await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: 9,
        voucherType: 'sarf',
        treasuryId: treasuryId,
        fiscalPeriodId: periodId,
        amount: 777000,
        voucherDate: DateTime(2026, 4, 1),
        itemType: const Value('بانزين'),
      ),
    );
    await db.close();

    // إعادة الحالة إلى ما قبل الترقية
    final raw = sqlite3.open(dbFile.path);
    raw.execute("DELETE FROM item_types WHERE name = 'سلفة موظف'");
    raw.execute(
      "INSERT OR IGNORE INTO item_types (name, kind, is_active, sort_order) "
      "VALUES ('سلفة', 'sarf', 1, 140)",
    );
    raw.execute('PRAGMA user_version = 5');
    raw.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ الترقية تحوّل سندات «سلفة» القديمة إلى «سلفة موظف»', () async {
    await seedLegacyDatabase();

    // فتح القاعدة يُشغّل onUpgrade(5 → 6)
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final rows = await db.vouchersDao.getExpensesByItemType(
      from: DateTime(2026, 1, 1),
      to: DateTime(2026, 12, 31, 23, 59, 59),
    );
    final names = rows.map((r) => r.itemType).toList();

    expect(names, isNot(contains('سلفة')),
        reason: 'بقاء القيمة القديمة يعني انقسام البند في التقرير');
    expect(names, contains('سلفة موظف'));

    final migrated = rows.firstWhere((r) => r.itemType == 'سلفة موظف');
    expect(migrated.voucherCount, 3, reason: 'السندات الثلاثة كلها');
    expect(migrated.totalEquivalentIqd, 600000,
        reason: '100,000 + 200,000 + 300,000 — لا مبلغ يضيع في الترحيل');

    await db.close();
  });

  test('⭐ الترحيل لا يمسّ البنود الأخرى', () async {
    await seedLegacyDatabase();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    final rows = await db.vouchersDao.getExpensesByItemType(
      from: DateTime(2026, 1, 1),
      to: DateTime(2026, 12, 31, 23, 59, 59),
    );
    final petrol = rows.firstWhere((r) => r.itemType == 'بانزين');
    expect(petrol.totalEquivalentIqd, 777000);

    await db.close();
  });

  test('⭐ قائمة البنود تُصحَّح: «سلفة» تختفي و«سلفة موظف» تظهر', () async {
    await seedLegacyDatabase();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    final names =
        (await db.advancesDao.getAllItemTypes()).map((t) => t.name).toList();
    expect(names, isNot(contains('سلفة')),
        reason: 'ترك القديم يتيح اختياره من جديد فيعود الانقسام');
    expect(names, contains('سلفة موظف'));

    await db.close();
  });

  test('⭐ جدول المرفقات يُنشأ في القاعدة المُرقّاة', () async {
    await seedLegacyDatabase();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    // لو نُسي إنشاؤه لتعطّلت شاشة المرفقات وحدها برسالة «no such table»
    // — وهو أصعب أنواع الأعطال تشخيصاً
    final row = await db
        .customSelect('SELECT COUNT(*) AS c FROM attachments')
        .getSingle();
    expect(row.data['c'], 0);

    await db.close();
  });

  test('⭐ الترقية لا تفقد أي بيانات قائمة', () async {
    await seedLegacyDatabase();
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    final vouchers = await db.vouchersDao.getAllVouchers();
    expect(vouchers, hasLength(4), reason: 'السندات الأربعة كلها باقية');

    final periods = await db.fiscalPeriodsDao.watchAllPeriods().first;
    expect(periods, hasLength(1));

    final treasuries = await db.treasuriesDao.watchAllTreasuries().first;
    expect(treasuries, hasLength(1));

    await db.close();
  });

  test('إعادة فتح القاعدة بعد الترقية لا تُعيد الترحيل ولا تُفسده', () async {
    await seedLegacyDatabase();

    var db = AppDatabase.forTesting(NativeDatabase(dbFile));
    await db.customSelect('SELECT 1').get();
    await db.close();

    // فتحة ثانية — الإصدار صار ٦ فلا يعمل onUpgrade
    db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final rows = await db.vouchersDao.getExpensesByItemType(
      from: DateTime(2026, 1, 1),
      to: DateTime(2026, 12, 31, 23, 59, 59),
    );
    final migrated = rows.firstWhere((r) => r.itemType == 'سلفة موظف');
    expect(migrated.voucherCount, 3);
    await db.close();
  });
}
