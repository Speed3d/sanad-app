// ─────────────────────────────────────────────────────────────────────────────
// contractor_partner_treasury_test.dart — توصيل المقاولين والشركاء بالخزائن
//
// **السؤال الذي حُسم** (قرار المالك 2026-09-01: «وصّلها، لا تُزلها»):
//   كان `contractors.treasury_id` و`partners.treasury_id` يبقيان `NULL`
//   **أبداً** لأن واجهتَي الإنشاء لا تمرّرانهما، و`kind` ثابت `'main'` عند
//   إنشاء أي خزينة.
//
//   فتبويبا الفلترة «مقاولون/شركاء» في شاشة الخزائن، وشاراتهما، وألوانهما،
//   و`getTreasuriesByKind('contractor')`، و`getContractorByTreasury` —
//   كلها **واجهة وشيفرة لبيانات لا يمكن أن توجد**. وهو ع-٠٦ في أوسع صوره:
//   ليس حقلاً يُكتَب ولا يُقرأ، بل **ميزة كاملة معروضة ومعطَّلة**.
//
// ═══ ما يحرسه هذا الملف ═══
//   ١. الخزينة تُنشَأ بـ`kind` الصحيح وتُربَط في **الاتجاهين**
//   ٢. الربط بخزينة قائمة **يحوّل نوعها** — وإلا بقيت «رئيسية» فلا يراها
//      تبويب المقاولين ولا شارته
//   ٣. «بلا خزينة» يبقى خياراً يعمل — لا كل مقاول يحتاج حساباً
//   ٤. **الذرّية**: لا مقاولَ بلا خزينته ولا خزينةَ بلا صاحبها
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  ContractorsCompanion contractor(String name) =>
      ContractorsCompanion.insert(name: name);

  PartnersCompanion partner(String name) => PartnersCompanion.insert(name: name);

  // ═══════════════════════════════════════════════════════════════════════
  // المقاولون
  // ═══════════════════════════════════════════════════════════════════════

  group('المقاول وخزينته', () {
    test('⭐⭐⭐ الخزينة تُنشَأ بنوعها وتُربَط في الاتجاهين', () async {
      final id = await db.contractorsDao.insertContractorWithTreasury(
        contractor('أبو علي'),
        treasuryName: 'مقاول: أبو علي',
      );

      final c = await db.contractorsDao.getContractorById(id);
      expect(c!.treasuryId, isNotNull,
          reason: '🔴 كان يبقى NULL أبداً — والتبويب واجهةً لبيانات مستحيلة');

      final t = await db.treasuriesDao.getTreasuryById(c.treasuryId!);
      expect(t!.name, 'مقاول: أبو علي');
      expect(t.kind, 'contractor');
      expect(t.entityId, id);
      expect(t.entityType, 'contractor');

      // والاتجاه العكسي — وهو ما تقرؤه بطاقة الخزينة
      final back = await db.contractorsDao.getContractorByTreasury(t.id);
      expect(back!.id, id);
    });

    test('⭐⭐⭐ تبويب «مقاولون» في شاشة الخزائن يجد شيئاً أخيراً', () async {
      await db.contractorsDao.insertContractorWithTreasury(
        contractor('أبو علي'),
        treasuryName: 'مقاول: أبو علي',
      );

      final list = await db.treasuriesDao.getTreasuriesByKind('contractor');
      expect(list, hasLength(1));
      expect(list.first.name, 'مقاول: أبو علي');
    });

    test('⭐⭐⭐ الربط بخزينة قائمة **يحوّل نوعها** لا يتركها رئيسية', () async {
      final existing = await db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(name: 'خزنة الكرخ'),
      );

      final id = await db.contractorsDao.insertContractorWithTreasury(
        contractor('أبو حسن'),
        existingTreasuryId: existing,
      );

      final t = await db.treasuriesDao.getTreasuryById(existing);
      // 🔴 بلا هذا التحويل: المقاول مربوط والخزينة «رئيسية» — فلا تظهر في
      //   تبويبه ولا تحمل شارته، والربط موجودٌ لا يراه أحد
      expect(t!.kind, 'contractor');
      expect(t.entityId, id);
      expect(t.name, 'خزنة الكرخ', reason: 'الاسم الذي اختاره المالك لا يُمسّ');

      final c = await db.contractorsDao.getContractorById(id);
      expect(c!.treasuryId, existing);
    });

    test('⭐⭐ «بلا خزينة» يبقى خياراً يعمل', () async {
      final id = await db.contractorsDao
          .insertContractorWithTreasury(contractor('نقديّ'));

      final c = await db.contractorsDao.getContractorById(id);
      expect(c!.treasuryId, isNull);
      expect(await db.treasuriesDao.getTreasuriesByKind('contractor'), isEmpty);
    });

    test('⭐⭐ خزينةٌ قائمة تُقدَّم على الإنشاء — لا تُنشَأ خزينتان', () async {
      final existing = await db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(name: 'خزنة قائمة'),
      );

      await db.contractorsDao.insertContractorWithTreasury(
        contractor('أبو علي'),
        treasuryName: 'مقاول: أبو علي',
        existingTreasuryId: existing,
      );

      final all = await db.treasuriesDao.getAllTreasuries();
      expect(all, hasLength(1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الشركاء
  // ═══════════════════════════════════════════════════════════════════════

  group('الشريك وخزينته', () {
    test('⭐⭐⭐ الخزينة تُنشَأ بنوعها وتُربَط في الاتجاهين', () async {
      final id = await db.partnersDao.insertPartnerWithTreasury(
        partner('سعد'),
        treasuryName: 'شريك: سعد',
      );

      final p = await db.partnersDao.getPartnerById(id);
      expect(p!.treasuryId, isNotNull);

      final t = await db.treasuriesDao.getTreasuryById(p.treasuryId!);
      expect(t!.kind, 'partner');
      expect(t.entityId, id);
      expect(t.entityType, 'partner');
    });

    test('⭐⭐ تبويبا «مقاولون» و«شركاء» لا يختلطان', () async {
      await db.contractorsDao.insertContractorWithTreasury(
        contractor('أبو علي'),
        treasuryName: 'مقاول: أبو علي',
      );
      await db.partnersDao.insertPartnerWithTreasury(
        partner('سعد'),
        treasuryName: 'شريك: سعد',
      );

      expect(await db.treasuriesDao.getTreasuriesByKind('contractor'),
          hasLength(1));
      expect(
          await db.treasuriesDao.getTreasuriesByKind('partner'), hasLength(1));
      expect(await db.treasuriesDao.getTreasuriesByKind('main'), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الذرّية
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐⭐⭐ فشلٌ في منتصف العملية لا يترك مقاولاً بلا خزينة', () async {
    // خزينةٌ لا وجود لها ⇒ يفشل التحديث داخل المعاملة
    await expectLater(
      db.contractorsDao.insertContractorWithTreasury(
        contractor('أبو علي'),
        existingTreasuryId: 9999,
      ),
      throwsA(anything),
    );

    // 🔑 والمقاول **لم يُنشَأ**: نصفُ عملية هنا يعني بطاقةَ «حساب مقاول»
    //   بلا مقاول، أو مقاولاً يظهر في قائمته بلا الحساب الذي طلبه المالك
    expect(await db.contractorsDao.getAllContractors(), isEmpty);
  });
}
