import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat, DateFormat;

import '../../../core/auth/permissions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/voucher_providers.dart';

// ════════════════════════════════════════════════════════════════════════════
// TAB 4 — تقارير السلف والمشاريع
// ════════════════════════════════════════════════════════════════════════════

class AdvanceReportTab extends ConsumerStatefulWidget {
  const AdvanceReportTab({super.key});

  @override
  ConsumerState<AdvanceReportTab> createState() => _AdvanceReportTabState();
}

class _AdvanceReportTabState extends ConsumerState<AdvanceReportTab> {
  final _advanceNumCtrl = TextEditingController();
  final _projectCtrl = TextEditingController();
  final _invoiceCtrl = TextEditingController();

  // الفلاتر المطبقة
  ({String? advanceNumber, String? projectName, String? invoiceNumber})? _applied;

  @override
  void dispose() {
    _advanceNumCtrl.dispose();
    _projectCtrl.dispose();
    _invoiceCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _applied = (
        advanceNumber: _advanceNumCtrl.text.trim().isEmpty ? null : _advanceNumCtrl.text.trim(),
        projectName: _projectCtrl.text.trim().isEmpty ? null : _projectCtrl.text.trim(),
        invoiceNumber: _invoiceCtrl.text.trim().isEmpty ? null : _invoiceCtrl.text.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── لوحة الفلاتر ────────────────────────────────────────────
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('بحث السلف والمشاريع', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _advanceNumCtrl,
                        decoration: const InputDecoration(
                          labelText: 'رقم السلفة',
                          prefixIcon: Icon(Icons.tag),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _projectCtrl,
                        decoration: const InputDecoration(
                          labelText: 'المشروع',
                          prefixIcon: Icon(Icons.business_outlined),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _invoiceCtrl,
                        decoration: const InputDecoration(
                          labelText: 'رقم الفاتورة',
                          prefixIcon: Icon(Icons.receipt_outlined),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _applyFilters,
                    icon: const Icon(Icons.search),
                    label: const Text('بحث وعرض التفاصيل'),
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── النتائج ─────────────────────────────────────────────────
        Expanded(
          child: _applied == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.manage_search, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('أدخل معايير البحث (رقم السلفة أو المشروع) واضغط بحث'),
                    ],
                  ),
                )
              : _AdvanceReportResults(filters: _applied!),
        ),
      ],
    );
  }
}

class _AdvanceReportResults extends ConsumerWidget {
  const _AdvanceReportResults({required this.filters});
  final ({String? advanceNumber, String? projectName, String? invoiceNumber}) filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // إلغاء السلفة عملية مدمّرة (حذف + عكس أرصدة) → admin فأعلى
    final currentUser = ref.watch(authNotifierProvider.notifier).currentUser;
    final canCancel =
        currentUser != null && currentUser.can(AppPermission.cancelAdvance);
    final resultsAsync = ref.watch(
      advanceReportsProvider(
        advanceNumber: filters.advanceNumber,
        projectName: filters.projectName,
        invoiceNumber: filters.invoiceNumber,
      ),
    );

    final fmt = NumberFormat('#,##0.##');
    final dateFmt = DateFormat('yyyy/MM/dd');

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (vouchers) {
        if (vouchers.isEmpty) {
          return const Center(
            child: Text('لا توجد نتائج تطابق معايير البحث.'),
          );
        }

        // حساب إجمالي الصرف لهذه السلفة
        double totalSarf = 0;
        for (final v in vouchers) {
          if (v.voucherType == 'sarf') {
            totalSarf += v.currency == 'IQD' ? v.amount : v.amount * v.exchangeRate;
          }
        }

        return Column(
          children: [
            // ملخص
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إجمالي مصروفات البحث',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              '${fmt.format(totalSarf)} د.ع',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // زر التراجع عن السلفة إذا تم البحث برقم سلفة محدد فقط
                      // ويملك المستخدم صلاحية الإلغاء (admin فأعلى)
                      if (canCancel &&
                          filters.advanceNumber != null &&
                          filters.projectName == null &&
                          filters.invoiceNumber == null)
                        FilledButton.icon(
                          onPressed: () => _confirmDeleteAdvance(context, ref, filters.advanceNumber!),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          ),
                          icon: const Icon(Icons.undo),
                          label: const Text('إلغاء السلفة بالكامل'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // القائمة
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: vouchers.length,
                itemBuilder: (ctx, i) {
                  final v = vouchers[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ExpansionTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.receipt_long, size: 18),
                      ),
                      title: Text('سند رقم: ${v.voucherNumber} | الفاتورة: ${v.invoiceNumber ?? "-"}'),
                      subtitle: Text(
                        'المشروع: ${v.projectName ?? "-"} | التاريخ: ${dateFmt.format(v.voucherDate)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '${fmt.format(v.amount)} ${v.currency}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DetailRow('المستلم:', v.spentBy ?? '-'),
                              const SizedBox(height: 4),
                              _DetailRow('رقم السلفة:', v.advanceNumber ?? '-'),
                              const SizedBox(height: 4),
                              _DetailRow('التفاصيل/السبب:', v.reason),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteAdvance(BuildContext context, WidgetRef ref, String advanceNumber) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الإلغاء'),
        content: Text(
          'هل أنت متأكد من إلغاء وحذف كافة سندات السلفة رقم ($advanceNumber)؟\n\n'
          'سيتم التراجع عن المبالغ المصروفة وإعادتها للخزينة. لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، احذف السلفة'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (context.mounted) {
      final success = await ref.read(advanceDeleteNotifierProvider.notifier).deleteAdvance(advanceNumber);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء السلفة واسترداد المبالغ بنجاح.'), backgroundColor: Colors.green),
        );
      } else if (context.mounted) {
        final error = ref.read(advanceDeleteNotifierProvider).error?.toString() ?? 'حدث خطأ غير متوقع';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text(value)),
      ],
    );
  }
}
