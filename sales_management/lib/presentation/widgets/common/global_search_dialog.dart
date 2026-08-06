// ─────────────────────────────────────────────────────────────────────────────
// global_search_dialog.dart — نافذة البحث الشامل للبرنامج
//
// تعليقات توضيحية بالعربية:
// هذا الملف يوفر نافذة بحث ذكية وسريعة تبحث عبر كافة بيانات النظام:
//   1. السندات (حسب الرقم، المستفيد، السبب، اسم المشروع، المبلغ)
//   2. الموظفون (حسب الاسم، الهاتف)
//   3. المقاولون (حسب الاسم، الهاتف، النوع)
//   4. الشركاء (حسب الاسم، الهاتف)
//   5. الخزائن (حسب الاسم، النوع)
//
// عند النقر على أي نتيجة يتم التوجيه الشفاف للشاشة المعنية.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../domain/models/contractor_model.dart';
import '../../../domain/models/employee_model.dart';
import '../../../domain/models/partner_model.dart';
import '../../../domain/models/treasury_model.dart';
import '../../../domain/models/voucher_model.dart';
import '../../providers/contractor_providers.dart';
import '../../providers/employee_providers.dart';
import '../../providers/partner_providers.dart';
import '../../providers/treasury_providers.dart';
import '../../providers/voucher_providers.dart';

/// عرض نافذة البحث الشامل
Future<void> showGlobalSearchDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const GlobalSearchDialog(),
  );
}

/// ويدجت نافذة البحث الشامل
class GlobalSearchDialog extends ConsumerStatefulWidget {
  const GlobalSearchDialog({super.key});

  @override
  ConsumerState<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends ConsumerState<GlobalSearchDialog> {
  /// وحدة التحكم بنص البحث
  final TextEditingController _searchController = TextEditingController();

  /// نص الاستعلام الحالي
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: context.isDesktop ? 700 : context.screenWidth * 0.9,
        height: 550,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── شريط إدخال البحث ──────────────────────────────────────────
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'ابحث عن سند، موظف، مقاول، شريك، أو خزينة...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                setState(() => _query = val.trimAndClean());
              },
            ),
            const SizedBox(height: 12),

            // ── نتائج البحث ───────────────────────────────────────────────
            Expanded(
              child: _query.isEmpty
                  ? _buildEmptyState(theme)
                  : _SearchResultsView(query: _query),
            ),
          ],
        ),
      ),
    );
  }

  /// حالة عدم كتابة استعلام
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.manage_search_rounded,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'اكتب كلمة البحث للوصول السريع',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'يمكنك البحث بأرقام السندات، الأسماء، الملاحظات أو أرقام الهواتف',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// عرض نتائج البحث المجمعة
class _SearchResultsView extends ConsumerWidget {
  const _SearchResultsView({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;

    // جلب البيانات من المصادر
    final vouchersAsync = ref.watch(searchVouchersProvider(query));
    final employees = ref.watch(allEmployeesProvider).valueOrNull ?? [];
    final contractors = ref.watch(allContractorsProvider).valueOrNull ?? [];
    final partners = ref.watch(allPartnersProvider).valueOrNull ?? [];
    final treasuries = ref.watch(treasuryBalancesProvider).valueOrNull ?? [];

    // تصفية الكيانات حسب استعلام البحث
    final matchedEmployees = employees.where((e) =>
        e.fullName.contains(query) || e.phone.contains(query)).toList();

    final matchedContractors = contractors.where((c) =>
        c.name.contains(query) || c.phone1.contains(query) || c.phone2.contains(query)).toList();

    final matchedPartners = partners.where((p) =>
        p.name.contains(query) || p.phone.contains(query)).toList();

    final matchedTreasuries = treasuries.where((t) =>
        t.treasuryName.contains(query)).toList();

    return vouchersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('خطأ أثناء البحث: $err')),
      data: (vouchers) {
        final totalResults = vouchers.length +
            matchedEmployees.length +
            matchedContractors.length +
            matchedPartners.length +
            matchedTreasuries.length;

        if (totalResults == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 8),
                Text(
                  'لم يتم العثور على نتائج تطابق "$query"',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView(
          children: [
            // ── السندات ───────────────────────────────────────────────────
            if (vouchers.isNotEmpty) ...[
              _buildCategoryHeader(context, 'السندات (${vouchers.length})', Icons.receipt_long),
              ...vouchers.take(5).map((v) => _VoucherResultTile(voucher: v)),
            ],

            // ── الموظفون ──────────────────────────────────────────────────
            if (matchedEmployees.isNotEmpty) ...[
              _buildCategoryHeader(context, 'الموظفون (${matchedEmployees.length})', Icons.people),
              ...matchedEmployees.map((e) => _EmployeeResultTile(employee: e)),
            ],

            // ── المقاولون ─────────────────────────────────────────────────
            if (matchedContractors.isNotEmpty) ...[
              _buildCategoryHeader(context, 'المقاولون (${matchedContractors.length})', Icons.construction),
              ...matchedContractors.map((c) => _ContractorResultTile(contractor: c)),
            ],

            // ── الشركاء ───────────────────────────────────────────────────
            if (matchedPartners.isNotEmpty) ...[
              _buildCategoryHeader(context, 'الشركاء (${matchedPartners.length})', Icons.handshake),
              ...matchedPartners.map((p) => _PartnerResultTile(partner: p)),
            ],

            // ── الخزائن ───────────────────────────────────────────────────
            if (matchedTreasuries.isNotEmpty) ...[
              _buildCategoryHeader(context, 'الخزائن (${matchedTreasuries.length})', Icons.account_balance_wallet),
              ...matchedTreasuries.map((t) => _TreasuryResultTile(treasury: t)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String title, IconData icon) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4, right: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const Expanded(child: Divider(indent: 8)),
        ],
      ),
    );
  }
}

// ── نتيجة البحث عن سند ───────────────────────────────────────────────────────
class _VoucherResultTile extends StatelessWidget {
  const _VoucherResultTile({required this.voucher});
  final VoucherModel voucher;

  @override
  Widget build(BuildContext context) {
    final isKabd = voucher.voucherType == 'kabd';
    final color = isKabd ? Colors.green.shade700 : Colors.red.shade700;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(
          isKabd ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          color: color,
          size: 18,
        ),
      ),
      title: Text('سند ${voucher.voucherType.toArabicVoucherType()} #${voucher.voucherNumber}'),
      subtitle: Text(voucher.reason.orDefault(voucher.personName)),
      trailing: Text(
        voucher.amount.toIQD(),
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
      onTap: () {
        Navigator.of(context).pop();
        context.go(AppRoutes.vouchers);
      },
    );
  }
}

// ── نتيجة البحث عن موظف ──────────────────────────────────────────────────────
class _EmployeeResultTile extends StatelessWidget {
  const _EmployeeResultTile({required this.employee});
  final EmployeeModel employee;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.person, size: 18),
      ),
      title: Text(employee.fullName),
      subtitle: Text(employee.phone.orDefault('بدون رقم هاتف')),
      trailing: Text(
        'الراتب: ${employee.basicSalary.toIQD()}',
        style: const TextStyle(fontSize: 12),
      ),
      onTap: () {
        Navigator.of(context).pop();
        context.go(AppRoutes.employees);
      },
    );
  }
}

// ── نتيجة البحث عن مقاول ─────────────────────────────────────────────────────
class _ContractorResultTile extends StatelessWidget {
  const _ContractorResultTile({required this.contractor});
  final ContractorModel contractor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.construction, size: 18),
      ),
      title: Text(contractor.name),
      subtitle: Text(contractor.phone1.orDefault(contractor.contractorType.toTitleCase())),
      onTap: () {
        Navigator.of(context).pop();
        context.go(AppRoutes.contractors);
      },
    );
  }
}

// ── نتيجة البحث عن شريك ──────────────────────────────────────────────────────
class _PartnerResultTile extends StatelessWidget {
  const _PartnerResultTile({required this.partner});
  final PartnerModel partner;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.handshake, size: 18),
      ),
      title: Text(partner.name),
      subtitle: Text(partner.phone.orDefault('شريك')),
      trailing: Text('${partner.sharePercentage}%'),
      onTap: () {
        Navigator.of(context).pop();
        context.go(AppRoutes.partners);
      },
    );
  }
}

// ── نتيجة البحث عن خزينة ─────────────────────────────────────────────────────
class _TreasuryResultTile extends StatelessWidget {
  const _TreasuryResultTile({required this.treasury});
  final TreasuryBalanceModel treasury;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.account_balance_wallet, size: 18),
      ),
      title: Text(treasury.treasuryName),
      subtitle: Text('خزينة ${treasury.treasuryKind.toArabicTreasuryKind()}'),
      trailing: Text(
        treasury.balanceIqd.toIQD(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: treasury.balanceIqd >= 0 ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        context.go(AppRoutes.treasury);
      },
    );
  }
}
