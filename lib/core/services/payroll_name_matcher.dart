// ─────────────────────────────────────────────────────────────────────────────
// payroll_name_matcher.dart — مطابقة أسماء الموظفين عند استيراد كشف الرواتب
//
// **المشكلة التي يحلّها هذا الملف:**
//   ملفات الرواتب التي يرسلها محاسبو المشاريع **بلا رقم موظف** — والتسلسل
//   فيها يختلف من ملف لآخر حسب من كتبه (قرار المالك 2026-08-24). فالسبيل
//   الوحيد لمعرفة «هل هذا الاسم موظف مسجَّل أم جديد؟» هو الاسم نفسه.
//
//   والاسم العربي هشّ في المطابقة الحرفية:
//     «أحمد علي» ≠ «احمد علي» ≠ «أحمد  علي» ≠ «أحمَد علي»
//   ثلاثة أشكال لشخص واحد. المطابقة الحرفية تُنتج ثلاثة موظفين، وتنقسم
//   رواتبه بينهم فلا يظهر تاريخه الحقيقي في أي منها.
//
// **الحلّ — تطبيع ثم مفتاح مركّب:**
//   المفتاح = (الاسم المُطبَّع + تاريخ التعيين)
//   وتاريخ التعيين موجود في الملف ومستقرّ عبر الشهور، فهو أقرب ما يكون
//   إلى رقم موظف بلا رقم موظف.
//
// 🔑 **القاعدة الحاكمة: لا ربط صامت ولا إنشاء صامت.**
//   كل حالة غامضة تُعرَض على المالك ليبتّ فيها (قرار 2026-08-24). الإنشاء
//   الصامت يملأ القاعدة بموظفين وُلدوا من خطأ إملائي، والربط الصامت يُدخل
//   راتب شخص في سجلّ آخر — وكلاهما لا يُكتشَف إلا بعد شهور.
// ─────────────────────────────────────────────────────────────────────────────

/// نتيجة مطابقة اسم واحد من الملف بموظفي القاعدة
enum PayrollMatchKind {
  /// موظف مسجَّل وُجد بيقين — يُربط السطر به
  matched,

  /// أكثر من احتمال أو تعارض في تاريخ التعيين — **يُعرَض للبتّ**
  ambiguous,

  /// لا موظف يطابقه — **يُعرَض «سيُنشأ» وينتظر الموافقة**
  isNew,
}

/// مرشّح للمطابقة — أقلّ ما يلزم من بيانات الموظف
class PayrollMatchCandidate {
  /// معرّف الموظف في قاعدة البيانات
  final int employeeId;

  /// الاسم كما هو مخزَّن (غير مُطبَّع) — للعرض في حوار البتّ
  final String fullName;

  /// تاريخ التعيين المسجَّل · قد يكون `null` لموظفين قدامى
  final DateTime? hireDate;

  const PayrollMatchCandidate({
    required this.employeeId,
    required this.fullName,
    this.hireDate,
  });
}

/// حصيلة مطابقة سطر واحد
class PayrollNameMatch {
  final PayrollMatchKind kind;

  /// الموظف المطابَق — يُملأ في [PayrollMatchKind.matched] وحدها
  final PayrollMatchCandidate? employee;

  /// المرشّحون حين تكون النتيجة [PayrollMatchKind.ambiguous]
  final List<PayrollMatchCandidate> candidates;

  /// سبب الغموض بالعربية — يُعرض للمالك ليفهم ما يُسأل عنه
  final String? reason;

  const PayrollNameMatch({
    required this.kind,
    this.employee,
    this.candidates = const [],
    this.reason,
  });

  bool get isMatched => kind == PayrollMatchKind.matched;
  bool get isAmbiguous => kind == PayrollMatchKind.ambiguous;
  bool get isNew => kind == PayrollMatchKind.isNew;
}

/// مطابِق أسماء الموظفين — دوال نقيّة بلا حالة ولا قاعدة بيانات
abstract final class PayrollNameMatcher {
  // ── التطبيع ──────────────────────────────────────────────────────────────

  /// حروف التشكيل والتطويل التي تُحذف قبل المقارنة
  ///
  /// الفتحة والضمة والكسرة والشدّة والسكون والتنوين، والألف الخنجرية،
  /// والتطويل `ـ` الذي يُستعمل للتنسيق البصري ولا يغيّر النطق.
  ///
  /// ⚠️ مكتوبة بترميز `\u` لا بالحروف نفسها: هذه محارف **غير مرئية** في
  ///   المحرّر، فكتابتها حرفياً تجعل التعبير النمطي يبدو فارغاً أو مشوّهاً
  ///   ويستحيل مراجعته أو تعديله بثقة لاحقاً.
  static final RegExp _diacritics = RegExp('[\u064B-\u0652\u0670\u0640]');

  /// مسافات متعدّدة تُضغط إلى واحدة
  ///
  /// تشمل المسافة غير الفاصلة (`\u00A0`) ومحارف التحكّم بالاتجاه
  /// (`\u200B`–`\u200F`) التي تتسرّب من النسخ من مستندات عربية ولا تُرى
  /// إطلاقاً — فاسمٌ يحمل أحدها لا يطابق نظيره أبداً بلا هذا التنظيف.
  static final RegExp _spaces = RegExp('[\\s\u00A0\u200B-\u200F]+');

  /// تطبيع اسم عربي للمقارنة
  ///
  /// ما يفعله ولماذا:
  /// | التحويل | السبب |
  /// |---|---|
  /// | `أ إ آ ٱ` ← `ا` | الهمزة تُكتب وتُهمَل بلا قاعدة ثابتة في الأسماء |
  /// | `ة` ← `ه` | «فاطمة» و«فاطمه» اسم واحد في كل ملف يدوي |
  /// | `ى` ← `ي` | «يحيى» و«يحيي» |
  /// | `ؤ` ← `و` · `ئ` ← `ي` | «رؤوف» و«رووف» |
  /// | حذف التشكيل والتطويل | زينة كتابية لا تغيّر الاسم |
  /// | ضغط المسافات | «أحمد  علي» بمسافتين |
  ///
  /// ⚠️ **ما لا يفعله عمداً:** لا يحذف «ال» التعريف ولا يختصر الاسم إلى
  ///   جزأين. حذف «ال» كان يجعل «العلي» و«علي» شخصاً واحداً، واختصار
  ///   الاسم يدمج إخوةً يشتركون في الاسم الأول واسم الأب.
  static String normalize(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return '';

    s = s.replaceAll(_diacritics, '');
    s = s
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
    s = s.replaceAll(_spaces, ' ').trim();
    return s;
  }

  /// هل الاسمان واحد بعد التطبيع؟
  static bool sameName(String a, String b) => normalize(a) == normalize(b);

  // ── المطابقة ─────────────────────────────────────────────────────────────

  /// تجريد الوقت من التاريخ — المقارنة باليوم لا بالساعة
  static DateTime? _dateOnly(DateTime? d) =>
      d == null ? null : DateTime(d.year, d.month, d.day);

  /// مطابقة اسم قادم من الملف بقائمة موظفي القاعدة
  ///
  /// [fileName]     — الاسم كما ورد في ملف الإكسل
  /// [fileHireDate] — تاريخ التعيين كما ورد فيه (قد يغيب)
  /// [employees]    — كل الموظفين غير المحذوفين
  ///
  /// **جدول القرار:**
  ///
  /// | الحالة | النتيجة |
  /// |---|---|
  /// | لا اسم يطابق | 🔵 جديد — يُعرَض «سيُنشأ» |
  /// | مرشّح واحد وتاريخا التعيين متطابقان | 🟢 مطابَق |
  /// | مرشّح واحد والملف بلا تاريخ تعيين | 🟢 مطابَق (لا تعارض) |
  /// | مرشّح واحد والمسجَّل بلا تاريخ تعيين | 🟢 مطابَق + يُكمَّل تاريخه |
  /// | مرشّح واحد وتاريخان **مختلفان** | 🟠 غامض — أهو هو أم شخص آخر؟ |
  /// | أكثر من مرشّح | 🟠 غامض — إلا أن يحسم تاريخ التعيين واحداً منهم |
  static PayrollNameMatch match({
    required String fileName,
    DateTime? fileHireDate,
    required List<PayrollMatchCandidate> employees,
  }) {
    final key = normalize(fileName);
    if (key.isEmpty) {
      return const PayrollNameMatch(
        kind: PayrollMatchKind.ambiguous,
        reason: 'اسم فارغ — لا يمكن مطابقته ولا إنشاؤه.',
      );
    }

    final sameNamed =
        employees.where((e) => normalize(e.fullName) == key).toList();

    if (sameNamed.isEmpty) {
      return const PayrollNameMatch(kind: PayrollMatchKind.isNew);
    }

    final fileDate = _dateOnly(fileHireDate);

    // مرشّح واحد بالاسم — يحسم تاريخ التعيين إن تعارضا
    if (sameNamed.length == 1) {
      final only = sameNamed.first;
      final stored = _dateOnly(only.hireDate);

      final conflict =
          fileDate != null && stored != null && fileDate != stored;
      if (conflict) {
        return PayrollNameMatch(
          kind: PayrollMatchKind.ambiguous,
          candidates: sameNamed,
          reason: 'الاسم «${only.fullName}» مسجَّل بتاريخ تعيين مختلف — '
              'أهو الموظف نفسه أم شخص آخر يحمل الاسم ذاته؟',
        );
      }
      return PayrollNameMatch(kind: PayrollMatchKind.matched, employee: only);
    }

    // أكثر من موظف بالاسم نفسه — تاريخ التعيين وحده قد يحسم
    if (fileDate != null) {
      final exact = sameNamed
          .where((e) => _dateOnly(e.hireDate) == fileDate)
          .toList();
      if (exact.length == 1) {
        return PayrollNameMatch(
          kind: PayrollMatchKind.matched,
          employee: exact.first,
        );
      }
    }

    return PayrollNameMatch(
      kind: PayrollMatchKind.ambiguous,
      candidates: sameNamed,
      reason: '${sameNamed.length} موظفين يحملون الاسم «$fileName» — '
          'حدّد المقصود منهم.',
    );
  }
}
