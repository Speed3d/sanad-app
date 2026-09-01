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

  // ═══════════════════════════════════════════════════════════════════════
  // ٥. قراءة المزوّدات غير المتزامنة (ع-٣٥)
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐⭐ لا `ref.read(provider.future)` — يُسقط التطبيق بسباق تخلّص', () {
    // 🔴 **بلاغ المالك 2026-08-27:** أسقط التطبيقَ حذفُ خزينة بالاستثناء
    //   «disposed during loading state, yet no value could be emitted».
    //
    //   المزوّدات المولَّدة كلها `autoDispose`، و`ref.read` لا يضيف مستمعاً —
    //   فيُنشَأ المزوّد ويبدأ استعلامه ثم يُتخلَّص منه قبل وصول الجواب.
    //   **وهو سباق**: ينجح حين يسبق الاستعلامُ دورةَ التخلّص. فمرّ من كل
    //   الاختبارات وظهر عند المالك وحده.
    //
    //   البديل: `ref.readOnce(p, p.future)` في `provider_read_once.dart`،
    //   أو القراءة من المستودع/الـDAO مباشرةً حين يكون الاستعلام لمرّة واحدة.
    final offenders = <String>[];
    final pattern = RegExp(r'ref\s*\.\s*read\s*\([^;]*\.future\s*\)');

    for (final f in _sourceFiles()) {
      // ملف الأداة نفسه يذكر النمط في توثيقه
      if (f.path.contains('provider_read_once')) continue;
      for (final line in _read(f.path).split('\n')) {
        final trimmed = line.trimLeft();
        // التعليقات تشرح العطل ولا تُنتجه
        if (trimmed.startsWith('//')) continue;
        if (pattern.hasMatch(line)) {
          offenders.add('${f.path}: ${line.trim()}');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'كانت ١٢ موضعاً قبل ع-٣٥ — كلها قنابل موقوتة.\n'
            'استعمل `ref.readOnce(p, p.future)` بدلاً منها.\n'
            '${offenders.join('\n')}');
  });

  test('⭐⭐ لا قراءة متزامنة لمزوّد غير مُراقَب — تُعيد null بصمت (ع-٤١ · ع-٤٢)',
      () {
    // 🔴 **عطلان كُشفا في 2026-08-30، وكلاهما صامت تماماً:**
    //
    //   ع-٤١: النسخة الاحتياطية الشاملة كانت تقرأ `attachmentsRootProvider`
    //         بـ`ref.read(...).valueOrNull` وهي لا تراقبه ⇒ الجذر `''` دائماً
    //         ⇒ **صفر مرفق يُنسَخ**، والرسالة تقول «تمّت النسخة الشاملة».
    //   ع-٤٢: زرّ طباعة السند كان يقرأ `pdfCompanyHeaderProvider` كذلك ⇒
    //         **كل سند يُطبع بلا شعار ولا اسم شركة**، وميزة المرحلة ب-٣
    //         معطَّلة كلياً بلا أن يشتكي أحد.
    //
    // **السبب الواحد:** المزوّدات المولَّدة بـ`@riverpod` كلها `autoDispose`.
    //   فحين لا يراقبها أحد، `ref.read` يُنشئ المزوّد ويُطلق استعلامه ويُعيد
    //   `AsyncLoading` **في اللحظة نفسها** ⇒ `valueOrNull == null` دائماً، ثم
    //   يُتلَف المزوّد فتكرّر الضغطةُ التاليةُ الشيءَ نفسه إلى الأبد.
    //
    // ⚠️ **ولماذا هذا أخطر من ع-٣٥؟** ذاك كان يُسقط التطبيق فيُبلَّغ عنه،
    //   وهذا يُعيد `null` بصمت فيعيش شهوراً. القراءةُ الصامتة الخاطئة أسوأ
    //   من الانهيار الصريح.
    //
    // **القاعدة المفروضة هنا:** القراءة المتزامنة مسموحة **فقط** إن كان
    //   المزوّد نفسه مُراقَباً بـ`ref.watch` في **المكتبة نفسها** (الملف مع
    //   أجزائه) — عندئذٍ يكون محمَّلاً فعلاً ويكون `read` قراءةً للقيمة
    //   الحاضرة لا إنشاءً لمزوّد جديد. وإلا فاستعمل `ref.readOnce` أو اقرأ
    //   من الـDAO مباشرةً.
    final offenders = <String>[];

    // `ref.read(xProvider).valueOrNull` / `.value` / `.requireValue`
    final pattern = RegExp(
        r'ref\s*\.\s*read\s*\(\s*([a-zA-Z0-9_]+Provider)[^)]*\)\s*\.\s*'
        r'(valueOrNull|value|requireValue)\b');

    // ── جمع مصادر كل مكتبة: الملف + أجزاؤه ──────────────────────────────
    // البحث في الملف وحده يكذب: `vouchers_list_widgets.dart` جزءٌ من
    // `vouchers_list_screen.dart`، والمراقبة قد تقع في أيّهما.
    final files = _sourceFiles().where((f) => f.path.contains('presentation'));
    final libraryOf = <String, List<String>>{};
    for (final f in files) {
      final src = _read(f.path);
      final partOf = RegExp(r"""part\s+of\s+['"]([^'"]+)['"]""").firstMatch(src);
      final root = partOf == null
          ? f.path
          : '${f.parent.path}${Platform.pathSeparator}${partOf.group(1)}';
      libraryOf.putIfAbsent(root, () => []).add(f.path);
      if (partOf != null) libraryOf[root]!.add(root);
    }
    String librarySource(String path) {
      for (final entry in libraryOf.entries) {
        if (entry.value.contains(path)) {
          return entry.value.toSet().map((p) {
            final file = File(p);
            return file.existsSync() ? _read(p) : '';
          }).join('\n');
        }
      }
      return _read(path);
    }

    for (final f in files) {
      final lines = _read(f.path).split('\n');
      String? libSrc;
      for (final line in lines) {
        if (line.trimLeft().startsWith('//')) continue; // التعليقات تشرح لا تُنتج
        final m = pattern.firstMatch(line);
        if (m == null) continue;
        final provider = m.group(1)!;
        libSrc ??= librarySource(f.path);
        // نصوص خام مضمومة لا نصّاً مُستوفياً: `'...\s...$provider'` يبتلع
        // الشرطات المائلة فيصير النمط `refs*.s*watch` ولا يطابق شيئاً.
        final watched = RegExp(r'ref\s*\.\s*watch\s*\(\s*' + provider + r'\b')
            .hasMatch(libSrc);
        if (!watched) {
          offenders.add('${f.path}: $provider — يُقرأ ولا يُراقَب\n'
              '    ${line.trim()}');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'قراءة متزامنة لمزوّد autoDispose غير مُراقَب تُعيد null '
            'دائماً — وبصمت.\n'
            'استعمل `ref.readOnce(p, p.future)` أو اقرأ من الـDAO مباشرةً:\n'
            '${offenders.join('\n')}');
  });

  test('⭐⭐ لا `pw.Font.ttf` مباشرةً — تُسقط حروفاً عربية (ع-٥٢)', () {
    // جدول `basicToIsolatedMappings` في حزمة `pdf` يُسنِد رسم **ي** إلى رمز
    // **ى** المنفصلة، ولا يُسنِد رسماً لـ **ي** المنفصلة إطلاقاً. فالنتيجة
    // أن «أخرى» تُطبع «أخري»، وأن اسماً مثل «هادي» يُطبع بلا يائه.
    //
    // `ArabicPdfFont` تُصلح الخريطة بعد بناء الخطّ — ومن يستعمل
    // `pw.Font.ttf` مباشرةً يلتفّ حول الإصلاح ويُعيد العطل بصمت.
    final offenders = <String>[];
    for (final f in _sourceFiles()) {
      final src = _read(f.path);
      if (!src.contains('Font.ttf(')) continue;
      // الاستثناء الوحيد: الملف الذي يُعرَّف فيه البديل ويشرح السبب
      if (f.path.endsWith('pdf_service.dart')) continue;
      offenders.add(f.path);
    }
    expect(offenders, isEmpty,
        reason: 'استعمل `ArabicPdfFont(data)` بدل `pw.Font.ttf(data)`:\n'
            '${offenders.join('\n')}');
  });

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
