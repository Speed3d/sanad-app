// ─────────────────────────────────────────────────────────────────────────────
// employee_events_table.dart — سجل حركات الموظف (Schema v10)
//
// **طلب المالك (2026-09-03):** «يجب أن يكون هناك سجل حركات في كل صفحة موظف
//   حتى يبين لي متى تم تعيينه ومتى تم تعديل راتبه ومتى أخذ إجازة أو سلفة
//   ومتى تم إنهاء خدماته.»
//
// ═══ لماذا جدولٌ جديد ولم يكفِ اشتقاقُه ممّا هو موجود؟ ═══
//   لأن معظم الأحداث موجودة فعلاً بتواريخها (الإجازات · السلف · رواتب كل
//   شهر · التعيين والإنهاء)، **إلا واحداً**: تعديل الراتب **لا يُسجَّل في
//   أي مكان**. الرقم يُستبدَل ولا يُحفَظ سابقه، فسؤال «متى صار راتبه ثلاثة
//   ملايين؟» بلا جواب في القاعدة كلها.
//
//   وسجلٌّ مشتقٌّ يجيب عن ستّة أسئلة ويصمت عن سابعها ليس سجلّاً — يُفقِد
//   الثقة بالباقي. فالحدث يُكتَب صراحةً لحظةَ وقوعه.
//
// ═══ ولماذا ليس `audit_log`؟ ═══
//   سجل التدقيق **أمنيّ**: من فعل ماذا ومتى، ويُقرأ بصلاحية `super_admin`
//   وحدها (الدفعة أ)، ويُمحى في تصفير المصنع. وهذا **إداريّ**: يُقرأ في
//   بطاقة الموظف ويُطبَع في تقريره ويبقى ما بقي الموظف. خلطُهما يجعل
//   إخفاء أحدهما يُخفي الآخر.
//
// ⚠️ **والحدث لقطةٌ لا إشارة**: يحمل نصَّه ومبلغيه وقت وقوعه، فلا يتغيّر
//   معنى سطرٍ قديم بتغيّر ما يشير إليه. الدرس نفسه الذي جعل `salary_payments`
//   تحمل `snapshot_name`.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

import 'employees_table.dart';

/// أنواع أحداث الموظف — **مصدر الحقيقة الوحيد**
///
/// ⚠️ أي إضافة هنا تحتاج ترجمةً في [EmployeeEventKind.label] — والمجهول
///   يُعرَض بنصّه لا يُخفى (درس ب-٥).
abstract final class EmployeeEventKind {
  static const String hired = 'hired';
  static const String salaryChanged = 'salary_changed';
  static const String departmentChanged = 'department_changed';
  static const String treasuryChanged = 'treasury_changed';
  static const String leaveAdded = 'leave_added';
  static const String leaveRemoved = 'leave_removed';
  static const String advanceTaken = 'advance_taken';
  static const String advanceRepaid = 'advance_repaid';
  static const String terminated = 'terminated';
  static const String reinstated = 'reinstated';
  static const String statusChanged = 'status_changed';

  static const List<String> all = [
    hired,
    salaryChanged,
    departmentChanged,
    treasuryChanged,
    leaveAdded,
    leaveRemoved,
    advanceTaken,
    advanceRepaid,
    terminated,
    reinstated,
    statusChanged,
  ];

  /// التسمية العربية — والمجهول يُعرَض كما هو
  static String label(String kind) => switch (kind) {
        hired => 'التعيين',
        salaryChanged => 'تعديل الراتب',
        departmentChanged => 'نقل بين الأقسام',
        treasuryChanged => 'نقل بين المشاريع',
        leaveAdded => 'إجازة',
        leaveRemoved => 'إلغاء إجازة',
        advanceTaken => 'سلفة',
        advanceRepaid => 'تسديد سلفة',
        terminated => 'إنهاء الخدمة',
        reinstated => 'العودة إلى الخدمة',
        statusChanged => 'تغيير الحالة',
        _ => kind,
      };
}

/// حركات الموظف — سطرٌ لكل حدث في حياته الوظيفية
class EmployeeEvents extends Table {
  @override
  String get tableName => 'employee_events';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get employeeId => integer()
      .named('employee_id')
      .references(Employees, #id, onDelete: KeyAction.cascade)();

  /// نوع الحدث — راجع [EmployeeEventKind]
  TextColumn get kind => text().withLength(min: 1, max: 40)();

  /// تاريخ **وقوع** الحدث لا تاريخ تسجيله
  ///
  /// ⚠️ الفرق جوهري: إجازةٌ تُسجَّل اليوم عن الشهر الماضي حدثُها الشهر
  ///   الماضي. و`created_at` يبقى للتسجيل — فيُعرف المتأخّر عن موعده.
  DateTimeColumn get eventDate => dateTime().named('event_date')();

  /// وصفٌ عربي جاهز — **لقطة لا إشارة**
  ///
  /// «تعديل الراتب من ٢٬٥٠٠٬٠٠٠ إلى ٣٬٠٠٠٬٠٠٠ د.ع». يُكتَب وقت الحدث فلا
  /// يتغيّر معناه لاحقاً بتغيّر ما يشير إليه.
  TextColumn get description => text().withDefault(const Constant(''))();

  /// القيمتان قبل وبعد — للأحداث الرقمية (الراتب)
  ///
  /// تُخزَّنان مفصولتين عن [description] لأن التقرير قد يريد الفرق رقماً
  /// لا نصّاً.
  RealColumn get oldValue => real().named('old_value').nullable()();
  RealColumn get newValue => real().named('new_value').nullable()();

  /// سند الحدث — رقم الكتاب أو الأمر الإداري
  TextColumn get reference => text().withDefault(const Constant(''))();

  TextColumn get notes => text().withDefault(const Constant(''))();

  /// من سجّل الحدث — `null` لما سجّله النظام تلقائياً
  IntColumn get createdByUserId =>
      integer().named('created_by_user_id').nullable()();

  DateTimeColumn get createdAt => dateTime()
      .named('created_at')
      .withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => [
        "CHECK (kind <> '')",
      ];
}
