// ─────────────────────────────────────────────────────────────────────────────
// employee_events_ui.dart — جزء من مكتبة `employees_screen.dart`
//
// تبويب «السجل» في بطاقة الموظف (Schema v10 — طلب المالك 2026-09-03):
//   «سجل حركات في كل صفحة موظف حتى يبين لي متى تم تعيينه ومتى تم تعديل
//    راتبه ومتى أخذ إجازة أو سلفة ومتى تم إنهاء خدماته.»
//
// ⚠️ **قراءةٌ خالصة**: لا زرّ كتابةٍ هنا إطلاقاً. الأحداث تُكتَب حيث تقع
//   (تعديل الراتب في حواره، الإجازة في تبويبها…) — وسجلٌّ يُكتَب فيه بيد
//   يصير روايةً لا سجلّاً.
// ─────────────────────────────────────────────────────────────────────────────

part of 'employees_screen.dart';

class _EventsTab extends ConsumerWidget {
  const _EventsTab({
    required this.employee,
    required this.scrollController,
  });

  final EmployeeModel employee;
  final ScrollController scrollController;

  /// أيقونةٌ ولونٌ لكل نوع — العين تفرز السجل الطويل بالألوان قبل النصّ
  static (IconData, Color) _visual(String kind) => switch (kind) {
        EmployeeEventKind.hired => (Icons.badge_outlined, Colors.green),
        EmployeeEventKind.salaryChanged => (Icons.trending_up, Colors.blue),
        EmployeeEventKind.departmentChanged =>
          (Icons.category_outlined, Colors.purple),
        EmployeeEventKind.treasuryChanged =>
          (Icons.account_balance_wallet_outlined, Colors.teal),
        EmployeeEventKind.leaveAdded =>
          (Icons.beach_access_outlined, Colors.amber),
        EmployeeEventKind.leaveRemoved =>
          (Icons.beach_access_outlined, Colors.grey),
        EmployeeEventKind.advanceTaken => (Icons.money_off, Colors.orange),
        EmployeeEventKind.advanceRepaid => (Icons.savings_outlined, Colors.teal),
        EmployeeEventKind.terminated => (Icons.person_off_outlined, Colors.red),
        EmployeeEventKind.reinstated =>
          (Icons.person_add_alt_1_outlined, Colors.green),
        _ => (Icons.circle_outlined, Colors.blueGrey),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(employeeEventsProvider(employee.id));
    final dateFmt = DateFormat('yyyy/MM/dd');

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('تعذّر تحميل السجل: $e')),
      data: (events) {
        if (events.isEmpty) {
          return const AppEmptyState(
            icon: Icons.history_rounded,
            message: 'لا حركات مسجَّلة بعد.\n'
                'يُسجَّل هنا التعيين وتعديل الراتب والإجازات والسلف '
                'وإنهاء الخدمة.',
          );
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final e = events[i];
            final (icon, color) = _visual(e.kind);

            return Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Icon(icon, size: 16, color: color),
                ),
                title: Text(
                  e.description.isEmpty
                      ? EmployeeEventKind.label(e.kind)
                      : e.description,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // ⚠️ `.toLocal()` — `event_date` قد تُملأ من القاعدة
                      //   بـUTC، وعرضُها بلا تحويل يُنقص ثلاث ساعات (ع-١٤)
                      '${EmployeeEventKind.label(e.kind)} · '
                      '${dateFmt.format(e.eventDate.toLocal())}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    if (e.reference.isNotEmpty)
                      Text('السند: ${e.reference}',
                          style: const TextStyle(fontSize: 11)),
                    if (e.notes.isNotEmpty)
                      Text(e.notes, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
