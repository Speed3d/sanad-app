// ─────────────────────────────────────────────────────────────────────────────
// attachment_service_test.dart — نسخ المرفقات وتنقية المسارات (المرحلة ج)
//
// أخطر ما في هذه الخدمة ليس النسخ بل **بناء المسار**: اسم المشروع يكتبه
// المالك بحرّية ويدخل مباشرةً في مسار على القرص. اسم مثل «مشروع/البصرة»
// يُنتج مجلداً متداخلاً غير مقصود، و«تقرير:نهائي» يرفضه ويندوز أصلاً فيفشل
// النسخ برسالة غامضة — أو الأسوأ، يُكتب الملف في مكان غير متوقَّع.
//
// ولهذا معظم الاختبارات هنا على `sanitize` و`buildRelativePath`.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/services/attachment_service.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('sanad_attach');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  /// إنشاء ملف مصدر للاختبار
  Future<String> makeSource(String name, {int size = 100}) async {
    final f = File('${root.path}/src_$name');
    await f.writeAsBytes(List<int>.generate(size, (i) => i % 256));
    return f.path;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // تنقية الأسماء — حيث يكمن الخطر الحقيقي
  // ═══════════════════════════════════════════════════════════════════════

  group('تنقية أجزاء المسار', () {
    test('⭐ الشرطة المائلة لا تُنتج مجلداً متداخلاً', () {
      // «مشروع/البصرة» كان سيُنشئ مجلد «مشروع» وداخله «البصرة»
      expect(AttachmentService.sanitize('مشروع/البصرة'), 'مشروع-البصرة');
      expect(AttachmentService.sanitize(r'مشروع\البصرة'), 'مشروع-البصرة');
    });

    test('⭐ الرموز التي يرفضها ويندوز تُستبدَل', () {
      // \ / : * ? " < > |
      expect(AttachmentService.sanitize('تقرير:نهائي'), 'تقرير-نهائي');
      expect(AttachmentService.sanitize('ملف*مهم?'), 'ملف-مهم-');
      expect(AttachmentService.sanitize('a<b>c|d"e'), 'a-b-c-d-e');
    });

    test('⭐ الصعود بالمسار (..) لا يخرج من مجلد المرفقات', () {
      // لولا التنقية لكتب «../../secret» ملفاً خارج الجذر تماماً
      final p = AttachmentService.buildRelativePath(
        year: 2026,
        folderName: '../../خارج',
        fileName: 'x.pdf',
      );
      // الخطر ليس وجود النقطتين نصّاً بل كونهما **مقطعاً مستقلاً** في
      // المسار — عندها فقط يصعد نظام الملفات مستوىً للأعلى
      final segments = p.split('/');
      expect(segments, isNot(contains('..')), reason: p);
      expect(segments, isNot(contains('.')), reason: p);
      expect(segments.every((s) => s.isNotEmpty), isTrue, reason: p);
    });

    test('النقاط في النهاية تُحذف — ويندوز يحذفها صامتاً', () {
      expect(AttachmentService.sanitize('مجلد...'), 'مجلد');
    });

    test('المسافات المتعدّدة تُضغَط والأطراف تُقصّ', () {
      expect(AttachmentService.sanitize('  مشروع    البصرة  '),
          'مشروع البصرة');
    });

    test('الاسم الفارغ يُعطي بديلاً لا سلسلة فارغة', () {
      // مجلد باسم فارغ يعني مساراً بشرطتين متتاليتين — سلوك غير معرَّف
      expect(AttachmentService.sanitize(''), 'بلا-اسم');
      expect(AttachmentService.sanitize('///'), 'بلا-اسم');
    });

    test('الأسماء الطويلة تُقصّ — حدّ المسار على ويندوز ٢٦٠ محرفاً', () {
      final long = 'م' * 200;
      expect(AttachmentService.sanitize(long).length, lessThanOrEqualTo(60));
    });

    test('العربية والأرقام والشرطات تبقى كما هي', () {
      expect(AttachmentService.sanitize('سلفة-23-مشروع البصرة'),
          'سلفة-23-مشروع البصرة');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // بناء المسار النسبي
  // ═══════════════════════════════════════════════════════════════════════

  group('المسار النسبي', () {
    test('⭐ الفاصل «/» دائماً — القاعدة قد تُفتَح على الماك', () {
      final p = AttachmentService.buildRelativePath(
        year: 2026,
        folderName: 'سلفة-23',
        fileName: 'فاتورة.pdf',
      );
      expect(p, '2026/سلفة-23/فاتورة.pdf');
      expect(p.contains(r'\'), isFalse,
          reason: r'فاصل ويندوز \ يصير على الماك جزءاً من الاسم لا فاصلاً');
    });

    test('اسم مجلد السلفة يحمل الرقم والمشروع', () {
      expect(
        AttachmentService.advanceFolder(
            advanceNumber: '23', projectName: 'مشروع البصرة'),
        'سلفة-23-مشروع البصرة',
      );
    });

    test('سلفة بلا اسم مشروع لا تُنتج شرطة معلّقة', () {
      expect(
        AttachmentService.advanceFolder(advanceNumber: '23', projectName: '  '),
        'سلفة-23',
      );
    });

    test('اسم مجلد السند يترجم نوعه للعربية', () {
      expect(
        AttachmentService.voucherFolder(voucherNumber: 7, voucherType: 'sarf'),
        'سند-صرف-7',
      );
      expect(
        AttachmentService.voucherFolder(voucherNumber: 3, voucherType: 'kabd'),
        'سند-قبض-3',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // البصمة
  // ═══════════════════════════════════════════════════════════════════════

  group('البصمة', () {
    test('⭐ المحتوى نفسه يُعطي البصمة نفسها', () {
      final a = AttachmentService.hashBytes(Uint8List.fromList([1, 2, 3]));
      final b = AttachmentService.hashBytes(Uint8List.fromList([1, 2, 3]));
      expect(a, equals(b));
      expect(a.length, 64, reason: 'SHA-256 = ٦٤ محرفاً سداسياً عشرياً');
    });

    test('اختلاف بايت واحد يغيّر البصمة', () {
      final a = AttachmentService.hashBytes(Uint8List.fromList([1, 2, 3]));
      final b = AttachmentService.hashBytes(Uint8List.fromList([1, 2, 4]));
      expect(a, isNot(equals(b)));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // النسخ الفعلي
  // ═══════════════════════════════════════════════════════════════════════

  group('النسخ إلى مجلد المرفقات', () {
    test('⭐ الملف يُنسَخ ويُنشَأ المجلد تلقائياً', () async {
      final src = await makeSource('a.pdf', size: 512);
      final r = await AttachmentService.copyIntoStore(
        root: root.path,
        sourcePath: src,
        year: 2026,
        folderName: 'سلفة-23-البصرة',
      );

      expect(File(r.absolutePath).existsSync(), isTrue);
      expect(r.sizeBytes, 512);
      expect(r.mimeType, 'application/pdf');
      expect(r.relativePath, startsWith('2026/سلفة-23-البصرة/'));
    });

    test('⭐ الأصل يبقى مكانه — ننسخ ولا ننقل', () async {
      final src = await makeSource('b.pdf');
      await AttachmentService.copyIntoStore(
        root: root.path,
        sourcePath: src,
        year: 2026,
        folderName: 'س',
      );
      expect(File(src).existsSync(), isTrue,
          reason: 'نقل ملف المستخدم من مكانه تصرّف عدواني');
    });

    test('⭐ ملف بالاسم نفسه لا يدهس السابق', () async {
      final src = await makeSource('c.pdf');
      final first = await AttachmentService.copyIntoStore(
        root: root.path, sourcePath: src, year: 2026, folderName: 'س');
      final second = await AttachmentService.copyIntoStore(
        root: root.path, sourcePath: src, year: 2026, folderName: 'س');

      expect(first.relativePath, isNot(equals(second.relativePath)));
      expect(File(first.absolutePath).existsSync(), isTrue,
          reason: 'الدهس يمحو فاتورة سند آخر بلا إنذار');
      expect(File(second.absolutePath).existsSync(), isTrue);
    });

    test('جذر غير محدَّد يُعطي رسالة عربية واضحة', () async {
      final src = await makeSource('d.pdf');
      await expectLater(
        AttachmentService.copyIntoStore(
            root: '  ', sourcePath: src, year: 2026, folderName: 'س'),
        throwsA(isA<AttachmentException>()),
      );
    });

    test('ملف غير موجود يُعطي خطأً واضحاً', () async {
      await expectLater(
        AttachmentService.copyIntoStore(
          root: root.path,
          sourcePath: '${root.path}/لا-يوجد.pdf',
          year: 2026,
          folderName: 'س',
        ),
        throwsA(isA<AttachmentException>()),
      );
    });

    test('الملف الفارغ يُرفَض', () async {
      final f = File('${root.path}/empty.pdf')..writeAsBytesSync([]);
      await expectLater(
        AttachmentService.copyIntoStore(
            root: root.path, sourcePath: f.path, year: 2026, folderName: 'س'),
        throwsA(isA<AttachmentException>()),
      );
    });

    test('⭐ الملف الأكبر من الحدّ يُرفَض برسالة تذكر الحجم', () async {
      final big = File('${root.path}/big.bin');
      await big.writeAsBytes(
          Uint8List(AttachmentService.maxFileBytes + 1024));
      await expectLater(
        AttachmentService.copyIntoStore(
            root: root.path, sourcePath: big.path, year: 2026, folderName: 'س'),
        throwsA(
          isA<AttachmentException>().having(
            (e) => e.message,
            'الرسالة',
            contains('ميغابايت'),
          ),
        ),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الوجود والحذف
  // ═══════════════════════════════════════════════════════════════════════

  group('الوجود والحذف', () {
    test('exists يميّز الموجود من المفقود', () async {
      final src = await makeSource('e.pdf');
      final r = await AttachmentService.copyIntoStore(
          root: root.path, sourcePath: src, year: 2026, folderName: 'س');

      expect(
        await AttachmentService.exists(
            root: root.path, relativePath: r.relativePath),
        isTrue,
      );
      expect(
        await AttachmentService.exists(
            root: root.path, relativePath: '2026/س/وهمي.pdf'),
        isFalse,
      );
    });

    test('⭐ حذف ملف مفقود لا يرمي — الفهرس أهمّ من الملف', () async {
      // لو رمى، لتعذّر حذف مرفق حُذف ملفه يدوياً من خارج البرنامج،
      // فيبقى صفّه في الفهرس إلى الأبد
      await AttachmentService.deleteFile(
          root: root.path, relativePath: '2026/س/وهمي.pdf');
      expect(true, isTrue);
    });

    test('الحذف يمحو الملف فعلاً', () async {
      final src = await makeSource('f.pdf');
      final r = await AttachmentService.copyIntoStore(
          root: root.path, sourcePath: src, year: 2026, folderName: 'س');

      await AttachmentService.deleteFile(
          root: root.path, relativePath: r.relativePath);
      expect(File(r.absolutePath).existsSync(), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // نوع المحتوى
  // ═══════════════════════════════════════════════════════════════════════

  test('نوع المحتوى يُستنتَج من الامتداد', () {
    expect(AttachmentService.mimeFromName('a.PDF'), 'application/pdf');
    expect(AttachmentService.mimeFromName('b.jpg'), 'image/jpeg');
    expect(AttachmentService.mimeFromName('c.png'), 'image/png');
    expect(AttachmentService.mimeFromName('d.xyz'),
        'application/octet-stream');
  });
}
