// ─────────────────────────────────────────────────────────────────────────────
// payroll_sheet_widgets.dart — جزء من مكتبة `payroll_sheet_screen.dart`
//
// الترويسة والجدول وحوارا التعديل والتسديد. أصنافها **خاصة** (`_X`) ومرئية
// عبر المكتبة وحدها — فلا تتسرّب إلى بقية المشروع.
// ─────────────────────────────────────────────────────────────────────────────

part of 'payroll_sheet_screen.dart';

const double _kRowPadding = 12;

/// سُمك حدّ الجدول — **يدخل في حساب عرضه**
///
/// ⚠️ بكسلٌ على كل جانب. إغفاله جعل الجدول يتجاوز عرضه بـ**بكسلين بالضبط**
///   فظهر `RenderFlex overflowed by 2.0 pixels`. كشفه
///   `test/widget/payroll_screens_test.dart` قبل أن يصل إلى المالك — وهو
///   نفس صنف العطل الذي حجب أسماء الموظفين في المشروع المرجعي DMS، لكنه
///   هناك وصل إلى الشاشة لأن العرض كان **رقماً مكتوباً بيد**.
const double _kBorderWidth = 1;

/// أعمدة جدول الكشف — **مصدر العرض الوحيد**
///
/// ⚠️ **لماذا تعداد لا أرقام متناثرة؟** لأن عرض الجدول يجب أن يُشتقّ من
///   مجموع أعمدته. في مشروع DMS المرجعي كان الرقم مكتوباً بيد بينما تغيّر
///   مجموع الأعمدة، فتجاوزه بـ٩٤ بكسل وظهر شريط «RIGHT OVERFLOWED» فوق
///   عمود الاسم **فحجب أسماء الموظفين**. وأخطأ فيه كاتبه مرّتين: مرّة عند
///   البناء ومرّة حين أضاف عموداً وزاد الرقمين بمقدارٍ واحد.
///   الآن **إضافة عمود لا تحتاج تذكّر رقم في مكان آخر**.
enum _Col {
  seq('#', 40),
  name('الاسم', 180),
  position('الصفة', 120),
  currency('العملة', 64),
  basic('الأساسي', 118),
  days('الأيام', 62),
  absence('غياب', 60),
  absenceDed('خصم الغياب', 110),
  bonus('مكافأة', 110),
  deduction('خصم', 110),
  advanceDed('خصم سلفة', 110),
  net('الصافي', 120),
  netIqd('بالدينار', 128),
  // ⚠️ يتّسع للشارة **وأيقونتَي الطباعة والقلم** معاً. كان 90 فتجاوزته
  //   المحتويات بنصف بكسل لحظة إضافة أيقونة القلم، ثم وُسِّع إلى 150 لحظة
  //   إضافة أيقونة طباعة الإيصال (المرحلة ٤). هذا بالضبط ما يجعل اشتقاق
  //   العرض من هذا التعداد ذا قيمة: تغيير رقم واحد هنا يُصلح الجدول كلّه
  //   بلا تذكّر رقم في مكان آخر — ويحرسه اختبار الودجت.
  status('الحالة', 150);

  const _Col(this.label, this.width);

  final String label;
  final double width;

  /// العرض الكلّي — مجموع الأعمدة زائد الحشو **وسُمك الحدّ** على الجانبين
  static double get tableWidth =>
      values.fold<double>(0, (sum, c) => sum + c.width) +
      _kRowPadding * 2 +
      _kBorderWidth * 2;
}

// ═══════════════════════════════════════════════════════════════════════════
// الترويسة
// ═══════════════════════════════════════════════════════════════════════════

class _SheetHeader extends ConsumerWidget {
  final PayrollPeriod period;
  final PayrollPeriodTotals? totals;

  const _SheetHeader({required this.period, this.totals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final money = NumberFormat('#,##0');
    final isPosted = period.status == PayrollStatusDb.posted;
    final label = PayrollCalculator.periodLabel(period.year, period.month);

    final auth = ref.watch(authNotifierProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final canPay = user?.can(AppPermission.managePayroll) ?? false;
    final canPrepare = user?.can(AppPermission.preparePayroll) ?? false;

    final t = totals;
    final hasUnpaid = t != null && t.unpaidIqd > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => PayrollSheetScreen._goBack(context),
                icon: const Icon(Icons.arrow_forward_rounded),
                tooltip: 'رجوع',
              ),
              Text(
                'رواتب $label',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: colors.text,
                ),
              ),
              const SizedBox(width: 12),
              AppStatusBadge(
                label: isPosted ? 'مُسدَّد' : 'مسودة',
                color: isPosted ? Colors.green : colors.gold,
              ),
              const Spacer(),
              // الطباعة متاحة للجميع: قراءةٌ لا تكتب شيئاً ولا تمسّ مالاً
              TextButton.icon(
                onPressed: () => _openPrintSheetDialog(context, ref, period),
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('طباعة الكشف'),
              ),
              const SizedBox(width: 4),
              // 🔑 **إلغاء تسديد الشهر** (بلاغ المالك 2026-08-27): الكشف
              //   المُسدَّد كان بلا أي زرّ سوى الطباعة — فلا سبيل لتصحيح شهر
              //   اعتُمد خطأً إلا بالالتفاف على النظام (وهو ما ولّد ع-٣٢).
              if (isPosted && canPay && (t?.paidCount ?? 0) > 0)
                TextButton.icon(
                  onPressed: () => _confirmUnpayPeriod(context, ref, period),
                  icon: Icon(Icons.undo_rounded, color: colors.gold),
                  label: Text('إلغاء تسديد الشهر',
                      style: TextStyle(color: colors.gold)),
                ),
              // ⚠️ **والحذف يظهر للمُسدَّد أيضاً**: حواره صار يتعامل مع
              //   المدفوع بأمان منذ المرحلة ٧ (يعكسه أو يُبقيه)، والشرط
              //   الذي كان يُخفيه بقي من قبلها.
              if (canPrepare)
                TextButton.icon(
                  onPressed: () => _confirmDeletePeriod(context, ref, period),
                  icon: Icon(Icons.delete_outline, color: colors.danger),
                  label: Text('حذف الكشف',
                      style: TextStyle(color: colors.danger)),
                ),
              const SizedBox(width: 8),
              if (canPay && hasUnpaid)
                FilledButton.icon(
                  onPressed: () => _openPayDialog(context, ref, period),
                  icon: const Icon(Icons.payments_rounded, size: 18),
                  label: const Text('تسديد الرواتب'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _Stat(
                label: 'الموظفون',
                value: '${t?.entryCount ?? 0}',
              ),
              _Stat(
                label: 'إجمالي الكشف',
                value: '${money.format(t?.totalIqd ?? 0)} د.ع',
              ),
              _Stat(
                label: 'المستحقّ للصرف',
                value: '${money.format(t?.unpaidIqd ?? 0)} د.ع',
                highlight: hasUnpaid,
              ),
              _Stat(
                label: 'أيام العمل',
                value: '${period.workingDays}',
              ),
              if (period.exchangeRate != null)
                _Stat(
                  label: 'سعر الصرف',
                  value: money.format(period.exchangeRate),
                ),
              if (period.fileTotal > 0)
                _Stat(
                  label: 'مجموع الملف',
                  value: '${money.format(period.fileTotal)} د.ع',
                  // 🔑 المطابقة الثانية: المحسوب ↔ ما ذكره الملف.
                  //   الفرق هنا يكشف خطأً حسابياً **في الملف نفسه** قبل أن
                  //   يدخل الدفاتر — وهي أرخص لحظة لاكتشافه.
                  warn: t != null &&
                      (t.totalIqd - period.fileTotal).abs() > 1,
                ),
            ],
          ),
          if (t != null &&
              period.fileTotal > 0 &&
              (t.totalIqd - period.fileTotal).abs() > 1) ...[
            const SizedBox(height: 10),
            _MismatchBanner(
              computed: t.totalIqd,
              fromFile: period.fileTotal,
              // السطور تُقرأ من المزوّد نفسه الذي يبني الجدول — لا استعلام
              // ثانٍ ولا حساب ثانٍ، فقط نسبة الفرق إلى أصحابه
              entries:
                  ref.watch(payrollEntriesProvider(period.id)).valueOrNull ??
                      const [],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool warn;

  const _Stat({
    required this.label,
    required this.value,
    this.highlight = false,
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = warn
        ? colors.danger
        : highlight
            ? colors.gold
            : colors.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: colors.subtext)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// شريط يعلن فرق المجموع بدل أن يتركه رقمين متجاورين يلاحظهما من ينتبه
/// لافتة فرق المجموع — **وتقول سببه حين تعرفه**
///
/// 🔑 **بلاغ المالك 2026-08-26:** صرف راتباً كاملاً (٣٠ يوماً) لموظف له أربعة
///   أيام غياب، ثم استورد ملف الشهر — فظهرت هذه اللافتة برقمٍ **بلا سبب**.
///   والبرنامج يعرف السبب: سطر الموظف يحمل ما صُرف **وما يقوله الملف** معاً
///   (يُحفظ `file_net_amount` حتى للسطر المسدَّد).
///
///   **تنبيهٌ يذكر رقماً بلا سببه يُدرّب العين على تخطّي ما حوله.**
class _MismatchBanner extends StatelessWidget {
  final double computed;
  final double fromFile;
  final List<SalaryPayment> entries;

  const _MismatchBanner({
    required this.computed,
    required this.fromFile,
    this.entries = const [],
  });

  /// السطور التي يختلف فيها المصروف عمّا يقوله الملف — أصحاب الفرق
  ///
  /// هامش الدينار الواحد: ما دونه ضجيج فاصلة عائمة (نفس هامش المطابقة).
  List<SalaryPayment> get _contributors => entries
      .where((e) =>
          e.fileNetAmount != null &&
          (e.netAmount - e.fileNetAmount!).abs() > 1)
      .toList();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final money = NumberFormat('#,##0.##');
    final diff = computed - fromFile;
    final causes = _contributors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجمالي الكشف المحسوب يخالف المجموع المذكور في الملف بمقدار '
                  '${money.format(diff.abs())} د.ع '
                  '(${diff > 0 ? 'المحسوب أعلى' : 'المحسوب أقل'}). '
                  'راجع السطور قبل التسديد.',
                  style: TextStyle(fontSize: 12.5, color: colors.text),
                ),
                // ── سبب الفرق باسم صاحبه ─────────────────────────────
                if (causes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  for (final e in causes.take(4))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• ${e.snapshotName}: '
                        'صُرف ${money.format(e.netAmount)} '
                        'والملف يحسب ${money.format(e.fileNetAmount!)} '
                        '(${e.netAmount > e.fileNetAmount! ? 'زيادة' : 'نقص'} '
                        '${money.format((e.netAmount - e.fileNetAmount!).abs())})',
                        style: TextStyle(fontSize: 12, color: colors.subtext),
                      ),
                    ),
                  if (causes.length > 4)
                    Text('• و${causes.length - 4} غيرهم',
                        style:
                            TextStyle(fontSize: 12, color: colors.subtext)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// الجدول
// ═══════════════════════════════════════════════════════════════════════════

class _EntriesTable extends ConsumerWidget {
  final PayrollPeriod period;
  final List<SalaryPayment> entries;

  const _EntriesTable({required this.period, required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    final isDraft = period.status == PayrollStatusDb.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 🔑 **تلميح الاكتشاف**: التعديل كان متاحاً بالضغط على السطر منذ
        //   البداية، ولا شيء يدلّ عليه. وميزةٌ لا يعرف المستخدم بوجودها
        //   تساوي ميزةً غائبة — بلاغ المالك 2026-08-25.
        if (isDraft)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded, size: 18, color: colors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'اضغط أي سطر لتعديل راتبه أو أيامه أو خصوماته — '
                    'الكشف مسودة ولا يمسّ رصيد أي خزينة حتى تُسدّده.',
                    style: TextStyle(fontSize: 12.5, color: colors.subtext),
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: _tableBody(context)),
      ],
    );
  }

  Widget _tableBody(BuildContext context) {
    final colors = context.colors;

    // ═══════════════════════════════════════════════════════════════════
    // 🔴 تمرير في المحورين — بلاغ المالك 2026-08-25
    // ═══════════════════════════════════════════════════════════════════
    //
    // كان الجدول يمرّر **أفقياً فقط**، وسطوره داخل `Column` بلا ارتفاع
    // محدود. فكشفٌ فيه ٤٧ موظفاً يحتاج ٢٬٢٠٩ بكسل والمتاح ٤١٥:
    //   `A RenderFlex overflowed by 1839 pixels on the bottom`
    // ولا يستطيع المالك النزول لرؤية بقيّة موظفيه إطلاقاً.
    //
    // ⚠️ **ولماذا لم يمسكه اختبار الودجت؟** لأنه يزرع **موظفَين اثنين**،
    //   فلا يتجاوز الارتفاع أبداً. الاختبار كان يفحص العرض (وقد أمسك
    //   تجاوزاً أفقياً مرّتين فعلاً) ولا يفحص الارتفاع.
    //   **حجم البيانات في الاختبار جزءٌ من الاختبار** — وقد أُضيف الآن
    //   اختبار بـ٤٠ سطراً يحرس هذا الاتجاه.
    //
    // **البنية:** الترويسة تبقى ثابتة (فلا تضيع أسماء الأعمدة عند النزول)
    // والسطور وحدها في `ListView`. والمحور الأفقي يلفّهما معاً ليتحرّكا
    // متطابقين — ترويسةٌ لا تتبع الأعمدة أسوأ من لا ترويسة.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SizedBox(
        width: _Col.tableWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الترويسة تُبنى من التعداد نفسه — فلا تتباعد عن عرض الصفوف
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: _kRowPadding, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface2,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  for (final c in _Col.values)
                    SizedBox(
                      width: c.width,
                      child: Text(
                        c.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: colors.subtext,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // `Expanded` داخل `SingleChildScrollView` أفقي مشروع: المحور
            // العمودي **مقيَّد** من الأب، والأفقي وحده هو غير المقيَّد.
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(
                    left: BorderSide(color: colors.border),
                    right: BorderSide(color: colors.border),
                    bottom: BorderSide(color: colors.border),
                  ),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(12)),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: entries.length,
                    itemBuilder: (context, i) => _EntryRow(
                      index: i + 1,
                      entry: entries[i],
                      period: period,
                      isLast: i == entries.length - 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends ConsumerWidget {
  final int index;
  final SalaryPayment entry;
  final PayrollPeriod period;
  final bool isLast;

  const _EntryRow({
    required this.index,
    required this.entry,
    required this.period,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final money = NumberFormat('#,##0.##');
    final isPaid = entry.paymentStatus == PayrollPaymentStatusDb.paid;
    final isNegative = entry.netAmount < 0;
    // من `paid_at` لا `created_at`: الأخير بدقّة الثانية فيكذب داخلها
    final isLateAddition = period.postedAt != null &&
        entry.paidAt != null &&
        entry.paidAt!.isAfter(period.postedAt!);

    Widget cell(_Col col, String text, {Color? color, bool bold = false}) {
      return SizedBox(
        width: col.width,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? colors.text,
          ),
        ),
      );
    }

    return InkWell(
      // 🔑 الضغط على السطر يفتح ما يناسب حالته: تعديلاً للمسودة، وإجراءات
      //   التصحيح/الإلغاء للمسدَّد. إيماءةٌ واحدة لا اثنتان (المرحلة ٦).
      onTap: isPaid
          ? () => _openPaidEntryActions(context, ref, period, entry)
          : () => _openEditDialog(context, ref, entry),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: _kRowPadding, vertical: 11),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: colors.border)),
          // الصافي السالب يُبرَز: مقبول في المسودة ومرفوض عند التسديد،
          // فرؤيته مبكراً تجنّب المالك رفضاً مفاجئاً بعد اختيار الخزينة
          color: isNegative ? colors.danger.withValues(alpha: 0.06) : null,
        ),
        child: Row(
          children: [
            cell(_Col.seq, '$index', color: colors.subtext),
            cell(_Col.name, entry.snapshotName, bold: true),
            cell(_Col.position, entry.snapshotPosition,
                color: colors.subtext),
            cell(
              _Col.currency,
              entry.snapshotCurrency == PayrollCurrency.usd ? 'دولار' : 'دينار',
              color: colors.subtext,
            ),
            cell(_Col.basic, money.format(entry.basicSalary)),
            cell(
              _Col.days,
              '${entry.eligibleDays}',
              color: entry.eligibleDaysIsManual ? colors.gold : null,
            ),
            cell(_Col.absence,
                entry.absenceDays == 0 ? '—' : '${entry.absenceDays}'),
            cell(
              _Col.absenceDed,
              entry.absenceDeduction == 0
                  ? '—'
                  : money.format(entry.absenceDeduction),
              color: entry.absenceDeductionIsManual ? colors.gold : null,
            ),
            cell(_Col.bonus,
                entry.additions == 0 ? '—' : money.format(entry.additions)),
            cell(_Col.deduction,
                entry.deductions == 0 ? '—' : money.format(entry.deductions)),
            cell(
              _Col.advanceDed,
              entry.advanceRepaymentAmount == 0
                  ? '—'
                  : money.format(entry.advanceRepaymentAmount),
            ),
            cell(
              _Col.net,
              money.format(entry.netAmount),
              bold: true,
              color: isNegative ? colors.danger : null,
            ),
            cell(_Col.netIqd, money.format(entry.netAmountIqd), bold: true),
            SizedBox(
              width: _Col.status.width,
              child: Row(
                children: [
                  AppStatusBadge(
                    // 🔑 «لاحق» = أُضيف بعد اعتماد الكشف (صرفٌ مباشر متأخّر).
                    //   يُشتقّ من `created_at` مقابل `posted_at` بلا عمود
                    //   جديد. وبدونه يجد المالك في كشفٍ اعتمده اسماً لا
                    //   يذكره ولا يعرف متى دخل.
                    label: isPaid
                        ? (isLateAddition ? 'مُسدَّد · لاحق' : 'مُسدَّد')
                        : 'مستحقّ',
                    color: isPaid
                        ? (isLateAddition ? Colors.orange : Colors.green)
                        : colors.subtext,
                  ),
                  const SizedBox(width: 6),
                  // 🔑 **الإيصال متاح للسطر المسدَّد وغير المسدَّد معاً:**
                  //   المسدَّد يُسلَّم للموظف مع راتبه، وغير المسدَّد بيانُ
                  //   استحقاق يُراجَع (والمستند نفسه يقول أيّهما بوضوح).
                  //   والضغط على السطر نفسه يفتح التعديل، فلا تتضارب
                  //   الإيماءتان: هذه أيقونة مستقلّة بمنطقة ضغط خاصة بها.
                  Tooltip(
                    message: 'طباعة إيصال الراتب',
                    child: InkWell(
                      onTap: () => PayrollPrintActions.printSlip(
                          context, ref, entry.id),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Icon(Icons.receipt_long_outlined,
                            size: 15, color: colors.subtext),
                      ),
                    ),
                  ),
                  // ⚠️ أيقونة **في الحالتين بالعرض نفسه**: عمود الحالة
                  //   محسوب على المحتوى (١١٢px)، وإخفاؤها في حالة وإظهارها
                  //   في أخرى كان يغيّر العرض الفعلي — وهو مصدر ع-٢٣.
                  const SizedBox(width: 2),
                  Icon(isPaid ? Icons.tune_rounded : Icons.edit_outlined,
                      size: 13, color: colors.subtext),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// حوار تعديل سطر
// ═══════════════════════════════════════════════════════════════════════════

/// ⚠️ **بلا `TextEditingController`** — متغيّرات نصّية مع `initialValue`
///   و`onChanged`. المتحكّم المُتخلَّص منه بعد `await showDialog` سبّب شاشة
///   حمراء في خمسة مواضع (ع-٠٤): الـ await ينتهي لحظة `Navigator.pop` لا
///   لحظة اختفاء الحوار، فيبقى الحقل يُعاد بناؤه على متحكّم ميت.
Future<void> _openEditDialog(
  BuildContext context,
  WidgetRef ref,
  SalaryPayment entry,
) async {
  final advances =
      await ref.readOnce(employeePendingAdvancesProvider(entry.employeeId),
          employeePendingAdvancesProvider(entry.employeeId).future);
  if (!context.mounted) return;

  double? basic = entry.basicSalary;
  int? days = entry.eligibleDays;
  int? absenceDays = entry.absenceDays;
  double? absenceDed = entry.absenceDeduction;
  double? bonus = entry.additions;
  double? deduction = entry.deductions;
  double? repayment = entry.advanceRepaymentAmount;
  int? advanceId = entry.cashAdvanceId ??
      (advances.isNotEmpty ? advances.first.id : null);
  var daysTouched = false;
  var absenceDedTouched = false;

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final colors = ctx.colors;
      final money = NumberFormat('#,##0.##');

      Widget numField({
        required String label,
        required String initial,
        required ValueChanged<String> onChanged,
        String? helper,
      }) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            initialValue: initial,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: label,
              helperText: helper,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: onChanged,
          ),
        );
      }

      return AlertDialog(
        title: Text('تعديل راتب «${entry.snapshotName}»'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                numField(
                  label: 'الراتب الأساسي',
                  initial: money.format(entry.basicSalary),
                  onChanged: (v) =>
                      basic = double.tryParse(v.replaceAll(',', '')),
                ),
                numField(
                  label: 'الأيام المستحقّة',
                  initial: '${entry.eligibleDays}',
                  helper: 'تعديلها يدوياً يصونها من إعادة الحساب',
                  onChanged: (v) {
                    daysTouched = true;
                    days = int.tryParse(v);
                  },
                ),
                numField(
                  label: 'أيام الغياب',
                  initial: '${entry.absenceDays}',
                  onChanged: (v) => absenceDays = int.tryParse(v),
                ),
                numField(
                  label: 'خصم الغياب',
                  initial: money.format(entry.absenceDeduction),
                  helper: 'اتركه ليُحتسب تلقائياً من أيام الغياب',
                  onChanged: (v) {
                    absenceDedTouched = true;
                    absenceDed = double.tryParse(v.replaceAll(',', ''));
                  },
                ),
                numField(
                  label: 'مكافأة',
                  initial: money.format(entry.additions),
                  onChanged: (v) =>
                      bonus = double.tryParse(v.replaceAll(',', '')),
                ),
                numField(
                  label: 'خصومات أخرى',
                  initial: money.format(entry.deductions),
                  onChanged: (v) =>
                      deduction = double.tryParse(v.replaceAll(',', '')),
                ),
                if (advances.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    'خصم سلفة الموظف',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اقتراحٌ تقرّره أنت — يُسجَّل قسط سداد عند التسديد.',
                    style: TextStyle(fontSize: 11.5, color: colors.subtext),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: advanceId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'السلفة',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: advances
                        .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                'سلفة ${money.format(a.amount)} — '
                                'المتبقي ${money.format(a.amount - a.totalRepaid)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => advanceId = v,
                  ),
                  const SizedBox(height: 12),
                  numField(
                    label: 'المبلغ المخصوم',
                    initial: money.format(entry.advanceRepaymentAmount),
                    onChanged: (v) =>
                        repayment = double.tryParse(v.replaceAll(',', '')),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حفظ'),
          ),
        ],
      );
    },
  );

  if (saved != true) return;

  await ref.read(payrollNotifierProvider.notifier).updateEntry(
        entryId: entry.id,
        basicSalary: basic,
        eligibleDays: daysTouched ? days : null,
        absenceDays: absenceDays,
        absenceDeduction: absenceDedTouched ? absenceDed : null,
        bonus: bonus,
        deduction: deduction,
        advanceRepayment: repayment,
        cashAdvanceId: (repayment ?? 0) > 0 ? advanceId : null,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// حوار التسديد
// ═══════════════════════════════════════════════════════════════════════════

Future<void> _openPayDialog(
  BuildContext context,
  WidgetRef ref,
  PayrollPeriod period,
) async {
  final entries = await ref.readOnce(payrollEntriesProvider(period.id),
      payrollEntriesProvider(period.id).future);
  final treasuries = await ref.readOnce(
      allTreasuriesProvider, allTreasuriesProvider.future);
  if (!context.mounted) return;

  final unpaid = entries
      .where((e) => e.paymentStatus == PayrollPaymentStatusDb.unpaid)
      .toList();
  if (unpaid.isEmpty) return;

  final selected = <int>{...unpaid.map((e) => e.id)};
  int? treasuryId = treasuries.isNotEmpty ? treasuries.first.id : null;
  var payDate = DateTime.now();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final colors = ctx.colors;
        final money = NumberFormat('#,##0');
        final total = unpaid
            .where((e) => selected.contains(e.id))
            .fold<double>(0, (s, e) => s + e.netAmountIqd);

        return AlertDialog(
          title: Text(
            'تسديد رواتب '
            '${PayrollCalculator.periodLabel(period.year, period.month)}',
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ملخّص ما سيخرج — قبل اختيار الخزينة لا بعده
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${selected.length} موظفاً',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${money.format(total)} د.ع',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: colors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'يُنشأ **سند صرف واحد** بالمجموع — لا سند لكل موظف. '
                  'وتفصيل كل راتب محفوظ في الكشف.',
                  style: TextStyle(fontSize: 12, color: colors.subtext),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: treasuryId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'الخزينة التي يُصرف منها',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: treasuries
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => treasuryId = v),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الصرف',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('yyyy/MM/dd').format(payDate),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: payDate,
                            firstDate: DateTime(period.year - 1),
                            lastDate: DateTime(period.year + 2),
                          );
                          if (picked != null) {
                            setState(() => payDate = picked);
                          }
                        },
                        child: const Text('تغيير'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'الموظفون الداخلون في هذه الدفعة',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: colors.text),
                ),
                const SizedBox(height: 6),
                // الاختيار الجزئي هو ما يجعل التسديد على دفعات ممكناً:
                // موظفو البصرة من سلفتها ومن في بغداد من الرئيسية
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final e in unpaid)
                        CheckboxListTile(
                          dense: true,
                          value: selected.contains(e.id),
                          title: Text(e.snapshotName),
                          subtitle: Text(
                            '${money.format(e.netAmountIqd)} د.ع'
                            '${e.advanceRepaymentAmount > 0 ? ' · خصم سلفة ${money.format(e.advanceRepaymentAmount)}' : ''}',
                          ),
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              selected.add(e.id);
                            } else {
                              selected.remove(e.id);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: selected.isEmpty || treasuryId == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('تأكيد الصرف'),
            ),
          ],
        );
      },
    ),
  );

  if (confirmed != true || treasuryId == null) return;

  await ref.read(payrollNotifierProvider.notifier).payEntries(
        periodId: period.id,
        entryIds: selected.toList(),
        treasuryId: treasuryId!,
        paymentDate: payDate,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// حذف الكشف
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// حوار خيارات طباعة الكشف
// ═══════════════════════════════════════════════════════════════════════════

/// يسأل عن عمود توقيع الاستلام قبل الطباعة (قرار المالك 2026-08-26)
///
/// **ولماذا سؤال لا ثابت؟** الورقة التي تُوزَّع على الموظفين تحتاج خانة
/// توقيع، ونسخة الأرشيف لا تحتاجها فتتّسع بقيةُ الأعمدة. والافتراضي
/// **مُفعَّل** لأن ورقة التوزيع هي الاستعمال الأشيع.
///
/// ⚠️ **بلا `TextEditingController`** — مربّع اختيار فقط داخل
///   `StatefulBuilder`. راجع تحذير أعلى هذا الملف (ع-٠٤).
Future<void> _openPrintSheetDialog(
  BuildContext context,
  WidgetRef ref,
  PayrollPeriod period,
) async {
  var withSignature = true;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: const Text('طباعة كشف الرواتب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'رواتب '
              '${PayrollCalculator.periodLabel(period.year, period.month)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: withSignature,
              onChanged: (v) => setLocal(() => withSignature = v ?? false),
              title: const Text('عمود توقيع الاستلام'),
              subtitle: const Text(
                'خانة فارغة يوقّع فيها كل موظف عند استلام راتبه.',
                style: TextStyle(fontSize: 12),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('معاينة وطباعة'),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true || !context.mounted) return;
  await PayrollPrintActions.printSheet(
    context,
    ref,
    period.id,
    withSignatureColumn: withSignature,
  );
}
