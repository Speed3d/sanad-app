// ─────────────────────────────────────────────────────────────────────────────
// currency_formatter_test.dart — اختبارات وحدة أداة تنسيق العملات
//
// تعليقات توضيحية بالعربية:
// هذا الملف يحتوي على اختبارات الوحدة (Unit Tests) لـ [CurrencyFormatter].
// يُغطي الحالات التالية:
//   1. تنسيق الدينار العراقي (IQD)
//   2. تنسيق الدولار الأمريكي (USD)
//   3. التحليل العكسي من النص إلى double (parseAmount)
//   4. التنسيق مع الإشارة (+ / -)
//   5. مقارنة المبالغ مع هامش التسامح العشرية
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/utils/currency_formatter.dart';

void main() {
  group('اختبارات تنسيق العملات (CurrencyFormatter)', () {
    // ── 1. تنسيق الدينار العراقي (IQD) ───────────────────────────────────────
    test('formatIQD يجب أن ينسّق المبالغ مع 3 منازل عشرية ورمز العملة', () {
      expect(CurrencyFormatter.formatIQD(1500000.5), equals('1,500,000.500 د.ع'));
      expect(CurrencyFormatter.formatIQD(0), equals('0.000 د.ع'));
    });

    test('formatIQDCompact يجب أن يقدم صياغة مختصرة للأرقام الكبيرة', () {
      expect(CurrencyFormatter.formatIQDCompact(2500000), equals('2.5M د.ع'));
      expect(CurrencyFormatter.formatIQDCompact(850000), equals('850K د.ع'));
      expect(CurrencyFormatter.formatIQDCompact(500), equals('500 د.ع'));
    });

    // ── 2. تنسيق الدولار الأمريكي (USD) ──────────────────────────────────────
    test('formatUSD يجب أن ينسّق المبالغ مع منزلتين عشريتين ورمز الدولار', () {
      expect(CurrencyFormatter.formatUSD(1250.75), equals('\$1,250.75'));
      expect(CurrencyFormatter.formatUSD(100), equals('\$100.00'));
    });

    // ── 3. التحليل العكسي (parseAmount) ──────────────────────────────────────
    test('parseAmount يجب أن يستخرج القيمة الرقمية للدينار العراقي', () {
      expect(CurrencyFormatter.parseAmount('1,500,000.500 د.ع'), equals(1500000.5));
    });

    test('parseAmount يجب أن يستخرج القيمة الرقمية للدولار الأمريكي', () {
      expect(CurrencyFormatter.parseAmount('\$1,250.75'), equals(1250.75));
    });

    test('parseAmount يجب أن يُعيد null للنصوص غير الرقمية', () {
      expect(CurrencyFormatter.parseAmount('invalid text'), isNull);
    });

    test('parseAmountOrZero يجب أن يُعيد 0.0 للنصوص غير الصالحة', () {
      expect(CurrencyFormatter.parseAmountOrZero('invalid text'), equals(0.0));
      expect(CurrencyFormatter.parseAmountOrZero('500'), equals(500.0));
    });

    // ── 4. التنسيق مع الإشارة (+ / -) ───────────────────────────────────────
    test('formatWithSign يجب أن يضيف إشارة الموجب للمبالغ الواردة', () {
      expect(CurrencyFormatter.formatWithSign(1500), contains('+'));
      expect(CurrencyFormatter.formatWithSign(-1500), contains('-'));
    });

    // ── 5. مقارنة المبالغ مع التسامح العشرية ──────────────────────────────────
    test('areEqual يجب أن يقارن المبالغ بدقة ويتجاهل الفروق العشرية الصغرى', () {
      expect(CurrencyFormatter.areEqual(1000.0001, 1000.0002), isTrue);
      expect(CurrencyFormatter.areEqual(1000.0, 1005.0), isFalse);
    });
  });
}
