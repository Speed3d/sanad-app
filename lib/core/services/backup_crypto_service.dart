// ─────────────────────────────────────────────────────────────────────────────
// backup_crypto_service.dart — خدمة تشفير وفك تشفير النسخ الاحتياطية
//
// الغرض:
//   عزل منطق التشفير عن شاشة الواجهة ليصبح قابلاً للاختبار والمراجعة،
//   وقابلاً للتشغيل داخل Isolate منفصل (دوال static) دون تجميد الواجهة.
//
// الخوارزمية:
//   التشفير:        AES-256-GCM (تشفير + توثيق في آن واحد)
//   اشتقاق المفتاح: PBKDF2-HMAC-SHA256 — 100,000 تكرار — مفتاح 32 بايت
//   العشوائية:      Random.secure() — مولّد نظام التشغيل المؤمَّن
//
// صيغة الملف:
//   magic(7) + salt(16) + iv(12) + tag(16) + ciphertext
//
// ═══════════════════════════════════════════════════════════════════════════
// ⚠️ ثغرتان حرجتان أُصلحتا هنا (تدقيق 2026-08-06) — لا تُعِد كتابتهما:
// ═══════════════════════════════════════════════════════════════════════════
//
// 1) العشوائية كانت مشتقة من الساعة:
//      SecureRandom('Fortuna')..seed(... microsecondsSinceEpoch >> (i % 8) ...)
//    البذرة "32 بايت" كانت في الحقيقة 8 بايتات مكرّرة أربع مرات، وكلها من
//    البتات 0–14 للساعة فقط → 32,768 احتمالاً كحد أقصى (≈15 بت)، ووقت
//    التصدير مكتوب في اسم الملف نفسه!
//    الأثر: الملح (salt) متوقّع فتنهار حماية PBKDF2، والأخطر أن الـ IV
//    يتكرر — وفي AES-GCM تكرار الـ nonce مع نفس المفتاح يكسر السرية
//    والتوثيق معاً (تسريب XOR للنصوص + إمكانية تزوير الملف).
//    الحل: Random.secure() الذي يقرأ من مولّد نظام التشغيل مباشرةً.
//
// 2) اشتقاق المفتاح كان يستخدم codeUnits بدل UTF-8:
//      pbkdf2.process(Uint8List.fromList(password.codeUnits))
//    codeUnits تُعيد وحدات UTF-16، و Uint8List.fromList تقتطع كلاً منها إلى
//    8 بتات دنيا. فالحرف 'ا' (U+0627) يصير 0x27، و 'ب' (U+0628) يصير 0x28.
//    الأثر: كل الحروف العربية تنهار على 256 قيمة، فكلمات مرور مختلفة
//    تُنتج نفس المفتاح — كلمة السر "اب" تفتح النسخة كما يفتحها "'(".
//    الحل: utf8.encode(password) وهو الترميز القياسي.
//
// التوافق مع النسخ القديمة:
//   الملفات القديمة تحمل التوقيع SMBAK1 وتُفكّ بالطريقة القديمة (codeUnits)
//   حتى لا يفقد المستخدم نسخه السابقة. الملفات الجديدة تُكتب بـ SMBAK2.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart' as pc;

/// ثوابت صيغة ملف النسخة الاحتياطية
class BackupFormat {
  /// التوقيع الحالي — يستخدم UTF-8 في اشتقاق المفتاح
  static const magicV2 = 'SMBAK2\n'; // 7 bytes

  /// التوقيع القديم — يستخدم codeUnits (للقراءة فقط، لا يُكتب بعد الآن)
  static const magicV1 = 'SMBAK1\n'; // 7 bytes

  static const magicLen = 7;
  static const saltLen = 16;
  static const ivLen = 12;
  static const tagLen = 16;
  static const keyLen = 32; // AES-256
  static const pbkdfIterations = 100000;
}

/// خدمة تشفير النسخ الاحتياطية
///
/// كل الدوال static حتى يمكن تمريرها لـ compute() وتشغيلها في Isolate
/// منفصل دون تجميد واجهة المستخدم.
class BackupCryptoService {
  const BackupCryptoService._();

  // ── توليد البايتات العشوائية ────────────────────────────────────────────

  /// توليد بايتات عشوائية آمنة تشفيرياً
  ///
  /// يعتمد على `Random.secure()` الذي يقرأ من مولّد نظام التشغيل
  /// (CryptGenRandom على ويندوز، /dev/urandom على لينكس وأندرويد).
  ///
  /// [length] — عدد البايتات المطلوبة
  static Uint8List randomBytes(int length) {
    final rng = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      // nextInt(256) يُعطي المدى الكامل 0..255 لبايت واحد
      bytes[i] = rng.nextInt(256);
    }
    return bytes;
  }

  // ── اشتقاق المفتاح ──────────────────────────────────────────────────────

  /// اشتقاق مفتاح AES-256 من كلمة المرور بـ PBKDF2-HMAC-SHA256
  ///
  /// [password] — كلمة المرور النصية كما أدخلها المستخدم
  /// [salt] — الملح العشوائي (16 بايت) المخزَّن في رأس الملف
  /// [legacyCodeUnits] — true فقط عند فك ملف قديم بصيغة SMBAK1
  ///
  /// يُعيد: مفتاحاً بطول 32 بايت
  static Uint8List deriveKey(
    String password,
    Uint8List salt, {
    bool legacyCodeUnits = false,
  }) {
    final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64))
      ..init(
        pc.Pbkdf2Parameters(
          salt,
          BackupFormat.pbkdfIterations,
          BackupFormat.keyLen,
        ),
      );

    // الترميز الصحيح هو UTF-8. الفرع القديم موجود فقط لفتح ملفات SMBAK1.
    final passwordBytes = legacyCodeUnits
        ? Uint8List.fromList(password.codeUnits)
        : Uint8List.fromList(utf8.encode(password));

    return pbkdf2.process(passwordBytes);
  }

  // ── التشفير ─────────────────────────────────────────────────────────────

  /// تشفير البيانات بـ AES-256-GCM وإنتاج ملف نسخة احتياطية كامل
  ///
  /// [plain] — البيانات الأصلية (ملف قاعدة البيانات)
  /// [password] — كلمة المرور التي سيحتاجها المستخدم للاستعادة
  ///
  /// يُعيد: البايتات الجاهزة للكتابة على القرص بصيغة SMBAK2
  static Uint8List encrypt(Uint8List plain, String password) {
    // ملح و IV جديدان تماماً لكل عملية تشفير — أساس أمان GCM
    final salt = randomBytes(BackupFormat.saltLen);
    final iv = randomBytes(BackupFormat.ivLen);
    final key = deriveKey(password, salt);

    final cipher = pc.GCMBlockCipher(pc.AESEngine())
      ..init(
        true, // true = تشفير
        pc.AEADParameters(
          pc.KeyParameter(key),
          BackupFormat.tagLen * 8, // طول علامة التوثيق بالبِتّات (128)
          iv,
          Uint8List(0), // لا بيانات إضافية موثَّقة (AAD)
        ),
      );

    final out = Uint8List(cipher.getOutputSize(plain.length));
    var off = cipher.processBytes(plain, 0, plain.length, out, 0);
    off += cipher.doFinal(out, off);

    // مخرجات GCM = النص المشفَّر متبوعاً بعلامة التوثيق (16 بايت)
    final ciphertext = out.sublist(0, off - BackupFormat.tagLen);
    final tag = out.sublist(off - BackupFormat.tagLen, off);

    // ── تجميع الملف: magic + salt + iv + tag + ciphertext ────────────────
    final magic = Uint8List.fromList(utf8.encode(BackupFormat.magicV2));
    final result = Uint8List(
      magic.length +
          BackupFormat.saltLen +
          BackupFormat.ivLen +
          BackupFormat.tagLen +
          ciphertext.length,
    );
    var pos = 0;
    result.setRange(pos, pos += magic.length, magic);
    result.setRange(pos, pos += BackupFormat.saltLen, salt);
    result.setRange(pos, pos += BackupFormat.ivLen, iv);
    result.setRange(pos, pos += BackupFormat.tagLen, tag);
    result.setRange(pos, pos + ciphertext.length, ciphertext);
    return result;
  }

  // ── فك التشفير ──────────────────────────────────────────────────────────

  /// فك تشفير ملف نسخة احتياطية
  ///
  /// يدعم الصيغتين: SMBAK2 (الحالية) و SMBAK1 (القديمة).
  ///
  /// [data] — بايتات الملف كاملةً
  /// [password] — كلمة المرور التي أدخلها المستخدم
  ///
  /// يُعيد: البيانات الأصلية، أو **null** إذا كانت كلمة المرور خاطئة
  /// أو الملف تالفاً أو مُعدَّلاً (تحقق علامة التوثيق يفشل).
  static Uint8List? decrypt(Uint8List data, String password) {
    try {
      // ── 1. التحقق من التوقيع وتحديد الإصدار ──────────────────────────
      final isLegacy = _matchesMagic(data, BackupFormat.magicV1);
      final isCurrent = _matchesMagic(data, BackupFormat.magicV2);
      if (!isLegacy && !isCurrent) return null; // ليس ملف نسخة احتياطية

      const minLen = BackupFormat.magicLen +
          BackupFormat.saltLen +
          BackupFormat.ivLen +
          BackupFormat.tagLen;
      if (data.length < minLen) return null; // ملف مبتور

      // ── 2. تفكيك رأس الملف ────────────────────────────────────────────
      var pos = BackupFormat.magicLen;
      final salt = data.sublist(pos, pos += BackupFormat.saltLen);
      final iv = data.sublist(pos, pos += BackupFormat.ivLen);
      final tag = data.sublist(pos, pos += BackupFormat.tagLen);
      final ciphertext = data.sublist(pos);

      // الملفات القديمة تحتاج طريقة الاشتقاق القديمة لتُفتح
      final key = deriveKey(password, salt, legacyCodeUnits: isLegacy);

      // ── 3. فك التشفير — GCM يتوقع النص المشفَّر متبوعاً بالعلامة ──────
      final combined = Uint8List(ciphertext.length + BackupFormat.tagLen)
        ..setRange(0, ciphertext.length, ciphertext)
        ..setRange(
          ciphertext.length,
          ciphertext.length + BackupFormat.tagLen,
          tag,
        );

      final cipher = pc.GCMBlockCipher(pc.AESEngine())
        ..init(
          false, // false = فك تشفير
          pc.AEADParameters(
            pc.KeyParameter(key),
            BackupFormat.tagLen * 8,
            iv,
            Uint8List(0),
          ),
        );

      final plain = Uint8List(cipher.getOutputSize(combined.length));
      var off = cipher.processBytes(combined, 0, combined.length, plain, 0);
      // doFinal يتحقق من علامة التوثيق ويرمي استثناءً إذا لم تُطابق —
      // وهذا ما يجعل الملف المُعدَّل أو كلمة المرور الخاطئة تفشل هنا
      off += cipher.doFinal(plain, off);
      return plain.sublist(0, off);
    } catch (_) {
      // كلمة مرور خاطئة أو ملف تالف/مُعدَّل
      return null;
    }
  }

  /// مطابقة توقيع الملف مع توقيع متوقّع
  static bool _matchesMagic(Uint8List data, String magic) {
    final expected = utf8.encode(magic);
    if (data.length < expected.length) return false;
    for (var i = 0; i < expected.length; i++) {
      if (data[i] != expected[i]) return false;
    }
    return true;
  }
}
