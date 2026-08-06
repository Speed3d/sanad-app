// ─────────────────────────────────────────────────────────────────────────────
// string_extensions.dart — امتدادات النصوص والسلاسل الحرفية
//
// هذا الملف يُضيف دوالاً مساعدة على String لتسهيل التعامل مع النصوص
// في سياق التطبيق العربي.
//
// كيفية الاستخدام:
//   'ahmed'.capitalize()         → 'Ahmed'
//   '  نص  '.trimAndClean()      → 'نص'
//   'سند قبض'.truncate(5)        → 'سند ق...'
//   ''.isNullOrEmpty             → true  (على String?)
//   'abc123'.isAlphanumeric      → true
//   '1500000'.toDoubleOrNull()   → 1500000.0
//   '500,000'.toFormattedDouble()→ 500000.0  (يتجاهل الفاصلة)
// ─────────────────────────────────────────────────────────────────────────────

/// امتدادات String — أدوات التعامل مع النصوص العربية والعامة
extension StringExtensions on String {
  // ── التنظيف والتحويل ──────────────────────────────────────────────────────

  /// إزالة المسافات الزائدة من البداية والنهاية والداخل
  ///
  /// مثال: '  نص   طويل  ' → 'نص طويل'
  String trimAndClean() {
    return trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// تحويل الحرف الأول إلى حرف كبير (للنصوص الإنجليزية)
  ///
  /// مثال: 'ahmed ali' → 'Ahmed ali'
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// تحويل كل كلمة إلى حرف كبير في البداية (Title Case)
  ///
  /// مثال: 'ahmed ali hassan' → 'Ahmed Ali Hassan'
  String toTitleCase() {
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// اقتطاع النص إلى حد أقصى مع إضافة '...' إذا تجاوز الحد
  ///
  /// [maxLength] — الحد الأقصى لعدد الحروف قبل الاقتطاع
  /// مثال: 'سند قبض رقم 1'.truncate(8) → 'سند قبض...'
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// إزالة الأصفار غير الضرورية من نهاية الرقم العشري
  ///
  /// مثال: '1500.500' → '1500.5' | '1500.000' → '1500'
  String trimTrailingZeros() {
    if (!contains('.')) return this;
    final trimmed = replaceAll(RegExp(r'0+$'), '');
    return trimmed.endsWith('.') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }

  // ── التحويل إلى أرقام ─────────────────────────────────────────────────────

  /// تحويل النص إلى double (يُعيد null إذا فشل التحويل)
  ///
  /// مثال: '1500.5' → 1500.5 | 'abc' → null
  double? toDoubleOrNull() => double.tryParse(this);

  /// تحويل النص إلى int (يُعيد null إذا فشل التحويل)
  ///
  /// مثال: '42' → 42 | 'abc' → null
  int? toIntOrNull() => int.tryParse(this);

  /// تحويل النص المنسق كعملة إلى double
  ///
  /// يُزيل الفواصل والمسافات والرموز قبل التحويل
  /// مثال: '1,500,000.500 د.ع' → 1500000.5
  double? toFormattedDouble() {
    final cleaned = replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned);
  }

  // ── الفحوصات ──────────────────────────────────────────────────────────────

  /// هل النص فارغ بعد إزالة المسافات؟
  bool get isBlank => trim().isEmpty;

  /// هل النص غير فارغ بعد إزالة المسافات؟
  bool get isNotBlank => trim().isNotEmpty;

  /// هل النص يحتوي على أحرف وأرقام فقط؟ (بدون رموز خاصة)
  bool get isAlphanumeric => RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);

  /// هل النص يحتوي على أحرف عربية؟
  bool get containsArabic => RegExp(r'[\u0600-\u06FF]').hasMatch(this);

  /// هل النص عبارة عن رقم صالح؟
  bool get isNumeric => double.tryParse(this) != null;

  /// هل النص يمكن استخدامه كاسم مستخدم صالح؟
  /// (3-50 حرف، أحرف إنجليزية وأرقام وشرطة سفلية فقط)
  bool get isValidUsername {
    return RegExp(r'^[a-zA-Z0-9_]{3,50}$').hasMatch(this);
  }

  /// هل طول النص ضمن الحد المسموح؟
  ///
  /// [min] — الحد الأدنى للطول
  /// [max] — الحد الأقصى للطول
  bool isLengthBetween(int min, int max) {
    return length >= min && length <= max;
  }

  // ── مساعدات خاصة بالتطبيق ────────────────────────────────────────────────

  /// إضافة قيمة بديلة إذا كان النص فارغاً
  ///
  /// [fallback] — النص البديل
  /// مثال: ''.orDefault('غير محدد') → 'غير محدد'
  String orDefault(String fallback) => isEmpty ? fallback : this;

  /// تحويل رمز دور المستخدم إلى نص عربي قابل للعرض
  ///
  /// مثال: 'super_admin' → 'مدير عام' | 'admin' → 'مدير' | 'user' → 'مستخدم'
  String toArabicRole() {
    return switch (this) {
      'super_admin' => 'مدير عام',
      'admin'       => 'مدير',
      'user'        => 'مستخدم',
      _             => this,
    };
  }

  /// تحويل نوع السند إلى نص عربي
  ///
  /// مثال: 'sarf' → 'صرف' | 'kabd' → 'قبض' | 'opening_balance' → 'رصيد افتتاحي'
  String toArabicVoucherType() {
    return switch (this) {
      'sarf'            => 'صرف',
      'kabd'            => 'قبض',
      'opening_balance' => 'رصيد افتتاحي',
      'transfer_out'    => 'تحويل (صادر)',
      'transfer_in'     => 'تحويل (وارد)',
      _                 => this,
    };
  }

  /// تحويل رمز العملة إلى اسم عربي كامل
  ///
  /// مثال: 'IQD' → 'دينار عراقي' | 'USD' → 'دولار أمريكي'
  String toCurrencyName() {
    return switch (this) {
      'IQD' => 'دينار عراقي',
      'USD' => 'دولار أمريكي',
      _     => this,
    };
  }

  /// تحويل رمز العملة إلى رمزها القصير
  ///
  /// مثال: 'IQD' → 'د.ع' | 'USD' → '$'
  String toCurrencySymbol() {
    return switch (this) {
      'IQD' => 'د.ع',
      'USD' => '\$',
      _     => this,
    };
  }

  /// تحويل حالة الفترة المالية إلى نص عربي
  ///
  /// مثال: 'active' → 'نشطة' | 'frozen' → 'مغلقة'
  String toArabicFiscalStatus() {
    return switch (this) {
      'active'                  => 'نشطة',
      'frozen'                  => 'مغلقة',
      'frozen_pending_recompute'=> 'مغلقة (تحتاج إعادة حساب)',
      _                         => this,
    };
  }

  /// تحويل حالة السلفة إلى نص عربي
  ///
  /// مثال: 'pending' → 'قيد السداد' | 'paid' → 'مسددة'
  String toArabicAdvanceStatus() {
    return switch (this) {
      'pending'     => 'قيد السداد',
      'partial'     => 'مسددة جزئياً',
      'paid'        => 'مسددة بالكامل',
      'written_off' => 'مشطوبة',
      _             => this,
    };
  }

  /// تحويل نوع الخزينة إلى نص عربي
  ///
  /// مثال: 'main' → 'رئيسية' | 'contractor' → 'مقاول' | 'partner' → 'شريك'
  String toArabicTreasuryKind() {
    return switch (this) {
      'main'       => 'رئيسية',
      'contractor' => 'مقاول',
      'partner'    => 'شريك',
      _            => this,
    };
  }
}

/// امتدادات String? — للنصوص القابلة للـ null
extension NullableStringExtensions on String? {
  /// هل النص null أو فارغ؟
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// هل النص null أو فارغ بعد إزالة المسافات؟
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;

  /// النص أو قيمة بديلة إذا كان null أو فارغاً
  ///
  /// [fallback] — النص البديل
  String orDefault(String fallback) =>
      (this == null || this!.isEmpty) ? fallback : this!;

  /// تحويل آمن — يُعيد النص أو سلسلة فارغة
  String get orEmpty => this ?? '';
}
