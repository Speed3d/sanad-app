// ─────────────────────────────────────────────────────────────────────────────
// post_advance_dialog.dart — نافذة اعتماد السلفة وقرار العجز
//
// هذه النافذة هي **اللحظة الفاصلة** في النظام كله: بعدها تتحوّل المسودة إلى
// سندات صرف ويتأثر رصيد الخزينة. لذلك تعرض كل ما يحتاجه القرار في مكان واحد
// بدل أن يضغط المستخدم «اعتماد» ثم يكتشف الأثر لاحقاً.
//
// حالتان:
//   بلا عجز → تأكيد بسيط بالأرقام
//   بعجز    → خياران صريحان:
//             (أ) اعتماد مع عجز + اسم من غطّاه (إلزامي — بدونه يضيع الدَّين)
//             (ب) تحويل تكميلي أولاً (يُعيد المستخدم لشاشة التحويل)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../domain/models/advance_model.dart';

/// نتيجة نافذة الاعتماد
class PostAdvanceDecision {
  /// هل يمضي المستخدم في الاعتماد؟
  final bool confirmed;

  /// هل أقرّ بالعجز صراحةً؟
  final bool allowDeficit;

  /// اسم من غطّى العجز
  final String? deficitCoveredBy;

  /// هل اختار «تحويل تكميلي أولاً» بدل الاعتماد؟
  final bool wantsTopUp;

  const PostAdvanceDecision({
    this.confirmed = false,
    this.allowDeficit = false,
    this.deficitCoveredBy,
    this.wantsTopUp = false,
  });
}

/// نافذة اعتماد السلفة
class PostAdvanceDialog extends StatefulWidget {
  const PostAdvanceDialog({
    super.key,
    required this.advance,
    required this.summary,
    required this.canPostWithDeficit,
  });

  final AdvanceModel advance;
  final AdvanceSummary summary;

  /// هل يملك المستخدم صلاحية الاعتماد بعجز؟
  final bool canPostWithDeficit;

  @override
  State<PostAdvanceDialog> createState() => _PostAdvanceDialogState();
}

class _PostAdvanceDialogState extends State<PostAdvanceDialog> {
  final _coveredByCtrl = TextEditingController();
  bool _acknowledged = false;
  String? _error;

  @override
  void dispose() {
    _coveredByCtrl.dispose();
    super.dispose();
  }

  bool get _hasDeficit => widget.summary.deficit > 0;

  void _confirm() {
    if (_hasDeficit) {
      if (!_acknowledged) {
        setState(() => _error = 'أقرّ بأن الخزينة ستصبح بالسالب للمتابعة.');
        return;
      }
      if (_coveredByCtrl.text.trim().isEmpty) {
        setState(() => _error =
            'اكتب اسم من غطّى العجز — بدونه لا يُعرَف لمن تدين الشركة.');
        return;
      }
    }
    Navigator.of(context).pop(
      PostAdvanceDecision(
        confirmed: true,
        allowDeficit: _hasDeficit,
        deficitCoveredBy:
            _hasDeficit ? _coveredByCtrl.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0');
    final s = widget.summary;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _hasDeficit ? Icons.warning_amber_rounded : Icons.fact_check_outlined,
            color: _hasDeficit ? Colors.orange.shade800 : theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('اعتماد سلفة ${widget.advance.advanceNumber}'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سيُنشأ ${s.countedLines} سند صرف على ${widget.advance.projectName}.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _Row('إجمالي المصاريف', '${fmt.format(s.spent)} د.ع'),
            _Row('رصيد الخزينة الآن', '${fmt.format(s.treasuryBalance)} د.ع'),
            if (s.excludedLines > 0)
              _Row('أسطر مستبعَدة', '${s.excludedLines}'),
            if (!s.matchesExcel)
              _Row(
                'فرق عن ملف الإكسل',
                '${fmt.format(s.excelDifference.abs())} د.ع',
                color: Colors.orange.shade800,
              ),

            if (_hasDeficit) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'العجز: ${fmt.format(s.deficit)} د.ع',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'المصاريف تتجاوز رصيد الخزينة. الاعتماد سيجعل رصيد '
                      '${widget.advance.projectName} سالباً — أي أن الشركة '
                      'مدينة بهذا المبلغ لمن دفعه من ماله.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (!widget.canPostWithDeficit)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'اعتماد سلفة بعجز يتطلب صلاحية مدير. يمكنك بدلاً '
                          'من ذلك تحويل المبلغ الناقص إلى الخزينة أولاً.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                CheckboxListTile(
                  value: _acknowledged,
                  onChanged: (v) =>
                      setState(() => _acknowledged = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  title: const Text(
                    'أقرّ بأن رصيد الخزينة سيصبح سالباً',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                TextField(
                  controller: _coveredByCtrl,
                  decoration: const InputDecoration(
                    labelText: 'من غطّى العجز؟ *',
                    hintText: 'مثال: أبو أحمد — مدير المشروع',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
              ],
            ],

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            const PostAdvanceDecision(),
          ),
          child: const Text('إلغاء'),
        ),
        if (_hasDeficit)
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(
              const PostAdvanceDecision(wantsTopUp: true),
            ),
            icon: const Icon(Icons.sync_alt, size: 18),
            label: const Text('تحويل تكميلي أولاً'),
          ),
        FilledButton.icon(
          onPressed:
              (_hasDeficit && !widget.canPostWithDeficit) ? null : _confirm,
          style: _hasDeficit
              ? FilledButton.styleFrom(backgroundColor: Colors.orange.shade800)
              : null,
          icon: const Icon(Icons.check, size: 18),
          label: Text(_hasDeficit ? 'اعتماد مع عجز' : 'اعتماد'),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
