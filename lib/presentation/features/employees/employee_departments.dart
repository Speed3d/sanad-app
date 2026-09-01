// ─────────────────────────────────────────────────────────────────────────────
// employee_departments.dart — الأقسام وفلتر الحالة والترتيب اليدوي (Schema v8)
//
// جزءٌ من `employees_screen.dart` — راجع رأسه.
//
// **البلاغ الذي أنتج هذا الملف** (المالك 2026-08-30 · الدفعة د):
//   «أريد الموظفين مرتّبين بأقسام: مهندسون ١–٧ · فنيون ٨–١٩ · سواق ٢٠–٣٥،
//   وأن أرتّبهم بيدي داخل كل قسم. وأريد حالة لكل موظف: حالي · منتهية
//   خدمته · إجازة.»
//
// ═══ ثلاثة قرارات تصميمية تُفسَّر مرّة واحدة هنا ═══
//
//   ١. **قائمة لكل قسم لا قائمة واحدة بعناوين.** `SliverReorderableList`
//      لكل قسم تعني أن السحب لا يتجاوز حدود القسم — وهو **الصواب**: نقل
//      موظفٍ بين قسمين قرارٌ إداري يُتَّخذ بوعي، لا أثرٌ جانبيّ لسحبةٍ
//      طويلة أخطأت هدفها. والنقل بابه «نقل إلى قسم…» في قائمة الموظف.
//
//   ٢. **السحب معطَّل مع أي فلتر.** راجع `canReorder` في الشاشة.
//
//   ٣. **«بلا قسم» في الآخر** — راجع `EmployeesDao._orderedEmployees`.
// ─────────────────────────────────────────────────────────────────────────────

part of 'employees_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// شريط فلترة الحالة
// ═══════════════════════════════════════════════════════════════════════════

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _chip(context, 'الكل', null),
          // التسميات من `EmployeeStatus` لا مكتوبة هنا — ترجمةٌ منسوخة
          // تُصحَّح في موضع وتُنسى في آخر (ع-٤٧)
          for (final s in EmployeeStatus.all)
            _chip(context, EmployeeStatus.label(s), s),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, String? value) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      selected: selected == value,
      onSelected: (_) => onChanged(value),
      visualDensity: VisualDensity.compact,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// قائمة الموظفين مقسَّمةً بالأقسام مع السحب والإفلات
// ═══════════════════════════════════════════════════════════════════════════

/// قسمٌ معروض: معرّفه (أو `null` لـ«بلا قسم») واسمه وموظفوه
typedef _Section = ({int? id, String name, List<EmployeeModel> members});

class _EmployeeSections extends ConsumerWidget {
  const _EmployeeSections({
    required this.employees,
    required this.canReorder,
    required this.onTap,
    required this.onReorder,
  });

  /// الموظفون **بعد الفلترة** وبالترتيب القادم من القاعدة
  final List<EmployeeModel> employees;

  final bool canReorder;
  final void Function(EmployeeModel) onTap;
  final Future<bool> Function(List<int> idsInOrder) onReorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<DepartmentModel> departments =
        ref.watch(allDepartmentsProvider).valueOrNull ?? const [];

    final byDept = <int?, List<EmployeeModel>>{};
    for (final e in employees) {
      byDept.putIfAbsent(e.departmentId, () => []).add(e);
    }

    final sections = <_Section>[
      for (final d in departments)
        if (byDept[d.id] != null)
          (id: d.id, name: d.name, members: byDept[d.id]!),
      // ⚠️ ويشمل هذا **من ينتمي إلى قسمٍ حُذف** لو بقي رابطه: حذف القسم
      //   يفكّ الربط صراحةً، فلا انتماء شبحيّ — راجع `deleteDepartment`.
      if (byDept[null] != null)
        (id: null, name: 'بلا قسم', members: byDept[null]!),
    ];

    // شركة بلا أقسام: قائمةٌ واحدة بلا عناوين — العنوان الوحيد ضجيج
    final showHeaders = departments.isNotEmpty;

    return CustomScrollView(
      slivers: [
        if (!canReorder)
          const SliverToBoxAdapter(child: _ReorderDisabledHint()),
        for (final sec in sections) ...[
          if (showHeaders)
            SliverToBoxAdapter(
              child: _SectionHeader(name: sec.name, count: sec.members.length),
            ),
          if (canReorder)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              sliver: SliverReorderableList(
                itemCount: sec.members.length,
                onReorderItem: (oldIndex, newIndex) =>
                    _reorderWithin(sec, oldIndex, newIndex),
                itemBuilder: (ctx, i) => _row(sec.members[i], i, dragging: true),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              sliver: SliverList.builder(
                itemCount: sec.members.length,
                itemBuilder: (ctx, i) =>
                    _row(sec.members[i], i, dragging: false),
              ),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ],
    );
  }

  /// صفّ موظف — بمقبض سحبٍ حين يكون الترتيب متاحاً
  ///
  /// ⚠️ `SliverReorderableList` **لا تُضيف مقبضاً بنفسها** بخلاف
  ///   `ReorderableListView`. بلا `ReorderableDragStartListener` يبدو
  ///   الترتيب معطَّلاً وهو مفعَّل — عطلٌ صامت في الواجهة.
  Widget _row(EmployeeModel e, int index, {required bool dragging}) {
    final card = _EmployeeCard(employee: e, onTap: () => onTap(e));
    return Padding(
      key: ValueKey(e.id),
      padding: const EdgeInsets.only(bottom: 10),
      child: dragging
          ? Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.drag_indicator, size: 20),
                  ),
                ),
                Expanded(child: card),
              ],
            )
          : card,
    );
  }

  void _reorderWithin(_Section sec, int oldIndex, int newIndex) {
    // ⚠️ `onReorderItem` لا `onReorder`: الأولى تُصحّح الفهرس عند النزول
    //   للأسفل بنفسها، والثانية مهجورة منذ Flutter 3.41 وتتطلّب تصحيحاً
    //   يدوياً يُنسى فيقع العنصر مكاناً واحداً قبل هدفه.
    final ids = [for (final e in sec.members) e.id];
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    onReorder(ids);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 8),
      child: Row(
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: context.colors.text,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: context.colors.surface2,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.colors.subtext,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: context.colors.border, height: 1)),
        ],
      ),
    );
  }
}

/// تنبيهٌ يقول **لماذا** لا يعمل السحب — لا صمتٌ يبدو عطلاً
class _ReorderDisabledHint extends StatelessWidget {
  const _ReorderDisabledHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 15, color: context.colors.subtext),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'الترتيب اليدوي متاح بلا فلاتر — امسح البحث والمشروع والحالة.',
              style: TextStyle(fontSize: 11.5, color: context.colors.subtext),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// حوار إدارة الأقسام
// ═══════════════════════════════════════════════════════════════════════════

Future<void> _showDepartmentsDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const _DepartmentsDialog(),
    );

class _DepartmentsDialog extends ConsumerStatefulWidget {
  const _DepartmentsDialog();

  @override
  ConsumerState<_DepartmentsDialog> createState() => _DepartmentsDialogState();
}

class _DepartmentsDialogState extends ConsumerState<_DepartmentsDialog> {
  // ⚠️ المتحكّم يعيش مع الحالة ويُتخلَّص منه في `dispose` — لا يُنشَأ خارج
  //   الحوار ثم يُتخلَّص منه بعد `await showDialog` (ع-٠٤: الـ await ينتهي
  //   لحظة `Navigator.pop` لا لحظة اختفاء الحوار ⇒ شاشة حمراء).
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  EmployeeNotifier get _notifier =>
      ref.read(employeeNotifierProvider.notifier);

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final ok = await _notifier.addDepartment(name);
    if (ok) _nameCtrl.clear();
  }

  Future<void> _rename(DepartmentModel d) async {
    final name = await _promptName(context, initial: d.name, title: 'تسمية القسم');
    if (name == null || !mounted) return;
    await _notifier.renameDepartment(d.id, name);
  }

  Future<void> _delete(DepartmentModel d, int members) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حذف القسم «${d.name}»'),
        // العدد **قبل** التأكيد: حذفٌ جماعي بلا رقم يجعل المالك يضغط على
        // المجهول — القاعدة نفسها في «نقل موظفي مشروع»
        content: Text(members == 0
            ? 'لا موظف في هذا القسم.'
            : 'سيصير $members موظفاً **بلا قسم**، ولا يُحذف أحد منهم.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _notifier.removeDepartment(d.id);
  }

  @override
  Widget build(BuildContext context) {
    final List<DepartmentModel> departments =
        ref.watch(allDepartmentsProvider).valueOrNull ?? const [];
    final List<EmployeeModel> employees =
        ref.watch(allEmployeesProvider).valueOrNull ?? const [];

    int membersOf(int id) =>
        employees.where((e) => e.departmentId == id).length;

    return AlertDialog(
      title: const Text('أقسام الموظفين'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم قسم جديد',
                      hintText: 'مهندسون · فنيون · سواق',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _add, child: const Text('إضافة')),
              ],
            ),
            const SizedBox(height: 14),
            if (departments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'لا أقسام بعد — أضف أولها، ثم انقل الموظفين إليها من قائمة كل موظف.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: 300,
                child: ReorderableListView.builder(
                  itemCount: departments.length,
                  onReorderItem: (oldIndex, newIndex) {
                    final ids = [for (final d in departments) d.id];
                    final moved = ids.removeAt(oldIndex);
                    ids.insert(newIndex, moved);
                    _notifier.reorderDepartments(ids);
                  },
                  itemBuilder: (ctx, i) {
                    final d = departments[i];
                    final n = membersOf(d.id);
                    return ListTile(
                      key: ValueKey(d.id),
                      dense: true,
                      title: Text(d.name),
                      subtitle: Text('$n موظفاً'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'إعادة تسمية',
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _rename(d),
                          ),
                          IconButton(
                            tooltip: 'حذف',
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => _delete(d, n),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 6),
            Text(
              'اسحب القسم لتغيير ترتيبه — وترتيب الأقسام هو ترتيب القائمة.',
              style: TextStyle(fontSize: 11.5, color: context.colors.subtext),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// نقل موظف إلى قسم
// ═══════════════════════════════════════════════════════════════════════════

/// حوار اختيار قسمٍ لموظف — و«بلا قسم» خيارٌ صريح لا غياب
Future<void> _showAssignDepartmentDialog(
  BuildContext context,
  WidgetRef ref,
  EmployeeModel employee,
) async {
  final List<DepartmentModel> departments =
      ref.read(allDepartmentsProvider).valueOrNull ?? const [];

  final chosen = await showDialog<({bool picked, int? id})>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text('نقل «${employee.fullName}» إلى قسم'),
      children: [
        if (departments.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Text('لا أقسام بعد — أنشئها من زرّ «الأقسام».'),
          ),
        for (final d in departments)
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(ctx).pop((picked: true, id: d.id)),
            child: Row(
              children: [
                Icon(
                  d.id == employee.departmentId
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(d.name),
              ],
            ),
          ),
        const Divider(),
        SimpleDialogOption(
          onPressed: () => Navigator.of(ctx).pop((picked: true, id: null)),
          child: Row(
            children: [
              Icon(
                employee.departmentId == null
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
              ),
              const SizedBox(width: 10),
              const Text('بلا قسم'),
            ],
          ),
        ),
      ],
    ),
  );

  if (chosen == null || !chosen.picked) return;
  await ref
      .read(employeeNotifierProvider.notifier)
      .assignDepartment(employee.id, chosen.id);
}

/// حوار إدخال اسم — يُستعمَل لإعادة تسمية قسم
Future<String?> _promptName(
  BuildContext context, {
  required String initial,
  required String title,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _NamePromptDialog(initial: initial, title: title),
  );
}

class _NamePromptDialog extends StatefulWidget {
  const _NamePromptDialog({required this.initial, required this.title});

  final String initial;
  final String title;

  @override
  State<_NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<_NamePromptDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
