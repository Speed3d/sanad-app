// ─────────────────────────────────────────────────────────────────────────────
// display_format_test.dart — التوقيت المحلي وتنسيق المبالغ (بلاغات 2026-08-24)
//
// عطلان أبلغ عنهما المالك، كلاهما في **العرض** لا في الحساب — ولهذا لم
// يكشفهما أي اختبار سابق: الأرقام المخزَّنة كانت صحيحة تماماً طوال الوقت.
//
//   ١. **التوقيت:** سند أُدخل الساعة ١:٣٠ ظهراً بتوقيت بغداد كان يُعرَض
//      ١٠:٣٠ — ناقص ثلاث ساعات بالضبط. السبب أن `created_at` يُملأ بـ
//      `CURRENT_TIMESTAMP` من SQLite وهي **UTC**، ويقرأها Drift بعلامة
//      `isUtc = true`، فتُنسَّق كما هي بلا تحويل.
//
//   ٢. **التنسيق:** الدينار كان يُعرَض `1,000.000` بثلاث منازل عشرية
//      أصفار دائمة — الدينار العراقي بلا فلوس متداوَلة.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/extensions/date_extensions.dart';
import 'package:sales_management/core/utils/currency_formatter.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════
  // التوقيت
  // ═══════════════════════════════════════════════════════════════════════

  group('التوقيت المحلي', () {
    test('⭐ التاريخ المخزَّن UTC يُعرَض بتوقيت الجهاز', () {
      // لحظة واحدة بتمثيلين — يجب أن تُعرَض متطابقة
      final utc = DateTime.utc(2026, 8, 24, 10, 30);
      final local = utc.toLocal();

      expect(utc.toTimeString(), local.toTimeString(),
          reason: 'عرض UTC كما هو يُنقص ساعات المنطقة الزمنية.\n'
              'ببغداد (UTC+3) كان ١:٣٠ ظهراً يظهر ١٠:٣٠');
    });

    test('⭐ التاريخ المحلي أصلاً لا يتأثّر', () {
      // `voucher_date` يُكتب من Dart بتوقيت محلي — التحويل يجب ألّا يزيحه
      final local = DateTime(2026, 8, 24, 13, 30);
      expect(local.toTimeString(), '13:30');
      expect(local.toDateTimeString(), '24/08/2026 13:30');
    });

    test('التاريخ فقط يتبع التوقيت المحلي أيضاً', () {
      // لحظة UTC قد تقع في يوم مختلف عن اليوم المحلي قرب منتصف الليل
      final utc = DateTime.utc(2026, 8, 24, 22, 0);
      expect(utc.toDateString(), utc.toLocal().toDateString());
    });

    test('التنسيق الكامل مع الثواني يتبع التوقيت المحلي', () {
      final utc = DateTime.utc(2026, 8, 24, 10, 30, 45);
      expect(utc.toFullDateTimeString(),
          utc.toLocal().toFullDateTimeString());
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // تنسيق المبالغ
  // ═══════════════════════════════════════════════════════════════════════

  group('تنسيق المبالغ', () {
    test('⭐ الدينار بلا كسور — كان 1,000.000', () {
      expect(CurrencyFormatter.formatIQD(1000), '1,000 د.ع');
      expect(CurrencyFormatter.formatIQD(1500000), '1,500,000 د.ع');
    });

    test('⭐ الدولار يبقى بكسرين — السنت متداوَل', () {
      expect(CurrencyFormatter.formatUSD(100.5), contains('100.50'));
      expect(CurrencyFormatter.formatUSD(1250.75), contains('1,250.75'));
    });

    test('فاصل الآلاف موجود في الأرقام الكبيرة', () {
      expect(CurrencyFormatter.formatIQD(12345678), '12,345,678 د.ع');
    });

    test('الصفر يُعرَض صفراً لا فارغاً', () {
      expect(CurrencyFormatter.formatIQD(0), '0 د.ع');
    });

    test('⭐ التقريب للعرض فقط — القيمة المخزَّنة لا تتغيّر', () {
      // المبلغ يبقى double كامل الدقة؛ التنسيق لا يمسّه
      const amount = 1000.4;
      expect(CurrencyFormatter.formatIQD(amount), '1,000 د.ع');
      expect(amount, 1000.4, reason: 'الحساب يجري على القيمة لا على النصّ');
    });

    test('المبلغ السالب يحتفظ بإشارته', () {
      expect(CurrencyFormatter.formatIQD(-500000), contains('500,000'));
      expect(CurrencyFormatter.formatIQD(-500000), startsWith('-'));
    });
  });
}
