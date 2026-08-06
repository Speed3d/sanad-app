// ─────────────────────────────────────────────────────────────────────────────
// input_validators.dart — مُحقِّقات نماذج البيانات
//
// هذا الملف يحتوي على دوال التحقق من صحة المدخلات في نماذج البيانات (Forms).
//
// الغرض:
//   توحيد قواعد التحقق من المدخلات في جميع شاشات التطبيق.
//   جميع رسائل الخطأ بالعربية ومناسبة للعرض في حقول النموذج.
//
// كيفية الاستخدام مع TextFormField:
//   TextFormField(
//     validator: InputValidators.required('اسم الخزينة'),
//   )
//
// أو دمج عدة محققات:
//   TextFormField(
//     validator: InputValidators.combine([
//       InputValidators.required('المبلغ'),
//       InputValidators.positiveAmount,
//     ]),
//   )
//
// الدوال المتاحة:
//   required(fieldName)     — حقل مطلوب
//   minLength(n, fieldName) — حد أدنى للطول
//   maxLength(n, fieldName) — حد أقصى للطول
//   username                — اسم مستخدم صالح
//   password                — كلمة مرور (حد أدنى 3 أحرف)
//   positiveAmount          — مبلغ أكبر من صفر
//   nonNegativeAmount       — مبلغ لا يقل عن صفر
//   sharePercentage         — نسبة بين 0 و 100
//   phoneNumber             — رقم هاتف صالح
//   combine(validators)     — دمج عدة محققات
// ─────────────────────────────────────────────────────────────────────────────

/// مُحقِّقات نماذج البيانات
///
/// جميع الدوال تُعيد `FormFieldValidator<String>` المتوافقة مع TextFormField
/// null = المدخل صالح | String = رسالة خطأ بالعربي
abstract final class InputValidators {
  // ── المحققات الأساسية ─────────────────────────────────────────────────────

  /// التحقق من أن الحقل غير فارغ
  ///
  /// [fieldName] — اسم الحقل بالعربي يظهر في رسالة الخطأ
  ///
  /// مثال: InputValidators.required('اسم المستخدم')
  static String? Function(String?) required(String fieldName) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName مطلوب ولا يمكن تركه فارغاً';
      }
      return null; // صالح
    };
  }

  /// التحقق من الحد الأدنى لطول النص
  ///
  /// [minLength] — الحد الأدنى للأحرف
  /// [fieldName] — اسم الحقل بالعربي
  static String? Function(String?) minLength(int minLength, String fieldName) {
    return (value) {
      if (value == null || value.trim().length < minLength) {
        return '$fieldName يجب أن يكون $minLength أحرف على الأقل';
      }
      return null;
    };
  }

  /// التحقق من الحد الأقصى لطول النص
  ///
  /// [maxLength] — الحد الأقصى للأحرف
  /// [fieldName] — اسم الحقل بالعربي
  static String? Function(String?) maxLength(int maxLength, String fieldName) {
    return (value) {
      if (value != null && value.trim().length > maxLength) {
        return '$fieldName يجب ألا يتجاوز $maxLength حرفاً';
      }
      return null;
    };
  }

  // ── محققات المصادقة ───────────────────────────────────────────────────────

  /// التحقق من صحة اسم المستخدم
  ///
  /// القواعد:
  ///   - 3 إلى 50 حرفاً
  ///   - أحرف إنجليزية وأرقام وشرطة سفلية فقط
  ///   - لا مسافات ولا أحرف خاصة
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'اسم المستخدم مطلوب';
    }
    if (value.length < 3) {
      return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    }
    if (value.length > 50) {
      return 'اسم المستخدم يجب ألا يتجاوز 50 حرفاً';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'اسم المستخدم يقبل فقط: حروف إنجليزية، أرقام، شرطة سفلية (_)';
    }
    return null;
  }

  /// التحقق من صحة كلمة المرور
  ///
  /// [minLength] — الحد الأدنى للطول (افتراضي: 3 أحرف)
  ///
  /// مثال: InputValidators.password() أو InputValidators.password(minLength: 6)
  static String? Function(String?) password({int minLength = 3}) {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'كلمة المرور مطلوبة';
      }
      if (value.length < minLength) {
        return 'كلمة المرور يجب أن تكون $minLength أحرف على الأقل';
      }
      return null;
    };
  }

  /// التحقق من تطابق كلمتي المرور
  ///
  /// [originalPassword] — كلمة المرور الأصلية للمقارنة
  static String? Function(String?) confirmPassword(String originalPassword) {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'تأكيد كلمة المرور مطلوب';
      }
      if (value != originalPassword) {
        return 'كلمتا المرور غير متطابقتين';
      }
      return null;
    };
  }

  // ── محققات المبالغ والأرقام ───────────────────────────────────────────────

  /// التحقق من أن المبلغ رقم موجب (أكبر من صفر)
  ///
  /// للاستخدام في: إنشاء سندات القبض والصرف
  static String? positiveAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'المبلغ مطلوب';
    }
    // إزالة الفواصل والرموز مع الحفاظ على إشارة السالب والموجب
    final cleaned = value.replaceAll(RegExp(r'[^-\d.]'), '');
    final amount = double.tryParse(cleaned);
    if (amount == null) {
      return 'أدخل رقماً صالحاً للمبلغ';
    }
    if (amount <= 0) {
      return 'المبلغ يجب أن يكون أكبر من صفر';
    }
    return null;
  }

  /// التحقق من أن المبلغ لا يقل عن صفر (يقبل الصفر)
  ///
  /// للاستخدام في: الرصيد الافتتاحي
  static String? nonNegativeAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // الصفر مقبول — يُعامَل الفارغ كصفر
    }
    final cleaned = value.replaceAll(RegExp(r'[^-\d.]'), '');
    final amount = double.tryParse(cleaned);
    if (amount == null) {
      return 'أدخل رقماً صالحاً للمبلغ';
    }
    if (amount < 0) {
      return 'المبلغ لا يمكن أن يكون سالباً';
    }
    return null;
  }

  /// التحقق من نسبة المشاركة (بين 0 و 100)
  ///
  /// للاستخدام في: إضافة شريك
  static String? sharePercentage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'نسبة المشاركة مطلوبة';
    }
    final percentage = double.tryParse(value);
    if (percentage == null) {
      return 'أدخل رقماً صالحاً للنسبة';
    }
    if (percentage < 0 || percentage > 100) {
      return 'نسبة المشاركة يجب أن تكون بين 0 و 100%';
    }
    return null;
  }

  // ── محققات الاتصال ────────────────────────────────────────────────────────

  /// التحقق من صحة رقم الهاتف (اختياري)
  ///
  /// يقبل: أرقام، مسافات، +، -، ()
  /// يُعيد null إذا كان الحقل فارغاً (الهاتف اختياري)
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // اختياري
    }
    // تنظيف النص من المسافات والرموز المقبولة
    final cleaned = value.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (!RegExp(r'^\d{7,15}$').hasMatch(cleaned)) {
      return 'رقم الهاتف غير صالح (يجب أن يكون بين 7 و 15 رقماً)';
    }
    return null;
  }

  // ── محققات النصوص العامة ──────────────────────────────────────────────────

  /// التحقق من اسم الشركة أو الكيان
  ///
  /// [fieldName] — اسم الحقل (للرسالة)
  /// [minLen]    — الحد الأدنى للطول (افتراضي: 1)
  /// [maxLen]    — الحد الأقصى للطول (افتراضي: 150)
  static String? Function(String?) name({
    required String fieldName,
    int minLen = 1,
    int maxLen = 150,
  }) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName مطلوب';
      }
      if (value.trim().length < minLen) {
        return '$fieldName يجب أن يكون $minLen أحرف على الأقل';
      }
      if (value.trim().length > maxLen) {
        return '$fieldName يجب ألا يتجاوز $maxLen حرفاً';
      }
      return null;
    };
  }

  /// التحقق من الملاحظات/التفاصيل النصية (اختيارية مع حد أقصى)
  ///
  /// [maxLen] — الحد الأقصى للأحرف (افتراضي: 500)
  static String? Function(String?) notes({int maxLen = 500}) {
    return (value) {
      if (value == null || value.isEmpty) return null; // اختياري
      if (value.length > maxLen) {
        return 'الملاحظات يجب ألا تتجاوز $maxLen حرفاً';
      }
      return null;
    };
  }

  // ── دمج عدة محققات ────────────────────────────────────────────────────────

  /// دمج قائمة من المحققات وتشغيلها بالتسلسل
  ///
  /// يتوقف عند أول خطأ ويُعيده
  ///
  /// مثال:
  ///   validator: InputValidators.combine([
  ///     InputValidators.required('المبلغ'),
  ///     InputValidators.positiveAmount,
  ///   ])
  static String? Function(String?) combine(
      List<String? Function(String?)> validators) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error; // أعد الخطأ الأول
      }
      return null; // كل المحققات نجحت
    };
  }
}
