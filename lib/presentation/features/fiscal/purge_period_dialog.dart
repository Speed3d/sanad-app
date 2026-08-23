// ─────────────────────────────────────────────────────────────────────────────
// purge_period_dialog.dart — نافذة المحو القسري لفترة مالية
//
// 🔥 أخطر نافذة في التطبيق: تمحو فترة مالية **بكل سنداتها** محواً نهائياً لا
// رجعة فيه — بما فيها السندات المحذوفة ناعماً التي تمنع الحذف العادي.
//
// أُضيفت بطلب صريح من المالك (2026-08-23): مرحلة الاختبار تتطلّب تصفير سنة
// كاملة وإعادة بنائها، وبدونها تبقى كل سنة تجريبية حاجزاً دائماً على نطاق
// تواريخها لأن `deleteEmptyPeriod` ترفض — بحقّ — أي فترة فيها أثر مالي.
//
// ثلاثة حقول إلزامية، وترتيبها مقصود:
//   ١. **اسم الفترة** أولاً — يمنع الخطر الأرجح عملياً: محو السنة الخاطئة
//      وأنت مستعجل. لا ينفع فيه تذكّر كلمة مرور.
//   ٢. **كلمة المرور** — تمنع من يجد الجهاز مفتوحاً
//   ٣. **رمز المحو** — عامل ثانٍ لا يُكتب يومياً فلا يُرى ولا يُحفَظ في
//      مدير كلمات مرور. راجع purge_code_card.dart
//
// كلها تُتحقَّق في FiscalNotifier.purgePeriod لا هنا — الواجهة تجمع المدخلات
// فقط، والحرس الحقيقي في الطبقة التي لا يستطيع أحد تجاوزها بتعديل شاشة.
//
// ملاحظة تقنية: لا TextEditingController في هذا الملف رغم وجود ثلاثة حقول
// كلمة مرور. متغيّرات نصّية مع initialValue/onChanged تكفي، وتتجنّب عطل
// «متحكّم استُعمل بعد التخلّص منه» الذي أصاب حوارات هذه الشاشة نفسها.
// راجع الحارس في test/unit/dialog_controller_lifecycle_test.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../providers/fiscal_providers.dart';

/// يعرض نافذة المحو القسري ويُنفّذها عند التأكيد
///
/// [period] — الفترة المستهدفة
Future<void> showPurgePeriodDialog(
  BuildContext context,
  WidgetRef ref,
  FiscalPeriod period,
) async {
  final confirmed = await showDialog<_PurgeInput>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PurgeDialog(period: period),
  );

  if (confirmed == null) return;

  // النتيجة (نجاح أو سبب الرفض) تُعرَض عبر ref.listen في الشاشة الرئيسية
  await ref.read(fiscalNotifierProvider.notifier).purgePeriod(
        period.id,
        password: confirmed.password,
        purgeCode: confirmed.code,
        typedName: confirmed.typedName,
      );
}

/// مدخلات المحو الثلاثة
class _PurgeInput {
  final String typedName;
  final String password;
  final String code;

  const _PurgeInput({
    required this.typedName,
    required this.password,
    required this.code,
  });
}

class _PurgeDialog extends StatefulWidget {
  const _PurgeDialog({required this.period});

  final FiscalPeriod period;

  @override
  State<_PurgeDialog> createState() => _PurgeDialogState();
}

class _PurgeDialogState extends State<_PurgeDialog> {
  String _typedName = '';
  String _password = '';
  String _code = '';

  /// هل اكتملت المدخلات الثلاثة؟ — الاسم يُقارَن هنا للتغذية الراجعة الفورية
  /// فقط؛ المقارنة المُلزِمة تقع في FiscalNotifier.purgePeriod
  bool get _ready =>
      _typedName.trim() == widget.period.name.trim() &&
      _password.isNotEmpty &&
      _code.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.period.name;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.local_fire_department_outlined,
            size: 22,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'محو قسري نهائي',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
      scrollable: true,
      content: SizedBox(
        width: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                'ستُمحى الفترة "$name" وكل سنداتها نهائياً — بما فيها '
                'السندات المحذوفة سابقاً. لا يمكن التراجع، ولا تستعيدها إلا '
                'نسخة احتياطية.\n\n'
                'سيبقى في سجل المراجعة سطر واحد يوثّق أن المحو حدث.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 20),

            // ── ١. اسم الفترة ────────────────────────────────────────────
            Text(
              'اكتب اسم الفترة للتأكيد: $name',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            TextFormField(
              autofocus: true,
              initialValue: _typedName,
              onChanged: (v) => setState(() => _typedName = v),
              decoration: InputDecoration(
                hintText: name,
                prefixIcon: const Icon(Icons.edit_outlined),
                isDense: true,
                suffixIcon: _typedName.trim() == name.trim()
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
            ),
            const SizedBox(height: 14),

            // ── ٢. كلمة المرور ───────────────────────────────────────────
            TextFormField(
              initialValue: _password,
              onChanged: (v) => setState(() => _password = v),
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة مرورك',
                prefixIcon: Icon(Icons.lock_outline),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),

            // ── ٣. رمز المحو ─────────────────────────────────────────────
            TextFormField(
              initialValue: _code,
              onChanged: (v) => setState(() => _code = v),
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'رمز المحو القسري',
                helperText: 'يُعيَّن من: الإعدادات ← الأمان',
                prefixIcon: Icon(Icons.key_outlined),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _ready
              ? () => Navigator.pop(
                    context,
                    _PurgeInput(
                      typedName: _typedName,
                      password: _password,
                      code: _code,
                    ),
                  )
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          icon: const Icon(Icons.local_fire_department_outlined, size: 16),
          label: const Text('محو نهائي'),
        ),
      ],
    );
  }
}
