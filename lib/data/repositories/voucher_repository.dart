// ─────────────────────────────────────────────────────────────────────────────
// voucher_repository.dart — تنفيذ مستودع السندات باستخدام Drift
//
// هذا الـ Repository هو الأكثر تعقيداً لأنه:
//   1. يقرأ رقم السند التالي من FiscalPeriodsDao
//   2. يُحوّل بيانات Drift إلى VoucherModel والعكس
//   3. يُنفّذ عملية التحويل بين الخزائن بـ Atomic Transaction
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

import '../../core/services/fiscal_period_guard.dart';
import '../../core/services/treasury_state_guard.dart';
import '../../domain/models/voucher_model.dart';
import '../../domain/repositories/i_voucher_repository.dart';
import '../database/app_database.dart';
import '../database/daos/vouchers_dao.dart';
// VouchersCompanion و Voucher مُولَّدان في app_database.g.dart — لا حاجة لاستيراد vouchers_table.dart

/// تنفيذ مستودع السندات باستخدام Drift
class VoucherRepository implements IVoucherRepository {
  final AppDatabase _db;

  const VoucherRepository(this._db);

  // ── تحويل البيانات ────────────────────────────────────────────────────────

  /// تحويل نموذج Drift إلى نموذج Domain
  VoucherModel _toModel(Voucher v) {
    return VoucherModel(
      id: v.id,
      voucherNumber: v.voucherNumber,
      voucherType: v.voucherType,
      treasuryId: v.treasuryId,
      fiscalPeriodId: v.fiscalPeriodId,
      amount: v.amount,
      currency: v.currency,
      exchangeRate: v.exchangeRate,
      voucherDate: v.voucherDate,
      personName: v.personName,
      reason: v.reason,
      itemType: v.itemType,
      referenceNumber: v.referenceNumber,
      closeSafe: v.closeSafe,
      linkedTreasuryId: v.linkedTreasuryId,
      linkedEntityId: v.linkedEntityId,
      // حقول تتبّع المصروفات — كانت تُسقَط هنا فتصل الشاشة فارغة دائماً
      projectName: v.projectName,
      invoiceNumber: v.invoiceNumber,
      spentBy: v.spentBy,
      advanceNumber: v.advanceNumber,
      isDeleted: v.isDeleted,
      deletedAt: v.deletedAt,
    );
  }

  /// تحويل سطر كشف حساب Drift إلى نموذج Domain
  AccountStatementModel _toStatementModel(AccountStatementRow row) {
    return AccountStatementModel(
      voucher: _toModel(row.voucher),
      runningBalanceIqd: row.runningBalanceIqd,
      runningBalanceUsd: row.runningBalanceUsd,
    );
  }

  // ── تنفيذ الواجهة ─────────────────────────────────────────────────────────

  @override
  Stream<List<VoucherModel>> watchVouchersByTreasury(int treasuryId) {
    return _db.vouchersDao
        .watchVouchersByTreasury(treasuryId)
        .map((list) => list.map(_toModel).toList());
  }

  @override
  Stream<List<VoucherModel>> watchVouchersByType(String voucherType) {
    return _db.vouchersDao
        .watchVouchersByType(voucherType)
        .map((list) => list.map(_toModel).toList());
  }

  @override
  Future<List<VoucherModel>> getVouchersByDateRange({
    required DateTime from,
    required DateTime to,
    int? treasuryId,
    String? voucherType,
    int? fiscalPeriodId,
  }) async {
    final list = await _db.vouchersDao.getVouchersByDateRange(
      from: from,
      to: to,
      treasuryId: treasuryId,
      voucherType: voucherType,
      fiscalPeriodId: fiscalPeriodId,
    );
    return list.map(_toModel).toList();
  }

  @override
  Future<List<VoucherModel>> searchVouchers(String query) async {
    final list = await _db.vouchersDao.searchVouchers(query);
    return list.map(_toModel).toList();
  }

  @override
  Future<List<AccountStatementModel>> getAccountStatement({
    required int treasuryId,
    required DateTime from,
    required DateTime to,
    double openingBalanceIqd = 0,
    double openingBalanceUsd = 0,
  }) async {
    final rows = await _db.vouchersDao.getAccountStatement(
      treasuryId: treasuryId,
      from: from,
      to: to,
      openingBalanceIqd: openingBalanceIqd,
      openingBalanceUsd: openingBalanceUsd,
    );
    return rows.map(_toStatementModel).toList();
  }

  @override
  Future<
      ({
        double totalSarf,
        double totalKabd,
        double totalSarfUsd,
        double totalKabdUsd,
      })> getDailySummary(
    DateTime date,
  ) {
    return _db.vouchersDao.getDailySummary(date);
  }

  /// حارس الفترة المالية — يرمي استثناءً إذا كانت الفترة غير نشطة
  ///
  /// المنطق انتقل إلى [FiscalPeriodGuard] لمّا صار مستودع السلف يحتاجه أيضاً،
  /// فبقيت هذه الدالة غلافاً رفيعاً حفاظاً على مواضع الاستدعاء الأربعة أدناه.
  Future<void> _ensurePeriodActive(int fiscalPeriodId) {
    return FiscalPeriodGuard.ensureActive(_db, fiscalPeriodId);
  }

  /// حارس الخزينة — يرمي إن كانت معطَّلة أو محذوفة
  ///
  /// أُضيف 2026-08-30 (بلاغ المالك): عمود `is_active` كان موجوداً وله مبدّل
  /// في الواجهة، **ولا يفحصه أي مسار كتابة** — فالمال يدخل خزينةً أوقفها
  /// المالك بنفسه. نمط ع-٠٦: حقلٌ يُكتَب ولا يُقرأ.
  Future<void> _ensureTreasuryActive(int treasuryId, String action) {
    return TreasuryStateGuard.ensureActive(_db, treasuryId, action: action);
  }

  /// وصف العملية بلغة المالك حسب نوع السند — ليقول المنعُ **ما مُنع**
  static String _actionOf(String voucherType) => switch (voucherType) {
        'kabd' => 'القبض في',
        'sarf' => 'الصرف من',
        _ => 'إدخال حركة على',
      };

  @override
  Future<int> createVoucher({
    required int fiscalPeriodId,
    required String voucherType,
    required int treasuryId,
    required double amount,
    required String currency,
    required DateTime voucherDate,
    String personName = '',
    String reason = '',
    String itemType = '',
    String referenceNumber = '',
    bool closeSafe = false,
    int? linkedTreasuryId,
    int? linkedEntityId,
    double exchangeRate = 1.0,
    int? createdByUserId,
    String? projectName,
    String? invoiceNumber,
    String? spentBy,
    String? advanceNumber,
  }) async {
    // 0. التأكد أن الفترة نشطة (دفاع في العمق حتى لو مرّر المستدعي فترة مقفلة)
    await _ensurePeriodActive(fiscalPeriodId);

    // 0-ب. والخزينة نشطة — لا حركة جديدة على خزينة أوقفها المالك
    await _ensureTreasuryActive(treasuryId, _actionOf(voucherType));

    // 1. الحصول على رقم السند التالي (ذري)
    final voucherNumber = await _db.fiscalPeriodsDao.getNextVoucherNumber(
      fiscalPeriodId: fiscalPeriodId,
      voucherType: voucherType,
    );

    // 2. إدراج السند
    return _db.vouchersDao.insertVoucher(
      VouchersCompanion.insert(
        voucherNumber: voucherNumber,
        voucherType: voucherType,
        treasuryId: treasuryId,
        fiscalPeriodId: fiscalPeriodId,
        amount: amount,
        // currency له قيمة افتراضية 'IQD' → يجب تغليفه بـ Value()
        currency: Value(currency),
        exchangeRate: Value(exchangeRate),
        voucherDate: voucherDate,
        personName: Value(personName),
        reason: Value(reason),
        itemType: Value(itemType),
        referenceNumber: Value(referenceNumber),
        closeSafe: Value(closeSafe),
        linkedTreasuryId: Value(linkedTreasuryId),
        linkedEntityId: Value(linkedEntityId),
        createdByUserId: Value(createdByUserId),
        // ── تتبّع المصروفات ───────────────────────────────────────────
        // نحوّل النصّ الفارغ إلى null عمداً: العمود nullable، وتخزين ''
        // يجعل الفلترة والتقارير تعامله كقيمة قائمة لا كغياب.
        projectName: Value(_orNull(projectName)),
        invoiceNumber: Value(_orNull(invoiceNumber)),
        spentBy: Value(_orNull(spentBy)),
        advanceNumber: Value(_orNull(advanceNumber)),
      ),
    );
  }

  /// نصّ فارغ أو مقصوص إلى فراغ ← null
  ///
  /// الأعمدة الأربعة nullable، وتخزين '' فيها يجعل الفلترة تظنّها قيمة
  /// موجودة. القاعدة: **الغياب يُمثَّل بـ null دائماً لا بنصّ فارغ.**
  static String? _orNull(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  @override
  Future<({int outId, int inId})> createTransfer({
    required int fromTreasuryId,
    required int toTreasuryId,
    required double amount,
    required String currency,
    required int fiscalPeriodId,
    required DateTime voucherDate,
    String reason = '',
    int? createdByUserId,
    double exchangeRate = 1.0,
  }) async {
    // التأكد أن الفترة نشطة قبل أي كتابة
    await _ensurePeriodActive(fiscalPeriodId);

    // والخزينتان نشطتان — المصدر أولاً: لو فُحصت الوجهة أولاً لظهرت رسالة
    // عن خزينةٍ لم يصلها المال أصلاً، والمانع الحقيقي في مصدره.
    await TreasuryStateGuard.ensureTransferAllowed(
      _db,
      fromTreasuryId: fromTreasuryId,
      toTreasuryId: toTreasuryId,
    );

    // الحصول على رقمَي السند التاليَين
    final outNumber = await _db.fiscalPeriodsDao.getNextVoucherNumber(
      fiscalPeriodId: fiscalPeriodId,
      voucherType: 'transfer_out',
    );
    final inNumber = await _db.fiscalPeriodsDao.getNextVoucherNumber(
      fiscalPeriodId: fiscalPeriodId,
      voucherType: 'transfer_in',
    );

    // بناء السندين
    final outVoucher = VouchersCompanion.insert(
      voucherNumber: outNumber,
      voucherType: 'transfer_out',
      treasuryId: fromTreasuryId,
      fiscalPeriodId: fiscalPeriodId,
      amount: amount,
      // currency له قيمة افتراضية → Value()
      currency: Value(currency),
      exchangeRate: Value(exchangeRate),
      voucherDate: voucherDate,
      reason: Value(reason),
      linkedTreasuryId: Value(toTreasuryId),
      createdByUserId: Value(createdByUserId),
    );

    final inVoucher = VouchersCompanion.insert(
      voucherNumber: inNumber,
      voucherType: 'transfer_in',
      treasuryId: toTreasuryId,
      fiscalPeriodId: fiscalPeriodId,
      amount: amount,
      // currency له قيمة افتراضية → Value()
      currency: Value(currency),
      exchangeRate: Value(exchangeRate),
      voucherDate: voucherDate,
      reason: Value(reason),
      linkedTreasuryId: Value(fromTreasuryId),
      createdByUserId: Value(createdByUserId),
    );

    // تنفيذ كلا السندين في Transaction واحدة
    return _db.vouchersDao.insertTransfer(
      outVoucher: outVoucher,
      inVoucher: inVoucher,
    );
  }

  @override
  Future<void> updateVoucher(VoucherModel voucher, {int? updatedByUserId}) async {
    // ── حاجز 1: سندات التحويل لا تُعدَّل إطلاقاً ────────────────────────
    //
    // ⚠️ لماذا المنع بدل المزامنة؟ (إصلاح ح-١ — تدقيق 2026-08-15)
    //   التحويل سندان توأمان يربطهما transfer_group_id. تعديل أحدهما وحده
    //   يخلق مالاً من العدم أو يُبخّره: تحويل 3 مليون يُعدَّل إلى 1 مليون
    //   يجعل الخزينة المُرسِلة تفقد 1 مليون بينما المُستقبِلة استلمت 3.
    //   وكان هذا ممكناً فعلياً لأن قائمة السندات توجّه سند التحويل إلى شاشة
    //   تعديل الصرف/القبض التي لا تفحص النوع.
    //   المنع هنا هو الحاجز الحقيقي — يبقى قائماً مهما تغيّرت الواجهات.
    //   التصحيح يتم بالحذف (يحذف الطرفين ذرّياً) ثم إعادة الإنشاء.
    if (voucher.voucherType == 'transfer_out' ||
        voucher.voucherType == 'transfer_in') {
      throw StateError(
        'لا يمكن تعديل سند تحويل — التحويل سندان مرتبطان، وتعديل أحدهما '
        'يخلّ بتوازن الخزينتين.\n'
        'احذف التحويل (يُحذف الطرفان معاً) ثم أنشئه من جديد بالقيم الصحيحة.',
      );
    }

    // ── حاجز 2: منع تعديل سند داخل فترة مُقفَلة (يغيّر أرصدة تاريخية) ──
    await _ensurePeriodActive(voucher.fiscalPeriodId);

    // ── حاجز 2-ب: والخزينة المستهدَفة نشطة ─────────────────────────────
    // التعديل يُغيّر رصيداً كالإنشاء تماماً — ونقلُ سندٍ إلى خزينة معطَّلة
    // بابٌ خلفيّ لما مُنع في الإنشاء.
    await _ensureTreasuryActive(
      voucher.treasuryId,
      _actionOf(voucher.voucherType),
    );

    // ── حاجز 3: منع نقل السند إلى سنة مالية أخرى (إصلاح ح-٥) ──────────
    //
    // كان updateVoucher يكتب fiscalPeriodId الأصلية دائماً، فنقل تاريخ سند
    // من ديسمبر 2025 إلى يناير 2026 يُبقيه محسوباً في 2025 ← تقارير
    // السنتين خاطئة والمستخدم لا يرى شيئاً.
    //
    // لماذا الرفض بدل إعادة التصنيف تلقائياً؟
    //   رقم السند مُخصَّص من تسلسل سنته. نقله يترك ثغرة في تسلسل السنة
    //   القديمة ورقماً قد يتكرر في الجديدة. الرفض أصدق، ويطابق نهج
    //   «امنع وأعد الإنشاء» المعتمد في تعديل التحويلات.
    final targetPeriod =
        await _db.fiscalPeriodsDao.getFiscalPeriodForDate(voucher.voucherDate);
    if (targetPeriod == null) {
      throw StateError(
        'لا توجد فترة مالية نشطة للتاريخ المُدخَل — تحقق من التاريخ أو '
        'افتح السنة المالية المناسبة أولاً.',
      );
    }
    if (targetPeriod.id != voucher.fiscalPeriodId) {
      throw StateError(
        'لا يمكن نقل سند إلى سنة مالية أخرى (${targetPeriod.name}).\n'
        'رقم السند مرتبط بتسلسل سنته الأصلية. احذف السند وأنشئه من جديد '
        'بالتاريخ الصحيح.',
      );
    }
    await _db.vouchersDao.updateVoucher(
      VouchersCompanion(
        id: Value(voucher.id),
        voucherNumber: Value(voucher.voucherNumber),
        voucherType: Value(voucher.voucherType),
        treasuryId: Value(voucher.treasuryId),
        fiscalPeriodId: Value(voucher.fiscalPeriodId),
        amount: Value(voucher.amount),
        currency: Value(voucher.currency),
        exchangeRate: Value(voucher.exchangeRate),
        voucherDate: Value(voucher.voucherDate),
        personName: Value(voucher.personName),
        reason: Value(voucher.reason),
        itemType: Value(voucher.itemType),
        referenceNumber: Value(voucher.referenceNumber),
        closeSafe: Value(voucher.closeSafe),
        linkedTreasuryId: Value(voucher.linkedTreasuryId),
        linkedEntityId: Value(voucher.linkedEntityId),
        // حقول تتبّع المصروفات — لم تكن تُكتب فكان التعديل يفقدها
        projectName: Value(_orNull(voucher.projectName)),
        invoiceNumber: Value(_orNull(voucher.invoiceNumber)),
        spentBy: Value(_orNull(voucher.spentBy)),
        advanceNumber: Value(_orNull(voucher.advanceNumber)),
        // ── أثر التعديل على الصف نفسه (إصلاح ث-٣) ───────────────────────
        //
        // العمودان موجودان في الجدول منذ البداية وكان التعديل لا يكتبهما
        // إطلاقاً، فيبقيان على قيمة لحظة الإنشاء. النتيجة أن فحص قاعدة
        // البيانات مباشرةً لا يكشف أن السند عُدِّل أصلاً — وهو خط الدفاع
        // الأخير لو ضاع سجل التدقيق أو أُفرغ.
        updatedAt: Value(DateTime.now()),
        updatedByUserId: Value(updatedByUserId),
      ),
    );
  }

  @override
  Future<void> deleteVoucher(int id, {int? deletedByUserId}) async {
    // ⚠️ **لا حارس خزينة هنا عمداً:** التعطيل يمنع الحركة **الجديدة** لا
    //   تصحيح القديمة. ولو مُنع الحذف على خزينة معطَّلة لصار سندٌ أُدخل
    //   بالخطأ محبوساً إلى الأبد — والمالك يعطّل الخزينة عادةً **بعد** أن
    //   يكتشف الخطأ لا قبله.
    //
    // منع حذف سند داخل فترة مُقفَلة
    final voucher = await _db.vouchersDao.getVoucherById(id);
    if (voucher != null) {
      await _ensurePeriodActive(voucher.fiscalPeriodId);
    }
    await _db.vouchersDao.softDeleteVoucher(
      id,
      deletedByUser: deletedByUserId,
    );
  }
}
