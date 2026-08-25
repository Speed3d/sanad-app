// ─────────────────────────────────────────────────────────────────────────────
// advance_repository.dart — تنفيذ مستودع سلف المشاريع
//
// ⚠️ Advances (سلفة مشروع) ≠ CashAdvances (سلفة موظف تُسدَّد من الراتب)
//
// هنا تعيش **قواعد العمل**، بينما الذرّية مسؤولية AdvancesDao. الفصل مقصود:
//   المستودع  → متى يجوز الاعتماد؟ كم العجز؟ هل الفترة مفتوحة؟
//   الـ DAO    → نفّذ الاعتماد كله أو لا شيء منه
//
// القاعدة التي يقوم عليها التصميم:
//   إنشاء السلفة وبناء المسودة وتعديلها **لا تمسّ رصيد أي خزينة إطلاقاً**.
//   الأثر المالي يقع في تابع واحد فقط: postAdvance().
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

import '../../core/services/fiscal_period_guard.dart';
import '../../core/services/payroll_calculator.dart';
import '../../domain/models/advance_model.dart';
import '../../domain/repositories/i_advance_repository.dart';
import '../database/app_database.dart';
import '../database/daos/advances_dao.dart'
    show AdvanceStatusDb, PayrollLinkPreview;

/// تنفيذ مستودع سلف المشاريع باستخدام Drift
class AdvanceRepository implements IAdvanceRepository {
  final AppDatabase _db;

  const AdvanceRepository(this._db);

  // ── تحويل البيانات ────────────────────────────────────────────────────────

  AdvanceModel _toModel(Advance a) => AdvanceModel(
        id: a.id,
        advanceNumber: a.advanceNumber,
        projectTreasuryId: a.projectTreasuryId,
        fiscalPeriodId: a.fiscalPeriodId,
        projectName: a.projectName,
        advanceDate: a.advanceDate,
        status: a.status,
        excelTotal: a.excelTotal,
        sourceFileName: a.sourceFileName,
        sourceFileHash: a.sourceFileHash,
        deficitAmount: a.deficitAmount,
        deficitCoveredBy: a.deficitCoveredBy,
        notes: a.notes,
        createdByUserId: a.createdByUserId,
        createdAt: a.createdAt,
        postedByUserId: a.postedByUserId,
        postedAt: a.postedAt,
        cancelledByUserId: a.cancelledByUserId,
        cancelledAt: a.cancelledAt,
      );

  AdvanceLineModel _toLineModel(AdvanceLine l) => AdvanceLineModel(
        id: l.id,
        advanceId: l.advanceId,
        rowNumber: l.rowNumber,
        voucherDate: l.voucherDate,
        amount: l.amount,
        itemType: l.itemType,
        reason: l.reason,
        personName: l.personName,
        projectName: l.projectName,
        invoiceNumber: l.invoiceNumber,
        spentBy: l.spentBy,
        originalAmount: l.originalAmount,
        originalItemType: l.originalItemType,
        originalDate: l.originalDate,
        isEdited: l.isEdited,
        isExcluded: l.isExcluded,
        excludeReason: l.excludeReason,
        voucherId: l.voucherId,
        payrollPeriodId: l.payrollPeriodId,
      );

  // ── قراءة ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<AdvanceModel>> watchAdvances({String? status}) {
    return _db.advancesDao
        .watchAdvances(status: status)
        .map((rows) => rows.map(_toModel).toList());
  }

  @override
  Stream<AdvanceModel?> watchAdvance(int id) {
    return _db.advancesDao
        .watchAdvanceById(id)
        .map((a) => a == null ? null : _toModel(a));
  }

  @override
  Future<AdvanceModel?> getAdvance(int id) async {
    final a = await _db.advancesDao.getAdvanceById(id);
    return a == null ? null : _toModel(a);
  }

  @override
  Future<List<AdvanceModel>> getActiveAdvancesForTreasury(
    int treasuryId,
  ) async {
    final rows =
        await _db.advancesDao.getActiveAdvancesForTreasury(treasuryId);
    return rows.map(_toModel).toList();
  }

  @override
  Stream<List<AdvanceLineModel>> watchLines(int advanceId) {
    return _db.advancesDao
        .watchLines(advanceId)
        .map((rows) => rows.map(_toLineModel).toList());
  }

  @override
  Future<AdvanceModel?> findByFileHash(String hash) async {
    final a = await _db.advancesDao.findByFileHash(hash);
    return a == null ? null : _toModel(a);
  }

  /// ملخص السلفة — الأرقام التي تظهر في شريط المطابقة
  ///
  /// المصروف يُقرأ من مصدرين حسب الحالة:
  ///   مسودة  → مجموع أسطر المسودة غير المستبعدة (لا سندات بعد)
  ///   معتمدة → مجموع سندات الصرف المرتبطة (الحقيقة النهائية في الدفاتر)
  @override
  Future<AdvanceSummary> getSummary(int advanceId) async {
    final advance = await _db.advancesDao.getAdvanceById(advanceId);
    if (advance == null) return const AdvanceSummary();

    final sent = await _db.advancesDao.getSentAmount(
      advanceId: advanceId,
      projectTreasuryId: advance.projectTreasuryId,
    );

    final balanceRow =
        await _db.treasuriesDao.getTreasuryBalance(advance.projectTreasuryId);
    final balance = balanceRow?.balanceIqd ?? 0.0;

    double spent;
    int counted = 0;
    int excluded = 0;
    int edited = 0;

    if (advance.status == 'posted') {
      spent = await _db.advancesDao.getPostedSpent(advanceId);
      final lines = await _db.advancesDao.getLines(advanceId);
      counted = lines.where((l) => !l.isExcluded).length;
      excluded = lines.where((l) => l.isExcluded).length;
      edited = lines.where((l) => l.isEdited).length;
    } else {
      final lines = await _db.advancesDao.getLines(advanceId);
      spent = lines
          .where((l) => !l.isExcluded)
          .fold<double>(0, (sum, l) => sum + l.amount);
      counted = lines.where((l) => !l.isExcluded).length;
      excluded = lines.where((l) => l.isExcluded).length;
      edited = lines.where((l) => l.isEdited).length;
    }

    return AdvanceSummary(
      sent: sent,
      spent: spent,
      excelTotal: advance.excelTotal,
      treasuryBalance: balance,
      countedLines: counted,
      excludedLines: excluded,
      editedLines: edited,
      // بعد الاعتماد يصير العجز رقماً مُثبَّتاً لا محسوباً — راجع
      // AdvanceSummaryX.deficit
      isPosted: advance.status == 'posted',
      postedDeficit: advance.deficitAmount,
    );
  }

  // ── إنشاء السلفة ──────────────────────────────────────────────────────────

  @override
  Future<int> createAdvance({
    required String advanceNumber,
    required int projectTreasuryId,
    required DateTime advanceDate,
    String projectName = '',
    String notes = '',
    int? createdByUserId,
  }) async {
    final number = advanceNumber.trim();
    if (number.isEmpty) {
      throw StateError('رقم السلفة مطلوب.');
    }

    // الفترة المالية تُحدَّد من تاريخ السلفة لا من وقت الإدخال
    final period =
        await _db.fiscalPeriodsDao.getFiscalPeriodForDate(advanceDate);
    if (period == null) {
      throw StateError(
        'لا توجد فترة مالية نشطة لتاريخ ${advanceDate.year}/'
        '${advanceDate.month}/${advanceDate.day}.',
      );
    }

    // فحص استباقي لإعطاء رسالة مفهومة بدل استثناء SQLite من الفهرس الفريد
    final taken = await _db.advancesDao.isAdvanceNumberTaken(
      advanceNumber: number,
      fiscalPeriodId: period.id,
    );
    if (taken) {
      throw StateError(
        'رقم السلفة "$number" مستعمَل في السنة المالية ${period.name}. '
        'اختر رقماً آخر.',
      );
    }

    // اسم المشروع الافتراضي = اسم خزينة المشروع
    var name = projectName.trim();
    if (name.isEmpty) {
      final treasury =
          await _db.treasuriesDao.getTreasuryById(projectTreasuryId);
      name = treasury?.name ?? '';
    }

    return _db.advancesDao.insertAdvance(
      AdvancesCompanion.insert(
        advanceNumber: number,
        projectTreasuryId: projectTreasuryId,
        fiscalPeriodId: period.id,
        advanceDate: advanceDate,
        projectName: Value(name),
        notes: Value(notes),
        createdByUserId: Value(createdByUserId),
      ),
    );
  }

  @override
  Future<void> linkTransferVouchers({
    required int advanceId,
    required List<int> voucherIds,
  }) async {
    if (voucherIds.isEmpty) return;
    final advance = await _db.advancesDao.getAdvanceById(advanceId);
    if (advance == null) {
      throw StateError('السلفة غير موجودة.');
    }
    await (_db.update(_db.vouchers)..where((v) => v.id.isIn(voucherIds)))
        .write(
      AdvancesLinkCompanion.forVouchers(
        advanceId: advanceId,
        advanceNumber: advance.advanceNumber,
      ),
    );
  }

  // ── بناء المسودة ──────────────────────────────────────────────────────────

  @override
  Future<void> createDraftFromExcel({
    required int advanceId,
    required List<ParsedAdvanceLine> lines,
    required String fileName,
    required String fileHash,
    bool replaceExisting = false,
  }) async {
    if (lines.isEmpty) {
      throw StateError('الملف لا يحتوي على أي سطر صالح.');
    }

    final advance = await _db.advancesDao.getAdvanceById(advanceId);
    if (advance == null) {
      throw StateError('السلفة غير موجودة.');
    }
    if (advance.status == 'posted') {
      throw StateError(
        'السلفة رقم ${advance.advanceNumber} معتمدة بالفعل — لا يمكن '
        'استيراد مصاريف جديدة عليها. أنشئ سلفة جديدة.',
      );
    }
    if (advance.status == 'cancelled') {
      throw StateError('السلفة ملغاة — لا يمكن الاستيراد عليها.');
    }

    // الفترة المالية يجب أن تكون مفتوحة حتى لبناء المسودة، وإلا بنى المستخدم
    // مسودة كاملة ثم اصطدم بالرفض عند الاعتماد بعد ضياع وقته في المراجعة.
    await FiscalPeriodGuard.ensureActive(_db, advance.fiscalPeriodId);

    final excelTotal = lines.fold<double>(0, (sum, l) => sum + l.amount);

    await _db.transaction(() async {
      if (replaceExisting) {
        await _db.advancesDao.deleteLines(advanceId);
      }

      await _db.advancesDao.insertLines(
        lines
            .map(
              (l) => AdvanceLinesCompanion.insert(
                advanceId: advanceId,
                rowNumber: Value(l.rowNumber),
                voucherDate: l.date,
                amount: l.amount,
                itemType: Value(l.itemType),
                reason: Value(l.reason),
                personName: Value(l.personName),
                projectName: Value(l.projectName),
                invoiceNumber: Value(l.invoiceNumber),
                spentBy: Value(l.spentBy),
                // القيم الأصلية = ما وصل من الملف بالضبط، لا تتغير أبداً
                originalAmount: l.amount,
                originalItemType: Value(l.itemType),
                originalDate: l.date,
              ),
            )
            .toList(),
      );

      await _db.advancesDao.updateAdvance(
        AdvancesCompanion(
          id: Value(advanceId),
          status: const Value('draft'),
          excelTotal: Value(excelTotal),
          sourceFileName: Value(fileName),
          sourceFileHash: Value(fileHash),
        ),
      );
    });
  }

  // ── تحرير المسودة ─────────────────────────────────────────────────────────

  @override
  Future<void> updateLine({
    required int lineId,
    DateTime? date,
    double? amount,
    String? itemType,
    String? reason,
    String? personName,
    String? projectName,
    String? invoiceNumber,
    String? spentBy,
  }) async {
    final line = await (_db.select(_db.advanceLines)
          ..where((l) => l.id.equals(lineId)))
        .getSingleOrNull();
    if (line == null) {
      throw StateError('السطر غير موجود.');
    }

    final advance = await _db.advancesDao.getAdvanceById(line.advanceId);
    if (advance == null || advance.status != 'draft') {
      throw StateError(
        'لا يمكن تعديل الأسطر إلا وهي مسودة — هذه السلفة '
        '${advance == null ? 'غير موجودة' : 'حالتها ${advance.status}'}.',
      );
    }

    if (amount != null && amount <= 0) {
      throw StateError('المبلغ يجب أن يكون أكبر من صفر.');
    }

    final newAmount = amount ?? line.amount;
    final newItemType = itemType ?? line.itemType;
    final newDate = date ?? line.voucherDate;

    // علامة «معدَّل» تُحسَب بمقارنة القيم الجديدة بالأصلية لا بالسابقة:
    // لو أعاد المستخدم القيمة إلى أصلها، يجب أن تختفي العلامة لا أن تبقى.
    final isEdited = (newAmount - line.originalAmount).abs() > 0.001 ||
        newItemType != line.originalItemType ||
        !newDate.isAtSameMomentAs(line.originalDate);

    await _db.advancesDao.updateLine(
      AdvanceLinesCompanion(
        id: Value(lineId),
        voucherDate: Value(newDate),
        amount: Value(newAmount),
        itemType: Value(newItemType),
        reason: Value(reason ?? line.reason),
        personName: Value(personName ?? line.personName),
        projectName: Value(projectName ?? line.projectName),
        invoiceNumber: Value(invoiceNumber ?? line.invoiceNumber),
        spentBy: Value(spentBy ?? line.spentBy),
        isEdited: Value(isEdited),
      ),
    );
  }

  @override
  Future<void> setLineExcluded({
    required int lineId,
    required bool excluded,
    String reason = '',
  }) async {
    final line = await (_db.select(_db.advanceLines)
          ..where((l) => l.id.equals(lineId)))
        .getSingleOrNull();
    if (line == null) {
      throw StateError('السطر غير موجود.');
    }

    final advance = await _db.advancesDao.getAdvanceById(line.advanceId);
    if (advance == null || advance.status != 'draft') {
      throw StateError('لا يمكن استبعاد الأسطر إلا وهي مسودة.');
    }

    await _db.advancesDao.updateLine(
      AdvanceLinesCompanion(
        id: Value(lineId),
        isExcluded: Value(excluded),
        excludeReason: Value(excluded ? reason : ''),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ربط الرواتب (Schema v7)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<int> linkLineToPayroll({
    required int lineId,
    required int payrollPeriodId,
  }) async {
    final line = await _db.advancesDao.getLineById(lineId);
    if (line == null) throw StateError('سطر المسودة غير موجود.');

    final advance = await _db.advancesDao.getAdvanceById(line.advanceId);
    if (advance == null) throw StateError('السلفة غير موجودة.');
    if (advance.status != AdvanceStatusDb.draft) {
      throw StateError(
        'الربط متاح في المسودة فقط — السلفة رقم ${advance.advanceNumber} '
        'حالتها «${advance.status}».',
      );
    }

    final period = await _db.payrollDao.getPeriodById(payrollPeriodId);
    if (period == null) throw StateError('كشف الرواتب غير موجود.');
    if (period.status == PayrollStatusDb.posted) {
      throw StateError(
        'كشف ${PayrollCalculator.periodLabel(period.year, period.month)} '
        'مُسدَّد بالفعل — لا يُربط بسلفة.',
      );
    }

    final count = await _db.advancesDao.linkLineToPayroll(
      lineId: lineId,
      payrollPeriodId: payrollPeriodId,
      projectTreasuryId: advance.projectTreasuryId,
    );

    if (count == 0) {
      // نفكّ الربط فوراً بدل تركه رباطاً فارغاً يُفشل الاعتماد لاحقاً
      await _db.advancesDao.unlinkLineFromPayroll(lineId);
      throw StateError(
        'لا يوجد في كشف '
        '${PayrollCalculator.periodLabel(period.year, period.month)} '
        'موظف واحد غير مسدَّد تابع لخزينة «${advance.projectName}».\n'
        'تأكّد أن خزينة الموظفين في بطاقاتهم هي خزينة هذا المشروع.',
      );
    }
    return count;
  }

  @override
  Future<void> unlinkLineFromPayroll(int lineId) =>
      _db.advancesDao.unlinkLineFromPayroll(lineId);

  @override
  Future<List<PayrollLinkPreview>> getPayrollLinkPreviews(int advanceId) =>
      _db.advancesDao.getPayrollLinkPreviews(advanceId);

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔑 الاعتماد — اللحظة الوحيدة التي تتأثر فيها الخزينة
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<PostAdvanceOutcome> postAdvance({
    required int advanceId,
    bool allowDeficit = false,
    String? deficitCoveredBy,
    int? postedByUserId,
  }) async {
    // ── 1. الحالة: مسودة فقط (يمنع الاعتماد المزدوج) ────────────────────
    final advance = await _db.advancesDao.getAdvanceById(advanceId);
    if (advance == null) {
      return const PostAdvanceOutcome(
        success: false,
        message: 'السلفة غير موجودة.',
      );
    }
    if (advance.status != 'draft') {
      return PostAdvanceOutcome(
        success: false,
        message: advance.status == 'posted'
            ? 'السلفة رقم ${advance.advanceNumber} معتمدة بالفعل — لا يمكن '
                'اعتمادها مرتين.'
            : 'لا يمكن اعتماد سلفة حالتها "${advance.status}".',
      );
    }

    // ── 2. الفترة المالية مفتوحة ─────────────────────────────────────────
    await FiscalPeriodGuard.ensureActive(_db, advance.fiscalPeriodId);

    // ── 3. إجمالي الأسطر الداخلة في الاعتماد ─────────────────────────────
    final lines = await _db.advancesDao.getLines(advanceId);
    final counted = lines.where((l) => !l.isExcluded).toList();
    if (counted.isEmpty) {
      return const PostAdvanceOutcome(
        success: false,
        message: 'لا توجد أسطر قابلة للاعتماد — كل الأسطر مستبعَدة.',
      );
    }
    final total = counted.fold<double>(0, (sum, l) => sum + l.amount);

    // ── 4. رصيد الخزينة ──────────────────────────────────────────────────
    // نقرأ من getTreasuryBalance نفسها التي يستخدمها BalanceGuard، فلا
    // يختلف الرقمان أبداً بين مسار الصرف العادي ومسار اعتماد السلفة.
    final balanceRow =
        await _db.treasuriesDao.getTreasuryBalance(advance.projectTreasuryId);
    final available = balanceRow?.balanceIqd ?? 0.0;

    // ── 5. قرار العجز ────────────────────────────────────────────────────
    final rawDeficit = total - available;
    final deficit = rawDeficit > 0.001 ? rawDeficit : 0.0;

    if (deficit > 0) {
      // العجز حقيقي: صرف المشروع أكثر مما في خزينته. لا نمنع — لأن المال
      // صُرف فعلاً وغطّاه أحدهم — لكن لا نمرّره صامتاً أيضاً.
      if (!allowDeficit) {
        return PostAdvanceOutcome(
          success: false,
          deficit: deficit,
          needsDeficitConfirmation: true,
          message:
              'مصاريف السلفة (${_fmt(total)}) تتجاوز رصيد خزينة المشروع '
              '(${_fmt(available)}) بمقدار ${_fmt(deficit)}.\n'
              'الاعتماد سيجعل رصيد الخزينة سالباً — أي أن الشركة مدينة '
              'بهذا المبلغ لمن غطّاه.',
        );
      }
      if (deficitCoveredBy == null || deficitCoveredBy.trim().isEmpty) {
        return PostAdvanceOutcome(
          success: false,
          deficit: deficit,
          needsDeficitConfirmation: true,
          message: 'حدّد اسم من غطّى العجز (${_fmt(deficit)}) قبل الاعتماد — '
              'بدونه يضيع الدَّين ولا يُعرَف لمن تدين الشركة.',
        );
      }
    }

    // ── 6. التنفيذ الذرّي ────────────────────────────────────────────────
    final result = await _db.advancesDao.postAdvance(
      advanceId: advanceId,
      deficitAmount: deficit,
      deficitCoveredBy: deficit > 0 ? deficitCoveredBy!.trim() : null,
      postedByUserId: postedByUserId,
    );

    final msg = StringBuffer(
      'تم اعتماد السلفة رقم ${advance.advanceNumber} — '
      '${result.voucherIds.length} سند صرف بإجمالي ${_fmt(result.totalPosted)}',
    );
    if (deficit > 0) {
      msg.write(
        '.\n⚠ خزينة المشروع أصبحت بعجز ${_fmt(deficit)} '
        'مستحق لـ ${deficitCoveredBy!.trim()}',
      );
    }

    // ── أثر الرواتب في الرسالة (Schema v7) ────────────────────────────────
    // الاعتماد الواحد صار حدثاً في نظامين. ورسالةٌ تذكر السندات وحدها تُخفي
    // أن رواتب خمسة وعشرين موظفاً صارت مسدَّدة في اللحظة نفسها.
    if (result.payrollEmployeesPaid > 0) {
      msg.write('.\n✓ وسُدِّدت رواتب ${result.payrollEmployeesPaid} موظفاً');
      if (result.payrollPeriodsCompleted.isNotEmpty) {
        msg.write('، واكتمل كشف ${result.payrollPeriodsCompleted.join(' و')}');
      }
    }

    return PostAdvanceOutcome(
      success: true,
      message: msg.toString(),
      deficit: deficit,
      vouchersCreated: result.voucherIds.length,
      payrollEmployeesPaid: result.payrollEmployeesPaid,
      payrollPeriodsCompleted: result.payrollPeriodsCompleted,
    );
  }

  @override
  Future<CancelAdvanceInfo> cancelAdvance({
    required int advanceId,
    int? cancelledByUserId,
  }) async {
    final advance = await _db.advancesDao.getAdvanceById(advanceId);
    if (advance == null) {
      throw StateError('السلفة غير موجودة.');
    }
    if (advance.status == 'cancelled') {
      throw StateError('السلفة ملغاة بالفعل.');
    }

    // إلغاء سلفة معتمدة يحذف سنداتها فيغيّر أرصدة الفترة — ممنوع في فترة
    // مُقفَلة تماماً كأي تعديل محاسبي آخر.
    await FiscalPeriodGuard.ensureActive(_db, advance.fiscalPeriodId);

    // نقرأ ما سيُعكَس **قبل** الإلغاء، لأن الحذف الناعم يُخفيه بعده فلا يبقى
    // في سجل التدقيق أثر لحجم ما تراجعنا عنه.
    final reversedAmount = await _db.advancesDao.getPostedSpent(advanceId);
    final reversedCount = (await _db.advancesDao.getLines(advanceId))
        .where((l) => l.voucherId != null)
        .length;

    await _db.advancesDao.cancelAdvance(
      advanceId: advanceId,
      cancelledByUserId: cancelledByUserId,
    );

    return CancelAdvanceInfo(
      advanceNumber: advance.advanceNumber,
      previousStatus: advance.status,
      vouchersReversed: reversedCount,
      reversedAmount: reversedAmount,
    );
  }

  /// تنسيق مبلغ بالدينار للرسائل العربية
  String _fmt(double v) {
    final s = v.abs().toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${v < 0 ? '-' : ''}$buf د.ع';
  }
}

/// مساعد بناء تحديث ربط السندات بالسلفة
///
/// موجود كصنف منفصل لأن VouchersCompanion يحتاج حقلين فقط هنا، وتكرار
/// بنائه في أكثر من موضع يفتح باب نسيان أحدهما.
abstract final class AdvancesLinkCompanion {
  static VouchersCompanion forVouchers({
    required int advanceId,
    required String advanceNumber,
  }) {
    return VouchersCompanion(
      advanceId: Value(advanceId),
      advanceNumber: Value(advanceNumber),
    );
  }
}
