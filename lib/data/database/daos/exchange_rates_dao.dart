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
  Future<ExchangeRate?> getLatestRate(String from, String to) {
    return (select(exchangeRates)
          ..where(
            (r) =>
                r.fromCurrency.equals(from) & r.toCurrency.equals(to),
          )
          ..orderBy([(r) => OrderingTerm.desc(r.effectiveDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Reactive Stream لآخر سعر صرف — يتحدث فور تغييره
  ///
  /// يُستخدَم في شاشة الإعدادات لعرض السعر الحالي
  Stream<ExchangeRate?> watchLatestRate(String from, String to) {
    return (select(exchangeRates)
          ..where(
            (r) =>
                r.fromCurrency.equals(from) & r.toCurrency.equals(to),
          )
          ..orderBy([(r) => OrderingTerm.desc(r.effectiveDate)])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// قيمة سعر الصرف الحالي كـ double — مختصر للاستخدام المتكرر
  ///
  /// يُعيد [defaultRate] إذا لم يوجد سعر مسجَّل
  Future<double> getLatestRateValue(
    String from,
    String to, {
    double defaultRate = 1310.0,
  }) async {
    final row = await getLatestRate(from, to);
    return row?.rate ?? defaultRate;
  }

  /// سعر الصرف لتاريخ محدد — للتقارير التاريخية
  ///
  /// يجلب آخر سعر مسجَّل قبل أو في [date]
  Future<ExchangeRate?> getRateForDate(
    String from,
    String to,
    DateTime date,
  ) {
    return (select(exchangeRates)
          ..where(
            (r) =>
                r.fromCurrency.equals(from) &
                r.toCurrency.equals(to) &
                r.effectiveDate.isSmallerOrEqualValue(date),
          )
          ..orderBy([(r) => OrderingTerm.desc(r.effectiveDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// سجل أسعار الصرف كاملاً — للاستعلام وعرض التاريخ
  ///
  /// مرتب من الأحدث للأقدم
  Future<List<ExchangeRate>> getRateHistory(
    String from,
    String to, {
    int limit = 100,
  }) {
    return (select(exchangeRates)
          ..where(
            (r) =>
                r.fromCurrency.equals(from) & r.toCurrency.equals(to),
          )
          ..orderBy([(r) => OrderingTerm.desc(r.effectiveDate)])
          ..limit(limit))
        .get();
  }

  /// جميع أسعار الصرف المسجَّلة بغض النظر عن العملة — للمراجعة الكاملة
  Future<List<ExchangeRate>> getAllRates({int limit = 200}) {
    return (select(exchangeRates)
          ..orderBy([(r) => OrderingTerm.desc(r.effectiveDate)])
          ..limit(limit))
        .get();
  }

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
  Future<void> deleteRate(int id) async {
    await (delete(exchangeRates)..where((r) => r.id.equals(id))).go();
  }
}
