// ─────────────────────────────────────────────────────────────────────────────
// backup_crypto_test.dart — اختبارات تشفير النسخ الاحتياطية
//
// لماذا هذا الملف؟
//   كشف تدقيق 2026-08-06 ثغرتين حرجتين في تشفير النسخ الاحتياطية، ولم يكن
//   هناك أي اختبار للتشفير إطلاقاً (كل الاختبارات الـ43 كانت لتنسيق النصوص
//   والأرقام). الاختباران الأولان أدناه كانا سيكشفان الثغرتين فوراً.
//
// ما يُختبَر هنا:
//   1. عشوائية الملح والـ IV — الثغرة الأولى (بذرة مشتقة من الساعة)
//   2. كلمات المرور العربية لا تتصادم — الثغرة الثانية (codeUnits بدل UTF-8)
//   3. دورة كاملة: تشفير ← فك تشفير ← تطابق البيانات
//   4. كلمة مرور خاطئة تفشل
//   5. ملف مُعدَّل (عبث) يفشل — تحقق علامة التوثيق
//   6. التوافق مع صيغة الملفات القديمة
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:sales_management/core/services/backup_crypto_service.dart';

void main() {
  /// بيانات تجريبية تمثّل ملف قاعدة بيانات
  final sampleData = Uint8List.fromList(
    utf8.encode('SQLite format 3 — بيانات اختبارية للخزينة ١٢٣٤٥٦٧٨٩٠' * 20),
  );

  group('عشوائية الملح والـ IV (الثغرة الأولى)', () {
    test('تشفيران متتاليان لنفس البيانات ينتجان ملحاً و IV مختلفين', () {
      const password = 'كلمة-سر-قوية-123';

      final first = BackupCryptoService.encrypt(sampleData, password);
      final second = BackupCryptoService.encrypt(sampleData, password);

      // استخراج الملح والـ IV من رأس كل ملف
      const saltStart = BackupFormat.magicLen;
      const saltEnd = saltStart + BackupFormat.saltLen;
      const ivEnd = saltEnd + BackupFormat.ivLen;

      final salt1 = first.sublist(saltStart, saltEnd);
      final salt2 = second.sublist(saltStart, saltEnd);
      final iv1 = first.sublist(saltEnd, ivEnd);
      final iv2 = second.sublist(saltEnd, ivEnd);

      // ⚠️ هذا بالضبط ما كان يفشل: البذرة المشتقة من الساعة كانت تُنتج
      // نفس الملح ونفس الـ IV لعمليتين في نفس اللحظة تقريباً.
      // تكرار الـ IV في AES-GCM يكسر السرية والتوثيق معاً.
      expect(salt1, isNot(equals(salt2)), reason: 'الملح يجب أن يختلف كل مرة');
      expect(iv1, isNot(equals(iv2)), reason: 'الـ IV يجب أن يختلف كل مرة');
    });

    test('النص المشفَّر يختلف حتى مع نفس البيانات ونفس كلمة المرور', () {
      const password = 'نفس-الكلمة';
      final first = BackupCryptoService.encrypt(sampleData, password);
      final second = BackupCryptoService.encrypt(sampleData, password);

      expect(first, isNot(equals(second)));
    });

    test('randomBytes تُنتج قيماً مختلفة ومتنوعة', () {
      final a = BackupCryptoService.randomBytes(32);
      final b = BackupCryptoService.randomBytes(32);

      expect(a.length, equals(32));
      expect(a, isNot(equals(b)));

      // البذرة القديمة كانت 8 بايتات مكرّرة 4 مرات — أي 8 قيم مميزة فقط.
      // مولّد سليم يُعطي تنوعاً أعلى بكثير في 32 بايتاً.
      final distinct = a.toSet().length;
      expect(distinct, greaterThan(10), reason: 'يجب أن تكون البايتات متنوعة');
    });
  });

  group('كلمات المرور العربية (الثغرة الثانية)', () {
    test('كلمتا مرور مختلفتان لا تفتحان نفس الملف', () {
      // 'اب' = U+0627 U+0628. مع codeUnits المقتطعة كانت تصير 0x27 0x28،
      // وهي نفس بايتات "'(" تماماً — فتفتح إحداهما ملف الأخرى.
      const arabicPassword = 'اب';
      const collidingPassword = "'(";

      final encrypted = BackupCryptoService.encrypt(sampleData, arabicPassword);

      final wrongAttempt =
          BackupCryptoService.decrypt(encrypted, collidingPassword);

      expect(
        wrongAttempt,
        isNull,
        reason: 'كلمة مرور مختلفة يجب ألا تفك التشفير أبداً',
      );
    });

    test('كلمة مرور عربية كاملة تُشفّر وتُفكّ بنجاح', () {
      const password = 'كلمة السر الخاصة بالخزينة ٢٠٢٦';

      final encrypted = BackupCryptoService.encrypt(sampleData, password);
      final decrypted = BackupCryptoService.decrypt(encrypted, password);

      expect(decrypted, isNotNull);
      expect(decrypted, equals(sampleData));
    });

    test('كلمة مرور فيها رموز تعبيرية تعمل بشكل صحيح', () {
      const password = 'خزينة🔐آمنة';

      final encrypted = BackupCryptoService.encrypt(sampleData, password);
      expect(BackupCryptoService.decrypt(encrypted, password), equals(sampleData));

      // كلمة مقاربة يجب أن تفشل
      expect(BackupCryptoService.decrypt(encrypted, 'خزينة🔓آمنة'), isNull);
    });
  });

  group('الدورة الكاملة والتحقق من السلامة', () {
    test('تشفير ثم فك تشفير يُعيد البيانات الأصلية بالضبط', () {
      const password = 'Str0ng-P@ssw0rd';

      final encrypted = BackupCryptoService.encrypt(sampleData, password);
      final decrypted = BackupCryptoService.decrypt(encrypted, password);

      expect(decrypted, equals(sampleData));
    });

    test('الملف الناتج يحمل التوقيع SMBAK2', () {
      final encrypted = BackupCryptoService.encrypt(sampleData, 'pass');
      final magic = utf8.decode(encrypted.sublist(0, BackupFormat.magicLen));

      expect(magic, equals(BackupFormat.magicV2));
    });

    test('كلمة مرور خاطئة تُعيد null ولا ترمي استثناءً', () {
      final encrypted = BackupCryptoService.encrypt(sampleData, 'correct');

      expect(BackupCryptoService.decrypt(encrypted, 'wrong'), isNull);
    });

    test('ملف مُعدَّل (عبث) يفشل بفضل علامة التوثيق', () {
      const password = 'pass';
      final encrypted = BackupCryptoService.encrypt(sampleData, password);

      // قلب بايت واحد في النص المشفَّر
      final tampered = Uint8List.fromList(encrypted);
      final target = tampered.length - 5;
      tampered[target] = tampered[target] ^ 0xFF;

      expect(
        BackupCryptoService.decrypt(tampered, password),
        isNull,
        reason: 'AES-GCM يجب أن يكشف أي تعديل على الملف',
      );
    });

    test('ملف ليس نسخة احتياطية يُعيد null', () {
      final notABackup = Uint8List.fromList(utf8.encode('hello world' * 50));

      expect(BackupCryptoService.decrypt(notABackup, 'pass'), isNull);
    });

    test('ملف مبتور يُعيد null بدلاً من التعطل', () {
      final encrypted = BackupCryptoService.encrypt(sampleData, 'pass');
      final truncated = encrypted.sublist(0, 20);

      expect(BackupCryptoService.decrypt(truncated, 'pass'), isNull);
    });
  });

  group('التوافق مع الصيغة القديمة (SMBAK1)', () {
    test('ملف قديم بكلمة مرور إنجليزية يُفتَح بالطريقة القديمة', () {
      // نبني ملفاً بصيغة SMBAK1 يدوياً كما كان يفعل الكود القديم:
      // نفس البنية لكن التوقيع SMBAK1 والمفتاح مشتق من codeUnits.
      const password = 'legacyPassword';
      final legacyFile = _buildLegacyBackup(sampleData, password);

      final decrypted = BackupCryptoService.decrypt(legacyFile, password);

      expect(
        decrypted,
        equals(sampleData),
        reason: 'النسخ الاحتياطية القديمة يجب أن تبقى قابلة للاستعادة',
      );
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// مساعد: بناء ملف بالصيغة القديمة SMBAK1 لاختبار التوافق الرجعي
// ─────────────────────────────────────────────────────────────────────────────

Uint8List _buildLegacyBackup(Uint8List plain, String password) {
  final salt = BackupCryptoService.randomBytes(BackupFormat.saltLen);
  final iv = BackupCryptoService.randomBytes(BackupFormat.ivLen);
  // المفتاح بالطريقة القديمة: codeUnits
  final key = BackupCryptoService.deriveKey(password, salt,
      legacyCodeUnits: true);

  final cipher = _gcm(key, iv, forEncryption: true);
  final out = Uint8List(cipher.getOutputSize(plain.length));
  var off = cipher.processBytes(plain, 0, plain.length, out, 0);
  off += cipher.doFinal(out, off);

  final ciphertext = out.sublist(0, off - BackupFormat.tagLen);
  final tag = out.sublist(off - BackupFormat.tagLen, off);

  final magic = Uint8List.fromList(utf8.encode(BackupFormat.magicV1));
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

pc.GCMBlockCipher _gcm(
  Uint8List key,
  Uint8List iv, {
  required bool forEncryption,
}) {
  return pc.GCMBlockCipher(pc.AESEngine())
    ..init(
      forEncryption,
      pc.AEADParameters(
        pc.KeyParameter(key),
        BackupFormat.tagLen * 8,
        iv,
        Uint8List(0),
      ),
    );
}
