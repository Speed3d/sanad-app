// ─────────────────────────────────────────────────────────────────────────────
// extensions_test.dart — اختبارات وحدة امتدادات التاريخ والنصوص والأرقام
//
// تعليقات توضيحية بالعربية:
// هذا الملف يحتوي على اختبارات الوحدة (Unit Tests) لـ Extensions:
//   1. DateExtensions (toDateString, isToday, startOfDay, toFileSafeString)
//   2. NumberExtensions (toIQD, roundTo, toPercentage)
//   3. StringExtensions (trimAndClean, toArabicVoucherType, toArabicRole)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/extensions/date_extensions.dart';
import 'package:sales_management/core/extensions/number_extensions.dart';
import 'package:sales_management/core/extensions/string_extensions.dart';

void main() {
  group('اختبارات الامتدادات (Extensions Tests)', () {
    // ── 1. اختبارات DateExtensions ──────────────────────────────────────────
    group('DateExtensions', () {
      test('toDateString يجب أن ينسّق التاريخ بالصيغة dd/MM/yyyy', () {
        final date = DateTime(2026, 8, 6);
        expect(date.toDateString(), equals('06/08/2026'));
      });

      test('isToday يجب أن يتعرف على تاريخ اليوم الحالي', () {
        final now = DateTime.now();
        expect(now.isToday, isTrue);
        expect(now.subtract(const Duration(days: 2)).isToday, isFalse);
      });

      test('toFileSafeString يجب أن يُعيد اسماً صالاً كاسم ملف', () {
        final date = DateTime(2026, 8, 6, 17, 30);
        expect(date.toFileSafeString(), equals('2026-08-06_17-30'));
      });

      test('startOfDay يجب أن يضبط الوقت على 00:00:00', () {
        final date = DateTime(2026, 8, 6, 15, 45, 30);
        final start = date.startOfDay;
        expect(start.hour, equals(0));
        expect(start.minute, equals(0));
        expect(start.second, equals(0));
      });
    });

    // ── 2. اختبارات NumberExtensions ────────────────────────────────────────
    group('NumberExtensions', () {
      test('toIQD يجب أن يحول الرقم إلى صيغة الدينار العراقي', () {
        expect(1500000.0.toIQD(), equals('1,500,000.000 د.ع'));
      });

      test('roundTo يجب أن يقرّب للمنازل العشرية المحددة', () {
        expect(10.12345.roundTo(2), equals(10.12));
        expect(10.12345.roundTo(3), equals(10.123));
      });

      test('toPercentage يجب أن ينسّق النسبة المئوية', () {
        expect(85.5.toPercentage(), equals('85.5%'));
      });
    });

    // ── 3. اختبارات StringExtensions ────────────────────────────────────────
    group('StringExtensions', () {
      test('trimAndClean يجب أن يزيل المسافات الزائدة', () {
        expect('  نص   طويل  '.trimAndClean(), equals('نص طويل'));
      });

      test('toArabicVoucherType يجب أن يترجم أنواع السندات للعربية', () {
        expect('sarf'.toArabicVoucherType(), equals('صرف'));
        expect('kabd'.toArabicVoucherType(), equals('قبض'));
        expect('opening_balance'.toArabicVoucherType(), equals('رصيد افتتاحي'));
      });

      test('toArabicRole يجب أن يترجم الأدوار للعربية', () {
        expect('super_admin'.toArabicRole(), equals('مدير عام'));
        expect('admin'.toArabicRole(), equals('مدير'));
        expect('user'.toArabicRole(), equals('مستخدم'));
      });

      test('isNullOrEmpty يجب أن يتعرف على النصوص الفارغة والـ null', () {
        String? nullStr;
        String? emptyStr = '';
        String? validStr = 'نص';

        expect(nullStr.isNullOrEmpty, isTrue);
        expect(emptyStr.isNullOrEmpty, isTrue);
        expect(validStr.isNullOrEmpty, isFalse);
      });
    });
  });
}
