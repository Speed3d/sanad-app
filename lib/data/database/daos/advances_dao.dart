// ─────────────────────────────────────────────────────────────────────────────
// advances_dao.dart — DAO سلف المشاريع (الترويسة + أسطر المسودة)
//
// ⚠️ Advances ≠ CashAdvances (سلف الموظفين) — راجع advances_table.dart
//
// 🔑 العملية الأخطر في هذا الملف: postAdvance()
//   تحوّل أسطر المسودة إلى سندات صرف حقيقية داخل **معاملة واحدة**.
//   إما أن تُنشأ كل السندات وتُربَط بأسطرها وتتغيّر حالة السلفة، أو لا شيء
//   إطلاقاً. فشل جزئي هنا يعني دفاتر مشوّهة: سندات بلا سلفة، أو سلفة معتمدة
//   بنصف مصاريفها — وكلاهما يفسد الأرصدة بصمت.
//
// لماذا لا نستخدم insertVouchersBatch الموجودة في vouchers_dao؟
//   batch.insertAll لا تُعيد المعرّفات المُولَّدة، ونحن نحتاجها لملء
//   advance_lines.voucher_id (الرباط بين السطر وسنده). الإدراج الفردي داخل
//   db.transaction() يحفظ الذرّية نفسها ويُعيد المعرّفات.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/advances_table.dart';
import '../tables/advance_lines_table.dart';
import '../tables/item_types_table.dart';
import '../tables/vouchers_table.dart';

part 'advances_dao.g.dart';

/// نتيجة اعتماد سلفة
class PostAdvanceResult {
  /// معرّفات السندات التي أُنشئت
  final List<int> voucherIds;

  /// إجمالي المبلغ المُرحَّل
  final double totalPosted;

  const PostAdvanceResult({
    required this.voucherIds,
    required this.totalPosted,
  });
}

/// DAO سلف المشاريع
@DriftAccessor(tables: [Advances, AdvanceLines, ItemTypes, Vouchers])
class AdvancesDao extends DatabaseAccessor<AppDatabase>
    with _$AdvancesDaoMixin {
  AdvancesDao(super.db);

  // ── قراءة السلف ───────────────────────────────────────────────────────────

  /// متابعة السلف حسب الحالة — Reactive Stream
  ///
  /// [status] — null = كل الحالات
  Stream<List<Advance>> watchAdvances({String? status}) {
    final q = select(advances);
    if (status != null) {
      q.where((a) => a.status.equals(status));
    }
    q.orderBy([(a) => OrderingTerm.desc(a.advanceDate)]);
    return q.watch();
  }

  /// متابعة سلفة واحدة — Reactive Stream
  Stream<Advance?> watchAdvanceById(int id) {
    return (select(advances)..where((a) => a.id.equals(id)))
        .watchSingleOrNull();
  }

  /// جلب سلفة بالمعرّف
  Future<Advance?> getAdvanceById(int id) {
    return (select(advances)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  /// السلف المفتوحة أو المسودات لخزينة مشروع محددة
  ///
  /// تُستخدَم في شاشة الاستيراد: «على أي سلفة أُنزل هذا الملف؟»
  Future<List<Advance>> getActiveAdvancesForTreasury(int treasuryId) {
    return (select(advances)
          ..where((a) =>
              a.projectTreasuryId.equals(treasuryId) &
              a.status.isIn([AdvanceStatusDb.open, AdvanceStatusDb.draft]))
          ..orderBy([(a) => OrderingTerm.desc(a.advanceDate)]))
        .get();
  }

  /// البحث عن سلفة استُورد فيها ملف ببصمة معيّنة
  ///
  /// يمنع مضاعفة المصاريف باستيراد نفس الملف مرتين — وهو خطأ وارد جداً
  /// في العمل اليومي ولا يكشفه شيء آخر في النظام.
  Future<Advance?> findByFileHash(String hash) {
    if (hash.isEmpty) return Future.value(null);
    return (select(advances)
          ..where((a) =>
              a.sourceFileHash.equals(hash) &
              a.status.equals(AdvanceStatusDb.cancelled).not())
          ..limit(1))
        .getSingleOrNull();
  }

  /// هل رقم السلفة مستعمَل في هذه الفترة المالية؟
  ///
  /// فحص استباقي لإعطاء رسالة عربية واضحة بدل ترك الفهرس الفريد يرمي
  /// استثناء SQLite غامضاً في وجه المستخدم.
  Future<bool> isAdvanceNumberTaken({
    required String advanceNumber,
    required int fiscalPeriodId,
    int? exceptId,
  }) async {
    final rows = await (select(advances)
          ..where((a) {
            var c = a.advanceNumber.equals(advanceNumber) &
                a.fiscalPeriodId.equals(fiscalPeriodId) &
                a.status.equals(AdvanceStatusDb.cancelled).not();
            if (exceptId != null) c = c & a.id.equals(exceptId).not();
            return c;
          })
          ..limit(1))
        .get();
    return rows.isNotEmpty;
  }

  // ── كتابة السلف ───────────────────────────────────────────────────────────

  /// إنشاء سلفة جديدة — يُعيد المعرّف المُولَّد
  Future<int> insertAdvance(AdvancesCompanion advance) {
    return into(advances).insert(advance);
  }

  /// تحديث جزئي للسلفة
  ///
  /// نستخدم write وليس replace للسبب نفسه الموثَّق في vouchers_dao:
  /// replace يُعيد الحقول الغائبة إلى قيمها الافتراضية فيمحو أثر الاعتماد
  /// والإلغاء ومقدار العجز.
  Future<bool> updateAdvance(AdvancesCompanion advance) async {
    final n = await (update(advances)
          ..where((a) => a.id.equals(advance.id.value)))
        .write(advance);
    return n > 0;
  }

  // ── أسطر المسودة ──────────────────────────────────────────────────────────

  /// متابعة أسطر سلفة — Reactive Stream مرتبة بترتيب الملف الأصلي
  Stream<List<AdvanceLine>> watchLines(int advanceId) {
    return (select(advanceLines)
          ..where((l) => l.advanceId.equals(advanceId))
          ..orderBy([(l) => OrderingTerm.asc(l.rowNumber)]))
        .watch();
  }

  /// جلب أسطر سلفة
  Future<List<AdvanceLine>> getLines(int advanceId) {
    return (select(advanceLines)
          ..where((l) => l.advanceId.equals(advanceId))
          ..orderBy([(l) => OrderingTerm.asc(l.rowNumber)]))
        .get();
  }

  /// إدراج أسطر المسودة دفعة واحدة (بعد قراءة ملف الإكسل)
  Future<void> insertLines(List<AdvanceLinesCompanion> lines) async {
    await batch((b) => b.insertAll(advanceLines, lines));
  }

  /// تحديث سطر مسودة — تحديث جزئي
  Future<bool> updateLine(AdvanceLinesCompanion line) async {
    final n = await (update(advanceLines)
          ..where((l) => l.id.equals(line.id.value)))
        .write(line);
    return n > 0;
  }

  /// حذف كل أسطر سلفة (عند إعادة استيراد ملف بديل على نفس السلفة)
  Future<int> deleteLines(int advanceId) {
    return (delete(advanceLines)..where((l) => l.advanceId.equals(advanceId)))
        .go();
  }

  // ── حسابات الملخص ─────────────────────────────────────────────────────────

  /// المبلغ الصافي المُرسَل للمشروع على حساب هذه السلفة
  ///
  /// = مجموع التحويلات الواردة إلى خزينة المشروع
  /// − مجموع التحويلات الصادرة منها (إعادة مبلغ غير مصروف)
  ///
  /// الفلترة على خزينة المشروع ضرورية: سند التحويل الصادر من الخزينة
  /// الرئيسية يحمل نفس advance_id، وحسابه هنا كان سيُصفّر المُرسَل.
  Future<double> getSentAmount({
    required int advanceId,
    required int projectTreasuryId,
  }) async {
    final row = await customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN voucher_type = 'transfer_in'  THEN amount ELSE 0 END), 0)
      - COALESCE(SUM(CASE WHEN voucher_type = 'transfer_out' THEN amount ELSE 0 END), 0)
        AS net_sent
      FROM vouchers
      WHERE advance_id = ?
        AND treasury_id = ?
        AND is_deleted = 0
      ''',
      variables: [Variable.withInt(advanceId), Variable.withInt(projectTreasuryId)],
      readsFrom: {vouchers},
    ).getSingle();
    return (row.data['net_sent'] as num).toDouble();
  }

  /// مجموع مصاريف المسودات المعلّقة لكل خزينة مشروع
  ///
  /// يُستخدَم للتحذير المبكر على بطاقة الخزينة:
  ///   «الرصيد 3,000,000 · معلّق في مسودات 3,500,000 · المتاح −500,000»
  ///
  /// لماذا؟ المسودة لا تمسّ الرصيد (وهذا مقصود)، لكن ذلك يعني أن الخزينة
  /// تبدو ممتلئة بينما مصاريفها وصلت فعلاً وتنتظر الاعتماد فقط. عرض المعلّق
  /// يكشف العجز **قبل** لحظة الاعتماد لا بعدها.
  Stream<Map<int, double>> watchPendingDraftTotals() {
    return customSelect(
      '''
      SELECT a.project_treasury_id AS treasury_id,
             COALESCE(SUM(l.amount), 0) AS pending
      FROM advances a
      JOIN advance_lines l ON l.advance_id = a.id
      WHERE a.status = 'draft' AND l.is_excluded = 0
      GROUP BY a.project_treasury_id
      ''',
      readsFrom: {advances, advanceLines},
    ).watch().map((rows) {
      return {
        for (final r in rows)
          r.data['treasury_id'] as int: (r.data['pending'] as num).toDouble(),
      };
    });
  }

  /// المصروف المُرحَّل فعلياً (بعد الاعتماد) — مجموع سندات الصرف المرتبطة
  Future<double> getPostedSpent(int advanceId) async {
    final row = await customSelect(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM vouchers
      WHERE advance_id = ? AND voucher_type = 'sarf' AND is_deleted = 0
      ''',
      variables: [Variable.withInt(advanceId)],
      readsFrom: {vouchers},
    ).getSingle();
    return (row.data['total'] as num).toDouble();
  }

  // ── أنواع البنود ──────────────────────────────────────────────────────────

  /// متابعة أنواع البنود النشطة — Reactive Stream
  ///
  /// [kind] — 'sarf' | 'kabd' | null (الكل). البنود المُعلَّمة 'both' تظهر دائماً.
  Stream<List<ItemType>> watchItemTypes({String? kind}) {
    final q = select(itemTypes)..where((t) => t.isActive.equals(true));
    if (kind != null) {
      q.where((t) => t.kind.isIn([kind, 'both']));
    }
    q.orderBy([
      (t) => OrderingTerm.asc(t.sortOrder),
      (t) => OrderingTerm.asc(t.name),
    ]);
    return q.watch();
  }

  /// جلب أنواع البنود (كل الحالات — للإدارة في الإعدادات)
  Future<List<ItemType>> getAllItemTypes() {
    return (select(itemTypes)
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  /// إضافة نوع بند جديد
  Future<int> insertItemType(ItemTypesCompanion itemType) {
    return into(itemTypes).insert(itemType);
  }

  /// تحديث نوع بند (تعطيل / إعادة تسمية / ترتيب)
  Future<bool> updateItemType(ItemTypesCompanion itemType) async {
    final n = await (update(itemTypes)
          ..where((t) => t.id.equals(itemType.id.value)))
        .write(itemType);
    return n > 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔑 الاعتماد — تحويل المسودة إلى سندات صرف (معاملة ذرّية واحدة)
  // ═══════════════════════════════════════════════════════════════════════════

  /// اعتماد سلفة: كل سطر غير مستبعَد يصبح سند صرف على خزينة المشروع
  ///
  /// **كل شيء أو لا شيء.** أي استثناء في أي خطوة يُلغي المعاملة بالكامل فلا
  /// يبقى سند واحد ولا تتغيّر حالة السلفة.
  ///
  /// [advanceId]          — السلفة المراد اعتمادها
  /// [deficitAmount]      — العجز المحسوب مسبقاً في المستودع (0 = لا عجز)
  /// [deficitCoveredBy]   — من غطّى العجز (مطلوب إذا كان هناك عجز)
  /// [postedByUserId]     — المستخدم المعتمِد (للتدقيق)
  ///
  /// يُعيد معرّفات السندات المُنشأة وإجمالي المبلغ.
  ///
  /// ⚠️ لا يُجري هذا التابع أي فحص للصلاحيات أو الرصيد أو الفترة المالية —
  ///    تلك مسؤولية AdvanceRepository الذي يستدعيه. الفصل مقصود: الـ DAO
  ///    يضمن الذرّية، والمستودع يضمن قواعد العمل.
  Future<PostAdvanceResult> postAdvance({
    required int advanceId,
    required double deficitAmount,
    String? deficitCoveredBy,
    int? postedByUserId,
  }) async {
    return db.transaction(() async {
      final advance = await getAdvanceById(advanceId);
      if (advance == null) {
        throw StateError('السلفة غير موجودة (معرّف: $advanceId)');
      }

      // الأسطر الداخلة في الاعتماد — المستبعَدة تبقى في المسودة بلا سند
      final lines = await (select(advanceLines)
            ..where((l) =>
                l.advanceId.equals(advanceId) & l.isExcluded.equals(false))
            ..orderBy([(l) => OrderingTerm.asc(l.rowNumber)]))
          .get();

      if (lines.isEmpty) {
        throw StateError(
          'لا توجد أسطر قابلة للاعتماد في هذه السلفة — كل الأسطر مستبعَدة.',
        );
      }

      final voucherIds = <int>[];
      double total = 0;

      for (final line in lines) {
        // رقم السند التالي — ذرّي عبر UPSERT في voucher_sequences
        final voucherNumber = await db.fiscalPeriodsDao.getNextVoucherNumber(
          fiscalPeriodId: advance.fiscalPeriodId,
          voucherType: 'sarf',
        );

        final voucherId = await into(vouchers).insert(
          VouchersCompanion.insert(
            voucherNumber: voucherNumber,
            voucherType: 'sarf',
            treasuryId: advance.projectTreasuryId,
            fiscalPeriodId: advance.fiscalPeriodId,
            amount: line.amount,
            // الاستيراد بالدينار حصراً — لا سعر صرف ولا التباس
            currency: const Value('IQD'),
            exchangeRate: const Value(1.0),
            voucherDate: line.voucherDate,
            personName: Value(line.personName),
            reason: Value(line.reason),
            itemType: Value(line.itemType),
            projectName: Value(line.projectName ?? advance.projectName),
            invoiceNumber: Value(line.invoiceNumber),
            spentBy: Value(line.spentBy),
            advanceNumber: Value(advance.advanceNumber),
            advanceId: Value(advanceId),
            createdByUserId: Value(postedByUserId),
          ),
        );

        // ربط السطر بسنده — بهذا يصبح لكل مصروف أثر مزدوج قابل للتتبع
        await (update(advanceLines)..where((l) => l.id.equals(line.id)))
            .write(AdvanceLinesCompanion(voucherId: Value(voucherId)));

        voucherIds.add(voucherId);
        total += line.amount;
      }

      // ختم السلفة: معتمدة، بمن اعتمدها ومتى، وبمقدار العجز إن وُجد
      await (update(advances)..where((a) => a.id.equals(advanceId))).write(
        AdvancesCompanion(
          status: const Value(AdvanceStatusDb.posted),
          postedAt: Value(DateTime.now()),
          postedByUserId: Value(postedByUserId),
          deficitAmount: Value(deficitAmount),
          deficitCoveredBy: Value(deficitCoveredBy),
        ),
      );

      return PostAdvanceResult(voucherIds: voucherIds, totalPosted: total);
    });
  }

  /// إلغاء سلفة معتمدة أو مسودة
  ///
  /// المعتمدة: تُحذف **سندات الصرف** التي أنشأها الاعتماد حذفاً ناعماً، فيرتدّ
  /// المبلغ إلى الخزينة تلقائياً (الرصيد محسوب من السندات لا مخزَّن)، ويبقى
  /// الأثر الرقابي كاملاً.
  ///
  /// ⚠️ سندات التحويل (transfer_in/out) **لا تُحذف** رغم حملها نفس advance_id.
  ///   الإلغاء يتراجع عن *تسجيل المصاريف* لا عن *حركة المال*: المبلغ انتقل
  ///   فعلاً من الخزينة الرئيسية إلى خزنة المشروع وما زال هناك. حذفه كان
  ///   يُبخّر التمويل ويُظهر خزنة المشروع صفراً بدل رصيدها الحقيقي.
  ///   (كشفه اختبار «إلغاء سلفة معتمدة يُعيد المبلغ للخزينة».)
  Future<void> cancelAdvance({
    required int advanceId,
    int? cancelledByUserId,
  }) async {
    await db.transaction(() async {
      final now = DateTime.now();

      // حذف ناعم لسندات الصرف الناتجة عن الاعتماد فقط
      await (update(vouchers)
            ..where((v) =>
                v.advanceId.equals(advanceId) &
                v.voucherType.equals('sarf') &
                v.isDeleted.equals(false)))
          .write(
        VouchersCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(now),
          updatedByUserId: Value(cancelledByUserId),
          updatedAt: Value(now),
        ),
      );

      // فكّ ربط الأسطر بسنداتها المحذوفة
      await (update(advanceLines)
            ..where((l) => l.advanceId.equals(advanceId)))
          .write(const AdvanceLinesCompanion(voucherId: Value(null)));

      await (update(advances)..where((a) => a.id.equals(advanceId))).write(
        AdvancesCompanion(
          status: const Value(AdvanceStatusDb.cancelled),
          cancelledAt: Value(now),
          cancelledByUserId: Value(cancelledByUserId),
        ),
      );
    });
  }
}

/// ثوابت حالات السلفة على مستوى قاعدة البيانات
///
/// نسخة من AdvanceStatus في طبقة الـ domain — مكرّرة عمداً هنا لأن طبقة
/// البيانات يجب ألا تستورد من طبقة الـ domain (اتجاه الاعتماد معاكس).
abstract final class AdvanceStatusDb {
  static const String open = 'open';
  static const String draft = 'draft';
  static const String posted = 'posted';
  static const String cancelled = 'cancelled';
}
