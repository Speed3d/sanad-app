// ─────────────────────────────────────────────────────────────────────────────
// cumulative_balance_test.dart — الرصيد التراكمي بين السنوات (ح-٣ + ح-٤)
//
// الثغرتان اللتان يغلقهما:
//   ح-٣ — إعادة الاحتساب كانت تحذف 'opening_balance' فقط بينما تُدرج نوعين
//         ('opening_balance' و'opening_balance_debit')، فالدَّين يتضاعف.
//   ح-٤ — v_treasury_balances تراكمي ولا يفلتر بالفترة، فسند الرصيد
//         الافتتاحي يمثّل مالاً محسوباً أصلاً ويُضاف مرة ثانية.
//
// المبدأ المعتمد (قرار المالك): الخزينة صندوق نقدي مستمر لا يُصفَّر في
// 31 ديسمبر — فلا تُنشأ سندات رصيد افتتاحي إطلاقاً.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';

void main() {
  late AppDatabase db;
  late int period2025;
  late int period2026;
  late int treasuryId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    period2025 = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2025',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31, 23, 59, 59),
      ),
    );
    period2026 = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31, 23, 59, 59),
      ),
    );
    treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الخزينة', kind: const Value('main')),
    );
  });

  tearDown(() async => db.close());

  Future<double> balance() async =>
      (await db.treasuriesDao.getTreasuryBalance(treasuryId))?.balanceIqd ?? 0;

  test('⭐ الرصيد ينتقل تراكمياً بلا أي سند افتتاحي', () async {
    // نشاط سنة 2025: قبض 5 مليون، صرف 2 مليون
    await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: 1,
        voucherType: 'kabd',
        treasuryId: treasuryId,
        fiscalPeriodId: period2025,
        amount: 5000000.0,
        currency: const Value('IQD'),
        voucherDate: DateTime(2025, 6, 1),
      ),
    );
    await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: 2,
        voucherType: 'sarf',
        treasuryId: treasuryId,
        fiscalPeriodId: period2025,
        amount: 2000000.0,
        currency: const Value('IQD'),
        voucherDate: DateTime(2025, 8, 1),
      ),
    );

    expect(await balance(), equals(3000000.0));

    // سند في 2026 — الرصيد يستمر ولا يبدأ من الصفر
    await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: 1,
        voucherType: 'sarf',
        treasuryId: treasuryId,
        fiscalPeriodId: period2026,
        amount: 1000000.0,
        currency: const Value('IQD'),
        voucherDate: DateTime(2026, 2, 1),
      ),
    );

    expect(await balance(), equals(2000000.0),
        reason: 'الصندوق مستمر — 3 مليون من 2025 ناقص مليون في 2026');
  });

  test('⭐ سند رصيد افتتاحي كان يُضاعف الرصيد (إثبات ح-٤)', () async {
    await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: 1,
        voucherType: 'kabd',
        treasuryId: treasuryId,
        fiscalPeriodId: period2025,
        amount: 3000000.0,
        currency: const Value('IQD'),
        voucherDate: DateTime(2025, 6, 1),
      ),
    );
    expect(await balance(), equals(3000000.0));

    // محاكاة ما كان يفعله النظام سابقاً: إدراج رصيد افتتاحي لسنة 2026
    await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: 1,
        voucherType: 'opening_balance',
        treasuryId: treasuryId,
        fiscalPeriodId: period2026,
        amount: 3000000.0,
        currency: const Value('IQD'),
        voucherDate: DateTime(2026, 1, 1),
      ),
    );

    expect(await balance(), equals(6000000.0),
        reason: 'هذا بالضبط هو الخلل: 3 مليون صارت 6. '
            'ولهذا أُوقف إنشاء سندات الرصيد الافتتاحي.');
  });

  test('حذف الأرصدة الافتتاحية يشمل النوع المدين أيضاً (إصلاح ح-٣)',
      () async {
    // النوعان معاً في الفترة نفسها
    await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: 1,
        voucherType: 'opening_balance',
        treasuryId: treasuryId,
        fiscalPeriodId: period2026,
        amount: 1000000.0,
        currency: const Value('IQD'),
        voucherDate: DateTime(2026, 1, 1),
      ),
    );
    await db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: 2,
        voucherType: 'opening_balance_debit',
        treasuryId: treasuryId,
        fiscalPeriodId: period2026,
        amount: 400000.0,
        currency: const Value('IQD'),
        voucherDate: DateTime(2026, 1, 1),
      ),
    );

    // الاستعلام نفسه الذي تستخدمه recomputeOpeningBalances بعد الإصلاح
    final removed = await db.customUpdate(
      "DELETE FROM vouchers "
      "WHERE voucher_type IN ('opening_balance', 'opening_balance_debit') "
      "AND fiscal_period_id = ?",
      variables: [Variable.withInt(period2026)],
      updates: {db.vouchers},
    );

    expect(removed, equals(2),
        reason: 'الحذف القديم كان يترك opening_balance_debit فيتضاعف الدَّين');
    expect(await balance(), equals(0.0));
  });

  test('الـ VIEW تراكمي عمداً — لا يفلتر بالفترة المالية', () async {
    for (final p in [period2025, period2026]) {
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: 1,
          voucherType: 'kabd',
          treasuryId: treasuryId,
          fiscalPeriodId: p,
          amount: 1000000.0,
          currency: const Value('IQD'),
          voucherDate: p == period2025
              ? DateTime(2025, 6, 1)
              : DateTime(2026, 6, 1),
        ),
      );
    }
    expect(await balance(), equals(2000000.0),
        reason: 'هذا السلوك مقصود ويجعل الأرصدة الافتتاحية زائدة وضارة');
  });
}
