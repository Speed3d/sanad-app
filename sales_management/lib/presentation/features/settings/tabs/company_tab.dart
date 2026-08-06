// ─────────────────────────────────────────────────────────────────────────────
// company_tab.dart — قسم بيانات الشركة
//
// يتيح للمستخدم:
//   - تعديل اسم الشركة (يظهر في السندات والتقارير)
//   - رفع شعار الشركة أو حذفه (PNG/JPEG — يُحفَظ في app_blobs)
//
// الحفظ:
//   - repo.setCompanyName() → جدول app_settings ('company_name')
//   - repo.setBlob()        → جدول app_blobs   ('company_logo')
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_settings_keys.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/settings_provider.dart';
import 'settings_shared.dart';

/// قسم بيانات الشركة
class CompanyTab extends ConsumerStatefulWidget {
  const CompanyTab({super.key});

  @override
  ConsumerState<CompanyTab> createState() => _CompanyTabState();
}

class _CompanyTabState extends ConsumerState<CompanyTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  bool _isSaving = false;
  bool _nameLoaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// تحميل الاسم الحالي من الإعدادات (يُنفَّذ مرة واحدة)
  void _loadCurrentName(String? name) {
    if (!_nameLoaded && name != null) {
      _nameCtrl.text = name;
      _nameLoaded = true;
    }
  }

  /// حفظ اسم الشركة
  Future<void> _saveName() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.setCompanyName(_nameCtrl.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ تم حفظ اسم الشركة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// اختيار شعار من معرض الصور ورفعه
  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isSaving = true);
    try {
      final bytes = await picked.readAsBytes();
      final mimeType =
          picked.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

      final repo = ref.read(settingsRepositoryProvider);
      // حفظ الشعار في جدول app_blobs
      await repo.setBlob(AppSettingsKeys.companyLogo, bytes, mimeType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ تم رفع الشعار')),
        );
        setState(() {}); // إعادة البناء لعرض الشعار الجديد
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في رفع الشعار: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // مراقبة اسم الشركة الحالي
    final companyNameAsync = ref.watch(companyNameProvider);
    companyNameAsync.whenData(_loadCurrentName);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── عنوان القسم ────────────────────────────────────────────────────
          const SettingsSectionHeader(
            icon: Icons.business_outlined,
            title: 'بيانات الشركة',
            subtitle: 'المعلومات التي تظهر في السندات والتقارير',
          ),

          const SizedBox(height: 24),

          // ── اسم الشركة ─────────────────────────────────────────────────────
          Text(
            'اسم الشركة',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'اسم الشركة',
                    hintText: 'مثال: شركة النجمة للتجارة',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'اسم الشركة مطلوب';
                    }
                    if (v.trim().length < 2) {
                      return 'الاسم يجب أن يكون حرفين على الأقل';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveName,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('حفظ الاسم'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // ── شعار الشركة ────────────────────────────────────────────────────
          Text(
            'شعار الشركة',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'يظهر في رأس السندات والتقارير (PNG أو JPEG، حد أقصى 512×512)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Column(
              children: [
                // منطقة الشعار
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _pickLogo,
                  icon: const Icon(Icons.upload_outlined),
                  label: const Text('اختر شعاراً'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
