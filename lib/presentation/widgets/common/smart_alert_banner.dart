// ─────────────────────────────────────────────────────────────────────────────
// smart_alert_banner.dart — ودجت التنبيهات الذكية
//
// الغرض:
//   شريط تنبيهات ديناميكي وتفاعلي يُعرض في أعلى لوحة التحكم (Dashboard)
//   لتنبيه المستخدم بالأحداث الحرجة (انخفاض الرصيد، السلف المعلقة).
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/smart_alert_service.dart';

/// ودجت التنبيهات الذكية في الواجهة الرئيسية
class SmartAlertBanner extends ConsumerWidget {
  const SmartAlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(smartAlertsProvider);

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: alerts.map((alert) => _buildAlertCard(context, alert)).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAlertCard(BuildContext context, SmartAlert alert) {
    final theme = Theme.of(context);
    final isCritical = alert.severity == AlertSeverity.critical;

    final bgColor = isCritical ? Colors.red.shade50 : Colors.amber.shade50;
    final borderColor = isCritical ? Colors.red.shade300 : Colors.amber.shade400;
    final iconColor = isCritical ? Colors.red.shade700 : Colors.amber.shade800;
    final textColor = isCritical ? Colors.red.shade900 : Colors.amber.shade900;

    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isCritical ? Icons.warning_amber_rounded : Icons.info_outline,
              color: iconColor,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor.withValues(alpha: 0.85),
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
