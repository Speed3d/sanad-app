// ─────────────────────────────────────────────────────────────────────────────
// contractor_partner_delete_test.dart — ع-٥٧: بابا حذفٍ غير متماثلين
//
// **بلاغ المالك (2026-09-02):** «أضفتُ مقاولاً فظهر في الخزائن، ثم حذفته
//   فتوقّف البرنامج. وحين حذفتُ خزينته من شاشة الخزائن بقي المقاول موجوداً،
//   ومحاولة حذفه مرّة أخرى تُوقف البرنامج أيضاً.»
//
// **عطلان في بلاغ واحد:**
//   ١. **الانهيار**: `ref` يُستعمَل بعد التخلّص من ورقة التفاصيل —
//      يحرسه اختبار الودجت لا هذا الملف.
//   ٢. **اللاتماثل**: صار الإنشاء ذرّياً (مقاول + خزينة في معاملة) وبقي
//      الحذف يعرف طرفاً واحداً — فيُولَد يتيمٌ من كل باب.
//
// وهو **خامس** عطل من العائلة نفسها (ع-٢٨ · ع-٣١ · ع-٣٣ · ع-٥٦):
// «كل باب حذفٍ يعرف مكاناً ويجهل الباقي». والقاعدة المستخلصة:
// **ما أُنشئ معاً يُحذَف معاً.**
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';

void main() {
  late AppDatabase db;
  late int periodId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31, 23, 59, 59),
      ),
    );
  });

  tearDown(() async => db.close());

  // ── مساعدات ──────────────────────────────────────────────────────────────

  Future<int> newContractor([String name = 'مقاول البصرة']) =>
      db.contractorsDao.insertContractorWithTreasury(
        ContractorsCompanion.insert(name: name),
        treasuryName: 'خزنة $name',
      );

  Future<int> newPartner([String name = 'شريك بغداد']) =>
      db.partnersDao.insertPartnerWithTreasury(
        PartnersCompanion.insert(name: name),
        treasuryName: 'خزنة $name',
      );

  Future<int?> treasuryIdOfContractor(int id) async {
    final row = await (db.select(db.contractors)
          ..where((c) => c.id.equals(id)))
        .getSingle();
    return row.treasuryId;
  }

  /// هل تراه الشاشات؟ — القوائم تقرأ غير المحذوف فقط
  Future<bool> contractorVisible(int id) async {
    final all = await db.contractorsDao.getAllContractors();
    return all.any((c) => c.id == id);
  }

  Future<bool> partnerVisible(int id) async {
    final all = await db.partnersDao.getAllPartners();
    return all.any((p) => p.id == id);
  }

  Future<bool> treasuryVisible(int id) async {
    final all = await db.treasuriesDao.getAllTreasuries();
    return all.any((t) => t.id == id);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // الباب الأول — حذف المقاول
  // ═══════════════════════════════════════════════════════════════════════

  group('ع-٥٧ · حذف المقاول يأخذ خزينته معه', () {
    test('⭐⭐⭐ لا تبقى «خزنة مقاول» بلا مقاول', () async {
      final id = await newContractor();
      final tId = (await treasuryIdOfContractor(id))!;

      expect(await treasuryVisible(tId), isTrue, reason: 'الشرط المسبق');

      final hadTreasury =
          await db.contractorsDao.softDeleteContractorWithTreasury(id);

      expect(hadTreasury, isTrue);
      expect(await contractorVisible(id), isFalse);
      // 🔴 قبل الإصلاح: الخزينة تبقى ظاهرة في تبويب «مقاولون» بلا صاحب
      expect(await treasuryVisible(tId), isFalse,
          reason: 'الخزينة بقيت — يتيمٌ من باب الحذف الأول');
    });

    test('⭐⭐⭐ خزينةٌ فيها سندات تمنع الحذف برسالة تقول البديل', () async {
      final id = await newContractor();
      final tId = (await treasuryIdOfContractor(id))!;

      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: 1,
          voucherType: 'kabd',
          treasuryId: tId,
          fiscalPeriodId: periodId,
          amount: 500000,
          voucherDate: DateTime(2026, 3, 1),
        ),
      );

      // المال الذي تحرّك لا يُخفى بحذف صاحبه
      await expectLater(
        db.contractorsDao.softDeleteContractorWithTreasury(id),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'الرسالة', contains('عطّله بدلاً من ذلك'))),
      );

      // ⚠️ **والمعاملة تتراجع كاملةً**: رفضٌ يترك المقاول محذوفاً وخزينته
      //   قائمة أسوأ من الرفض نفسه
      expect(await contractorVisible(id), isTrue);
      expect(await treasuryVisible(tId), isTrue);
    });

    test('⭐ مقاول بلا خزينة يُحذف بلا شكوى', () async {
      final id = await db.contractorsDao
          .insertContractor(ContractorsCompanion.insert(name: 'بلا خزينة'));

      expect(await db.contractorsDao.softDeleteContractorWithTreasury(id),
          isFalse);
      expect(await contractorVisible(id), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الباب الثاني — حذف الخزينة
  // ═══════════════════════════════════════════════════════════════════════

  group('ع-٥٧ · حذف الخزينة يأخذ صاحبها معه', () {
    test('⭐⭐⭐ حذف خزينة المقاول لا يُبقيه ظاهراً في شاشته', () async {
      final id = await newContractor();
      final tId = (await treasuryIdOfContractor(id))!;

      await db.treasuriesDao.softDeleteTreasury(tId);

      expect(await treasuryVisible(tId), isFalse);
      // 🔴 **بلاغ المالك حرفياً**: «حذفته من الخزائن فبقي في المقاولون»
      expect(await contractorVisible(id), isFalse,
          reason: 'المقاول بقي مشيراً إلى خزينةٍ ميتة — يتيمٌ من الباب الثاني');
    });

    test('⭐⭐⭐ وحذف خزينة الشريك كذلك — البابان أُصلحا معاً', () async {
      final id = await newPartner();
      final row =
          await (db.select(db.partners)..where((p) => p.id.equals(id)))
              .getSingle();

      await db.treasuriesDao.softDeleteTreasury(row.treasuryId!);

      expect(await partnerVisible(id), isFalse);
    });

    test('⭐⭐ خزينة رئيسية لا صاحب لها تُحذف وحدها بلا أثر جانبي', () async {
      final tId = await db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
      );
      final other = await newContractor('مقاول آخر');

      await db.treasuriesDao.softDeleteTreasury(tId);

      expect(await treasuryVisible(tId), isFalse);
      // حذفٌ يمتدّ إلى ما لا علاقة له أخطر من حذفٍ ناقص
      expect(await contractorVisible(other), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // التماثل — البابان يُنتجان الحالة نفسها
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐⭐⭐ البابان متماثلان: أيّهما سلكتَ فالنتيجة واحدة', () async {
    final a = await newContractor('مقاول أ');
    final b = await newContractor('مقاول ب');
    final ta = (await treasuryIdOfContractor(a))!;
    final tb = (await treasuryIdOfContractor(b))!;

    // الأول من باب المقاول، والثاني من باب الخزينة
    await db.contractorsDao.softDeleteContractorWithTreasury(a);
    await db.treasuriesDao.softDeleteTreasury(tb);

    // ⚠️ **هذا هو الاختبار الذي كان ينقص العائلة كلها**: لا يسأل «هل يعمل
    //   هذا الباب؟» بل «هل يتّفق البابان؟» — فالأعطال الخمسة نشأت من
    //   بابٍ يعمل وحده بينما جاره يخالفه.
    expect(await contractorVisible(a), await contractorVisible(b));
    expect(await treasuryVisible(ta), await treasuryVisible(tb));
    expect(await contractorVisible(a), isFalse);
    expect(await treasuryVisible(ta), isFalse);
  });
}
