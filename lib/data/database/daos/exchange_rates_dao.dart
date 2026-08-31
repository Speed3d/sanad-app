// ─────────────────────────────────────────────────────────────────────────────
// exchange_rates_dao.dart — DAO أسعار الصرف
//
// يُدير سجل أسعار الصرف التاريخية بين العملات.
//
// كيفية الاستخدام:
//   1. عند فتح شاشة سند صرف/قبض → getLatestRate('USD','IQD') للسعر الحالي
//   2. عند تغيير سعر الصرف → insertRate() لحفظ السعر الجديد
//   3. في التقارير التاريخية → getRateForDate() لمعرفة السعر وقت السند
//
// ملاحظة مهمة:
//   كل سند يحتفظ بسعر الصرف الخاص به (vouchers.exchange_rate).
//   هذا الجدول يخدم الاستفسارات التاريخية فقط —
//   ليس المصدر الوحيد للحقيقة عند القراءة.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/exchange_rates_table.dart';

part 'exchange_rates_dao.g.dart';

/// DAO أسعار الصرف
@DriftAccessor(tables: [ExchangeRates])
class ExchangeRatesDao extends DatabaseAccessor<AppDatabase>
    with _$ExchangeRatesDaoMixin {
  ExchangeRatesDao(super.db);

  // ── استعلامات القراءة ────────────────────────────────────────────────────

  /// آخر سعر صرف فعّال بين عملتين
  ///
  /// [from] — العملة المصدر (مثال: 'USD')
  /// [to]   — العملة الهدف  (مثال: 'IQD')
  ///
  /// يُعيد null إذا لم يُدخَّل أي سعر بعد
    /// Reactive Stream لآخر سعر صرف — يتحدث فور تغييره
  ///
  /// يُستخدَم في شاشة الإعدادات لعرض السعر الحالي
    /// قيمة سعر الصرف الحالي كـ double — مختصر للاستخدام المتكرر
  ///
  /// يُعيد [defaultRate] إذا لم يوجد سعر مسجَّل
    /// سعر الصرف لتاريخ محدد — للتقارير التاريخية
  ///
  /// يجلب آخر سعر مسجَّل قبل أو في [date]
    /// سجل أسعار الصرف كاملاً — للاستعلام وعرض التاريخ
  ///
  /// مرتب من الأحدث للأقدم
    /// جميع أسعار الصرف المسجَّلة بغض النظر عن العملة — للمراجعة الكاملة
    // ── عمليات الكتابة ────────────────────────────────────────────────────────

  /// تسجيل سعر صرف جديد — يُعيد الـ ID المُولَّد
  ///
  /// كل تغيير في السعر يُحفَظ كسجل جديد (لا يُحدَّث القديم)
  /// هذا يحفظ التاريخ الكامل لأسعار الصرف.
  Future<int> insertRate(ExchangeRatesCompanion rate) {
    return into(exchangeRates).insert(rate);
  }

  /// تسجيل سعر صرف USD/IQD الشائع بسرعة
  ///
  /// [rate]          — القيمة (مثال: 1310.0 يعني 1 USD = 1310 IQD)
  /// [createdByUser] — معرّف المستخدم الذي غيّر السعر
  Future<int> setUsdToIqdRate(double rate, {int? createdByUser}) {
    return insertRate(
      ExchangeRatesCompanion.insert(
        fromCurrency: 'USD',
        toCurrency: 'IQD',
        rate: rate,
        effectiveDate: DateTime.now(),
        createdByUserId: Value(createdByUser),
      ),
    );
  }

  /// حذف سجل سعر صرف (للتصحيح فقط — Super Admin)
  ///
  /// تحذير: لا تحذف سجلاً إذا كانت توجد سندات تعتمد عليه
  }
