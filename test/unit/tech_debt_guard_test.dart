// ─────────────────────────────────────────────────────────────────────────────
// tech_debt_guard_test.dart — حارس الدين التقني (المرحلة د)
//
// **لماذا يُختبَر الكود بدل السلوك هنا؟**
//   الدين التقني لا يُفشل أي اختبار سلوك — البرنامج يعمل تماماً وفيه ٨٤٠
//   سطراً مكرّراً و١٦٤ شرط ثيم. لهذا **يعود دائماً** بعد كل تنظيف: لا شيء
//   يمنع عودته.
//
//   هذه الاختبارات تفحص **المصدر نفسه**، فتجعل التراجع مرئياً فوراً بدل أن
//   يُكتشَف في تدقيق بعد سنة.
//
// نفس فلسفة `dialog_controller_lifecycle_test.dart` الذي يحرس نمطاً لا سلوكاً.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// كل ملفات Dart المكتوبة يدوياً (بلا المولَّدة)
List<File> _sourceFiles() {
  return Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) =>
          f.path.endsWith('.dart') &&
          !f.path.endsWith('.g.dart') &&
          !f.path.endsWith('.freezed.dart'))
      .toList();
}

String _read(String path) => File(path).readAsStringSync();

void main() {
  // ═══════════════════════════════════════════════════════════════════════
  // ١. الكود الميت
  // ═══════════════════════════════════════════════════════════════════════

  group('الكود الميت', () {
    test('⭐ AppException محذوف — كان يكرّر نمط StateError القائم', () {
      // حُذف بقرار المالك 2026-08-24. المشروع يستعمل StateError برسالة
      // عربية كاملة تعرضها الواجهة — نمط يعمل وموثَّق ولا يحتاج بديلاً.
      expect(File('lib/core/errors/app_exception.dart').existsSync(), isFalse,
          reason: 'إعادته تعني نمطين متوازيين لمعالجة الأخطاء');
    });

    test('⭐ InputValidators مستعمَل فعلاً لا مجرّد موجود', () {
      final users = _sourceFiles()
          .where((f) => !f.path.contains('input_validators'))
          .where((f) => _read(f.path).contains('InputValidators.'))
          .toList();

      expect(users, isNotEmpty,
          reason: 'أداة مكتوبة لا يستعملها أحد = أداة غير موجودة.\n'
              'وُصلت في المرحلة د — لا تُعِدها إلى الموت.');
    });

    test('المجلدات الفارغة محذوفة', () {
      for (final d in [
        'lib/presentation/widgets/forms',
        'lib/domain/usecases',
        'lib/data/database/migrations',
      ]) {
        expect(Directory(d).existsSync(), isFalse,
            reason: 'مجلد فارغ يوحي ببنية غير موجودة: $d');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٢. ألوان الثيم
  // ═══════════════════════════════════════════════════════════════════════

  group('لوحة الثيم', () {
    /// الشروط المتبقّية المسموح بها — حالات مشروعة لا تُختصَر بلوحة:
    /// شفافيات مختلفة لكل وضع · أيقونات · منطق غير لوني
    const allowed = 40;

    test('⭐ شروط isDark لا تتجاوز الحدّ المتّفق عليه', () {
      var total = 0;
      final worst = <String, int>{};
      for (final f in _sourceFiles()) {
        // ملفا الثيم يبنيان اللوحة فيُستثنيان
        if (f.path.contains('app_theme')) continue;
        final n = 'isDark ?'.allMatches(_read(f.path)).length;
        if (n > 0) {
          total += n;
          worst[f.path] = n;
        }
      }
      expect(total, lessThanOrEqualTo(allowed),
          reason: 'كانت ١٦٤ قبل المرحلة د واستُبدل منها ١٤٠ بـ AppPalette.\n'
              'استعمل `context.colors.x` بدل شرط جديد.\nالتوزيع: $worst');
    });

    test('AppPalette مسجَّل في الثيم وإلا لم تصل الألوان لأي شاشة', () {
      expect(_read('lib/core/theme/app_theme.dart'), contains('AppPalette'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٣. التكرار بين شاشتَي السند
  // ═══════════════════════════════════════════════════════════════════════

  group('مكوّنات نموذج السند', () {
    test('⭐ الشاشتان تستعملان الودجتات المشتركة', () {
      for (final p in [
        'lib/presentation/features/vouchers/voucher_sarf_screen.dart',
        'lib/presentation/features/vouchers/voucher_kabd_screen.dart',
      ]) {
        expect(_read(p), contains('voucher_form_widgets.dart'),
            reason: 'نسخة خاصة من الودجتات في $p تُعيد التكرار.\n'
                'كان بين الشاشتين ٨٤٠ سطراً متطابقاً قبل المرحلة د.');
      }
    });

    test('⭐ لا نسخ خاصة من الودجتات المشتركة', () {
      // أسماء الأصناف التي كانت مكرّرة باسمين مختلفين
      const banned = [
        '_KabdSectionLabel',
        '_KabdTreasuryDropdown',
        '_KabdActionButtons',
        '_KabdAmountCurrencyRow',
        '_KabdDateField',
        '_KabdFiscalBanner',
        '_KabdExchangeRateHint',
        '_KabdKindDot',
      ];
      for (final f in _sourceFiles()) {
        final src = _read(f.path);
        for (final name in banned) {
          expect(src.contains('class $name'), isFalse,
              reason: 'عاد التكرار: $name في ${f.path}');
        }
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٤. حجم الملفات
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ لا ملف مصدر يتجاوز ١٢٠٠ سطر', () {
    // employees_screen كان ٢٤٨٩ سطراً — أكبر ملف بفارق كبير — فقُسِّم
    // بـ part إلى ثلاثة. الحدّ يمنع عودة ملف عملاق آخر بصمت.
    final big = <String, int>{};
    for (final f in _sourceFiles()) {
      final n = _read(f.path).split('\n').length;
      if (n > 1200) big[f.path] = n;
    }
    expect(big, isEmpty,
        reason: 'ملفات تجاوزت الحدّ — قسّمها بـ part كما في '
            'employees_screen.dart:\n$big');
  });
}
