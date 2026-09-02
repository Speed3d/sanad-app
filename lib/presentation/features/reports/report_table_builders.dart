// ─────────────────────────────────────────────────────────────────────────────
// report_table_builders.dart — تحويل بيانات التقارير إلى بيان طباعة نقيّ
//
// **الحدّ الذي يحرسه هذا الملف:** `PdfService` تعيش في `core` ولا تعرف قاعدة
// البيانات ولا نماذج Drift. فالتحويل من `ItemTypeExpenseRow` و
// `TreasuryBalanceRow` و`AccountStatementModel` إلى `ReportTableData` يقع
// **هنا** في طبقة العرض — لا هناك. يحرس الحدَّ `company_identity_test.dart`.
//
// ═══ القاعدة: التنسيق يقع هنا لا في المستند ═══
//   كل خليّة تخرج من هذا الملف **نصّاً جاهزاً**. المستند يرسم ولا يحسب.
//   والسبب أن التنسيق قرار محاسبي لا تقنيّ:
//     • الدينار بلا كسور والدولار بكسرين
//     • **العملتان لا تُجمعان في رقم واحد أبداً** — تُعرَضان متجاورتين
//     • الدولار يُحوَّل بسعر صرف **سنده** لا بسعر اليوم، فلا يتغيّر التقرير
//       التاريخي بتحرّك السعر
//   وهي القرارات المحروسة في `test/unit/expense_reports_test.dart`.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:intl/intl.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/services/payroll_print_data.dart';
import '../../../core/services/pdf_service.dart' show PayrollPrintCurrency;
import '../../../core/services/report_print_data.dart';

import '../../../data/database/daos/advances_dao.dart';
import '../../../data/database/daos/treasuries_dao.dart';
import '../../../data/database/daos/vouchers_dao.dart';
import '../../../domain/models/advance_model.dart';
import '../../../domain/models/voucher_model.dart';

/// يُعاد تصديره: كل مستدعٍ للمحوِّلات يحتاج نوع نتيجتها
export '../../../core/services/report_print_data.dart';

final _money = NumberFormat('#,##0');
final _date = DateFormat('yyyy/MM/dd');

String _iqd(double v) => '${_money.format(v)} د.ع';
String _usd(double v) => '${NumberFormat('#,##0.00').format(v)} \$';

/// نصّ مدى التاريخ — يظهر في ترويسة كل تقرير مفلتَر بالتواريخ
String reportRangeLabel(DateTime from, DateTime to) =>
    'من ${_date.format(from)} إلى ${_date.format(to)}';

// ── ١) كشف الحساب ────────────────────────────────────────────────────────────

/// كشف حساب خزينة — بالرصيد الافتتاحي والتراكمي
///
/// 🔑 **الرصيد الافتتاحي والتراكمي هنا ليسا إضافة تجميلية:** المولّد القديم
///   `generateVaultStatement` كان **يستقبل `openingBalance` ولا يستعمله
///   إطلاقاً**، ويطبع قائمة سندات بلا رصيد. وكشفُ حسابٍ بلا رصيد تراكمي
///   ليس كشف حساب — هو قائمة حركات لا يُعرف منها أين وقف المال.
ReportTableData buildAccountStatementTable({
  required String treasuryName,
  required DateTime from,
  required DateTime to,
  required List<AccountStatementModel> rows,
}) {
  final hasUsd = rows.any((r) =>
      r.voucher.currency == 'USD' || r.runningBalanceUsd.abs() > 0.001);

  final columns = <String>[
    'الرقم',
    'التاريخ',
    'النوع',
    'البيان',
    'المبلغ',
    'الرصيد (د.ع)',
    if (hasUsd) 'الرصيد (\$)',
  ];

  final data = <List<String>>[
    for (final r in rows)
      [
        '${r.voucher.voucherNumber}',
        _date.format(r.voucher.voucherDate.toLocal()),
        r.voucher.voucherType.toArabicVoucherType(),
        r.voucher.reason.isEmpty ? '—' : r.voucher.reason,
        r.voucher.currency == 'USD'
            ? _usd(r.voucher.amount)
            : _iqd(r.voucher.amount),
        _money.format(r.runningBalanceIqd),
        if (hasUsd) NumberFormat('#,##0.00').format(r.runningBalanceUsd),
      ],
  ];

  final last = rows.isEmpty ? null : rows.last;

  return ReportTableData(
    title: 'كشف حساب: $treasuryName',
    subtitle: reportRangeLabel(from, to),
    columns: columns,
    rows: data,
    summary: [
      (label: 'عدد السندات', value: '${rows.length}'),
      if (last != null)
        (label: 'الرصيد النهائي', value: _iqd(last.runningBalanceIqd)),
      if (last != null && hasUsd)
        (label: 'الرصيد بالدولار', value: _usd(last.runningBalanceUsd)),
    ],
    footerNote: hasUsd
        ? 'العملتان معروضتان متجاورتين ولا تُجمعان في رقم واحد.'
        : null,
    landscape: hasUsd,
    // المبلغ والرصيد أرقامٌ يجمعها المالك في Excel — لا نصوص تُفرَز أبجدياً
    numericColumns: hasUsd ? const {4, 5, 6} : const {4, 5},
  );
}

// ── ٢) الملخّص اليومي ────────────────────────────────────────────────────────

ReportTableData buildDailySummaryTable({
  required DateTime day,
  required double totalKabd,
  required double totalSarf,
  double totalKabdUsd = 0,
  double totalSarfUsd = 0,
}) {
  final net = totalKabd - totalSarf;
  final netUsd = totalKabdUsd - totalSarfUsd;
  final hasUsd = totalKabdUsd.abs() > 0.001 || totalSarfUsd.abs() > 0.001;

  return ReportTableData(
    title: 'الملخّص اليومي',
    subtitle: DateFormat('EEEE، d MMMM yyyy', 'ar').format(day),
    columns: const ['البند', 'المبلغ', 'العملة'],
    rows: [
      ['إجمالي القبض', _money.format(totalKabd), 'د.ع'],
      ['إجمالي الصرف', _money.format(totalSarf), 'د.ع'],
      ['الصافي', _money.format(net), 'د.ع'],
      // العملتان متجاورتان لا مجموعتان — قاعدة محروسة في expense_reports_test
      if (hasUsd) ...[
        ['إجمالي القبض', NumberFormat('#,##0.00').format(totalKabdUsd), '\$'],
        ['إجمالي الصرف', NumberFormat('#,##0.00').format(totalSarfUsd), '\$'],
        ['الصافي', NumberFormat('#,##0.00').format(netUsd), '\$'],
      ],
    ],
    summary: [
      (label: 'الصافي بالدينار', value: _iqd(net)),
      if (hasUsd) (label: 'الصافي بالدولار', value: _usd(netUsd)),
    ],
    numericColumns: const {1},
    footerNote: hasUsd
        ? 'العملتان معروضتان متجاورتين ولا تُجمعان في رقم واحد.'
        : null,
  );
}

// ── ٣) تقرير الفترة ──────────────────────────────────────────────────────────

ReportTableData buildPeriodReportTable({
  required DateTime from,
  required DateTime to,
  required String scopeLabel,
  required List<VoucherModel> vouchers,
}) {
  double sum(bool Function(VoucherModel) test) => vouchers
      .where(test)
      .fold<double>(
          0,
          (a, v) =>
              a + (v.currency == 'IQD' ? v.amount : v.amount * v.exchangeRate));

  final kabd = sum((v) => v.voucherType == 'kabd');
  final sarf = sum((v) => v.voucherType == 'sarf');

  return ReportTableData(
    title: 'تقرير فترة',
    subtitle: '${reportRangeLabel(from, to)} · $scopeLabel',
    columns: const [
      'الرقم',
      'التاريخ',
      'النوع',
      'البند',
      'الاسم',
      'البيان',
      'المبلغ',
    ],
    rows: [
      for (final v in vouchers)
        [
          '${v.voucherNumber}',
          _date.format(v.voucherDate.toLocal()),
          v.voucherType.toArabicVoucherType(),
          v.itemType.isEmpty ? '—' : v.itemType,
          v.personName.isEmpty ? '—' : v.personName,
          v.reason.isEmpty ? '—' : v.reason,
          v.currency == 'USD' ? _usd(v.amount) : _iqd(v.amount),
        ],
    ],
    summary: [
      (label: 'عدد السندات', value: '${vouchers.length}'),
      (label: 'إجمالي القبض', value: _iqd(kabd)),
      (label: 'إجمالي الصرف', value: _iqd(sarf)),
    ],
    footerNote: 'مبالغ الدولار محوَّلة بسعر صرف سندها لا بسعر اليوم، '
        'فلا يتغيّر هذا التقرير بتحرّك السعر لاحقاً.',
    landscape: true,
    numericColumns: const {6},
  );
}

// ── ٤) المصروفات حسب البند ───────────────────────────────────────────────────

ReportTableData buildExpensesByItemTable({
  required DateTime from,
  required DateTime to,
  required String scopeLabel,
  required List<ItemTypeExpenseRow> rows,
}) {
  final total = rows.fold<double>(0, (a, r) => a + r.totalEquivalentIqd);
  final anyUsd = rows.any((r) => r.hasUsd);

  return ReportTableData(
    title: 'المصروفات حسب البند',
    subtitle: '${reportRangeLabel(from, to)} · $scopeLabel',
    columns: const ['#', 'البند', 'المبلغ (د.ع)', 'النسبة', 'عدد السندات'],
    rows: [
      for (var i = 0; i < rows.length; i++)
        [
          '${i + 1}',
          rows[i].displayName,
          _money.format(rows[i].totalEquivalentIqd),
          total <= 0
              ? '—'
              : '${(rows[i].totalEquivalentIqd / total * 100).toStringAsFixed(1)}%',
          '${rows[i].voucherCount}',
        ],
    ],
    summary: [
      (label: 'إجمالي المصروفات', value: _iqd(total)),
      (label: 'عدد البنود', value: '${rows.length}'),
      (
        label: 'عدد السندات',
        value: '${rows.fold<int>(0, (a, r) => a + r.voucherCount)}'
      ),
    ],
    numericColumns: const {2, 4},
    footerNote: [
      'التحويلات بين الخزائن ليست مصروفاً ولا تدخل في هذا التقرير.',
      'البند الفارغ يظهر «غير محدد» ليطابق المجموع الدفاتر.',
      if (anyUsd)
        'بعض المصروفات بالدولار — حُوّلت بسعر صرف كل سند وقت إنشائه.',
    ].join('\n'),
  );
}

// ── ٥) المستحقات ─────────────────────────────────────────────────────────────

/// خزائن العجز + من تدين لهم الشركة — **قسمان في ورقة واحدة**
///
/// يُدمجان في جدول واحد بعمود «النوع» لأن فصلهما إلى ورقتين يُفقد المالك
/// المقارنة بينهما، وهي كلّ فائدة التقرير: كم ناقص، ولمن.
ReportTableData buildDeficitTable({
  required List<TreasuryBalanceRow> balances,
  required List<DeficitCreditorRow> creditors,
}) {
  final deficits = balances.where((b) => b.balanceIqd < -0.001).toList();
  final totalDeficit = deficits.fold<double>(0, (a, b) => a + b.balanceIqd);
  final totalOwed = creditors.fold<double>(0, (a, c) => a + c.totalCovered);
  final anyUsd = deficits.any((b) => b.balanceUsd.abs() > 0.001);

  return ReportTableData(
    title: 'تقرير المستحقات',
    subtitle: 'خزائن بعجز: ${deficits.length} · دائنون: ${creditors.length}',
    columns: [
      'النوع',
      'الجهة',
      'المبلغ (د.ع)',
      if (anyUsd) 'المبلغ (\$)',
      'التفصيل',
    ],
    rows: [
      for (final b in deficits)
        [
          'خزينة بعجز',
          b.treasuryName,
          _money.format(b.balanceIqd),
          if (anyUsd) NumberFormat('#,##0.00').format(b.balanceUsd),
          '${b.totalVouchers} سند',
        ],
      for (final c in creditors)
        [
          'مستحقّ لشخص',
          c.coveredBy,
          _money.format(c.totalCovered),
          if (anyUsd) '—',
          '${c.advanceCount} سلفة',
        ],
    ],
    summary: [
      (label: 'إجمالي عجز الخزائن', value: _iqd(totalDeficit)),
      (label: 'مستحقّ لأشخاص', value: _iqd(totalOwed)),
    ],
    numericColumns: anyUsd ? const {2, 3} : const {2},
    footerNote: 'عجز الخزينة رصيدٌ سالب في دفاترنا؛ والمستحقّ لشخص مالٌ غطّى '
        'به عجز سلفة من جيبه. الرقمان لا يُجمعان.',
  );
}

// ── ٦) سلف المشاريع ─────────────────────────────────────────────────────────

/// قائمة سلف المشاريع بحالاتها
///
/// ⚠️ **لا يحمل المصروف الفعليّ لكل سلفة عمداً.** ذاك يأتي من
/// `advanceSummaryProvider` استعلاماً **لكل بطاقة على حدة**، وجمعه هنا يعني
/// عشرات الاستعلامات المتزامنة لحظة الضغط على «طباعة». والتقرير التفصيلي
/// لسلفة بعينها مكانه شاشة مراجعتها لا قائمةَ الكل.
ReportTableData buildAdvancesListTable({
  required String statusLabel,
  required String query,
  required List<AdvanceModel> advances,
}) {
  final filters = [
    'الحالة: $statusLabel',
    if (query.isNotEmpty) 'بحث: «$query»',
  ].join(' · ');

  return ReportTableData(
    title: 'تقرير سلف المشاريع',
    subtitle: filters,
    columns: const [
      'رقم السلفة',
      'المشروع',
      'التاريخ',
      'الحالة',
      'مجموع الملف (د.ع)',
      'العجز (د.ع)',
    ],
    rows: [
      for (final a in advances)
        [
          a.advanceNumber,
          a.projectName.isEmpty ? '—' : a.projectName,
          _date.format(a.advanceDate.toLocal()),
          a.status.toArabicAdvanceStatus(),
          a.excelTotal > 0 ? _money.format(a.excelTotal) : '—',
          a.deficitAmount > 0 ? _money.format(a.deficitAmount) : '—',
        ],
    ],
    summary: [
      (label: 'عدد السلف', value: '${advances.length}'),
      (
        label: 'مجموع ملفاتها',
        value: _iqd(advances.fold<double>(0, (s, a) => s + a.excelTotal))
      ),
    ],
    numericColumns: const {4, 5},
    footerNote: 'مجموع الملف هو ما ذكره ملف الإكسل عند الاستيراد — '
        'والمصروف الفعليّ لكل سلفة في شاشة مراجعتها.',
  );
}

// ── ٤-ب) سلف المشاريع **بسطورها** ───────────────────────────────────────────

/// تصدير السلف بتفاصيل مصاريفها — سطرٌ لكل مصروف لا لكل سلفة
///
/// 🔑 **ما كان ناقصاً** (الدفعة ج — بلاغ المالك 2026-08-30): التصدير كان
///   يُخرج **المبلغ الكلي** لكل سلفة، فالورقة تقول «سلفة ٢٣: ٨٬٤٠٠٬٠٠٠»
///   ولا تقول على ماذا. والسؤال الذي يُطرَح فعلاً — «على ماذا صُرفت؟» — يبقى
///   بلا جواب إلا بفتح البرنامج سلفةً سلفة.
///
/// ⚠️ **والمستبعَد يظهر ولا يُحتسَب.** إخفاؤه يجعل الورقة تقول إن المحاسب
///   أرسل عشرة مصاريف وقد أرسل اثني عشر — وهو تزييفٌ بالحذف. وعمودُ الحالة
///   يقول أيّها دخل المجموع، والمجموع نفسه لا يعدّ المستبعَد.
///
/// [itemQuery] — بند البحث الفعّال إن وُجد؛ يُكتَب في الترويسة كي **لا
///   تُقرأ الورقة ناقصةً** بعد شهور: صفحةٌ فيها الوقود وحده بلا ذكر الفلتر
///   تبدو كشفاً كاملاً للسلفة.
ReportTableData buildAdvanceLinesTable({
  required String statusLabel,
  required String query,
  required String itemQuery,
  required List<AdvanceModel> advances,
  required List<AdvanceLineModel> lines,
}) {
  final byId = {for (final a in advances) a.id: a};

  final filters = [
    'الحالة: $statusLabel',
    if (query.isNotEmpty) 'بحث: «$query»',
    if (itemQuery.isNotEmpty) 'البند: «$itemQuery»',
  ].join(' · ');

  final counted = lines.where((l) => !l.isExcluded).toList();
  final excluded = lines.length - counted.length;

  return ReportTableData(
    title: 'سلف المشاريع — بتفاصيل المصاريف',
    subtitle: filters,
    columns: const [
      'رقم السلفة',
      'المشروع',
      'التاريخ',
      'البند',
      'البيان',
      'الشخص',
      'الفاتورة',
      'المبلغ (د.ع)',
      'الحالة',
    ],
    rows: [
      for (final l in lines)
        [
          byId[l.advanceId]?.advanceNumber ?? '—',
          byId[l.advanceId]?.projectName.orDefault('—') ?? '—',
          _date.format(l.voucherDate.toLocal()),
          l.itemType.isEmpty ? 'بلا بند' : l.itemType,
          l.reason.orDefault('—'),
          l.personName.orDefault('—'),
          (l.invoiceNumber ?? '').orDefault('—'),
          _money.format(l.amount),
          l.isExcluded ? 'مستبعَد' : 'محتسَب',
        ],
    ],
    summary: [
      (label: 'عدد السلف', value: '${byId.length}'),
      (label: 'عدد المصاريف', value: '${counted.length}'),
      (
        label: 'المجموع المحتسَب',
        value: _iqd(counted.fold<double>(0, (s, l) => s + l.amount))
      ),
      if (excluded > 0) (label: 'مصاريف مستبعَدة', value: '$excluded'),
    ],
    landscape: true,
    numericColumns: const {7},
    footerNote: [
      'المصاريف المستبعَدة معروضة ولا تدخل المجموع.',
      if (itemQuery.isNotEmpty)
        'هذه الورقة مفلترة على البند «$itemQuery» — وليست كشف السلفة كاملاً.',
    ].join(' '),
  );
}

// ── ٧) كشف رواتب شهر ─────────────────────────────────────────────────────────

/// كشف رواتب شهر جاهزاً لـExcel — الأعمدة نفسها التي تُطبع في الـPDF
///
/// 🔑 **ما كان ناقصاً** (الدفعة ج — بلاغ المالك 2026-08-30): كشف الشهر كان
///   يُطبَع PDF ولا يُحفَظ Excel إطلاقاً، بينما البنية كلّها جاهزة
///   (`ExcelExportService` + `ReportPrintActions.exportExcel`). فمن أراد
///   جمعاً أو فرزاً أو معادلةً على الكشف طبعه ثم أعاد إدخاله بيده.
///
/// ⚠️ **والفرق المقصود عن ورقة الطباعة: الصفر يُكتَب صفراً لا «—».**
///   الشرطة أوضح على الورق، وفي Excel تجعل الخليّة **نصّاً** فينكسر جمع
///   العمود — وهو الغرض الوحيد من التصدير. والأيام أرقامٌ كذلك، فسؤال «كم
///   يوم غياب هذا الشهر؟» يُجاب بمعادلة واحدة.
///
/// ⚠️ **وعمود التوقيع لا يُصدَّر**: خانةٌ فارغة تُوقَّع باليد لا معنى لها في
///   ملف، وتُزيح الأعمدة بلا فائدة.
ReportTableData buildPayrollSheetTable(PayrollSheetPrintData data) {
  final hasUsd = data.hasForeignCurrency;
  final gap = data.fileTotalGap;

  return ReportTableData(
    title: 'كشف رواتب ${data.periodLabel}',
    subtitle: [
      'أيام العمل: ${data.workingDays}',
      if (data.exchangeRate != null)
        'سعر الصرف: ${_money.format(data.exchangeRate)}',
      data.isPosted ? 'الحالة: مُسدَّد' : 'الحالة: غير مُسدَّد بالكامل',
    ].join(' · '),
    columns: const [
      '#',
      'الاسم',
      'الصفة',
      'العملة',
      'الأساسي',
      'الأيام',
      'غياب',
      'إجازة (م)',
      'إجازة (غ)',
      'خصم الغياب',
      'مكافأة',
      'خصم',
      'خصم سلفة',
      'الصافي',
      'بالدينار',
      'الحالة',
    ],
    rows: [
      for (final r in data.rows)
        [
          '${r.seq}',
          r.name,
          r.position.orDefault('—'),
          r.currency == PayrollPrintCurrency.iqd ? 'د.ع' : '\$',
          _money.format(r.basicSalary),
          '${r.eligibleDays}',
          '${r.absenceDays}',
          // عمودان منفصلان لا خليّة واحدة: في Excel تُجمع وتُفرَز
          '${r.leaveDaysPaid}',
          '${r.leaveDaysUnpaid}',
          _money.format(r.absenceDeduction),
          _money.format(r.bonus),
          _money.format(r.deduction),
          _money.format(r.advanceRepayment),
          _money.format(r.net),
          _money.format(r.netIqd),
          r.isPaid
              ? (r.addedAfterPosting ? 'مسدَّد (لاحق)' : 'مسدَّد')
              : 'مستحقّ',
        ],
    ],
    summary: [
      (label: 'عدد الموظفين', value: '${data.employeeCount}'),
      (label: 'مجموع الكشف', value: _iqd(data.totalIqd)),
      (label: 'المُسدَّد', value: _iqd(data.paidIqd)),
      (label: 'المتبقّي', value: _iqd(data.unpaidIqd)),
      if (data.fileTotal > 0)
        (label: 'مجموع ملف المحاسب', value: _iqd(data.fileTotal)),
      if (gap != null) (label: 'الفرق عن الملف', value: _iqd(gap)),
    ],
    landscape: true,
    // كل عمود مالٍ أو عددِ أيام — فيُجمَع ويُفرَز في Excel
    numericColumns: const {4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14},
    footerNote: [
      'إجازة (م) = براتب · إجازة (غ) = بلا راتب وتُنقِص الأيام المستحقّة.',
      if (hasUsd)
        'رواتب الدولار محوَّلة في عمود «بالدينار» بسعر صرف الشهر المجمَّد '
            'لا بسعر اليوم.',
      if (gap != null)
        'مجموع الكشف يخالف مجموع ملف المحاسب — راجع الفرق أعلاه.',
    ].join(' '),
  );
}
