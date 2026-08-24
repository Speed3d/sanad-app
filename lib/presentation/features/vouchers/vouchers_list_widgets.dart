// ─────────────────────────────────────────────────────────────────────────────
// vouchers_list_widgets.dart — مكوّنات شاشة السندات
//
// جزء من مكتبة `vouchers_list_screen.dart` — فُصل لأن إضافة الفلاتر
// المتقدّمة (2026-08-24) دفعت الملف الأصل فوق حدّ الـ ١٢٠٠ سطر الذي يحرسه
// `test/unit/tech_debt_guard_test.dart`. **الحارس هو من كشف ذلك** لا العين.
//
// نستعمل `part` لا ملفاً مستقلاً كي تبقى الأصناف **خاصة** (`_X`) كما هي.
//
// يحوي: فلاتر البند والمشروع · الفلاتر المتقدّمة · تبويب القائمة · كارت
// السند · بلاطة الإضافة · ورقة التفاصيل.
// ─────────────────────────────────────────────────────────────────────────────

part of 'vouchers_list_screen.dart';

// ── فلاتر البند والمشروع ─────────────────────────────────────────────────────

/// صفّ الفلاتر الثانوية — يظهر كلّ فلتر فقط حين توجد قيم فعلاً
///
/// **لماذا الظهور المشروط؟** (ب-١ — 2026-08-23)
///   في قاعدة بيانات جديدة لا توجد مشاريع بعد، فقائمة «المشروع» ستحوي خياراً
///   واحداً هو «الكل» — ضجيج بصري يشغل مساحة بلا فائدة. وحين يبدأ المالك
///   بإدخال المشاريع يظهر الفلتر تلقائياً.
///
/// **ولماذا القيم المستعملة فقط؟** جدول `item_types` فيه ٢١ بنداً مبذوراً.
/// عرضها كلها يعني أن أغلب الخيارات تُعطي نتيجة فارغة فيظنّ المستخدم الفلتر
/// معطوباً. راجع `VouchersDao.watchUsedItemTypes`.
class _SecondaryFilters extends ConsumerWidget {
  const _SecondaryFilters({
    required this.itemType,
    required this.project,
    required this.onItemType,
    required this.onProject,
  });

  final String? itemType;
  final String? project;
  final ValueChanged<String?> onItemType;
  final ValueChanged<String?> onProject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(usedItemTypesProvider).valueOrNull ?? const [];
    final projects = ref.watch(usedProjectsProvider).valueOrNull ?? const [];

    // لا فلاتر متاحة بعد — لا نشغل مساحة بصفّ فارغ
    if (types.isEmpty && projects.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          if (types.isNotEmpty)
            Expanded(
              child: ItemTypeFilterDropdown(
                values: types,
                selected: itemType,
                onChanged: onItemType,
              ),
            ),
          if (types.isNotEmpty && projects.isNotEmpty)
            const SizedBox(width: 12),
          if (projects.isNotEmpty)
            Expanded(
              child: ItemTypeFilterDropdown(
                values: projects,
                selected: project,
                onChanged: onProject,
                label: 'المشروع',
                icon: Icons.location_city_outlined,
              ),
            ),
          // زرّ مسح سريع — الوصول لكل قائمة واختيار «الكل» عمل متكرّر
          if (itemType != null || project != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'مسح الفلاتر',
              icon: const Icon(Icons.filter_alt_off_outlined, size: 20),
              onPressed: () {
                onItemType(null);
                onProject(null);
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ── الفلاتر المتقدّمة: نطاق التاريخ والمبلغ ─────────────────────────────────

/// لوحة نطاقَي التاريخ والمبلغ (طلب المالك 2026-08-24)
///
/// **لماذا نطاقات لا قيمة واحدة؟** السؤال الفعلي نادراً ما يكون «سند بمبلغ
/// ٥٠٠ ألف بالضبط»، بل «ما بين ١٠٠ ألف ومليون» أو «سندات آب». والنطاق يشمل
/// الحالة المفردة (تساوي الطرفين) ولا العكس.
///
/// كل حقل مستقلّ: تحديد «من» وحده يعني «كل ما بعد هذا التاريخ».
class _AdvancedFilters extends StatelessWidget {
  const _AdvancedFilters({
    required this.fromDate,
    required this.toDate,
    required this.minAmount,
    required this.maxAmount,
    required this.onFrom,
    required this.onTo,
    required this.onMin,
    required this.onMax,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final double? minAmount;
  final double? maxAmount;
  final ValueChanged<DateTime?> onFrom;
  final ValueChanged<DateTime?> onTo;
  final ValueChanged<double?> onMin;
  final ValueChanged<double?> onMax;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DateBox(
                  label: 'من تاريخ',
                  value: fromDate,
                  onChanged: onFrom,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateBox(
                  label: 'إلى تاريخ',
                  value: toDate,
                  onChanged: onTo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AmountBox(
                  label: 'أقلّ مبلغ',
                  value: minAmount,
                  onChanged: onMin,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AmountBox(
                  label: 'أعلى مبلغ',
                  value: maxAmount,
                  onChanged: onMax,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// حقل تاريخ قابل للمسح
class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          locale: const Locale('ar'),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.event_outlined, size: 18),
          // زر المسح يظهر فقط حين توجد قيمة — بلا مسح يبقى النطاق
          // مضبوطاً ولا سبيل لإلغائه إلا بمسح كل الفلاتر
          suffixIcon: value == null
              ? null
              : IconButton(
                  tooltip: 'مسح',
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(
          value == null
              ? 'الكل'
              : '${value!.year}/${value!.month.toString().padLeft(2, '0')}/'
                  '${value!.day.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 13.5,
            color: value == null ? context.colors.subtext : null,
          ),
        ),
      ),
    );
  }
}

/// حقل مبلغ رقمي قابل للمسح
class _AmountBox extends StatefulWidget {
  const _AmountBox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double? value;
  final ValueChanged<double?> onChanged;

  @override
  State<_AmountBox> createState() => _AmountBoxState();
}

class _AmountBoxState extends State<_AmountBox> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.value == null ? '' : widget.value!.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      // الفواصل تُزال قبل التحويل — المستخدم قد يكتب 1,000,000
      onChanged: (t) {
        final cleaned = t.replaceAll(RegExp(r'[^0-9.]'), '');
        widget.onChanged(cleaned.isEmpty ? null : double.tryParse(cleaned));
      },
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'الكل',
        isDense: true,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.payments_outlined, size: 18),
        suffixIcon: _ctrl.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'مسح',
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  _ctrl.clear();
                  widget.onChanged(null);
                  setState(() {});
                },
              ),
      ),
    );
  }
}

// ── تبويب قائمة السندات ──────────────────────────────────────────────────────

class _VoucherTab extends ConsumerWidget {
  final String? typeFilter;
  final String query;
  final int? treasuryId;

  /// فلترة بنوع البند — null = الكل
  final String? itemType;

  /// فلترة باسم المشروع — null = الكل
  final String? project;

  /// نطاق التاريخ — null في أي طرف يعني بلا حدّ من تلك الجهة
  final DateTime? fromDate;
  final DateTime? toDate;

  /// نطاق المبلغ — يُقارَن بالمبلغ كما هو بعملته
  final double? minAmount;
  final double? maxAmount;

  final AsyncValue<Map<int, TreasuryModel>> treasuryMap;
  final void Function(VoucherModel) onTapVoucher;

  const _VoucherTab({
    required this.typeFilter,
    required this.query,
    required this.treasuryId,
    required this.itemType,
    required this.project,
    required this.fromDate,
    required this.toDate,
    required this.minAmount,
    required this.maxAmount,
    required this.treasuryMap,
    required this.onTapVoucher,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // تبويب بنوع محدد — نراقب مزوّداً واحداً فقط (لا اشتراكات زائدة)
    if (typeFilter != null) {
      final streamAsync = ref.watch(vouchersByTypeProvider(typeFilter!));
      return streamAsync.when(
        data: (list) => _renderList(context, list, isDark),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      );
    }

    // تبويب "الكل" — دمج الصرف (+صادر) والقبض (+وارد) = كل الأنواع الحركية
    final sarfAsync = ref.watch(vouchersByTypeProvider('sarf'));
    final kabdAsync = ref.watch(vouchersByTypeProvider('kabd'));

    if (sarfAsync.isLoading || kabdAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final combined = <VoucherModel>[
      ...sarfAsync.valueOrNull ?? [],
      ...kabdAsync.valueOrNull ?? [],
    ]..sort((a, b) => b.voucherDate.compareTo(a.voucherDate));

    return _renderList(context, combined, isDark);
  }

  /// سبب خلوّ القائمة — يُسمّي الفلتر الفعّال بدل رسالة عامة
  String _emptyReason() {
    final active = <String>[
      if (query.isNotEmpty) 'البحث',
      if (treasuryId != null) 'الخزينة',
      if (itemType != null) 'البند "$itemType"',
      if (project != null) 'المشروع "$project"',
      if (fromDate != null || toDate != null) 'نطاق التاريخ',
      if (minAmount != null || maxAmount != null) 'نطاق المبلغ',
    ];
    if (active.isEmpty) return 'لا توجد سندات بعد';
    return 'لا توجد سندات مطابقة لـ ${active.join(' و')}';
  }

  Widget _renderList(
      BuildContext context, List<VoucherModel> list, bool isDark) {
    var filtered = list;

    // ── البحث النصّي الشامل ──────────────────────────────────────────
    //
    // وُسّع ليشمل كل ما يكتبه المستخدم في السند (طلب المالك 2026-08-24):
    // كان يمسح الرقم والاسم والسبب فقط، فالبحث عن رقم فاتورة أو اسم مشروع
    // أو مبلغ لا يُرجع شيئاً رغم أن القيمة ظاهرة على الشاشة.
    if (query.isNotEmpty) {
      final q = query.toLowerCase().trim();
      // الرقم المكتوب بلا فواصل يطابق المبلغ المخزَّن
      final qDigits = q.replaceAll(RegExp(r'[^0-9.]'), '');
      filtered = filtered.where((v) {
        bool has(String? x) => (x ?? '').toLowerCase().contains(q);
        final amountMatch = qDigits.isNotEmpty &&
            v.amount.toStringAsFixed(0).contains(qDigits);
        return v.voucherNumber.toString().contains(q) ||
            has(v.personName) ||
            has(v.reason) ||
            has(v.itemType) ||
            has(v.referenceNumber) ||
            has(v.projectName) ||
            has(v.invoiceNumber) ||
            has(v.spentBy) ||
            has(v.advanceNumber) ||
            amountMatch;
      }).toList();
    }

    // ── نطاق التاريخ ────────────────────────────────────────────────
    // الطرفان شاملان: «من ١ آب إلى ٣١ آب» يجب أن تضمّ سندات اليومين نفسهما
    if (fromDate != null) {
      final f = DateTime(fromDate!.year, fromDate!.month, fromDate!.day);
      filtered = filtered.where((v) => !v.voucherDate.isBefore(f)).toList();
    }
    if (toDate != null) {
      final t = DateTime(
          toDate!.year, toDate!.month, toDate!.day, 23, 59, 59, 999);
      filtered = filtered.where((v) => !v.voucherDate.isAfter(t)).toList();
    }

    // ── نطاق المبلغ ─────────────────────────────────────────────────
    // هامش صغير يتفادى أخطاء تقريب العشريات عند المطابقة على الحدّ تماماً
    if (minAmount != null) {
      filtered = filtered.where((v) => v.amount >= minAmount! - 0.001).toList();
    }
    if (maxAmount != null) {
      filtered = filtered.where((v) => v.amount <= maxAmount! + 0.001).toList();
    }

    // فلترة الخزينة
    if (treasuryId != null) {
      filtered = filtered.where((v) => v.treasuryId == treasuryId).toList();
    }

    // فلترة نوع البند — مطابقة تامة لا جزئية: البنود قيم من قائمة مضبوطة
    // لا نصّ حرّ، والمطابقة الجزئية تجعل «سلفة» تلتقط «سلفة موظف» أيضاً.
    if (itemType != null) {
      filtered = filtered.where((v) => v.itemType == itemType).toList();
    }

    // فلترة المشروع — العمود nullable فالسندات بلا مشروع تُستبعَد ضمناً
    if (project != null) {
      filtered = filtered.where((v) => v.projectName == project).toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: context.colors.subtext,
            ),
            const SizedBox(height: 14),
            Text(
              // نُسمّي الفلتر الفعّال بدل رسالة عامة: المستخدم قد يكون نسي
              // فلتراً مضبوطاً في تبويب آخر فيظنّ السندات اختفت.
              _emptyReason(),
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: context.colors.subtext,
              ),
            ),
          ],
        ),
      );
    }

    final tMap = treasuryMap.valueOrNull ?? {};

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _VoucherRowCard(
        voucher: filtered[i],
        treasury: tMap[filtered[i].treasuryId],
        onTap: () => onTapVoucher(filtered[i]),
      ),
    );
  }
}

// ── كارت السند الفردي (Voucher Item Card) ───────────────────────────────────

// ConsumerWidget لا StatelessWidget: زر الطباعة يحتاج ترويسة الشركة
// من المزوّدات (ب-٣)
class _VoucherRowCard extends ConsumerWidget {
  final VoucherModel voucher;
  final TreasuryModel? treasury;
  final VoidCallback onTap;

  const _VoucherRowCard({
    required this.voucher,
    required this.treasury,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isKabd = voucher.isKabd;
    final isTransfer = voucher.voucherType.contains('transfer');

    final Color badgeBg = isKabd
        ? Colors.green.withValues(alpha: 0.12)
        : isTransfer
            ? Colors.blue.withValues(alpha: 0.12)
            : Colors.red.withValues(alpha: 0.12);

    final Color badgeText = isKabd
        ? Colors.green.shade600
        : isTransfer
            ? Colors.blue.shade600
            : Colors.red.shade600;

    final fmtDate = DateFormat('yyyy/MM/dd', 'ar');
    final fmtNum = NumberFormat('#,##0');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.border,
          ),
        ),
        child: Row(
          children: [
            // شارة نوع السند
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                voucher.typeDisplayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: badgeText,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // رقم السند
            Text(
              '#${voucher.voucherNumber}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.colors.subtext,
              ),
            ),
            const SizedBox(width: 16),

            // المستلم / البيان
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voucher.personName.isNotEmpty
                        ? voucher.personName
                        : (voucher.reason.isNotEmpty
                            ? voucher.reason
                            : 'سند بدون اسم'),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: context.colors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (treasury != null)
                    Text(
                      'خزينة: ${treasury!.name}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.colors.subtext,
                      ),
                    ),
                ],
              ),
            ),

            // التاريخ
            Text(
              fmtDate.format(voucher.voucherDate),
              style: TextStyle(
                fontSize: 12,
                color: context.colors.subtext,
              ),
            ),
            const SizedBox(width: 20),

            // المبلغ
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${fmtNum.format(voucher.amount)} ${voucher.currency == 'IQD' ? 'د.ع' : '\$'}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: badgeText,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // زر الطباعة
            IconButton(
              icon: Icon(
                Icons.print_outlined,
                size: 19,
                color: context.colors.subtext,
              ),
              tooltip: 'طباعة PDF',
              // نمرّر ترويسة الشركة إن كانت جاهزة؛ وإن لم تُحمَّل بعد
              // يُطبَع السند بلا ترويسة بدل تعطيل الزر
              onPressed: () => PdfPrintHelper.printVoucherReceipt(
                context,
                voucher,
                header: ref.read(pdfCompanyHeaderProvider).valueOrNull ??
                    PdfCompanyHeader.empty,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── بلاطة خيار إضافة سند ────────────────────────────────────────────────────

class _AddVoucherTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color chipBg;
  final Color color;
  final VoidCallback onTap;

  const _AddVoucherTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.chipBg,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.border,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: context.colors.text,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: context.colors.subtext,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ── ورقة تفاصيل سند للقراءة فقط ──────────────────────────────────────────────

/// عرض تفاصيل سند لا يُعدَّل (تحويل أو رصيد افتتاحي)
///
/// وُجدت لإصلاح ح-١: كانت سندات التحويل تُفتح في شاشة تعديل الصرف/القبض
/// فيُعدَّل طرف واحد دون توأمه. الآن تُعرض هنا للقراءة، مع زر حذف يحذف
/// الطرفين معاً عند الاقتضاء.
class _VoucherDetailsSheet extends StatelessWidget {
  const _VoucherDetailsSheet({
    required this.voucher,
    required this.title,
    required this.note,
    this.onDelete,
  });

  final VoucherModel voucher;
  final String title;
  final String note;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0');
    final dateFmt = DateFormat('yyyy/MM/dd');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync_alt, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleMedium),
              const Spacer(),
              Text('#${voucher.voucherNumber}',
                  style: theme.textTheme.bodySmall),
            ],
          ),
          const Divider(height: 20),
          _row('المبلغ', '${fmt.format(voucher.amount)} ${voucher.currency}'),
          _row('التاريخ', dateFmt.format(voucher.voucherDate)),
          if (voucher.reason.isNotEmpty) _row('البيان', voucher.reason),
          if (voucher.personName.isNotEmpty) _row('الشخص', voucher.personName),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(note, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إغلاق'),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                    ),
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('حذف التحويل'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
