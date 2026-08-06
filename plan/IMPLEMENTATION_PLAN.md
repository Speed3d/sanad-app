# 📘 الخطة الشاملة النهائية — مشروع Sanad App

> **الإصدار**: v3.0 (نهائي بعد المراجعة الفنية)
> **التاريخ**: 2026-05-10
> **الحالة**: في انتظار المراجعة الأخيرة قبل البدء بـ Sprint 0
> **المعمارية المعتمدة**: Drift أولاً (Phase 1) → Supabase لاحقًا (Phase 3)

---

## سجل التغييرات (Changelog v2.0 → v3.0)

| # | التغيير | السبب |
|---|---|---|
| 1 | فصل الـ blobs (الشعار، الصور) في جدول `app_blobs` + استخدام OPFS على Web | تجنّب انتفاخ الإعدادات + أداء أفضل |
| 2 | **إلغاء أعمدة `balance_iqd` و `balance_usd`** من `treasuries` | منع كوارث محاسبية من حقول محسوبة مخزَّنة |
| 3 | إضافة SQL VIEW `v_treasury_balances` + جدول كاش `treasury_balance_cache` | source-of-truth حقيقي + أداء |
| 4 | إضافة جدول `voucher_sequences` لتوليد أرقام السندات atomically | منع race conditions |
| 5 | معالج إعادة فتح سنة مع **Cascade Lock + Cascade Recompute** | حل فجوة منطقية حقيقية |
| 6 | إعادة تسمية `employee_loans` → `cash_advances` + جدول `cash_advance_repayments` | تسمية صحيحة محاسبيًا + دعم السداد الجزئي |
| 7 | إضافة حالة `frozen_pending_recompute` للفترات المالية | دعم Cascade Lock |
| 8 | استبدال `google_fonts` بخطوط محلية كـ assets | لا حاجة لإنترنت + أسرع |
| 9 | تعديل النسخ التلقائي: افتراضي **6 ساعات + كل 50 سند** | أكثر معقولية من كل ساعة |
| 10 | **Partial indexes** على كل الجداول التي تحتوي `is_deleted` | أداء أفضل + DB أصغر |
| 11 | enum + lookup table لقيم `sub_type` | توثيق + ترجمة ديناميكية |
| 12 | استراتيجية ضغط Audit Log + سياسة احتفاظ 365 يوم + أرشفة | منع تضخم DB |
| 13 | قسم جديد "اختبارات انحدار الأرصدة" | كشف bugs خفية مبكرًا |
| 14 | خطة Excel benchmark + خطة احتياطية لـ syncfusion إن لزم | أداء استيراد آمن |
| 15 | قسم جديد "حسابات الأرصدة المحاسبية" | توثيق المنطق الحرج |
| 16 | إضافة CHECK constraints صارمة | حماية سلامة البيانات |

---

## فهرس

1. [ملخص تنفيذي](#1-ملخص-تنفيذي)
2. [القرارات المعمارية الحرجة](#2-القرارات-المعمارية-الحرجة)
3. [النطاق والقرارات الرئيسية](#3-النطاق-والقرارات-الرئيسية)
4. [هوية التطبيق والإعدادات العامة](#4-هوية-التطبيق-والإعدادات-العامة)
5. [اللغة والتوطين](#5-اللغة-والتوطين)
6. [نظام العملات وسعر الصرف](#6-نظام-العملات-وسعر-الصرف)
7. [الأدوار والصلاحيات (3 طبقات)](#7-الأدوار-والصلاحيات-3-طبقات)
8. [نظام الفترات المالية والغلق](#8-نظام-الفترات-المالية-والغلق)
9. [قاعدة البيانات الكاملة](#9-قاعدة-البيانات-الكاملة)
10. [حسابات الأرصدة المحاسبية](#10-حسابات-الأرصدة-المحاسبية)
11. [الوحدات (Modules)](#11-الوحدات-modules)
12. [النسخ الاحتياطي والتخزين السحابي](#12-النسخ-الاحتياطي-والتخزين-السحابي)
13. [استيراد وتصدير Excel](#13-استيراد-وتصدير-excel)
14. [سجل العمليات (Audit Log)](#14-سجل-العمليات-audit-log)
15. [معايير UI/UX](#15-معايير-uiux)
16. [حزمة التقنيات](#16-حزمة-التقنيات)
17. [هيكل المشروع](#17-هيكل-المشروع)
18. [خطة التنفيذ المرحلية](#18-خطة-التنفيذ-المرحلية)
19. [الاختبار](#19-الاختبار)
20. [النشر](#20-النشر)
21. [المراحل المستقبلية](#21-المراحل-المستقبلية)
22. [خارج النطاق](#22-خارج-النطاق)
23. [المخاطر والتخفيف منها](#23-المخاطر-والتخفيف-منها)
24. [مصطلحات](#24-مصطلحات)

---

## 1. ملخص تنفيذي

نظام **Sanad** هو تطبيق Flutter حديث يحلّ محلّ نظام `Sales_Managment` القديم (WinForms + SQL Server) في نطاق:
- الخزائن النقدية + سندات الصرف والقبض
- الموظفون + المقاولون + الشركاء
- التقارير وكشوف الحساب
- استيراد Excel + النسخ الاحتياطي
- نظام سنوات مالية كامل مع الغلق والفتح

### المعمارية المعتمدة (Phase 1)

```
┌──────────────────────────────────────────────┐
│   Flutter (Web + Android + iOS من نفس الكود)   │
├──────────────────────────────────────────────┤
│   Riverpod (State) + go_router (Routing)     │
├──────────────────────────────────────────────┤
│   Repositories (Interfaces)                   │
│   ↓                                            │
│   Drift (SQLite typesafe)                     │
├──────────────────────────────────────────────┤
│   Mobile: native sqlite3 (sqlite3_flutter_libs) │
│   Web: sqlite3 wasm + IndexedDB + OPFS        │
└──────────────────────────────────────────────┘
```

### المراحل المستقبلية

- **Phase 2**: تكامل Google Drive + OneDrive للنسخ الاحتياطي السحابي (OAuth)
- **Phase 3**: ترحيل لـ Supabase للمزامنة Real-time بين الأجهزة (تغيير طبقة Repository فقط)

---

## 2. القرارات المعمارية الحرجة

هذا القسم يوثّق القرارات الأهم التي اتُّفق عليها بعد المراجعة الفنية.

### 2.1 الأرصدة المحاسبية محسوبة لا مخزَّنة (CRITICAL)

❌ **رفضنا**: حقول `balance_iqd`, `balance_usd` كأعمدة في جدول `treasuries`
**السبب**: أي bug في transaction، أو crash بين تحديثين، أو استعادة جزئية → الرصيد يصبح خاطئًا ولن يُكتشف لشهور.

✅ **اعتمدنا**:
- **SQL VIEW** `v_treasury_balances` تحسب الرصيد دائمًا من السندات (source of truth)
- جدول كاش `treasury_balance_cache` للأداء فقط (غير ملزِم)
- إعادة حساب تلقائية عند: بدء التطبيق، استعادة نسخة، فتح/غلق سنة، يدويًا
- Sanity check دوري: لو فرق بين الكاش والـ VIEW > 0.01 → recompute فوري

### 2.2 توليد أرقام السندات Atomically

❌ **رفضنا**: `MAX(voucher_number) + 1` (race condition عند الإدخال المتزامن)

✅ **اعتمدنا**: جدول `voucher_sequences` + `UPDATE ... RETURNING` داخل transaction.

### 2.3 Cascade Lock عند إعادة فتح سنة

❌ **رفضنا**: السماح بإضافة سندات في السنوات اللاحقة أثناء إعادة فتح سنة سابقة

✅ **اعتمدنا**:
- إعادة فتح 2025 → تجميد تلقائي لـ 2026 و 2027 (`frozen_pending_recompute`)
- لا insert/update/delete على السنوات المجمَّدة (حتى للسوبر أدمن)
- بعد إعادة الغلق: cascade recompute لكل السنوات اللاحقة

### 2.4 Drift على Web — مقبول لحجم بياناتنا

**الحقيقة التقنية**:
- IndexedDB يدعم 60% من مساحة القرص في المتصفحات الحديثة → عشرات GB
- 50,000 سند خلال 10 سنوات = ~50-100 MB DB → في حدود مريحة جدًا
- WASM SQLite سرعته 50% من الأصلي → استعلامات < 100ms مع indexes صحيحة

**الإجراءات الإضافية**:
- ضغط النسخ الاحتياطية (gzip)
- المرفقات الكبيرة في **OPFS** بدل IndexedDB
- Backup incremental لاحقًا (مرحلة Phase 2)

### 2.5 الـ Blobs (الشعار، المرفقات) منفصلة

❌ **رفضنا**: تخزين الشعار Base64 في `app_settings`
**السبب**: يُحمَّل مع كل query على الإعدادات → بطء + ضغط ذاكرة

✅ **اعتمدنا**:
- جدول `app_blobs` منفصل
- على Mobile: ملف عادي في `applicationDocumentsDirectory/blobs/`
- على Web: **OPFS** (Origin Private File System — نظام ملفات حقيقي في المتصفح، أسرع 10× من IndexedDB)

### 2.6 الخطوط محلية (Bundled Assets)

❌ **رفضنا**: حزمة `google_fonts` (تنزّل runtime من النت)

✅ **اعتمدنا**: ضمّ Tajawal + Inter كـ assets في `pubspec.yaml`.

---

## 3. النطاق والقرارات الرئيسية

### 3.1 ملخص القرارات النهائية

| القرار | الاختيار |
|---|---|
| المنصات | Web + Mobile (Android/iOS) |
| Backend Phase 1 | SQLite محلي (Drift) — offline-first |
| Backend Phase 2 | + Google Drive + OneDrive backups (OAuth) |
| Backend Phase 3 | + Supabase (multi-device sync) |
| البداية | قاعدة فارغة + استيراد Excel |
| اللغات | عربي (افتراضي) + إنجليزي |
| التاريخ | ميلادي فقط |
| العملة الأساسية | الدينار العراقي (IQD) |
| العملة الثانوية | الدولار (USD) مع سعر صرف |
| الخزائن | موحَّدة بحقل `kind` |
| السندات | موحَّدة بحقل `voucher_type` |
| الأدوار | 3 طبقات: Super Admin / Admin / User |
| الفترات المالية | سنوية ميلادية — قابلة للتوسع شهري/ربعي |
| الانتقال بين السنين | سلس — أكثر من سنة نشطة في وقت واحد |
| إعادة فتح سنة | Super Admin فقط + Cascade Lock |
| النسخ الاحتياطي | محلي + سحابي + تشفير AES-256-GCM |
| تكرار النسخ التلقائي | كل 6 ساعات + بعد كل 50 سند |
| نسخة قبل عمليات حساسة | تلقائية إن النسخ التلقائي ON، يسأل إن OFF |
| Branding | قابل للتخصيص بالكامل |
| الأرصدة | محسوبة من VIEW، لا مخزَّنة |
| توليد أرقام السندات | Atomic via voucher_sequences |
| الخطوط | محلية (Tajawal + Inter) |

### 3.2 ما داخل النطاق (In Scope)

✅ تسجيل الدخول
✅ إدارة المستخدمين والصلاحيات (3 أدوار)
✅ هوية الشركة (Branding) قابلة للتخصيص
✅ الموظفون + سُلَفهم النقدية + مرتباتهم
✅ المقاولون + خزائنهم + سنداتهم
✅ الشركاء + خزائنهم + سنداتهم
✅ الخزائن (موحَّدة) + إيداع/سحب/تحويل/تحويل عملة
✅ سند صرف بكل التفاصيل
✅ سند قبض بكل التفاصيل
✅ كشوف الحساب الشاملة + التقارير
✅ استيراد Excel
✅ تصدير Excel
✅ النسخ الاحتياطي والاستعادة (محلي + سحابي)
✅ نظام السنوات المالية والغلق + إعادة الفتح بـ Cascade
✅ سجل العمليات (Audit Log)
✅ تعدد العملات + سعر الصرف + سجل تغييرات السعر
✅ تعدد اللغات (عربي/إنجليزي)
✅ الإعدادات الشاملة

### 3.3 ما خارج النطاق

❌ المنتجات / المخزون
❌ العملاء
❌ الموردون
❌ المشتريات
❌ المبيعات
❌ المرتجعات
❌ الضرائب
❌ طباعة الباركود
❌ Crystal Reports

---

## 4. هوية التطبيق والإعدادات العامة

### 4.1 هوية الشركة (Branding)

قسم في الإعدادات يضبط الهوية، تُطبَّق تلقائيًا في:
- شاشة تسجيل الدخول
- AppBar + Drawer
- ترويسة كل تقرير وكل Excel export
- ترويسة طباعة كل سند

#### الحقول

| الحقل | النوع | إلزامي |
|---|---|---|
| اسم التطبيق | نص | ✅ |
| اسم الشركة | نص | ✅ |
| الشعار | صورة PNG/JPG | ❌ |
| الشعار النصي (Tagline) | نص قصير | ❌ |
| العنوان | نص متعدد الأسطر | ❌ |
| هاتف 1 / هاتف 2 | نص | ❌ |
| البريد الإلكتروني | نص | ❌ |
| الموقع الإلكتروني | نص | ❌ |
| الرقم الضريبي / السجل التجاري | نص | ❌ |

#### تخزين الشعار (مُحدَّث v3.0)

- **النصوص** في `app_settings` (key/value)
- **الشعار** في جدول `app_blobs` كمرجع لملف:
  - **Mobile**: ملف فعلي في `applicationDocumentsDirectory/blobs/logo.png`
  - **Web**: ملف فعلي في **OPFS** (`/blobs/logo.png`)
- جدول `app_blobs` يحفظ metadata فقط (path, mime_type, size, hash)
- **الفائدة**: الـ blob لا يُحمَّل مع query `app_settings`

---

## 5. اللغة والتوطين

### 5.1 اللغات
- **العربية** (افتراضية) — RTL
- **الإنجليزية** — LTR

### 5.2 آلية التوطين
- ملفات ARB: `lib/core/localization/arb/app_ar.arb` + `app_en.arb`
- استخدام `flutter_localizations` + `intl` + `flutter gen-l10n`
- **جميع النصوص** مستخرَجة (لا hardcoded)
- التبديل من زر في الإعدادات أو شاشة الدخول
- اللغة المحفوظة في `app_settings`
- الاتجاه يتبدّل تلقائيًا

### 5.3 التواريخ والأرقام
- التاريخ ميلادي فقط
- العرض:
  - عربي: `DD/MM/YYYY`
  - إنجليزي: `MMM DD, YYYY`
- التخزين: ISO 8601 (`YYYY-MM-DD HH:mm:ss`)
- الأرقام: عربية شرقية أو غربية (إعداد المستخدم)

---

## 6. نظام العملات وسعر الصرف

### 6.1 العملات
- **IQD** (افتراضية) | **USD** (ثانوية)

### 6.2 سعر الصرف
- حقل في الإعدادات: 1 USD = X IQD
- قابل للتعديل (يحتاج صلاحية `manage_exchange_rate`)
- كل تغيير يُسجَّل في `exchange_rate_history`

### 6.3 التخزين التاريخي ⭐
كل سند يخزّن:
- `amount` — كما أُدخل
- `currency` — IQD/USD
- `exchange_rate` — السعر **وقت الإدخال** (snapshot)
- `amount_iqd` — محسوب وقت الإدخال

**النتيجة**: التقارير التاريخية تبقى دقيقة حتى لو تغيّر السعر.

### 6.4 خيارات العرض في التقارير
- العملة الأصلية
- مُحوَّل لـ IQD (تاريخي)
- مُحوَّل لـ USD (تاريخي)
- مُحوَّل بسعر اليوم (تحليلي)

### 6.5 شاشة "تحويل عملة"
- داخل خزنة واحدة
- المبلغ + العملة الأصلية → الهدف
- سعر صرف لهذه العملية (افتراضي السعر الحالي، قابل للتعديل)
- يسجَّل كسند نوع `currency_exchange`

---

## 7. الأدوار والصلاحيات (3 طبقات)

### 7.1 🔱 Super Admin
- **واحد افتراضيًا** عند أول تشغيل
- صلاحيات **مطلقة**
- يستطيع:
  - كل ما يستطيعه Admin و User
  - **إعادة فتح سنة مالية مغلقة**
  - **تعديل/حذف سندات في سنة مالية مغلقة**
  - إنشاء وحذف Admins
  - **إنشاء سوبر أدمنز إضافيين**
  - **حذف سوبر أدمنز آخرين** (لا يستطيع حذف نفسه)
  - الوصول لسجل العمليات الكامل
  - تجاوز أي صلاحية أخرى
- **قاعدة "آخر سوبر أدمن"**: يجب أن يبقى **سوبر أدمن واحد على الأقل**
  - النظام يمنع حذف/تعطيل/تغيير دور آخر سوبر أدمن
  - رسالة: "لا يمكن حذف آخر سوبر أدمن. أنشئ سوبر أدمن آخر أولًا."

### 7.2 👑 Admin
- يُنشأ من قِبل Super Admin
- يستطيع:
  - إدارة المستخدمين العاديين
  - إدارة الصلاحيات للمستخدمين
  - إدارة الإعدادات
  - إدارة النسخ الاحتياطي
  - الوصول لكل البيانات في السنوات المفتوحة
  - **لا** يستطيع المساس بسنة مغلقة
  - **لا** يستطيع إدارة Super Admin

### 7.3 👤 User — مصفوفة الصلاحيات

| الصلاحية | الوصف |
|---|---|
| `manage_employees` | إدارة موظفين |
| `manage_contractors` | إدارة مقاولين |
| `manage_partners` | إدارة شركاء |
| `manage_treasuries` | إدارة خزائن |
| `manage_categories` | إدارة تصنيفات |
| `voucher_sarf_create` | إنشاء سند صرف |
| `voucher_sarf_edit` | تعديل سند صرف |
| `voucher_sarf_delete` | حذف سند صرف |
| `voucher_kabd_create` | إنشاء سند قبض |
| `voucher_kabd_edit` | تعديل سند قبض |
| `voucher_kabd_delete` | حذف سند قبض |
| `treasury_transfer` | تحويل بين خزائن |
| `currency_exchange` | تحويل عملة |
| `advance_create` | إنشاء سُلفة نقدية |
| `salary_pay` | دفع مرتبات |
| `view_reports` | الوصول للتقارير |
| `export_excel` | تصدير Excel |
| `import_excel` | استيراد Excel |
| `view_dashboard` | الوصول للوحة المعلومات |
| `view_audit_log` | قراءة Audit Log |

### 7.4 صلاحيات حصرية (لا تُمنح للـ User)
- إدارة المستخدمين (Admin/Super Admin فقط)
- النسخ الاحتياطي والاستعادة
- تغيير الإعدادات الجوهرية
- تغيير سعر الصرف (`manage_exchange_rate`)
- غلق فترة مالية (`close_fiscal_period`)
- إعادة فتح فترة مغلقة (Super Admin فقط)
- تعديل/حذف في فترة مغلقة (Super Admin فقط)

---

## 8. نظام الفترات المالية والغلق

### 8.1 المفهوم العام
نستخدم تجريد **"الفترة المالية" (Fiscal Period)** بدلًا من "السنة المالية" حصرًا — قابل للتوسع المستقبلي:
- سنوي (الآن — افتراضي)
- ربع سنوي (مستقبلًا)
- شهري (مستقبلًا)
- مخصص (مستقبلًا)

التحويل المستقبلي = **إعداد فقط، بدون migration، بدون مشاكل**.

### 8.2 الإعدادات الافتراضية
- `fiscal_period_type` = `yearly`
- `fiscal_year_start_month` = `1` (يناير)
- `fiscal_year_start_day` = `1`
- `multiple_active_periods_allowed` = `true`

### 8.3 حالات الفترة المالية (`status`)

| الحالة | الوصف |
|---|---|
| `active` | نشطة، يُسمح بالـ CRUD |
| `closed` | مغلقة، قراءة فقط (إلا للسوبر أدمن) |
| `archived` | مؤرشَفة (تم تصديرها لملف منفصل) |
| `frozen_pending_recompute` | **مجمَّدة** — لا insert/update/delete (إلا للسوبر أدمن في وضع reopen) |
| `reopening` | في وضع إعادة فتح (مؤقت) |

### 8.4 سيناريو "الانتقال السلس" بين السنين

#### في 31 ديسمبر 2026
- 2026 = `active`
- سند 28 ديسمبر 2026 → يدخل في 2026

#### في 1 يناير 2027 (تلقائي)
- النظام يُنشئ 2027 = `active` (لأن `fiscal_year_start = 01-01`)
- الآن **سنتان نشطتان**: 2026 + 2027
- سند 5 يناير 2027 → يدخل في 2027
- سند 30 ديسمبر 2026 (تسوية) → يدخل في 2026 (لا تزال active)

#### في فبراير 2027 — قرار غلق 2026
- معالج غلق السنة → الفحص → النسخة الاحتياطية → التنفيذ
- 2026 → `closed` (قراءة فقط)
- 2027 → الوحيدة `active`

### 8.5 السندات الافتتاحية

عند غلق سنة، تُولَّد سندات افتتاحية في السنة التالية لكل:
- خزنة (رصيد ختامي → رصيد افتتاحي)
- خزنة مقاول
- خزنة شريك
- سُلَف نقدية غير مسددة

السندات الافتتاحية:
- `voucher_type = 'opening_balance'`
- `voucher_number = OB-2027-NNNNN`
- تاريخ: 1 يناير من السنة الجديدة
- **محمية** من التعديل (إلا للسوبر أدمن)
- مميَّزة بصريًا في كشف الحساب

### 8.6 معالج غلق السنة (Wizard 5 مراحل)

#### المرحلة 1: الاختيار
- اختر سنة من النشطة
- يجب أن تكون نهايتها قد مرّت

#### المرحلة 2: الفحص الذكي
يفحص النظام:
- ✅ كل السندات لها أرصدة سليمة
- ⚠️ سُلَف نقدية غير مسددة (تُرحَّل)
- ⛔ سندات بتواريخ خارج النطاق (يجب إصلاحها أولًا)
- ⚠️ خزائن برصيد سالب
- ⚠️ سندات بدون صنف
- ⛔ أي اختلال في الأرصدة (sanity check بين VIEW والكاش)

إن وُجد ⛔ → يُمنع المتابعة.

#### المرحلة 3: معاينة الترحيل
جدول يعرض:
- لكل خزنة: الرصيد الختامي IQD + USD + السند الافتتاحي المُقترح
- لكل موظف لديه سلفة غير مسددة: المبلغ والترحيل المُقترح

#### المرحلة 4: التأكيد + النسخة الاحتياطية
- إن النسخ التلقائي ON → نسخة تلقائية silent
- إن OFF → سؤال "نأخذ نسخة قبل المتابعة؟"
- تأكيد نهائي بكتابة كلمة "نعم"

#### المرحلة 5: التنفيذ (داخل transaction واحدة)
1. snapshot الأرصدة في `fiscal_periods.closing_balances_json`
2. `vouchers.is_locked = 1` لكل سندات السنة
3. توليد سندات `opening_balance` في السنة الجديدة (عبر `voucher_sequences`)
4. ترحيل سُلَف غير مسددة للسنة الجديدة
5. `fiscal_periods.status = 'closed'`
6. تسجيل العملية في `audit_log`
7. recompute الكاش للأرصدة

### 8.7 معالج إعادة فتح سنة (Super Admin) — مُحدَّث v3.0

**سيناريو الكارثة المحتملة:**
- 2025 مغلقة، أرصدتها = أرصدة 2026 الافتتاحية
- 2026 مغلقة، أرصدتها = أرصدة 2027 الافتتاحية
- 2027 نشطة وفيها سندات
- السوبر أدمن يُعيد فتح 2025 ويُعدِّل
- → الأرصدة الافتتاحية في 2026 و 2027 تصبح خاطئة

**الحل: Wizard بـ 4 مراحل + Cascade Lock + Cascade Recompute**

#### المرحلة 1: تحذير وتفسير
شاشة بتحذيرات قوية:
- "إعادة فتح 2025 ستُجمِّد 2026 و 2027 حتى تكتمل"
- "ستُعاد معالجة الأرصدة الافتتاحية لكل السنوات اللاحقة"
- "العملية ستُسجَّل في Audit Log بشكل دائم"

#### المرحلة 2: قفل تتابعي تلقائي + نسخة احتياطية إجبارية
- نسخة احتياطية تلقائية إجبارية
- النظام يحوّل:
  - 2025: `closed` → `reopening`
  - 2026: `closed` → `frozen_pending_recompute`
  - 2027: `active` → `frozen_pending_recompute`
- في الوضع `frozen`: **لا insert/update/delete** على هذه السنوات (حتى للسوبر أدمن)
- مؤشّر بصري واضح في الواجهة لكل سنة مجمَّدة
- `vouchers.is_locked = 0` فقط للسنة 2025

#### المرحلة 3: التعديلات
- السوبر أدمن يعدّل/يحذف/يضيف سندات في 2025
- 2026 و 2027 مجمَّدتان لا يمكن المساس بهما
- زر "إكمال إعادة الفتح" متاح في كل وقت

#### المرحلة 4: إعادة الغلق + Cascade Recompute
- نسخة احتياطية ثانية إجبارية
- داخل transaction واحدة:
  1. حساب closing_balances الجديدة لـ 2025
  2. حذف opening_balance vouchers في 2026
  3. توليد opening_balance vouchers جديدة في 2026 (بنفس voucher_sequences)
  4. حساب closing_balances الجديدة لـ 2026
  5. حذف opening_balance vouchers في 2027
  6. توليد opening_balance vouchers جديدة في 2027
  7. تحديث الحالات:
     - 2025: `reopening` → `closed`
     - 2026: `frozen_pending_recompute` → `closed`
     - 2027: `frozen_pending_recompute` → `active`
  8. recompute كاش الأرصدة لكل الخزائن
  9. audit log مفصل لكل خطوة

### 8.8 التقارير عبر السنين
- زر "اختيار السنة" في كل التقارير (افتراضي: النشطة)
- خيار "كل السنين" (lifetime view)
- مقارنة بين سنوات (مرحلة لاحقة)

---

## 9. قاعدة البيانات الكاملة

### 9.1 ملاحظات تصميمية

- **SQLite** عبر **Drift** (typesafe + migrations + reactive)
- جميع الجداول: `created_at`, `updated_at` (auto-managed)
- الجداول المهمة: `is_deleted INTEGER DEFAULT 0` (soft delete)
- Foreign keys مُفعَّلة (`PRAGMA foreign_keys = ON`)
- **Partial indexes** على الأعمدة المستخدمة في البحث/الفلترة (`WHERE is_deleted = 0`)
- جميع الاستعلامات parameterized
- التاريخ يُخزَّن بـ ISO 8601
- **CHECK constraints** صارمة لحماية سلامة البيانات

### 9.2 قائمة الجداول (20 جدولًا في v3.0)

#### إعدادات النظام
1. `app_settings` — Key/Value
2. `app_blobs` — مرفقات النظام (الشعار)

#### المستخدمون والأمان
3. `users`
4. `permissions`
5. `audit_log`

#### الفترات المالية
6. `fiscal_periods`
7. `voucher_sequences` — توليد أرقام atomic ⭐ جديد

#### الكيانات
8. `treasuries` (موحَّد)
9. `expense_categories`
10. `voucher_sub_types` — lookup table ⭐ جديد
11. `employees`
12. `contractors`
13. `partners`

#### الحركات
14. `vouchers` (موحَّد)
15. `treasury_transfers`
16. `cash_advances` ⭐ مُعاد التصميم
17. `cash_advance_repayments` ⭐ جديد
18. `employee_salaries`

#### الكاش والمساعدات
19. `treasury_balance_cache` ⭐ جديد

#### المرفقات والتاريخ
20. `attachments`
21. `exchange_rate_history`
22. `backup_history`

### 9.3 الـ Views

#### `v_treasury_balances` ⭐ Source of Truth للأرصدة

```sql
CREATE VIEW v_treasury_balances AS
SELECT
  t.id AS treasury_id,
  t.name,
  t.kind,
  -- الرصيد بالدينار = (قبض + افتتاحي) - (صرف)
  COALESCE(SUM(CASE
    WHEN v.voucher_type IN ('kabd','opening_balance')
      AND v.currency = 'IQD'
      AND v.is_deleted = 0
    THEN v.amount ELSE 0
  END), 0)
  - COALESCE(SUM(CASE
    WHEN v.voucher_type = 'sarf'
      AND v.currency = 'IQD'
      AND v.is_deleted = 0
    THEN v.amount ELSE 0
  END), 0)
  AS balance_iqd,

  COALESCE(SUM(CASE
    WHEN v.voucher_type IN ('kabd','opening_balance')
      AND v.currency = 'USD'
      AND v.is_deleted = 0
    THEN v.amount ELSE 0
  END), 0)
  - COALESCE(SUM(CASE
    WHEN v.voucher_type = 'sarf'
      AND v.currency = 'USD'
      AND v.is_deleted = 0
    THEN v.amount ELSE 0
  END), 0)
  AS balance_usd,

  -- نفس الشيء لكن بـ amount_iqd للحسابات الموحَّدة
  COALESCE(SUM(CASE
    WHEN v.voucher_type IN ('kabd','opening_balance')
      AND v.is_deleted = 0
    THEN v.amount_iqd ELSE 0
  END), 0)
  - COALESCE(SUM(CASE
    WHEN v.voucher_type = 'sarf'
      AND v.is_deleted = 0
    THEN v.amount_iqd ELSE 0
  END), 0)
  AS balance_unified_iqd

FROM treasuries t
LEFT JOIN vouchers v ON v.treasury_id = t.id
WHERE t.is_deleted = 0
GROUP BY t.id, t.name, t.kind;
```

**ملاحظة**: عمليات `currency_exchange` تُسجَّل كـ سندَيْن (سحب من عملة + إيداع في الأخرى) لذا يبقى الـ VIEW دقيقًا.

### 9.4 تفاصيل الجداول

#### `app_settings`
```sql
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY NOT NULL,
  value TEXT,
  value_type TEXT NOT NULL DEFAULT 'string',
    -- 'string' | 'int' | 'real' | 'bool' | 'json'
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

**القيم الافتراضية:**
| key | value | value_type |
|---|---|---|
| `app_name` | `Sanad` | string |
| `company_name` | `` | string |
| `default_currency` | `IQD` | string |
| `usd_to_iqd_rate` | `1500` | real |
| `language` | `ar` | string |
| `theme_mode` | `system` | string |
| `seed_color` | `#1976D2` | string |
| `numeric_locale` | `ar` | string |
| `fiscal_period_type` | `yearly` | string |
| `fiscal_year_start_month` | `1` | int |
| `fiscal_year_start_day` | `1` | int |
| `multiple_active_periods_allowed` | `true` | bool |
| `auto_backup_enabled` | `false` | bool |
| `auto_backup_interval_hours` | `6` | int |
| `auto_backup_after_n_vouchers` | `50` | int |
| `backup_password_required` | `false` | bool |
| `backup_password_hint` | `` | string |
| `audit_retention_days` | `365` | int |

#### `app_blobs` ⭐ جديد
```sql
CREATE TABLE app_blobs (
  key TEXT PRIMARY KEY NOT NULL,    -- 'logo' | 'background' | etc.
  file_path TEXT NOT NULL,           -- مسار الملف (مختلف بين Mobile/Web)
  storage_kind TEXT NOT NULL,        -- 'app_dir' (Mobile) | 'opfs' (Web)
  mime_type TEXT,
  size_bytes INTEGER,
  sha256_hash TEXT,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

#### `users`
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,        -- bcrypt
  display_name TEXT,
  role TEXT NOT NULL CHECK (role IN ('super_admin','admin','user')),
  default_treasury_id INTEGER REFERENCES treasuries(id),
  is_active INTEGER NOT NULL DEFAULT 1,
  failed_login_count INTEGER DEFAULT 0,
  locked_until DATETIME,
  last_login_at DATETIME,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_active ON users(role, is_active) WHERE is_active = 1;
```

#### `permissions`
```sql
CREATE TABLE permissions (
  user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  manage_employees INTEGER NOT NULL DEFAULT 0,
  manage_contractors INTEGER NOT NULL DEFAULT 0,
  manage_partners INTEGER NOT NULL DEFAULT 0,
  manage_treasuries INTEGER NOT NULL DEFAULT 0,
  manage_categories INTEGER NOT NULL DEFAULT 0,
  voucher_sarf_create INTEGER NOT NULL DEFAULT 0,
  voucher_sarf_edit INTEGER NOT NULL DEFAULT 0,
  voucher_sarf_delete INTEGER NOT NULL DEFAULT 0,
  voucher_kabd_create INTEGER NOT NULL DEFAULT 0,
  voucher_kabd_edit INTEGER NOT NULL DEFAULT 0,
  voucher_kabd_delete INTEGER NOT NULL DEFAULT 0,
  treasury_transfer INTEGER NOT NULL DEFAULT 0,
  currency_exchange INTEGER NOT NULL DEFAULT 0,
  advance_create INTEGER NOT NULL DEFAULT 0,
  salary_pay INTEGER NOT NULL DEFAULT 0,
  view_reports INTEGER NOT NULL DEFAULT 0,
  export_excel INTEGER NOT NULL DEFAULT 0,
  import_excel INTEGER NOT NULL DEFAULT 0,
  view_dashboard INTEGER NOT NULL DEFAULT 1,
  view_audit_log INTEGER NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

#### `fiscal_periods` — مُحدَّث v3.0
```sql
CREATE TABLE fiscal_periods (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,           -- '2026' | 'Q1-2026' | etc.
  period_type TEXT NOT NULL DEFAULT 'yearly'
    CHECK (period_type IN ('yearly','quarterly','monthly','custom')),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active','closed','archived','frozen_pending_recompute','reopening')),
  closed_at DATETIME,
  closed_by INTEGER REFERENCES users(id),
  reopened_at DATETIME,
  reopened_by INTEGER REFERENCES users(id),
  reopening_session_id TEXT,           -- لربط cascade lock بإعادة فتح معينة
  opening_balances_json TEXT,
  closing_balances_json TEXT,
  notes TEXT,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CHECK (end_date > start_date)
);

CREATE INDEX idx_fiscal_periods_status ON fiscal_periods(status, start_date);
CREATE INDEX idx_fiscal_periods_dates ON fiscal_periods(start_date, end_date);
```

#### `voucher_sequences` ⭐ جديد
```sql
CREATE TABLE voucher_sequences (
  fiscal_period_id INTEGER NOT NULL REFERENCES fiscal_periods(id),
  voucher_type TEXT NOT NULL,         -- 'sarf' | 'kabd' | 'opening_balance' | 'currency_exchange'
  last_number INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (fiscal_period_id, voucher_type)
);
```

**التوليد** (داخل transaction):
```sql
UPDATE voucher_sequences
SET last_number = last_number + 1
WHERE fiscal_period_id = ? AND voucher_type = ?
RETURNING last_number;
-- ثم تكوين 'S-2026-' || printf('%05d', last_number)
```

#### `voucher_sub_types` ⭐ جديد (Lookup)
```sql
CREATE TABLE voucher_sub_types (
  code TEXT PRIMARY KEY,               -- 'close_safe', 'general', etc.
  name_ar TEXT NOT NULL,
  name_en TEXT NOT NULL,
  applies_to TEXT NOT NULL,            -- 'sarf' | 'kabd' | 'both'
  display_order INTEGER DEFAULT 0,
  is_system INTEGER DEFAULT 0          -- لا يُحذف
);

-- البيانات المُهيَّأة:
INSERT INTO voucher_sub_types (code, name_ar, name_en, applies_to, is_system) VALUES
  ('close_safe', 'غلق قاصة', 'Cash Box Close', 'sarf', 1),
  ('general', 'صرف عام', 'General Payment', 'sarf', 1),
  ('advance_issue', 'صرف سُلفة', 'Advance Issue', 'sarf', 1),
  ('salary_payment', 'دفع راتب', 'Salary Payment', 'sarf', 1),
  ('treasury_transfer_out', 'تحويل لخزنة', 'Treasury Transfer Out', 'sarf', 1),
  ('currency_exchange_out', 'تحويل عملة (سحب)', 'Currency Exchange (Out)', 'sarf', 1),
  ('general_kabd', 'قبض عام', 'General Receipt', 'kabd', 1),
  ('advance_repayment', 'سداد سُلفة', 'Advance Repayment', 'kabd', 1),
  ('treasury_transfer_in', 'استلام من خزنة', 'Treasury Transfer In', 'kabd', 1),
  ('currency_exchange_in', 'تحويل عملة (إيداع)', 'Currency Exchange (In)', 'kabd', 1),
  ('opening_balance', 'رصيد افتتاحي', 'Opening Balance', 'kabd', 1);
```

#### `treasuries` — مُحدَّث v3.0 (بدون أعمدة الرصيد!)
```sql
CREATE TABLE treasuries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('main','contractor','partner')),
  linked_entity_id INTEGER,             -- للمقاولين/الشركاء
  notes TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CHECK (
    (kind = 'main' AND linked_entity_id IS NULL)
    OR (kind IN ('contractor','partner') AND linked_entity_id IS NOT NULL)
  )
);

CREATE INDEX idx_treasuries_active ON treasuries(kind, is_active)
  WHERE is_deleted = 0;
CREATE INDEX idx_treasuries_linked ON treasuries(kind, linked_entity_id)
  WHERE is_deleted = 0 AND kind IN ('contractor','partner');
```

#### `treasury_balance_cache` ⭐ جديد (للأداء)
```sql
CREATE TABLE treasury_balance_cache (
  treasury_id INTEGER PRIMARY KEY REFERENCES treasuries(id) ON DELETE CASCADE,
  balance_iqd REAL NOT NULL DEFAULT 0,
  balance_usd REAL NOT NULL DEFAULT 0,
  balance_unified_iqd REAL NOT NULL DEFAULT 0,
  last_voucher_id INTEGER,
  computed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  is_dirty INTEGER NOT NULL DEFAULT 0   -- 1 = يحتاج إعادة حساب
);
```

#### `expense_categories`
```sql
CREATE TABLE expense_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  applies_to TEXT NOT NULL CHECK (applies_to IN ('sarf','kabd','both')),
  is_active INTEGER NOT NULL DEFAULT 1,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_categories_active ON expense_categories(applies_to)
  WHERE is_deleted = 0 AND is_active = 1;
```

#### `employees`
```sql
CREATE TABLE employees (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  salary REAL,
  salary_currency TEXT CHECK (salary_currency IN ('IQD','USD')),
  hire_date DATE,
  national_id TEXT,
  phone TEXT,
  address TEXT,
  notes TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_employees_active ON employees(is_active)
  WHERE is_deleted = 0;
CREATE INDEX idx_employees_search ON employees(name, phone, national_id)
  WHERE is_deleted = 0;
```

#### `contractors`
```sql
CREATE TABLE contractors (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  notes TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_contractors_active ON contractors(is_active)
  WHERE is_deleted = 0;
```

#### `partners`
```sql
CREATE TABLE partners (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  share_percentage REAL DEFAULT 0,
  phone TEXT,
  address TEXT,
  notes TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CHECK (share_percentage >= 0 AND share_percentage <= 100)
);

CREATE INDEX idx_partners_active ON partners(is_active)
  WHERE is_deleted = 0;
```

#### `vouchers` ⭐ الجدول الأهم
```sql
CREATE TABLE vouchers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  voucher_number TEXT NOT NULL UNIQUE,
    -- 'S-2026-00001' | 'K-2026-00001' | 'OB-2026-00001' | 'CE-2026-00001'
  voucher_type TEXT NOT NULL
    CHECK (voucher_type IN ('sarf','kabd','opening_balance','currency_exchange')),
  voucher_date DATE NOT NULL,
  fiscal_period_id INTEGER NOT NULL REFERENCES fiscal_periods(id),
  treasury_id INTEGER NOT NULL REFERENCES treasuries(id),

  amount REAL NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL CHECK (currency IN ('IQD','USD')),
  exchange_rate REAL NOT NULL CHECK (exchange_rate > 0),
  amount_iqd REAL NOT NULL,             -- محسوب وقت الإدخال

  responsible_name TEXT,
  paid_to TEXT,                         -- للصرف
  received_from TEXT,                   -- للقبض
  reference_number TEXT,
  description TEXT,

  category_id INTEGER REFERENCES expense_categories(id),
  sub_type TEXT REFERENCES voucher_sub_types(code),
  close_safe_details TEXT,

  linked_entity_type TEXT
    CHECK (linked_entity_type IN ('contractor','partner','employee')),
  linked_entity_id INTEGER,
  linked_voucher_id INTEGER REFERENCES vouchers(id),
  linked_advance_id INTEGER,            -- FK إلى cash_advances
  linked_salary_id INTEGER,             -- FK إلى employee_salaries
  linked_transfer_id INTEGER,           -- FK إلى treasury_transfers

  is_locked INTEGER NOT NULL DEFAULT 0,
  is_deleted INTEGER NOT NULL DEFAULT 0,

  created_by INTEGER NOT NULL REFERENCES users(id),
  updated_by INTEGER REFERENCES users(id),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CHECK (
    (voucher_type = 'sarf' AND paid_to IS NOT NULL AND received_from IS NULL)
    OR (voucher_type IN ('kabd','opening_balance') AND received_from IS NOT NULL AND paid_to IS NULL)
    OR (voucher_type = 'currency_exchange')
  ),

  CHECK (
    (linked_entity_type IS NULL AND linked_entity_id IS NULL)
    OR (linked_entity_type IS NOT NULL AND linked_entity_id IS NOT NULL)
  )
);

-- Partial indexes
CREATE INDEX idx_vouchers_type_date ON vouchers(voucher_type, voucher_date)
  WHERE is_deleted = 0;
CREATE INDEX idx_vouchers_treasury ON vouchers(treasury_id, voucher_date)
  WHERE is_deleted = 0;
CREATE INDEX idx_vouchers_period ON vouchers(fiscal_period_id, voucher_type)
  WHERE is_deleted = 0;
CREATE INDEX idx_vouchers_entity ON vouchers(linked_entity_type, linked_entity_id)
  WHERE is_deleted = 0 AND linked_entity_id IS NOT NULL;
CREATE INDEX idx_vouchers_category ON vouchers(category_id)
  WHERE is_deleted = 0 AND category_id IS NOT NULL;
CREATE INDEX idx_vouchers_locked ON vouchers(is_locked, fiscal_period_id);
```

#### `treasury_transfers`
```sql
CREATE TABLE treasury_transfers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_treasury_id INTEGER NOT NULL REFERENCES treasuries(id),
  to_treasury_id INTEGER NOT NULL REFERENCES treasuries(id),
  amount REAL NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL,
  exchange_rate REAL NOT NULL,
  transfer_date DATE NOT NULL,
  responsible_name TEXT,
  reason TEXT,
  sarf_voucher_id INTEGER NOT NULL REFERENCES vouchers(id),
  kabd_voucher_id INTEGER NOT NULL REFERENCES vouchers(id),
  fiscal_period_id INTEGER NOT NULL REFERENCES fiscal_periods(id),
  created_by INTEGER NOT NULL REFERENCES users(id),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CHECK (from_treasury_id != to_treasury_id)
);

CREATE INDEX idx_transfers_date ON treasury_transfers(transfer_date);
```

#### `cash_advances` ⭐ مُعاد التصميم v3.0
```sql
CREATE TABLE cash_advances (
  id INTEGER PRIMARY KEY AUTOINCREMENT,

  -- المستحقّ عليه السلفة (المدين)
  debtor_type TEXT NOT NULL CHECK (debtor_type IN ('employee','external')),
  employee_id INTEGER REFERENCES employees(id),
  external_person_name TEXT,

  amount REAL NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL CHECK (currency IN ('IQD','USD')),
  exchange_rate REAL NOT NULL,
  amount_iqd REAL NOT NULL,

  advance_date DATE NOT NULL,
  reminder_date DATE,
  notes TEXT,

  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','partial','paid','written_off')),
  total_paid REAL NOT NULL DEFAULT 0,

  related_sarf_voucher_id INTEGER NOT NULL REFERENCES vouchers(id),
  fiscal_period_id INTEGER NOT NULL REFERENCES fiscal_periods(id),

  is_deleted INTEGER NOT NULL DEFAULT 0,
  created_by INTEGER NOT NULL REFERENCES users(id),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CHECK (
    (debtor_type = 'employee' AND employee_id IS NOT NULL AND external_person_name IS NULL)
    OR (debtor_type = 'external' AND employee_id IS NULL AND external_person_name IS NOT NULL)
  ),
  CHECK (total_paid >= 0 AND total_paid <= amount)
);

CREATE INDEX idx_advances_status ON cash_advances(status, advance_date)
  WHERE is_deleted = 0;
CREATE INDEX idx_advances_employee ON cash_advances(employee_id, status)
  WHERE is_deleted = 0 AND employee_id IS NOT NULL;
CREATE INDEX idx_advances_period ON cash_advances(fiscal_period_id, status)
  WHERE is_deleted = 0;
```

#### `cash_advance_repayments` ⭐ جديد
```sql
CREATE TABLE cash_advance_repayments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  advance_id INTEGER NOT NULL REFERENCES cash_advances(id),
  amount REAL NOT NULL CHECK (amount > 0),
  payment_date DATE NOT NULL,
  payment_method TEXT NOT NULL
    CHECK (payment_method IN ('salary_deduction','cash_payment')),
  related_kabd_voucher_id INTEGER REFERENCES vouchers(id),
  related_salary_id INTEGER REFERENCES employee_salaries(id),
  notes TEXT,
  fiscal_period_id INTEGER NOT NULL REFERENCES fiscal_periods(id),
  created_by INTEGER NOT NULL REFERENCES users(id),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CHECK (
    (payment_method = 'cash_payment' AND related_kabd_voucher_id IS NOT NULL)
    OR (payment_method = 'salary_deduction' AND related_salary_id IS NOT NULL)
  )
);

CREATE INDEX idx_repayments_advance ON cash_advance_repayments(advance_id);
```

#### `employee_salaries`
```sql
CREATE TABLE employee_salaries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  employee_id INTEGER NOT NULL REFERENCES employees(id),
  total_salary REAL NOT NULL,
  total_advances_deducted REAL NOT NULL DEFAULT 0,
  net_salary REAL NOT NULL,
  currency TEXT NOT NULL CHECK (currency IN ('IQD','USD')),
  exchange_rate REAL NOT NULL,
  pay_date DATE NOT NULL,
  period_start_date DATE NOT NULL,
  period_end_date DATE NOT NULL,
  notes TEXT,
  related_sarf_voucher_id INTEGER NOT NULL REFERENCES vouchers(id),
  fiscal_period_id INTEGER NOT NULL REFERENCES fiscal_periods(id),
  is_deleted INTEGER NOT NULL DEFAULT 0,
  created_by INTEGER NOT NULL REFERENCES users(id),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CHECK (period_end_date >= period_start_date),
  CHECK (net_salary = total_salary - total_advances_deducted)
);

CREATE INDEX idx_salaries_employee ON employee_salaries(employee_id, pay_date)
  WHERE is_deleted = 0;
```

#### `attachments`
```sql
CREATE TABLE attachments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  voucher_id INTEGER NOT NULL REFERENCES vouchers(id),
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  storage_kind TEXT NOT NULL CHECK (storage_kind IN ('app_dir','opfs')),
  mime_type TEXT,
  size_bytes INTEGER,
  sha256_hash TEXT,
  uploaded_by INTEGER NOT NULL REFERENCES users(id),
  uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_attachments_voucher ON attachments(voucher_id);
```

#### `exchange_rate_history`
```sql
CREATE TABLE exchange_rate_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_currency TEXT NOT NULL,
  to_currency TEXT NOT NULL,
  rate REAL NOT NULL CHECK (rate > 0),
  effective_date DATETIME NOT NULL,
  set_by_user_id INTEGER NOT NULL REFERENCES users(id),
  notes TEXT,

  CHECK (from_currency != to_currency)
);

CREATE INDEX idx_rate_history_date ON exchange_rate_history(effective_date DESC);
```

#### `audit_log` — مُحدَّث v3.0
```sql
CREATE TABLE audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  action TEXT NOT NULL,
    -- 'create' | 'update' | 'delete' | 'login' | 'logout' | 'login_failed' |
    -- 'backup' | 'restore' | 'close_period' | 'reopen_period' |
    -- 'import' | 'export' | 'permission_change' | 'rate_change'
  entity_type TEXT,
  entity_id INTEGER,

  -- بيانات مضغوطة (gzip):
  diff_json_compressed BLOB,           -- diff فقط للـ update، snapshot للحذف، new للـ create
  diff_size_bytes INTEGER,             -- الحجم قبل الضغط (للإحصاء)

  ip_address TEXT,
  device_info TEXT,
  notes TEXT,
  timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_user_time ON audit_log(user_id, timestamp DESC);
CREATE INDEX idx_audit_entity ON audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_action_time ON audit_log(action, timestamp DESC);
```

**استراتيجية تخزين الـ diff:**
| نوع العملية | المُخزَّن في `diff_json_compressed` |
|---|---|
| `create` | `{"new": {...full row}}` |
| `update` | `{"changes": {"field": [old, new], ...}}` (الحقول المتغيِّرة فقط) |
| `delete` | `{"snapshot": {...full row before delete}}` |
| `login`/`logout`/etc. | metadata فقط (صغير) |

**سياسة الاحتفاظ:**
- الافتراضي: 365 يوم في DB
- مهمة دورية يومية: السجلات > 365 يوم → تُصدَّر لـ ZIP/JSON محلي
- ملفات الأرشيف في `archive/audit_logs/audit_2025_Q1.json.gz`

#### `backup_history`
```sql
CREATE TABLE backup_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  backup_type TEXT NOT NULL
    CHECK (backup_type IN ('manual','auto_scheduled','auto_activity','pre_sensitive_op')),
  destination TEXT NOT NULL
    CHECK (destination IN ('local_file','google_drive','onedrive')),
  file_path_or_url TEXT NOT NULL,
  file_size_bytes INTEGER NOT NULL,
  is_encrypted INTEGER NOT NULL DEFAULT 0,
  encryption_method TEXT,             -- 'AES-256-GCM' or NULL
  sha256_hash TEXT NOT NULL,
  success INTEGER NOT NULL,
  error_message TEXT,
  triggered_before_op TEXT,            -- 'close_period', 'restore', etc.
  created_by INTEGER NOT NULL REFERENCES users(id),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_backup_recent ON backup_history(created_at DESC);
CREATE INDEX idx_backup_dest ON backup_history(destination, created_at DESC);
```

---

## 10. حسابات الأرصدة المحاسبية

هذا قسم حرج يوثّق منطق حساب الأرصدة الذي يضمن دقة محاسبية مطلقة.

### 10.1 المبدأ الأساسي

**الرصيد = SUM من سندات الخزنة** (لا قيمة مخزَّنة في عمود).

### 10.2 معادلة الرصيد

```
Balance(treasury, currency) =
    SUM(amount WHERE voucher_type IN ('kabd','opening_balance') AND currency=X AND not_deleted)
  - SUM(amount WHERE voucher_type='sarf' AND currency=X AND not_deleted)
```

عمليات `currency_exchange` تُسجَّل كسندَيْن (سحب من عملة + إيداع في الأخرى) — الـ VIEW يحتسبهما تلقائيًا.

عمليات `treasury_transfer` تُسجَّل كسندَيْن (سحب من الأولى + إيداع في الثانية) — كل خزنة ترى تأثيرها فقط.

### 10.3 نظام الكاش

#### متى يُحدَّث الكاش (incremental)
- بعد كل insert ناجح لـ voucher → نضيف/نطرح من الكاش مباشرة
- بعد كل update → نطرح القيمة القديمة + نضيف الجديدة
- بعد كل delete → نطرح القيمة

#### متى يُعاد حساب الكاش بالكامل (full recompute)
- عند بدء التطبيق (sanity check)
- بعد استعادة نسخة احتياطية
- بعد فتح/غلق سنة مالية
- بعد cascade recompute
- يدويًا من زر "إعادة حساب الأرصدة" (للأدمن/سوبر أدمن)
- مهمة دورية يومية في الخلفية
- لو فرق بين الكاش والـ VIEW > 0.01 → فوري

#### كود recompute كامل
```sql
-- داخل transaction
BEGIN;
DELETE FROM treasury_balance_cache;

INSERT INTO treasury_balance_cache (
  treasury_id, balance_iqd, balance_usd, balance_unified_iqd,
  last_voucher_id, computed_at, is_dirty
)
SELECT
  treasury_id,
  balance_iqd,
  balance_usd,
  balance_unified_iqd,
  (SELECT MAX(id) FROM vouchers WHERE treasury_id = v_treasury_balances.treasury_id),
  CURRENT_TIMESTAMP,
  0
FROM v_treasury_balances;
COMMIT;
```

### 10.4 سلامة المعاملات (Transaction Safety)

كل عملية تُعدِّل الرصيد تكون داخل **transaction واحدة**:

```dart
await db.transaction(() async {
  // 1. توليد voucher_number عبر voucher_sequences
  final newNumber = await _incrementSequence(periodId, type);

  // 2. حساب amount_iqd
  final amountIqd = currency == 'USD' ? amount * exchangeRate : amount;

  // 3. تحديد fiscal_period_id من التاريخ
  final periodId = await _findPeriodForDate(date);

  // 4. التحقق من رصيد الخزنة (للصرف)
  if (type == 'sarf') {
    final balance = await _getTreasuryBalance(treasuryId, currency);
    if (balance < amount) throw InsufficientBalanceException();
  }

  // 5. insert في vouchers
  final voucherId = await _insertVoucher(...);

  // 6. تحديث الكاش (incremental)
  await _updateCache(treasuryId, type, amount, currency, amountIqd);

  // 7. audit log
  await _logAudit(action: 'create', entity: 'voucher', id: voucherId, new: data);
});
```

### 10.5 معالجة Currency Exchange

عند تحويل مبلغ بالدولار إلى دينار في خزنة واحدة:
- يُنشأ **سندان** مرتبطان بـ `linked_voucher_id`:
  1. سند `sub_type=currency_exchange_out` بمبلغ بالدولار
  2. سند `sub_type=currency_exchange_in` بمبلغ بالدينار
- كلاهما `voucher_type=currency_exchange`
- الـ VIEW يحسبهما طبيعيًا — الرصيد بالدولار ينقص، بالدينار يزيد

### 10.6 Treasury Transfer

عند تحويل بين خزنتين:
- يُنشأ **سندان** + سجل في `treasury_transfers`:
  1. سند `sarf` على الخزنة المصدر (`sub_type=treasury_transfer_out`)
  2. سند `kabd` على الخزنة الهدف (`sub_type=treasury_transfer_in`)
- مرتبطان بـ `linked_voucher_id` و `linked_transfer_id`

### 10.7 اختبارات الانحدار (انظر القسم 19)

اختبارات تكامل تتأكد:
- توليد 1000 سند عشوائي → SUM من vouchers = balance من VIEW = balance من cache
- 100 عملية متزامنة → لا race conditions
- بعد كل غلق: opening(N+1) = closing(N) بالضبط
- بعد cascade recompute: كل السنوات اللاحقة سليمة

---

## 11. الوحدات (Modules)

### 11.1 Splash + التهيئة الأولى
- شعار الشركة (إن مُهيَّأ، وإلا الافتراضي)
- مؤشر تحميل
- في الخلفية:
  - فحص DB
  - تشغيل migrations
  - عند أول تشغيل: شاشة "إعداد التطبيق" (إنشاء Super Admin + اسم الشركة + خزنة رئيسية)
  - تجهيز اللغة والمظهر
  - sanity check للأرصدة

### 11.2 شاشة تسجيل الدخول
- شعار الشركة + اسم التطبيق
- اسم المستخدم + كلمة السر (مع زر إظهار/إخفاء)
- "تذكرني" (توكن لـ 7 أيام في secure storage)
- زر تبديل اللغة + المظهر في الزاوية
- 5 محاولات فاشلة → قفل 5 دقائق + audit
- عند النجاح: تحديث `last_login_at` + audit + توجيه للـ Dashboard

### 11.3 لوحة المعلومات (Dashboard)
**KPI Cards:**
- إجمالي رصيد كل خزنة (IQD + USD)
- صرف اليوم/الأسبوع/الشهر
- قبض اليوم/الأسبوع/الشهر
- صافي الحركة هذا الشهر
- سعر الصرف الحالي

**Quick Lists:**
- آخر 5 سندات صرف (روابط للتفاصيل)
- آخر 5 سندات قبض
- مرتبات/سُلَف مستحقة قريبًا

**Charts:**
- منحنى شهري (صرف vs قبض) للسنة النشطة
- توزيع الصرف حسب الصنف (Pie)

**Quick Actions:**
- إضافة سند صرف
- إضافة سند قبض
- تقرير سريع

### 11.4 إدارة المستخدمين

#### قائمة:
- جدول: الاسم، اسم المستخدم، الدور، الخزنة الافتراضية، الحالة، آخر دخول
- فلتر بالدور
- بحث

#### إضافة/تعديل:
- اسم العرض + اسم المستخدم (فريد) + كلمة السر + تأكيد
- الدور (حسب صلاحية المُنشئ):
  - Super Admin: أي دور
  - Admin: User فقط
- الخزنة الافتراضية
- الحالة
- إن User: مصفوفة الصلاحيات (20 checkbox)
- زر "إعادة تعيين كلمة السر"
- **حماية حذف آخر سوبر أدمن**

### 11.5 الإعدادات (8 تبويبات)

1. **عام**: اللغة، المظهر، اللون، نمط الأرقام
2. **هوية الشركة**: كل الحقول في 4.1
3. **العملات وسعر الصرف**: السعر الحالي + سجل
4. **التصنيفات**: إدارة `expense_categories`
5. **الفترات المالية**: قائمة + غلق + إعادة فتح (Super Admin)
6. **النسخ الاحتياطي**: في القسم 12
7. **سجل العمليات**: قابل للفلترة + تصدير
8. **حول التطبيق**: الإصدار، الترخيص، روابط

### 11.6 الموظفون

#### قائمة:
- جدول: الاسم، الراتب، الهاتف، تاريخ التعيين، الحالة
- فلاتر + بحث + ترتيب

#### شاشة موظف (Tabs):
- **معلومات أساسية**
- **السُّلَف النقدية** (قائمة + إضافة)
- **المرتبات** (قائمة + دفع راتب جديد)
- **كشف حساب** (كل الحركات + إجماليات + تصدير Excel)

#### شاشة إضافة سُلفة نقدية:
- نوع المدين: موظف / شخص خارجي (radio)
- إن موظف: dropdown (يعرض راتبه)
- إن خارجي: حقل اسم
- المبلغ + العملة + سعر الصرف
- تاريخ السلفة + تاريخ التذكير
- الخزنة المصدر
- ملاحظات
- → ينشئ سند صرف مرتبط + سجل في `cash_advances`

#### شاشة دفع المرتبات:
- اختيار الموظف
- يحسب: الراتب الكلي، السُّلَف غير المسددة، صافي الراتب
- اختيار الخزنة
- تاريخ الدفع + الفترة (من/إلى)
- ملاحظات
- → ينشئ سند صرف + سجل في `employee_salaries` + سجل في `cash_advance_repayments` (لكل سُلفة مغطّاة) + يُحدّث `cash_advances.status`

### 11.7 المقاولون
- نفس بنية الموظفين
- Tab "خزنة المقاول" (إيداع/سحب) + Tab "السندات" + Tab "كشف حساب"

### 11.8 الشركاء
- نفس بنية المقاولين + `share_percentage`
- Tab مستقبلي "توزيع الأرباح"

### 11.9 الخزائن

#### قائمة:
- جدول مع الرصيد المعروض **من VIEW (cache)**
- فلتر بالنوع
- ترتيب
- زر إضافة (kind=`main` فقط من هنا)

#### شاشة خزنة:
- معلومات + بطاقتا الرصيد
- أزرار: إيداع / سحب / تحويل / تحويل عملة
- جدول الحركات (آخر 50 + pagination)
- زر "كشف حساب كامل"

#### شاشات الإيداع/السحب/التحويل/تحويل العملة
موصوفة في القسم 6.5 + 8.6.

### 11.10 سند الصرف ⭐

**العنوان**: "سند صرف"

**الحقول:**

| الحقل | النوع | إلزامي | المصدر |
|---|---|---|---|
| رقم العملية | عرض | — | تلقائي عند الحفظ من `voucher_sequences` |
| السنة المالية | عرض | — | يُحدَّد من التاريخ تلقائيًا |
| تاريخ الصرف | DatePicker | ✅ | اليوم |
| الخزنة | Dropdown | ✅ | `treasuries` (kind=main افتراضي) |
| نوع الصرف | Radio | ✅ | غلق قاصة / صرف عام (من `voucher_sub_types`) |
| تفاصيل غلق القاصة | TextField | عند "غلق قاصة" | — |
| المبلغ | NumberField | ✅ | > 0 |
| العملة | Dropdown | ✅ | IQD/USD |
| سعر الصرف | NumberField | ✅ | السعر الحالي افتراضيًا |
| المسؤول | TextField | ✅ | المستخدم الحالي |
| تم الصرف لـ | TextField | ✅ | — |
| الصنف | Dropdown | ❌ | `expense_categories` (sarf/both) |
| رقم الفاتورة/الوصل | TextField | ✅ | — |
| الوصف | TextField متعدد | ✅ | — |
| الجهة المرتبطة | Dropdown | ❌ | موظف/مقاول/شريك |
| المرفقات | File picker | ❌ | (Phase 1.5) |

**Toolbar:**
- ⏮ ◀ ▶ ⏭ | ➕ 💾 ✏️ 🗑 | 🖨 📤 🔍

**التحقق:**
- الحقول الإلزامية + المبلغ > 0 + رصيد كافٍ + التاريخ في فترة مفتوحة + إن غلق قاصة: التفاصيل
- إن في فترة مغلقة: مرفوض (إلا للسوبر أدمن)
- إن في فترة `frozen_pending_recompute`: مرفوض حتى للسوبر أدمن

**السلوك (داخل transaction):**
- **Add**: voucher_sequences → insert → cache update → audit
- **Edit**: revert old → apply new → cache update → audit
- **Delete (soft)**: revert → is_deleted=1 → cache update → audit

### 11.11 سند القبض ⭐
- نفس البنية
- بدون "نوع الصرف" / "تفاصيل غلق القاصة"
- "قبض من" بدل "تم الصرف لـ"
- **الإضافة تضيف للخزنة** (مصححة من bug الأصل)
- لا فحص "الرصيد كافٍ"

### 11.12 التقارير وكشوف الحساب ⭐

**فلاتر قوية:**
- نوع التقرير (10 أنواع)
- السنة المالية (افتراضي: النشطة)
- تاريخ من/إلى
- العملة
- وضع العرض (4 خيارات للعملات)
- بحث نصي
- ترتيب

**النتائج:**
- جدول قابل للترتيب
- صف المجاميع
- الرصيد الجاري (إن كان فلتر على كيان واحد)
- KPI cards في الأعلى

**أزرار:**
- 📊 تصدير Excel (مع Branding header)
- 🖨 طباعة PDF (Phase 1.5)

### 11.13 معالجات الفترات المالية
- معالج غلق سنة (5 مراحل) — في 8.6
- معالج إعادة فتح سنة (4 مراحل + Cascade) — في 8.7

---

## 12. النسخ الاحتياطي والتخزين السحابي

### 12.1 المراحل الثلاث

#### Phase 1 (مع MVP) — النسخ المحلي
- ✅ نسخ يدوي بنقرة
- ✅ ضغط gzip (-70-80%)
- ✅ تشفير AES-256-GCM اختياري بكلمة سر
- ✅ Hash SHA-256 للتحقق
- ✅ نسخ تلقائي:
  - **افتراضي**: كل 6 ساعات
  - أو بعد كل 50 سند (أيهما أسبق)
  - خيارات: 1ساعة / 6 ساعات / 12 ساعة / يومي / يدوي + كل N سند
- ✅ نسخة قبل عمليات حساسة (راجع 12.2)
- ✅ على الويب: تنزيل ملف للمستخدم
- ✅ سياسة الاحتفاظ: آخر 30 نسخة

#### Phase 2 (بعد استقرار MVP) — التكامل السحابي
- ✅ Google Drive — OAuth 2.0 (حسابات شخصية)
- ✅ OneDrive — OAuth 2.0 (Microsoft شخصية)
- ✅ نسخ تلقائي للسحابة في الخلفية
- ✅ استعادة بنقرة
- ✅ قائمة النسخ السحابية

#### Phase 3 (المستقبل) — Supabase Sync
- ✅ مزامنة Real-time بين الأجهزة
- ✅ يحلّ محلّ النسخ التقليدي

### 12.2 العمليات الحساسة (نسخة قبلها)

- غلق فترة مالية
- إعادة فتح فترة مالية
- استعادة نسخة احتياطية
- استيراد Excel بأكثر من 100 صف
- حذف كيان لديه حركات
- تغيير سعر الصرف بفارق > 20%
- ترقية إصدار قاعدة البيانات (migrations)
- Cascade Recompute بعد إعادة فتح

### 12.3 المنطق الذكي للنسخ قبل العمليات

```
عند بدء عملية حساسة:
  if (auto_backup_enabled == true):
    take_silent_backup()  # تلقائي بدون مقاطعة
    proceed()
  else:
    show_dialog("نأخذ نسخة احتياطية أولًا؟", buttons: [نعم/لا/إلغاء])
    if (yes): take_backup()
    if (no): log_warning_in_audit()
    proceed()
```

### 12.4 التشفير
- AES-256-GCM (advanced AEAD)
- مفتاح بـ PBKDF2 (100,000 iterations)
- Salt + IV عشوائيين لكل نسخة
- تنبيه قوي: "إن نسيت كلمة السر، البيانات لا تُسترَد"
- خيار حفظ Hint (تلميح)

### 12.5 إعدادات النسخ السحابي (Phase 2)
- ربط Google Drive (OAuth)
- ربط OneDrive (OAuth)
- مجلد السحابة (افتراضي: `/SanadBackups`)
- جدولة + سياسة احتفاظ
- Tokens في `flutter_secure_storage`

### 12.6 سجل النسخ (`backup_history`)
موصوف في 9.4

---

## 13. استيراد وتصدير Excel

### 13.1 الاستيراد — Wizard 5 خطوات

#### الخطوة 1: الاختيار
- نوع الكيان (السندات / الموظفون / المقاولون / الشركاء / الخزائن / التصنيفات)
- زر "تنزيل قالب Excel"
- اختيار الملف (.xlsx, .xls, .csv)
- drag & drop على الويب

#### الخطوة 2: المطابقة
- قراءة الصف الأول
- جدول مطابقة Excel ↔ DB
- مطابقة تلقائية بالاسم
- تعديل يدوي

#### الخطوة 3: المعاينة
- أول 10 صفوف بعد المطابقة

#### الخطوة 4: التحقق
يفحص:
- الحقول الإلزامية
- التواريخ (تنسيقات متعددة + Excel serial)
- الأرقام
- المفاتيح الخارجية (اسم الخزنة → ID)
- العملة
- التاريخ في فترة مفتوحة

تقرير: X صحيح / Y خطأ + جدول الأخطاء قابل للتصدير.

#### الخطوة 5: التنفيذ
خيارات:
- تخطّي الخاطئ
- إيقاف عند أول خطأ
- وضع اختبار (لا يحفظ)

ميزات:
- شريط تقدّم
- **Isolate** منفصل (لا تجمد UI)
- **transaction واحدة** (rollback عند الفشل)
- نسخة احتياطية تلقائية إن > 100 صف
- استخدام `voucher_sequences` بشكل صحيح
- تقرير نهائي + ملف الأخطاء

### 13.2 خطة الأداء (Excel Performance Plan)

#### المرحلة الأولية (MVP)
- استخدام حزمة `excel` (مفتوحة)

#### Benchmark إجباري في Sprint 11
- ملف اختبار 5,000 صف
- قياس زمن القراءة + التحقق + الإدراج

#### معايير القرار:
| النتيجة | الإجراء |
|---|---|
| < 30 ثانية | نبقى على `excel` |
| 30-60 ثانية | تحسينات (chunking, batch insert) |
| > 60 ثانية | الانتقال لـ `syncfusion_flutter_xlsio` |

#### الحل البديل للملفات الضخمة
- نوصي المستخدم باستخدام **CSV** بدل XLSX
- نقرأها بـ `csv` package (أسرع 10×)

### 13.3 قوالب Excel
- يولّدها التطبيق ديناميكيًا
- ورقة "تعليمات" منفصلة في كل قالب
- يقبل اسم الخزنة بدل ID (يحوّل تلقائيًا)

### 13.4 معالجة التواريخ
- أنماط: `dd/MM/yyyy`, `dd-MM-yyyy`, `yyyy-MM-dd`, `MM/dd/yyyy` + مع وقت
- رقم Excel التسلسلي (DateTime.FromOADate)
- DateTime مباشر
- skip + warning للقيم غير الصالحة

### 13.5 التصدير
كل تقرير له زر تصدير:

**هيكل الملف:**
- **Sheet 1** ترويسة: شعار + Branding + معايير الفلترة + التاريخ + الإجماليات
- **Sheet 2** البيانات: رؤوس ملوّنة (RTL-aware) + تنسيق + تجميد الصف الأول + auto-width
- **Sheet 3** الإجماليات (Phase 1.5): رسوم بيانية

اسم الملف: `[نوع]_[التاريخ_من_إلى].xlsx`

---

## 14. سجل العمليات (Audit Log)

### 14.1 الأحداث المسجَّلة
- create/update/delete على الجداول الحركية
- login/logout/login_failed (مع IP)
- backup/restore
- close_period/reopen_period
- import/export
- permission_change
- rate_change

### 14.2 تخزين ذكي (مُحدَّث v3.0)
- create: new فقط
- update: diff (الحقول المتغيِّرة)، ليس row كاملة
- delete: snapshot
- login/etc.: metadata فقط
- ضغط gzip للحقل JSON

### 14.3 الوصول
- Super Admin: كل السجل
- Admin: عدا أحداث Super Admin
- User: لا (إلا إن مُنح `view_audit_log` — يرى أحداثه فقط)

### 14.4 سياسة الاحتفاظ والأرشفة
- 365 يوم في DB (إعداد قابل للتعديل)
- مهمة دورية يومية:
  - السجلات > 365 يوم → ZIP/JSON محلي
  - مسار: `archive/audit_logs/audit_YYYY_QN.json.gz`
  - تُحذف من DB
- تصدير دوري لـ Excel (للمالك)

### 14.5 الأمان
- لا يُحذف من السجل
- لا يُعدَّل (insert-only)
- في Phase 3 مع Supabase: تخزين سحابي immutable

---

## 15. معايير UI/UX

### 15.1 المظهر
- Material 3
- Light + Dark + System (تلقائي)
- لون أساسي قابل للتخصيص
- زوايا 12-16px
- ظلال خفيفة
- انتقالات 200-300ms

### 15.2 الخطوط (مُحدَّث v3.0 — محلية)
- **عربي**: Tajawal (Regular/Medium/Bold) كـ assets
- **إنجليزي**: Inter (Regular/Medium/Bold) كـ assets
- **بدون** حزمة `google_fonts`

### 15.3 المكونات
- Cards بدل Modal Dialogs المتراكمة
- Snackbars للإشعارات
- Dialogs للتأكيدات الحرجة فقط
- Skeleton loaders بدل spinners
- Empty states برسومات

### 15.4 النماذج
- Floating labels
- Inline validation
- Helper text
- Error text بأيقونة
- Auto-focus + Tab order
- Submit بـ Enter

### 15.5 الجداول (DataTable Pro)
- فرز + بحث + فلاتر
- Pagination (50)
- تصدير سريع
- Highlight + multi-select
- Inline actions

### 15.6 التنقل
- Drawer (يمين للعربي)
- AppBar مع: لوجو + بحث + مستخدم + إشعارات + اللغة + المظهر
- Breadcrumbs

### 15.7 Responsive
- Web: 3 أعمدة (>1200px) → 2 (>768px) → 1
- Mobile: عمود واحد دائمًا
- Tablet: 2 + Drawer أصغر

### 15.8 Animations
- Page transitions ناعمة
- List items fade-in
- Buttons hover/press states

---

## 16. حزمة التقنيات

### 16.1 الأساسية
| الفئة | المكتبة |
|---|---|
| Framework | Flutter ≥ 3.22 |
| Language | Dart ≥ 3.4 |

### 16.2 الإدارة والبنية
| الفئة | المكتبة |
|---|---|
| State | `flutter_riverpod` 2.x |
| Routing | `go_router` 14.x |
| Models | `freezed` + `json_serializable` |
| Logging | `logger` |

### 16.3 قاعدة البيانات
| الفئة | المكتبة |
|---|---|
| ORM | `drift` 2.x |
| Web | `drift` web (sqlite3 wasm + IndexedDB + OPFS) |
| Mobile | `drift` + `sqlite3_flutter_libs` |

### 16.4 التوطين
- `flutter_localizations` + `intl` + `flutter gen-l10n`

### 16.5 الواجهة
| الفئة | المكتبة |
|---|---|
| Forms | `reactive_forms` 17.x |
| Charts | `fl_chart` 0.68 |
| Color Picker | `flex_color_picker` |
| Icons | Material Icons + `lucide_icons` |
| Image | `cached_network_image` |
| File picker | `file_picker` 8.x |
| ~~Fonts~~ | ~~`google_fonts`~~ — **محذوف، نستخدم assets** |

### 16.6 الخدمات
| الفئة | المكتبة |
|---|---|
| Excel (MVP) | `excel` 4.x |
| Excel (احتياط) | `syncfusion_flutter_xlsio` (إن لزم) |
| CSV | `csv` |
| PDF | `pdf` + `printing` (Phase 1.5) |
| Hash | `bcrypt` 1.x |
| AES Encryption | `pointycastle` |
| Compression | `archive` (gzip) |
| Path | `path_provider` 2.x |
| OPFS (Web) | `web` package + JS interop |
| Secure Storage | `flutter_secure_storage` |

### 16.7 Phase 2 (السحابة)
| الفئة | المكتبة |
|---|---|
| Google APIs | `googleapis` + `googleapis_auth` |
| OneDrive | `flutter_appauth` + Microsoft Graph REST |
| OAuth | `oauth2` |

### 16.8 الاختبار
| الفئة | المكتبة |
|---|---|
| Mocking | `mocktail` |
| Drift Testing | (built-in) |
| Integration | `integration_test` |

### 16.9 Phase 3 (Supabase)
- `supabase_flutter` 2.x

---

## 17. هيكل المشروع

```
sanad_app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── colors.dart
│   │   │   └── typography.dart
│   │   ├── localization/arb/
│   │   ├── router/
│   │   ├── utils/
│   │   │   ├── date_utils.dart
│   │   │   ├── number_format.dart
│   │   │   ├── currency_converter.dart
│   │   │   ├── voucher_number_generator.dart
│   │   │   ├── fiscal_period_resolver.dart
│   │   │   ├── balance_calculator.dart        ⭐
│   │   │   └── validators.dart
│   │   ├── error/
│   │   └── di/
│   ├── data/
│   │   ├── db/
│   │   │   ├── app_database.dart
│   │   │   ├── tables/                        # 22 جدول
│   │   │   ├── views/
│   │   │   │   └── treasury_balances_view.dart  ⭐
│   │   │   ├── daos/
│   │   │   │   ├── voucher_dao.dart
│   │   │   │   ├── treasury_dao.dart
│   │   │   │   ├── balance_dao.dart           ⭐
│   │   │   │   ├── sequence_dao.dart          ⭐
│   │   │   │   ├── advance_dao.dart           ⭐
│   │   │   │   └── ...
│   │   │   ├── migrations/
│   │   │   └── triggers.sql                   ⭐ تحديث الكاش
│   │   ├── models/                            # freezed
│   │   ├── repositories/
│   │   │   ├── interfaces/
│   │   │   ├── auth_repository.dart
│   │   │   ├── voucher_repository.dart
│   │   │   ├── treasury_repository.dart
│   │   │   ├── balance_repository.dart        ⭐
│   │   │   ├── advance_repository.dart        ⭐
│   │   │   ├── employee_repository.dart
│   │   │   ├── contractor_repository.dart
│   │   │   ├── partner_repository.dart
│   │   │   ├── fiscal_period_repository.dart
│   │   │   ├── settings_repository.dart
│   │   │   └── audit_repository.dart
│   │   └── services/
│   │       ├── excel_import_service.dart
│   │       ├── excel_export_service.dart
│   │       ├── backup_service.dart
│   │       ├── encryption_service.dart
│   │       ├── compression_service.dart       ⭐
│   │       ├── opfs_service.dart              ⭐ (Web)
│   │       ├── cloud_backup_service.dart      # Phase 2
│   │       ├── currency_service.dart
│   │       ├── fiscal_close_service.dart
│   │       ├── fiscal_reopen_service.dart     ⭐
│   │       └── audit_archive_service.dart     ⭐
│   ├── features/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── users/
│   │   ├── settings/
│   │   ├── branding/
│   │   ├── employees/
│   │   ├── contractors/
│   │   ├── partners/
│   │   ├── treasuries/
│   │   ├── voucher_sarf/
│   │   ├── voucher_kabd/
│   │   ├── reports/
│   │   ├── excel_import/
│   │   ├── backup/
│   │   ├── fiscal_periods/
│   │   ├── advances/                          ⭐ مُعاد التسمية
│   │   └── audit_log/
│   └── shared/
│       └── widgets/
│           ├── app_scaffold.dart
│           ├── nav_arrows.dart
│           ├── voucher_form_fields.dart
│           ├── currency_amount_input.dart
│           ├── treasury_picker.dart
│           ├── fiscal_period_indicator.dart
│           ├── frozen_period_warning.dart     ⭐
│           ├── confirm_dialog.dart
│           ├── data_table_pro.dart
│           ├── empty_state.dart
│           └── ...
├── assets/
│   ├── fonts/                                 ⭐ خطوط محلية
│   │   ├── Tajawal-Regular.ttf
│   │   ├── Tajawal-Medium.ttf
│   │   ├── Tajawal-Bold.ttf
│   │   ├── Inter-Regular.ttf
│   │   ├── Inter-Medium.ttf
│   │   └── Inter-Bold.ttf
│   ├── images/
│   │   └── default_logo.png
│   └── i18n/
├── test/
├── integration_test/
│   ├── balance_regression_test.dart           ⭐
│   ├── voucher_concurrent_test.dart           ⭐
│   ├── fiscal_close_test.dart                 ⭐
│   └── cascade_reopen_test.dart               ⭐
├── build.yaml                                 ⭐ تحسين build_runner
├── pubspec.yaml
└── README.md
```

---

## 18. خطة التنفيذ المرحلية (Sprints)

### Sprint 0 — التأسيس (يوم 1)
- إنشاء مشروع Flutter
- pubspec.yaml بكل الحزم (بدون google_fonts)
- تنزيل خطوط Tajawal + Inter كـ assets
- Theme + RTL
- هيكل المجلدات
- Drift base
- ARB + intl
- go_router + shell route
- Splash + شاشة "Hello"
- **build.yaml** للأداء

### Sprint 1 — قاعدة البيانات الكاملة (يوم 2-3)
- 22 جدولًا في Drift
- View `v_treasury_balances`
- Migrations
- Seeders (Super Admin + خزنة + إعدادات + سنة مالية حالية + sub_types)
- DAOs لكل جدول
- balance_dao + sequence_dao
- Repository interfaces

### Sprint 2 — تسجيل الدخول والمستخدمون (يوم 4)
- Login + bcrypt
- 5 محاولات → قفل
- Auth provider + secure storage
- Route guards + 3 أدوار
- شاشة "أول تشغيل"
- إدارة المستخدمين + مصفوفة الصلاحيات
- حماية حذف آخر سوبر أدمن

### Sprint 3 — الإعدادات والـ Branding (يوم 5)
- 8 تبويبات
- رفع الشعار → `app_blobs` + OPFS/file
- اللغة + المظهر + اللون
- العملات + سعر الصرف + سجل
- التصنيفات

### Sprint 4 — الفترات المالية (يوم 6-7)
- جدول fiscal_periods + إعدادات
- منطق تحديد الفترة من التاريخ
- توليد سنة جديدة تلقائيًا في 1 يناير
- شاشة قائمة السنوات
- معالج غلق سنة (5 مراحل)
- معالج إعادة فتح (Super Admin) + Cascade Lock
- توليد opening_balance vouchers

### Sprint 5 — الخزائن (يوم 8)
- قائمة موحَّدة + الرصيد من VIEW
- إضافة/تعديل
- شاشة تفاصيل + كاش
- إيداع/سحب/تحويل
- تحويل عملة (USD↔IQD)
- زر "إعادة حساب الأرصدة"

### Sprint 6 — سند الصرف ⭐ (يوم 9-10)
- الشاشة الكاملة
- التحقق + balance check
- voucher_sequences
- أزرار التنقل + CRUD
- ربط بكيان
- Audit logging
- تحديث الكاش incremental

### Sprint 7 — سند القبض ⭐ (يوم 11)
- نفس مستوى الصرف
- إصلاح bug الحذف من الأصل

### Sprint 8 — الموظفون والسُّلَف (يوم 12-13)
- قائمة + Tabs
- cash_advances (الـ schema الجديد)
- cash_advance_repayments
- دفع المرتبات
- كشف حساب الموظف

### Sprint 9 — المقاولون والشركاء (يوم 14)
- قوائم + Tabs
- خزائنهم
- سندات صرفهم
- كشوف حساب

### Sprint 10 — التقارير وكشوف الحساب ⭐ (يوم 15-16)
- شاشة التقارير الموحَّدة
- الفلاتر الكاملة
- جدول النتائج + إجماليات + رصيد جاري
- خيارات العرض بالعملات
- تصدير Excel مع Branding header

### Sprint 11 — استيراد Excel ⭐ + Benchmark (يوم 17-18)
- Wizard 5 خطوات
- قوالب قابلة للتنزيل
- قراءة + auto-mapping + معاينة
- التحقق + تقرير الأخطاء
- التنفيذ في Isolate + transaction
- **Benchmark 5000 صف**
- قرار: البقاء على `excel` أو الانتقال

### Sprint 12 — Dashboard + النسخ المحلي (يوم 19-20)
- لوحة المعلومات + KPIs + charts
- النسخ الاحتياطي المحلي
- التشفير AES + كلمة سر
- النسخ التلقائي (6 ساعات + كل 50 سند)
- النسخ قبل العمليات الحساسة
- سجل النسخ

### Sprint 13 — Audit Log + التلميع (يوم 21-22)
- شاشة Audit Log + فلاتر
- ضغط gzip للـ diff
- مهمة الأرشفة الدورية
- مراجعة شاملة + إصلاح bugs
- اختبار يدوي عربي/إنجليزي + Light/Dark
- تحسينات أداء + animations

### Sprint 14 — اختبارات الانحدار ⭐ (يوم 23)
- 4 ملفات اختبار تكامل (انظر القسم 19)

### Sprint 15 — البناء والنشر (يوم 24-25)
- Flutter Web release + WASM
- Android APK + AAB
- (اختياري) Windows desktop
- دليل المستخدم
- نشر

**إجمالي تقديري: 25 يوم عمل** (لمطور واحد متفرغ).

---

## 19. الاختبار

### 19.1 Unit Tests
- كل Repository (mock DB)
- balance_calculator (حسابات الأرصدة)
- currency_converter
- voucher_number_generator
- fiscal_period_resolver
- التحقق من الصلاحيات
- encryption_service

### 19.2 Widget Tests
- كل form (validation + interaction)
- شاشة Login
- شاشات السندات
- Excel Import wizard

### 19.3 Integration Tests (تدفقات كاملة)
- Login → سند صرف → تقرير → تصدير
- موظف → سُلفة → دفع راتب
- تحويل بين خزائن
- Excel Import (ملفات صحيحة وخاطئة)
- غلق سنة → التحقق من opening_balance
- نسخ احتياطي + استعادة

### 19.4 ⭐ اختبارات الانحدار للأرصدة (CRITICAL)

#### `balance_regression_test.dart`
- توليد 1000 سند عشوائي على 5 خزائن (تواريخ متفاوتة، عملات مختلطة)
- التحقق:
  - SUM من vouchers = balance من VIEW
  - balance من VIEW = balance من cache
  - الفرق < 0.01 لكل خزنة

#### `voucher_concurrent_test.dart`
- 100 عملية متزامنة (insert/update/delete)
- التحقق:
  - لا race conditions
  - لا أرقام سندات مكررة
  - الكاش متطابق مع VIEW
- اختبار `voucher_sequences` تحت ضغط

#### `fiscal_close_test.dart`
- إنشاء سنة بـ 500 سند
- غلق السنة
- التحقق:
  - opening_balance(N+1) = closing_balance(N) بالضبط لكل خزنة
  - السندات locked
  - السنة الجديدة فيها سندات افتتاحية صحيحة

#### `cascade_reopen_test.dart`
- إنشاء 3 سنوات: 2025, 2026, 2027
- 2025 + 2026 مغلقتان، 2027 نشطة
- إعادة فتح 2025
- التحقق:
  - 2026 + 2027 → frozen_pending_recompute
  - محاولة insert في 2026 → خطأ
- تعديل سند في 2025
- إعادة الغلق (cascade)
- التحقق:
  - opening_balances في 2026 و 2027 صحيحة
  - الحالات صحيحة
  - audit log كامل

### 19.5 الاختبار اليدوي
- عربي/إنجليزي
- RTL/LTR
- Light/Dark
- Web (Chrome, Firefox, Edge)
- Android (شاشات صغيرة وكبيرة)
- iOS (إن أتيح)

### 19.6 ملفات Excel للاختبار
- سند صرف صحيح (50 صف)
- سند صرف بأخطاء متنوعة
- تواريخ بتنسيقات مختلفة
- أعمدة مفقودة
- صفوف فارغة
- ملفات ضخمة (5,000+ صف)

---

## 20. النشر

### 20.1 Web
```bash
flutter build web --release --wasm --base-href /
```
- النشر على: Firebase Hosting / Netlify / VPS / GitHub Pages
- HTTPS إجباري
- Service Worker للـ offline
- Lazy loading

### 20.2 Android
- APK للتوزيع
- AAB للـ Google Play
- Release key (يُحفظ آمنًا)
- minSdkVersion: 21
- targetSdkVersion: 34

### 20.3 iOS (لاحقًا)
- Apple Developer ($99/year)
- Provisioning Profiles
- App Store أو TestFlight

### 20.4 Windows Desktop (لاحقًا)
```bash
flutter build windows --release
```
- Inno Setup أو MSIX

---

## 21. المراحل المستقبلية

### Phase 2: التكامل السحابي
- Google Drive direct (OAuth)
- OneDrive direct (OAuth)
- Auto sync to cloud

### Phase 3: Supabase Migration
- Supabase project
- Schema → PostgreSQL
- Repository implementations جديدة
- Row Level Security
- Real-time sync
- Supabase Auth بدل bcrypt
- Storage للمرفقات

### Phase 4: ميزات متقدمة
- توزيع الأرباح للشركاء
- طباعة PDF متقدمة
- إشعارات (تذكير سُلَف، غلق سنة)
- لوحة معلومات مخصصة
- بحث عام
- اختصارات لوحة المفاتيح

### Phase 5: غلق شهري/ربعي
- تغيير `fiscal_period_type`
- بدون migration
- النظام يولّد فترات شهرية/ربعية تلقائيًا

---

## 22. خارج النطاق

❌ المنتجات / المخزون
❌ العملاء
❌ الموردون
❌ المشتريات / المبيعات / المرتجعات
❌ الضرائب
❌ طباعة الباركود
❌ Crystal Reports

(~50 شاشة محذوفة من الأصل)

---

## 23. المخاطر والتخفيف منها

| الخطر | الاحتمال | التأثير | التخفيف |
|---|---|---|---|
| فقد بيانات | منخفض | عالي | نسخ تلقائي + سحابي + تشفير |
| نسيان كلمة سر التشفير | متوسط | عالي | تنبيه + Hint + توثيق |
| Bug في الأرصدة | منخفض | عالي | VIEW = source of truth + اختبارات انحدار + sanity check |
| Race conditions | منخفض | عالي | voucher_sequences + transactions |
| استيراد Excel بأخطاء | متوسط | متوسط | wizard + تحقق + معاينة + transaction |
| تجمد UI | منخفض | متوسط | Isolates |
| سرقة tokens | منخفض | عالي | secure storage + انتهاء + HTTPS |
| غلق سنة خاطئ | متوسط | عالي | wizard + تأكيد + نسخة + إعادة فتح للسوبر أدمن |
| Cascade خاطئ | منخفض | عالي | frozen_pending_recompute + transactions + اختبارات |
| تعديل سعر الصرف يؤثر على القديم | لا | — | تخزين تاريخي |
| كسر التوافق عند التحديث | منخفض | عالي | migrations محكمة + نسخة قبلها |
| تضخم Audit Log | عالي | متوسط | gzip + احتفاظ 365 يوم + أرشفة |
| أداء Web بطيء مع البيانات الكبيرة | متوسط | متوسط | Partial indexes + cache + benchmark + خطة Supabase |

---

## 24. مصطلحات

| العربي | English | الوصف |
|---|---|---|
| سند صرف | Payment Voucher (Sarf) | إخراج مال من خزنة |
| سند قبض | Receipt Voucher (Kabd) | إدخال مال لخزنة |
| الخزنة / القاصة | Treasury / Cash Box | حاوية الأموال |
| الفترة المالية | Fiscal Period | المدى الزمني المحاسبي |
| السنة المالية | Fiscal Year | فترة سنوية |
| غلق السنة | Year-End Closing | تجميد بيانات السنة |
| الرصيد الافتتاحي | Opening Balance | رصيد بداية الفترة |
| الرصيد الختامي | Closing Balance | رصيد نهاية الفترة |
| المقاول | Contractor | مقاول خارجي |
| الشريك | Partner | شريك في الأعمال |
| السُّلفة النقدية | Cash Advance | مال يُسلَّف للموظف |
| المدين | Debtor | المستحقّ عليه السلفة |
| سعر الصرف | Exchange Rate | نسبة التحويل بين عملتين |
| كشف الحساب | Statement of Account | تقرير حركات حساب |
| الأرشفة | Archive | حفظ بيانات قديمة |
| السجل / التدقيق | Audit Log | سجل العمليات |
| النسخ الاحتياطي | Backup | نسخة احتياطية |
| الاستعادة | Restore | استرجاع نسخة |
| المزامنة | Sync | تطابق البيانات |
| الصلاحية | Permission | إذن لعمل ما |
| التشفير | Encryption | تأمين البيانات |
| Cascade Lock | تجميد متتابع | قفل السنوات اللاحقة عند إعادة فتح |
| Cascade Recompute | إعادة حساب متتابعة | إعادة حساب الأرصدة في كل السنوات اللاحقة |
| OPFS | Origin Private File System | نظام ملفات حقيقي في المتصفح |
| VIEW | عرض / مشهد | جدول افتراضي محسوب |
| Cache | كاش | تخزين مؤقت لتسريع الأداء |

---

## ✅ قائمة الموافقة النهائية (v3.0)

### القرارات المعمارية الحرجة
- [ ] **(A) Drift أولاً، Supabase لاحقًا** — معتمد ✅
- [ ] لا أعمدة `balance_iqd/balance_usd` في `treasuries` — VIEW + Cache
- [ ] `voucher_sequences` للترقيم Atomic
- [ ] Wizard إعادة الفتح بـ Cascade Lock + Cascade Recompute
- [ ] حالة `frozen_pending_recompute` للفترات المالية
- [ ] جدول `app_blobs` منفصل + OPFS على Web
- [ ] خطوط محلية (Tajawal + Inter) بدل google_fonts

### النطاق
- [ ] الموظفون، المقاولون، الشركاء، الخزائن، السندات، التقارير، الاستيراد، النسخ، الفترات المالية ✅
- [ ] حذف: المنتجات، المخازن، العملاء، الموردين، المشتريات، المبيعات، المرتجعات، الضرائب، الباركود ✅

### قاعدة البيانات
- [ ] توحيد الخزائن (`kind`)
- [ ] توحيد السندات (`voucher_type`)
- [ ] إعادة تسمية إلى `cash_advances` + جدول `cash_advance_repayments`
- [ ] CHECK constraints صارمة
- [ ] Partial indexes
- [ ] Lookup table `voucher_sub_types`

### الأمان
- [ ] bcrypt لكلمات السر
- [ ] Parameterized queries
- [ ] Soft delete
- [ ] Audit log مع ضغط gzip + diff فقط للـ update + احتفاظ 365 يوم + أرشفة
- [ ] AES-256-GCM للنسخ الاحتياطية بكلمة سر اختيارية

### الأدوار
- [ ] 3 طبقات: Super Admin / Admin / User
- [ ] قاعدة "آخر سوبر أدمن"
- [ ] صلاحيات حصرية للأدمن وما فوق

### الفترات المالية
- [ ] yearly الآن + قابلية التوسع
- [ ] انتقال سلس (سنتان نشطتان)
- [ ] إعادة فتح للسوبر أدمن فقط + Cascade

### النسخ الاحتياطي
- [ ] محلي الآن، سحابي Phase 2، Supabase Phase 3
- [ ] افتراضي: كل 6 ساعات + كل 50 سند
- [ ] نسخة قبل العمليات الحساسة (8 عمليات محددة)
- [ ] التشفير اختياري بكلمة سر

### Excel
- [ ] استيراد: Wizard 5 خطوات + Isolate + Transaction
- [ ] Benchmark إجباري في Sprint 11
- [ ] احتياط: syncfusion إن لزم
- [ ] قوالب ديناميكية + ورقة تعليمات

### الواجهة
- [ ] Material 3 + Tajawal/Inter assets + Light/Dark
- [ ] DataTable Pro + Cards + Snackbars + Skeleton
- [ ] Responsive (Web/Tablet/Mobile)

### الاختبارات
- [ ] Unit + Widget + Integration
- [ ] **4 اختبارات انحدار للأرصدة** (CRITICAL)
- [ ] ملفات Excel متنوعة للاختبار

### خطة التنفيذ
- [ ] 15 Sprint = 25 يوم عمل تقديري

---

> **هذه الوثيقة هي المرجع الوحيد. لا تنفيذ قبل الموافقة النهائية.**
> **بانتظار قرارك**
