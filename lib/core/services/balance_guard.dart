// ─────────────────────────────────────────────────────────────────────────────
// balance_guard.dart — حارس رصيد الخزينة عند الصرف
//
// الغرض:
//   فحص موحّد يمنع (أو يسمح) بصرف مبلغ يتجاوز رصيد الخزينة، حسب إعداد
//   المالك `enforce_balance_check`.
//
// السياسة (قابلة للتغيير من الإعدادات):
//   'true'  (الافتراضي) → منع باتّ: لا يمكن الصرف فوق الرصيد
//   'false'             → سماح: يُسمح بالرصيد المدين (خزينة سالبة)
//
// لماذا فحص موحّد؟
//   كشف تدقيق 2026-08-06 أنه لا يوجد أي فحص للرصيد في أي عملية صرف، فيمكن
//   صرف 10 مليون من خزينة فيها 500. كل عمليات الصرف (سند صرف، تحويل، راتب،
//   سلفة) تمرّ الآن عبر هذا الحارس.
// ─────────────────────────────────────────────────────────────────────────────

import '../../data/database/app_database.dart';
import '../constants/app_settings_keys.dart';
import '../utils/currency_formatter.dart';

/// حارس رصيد الخزينة
class BalanceGuard {
  const BalanceGuard._();

  /// يفحص كفاية الرصيد لعملية صرف
  ///
  /// [db]         — قاعدة البيانات
  /// [treasuryId] — الخزينة التي سيُخصم منها
  /// [currency]   — العملة ('IQD' أو 'USD')
  /// [amount]     — المبلغ المطلوب صرفه
  ///
  /// يُعيد: **رسالة خطأ عربية** إذا وجب الرفض، أو **null** إذا سُمح بالعملية
  /// (إما لأن الرصيد كافٍ، أو لأن المنع معطَّل من الإعدادات).
  static Future<String?> checkSufficientBalance(
    AppDatabase db, {
    required int treasuryId,
    required String currency,
    required double amount,
  }) async {
    // قراءة سياسة المنع — الافتراضي true (منع) حتى لو لم يوجد المفتاح
    final enforce = await db.appSettingsDao.getBool(
      AppSettingsKeys.enforceBalanceCheck,
      defaultValue: true,
    );
    if (!enforce) return null; // السماح بالرصيد المدين حسب إعداد المالك

    // قراءة رصيد الخزينة الحالي
    final balanceRow = await db.treasuriesDao.getTreasuryBalance(treasuryId);
    final available = currency == 'USD'
        ? (balanceRow?.balanceUsd ?? 0.0)
        : (balanceRow?.balanceIqd ?? 0.0);

    // مقارنة بهامش بسيط لتفادي أخطاء التقريب في الأعداد العشرية
    if (amount > available + 0.001) {
      final fmt = CurrencyFormatter.format(available, currency);
      return 'الرصيد غير كافٍ — المتاح في الخزينة: $fmt.\n'
          'يمكنك السماح بالرصيد المدين من الإعدادات إذا رغبت.';
    }
    return null;
  }
}
