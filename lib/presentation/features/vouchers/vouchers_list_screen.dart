// ─────────────────────────────────────────────────────────────────────────────
// vouchers_list_screen.dart — شاشة قائمة السندات
//
// الميزات:
//   - تبويبان: سند صرف / سند قبض
//   - بحث نصي في السندات (اسم، سبب، مرجع)
//   - بطاقة لكل سند مع المبلغ والخزينة والتاريخ
//   - FAB لإنشاء سند جديد (صرف أو قبض)
//   - التنقل لشاشة التعديل عند الضغط
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/pdf_print_helper.dart';
import '../../../domain/models/treasury_model.dart';
import '../../../domain/models/voucher_model.dart';
import '../../providers/treasury_providers.dart';
import '../../providers/voucher_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// الشاشة الرئيسية
// ═══════════════════════════════════════════════════════════════════════════

/// شاشة السندات مع تبويب صرف / قبض وبحث
class VouchersListScreen extends ConsumerStatefulWidget {
  const VouchersListScreen({super.key});

  @override
  ConsumerState<VouchersListScreen> createState() =>
      _VouchersListScreenState();
}

class _VouchersListScreenState extends ConsumerState<VouchersListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(
      () => setState(() => _query = _searchCtrl.text),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── إضافة سند جديد ───────────────────────────────────────────────────────

  void _showAddSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'نوع السند الجديد',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // سند صرف
                Expanded(
                  child: _AddVoucherTile(
                    icon: Icons.arrow_upward_rounded,
                    label: 'سند صرف',
                    subtitle: 'صرف من الخزينة',
                    color: theme.colorScheme.error,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go('/vouchers/sarf');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // سند قبض
                Expanded(
                  child: _AddVoucherTile(
                    icon: Icons.arrow_downward_rounded,
                    label: 'سند قبض',
                    subtitle: 'إيداع في الخزينة',
                    color: Colors.green.shade600,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go('/vouchers/kabd');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final treasuriesAsync = ref.watch(allTreasuriesProvider);

    // خريطة معرّف الخزينة → الاسم (للعرض في البطاقات)
    final treasuryMap = treasuriesAsync.whenData(
      (list) => {for (final t in list) t.id: t},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('السندات'),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // شريط البحث
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SearchBar(
                  controller: _searchCtrl,
                  hintText: 'بحث في الاسم، السبب، الرقم المرجعي...',
                  leading: const Icon(Icons.search, size: 20),
                  trailing: _query.isNotEmpty
                      ? [
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                        ]
                      : null,
                  elevation: const WidgetStatePropertyAll(0),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                  ),
                ),
              ),
              // التبويبات
              TabBar(
                controller: _tabCtrl,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.arrow_upward, size: 18),
                    text: 'سند صرف',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                  Tab(
                    icon: Icon(Icons.arrow_downward, size: 18),
                    text: 'سند قبض',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                ],
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── تبويب سندات الصرف ────────────────────────────────────────────
          _VoucherTab(
            type: 'sarf',
            query: _query,
            treasuryMap: treasuryMap,
            emptyIcon: Icons.arrow_upward_rounded,
            emptyMessage: 'لا توجد سندات صرف بعد',
            emptyHint: 'اضغط + لإضافة سند صرف جديد',
            onTapVoucher: (v) => context.go('/vouchers/sarf/${v.id}'),
          ),
          // ── تبويب سندات القبض ────────────────────────────────────────────
          _VoucherTab(
            type: 'kabd',
            query: _query,
            treasuryMap: treasuryMap,
            emptyIcon: Icons.arrow_downward_rounded,
            emptyMessage: 'لا توجد سندات قبض بعد',
            emptyHint: 'اضغط + لإضافة سند قبض جديد',
            onTapVoucher: (v) => context.go('/vouchers/kabd/${v.id}'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('سند جديد'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// تبويب قائمة السندات
// ═══════════════════════════════════════════════════════════════════════════

class _VoucherTab extends ConsumerWidget {
  final String type;
  final String query;
  final AsyncValue<Map<int, TreasuryModel>> treasuryMap;
  final IconData emptyIcon;
  final String emptyMessage;
  final String emptyHint;
  final void Function(VoucherModel) onTapVoucher;

  const _VoucherTab({
    required this.type,
    required this.query,
    required this.treasuryMap,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.emptyHint,
    required this.onTapVoucher,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // وضع البحث: Future بحث، وضع عادي: Stream
    if (query.isNotEmpty) {
      final searchAsync = ref.watch(searchVouchersProvider(query));
      return searchAsync.when(
        data: (all) {
          final filtered = all.where((v) {
            if (type == 'sarf') {
              return v.voucherType == 'sarf' || v.voucherType == 'transfer_out';
            } else if (type == 'kabd') {
              return v.voucherType == 'kabd' || v.voucherType == 'transfer_in';
            }
            return v.voucherType == type;
          }).toList();
          return _buildList(context, filtered);
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      );
    }

    final streamAsync = ref.watch(vouchersByTypeProvider(type));
    return streamAsync.when(
      data: (list) => _buildList(context, list),
      loading: () =>
          const Center(child: CircularProgressIndicator.adaptive()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
    );
  }

  Widget _buildList(BuildContext context, List<VoucherModel> list) {
    if (list.isEmpty) {
      return _EmptyState(
        icon: emptyIcon,
        message: emptyMessage,
        hint: emptyHint,
      );
    }
    final tMap = treasuryMap.valueOrNull ?? {};
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _VoucherCard(
        voucher: list[i],
        treasury: tMap[list[i].treasuryId],
        onTap: () => onTapVoucher(list[i]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// بطاقة السند
// ═══════════════════════════════════════════════════════════════════════════

class _VoucherCard extends StatelessWidget {
  final VoucherModel voucher;
  final TreasuryModel? treasury;
  final VoidCallback onTap;

  const _VoucherCard({
    required this.voucher,
    required this.treasury,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSarf = voucher.isSarf;
    final accent = isSarf ? theme.colorScheme.error : Colors.green.shade600;
    final fmtDate = DateFormat('dd/MM/yyyy', 'ar');
    final fmtNum = NumberFormat('#,##0.###', 'ar');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // شريط اللون الجانبي
              Container(width: 5, color: accent),
              // المحتوى
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // السطر الأول: رقم السند + التاريخ
                      Row(
                        children: [
                          // نوع السند
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              voucher.typeDisplayName,
                              style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '#${voucher.voucherNumber}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            fmtDate.format(voucher.voucherDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // السطر الثاني: المبلغ والخزينة
                      Row(
                        children: [
                          // المبلغ
                          Text(
                            '${fmtNum.format(voucher.amount)} ${voucher.currency == 'IQD' ? 'د.ع' : '\$'}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                          const Spacer(),
                          // اسم الخزينة
                          if (treasury != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 14,
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  treasury!.name,
                                  style:
                                      theme.textTheme.labelMedium?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      // السطر الثالث: اسم المستلم والسبب (إن وجد)
                      if (voucher.personName.isNotEmpty ||
                          voucher.reason.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (voucher.personName.isNotEmpty) ...[
                              Icon(
                                Icons.person_outline,
                                size: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                voucher.personName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (voucher.reason.isNotEmpty)
                              Expanded(
                                child: Text(
                                  voucher.reason,
                                  style:
                                      theme.textTheme.bodySmall?.copyWith(
                                    color: theme
                                        .colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                      // نوع البند (إن وجد)
                      if (voucher.itemType.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.label_outline,
                              size: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              voucher.itemType,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // زر الطباعة وسهم التفاصيل
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.print_outlined, size: 20),
                      tooltip: 'طباعة السند',
                      onPressed: () => PdfPrintHelper.printVoucherReceipt(context, voucher),
                    ),
                    Icon(
                      Icons.chevron_left,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// حالة الفراغ
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String hint;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// بلاطة إضافة سند
// ═══════════════════════════════════════════════════════════════════════════

class _AddVoucherTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AddVoucherTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: color,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
