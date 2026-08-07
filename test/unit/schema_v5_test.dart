// ─────────────────────────────────────────────────────────────────────────────
// schema_v5_test.dart — اختبارات الإصدار 5 (نظام سلف المشاريع بالمسودة)
//
// يغطي:
//   1. وجود الجداول الثلاثة الجديدة وعمود الربط على السندات
//   2. القيود الدفاعية (CHECK) على الحالة والمبالغ
//   3. الفهرس الفريد لرقم السلفة داخل السنة المالية، وتحرّره عند الإلغاء
//   4. بذور أنواع البنود وكونها idempotent
//   5. ⭐ القاعدة الجوهرية: أسطر المسودة لا تؤثر على رصيد أي خزينة
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';

void main() {
  late AppDatabase db;
  late int periodId;
  late int treasuryId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
      ),
    );
    treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(
        name: 'خزنة البصرة',
        kind: const Value('main'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  /// مساعد: إنشاء سلفة بالحد الأدنى من الحقول
  Future<int> insertAdvance({
    String number = '23',
    String status = 'open',
    int? period,
  }) {
    return db.into(db.advances).insert(
          AdvancesCompanion.insert(
            advanceNumber: number,
            projectTreasuryId: treasuryId,
            fiscalPeriodId: period ?? periodId,
            advanceDate: DateTime(2026, 3, 1),
            status: Value(status),
          ),
        );
  }

  test('الإصدار الحالي هو 5', () {
    expect(db.schemaVersion, equals(5));
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 1. الجداول الجديدة
  // ═══════════════════════════════════════════════════════════════════════

  group('الجداول الجديدة', () {
    test('يمكن إنشاء سلفة وقراءتها', () async {
      final id = await insertAdvance();
      final row = await (db.select(db.advances)
            ..where((a) => a.id.equals(id)))
          .getSingle();

      expect(row.advanceNumber, equals('23'));
      expect(row.status, equals('open'), reason: 'الحالة الافتراضية open');
      expect(row.excelTotal, equals(0.0));
      expect(row.deficitAmount, equals(0.0));
      expect(row.deficitCoveredBy, isNull);
      expect(row.postedAt, isNull);
    });

    test('يمكن إضافة أسطر مسودة مرتبطة بالسلفة', () async {
      final advanceId = await insertAdvance(status: 'draft');
      await db.into(db.advanceLines).insert(
            AdvanceLinesCompanion.insert(
              advanceId: advanceId,
              voucherDate: DateTime(2026, 3, 5),
              amount: 250000.0,
              originalAmount: 250000.0,
              originalDate: DateTime(2026, 3, 5),
              itemType: const Value('كهربائيات'),
              rowNumber: const Value(1),
            ),
          );

      final lines = await (db.select(db.advanceLines)
            ..where((l) => l.advanceId.equals(advanceId)))
          .get();

      expect(lines, hasLength(1));
      expect(lines.first.itemType, equals('كهربائيات'));
      expect(lines.first.isEdited, isFalse);
      expect(lines.first.isExcluded, isFalse);
      expect(lines.first.voucherId, isNull,
          reason: 'السطر لم يُعتمَد بعد فلا سند له');
    });

    test('عمود advance_id مضاف إلى جدول السندات', () async {
      final advanceId = await insertAdvance();
      final voucherId = await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: 1,
          voucherType: 'sarf',
          treasuryId: treasuryId,
          fiscalPeriodId: periodId,
          amount: 100000.0,
          voucherDate: DateTime(2026, 3, 5),
          advanceId: Value(advanceId),
        ),
      );

      final v = await db.vouchersDao.getVoucherById(voucherId);
      expect(v!.advanceId, equals(advanceId));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 2. القيود الدفاعية
  // ═══════════════════════════════════════════════════════════════════════

  group('القيود الدفاعية (CHECK)', () {
    test('ترفض حالة سلفة غير معروفة', () async {
      expect(
        () => insertAdvance(status: 'postd'), // خطأ إملائي متعمَّد
        throwsA(isA<Exception>()),
        reason: 'حالة خارج القائمة يجب أن تُرفض على مستوى قاعدة البيانات',
      );
    });

    test('ترفض سطر مسودة بمبلغ صفر أو سالب', () async {
      final advanceId = await insertAdvance(status: 'draft');
      expect(
        () => db.into(db.advanceLines).insert(
              AdvanceLinesCompanion.insert(
                advanceId: advanceId,
                voucherDate: DateTime(2026, 3, 5),
                amount: 0.0,
                originalAmount: 100.0,
                originalDate: DateTime(2026, 3, 5),
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('ترفض نوع بند بتصنيف غير معروف', () async {
      expect(
        () => db.into(db.itemTypes).insert(
              ItemTypesCompanion.insert(
                name: 'بند تجريبي',
                kind: const Value('invalid'),
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 3. الفهرس الفريد لرقم السلفة
  // ═══════════════════════════════════════════════════════════════════════

  group('تفرّد رقم السلفة', () {
    test('يرفض رقمين متطابقين في نفس السنة المالية', () async {
      await insertAdvance(number: '23');
      expect(
        () => insertAdvance(number: '23'),
        throwsA(isA<Exception>()),
        reason: 'رقم السلفة يجب أن يكون فريداً داخل السنة المالية',
      );
    });

    test('يسمح بنفس الرقم في سنة مالية أخرى', () async {
      await insertAdvance(number: '23');
      final otherPeriod = await db.fiscalPeriodsDao.insertPeriod(
        FiscalPeriodsCompanion.insert(
          name: '2027',
          startDate: DateTime(2027, 1, 1),
          endDate: DateTime(2027, 12, 31),
        ),
      );

      final id = await insertAdvance(number: '23', period: otherPeriod);
      expect(id, greaterThan(0), reason: 'الترقيم يُستأنف كل سنة مالية');
    });

    test('إلغاء السلفة يُحرّر رقمها لإعادة الاستعمال', () async {
      final first = await insertAdvance(number: '23');
      await (db.update(db.advances)..where((a) => a.id.equals(first)))
          .write(const AdvancesCompanion(status: Value('cancelled')));

      final second = await insertAdvance(number: '23');
      expect(second, greaterThan(0),
          reason: 'رقم سلفة ملغاة يجب ألا يبقى محجوزاً للأبد');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 4. بذور أنواع البنود
  // ═══════════════════════════════════════════════════════════════════════

  group('بذور أنواع البنود', () {
    test('البنود المطلوبة موجودة بعد الإنشاء', () async {
      final all = await db.select(db.itemTypes).get();
      final names = all.map((t) => t.name).toSet();

      // بنود مصاريف المشاريع التي طلبها المالك
      for (final expected in ['كهربائيات', 'بانزين', 'إنترنت', 'طعام']) {
        expect(names, contains(expected));
      }
      // البنود الإدارية القديمة لم تُفقَد
      for (final expected in ['راتب', 'إيجار', 'مشتريات']) {
        expect(names, contains(expected));
      }
      // بنود القبض
      expect(names, contains('رأس مال'));
    });

    test('أسماء البنود فريدة — لا تكرار', () async {
      final all = await db.select(db.itemTypes).get();
      final names = all.map((t) => t.name).toList();
      expect(names.length, equals(names.toSet().length));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 5. ⭐ القاعدة الجوهرية — المسودة لا تمسّ الأرصدة
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ أسطر المسودة لا تغيّر رصيد الخزينة إطلاقاً', () async {
    // تمويل الخزنة بـ 3 مليون (كما لو حُوِّلت من الخزنة الرئيسية)
    await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: 1,
        voucherType: 'transfer_in',
        treasuryId: treasuryId,
        fiscalPeriodId: periodId,
        amount: 3000000.0,
        currency: const Value('IQD'),
        voucherDate: DateTime(2026, 3, 1),
      ),
    );

    final before = await db.treasuriesDao.getTreasuryBalance(treasuryId);
    expect(before!.balanceIqd, equals(3000000.0));

    // مسودة بمصاريف 3.5 مليون — أكثر من الرصيد
    final advanceId = await insertAdvance(status: 'draft');
    for (var i = 0; i < 7; i++) {
      await db.into(db.advanceLines).insert(
            AdvanceLinesCompanion.insert(
              advanceId: advanceId,
              voucherDate: DateTime(2026, 3, 10),
              amount: 500000.0,
              originalAmount: 500000.0,
              originalDate: DateTime(2026, 3, 10),
              rowNumber: Value(i + 1),
            ),
          );
    }

    final after = await db.treasuriesDao.getTreasuryBalance(treasuryId);
    expect(
      after!.balanceIqd,
      equals(3000000.0),
      reason: 'المسودة ليست سندات — يجب ألا تمسّ الرصيد قبل الاعتماد. '
          'هذه هي القاعدة التي يقوم عليها التصميم كله.',
    );
  });
}
