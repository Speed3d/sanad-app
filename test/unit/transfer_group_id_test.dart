// ─────────────────────────────────────────────────────────────────────────────
// transfer_group_id_test.dart — اختبار مولّد معرّف مجموعة التحويل
//
// لماذا هذا الملف؟
//   عطّل التحويل على المتصفح بالكامل (2026-08-15) بسبب:
//     _random.nextInt(1 << 32)
//   على الويب تُمثَّل أعداد Dart كأعداد JavaScript والإزاحة البتّية ٣٢-بت،
//   فـ `1 << 32` يساوي صفراً ← RangeError: max must be in range 0 < max < 2^32
//
//   لم تكشفه أيٌّ من 152 اختباراً لأن `flutter test` يعمل على الـ VM حيث
//   `1 << 32` = 4294967296 ويعمل سليماً.
//
// 🔑 الحيلة التي تجعل هذا الاختبار يحرس **حتى على الـ VM**:
//   نتحقق أن الحدّ الأقصى **أصغر تماماً** من 2^32. فلو أعاد أحدهم
//   `1 << 32` فستكون القيمة على الـ VM = 2^32 بالضبط ← يفشل الاختبار هنا
//   قبل أن يصل الخلل إلى المتصفح.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/daos/vouchers_dao.dart';

void main() {
  /// 2^32 — الحدّ الذي يرفضه Random.nextInt
  const pow2_32 = 4294967296;

  group('حدّ المولّد العشوائي', () {
    test('⭐ الحدّ ضمن المدى الذي يقبله Random.nextInt حصراً', () {
      expect(VouchersDao.maxRandomBound, greaterThan(0),
          reason: 'صفر يرمي RangeError — وهو ما عطّل التحويل على الويب');
      expect(VouchersDao.maxRandomBound, lessThan(pow2_32),
          reason: 'يجب أن يكون أصغر تماماً من 2^32. '
              'العودة إلى `1 << 32` تُنتج 2^32 على الـ VM وصفراً على الويب — '
              'وكلاهما خطأ.');
    });

    test('الحدّ ثابت حرفي لا ناتج إزاحة بتّية', () {
      // 0xFFFFFFFF = 4294967295 — قيمة صريحة لا تتأثر باختلاف المنصات
      expect(VouchersDao.maxRandomBound, equals(0xFFFFFFFF));
    });
  });

  group('توليد المعرّف', () {
    test('يُنتج معرّفاً غير فارغ بالصيغة المتوقعة', () {
      final id = VouchersDao.generateTransferGroupId();
      expect(id, isNotEmpty);
      expect(id, startsWith('tg_'));
      expect(id.split('_'), hasLength(3),
          reason: 'الصيغة: tg_<الوقت>_<عشوائي>');
    });

    test('لا يرمي استثناءً مهما تكرّر', () {
      // الاستدعاء المتكرر يكشف أي خلل في حدود المولّد فوراً
      expect(() {
        for (var i = 0; i < 1000; i++) {
          VouchersDao.generateTransferGroupId();
        }
      }, returnsNormally);
    });

    test('المعرّفات المتتابعة مختلفة', () {
      final ids = <String>{};
      for (var i = 0; i < 200; i++) {
        ids.add(VouchersDao.generateTransferGroupId());
      }
      // الوقت بالميكروثانية + عشوائي 32-بت — التصادم شبه مستحيل
      expect(ids.length, equals(200),
          reason: 'تصادم المعرّفات يربط تحويلين مختلفين ببعضهما');
    });
  });
}
