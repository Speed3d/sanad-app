// ─────────────────────────────────────────────────────────────────────────────
// database_location_dialogs.dart — حوارات موضع القاعدة المشتركة
//
// تُستعمَل من ثلاثة أبواب: تبويب «قاعدة البيانات» في الإعدادات · شاشة الإعداد
// الأول («لديّ قاعدة سابقة») · وشاشة خطأ الإقلاع (القاعدة غير موجودة).
// ونسخةٌ واحدة لا ثلاث: ٨٤٠ سطراً مكرّراً بين شاشتَي السند نشأت من «نسخةٍ
// صغيرة» تباعدت (المرحلة د).
//
// ⚠️ الألوان من `colorScheme` لا من `context.colors`: شاشة خطأ الإقلاع تُبنى
//   قبل أن تُفتح القاعدة، فلا إعدادات ثيمٍ مخصّص فيها — والمخطط اللوني القياسي
//   موجود في كل ثيم.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/database/database_location.dart';

/// يختار مجلداً — `null` إن ألغى المالك
Future<String?> pickDatabaseFolder(String title) =>
    FilePicker.platform.getDirectoryPath(dialogTitle: title);

/// يعرض حصيلة فحص مجلد
///
/// الأخطاء تمنع (زرّ واحد: حسناً) · والتحذيرات تُسأل (متابعة أو تراجع).
/// يُعيد `true` إن جاز المضيّ.
Future<bool> presentFolderCheck(
  BuildContext context,
  FolderCheck check, {
  required String title,
}) async {
  if (check.isAllowed && check.warnings.isEmpty) return true;
  final scheme = Theme.of(context).colorScheme;

  final blocked = !check.isAllowed;
  final lines = blocked ? check.errors : check.warnings;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        blocked ? Icons.block : Icons.warning_amber_rounded,
        color: blocked ? scheme.error : scheme.tertiary,
        size: 36,
      ),
      title: Text(blocked ? 'لا يصلح هذا المجلد' : title),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('• $l', style: const TextStyle(height: 1.6)),
                ),
              if (!blocked)
                const Text(
                  'هل تريد المتابعة رغم ذلك؟',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
      ),
      actions: blocked
          ? [
              FilledButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('حسناً'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('تراجع'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('متابعة رغم التحذير'),
              ),
            ],
    ),
  );
  return result == true;
}

/// تأكيد «فتح قاعدة موجودة» — يرى المالك **ما في القاعدة** قبل أن يقرّر
///
/// اسم الشركة وعدد السندات والمستخدمين: فاختيار المجلد الخطأ (نسخة قديمة من
/// السنة الماضية مثلاً) يُكشف هنا لا بعد إعادة التشغيل.
///
/// [aboutCurrent] — ما سيحدث للقاعدة المفتوحة الآن (يختلف بحسب الباب).
Future<bool> confirmAttach(
  BuildContext context,
  DatabaseCandidate candidate, {
  required int appSchemaVersion,
  required String aboutCurrent,
}) async {
  final upgrade = candidate.schemaVersion < appSchemaVersion;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.storage_rounded, size: 36),
      title: const Text('فتح هذه القاعدة؟'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // مسارٌ وحده: اتجاهٌ صريح لا محارف عزل — راجع bidiPath
              SelectableText(
                candidate.path,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 16),
              _Fact('الشركة', candidate.companyName ?? '— (لم يُسجَّل اسم)'),
              _Fact('السندات', '${candidate.voucherCount}'),
              _Fact('المستخدمون', '${candidate.userCount}'),
              _Fact('إصدار المخطط', 'v${candidate.schemaVersion}'),
              if (upgrade) ...[
                const SizedBox(height: 12),
                Text(
                  '⚠️ القاعدة من إصدارٍ أقدم (v${candidate.schemaVersion})، '
                  'وستُرقّى إلى v$appSchemaVersion عند فتحها. خذ نسخةً من '
                  'المجلد قبل المتابعة إن لم تكن لديك.',
                  style: const TextStyle(height: 1.6),
                ),
              ],
              const SizedBox(height: 12),
              Text(aboutCurrent, style: const TextStyle(height: 1.6)),
              const SizedBox(height: 12),
              const Text(
                'سيُعاد تشغيل البرنامج، وتدخل بحساب من حسابات هذه القاعدة.',
                style: TextStyle(fontWeight: FontWeight.w700, height: 1.6),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('تراجع'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('افتحها'),
        ),
      ],
    ),
  );
  return result == true;
}

/// حوار انتظار لا يُغلَق باليد — يُعيد دالة إغلاقه
///
/// ⚠️ الـ `NavigatorState` يُلتقط **الآن** لا لحظة الإغلاق: بين الفتح والإغلاق
///   عملياتٌ طويلة قد تُميت السياق، ومرجعٌ ميت بعد `await` هو ع-٥٧ بعينه.
VoidCallback showBlockingProgress(BuildContext context, String message) {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 20),
            Expanded(child: Text(message, style: const TextStyle(height: 1.6))),
          ],
        ),
      ),
    ),
  );
  return navigator.pop;
}

/// رسالة نتيجة بزرٍّ واحد
Future<void> showLocationMessage(
  BuildContext context, {
  required String title,
  required String body,
  bool isError = false,
  String button = 'حسناً',
}) {
  final scheme = Theme.of(context).colorScheme;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: isError ? scheme.error : scheme.primary,
        size: 36,
      ),
      title: Text(title),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: SelectableText(body, style: const TextStyle(height: 1.6)),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(button),
        ),
      ],
    ),
  );
}

/// سطرُ «تسمية: قيمة» في حوار التأكيد
class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
