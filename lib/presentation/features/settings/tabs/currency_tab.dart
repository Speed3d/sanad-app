// ─────────────────────────────────────────────────────────────────────────────
// currency_tab.dart — قسم العملة والأسعار
//
// يتيح للمستخدم:
//   - اختيار العملة الأساسية (IQD / USD) والثانوية
//   - إدخال سعر صرف الدولار مقابل الدينار العراقي
//
// الحفظ:
//   - repo.setString('primary_currency', code)
//   - repo.setString('secondary_currency', code)
//   - repo.setExchangeRate(rate) + db.exchangeRatesDao.setUsdToIqdRate(rate)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/permissions.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_settings_keys.dart';
import '../../../../core/utils/audit_logger.dart';
import '../../../../domain/models/auth_state.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/settings_provider.dart';
import 'settings_shared.dart';

// ── العملات المتاحة ───────────────────────────────────────────────────────────

const List<_CurrencyOption> _currencies = [
  _CurrencyOption(code: 'IQD', name: 'الدينار العراقي', symbol: 'د.ع'),
  _CurrencyOption(code: 'USD', name: 'الدولار الأمريكي', symbol: '\$'),
  _CurrencyOption(code: 'EUR', name: 'اليورو', symbol: '€'),
];

class _CurrencyOption {
  final String code;
  final String name;
  final String symbol;
  const _CurrencyOption({required this.code, required this.name, required this.symbol});
}

// ─────────────────────────────────────────────────────────────────────────────
// قسم العملة والأسعار
// ─────────────────────────────────────────────────────────────────────────────

/// قسم إعدادات العملة وسعر الصرف
class CurrencyTab extends ConsumerStatefulWidget {
  const CurrencyTab({super.key});

  @override
  ConsumerState<CurrencyTab> createState() => _CurrencyTabState();
}

class _CurrencyTabState extends ConsumerState<CurrencyTab> {
  final _rateCtrl = TextEditingController();
  final _rateFormKey = GlobalKey<FormState>();

  bool _isSaving = false;
  bool _rateLoaded = false;

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  /// تحميل سعر الصرف الحالي (مرة واحدة، فقط عند وصول القيمة الحقيقية)
  ///
  /// ⚠️ إصلاح H6 (تدقيق 2026-08-06): كان يُستدعى بالقيمة الاحتياطية 1310
  /// في إطار التحميل الأول فيلتصق بها، فيعرض 1310 حتى لو كان المحفوظ 1450،
  /// ثم الحفظ يدهس القيمة الحقيقية. الآن يُحمَّل فقط عند توفّر القيمة الفعلية.
  void _loadRate(double rate) {
    if (!_rateLoaded) {
      _rateCtrl.text = rate.toStringAsFixed(0);
      _rateLoaded = true;
    }
  }

  /// حفظ العملة الأساسية
  Future<void> _savePrimaryCurrency(String code) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setString(AppSettingsKeys.primaryCurrency, code);
  }

  /// حفظ العملة الثانوية
  Future<void> _saveSecondaryCurrency(String code) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setString(AppSettingsKeys.secondaryCurrency, code);
  }

  /// حفظ سعر الصرف
  Future<void> _saveExchangeRate() async {
    if (!_rateFormKey.currentState!.validate()) return;

    // 🔴 **فجوة أُغلقت (المرحلة ١٦ — 2026-08-30):** لم يكن على هذا الحقل أي
    //   فحص صلاحية، ومسار `/settings` بلا حاجز في الموجّه — فأيّ مستخدم
    //   مسجَّل كان يستطيع تغيير سعر الصرف.
    //
    //   وسعر الصرف ليس إعداداً كبقيّة الإعدادات: كل سند بالدولار يُثبَّت
    //   عليه سعرُ لحظته، فتغييره يُغيّر **قيمة كل ما يُدخَل بعده** في
    //   التقارير. وصلاحية `manageExchangeRate` كانت موجودة وبصفر مستدعٍ.
    final authState = ref.read(authNotifierProvider);
    final actor = authState is AuthAuthenticated ? authState.user : null;
    if (actor == null || !actor.can(AppPermission.manageExchangeRate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تغيير سعر الصرف متاح للمدير فما فوق.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final rate = double.parse(_rateCtrl.text.trim());
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(settingsRepositoryProvider);
      final db = ref.read(appDatabaseProvider);

      // القيمة السابقة قبل الكتابة — سطرُ تدقيقٍ بلا «من ماذا» يوثّق نصف
      // الحقيقة، ولا يُعرف منه هل ارتفع السعر أم انخفض.
      final previous = await repo.getString(AppSettingsKeys.exchangeRate);

      // حفظ في الإعدادات النصية
      await repo.setExchangeRate(rate);

      // حفظ سجل تاريخي في جدول exchange_rates
      await db.exchangeRatesDao.setUsdToIqdRate(rate);

      // ⚠️ كان تغيير سعر الصرف يقع **بلا أي أثر في سجل التدقيق**
      //   (`logSettingChanged` كانت بصفر مستدعٍ).
      await ref.read(auditLoggerProvider).logSettingChanged(
            userId: actor.id,
            username: actor.username,
            key: AppSettingsKeys.exchangeRate,
            oldValue: previous ?? '—',
            newValue: rate.toString(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ تم حفظ سعر الصرف: ${NumberFormat('#,###').format(rate)} د.ع / دولار',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final primaryCurr =
        ref.watch(primaryCurrencyProvider).valueOrNull ?? 'IQD';
    final secondaryCurr =
        ref.watch(secondaryCurrencyProvider).valueOrNull ?? 'USD';

    // نُحمّل الحقل فقط عند وصول القيمة الحقيقية من قاعدة البيانات (hasValue)،
    // لا في إطار التحميل حيث القيمة احتياطية — إصلاح H6.
    final rateAsync = ref.watch(exchangeRateProvider);
    if (rateAsync.hasValue) {
      _loadRate(rateAsync.value!);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── عنوان القسم ────────────────────────────────────────────────────
          const SettingsSectionHeader(
            icon: Icons.currency_exchange_outlined,
            title: 'العملة والأسعار',
            subtitle: 'العملات المستخدمة وسعر الصرف الحالي',
          ),

          const SizedBox(height: 32),

          // ── العملة الأساسية ────────────────────────────────────────────────
          Text(
            'العملة الأساسية',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'تُعرَض بها جميع المبالغ في السندات والتقارير',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            children: _currencies.map((c) {
              final isSelected = c.code == primaryCurr;
              return ChoiceChip(
                label: Text('${c.symbol}  ${c.code}  — ${c.name}'),
                selected: isSelected,
                onSelected: (_) => _savePrimaryCurrency(c.code),
                selectedColor: theme.colorScheme.primaryContainer,
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 20),

          // ── العملة الثانوية ────────────────────────────────────────────────
          Text(
            'العملة الثانوية',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'تُستخدم للعرض الجانبي وحسابات التحويل',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            children: _currencies
                .where((c) => c.code != primaryCurr)
                .map((c) {
              final isSelected = c.code == secondaryCurr;
              return ChoiceChip(
                label: Text('${c.symbol}  ${c.code}  — ${c.name}'),
                selected: isSelected,
                onSelected: (_) => _saveSecondaryCurrency(c.code),
                selectedColor: theme.colorScheme.primaryContainer,
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 20),

          // ── سعر الصرف ──────────────────────────────────────────────────────
          Text(
            'سعر صرف الدولار',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'يُستخدَم في تحويل المبالغ بين الدينار والدولار',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          Form(
            key: _rateFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _rateCtrl,
                  keyboardType: TextInputType.number,
                  enabled: !_isSaving,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'سعر الصرف',
                    hintText: 'مثال: 1310',
                    prefixIcon: Icon(Icons.attach_money),
                    suffixText: 'دينار / دولار',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'سعر الصرف مطلوب';
                    final rate = int.tryParse(v);
                    if (rate == null || rate < 100) {
                      return 'سعر الصرف يجب أن يكون 100 دينار على الأقل';
                    }
                    if (rate > 10000) return 'سعر الصرف مرتفع جداً';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveExchangeRate,
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
                    label: const Text('حفظ سعر الصرف'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── عرض السعر الحالي ───────────────────────────────────────────────
          _RateDisplay(rate: rateAsync.valueOrNull ?? 1310.0),
        ],
      ),
    );
  }
}

// ── عرض السعر الحالي ─────────────────────────────────────────────────────────

class _RateDisplay extends StatelessWidget {
  final double rate;
  const _RateDisplay({required this.rate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'السعر الحالي',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '1 دولار = ${fmt.format(rate)} دينار',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
