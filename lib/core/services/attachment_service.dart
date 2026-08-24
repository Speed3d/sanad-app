// ─────────────────────────────────────────────────────────────────────────────
// attachment_service.dart — نسخ المرفقات إلى القرص وفتحها (Schema v6)
//
// **مسؤوليتها:** كل ما يمسّ نظام الملفات. الفهرس في قاعدة البيانات مسؤولية
// `AttachmentsDao`. الفصل يجعل الفهرس قابلاً للاختبار بلا لمس القرص، ويجعل
// هذه الخدمة قابلة للاختبار بمجلد مؤقّت بلا قاعدة بيانات.
//
// ═══ القرارات ═══
//
// ١. **ننسخ الملف ولا نشير إليه في مكانه.**
//    الإشارة إلى ملف في «التنزيلات» تعني ضياع المرفق أول ما ينظّف المستخدم
//    مجلده. النسخ يجعل مجلد المرفقات مكتفياً بذاته وقابلاً للنسخ الاحتياطي.
//
// ٢. **المسار المخزَّن نسبي، والفاصل `/` دائماً.**
//    حتى على ويندوز: القاعدة قد تُفتَح على الماك، و`\` يصير هناك جزءاً من
//    اسم الملف لا فاصلاً.
//
// ٣. **بلا أي حزمة جديدة** (قرار المالك 2026-08-23).
//    الفتح عبر `Process.run('explorer', [path])` على ويندوز — وهي المنصة
//    الهدف. والبصمة عبر `SHA256Digest` من `pointycastle` الموجودة أصلاً
//    للنسخ المشفَّرة.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:typed_data';

import 'package:pointycastle/digests/sha256.dart';

/// نتيجة تجهيز مرفق للحفظ
class PreparedAttachment {
  /// المسار النسبي من الجذر — يُخزَّن في قاعدة البيانات
  final String relativePath;

  /// المسار المطلق على القرص — لا يُخزَّن، للاستعمال الفوري فقط
  final String absolutePath;

  /// اسم الملف كما سيُعرَض
  final String fileName;

  /// حجم الملف بالبايت
  final int sizeBytes;

  /// بصمة SHA-256 لمحتوى الملف
  final String sha256;

  /// نوع المحتوى المستنتَج من الامتداد
  final String mimeType;

  const PreparedAttachment({
    required this.relativePath,
    required this.absolutePath,
    required this.fileName,
    required this.sizeBytes,
    required this.sha256,
    required this.mimeType,
  });
}

/// خطأ في التعامل مع ملفات المرفقات — برسالة عربية جاهزة للعرض
class AttachmentException implements Exception {
  final String message;
  const AttachmentException(this.message);
  @override
  String toString() => message;
}

/// خدمة المرفقات
abstract final class AttachmentService {
  /// أقصى حجم مقبول للمرفق الواحد — ٥٠ ميغابايت
  ///
  /// ليس قيداً تقنياً بل حارس عملي: ملف أكبر من ذلك غالباً فيديو أو نسخة
  /// احتياطية أُرفقت بالخطأ، وسيُثقل النسخة الشاملة بلا فائدة.
  static const int maxFileBytes = 50 * 1024 * 1024;

  // ── البصمة ────────────────────────────────────────────────────────────────

  /// بصمة SHA-256 لمحتوى بايتات — نصّ سداسي عشري صغير
  ///
  /// تُستعمَل لكشف إرفاق الملف نفسه مرّتين، وللتحقق لاحقاً أن الملف على
  /// القرص لم يُستبدَل منذ إرفاقه.
  static String hashBytes(Uint8List bytes) {
    final digest = SHA256Digest().process(bytes);
    return digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // ── تنظيف الأسماء ─────────────────────────────────────────────────────────

  /// تنقية جزء من مسار ملف من الرموز التي يرفضها نظام الملفات
  ///
  /// **لماذا؟** اسم المشروع يدخل في المسار، والمالك يكتبه بحرّية. اسم مثل
  /// «مشروع البصرة/المرحلة ٢» يُنتج مجلداً متداخلاً غير مقصود، و«تقرير:نهائي»
  /// يرفضه ويندوز أصلاً فيفشل النسخ برسالة غامضة.
  ///
  /// نُبقي العربية والأرقام والمسافات والشرطات — ونستبدل ما عداها بشرطة.
  static String sanitize(String input) {
    final cleaned = input
        .trim()
        // الرموز المحرّمة في ويندوز: \ / : * ? " < > |  إضافةً لمحارف التحكّم
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '-')
        // النقاط في نهاية اسم المجلد يحذفها ويندوز صامتاً
        .replaceAll(RegExp(r'\.+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    // اسم يتكوّن من شرطات ونقاط ومسافات فقط ليس اسماً: «///» تصير «---»،
    // و«..» تبقى «..» وهي اسم مقطع خطر لو صار مقطعاً مستقلاً في المسار.
    // كلاهما يُستبدَل ببديل صريح. (كشفهما اختبار المرحلة ج.)
    if (cleaned.isEmpty || RegExp(r'^[-.\s]+$').hasMatch(cleaned)) {
      return 'بلا-اسم';
    }
    // حدّ عملي: المسار الكامل على ويندوز محدود بـ 260 محرفاً افتراضياً
    return cleaned.length > 60 ? cleaned.substring(0, 60).trim() : cleaned;
  }

  /// بناء المسار النسبي لمرفق
  ///
  /// الشكل: `<السنة>/<اسم المجلد>/<اسم الملف>`
  /// مثال: `2026/سلفة-23-مشروع البصرة/فاتورة.pdf`
  ///
  /// التنظيم بالسنة أولاً مقصود: يطابق تنظيم الملفات الورقية، ويجعل أرشفة
  /// سنة كاملة نقل مجلد واحد.
  static String buildRelativePath({
    required int year,
    required String folderName,
    required String fileName,
  }) {
    return '$year/${sanitize(folderName)}/${sanitize(fileName)}';
  }

  /// اسم مجلد سلفة مشروع
  static String advanceFolder({
    required String advanceNumber,
    required String projectName,
  }) {
    final project = projectName.trim();
    return project.isEmpty
        ? 'سلفة-$advanceNumber'
        : 'سلفة-$advanceNumber-$project';
  }

  /// اسم مجلد سند
  static String voucherFolder({
    required int voucherNumber,
    required String voucherType,
  }) {
    const labels = {
      'sarf': 'صرف',
      'kabd': 'قبض',
      'transfer_out': 'تحويل-صادر',
      'transfer_in': 'تحويل-وارد',
    };
    return 'سند-${labels[voucherType] ?? voucherType}-$voucherNumber';
  }

  // ── نوع المحتوى ───────────────────────────────────────────────────────────

  /// استنتاج نوع المحتوى من امتداد الملف
  ///
  /// قائمة قصيرة عمداً — الأنواع التي تُرفَق فعلاً في هذا النظام: فواتير
  /// PDF وصور الوصولات وجداول الإكسل.
  static String mimeFromName(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  // ── النسخ إلى القرص ───────────────────────────────────────────────────────

  /// نسخ ملف إلى مجلد المرفقات وإرجاع بياناته الجاهزة للفهرسة
  ///
  /// [root]         — جذر المرفقات من الإعدادات
  /// [sourcePath]   — الملف الذي اختاره المستخدم
  /// [year] / [folderName] — لبناء المسار النسبي
  ///
  /// **لا يلمس قاعدة البيانات.** المستدعي يُسجّل الصفّ **بعد** نجاح هذه
  /// الدالة — الترتيب المعاكس يُنتج فهرساً يشير إلى ملف غير موجود.
  ///
  /// يرمي [AttachmentException] برسالة عربية عند أي خطأ متوقَّع.
  static Future<PreparedAttachment> copyIntoStore({
    required String root,
    required String sourcePath,
    required int year,
    required String folderName,
  }) async {
    if (root.trim().isEmpty) {
      throw const AttachmentException(
        'لم يُحدَّد مجلد المرفقات بعد.\n'
        'عيّنه من: الإعدادات ← المرفقات.',
      );
    }

    final source = File(sourcePath);
    if (!await source.exists()) {
      throw AttachmentException('الملف غير موجود: $sourcePath');
    }

    final bytes = await source.readAsBytes();
    if (bytes.isEmpty) {
      throw const AttachmentException('الملف فارغ — لا شيء لإرفاقه.');
    }
    if (bytes.length > maxFileBytes) {
      final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      throw AttachmentException(
        'حجم الملف $mb ميغابايت ويتجاوز الحدّ المسموح '
        '(${maxFileBytes ~/ (1024 * 1024)} ميغابايت).',
      );
    }

    final fileName = sanitize(sourcePath.split(RegExp(r'[\\/]')).last);
    var relative = buildRelativePath(
      year: year,
      folderName: folderName,
      fileName: fileName,
    );

    // تفادي الدهس: ملف بالاسم نفسه موجود → نضيف لاحقة رقمية بدل استبداله
    var target = File(_join(root, relative));
    if (await target.exists()) {
      final dot = fileName.lastIndexOf('.');
      final base = dot > 0 ? fileName.substring(0, dot) : fileName;
      final ext = dot > 0 ? fileName.substring(dot) : '';
      var n = 2;
      while (await target.exists()) {
        relative = buildRelativePath(
          year: year,
          folderName: folderName,
          fileName: '$base-$n$ext',
        );
        target = File(_join(root, relative));
        n++;
        if (n > 999) {
          throw const AttachmentException(
            'تعذّر إيجاد اسم متاح للملف — نظّف المجلد أولاً.',
          );
        }
      }
    }

    try {
      await target.parent.create(recursive: true);
      await target.writeAsBytes(bytes, flush: true);
    } on FileSystemException catch (e) {
      throw AttachmentException(
        'تعذّر نسخ الملف إلى مجلد المرفقات.\n'
        'تحقّق أن المجلد موجود وقابل للكتابة: $root\n'
        '(${e.osError?.message ?? e.message})',
      );
    }

    return PreparedAttachment(
      relativePath: relative,
      absolutePath: target.path,
      fileName: fileName,
      sizeBytes: bytes.length,
      sha256: hashBytes(bytes),
      mimeType: mimeFromName(fileName),
    );
  }

  /// المسار المطلق لمرفق مخزَّن
  static String absolutePathOf({
    required String root,
    required String relativePath,
  }) =>
      _join(root, relativePath);

  /// هل الملف موجود فعلاً على القرص؟
  ///
  /// الفهرس قد يشير إلى ملف حذفه المستخدم يدوياً من خارج البرنامج — نعرض
  /// ذلك بوضوح بدل فتحٍ يفشل بلا تفسير.
  static Future<bool> exists({
    required String root,
    required String relativePath,
  }) {
    if (root.trim().isEmpty) return Future.value(false);
    return File(_join(root, relativePath)).exists();
  }

  /// حذف ملف مرفق من القرص — يبتلع الفشل عمداً
  ///
  /// يُستدعى **بعد** حذف الصفّ من الفهرس. لو فشل الحذف (الملف مفتوح في
  /// برنامج آخر مثلاً) فالأسوأ أن يبقى ملف معلّق لا يشير إليه شيء — وهو
  /// أهون بكثير من إفشال العملية كلها وإبقاء فهرس يشير إلى ملف محذوف.
  static Future<void> deleteFile({
    required String root,
    required String relativePath,
  }) async {
    try {
      final f = File(_join(root, relativePath));
      if (await f.exists()) await f.delete();
    } catch (_) {
      // متعمَّد — راجع التوثيق أعلاه
    }
  }

  // ── الفتح ─────────────────────────────────────────────────────────────────

  /// فتح المرفق بالتطبيق الافتراضي على ويندوز
  ///
  /// **بلا أي حزمة جديدة** (قرار المالك 2026-08-23): `explorer.exe` يفتح
  /// الملف بالتطبيق المرتبط بامتداده تماماً كالنقر المزدوج.
  ///
  /// ⚠️ `explorer` يُعيد رمز خروج **غير صفري حتى عند النجاح** — سلوك موثَّق
  /// ومعروف. لذلك لا نفحص `exitCode` إطلاقاً، بل نتحقّق من وجود الملف
  /// **قبل** الاستدعاء. فحص رمز الخروج كان سيُظهر رسالة فشل كاذبة في كل مرة.
  static Future<void> openFile({
    required String root,
    required String relativePath,
  }) async {
    final path = _join(root, relativePath);
    if (!await File(path).exists()) {
      throw AttachmentException(
        'الملف غير موجود على القرص:\n$path\n'
        'قد يكون حُذف أو نُقل من خارج البرنامج.',
      );
    }
    if (!Platform.isWindows) {
      throw const AttachmentException(
        'فتح المرفقات مدعوم على ويندوز فقط حالياً.',
      );
    }
    await Process.run('explorer', [path.replaceAll('/', r'\')]);
  }

  /// إظهار المرفق داخل مستكشف الملفات ومحدَّداً
  static Future<void> revealInExplorer({
    required String root,
    required String relativePath,
  }) async {
    if (!Platform.isWindows) return;
    final path = _join(root, relativePath).replaceAll('/', r'\');
    await Process.run('explorer', ['/select,$path']);
  }

  // ── مساعد ─────────────────────────────────────────────────────────────────

  /// ضمّ الجذر بالمسار النسبي بفاصل واحد نظيف
  static String _join(String root, String relative) {
    final r = root.trim().replaceAll(RegExp(r'[\\/]+$'), '');
    final p = relative.replaceAll(RegExp(r'^[\\/]+'), '');
    return '$r/$p';
  }
}
