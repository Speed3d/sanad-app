// ─────────────────────────────────────────────────────────────────────────────
// advance_review_screen.dart — مراجعة مسودة السلفة واعتمادها
//
// الشاشة الأهم في نظام السلف. هنا يفعل المالك ما كان مستحيلاً قبلها:
//   • يرى المُرسَل والمصروف والفرق قبل أن تتأثر الدفاتر
//   • يصحّح تصنيف كل مصروف (الفلتر) من قائمة موحّدة
//   • يستبعد الأسطر الخاطئة بلا محو أثرها
//   • يقرّر ما يفعل بالعجز إن وُجد
//
// كل تعديل يُعلَّم ويُقارَن بالقيمة الأصلية من الإكسل، فيبقى الفرق مرئياً.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../core/auth/permissions.dart';
import '../../../core/constants/app_routes.dart';
import '../../../domain/models/advance_model.dart';
import '../../providers/advance_providers.dart';
import '../../providers/auth_provider.dart';
import 'widgets/advance_summary_bar.dart';
import 'widgets/post_advance_dialog.dart';

/// شاشة مراجعة مسودة السلفة
class AdvanceReviewScreen extends ConsumerWidget {
  const AdvanceReviewScreen({super.key, required this.advanceId});

  final int advanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advanceAsync = ref.watch(advanceByIdProvider(advanceId));

    // رسائل العمليات
    ref.listen<AsyncValue<String?>>(advanceNotifierProvider, (_, next) {
      if (!context.mounted) return;
      if (next is AsyncData<String?> && next.value != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.value!),
            backgroundColor: Colors.green.shade700,
          ),
        );
        ref.read(advanceNotifierProvider.notifier).reset();
      } else if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 6),
          ),
        );
        ref.read(advanceNotifierProvider.notifier).reset();
      }
    });

    return advanceAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('السلفة')),
        body: Center(child: Text('خطأ: $e')),
      ),
      data: (advance) {
        if (advance == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('السلفة')),
            body: const Center(child: Text('السلفة غير موجودة.')),
          );
        }
        return _ReviewBody(advance: advance);
      },
    );
  }
}

// ── جسم الشاشة ───────────────────────────────────────────────────────────────

class _ReviewBody extends ConsumerWidget {
  const _ReviewBody({required this.advance});
  final AdvanceModel advance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linesAsync = ref.watch(advanceLinesProvider(advance.id));
    final summaryAsync = ref.watch(advanceSummaryProvider(advance.id));
    final user = ref.watch(authNotifierProvider.notifier).currentUser;
    final canPost = user?.can(AppPermission.postAdvance) ?? false;
    final canPostDeficit =
        user?.can(AppPermission.postAdvanceWithDeficit) ?? false;
    final canCancel = user?.can(AppPermission.cancelAdvance) ?? false;
    final isWorking = ref.watch(advanceNotifierProvider) is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text('سلفة ${advance.advanceNumber} — ${advance.projectName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.advances),
        ),
        actions: [
          if (canCancel && !advance.isCancelled)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'إلغاء السلفة',
              onPressed: isWorking
                  ? null
                  : () => _confirmCancel(context, ref, advance),
            ),
        ],
      ),
      body: Column(
        children: [
          summaryAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('خطأ في حساب الملخص: $e'),
            ),
            data: (s) => AdvanceSummaryBar(
              summary: s,
              isPosted: advance.isPosted,
            ),
          ),

          // شريط حالة للسلف غير القابلة للتحرير
          if (!advance.isEditable)
            _StateBanner(advance: advance),

          Expanded(
            child: linesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (lines) {
                if (lines.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'لا توجد مصاريف على هذه السلفة بعد.\n'
                        'استورد ملف Excel لتجهيز مسودة.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                  itemCount: lines.length,
                  itemBuilder: (_, i) => _LineCard(
                    line: lines[i],
                    advance: advance,
                    editable: advance.isEditable,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: (advance.isDraft && canPost)
          ? FloatingActionButton.extended(
              onPressed: isWorking
                  ? null
                  : () => _openPostDialog(context, ref, canPostDeficit),
              icon: isWorking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.fact_check_outlined),
              label: Text(isWorking ? 'جارٍ الاعتماد…' : 'اعتماد وتسديد'),
            )
          : null,
    );
  }

  // ── حوار الاعتماد ───────────────────────────────────────────────────────

  Future<void> _openPostDialog(
    BuildContext context,
    WidgetRef ref,
    bool canPostDeficit,
  ) async {
    final summary = await ref.read(advanceSummaryProvider(advance.id).future);
    if (!context.mounted) return;

    final decision = await showDialog<PostAdvanceDecision>(
      context: context,
      builder: (_) => PostAdvanceDialog(
        advance: advance,
        summary: summary,
        canPostWithDeficit: canPostDeficit,
      ),
    );

    if (decision == null || !context.mounted) return;

    // اختار تمويل النقص أولاً بدل الاعتماد بعجز
    if (decision.wantsTopUp) {
      context.go(AppRoutes.voucherTransfer);
      return;
    }
    if (!decision.confirmed) return;

    await ref.read(advanceNotifierProvider.notifier).postAdvance(
          advanceId: advance.id,
          allowDeficit: decision.allowDeficit,
          deficitCoveredBy: decision.deficitCoveredBy,
        );
  }

  // ── تأكيد الإلغاء ───────────────────────────────────────────────────────

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    AdvanceModel advance,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد إلغاء السلفة'),
        content: Text(
          advance.isPosted
              ? 'ستُعكَس كل سندات صرف السلفة رقم ${advance.advanceNumber} '
                  'ويرتدّ المبلغ إلى خزينة المشروع.\n\n'
                  'ملاحظة: سند التحويل الذي موّل السلفة لن يُمَسّ — المال '
                  'انتقل فعلاً إلى الخزينة وما زال فيها.'
              : 'ستُلغى السلفة رقم ${advance.advanceNumber} ومسودتها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، ألغِ السلفة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(advanceNotifierProvider.notifier).cancelAdvance(advance.id);
  }
}

// ── شريط حالة السلف غير القابلة للتحرير ─────────────────────────────────────

class _StateBanner extends StatelessWidget {
  const _StateBanner({required this.advance});
  final AdvanceModel advance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, text) = switch (advance.status) {
      AdvanceStatus.posted => (
          Colors.green,
          'هذه السلفة معتمدة — أسطرها صارت سندات صرف ولا يمكن تعديلها.'
        ),
      AdvanceStatus.cancelled => (
          Colors.grey,
          'هذه السلفة ملغاة.'
        ),
      _ => (
          Colors.blue,
          'هذه السلفة مفتوحة بانتظار وصول ملف مصاريفها.'
        ),
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

// ── بطاقة سطر ────────────────────────────────────────────────────────────────

class _LineCard extends ConsumerWidget {
  const _LineCard({
    required this.line,
    required this.advance,
    required this.editable,
  });

  final AdvanceLineModel line;
  final AdvanceModel advance;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0.##');
    final dateFmt = DateFormat('yyyy/MM/dd');

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: line.isExcluded
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : null,
      child: Opacity(
        opacity: line.isExcluded ? 0.55 : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      '${line.rowNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.reason.isEmpty ? '(بلا بيان)' : line.reason,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            decoration: line.isExcluded
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dateFmt.format(line.voucherDate)}'
                          '${line.spentBy != null ? ' · ${line.spentBy}' : ''}'
                          '${line.invoiceNumber != null ? ' · فاتورة ${line.invoiceNumber}' : ''}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${fmt.format(line.amount)} د.ع',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: line.isExcluded
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.error,
                        ),
                      ),
                      if (line.amountChanged)
                        Text(
                          'كان ${fmt.format(line.originalAmount)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade800,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // ── الفلتر: أهم عنصر قابل للتحرير في هذه الشاشة ──
                  Expanded(
                    child: _ItemTypeSelector(
                      line: line,
                      advanceId: advance.id,
                      editable: editable,
                    ),
                  ),
                  if (line.isEdited) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'عُدِّل عن ملف الإكسل — الأصل: '
                          '${line.originalItemType.isEmpty ? "(بلا بند)" : line.originalItemType}'
                          ' · ${fmt.format(line.originalAmount)} د.ع'
                          ' · ${dateFmt.format(line.originalDate)}',
                      child: Icon(Icons.edit_note,
                          size: 18, color: Colors.orange.shade800),
                    ),
                  ],
                  if (editable) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.tune, size: 18),
                      tooltip: 'تعديل السطر',
                      onPressed: () => _openEditSheet(context, ref),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        line.isExcluded
                            ? Icons.add_circle_outline
                            : Icons.remove_circle_outline,
                        size: 18,
                        color: line.isExcluded ? Colors.green : Colors.red,
                      ),
                      tooltip: line.isExcluded
                          ? 'إعادة السطر للاعتماد'
                          : 'استبعاد السطر',
                      onPressed: () => _toggleExclude(context, ref),
                    ),
                  ],
                ],
              ),
              if (line.isExcluded && line.excludeReason.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'سبب الاستبعاد: ${line.excludeReason}',
                    style: TextStyle(
                        fontSize: 11, color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleExclude(BuildContext context, WidgetRef ref) async {
    var reason = '';
    if (!line.isExcluded) {
      reason = await showDialog<String>(
            context: context,
            builder: (ctx) => _ExcludeReasonDialog(),
          ) ??
          '__cancelled__';
      if (reason == '__cancelled__') return;
    }
    await ref.read(advanceNotifierProvider.notifier).setLineExcluded(
          advanceId: advance.id,
          lineId: line.id,
          excluded: !line.isExcluded,
          reason: reason,
        );
  }

  Future<void> _openEditSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditLineSheet(line: line, advanceId: advance.id),
    );
  }
}

// ── محدّد الفلتر (قائمة البنود الموحّدة) ─────────────────────────────────────

class _ItemTypeSelector extends ConsumerWidget {
  const _ItemTypeSelector({
    required this.line,
    required this.advanceId,
    required this.editable,
  });

  final AdvanceLineModel line;
  final int advanceId;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final namesAsync = ref.watch(itemTypeNamesProvider('sarf'));

    if (!editable) {
      return _StaticChip(
        label: line.itemType.isEmpty ? 'بلا بند' : line.itemType,
        highlight: line.itemType.isNotEmpty,
      );
    }

    return namesAsync.when(
      loading: () => const SizedBox(height: 32),
      error: (_, __) => _StaticChip(
        label: line.itemType.isEmpty ? 'بلا بند' : line.itemType,
        highlight: line.itemType.isNotEmpty,
      ),
      data: (names) {
        // قيمة السطر قد تكون نصاً حراً من الإكسل غير موجود في القائمة —
        // نضيفه مؤقتاً حتى لا يختفي أمام المستخدم فيظن أن البيانات ضاعت.
        final options = <String>[
          '',
          ...names,
          if (line.itemType.isNotEmpty && !names.contains(line.itemType))
            line.itemType,
        ];

        return DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: line.itemType,
            isDense: true,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            style: theme.textTheme.bodySmall,
            items: options
                .map(
                  (n) => DropdownMenuItem(
                    value: n,
                    child: Text(
                      n.isEmpty ? '— اختر البند —' : n,
                      style: TextStyle(
                        fontSize: 12,
                        color: n.isEmpty
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              ref.read(advanceNotifierProvider.notifier).updateLine(
                    advanceId: advanceId,
                    lineId: line.id,
                    itemType: v,
                  );
            },
          ),
        );
      },
    );
  }
}

class _StaticChip extends StatelessWidget {
  const _StaticChip({required this.label, required this.highlight});
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: highlight
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: highlight
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── حوار سبب الاستبعاد ───────────────────────────────────────────────────────

class _ExcludeReasonDialog extends StatefulWidget {
  @override
  State<_ExcludeReasonDialog> createState() => _ExcludeReasonDialogState();
}

class _ExcludeReasonDialogState extends State<_ExcludeReasonDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('استبعاد السطر'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'السطر لن يُحذف — سيبقى مرئياً في المسودة لكنه يخرج من الإجمالي '
            'ولن يتحوّل إلى سند.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'سبب الاستبعاد (اختياري)',
              hintText: 'مثال: مصروف مكرر',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, '__cancelled__'),
          child: const Text('تراجع'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: const Text('استبعاد'),
        ),
      ],
    );
  }
}

// ── ورقة تعديل السطر ─────────────────────────────────────────────────────────

class _EditLineSheet extends ConsumerStatefulWidget {
  const _EditLineSheet({required this.line, required this.advanceId});
  final AdvanceLineModel line;
  final int advanceId;

  @override
  ConsumerState<_EditLineSheet> createState() => _EditLineSheetState();
}

class _EditLineSheetState extends ConsumerState<_EditLineSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _reasonCtrl;
  late final TextEditingController _personCtrl;
  late final TextEditingController _projectCtrl;
  late final TextEditingController _invoiceCtrl;
  late final TextEditingController _spentByCtrl;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final l = widget.line;
    _amountCtrl = TextEditingController(
      text: l.amount == l.amount.truncateToDouble()
          ? l.amount.toInt().toString()
          : l.amount.toString(),
    );
    _reasonCtrl = TextEditingController(text: l.reason);
    _personCtrl = TextEditingController(text: l.personName);
    _projectCtrl = TextEditingController(text: l.projectName ?? '');
    _invoiceCtrl = TextEditingController(text: l.invoiceNumber ?? '');
    _spentByCtrl = TextEditingController(text: l.spentBy ?? '');
    _date = l.voucherDate;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _personCtrl.dispose();
    _projectCtrl.dispose();
    _invoiceCtrl.dispose();
    _spentByCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(
      _amountCtrl.text.replaceAll(',', '').trim(),
    );
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المبلغ يجب أن يكون رقماً موجباً')),
      );
      return;
    }

    final ok = await ref.read(advanceNotifierProvider.notifier).updateLine(
          advanceId: widget.advanceId,
          lineId: widget.line.id,
          date: _date,
          amount: amount,
          reason: _reasonCtrl.text.trim(),
          personName: _personCtrl.text.trim(),
          projectName: _projectCtrl.text.trim(),
          invoiceNumber: _invoiceCtrl.text.trim(),
          spentBy: _spentByCtrl.text.trim(),
        );

    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0.##');
    final dateFmt = DateFormat('yyyy/MM/dd');
    final l = widget.line;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تعديل السطر ${l.rowNumber}',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'الأصل من الإكسل: ${fmt.format(l.originalAmount)} د.ع · '
              '${dateFmt.format(l.originalDate)}'
              '${l.originalItemType.isNotEmpty ? " · ${l.originalItemType}" : ""}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'المبلغ (د.ع)',
                prefixIcon: Icon(Icons.payments_outlined),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'التاريخ',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: Text(dateFmt.format(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'السبب / البيان',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _spentByCtrl,
              decoration: const InputDecoration(
                labelText: 'صرف من قبل',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _invoiceCtrl,
              decoration: const InputDecoration(
                labelText: 'رقم الفاتورة',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _projectCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم المشروع',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _personCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم الشخص',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('حفظ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
