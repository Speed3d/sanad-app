// ─────────────────────────────────────────────────────────────────────────────
// company_identity_test.dart — هوية الشركة على المستندات (ب-٣)
//
// الفجوة التي يغلقها (2026-08-23):
//   شعار الشركة كان **يُرفَع ويُخزَّن في `app_blobs` ولا يُقرأ أبداً** —
//   `setBlob` مستدعاة و`getBlob` بصفر استدعاء في المشروع كلّه. أي أن المالك
//   يرفع شعاره ثم لا يراه لا في الإعدادات ولا في أي مستند مطبوع.
//
// وهنا أيضاً حارس على قرار معماري: `PdfService` في طبقة `core` و**لا يجوز**
// أن تعرف شيئاً عن قاعدة البيانات. هوية الشركة تُمرَّر إليها ككائن جاهز،
// فتبقى قابلة للاختبار بلا قاعدة بيانات إطلاقاً — وهو ما تُثبته هذه الملفات.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/constants/app_settings_keys.dart';
import 'package:sales_management/core/services/pdf_service.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/domain/models/voucher_model.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════
  // دورة حياة الشعار: رفع → قراءة → حذف
  // ═══════════════════════════════════════════════════════════════════════

  group('تخزين شعار الشركة', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() async => db.close());

    // بايتات تمثّل صورة — المحتوى غير مهم، المهم أنها تعود كما هي
    final logo = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3]);

    test('⭐ الشعار المرفوع يُقرأ كما هو — كان يُكتَب ولا يُقرأ قط', () async {
      await db.appSettingsDao
          .setBlob(AppSettingsKeys.companyLogo, logo, 'image/png');

      final read = await db.appSettingsDao.getBlob(AppSettingsKeys.companyLogo);
      expect(read, isNotNull);
      expect(read, equals(logo));
    });

    test('لا شعار مرفوع يُعيد null لا بايتات فارغة', () async {
      final read = await db.appSettingsDao.getBlob(AppSettingsKeys.companyLogo);
      expect(read, isNull,
          reason: 'الواجهة تفرّق بين «لا شعار» و«شعار فارغ» بناءً على هذا');
    });

    test('رفع شعار جديد يستبدل القديم ولا يتراكم', () async {
      await db.appSettingsDao
          .setBlob(AppSettingsKeys.companyLogo, logo, 'image/png');
      final newLogo = Uint8List.fromList([255, 216, 255, 224, 9, 9]);
      await db.appSettingsDao
          .setBlob(AppSettingsKeys.companyLogo, newLogo, 'image/jpeg');

      expect(await db.appSettingsDao.getBlob(AppSettingsKeys.companyLogo),
          equals(newLogo));
    });

    test('⭐ الحذف يُعيد الحالة إلى «لا شعار»', () async {
      await db.appSettingsDao
          .setBlob(AppSettingsKeys.companyLogo, logo, 'image/png');
      await db.appSettingsDao.deleteBlob(AppSettingsKeys.companyLogo);

      expect(await db.appSettingsDao.getBlob(AppSettingsKeys.companyLogo),
          isNull,
          reason: 'بلا حذف يبقى شعار رُفع بالخطأ إلى الأبد');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ترويسة الـ PDF — منطق «هل تستحق العرض؟»
  // ═══════════════════════════════════════════════════════════════════════

  group('ترويسة الشركة على الـ PDF', () {
    final logo = Uint8List.fromList([1, 2, 3, 4]);

    test('⭐ ترويسة بلا اسم ولا شعار لا تستحق العرض', () {
      // وإلا تُرك فراغ أبيض في أعلى كل صفحة بلا سبب
      expect(PdfCompanyHeader.empty.hasContent, isFalse);
      expect(const PdfCompanyHeader(companyName: '   ').hasContent, isFalse,
          reason: 'الفراغات وحدها ليست اسماً');
    });

    test('الاسم وحده يكفي لعرض الترويسة', () {
      expect(
        const PdfCompanyHeader(companyName: 'شركة سند').hasContent,
        isTrue,
      );
    });

    test('الشعار وحده يكفي لعرض الترويسة', () {
      expect(PdfCompanyHeader(logoBytes: logo).hasContent, isTrue);
    });

    test('⭐ الترويسة الفارغة ثابتة جاهزة للاستعمال الافتراضي', () {
      // المستند يُطبَع بلا ترويسة بدل أن يفشل توليده حين تتعذّر القراءة:
      // غياب الشعار إزعاج، وفشل الطباعة تعطيل.
      expect(PdfCompanyHeader.empty.companyName, '');
      expect(PdfCompanyHeader.empty.logoBytes, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // الحارس المعماري: توليد الـ PDF بلا قاعدة بيانات
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ PdfService يعمل بلا قاعدة بيانات إطلاقاً', () async {
    // هذا الاختبار نفسه هو البرهان: لا AppDatabase في نطاقه. لو احتاجت
    // الخدمة يوماً قراءة الإعدادات بنفسها لانكسر — وهو المقصود.
    final service = _service();
    final bytes = await service.generateVoucherReceipt(
      _sampleVoucher(),
      header: const PdfCompanyHeader(companyName: 'شركة سند للمقاولات'),
    );

    expect(bytes, isNotEmpty);
    // توقيع ملف PDF: %PDF
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('توليد السند بلا ترويسة ينجح أيضاً', () async {
    final bytes = await _service().generateVoucherReceipt(_sampleVoucher());
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}

/// خدمة PDF بخطوط محقونة من القرص
///
/// `rootBundle` لا يعمل خارج تطبيق حيّ، والخدمة **لم تعد تتراجع صامتةً إلى
/// Helvetica** بعد عطل «العربي غير مفهوم» (2026-08-24) — فالحقن هو الطريق
/// الصحيح للاختبار. راجع `pdf_arabic_font_test.dart`.
PdfService _service() => PdfService(
      regular: _font('Tajawal-Regular.ttf'),
      bold: _font('Tajawal-Bold.ttf'),
    );

pw.Font _font(String name) => ArabicPdfFont(
      File('assets/fonts/$name').readAsBytesSync().buffer.asByteData(),
    );

/// سند نموذجي للاختبار — قيم ثابتة لا تعتمد على قاعدة بيانات
VoucherModel _sampleVoucher() => VoucherModel(
      id: 1,
      voucherNumber: 7,
      voucherType: 'sarf',
      treasuryId: 1,
      fiscalPeriodId: 1,
      amount: 250000,
      currency: 'IQD',
      voucherDate: DateTime(2026, 3, 1),
      personName: 'أحمد محمد',
      reason: 'شراء كهربائيات',
      itemType: 'كهربائيات',
      projectName: 'مشروع البصرة',
      invoiceNumber: 'INV-118',
    );
