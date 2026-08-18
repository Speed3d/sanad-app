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

  /// يفحص أثر **تعديل** سند قائم على رصيد الخزينة
  ///
  /// **لماذا دالة منفصلة؟** (إصلاح ح-٢ — تدقيق 2026-08-15)
  ///   [checkSufficientBalance] تصلح للإنشاء فقط: تفترض أن المبلغ كله خصم
  ///   جديد. عند التعديل يكون السند القديم **محسوباً أصلاً** في الرصيد، فلو
  ///   استعملناها لرفضت كل تعديل تقريباً.
  ///   وبدون أي فحص — وهو ما كان عليه الحال — يستطيع المستخدم تعديل سند صرف
  ///   من 100 ألف إلى 100 مليون فيمرّ بلا اعتراض وتصبح الخزينة سالبة رغم
  ///   تفعيل المنع. أي أن الحماية كانت مُلتَفّاً عليها من باب التعديل.
  ///
  /// **المعادلة:** الرصيد الناتج = الحالي − أثر السند القديم + أثر الجديد
  ///
  /// تغطّي الحالات الأربع:
  ///   • زيادة مبلغ سند صرف
  ///   • خفض مبلغ سند قبض بعد الصرف منه
  ///   • نقل السند إلى خزينة أخرى
  ///   • تغيير عملة السند
  ///
  /// [original]     — السند كما هو مخزَّن قبل التعديل
  /// [newTreasuryId] / [newCurrency] / [newAmount] — القيم بعد التعديل
  ///
  /// يُعيد **رسالة خطأ عربية** عند الرفض، أو **null** عند السماح.
  static Future<String?> checkEditImpact(
    AppDatabase db, {
    required Voucher original,
    required int newTreasuryId,
    required String newCurrency,
    required double newAmount,
  }) async {
    final enforce = await db.appSettingsDao.getBool(
      AppSettingsKeys.enforceBalanceCheck,
      defaultValue: true,
    );
    if (!enforce) return null; // السماح بالرصيد المدين حسب إعداد المالك

    /// إشارة السند في معادلة الرصيد: +1 للدائن، −1 للمدين
    int signOf(String type) {
      switch (type) {
        case 'kabd':
        case 'opening_balance':
        case 'transfer_in':
          return 1;
        default:
          return -1; // sarf | transfer_out | opening_balance_debit
      }
    }

    final sign = signOf(original.voucherType);

    // نجمع التغيّر الصافي لكل (خزينة، عملة) متأثرة. التعديل قد يمسّ اثنتين
    // إن نُقل السند لخزينة أخرى أو غُيّرت عملته.
    final deltas = <({int treasuryId, String currency}), double>{};

    void add(int treasuryId, String currency, double delta) {
      final key = (treasuryId: treasuryId, currency: currency);
      deltas[key] = (deltas[key] ?? 0) + delta;
    }

    // سحب أثر السند القديم، ثم إضافة أثر الجديد
    add(original.treasuryId, original.currency, -sign * original.amount);
    add(newTreasuryId, newCurrency, sign * newAmount);

    for (final entry in deltas.entries) {
      if (entry.value >= -0.001) continue; // لا نقصان — لا داعي للفحص

      final row = await db.treasuriesDao.getTreasuryBalance(entry.key.treasuryId);
      final current = entry.key.currency == 'USD'
          ? (row?.balanceUsd ?? 0.0)
          : (row?.balanceIqd ?? 0.0);

      final resulting = current + entry.value;
      if (resulting < -0.001) {
        final treasury =
            await db.treasuriesDao.getTreasuryById(entry.key.treasuryId);
        final name = treasury?.name ?? 'الخزينة';
        return 'هذا التعديل يجعل رصيد "$name" سالباً '
            '(${CurrencyFormatter.format(resulting, entry.key.currency)}).\n'
            'الرصيد الحالي: '
            '${CurrencyFormatter.format(current, entry.key.currency)}.\n'
            'يمكنك السماح بالرصيد المدين من الإعدادات إذا رغبت.';
      }
    }
    return null;
  }
}
