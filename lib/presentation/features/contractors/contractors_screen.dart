// ─────────────────────────────────────────────────────────────────────────────
// contractors_screen.dart — شاشة المقاولين
//
// الميزات:
//   - قائمة تفاعلية لجميع المقاولين مع بحث فوري
//   - فلترة حسب النوع (الكل / فرد / شركة)
//   - بطاقة مقاول بلون مميز حسب النوع وشارة الحالة
//   - ورقة تفاصيل (DraggableScrollableSheet) بـ PopupMenu للإجراءات
//   - حوار إضافة / تعديل مقاول
//   - تغذية راجعة بـ SnackBar عبر ref.listen
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/contractor_model.dart';
import '../../providers/contractor_providers.dart';

// ════════════════════════════════════════════════════════════════════════════
// ContractorsScreen — الشاشة الرئيسية
// ════════════════════════════════════════════════════════════════════════════

class ContractorsScreen extends ConsumerStatefulWidget {
  const ContractorsScreen({super.key});

  @override
  ConsumerState<ContractorsScreen> createState() => _ContractorsScreenState();
}

class _ContractorsScreenState extends ConsumerState<ContractorsScreen> {
  final _searchCtrl = SearchController();
  String _query = '';
  // null = الكل | 'individual' = فرد | 'company' = شركة
  String? _typeFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── تغذية راجعة ─────────────────────────────────────────────────────────
    ref.listen<AsyncValue<String?>>(contractorNotifierProvider, (_, next) {
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
        title: const Text('المقاولون'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                // ── شريط البحث ──────────────────────────────────────────
                SearchBar(
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
                const SizedBox(height: 8),
                // ── فلاتر النوع ────────────────────────────────────────
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _TypeChip(
                          label: 'الكل',
                          icon: Icons.people_outline,
                          selected: _typeFilter == null,
                          onTap: () => setState(() => _typeFilter = null),
                        ),
                        const SizedBox(width: 8),
                        _TypeChip(
                          label: 'أفراد',
                          icon: Icons.person_outline,
                          selected: _typeFilter == 'individual',
                          onTap: () => setState(
                            () => _typeFilter = _typeFilter == 'individual'
                                ? null
                                : 'individual',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TypeChip(
                          label: 'شركات',
                          icon: Icons.business_outlined,
                          selected: _typeFilter == 'company',
                          onTap: () => setState(
                            () => _typeFilter =
                                _typeFilter == 'company' ? null : 'company',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _query.trim().isNotEmpty
          ? _SearchResults(query: _query, typeFilter: _typeFilter)
          : _ContractorsList(typeFilter: _typeFilter),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _ContractorFormDialog(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('مقاول جديد'),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _ContractorsList — قائمة تفاعلية
// ════════════════════════════════════════════════════════════════════════════

class _ContractorsList extends ConsumerWidget {
  const _ContractorsList({this.typeFilter});
  final String? typeFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(allContractorsProvider);
    return stream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (all) {
        final list = typeFilter == null
            ? all
            : all.where((c) => c.contractorType == typeFilter).toList();
        if (list.isEmpty) {
          return _EmptyState(
            icon: Icons.construction_outlined,
            message: typeFilter == null
                ? 'لا يوجد مقاولون مسجّلون بعد'
                : 'لا يوجد مقاولون من هذا النوع',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) => _ContractorCard(contractor: list[i]),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _SearchResults — نتائج البحث
// ════════════════════════════════════════════════════════════════════════════

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query, this.typeFilter});
  final String query;
  final String? typeFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.watch(searchContractorsProvider(query));
    return future.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (all) {
        final list = typeFilter == null
            ? all
            : all.where((c) => c.contractorType == typeFilter).toList();
        if (list.isEmpty) {
          return const _EmptyState(
            icon: Icons.search_off_outlined,
            message: 'لا توجد نتائج مطابقة',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) => _ContractorCard(contractor: list[i]),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _ContractorCard — بطاقة مقاول
// ════════════════════════════════════════════════════════════════════════════

class _ContractorCard extends StatelessWidget {
  const _ContractorCard({required this.contractor});
  final ContractorModel contractor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompany = contractor.isCompany;
    final typeColor = isCompany ? Colors.indigo : Colors.teal;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetailSheet(context, contractor),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // شريط لوني جانبي
              Container(width: 4, color: typeColor),
              const SizedBox(width: 12),
              // أيقونة دائرية
              CircleAvatar(
                radius: 22,
                backgroundColor: typeColor.withValues(alpha: 0.15),
                child: Icon(
                  isCompany ? Icons.business : Icons.person,
                  color: typeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // بيانات المقاول
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
                              contractor.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _SmallBadge(
                            label: contractor.typeDisplayName,
                            color: typeColor,
                          ),
                          if (!contractor.isActive) ...[
                            const SizedBox(width: 6),
                            const _SmallBadge(
                              label: 'موقوف',
                              color: Colors.grey,
                            ),
                          ],
                          const SizedBox(width: 8),
                        ],
                      ),
                      if (contractor.displayPhone.isNotEmpty) ...[
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
                              contractor.displayPhone,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (contractor.address.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                contractor.address,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
// _showDetailSheet + _ContractorDetailSheet
// ════════════════════════════════════════════════════════════════════════════

void _showDetailSheet(BuildContext context, ContractorModel contractor) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ContractorDetailSheet(contractor: contractor),
  );
}

class _ContractorDetailSheet extends ConsumerWidget {
  const _ContractorDetailSheet({required this.contractor});
  final ContractorModel contractor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompany = contractor.isCompany;
    final typeColor = isCompany ? Colors.indigo : Colors.teal;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
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
                  backgroundColor: typeColor.withValues(alpha: 0.15),
                  child: Text(
                    contractor.name.isNotEmpty
                        ? contractor.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contractor.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _SmallBadge(
                            label: contractor.typeDisplayName,
                            color: typeColor,
                          ),
                          const SizedBox(width: 6),
                          _SmallBadge(
                            label: contractor.isActive ? 'نشط' : 'موقوف',
                            color:
                                contractor.isActive ? Colors.green : Colors.grey,
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
                          contractor.isActive
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                        ),
                        title: Text(
                          contractor.isActive ? 'تعطيل' : 'تفعيل',
                        ),
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
          // تفاصيل المقاول
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                if (contractor.phone1.isNotEmpty)
                  _DetailRow(
                    icon: Icons.phone_outlined,
                    label: 'الهاتف الأول',
                    value: contractor.phone1,
                  ),
                if (contractor.phone2.isNotEmpty)
                  _DetailRow(
                    icon: Icons.phone_outlined,
                    label: 'الهاتف الثاني',
                    value: contractor.phone2,
                  ),
                if (contractor.address.isNotEmpty)
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'العنوان',
                    value: contractor.address,
                  ),
                if (contractor.notes.isNotEmpty)
                  _DetailRow(
                    icon: Icons.notes_outlined,
                    label: 'ملاحظات',
                    value: contractor.notes,
                  ),
                if (contractor.createdAt != null)
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'تاريخ التسجيل',
                    value:
                        '${contractor.createdAt!.day}/${contractor.createdAt!.month}/${contractor.createdAt!.year}',
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    Navigator.pop(context);
    switch (action) {
      case 'edit':
        showDialog<void>(
          context: context,
          builder: (_) => _ContractorFormDialog(existing: contractor),
        );
      case 'toggle':
        ref
            .read(contractorNotifierProvider.notifier)
            .toggleActive(contractor);
      case 'delete':
        showDialog<void>(
          context: context,
          builder: (_) => _ConfirmDeleteDialog(
            name: contractor.name,
            onConfirm: () => ref
                .read(contractorNotifierProvider.notifier)
                .deleteContractor(contractor.id),
          ),
        );
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _ContractorFormDialog — حوار إضافة / تعديل مقاول
// ════════════════════════════════════════════════════════════════════════════

class _ContractorFormDialog extends ConsumerStatefulWidget {
  const _ContractorFormDialog({this.existing});
  final ContractorModel? existing;

  @override
  ConsumerState<_ContractorFormDialog> createState() =>
      _ContractorFormDialogState();
}

class _ContractorFormDialogState
    extends ConsumerState<_ContractorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phone1Ctrl = TextEditingController();
  final _phone2Ctrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _contractorType = 'individual';
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _phone1Ctrl.text = e.phone1;
      _phone2Ctrl.text = e.phone2;
      _addressCtrl.text = e.address;
      _notesCtrl.text = e.notes;
      _contractorType = e.contractorType;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phone1Ctrl.dispose();
    _phone2Ctrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_isEdit ? 'تعديل مقاول' : 'مقاول جديد'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── نوع المقاول ─────────────────────────────────────────
                Text('نوع المقاول', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'individual',
                      label: Text('فرد'),
                      icon: Icon(Icons.person_outline),
                    ),
                    ButtonSegment(
                      value: 'company',
                      label: Text('شركة'),
                      icon: Icon(Icons.business_outlined),
                    ),
                  ],
                  selected: {_contractorType},
                  onSelectionChanged: (s) =>
                      setState(() => _contractorType = s.first),
                ),
                const SizedBox(height: 16),
                // ── الاسم ──────────────────────────────────────────────
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: _contractorType == 'company'
                        ? 'اسم الشركة *'
                        : 'اسم المقاول *',
                    prefixIcon: Icon(
                      _contractorType == 'company'
                          ? Icons.business
                          : Icons.person,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'حقل إلزامي' : null,
                ),
                const SizedBox(height: 12),
                // ── الهاتف الأول ────────────────────────────────────────
                TextFormField(
                  controller: _phone1Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'الهاتف الأول',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                // ── الهاتف الثاني ───────────────────────────────────────
                TextFormField(
                  controller: _phone2Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'الهاتف الثاني',
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

    final notifier = ref.read(contractorNotifierProvider.notifier);
    final bool ok;

    if (_isEdit) {
      ok = await notifier.updateContractor(
        widget.existing!,
        name: _nameCtrl.text,
        phone1: _phone1Ctrl.text,
        phone2: _phone2Ctrl.text,
        address: _addressCtrl.text,
        contractorType: _contractorType,
        notes: _notesCtrl.text,
      );
    } else {
      ok = await notifier.createContractor(
        name: _nameCtrl.text,
        phone1: _phone1Ctrl.text,
        phone2: _phone2Ctrl.text,
        address: _addressCtrl.text,
        contractorType: _contractorType,
        notes: _notesCtrl.text,
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
  const _ConfirmDeleteDialog({required this.name, required this.onConfirm});
  final String name;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تأكيد الحذف'),
      content: Text(
        'هل تريد حذف المقاول "$name"؟\nلن يُحذف سجل المعاملات السابقة.',
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
    );
  }
}

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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 72,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
