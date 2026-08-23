// ─────────────────────────────────────────────────────────────────────────────
// fiscal_screen.dart — شاشة إدارة الفترات المالية
//
// الوظائف:
//   1. عرض قائمة تفاعلية بجميع الفترات المالية مع إحصائياتها
//   2. إنشاء فترة مالية جديدة (wizard مع اختيار النوع والتواريخ)
//   3. إقفال فترة نشطة (frozen) مع ملاحظات الإقفال
//   4. إعادة فتح فترة مُقفَلة (Super Admin فقط)
//   5. إعادة احتساب الأرصدة الافتتاحية (cascade recompute)
//
// التفويض:
//   - المستخدم العادي: عرض فقط
//   - المدير (admin): إقفال الفترات
//   - مدير النظام (super_admin): جميع العمليات بما فيها إعادة الفتح
//
// الفترة المالية — دورة الحياة:
//   active → [إقفال] → frozen
//   frozen → [إعادة فتح - super_admin] → active
//             + الفترات اللاحقة → frozen_pending_recompute
//   frozen_pending_recompute → [إعادة احتساب] → frozen
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/database/app_database.dart';
import '../../../domain/models/auth_state.dart';
import '../../../domain/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fiscal_providers.dart';
import 'purge_period_dialog.dart';

// ── ثوابت ────────────────────────────────────────────────────────────────────

/// خيارات نوع الفترة المالية
const List<_PeriodTypeOption> _periodTypes = [
  _PeriodTypeOption(value: 'yearly', label: 'سنوية', icon: Icons.calendar_today),
  _PeriodTypeOption(value: 'quarterly', label: 'ربع سنوية', icon: Icons.date_range),
  _PeriodTypeOption(value: 'monthly', label: 'شهرية', icon: Icons.calendar_month),
];

class _PeriodTypeOption {
  final String value;
  final String label;
  final IconData icon;
  const _PeriodTypeOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// FiscalScreen — الشاشة الرئيسية
// ═══════════════════════════════════════════════════════════════════════════

/// شاشة إدارة الفترات المالية
class FiscalScreen extends ConsumerStatefulWidget {
  const FiscalScreen({super.key});

  @override
  ConsumerState<FiscalScreen> createState() => _FiscalScreenState();
}

class _FiscalScreenState extends ConsumerState<FiscalScreen> {
  @override
  Widget build(BuildContext context) {
    // ── مراقبة نتائج العمليات لعرض SnackBars ───────────────────────────
    ref.listen<AsyncValue<String?>>(fiscalNotifierProvider, (prev, next) {
      if (!mounted) return;

      if (next is AsyncData<String?> && next.value != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.value!),
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(fiscalNotifierProvider.notifier).reset();
      } else if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${next.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
        ref.read(fiscalNotifierProvider.notifier).reset();
      }
    });

    // ── البيانات التفاعلية ──────────────────────────────────────────────
    final periodsAsync = ref.watch(allPeriodsProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUser =
        authState is AuthAuthenticated ? authState.user : null;
    final isAdmin = currentUser?.isAdmin ?? false;
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    final isOperating = ref.watch(fiscalNotifierProvider) is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('السنوات المالية'),
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: isOperating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline),
              tooltip: 'إنشاء فترة مالية جديدة',
              onPressed: isOperating
                  ? null
                  : () => _showCreateDialog(context),
            ),
          ],
        ],
      ),

      body: periodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('خطأ في تحميل الفترات المالية:\n$e',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (periods) {
          if (periods.isEmpty) {
            return _EmptyState(
              isAdmin: isAdmin,
              onCreateTap: () => _showCreateDialog(context),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allPeriodsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: periods.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final period = periods[index];
                return _PeriodCard(
                  period: period,
                  isAdmin: isAdmin,
                  isSuperAdmin: isSuperAdmin,
                  isOperating: isOperating,
                  onClose: () => _showCloseDialog(context, period),
                  onReopen: () => _showReopenDialog(context, period),
                  onRecompute: () => _showRecomputeDialog(context, period),
                  onDelete: () => _showDeleteDialog(context, period),
                  onPurge: () => showPurgePeriodDialog(context, ref, period),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // حوارات العمليات
  // ══════════════════════════════════════════════════════════════════════

  /// حوار إنشاء فترة مالية جديدة
  Future<void> _showCreateDialog(BuildContext context) async {
    final theme = Theme.of(context);

    // متغيرات حالة الحوار (نستخدم StatefulBuilder)
    String name = '';
    String periodType = 'yearly';
    DateTime? startDate;
    DateTime? endDate;
    // ⚠️ لا تُنشئ TextEditingController هنا ثم تتخلّص منه بعد showDialog.
    //   الـ await ينتهي لحظة استدعاء Navigator.pop، بينما يبقى الحوار
    //   **يُعاد بناؤه** طوال أنيميشن خروجه — فالتخلّص الفوري يجعل الحقل
    //   يلمس متحكّماً ميتاً: «A TextEditingController was used after being
    //   disposed»، ثم تنهار الشجرة بـ «_dependents.isEmpty» شاشةً حمراء.
    //   (عطل بلّغ عنه المالك 2026-08-23 عند إنشاء فترة مالية ثانية.)
    //   الحلّ: متغيّر نصّي عادي مع initialValue/onChanged — بلا متحكّم أصلاً.
    String notes = '';
    final formKey = GlobalKey<FormState>();
    bool isCreating = false;

    /// ملء التواريخ التلقائية للفترة السنوية
    void autoFillYearly(StateSetter setDialogState) {
      if (periodType != 'yearly') return;
      final year = int.tryParse(name);
      if (year == null || year < 2000 || year > 2100) return;
      setDialogState(() {
        startDate = DateTime(year, 1, 1);
        endDate = DateTime(year, 12, 31, 23, 59, 59);
      });
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_circle_outline, size: 20),
                SizedBox(width: 8),
                Text('فترة مالية جديدة'),
              ],
            ),
            scrollable: true,
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── نوع الفترة ──────────────────────────────────
                    Text(
                      'نوع الفترة',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _periodTypes.map((opt) {
                        final isSelected = opt.value == periodType;
                        return ChoiceChip(
                          avatar: Icon(opt.icon, size: 16),
                          label: Text(opt.label),
                          selected: isSelected,
                          onSelected: (_) {
                            setDialogState(() {
                              periodType = opt.value;
                              startDate = null;
                              endDate = null;
                            });
                          },
                          selectedColor: theme.colorScheme.primaryContainer,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // ── اسم الفترة ────────────────────────────────
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: periodType == 'yearly'
                            ? 'السنة (مثال: 2025)'
                            : 'اسم الفترة',
                        prefixIcon: const Icon(Icons.label_outline),
                        hintText: periodType == 'yearly' ? '2025' : 'مثال: 2025-Q1',
                      ),
                      onChanged: (v) {
                        name = v.trim();
                        autoFillYearly(setDialogState);
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'اسم الفترة مطلوب';
                        }
                        if (periodType == 'yearly') {
                          final year = int.tryParse(v.trim());
                          if (year == null || year < 2000 || year > 2100) {
                            return 'أدخل سنة صحيحة (2000 - 2100)';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── تواريخ الفترة ─────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _DatePickerField(
                            label: 'تاريخ البداية',
                            value: startDate,
                            onPick: (d) =>
                                setDialogState(() => startDate = d),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DatePickerField(
                            label: 'تاريخ النهاية',
                            value: endDate,
                            firstDate: startDate,
                            onPick: (d) => setDialogState(
                              () => endDate = DateTime(
                                d.year, d.month, d.day, 23, 59, 59,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (startDate != null && endDate != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'المدة: ${endDate!.difference(startDate!).inDays + 1} يوم',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // ── ملاحظات (اختياري) ─────────────────────────
                    TextFormField(
                      initialValue: notes,
                      onChanged: (v) => notes = v,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isCreating ? null : () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              FilledButton.icon(
                onPressed: isCreating
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        if (startDate == null || endDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('يرجى تحديد تاريخي البداية والنهاية'),
                            ),
                          );
                          return;
                        }
                        if (endDate!.isBefore(startDate!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'تاريخ النهاية يجب أن يكون بعد تاريخ البداية',
                              ),
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isCreating = true);
                        final success = await ref
                            .read(fiscalNotifierProvider.notifier)
                            .createPeriod(
                              name: name,
                              periodType: periodType,
                              startDate: startDate!,
                              endDate: endDate!,
                              notes: notes.trim(),
                            );

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          if (!success) {
                            // الخطأ يُعرَض عبر ref.listen في الشاشة الرئيسية
                          }
                        }
                      },
                icon: isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add),
                label: const Text('إنشاء الفترة'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── حوار حذف فترة مالية خالية ──────────────────────────────────────────

  /// تأكيد حذف فترة مالية لا تحتوي أي سند
  ///
  /// لا متحكّم نصّي هنا عمداً — راجع التعليق في حوار الإنشاء: التخلّص من
  /// متحكّم بعد `await showDialog` يقع أثناء أنيميشن الخروج فيُعطب الشجرة.
  Future<void> _showDeleteDialog(
    BuildContext context,
    FiscalPeriod period,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline,
                size: 20, color: Theme.of(ctx).colorScheme.error),
            const SizedBox(width: 8),
            const Text('حذف فترة مالية'),
          ],
        ),
        content: Text(
          'حذف الفترة "${period.name}" نهائياً؟\n\n'
          'هذا الحذف فعلي لا يمكن التراجع عنه. لن يُسمح به إلا إن كانت '
          'الفترة خالية تماماً من السندات وسلف المشاريع — فلا يضيع أي أثر '
          'مالي. سيُسجَّل الحذف في سجل المراجعة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('حذف نهائياً'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    // النتيجة (نجاح أو رسالة المنع) تُعرَض عبر ref.listen في الشاشة الرئيسية
    await ref.read(fiscalNotifierProvider.notifier).deletePeriod(period.id);
  }

  // ── حوار إقفال فترة مالية ──────────────────────────────────────────────

  /// حوار تأكيد إقفال الفترة مع إدخال الملاحظات
  Future<void> _showCloseDialog(
    BuildContext context,
    FiscalPeriod period,
  ) async {
    final theme = Theme.of(context);
    // ⚠️ لا تُنشئ TextEditingController هنا ثم تتخلّص منه بعد showDialog.
    //   الـ await ينتهي لحظة استدعاء Navigator.pop، بينما يبقى الحوار
    //   **يُعاد بناؤه** طوال أنيميشن خروجه — فالتخلّص الفوري يجعل الحقل
    //   يلمس متحكّماً ميتاً: «A TextEditingController was used after being
    //   disposed»، ثم تنهار الشجرة بـ «_dependents.isEmpty» شاشةً حمراء.
    //   (عطل بلّغ عنه المالك 2026-08-23 عند إنشاء فترة مالية ثانية.)
    //   الحلّ: متغيّر نصّي عادي مع initialValue/onChanged — بلا متحكّم أصلاً.
    String notes = '';
    bool isClosing = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_outline, size: 20),
              SizedBox(width: 8),
              Text('إقفال الفترة المالية'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'بعد الإقفال لن يمكن إضافة سندات جديدة لهذه الفترة.\n'
                          'يمكن لمدير النظام إعادة فتحها لاحقاً إذا لزم.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // معلومات الفترة
                _InfoRow(
                  label: 'الفترة',
                  value: period.name,
                  icon: Icons.calendar_today,
                ),
                _InfoRow(
                  label: 'النطاق',
                  value:
                      '${DateFormat('dd/MM/yyyy').format(period.startDate)} — '
                      '${DateFormat('dd/MM/yyyy').format(period.endDate)}',
                  icon: Icons.date_range,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  initialValue: notes,
                  onChanged: (v) => notes = v,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات الإقفال (اختياري)',
                    prefixIcon: Icon(Icons.notes_outlined),
                    hintText: 'مثال: إقفال نهاية السنة المالية 2024...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isClosing ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: isClosing
                  ? null
                  : () async {
                      setDialogState(() => isClosing = true);
                      await ref
                          .read(fiscalNotifierProvider.notifier)
                          .closePeriod(
                            period.id,
                            notes: notes.trim(),
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              icon: isClosing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_outline),
              label: const Text('تأكيد الإقفال'),
            ),
          ],
        ),
      ),
    );
  }

  // ── حوار إعادة فتح فترة (Super Admin) ────────────────────────────────

  /// حوار تأكيد قوي لإعادة فتح فترة مُقفَلة
  Future<void> _showReopenDialog(
    BuildContext context,
    FiscalPeriod period,
  ) async {
    final theme = Theme.of(context);
    bool isReopening = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock_open_outlined,
                  color: theme.colorScheme.error, size: 20),
              const SizedBox(width: 8),
              const Text('إعادة فتح الفترة المالية'),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning,
                              color: theme.colorScheme.onErrorContainer),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'تحذير — إعادة الفتح تؤثر على البيانات',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• الفترات المالية اللاحقة المُقفَلة ستُحدَّد بـ "تحتاج إعادة احتساب"\n'
                        '• يجب إعادة الاحتساب (تنظيف وإقفال) بعد الانتهاء من التعديلات\n'
                        '• هذه العملية للمدير الأعلى فقط',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _InfoRow(
                  label: 'الفترة',
                  value: period.name,
                  icon: Icons.calendar_today,
                ),
                _InfoRow(
                  label: 'النطاق',
                  value:
                      '${DateFormat('dd/MM/yyyy').format(period.startDate)} — '
                      '${DateFormat('dd/MM/yyyy').format(period.endDate)}',
                  icon: Icons.date_range,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isReopening ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: isReopening
                  ? null
                  : () async {
                      setDialogState(() => isReopening = true);
                      await ref
                          .read(fiscalNotifierProvider.notifier)
                          .reopenPeriod(period.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              icon: isReopening
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_open_outlined),
              label: const Text('تأكيد إعادة الفتح'),
            ),
          ],
        ),
      ),
    );
  }

  // ── حوار إعادة الاحتساب ───────────────────────────────────────────────

  /// حوار إعادة احتساب الأرصدة الافتتاحية
  Future<void> _showRecomputeDialog(
    BuildContext context,
    FiscalPeriod period,
  ) async {
    final theme = Theme.of(context);
    bool isRecomputing = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.calculate_outlined, size: 20),
              SizedBox(width: 8),
              Text('إعادة الاحتساب'),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRecomputing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جارٍ إعادة احتساب الأرصدة الافتتاحية...'),
                      ],
                    ),
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.tertiary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ما الذي ستقوم به إعادة الاحتساب؟',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. حذف أي سندات رصيد افتتاحي قديمة لهذه الفترة\n'
                          '2. إقفال هذه الفترة تلقائياً\n\n'
                          'ملاحظة: الرصيد ينتقل تراكمياً بين السنوات — '
                          'الخزينة صندوق نقدي مستمر لا يُصفَّر، فلا تُنشأ '
                          'سندات رصيد افتتاحي (كانت تُضاعف الرصيد).',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _InfoRow(
                    label: 'الفترة',
                    value: period.name,
                    icon: Icons.calendar_today,
                  ),
                  _InfoRow(
                    label: 'الحالة',
                    value: 'تحتاج إعادة احتساب',
                    icon: Icons.warning_amber_outlined,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (!isRecomputing)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
            if (!isRecomputing)
              FilledButton.icon(
                onPressed: () async {
                  setDialogState(() => isRecomputing = true);
                  await ref
                      .read(fiscalNotifierProvider.notifier)
                      .recomputeOpeningBalances(period.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('بدء إعادة الاحتساب'),
              ),
          ],
        ),
      ),
    );
  }
}

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
                            'الأرصدة الافتتاحية قديمة — تحتاج إعادة احتساب '
                            'بسبب تعديل في فترة سابقة',
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

                  // إعادة الاحتساب (super_admin فقط)
                  if (isPendingRecompute && isSuperAdmin)
                    FilledButton.icon(
                      onPressed: isOperating ? null : onRecompute,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.calculate_outlined, size: 16),
                      label: const Text('إعادة الاحتساب'),
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
