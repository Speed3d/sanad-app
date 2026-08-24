// ─────────────────────────────────────────────────────────────────────────────
// attachments_tab.dart — إعداد مجلد المرفقات (المرحلة ج)
//
// **لماذا يستحقّ الإعداد تبويباً كاملاً؟**
//   لأنه المفتاح الذي تعتمد عليه **كل** روابط المرفقات. المسارات مخزَّنة في
//   قاعدة البيانات نسبيةً لهذا الجذر، فتغييره ينقل كل المرفقات دفعةً واحدة،
//   وتعيينه خطأً يجعلها كلها تبدو مفقودة.
//
//   ولهذا نشرح للمالك ما يفعله التغيير **قبل** أن يفعله — بدل أن يكتشف بعده
//   أن مرفقاته كلها اختفت من الشاشات.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_settings_keys.dart';
import '../../../providers/attachment_providers.dart';
import '../../../providers/repository_providers.dart';

/// تبويب إعدادات المرفقات
class AttachmentsTab extends ConsumerStatefulWidget {
  const AttachmentsTab({super.key});

  @override
  ConsumerState<AttachmentsTab> createState() => _AttachmentsTabState();
}

class _AttachmentsTabState extends ConsumerState<AttachmentsTab> {
  bool _saving = false;

  /// اختيار مجلد الجذر
  Future<void> _pickRoot() async {
    final picked = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'اختر مجلد حفظ المرفقات',
    );
    if (picked == null) return;

    // نتحقّق أن المجلد قابل للكتابة **قبل** حفظ الإعداد. تعيين مجلد محمي
    // يجعل كل إرفاق لاحق يفشل برسالة غامضة بعيدة عن سببها.
    try {
      final probe = File('$picked/.sanad_write_test');
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('المجلد غير قابل للكتابة:\n$picked\n'
              'اختر مجلداً آخر أو صحّح صلاحياته.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(settingsRepositoryProvider)
          .setString(AppSettingsKeys.attachmentsRoot, picked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ تم تعيين مجلد المرفقات')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// حجم مقروء بشرياً
  String _size(int bytes) {
    if (bytes < 1024) return '$bytes بايت';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} كيلوبايت';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ميغابايت';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final root = ref.watch(attachmentsRootProvider).valueOrNull ?? '';
    final totalSize = ref.watch(attachmentsTotalSizeProvider).valueOrNull ?? 0;
    final isSet = root.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('مجلد المرفقات', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'المكان الذي تُنسَخ إليه فواتير السلف ووصولات السندات.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isSet ? Icons.folder_outlined : Icons.folder_off_outlined,
                      size: 20,
                      color: isSet
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isSet ? root : 'لم يُحدَّد بعد',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSet ? null : theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _saving ? null : _pickRoot,
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: Text(isSet ? 'تغيير المجلد' : 'اختر المجلد'),
                    ),
                    if (isSet) ...[
                      const SizedBox(width: 12),
                      Text(
                        'إجمالي المرفقات: ${_size(totalSize)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── شرح صريح لأثر التغيير ──────────────────────────────────────
        Card(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.4),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 17, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('كيف تعمل المرفقات',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                _Bullet(
                  'البرنامج **ينسخ** الملف إلى هذا المجلد ولا ينقله — '
                  'يبقى أصلك في مكانه.',
                ),
                _Bullet(
                  'التنظيم تلقائي: '
                  '«السنة ← سلفة-الرقم-المشروع ← الملف»، تماماً كتنظيم '
                  'الملفات الورقية.',
                ),
                _Bullet(
                  'قاعدة البيانات تحفظ **المسار النسبي** لا الكامل. لذلك نقل '
                  'المجلد كلّه أو تغيّر حرف القرص لا يكسر أي رابط — يكفي '
                  'تحديث هذا الإعداد.',
                ),
                _Bullet(
                  'انسخ هذا المجلد مع النسخة الاحتياطية: قاعدة البيانات تحفظ '
                  'الفهرس فقط، والملفات هنا.',
                ),
              ],
            ),
          ),
        ),

        if (isSet) ...[
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.25),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: theme.colorScheme.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تغيير المجلد لا ينقل الملفات الموجودة. إن غيّرته، '
                      'انقل محتوى المجلد القديم إلى الجديد بنفسك — وإلا '
                      'ظهرت كل المرفقات السابقة «مفقودة».',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// نقطة في قائمة الشرح
class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: theme.textTheme.bodySmall),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text.replaceAll('**', ''),
              style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
