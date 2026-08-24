// ─────────────────────────────────────────────────────────────────────────────
// attachments_panel.dart — لوحة المرفقات المشتركة (المرحلة ج)
//
// ودجت واحد يخدم السلف والسندات معاً. **لا نسختين** — النسخ المكرّرة هي
// بالضبط ما أنتج مشكلة قوائم البنود في شاشتَي الصرف والقبض (ب-١): عُدِّلت
// إحداهما ونُسيت الأخرى.
//
// يعرض: قائمة المرفقات · زر إضافة · فتح · حذف · وحالة «الملف مفقود» حين
// يُحذف من خارج البرنامج.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/attachment_service.dart';
import '../../../data/database/app_database.dart';
import '../../providers/attachment_providers.dart';

/// لوحة مرفقات كيان (سلفة أو سند)
///
/// [entityType] من `AttachmentEntity` · [entityId] معرّف الكيان
/// [year] سنة الكيان · [folderName] اسم مجلده داخل مخزن المرفقات
class AttachmentsPanel extends ConsumerWidget {
  const AttachmentsPanel({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.year,
    required this.folderName,
    this.title = 'المرفقات',
    this.readOnly = false,
  });

  final String entityType;
  final int entityId;
  final int year;
  final String folderName;
  final String title;

  /// يمنع الإضافة والحذف — للكيانات المُقفَلة (سلفة ملغاة مثلاً)
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final listAsync = ref.watch(
      attachmentsForProvider(entityType: entityType, entityId: entityId),
    );
    final root = ref.watch(attachmentsRootProvider).valueOrNull ?? '';
    final rootMissing = root.trim().isEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_file, size: 18,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                listAsync.maybeWhen(
                  data: (list) => list.isEmpty
                      ? const SizedBox.shrink()
                      : Text('${list.length}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                  orElse: () => const SizedBox.shrink(),
                ),
                if (!readOnly) ...[
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: rootMissing
                        ? null
                        : () => _pickAndAttach(context, ref),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('إرفاق'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ],
            ),

            // الجذر غير معيَّن — نشرح السبب بدل زرّ معطّل بلا تفسير
            if (rootMissing) ...[
              const SizedBox(height: 10),
              _Hint(
                icon: Icons.folder_off_outlined,
                text: 'لم يُحدَّد مجلد المرفقات بعد.\n'
                    'عيّنه من: الإعدادات ← المرفقات.',
                color: theme.colorScheme.error,
              ),
            ] else
              listAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (e, _) => _Hint(
                  icon: Icons.error_outline,
                  text: 'تعذّر تحميل المرفقات: $e',
                  color: theme.colorScheme.error,
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: _Hint(
                        icon: Icons.description_outlined,
                        text: 'لا مرفقات بعد — أرفق الفاتورة أو الوصل.',
                      ),
                    );
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 6),
                      ...list.map(
                        (a) => _AttachmentTile(
                          attachment: a,
                          root: root,
                          readOnly: readOnly,
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// اختيار ملف وإرفاقه
  Future<void> _pickAndAttach(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'اختر ملفاً لإرفاقه',
      // نسمح بأي امتداد: الوصولات تأتي أحياناً صوراً وأحياناً PDF أو إكسل،
      // وتقييد القائمة يُربك أكثر مما يحمي
      withData: false,
    );
    final path = picked?.files.single.path;
    if (path == null) return;

    final outcome =
        await ref.read(attachmentNotifierProvider.notifier).attach(
              entityType: entityType,
              entityId: entityId,
              sourcePath: path,
              year: year,
              folderName: folderName,
            );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(outcome.message),
        backgroundColor: outcome.ok ? null : Theme.of(context).colorScheme.error,
        duration: Duration(seconds: outcome.ok ? 3 : 6),
      ),
    );
  }
}

// ── صفّ مرفق واحد ────────────────────────────────────────────────────────────

class _AttachmentTile extends ConsumerStatefulWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.root,
    required this.readOnly,
  });

  final Attachment attachment;
  final String root;
  final bool readOnly;

  @override
  ConsumerState<_AttachmentTile> createState() => _AttachmentTileState();
}

class _AttachmentTileState extends ConsumerState<_AttachmentTile> {
  /// هل الملف موجود على القرص؟ null = لم يُفحَص بعد
  ///
  /// نفحص لأن الفهرس قد يشير إلى ملف حذفه المستخدم يدوياً من خارج البرنامج.
  /// إظهار ذلك أصدق من فتحٍ يفشل بلا تفسير.
  bool? _exists;

  @override
  void initState() {
    super.initState();
    _checkExists();
  }

  Future<void> _checkExists() async {
    final ok = await AttachmentService.exists(
      root: widget.root,
      relativePath: widget.attachment.relativePath,
    );
    if (mounted) setState(() => _exists = ok);
  }

  /// حجم مقروء بشرياً
  String _size(int bytes) {
    if (bytes < 1024) return '$bytes بايت';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} كيلوبايت';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ميغابايت';
  }

  IconData get _icon {
    final m = widget.attachment.mimeType;
    if (m.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (m.startsWith('image/')) return Icons.image_outlined;
    if (m.contains('sheet') || m.contains('excel')) return Icons.table_chart_outlined;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = widget.attachment;
    final missing = _exists == false;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        missing ? Icons.link_off : _icon,
        size: 22,
        color: missing ? theme.colorScheme.error : theme.colorScheme.primary,
      ),
      title: Text(
        a.fileName,
        style: theme.textTheme.bodyMedium?.copyWith(
          decoration: missing ? TextDecoration.lineThrough : null,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        missing
            ? 'الملف مفقود من القرص — حُذف أو نُقل من خارج البرنامج'
            : '${_size(a.sizeBytes)} · '
                '${a.createdAt.year}/${a.createdAt.month.toString().padLeft(2, '0')}/'
                '${a.createdAt.day.toString().padLeft(2, '0')}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: missing
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!missing)
            IconButton(
              tooltip: 'فتح',
              icon: const Icon(Icons.open_in_new, size: 18),
              onPressed: () => _open(),
            ),
          if (!widget.readOnly)
            IconButton(
              tooltip: 'حذف المرفق',
              icon: Icon(Icons.delete_outline,
                  size: 18, color: theme.colorScheme.error),
              onPressed: () => _confirmDelete(),
            ),
        ],
      ),
    );
  }

  Future<void> _open() async {
    final outcome = await ref
        .read(attachmentNotifierProvider.notifier)
        .open(widget.attachment);
    if (!outcome.ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(outcome.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      // الفتح فشل غالباً لأن الملف اختفى — نُحدّث الحالة لتظهر الشطبة
      await _checkExists();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المرفق'),
        content: Text(
          'سيُحذف «${widget.attachment.fileName}» من الفهرس ومن القرص معاً.\n'
          'لا يمكن التراجع.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final outcome = await ref
        .read(attachmentNotifierProvider.notifier)
        .remove(widget.attachment.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(outcome.message),
        backgroundColor:
            outcome.ok ? null : Theme.of(context).colorScheme.error,
      ),
    );
  }
}

// ── تلميح ────────────────────────────────────────────────────────────────────

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(color: c, height: 1.5),
          ),
        ),
      ],
    );
  }
}
