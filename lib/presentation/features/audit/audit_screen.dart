// ─────────────────────────────────────────────────────────────────────────────
// audit_screen.dart — شاشة سجل المراجعة
//
// الميزات:
//   - قائمة تفاعلية لآخر 100 حدث (Stream)
//   - بحث نصي في اسم المستخدم والجدول والعملية
//   - فلترة حسب نوع العملية (INSERT/UPDATE/DELETE/LOGIN/...)
//   - تلوين شارات العمليات (أخضر INSERT، أزرق UPDATE، أحمر DELETE)
//   - ورقة تفاصيل تعرض metaJson وwقت العملية والمستخدم والجدول
//   - تنظيف السجلات القديمة (أكثر من سنة)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../data/database/app_database.dart';
import '../../providers/audit_providers.dart';
import '../../providers/database_provider.dart';

// ── ثوابت ألوان العمليات ─────────────────────────────────────────────────────

Color _actionColor(String action) {
  switch (action.toUpperCase()) {
    case 'INSERT':
      return Colors.green.shade700;
    case 'UPDATE':
      return Colors.blue.shade700;
    case 'DELETE':
      return Colors.red.shade700;
    case 'LOGIN':
      return Colors.teal.shade700;
    case 'LOGOUT':
      return Colors.grey.shade600;
    case 'FISCAL_CLOSE':
      return Colors.orange.shade700;
    default:
      return Colors.purple.shade600;
  }
}

IconData _actionIcon(String action) {
  switch (action.toUpperCase()) {
    case 'INSERT':
      return Icons.add_circle_outline;
    case 'UPDATE':
      return Icons.edit_outlined;
    case 'DELETE':
      return Icons.delete_outline;
    case 'LOGIN':
      return Icons.login_outlined;
    case 'LOGOUT':
      return Icons.logout_outlined;
    case 'FISCAL_CLOSE':
      return Icons.lock_outline;
    default:
      return Icons.info_outline;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// AuditScreen — الشاشة الرئيسية
// ════════════════════════════════════════════════════════════════════════════

class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  final _searchCtrl = SearchController();
  String _query = '';
  String? _actionFilter; // null = الكل

  static const _actionTypes = [
    'INSERT',
    'UPDATE',
    'DELETE',
    'LOGIN',
    'LOGOUT',
    'FISCAL_CLOSE',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المراجعة'),
        actions: [
          // زر تنظيف السجلات القديمة
          IconButton(
            icon: const Icon(Icons.auto_delete_outlined),
            tooltip: 'أرشفة السجلات القديمة',
            onPressed: () => _showArchiveDialog(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                // ── شريط البحث ──────────────────────────────────
                SearchBar(
                  controller: _searchCtrl,
                  hintText: 'بحث بالمستخدم أو الجدول أو العملية…',
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
                // ── فلاتر نوع العملية ──────────────────────────
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('الكل'),
                          selected: _actionFilter == null,
                          onSelected: (_) =>
                              setState(() => _actionFilter = null),
                        ),
                        ...List.generate(_actionTypes.length, (i) {
                          final a = _actionTypes[i];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(a),
                              avatar: Icon(_actionIcon(a), size: 14),
                              selected: _actionFilter == a,
                              selectedColor:
                                  _actionColor(a).withValues(alpha: 0.15),
                              onSelected: (_) => setState(
                                () => _actionFilter =
                                    _actionFilter == a ? null : a,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _AuditLogList(
        query: _query,
        actionFilter: _actionFilter,
      ),
    );
  }

  void _showArchiveDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _ArchiveDialog(
        onConfirm: () async {
          final db = ref.read(appDatabaseProvider);
          final cutoff = DateTime.now().subtract(const Duration(days: 365));
          final deleted = await db.auditLogDao.deleteLogsBeforeDate(cutoff);
          ref.invalidate(recentAuditLogsProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم أرشفة $deleted سجل قديم'),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _AuditLogList — قائمة السجلات
// ════════════════════════════════════════════════════════════════════════════

class _AuditLogList extends ConsumerWidget {
  const _AuditLogList({required this.query, this.actionFilter});
  final String query;
  final String? actionFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(recentAuditLogsProvider);

    return stream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (logs) {
        // تطبيق الفلاتر المحلية
        final filtered = logs.where((log) {
          final matchAction =
              actionFilter == null || log.action.toUpperCase() == actionFilter;
          final matchQuery = query.isEmpty ||
              log.username.toLowerCase().contains(query.toLowerCase()) ||
              log.affectedTable.toLowerCase().contains(query.toLowerCase()) ||
              log.action.toLowerCase().contains(query.toLowerCase());
          return matchAction && matchQuery;
        }).toList();

        if (filtered.isEmpty) {
          return const _EmptyState();
        }

        return Column(
          children: [
            // شريط معلومات العدد
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${filtered.length} سجل',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) =>
                    _AuditLogCard(log: filtered[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _AuditLogCard — بطاقة سجل مراجعة
// ════════════════════════════════════════════════════════════════════════════

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({required this.log});
  final AuditLogData log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _actionColor(log.action);
    final icon = _actionIcon(log.action);
    final dateFmt = DateFormat('yyyy/MM/dd HH:mm:ss');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, size: 16, color: color),
      ),
      title: Row(
        children: [
          // شارة نوع العملية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              log.action,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // اسم الجدول
          Expanded(
            child: Text(
              log.affectedTable,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (log.recordId != null)
            Text(
              '#${log.recordId}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Icon(
            Icons.person_outline,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Text(
            log.username,
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.access_time,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Text(
            dateFmt.format(log.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      onTap: () => _showDetails(context, log),
    );
  }

  void _showDetails(BuildContext context, AuditLogData log) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AuditDetailSheet(log: log),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _AuditDetailSheet — ورقة تفاصيل سجل المراجعة
// ════════════════════════════════════════════════════════════════════════════

class _AuditDetailSheet extends StatelessWidget {
  const _AuditDetailSheet({required this.log});
  final AuditLogData log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _actionColor(log.action);
    final dateFmt = DateFormat('yyyy/MM/dd HH:mm:ss');

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) => Column(
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
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(_actionIcon(log.action), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${log.action} — ${log.affectedTable}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dateFmt.format(log.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          // التفاصيل
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _DetailRow(label: 'المستخدم', value: log.username),
                if (log.userId != null)
                  _DetailRow(label: 'معرّف المستخدم', value: '${log.userId}'),
                _DetailRow(label: 'الجدول', value: log.affectedTable),
                if (log.recordId != null)
                  _DetailRow(label: 'معرّف السجل', value: '#${log.recordId}'),
                _DetailRow(label: 'نوع العملية', value: log.action),
                if (log.ipAddress.isNotEmpty && log.ipAddress != '0.0.0.0')
                  _DetailRow(label: 'عنوان IP', value: log.ipAddress),
                if (log.metaJson.isNotEmpty && log.metaJson != '{}') ...[
                  const SizedBox(height: 8),
                  Text('معلومات إضافية', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.metaJson,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
                if (log.diffGzip != null) ...[
                  const SizedBox(height: 8),
                  Text('diff مضغوط', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${log.diffGzip!.length} بايت (gzip)',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _ArchiveDialog — تأكيد أرشفة السجلات القديمة
// ════════════════════════════════════════════════════════════════════════════

class _ArchiveDialog extends StatelessWidget {
  const _ArchiveDialog({required this.onConfirm});
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('أرشفة السجلات القديمة'),
      content: const Text(
        'سيتم حذف جميع السجلات الأقدم من 365 يوماً.\n'
        'هذه العملية لا يمكن التراجع عنها. هل تريد المتابعة؟',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('تأكيد الأرشفة'),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets مساعدة
// ════════════════════════════════════════════════════════════════════════════

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_outlined,
            size: 72,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد سجلات مراجعة',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
