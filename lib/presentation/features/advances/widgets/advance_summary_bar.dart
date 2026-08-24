// ─────────────────────────────────────────────────────────────────────────────
// advance_summary_bar.dart — شريط المطابقة أعلى شاشة مراجعة السلفة
//
// يعرض في سطر واحد الأرقام الأربعة التي تُجيب سؤال المالك:
//   المُرسَل · إجمالي الإكسل · إجمالي المسودة · المتبقي أو العجز
//
// لماذا نعرض «إجمالي الإكسل» و«إجمالي المسودة» معاً؟
//   المالك يعدّل الأسطر (يصحّح مبلغاً، يستبعد سطراً مكرراً)، وهذا مشروع.
//   لكن التعديل يجعل المسودة تختلف عمّا أرسله المشروع. إبقاء الرقمين جنباً
//   إلى جنب يجعل الفرق **مرئياً** لا صامتاً — فتبقى المطابقة صادقة.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../domain/models/advance_model.dart';

/// شريط ملخص السلفة
class AdvanceSummaryBar extends StatelessWidget {
  const AdvanceSummaryBar({
    super.key,
    required this.summary,
    required this.isPosted,
  });

  final AdvanceSummary summary;

  /// بعد الاعتماد تتغيّر لغة العرض: «سيصبح» → «أصبح»
  final bool isPosted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0');
    final hasDeficit = summary.deficit > 0;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── الأرقام الأربعة ──────────────────────────────────────
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _Figure(
                  label: 'المُرسَل للمشروع',
                  value: '${fmt.format(summary.sent)} د.ع',
                  color: theme.colorScheme.primary,
                ),
                _Figure(
                  label: 'إجمالي الإكسل',
                  value: '${fmt.format(summary.excelTotal)} د.ع',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                _Figure(
                  label: 'إجمالي المسودة',
                  value: '${fmt.format(summary.spent)} د.ع',
                  color: theme.colorScheme.onSurface,
                  trailing: summary.matchesExcel
                      ? const Icon(Icons.check_circle,
                          size: 16, color: Colors.green)
                      : Icon(Icons.warning_amber_rounded,
                          size: 16, color: Colors.orange.shade800),
                ),
                _Figure(
                  label: summary.remaining < 0
                      ? 'تجاوز السلفة'
                      : 'المتبقي من السلفة',
                  value: '${fmt.format(summary.remaining.abs())} د.ع',
                  color: summary.remaining < 0
                      ? Colors.orange.shade800
                      : Colors.green.shade700,
                  bold: true,
                ),
              ],
            ),

            // ── فرق المسودة عن الإكسل ────────────────────────────────
            if (!summary.matchesExcel) ...[
              const SizedBox(height: 10),
              _Note(
                icon: Icons.difference_outlined,
                color: Colors.orange.shade800,
                text: 'المسودة تختلف عن ملف الإكسل بمقدار '
                    '${fmt.format(summary.excelDifference.abs())} د.ع '
                    '(${summary.excelDifference > 0 ? 'أكبر' : 'أصغر'})'
                    '${summary.excludedLines > 0 ? ' · ${summary.excludedLines} سطر مستبعَد' : ''}'
                    '${summary.editedLines > 0 ? ' · ${summary.editedLines} سطر معدَّل' : ''}',
              ),
            ],

            // ── تحذير العجز ──────────────────────────────────────────
            if (hasDeficit) ...[
              const SizedBox(height: 10),
              _Note(
                icon: Icons.account_balance_wallet_outlined,
                color: Colors.red.shade700,
                text: isPosted
                    ? 'اعتُمدت بعجز ${fmt.format(summary.deficit)} د.ع — '
                        'خزينة المشروع بالسالب والشركة مدينة بهذا المبلغ.'
                    : 'الاعتماد الآن سيجعل رصيد الخزينة سالباً بمقدار '
                        '${fmt.format(summary.deficit)} د.ع — '
                        'رصيدها الحالي ${fmt.format(summary.treasuryBalance)} د.ع.',
                bold: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
    this.trailing,
  });

  final String label;
  final String value;
  final Color color;
  final bool bold;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: bold ? 17 : 15,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ],
          ],
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({
    required this.icon,
    required this.color,
    required this.text,
    this.bold = false,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
