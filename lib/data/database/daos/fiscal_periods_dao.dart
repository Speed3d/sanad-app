// ─────────────────────────────────────────────────────────────────────────────
// fiscal_periods_dao.dart — DAO السنوات المالية وأرقام السندات
//
// يُدير هذا الـ DAO السنوات المالية وتسلسل أرقام السندات.
//
// أهم العمليات:
//   1. getOrCreateCurrentPeriod()  — الحصول على الفترة الحالية أو إنشائها
//   2. getFiscalPeriodForDate()    — تحديد الفترة حسب تاريخ السند
//   3. getNextVoucherNumber()      — رقم السند التالي بطريقة آمنة تمامًا
//   4. closeFiscalPeriod()         — إقفال السنة المالية
//
// آلية getNextVoucherNumber (Atomic Increment):
//   تستخدم UPSERT + Transaction لضمان عدم تكرار رقم السند
//   حتى في حالة عدة مستخدمين يعملون في وقت واحد.
//   النهج: INSERT...ON CONFLICT DO UPDATE (ذري بطبيعته في SQLite)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/fiscal_periods_table.dart';

part 'fiscal_periods_dao.g.dart';

/// DAO السنوات المالية وتسلسل أرقام السندات
@DriftAccessor(tables: [FiscalPeriods, VoucherSequences])
class FiscalPeriodsDao extends DatabaseAccessor<AppDatabase>
    with _$FiscalPeriodsDaoMixin {
  FiscalPeriodsDao(super.db);

  // ── استعلامات الفترات المالية ─────────────────────────────────────────────

  /// متابعة جميع الفترات المالية — Reactive Stream مرتب من الأحدث للأقدم
  Stream<List<FiscalPeriod>> watchAllPeriods() {
    return (select(fiscalPeriods)
          ..orderBy([(p) => OrderingTerm.desc(p.startDate)]))
        .watch();
  }

  /// جلب الفترات النشطة فقط (status = 'active')
  ///
  /// عادةً فترة واحدة، لكن خلال فترة الانتقال بين السنوات قد تكون اثنتان
  Future<List<FiscalPeriod>> getActivePeriods() {
    return (select(fiscalPeriods)
          ..where((p) => p.status.equals('active'))
          ..orderBy([(p) => OrderingTerm.desc(p.startDate)]))
        .get();
  }

  /// جلب الفترة المناسبة لتاريخ محدد
  ///
  /// يُستخدَم عند إنشاء سند لتحديد السنة المالية حسب تاريخ السند
  /// وليس حسب وقت الإدخال
  Future<FiscalPeriod?> getFiscalPeriodForDate(DateTime date) async {
    // نبحث عن فترة نشطة يقع التاريخ ضمن نطاقها
    final result = await (select(fiscalPeriods)
          ..where(
            (p) =>
                p.status.equals('active') &
                p.startDate.isSmallerOrEqualValue(date) &
                p.endDate.isBiggerOrEqualValue(date),
          )
          ..limit(1))
        .getSingleOrNull();
    return result;
  }

  /// جلب الفترة التي يقع فيها تاريخ **أياً كانت حالتها**
  ///
  /// ⚠️ **الفرق عن [getFiscalPeriodForDate]**: تلك تفلتر بـ`active`، فتُعيد
  ///   `null` للفترة المُقفَلة كما تُعيده للفترة غير الموجودة — والحالتان
  ///   مختلفتان تماماً عند المستخدم:
  ///     «لا توجد سنة مالية لهذا الشهر»  ⇐ أنشئ السنة
  ///     «سنة 2025 مُقفَلة»              ⇐ أعد فتحها أو اختر شهراً آخر
  ///   ورسالةٌ تقول الأولى والواقع الثاني تُرسل المالك في طريق خاطئ.
  ///   (كشفه بلاغ المالك 2026-08-25 على بناء كشف رواتب.)
  Future<FiscalPeriod?> getAnyPeriodForDate(DateTime date) {
    return (select(fiscalPeriods)
          ..where((p) =>
              p.startDate.isSmallerOrEqualValue(date) &
              p.endDate.isBiggerOrEqualValue(date))
          ..limit(1))
        .getSingleOrNull();
  }

  /// جلب فترة مالية بالمعرّف
  Future<FiscalPeriod?> getPeriodById(int id) {
    return (select(fiscalPeriods)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  // ── قاعدة عدم التقاطع ─────────────────────────────────────────────────────

  /// البحث عن فترة قائمة تتقاطع مع النطاق [start] → [end]
  ///
  /// **معادلة التقاطع الصحيحة** — تقاطع فترتين زمنيتين:
  /// ```
  ///   start <= p.endDate  &&  end >= p.startDate
  /// ```
  /// بلا أي إزاحة أيام. الإزاحة كانت أصل العطل: الكود السابق في طبقة العرض
  /// كتب `start.isBefore(p.endDate + يوم)` ظنّاً أنها تحوّل `<` الصارمة إلى
  /// `<=`، لكنها تُزيح الحدّ **٨٦٬٤٠٠ ثانية** لا لحظة واحدة. فصار حدّ التقاطع
  /// مع فترة 2026 هو 2027-01-01 23:59:59 — أي أن سنة 2027 كاملة تُرفض، وكذلك
  /// 2025 من الطرف الآخر. النتيجة: **كل سنة مجاورة تُرفض** ولا يُقبل إلا ما
  /// بَعُد سنتين. (بلاغ المالك 2026-08-23.)
  ///
  /// يشمل الفحص **كل الحالات** (نشطة ومُقفَلة) بقرار المالك: فترتان تدّعيان
  /// نفس التواريخ تجعلان التقارير غامضة ولا يُعرَف لأيّهما ينتمي السند.
  ///
  /// [excludeId] — يُستثنى من الفحص (لتعديل فترة قائمة مستقبلاً)
  ///
  /// يُعيد أول فترة متقاطعة، أو null إن كان النطاق خالياً.
  Future<FiscalPeriod?> findOverlappingPeriod({
    required DateTime start,
    required DateTime end,
    int? excludeId,
  }) {
    return (select(fiscalPeriods)
          ..where((p) {
            var cond = p.startDate.isSmallerOrEqualValue(end) &
                p.endDate.isBiggerOrEqualValue(start);
            if (excludeId != null) {
              cond = cond & p.id.equals(excludeId).not();
            }
            return cond;
          })
          ..orderBy([(p) => OrderingTerm.asc(p.startDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// إنشاء فترة مالية جديدة — يُعيد الـ ID المُولَّد
  ///
  /// ⚠️ **حارس التقاطع هنا لا في طبقة العرض** (إصلاح 2026-08-23).
  ///   كان الفحص في `FiscalNotifier.createPeriod` وحدها، فترتّب على ذلك أمران:
  ///   ١. أي مستدعٍ آخر (استيراد، ترحيل، شاشة مستقبلية) يتجاوزه بلا علم.
  ///   ٢. **لم يُختبَر قط** — فكل اختبارات المشروع تستدعي هذه الدالة مباشرةً،
  ///      ولهذا نجح ١٧٦ اختباراً بينما القاعدة معطوبة عطلاً كاملاً.
  ///   وضعه داخل معاملة هنا يجعله غير قابل للالتفاف، ويضع كل اختبار يُنشئ
  ///   فترةً تحت حمايته تلقائياً.
  ///
  /// يرمي [StateError] برسالة عربية **تسمّي الفترة المتقاطعة وتاريخيها** —
  /// الرسالة القديمة «يتداخل نطاق التواريخ مع فترة مالية موجودة» لم تكن تذكر
  /// مع أي فترة، فبقي المالك يجرّب سنةً بعد سنة بلا دليل.
  Future<int> insertPeriod(FiscalPeriodsCompanion period) async {
    return transaction(() async {
      final start = period.startDate.value;
      final end = period.endDate.value;

      if (!end.isAfter(start)) {
        throw StateError(
          'تاريخ النهاية يجب أن يكون بعد تاريخ البداية.',
        );
      }

      final clash = await findOverlappingPeriod(start: start, end: end);
      if (clash != null) {
        throw StateError(
          'يتقاطع نطاق التواريخ مع الفترة المالية "${clash.name}" '
          '(${_d(clash.startDate)} → ${_d(clash.endDate)}).\n'
          'اختر نطاقاً لا يتقاطع معها، أو احذف تلك الفترة إن كانت خالية '
          'من السندات.',
        );
      }

      return into(fiscalPeriods).insert(period);
    });
  }

  /// تنسيق تاريخ مختصر للرسائل العربية (يوم/شهر/سنة)
  String _d(DateTime v) =>
      '${v.year}/${v.month.toString().padLeft(2, '0')}/'
      '${v.day.toString().padLeft(2, '0')}';

  /// الحصول على السنة المالية الحالية أو إنشائها إذا لم تكن موجودة
  ///
  /// يُستخدَم عند بدء التطبيق لضمان وجود فترة نشطة
  Future<FiscalPeriod> getOrCreateCurrentPeriod() async {
    final now = DateTime.now();
    final existing = await getFiscalPeriodForDate(now);
    if (existing != null) return existing;

    // إنشاء فترة للسنة الحالية
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    final id = await insertPeriod(
      FiscalPeriodsCompanion.insert(
        name: now.year.toString(),
        startDate: startOfYear,
        endDate: endOfYear,
        status: const Value('active'),
      ),
    );

    return (select(fiscalPeriods)..where((p) => p.id.equals(id))).getSingle();
  }

  // ── حذف فترة خالية ────────────────────────────────────────────────────────

  /// حذف فترة مالية **خالية تماماً** من أي أثر مالي
  ///
  /// **لماذا أُضيفت؟** (2026-08-23) لم يكن في النظام أي طريقة لحذف فترة
  /// مالية — لا في طبقة البيانات ولا في الواجهة. فأي سنة تُنشأ بالخطأ تبقى
  /// إلى الأبد، وتحجب بقاعدة عدم التقاطع إنشاء السنة الصحيحة مكانها.
  ///
  /// **لماذا «خالية» شرطٌ لا يُتساهل فيه؟** الحذف هنا **فعلي لا ناعم**، فلو
  /// حُذفت فترة تحمل سندات لاختفى أثر مالي حقيقي بلا رجعة — وهذا ما يمنعه
  /// كل تصميم هذا النظام (السندات تُحذف حذفاً ناعماً دائماً). الشرط يجعل
  /// العملية **بلا أثر محاسبي إطلاقاً**: لا شيء يُمحى إلا سجلّ فارغ.
  ///
  /// يُفحص كل ما قد يشير إلى الفترة:
  ///   • السندات — **بما فيها المحذوفة ناعماً**، فهي أثر تدقيقي قائم
  ///   • سلف المشاريع
  /// ثم تُحذف صفوف تسلسل الترقيم التابعة لها (مفتاح خارجي يمنع الحذف بدونه).
  ///
  /// يرمي [StateError] برسالة عربية تشرح المانع بالأرقام.
  Future<void> deleteEmptyPeriod(int id) async {
    await transaction(() async {
      final period = await getPeriodById(id);
      if (period == null) {
        throw StateError('الفترة المالية غير موجودة.');
      }

      // السندات — لا نفلتر is_deleted عمداً: السند المحذوف ناعماً أثر قائم.
      // نفصل العدّين لأن الشاشة تعرض غير المحذوف فقط، فلو اكتفينا برقم واحد
      // لقرأ المالك «0 سند» في البطاقة و«3 سندات» في رسالة الرفض فيحتار.
      final vRow = await customSelect(
        'SELECT COUNT(*) AS total, '
        'SUM(CASE WHEN is_deleted = 1 THEN 1 ELSE 0 END) AS soft '
        'FROM vouchers WHERE fiscal_period_id = ?',
        variables: [Variable.withInt(id)],
        readsFrom: {db.vouchers},
      ).getSingle();
      final voucherCount = vRow.data['total'] as int? ?? 0;
      final softDeleted = (vRow.data['soft'] as int?) ?? 0;

      final aRow = await customSelect(
        'SELECT COUNT(*) AS c FROM advances WHERE fiscal_period_id = ?',
        variables: [Variable.withInt(id)],
      ).getSingle();
      final advanceCount = aRow.data['c'] as int? ?? 0;

      // كشوف الرواتب (Schema v7) — مفتاح خارجي إلى الفترة.
      //
      // ⚠️ بدون هذا الفحص لا يمرّ الحذف أصلاً: يرمي SqliteException(787)
      //   برسالة إنجليزية غامضة بدل أن يقول للمالك ما يمنعه. وهو بالضبط
      //   ما وقع في زرّ التصفير (ع-٩): قيد أجنبي لم يتوقّعه أحد.
      final pRow = await customSelect(
        'SELECT COUNT(*) AS c FROM payroll_periods WHERE fiscal_period_id = ?',
        variables: [Variable.withInt(id)],
      ).getSingle();
      final payrollCount = pRow.data['c'] as int? ?? 0;

      if (voucherCount > 0 || advanceCount > 0 || payrollCount > 0) {
        final parts = <String>[
          if (voucherCount > 0)
            voucherCount == softDeleted
                // كلها محذوفة ناعماً: الشاشة تعرضها صفراً، فنوضّح المفارقة
                ? '$voucherCount سنداً محذوفاً (الحذف الناعم يُبقي الأثر)'
                : '$voucherCount سند',
          if (advanceCount > 0) '$advanceCount سلفة مشروع',
          if (payrollCount > 0) '$payrollCount كشف رواتب',
        ];
        throw StateError(
          'لا يمكن حذف الفترة "${period.name}" لأنها تحتوي '
          '${parts.join(' و')}.\n'
          'الحذف متاح للفترات الخالية تماماً فقط — حتى لا يختفي أثر مالي.',
        );
      }

      // تسلسل الترقيم مفتاح خارجي إلى الفترة — يُحذف أولاً وإلا فشل القيد
      await (delete(voucherSequences)
            ..where((q) => q.fiscalPeriodId.equals(id)))
          .go();

      await (delete(fiscalPeriods)..where((p) => p.id.equals(id))).go();
    });
  }

  // ── المحو القسري ──────────────────────────────────────────────────────────

  /// 🔥 محو فترة مالية **بكل سنداتها** محواً نهائياً لا رجعة فيه
  ///
  /// ⚠️⚠️ **هذه الدالة تمحو بيانات مالية حقيقية.** لا تستدعِها من أي مكان
  ///   جديد دون المرور بـ `FiscalNotifier.purgePeriod` التي تحرسها بثلاث
  ///   طبقات: صلاحية super_admin · كلمة مرور المستخدم (bcrypt) · رمز محو
  ///   منفصل + كتابة اسم الفترة. وُضع الحرس هناك لا هنا لأن التحقق من
  ///   bcrypt وظيفة طبقة الخدمات لا طبقة البيانات.
  ///
  /// **الفرق عن [deleteEmptyPeriod]:** تلك ترفض أي فترة فيها أثر مالي وهي
  /// التصرّف الافتراضي الصحيح. هذه تمحو الأثر نفسه — أُضيفت بطلب صريح من
  /// المالك (2026-08-23) لأن مرحلة الاختبار تتطلّب تصفير سنة كاملة وإعادة
  /// بنائها، وبدونها تبقى كل سنة تجريبية حاجزاً دائماً على نطاقها.
  ///
  /// **ما يُمحى** بالترتيب الإلزامي (الابن قبل الأب وإلا فشل القيد الأجنبي):
  ///   advance_lines → advances → salary_payments → payroll_periods
  ///   → vouchers (**بما فيها المحذوفة ناعماً**)
  ///   → voucher_sequences → الفترة نفسها
  ///
  /// **ما لا يُمسّ:** الخزائن · الموظفون · المقاولون · الشركاء · المستخدمون
  /// · الإعدادات · **سجل التدقيق** — يبقى فيه سطر يوثّق أن المحو حدث، وإلا
  /// صار في البرنامج محوٌ صامت للدفاتر بلا شاهد.
  ///
  /// يُعيد عدّادات ما مُحي فعلاً — تُقرأ **قبل** المحو لأنها تختفي بعده.
  Future<({int vouchers, int advances, int payrolls})>
      purgeFiscalPeriodCompletely(
    int id,
  ) async {
    return transaction(() async {
      final period = await getPeriodById(id);
      if (period == null) {
        throw StateError('الفترة المالية غير موجودة.');
      }

      final vRow = await customSelect(
        'SELECT COUNT(*) AS c FROM vouchers WHERE fiscal_period_id = ?',
        variables: [Variable.withInt(id)],
        readsFrom: {db.vouchers},
      ).getSingle();
      final voucherCount = vRow.data['c'] as int? ?? 0;

      final aRow = await customSelect(
        'SELECT COUNT(*) AS c FROM advances WHERE fiscal_period_id = ?',
        variables: [Variable.withInt(id)],
      ).getSingle();
      final advanceCount = aRow.data['c'] as int? ?? 0;

      final pRow = await customSelect(
        'SELECT COUNT(*) AS c FROM payroll_periods WHERE fiscal_period_id = ?',
        variables: [Variable.withInt(id)],
      ).getSingle();
      final payrollCount = pRow.data['c'] as int? ?? 0;

      // أسطر السلف تتبع سلف هذه الفترة — تُمحى قبلها
      await customStatement(
        'DELETE FROM advance_lines WHERE advance_id IN '
        '(SELECT id FROM advances WHERE fiscal_period_id = ?)',
        [id],
      );
      await customStatement(
        'DELETE FROM advances WHERE fiscal_period_id = ?',
        [id],
      );

      // ── كشوف الرواتب وسطورها (Schema v7) ──────────────────────────────
      // الترتيب: السطور ← فكّ ارتباط أسطر السلف ← الكشوف نفسها.
      await customStatement(
        'DELETE FROM salary_payments WHERE payroll_period_id IN '
        '(SELECT id FROM payroll_periods WHERE fiscal_period_id = ?)',
        [id],
      );

      // ⚠️ **فكّ ارتباط لا حذف**: قد يشير سطرُ سلفةٍ في سنة أخرى إلى كشف من
      //   هذه السنة (سلفة كانون الأول تسدّد رواتب كانون الثاني). حذف ذلك
      //   السطر يمحو مصروفاً من سنة لا يجوز مسّها أصلاً — فالمحو محصور
      //   بفترة واحدة بإجماع. نفكّ الرباط فحسب ويبقى المبلغ وسنده سليمين.
      await customStatement(
        'UPDATE advance_lines SET payroll_period_id = NULL '
        'WHERE payroll_period_id IN '
        '(SELECT id FROM payroll_periods WHERE fiscal_period_id = ?)',
        [id],
      );

      await customStatement(
        'DELETE FROM payroll_periods WHERE fiscal_period_id = ?',
        [id],
      );
      // كل السندات بلا استثناء — المحذوف ناعماً هو بالضبط ما يمنع الحذف
      // العادي، ومحوه هو الغرض من هذه الدالة
      await customStatement(
        'DELETE FROM vouchers WHERE fiscal_period_id = ?',
        [id],
      );
      await (delete(voucherSequences)
            ..where((q) => q.fiscalPeriodId.equals(id)))
          .go();
      await (delete(fiscalPeriods)..where((p) => p.id.equals(id))).go();

      return (
        vouchers: voucherCount,
        advances: advanceCount,
        payrolls: payrollCount,
      );
    });
  }

  /// إقفال فترة مالية
  ///
  /// [id]         — معرّف الفترة
  /// [closedBy]   — معرّف المستخدم الذي أقفل الفترة
  /// [notes]      — ملاحظات الإقفال (اختياري)
  Future<void> closePeriod(int id, int closedBy, {String notes = ''}) async {
    await (update(fiscalPeriods)..where((p) => p.id.equals(id))).write(
      FiscalPeriodsCompanion(
        status: const Value('frozen'),
        closedAt: Value(DateTime.now()),
        closedByUserId: Value(closedBy),
        notes: Value(notes),
      ),
    );
  }

  /// وضع فترة في حالة "مقفلة تحتاج إعادة احتساب"
  ///
  /// يُستخدَم عند إعادة فتح فترة سابقة تؤثر على الفترات اللاحقة
  Future<void> markPeriodPendingRecompute(int id) async {
    await (update(fiscalPeriods)..where((p) => p.id.equals(id))).write(
      const FiscalPeriodsCompanion(
        status: Value('frozen_pending_recompute'),
      ),
    );
  }

  /// إعادة تفعيل فترة مقفلة (إعادة الفتح — Super Admin فقط)
  Future<void> reopenPeriod(int id) async {
    await (update(fiscalPeriods)..where((p) => p.id.equals(id))).write(
      const FiscalPeriodsCompanion(
        status: Value('active'),
        closedAt: Value(null),
        closedByUserId: Value(null),
      ),
    );
  }

  // ── تسلسل أرقام السندات (Atomic) ─────────────────────────────────────────

  /// الحصول على رقم السند التالي بطريقة آمنة تمامًا
  ///
  /// يستخدم UPSERT ذري في SQLite لضمان عدم التكرار حتى مع مستخدمين متعددين.
  ///
  /// [fiscalPeriodId] — معرّف الفترة المالية
  /// [voucherType]    — 'sarf' أو 'kabd'
  ///
  /// يُعيد: رقم السند التالي (1، 2، 3، ...)
  Future<int> getNextVoucherNumber({
    required int fiscalPeriodId,
    required String voucherType,
  }) async {
    return db.transaction(() async {
      // UPSERT ذري:
      //   إذا لم يوجد السجل → ينشئه بـ last_number = 1
      //   إذا وجد → يزيد last_number بمقدار 1
      // هذا العملية ذرية (Atomic) في SQLite لأن SQLite يسمح بكاتب واحد فقط
      await db.customStatement(
        '''
        INSERT INTO voucher_sequences (fiscal_period_id, voucher_type, last_number)
        VALUES (?, ?, 1)
        ON CONFLICT(fiscal_period_id, voucher_type)
        DO UPDATE SET last_number = last_number + 1
        ''',
        [fiscalPeriodId, voucherType],
      );

      // قراءة القيمة المُحدَّثة
      final result = await db
          .customSelect(
            'SELECT last_number FROM voucher_sequences '
            'WHERE fiscal_period_id = ? AND voucher_type = ?',
            variables: [
              Variable.withInt(fiscalPeriodId),
              Variable.withString(voucherType),
            ],
            readsFrom: {db.voucherSequences},
          )
          .getSingle();

      return result.data['last_number'] as int;
    });
  }

  /// إعادة تعيين تسلسل السند (يُستخدَم فقط عند اختبار قاعدة بيانات جديدة)
  Future<void> resetSequence(int fiscalPeriodId, String voucherType) async {
    await (delete(voucherSequences)
          ..where(
            (s) =>
                s.fiscalPeriodId.equals(fiscalPeriodId) &
                s.voucherType.equals(voucherType),
          ))
        .go();
  }
}
