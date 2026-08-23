// ─────────────────────────────────────────────────────────────────────────────
// voucher_tracking_fields_test.dart — حقول تتبّع المصروفات (ب-١)
//
// الفجوة التي يغلقها (2026-08-23):
//   الأعمدة project_name · invoice_number · spent_by · advance_number موجودة
//   في جدول vouchers منذ Schema v2، وموجودة في VoucherModel أيضاً — لكن
//   **طبقة المستودع كانت تُسقطها في ثلاثة مواضع**:
//     ١. createVoucher لا يقبلها أصلاً  → تُخزَّن NULL دائماً
//     ٢. _toModel لا يقرأها             → تصل الشاشة فارغة دائماً
//     ٣. updateVoucher لا يكتبها        → التعديل يمحوها
//
//   الأثر العملي: بيانات تتبّع المصروفات (المشروع · الفاتورة · من صرف)
//   كانت **مستحيلة الإدخال** من الشاشة رغم جاهزية قاعدة البيانات لها.
//
// الخطر الأخبث هنا هو الموضع الثالث: لو وُصلت الشاشة دون إصلاح _toModel،
// لفتح المستخدم سنداً فيه بيانات، ورآها فارغة، وحفظ — فمحاها دون أن يشعر.
// لهذا يوجد اختبار «دورة التعديل الكاملة» أدناه.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/repositories/voucher_repository.dart';

void main() {
  late AppDatabase db;
  late VoucherRepository repo;
  late int periodId;
  late int treasuryId;

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
    treasuryId = await db.treasuriesDao.insertTreasury(
      TreasuriesCompanion.insert(name: 'الرئيسية', kind: const Value('main')),
    );
    // رصيد يسمح بالصرف
    await repo.createVoucher(
      fiscalPeriodId: periodId,
      voucherType: 'kabd',
      treasuryId: treasuryId,
      amount: 10000000,
      currency: 'IQD',
      voucherDate: DateTime(2026, 2, 1),
    );
  });

  tearDown(() async => db.close());

  Future<int> createSarf({
    String? project,
    String? invoice,
    String? spentBy,
    String? advance,
  }) {
    return repo.createVoucher(
      fiscalPeriodId: periodId,
      voucherType: 'sarf',
      treasuryId: treasuryId,
      amount: 250000,
      currency: 'IQD',
      voucherDate: DateTime(2026, 3, 1),
      itemType: 'كهربائيات',
      projectName: project,
      invoiceNumber: invoice,
      spentBy: spentBy,
      advanceNumber: advance,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ١. الحفظ والقراءة
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ الحقول الأربعة تُحفظ وتُقرأ ذهاباً وإياباً', () async {
    final id = await createSarf(
      project: 'مشروع البصرة',
      invoice: 'INV-2026-118',
      spentBy: 'أحمد محمد',
      advance: '23',
    );

    final row = (await db.vouchersDao.getVoucherById(id))!;
    expect(row.projectName, 'مشروع البصرة');
    expect(row.invoiceNumber, 'INV-2026-118');
    expect(row.spentBy, 'أحمد محمد');
    expect(row.advanceNumber, '23');
  });

  test('⭐ _toModel يقرأ الحقول الأربعة — كانت تصل الشاشة فارغة', () async {
    await createSarf(
      project: 'مشروع البصرة',
      invoice: 'INV-118',
      spentBy: 'أحمد',
      advance: '23',
    );

    final list = await repo.getVouchersByDateRange(
      from: DateTime(2026, 1, 1),
      to: DateTime(2026, 12, 31),
      voucherType: 'sarf',
    );
    expect(list, hasLength(1));
    expect(list.first.projectName, 'مشروع البصرة');
    expect(list.first.invoiceNumber, 'INV-118');
    expect(list.first.spentBy, 'أحمد');
    expect(list.first.advanceNumber, '23');
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٢. الغياب يُمثَّل بـ null لا بنصّ فارغ
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ النصّ الفارغ يُخزَّن null لا سلسلة فارغة', () async {
    // الشاشة تُرسل '' حين يترك المستخدم الحقل فارغاً. تخزينها كما هي يجعل
    // الفلترة والتقارير تعاملها كقيمة قائمة — فالغياب يجب أن يكون null.
    final id = await createSarf(project: '', invoice: '   ', spentBy: '');

    final row = (await db.vouchersDao.getVoucherById(id))!;
    expect(row.projectName, isNull);
    expect(row.invoiceNumber, isNull, reason: 'الفراغات وحدها ليست قيمة');
    expect(row.spentBy, isNull);
  });

  test('القيم تُقصّ من الفراغات الزائدة', () async {
    final id = await createSarf(project: '  مشروع البصرة  ');
    final row = (await db.vouchersDao.getVoucherById(id))!;
    expect(row.projectName, 'مشروع البصرة');
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٣. أخطر حالة: دورة التعديل الكاملة
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ فتح سند وحفظه دون تغيير لا يمحو حقول التتبّع', () async {
    final id = await createSarf(
      project: 'مشروع البصرة',
      invoice: 'INV-118',
      spentBy: 'أحمد',
      advance: '23',
    );

    // هذا بالضبط ما تفعله شاشة التعديل: تقرأ النموذج، تعرضه، ثم تحفظه.
    // لو كان _toModel يُسقط الحقول لعادت null وحُفظت null فوقها — أي أن
    // مجرّد فتح السند وحفظه كان سيمحو بياناته.
    final loaded = (await repo.getVouchersByDateRange(
      from: DateTime(2026, 1, 1),
      to: DateTime(2026, 12, 31),
      voucherType: 'sarf',
    ))
        .first;

    await repo.updateVoucher(loaded, updatedByUserId: 1);

    final after = (await db.vouchersDao.getVoucherById(id))!;
    expect(after.projectName, 'مشروع البصرة');
    expect(after.invoiceNumber, 'INV-118');
    expect(after.spentBy, 'أحمد');
    expect(after.advanceNumber, '23');
  });

  test('التعديل يكتب القيم الجديدة ويمسح ما فُرِّغ', () async {
    final id = await createSarf(project: 'البصرة', invoice: 'INV-1');

    final loaded = (await repo.getVouchersByDateRange(
      from: DateTime(2026, 1, 1),
      to: DateTime(2026, 12, 31),
      voucherType: 'sarf',
    ))
        .first;

    await repo.updateVoucher(
      loaded.copyWith(projectName: 'كربلاء', invoiceNumber: ''),
      updatedByUserId: 1,
    );

    final after = (await db.vouchersDao.getVoucherById(id))!;
    expect(after.projectName, 'كربلاء');
    expect(after.invoiceNumber, isNull, reason: 'تفريغ الحقل يعني الغياب');
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ٤. سند القبض يحمل رقم فاتورة أيضاً
  // ═══════════════════════════════════════════════════════════════════════

  test('سند القبض يحفظ رقم الفاتورة مستقلاً عن الرقم المرجعي', () async {
    final id = await repo.createVoucher(
      fiscalPeriodId: periodId,
      voucherType: 'kabd',
      treasuryId: treasuryId,
      amount: 3000000,
      currency: 'IQD',
      voucherDate: DateTime(2026, 4, 1),
      referenceNumber: 'CHK-900',
      invoiceNumber: 'INV-2026-55',
    );

    final row = (await db.vouchersDao.getVoucherById(id))!;
    // مفهومان مختلفان: الأول رقم الشيك، والثاني رقم فاتورة الشركة
    expect(row.referenceNumber, 'CHK-900');
    expect(row.invoiceNumber, 'INV-2026-55');
  });
}
