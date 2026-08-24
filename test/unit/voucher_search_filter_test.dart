// ─────────────────────────────────────────────────────────────────────────────
// voucher_search_filter_test.dart — البحث الشامل ونطاقا التاريخ والمبلغ
//
// طلب المالك (2026-08-24): «يجب أن يكون هناك فلتر للبحث حول تاريخ معيّن أو
// مبلغ معيّن حتى يكون البحث شاملاً عن كل شيء».
//
// **ما كان ناقصاً:** البحث النصّي كان يمسح ثلاثة حقول فقط (رقم السند · اسم
// الشخص · السبب). فالبحث عن رقم فاتورة أو اسم مشروع أو مبلغ **لا يُرجع
// شيئاً رغم أن القيمة ظاهرة على الشاشة أمام المستخدم** — وهو أسوأ أنواع
// الفشل: البرنامج يبدو معطوباً بينما البيانات سليمة.
//
// ولا سبيل إطلاقاً لتضييق النتائج بتاريخ أو مبلغ.
//
// المنطق هنا نسخة مطابقة لما في `_VoucherTab._renderList` — يُختبَر مستقلاً
// لأن الفلترة قرار عمل لا تفصيلة عرض.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/domain/models/voucher_model.dart';

/// تطبيق الفلاتر — يطابق منطق الشاشة حرفياً
List<VoucherModel> applyFilters(
  List<VoucherModel> list, {
  String query = '',
  DateTime? fromDate,
  DateTime? toDate,
  double? minAmount,
  double? maxAmount,
}) {
  var filtered = list;

  if (query.isNotEmpty) {
    final q = query.toLowerCase().trim();
    final qDigits = q.replaceAll(RegExp(r'[^0-9.]'), '');
    filtered = filtered.where((v) {
      bool has(String? x) => (x ?? '').toLowerCase().contains(q);
      final amountMatch =
          qDigits.isNotEmpty && v.amount.toStringAsFixed(0).contains(qDigits);
      return v.voucherNumber.toString().contains(q) ||
          has(v.personName) ||
          has(v.reason) ||
          has(v.itemType) ||
          has(v.referenceNumber) ||
          has(v.projectName) ||
          has(v.invoiceNumber) ||
          has(v.spentBy) ||
          has(v.advanceNumber) ||
          amountMatch;
    }).toList();
  }

  if (fromDate != null) {
    final f = DateTime(fromDate.year, fromDate.month, fromDate.day);
    filtered = filtered.where((v) => !v.voucherDate.isBefore(f)).toList();
  }
  if (toDate != null) {
    final t =
        DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999);
    filtered = filtered.where((v) => !v.voucherDate.isAfter(t)).toList();
  }
  if (minAmount != null) {
    filtered = filtered.where((v) => v.amount >= minAmount - 0.001).toList();
  }
  if (maxAmount != null) {
    filtered = filtered.where((v) => v.amount <= maxAmount + 0.001).toList();
  }
  return filtered;
}

VoucherModel v({
  int number = 1,
  double amount = 100000,
  DateTime? date,
  String person = '',
  String reason = '',
  String itemType = '',
  String reference = '',
  String? project,
  String? invoice,
  String? spentBy,
  String? advanceNumber,
}) =>
    VoucherModel(
      id: number,
      voucherNumber: number,
      voucherType: 'sarf',
      treasuryId: 1,
      fiscalPeriodId: 1,
      amount: amount,
      currency: 'IQD',
      voucherDate: date ?? DateTime(2026, 6, 15),
      personName: person,
      reason: reason,
      itemType: itemType,
      referenceNumber: reference,
      projectName: project,
      invoiceNumber: invoice,
      spentBy: spentBy,
      advanceNumber: advanceNumber,
    );

void main() {
  // ═══════════════════════════════════════════════════════════════════════
  // البحث النصّي الشامل
  // ═══════════════════════════════════════════════════════════════════════

  group('البحث النصّي', () {
    test('⭐ يشمل الحقول التي كانت خارج البحث', () {
      final list = [
        v(number: 1, project: 'مشروع البصرة'),
        v(number: 2, invoice: 'INV-118'),
        v(number: 3, spentBy: 'أحمد الجبوري'),
        v(number: 4, itemType: 'بانزين'),
        v(number: 5, advanceNumber: '23'),
        v(number: 6, reference: 'CHK-900'),
        v(number: 7, person: 'لا شيء'),
      ];

      for (final entry in {
        'البصرة': 1,
        'inv-118': 2,
        'الجبوري': 3,
        'بانزين': 4,
        'CHK-900': 6,
      }.entries) {
        final r = applyFilters(list, query: entry.key);
        expect(r, hasLength(1), reason: 'البحث عن «${entry.key}»');
        expect(r.first.voucherNumber, entry.value,
            reason: 'البحث عن «${entry.key}»');
      }
    });

    test('⭐ البحث بالمبلغ يعمل — كان مستحيلاً', () {
      final list = [
        v(number: 1, amount: 250000),
        v(number: 2, amount: 999),
      ];
      expect(applyFilters(list, query: '250000').single.voucherNumber, 1);
    });

    test('البحث بالمبلغ يتجاهل الفواصل التي يكتبها المستخدم', () {
      final list = [v(number: 1, amount: 1500000)];
      // المستخدم يرى «1,500,000» على الشاشة فيكتبها بفواصلها
      expect(applyFilters(list, query: '1,500,000'), hasLength(1));
    });

    test('البحث لا يفرّق بين حالة الأحرف الإنجليزية', () {
      final list = [v(number: 1, invoice: 'INV-118')];
      expect(applyFilters(list, query: 'inv'), hasLength(1));
      expect(applyFilters(list, query: 'INV'), hasLength(1));
    });

    test('الحقول الفارغة أو null لا تُسقط البحث', () {
      final list = [v(number: 1)];
      expect(applyFilters(list, query: 'شيء غير موجود'), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // نطاق التاريخ
  // ═══════════════════════════════════════════════════════════════════════

  group('نطاق التاريخ', () {
    final list = [
      v(number: 1, date: DateTime(2026, 5, 31, 23, 0)),
      v(number: 2, date: DateTime(2026, 6, 1, 0, 30)),
      v(number: 3, date: DateTime(2026, 6, 15, 12, 0)),
      v(number: 4, date: DateTime(2026, 6, 30, 22, 45)),
      v(number: 5, date: DateTime(2026, 7, 1, 1, 0)),
    ];

    test('⭐ الطرفان شاملان — سندات اليوم الأول والأخير تدخل', () {
      final r = applyFilters(
        list,
        fromDate: DateTime(2026, 6, 1),
        toDate: DateTime(2026, 6, 30),
      );
      expect(r.map((x) => x.voucherNumber), [2, 3, 4],
          reason: 'سند الساعة 00:30 وسند الساعة 22:45 داخل النطاق');
    });

    test('«من» وحدها تعني كل ما بعد التاريخ', () {
      final r = applyFilters(list, fromDate: DateTime(2026, 6, 30));
      expect(r.map((x) => x.voucherNumber), [4, 5]);
    });

    test('«إلى» وحدها تعني كل ما قبل التاريخ', () {
      final r = applyFilters(list, toDate: DateTime(2026, 6, 1));
      expect(r.map((x) => x.voucherNumber), [1, 2]);
    });

    test('يوم واحد: من وإلى بالتاريخ نفسه', () {
      final r = applyFilters(
        list,
        fromDate: DateTime(2026, 6, 15),
        toDate: DateTime(2026, 6, 15),
      );
      expect(r.map((x) => x.voucherNumber), [3]);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // نطاق المبلغ
  // ═══════════════════════════════════════════════════════════════════════

  group('نطاق المبلغ', () {
    final list = [
      v(number: 1, amount: 50000),
      v(number: 2, amount: 100000),
      v(number: 3, amount: 500000),
      v(number: 4, amount: 1000000),
    ];

    test('⭐ النطاق يشمل الحدّين', () {
      final r = applyFilters(list, minAmount: 100000, maxAmount: 500000);
      expect(r.map((x) => x.voucherNumber), [2, 3]);
    });

    test('حدّ أدنى وحده', () {
      expect(
        applyFilters(list, minAmount: 500000).map((x) => x.voucherNumber),
        [3, 4],
      );
    });

    test('حدّ أعلى وحده', () {
      expect(
        applyFilters(list, maxAmount: 100000).map((x) => x.voucherNumber),
        [1, 2],
      );
    });

    test('مبلغ واحد بالضبط: الحدّان متساويان', () {
      expect(
        applyFilters(list, minAmount: 500000, maxAmount: 500000)
            .map((x) => x.voucherNumber),
        [3],
      );
    });

    test('⭐ هامش التقريب يحمي المطابقة على الحدّ', () {
      final odd = [v(number: 9, amount: 333333.33)];
      expect(applyFilters(odd, minAmount: 333333.33), hasLength(1));
      expect(applyFilters(odd, maxAmount: 333333.33), hasLength(1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // التركيب
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ الفلاتر تتراكم لا تتنافس', () {
    final list = [
      v(number: 1, amount: 200000, date: DateTime(2026, 6, 10), project: 'البصرة'),
      v(number: 2, amount: 900000, date: DateTime(2026, 6, 10), project: 'البصرة'),
      v(number: 3, amount: 200000, date: DateTime(2026, 8, 10), project: 'البصرة'),
      v(number: 4, amount: 200000, date: DateTime(2026, 6, 10), project: 'كربلاء'),
    ];
    final r = applyFilters(
      list,
      query: 'البصرة',
      fromDate: DateTime(2026, 6, 1),
      toDate: DateTime(2026, 6, 30),
      maxAmount: 500000,
    );
    expect(r.map((x) => x.voucherNumber), [1]);
  });

  test('بلا أي فلتر تُعاد القائمة كما هي', () {
    final list = [v(number: 1), v(number: 2)];
    expect(applyFilters(list), hasLength(2));
  });
}
