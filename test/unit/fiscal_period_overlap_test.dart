// ─────────────────────────────────────────────────────────────────────────────
// fiscal_period_overlap_test.dart — قاعدة عدم تقاطع الفترات المالية
//
// العطل الذي يمنع عودته (بلاغ المالك 2026-08-23):
//   مع وجود فترة 2026، رُفض إنشاء 2025 و2027 برسالة «يتداخل نطاق التواريخ».
//
//   السبب — [fiscal_providers.dart] سابقاً:
//     startDate.isBefore(p.endDate.add(const Duration(days: 1))) &&
//     endDate.isAfter(p.startDate.subtract(const Duration(days: 1)))
//
//   الإزاحة بيوم كامل كان القصد منها تحويل `<` الصارمة إلى `<=`، لكنها
//   تُزيح الحدّ ٨٦٬٤٠٠ ثانية لا لحظة واحدة. فصار حدّ التقاطع مع فترة 2026:
//     • من الأعلى: 2027-01-01 23:59:59 → ترفض سنة 2027 كاملة
//     • من الأسفل: 2025-12-31 00:00:00 → ترفض سنة 2025 كاملة
//   النتيجة: **كل سنة مجاورة مرفوضة**، ولا يُقبل إلا ما بَعُد سنتين.
//
// لماذا لم يكشفه أيٌّ من ١٨٥ اختباراً؟
//   لأن القاعدة كانت تعيش في طبقة العرض وحدها، وكل الاختبارات تستدعي
//   `insertPeriod` مباشرةً فلا تمرّ بها إطلاقاً. نُقلت القاعدة إلى
//   `FiscalPeriodsDao.insertPeriod` — فصار كل اختبار يُنشئ فترةً يمرّ بها.
//   هذا هو الدرس البنيوي: **حارس لا يمرّ به اختبار ليس حارساً.**
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // الفترة المرجعية — نفس ما كان في قاعدة بيانات المالك بالضبط
    await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31, 23, 59, 59),
      ),
    );
  });

  tearDown(() async => db.close());

  /// محاولة إنشاء سنة كاملة — تُعيد رسالة الرفض أو null عند النجاح
  Future<String?> tryYear(int year) async {
    try {
      await db.fiscalPeriodsDao.insertPeriod(
        FiscalPeriodsCompanion.insert(
          name: '$year',
          startDate: DateTime(year, 1, 1),
          endDate: DateTime(year, 12, 31, 23, 59, 59),
        ),
      );
      return null;
    } on StateError catch (e) {
      return e.message;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // الحدود — هنا كان العطل بالضبط
  // ═══════════════════════════════════════════════════════════════════════

  group('السنوات المجاورة تُقبل', () {
    test('⭐ السنة التالية مباشرة (2027) تُقبل', () async {
      expect(await tryYear(2027), isNull,
          reason: 'تبدأ 2027-01-01 بعد نهاية 2026 بثانية — لا تقاطع');
    });

    test('⭐ السنة السابقة مباشرة (2025) تُقبل', () async {
      expect(await tryYear(2025), isNull,
          reason: 'تنتهي 2025-12-31 قبل بداية 2026 بثانية — لا تقاطع');
    });

    test('سنة بعيدة (2028) تُقبل', () async {
      expect(await tryYear(2028), isNull);
    });

    test('السنتان المجاورتان معاً تُقبلان — فتصير ثلاث سنوات متتالية', () async {
      expect(await tryYear(2025), isNull);
      expect(await tryYear(2027), isNull);
      final all = await db.fiscalPeriodsDao.watchAllPeriods().first;
      expect(all.map((p) => p.name).toList()..sort(),
          ['2025', '2026', '2027']);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // التقاطع الحقيقي يُرفض — القاعدة لم تُلغَ، صُحّحت فقط
  // ═══════════════════════════════════════════════════════════════════════

  group('التقاطع الحقيقي يُرفض', () {
    test('نفس السنة تماماً تُرفض', () async {
      expect(await tryYear(2026), contains('2026'));
    });

    test('تقاطع جزئي (نصف سنة) يُرفض', () async {
      final err = await _tryRange(
        db,
        name: 'منتصف',
        start: DateTime(2026, 7, 1),
        end: DateTime(2027, 6, 30),
      );
      expect(err, isNotNull);
    });

    test('فترة تبتلع الفترة القائمة تُرفض', () async {
      final err = await _tryRange(
        db,
        name: 'عقد',
        start: DateTime(2020, 1, 1),
        end: DateTime(2030, 12, 31),
      );
      expect(err, isNotNull);
    });

    test('فترة داخل الفترة القائمة تُرفض', () async {
      final err = await _tryRange(
        db,
        name: 'ربع',
        start: DateTime(2026, 4, 1),
        end: DateTime(2026, 6, 30),
      );
      expect(err, isNotNull);
    });

    test('التماس بثانية واحدة يُرفض (التقاطع شامل للحدّين)', () async {
      // تبدأ في نفس لحظة نهاية 2026 بالضبط
      final err = await _tryRange(
        db,
        name: 'ملامسة',
        start: DateTime(2026, 12, 31, 23, 59, 59),
        end: DateTime(2027, 6, 30),
      );
      expect(err, isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الرسالة تسمّي الفترة المانعة — كان المالك يجرّب سنةً بعد سنة بلا دليل
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ رسالة الرفض تذكر اسم الفترة المتقاطعة وتاريخيها', () async {
    final err = await tryYear(2026);
    expect(err, isNotNull);
    expect(err, contains('2026'), reason: 'اسم الفترة المانعة');
    expect(err, contains('2026/01/01'), reason: 'تاريخ بدايتها');
    expect(err, contains('2026/12/31'), reason: 'تاريخ نهايتها');
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الفترة المُقفَلة تمنع التقاطع أيضاً — قرار المالك 2026-08-23
  // ═══════════════════════════════════════════════════════════════════════

  test('الفترة المُقفَلة تمنع التقاطع مثل النشطة', () async {
    final all = await db.fiscalPeriodsDao.watchAllPeriods().first;
    await db.fiscalPeriodsDao.closePeriod(all.first.id, 1);

    expect(await tryYear(2026), isNotNull,
        reason: 'فترتان تدّعيان نفس التواريخ تجعلان التقارير غامضة');
    expect(await tryYear(2027), isNull,
        reason: 'لكن السنة التالية تبقى مقبولة — الإقفال ليس عائقاً');
  });

  // ═══════════════════════════════════════════════════════════════════════
  // نطاق مقلوب
  // ═══════════════════════════════════════════════════════════════════════

  test('نهاية قبل البداية تُرفض', () async {
    final err = await _tryRange(
      db,
      name: 'مقلوبة',
      start: DateTime(2030, 12, 31),
      end: DateTime(2030, 1, 1),
    );
    expect(err, contains('النهاية'));
  });
}

/// محاولة إنشاء فترة بنطاق حرّ — تُعيد رسالة الرفض أو null
Future<String?> _tryRange(
  AppDatabase db, {
  required String name,
  required DateTime start,
  required DateTime end,
}) async {
  try {
    await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: name,
        startDate: start,
        endDate: end,
      ),
    );
    return null;
  } on StateError catch (e) {
    return e.message;
  }
}
