# سند — نظام إدارة المبيعات والخزينة

> نظام إدارة خزائن ومحاسبة نقدية لشركة مقاولات ومشاريع عراقية
> واجهة عربية RTL بالكامل · المنصة الهدف: ويندوز سطح المكتب

[![tests](https://img.shields.io/badge/tests-316%20passing-brightgreen)]()
[![analyzer](https://img.shields.io/badge/analyzer-0%20issues-brightgreen)]()
[![schema](https://img.shields.io/badge/schema-v6-blue)]()

---

## 📖 التوثيق — ابدأ من هنا

### 👉 **[CLAUDE.md — ذاكرة المشروع](CLAUDE.md)**

نقطة الدخول الوحيدة. تحوي الملخّص والمحاذير وخريطة التوثيق كاملة.

| الملف | متى تقرأه |
|---|---|
| [docs/01-OVERVIEW.md](docs/01-OVERVIEW.md) | ما هو البرنامج وكيف يتدفّق المال فيه |
| [docs/06-SETUP.md](docs/06-SETUP.md) | تشغيله على جهازك من الصفر |
| [docs/03-RULES.md](docs/03-RULES.md) | القوانين الملزمة قبل أي تعديل |
| [docs/02-CODEMAP.md](docs/02-CODEMAP.md) | خريطة الكود والكود الميت |
| [docs/04-STATUS.md](docs/04-STATUS.md) | ما أُنجز وما تبقّى |
| [docs/05-LESSONS.md](docs/05-LESSONS.md) | كل عطل واجهناه وكيف حُلّ |

---

## ⚡ تشغيل سريع

```bash
flutter pub get
```
```bash
dart run build_runner build --delete-conflicting-outputs
```
```bash
flutter run -d windows
```

> ⚠️ خطوة `build_runner` **إلزامية** — الملفات المولَّدة ليست في المستودع.

التفاصيل الكاملة في [docs/06-SETUP.md](docs/06-SETUP.md).

---

## 🧱 التقنيات

**Flutter** · **Drift** (SQLite) · **Riverpod** · **go_router** · **Material 3**
· bcrypt · AES-256-GCM · Freezed · fl_chart · pdf

---

## 🎯 ما يفعله

- **السنوات المالية** — تسلسل أرقام سندات ذرّي لكل سنة · حماية الفترات المُقفَلة
- **الخزائن** — رئيسية ومقاولين وشركاء · **الرصيد محسوب لا مخزَّن**
- **السندات** — قبض · صرف · تحويل (سندان توأمان ذرّيان) · حذف ناعم دائماً
- **سلف المشاريع** — استيراد إكسل → مسودة لا تمسّ الدفاتر → مراجعة → اعتماد
  ذرّي · العجز مُثبَّت مع اسم من غطّاه
- **الموظفون** — رواتب وسلف وتسديد بأقساط
- **التقارير** — كشف حساب · ملخص يومي · تقرير فترة · تقارير السلف
- **الأمان** — RBAC بثلاثة مستويات · سجل تدقيق كامل · نسخ احتياطي مشفَّر

---

## ✅ التحقق

```bash
flutter analyze
```
```bash
flutter test
```

**الشرطان إلزاميان:** المحلّل 0 مشاكل · الاختبارات كلها ناجحة ولا ينخفض عددها
عن **316**. راجع [docs/03-RULES.md](docs/03-RULES.md).

---

## 📄 الترخيص

مشروع خاص — غير منشور على pub.dev.
