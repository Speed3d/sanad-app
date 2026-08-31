// ─────────────────────────────────────────────────────────────────────────────
// fiscal_permissions_test.dart — صلاحيات الفترة المالية والملخّص اليومي
//
// ═══ ما يحرسه هذا الملف (المرحلة ١٦ — 2026-08-30) ═══
//
// ١. **خرق القانون ٤ في الفترات المالية:** كانت `closePeriod` و
//    `reopenPeriod` و`recomputeOpeningBalances` و`deletePeriod` **لا تفحص
//    أي صلاحية إطلاقاً**؛ تكتفي بأن أحداً مسجَّل الدخول، و`reopenPeriod`
//    لا تفحص حتى ذلك (تكتب `_currentUserId ?? 0` في سجل التدقيق).
//
//    والحماية الوحيدة كانت **إخفاء الأزرار** في `fiscal_period_card.dart`.
//    وحارسٌ في طبقة العرض يتجاوزه أي مستدعٍ آخر — شاشةٌ جديدة أو اختصار أو
//    إعادة استعمال — بلا أن يشتكي شيء.
//
//    والأسوأ أن الصلاحيات الأربع كانت **مكتوبة في `permissions.dart` وبصفر
//    مستدعٍ**: مصدر الحقيقة للصلاحيات يَعِد بحمايةٍ لا تقع.
//
// ٢. **الملخّص اليومي كان يُسقط سندات الدولار صامتاً:** الاستعلام يشترط
//    `currency = 'IQD'` حرفياً، فيومٌ صُرف فيه ٥٠٠ دولار وحدها يُعرَض
//    «إجمالي الصرف: 0 د.ع». وهو أخطر من رقم خاطئ — رقمٌ **مطمئِن** وخاطئ.
//
// 📌 الحُرّاس نفسها تُفحص هنا على مستوى **الصلاحية** (`user.can`) لا عبر
//    الـNotifier: بناء Riverpod كامل في اختبار وحدة يقيس تركيب المزوّدات لا
//    القاعدة. والقاعدة هي المقصودة.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/auth/permissions.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/domain/models/user_model.dart';

void main() {
  UserModel u(String role) => UserModel(
        id: 1,
        username: 'u',
        fullName: 'u',
        role: role,
        createdAt: DateTime(2026, 1, 1),
      );

  // ══════════════════════════════════════════════════════════════════════
  group('صلاحيات الفترة المالية — كانت بصفر مستدعٍ', () {
    // كل صلاحية هنا كانت **معرَّفة ولا يفحصها أحد**. الاختبار يثبت أنها
    // تميّز فعلاً بين الأدوار، فإن حُذف الفحص من الـNotifier بقي هذا
    // الاختبار ناجحاً — ولهذا يُقرأ مع `_requirePermission` لا وحده.

    test('⭐⭐ إقفال السنة المالية — للمدير فما فوق', () {
      expect(u('user').can(AppPermission.closeFiscalPeriod), isFalse);
      expect(u('admin').can(AppPermission.closeFiscalPeriod), isTrue);
      expect(u('super_admin').can(AppPermission.closeFiscalPeriod), isTrue);
    });

    test('⭐⭐ إعادة فتح السنة — لمدير النظام وحده', () {
      // كانت هذه الأخطر: الدالة بلا أي فحص إطلاقاً، فإعادةُ فتح سنة مُقفَلة
      // كانت متاحة لأي مستدعٍ.
      expect(u('user').can(AppPermission.reopenFiscalPeriod), isFalse);
      expect(u('admin').can(AppPermission.reopenFiscalPeriod), isFalse,
          reason: 'حتى المدير العادي لا يفتح سنة أُقفلت');
      expect(u('super_admin').can(AppPermission.reopenFiscalPeriod), isTrue);
    });

    test('⭐⭐ إعادة احتساب الأرصدة — لمدير النظام وحده', () {
      expect(u('admin').can(AppPermission.recomputeBalances), isFalse);
      expect(u('super_admin').can(AppPermission.recomputeBalances), isTrue);
    });

    test('⭐⭐ حذف فترة مالية — لمدير النظام وحده', () {
      expect(u('admin').can(AppPermission.deleteFiscalPeriod), isFalse);
      expect(u('super_admin').can(AppPermission.deleteFiscalPeriod), isTrue);
    });

    test('⭐ كل صلاحيات الفترة كارثية أو إدارية — لا شيء منها للمستخدم العادي',
        () {
      const fiscal = [
        AppPermission.closeFiscalPeriod,
        AppPermission.reopenFiscalPeriod,
        AppPermission.recomputeBalances,
        AppPermission.deleteFiscalPeriod,
        AppPermission.purgeFiscalPeriod,
      ];
      for (final p in fiscal) {
        expect(u('user').can(p), isFalse, reason: '$p يجب أن تُمنع');
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  group('الملخّص اليومي — العملتان', () {
    late AppDatabase db;
    late int periodId;
    late int treasuryId;

    final day = DateTime(2026, 3, 15);

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      periodId = await db.fiscalPeriodsDao.insertPeriod(
        FiscalPeriodsCompanion.insert(
          name: '2026',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31, 23, 59, 59),
        ),
      );
      treasuryId = await db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
      );
    });

    tearDown(() async => db.close());

    Future<void> voucher({
      required String type,
      required double amount,
      required String currency,
      double rate = 1,
    }) async {
      final n = await db.fiscalPeriodsDao
          .getNextVoucherNumber(fiscalPeriodId: periodId, voucherType: type);
      await db.into(db.vouchers).insert(
            VouchersCompanion.insert(
              voucherNumber: n,
              voucherType: type,
              treasuryId: treasuryId,
              fiscalPeriodId: periodId,
              amount: amount,
              currency: Value(currency),
              exchangeRate: Value(rate),
              voucherDate: DateTime(2026, 3, 15, 13, 30),
            ),
          );
    }

    test('⭐⭐⭐ سندات الدولار لم تعد تختفي — إثبات العطل', () async {
      // يومٌ فيه **الدولار وحده**: قبل الإصلاح كان الملخّص يقول
      // «القبض 0 · الصرف 0» بينما خرج من الخزينة ٥٠٠ دولار فعلاً.
      await voucher(type: 'sarf', amount: 500, currency: 'USD', rate: 1310);
      await voucher(type: 'kabd', amount: 200, currency: 'USD', rate: 1310);

      final s = await db.vouchersDao.getDailySummary(day);

      expect(s.totalSarfUsd, 500,
          reason: 'الدولار يُعرَض لا يُبتلع — رقمٌ مطمئِن وخاطئ أخطر من خاطئ');
      expect(s.totalKabdUsd, 200);
      expect(s.totalSarf, 0, reason: 'ولا يُجمَع على الدينار');
      expect(s.totalKabd, 0);
    });

    test('⭐⭐ العملتان تبقيان منفصلتين — لا تُجمعان في رقم واحد', () async {
      await voucher(type: 'sarf', amount: 1000000, currency: 'IQD');
      await voucher(type: 'sarf', amount: 500, currency: 'USD', rate: 1310);

      final s = await db.vouchersDao.getDailySummary(day);

      expect(s.totalSarf, 1000000);
      expect(s.totalSarfUsd, 500);
      // لو جُمعتا لصار الصرف 1,655,000 — وهي القاعدة المحروسة في
      // expense_reports_test: العملتان تُعرَضان متجاورتين ولا تُجمعان.
      expect(s.totalSarf, isNot(1000000 + 500 * 1310));
    });

    test('⭐ يومٌ بلا سندات يُعيد أصفاراً في العملتين', () async {
      final s = await db.vouchersDao.getDailySummary(DateTime(2026, 3, 1));
      expect(s.totalSarf, 0);
      expect(s.totalKabd, 0);
      expect(s.totalSarfUsd, 0);
      expect(s.totalKabdUsd, 0);
    });

    test('⭐ السند المحذوف ناعماً لا يدخل الملخّص', () async {
      await voucher(type: 'sarf', amount: 750, currency: 'USD', rate: 1310);
      final id = (await db.select(db.vouchers).getSingle()).id;
      await db.vouchersDao.softDeleteVoucher(id, deletedByUser: 1);

      final s = await db.vouchersDao.getDailySummary(day);
      expect(s.totalSarfUsd, 0);
    });
  });
}
