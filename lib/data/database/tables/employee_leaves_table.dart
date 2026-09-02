// ─────────────────────────────────────────────────────────────────────────────
// employee_leaves_table.dart — إجازات الموظفين (Schema v9)
//
// **طلب المالك (2026-09-02):** «يوجد موظفون لديهم أيام نزول أسبوعية أو
//   شهرية إجازة ويُحسب لهم بها راتب. ويوجد موظفون يأخذون إجازات بدون راتب
//   مثلاً ١٠ أيام أو شهر أو أكثر أو أقل وبدون راتب.»
//
// ═══ المخزن **واحد** والأبواب اثنان ═══
//   اختار المالك إدخال الإجازة من بطاقة الموظف **ومن سطر كشف الشهر** معاً.
//   وقد حُذِّر من خطر المسارين، فنُفِّذ بالشكل الآمن: **البابان يكتبان في هذا
//   الجدول وحده** — لا حقلَ إجازةٍ ثانٍ على سطر الراتب.
//
//   ولماذا هذا مهمّ؟ لأن العطلين ع-٣٧ و ع-٤٠ وُلدا من معنىً واحد يعيش في
//   مكانين: مساران للتسديد أحدهما ينسى الأقساط، وعمودٌ واحد بمعنيين. وهنا
//   المعنى واحد ومكانه واحد، وسهولةُ الإدخال من بابين لا تكلّف شيئاً.
//
// ═══ ولماذا مدىً (من/إلى) لا عددَ أيام؟ ═══
//   لأن عدد الأيام لا يعرف **أيّ شهر** يخصّه. إجازةٌ من ٢٨ تموز إلى ٥ آب
//   تُوزَّع على شهرين: أربعة أيام في تموز وخمسة في آب. ورقمٌ مجرّد «٩ أيام»
//   يُحمَّل كلّه على شهرٍ واحد فيُخصَم من الموظف ضعف ما يستحقّ في شهر
//   ويُهمَل في الآخر.
//
//   وهو الدرس نفسه الذي منع تخزين الأرصدة: **خزّن الواقعة لا نتيجتها.**
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

import 'employees_table.dart';

/// أنواع الإجازة — مصدر الحقيقة الوحيد بدل نصوص متناثرة
abstract final class LeaveKind {
  /// إجازة **براتب** — تُسجَّل ولا تمسّ الاستحقاق
  static const String paid = 'paid';

  /// إجازة **بلا راتب** — تُنقِص أيام الاستحقاق
  static const String unpaid = 'unpaid';

  static const List<String> all = [paid, unpaid];

  static String label(String kind) =>
      kind == paid ? 'إجازة براتب' : 'إجازة بلا راتب';
}

/// جدول إجازات الموظفين
@DataClassName('EmployeeLeave')
class EmployeeLeaves extends Table {
  @override
  String get tableName => 'employee_leaves';

  IntColumn get id => integer().autoIncrement()();

  /// الموظف صاحب الإجازة
  IntColumn get employeeId =>
      integer().named('employee_id').references(Employees, #id)();

  /// أول يوم إجازة **شاملاً إيّاه**
  DateTimeColumn get fromDate => dateTime().named('from_date')();

  /// آخر يوم إجازة **شاملاً إيّاه**
  ///
  /// ⚠️ الشمول مقصود ومطابق لقرار المالك في إنهاء الخدمة (٤ إلى ٢٤ = ٢١
  ///   يوماً): قاعدةُ عدٍّ واحدة في البرنامج كلّه أسلمُ من قاعدتين تختلفان
  ///   بيومٍ فيُصبح الفرق راتباً.
  DateTimeColumn get toDate => dateTime().named('to_date')();

  /// `paid` أو `unpaid` — راجع [LeaveKind]
  TextColumn get kind => text().withDefault(const Constant(LeaveKind.paid))();

  /// سند الإجازة — «بموجب الكتاب المرقّم…»
  TextColumn get reference => text().withDefault(const Constant(''))();

  TextColumn get notes => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  /// حذف ناعم — القانون ٨
  ///
  /// وإجازةٌ حُذفت **تُغيّر راتباً مضى**، فبقاء أثرها ضروري لتفسير الفرق.
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => [
        "CHECK (kind IN ('paid', 'unpaid'))",
        // مدىً مقلوب يُنتج عدد أيام سالباً فيزيد الراتب بدل أن يُنقصه —
        // حارسٌ في القاعدة يمنع وصوله أصلاً
        'CHECK (to_date >= from_date)',
      ];
}
