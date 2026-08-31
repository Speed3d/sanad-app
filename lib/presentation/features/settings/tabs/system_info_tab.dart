// ─────────────────────────────────────────────────────────────────────────────
// system_info_tab.dart — قسم معلومات النظام
//
// يعرض:
//   - إصدار التطبيق وتاريخ البناء
//   - إحصائيات قاعدة البيانات (عدد السندات، المستخدمين، إلخ)
//   - نسخة قاعدة البيانات (Schema Version)
//   - زر تسجيل الخروج مع تأكيد
//
// هذا القسم للعرض فقط — لا حفظ مطلوب
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/constants/app_settings_keys.dart';
import '../../../../core/services/factory_reset_service.dart';
import '../../../../core/utils/audit_logger.dart';
import '../../../../domain/models/auth_state.dart';
import '../../../../domain/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/settings_provider.dart';
import 'settings_shared.dart';

// ── Provider إحصائيات قاعدة البيانات ─────────────────────────────────────────

/// Provider لجلب إحصائيات قاعدة البيانات
final _dbStatsProvider = FutureProvider<_DbStats>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final settings = ref.watch(allSettingsProvider).valueOrNull ?? {};

  // جلب الإحصائيات بشكل متوازٍ
  final results = await Future.wait([
    db.usersDao.watchAllUsers().first,
    db.vouchersDao.getVouchersByDateRange(
      from: DateTime(2000),
      to: DateTime(2100),
    ),
    db.treasuriesDao.watchAllTreasuries().first,
    db.employeesDao.watchAllEmployees().first,
  ]);

  return _DbStats(
    usersCount: (results[0] as List).length,
    vouchersCount: (results[1] as List).length,
    treasuriesCount: (results[2] as List).length,
    employeesCount: (results[3] as List).length,
    schemaVersion: settings['db_schema_version'] ?? '1',
  );
});

class _DbStats {
  final int usersCount;
  final int vouchersCount;
  final int treasuriesCount;
  final int employeesCount;
  final String schemaVersion;

  const _DbStats({
    required this.usersCount,
    required this.vouchersCount,
    required this.treasuriesCount,
    required this.employeesCount,
    required this.schemaVersion,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// قسم معلومات النظام
// ─────────────────────────────────────────────────────────────────────────────

/// قسم معلومات النظام
class SystemInfoTab extends ConsumerWidget {
  const SystemInfoTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final currentUser =
        authState is AuthAuthenticated ? authState.user : null;
    final dbStatsAsync = ref.watch(_dbStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── عنوان القسم ────────────────────────────────────────────────────
          const SettingsSectionHeader(
            icon: Icons.info_outline,
            title: 'معلومات النظام',
            subtitle: 'إصدار التطبيق وإحصائيات قاعدة البيانات',
          ),

          const SizedBox(height: 24),

          // ── معلومات التطبيق ────────────────────────────────────────────────
          _InfoSection(
            title: 'التطبيق',
            children: [
              _InfoRow(label: 'اسم التطبيق', value: 'نظام إدارة المبيعات'),
              _InfoRow(label: 'الإصدار', value: '1.0.0'),
              _InfoRow(label: 'رقم البناء', value: '1'),
              _InfoRow(label: 'Flutter SDK', value: '3.35.6'),
              _InfoRow(label: 'Dart SDK', value: '3.9.2'),
            ],
          ),

          const SizedBox(height: 16),

          // ── إحصائيات قاعدة البيانات ───────────────────────────────────────
          Text(
            'إحصائيات قاعدة البيانات',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          dbStatsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('خطأ في تحميل الإحصائيات: $e'),
            ),
            data: (stats) => _InfoSection(
              title: '',
              showTitle: false,
              children: [
                _InfoRow(
                  label: 'نسخة الـ Schema',
                  value: 'الإصدار ${stats.schemaVersion}',
                ),
                _InfoRow(
                  label: 'المستخدمون',
                  value: '${stats.usersCount} حساب',
                ),
                _InfoRow(
                  label: 'السندات',
                  value: '${stats.vouchersCount} سند',
                ),
                _InfoRow(
                  label: 'الخزائن',
                  value: '${stats.treasuriesCount} خزينة',
                ),
                _InfoRow(
                  label: 'الموظفون',
                  value: '${stats.employeesCount} موظف',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── معلومات المستخدم الحالي ────────────────────────────────────────
          if (currentUser != null)
            _InfoSection(
              title: 'الجلسة الحالية',
              children: [
                _InfoRow(label: 'المستخدم', value: currentUser.fullName),
                _InfoRow(label: 'الدور', value: currentUser.roleDisplayName),
                _InfoRow(label: 'اسم الدخول', value: '@${currentUser.username}'),
                if (currentUser.lastLoginAt != null)
                  _InfoRow(
                    label: 'آخر دخول',
                    value: _formatDate(currentUser.lastLoginAt!),
                  ),
              ],
            ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // ── نسخ معلومات التشخيص ────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text: _buildDiagnosticsText(dbStatsAsync.valueOrNull),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ تم نسخ معلومات التشخيص')),
              );
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('نسخ معلومات التشخيص'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          const SizedBox(height: 12),

          // ── تصفير الحركة وحدها (للتطوير) ───────────────────────────────────
          // عملية كارثية — super_admin فقط عبر نظام الصلاحيات المركزي.
          // (كان الفحص `role == 'admin'` مقلوباً: يمنع super_admin ويسمح لـ admin)
          //
          // 📌 التسمية تقول ما تفعله بالضبط: هذا الزرّ يمحو **الحركة** ويُبقي
          //    المستخدمين والخزائن والموظفين. كان اسمه «تصفير الحسابات» وهو
          //    اسمٌ يوحي بأكثر مما يفعل — والزرّ الذي يفعل الأكثر تحته.
          if (currentUser != null &&
              currentUser.can(AppPermission.resetFinancialData)) ...[
            OutlinedButton.icon(
              onPressed: () => _confirmResetData(context, ref),
              icon: const Icon(Icons.cleaning_services_outlined),
              label: const Text('تصفير الحركة فقط (للتطوير)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(
                  color: theme.colorScheme.error.withValues(alpha: 0.5),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── 🔥 تصفير المصنع (للتطوير) ──────────────────────────────────────
          // أخطر زرّ في التطبيق: يمحو البرنامج كلّه ويعود لشاشة الإعداد الأول.
          // صلاحية مستقلّة عن سابقه عمداً — راجع AppPermission.factoryReset.
          if (currentUser != null &&
              currentUser.can(AppPermission.factoryReset)) ...[
            FilledButton.icon(
              onPressed: () => _confirmFactoryReset(context, ref),
              icon: const Icon(Icons.local_fire_department_outlined),
              label: const Text('تصفير المصنع — محو كل شيء (للتطوير)'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── تسجيل الخروج ───────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout_outlined),
            label: const Text('تسجيل الخروج'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  /// تأكيد تصفير الحسابات
  Future<void> _confirmResetData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصفير الحسابات'),
        content: const Text(
          'تحذير خطير: سيتم مسح جميع السندات المالية وتصفير أرصدة الخزائن بالكامل!\n\n'
          'هل أنت متأكد من هذا الإجراء؟ لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، مسح وتصفير'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(appDatabaseProvider);
      // نقرأ هوية المنفِّذ قبل العملية — بعدها قد تكون الشاشة أُغلقت
      final auth = ref.read(authNotifierProvider);
      final user = auth is AuthAuthenticated ? auth.user : null;
      try {
        final removed = await db.resetFinancialData();

        // ── توثيق العملية الكارثية في سجل التدقيق (إصلاح ث-١) ──────────
        // سجل التدقيق نفسه لا يُمسح في التصفير عمداً، فيبقى هذا السطر
        // الدليل الوحيد على أن بيانات كانت موجودة ومَن محاها.
        await ref.read(auditLoggerProvider).logFinancialDataReset(
              userId: user?.id ?? 0,
              username: user?.username ?? 'system',
              vouchersDeleted: removed.vouchers,
              periodsDeleted: removed.periods,
              advancesDeleted: removed.advances,
              payrollsDeleted: removed.payrolls,
            );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✓ تم التصفير — حُذف ${removed.vouchers} سند و'
                '${removed.periods} سنة مالية و${removed.advances} سلفة مشروع و'
                '${removed.payrolls} كشف رواتب',
              ),
            ),
          );
          // إعادة تحميل الإحصائيات
          ref.invalidate(_dbStatsProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: $e')),
          );
        }
      }
    }
  }

  // ── 🔥 تصفير المصنع ────────────────────────────────────────────────────────

  /// تأكيد وتنفيذ تصفير المصنع — كلمة المرور ورمز المحو ثم محو كل شيء
  ///
  /// الواجهة تجمع المدخلين فقط؛ **التحقّق المُلزِم في `FactoryResetService`**
  /// لا هنا — فحارسٌ في طبقة العرض يتجاوزه أي مستدعٍ آخر ولا يمرّ به اختبار
  /// (القانون ٤).
  Future<void> _confirmFactoryReset(BuildContext context, WidgetRef ref) async {
    final input = await showDialog<_FactoryResetInput>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _FactoryResetDialog(),
    );
    if (input == null) return;

    // هوية المنفِّذ تُقرأ **قبل** العملية — بعدها لا يبقى مستخدم في القاعدة
    final auth = ref.read(authNotifierProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    if (user == null) return;

    final db = ref.read(appDatabaseProvider);
    final authService = ref.read(authServiceProvider);

    // قراءة مباشرة من الـDAO لا من مزوّد عائلي: استعلام لمرّة واحدة لا يحتاج
    // مزوّداً، و`ref.read(p.future)` على مزوّد autoDispose يُسقط التطبيق (ع-٣٥)
    final root =
        await db.appSettingsDao.getString(AppSettingsKeys.attachmentsRoot) ?? '';

    try {
      final report = await FactoryResetService.run(
        db: db,
        auth: authService,
        user: user,
        password: input.password,
        purgeCode: input.purgeCode,
        attachmentsRoot: root,
        audit: ref.read(auditLoggerProvider),
      );

      // ── الجلسة ──────────────────────────────────────────────────────
      // جلسةٌ محفوظة تشير إلى مستخدم لم يعد موجوداً؛ إبقاؤها يعني أن التطبيق
      // يحاول استعادتها عند الإقلاع التالي ويفشل بلا تفسير.
      //
      // ⚠️ في `try` خاصّ به عمداً: القاعدة **مُحيت بنجاح** قبل هذا السطر،
      //    فلو رمى التخزين الآمن (قناة منصّة قد تفشل) لعرضنا «تعذّر التصفير»
      //    على عملية وقعت فعلاً — وهو أسوأ من الصمت: يدفع المالك لإعادة
      //    المحاولة على قاعدة نظيفة أصلاً.
      try {
        await authService.clearSession();
      } catch (_) {
        // الجلسة ستفشل استعادتها عند الإقلاع التالي فتُمسح تلقائياً
        // (الخطوة ٣ في AuthNotifier._initialize) — لا شيء يضيع.
      }

      if (!context.mounted) return;

      // ── الحصيلة في حوارٍ لا في شريط ────────────────────────────────
      // الشريط يختفي مع الشاشة لحظة تحويل الموجّه إلى «الإعداد الأول»، فلا
      // يقرأه المالك أصلاً. والحوار يُوقف الانتقال حتى يراه — وهو أقلّ ما
      // تستحقه عملية بلا تراجع.
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('✓ تم تصفير المصنع'),
          content: SizedBox(
            width: 420,
            child: Text(
              'مُحي نهائياً:\n'
              '• ${report.users} مستخدم\n'
              '• ${report.treasuries} خزينة · ${report.employees} موظف\n'
              '• ${report.vouchers} سند · ${report.periods} سنة مالية\n'
              '• ${report.advances} سلفة مشروع · ${report.payrolls} كشف رواتب\n'
              '• ${report.attachments} مرفق '
              '(${report.filesDeleted} ملف حُذف من القرص)\n\n'
              'التطبيق الآن نظيف تماماً. اضغط «ابدأ من جديد» للانتقال إلى '
              'شاشة الإعداد الأول وإنشاء حساب مدير النظام.',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ابدأ من جديد'),
            ),
          ],
        ),
      );

      // ── العودة لشاشة الإعداد الأول ──────────────────────────────────
      // `first_run_complete` عاد إلى false مع إعادة البذر، فـ`reinitialize`
      // تُنتج AuthUnauthenticated(isFirstRun: true) والموجّه يُحوّل تلقائياً.
      await ref.read(authNotifierProvider.notifier).reinitialize();
    } on StateError catch (e) {
      // رسائل الحُرّاس الثلاثة عربية جاهزة للعرض كما هي
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(e.message),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر تصفير المصنع: $e')),
        );
      }
    }
  }

  /// تأكيد تسجيل الخروج
  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من الحساب الحالي؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
      // GoRouter سيُعيد التوجيه تلقائياً لـ /login عبر redirect guard
    }
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// بناء نص معلومات التشخيص
  String _buildDiagnosticsText(_DbStats? stats) {
    return '''
نظام إدارة المبيعات — تقرير التشخيص
=====================================
الإصدار: 1.0.0 (بناء: 1)
Flutter: 3.35.6 | Dart: 3.9.2
قاعدة البيانات: Schema v${stats?.schemaVersion ?? 'N/A'}
المستخدمون: ${stats?.usersCount ?? 'N/A'}
السندات: ${stats?.vouchersCount ?? 'N/A'}
الخزائن: ${stats?.treasuriesCount ?? 'N/A'}
الموظفون: ${stats?.employeesCount ?? 'N/A'}
التاريخ: ${DateTime.now().toIso8601String()}
''';
  }
}

// ── مجموعة معلومات ────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool showTitle;

  const _InfoSection({
    required this.title,
    required this.children,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle && title.isNotEmpty) ...[
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: theme.colorScheme.outlineVariant,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── صف معلومة واحدة ───────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 🔥 حوار تصفير المصنع ─────────────────────────────────────────────────────
//
// عاملان إلزاميان بترتيب مقصود:
//   ١. **كلمة المرور** — تمنع من يجد الجهاز مفتوحاً وصاحبه غائب
//   ٢. **رمز المحو القسري** — عاملٌ ثانٍ لا يُكتب يومياً فلا يُرى ولا يُحفَظ
//      في مدير كلمات مرور. راجع purge_code_card.dart
//
// كلاهما يُتحقَّق في `FactoryResetService.run` لا هنا — الواجهة تجمع المدخلات
// فقط، والحرس الحقيقي في الطبقة التي لا يتجاوزها أحد بتعديل شاشة (القانون ٤).
//
// ⚠️ **بلا `TextEditingController`** — متغيّرات نصّية مع initialValue/onChanged.
//   المتحكّم المُتخلَّص منه بعد `await showDialog` سبّب شاشة حمراء في خمسة
//   مواضع (ع-٠٤)، ويحرسه `test/unit/dialog_controller_lifecycle_test.dart`.

/// مدخلا التصفير — يُعيدهما الحوار عند التأكيد
class _FactoryResetInput {
  const _FactoryResetInput({required this.password, required this.purgeCode});

  final String password;
  final String purgeCode;
}

class _FactoryResetDialog extends StatefulWidget {
  const _FactoryResetDialog();

  @override
  State<_FactoryResetDialog> createState() => _FactoryResetDialogState();
}

class _FactoryResetDialogState extends State<_FactoryResetDialog> {
  String _password = '';
  String _code = '';

  bool get _ready => _password.isNotEmpty && _code.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              'تصفير المصنع',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
      scrollable: true,
      content: SizedBox(
        width: 460,
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
              // القائمة صريحة عمداً: «كل شيء» كلمة يقرأها كلٌّ على هواه،
              // والمالك يستحق أن يعرف ما يفقده قبل الضغط لا بعده.
              child: Text(
                'سيُمحى كل شيء في البرنامج نهائياً ولا رجعة:\n\n'
                '• المستخدمون — بما فيهم حسابك أنت\n'
                '• الخزائن والمقاولون والشركاء\n'
                '• الموظفون وسلفهم وكشوف رواتبهم\n'
                '• السندات والسنوات المالية وسلف المشاريع\n'
                '• المرفقات وملفاتها على القرص\n'
                '• شعار الشركة وكل الإعدادات — ومنها رمز المحو نفسه\n'
                '• سجل التدقيق كاملاً — فلا يبقى أثر لشيء\n\n'
                'ثم يعود التطبيق إلى شاشة الإعداد الأول كأنه لم يُشغَّل قط.\n'
                'لا تستعيد شيئاً بعدها إلا نسخة احتياطية أُخذت قبل الآن.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 20),

            // ── ١. كلمة المرور ────────────────────────────────────────────
            TextFormField(
              initialValue: _password,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'كلمة مرورك',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.lock_outline, size: 18),
              ),
              onChanged: (v) => setState(() => _password = v),
            ),
            const SizedBox(height: 12),

            // ── ٢. رمز المحو القسري ──────────────────────────────────────
            TextFormField(
              initialValue: _code,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'رمز المحو القسري',
                helperText: 'الإعدادات ← الأمان ← رمز المحو القسري',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.key_outlined, size: 18),
              ),
              onChanged: (v) => setState(() => _code = v),
              onFieldSubmitted: (_) => _ready ? _submit() : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('تراجع'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: _ready ? _submit : null,
          child: const Text('امحُ كل شيء'),
        ),
      ],
    );
  }

  void _submit() => Navigator.pop(
        context,
        _FactoryResetInput(password: _password, purgeCode: _code),
      );
}
