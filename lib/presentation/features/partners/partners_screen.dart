// ─────────────────────────────────────────────────────────────────────────────
// partners_screen.dart — شاشة الشركاء
//
// الميزات:
//   - شريط ملخص يُظهر مجموع الحصص المُخصَّصة من 100%
//   - قائمة تفاعلية لجميع الشركاء مع بحث فوري
//   - بطاقة شريك بشريط تقدم يُمثّل نسبة حصته
//   - ورقة تفاصيل (DraggableScrollableSheet) بـ PopupMenu للإجراءات
//   - حوار إضافة / تعديل مع التحقق من مجموع الحصص (≤ 100%)
//   - تغذية راجعة بـ SnackBar عبر ref.listen
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/partner_model.dart';
import '../../providers/partner_providers.dart';
import '../../widgets/common/treasury_link_picker.dart';
import '../../widgets/common/app_components.dart';

// ════════════════════════════════════════════════════════════════════════════
// PartnersScreen — الشاشة الرئيسية
// ════════════════════════════════════════════════════════════════════════════

class PartnersScreen extends ConsumerStatefulWidget {
  const PartnersScreen({super.key});

  @override
  ConsumerState<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends ConsumerState<PartnersScreen> {
  final _searchCtrl = SearchController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── تغذية راجعة ─────────────────────────────────────────────────────────
    ref.listen<AsyncValue<String?>>(partnerNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (msg) {
          if (msg != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('الشركاء'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'بحث بالاسم أو الهاتف…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── شريط ملخص الحصص ──────────────────────────────────────────────
          const _ShareSummaryBanner(),
          // ── القائمة / نتائج البحث ────────────────────────────────────────
          Expanded(
            child: _query.trim().isNotEmpty
                ? _SearchResults(query: _query)
                : const _PartnersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _PartnerFormDialog(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('شريك جديد'),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _ShareSummaryBanner — شريط ملخص مجموع الحصص
// ════════════════════════════════════════════════════════════════════════════

class _ShareSummaryBanner extends ConsumerWidget {
  const _ShareSummaryBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totalAsync = ref.watch(totalSharePercentageProvider);

    return totalAsync.when(
      loading: () => const SizedBox(height: 4, child: LinearProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (total) {
        final remaining = (100 - total).clamp(0.0, 100.0);
        final progress = (total / 100).clamp(0.0, 1.0);
        final isOverAllocated = total > 100.001;
        final barColor = isOverAllocated
            ? Colors.red
            : total >= 90
                ? Colors.orange
                : Colors.green.shade600;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'توزيع حصص الشركاء',
                    style: theme.textTheme.labelLarge,
                  ),
                  Row(
                    children: [
                      Text(
                        'مُخصَّص: ${total.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: barColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'متبقي: ${remaining.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: barColor,
                  backgroundColor:
                      theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _PartnersList — قائمة تفاعلية
// ════════════════════════════════════════════════════════════════════════════

class _PartnersList extends ConsumerWidget {
  const _PartnersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(allPartnersProvider);
    return stream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (list) {
        if (list.isEmpty) {
          return const AppEmptyState(
            icon: Icons.handshake_outlined,
            message: 'لا يوجد شركاء مسجّلون بعد',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) => _PartnerCard(partner: list[i]),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _SearchResults — نتائج البحث
// ════════════════════════════════════════════════════════════════════════════

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.watch(searchPartnersProvider(query));
    return future.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (list) {
        if (list.isEmpty) {
          return const AppEmptyState(
            icon: Icons.search_off_outlined,
            message: 'لا توجد نتائج مطابقة',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) => _PartnerCard(partner: list[i]),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _PartnerCard — بطاقة شريك
// ════════════════════════════════════════════════════════════════════════════

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.partner});
  final PartnerModel partner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const cardColor = Colors.deepPurple;
    final shareProgress = (partner.sharePercentage / 100).clamp(0.0, 1.0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetailSheet(context, partner),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // شريط لوني جانبي
              Container(width: 4, color: cardColor),
              const SizedBox(width: 12),
              // أيقونة دائرية
              CircleAvatar(
                radius: 22,
                backgroundColor: cardColor.withValues(alpha: 0.12),
                child: Text(
                  partner.name.isNotEmpty
                      ? partner.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // بيانات الشريك
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              partner.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // نسبة الحصة
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              partner.shareDisplayText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: cardColor,
                              ),
                            ),
                          ),
                          if (!partner.isActive) ...[
                            const SizedBox(width: 6),
                            const _SmallBadge(
                              label: 'موقوف',
                              color: Colors.grey,
                            ),
                          ],
                          const SizedBox(width: 8),
                        ],
                      ),
                      // شريط تقدم الحصة
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: shareProgress,
                          minHeight: 5,
                          color: cardColor.withValues(alpha: 0.7),
                          backgroundColor:
                              cardColor.withValues(alpha: 0.1),
                        ),
                      ),
                      if (partner.phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              partner.phone,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _showDetailSheet + _PartnerDetailSheet
// ════════════════════════════════════════════════════════════════════════════

void _showDetailSheet(BuildContext context, PartnerModel partner) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PartnerDetailSheet(partner: partner),
  );
}

class _PartnerDetailSheet extends ConsumerWidget {
  const _PartnerDetailSheet({required this.partner});
  final PartnerModel partner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    const cardColor = Colors.deepPurple;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // مقبض السحب
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // رأس الورقة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cardColor.withValues(alpha: 0.12),
                  child: Text(
                    partner.name.isNotEmpty
                        ? partner.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: cardColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'حصة ${partner.shareDisplayText}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: cardColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _SmallBadge(
                            label: partner.isActive ? 'نشط' : 'موقوف',
                            color: partner.isActive ? Colors.green : Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) =>
                      _handleAction(context, ref, action),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('تعديل'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: ListTile(
                        leading: Icon(
                          partner.isActive
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                        ),
                        title: Text(partner.isActive ? 'تعطيل' : 'تفعيل'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        title: Text(
                          'حذف',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          // تفاصيل الشريك
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // شريط تقدم الحصة
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'نسبة الحصة',
                            style: theme.textTheme.labelMedium,
                          ),
                          Text(
                            partner.shareDisplayText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cardColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (partner.sharePercentage / 100).clamp(0.0, 1.0),
                          minHeight: 10,
                          color: cardColor.withValues(alpha: 0.7),
                          backgroundColor: cardColor.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
                if (partner.phone.isNotEmpty)
                  _DetailRow(
                    icon: Icons.phone_outlined,
                    label: 'الهاتف',
                    value: partner.phone,
                  ),
                if (partner.address.isNotEmpty)
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'العنوان',
                    value: partner.address,
                  ),
                if (partner.notes.isNotEmpty)
                  _DetailRow(
                    icon: Icons.notes_outlined,
                    label: 'ملاحظات',
                    value: partner.notes,
                  ),
                if (partner.createdAt != null)
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'تاريخ الانضمام',
                    value:
                        '${partner.createdAt!.day}/${partner.createdAt!.month}/${partner.createdAt!.year}',
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ⚠️ الالتقاط المسبق — الشرح الكامل في `contractors_screen.dart` (ع-٥٧).
  ///   `Navigator.pop` يتخلّص من ورقة التفاصيل المالكة لهذا الـ`ref`، فيصير
  ///   استعمالُه داخل حوارٍ يُفتح بعدها انهياراً مؤكّداً.
  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    final notifier = ref.read(partnerNotifierProvider.notifier);
    final navigator = Navigator.of(context);
    final rootContext = navigator.context;

    navigator.pop();

    switch (action) {
      case 'edit':
        showDialog<void>(
          context: rootContext,
          builder: (_) => _PartnerFormDialog(existing: partner),
        );
      case 'toggle':
        notifier.toggleActive(partner);
      case 'delete':
        showDialog<void>(
          context: rootContext,
          builder: (_) => _ConfirmDeleteDialog(
            name: partner.name,
            note: partner.treasuryId == null
                ? null
                : 'وستُحذف خزينته معه — فهما أُنشئا معاً.',
            onConfirm: () => notifier.deletePartner(partner.id),
          ),
        );
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _PartnerFormDialog — حوار إضافة / تعديل شريك
// ════════════════════════════════════════════════════════════════════════════

class _PartnerFormDialog extends ConsumerStatefulWidget {
  const _PartnerFormDialog({this.existing});
  final PartnerModel? existing;

  @override
  ConsumerState<_PartnerFormDialog> createState() => _PartnerFormDialogState();
}

class _PartnerFormDialogState extends ConsumerState<_PartnerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _shareCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  /// كيف تُربَط خزينته — الإنشاء التلقائي هو الافتراضي (قرار المالك)
  TreasuryLinkMode _treasuryMode = TreasuryLinkMode.create;
  int? _linkedTreasuryId;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _phoneCtrl.text = e.phone;
      _addressCtrl.text = e.address;
      _shareCtrl.text = e.sharePercentage == 0
          ? ''
          : e.sharePercentage.toStringAsFixed(
              e.sharePercentage == e.sharePercentage.roundToDouble() ? 0 : 1,
            );
      _notesCtrl.text = e.notes;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _shareCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // عرض الحد الأقصى المتاح للمستخدم أثناء الإدخال
    final totalAsync = ref.watch(totalSharePercentageProvider);
    final currentTotal = totalAsync.valueOrNull ?? 0.0;
    final myCurrentShare = widget.existing?.sharePercentage ?? 0.0;
    final maxAllowed = (100 - currentTotal + myCurrentShare).clamp(0.0, 100.0);

    return AlertDialog(
      title: Text(_isEdit ? 'تعديل شريك' : 'شريك جديد'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── الاسم ──────────────────────────────────────────────
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم الشريك *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  // إعادة البناء ليتبع اسمُ الخزينة المقترَح ما يُكتَب
                  onChanged: (_) => setState(() {}),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'حقل إلزامي' : null,
                ),
                const SizedBox(height: 12),
                // ── الهاتف ─────────────────────────────────────────────
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الهاتف',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                // ── العنوان ────────────────────────────────────────────
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // ── نسبة الحصة ─────────────────────────────────────────
                TextFormField(
                  controller: _shareCtrl,
                  decoration: InputDecoration(
                    labelText: 'نسبة الحصة % *',
                    prefixIcon: const Icon(Icons.pie_chart_outline),
                    border: const OutlineInputBorder(),
                    helperText:
                        'الحد الأقصى المتاح: ${maxAllowed.toStringAsFixed(1)}%',
                    suffixText: '%',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'حقل إلزامي';
                    final d = double.tryParse(v.trim());
                    if (d == null) return 'أدخل رقماً صحيحاً';
                    if (d < 0) return 'لا يمكن أن تكون سالبة';
                    if (d > 100) return 'لا يمكن أن تتجاوز 100%';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // ── ملاحظات ────────────────────────────────────────────
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // ── الخزينة (الإنشاء وحده) ────────────────────────────
                //
                // ⚠️ لا تظهر عند التعديل: تغيير خزينة شريكٍ له حركة مالية
                //   ينقل رصيداً بين حسابين بضغطة — مسارٌ يحتاج حارساً بنفسه.
                if (!_isEdit) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  TreasuryLinkPicker(
                    mode: _treasuryMode,
                    linkedTreasuryId: _linkedTreasuryId,
                    autoName: 'شريك: ${_nameCtrl.text.trim().isEmpty ?
                        '(اسم الشريك)' : _nameCtrl.text.trim()}',
                    onChanged: (m, id) => setState(() {
                      _treasuryMode = m;
                      _linkedTreasuryId = id;
                    }),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEdit ? 'حفظ التعديلات' : 'إضافة'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final share = double.tryParse(_shareCtrl.text.trim()) ?? 0.0;
    final notifier = ref.read(partnerNotifierProvider.notifier);
    final bool ok;

    if (_isEdit) {
      ok = await notifier.updatePartner(
        widget.existing!,
        name: _nameCtrl.text,
        phone: _phoneCtrl.text,
        address: _addressCtrl.text,
        sharePercentage: share,
        notes: _notesCtrl.text,
      );
    } else {
      ok = await notifier.createPartner(
        name: _nameCtrl.text,
        phone: _phoneCtrl.text,
        address: _addressCtrl.text,
        sharePercentage: share,
        notes: _notesCtrl.text,
        createTreasury: _treasuryMode == TreasuryLinkMode.create,
        existingTreasuryId:
            _treasuryMode == TreasuryLinkMode.link ? _linkedTreasuryId : null,
      );
    }

    if (mounted) {
      setState(() => _saving = false);
      if (ok) Navigator.pop(context);
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _ConfirmDeleteDialog — تأكيد الحذف
// ════════════════════════════════════════════════════════════════════════════

class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog({
    required this.name,
    required this.onConfirm,
    this.note,
  });
  final String name;
  final VoidCallback onConfirm;

  /// أثرٌ إضافي يجب أن يعرفه المالك قبل الضغط — كحذف الخزينة معه
  final String? note;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تأكيد الحذف'),
      content: Text(
        'هل تريد حذف الشريك "$name"؟\n'
        '${note == null ? '' : '$note\n'}'
        'ستُحفَظ سجلات المعاملات السابقة.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('حذف'),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets مساعدة
// ════════════════════════════════════════════════════════════════════════════

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// (أُزيل _EmptyState المحلي — يستخدم AppEmptyState المشترك الآن)
