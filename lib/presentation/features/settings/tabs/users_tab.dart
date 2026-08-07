// ─────────────────────────────────────────────────────────────────────────────
// users_tab.dart — قسم إدارة المستخدمين والصلاحيات
//
// العمليات المتاحة:
//   - عرض قائمة المستخدمين مع الأدوار والحالة
//   - إضافة مستخدم جديد (Dialog مع Form)
//   - تعديل دور مستخدم
//   - تفعيل / تعطيل حساب
//   - حذف ناعم (مع التحقق من بقاء super_admin واحد على الأقل)
//
// ملاحظة: تم استبدال RadioListTile.groupValue (deprecated في Flutter 3.32+)
//   بـ ListTile مع إشارة اختيار مرئية بديلاً أبسط ومتوافقاً
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/audit_logger.dart';
import '../../../../domain/models/auth_state.dart';
import '../../../../domain/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/repository_providers.dart';
import 'settings_shared.dart';

// ── أدوار المستخدمين المتاحة للتعيين ──────────────────────────────────────────

/// الأدوار التي يمكن تعيينها لمستخدم جديد (لا يمكن إنشاء super_admin من هنا)
const List<_RoleOption> _assignableRoles = [
  _RoleOption(value: 'admin', label: 'مدير النظام'),
  _RoleOption(value: 'accountant', label: 'محاسب'),
  _RoleOption(value: 'user', label: 'مستخدم عادي'),
];

class _RoleOption {
  final String value;
  final String label;
  const _RoleOption({required this.value, required this.label});
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider مؤقت لقائمة المستخدمين
// ─────────────────────────────────────────────────────────────────────────────

/// Provider داخلي لمراقبة قائمة المستخدمين تفاعلياً
final _allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(userRepositoryProvider).watchAllUsers();
});

// ─────────────────────────────────────────────────────────────────────────────
// قسم المستخدمين
// ─────────────────────────────────────────────────────────────────────────────

/// قسم إدارة المستخدمين
class UsersTab extends ConsumerWidget {
  const UsersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final UserModel? currentUser =
        authState is AuthAuthenticated ? authState.user : null;

    final canManage = currentUser?.isAdmin ?? false;
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;

    final usersAsync = ref.watch(_allUsersProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SettingsSectionHeader(
                    icon: Icons.manage_accounts_outlined,
                    title: 'المستخدمون',
                    subtitle: 'الحسابات والصلاحيات',
                  ),
                  if (!canManage) ...[
                    const SizedBox(height: 12),
                    _PermissionNotice(
                      message:
                          'عرض القائمة فقط — تحتاج صلاحية مدير للإدارة',
                    ),
                  ],
                ],
              ),
            ),
          ),

          usersAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('خطأ: $e')),
            ),
            data: (users) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  return _UserCard(
                    user: users[index],
                    canManage: canManage,
                    isSuperAdmin: isSuperAdmin,
                    currentUserId: currentUser?.id,
                    onToggleActive: (user) =>
                        _toggleActive(context, ref, user),
                    onEditRole: (user) =>
                        _showEditRoleDialog(context, ref, user),
                    onDelete: (user) =>
                        _showDeleteDialog(context, ref, user),
                  ).animate().fadeIn(delay: (index * 50).ms);
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showAddUserDialog(context, ref),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('إضافة مستخدم'),
            )
          : null,
    );
  }

  Future<void> _toggleActive(
      BuildContext context, WidgetRef ref, UserModel user) async {
    final repo = ref.read(userRepositoryProvider);
    if (user.isSuperAdmin && user.isActive) {
      final count = await repo.countActiveSuperAdmins();
      if (count <= 1) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يمكن تعطيل مدير النظام الأخير')),
          );
        }
        return;
      }
    }
    await repo.setActive(user.id, isActive: !user.isActive);
  }

  Future<void> _showEditRoleDialog(
      BuildContext context, WidgetRef ref, UserModel user) async {
    String selectedRole = user.role;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('تعديل دور: ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            // بديل عن RadioListTile.groupValue (deprecated في 3.32+)
            // نستخدم ListTile عادي مع أيقونة اختيار مرئية
            children: _assignableRoles.map((opt) {
              final isSelected = opt.value == selectedRole;
              return ListTile(
                title: Text(opt.label),
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? Theme.of(ctx).colorScheme.primary : null,
                ),
                onTap: () => setDialogState(() => selectedRole = opt.value),
                selected: isSelected,
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final repo = ref.read(userRepositoryProvider);
                await repo.updateUser(user.copyWith(role: selectedRole));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ تم تحديث الدور')),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(
      BuildContext context, WidgetRef ref, UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل تريد حذف حساب "${user.fullName}"؟\nهذا حذف ناعم — يمكن الاستعادة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(userRepositoryProvider);
      if (user.isSuperAdmin) {
        final count = await repo.countActiveSuperAdmins();
        if (count <= 1) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('لا يمكن حذف مدير النظام الأخير'),
              ),
            );
          }
          return;
        }
      }
      await repo.deleteUser(user.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ تم حذف ${user.fullName}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<void> _showAddUserDialog(
      BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddUserDialog(ref: ref),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// بطاقة مستخدم
// ─────────────────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final UserModel user;
  final bool canManage;
  final bool isSuperAdmin;
  final int? currentUserId;
  final void Function(UserModel) onToggleActive;
  final void Function(UserModel) onEditRole;
  final void Function(UserModel) onDelete;

  const _UserCard({
    required this.user,
    required this.canManage,
    required this.isSuperAdmin,
    required this.currentUserId,
    required this.onToggleActive,
    required this.onEditRole,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrentUser = user.id == currentUserId;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: CircleAvatar(
          backgroundColor: user.isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0] : '?',
            style: TextStyle(
              color: user.isActive
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.fullName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: user.isActive
                      ? null
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (isCurrentUser)
              Chip(
                label: const Text('أنا'),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                labelStyle: theme.textTheme.labelSmall,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '@${user.username}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _RoleBadge(role: user.role, label: user.roleDisplayName),
                const SizedBox(width: 8),
                _StatusBadge(isActive: user.isActive),
              ],
            ),
          ],
        ),
        trailing: canManage && !isCurrentUser
            ? PopupMenuButton<String>(
                onSelected: (action) {
                  switch (action) {
                    case 'toggle':
                      onToggleActive(user);
                    case 'edit_role':
                      onEditRole(user);
                    case 'delete':
                      onDelete(user);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: ListTile(
                      leading: Icon(
                        user.isActive
                            ? Icons.person_off_outlined
                            : Icons.person_outline,
                        size: 20,
                      ),
                      title: Text(
                        user.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب',
                      ),
                      dense: true,
                    ),
                  ),
                  if (!user.isSuperAdmin)
                    const PopupMenuItem(
                      value: 'edit_role',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined, size: 20),
                        title: Text('تغيير الدور'),
                        dense: true,
                      ),
                    ),
                  if (isSuperAdmin && !user.isSuperAdmin)
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, size: 20),
                        title: Text('حذف'),
                        dense: true,
                      ),
                    ),
                ],
              )
            : null,
      ),
    );
  }
}

// ── شارة الدور ────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String role;
  final String label;
  const _RoleBadge({required this.role, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (role) {
      'super_admin' => theme.colorScheme.error,
      'admin' => theme.colorScheme.primary,
      'accountant' => Colors.teal,
      _ => theme.colorScheme.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── شارة الحالة ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isActive
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.errorContainer)
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'نشط' : 'معطَّل',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.error,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// حوار إضافة مستخدم
// ─────────────────────────────────────────────────────────────────────────────

class _AddUserDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddUserDialog({required this.ref});

  @override
  ConsumerState<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // DropdownButtonFormField يستخدم initialValue بدلاً من value (منذ Flutter 3.33)
  String _selectedRole = 'accountant';
  bool _obscurePassword = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final userRepo = ref.read(userRepositoryProvider);
      final existing =
          await userRepo.getUserByUsername(_usernameCtrl.text.trim());
      if (existing != null) {
        setState(() {
          _errorMessage = 'اسم المستخدم موجود مسبقاً';
          _isSaving = false;
        });
        return;
      }

      final service = ref.read(authServiceProvider);
      final hash = await service.hashPassword(_passwordCtrl.text);

      final newUserId = await userRepo.createUser(
        username: _usernameCtrl.text.trim(),
        passwordHash: hash,
        fullName: _fullNameCtrl.text.trim(),
        role: _selectedRole,
      );

      // توثيق إنشاء المستخدم في سجل التدقيق (من أنشأ ومن أُنشئ وبأي دور)
      final admin = ref.read(authNotifierProvider.notifier).currentUser;
      if (admin != null) {
        await ref.read(auditLoggerProvider).logUserCreated(
              adminId: admin.id,
              adminUsername: admin.username,
              newUserId: newUserId,
              newUsername: _usernameCtrl.text.trim(),
              role: _selectedRole,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ تم إنشاء حساب ${_fullNameCtrl.text.trim()}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ في الإنشاء: $e';
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('إضافة مستخدم جديد'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _usernameCtrl,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'اسم المستخدم مطلوب';
                  if (v.trim().length < 3) return 'الحد الأدنى 3 أحرف';
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                    return 'أحرف إنجليزية وأرقام وشرطة سفلية فقط';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                  if (v.length < 6) return 'الحد الأدنى 6 أحرف';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // DropdownButtonFormField مع initialValue (بدلاً من value المهجور)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'الدور',
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                ),
                initialValue: _selectedRole,
                items: _assignableRoles
                    .map(
                      (opt) => DropdownMenuItem(
                        value: opt.value,
                        child: Text(opt.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedRole = v);
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                        color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('إنشاء'),
        ),
      ],
    );
  }
}

// ── إشعار الصلاحيات ───────────────────────────────────────────────────────────

class _PermissionNotice extends StatelessWidget {
  final String message;
  const _PermissionNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
