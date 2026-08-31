// ─────────────────────────────────────────────────────────────────────────────
// batch_a_guards_test.dart — الدفعة أ من ملاحظات المالك (2026-08-30)
//
// أربعة بنود، ثلاثة منها ثغرات وواحد عطل عرض:
//
//   ١. **الخزينة المعطَّلة**: عمود `is_active` موجود منذ البداية وله مبدّل في
//      الواجهة، **ولا يفحصه أي مسار كتابة** — فالمال يدخل خزينةً أوقفها
//      المالك بنفسه ويخرج منها. نمط ع-٠٦: حقلٌ يُكتَب ولا يُقرأ.
//
//   ٢. **حذف السند بلا كلمة مرور**: القاعدة المعتمدة منذ المرحلة ١٠ أن «كل ما
//      يُرجع مالاً خرج يُثبِت صاحبه هويّته» — وستّة مواضع أقلّ خطراً كانت
//      محروسة بينما حذفُ السند، أشيعها، بلا حارس.
//
//   ٣. **سجل التدقيق لأي مدير**: يكشف من فعل ماذا ومتى لكل مستخدم.
//
//   ٤. **جدول الـPDF معكوس**: `pw.Table` في حزمة `pdf` **لا تعرف الاتّجاه
//      إطلاقاً** (صفر إشارة إلى `Directionality` في مصدر 3.12.0)، فترتّب
//      الأعمدة من اليسار مهما كان اتّجاه الصفحة.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/auth/permissions.dart';
import 'package:sales_management/core/services/pdf_service.dart';
import 'package:sales_management/core/services/treasury_state_guard.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/voucher_repository.dart';
import 'package:sales_management/domain/models/user_model.dart';

void main() {
  late AppDatabase db;
  late VoucherRepository repo;
  late int periodId;
  late int activeId;
  late int disabledId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = VoucherRepository(db);
    periodId = await db.fiscalPeriodsDao.insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31, 23, 59, 59),
      ),
    );
    activeId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'بغداد', kind: const Value('main')),
    );
    disabledId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'البصرة', kind: const Value('main')),
    );
    // المالك أوقف الخزينة من الواجهة — وهذا كل ما كان يقع
    await db.treasuriesDao.setTreasuryActive(disabledId, isActive: false);
  });

  tearDown(() async => db.close());

  Future<int> kabd(int treasuryId, {double amount = 1000000}) =>
      repo.createVoucher(
        fiscalPeriodId: periodId,
        voucherType: 'kabd',
        treasuryId: treasuryId,
        amount: amount,
        currency: 'IQD',
        voucherDate: DateTime(2026, 3, 1),
      );

  // ══════════════════════════════════════════════════════════════════════
  group('١ — حارس الخزينة المعطَّلة', () {
    test('⭐⭐⭐ التحويل إلى خزنة معطَّلة يُرفض — بلاغ المالك', () async {
      await kabd(activeId, amount: 5000000);

      // 🔴 قبل الإصلاح كان هذا ينجح: المال يدخل خزينة أوقفها المالك بنفسه
      await expectLater(
        repo.createTransfer(
          fromTreasuryId: activeId,
          toTreasuryId: disabledId,
          amount: 1000000,
          currency: 'IQD',
          fiscalPeriodId: periodId,
          voucherDate: DateTime(2026, 3, 2),
        ),
        throwsA(isA<StateError>().having((e) => e.message, 'الرسالة',
            allOf(contains('البصرة'), contains('معطَّلة'), contains('فعّلها')))),
      );
    });

    test('⭐⭐ التحويل **من** خزنة معطَّلة يُرفض أيضاً', () async {
      // المصدر يُفحص أولاً: رسالةٌ عن وجهةٍ لم يصلها المال تُضلّل
      await expectLater(
        repo.createTransfer(
          fromTreasuryId: disabledId,
          toTreasuryId: activeId,
          amount: 500000,
          currency: 'IQD',
          fiscalPeriodId: periodId,
          voucherDate: DateTime(2026, 3, 2),
        ),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'الرسالة', contains('التحويل من'))),
      );
    });

    test('⭐⭐ القبض في خزنة معطَّلة يُرفض — لا بابَ خلفياً', () async {
      // منعُ التحويل وحده يُهجّر الخطر إلى بابٍ بلا حارس (درس ع-٣٢)
      await expectLater(
        kabd(disabledId),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'الرسالة', contains('القبض في'))),
      );
    });

    test('⭐⭐ الصرف من خزنة معطَّلة يُرفض', () async {
      await expectLater(
        repo.createVoucher(
          fiscalPeriodId: periodId,
          voucherType: 'sarf',
          treasuryId: disabledId,
          amount: 1000,
          currency: 'IQD',
          voucherDate: DateTime(2026, 3, 1),
        ),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'الرسالة', contains('الصرف من'))),
      );
    });

    test('⭐⭐ التفعيل يرفع المنع — والرسالة كانت تَعِد بذلك', () async {
      await db.treasuriesDao.setTreasuryActive(disabledId, isActive: true);
      await expectLater(kabd(disabledId), completes);
    });

    test('⭐⭐ الحذف **مسموح** على خزنة معطَّلة — تصحيح لا حركة جديدة', () async {
      final id = await kabd(activeId);
      await db.treasuriesDao.setTreasuryActive(activeId, isActive: false);

      // لولا هذا الاستثناء لصار سندٌ أُدخل بالخطأ محبوساً إلى الأبد —
      // والمالك يعطّل الخزينة عادةً **بعد** أن يكتشف الخطأ لا قبله.
      await expectLater(repo.deleteVoucher(id, deletedByUserId: 1), completes);
    });

    test('⭐ الخزينة المحذوفة تُرفض برسالة تخصّها', () async {
      await db.treasuriesDao.softDeleteTreasury(activeId);
      await expectLater(
        kabd(activeId),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'الرسالة', contains('محذوفة'))),
      );
    });

    test('⭐ خزينة غير موجودة ليست مسؤولية هذا الحارس', () async {
      // المفتاح الأجنبي يمسكها — ورميُ رسالتين لعلّة واحدة يُربك
      await expectLater(
        TreasuryStateGuard.ensureActive(db, 99999, action: 'القبض في'),
        completes,
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('٣ — سجل التدقيق لمدير النظام وحده', () {
    UserModel u(String role) => UserModel(
          id: 1,
          username: 'u',
          fullName: 'u',
          role: role,
          createdAt: DateTime(2026, 1, 1),
        );

    test('⭐⭐ المدير العادي لم يعد يراه — بلاغ المالك', () {
      // 🔴 كانت `viewAudit` مصنَّفة admin، فيرى كل مدير من دخل ومتى وماذا
      //   حذف — والرقابة تصير مكشوفة لمن يُراقَب.
      expect(u('user').can(AppPermission.viewAudit), isFalse);
      expect(u('admin').can(AppPermission.viewAudit), isFalse,
          reason: 'السجل يكشف من فعل ماذا لكل مستخدم');
      expect(u('super_admin').can(AppPermission.viewAudit), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('٤ — جداول الـPDF تُقرأ من اليمين', () {
    test('⭐⭐⭐ عكس الصفّ: العمود الأول يصير الأخير', () {
      // `pw.Table` ترتّب الأعمدة من اليسار دائماً، و`textDirection: rtl`
      // يضبط النصّ داخل الخليّة لا **ترتيب الأعمدة**.
      expect(rtlRow(const ['#', 'الاسم', 'المبلغ']),
          equals(const ['المبلغ', 'الاسم', '#']));
    });

    test('⭐⭐ عكس كل الصفوف يحفظ تقابل الأعمدة', () {
      final out = rtlRows(const [
        ['1', 'حسن', '500'],
        ['2', 'علي', '900'],
      ]);
      expect(out, equals(const [
        ['500', 'حسن', '1'],
        ['900', 'علي', '2'],
      ]));
    });

    test('⭐⭐⭐ خريطة الأعمدة تُعكس معها — وإلا حاذت العمود الخطأ', () {
      // هذا أخطر جزء: لو عُكست الصفوف ولم تُعكس خريطة العروض لخرج «الاسم»
      // بعرض عمود «التسلسل» — جدولٌ سليم البيانات مشوّه الشكل.
      expect(rtlColumnMap(const {0: 'a', 2: 'b'}, 3),
          equals(const {2: 'a', 0: 'b'}));
    });

    test('⭐ العكس مرّتين يُعيد الأصل — برهان أن العملية لا تفقد شيئاً', () {
      const original = ['أ', 'ب', 'ج', 'د'];
      expect(rtlRow(rtlRow(original)), equals(original));
    });

    test('⭐ عمود واحد أو صفر — لا انهيار على الحالات الحدّية', () {
      expect(rtlRow(const <String>[]), isEmpty);
      expect(rtlRow(const ['وحيد']), equals(const ['وحيد']));
      expect(rtlColumnMap(const {0: 'x'}, 1), equals(const {0: 'x'}));
    });
  });
}
