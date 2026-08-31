// ─────────────────────────────────────────────────────────────────────────────
// fiscal_period_card.dart — بطاقة الفترة المالية ومكوّناتها
//
// جزء من مكتبة `fiscal_screen.dart` — فُصل لأن الملف الأصل تجاوز الحدّ المتّفق عليه
// (١٢٠٠ سطر) الذي يحرسه `test/unit/tech_debt_guard_test.dart`.
//
// نستعمل `part` لا ملفاً مستقلاً كي تبقى الأصناف **خاصة** (`_X`) كما هي،
// فلا تتسرّب إلى بقية المشروع ولا نحتاج إعادة تسميتها.
// ─────────────────────────────────────────────────────────────────────────────

part of 'fiscal_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// _PeriodCard — بطاقة الفترة المالية
// ═══════════════════════════════════════════════════════════════════════════

class _PeriodCard extends ConsumerWidget {
  final FiscalPeriod period;
  final bool isAdmin;
  final bool isSuperAdmin;
  final bool isOperating;
  final VoidCallback onClose;
  final VoidCallback onReopen;
  final VoidCallback onRecompute;
  final VoidCallback onDelete;
  final VoidCallback onPurge;

  const _PeriodCard({
    required this.period,
    required this.isAdmin,
    required this.isSuperAdmin,
    required this.isOperating,
    required this.onClose,
    required this.onReopen,
    required this.onRecompute,
    required this.onDelete,
    required this.onPurge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy');

    // لون البطاقة حسب الحالة
    final borderColor = _statusBorderColor(theme, period.status);
    final isPendingRecompute = period.status == 'frozen_pending_recompute';
    final isActive = period.status == 'active';
    final isFrozen = period.status == 'frozen';

    // عدد السندات من Provider
    final voucherCountAsync =
        ref.watch(periodVoucherCountProvider(period.id));

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: isPendingRecompute ? 2 : 1.2),
      ),
      elevation: isActive ? 3 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── رأس البطاقة ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.12),
            ),
            child: Row(
              children: [
                // أيقونة الحالة
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _statusIcon(period.status),
                    size: 20,
                    color: borderColor,
                  ),
                ),

                const SizedBox(width: 12),

                // الاسم ونوع الفترة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        period.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _PeriodTypeChip(periodType: period.periodType),
                          const SizedBox(width: 8),
                          _StatusBadge(status: period.status),
                        ],
                      ),
                    ],
                  ),
                ),

                // عدد السندات
                voucherCountAsync.when(
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (count) => Column(
                    children: [
                      Text(
                        '$count',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'سند',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── تفاصيل الفترة ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // النطاق الزمني
                Row(
                  children: [
                    Icon(
                      Icons.date_range_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${dateFmt.format(period.startDate)} — '
                      '${dateFmt.format(period.endDate)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${period.endDate.difference(period.startDate).inDays + 1} يوم',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                // معلومات الإقفال
                if (period.closedAt != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'أُقفِلت: ${dateFmt.format(period.closedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],

                // ملاحظات الفترة
                if (period.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          period.notes,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // تحذير إعادة الاحتساب
                if (isPendingRecompute) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'فترة سابقة أُعيد فتحها — راجع أرقام هذه الفترة '
                            'ثم أعد إقفالها',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── أزرار الإجراءات ─────────────────────────────────────────
          if (isAdmin || isSuperAdmin) ...[
            const Divider(height: 24, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // إقفال الفترة النشطة (admin & super_admin)
                  if (isActive && isAdmin)
                    OutlinedButton.icon(
                      onPressed: isOperating ? null : onClose,
                      icon: const Icon(Icons.lock_outline, size: 16),
                      label: const Text('إقفال الفترة'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),

                  // إعادة فتح الفترة المُقفَلة (super_admin فقط)
                  if (isFrozen && isSuperAdmin)
                    OutlinedButton.icon(
                      onPressed: isOperating ? null : onReopen,
                      icon: const Icon(Icons.lock_open_outlined, size: 16),
                      label: const Text('إعادة الفتح'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: 0.5),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),

                  // ⚠️ **التسمية صُحّحت (المرحلة ١٦ — 2026-08-30):** كان
                  //   اسمه «إعادة الاحتساب» وهو يَعِد بما لا يقع.
                  //
                  //   الدالة تحذف سندات الرصيد الافتتاحي ثم تُقفل الفترة —
                  //   وإنشاء تلك السندات **أُوقف نهائياً** بقرار المالك
                  //   2026-08-15 (كانت تُضاعف الرصيد، ح-٣ وح-٤). فالحذف
                  //   يُعيد صفراً دائماً في أي قاعدة أُنشئت بعد ذلك التاريخ،
                  //   ولم يبقَ من العملية إلا **الإقفال**.
                  //
                  //   ولا يُحذف الزرّ: هو المخرج الوحيد من حالة
                  //   `frozen_pending_recompute` إلى `frozen`.
                  if (isPendingRecompute && isSuperAdmin)
                    FilledButton.icon(
                      onPressed: isOperating ? null : onRecompute,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.calculate_outlined, size: 16),
                      label: const Text('راجعتُ وأعد الإقفال'),
                    ),

                  // حذف فترة خالية (super_admin فقط)
                  //
                  // يظهر فقط حين تكون الفترة بلا سندات ظاهرة. الحارس الحقيقي
                  // في FiscalPeriodsDao.deleteEmptyPeriod — هذا الشرط لتقليل
                  // الضجيج لا للحماية.
                  if (isSuperAdmin && voucherCountAsync.valueOrNull == 0)
                    OutlinedButton.icon(
                      onPressed: isOperating ? null : onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('حذف'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: 0.5),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),

                  // 🔥 المحو القسري (super_admin فقط)
                  //
                  // بخلاف زر «حذف» أعلاه — المقيَّد بالفترة الخالية — يظهر
                  // هذا دائماً لأن غرضه بالضبط محو فترة **فيها** سندات.
                  // الحراسة الحقيقية ثلاث طبقات في FiscalNotifier.purgePeriod.
                  if (isSuperAdmin)
                    TextButton.icon(
                      onPressed: isOperating ? null : onPurge,
                      icon: const Icon(
                          Icons.local_fire_department_outlined, size: 16),
                      label: const Text('محو قسري'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),

                  // إعادة فتح فترة تحتاج احتساب (super_admin فقط)
                  if (isPendingRecompute && isSuperAdmin)
                    OutlinedButton.icon(
                      onPressed: isOperating ? null : onReopen,
                      icon: const Icon(Icons.lock_open_outlined, size: 16),
                      label: const Text('إعادة فتح'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: 0.5),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Color _statusBorderColor(ThemeData theme, String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'frozen':
        return theme.colorScheme.outline;
      case 'frozen_pending_recompute':
        return Colors.orange;
      default:
        return theme.colorScheme.outlineVariant;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.play_circle_outline;
      case 'frozen':
        return Icons.lock_outline;
      case 'frozen_pending_recompute':
        return Icons.warning_amber_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _StatusBadge — شارة الحالة
// ═══════════════════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bgColor) = switch (status) {
      'active' => ('نشطة', Colors.green.shade700, Colors.green.shade50),
      'frozen' => (
          'مُقفَلة',
          Colors.blueGrey.shade600,
          Colors.blueGrey.shade50,
        ),
      'frozen_pending_recompute' => (
          'تحتاج مراجعة',
          Colors.orange.shade700,
          Colors.orange.shade50,
        ),
      _ => (status, Colors.grey, Colors.grey.shade100),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _PeriodTypeChip — شارة نوع الفترة
// ═══════════════════════════════════════════════════════════════════════════

class _PeriodTypeChip extends StatelessWidget {
  final String periodType;
  const _PeriodTypeChip({required this.periodType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final label = switch (periodType) {
      'yearly' => 'سنوية',
      'quarterly' => 'ربع سنوية',
      'monthly' => 'شهرية',
      _ => periodType,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _EmptyState — الحالة الفارغة
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onCreateTap;

  const _EmptyState({required this.isAdmin, required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد فترات مالية',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAdmin
                ? 'انقر على + لإنشاء أول فترة مالية للنظام'
                : 'لم يتم إنشاء أي فترة مالية بعد — تواصل مع مدير النظام',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (isAdmin) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add),
              label: const Text('إنشاء فترة مالية'),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _DatePickerField — حقل اختيار التاريخ
// ═══════════════════════════════════════════════════════════════════════════

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime? firstDate;
  final void Function(DateTime) onPick;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onPick,
    this.firstDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? firstDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
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
                    value != null ? fmt.format(value!) : 'اختر تاريخاً',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: value != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
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

// ═══════════════════════════════════════════════════════════════════════════
// _InfoRow — صف معلومات في الحوارات
// ═══════════════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
