// ─────────────────────────────────────────────────────────────────────────────
// vouchers_list_screen.dart — شاشة قائمة السندات (Fintech Vouchers List)
//
// الميزات والتحديثات:
//   - شريط تصفية متعدد التبويبات (الكل / قبض / صرف / تحويل)
//   - شريط بحث متقدم مع فلاتر الخزائن والتاريخ
//   - بطاقات سندات عصرية مع شارات أنواع ملونة (قبض أخضر / صرف أحمر / تحويل أزرق)
//   - خيارات الإجراءات الفورية لكل سند (عرض التاصيل / طباعة PDF / حذف)
//   - نافذة الخيارات السفلية لإنشاء سند جديد (صرف / قبض / تحويل)
// ─────────────────────────────────────────────────────────────────────────────

import '../../../core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/services/pdf_print_helper.dart';
import '../../../domain/models/treasury_model.dart';
import '../../../domain/models/voucher_model.dart';
import '../../providers/treasury_providers.dart';
import '../../../core/services/pdf_service.dart' show PdfCompanyHeader;
import '../../providers/settings_provider.dart';
import '../../providers/voucher_providers.dart';
import '../../widgets/common/item_type_selector.dart';

// ── أجزاء المكتبة ───────────────────────────────────────────────────
part 'vouchers_list_widgets.dart';

/// شاشة السندات الرئيسية مع تبويبات الفلترة والبحث
class VouchersListScreen extends ConsumerStatefulWidget {
  const VouchersListScreen({super.key});

  @override
  ConsumerState<VouchersListScreen> createState() => _VouchersListScreenState();
}

class _VouchersListScreenState extends ConsumerState<VouchersListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';
  int? _selectedTreasuryId;

  // ── فلترة بالبند والمشروع (ب-١ — 2026-08-23) ────────────────────────
  // كانت الفلاتر بحثاً نصّياً وخزينةً فقط. البحث النصّي يمسح الاسم والسبب
  // ورقم السند — ولا يمسّ البند ولا المشروع إطلاقاً، فكان السؤال «ما صُرف
  // على البانزين في البصرة؟» بلا جواب من هذه الشاشة.
  // null = بلا فلترة (الكل).
  String? _itemTypeFilter;
  String? _projectFilter;

  // ── فلترة بالتاريخ والمبلغ (طلب المالك 2026-08-24) ──────────────────
  // «أريد سنداً بتاريخ معيّن أو مبلغ معيّن» — لم يكن لهما سبيل: البحث
  // النصّي لا يفهم النطاقات، وفلتر الخزينة لا يضيّق زمنياً.
  // null في كل حقل = بلا تقييد من تلك الجهة.
  DateTime? _fromDate;
  DateTime? _toDate;
  double? _minAmount;
  double? _maxAmount;

  /// هل لوحة الفلاتر المتقدّمة مفتوحة؟
  bool _advancedOpen = false;

  /// عدد الفلاتر المتقدّمة الفعّالة — يظهر شارةً على الزرّ
  int get _advancedCount =>
      (_fromDate != null ? 1 : 0) +
      (_toDate != null ? 1 : 0) +
      (_minAmount != null ? 1 : 0) +
      (_maxAmount != null ? 1 : 0);

  /// مسح الفلاتر المتقدّمة وحدها
  void _clearAdvanced() => setState(() {
        _fromDate = null;
        _toDate = null;
        _minAmount = null;
        _maxAmount = null;
      });

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// إظهار نافذة اختيار نوع السند الجديد
  void _showAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // المقبض
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: context.colors.surface2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'إضافة سند جديد',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.colors.text,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // سند صرف
                Expanded(
                  child: _AddVoucherTile(
                    icon: Icons.north_east_rounded,
                    label: 'سند صرف',
                    subtitle: 'صرف مالي من الخزينة',
                    chipBg: Colors.red.withValues(alpha: 0.12),
                    color: Colors.red.shade600,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go(AppRoutes.voucherSarf);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // سند قبض
                Expanded(
                  child: _AddVoucherTile(
                    icon: Icons.south_west_rounded,
                    label: 'سند قبض',
                    subtitle: 'إيداع مالي في الخزينة',
                    chipBg: Colors.green.withValues(alpha: 0.12),
                    color: Colors.green.shade600,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go(AppRoutes.voucherKabd);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // تحويل
                Expanded(
                  child: _AddVoucherTile(
                    icon: Icons.swap_horiz_rounded,
                    label: 'تحويل مالي',
                    subtitle: 'نقل بين خزينتين',
                    chipBg: Colors.blue.withValues(alpha: 0.12),
                    color: Colors.blue.shade600,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go(AppRoutes.voucherTransfer);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final treasuriesAsync = ref.watch(allTreasuriesProvider);

    final treasuryMap = treasuriesAsync.whenData(
      (list) => {for (final t in list) t.id: t},
    );

    return Scaffold(
      body: Column(
        children: [
          // ── شريط الأدوات والبحث والفلترة ───────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
            color: context.colors.bg,
            child: Column(
              children: [
                Row(
                  children: [
                    // حقل البحث
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.colors.border,
                          ),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: context.colors.text,
                          ),
                          decoration: InputDecoration(
                            hintText: 'بحث برقم السند، الاسم، البيان...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: context.colors.subtext,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: context.colors.subtext,
                            ),
                            suffixIcon: _query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _query = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // فلتر الخزائن
                    treasuriesAsync.when(
                      data: (treasuries) => Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.colors.border,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _selectedTreasuryId,
                            hint: Text(
                              'كل الخزائن',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.colors.text,
                              ),
                            ),
                            icon: Icon(
                              Icons.filter_list_rounded,
                              size: 18,
                              color: context.colors.subtext,
                            ),
                            dropdownColor: context.colors.surface,
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  'كل الخزائن',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.colors.text,
                                  ),
                                ),
                              ),
                              ...treasuries.map(
                                (t) => DropdownMenuItem<int?>(
                                  value: t.id,
                                  child: Text(
                                    t.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.colors.text,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedTreasuryId = v),
                          ),
                        ),
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),

                    const SizedBox(width: 12),

                    // زر إضافة سند جديد
                    ElevatedButton.icon(
                      onPressed: _showAddSheet,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('سند جديد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.gold,
                        foregroundColor: context.colors.onGold,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),

                // ── الصف الثاني: البند والمشروع ─────────────────────
                // في صفّ مستقلّ لا مع البحث والخزينة: أربعة عناصر في صفّ
                // واحد تتزاحم على الشاشات الضيّقة.
                // يظهر كلٌّ منهما فقط حين توجد قيم فعلاً — فلتر بخيار
                // واحد اسمه «الكل» ضجيج بصري بلا فائدة.
                _SecondaryFilters(
                  itemType: _itemTypeFilter,
                  project: _projectFilter,
                  onItemType: (v) => setState(() => _itemTypeFilter = v),
                  onProject: (v) => setState(() => _projectFilter = v),
                ),

                // ── الفلاتر المتقدّمة: التاريخ والمبلغ ──────────────────
                // مطويّة افتراضياً: الإدخال اليومي لا يحتاجها، وإظهارها
                // دائماً يُزاحم الشاشة. الشارة الرقمية تمنع نسيانها مضبوطة.
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(
                            () => _advancedOpen = !_advancedOpen),
                        icon: Icon(
                          _advancedOpen
                              ? Icons.expand_less
                              : Icons.tune_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _advancedCount > 0
                              ? 'فلاتر متقدّمة ($_advancedCount)'
                              : 'فلاتر متقدّمة',
                          style: TextStyle(
                            fontWeight: _advancedCount > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_advancedCount > 0)
                        TextButton.icon(
                          onPressed: _clearAdvanced,
                          icon: const Icon(Icons.filter_alt_off_outlined,
                              size: 17),
                          label: const Text('مسح'),
                        ),
                    ],
                  ),
                ),

                if (_advancedOpen)
                  _AdvancedFilters(
                    fromDate: _fromDate,
                    toDate: _toDate,
                    minAmount: _minAmount,
                    maxAmount: _maxAmount,
                    onFrom: (d) => setState(() => _fromDate = d),
                    onTo: (d) => setState(() => _toDate = d),
                    onMin: (v) => setState(() => _minAmount = v),
                    onMax: (v) => setState(() => _maxAmount = v),
                  ),

                const SizedBox(height: 16),

                // شريط التبويبات (الكل / قبض / صرف / تحويل)
                TabBar(
                  controller: _tabCtrl,
                  indicatorColor: context.colors.gold,
                  labelColor: context.colors.gold,
                  unselectedLabelColor: context.colors.subtext,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13.5),
                  tabs: const [
                    Tab(text: 'الكل'),
                    Tab(text: 'سندات القبض'),
                    Tab(text: 'سندات الصرف'),
                    Tab(text: 'التحويلات'),
                  ],
                ),
              ],
            ),
          ),

          // ── محتوى القائمة ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _VoucherTab(
                  typeFilter: null,
                  query: _query,
                  treasuryId: _selectedTreasuryId,
                  itemType: _itemTypeFilter,
                  project: _projectFilter,
                  fromDate: _fromDate,
                  toDate: _toDate,
                  minAmount: _minAmount,
                  maxAmount: _maxAmount,
                  treasuryMap: treasuryMap,
                  onTapVoucher: (v) => _navigateToVoucherDetail(v),
                ),
                _VoucherTab(
                  typeFilter: 'kabd',
                  query: _query,
                  treasuryId: _selectedTreasuryId,
                  itemType: _itemTypeFilter,
                  project: _projectFilter,
                  fromDate: _fromDate,
                  toDate: _toDate,
                  minAmount: _minAmount,
                  maxAmount: _maxAmount,
                  treasuryMap: treasuryMap,
                  onTapVoucher: (v) => _navigateToVoucherDetail(v),
                ),
                _VoucherTab(
                  typeFilter: 'sarf',
                  query: _query,
                  treasuryId: _selectedTreasuryId,
                  itemType: _itemTypeFilter,
                  project: _projectFilter,
                  fromDate: _fromDate,
                  toDate: _toDate,
                  minAmount: _minAmount,
                  maxAmount: _maxAmount,
                  treasuryMap: treasuryMap,
                  onTapVoucher: (v) => _navigateToVoucherDetail(v),
                ),
                _VoucherTab(
                  typeFilter: 'transfer',
                  query: _query,
                  treasuryId: _selectedTreasuryId,
                  itemType: _itemTypeFilter,
                  project: _projectFilter,
                  fromDate: _fromDate,
                  toDate: _toDate,
                  minAmount: _minAmount,
                  maxAmount: _maxAmount,
                  treasuryMap: treasuryMap,
                  onTapVoucher: (v) => _navigateToVoucherDetail(v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// التوجيه عند الضغط على سند في القائمة
  ///
  /// ⚠️ سندات التحويل تُفتح للعرض فقط (إصلاح ح-١ — تدقيق 2026-08-15).
  ///   كانت تُوجَّه إلى شاشتَي تعديل الصرف/القبض، فيُعدَّل طرف واحد من
  ///   التحويل دون توأمه ← يظهر مال من العدم أو يختفي.
  ///   التصحيح الآن بالحذف (يحذف الطرفين معاً) ثم إعادة الإنشاء.
  void _navigateToVoucherDetail(VoucherModel v) {
    if (v.voucherType == 'transfer_out' || v.voucherType == 'transfer_in') {
      _showTransferDetails(v);
      return;
    }
    if (v.voucherType == 'sarf') {
      context.go('/vouchers/sarf/${v.id}');
    } else if (v.voucherType == 'kabd') {
      context.go('/vouchers/kabd/${v.id}');
    } else {
      // الأرصدة الافتتاحية وغيرها — للعرض فقط، لا شاشة تعديل لها
      _showReadOnlyDetails(v);
    }
  }

  /// ورقة تفاصيل التحويل — للقراءة فقط مع إمكانية الحذف
  ///
  /// التحويل لا يُعدَّل (يخلّ بتوازن الخزينتين)، لكنه يُحذف بأمان:
  /// `softDeleteVoucher` يحذف الطرفين معاً عبر `transfer_group_id`.
  void _showTransferDetails(VoucherModel v) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _VoucherDetailsSheet(
        voucher: v,
        title: v.voucherType == 'transfer_out' ? 'تحويل صادر' : 'تحويل وارد',
        note: 'التحويل سندان مرتبطان ولا يُعدَّل أحدهما بمعزل عن الآخر.\n'
            'لتصحيحه: احذفه (يُحذف الطرفان معاً) ثم أنشئه من جديد.',
        onDelete: () => _confirmDeleteVoucher(v),
      ),
    );
  }

  /// ورقة تفاصيل عامة للقراءة فقط (الأرصدة الافتتاحية وغيرها)
  void _showReadOnlyDetails(VoucherModel v) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _VoucherDetailsSheet(
        voucher: v,
        title: v.typeDisplayName,
        note: 'هذا السند يُنشئه النظام ولا يُعدَّل يدوياً.',
      ),
    );
  }

  /// تأكيد حذف سند تحويل — يوضّح أن الطرفين سيُحذفان
  Future<void> _confirmDeleteVoucher(VoucherModel v) async {
    Navigator.of(context).pop(); // إغلاق ورقة التفاصيل أولاً
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التحويل'),
        content: const Text(
          'سيُحذف طرفا التحويل معاً (الصادر والوارد)، فيرتدّ المبلغ إلى '
          'الخزينة المُرسِلة ويُخصم من المُستقبِلة.\n\n'
          'الحذف ناعم — يبقى الأثر الرقابي في سجل التدقيق.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، احذف التحويل'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    // deleteSarf يستدعي softDeleteVoucher الذي يحذف طرفَي التحويل معاً
    await ref.read(voucherSarfNotifierProvider.notifier).deleteSarf(v.id);
  }
}
