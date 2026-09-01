# 🗺️ خريطة الكود — ما يوجد وما يُستعمَل وما هو ميت

> **آخر تحديث: 2026-08-25** · العودة إلى [ذاكرة المشروع](../CLAUDE.md)

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
| `services/treasury_state_guard.dart` | **حارس الخزينة المعطَّلة/المحذوفة** — `ensureActive` · `ensureTransferAllowed` | **إلزامي** قبل أي حركة مالية جديدة على خزينة |
| `services/fiscal_period_guard.dart` | `ensureActive` — يرمي إن كانت الفترة مُقفَلة | **إلزامي** قبل أي كتابة محاسبية |
| `services/payroll_name_matcher.dart` | **مطابقة أسماء الموظفين** — تطبيع عربي + مفتاح (الاسم، تاريخ التعيين) | أي مطابقة اسم موظف. **لا تقارن أسماء عربية حرفياً** |
| `services/payroll_row_parser.dart` | تحليل صف ملف الرواتب + مقارنة الصافي بالمذكور | استيراد الرواتب |
| `utils/sheet_value_parser.dart` | **تحليل قيم خلايا الإكسل** — تاريخ · مبلغ · عدد · كشف العملة الأجنبية · أرقام عربية | أي استيراد. **مشترك بين مستوردَي السلف والرواتب** |
| `utils/excel_sheet_reader.dart` | قراءة ملف `.xlsx` إلى شبكة نصوص مسوّاة + بصمته | أي استيراد — **لا تقرأ خلايا إكسل يدوياً** |
| `services/payroll_calculator.dart` | **حساب الرواتب** — نقيّ بلا قاعدة بيانات: الأيام المستحقّة · خصم الغياب · الصافي · المقابل بالدينار · حرّاس التسديد | أي حساب راتب. **لا تحسب صافياً يدوياً في شاشة أو DAO** |
| `services/report_print_data.dart` + `pdf_report_documents.dart` | **مستند التقرير الجدوليّ العام** — نموذج نقيّ بصفوف منسَّقة مسبقاً، ومولّد واحد يخدم التقارير الستّة | أي طباعة تقرير. **لا تكتب مولّد PDF سابعاً** |
| `services/excel_export_service.dart` | تصدير **xlsx مُنسَّق**: ترويسة · حدود · عرض أعمدة · **RTL** · والأرقام أرقاماً لا نصّاً | أي تصدير. CSV لا يحمل تنسيقاً بنيوياً فاستُبدل |
| `services/backup_service.dart` | **النسخة الشاملة**: `exportFull` · `inspect` · `restoreFull` — القاعدة مشفَّرة + المرفقات + بيان JSON | أي عمل على النسخ الاحتياطي. **لا تكتب منطق نسخ في الودجت** — هناك عاش ع-٤١ |
| `services/factory_reset_service.dart` | **تصفير المصنع** — ثلاث طبقات حراسة (صلاحية · كلمة مرور · رمز محو) ثم `db.factoryReset()` ثم حذف ملفات المرفقات | الزرّ الوحيد الذي يمحو التطبيق كلّه. **لا تكتب حارساً رابعاً في الشاشة** — الحُرّاس هنا وحدها تمرّ باختبار |
| `services/backup_crypto_service.dart` | AES-256-GCM + PBKDF2 · صيغة SMBAK2 | النسخ الاحتياطي المشفَّر |
| `services/cloud_backup_service.dart` | نسخة محلية إضافية (**ليست سحابة** — التسمية صادقة) | نسخة ثانية على الجهاز |
| `services/attachment_service.dart` | نسخ المرفقات · بصمة SHA-256 · تنقية المسارات · الفتح عبر `explorer` · و`deleteAllInStore` لتصفير المصنع (يمحو **المفهرَس** لا المجلد) | أي تعامل مع ملفات المرفقات — **لا تلمس نظام الملفات مباشرةً** |
| `services/smart_alert_service.dart` | تنبيهات: رصيد منخفض · سلف معلّقة قديمة | شريط التنبيهات في لوحة التحكم |
| `services/pdf_service.dart` + جزآن `pdf_payroll_documents.dart` و`pdf_report_documents.dart` + `pdf_print_helper.dart` | توليد وطباعة PDF + `PdfCompanyHeader` (الشعار والاسم). **مستندات الرواتب الثلاثة في `part` لا خدمة ثانية** — مسار الخطوط العربية واحد | طباعة السندات والرواتب. ⚠️ `printVaultStatement` و`printAdvanceReport` **بصفر استدعاء** |
| `services/payroll_print_data.dart` | نماذج مستندات الرواتب **النقيّة** (كشف · إيصال · تقرير سنة · **تقرير موظف**) — بلا Drift، فتبقى `PdfService` جاهلةً بقاعدة البيانات | أي طباعة رواتب. **الإجماليات حقولٌ تُمرَّر لا تُحسَب في المستند** |
| `auth/permissions.dart` | **مصدر الحقيقة الوحيد للصلاحيات** — `AppPermission` + `user.can()` | أي فحص صلاحية. **لا تكتب `role == 'admin'` يدوياً أبداً** |
| `utils/audit_labels.dart` | **تعريب سجل التدقيق** — أسماء العمليات السبعة عشر والجداول | أي عرض لسجل التدقيق. **لا تكتب ترجمة في الشاشة** |
| `utils/audit_logger.dart` | ١٩ دالة تسجيل جاهزة | **إلزامي** بعد أي عملية حساسة |
| `constants/app_routes.dart` | مسارات go_router | أي تنقّل |
| `constants/app_settings_keys.dart` | مفاتيح الإعدادات | **لا تكتب مفتاح إعداد كنصّ حرفي** |
| `theme/app_theme.dart` · `app_colors.dart` · `app_text_styles.dart` | الثيم Material 3 | التصميم |
| `theme/app_theme_extension.dart` | **`AppPalette`** — ألوان سند كامتداد ثيم | **`context.colors.x`** بدل أي شرط `isDark ?` |
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
| ~~`errors/app_exception.dart`~~ | — | ✅ **حُذف** (المرحلة د) — كان يكرّر نمط `StateError` القائم. المشروع يرمي `StateError` برسالة عربية كاملة تعرضها الواجهة |
| ~~`utils/input_validators.dart`~~ | — | ✅ **أُحيي ووُصِّل** (المرحلة د) — استعمله في أي تحقّق جديد بدل كتابة مدقّق يدوي |
| `l10n/` كله (`app_ar.arb` · `app_en.arb` · `generated/`) | — | مولَّد بالكامل و**صفر استخدام**. كل النصوص عربية مكتوبة يدوياً في الكود. **خارج النطاق** بقرار المنصة |
| ~~الجرد القديم~~ | — | ✅ **كُنِس بالكامل** (المرحلة ١٦د — 2026-08-30): ملفان + `FiscalPeriodModel` + ٣ مزوّدات + ~٢٥ دالة + ٧ مسارات. وما بقي مستثنىً عمداً: دوال ربط المقاولين/الشركاء بالخزائن — بانتظار قرار المالك |

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
| `employees` · `cash_advances` · `cash_advance_repayments` | الموارد البشرية | ⚠️ `cash_advances` = سلفة **موظف** · `employees.treasury_id` = **رابط المشروع** |
| `payroll_periods` | **كشف رواتب شهر** (Schema v7) | فهرس فريد `(year, month)` ⇒ لا كشفان لشهر واحد |
| `salary_payments` | **سطر كشف الرواتب** (تغيّر معناه في v7) | يحمل **لقطة** الموظف لحظة الشهر · فريد `(كشف، موظف)` · سطور الدفعة الواحدة تشترك في `voucher_id` |
| `contractors` · `partners` | الأطراف الخارجية | |
| `advances` · `advance_lines` · `item_types` | **سلف المشاريع** (Schema v5) | ⚠️ ≠ `cash_advances` |
| `attachments` | فهرس مرفقات السلف والسندات (Schema v6) | **المسار نسبي لا مطلق** · `entity_id` بلا مفتاح خارجي (يشير لجدولين) |
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
| `attachments_dao` | `watchForEntity()` · `findDuplicate()` · `deleteForEntity()` **يُعيد الصفوف** ليحذف المستدعي ملفاتها |
| `advances_dao` | **+Schema v7**: `linkLineToPayroll()` · `getPayrollLinkPreviews()` · و**حارس المطابقة داخل `postAdvance`** يمنع احتساب المال مرّتين |
| `advances_dao` | **+الدفعة ج**: `searchByItemType()` البحث بالبند داخل السلف (لا يعدّ المستبعَد) · `getLinesForAdvances()` أسطر عدّة سلف باستعلام واحد |
| `payroll_dao` | `payEntries()` **ذرّية** (سند واحد + السطور + أقساط السلف) · `getTotals()` **مصدر الحقيقة الوحيد للمجموع** · `getYears()` تشتقّ السنوات · `findByFileHash()` · `getYearMonths()` و`getYearTreasuryShares()` و`getOutOfSheetSalaries()` لتقرير السنة |
| `payroll_dao_reports.dart` | جزء (`mixin`) — **قراءة فقط**: تقرير الموظف والسنة · و`getStalePaidPayrolls()` **الكاشف المرآة**: سطورٌ «مسدَّدة» فقدت سندها |
| `payroll_dao_reversals.dart` | جزء (`mixin`) — **كل ما يعكس راتباً خرج ماله**: `unpayEntry` · `correctPaidEntry` · `unpayEntriesForAdvance` · `recordSalaryDeductions` (المسار الوحيد لأقساط السلف). مصدر ستة أعطال متتالية فجُمعت لتُقرأ ككتلة |
| `audit_log_dao` | `logSimpleAction()` · `getLogsByTable()` · `getRecentLogs()` |
| `app_settings_dao` | `getString/setString` · `getBool/setBool` · `getBlob/setBlob` |

### Repositories (`data/repositories/`) — قواعد العمل

| الملف | الحُرّاس بداخله |
|---|---|
| `voucher_repository.dart` | منع تعديل التحويل · منع نقل السند بين السنوات · حارس الفترة · كتابة `updated_at`/`updated_by` |
| `advance_repository.dart` | `postAdvance` — الفترة مفتوحة · حساب العجز · طلب اسم من غطّاه |
| `payroll_repository.dart` | الفترة مفتوحة · لا دولار بلا سعر صرف · لا صافي سالب · كفاية الرصيد · منع التعديل والتسديد المزدوج · و`buildSheetPrintData` / `buildSlipPrintData` / `buildYearReport` — **تجميع بيانات الطباعة من `getTotals` لا بجمع جديد** |
| `payroll_repository_reports.dart` | جزء (`mixin`) — بناء بيانات المستندات والتقارير · لا يُعيد حساب أي مجموع |
| `payroll_repository_corrections.dart` | جزء (`mixin`) — **عمليات ما بعد التسديد**: إلغاء التسديد · التصحيح بوضعَيه · `unpayPeriod` (الشهر كلّه) · تنظيف السندات اليتيمة وإصلاح الرواتب العالقة. كلها بسببٍ إلزامي وفترة مفتوحة |
| `user_repository` · `treasury_repository` · `settings_repository` | CRUD مع تحويل النماذج |

---

## ٤. `presentation/` — الواجهة

### الشاشات العشرون

| الشاشة | المسار | ملاحظة |
|---|---|---|
| `splash_screen` · `login_screen` · `first_run_screen` | خارج الـ Shell | |
| `dashboard_screen` + `dashboard_charts` | `/dashboard` | **بطاقات الخزائن** بدل الإجمالي · ٣ مخططات · بيانات حقيقية · **مبدّل عملة** يظهر حين يوجد دولار (الدفعة ج) |
| `vouchers_list_screen` + جزء | `/vouchers` | ٤ تبويبات · بحث في **٩ حقول** · فلاتر: خزينة · بند · مشروع · **نطاق تاريخ ومبلغ**. قُسِّم بـ `part`: `vouchers_list_widgets` |
| `voucher_sarf_screen` · `voucher_kabd_screen` | `/vouchers/sarf` · `/kabd` | ✅ الودجتات المشتركة في `voucher_form_widgets.dart` |
| `voucher_transfer_screen` | `/vouchers/transfer` | ربط اختياري بسلفة |
| `treasuries_screen` + جزء | `/treasury` | تحذير المسودات المعلّقة · قُسِّم بـ `part`: `treasury_card` |
| `advances_list_screen` · `advance_review_screen` | `/advances` | شاشة المراجعة أهمّها |
| `employees_screen` + جزآن | `/employees` | ✅ قُسِّم بـ `part`: `employee_detail_sheet` · `employee_dialogs` |
| `contractors_screen` · `partners_screen` | | |
| `reports_screen` + ٤ ملفات تبويبات | `/reports` | **٧ تبويبات** (آخرها «الرواتب») · الودجتات المشتركة في `report_widgets.dart` |
| `excel_import_screen` | `/reports/excel-import` | يُنتج مسودة لا سندات |
| `fiscal_screen` + جزء + `purge_period_dialog` | `/fiscal` | إقفال · إعادة فتح · حذف · محو قسري · قُسِّم بـ `part`: `fiscal_period_card` |
| `payroll_periods_screen` | `/payroll` | شبكة الأشهر الاثني عشر — غير المستورَد يظهر «لم يُستورَد بعد» |
| `payroll_sheet_screen` + جزء | `/payroll/:id` | جدول التحرير والتسديد · قُسِّم بـ`part`: `payroll_sheet_widgets` |
| `payroll_import_screen` + جزء `payroll_import_widgets.dart` | `/payroll/import` | معالج أربع خطوات · **مسار `import` قبل `:id` في الموجّه** · يُنبّه على **الموظف المصروف سلفاً** ويبدأ مستبعَداً |
| `payroll_correction_dialogs.dart` | جزء من شاشة الكشف | حوارا **التصحيح بعد التسديد** و**إلغاء التسديد** — سببٌ إلزامي، ومعاينة الفرق قبل وقوعه، وسؤالٌ بلغة المالك: «هل خرج المال فعلاً؟» |
| `payroll_print_actions.dart` | — | **إجراءات الطباعة المشتركة**: الكشف · الإيصال · تقرير السنة · تقرير الموظف. تُستدعى من شاشة الكشف وبطاقة الموظف وتبويب التقرير. **تمسك أخطاءها وتعرضها** (درس ع-٢٥) |
| `reports/payroll_report_tab.dart` | تبويب في `/reports` | تقرير رواتب السنة: الأشهر · توزيع الخزائن · **شريط الرواتب خارج الكشوف** |
| `reports/employee_payroll_report_tab.dart` | تبويب في `/reports` | **تقرير الموظف**: موظف واحد شهراً شهراً بكل بنوده · أو كل موظفي مشروع بمجاميعهم. مدى أشهر · فلتر المشروع يُضيّق القائمة **ويُظهر من موّل كل شهر** |
| `backup_screen` | `/backup` | معطَّل على الويب |
| `settings_screen` + ٩ تبويبات | `/settings` | منها `attachments_tab` (مجلد المرفقات) |
| `audit_screen` | `/audit` | |

### Providers (`presentation/providers/`)
مولَّدة بـ `riverpod_generator` — بعد أي تعديل شغّل `build_runner`.

أهمها: `voucher_providers` (السندات + الحُرّاس) · `fiscal_providers` (الفترات
+ المحو) · `advance_providers` · `auth_provider` · `database_provider` ·
`repository_providers` · `settings_provider`.

| `providers/provider_read_once.dart` | `ref.readOnce(p, p.future)` — قراءة مزوّد غير متزامن **مرّة واحدة** بأمان. `ref.read(p.future)` وحده يُسقط التطبيق بسباق تخلّص (ع-٣٥)، ويحرس النمطَ `tech_debt_guard_test` |

### الودجتات المشتركة (`presentation/widgets/common/`)

| الملف | استعمله بدل إعادة الكتابة |
|---|---|
| `app_components.dart` | مكوّنات مشتركة (حالات فارغة، بطاقات…) — **افحصه قبل بناء ودجت جديد** |
| `password_confirm_dialog.dart` | **تأكيد الهويّة** قبل أي عملية تُرجع مالاً خرج (٦ مواضع). الجلسة المفتوحة تُثبت أن أحداً دخل، لا أن **صاحبها** يضغط الآن |
| `reports/report_widgets.dart` | `ReportDateField` · `ReportSummaryCard` · `ReportPlaceholder` — **لأي تبويب تقرير جديد** |
| `attachments_panel.dart` | `AttachmentsPanel` — لوحة المرفقات للسلف والسندات معاً |
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

### ✅ الألوان من الثيم لا بشرط
```dart
color: context.colors.text          // ✅
color: isDark ? textDark : textLight // ❌ كان ١٦٤ مرة قبل المرحلة د
```
`AppPalette` يحمل ٩ ألوان (`bg` · `surface` · `surface2` · `text` · `subtext`
· `border` · `gold` · `onGold` · `sidebar` · `danger`). يحرس الحدَّ اختبار
`tech_debt_guard_test.dart`.

### 📎 أجزاء المكتبات — أين تجد الصنف

الملفات المقسَّمة بـ `part`. الأصناف فيها **خاصة** (`_X`) لكنها مرئية عبر
المكتبة كلها، فابحث في المجموعة لا في ملف واحد.

| المكتبة | الأجزاء |
|---|---|
| `employees_screen.dart` | `employee_detail_sheet.dart` · `employee_dialogs.dart` · `employee_repayment_sheet.dart` |
| `treasuries_screen.dart` | `treasury_card.dart` |
| `fiscal_screen.dart` | `fiscal_period_card.dart` |
| `vouchers_list_screen.dart` | `vouchers_list_widgets.dart` |

### ✅ الملف الكبير يُقسَّم بـ `part` لا بملف مستقل
`part` يُبقي الأصناف **خاصة** (`_X`) فلا تتسرّب، ولا تحتاج إعادة تسمية.
سوابق: `employees_screen` · `treasuries_screen` · `fiscal_screen`.
**الحدّ ١٢٠٠ سطر** ويحرسه اختبار.

### ✅ المرفقات: المسار نسبي والترتيب مقصود
```
الإرفاق:  انسخ الملف  ثم  سجّل الصفّ
الحذف:    احذف الصفّ  ثم  امحُ الملف
```
في الحالتين الخطأ الأسوأ — **فهرس يشير إلى ملف غير موجود** — مستحيل بنيوياً.
والمسار المخزَّن **نسبي بفاصل `/`** دائماً: نقل المجلد أو تغيّر حرف القرص أو
فتح القاعدة على الماك لا يكسر شيئاً.

### ✅ اختبر `onUpgrade` لا `onCreate` وحده
`schema_v6_upgrade_test.dart` هو **أول اختبار لمسار الترقية في المشروع**.
كل اختبارات المخطط السابقة (v4 · v5) تفحص قواعد **جديدة** فقط — بينما
`onUpgrade` هو الشيفرة الوحيدة التي تلمس بيانات المالك الموجودة.
أي ترحيل جديد يجب أن يمرّ باختبار مثله.

### ✅ تسمية السلف — لا تكتب «سلفة» وحدها
`Advances` (مشروع) و`CashAdvances` (موظف) يحملان الاسم نفسه بالعربية.
**القاعدة:** حيثما ظهر اللفظ **خارج** شاشة الموظفين أو شاشة سلف المشاريع،
اكتب **«سلفة موظف»** أو **«سلفة مشروع»** صراحةً — التنقّل والتنبيهات
وبيانات السندات ورسائل الصلاحيات وتبويبات التقارير.

⚠️ نوع البند المخزَّن لسلف الموظفين هو `'سلفة'` حرفياً — تمييزه يحتاج ترحيل
بيانات (Schema v6) وموافقة المالك. لا تغيّره في الكود وحده وإلا انقسم البند
في تقرير «المصروفات حسب البند» إلى قيمتين.

### ✅ طبقة core لا تعرف قاعدة البيانات
`PdfService` تستقبل `PdfCompanyHeader` جاهزاً بدل قراءة الإعدادات بنفسها.
لولا ذلك لانعكس اتجاه الاعتماد ولصار توليد الـ PDF غير قابل للاختبار بلا
قاعدة بيانات. يحرسه اختبار في `company_identity_test.dart`.

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

## ٦. الاختبارات (`test/`) — ٥٧ ملفاً · ٧٥٤ اختباراً

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
| **المرفقات** | `schema_v6` · `attachment_service` |
| **الترقية** | `schema_v6_upgrade` · `schema_v7_upgrade` ← **يختبران `onUpgrade` على بيانات مزروعة** |
| **الرواتب** | `payroll_calculator` (نقيّ · ٤٢) · `payroll_import` (التطبيع والمطابقة) · `payroll_posting` (الحرّاس والذرّية) · `payroll_advance_link` · `schema_v7` |
| **تقرير الرواتب** | `payroll_report` ← يحرس أن مجموع التقرير = `getTotals` لكل كشف · وحارس **ع-٢٨** (لا راتب بلا مقابله بالدينار) |
| **مستندات الرواتب** | `payroll_pdf` ← الخطوط العربية · الورقة **عرضية** · ٥٠ سطراً تُقسَّم على صفحات |
| **الودجت** | `widget/payroll_screens_test` ← **أول اختبار عرض حقيقي**: يمسك التجاوز الأفقي والعمودي والشاشة الحمراء · ويغطّي تبويب التقرير **بسنة كاملة** لا بشهر |
| **هوية الشركة** | `company_identity` ← يحرس أيضاً أن `PdfService` لا تعرف قاعدة البيانات |
| **النسخ الاحتياطي** | `backup_service` ← **الدورة الكاملة على قرص حقيقي**: صدّر ⇒ صفّر ⇒ استعد ⇒ الصفوف والملفات عادت. وقاعدته **ملفّية** لا في الذاكرة، وإلا لم تُختبَر الاستعادة أصلاً |
| **تصفير المصنع** | `factory_reset` ← يمرّ على **العشرين جدولاً** فيمسك أي جدول ينساه المحو، ويحرس ترتيب الحذف والحُرّاس الثلاثة |
| **حرّاس الأنماط** | `dialog_controller_lifecycle` · **`tech_debt_guard`** ← يفحصان **المصدر** لا السلوك |
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
