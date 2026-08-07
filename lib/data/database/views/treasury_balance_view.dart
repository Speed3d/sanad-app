// ─────────────────────────────────────────────────────────────────────────────
// treasury_balance_view.dart — VIEW لحساب أرصدة الخزائن
//
// هذا الـ VIEW هو "مصدر الحقيقة الوحيد" لأرصدة الخزائن.
// الأرصدة لا تُخزَّن في أي جدول — تُحسَب دائماً من السندات.
//
// لماذا VIEW وليس حقل مخزّن؟
//   ✓ يمنع أخطاء التناسق (inconsistency bugs) — الرقم المحسوب دائماً صحيح
//   ✓ عند تعديل سند قديم: الرصيد يتغير تلقائياً بدون أي كود إضافي
//   ✓ لا حاجة لتحديث رصيد منفصل عند كل عملية (INSERT/UPDATE/DELETE)
//
// معادلة الرصيد:
//   رصيد IQD = Σ(kabd + opening_balance حيث currency='IQD' وليس محذوف)
//             - Σ(sarf حيث currency='IQD' وليس محذوف)
//
//   رصيد USD = نفس المعادلة لكن currency='USD'
//
// SQL التوليدي (يُستخدَم في AppDatabase):
// ─────────────────────────────────────────────────────────────────────────────

/// SQL الخاص بـ VIEW أرصدة الخزائن
///
/// يُمرَّر مباشرة إلى AppDatabase كـ customStatement
/// لأن Drift لا يدعم CREATE VIEW بشكل كامل في الـ Tables API حتى الآن.
const String kCreateTreasuryBalancesView = '''
CREATE VIEW IF NOT EXISTS v_treasury_balances AS
SELECT
  t.id         AS treasury_id,
  t.name       AS treasury_name,
  t.kind       AS treasury_kind,
  t.entity_id  AS entity_id,
  t.entity_type AS entity_type,
  t.is_active  AS is_active,

  -- ── رصيد الدينار العراقي ──────────────────────────────────────────────
  COALESCE(
    SUM(
      CASE
        WHEN v.voucher_type IN ('kabd', 'opening_balance', 'transfer_in')
             AND v.currency = 'IQD'
             AND v.is_deleted = 0
        THEN v.amount
        ELSE 0
      END
    ), 0
  ) -
  COALESCE(
    SUM(
      CASE
        WHEN v.voucher_type IN ('sarf', 'transfer_out', 'opening_balance_debit')
             AND v.currency = 'IQD'
             AND v.is_deleted = 0
        THEN v.amount
        ELSE 0
      END
    ), 0
  ) AS balance_iqd,

  -- ── رصيد الدولار الأمريكي ────────────────────────────────────────────
  COALESCE(
    SUM(
      CASE
        WHEN v.voucher_type IN ('kabd', 'opening_balance', 'transfer_in')
             AND v.currency = 'USD'
             AND v.is_deleted = 0
        THEN v.amount
        ELSE 0
      END
    ), 0
  ) -
  COALESCE(
    SUM(
      CASE
        WHEN v.voucher_type IN ('sarf', 'transfer_out', 'opening_balance_debit')
             AND v.currency = 'USD'
             AND v.is_deleted = 0
        THEN v.amount
        ELSE 0
      END
    ), 0
  ) AS balance_usd,

  -- ── عدد السندات الكلي ────────────────────────────────────────────────
  COUNT(CASE WHEN v.is_deleted = 0 THEN 1 END) AS total_vouchers,

  -- ── آخر تحديث ─────────────────────────────────────────────────────────
  MAX(v.updated_at) AS last_voucher_date

FROM treasuries t
LEFT JOIN vouchers v ON v.treasury_id = t.id
WHERE t.is_deleted = 0
GROUP BY t.id, t.name, t.kind, t.entity_id, t.entity_type, t.is_active
''';

/// SQL لإسقاط الـ VIEW (عند الـ Migration)
const String kDropTreasuryBalancesView = '''
DROP VIEW IF EXISTS v_treasury_balances
''';

/// استعلام قراءة الـ VIEW بالكامل
const String kSelectTreasuryBalances = '''
SELECT * FROM v_treasury_balances
''';

/// استعلام قراءة رصيد خزينة واحدة
const String kSelectTreasuryBalance = '''
SELECT * FROM v_treasury_balances WHERE treasury_id = ?
''';
