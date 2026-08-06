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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/services/pdf_print_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/treasury_model.dart';
import '../../../domain/models/voucher_model.dart';
import '../../providers/treasury_providers.dart';
import '../../providers/voucher_providers.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
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
                color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'إضافة سند جديد',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textDark : AppColors.textLight,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
            color: isDark ? AppColors.bgDark : AppColors.bgLight,
            child: Column(
              children: [
                Row(
                  children: [
                    // حقل البحث
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? AppColors.textDark : AppColors.textLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'بحث برقم السند، الاسم، البيان...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
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
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _selectedTreasuryId,
                            hint: Text(
                              'كل الخزائن',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textDark : AppColors.textLight,
                              ),
                            ),
                            icon: Icon(
                              Icons.filter_list_rounded,
                              size: 18,
                              color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                            ),
                            dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  'كل الخزائن',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.textDark : AppColors.textLight,
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
                                      color: isDark ? AppColors.textDark : AppColors.textLight,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => _selectedTreasuryId = v),
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
                        backgroundColor: isDark ? AppColors.goldDark : AppColors.goldLight,
                        foregroundColor: isDark ? AppColors.navy : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // شريط التبويبات (الكل / قبض / صرف / تحويل)
                TabBar(
                  controller: _tabCtrl,
                  indicatorColor: isDark ? AppColors.goldDark : AppColors.navy,
                  labelColor: isDark ? AppColors.goldDark : AppColors.navy,
                  unselectedLabelColor: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
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
                  treasuryMap: treasuryMap,
                  onTapVoucher: (v) => _navigateToVoucherDetail(v),
                ),
                _VoucherTab(
                  typeFilter: 'kabd',
                  query: _query,
                  treasuryId: _selectedTreasuryId,
                  treasuryMap: treasuryMap,
                  onTapVoucher: (v) => _navigateToVoucherDetail(v),
                ),
                _VoucherTab(
                  typeFilter: 'sarf',
                  query: _query,
                  treasuryId: _selectedTreasuryId,
                  treasuryMap: treasuryMap,
                  onTapVoucher: (v) => _navigateToVoucherDetail(v),
                ),
                _VoucherTab(
                  typeFilter: 'transfer',
                  query: _query,
                  treasuryId: _selectedTreasuryId,
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

  void _navigateToVoucherDetail(VoucherModel v) {
    if (v.voucherType == 'sarf' || v.voucherType == 'transfer_out') {
      context.go('/vouchers/sarf/${v.id}');
    } else if (v.voucherType == 'kabd' || v.voucherType == 'transfer_in') {
      context.go('/vouchers/kabd/${v.id}');
    } else {
      context.go('/vouchers/transfer');
    }
  }
}

// ── تبويب قائمة السندات ──────────────────────────────────────────────────────

class _VoucherTab extends ConsumerWidget {
  final String? typeFilter;
  final String query;
  final int? treasuryId;
  final AsyncValue<Map<int, TreasuryModel>> treasuryMap;
  final void Function(VoucherModel) onTapVoucher;

  const _VoucherTab({
    required this.typeFilter,
    required this.query,
    required this.treasuryId,
    required this.treasuryMap,
    required this.onTapVoucher,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sarfAsync = ref.watch(vouchersByTypeProvider('sarf'));
    final kabdAsync = ref.watch(vouchersByTypeProvider('kabd'));

    if (typeFilter != null) {
      final streamAsync = ref.watch(vouchersByTypeProvider(typeFilter!));
      return streamAsync.when(
        data: (list) => _renderList(context, list, isDark),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      );
    }

    if (sarfAsync.isLoading || kabdAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final combined = [
      ...sarfAsync.valueOrNull ?? [],
      ...kabdAsync.valueOrNull ?? [],
    ]..sort((a, b) => b.voucherDate.compareTo(a.voucherDate));

    return _renderList(context, combined, isDark);
  }

  Widget _renderList(BuildContext context, List<VoucherModel> list, bool isDark) {
    var filtered = list;

    // فلترة البحث
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered.where((v) {
        final numStr = v.voucherNumber.toString();
        final person = v.personName.toLowerCase();
        final reason = v.reason.toLowerCase();
        return numStr.contains(q) || person.contains(q) || reason.contains(q);
      }).toList();
    }

    // فلترة الخزينة
    if (treasuryId != null) {
      filtered = filtered.where((v) => v.treasuryId == treasuryId).toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
            ),
            const SizedBox(height: 14),
            Text(
              'لا توجد سندات مطابقة للبحث',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
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

class _VoucherRowCard extends StatelessWidget {
  final VoucherModel voucher;
  final TreasuryModel? treasury;
  final VoidCallback onTap;

  const _VoucherRowCard({
    required this.voucher,
    required this.treasury,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
    final fmtNum = NumberFormat('#,##0.##');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
                color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
              ),
            ),
            const SizedBox(width: 16),

            // المستلم / البيان
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voucher.personName.isNotEmpty ? voucher.personName : (voucher.reason.isNotEmpty ? voucher.reason : 'سند بدون اسم'),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (treasury != null)
                    Text(
                      'خزينة: ${treasury!.name}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
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
                color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
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
                color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
              ),
              tooltip: 'طباعة PDF',
              onPressed: () => PdfPrintHelper.printVoucherReceipt(context, voucher),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
                color: isDark ? AppColors.textDark : AppColors.textLight,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
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
