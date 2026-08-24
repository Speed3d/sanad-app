// ─────────────────────────────────────────────────────────────────────────────
// report_widgets.dart — الودجتات المشتركة بين تبويبات التقارير
//
// **لماذا مُستخرَجة إلى ملف مستقلّ؟** (ب-٢ — 2026-08-23)
//   كانت هذه الثلاثة خاصّة (`_DateField` · `_SummaryCard` · `_ReportPlaceholder`)
//   داخل `reports_screen.dart`. وإضافة تبويبَين جديدين كانت تعني إمّا تضخيم
//   ذلك الملف إلى ~١٤٠٠ سطر، أو نسخ الودجتات — وهو الخطأ نفسه الذي أنتج
//   مشكلة قوائم البنود المكرّرة في شاشتَي الصرف والقبض (ب-١): نسختان،
//   عُدِّلت إحداهما ونُسيت الأخرى.
//
// استعمل هذه الودجتات في أي تبويب تقرير جديد — لا تكتب بديلاً رابعاً.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// حقل اختيار تاريخ — يفتح `showDatePicker` عند الضغط
///
/// [value] التاريخ الحالي · [onChanged] يُستدعى بالتاريخ المختار.
/// الحدّ الأعلى **اليوم**: التقارير تنظر إلى الماضي لا إلى المستقبل.
class ReportDateField extends StatelessWidget {
  const ReportDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(
          '${value.year}/${value.month.toString().padLeft(2, '0')}/'
          '${value.day.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

/// بطاقة ملخص صغيرة — رقم واحد بارز مع تسمية وأيقونة
class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// حالة فارغة موحّدة للتقارير — أيقونة كبيرة باهتة ورسالة
///
/// تُستعمَل لحالتين مختلفتين: «لم تختر فلاتر بعد» و«لا نتائج». اجعل الرسالة
/// تميّز بينهما — «لا نتائج» بعد بحث فعليّ معلومة، و«اختر فلاتر» تعليمات.
class ReportPlaceholder extends StatelessWidget {
  const ReportPlaceholder({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
