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
                  treasuryMap: treasuryMap,
                  onTapVoucher: (v) => _navigateToVoucherDetail(v),
                ),
                _VoucherTab(
                  typeFilter: 'kabd',
                  query: _query,
                  treasuryId: _selectedTreasuryId,
                  itemType: _itemTypeFilter,
                  project: _projectFilter,
                  treasuryMap: treasuryMap,
                  onTapVoucher: (v) => _navigateToVoucherDetail(v),
                ),
                _VoucherTab(
                  typeFilter: 'sarf',
                  query: _query,
                  treasuryId: _selectedTreasuryId,
                  itemType: _itemTypeFilter,
                  project: _projectFilter,
                  treasuryMap: treasuryMap,
                  onTapVoucher: (v) => _navigateToVoucherDetail(v),
                ),
                _VoucherTab(
                  typeFilter: 'transfer',
                  query: _query,
                  treasuryId: _selectedTreasuryId,
                  itemType: _itemTypeFilter,
                  project: _projectFilter,
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

// ── تبويب قائمة السندات ──────────────────────────────────────────────────────

class _VoucherTab extends ConsumerWidget {
  final String? typeFilter;
  final String query;
  final int? treasuryId;

  /// فلترة بنوع البند — null = الكل
  final String? itemType;

  /// فلترة باسم المشروع — null = الكل
  final String? project;

  final AsyncValue<Map<int, TreasuryModel>> treasuryMap;
  final void Function(VoucherModel) onTapVoucher;

  const _VoucherTab({
    required this.typeFilter,
    required this.query,
    required this.treasuryId,
    required this.itemType,
    required this.project,
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
    ];
    if (active.isEmpty) return 'لا توجد سندات بعد';
    return 'لا توجد سندات مطابقة لـ ${active.join(' و')}';
  }

  Widget _renderList(
      BuildContext context, List<VoucherModel> list, bool isDark) {
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
    final fmtNum = NumberFormat('#,##0.##');

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
    final fmt = NumberFormat('#,##0.##');
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
