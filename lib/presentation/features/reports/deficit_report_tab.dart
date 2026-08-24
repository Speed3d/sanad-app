// ─────────────────────────────────────────────────────────────────────────────
// deficit_report_tab.dart — تقرير «المستحقات على الشركة» (ب-٢)
//
// السؤال الذي يجيب عنه: **كم على الشركة من ديون ولمن؟**
//
// التقرير قسمان متكاملان لا مكرّران:
//
//   ١. **الخزائن بالعجز** — رصيد سالب يعني أن الخزينة صُرف منها أكثر مما
//      فيها. هذا هو المبلغ الذي على الشركة تغطيته، مقروءاً من مصدر الحقيقة
//      الوحيد `v_treasury_balances`.
//
//   ٢. **من غطّى العجز** — الأسماء التي تدين لها الشركة فعلاً. حين تُعتمَد
//      سلفة بعجز يُطلَب اسم من دفع الفرق من ماله، وكان هذا الاسم مدفوناً
//      داخل سجلّ كل سلفة على حدة بلا تقرير يجمعه. فكان المالك يعرف أن هناك
//      عجزاً، ولا يعرف **لمن** يدين ولا **كم** لكلٍّ منهم.
//
// القسمان يقيسان الشيء نفسه من زاويتين، وقد لا يتطابقان: خزينة قد تكون
// سالبة لسبب غير السلف، وشخص قد يكون غطّى عجزاً في خزينة عادت موجبة بعده.
// لهذا نعرضهما منفصلين ولا نجمعهما في رقم واحد يُضلّل.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../providers/voucher_providers.dart';
import 'report_widgets.dart';

/// تبويب المستحقات — الخزائن بالعجز ومن تدين لهم الشركة
class DeficitReportTab extends ConsumerWidget {
  const DeficitReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0');

    final balancesAsync = ref.watch(allTreasuryBalancesProvider);
    final creditorsAsync = ref.watch(deficitCreditorsProvider);

    return balancesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (balances) {
        // العجز = رصيد سالب. الهامش 0.001 يتجنّب أخطاء تقريب الأعداد العشرية
        // فلا تظهر خزينة رصيدها −0.0000001 كأنها مدينة
        final deficitIqd =
            balances.where((b) => b.balanceIqd < -0.001).toList();
        final deficitUsd =
            balances.where((b) => b.balanceUsd < -0.001).toList();

        final totalIqd = deficitIqd.fold<double>(0, (a, b) => a + b.balanceIqd);
        final totalUsd = deficitUsd.fold<double>(0, (a, b) => a + b.balanceUsd);

        final creditors = creditorsAsync.valueOrNull ?? const [];
        final totalOwed =
            creditors.fold<double>(0, (a, c) => a + c.totalCovered);

        final nothingOwed =
            deficitIqd.isEmpty && deficitUsd.isEmpty && creditors.isEmpty;

        if (nothingOwed) {
          return const ReportPlaceholder(
            icon: Icons.verified_outlined,
            message: 'لا توجد مستحقات على الشركة\n'
                'كل الخزائن بأرصدة موجبة ولا عجز مغطّى غير مسدَّد',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── الملخّص ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ReportSummaryCard(
                    label: 'إجمالي عجز الخزائن',
                    // العملتان لا تُجمعان أبداً — تُعرَضان متجاورتين. جمعهما
                    // في رقم واحد يتطلّب سعر صرف «اليوم» فيتغيّر التقرير كلما
                    // تحرّك السعر، وهو ما لا يجوز في رقم دَين قائم.
                    value: totalUsd.abs() > 0.001
                        ? '${fmt.format(totalIqd.abs())} د.ع'
                            ' + ${fmt.format(totalUsd.abs())} \$'
                        : '${fmt.format(totalIqd.abs())} د.ع',
                    color: Colors.red.shade700,
                    icon: Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ReportSummaryCard(
                    label: 'مستحقّ لأشخاص',
                    value: '${fmt.format(totalOwed)} د.ع',
                    color: Colors.orange.shade800,
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ReportSummaryCard(
                    label: 'خزائن بالعجز',
                    value: '${deficitIqd.length + deficitUsd.length}',
                    color: theme.colorScheme.primary,
                    icon: Icons.account_balance_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── القسم ١: الخزائن بالعجز ────────────────────────────────
            _SectionHeader(
              icon: Icons.account_balance_wallet_outlined,
              title: 'الخزائن بالعجز',
              subtitle: 'رصيد سالب — صُرف منها أكثر مما فيها',
            ),
            const SizedBox(height: 8),

            if (deficitIqd.isEmpty && deficitUsd.isEmpty)
              _EmptySection(
                message: 'لا توجد خزينة برصيد سالب',
                theme: theme,
              )
            else ...[
              ...deficitIqd.map(
                (b) => _DeficitCard(
                  name: b.treasuryName,
                  amount: b.balanceIqd,
                  currency: 'د.ع',
                  vouchers: b.totalVouchers,
                ),
              ),
              ...deficitUsd.map(
                (b) => _DeficitCard(
                  name: b.treasuryName,
                  amount: b.balanceUsd,
                  currency: '\$',
                  vouchers: b.totalVouchers,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── القسم ٢: من تدين لهم الشركة ────────────────────────────
            _SectionHeader(
              icon: Icons.handshake_outlined,
              title: 'من تدين لهم الشركة',
              subtitle: 'غطّوا عجز سلف معتمدة من مالهم الخاص',
            ),
            const SizedBox(height: 8),

            creditorsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('خطأ: $e'),
              data: (list) {
                if (list.isEmpty) {
                  return _EmptySection(
                    message: 'لا يوجد عجز مغطّى في أي سلفة معتمدة',
                    theme: theme,
                  );
                }
                return Column(
                  children: list
                      .map((c) => _CreditorCard(
                            name: c.coveredBy,
                            amount: c.totalCovered,
                            advanceCount: c.advanceCount,
                          ))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            // تفسير الفرق بين القسمين — بدونه يظنّ القارئ أن أحدهما خطأ
            Card(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'الرقمان قد لا يتطابقان، وهذا طبيعي: خزينة قد تكون '
                        'سالبة لسبب غير السلف، وشخص قد يكون غطّى عجزاً في '
                        'خزينة عادت موجبة بعده. القسم الأول يقيس حال الخزائن '
                        'اليوم، والثاني يقيس ما لم يُسدَّد لأصحابه.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── مكوّنات العرض ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message, required this.theme});

  final String message;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              size: 16, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة خزينة بالعجز
class _DeficitCard extends StatelessWidget {
  const _DeficitCard({
    required this.name,
    required this.amount,
    required this.currency,
    required this.vouchers,
  });

  final String name;

  /// الرصيد السالب كما هو — نعرض قيمته المطلقة مع علامة «عجز» صريحة
  final double amount;
  final String currency;
  final int vouchers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0');
    final red = Colors.red.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: red.withValues(alpha: 0.1),
          child: Icon(Icons.trending_down, size: 17, color: red),
        ),
        title: Text(
          name,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$vouchers سند',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              // نعرض المطلق مع كلمة «عجز» بدل إشارة سالبة قد تُقرأ خطأً
              '${fmt.format(amount.abs())} $currency',
              style: TextStyle(fontWeight: FontWeight.bold, color: red),
            ),
            Text(
              'عجز',
              style: theme.textTheme.labelSmall?.copyWith(color: red),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة دائن — شخص غطّى عجزاً
class _CreditorCard extends StatelessWidget {
  const _CreditorCard({
    required this.name,
    required this.amount,
    required this.advanceCount,
  });

  final String name;
  final double amount;
  final int advanceCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0');
    final orange = Colors.orange.shade800;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: orange.withValues(alpha: 0.12),
          child: Icon(Icons.person_outline, size: 17, color: orange),
        ),
        title: Text(
          name,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          advanceCount == 1 ? 'سلفة واحدة' : '$advanceCount سلف',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${fmt.format(amount)} د.ع',
              style: TextStyle(fontWeight: FontWeight.bold, color: orange),
            ),
            Text(
              'مستحقّ له',
              style: theme.textTheme.labelSmall?.copyWith(color: orange),
            ),
          ],
        ),
      ),
    );
  }
}
