// ─────────────────────────────────────────────────────────────────────────────
// advances_list_screen.dart — قائمة سلف المشاريع
//
// ⚠️ سلف المشاريع ≠ سلف الموظفين (تلك في شاشة الموظفين)
//
// أربعة تبويبات تعكس دورة حياة السلفة:
//   مفتوحة  — أُرسل المبلغ ولم تصل مصاريفه بعد
//   مسودات  — وصلت المصاريف وتنتظر المراجعة والاعتماد
//   معتمدة  — تحوّلت إلى سندات صرف
//   ملغاة   — عُكِست
//
// بطاقة كل سلفة تعرض المُرسَل والمصروف والفرق، فيرى المالك حالة كل مشروع
// من القائمة دون فتحها.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../core/constants/app_routes.dart';
import '../../../domain/models/advance_model.dart';
import '../../providers/advance_providers.dart';

/// شاشة قائمة سلف المشاريع
class AdvancesListScreen extends ConsumerStatefulWidget {
  const AdvancesListScreen({super.key});

  @override
  ConsumerState<AdvancesListScreen> createState() => _AdvancesListScreenState();
}

class _AdvancesListScreenState extends ConsumerState<AdvancesListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  static const _tabs = [
    (status: AdvanceStatus.draft, label: 'مسودات', icon: Icons.edit_note),
    (status: AdvanceStatus.open, label: 'مفتوحة', icon: Icons.outbox_outlined),
    (
      status: AdvanceStatus.posted,
      label: 'معتمدة',
      icon: Icons.check_circle_outline
    ),
    (
      status: AdvanceStatus.cancelled,
      label: 'ملغاة',
      icon: Icons.cancel_outlined
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سلف المشاريع'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: [
            for (final t in _tabs)
              Tab(icon: Icon(t.icon), text: t.label),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'استيراد مصاريف من Excel',
            onPressed: () => context.go(AppRoutes.excelImport),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          for (final t in _tabs) _AdvancesTab(status: t.status),
        ],
      ),
    );
  }
}

// ── تبويب واحد ───────────────────────────────────────────────────────────────

class _AdvancesTab extends ConsumerWidget {
  const _AdvancesTab({required this.status});
  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(advancesByStatusProvider(status));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (list) {
        if (list.isEmpty) return _EmptyState(status: status);
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) => _AdvanceCard(advance: list[i]),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.status});
  final String status;

  String get _message {
    switch (status) {
      case AdvanceStatus.draft:
        return 'لا توجد مسودات بانتظار المراجعة.\n'
            'استورد ملف مصاريف من Excel لتبدأ.';
      case AdvanceStatus.open:
        return 'لا توجد سلف مفتوحة.\n'
            'حوّل مبلغاً إلى خزينة مشروع مع رقم سلفة لإنشاء واحدة.';
      case AdvanceStatus.posted:
        return 'لا توجد سلف معتمدة بعد.';
      default:
        return 'لا توجد سلف ملغاة.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── بطاقة سلفة ───────────────────────────────────────────────────────────────

class _AdvanceCard extends ConsumerWidget {
  const _AdvanceCard({required this.advance});
  final AdvanceModel advance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0');
    final dateFmt = DateFormat('yyyy/MM/dd');
    final summaryAsync = ref.watch(advanceSummaryProvider(advance.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('${AppRoutes.advances}/${advance.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusChip(status: advance.status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سلفة ${advance.advanceNumber} — ${advance.projectName}',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    dateFmt.format(advance.advanceDate),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              summaryAsync.when(
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (e, _) => Text('خطأ: $e',
                    style: const TextStyle(fontSize: 11, color: Colors.red)),
                data: (s) => Row(
                  children: [
                    _Metric(
                      label: 'المُرسَل',
                      value: '${fmt.format(s.sent)} د.ع',
                      color: theme.colorScheme.primary,
                    ),
                    _Metric(
                      label: 'المصروف',
                      value: '${fmt.format(s.spent)} د.ع',
                      color: theme.colorScheme.error,
                    ),
                    _Metric(
                      label: s.remaining < 0 ? 'تجاوز' : 'المتبقي',
                      value: '${fmt.format(s.remaining.abs())} د.ع',
                      color: s.remaining < 0
                          ? Colors.orange.shade800
                          : Colors.green.shade700,
                      bold: true,
                    ),
                  ],
                ),
              ),
              // العجز أهم من أن يُترَك رقماً في صف — يُبرز باسم صاحبه
              if (advance.hasDeficit) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 14, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'عجز ${fmt.format(advance.deficitAmount)} د.ع '
                          'مستحق لـ ${advance.deficitCoveredBy}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة حالة السلفة
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  ({Color color, IconData icon, String label}) get _style {
    switch (status) {
      case AdvanceStatus.open:
        return (
          color: Colors.blue,
          icon: Icons.outbox_outlined,
          label: 'مفتوحة'
        );
      case AdvanceStatus.draft:
        return (
          color: Colors.amber.shade800,
          icon: Icons.edit_note,
          label: 'مسودة'
        );
      case AdvanceStatus.posted:
        return (
          color: Colors.green,
          icon: Icons.check_circle_outline,
          label: 'معتمدة'
        );
      default:
        return (
          color: Colors.grey,
          icon: Icons.cancel_outlined,
          label: 'ملغاة'
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 12, color: s.color),
          const SizedBox(width: 4),
          Text(
            s.label,
            style: TextStyle(
              fontSize: 11,
              color: s.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
