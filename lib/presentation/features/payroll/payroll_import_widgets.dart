// ─────────────────────────────────────────────────────────────────────────────
// payroll_import_widgets.dart — جزء من مكتبة `payroll_import_screen.dart`
//
// ودجتات المعالج: شريط الخطوات · لافتات التنبيه · شارات العدّ · بطاقة السطر.
// أصنافها **خاصة** (`_X`) ومرئية عبر المكتبة وحدها فلا تتسرّب إلى المشروع.
//
// **لماذا فُصلت؟** بلغ الملف الأصل ١٢٢٦ سطراً بعد إضافة تنبيه «مصروف سلفاً»،
// فتجاوز حدّ الـ١٢٠٠ الذي يحرسه `tech_debt_guard_test`. والحدّ ليس شكلياً:
// `employees_screen` بلغ ٢٤٨٩ سطراً قبل المرحلة د فصار تعديله عبئاً بذاته.
// ─────────────────────────────────────────────────────────────────────────────

part of 'payroll_import_screen.dart';

class _StepBar extends StatelessWidget {
  final int step;
  const _StepBar({required this.step});

  static const _labels = ['الملف', 'الوجهة', 'الأعمدة', 'المراجعة'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: i <= step ? colors.gold : colors.surface2,
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: i <= step ? colors.onGold : colors.subtext,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _labels[i],
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: i == step ? FontWeight.w800 : FontWeight.w500,
                color: i <= step ? colors.text : colors.subtext,
              ),
            ),
            if (i < _labels.length - 1)
              Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: colors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// شارة حالة السنة المالية للشهر المختار
///
/// تظهر في خطوتَي الوجهة والمراجعة معاً: الأولى لتوفير العمل، والثانية
/// لأن المالك قد يعود ويغيّر الشهر بعد التحليل.
class _FiscalCheckBanner extends ConsumerWidget {
  final int year;
  final int month;

  const _FiscalCheckBanner({required this.year, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final check = ref.watch(payrollMonthFiscalCheckProvider(year, month));

    return check.when(
      loading: () => const SizedBox(height: 4, child: LinearProgressIndicator()),
      error: (e, _) => _Banner(
        color: colors.danger,
        icon: Icons.error_outline_rounded,
        text: 'تعذّر فحص السنة المالية: $e',
      ),
      data: (result) {
        final problem = result.problem;
        if (problem == null) {
          return _Banner(
            color: Colors.green,
            icon: Icons.check_circle_outline_rounded,
            text: 'السنة المالية «${result.fiscalName}» مفتوحة وتغطّي '
                '${PayrollCalculator.periodLabel(year, month)} — '
                'الكشف قابل للبناء.',
          );
        }
        return _Banner(
          color: colors.danger,
          icon: Icons.event_busy_rounded,
          text: problem,
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _Banner({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Chip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: colors.subtext)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

/// بطاقة سطر في المراجعة — تعرض حالة المطابقة وتتيح البتّ فيها
/// نصّ تنبيه «مصروف سلفاً» — يذكر **المبلغ والتاريخ ورقم السند**
///
/// التنبيه بلا تاريخٍ ولا سند لا يُمكّن المالك من التحقّق، فيتحوّل إلى إزعاج
/// يُتجاهَل — وتنبيهٌ يُتجاهَل دائماً يُدرّب العين على تخطّي ما حوله.
String _paidBeforeText(PaidEmployeeInMonth paid, PaidVsFileComparison? cmp) {
  final money = NumberFormat('#,##0');
  final when = paid.paidAt == null
      ? ''
      : ' بتاريخ ${DateFormat('yyyy/MM/dd').format(paid.paidAt!.toLocal())}';
  final voucher =
      paid.voucherNumber == null ? '' : ' · سند صرف رقم ${paid.voucherNumber}';
  final base = 'راتبه عن هذا الشهر مصروفٌ سلفاً: '
      '${money.format(paid.netIqd)} د.ع$when$voucher.';

  // 🔑 **وهنا يُقال سبب الفرق** (بلاغ المالك 2026-08-26): بلا هذين السطرين
  //   يرى المالك رقماً في مكان آخر ولا يعرف من أين جاء — وتنبيهٌ يذكر رقماً
  //   بلا سببه يُدرّب العين على تخطّي ما حوله.
  if (cmp == null || !cmp.hasGap) return base;

  final direction = cmp.isOverpaid ? 'زيادة' : 'نقص';
  return '$base\n'
      'والملف يحسب له ${money.format(cmp.fileIqd)} د.ع '
      '(${cmp.fileDays} يوماً مقابل ${cmp.paidDays} يوماً مدفوعة) — '
      '$direction ${money.format(cmp.difference.abs())} د.ع.';
}

class _RowCard extends StatelessWidget {
  final _RowState state;
  final void Function(_RowDecision, int?) onDecision;

  const _RowCard({required this.state, required this.onDecision});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final money = NumberFormat('#,##0.##');
    final r = state.row;

    final (Color badgeColor, String badgeText) = switch (state.decision) {
      _RowDecision.link => (Colors.green, 'موظف مسجَّل'),
      _RowDecision.create => (Colors.blue, 'جديد — سيُنشأ'),
      _RowDecision.skip => (colors.subtext, 'مستبعَد'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: state.match.isAmbiguous &&
                  state.decision == _RowDecision.skip
              ? colors.gold
              : colors.border,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.employeeName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${r.rowLabel} · ${money.format(r.basicSalary)} '
            '${r.currency == PayrollCurrency.usd ? 'دولار' : 'د.ع'}'
            '${r.position.isNotEmpty ? ' · ${r.position}' : ''}'
            '${r.hireDate != null ? ' · تعيين ${DateFormat('yyyy/MM/dd').format(r.hireDate!)}' : ''}',
            style: TextStyle(fontSize: 12, color: colors.subtext),
          ),
          // ── سلفة قائمة على الموظف ───────────────────────────────
          if (state.pendingAdvance > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 15, color: Colors.deepPurple.shade300),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'عليه سلفة متبقّية '
                    '${NumberFormat('#,##0').format(state.pendingAdvance)} د.ع '
                    '— اخصمها من الكشف إن أردت (زرّ «اخصم السلفة» في سطره).',
                    style: TextStyle(
                        fontSize: 12, color: Colors.deepPurple.shade300),
                  ),
                ),
              ],
            ),
          ],
          // ── مصروف سلفاً ─────────────────────────────────────────
          if (state.alreadyPaid != null) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.purple.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_outlined,
                      size: 16, color: Colors.purple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _paidBeforeText(
                          state.alreadyPaid!, state.comparison),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.purple),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (state.match.reason != null) ...[
            const SizedBox(height: 8),
            Text(
              state.match.reason!,
              style: TextStyle(fontSize: 12, color: colors.gold),
            ),
          ],
          if (state.match.candidates.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final c in state.match.candidates)
                  OutlinedButton(
                    onPressed: () => onDecision(_RowDecision.link, c.employeeId),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: state.linkedEmployeeId == c.employeeId &&
                              state.decision == _RowDecision.link
                          ? colors.gold.withValues(alpha: 0.15)
                          : null,
                    ),
                    child: Text(
                      c.hireDate == null
                          ? c.fullName
                          : '${c.fullName} — ${DateFormat('yyyy/MM/dd').format(c.hireDate!)}',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => onDecision(_RowDecision.create, null),
                child: const Text('إنشاء موظف جديد',
                    style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => onDecision(_RowDecision.skip, null),
                child: Text('استبعاد',
                    style: TextStyle(fontSize: 12, color: colors.subtext)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
