// ─────────────────────────────────────────────────────────────────────────────
// voucher_filter_values_test.dart — قيم فلترة السندات (ب-١)
//
// الفجوة التي يغلقها (2026-08-23):
//   فلاتر شاشة السندات كانت **بحثاً نصّياً وخزينةً فقط**. والبحث النصّي يمسح
//   اسم الشخص والسبب ورقم السند — ولا يمسّ نوع البند ولا اسم المشروع.
//   فسؤال «كم صُرف على البانزين في مشروع البصرة؟» كان بلا جواب من الشاشة.
//
// قرار التصميم الذي تحرسه هذه الاختبارات:
//   الفلتر يعرض **القيم المستعملة فعلاً** لا كل القيم المتاحة. جدول
//   `item_types` مبذور بـ ٢١ بنداً؛ عرضها كلها يجعل أغلب الخيارات تُعطي
//   نتيجة فارغة فيظنّ المستخدم أن الفلتر معطوب.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/voucher_repository.dart';

void main() {
  late AppDatabase db;
  late VoucherRepository repo;
  late int periodId;
  late int treasuryId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = VoucherRepository(db);
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
    await repo.createVoucher(
      fiscalPeriodId: periodId,
      voucherType: 'kabd',
      treasuryId: treasuryId,
      amount: 20000000,
      currency: 'IQD',
      voucherDate: DateTime(2026, 2, 1),
    );
  });

  tearDown(() async => db.close());

  Future<int> sarf({String item = '', String? project}) {
    return repo.createVoucher(
      fiscalPeriodId: periodId,
      voucherType: 'sarf',
      treasuryId: treasuryId,
      amount: 100000,
      currency: 'IQD',
      voucherDate: DateTime(2026, 3, 1),
      itemType: item,
      projectName: project,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // أنواع البنود المستعملة
  // ═══════════════════════════════════════════════════════════════════════

  group('أنواع البنود المستعملة', () {
    test('⭐ تُعيد المستعمَل فعلاً لا كل البنود المبذورة', () async {
      // الجدول مبذور بـ ٢١ بنداً — لكن لا سند يستعملها بعد
      final seeded = await db.advancesDao.getAllItemTypes();
      expect(seeded.length, greaterThan(10),
          reason: 'الشرط المسبق: الجدول مبذور');

      await sarf(item: 'بانزين');
      await sarf(item: 'كهربائيات');

      final used = await db.vouchersDao.watchUsedItemTypes().first;
      expect(used, ['بانزين', 'كهربائيات'],
          reason: 'المستعمَل فقط، مرتَّباً — لا الـ ٢١ كلها');
    });

    test('لا تكرار حتى مع سندات متعدّدة بنفس البند', () async {
      await sarf(item: 'بانزين');
      await sarf(item: 'بانزين');
      await sarf(item: 'بانزين');

      final used = await db.vouchersDao.watchUsedItemTypes().first;
      expect(used, ['بانزين']);
    });

    test('البند الفارغ لا يظهر كخيار', () async {
      await sarf(item: '');
      await sarf(item: 'نقل');

      final used = await db.vouchersDao.watchUsedItemTypes().first;
      expect(used, ['نقل'], reason: '«غير محدد» ليس بنداً يُفلتَر به');
    });

    test('⭐ السند المحذوف ناعماً يختفي من قائمة الفلترة', () async {
      final id = await sarf(item: 'بانزين');
      await sarf(item: 'نقل');
      await repo.deleteVoucher(id);

      final used = await db.vouchersDao.watchUsedItemTypes().first;
      expect(used, ['نقل'],
          reason: 'خيار يُعطي نتيجة فارغة دائماً يُربك المستخدم');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // المشاريع المستعملة
  // ═══════════════════════════════════════════════════════════════════════

  group('المشاريع المستعملة', () {
    test('⭐ تُعيد أسماء المشاريع المميّزة مرتّبة', () async {
      await sarf(project: 'مشروع البصرة');
      await sarf(project: 'مشروع كربلاء');
      await sarf(project: 'مشروع البصرة');

      final used = await db.vouchersDao.watchUsedProjects().first;
      expect(used, ['مشروع البصرة', 'مشروع كربلاء']);
    });

    test('السندات بلا مشروع (null) لا تُنتج خياراً فارغاً', () async {
      await sarf(project: null);
      await sarf(project: 'مشروع البصرة');

      final used = await db.vouchersDao.watchUsedProjects().first;
      expect(used, ['مشروع البصرة']);
    });

    test('⭐ النصّ الفارغ لا يُنتج خياراً — تحوّله الطبقة إلى null', () async {
      // الشاشة تُرسل '' حين يترك المستخدم الحقل فارغاً
      await sarf(project: '');
      await sarf(project: '   ');

      final used = await db.vouchersDao.watchUsedProjects().first;
      expect(used, isEmpty);
    });

    test('قاعدة بيانات بلا مشاريع تُعيد قائمة فارغة (فيُخفى الفلتر)', () async {
      await sarf(item: 'نقل');
      final used = await db.vouchersDao.watchUsedProjects().first;
      expect(used, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // التفاعلية — القوائم تتحدّث فور الإدخال
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ القائمة تدفّق تفاعلي يتحدّث عند إضافة بند جديد', () async {
    await sarf(item: 'نقل');

    final stream = db.vouchersDao.watchUsedItemTypes();
    expect(await stream.first, ['نقل']);

    await sarf(item: 'بانزين');
    expect(await stream.first, ['بانزين', 'نقل'],
        reason: 'بلا هذا يبقى الفلتر قديماً حتى إعادة فتح الشاشة');
  });
}
