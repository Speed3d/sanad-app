// ─────────────────────────────────────────────────────────────────────────────
// schema_v6_test.dart — المرفقات وترحيل نوع البند (Schema v6)
//
// يغطّي أمرين:
//
//   ١. **جدول المرفقات** — الفهرس وقيوده. أهمّها أن المسار النسبي فريد:
//      مرفقان بنفس المسار يعنيان أن أحدهما يشير إلى ملف ليس له.
//
//   ٢. **ترحيل نوع البند** `'سلفة'` ← «سلفة موظف» (قرار المالك 2026-08-24).
//      هذا أخطر جزء لأنه **يعدّل بيانات قائمة**. لو نُفِّذ تغيير الكود بلا
//      ترحيل، لانقسم البند في تقرير «المصروفات حسب البند» إلى صفّين لمعنى
//      واحد: السندات القديمة تحت 'سلفة' والجديدة تحت 'سلفة موظف'.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/data/database/daos/attachments_dao.dart';

void main() {
  late AppDatabase db;
  late int periodId;
  late int treasuryId;

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

  Future<int> addAttachment({
    String entity = AttachmentEntity.voucher,
    int entityId = 1,
    String path = '2026/سند-1/فاتورة.pdf',
    String sha = 'abc123',
    int size = 1024,
  }) {
    return db.attachmentsDao.insertAttachment(
      AttachmentsCompanion.insert(
        entityType: entity,
        entityId: entityId,
        fileName: 'فاتورة.pdf',
        relativePath: path,
        mimeType: const Value('application/pdf'),
        sizeBytes: Value(size),
        sha256: Value(sha),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // إصدار الـ Schema
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ إصدار الـ Schema صار 6', () {
    expect(db.schemaVersion, 6);
  });

  // ═══════════════════════════════════════════════════════════════════════
  // جدول المرفقات
  // ═══════════════════════════════════════════════════════════════════════

  group('فهرس المرفقات', () {
    test('⭐ الإرفاق والقراءة يعملان', () async {
      final id = await addAttachment(entityId: 7);
      final row = await db.attachmentsDao.getById(id);

      expect(row, isNotNull);
      expect(row!.fileName, 'فاتورة.pdf');
      expect(row.relativePath, '2026/سند-1/فاتورة.pdf');
      expect(row.sizeBytes, 1024);
    });

    test('⭐ المسار النسبي فريد — لا مرفقان يشيران لملف واحد', () async {
      await addAttachment(path: '2026/سلفة-23/أ.pdf');
      await expectLater(
        addAttachment(entityId: 99, path: '2026/سلفة-23/أ.pdf', sha: 'zzz'),
        throwsA(isA<Exception>()),
        reason: 'مساران متطابقان يعنيان أن أحدهما يشير إلى ملف ليس له',
      );
    });

    test('⭐ نوع كيان غير معروف مرفوض على مستوى الجدول', () async {
      // مرفق بنوع مجهول يتيم لا تصل إليه أي شاشة، ولا يشتكي منه المحلّل
      await expectLater(
        addAttachment(entity: 'employee'),
        throwsA(isA<Exception>()),
      );
    });

    test('السلفة والسند برقم واحد لا يختلط مرفقاهما', () async {
      await addAttachment(
          entity: AttachmentEntity.voucher, entityId: 3, path: 'v/3.pdf');
      await addAttachment(
          entity: AttachmentEntity.advance, entityId: 3, path: 'a/3.pdf');

      final vouchers = await db.attachmentsDao.getForEntity(
          entityType: AttachmentEntity.voucher, entityId: 3);
      final advances = await db.attachmentsDao.getForEntity(
          entityType: AttachmentEntity.advance, entityId: 3);

      expect(vouchers, hasLength(1));
      expect(vouchers.first.relativePath, 'v/3.pdf');
      expect(advances, hasLength(1));
      expect(advances.first.relativePath, 'a/3.pdf');
    });

    test('⭐ كشف الملف المكرّر ببصمته على الكيان نفسه', () async {
      await addAttachment(entityId: 5, path: 'x/1.pdf', sha: 'HASH-A');

      final dup = await db.attachmentsDao.findDuplicate(
        entityType: AttachmentEntity.voucher,
        entityId: 5,
        sha256: 'HASH-A',
      );
      expect(dup, isNotNull, reason: 'إعادة إرفاق الملف نفسه تُكشَف');

      // البصمة نفسها على كيان آخر ليست تكراراً — قد يخصّ سندين فعلاً
      final other = await db.attachmentsDao.findDuplicate(
        entityType: AttachmentEntity.voucher,
        entityId: 6,
        sha256: 'HASH-A',
      );
      expect(other, isNull);
    });

    test('البصمة الفارغة لا تُطابق شيئاً', () async {
      await addAttachment(entityId: 5, sha: '');
      final dup = await db.attachmentsDao.findDuplicate(
        entityType: AttachmentEntity.voucher,
        entityId: 5,
        sha256: '',
      );
      expect(dup, isNull, reason: 'غياب البصمة ليس تطابقاً');
    });

    test('⭐ حذف مرفقات كيان يُعيد صفوفها ليُحذف ملفها من القرص', () async {
      await addAttachment(entityId: 9, path: 'a/1.pdf', sha: 'h1');
      await addAttachment(entityId: 9, path: 'a/2.pdf', sha: 'h2');

      final removed = await db.attachmentsDao.deleteForEntity(
        entityType: AttachmentEntity.voucher,
        entityId: 9,
      );

      expect(removed, hasLength(2),
          reason: 'بلا إعادة الصفوف تبقى الملفات معلّقة على القرص للأبد');
      expect(removed.map((a) => a.relativePath), containsAll(['a/1.pdf', 'a/2.pdf']));
      expect(
        await db.attachmentsDao
            .countForEntity(entityType: AttachmentEntity.voucher, entityId: 9),
        0,
      );
    });

    test('إجمالي الحجم يُحتسَب لكل المرفقات', () async {
      await addAttachment(path: 'a.pdf', sha: 'h1', size: 1000);
      await addAttachment(path: 'b.pdf', sha: 'h2', size: 2500);
      expect(await db.attachmentsDao.totalSizeBytes(), 3500);
    });

    test('قاعدة بلا مرفقات تُعيد صفراً لا null', () async {
      expect(await db.attachmentsDao.totalSizeBytes(), 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ترحيل نوع البند
  // ═══════════════════════════════════════════════════════════════════════

  group('ترحيل «سلفة» ← «سلفة موظف»', () {
    test('⭐ البذور تحمل «سلفة موظف» لا «سلفة» الغامضة', () async {
      final types = await db.advancesDao.getAllItemTypes();
      final names = types.map((t) => t.name).toList();

      expect(names, contains('سلفة موظف'));
      expect(names, isNot(contains('سلفة')),
          reason: 'القيمة الغامضة تنقسم في التقرير عن «سلفة موظف»');
    });

    test('⭐ سند سلفة موظف يظهر مميّزاً في تقرير البنود', () async {
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: 1,
          voucherType: 'kabd',
          treasuryId: treasuryId,
          fiscalPeriodId: periodId,
          amount: 5000000,
          voucherDate: DateTime(2026, 2, 1),
        ),
      );
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: 2,
          voucherType: 'sarf',
          treasuryId: treasuryId,
          fiscalPeriodId: periodId,
          amount: 300000,
          voucherDate: DateTime(2026, 3, 1),
          itemType: const Value('سلفة موظف'),
        ),
      );

      final rows = await db.vouchersDao.getExpensesByItemType(
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 12, 31),
      );
      expect(rows, hasLength(1));
      expect(rows.first.itemType, 'سلفة موظف');
      expect(rows.first.totalEquivalentIqd, 300000);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // التصفير يشمل المرفقات
  // ═══════════════════════════════════════════════════════════════════════

  test('⭐ تصفير البيانات المالية يمسح فهرس المرفقات', () async {
    await addAttachment(entityId: 1, path: 'x/1.pdf');
    await db.resetFinancialData();

    final row = await db
        .customSelect('SELECT COUNT(*) AS c FROM attachments')
        .getSingle();
    expect(row.data['c'], 0,
        reason: 'مرفقات تشير إلى سندات محذوفة = فهرس يكذب');
  });
}
