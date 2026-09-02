// ─────────────────────────────────────────────────────────────────────────────
// employees_dao_service.dart — جزء من `employees_dao.dart`
//
// **دورة حياة خدمة الموظف**: الإجازات · إنهاء الخدمة والعودة منها · اشتقاق
// حالة «في إجازة» · سياق حساب الراتب · وسجل الحركات.
//
// **لماذا جزءٌ مستقلّ؟** تجاوز `employees_dao.dart` سقف
//   `tech_debt_guard_test` (١٢٠٠ سطر) بعد إضافة السجل (Schema v10).
//   والفصل **بحسب الطبيعة لا الحجم**: هناك بياناتُ الموظف وأقسامه وسلفه،
//   وهنا **ما يجري له عبر الزمن**.
//
// ⚠️ وكل ما هنا يكتب في مصدرٍ واحد لكل معنى: الإجازة في `employee_leaves`،
//   والحالة تُشتقّ منها لا تُضبط بيد (قرار المالك 2026-09-03).
// ─────────────────────────────────────────────────────────────────────────────

part of 'employees_dao.dart';

/// دورة حياة الخدمة — **`mixin` لا `extension`**
///
/// ⚠️ الامتداد لا يُرى إلا حيث تُستورَد مكتبتُه، والمستدعون هنا يستوردون
///   `app_database.dart` لا هذا الملف — فاختفت الدوال عن أربعين موضعاً
///   دفعةً واحدة. والـ`mixin` يجعلها أعضاءً في الصنف نفسه فلا يتغيّر شيء.
///   (التحذير نفسه مكتوب في `payroll_repository_reports.dart` — وقد
///   أخطأتُه ثم أعاده المحلّل.)
mixin EmployeeServiceDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeesTable get employees;
  $EmployeeLeavesTable get employeeLeaves;
  $EmployeeEventsTable get employeeEvents;

  /// من الصنف الأمّ — تُستعمل في اشتقاق الحالة
  Future<Employee?> getEmployeeById(int id);

  // ══════════════════════════════════════════════════════════════════════
  // الإجازات وإنهاء الخدمة (Schema v9 — طلب المالك 2026-09-02)
  // ══════════════════════════════════════════════════════════════════════

  /// إجازات موظف — الأحدث أولاً
  Stream<List<EmployeeLeave>> watchLeaves(int employeeId) {
    return (select(employeeLeaves)
          ..where((l) =>
              l.employeeId.equals(employeeId) & l.isDeleted.equals(false))
          ..orderBy([(l) => OrderingTerm.desc(l.fromDate)]))
        .watch();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // سجل الحركات (Schema v10)
  // ═══════════════════════════════════════════════════════════════════════

  /// يسجّل حدثاً في حياة الموظف — **النقطة الوحيدة التي تكتب في السجل**
  ///
  /// 🔑 **ولماذا نقطةٌ واحدة؟** لأن سجلّاً يُكتَب من عشرة مواضع يصير عشرة
  ///   سجلّات: صيغةُ الوصف تختلف، وحدثٌ يُنسى في مسارٍ ويُكتب في آخر.
  ///   وهي العلّة نفسها التي أنتجت ع-٣٧ (أقساط السلف في مسارين).
  ///
  /// ⚠️ **ولا يرمي أبداً.** فشلُ تسجيل حدثٍ إداري لا يجوز أن يُفشل تعديل
  ///   راتبٍ نجح — نفس قرار `AuditLogger._safeLog`. السجل يخدم القراءة،
  ///   والعملية المالية أولى منه.
  Future<void> logEvent({
    required int employeeId,
    required String kind,
    DateTime? eventDate,
    String description = '',
    double? oldValue,
    double? newValue,
    String reference = '',
    String notes = '',
    int? userId,
  }) async {
    try {
      await into(employeeEvents).insert(
        EmployeeEventsCompanion.insert(
          employeeId: employeeId,
          kind: kind,
          eventDate: eventDate ?? DateTime.now(),
          description: Value(description),
          oldValue: Value(oldValue),
          newValue: Value(newValue),
          reference: Value(reference),
          notes: Value(notes),
          createdByUserId: Value(userId),
        ),
      );
    } catch (_) {
      // صمتٌ مقصود — راجع الشرح أعلاه
    }
  }

  /// حركات موظف مرتَّبة من الأحدث — Reactive Stream
  ///
  /// ⚠️ الترتيب بـ`event_date` ثم بالمعرّف: حدثان في يومٍ واحد يجب أن
  ///   يُقرآ بترتيب وقوعهما لا عشوائياً.
  Stream<List<EmployeeEvent>> watchEvents(int employeeId) {
    return (select(employeeEvents)
          ..where((e) => e.employeeId.equals(employeeId))
          ..orderBy([
            (e) => OrderingTerm.desc(e.eventDate),
            (e) => OrderingTerm.desc(e.id),
          ]))
        .watch();
  }

  /// تسجيل إجازة — يُعيد معرّفها، **ويُحدِّث حالة الموظف معها**
  Future<int> insertLeave(EmployeeLeavesCompanion leave) async {
    final id = await into(employeeLeaves).insert(leave);
    final empId = leave.employeeId.value;
    await refreshLeaveStatus(empId);

    final row = await (select(employeeLeaves)..where((l) => l.id.equals(id)))
        .getSingle();
    final days = row.toDate.difference(row.fromDate).inDays + 1;
    await logEvent(
      employeeId: empId,
      kind: EmployeeEventKind.leaveAdded,
      eventDate: row.fromDate,
      description: 'إجازة ${row.kind == LeaveKind.paid ? 'براتب' : 'بلا راتب'} '
          '${_days(days)} — '
          'من ${_d(row.fromDate)} إلى ${_d(row.toDate)}',
      reference: row.reference,
      notes: row.notes,
    );
    return id;
  }

  /// عدد الأيام بصيغته العربية الصحيحة
  ///
  /// ⚠️ **العربية ليست مفرداً وجمعاً**: ١ يوم · ٢ يومان · ٣–١٠ أيام ·
  ///   ١١ فأكثر يوماً. والثنائي `يوم/يوماً` يُخرج «٥ يوماً» — وهو خطأ
  ///   يقرؤه المالك في سجلّه كل يوم. كشفه اختبار السجل نفسه.
  static String _days(int n) => switch (n) {
        1 => 'يوم واحد',
        2 => 'يومان',
        >= 3 && <= 10 => '$n أيام',
        _ => '$n يوماً',
      };

  /// تاريخٌ مقروء داخل وصف الحدث
  static String _d(DateTime x) =>
      '${x.year}/${x.month.toString().padLeft(2, '0')}/'
      '${x.day.toString().padLeft(2, '0')}';

  /// حذف ناعم لإجازة — **ويُحدِّث الحالة معها**
  ///
  /// ناعمٌ لا صلب (القانون ٨): الإجازة **غيّرت راتباً مضى**، وبقاء أثرها
  /// هو ما يفسّر الفرق بين كشفٍ طُبع أمس وكشفٍ يُطبع اليوم.
  Future<void> softDeleteLeave(int id) async {
    final row = await (select(employeeLeaves)..where((l) => l.id.equals(id)))
        .getSingleOrNull();
    await (update(employeeLeaves)..where((l) => l.id.equals(id)))
        .write(const EmployeeLeavesCompanion(isDeleted: Value(true)));
    if (row != null) {
      await refreshLeaveStatus(row.employeeId);
      await logEvent(
        employeeId: row.employeeId,
        kind: EmployeeEventKind.leaveRemoved,
        description: 'أُلغيت إجازة من ${_d(row.fromDate)} إلى ${_d(row.toDate)}',
      );
    }
  }

  /// يُعيد اشتقاق حالة «في إجازة» من جدول الإجازات (قرار المالك 2026-09-03)
  ///
  /// 🔴 **ما كان معطوباً:** «أسجّل إجازة على موظف، ثم أضغط فلتر «في إجازة»
  ///   فلا يظهر اسمه.» — لأن المعنى كان يعيش في **مكانين**:
  ///     • `employees.status = 'leave'` (v8) يكتبه زرّ الحالة يدوياً
  ///     • جدول `employee_leaves` (v9) تكتبه الإجازة بتاريخيها
  ///   والفلتر يقرأ الأول، والتسجيل يكتب في الثاني. **عمودان لمعنىً واحد
  ///   يفترقان بأول كتابة تنسى أحدهما** — وهو المحذور المكتوب في CLAUDE.md
  ///   بعينه (نمط ع-٤٠).
  ///
  /// **القرار: الجدول هو المصدر، والحالة تُشتقّ منه.** فمن له إجازةٌ تشمل
  /// **اليوم** حالته «في إجازة»، وبانقضائها يعود «حالي».
  ///
  /// ⚠️ **ومنتهي الخدمة لا تُمَسّ حالته إطلاقاً**: إنهاء الخدمة أقوى من
  ///   الإجازة، وإعادتُه «حالياً» لانقضاء إجازةٍ قديمة تُدخِله كشوف الرواتب
  ///   من جديد — عطلٌ مالي لا تجميلي.
  Future<void> refreshLeaveStatus(int employeeId) async {
    final emp = await getEmployeeById(employeeId);
    if (emp == null || emp.status == EmployeeStatus.terminated) return;

    final today = DateTime.now();
    final t = DateTime(today.year, today.month, today.day);

    final active = await (select(employeeLeaves)
          ..where((l) =>
              l.employeeId.equals(employeeId) &
              l.isDeleted.equals(false) &
              l.fromDate.isSmallerOrEqualValue(t) &
              l.toDate.isBiggerOrEqualValue(t))
          ..limit(1))
        .getSingleOrNull();

    final target =
        active == null ? EmployeeStatus.active : EmployeeStatus.leave;
    if (emp.status == target) return;

    await (update(employees)..where((e) => e.id.equals(employeeId)))
        .write(EmployeesCompanion(status: Value(target)));
  }

  /// يُعيد اشتقاق حالة **كل** الموظفين — تُستدعى عند فتح شاشة الموظفين
  ///
  /// 🔑 **ولماذا تُشتقّ عند القراءة أيضاً؟** لأن انقضاء الإجازة **حدثٌ لا
  ///   يكتبه أحد**: تنتهي بمرور الوقت لا بضغطة زرّ. فمن لا يُعاد اشتقاقه
  ///   يبقى «في إجازة» إلى الأبد بعد انتهائها.
  Future<void> refreshAllLeaveStatuses() async {
    final all = await (select(employees)
          ..where((e) =>
              e.isDeleted.equals(false) &
              e.status.equals(EmployeeStatus.terminated).not()))
        .get();
    for (final e in all) {
      await refreshLeaveStatus(e.id);
    }
  }

  /// أيام الإجازة **بلا راتب** لموظف داخل شهرٍ بعينه
  ///
  /// ═══ لماذا يُحسب التقاطع هنا لا يُخزَّن رقماً؟ ═══
  ///   لأن الإجازة **واقعة بمدىً**، وعددُ أيامها في شهرٍ ما نتيجةٌ تُشتقّ.
  ///   إجازةٌ من ٢٨ تموز إلى ٥ آب هي أربعة أيام في تموز وخمسة في آب —
  ///   ورقمٌ مخزَّن «٩ أيام» لا يعرف أيّهما، فيُحمَّل كلّه على شهر.
  ///
  ///   وهو المبدأ الحاكم للمشروع كلّه: **الأرصدة لا تُخزَّن، تُحسَب من
  ///   الواقعة.** الإجازة هنا كالسند هناك.
  ///
  /// ⚠️ **والحساب على أيام الشهر التقويمي ثم يُقصّ بأيام العمل**: موظفٌ في
  ///   شهرٍ من ٣١ يوماً وأيام عمله ٣٠ لا يجوز أن تُنقِص إجازتُه ٣١ يوماً
  ///   فيصير استحقاقه سالباً.
  Future<int> unpaidLeaveDaysInMonth({
    required int employeeId,
    required int year,
    required int month,
    required int workingDays,
  }) =>
      leaveDaysInMonth(
        employeeId: employeeId,
        year: year,
        month: month,
        workingDays: workingDays,
        kind: LeaveKind.unpaid,
      );

  /// أيام إجازةٍ من نوعٍ بعينه داخل شهر — **حسبةٌ واحدة للنوعين**
  ///
  /// ⚠️ نسخةٌ ثانية من حساب التقاطع لأجل «الإجازة براتب» كانت ستفترق عن
  ///   أختها بأول تصحيح — وهو ع-٣٧ حرفياً. النوع معاملٌ لا فرعٌ مكرّر.
  Future<int> leaveDaysInMonth({
    required int employeeId,
    required int year,
    required int month,
    required int workingDays,
    required String kind,
  }) async {
    final firstOfMonth = DateTime(year, month, 1);
    final lastOfMonth =
        DateTime(year, month, PayrollCalculator.daysInMonth(year, month));

    final rows = await (select(employeeLeaves)
          ..where((l) =>
              l.employeeId.equals(employeeId) &
              l.isDeleted.equals(false) &
              l.kind.equals(kind) &
              l.fromDate.isSmallerOrEqualValue(lastOfMonth) &
              l.toDate.isBiggerOrEqualValue(firstOfMonth)))
        .get();

    var days = 0;
    for (final l in rows) {
      final from = l.fromDate.isBefore(firstOfMonth) ? firstOfMonth : l.fromDate;
      final to = l.toDate.isAfter(lastOfMonth) ? lastOfMonth : l.toDate;
      // الطرفان **شاملان** — قرار المالك نفسه في إنهاء الخدمة (٤→٢٤ = ٢١)
      days += to.difference(DateTime(from.year, from.month, from.day)).inDays + 1;
    }
    return days > workingDays ? workingDays : days;
  }

  /// إنهاء خدمة موظف — التاريخ والسند والملاحظات والحالة في كتابة واحدة
  ///
  /// ⚠️ **الحالة والتاريخ يُكتَبان معاً دائماً**: `status = terminated` بلا
  ///   تاريخ تجعل الراتب يُحسب شهراً كاملاً لمن خرج في اليوم الخامس، و
  ///   تاريخٌ بلا حالة يجعله يظهر في فلتر «الحاليون». عمودان لمعنىً واحد
  ///   يفترقان بأول كتابة تنسى أحدهما — نمط ع-٤٠.
  Future<void> terminateEmployee({
    required int employeeId,
    required DateTime terminationDate,
    String reference = '',
    String notes = '',
  }) async {
    await (update(employees)..where((e) => e.id.equals(employeeId))).write(
      EmployeesCompanion(
        status: const Value(EmployeeStatus.terminated),
        terminationDate: Value(terminationDate),
        terminationReference: Value(reference),
        terminationNotes: Value(notes),
      ),
    );
    await logEvent(
      employeeId: employeeId,
      kind: EmployeeEventKind.terminated,
      eventDate: terminationDate,
      description: 'إنهاء الخدمة بتاريخ ${_d(terminationDate)}',
      reference: reference,
      notes: notes,
    );
  }

  /// إعادة موظف إلى الخدمة — تمحو التاريخ والسند معاً
  ///
  /// وإلا بقي تاريخُ إنهاءٍ قديم يقصّ راتبه في كل شهر بعد عودته.
  Future<void> reinstateEmployee(int employeeId) async {
    await (update(employees)..where((e) => e.id.equals(employeeId))).write(
      const EmployeesCompanion(
        status: Value(EmployeeStatus.active),
        terminationDate: Value(null),
        terminationReference: Value(''),
        terminationNotes: Value(''),
      ),
    );
    await logEvent(
      employeeId: employeeId,
      kind: EmployeeEventKind.reinstated,
      description: 'عاد إلى الخدمة — مُحي تاريخ الإنهاء وسنده',
    );
  }

  /// سياق خدمة الموظف اللازم لحساب راتب شهرٍ بعينه (Schema v9)
  ///
  /// 🔴 **ما كان معطوباً (طلب المالك 2026-09-02):**
  ///   ١. التناسب كان يعتمد على `hireDate` **من ملف الإكسل** وحده. فإن خلا
  ///      الملف من العمود — وهو الغالب — لم يقع تناسبٌ أصلاً، ومن عُيِّن في
  ///      اليوم العشرين أخذ راتب شهرٍ كامل.
  ///   ٢. و`terminationDate` **لا عمود له في القاعدة إطلاقاً**، فالدالة التي
  ///      تحسبه — مكتوبةً ومحروسةً بالاختبارات منذ اليوم الأول — لم تُستدعَ
  ///      بقيمةٍ قطّ. نمط ع-٠٦ في أنقى صوره.
  ///
  /// **وسجلّ الموظف هو مصدر الحقيقة** (قرار المالك): البرنامج يعرف تاريخ
  /// التعيين، والملف الشهري قد يخلو منه أو يحمل خطأً مطبعياً. والمستدعي
  /// يستعمل تاريخ الملف **فقط** حين يعود [hireDate] فارغاً.
  ///
  /// 📌 **ولماذا رَكوردٌ واحد لا ثلاث قراءات؟** لأن الثلاثة تصف حالةً واحدة
  ///   في لحظة واحدة، وتفريقُها يجعل مستدعياً لاحقاً يقرأ اثنتين وينسى
  ///   الثالثة — وهو النمط الذي أنتج ع-٥٠ (الدولار يسقط في المحطّة الوسطى).
  Future<
      ({
        DateTime? hireDate,
        DateTime? terminationDate,
        int unpaidLeaveDays,
        int paidLeaveDays,
      })> payrollServiceContext({
    required int employeeId,
    required int year,
    required int month,
    required int workingDays,
  }) async {
    final row = await getEmployeeById(employeeId);
    final unpaid = await leaveDaysInMonth(
      employeeId: employeeId,
      year: year,
      month: month,
      workingDays: workingDays,
      kind: LeaveKind.unpaid,
    );
    // 📌 **والمدفوعة تُقرأ وإن لم تُغيّر رقماً**: هي لقطةٌ تُكتَب على السطر
    //   لتفسّره لاحقاً — «حضر ٣٠ يوماً منها ٥ إجازة مدفوعة».
    final paid = await leaveDaysInMonth(
      employeeId: employeeId,
      year: year,
      month: month,
      workingDays: workingDays,
      kind: LeaveKind.paid,
    );
    return (
      hireDate: row?.hireDate,
      terminationDate: row?.terminationDate,
      unpaidLeaveDays: unpaid,
      paidLeaveDays: paid,
    );
  }
}
