// ─────────────────────────────────────────────────────────────────────────────
// dashboard_currency_test.dart — الدولار على لوحة التحكم (الدفعة ج)
//
// **لماذا اختبار ودجت وقد نجح اختبار الوحدة؟**
//   لأن العطل كان **في العرض وحده**: `getDailySummary` تُعيد الدولار منذ
//   المرحلة ١٦، والقاعدة صحيحة تماماً — ولوحة التحكم لا تقرأه. وهذا بالضبط
//   الدرس د-٣: ١٨٥ اختباراً نجحت بينما الميزة معطوبة كلياً في طبقة العرض.
//
//   واختبار الوحدة هنا يُثبت أن الرقم **يصل**، وهذا الملف يُثبت أنه **يُعرَض**.
//
// ⚠️ والحالة السالبة محروسة أيضاً: شركةٌ لا تتعامل بالدولار يجب ألّا ترى
//   «$ 0.00» تحت كل بطاقة — صفرٌ دائم بلا معنى يُعلَّم القارئ تجاهلَ السطر.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/voucher_repository.dart';
import 'package:sales_management/presentation/features/dashboard/dashboard_screen.dart';
import 'package:sales_management/presentation/providers/database_provider.dart';

void main() {
  late AppDatabase db;
  late VoucherRepository repo;
  late int periodId;
  late int treasuryId;

  final year = DateTime.now().year;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = VoucherRepository(db);
    periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '$year',
        startDate: DateTime(year, 1, 1),
        endDate: DateTime(year, 12, 31, 23, 59, 59),
      ),
    );
    treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );
  });

  tearDown(() async => db.close());

  /// ضخّ إطارات حتى تُحلَّ المزوّدات — لا `pumpAndSettle`، فمؤشّر التحميل
  /// أنيميشن لا ينتهي أبداً (راجع payroll_screens_test)
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  /// تفكيك الشجرة داخل جسم الاختبار — وإلا رُصد مؤقّت Drift معلّقاً
  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  }

  Widget wrap(Widget child) => ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('ar'),
          home: Directionality(textDirection: TextDirection.rtl, child: child),
        ),
      );

  Future<void> kabd({
    required double amount,
    String currency = 'IQD',
    double rate = 1.0,
  }) async {
    final now = DateTime.now();
    await repo.createVoucher(
      fiscalPeriodId: periodId,
      voucherType: 'kabd',
      treasuryId: treasuryId,
      amount: amount,
      currency: currency,
      exchangeRate: rate,
      voucherDate: DateTime(now.year, now.month, now.day, 10),
    );
  }

  group('لوحة التحكم — كروت اليوم', () {
    testWidgets('⭐⭐⭐ قبضٌ بالدولار يظهر على الكرت لا يختفي', (tester) async {
      await kabd(amount: 500, currency: 'USD', rate: 1310);

      await tester.pumpWidget(wrap(const DashboardScreen()));
      await settle(tester);

      // 🔴 قبل الإصلاح: البطاقة تكتب «قبض اليوم: 0» و«د.ع» بلا تحفّظ —
      //   رقمٌ مطمئِن وكاذب، وخمسمئة دولار لا أثر لها في الشاشة كلّها.
      expect(find.textContaining('500.00'), findsWidgets);
      await disposeTree(tester);
    });

    testWidgets('⭐⭐ بلا دولار لا يظهر سطر «\$ 0.00» تحت البطاقات',
        (tester) async {
      await kabd(amount: 2000000);

      await tester.pumpWidget(wrap(const DashboardScreen()));
      await settle(tester);

      expect(find.textContaining('0.00'), findsNothing);
      expect(find.text('قبض اليوم'), findsOneWidget);
      await disposeTree(tester);
    });

    testWidgets('⭐ الشاشة تُبنى بلا استثناء ولا تجاوز عرض', (tester) async {
      await kabd(amount: 1000000);
      await kabd(amount: 250, currency: 'USD', rate: 1310);

      await tester.pumpWidget(wrap(const DashboardScreen()));
      await settle(tester);

      expect(tester.takeException(), isNull);
      await disposeTree(tester);
    });
  });
}
