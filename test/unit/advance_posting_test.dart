// ─────────────────────────────────────────────────────────────────────────────
// advance_posting_test.dart — اختبارات مستودع سلف المشاريع
//
// ⚠️ Advances (سلفة مشروع) ≠ CashAdvances (سلفة موظف) — ملف اختبار الثانية هو
//    advance_repayment_test.dart
//
// يغطي:
//   1. ⭐ سيناريو المالك الكامل: أُرسل 3 مليون، صُرف 3.5، الخزنة −500 ألف
//   2. ذرّية الاعتماد — فشل جزئي لا يترك سنداً واحداً
//   3. حواجز العجز: تأكيد صريح + اسم من غطّاه
//   4. منع الاعتماد المزدوج والاعتماد في فترة مقفلة
//   5. تحرير المسودة: علامة «معدَّل»، الاستبعاد، كشف الملف المكرر
//   6. حسابات الملخص: المُرسَل / المصروف / المتبقي / العجز
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/advance_repository.dart';
// مطلوب لامتدادات AdvanceSummaryX (remaining / deficit / matchesExcel) —
// امتدادات Dart لا تعمل إلا باستيراد المكتبة التي تُعرّفها
import 'package:sales_management/domain/models/advance_model.dart';
import 'package:sales_management/domain/repositories/i_advance_repository.dart';

void main() {
  late AppDatabase db;
  late AdvanceRepository repo;
  late int periodId;
  late int mainTreasury;
  late int basraTreasury;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AdvanceRepository(db);

    periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31, 23, 59, 59),
      ),
    );
    mainTreasury = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(
        name: 'الخزينة الرئيسية',
        kind: const Value('main'),
      ),
    );
    basraTreasury = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(
        name: 'خزنة البصرة',
        kind: const Value('main'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  // ── مساعدات ──────────────────────────────────────────────────────────────

  /// تمويل خزنة البصرة بمبلغ عبر تحويل مرتبط بالسلفة
  Future<void> fundProject(int advanceId, double amount) async {
    await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: 1,
        voucherType: 'transfer_in',
        treasuryId: basraTreasury,
        fiscalPeriodId: periodId,
        amount: amount,
        currency: const Value('IQD'),
        voucherDate: DateTime(2026, 3, 1),
        advanceId: Value(advanceId),
      ),
    );
  }

  /// أسطر مصاريف بمبالغ محددة
  List<ParsedAdvanceLine> linesOf(List<double> amounts) {
    return [
      for (var i = 0; i < amounts.length; i++)
        ParsedAdvanceLine(
          rowNumber: i + 1,
          date: DateTime(2026, 3, 10),
          amount: amounts[i],
          itemType: 'كهربائيات',
          reason: 'مصروف ${i + 1}',
        ),
    ];
  }

  /// إنشاء سلفة ممولة بمسودة جاهزة
  Future<int> setupAdvance({
    required double funded,
    required List<double> expenses,
    String number = '23',
  }) async {
    final id = await repo.createAdvance(
      advanceNumber: number,
      projectTreasuryId: basraTreasury,
      advanceDate: DateTime(2026, 3, 1),
    );
    if (funded > 0) await fundProject(id, funded);
    await repo.createDraftFromExcel(
      advanceId: id,
      lines: linesOf(expenses),
      fileName: 'basra_$number.xlsx',
      fileHash: 'hash_$number',
    );
    return id;
  }

  Future<double> balanceOf(int treasuryId) async {
    final row = await db.treasuriesDao.getTreasuryBalance(treasuryId);
    return row?.balanceIqd ?? 0.0;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 1. ⭐ سيناريو المالك الكامل
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ سيناريو المالك: أُرسل 3 مليون، صُرف 3.5، الخزنة تصبح −500 ألف',
      () async {
    // أُرسل 3 مليون لمشروع البصرة على السلفة 23
    final advanceId = await setupAdvance(
      funded: 3000000,
      // مصاريف مجموعها 3,500,000
      expenses: [1500000, 1000000, 700000, 300000],
    );

    // المسودة وحدها لا تمسّ الرصيد
    expect(await balanceOf(basraTreasury), equals(3000000.0),
        reason: 'المسودة ليست سندات');

    // محاولة اعتماد بلا إقرار بالعجز → ترفض وتشرح
    final blocked = await repo.postAdvance(advanceId: advanceId);
    expect(blocked.success, isFalse);
    expect(blocked.needsDeficitConfirmation, isTrue);
    expect(blocked.deficit, closeTo(500000, 0.01));

    // الاعتماد مع الإقرار واسم من غطّى العجز
    final ok = await repo.postAdvance(
      advanceId: advanceId,
      allowDeficit: true,
      deficitCoveredBy: 'أبو أحمد — مدير المشروع',
    );
    expect(ok.success, isTrue);
    // 🔄 **تغيّر العقد 2026-08-27** (بلاغ المالك): كان سندٌ لكل سطر —
    //   فسلفةٌ بـ١٥٠ سطراً تُنتج ١٥٠ سنداً يستحيل تصحيحها. الآن **سند
    //   واحد** لمصاريفها، والتفصيل يبقى في سطورها.
    expect(ok.vouchersCreated, equals(1),
        reason: 'أربعة مصاريف بلا رواتب = سندٌ واحد مجمَّع');
    expect(ok.deficit, closeTo(500000, 0.01));

    // 🔑 النتيجة التي طلبها المالك: الخزنة بالسالب بمقدار ما تستحقه
    expect(await balanceOf(basraTreasury), closeTo(-500000, 0.01),
        reason: 'خزنة البصرة تطلب 500 ألف من الشركة');

    // الدَّين مسجَّل باسم صاحبه
    final advance = await repo.getAdvance(advanceId);
    expect(advance!.status, equals('posted'));
    expect(advance.deficitAmount, closeTo(500000, 0.01));
    expect(advance.deficitCoveredBy, equals('أبو أحمد — مدير المشروع'));

    // الملخص يعرض الأرقام الثلاثة
    final s = await repo.getSummary(advanceId);
    expect(s.sent, equals(3000000.0));
    expect(s.spent, equals(3500000.0));
    expect(s.remaining, equals(-500000.0));
  });

  test('الحالة الطبيعية: صُرف أقل من المُرسَل فيبقى متبقٍّ موجب', () async {
    final advanceId = await setupAdvance(
      funded: 3000000,
      expenses: [1500000, 1000000], // 2,500,000
    );

    final ok = await repo.postAdvance(advanceId: advanceId);
    expect(ok.success, isTrue, reason: 'لا عجز فلا حاجة لأي تأكيد');
    expect(ok.deficit, equals(0.0));

    expect(await balanceOf(basraTreasury), equals(500000.0));

    final s = await repo.getSummary(advanceId);
    expect(s.remaining, equals(500000.0),
        reason: 'أرسلتُ 3 مليون واشتروا بـ 2.5 → المتبقي 500 ألف');
    expect(s.deficit, equals(0.0));
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 2. ذرّية الاعتماد
  // ═══════════════════════════════════════════════════════════════════════

  test('الاعتماد ذرّي: فشل في المنتصف لا يترك أي سند ولا يغيّر الحالة',
      () async {
    final advanceId = await setupAdvance(
      funded: 5000000,
      expenses: [100000, 200000, 300000],
    );

    // 🔄 **أُعيدت صياغته 2026-08-27**: كان المُشغِّل يُفشل السند **الثالث**
    //   لأن الاعتماد كان يُنشئ سنداً لكل سطر. وبعد التجميع لا يوجد سند
    //   ثالث أصلاً — فصار المُشغِّل لا يُطلَق والاختبار يمرّ بلا أن يختبر.
    //
    //   الآن يُفشل **سند الصرف** أياً كان، ويُوسَّع الفحص ليشمل ما كان
    //   «المنتصف» يُثبته: أن **ربط السطور بسندها تراجع أيضاً** لا السند
    //   وحده — وهو جوهر الذرّية.
    await db.customStatement('''
      CREATE TRIGGER fail_third_sarf BEFORE INSERT ON vouchers
      WHEN NEW.voucher_type = 'sarf'
      BEGIN
        SELECT RAISE(ABORT, 'فشل مقصود لاختبار الذرّية');
      END
    ''');

    await expectLater(
      repo.postAdvance(advanceId: advanceId),
      throwsA(isA<Exception>()),
    );

    await db.customStatement('DROP TRIGGER fail_third_sarf');

    // ⭐ ولا سطرَ ارتبط بسند: التراجع يشمل الربط لا الإدراج وحده
    final linesAfterRollback = await db.advancesDao.getLines(advanceId);
    expect(linesAfterRollback.every((l) => l.voucherId == null), isTrue,
        reason: 'سطرٌ يشير إلى سند لم يُخلق = أثرٌ نصفيّ لعملية أُلغيت');

    // لا سند صرف واحد نجا.
    // نفلتر على 'sarf' عمداً: سند التحويل الذي موّل السلفة يحمل نفس
    // advance_id وهو موجود قبل الاعتماد ولا علاقة له بالتراجع.
    final sarfVouchers = await (db.select(db.vouchers)
          ..where((v) =>
              v.advanceId.equals(advanceId) & v.voucherType.equals('sarf')))
        .get();
    expect(sarfVouchers, isEmpty, reason: 'المعاملة تراجعت بالكامل');

    // الحالة لم تتغيّر إلى posted
    final advance = await db.advancesDao.getAdvanceById(advanceId);
    expect(advance!.status, equals('draft'));
    expect(advance.postedAt, isNull);

    // ولا سطر ارتبط بسند وهمي
    final lines = await db.advancesDao.getLines(advanceId);
    expect(lines.every((l) => l.voucherId == null), isTrue);
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 3. حواجز العجز
  // ═══════════════════════════════════════════════════════════════════════

  group('حواجز العجز', () {
    test('العجز بلا اسم من غطّاه يُرفض حتى مع الإقرار', () async {
      final advanceId = await setupAdvance(
        funded: 1000000,
        expenses: [1500000],
      );

      final r = await repo.postAdvance(
        advanceId: advanceId,
        allowDeficit: true,
        deficitCoveredBy: '   ', // فراغات فقط
      );

      expect(r.success, isFalse);
      expect(r.message, contains('من غطّى العجز'));
      expect(await balanceOf(basraTreasury), equals(1000000.0),
          reason: 'الرفض يجب ألا يمسّ الرصيد');
    });

    test('لا عجز = لا حاجة لاسم ولا إقرار', () async {
      final advanceId = await setupAdvance(
        funded: 1000000,
        expenses: [400000],
      );
      final r = await repo.postAdvance(advanceId: advanceId);
      expect(r.success, isTrue);
      expect(r.deficit, equals(0.0));
    });

    test('العجز يُحسَب من رصيد الخزينة لا من مبلغ السلفة', () async {
      // الخزينة فيها بقية من عملية سابقة (مليون) زائد سلفة بمليون
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: 99,
          voucherType: 'kabd',
          treasuryId: basraTreasury,
          fiscalPeriodId: periodId,
          amount: 1000000.0,
          currency: const Value('IQD'),
          voucherDate: DateTime(2026, 2, 1),
        ),
      );
      final advanceId = await setupAdvance(
        funded: 1000000,
        expenses: [1800000], // أكبر من السلفة لكن أصغر من الرصيد الكلي
      );

      final r = await repo.postAdvance(advanceId: advanceId);
      expect(r.success, isTrue,
          reason: 'الرصيد 2 مليون يكفي 1.8 — الخصم من الخزينة لا من السلفة');

      final s = await repo.getSummary(advanceId);
      expect(s.remaining, closeTo(-800000, 0.01),
          reason: 'السلفة نفسها تجاوزت مبلغها');
      expect(s.deficit, equals(0.0), reason: 'لكن الخزينة لم تدخل السالب');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 4. منع الاعتماد المزدوج والفترة المقفلة
  // ═══════════════════════════════════════════════════════════════════════

  test('لا يمكن اعتماد السلفة مرتين', () async {
    final advanceId =
        await setupAdvance(funded: 1000000, expenses: [200000]);

    final first = await repo.postAdvance(advanceId: advanceId);
    expect(first.success, isTrue);

    final second = await repo.postAdvance(advanceId: advanceId);
    expect(second.success, isFalse);
    expect(second.message, contains('معتمدة بالفعل'));

    // لم تتضاعف السندات
    final vouchers = await (db.select(db.vouchers)
          ..where((v) => v.advanceId.equals(advanceId)))
        .get();
    expect(vouchers.where((v) => v.voucherType == 'sarf'), hasLength(1));
    expect(await balanceOf(basraTreasury), equals(800000.0));
  });

  test('الاعتماد في فترة مالية مُقفَلة مرفوض', () async {
    final advanceId =
        await setupAdvance(funded: 1000000, expenses: [200000]);

    await (db.update(db.fiscalPeriods)..where((p) => p.id.equals(periodId)))
        .write(const FiscalPeriodsCompanion(status: Value('frozen')));

    await expectLater(
      repo.postAdvance(advanceId: advanceId),
      throwsA(isA<StateError>()),
    );
    expect(await balanceOf(basraTreasury), equals(1000000.0));
  });

  test('إلغاء سلفة معتمدة يُعيد المبلغ للخزينة', () async {
    final advanceId =
        await setupAdvance(funded: 1000000, expenses: [300000, 200000]);
    await repo.postAdvance(advanceId: advanceId);
    expect(await balanceOf(basraTreasury), equals(500000.0));

    await repo.cancelAdvance(advanceId: advanceId);

    expect(await balanceOf(basraTreasury), equals(1000000.0),
        reason: 'الحذف الناعم للسندات يُرجع الرصيد تلقائياً');
    final advance = await repo.getAdvance(advanceId);
    expect(advance!.status, equals('cancelled'));
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 5. تحرير المسودة
  // ═══════════════════════════════════════════════════════════════════════

  group('تحرير المسودة', () {
    test('تغيير الفلتر يضع علامة «معدَّل» ويحفظ الأصل', () async {
      final advanceId =
          await setupAdvance(funded: 1000000, expenses: [100000]);
      final line = (await db.advancesDao.getLines(advanceId)).first;

      await repo.updateLine(lineId: line.id, itemType: 'بانزين');

      final updated = (await db.advancesDao.getLines(advanceId)).first;
      expect(updated.itemType, equals('بانزين'));
      expect(updated.originalItemType, equals('كهربائيات'),
          reason: 'الأصل من الإكسل لا يتغير أبداً');
      expect(updated.isEdited, isTrue);
    });

    test('إعادة القيمة إلى أصلها تُزيل علامة «معدَّل»', () async {
      final advanceId =
          await setupAdvance(funded: 1000000, expenses: [100000]);
      final line = (await db.advancesDao.getLines(advanceId)).first;

      await repo.updateLine(lineId: line.id, amount: 999);
      expect((await db.advancesDao.getLines(advanceId)).first.isEdited, isTrue);

      await repo.updateLine(lineId: line.id, amount: 100000);
      expect((await db.advancesDao.getLines(advanceId)).first.isEdited, isFalse,
          reason: 'العلامة تُقارَن بالأصل لا بالقيمة السابقة');
    });

    test('الاستبعاد يُخرج السطر من الإجمالي ومن السندات', () async {
      final advanceId = await setupAdvance(
        funded: 1000000,
        expenses: [300000, 200000],
      );
      final lines = await db.advancesDao.getLines(advanceId);

      await repo.setLineExcluded(
        lineId: lines.last.id,
        excluded: true,
        reason: 'مصروف مكرر',
      );

      final s = await repo.getSummary(advanceId);
      expect(s.spent, equals(300000.0));
      expect(s.excludedLines, equals(1));

      final r = await repo.postAdvance(advanceId: advanceId);
      expect(r.vouchersCreated, equals(1), reason: 'المستبعَد لا يصبح سنداً');
      expect(await balanceOf(basraTreasury), equals(700000.0));

      // لكنه لم يُحذف — الأثر باقٍ
      final after = await db.advancesDao.getLines(advanceId);
      expect(after, hasLength(2));
      expect(after.last.excludeReason, equals('مصروف مكرر'));
    });

    test('لا يمكن تعديل أسطر سلفة معتمدة', () async {
      final advanceId =
          await setupAdvance(funded: 1000000, expenses: [100000]);
      final line = (await db.advancesDao.getLines(advanceId)).first;
      await repo.postAdvance(advanceId: advanceId);

      await expectLater(
        repo.updateLine(lineId: line.id, amount: 50000),
        throwsA(isA<StateError>()),
      );
    });

    test('كشف استيراد نفس الملف مرتين', () async {
      await setupAdvance(funded: 1000000, expenses: [100000], number: '23');

      final duplicate = await repo.findByFileHash('hash_23');
      expect(duplicate, isNotNull);
      expect(duplicate!.advanceNumber, equals('23'));

      expect(await repo.findByFileHash('hash_غير_موجود'), isNull);
    });

    test('لا يمكن الاستيراد على سلفة معتمدة', () async {
      final advanceId =
          await setupAdvance(funded: 1000000, expenses: [100000]);
      await repo.postAdvance(advanceId: advanceId);

      await expectLater(
        repo.createDraftFromExcel(
          advanceId: advanceId,
          lines: linesOf([50000]),
          fileName: 'x.xlsx',
          fileHash: 'h',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 6. الملخص والمطابقة
  // ═══════════════════════════════════════════════════════════════════════

  group('الملخص والمطابقة مع الإكسل', () {
    test('إجمالي الإكسل يبقى ثابتاً بعد تعديل الأسطر', () async {
      final advanceId = await setupAdvance(
        funded: 3000000,
        expenses: [1000000, 500000],
      );

      var s = await repo.getSummary(advanceId);
      expect(s.excelTotal, equals(1500000.0));
      expect(s.matchesExcel, isTrue);

      // المالك يصحّح مبلغاً
      final line = (await db.advancesDao.getLines(advanceId)).first;
      await repo.updateLine(lineId: line.id, amount: 900000);

      s = await repo.getSummary(advanceId);
      expect(s.excelTotal, equals(1500000.0),
          reason: 'مرجع المطابقة لا يتحرك مع التعديل');
      expect(s.spent, equals(1400000.0));
      expect(s.matchesExcel, isFalse, reason: 'الفرق يجب أن يبقى مرئياً');
      expect(s.excelDifference, equals(-100000.0));
      expect(s.editedLines, equals(1));
    });

    test('المُرسَل يطرح التحويلات المُعادة من المشروع', () async {
      final advanceId =
          await setupAdvance(funded: 3000000, expenses: [1000000]);

      // المشروع يُعيد 500 ألف غير مصروفة
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: 2,
          voucherType: 'transfer_out',
          treasuryId: basraTreasury,
          fiscalPeriodId: periodId,
          amount: 500000.0,
          currency: const Value('IQD'),
          voucherDate: DateTime(2026, 3, 20),
          advanceId: Value(advanceId),
        ),
      );

      final s = await repo.getSummary(advanceId);
      expect(s.sent, equals(2500000.0),
          reason: 'المُرسَل الصافي = 3 مليون − 500 ألف مُعادة');
    });

    test('سند التحويل الصادر من الخزينة الرئيسية لا يُنقص المُرسَل', () async {
      final advanceId = await repo.createAdvance(
        advanceNumber: '40',
        projectTreasuryId: basraTreasury,
        advanceDate: DateTime(2026, 3, 1),
      );

      // الطرفان يحملان نفس advance_id كما يفعل التحويل الحقيقي
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: 10,
          voucherType: 'transfer_out',
          treasuryId: mainTreasury, // الرئيسية — ليست خزينة المشروع
          fiscalPeriodId: periodId,
          amount: 3000000.0,
          currency: const Value('IQD'),
          voucherDate: DateTime(2026, 3, 1),
          advanceId: Value(advanceId),
        ),
      );
      await fundProject(advanceId, 3000000);

      final s = await repo.getSummary(advanceId);
      expect(s.sent, equals(3000000.0),
          reason: 'الفلترة على خزينة المشروع تمنع تصفير المُرسَل');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 7. قواعد إنشاء السلفة
  // ═══════════════════════════════════════════════════════════════════════

  group('إنشاء السلفة', () {
    test('رقم مكرر في نفس السنة يُرفض برسالة عربية واضحة', () async {
      await repo.createAdvance(
        advanceNumber: '23',
        projectTreasuryId: basraTreasury,
        advanceDate: DateTime(2026, 3, 1),
      );

      await expectLater(
        repo.createAdvance(
          advanceNumber: '23',
          projectTreasuryId: basraTreasury,
          advanceDate: DateTime(2026, 5, 1),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('مستعمَل'),
          ),
        ),
      );
    });

    test('اسم المشروع يُعبَّأ افتراضياً من اسم الخزينة', () async {
      final id = await repo.createAdvance(
        advanceNumber: '77',
        projectTreasuryId: basraTreasury,
        advanceDate: DateTime(2026, 3, 1),
      );
      final advance = await repo.getAdvance(id);
      expect(advance!.projectName, equals('خزنة البصرة'));
    });

    test('تاريخ بلا فترة مالية نشطة يُرفض', () async {
      await expectLater(
        repo.createAdvance(
          advanceNumber: '88',
          projectTreasuryId: basraTreasury,
          advanceDate: DateTime(2019, 3, 1),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // تقرير «حسب البند» بعد تجميع السندات (2026-08-27)
  // ═══════════════════════════════════════════════════════════════════════

  group('تقرير المصروفات حسب البند', () {
    test('⭐⭐ يقرأ بنود السلفة من **سطورها** بعد تجميع سندها', () async {
      // 🔑 لولا هذا لضاع تفصيل بنود المشاريع كلها خلف بندٍ واحد «سلفة»
      final advanceId = await setupAdvance(
        funded: 5000000,
        expenses: [100000, 200000, 300000],
      );
      await repo.postAdvance(advanceId: advanceId);

      final rows = await db.vouchersDao.getExpensesByItemType(
        from: DateTime(2020),
        to: DateTime(2030),
      );

      // سندٌ واحد مجمَّع — ومع ذلك تظهر بنود السطور لا بند «سلفة»
      expect(rows.any((r) => r.itemType == 'سلفة'), isFalse,
          reason: 'بندُ السند المجمَّع لا يُحتسب — التفصيل من السطور');

      final total = rows.fold<double>(0, (sum, r) => sum + r.totalEquivalentIqd);
      expect(total, closeTo(600000, 0.01),
          reason: 'مجموع البنود = مجموع مصاريف السلفة بلا زيادة ولا نقص');
    });

    test('⭐⭐ لا ازدواج: مال السلفة يُحتسب مرّة واحدة لا مرّتين', () async {
      // ⚠️ الخطر الأول في هذا التغيير: احتساب السند المجمَّع **و**سطوره معاً
      //   يُضاعف مصاريف المشاريع كلها — وهو صنف ع-١٣ نفسه.
      final advanceId = await setupAdvance(
        funded: 5000000,
        expenses: [250000, 250000],
      );
      await repo.postAdvance(advanceId: advanceId);

      // سند صرف عادي خارج السلفة — يجب أن يُحتسب هو أيضاً
      final n = await db.fiscalPeriodsDao.getNextVoucherNumber(
        fiscalPeriodId: 1,
        voucherType: 'sarf',
      );
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: n,
          voucherType: 'sarf',
          treasuryId: mainTreasury,
          fiscalPeriodId: 1,
          amount: 75000,
          voucherDate: DateTime(2025, 2, 15),
          itemType: const Value('قرطاسية'),
        ),
      );

      final rows = await db.vouchersDao.getExpensesByItemType(
        from: DateTime(2020),
        to: DateTime(2030),
      );
      final total = rows.fold<double>(0, (sum, r) => sum + r.totalEquivalentIqd);

      expect(total, closeTo(500000 + 75000, 0.01),
          reason: 'الازدواج كان سيُنتج ١٬٠٧٥٬٠٠٠ بدل ٥٧٥٬٠٠٠');
      expect(rows.any((r) => r.itemType == 'قرطاسية'), isTrue);
    });

    test('⭐ السلفة الملغاة لا تدخل التقرير — لم يخرج مالها', () async {
      final advanceId = await setupAdvance(
        funded: 5000000,
        expenses: [400000],
      );
      await repo.postAdvance(advanceId: advanceId);
      await repo.cancelAdvance(advanceId: advanceId);

      final rows = await db.vouchersDao.getExpensesByItemType(
        from: DateTime(2020),
        to: DateTime(2030),
      );
      final total = rows.fold<double>(0, (sum, r) => sum + r.totalEquivalentIqd);
      expect(total, closeTo(0, 0.01));
    });

    test('المسودة غير المعتمدة لا تدخل التقرير', () async {
      await setupAdvance(funded: 5000000, expenses: [900000]);

      final rows = await db.vouchersDao.getExpensesByItemType(
        from: DateTime(2020),
        to: DateTime(2030),
      );
      final total = rows.fold<double>(0, (sum, r) => sum + r.totalEquivalentIqd);
      expect(total, closeTo(0, 0.01),
          reason: 'مسودة لم يخرج مالها بعد');
    });
  });
}
