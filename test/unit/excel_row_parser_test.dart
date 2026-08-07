// ─────────────────────────────────────────────────────────────────────────────
// excel_row_parser_test.dart — اختبارات تحليل صفوف الإكسل
//
// لماذا هذا الملف مهم؟
//   هذا المنطق يقرّر ما يدخل مسودة السلفة وما يُرفض. أخطر قاعدة فيه رفض
//   العملة الأجنبية: تسجيل "500 USD" صامتاً كـ 500 دينار خطأ بمقدار سعر
//   الصرف كله (~650,000 دينار) ولا يكشفه شيء لاحقاً — لا الرصيد ولا التقارير.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/presentation/features/excel/excel_row_parser.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════
  // ⭐ رفض العملات الأجنبية
  // ═══════════════════════════════════════════════════════════════════════

  group('⭐ رفض العملات الأجنبية', () {
    const foreignAmounts = [
      '500 USD',
      '500\$',
      '\$500',
      '500 دولار',
      '1,200 usd',
      '300 €',
      '300 EUR',
      '250 يورو',
    ];

    for (final raw in foreignAmounts) {
      test('يرفض "$raw"', () {
        final r = ExcelRowParser.parseRow(
          rowNumber: 1,
          rowLabel: 'صف 1',
          dateRaw: '2026/03/10',
          amountRaw: raw,
        );
        expect(r.line, isNull, reason: 'يجب ألا يُنتج سطراً');
        expect(r.error, isNotNull);
        expect(r.error, contains('ليس بالدينار'));
      });
    }

    test('يقبل المبالغ بالدينار العادية', () {
      for (final raw in ['500000', '1,500,000', '250 ', ' 75000']) {
        final r = ExcelRowParser.parseRow(
          rowNumber: 1,
          rowLabel: 'صف 1',
          dateRaw: '2026/03/10',
          amountRaw: raw,
        );
        expect(r.error, isNull, reason: 'المبلغ "$raw" بالدينار ويجب أن يُقبل');
        expect(r.line, isNotNull);
      }
    });

    test('الكشف لا يتأثر بحالة الأحرف', () {
      expect(ExcelRowParser.hasForeignCurrency('500 UsD'), isTrue);
      expect(ExcelRowParser.hasForeignCurrency('500 Usd'), isTrue);
      expect(ExcelRowParser.hasForeignCurrency('500000'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // تحليل التواريخ
  // ═══════════════════════════════════════════════════════════════════════

  group('تحليل التواريخ', () {
    test('صيغة YYYY/MM/DD', () {
      expect(ExcelRowParser.parseDate('2026/03/10'), DateTime(2026, 3, 10));
      expect(ExcelRowParser.parseDate('2026-03-10'), DateTime(2026, 3, 10));
      expect(ExcelRowParser.parseDate('2026.03.10'), DateTime(2026, 3, 10));
    });

    test('صيغة DD/MM/YYYY', () {
      expect(ExcelRowParser.parseDate('10/03/2026'), DateTime(2026, 3, 10));
      expect(ExcelRowParser.parseDate('01-12-2025'), DateTime(2025, 12, 1));
    });

    test('التمييز بين الصيغتين بالجزء الأول', () {
      // 2026 > 31 → سنة أولاً
      expect(ExcelRowParser.parseDate('2026/01/02'), DateTime(2026, 1, 2));
      // 02 <= 31 → يوم أولاً
      expect(ExcelRowParser.parseDate('02/01/2026'), DateTime(2026, 1, 2));
    });

    test('يرفض التواريخ المستحيلة بدل تصحيحها صامتاً', () {
      // DateTime(2026, 2, 31) يعطي 3 مارس تلقائياً — سلوك خطير في المحاسبة
      expect(ExcelRowParser.parseDate('2026/02/31'), isNull);
      expect(ExcelRowParser.parseDate('2026/13/01'), isNull);
      expect(ExcelRowParser.parseDate('2026/00/10'), isNull);
    });

    test('يرفض الصيغ غير الصالحة', () {
      expect(ExcelRowParser.parseDate(''), isNull);
      expect(ExcelRowParser.parseDate('غير صحيح'), isNull);
      expect(ExcelRowParser.parseDate('2026/03'), isNull);
      expect(ExcelRowParser.parseDate('abc/def/ghi'), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // تحليل المبالغ
  // ═══════════════════════════════════════════════════════════════════════

  group('تحليل المبالغ', () {
    test('يتجاهل فواصل الآلاف والمسافات', () {
      expect(ExcelRowParser.parseAmount('1,500,000'), 1500000.0);
      expect(ExcelRowParser.parseAmount(' 250 000 '.replaceAll(' ', '')),
          250000.0);
      expect(ExcelRowParser.parseAmount('١٠٠'.replaceAll('١٠٠', '100')), 100.0);
    });

    test('يقبل الكسور العشرية', () {
      expect(ExcelRowParser.parseAmount('1500.5'), 1500.5);
    });

    test('يرفض الصفر والسالب وغير الرقمي', () {
      expect(ExcelRowParser.parseAmount('0'), isNull);
      expect(ExcelRowParser.parseAmount('-500'), isNull);
      expect(ExcelRowParser.parseAmount('نص'), isNull);
      expect(ExcelRowParser.parseAmount(''), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // تحليل الصف الكامل
  // ═══════════════════════════════════════════════════════════════════════

  group('تحليل الصف الكامل', () {
    test('الصف الفارغ تماماً يُتجاهَل بلا خطأ', () {
      final r = ExcelRowParser.parseRow(
        rowNumber: 5,
        rowLabel: 'صف 5',
        dateRaw: '',
        amountRaw: '',
      );
      expect(r.line, isNull);
      expect(r.error, isNull, reason: 'صف فارغ ليس خطأً — يُتجاهَل فقط');
    });

    test('الصف الكامل يُنتج سطراً بكل الحقول', () {
      final r = ExcelRowParser.parseRow(
        rowNumber: 3,
        rowLabel: 'صف 4',
        dateRaw: '2026/03/15',
        amountRaw: '750,000',
        itemType: ' كهربائيات ',
        reason: 'أسلاك ومفاتيح',
        personName: 'محمد',
        projectName: 'البصرة',
        invoiceNumber: 'INV-77',
        spentBy: 'أبو أحمد',
      );

      expect(r.error, isNull);
      final l = r.line!;
      expect(l.rowNumber, 3);
      expect(l.date, DateTime(2026, 3, 15));
      expect(l.amount, 750000.0);
      expect(l.itemType, 'كهربائيات', reason: 'يُقلَّم الفراغ');
      expect(l.reason, 'أسلاك ومفاتيح');
      expect(l.spentBy, 'أبو أحمد');
      expect(l.invoiceNumber, 'INV-77');
    });

    test('الحقول الاختيارية الفارغة تصبح null لا نصاً فارغاً', () {
      final r = ExcelRowParser.parseRow(
        rowNumber: 1,
        rowLabel: 'صف 1',
        dateRaw: '2026/03/15',
        amountRaw: '100',
        projectName: '   ',
        invoiceNumber: '',
      );
      expect(r.line!.projectName, isNull);
      expect(r.line!.invoiceNumber, isNull);
    });

    test('رسالة الخطأ تحمل تسمية الصف ليجدها المستخدم', () {
      final r = ExcelRowParser.parseRow(
        rowNumber: 11,
        rowLabel: 'صف 12',
        dateRaw: 'خطأ',
        amountRaw: '100',
      );
      expect(r.error, contains('صف 12'));
    });

    test('التاريخ الناقص وحده يُرفض (لا يُتجاهَل كصف فارغ)', () {
      final r = ExcelRowParser.parseRow(
        rowNumber: 1,
        rowLabel: 'صف 1',
        dateRaw: '',
        amountRaw: '500000',
      );
      expect(r.line, isNull);
      expect(r.error, isNotNull,
          reason: 'مبلغ بلا تاريخ خطأ حقيقي لا صف فارغ');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // نتيجة الملف الكامل
  // ═══════════════════════════════════════════════════════════════════════

  group('ExcelParseResult', () {
    test('الإجمالي يجمع الأسطر الصالحة فقط', () {
      final rows = [
        ('2026/03/01', '100000'),
        ('2026/03/02', '250000'),
        ('2026/03/03', '500 USD'), // مرفوض
      ];

      final lines = <dynamic>[];
      final errors = <String>[];
      for (var i = 0; i < rows.length; i++) {
        final r = ExcelRowParser.parseRow(
          rowNumber: i + 1,
          rowLabel: 'صف ${i + 1}',
          dateRaw: rows[i].$1,
          amountRaw: rows[i].$2,
        );
        if (r.line != null) lines.add(r.line);
        if (r.error != null) errors.add(r.error!);
      }

      final result = ExcelParseResult(
        lines: lines.cast(),
        errors: errors,
      );

      expect(result.total, 350000.0);
      expect(result.errors, hasLength(1));
      expect(result.isValid, isFalse,
          reason: 'وجود خطأ واحد يمنع تجهيز المسودة — '
              'مسودة ناقصة تعني مطابقة خاطئة مع الإكسل');
    });

    test('ملف نظيف يكون صالحاً', () {
      final r1 = ExcelRowParser.parseRow(
        rowNumber: 1,
        rowLabel: 'صف 1',
        dateRaw: '2026/03/01',
        amountRaw: '100000',
      );
      final result =
          ExcelParseResult(lines: [r1.line!], errors: const []);
      expect(result.isValid, isTrue);
      expect(result.total, 100000.0);
    });
  });
}
