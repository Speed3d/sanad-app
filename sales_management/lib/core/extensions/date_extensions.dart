// ─────────────────────────────────────────────────────────────────────────────
// date_extensions.dart — امتدادات التاريخ والوقت
//
// هذا الملف يُضيف دوالاً مساعدة على DateTime لتنسيق التواريخ
// بالعربي وتسهيل المقارنات الشائعة.
//
// الغرض:
//   توحيد تنسيق التواريخ في التطبيق بدلاً من تكرار كود الـ DateFormat
//   في كل مكان.
//
// كيفية الاستخدام:
//   final date = DateTime.now();
//   date.toDateString()       → '06/08/2026'
//   date.toDateTimeString()   → '06/08/2026 17:30'
//   date.toArabicDate()       → 'الأربعاء، 6 أغسطس 2026'
//   date.toTimeString()       → '17:30'
//   date.toFileSafeString()   → '2026-08-06_17-30'  (للأسماء في الملفات)
//   date.isToday              → true/false
//   date.isYesterday          → true/false
//   date.isSameDay(other)     → true/false
//
// ملاحظة حول الـ intl:
//   هذا الملف يعتمد على حزمة intl لتنسيق التواريخ.
//   يجب استيراد intl في pubspec.yaml (وهو موجود بالفعل).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:intl/intl.dart';

/// امتدادات DateTime — تنسيق التواريخ والمقارنات
extension DateExtensions on DateTime {
  // ── التنسيق الأساسي ───────────────────────────────────────────────────────

  /// تنسيق التاريخ فقط بالصيغة (يوم/شهر/سنة)
  ///
  /// مثال: DateTime(2026, 8, 6) → '06/08/2026'
  String toDateString() {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  /// تنسيق التاريخ والوقت معاً
  ///
  /// مثال: DateTime(2026, 8, 6, 17, 30) → '06/08/2026 17:30'
  String toDateTimeString() {
    return DateFormat('dd/MM/yyyy HH:mm').format(this);
  }

  /// تنسيق الوقت فقط (ساعة:دقيقة)
  ///
  /// مثال: DateTime(2026, 8, 6, 17, 30) → '17:30'
  String toTimeString() {
    return DateFormat('HH:mm').format(this);
  }

  /// تنسيق التاريخ بالكامل مع الوقت والثواني (للـ Audit Log)
  ///
  /// مثال: → '06/08/2026 17:30:45'
  String toFullDateTimeString() {
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(this);
  }

  // ── التنسيق العربي ────────────────────────────────────────────────────────

  /// تنسيق التاريخ بالعربي مع اليوم الكامل
  ///
  /// مثال: → 'الأربعاء، 6 أغسطس 2026'
  String toArabicDate() {
    return DateFormat('EEEE، d MMMM yyyy', 'ar').format(this);
  }

  /// تنسيق التاريخ بالعربي بدون اسم اليوم
  ///
  /// مثال: → '6 أغسطس 2026'
  String toArabicDateShort() {
    return DateFormat('d MMMM yyyy', 'ar').format(this);
  }

  /// تنسيق الشهر والسنة فقط بالعربي
  ///
  /// مثال: → 'أغسطس 2026'
  /// الاستخدام: لعناوين التقارير الشهرية
  String toArabicMonthYear() {
    return DateFormat('MMMM yyyy', 'ar').format(this);
  }

  /// تنسيق ذكي يعرض 'اليوم', 'أمس', أو التاريخ الكامل
  ///
  /// مثال:
  ///   (اليوم)    → 'اليوم، 17:30'
  ///   (أمس)      → 'أمس، 09:15'
  ///   (غير ذلك)  → '06/08/2026'
  String toSmartDate() {
    if (isToday) return 'اليوم، ${toTimeString()}';
    if (isYesterday) return 'أمس، ${toTimeString()}';
    return toDateString();
  }

  // ── اسم آمن للملفات ───────────────────────────────────────────────────────

  /// تنسيق التاريخ صالح لاستخدامه في اسم الملف (بدون أحرف خاصة)
  ///
  /// مثال: → '2026-08-06_17-30'
  /// الاستخدام: أسماء ملفات النسخ الاحتياطي وتصدير Excel
  String toFileSafeString() {
    return DateFormat('yyyy-MM-dd_HH-mm').format(this);
  }

  /// تنسيق ISO 8601 لتخزينه في قاعدة البيانات
  ///
  /// مثال: → '2026-08-06T17:30:00'
  String toIsoString() {
    return toIso8601String().substring(0, 19);
  }

  // ── التسمية النصية للفترات ────────────────────────────────────────────────

  /// نص وصف الفترة المالية السنوية
  ///
  /// مثال: DateTime(2026, 1, 1) → 'السنة المالية 2026'
  String toFiscalYearLabel() => 'السنة المالية $year';

  /// نص وصف الفترة الشهرية
  ///
  /// مثال: DateTime(2026, 8, 1) → 'أغسطس 2026'
  String toMonthLabel() => toArabicMonthYear();

  // ── دوال المقارنة ─────────────────────────────────────────────────────────

  /// هل هذا التاريخ هو اليوم؟
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// هل هذا التاريخ هو الأمس؟
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// هل هذا التاريخ هو الغد؟
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// هل هذا التاريخ في نفس اليوم مع تاريخ آخر؟
  ///
  /// [other] — التاريخ المراد المقارنة معه
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// هل هذا التاريخ في نفس الشهر والسنة مع تاريخ آخر؟
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }

  /// هل هذا التاريخ قبل اليوم؟ (ليس اليوم، بل قبله)
  bool get isPast {
    final now = DateTime.now();
    return isBefore(DateTime(now.year, now.month, now.day));
  }

  /// هل هذا التاريخ في المستقبل؟ (بعد اليوم)
  bool get isFuture {
    final now = DateTime.now();
    return isAfter(DateTime(now.year, now.month, now.day + 1)
        .subtract(const Duration(seconds: 1)));
  }

  // ── الحسابات المساعدة ─────────────────────────────────────────────────────

  /// بداية اليوم (00:00:00)
  DateTime get startOfDay => DateTime(year, month, day);

  /// نهاية اليوم (23:59:59.999)
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// بداية الشهر (اليوم الأول 00:00:00)
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// نهاية الشهر (آخر يوم 23:59:59.999)
  DateTime get endOfMonth {
    // اليوم الأول من الشهر التالي ناقص ثانية واحدة
    return DateTime(year, month + 1, 1)
        .subtract(const Duration(milliseconds: 1));
  }

  /// بداية السنة (1 يناير 00:00:00)
  DateTime get startOfYear => DateTime(year, 1, 1);

  /// نهاية السنة (31 ديسمبر 23:59:59.999)
  DateTime get endOfYear =>
      DateTime(year + 1, 1, 1).subtract(const Duration(milliseconds: 1));

  /// فرق الأيام من هذا التاريخ حتى تاريخ آخر
  ///
  /// [other] — التاريخ الثاني
  /// يُعيد قيمة موجبة إذا كان [other] في المستقبل، سالبة إذا كان في الماضي
  int daysDifference(DateTime other) {
    return other.difference(this).inDays;
  }
}

/// امتدادات DateTime? — لدعم القيم القابلة للـ null
extension NullableDateExtensions on DateTime? {
  /// تنسيق التاريخ أو عرض نص بديل إذا كان null
  ///
  /// [fallback] — النص البديل عند القيمة null (افتراضي: '—')
  String toDateStringOrDefault([String fallback = '—']) {
    return this?.toDateString() ?? fallback;
  }

  /// تنسيق التاريخ والوقت أو عرض نص بديل
  String toDateTimeStringOrDefault([String fallback = '—']) {
    return this?.toDateTimeString() ?? fallback;
  }

  /// تنسيق التاريخ الذكي أو عرض نص بديل
  String toSmartDateOrDefault([String fallback = '—']) {
    return this?.toSmartDate() ?? fallback;
  }
}
