# 🗺️ خريطة الكود — ما يوجد وما يُستعمَل وما هو ميت

> **آخر تحديث: 2026-08-23 (بعد ب-٢)** · العودة إلى [ذاكرة المشروع](../CLAUDE.md)

**الغرض من هذا الملف:** قبل أن تكتب أي كود جديد، اقرأ هنا. أكثر من ثلث
الأدوات المساعدة في هذا المشروع كُتبت ثم **لم تُستعمَل قط** — لأن أحداً لم يكن
يعرف بوجودها. هذا الملف يمنع تكرار ذلك: يخبرك بما هو موجود وجاهز، وبما هو
موجود ومهجور فلا تبنِ عليه.

---

## ١. المعمارية — أربع طبقات

```
lib/
├── core/          الأدوات والخدمات المشتركة (لا تعرف شيئاً عن الواجهة)
├── data/          الجداول + DAOs + Repositories (تنفيذ الوصول للبيانات)
├── domain/        النماذج والواجهات (العقود المجرَّدة)
└── presentation/  الشاشات + Providers (كل ما يراه المستخدم)
```

**اتجاه الاعتماد:** `presentation` → `domain` ← `data`، و`core` متاحة للجميع.
لا تجعل `data` أو `core` تعرف شيئاً عن `presentation`.

---

## ٢. `core/` — الخدمات والأدوات

### ✅ مُستعمَلة وحيّة

| الملف | ما يفعله | متى تستعمله |
|---|---|---|
| `services/auth_service.dart` | bcrypt في isolate: `hashPassword` · `verifyPassword` | أي تحقّق من كلمة مرور أو رمز سرّي |
| `services/balance_guard.dart` | `checkSufficientBalance` (إنشاء) · `checkEditImpact` (تعديل) | **إلزامي** في أي مسار يُخرج مالاً |
| `services/fiscal_period_guard.dart` | `ensureActive` — يرمي إن كانت الفترة مُقفَلة | **إلزامي** قبل أي كتابة محاسبية |
| `services/backup_crypto_service.dart` | AES-256-GCM + PBKDF2 · صيغة SMBAK2 | النسخ الاحتياطي المشفَّر |
| `services/cloud_backup_service.dart` | نسخة محلية إضافية (**ليست سحابة** — التسمية صادقة) | نسخة ثانية على الجهاز |
| `services/smart_alert_service.dart` | تنبيهات: رصيد منخفض · سلف معلّقة قديمة | شريط التنبيهات في لوحة التحكم |
| `services/pdf_service.dart` + `pdf_print_helper.dart` | توليد وطباعة PDF | التقارير والسندات |
| `auth/permissions.dart` | **مصدر الحقيقة الوحيد للصلاحيات** — `AppPermission` + `user.can()` | أي فحص صلاحية. **لا تكتب `role == 'admin'` يدوياً أبداً** |
| `utils/audit_logger.dart` | ١٩ دالة تسجيل جاهزة | **إلزامي** بعد أي عملية حساسة |
| `constants/app_routes.dart` | مسارات go_router | أي تنقّل |
| `constants/app_settings_keys.dart` | مفاتيح الإعدادات | **لا تكتب مفتاح إعداد كنصّ حرفي** |
| `theme/app_theme.dart` · `app_colors.dart` · `app_text_styles.dart` | الثيم Material 3 | التصميم |
| `router/app_router.dart` | go_router + حماية المسارات بـ RBAC | إضافة شاشة جديدة |

### 🟠 حيّة جزئياً — استعملها بدل كتابة بديل

| الملف | الحالة | ما يجب فعله |
|---|---|---|
| `utils/currency_formatter.dart` | مستعملة في **ملف واحد** فقط (`balance_guard`) | استعملها في كل عرض للمبالغ بدل التنسيق اليدوي المتكرّر |
| `extensions/date_extensions.dart` | مستعملة جزئياً | راجعها قبل كتابة أي منطق تواريخ |
| `extensions/string_extensions.dart` · `number_extensions.dart` · `build_context_extensions.dart` | استعمال متفرّق | راجعها أولاً |

### ❌ كود ميت — **صفر استدعاء في كامل المشروع**

| الملف | الحجم | القرار |
|---|---|---|
| `errors/app_exception.dart` | ٢١ KB | **لا تبنِ عليه.** إمّا يُوصَل فعلياً أو يُحذف — قرار مؤجَّل |
| `utils/input_validators.dart` | ١١ KB | **لا تبنِ عليه.** التحقق يتم يدوياً في كل شاشة حالياً |
| `l10n/` كله (`app_ar.arb` · `app_en.arb` · `generated/`) | — | مولَّد بالكامل و**صفر استخدام**. كل النصوص عربية مكتوبة يدوياً في الكود. مبدّل اللغة مقفل بصدق. **خارج النطاق** بقرار المنصة |
| `domain/usecases/` | مجلد فارغ | منطق الأعمال في Repositories والProviders |
| `data/database/migrations/` | مجلد فارغ | الترقيات في `app_database.dart` |
| `presentation/widgets/forms/` | مجلد فارغ | — |

> 📌 **القاعدة:** إن احتجت تحقّقاً من مدخلات أو صنف استثناء — **افحص الملفات
> الميتة أعلاه أولاً**. إمّا تستعملها فتحييها، أو تقرّر حذفها. لا تكتب بديلاً
> ثالثاً يزيد الفوضى.

---

## ٣. `data/` — طبقة البيانات

### الجداول (`data/database/tables/`)

| الجدول | الغرض | ملاحظات حرجة |
|---|---|---|
| `users` | المستخدمون | `password_hash` bcrypt · قفل الحساب |
| `app_settings` · `app_blobs` | إعدادات مفتاح/قيمة + ملفات (الشعار) | |
| `fiscal_periods` | السنوات المالية | `status`: active / frozen / frozen_pending_recompute |
| `voucher_sequences` | تسلسل أرقام السندات | مفتاح مركّب (فترة + نوع) · **ذرّي** |
| `treasuries` | الخزائن | موحّد بحقل `kind` · **الرصيد ليس هنا** |
| `vouchers` | **قلب النظام** | `transfer_group_id` يربط التوأمين · `advance_id` يربط بالسلفة · حذف ناعم |
| `employees` · `cash_advances` · `cash_advance_repayments` · `salary_payments` | الموارد البشرية | ⚠️ `cash_advances` = سلفة **موظف** |
| `contractors` · `partners` | الأطراف الخارجية | |
| `advances` · `advance_lines` · `item_types` | **سلف المشاريع** (Schema v5) | ⚠️ ≠ `cash_advances` |
| `exchange_rates` · `audit_log` | مساعدة | |

**الـ VIEW:** `views/treasury_balance_view.dart` — `v_treasury_balances`.
**مصدر الحقيقة الوحيد للأرصدة.** يُعاد بناؤه في كل ترقية.

### DAOs (`data/database/daos/`) — الحُرّاس العميقة

| الـ DAO | دوال يجب أن تعرفها |
|---|---|
| `vouchers_dao` | `getExpensesByItemType()` تجميع المصروفات · `watchUsedItemTypes/Projects()` · `generateTransferGroupId()` · `insertTransfer()` (معاملة) · `softDeleteVoucher()` (يحذف التوأم ويفكّ ربط السلفة) |
| `fiscal_periods_dao` | `getNextVoucherNumber()` **ذرّية** · `findOverlappingPeriod()` · `insertPeriod()` **يحرس التقاطع** · `deleteEmptyPeriod()` · `purgeFiscalPeriodCompletely()` 🔥 |
| `advances_dao` | `getDeficitCreditors()` من تدين لهم الشركة · `postAdvance()` **ذرّية** · `cancelAdvance()` · `getSentAmount()` · `getPostedSpent()` |
| `users_dao` | `registerFailedLogin()` **زيادة ذرّية** · `updatePasswordHash()` |
| `treasuries_dao` | `getTreasuryBalance()` — يقرأ من الـ VIEW |
| `audit_log_dao` | `logSimpleAction()` · `getLogsByTable()` · `getRecentLogs()` |
| `app_settings_dao` | `getString/setString` · `getBool/setBool` · `getBlob/setBlob` |

### Repositories (`data/repositories/`) — قواعد العمل

| الملف | الحُرّاس بداخله |
|---|---|
| `voucher_repository.dart` | منع تعديل التحويل · منع نقل السند بين السنوات · حارس الفترة · كتابة `updated_at`/`updated_by` |
| `advance_repository.dart` | `postAdvance` — الفترة مفتوحة · حساب العجز · طلب اسم من غطّاه |
| `user_repository` · `treasury_repository` · `settings_repository` | CRUD مع تحويل النماذج |

---

## ٤. `presentation/` — الواجهة

### الشاشات العشرون

| الشاشة | المسار | ملاحظة |
|---|---|---|
| `splash_screen` · `login_screen` · `first_run_screen` | خارج الـ Shell | |
| `dashboard_screen` + `dashboard_charts` | `/dashboard` | بيانات حقيقية (`weeklyLiquidity`) |
| `vouchers_list_screen` | `/vouchers` | ٤ تبويبات · فلاتر: بحث · خزينة · **بند · مشروع** (ب-١) |
| `voucher_sarf_screen` · `voucher_kabd_screen` | `/vouchers/sarf` · `/kabd` | ⚠️ **~١١٠٠ سطر مكرّر بينهما** |
| `voucher_transfer_screen` | `/vouchers/transfer` | ربط اختياري بسلفة |
| `treasuries_screen` | `/treasury` | تحذير المسودات المعلّقة |
| `advances_list_screen` · `advance_review_screen` | `/advances` | شاشة المراجعة أهمّها |
| `employees_screen` | `/employees` | **٩٦ KB — أكبر ملف**، مرشّح للتقسيم |
| `contractors_screen` · `partners_screen` | | |
| `reports_screen` + ٣ ملفات تبويبات | `/reports` | **٦ تبويبات** · الودجتات المشتركة في `report_widgets.dart` |
| `excel_import_screen` | `/reports/excel-import` | يُنتج مسودة لا سندات |
| `fiscal_screen` + `purge_period_dialog` | `/fiscal` | إقفال · إعادة فتح · حذف · محو قسري |
| `backup_screen` | `/backup` | معطَّل على الويب |
| `settings_screen` + ٨ تبويبات | `/settings` | |
| `audit_screen` | `/audit` | |

### Providers (`presentation/providers/`)
مولَّدة بـ `riverpod_generator` — بعد أي تعديل شغّل `build_runner`.

أهمها: `voucher_providers` (السندات + الحُرّاس) · `fiscal_providers` (الفترات
+ المحو) · `advance_providers` · `auth_provider` · `database_provider` ·
`repository_providers` · `settings_provider`.

### الودجتات المشتركة (`presentation/widgets/common/`)

| الملف | استعمله بدل إعادة الكتابة |
|---|---|
| `app_components.dart` | مكوّنات مشتركة (حالات فارغة، بطاقات…) — **افحصه قبل بناء ودجت جديد** |
| `reports/report_widgets.dart` | `ReportDateField` · `ReportSummaryCard` · `ReportPlaceholder` — **لأي تبويب تقرير جديد** |
| `item_type_selector.dart` | `ItemTypeSelector` شرائح البنود من جدول `item_types` · `ItemTypeFilterDropdown` قائمة فلترة. **استعملهما — لا تكتب قائمة بنود ثابتة في الكود** |
| `app_shell.dart` | القشرة: NavigationRail / NavigationBar |
| `error_screen.dart` | ٤٠٤ و٤٠٣ |
| `global_search_dialog.dart` | البحث الشامل |
| `smart_alert_banner.dart` | شريط التنبيهات |

---

## ٥. أنماط إلزامية عند كتابة كود جديد

### ✅ حقول النصّ في الحوارات
```dart
// ✅ الصحيح — بلا متحكّم
String notes = '';
TextFormField(
  initialValue: notes,
  onChanged: (v) => notes = v,
)
```
```dart
// ❌ الخطأ — سبّب عطل شاشة حمراء في خمسة مواضع
final ctrl = TextEditingController();
await showDialog(...);
ctrl.dispose();   // الحوار ما زال يُعاد بناؤه!
```
إن احتجت متحكّماً فعلاً (تركيز، تحديد نصّ)، اجعل الحوار `StatefulWidget`
يملكه ويتخلّص منه في `dispose()`. **يحرسه اختبار آلي:**
`test/unit/dialog_controller_lifecycle_test.dart`

### ✅ التقارير: ما يُحتسَب وما لا يُحتسَب
| القاعدة | السبب |
|---|---|
| المصروف = `sarf` فقط | `transfer_out` نقل بين خزائن الشركة — احتسابه يُضخّم الإنفاق مرّتين |
| البند الفارغ يظهر «غير محدد» | استبعاده يجعل مجموع التقرير لا يطابق الدفاتر فتضيع الثقة |
| الدولار بسعر صرف **سنده** | `exchange_rate` مخزَّن لحظة الإنشاء — التقرير التاريخي لا يتغيّر بتحرّك السعر |
| العملتان لا تُجمعان في رقم واحد | تُعرَضان متجاورتين دائماً |

محروسة في `test/unit/expense_reports_test.dart`.

### ✅ قوائم البنود تُقرأ من قاعدة البيانات
```dart
// ✅ الصحيح
ItemTypeSelector(kind: 'sarf', selected: _itemType, onSelected: ...)
```
```dart
// ❌ الخطأ — كان في شاشتَي الصرف والقبض
const _kItemTypes = ['راتب', 'سلفة', ...];   // قائمة ثابتة في الكود
```
جدول `item_types` يديره المالك من الإعدادات. أي قائمة ثابتة تعني أن ما يضيفه
لا يظهر — ميزة معطَّلة بصمت. المصدر الوحيد: `itemTypeNamesProvider`.

### ✅ الغياب يُمثَّل بـ null لا بنصّ فارغ
الأعمدة nullable (`project_name` · `invoice_number` · `spent_by` ·
`advance_number`) — الشاشة تُرسل `''` حين يترك المستخدم الحقل فارغاً، ويحوّلها
`VoucherRepository._orNull` إلى `null`. تخزين `''` يجعل الفلترة والتقارير
تعامله كقيمة قائمة.

### ✅ التحديث الجزئي في Drift
```dart
await (update(vouchers)..where(...)).write(companion);   // ✅
await (update(vouchers)..where(...)).replace(companion); // ❌ يُعيد الغائب لافتراضيه
```

### ✅ موضع الحارس
ضع القاعدة في **أعمق طبقة** — DAO أو Repository — لا في الشاشة.
*حارس في طبقة العرض لا يمرّ به أي اختبار، وقد كلّفنا عطلاً كاملاً.*

### ✅ رسائل الخطأ
عربية، كاملة، **تسمّي المانع بالاسم**: «يتقاطع مع الفترة "2026" (2026/01/01 →
2026/12/31)» لا «يتداخل مع فترة موجودة». تُرمى كـ `StateError` وتُلتقط في
الـ Notifier بـ `on StateError catch (e) => AsyncError(e.message)`.

### ✅ الترتيب عند الحذف
`PRAGMA foreign_keys = ON` مُفعَّل — احذف الابن قبل الأب دائماً:
`advance_lines → advances → vouchers → voucher_sequences → fiscal_periods`

---

## ٦. الاختبارات (`test/`) — ٣٠ ملفاً · ٢٤٨ اختباراً

| المجموعة | الملفات |
|---|---|
| **الأمان** | `auth_lockout` · `permissions` · `backup_crypto` |
| **سلامة الحسابات** | `balance_guard` · `voucher_edit_balance` · `transfer_delete` · `transfer_edit_guard` · `transfer_group_id` · `cumulative_balance` |
| **الفترات المالية** | `fiscal_period_guard` · `voucher_period_guard` · `fiscal_period_overlap` · `fiscal_period_delete` · `fiscal_period_purge` |
| **أثر التدقيق** | `audit_trail_and_reset` |
| **السلف** | `advance_posting` · `advance_repayment` · `excel_row_parser` |
| **الـ Schema** | `database` · `schema_v4` · `schema_v5` |
| **حقول التتبّع** | `voucher_tracking_fields` · `voucher_filter_values` |
| **التقارير** | `expense_reports` ← يحرس **قرارات محاسبية** لا كوداً |
| **حرّاس الأنماط** | `dialog_controller_lifecycle` ← يفحص **المصدر** لا السلوك |
| **الأدوات** | `input_validators` · `currency_formatter` · `extensions` · `services` |

⚠️ **حدّ بنيوي:** `flutter test` يعمل على الـ VM بـ `NativeDatabase` — فهو
**عاجز بنيوياً** عن كشف أخطاء الويب. لا يعوّضه إلا تشغيل فعلي على المنصة.

---

## ٧. التبعيات — لا تُضاف واحدة بلا موافقة المالك

**الأساسية:** `drift` · `drift_flutter` · `sqlite3` · `sqlite3_flutter_libs` ·
`flutter_riverpod` · `riverpod_annotation` · `go_router` · `freezed_annotation`
· `json_annotation` · `bcrypt` · `flutter_secure_storage` · `pointycastle` ·
`excel` · `file_picker` · `path_provider` · `path` · `flutter_animate` ·
`image_picker` · `intl` · `fl_chart` · `printing` · `pdf`

**أُزيلت ١٦ تبعية غير مستعملة** (تدقيق 2026-08-07) — لا تُعِدها بلا سبب.
`archive` متاحة **بشكل غير مباشر** عبر `excel` — استعمالها من كودنا يتطلّب
إعلانها صراحةً، وهو قرار مالك.
