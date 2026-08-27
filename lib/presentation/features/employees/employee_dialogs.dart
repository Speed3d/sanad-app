// ─────────────────────────────────────────────────────────────────────────────
// employee_dialogs.dart — حوارات الموظف
//
// جزء من مكتبة `employees_screen.dart` — راجع `employee_detail_sheet.dart`
// لسبب التقسيم.
//
// يحوي: حوار إضافة/تعديل موظف · صرف راتب · منح سلفة موظف · تسديد قسط.
//
// ⚠️ كل هذه الحوارات تملك متحكّماتها في `State` وتتخلّص منها في `dispose()`
// — وهو النمط الآمن. المحظور إنشاء متحكّم داخل دالة ثم التخلّص منه بعد
// `await showDialog`. راجع `test/unit/dialog_controller_lifecycle_test.dart`.
// ─────────────────────────────────────────────────────────────────────────────

part of 'employees_screen.dart';

// حوار نموذج الموظف (إضافة / تعديل)
// ═══════════════════════════════════════════════════════════════════════════

class _EmployeeFormDialog extends StatefulWidget {
  final String title;
  final Map<String, String?>? initialData;
  final Future<bool> Function(Map<String, String?>) onSave;

  const _EmployeeFormDialog({
    required this.title,
    this.initialData,
    required this.onSave,
  });

  @override
  State<_EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<_EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _salaryCtrl;
  late final TextEditingController _notesCtrl;
  DateTime? _hireDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nameCtrl = TextEditingController(text: d?['fullName'] ?? '');
    _phoneCtrl = TextEditingController(text: d?['phone'] ?? '');
    _addressCtrl = TextEditingController(text: d?['address'] ?? '');
    _salaryCtrl = TextEditingController(text: d?['basicSalary'] ?? '');
    _notesCtrl = TextEditingController(text: d?['notes'] ?? '');
    if (d?['hireDate'] != null) {
      _hireDate = DateTime.tryParse(d!['hireDate']!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _salaryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickHireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hireDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
      helpText: 'تاريخ التعيين',
    );
    if (picked != null && mounted) setState(() => _hireDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await widget.onSave({
      'fullName': _nameCtrl.text,
      'phone': _phoneCtrl.text,
      'address': _addressCtrl.text,
      'basicSalary': _salaryCtrl.text,
      'notes': _notesCtrl.text,
      'hireDate': _hireDate?.toIso8601String(),
    });
    if (ok && mounted) Navigator.pop(context);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmtDate = DateFormat('dd/MM/yyyy', 'ar');
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل *',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'الاسم مطلوب'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _salaryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الراتب الأساسي (د.ع)',
                    prefixIcon: Icon(Icons.payments_outlined, size: 20),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'))
                  ],
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                // تاريخ التعيين
                GestureDetector(
                  onTap: _pickHireDate,
                  // InputDecorator بدل TextFormField+Controller — بلا تسريب
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ التعيين',
                      prefixIcon:
                          Icon(Icons.calendar_today_outlined, size: 20),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      _hireDate != null ? fmtDate.format(_hireDate!) : '',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    prefixIcon: Icon(Icons.notes_outlined, size: 20),
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// حوار صرف الراتب
// ═══════════════════════════════════════════════════════════════════════════

class _PaySalaryDialog extends StatefulWidget {
  final EmployeeModel employee;
  final List<TreasuryModel> treasuries;
  final Future<bool> Function(Map<String, dynamic>) onSave;

  const _PaySalaryDialog({
    required this.employee,
    required this.treasuries,
    required this.onSave,
  });

  @override
  State<_PaySalaryDialog> createState() => _PaySalaryDialogState();
}

class _PaySalaryDialogState extends State<_PaySalaryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _basicCtrl;
  final _additionsCtrl = TextEditingController(text: '0');
  final _deductionsCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  int? _treasuryId;
  DateTime _paymentDate = DateTime.now();
  bool _saving = false;

  /// شهر **الراتب** وسنته — إلزاميان (قرار المالك 2026-08-26)
  ///
  /// 🔑 **لماذا قائمتان لا نصّ حرّ؟**
  ///   كان الحقل نصّاً يكتب فيه المستخدم ما شاء، وافتراضيه بأسماء أشهر
  ///   مختلفة عن نظام الرواتب («أغسطس 2025» مقابل «آب 2025») — فتعذّر
  ///   بنيوياً ربطُ راتبٍ مباشر بكشف شهره. وبالقائمتين يصير الراتب سطراً
  ///   في كشفه، فيظهر في التقارير ويُنبَّه عند استيراد ملف الشهر نفسه.
  late int _salaryYear;
  late int _salaryMonth;

  @override
  void initState() {
    super.initState();
    _basicCtrl = TextEditingController(
      text: widget.employee.basicSalary > 0
          ? widget.employee.basicSalary.toStringAsFixed(0)
          : '',
    );
    // الافتراضي: **الشهر السابق** (قرار المالك 2026-08-26) — الرواتب
    // تُصرف بعد انتهاء شهرها، فالشهر الحالي كان يعني تصحيحاً يدوياً في
    // كل مرة تقريباً.
    final previous = DateTime(DateTime.now().year, DateTime.now().month - 1);
    _salaryYear = previous.year;
    _salaryMonth = previous.month;
  }

  @override
  void dispose() {
    _basicCtrl.dispose();
    _additionsCtrl.dispose();
    _deductionsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _net =>
      (double.tryParse(_basicCtrl.text) ?? 0) +
      (double.tryParse(_additionsCtrl.text) ?? 0) -
      (double.tryParse(_deductionsCtrl.text) ?? 0);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_treasuryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('اختر الخزينة'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.onSave({
      'treasuryId': _treasuryId,
      'basicSalary': double.tryParse(_basicCtrl.text) ?? 0.0,
      'additions': double.tryParse(_additionsCtrl.text) ?? 0.0,
      'deductions': double.tryParse(_deductionsCtrl.text) ?? 0.0,
      'year': _salaryYear,
      'month': _salaryMonth,
      'paymentDate': _paymentDate,
      'notes': _notesCtrl.text.trim(),
    });
    if (ok && mounted) Navigator.pop(context);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmtNum = NumberFormat('#,##0', 'ar');
    final fmtDate = DateFormat('dd/MM/yyyy', 'ar');

    return AlertDialog(
      title: Text('صرف راتب: ${widget.employee.fullName}'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── شهر الراتب — إلزامي ──────────────────────────
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        initialValue: _salaryMonth,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'شهر الراتب *',
                          prefixIcon:
                              Icon(Icons.event_note_outlined, size: 20),
                        ),
                        items: [
                          for (var m = 1; m <= 12; m++)
                            DropdownMenuItem(
                              value: m,
                              child: Text(PayrollCalculator.arabicMonth(m)),
                            ),
                        ],
                        onChanged: (v) =>
                            setState(() => _salaryMonth = v ?? _salaryMonth),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        initialValue: _salaryYear,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'السنة *',
                        ),
                        items: [
                          // نطاق معقول حول اليوم: ماضٍ للتصحيح ومستقبل
                          // قريب لا يُغري بخطأ إدخال
                          for (var y = DateTime.now().year - 3;
                              y <= DateTime.now().year + 1;
                              y++)
                            DropdownMenuItem(value: y, child: Text('$y')),
                        ],
                        onChanged: (v) =>
                            setState(() => _salaryYear = v ?? _salaryYear),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // 🔑 إخبارٌ صريح بأثر العملية قبل وقوعها
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.blueGrey.shade400),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'سيُسجَّل هذا الراتب ضمن كشف رواتب '
                        '${PayrollCalculator.periodLabel(_salaryYear, _salaryMonth)}'
                        '، ويُنبَّه عند استيراد ملف الشهر نفسه.',
                        style: TextStyle(
                            fontSize: 11, color: Colors.blueGrey.shade400),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // الخزينة
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  hint: const Text('اختر الخزينة'),
                  decoration: const InputDecoration(
                    labelText: 'الخزينة *',
                    prefixIcon: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20),
                  ),
                  items: widget.treasuries
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _treasuryId = v),
                  validator: (v) =>
                      v == null ? 'اختر الخزينة' : null,
                ),
                const SizedBox(height: 12),
                // الراتب الأساسي
                TextFormField(
                  controller: _basicCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الراتب الأساسي (د.ع) *',
                    prefixIcon: Icon(Icons.attach_money, size: 20),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'))
                  ],
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    if (val == null) return 'رقم غير صالح';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // الإضافات والخصومات
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _additionsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'إضافات',
                          prefixIcon: Icon(Icons.add_circle_outline,
                              size: 20, color: Colors.green),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'))
                        ],
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _deductionsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'خصومات',
                          prefixIcon: Icon(Icons.remove_circle_outline,
                              size: 20, color: Colors.red),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'))
                        ],
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // الصافي
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الصافي:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${fmtNum.format(_net)} د.ع',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _net > 0
                              ? Theme.of(context).colorScheme.primary
                              : Colors.red,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // التاريخ
                GestureDetector(
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _paymentDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      locale: const Locale('ar'),
                    );
                    if (p != null && mounted) {
                      setState(() => _paymentDate = p);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الصرف',
                      prefixIcon:
                          Icon(Icons.calendar_today_outlined, size: 20),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(fmtDate.format(_paymentDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    prefixIcon: Icon(Icons.notes_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('صرف الراتب'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// حوار منح سلفة
// ═══════════════════════════════════════════════════════════════════════════

class _GrantAdvanceDialog extends StatefulWidget {
  final EmployeeModel employee;
  final List<TreasuryModel> treasuries;
  final Future<bool> Function(Map<String, dynamic>) onSave;

  const _GrantAdvanceDialog({
    required this.employee,
    required this.treasuries,
    required this.onSave,
  });

  @override
  State<_GrantAdvanceDialog> createState() => _GrantAdvanceDialogState();
}

class _GrantAdvanceDialogState extends State<_GrantAdvanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  int? _treasuryId;
  String _currency = 'IQD';
  DateTime _advanceDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_treasuryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('اختر الخزينة'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.onSave({
      'treasuryId': _treasuryId,
      'amount': double.tryParse(_amountCtrl.text) ?? 0.0,
      'currency': _currency,
      'advanceDate': _advanceDate,
      'reason': _reasonCtrl.text.trim(),
    });
    if (ok && mounted) Navigator.pop(context);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmtDate = DateFormat('dd/MM/yyyy', 'ar');
    return AlertDialog(
      title: Text('منح سلفة: ${widget.employee.fullName}'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // الخزينة
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  hint: const Text('اختر الخزينة'),
                  decoration: const InputDecoration(
                    labelText: 'الخزينة *',
                    prefixIcon: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20),
                  ),
                  items: widget.treasuries
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _treasuryId = v),
                  validator: (v) =>
                      v == null ? 'اختر الخزينة' : null,
                ),
                const SizedBox(height: 12),
                // المبلغ + العملة
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _amountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'المبلغ *',
                          prefixIcon:
                              Icon(Icons.attach_money, size: 20),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,3}'))
                        ],
                        validator: (v) {
                          final val = double.tryParse(v ?? '');
                          if (val == null || val <= 0) {
                            return 'أدخل مبلغاً صالحاً';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          const SizedBox(height: 4),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                  value: 'IQD', label: Text('د.ع')),
                              ButtonSegment(
                                  value: 'USD', label: Text('\$')),
                            ],
                            selected: {_currency},
                            onSelectionChanged: (s) =>
                                setState(() => _currency = s.first),
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // التاريخ
                GestureDetector(
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _advanceDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      locale: const Locale('ar'),
                    );
                    if (p != null && mounted) {
                      setState(() => _advanceDate = p);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ السلفة',
                      prefixIcon:
                          Icon(Icons.calendar_today_outlined, size: 20),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(fmtDate.format(_advanceDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'السبب / الغرض',
                    prefixIcon: Icon(Icons.notes_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('منح السلفة'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// حوار سداد سلفة
// ═══════════════════════════════════════════════════════════════════════════

class _RepayAdvanceDialog extends StatefulWidget {
  final CashAdvanceModel advance;
  final List<TreasuryModel> treasuries;
  final Future<bool> Function(Map<String, dynamic>) onSave;

  const _RepayAdvanceDialog({
    required this.advance,
    required this.treasuries,
    required this.onSave,
  });

  @override
  State<_RepayAdvanceDialog> createState() => _RepayAdvanceDialogState();
}

class _RepayAdvanceDialogState extends State<_RepayAdvanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  final _notesCtrl = TextEditingController();
  int? _treasuryId;
  String _method = 'cash';
  DateTime _repaymentDate = DateTime.now();
  bool _saving = false;

  static const _methods = {
    'cash': 'نقداً',
    'salary_deduction': 'خصم من الراتب',
    'bank_transfer': 'تحويل بنكي',
  };

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.advance.remainingAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_treasuryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('اختر الخزينة'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.onSave({
      'treasuryId': _treasuryId,
      'amount': double.tryParse(_amountCtrl.text) ?? 0.0,
      'repaymentDate': _repaymentDate,
      'method': _method,
      'notes': _notesCtrl.text.trim(),
    });
    if (ok && mounted) Navigator.pop(context);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmtNum = NumberFormat('#,##0', 'ar');
    final fmtDate = DateFormat('dd/MM/yyyy', 'ar');

    return AlertDialog(
      title: const Text('تسجيل سداد سلفة'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // معلومات السلفة
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المتبقي:',
                          style: TextStyle(
                              color: Colors.orange.shade800)),
                      Text(
                        '${fmtNum.format(widget.advance.remainingAmount)} ${widget.advance.currency == 'IQD' ? 'د.ع' : '\$'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // الخزينة
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  hint: const Text('اختر الخزينة'),
                  decoration: const InputDecoration(
                    labelText: 'الخزينة *',
                    prefixIcon: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20),
                  ),
                  items: widget.treasuries
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _treasuryId = v),
                  validator: (v) =>
                      v == null ? 'اختر الخزينة' : null,
                ),
                const SizedBox(height: 12),
                // مبلغ السداد
                TextFormField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'مبلغ السداد *',
                    prefixIcon: Icon(Icons.attach_money, size: 20),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,3}'))
                  ],
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    if (val == null || val <= 0) return 'مبلغ غير صالح';
                    if (val > widget.advance.remainingAmount + 0.001) {
                      return 'أكبر من المبلغ المتبقي';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // طريقة السداد
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'طريقة السداد',
                    prefixIcon:
                        Icon(Icons.payment_outlined, size: 20),
                  ),
                  items: _methods.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _method = v ?? 'cash'),
                ),
                const SizedBox(height: 12),
                // التاريخ
                GestureDetector(
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _repaymentDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      locale: const Locale('ar'),
                    );
                    if (p != null && mounted) {
                      setState(() => _repaymentDate = p);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ السداد',
                      prefixIcon: Icon(
                          Icons.calendar_today_outlined,
                          size: 20),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(fmtDate.format(_repaymentDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    prefixIcon: Icon(Icons.notes_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green.shade700,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('تسجيل السداد'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// مكونات مساعدة
// ═══════════════════════════════════════════════════════════════════════════

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _SmallBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  final VoidCallback onAdd;

  const _EmptyState({required this.isSearch, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'لا نتائج للبحث' : 'لا يوجد موظفون بعد',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!isSearch) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('إضافة أول موظف'),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onAction;

  const _TabEmptyState({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add, size: 18),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
