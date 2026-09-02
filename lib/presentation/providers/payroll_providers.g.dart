// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$payrollYearsHash() => r'af88127cc76acd03a642376ff8aca146c9b899d5';

/// سنوات الرواتب المشتقّة من الكشوف — الأحدث أولاً
///
/// Copied from [payrollYears].
@ProviderFor(payrollYears)
final payrollYearsProvider =
    AutoDisposeFutureProvider<List<PayrollYearSummary>>.internal(
  payrollYears,
  name: r'payrollYearsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$payrollYearsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PayrollYearsRef
    = AutoDisposeFutureProviderRef<List<PayrollYearSummary>>;
String _$allPayrollPeriodsHash() => r'67cfd697cb02fe68667ab9e59666ed30c95fa5a8';

/// كل كشوف الرواتب — Reactive
///
/// Copied from [allPayrollPeriods].
@ProviderFor(allPayrollPeriods)
final allPayrollPeriodsProvider =
    AutoDisposeStreamProvider<List<PayrollPeriod>>.internal(
  allPayrollPeriods,
  name: r'allPayrollPeriodsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allPayrollPeriodsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllPayrollPeriodsRef
    = AutoDisposeStreamProviderRef<List<PayrollPeriod>>;
String _$payrollPeriodsForYearHash() =>
    r'91511c7acb8777b89e2cd9a188c949bfc0ecd4e3';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// كشوف سنة بعينها
///
/// Copied from [payrollPeriodsForYear].
@ProviderFor(payrollPeriodsForYear)
const payrollPeriodsForYearProvider = PayrollPeriodsForYearFamily();

/// كشوف سنة بعينها
///
/// Copied from [payrollPeriodsForYear].
class PayrollPeriodsForYearFamily
    extends Family<AsyncValue<List<PayrollPeriod>>> {
  /// كشوف سنة بعينها
  ///
  /// Copied from [payrollPeriodsForYear].
  const PayrollPeriodsForYearFamily();

  /// كشوف سنة بعينها
  ///
  /// Copied from [payrollPeriodsForYear].
  PayrollPeriodsForYearProvider call(
    int year,
  ) {
    return PayrollPeriodsForYearProvider(
      year,
    );
  }

  @override
  PayrollPeriodsForYearProvider getProviderOverride(
    covariant PayrollPeriodsForYearProvider provider,
  ) {
    return call(
      provider.year,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'payrollPeriodsForYearProvider';
}

/// كشوف سنة بعينها
///
/// Copied from [payrollPeriodsForYear].
class PayrollPeriodsForYearProvider
    extends AutoDisposeStreamProvider<List<PayrollPeriod>> {
  /// كشوف سنة بعينها
  ///
  /// Copied from [payrollPeriodsForYear].
  PayrollPeriodsForYearProvider(
    int year,
  ) : this._internal(
          (ref) => payrollPeriodsForYear(
            ref as PayrollPeriodsForYearRef,
            year,
          ),
          from: payrollPeriodsForYearProvider,
          name: r'payrollPeriodsForYearProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$payrollPeriodsForYearHash,
          dependencies: PayrollPeriodsForYearFamily._dependencies,
          allTransitiveDependencies:
              PayrollPeriodsForYearFamily._allTransitiveDependencies,
          year: year,
        );

  PayrollPeriodsForYearProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.year,
  }) : super.internal();

  final int year;

  @override
  Override overrideWith(
    Stream<List<PayrollPeriod>> Function(PayrollPeriodsForYearRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PayrollPeriodsForYearProvider._internal(
        (ref) => create(ref as PayrollPeriodsForYearRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        year: year,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<PayrollPeriod>> createElement() {
    return _PayrollPeriodsForYearProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PayrollPeriodsForYearProvider && other.year == year;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PayrollPeriodsForYearRef
    on AutoDisposeStreamProviderRef<List<PayrollPeriod>> {
  /// The parameter `year` of this provider.
  int get year;
}

class _PayrollPeriodsForYearProviderElement
    extends AutoDisposeStreamProviderElement<List<PayrollPeriod>>
    with PayrollPeriodsForYearRef {
  _PayrollPeriodsForYearProviderElement(super.provider);

  @override
  int get year => (origin as PayrollPeriodsForYearProvider).year;
}

String _$payrollPeriodHash() => r'a8e91fd6a3f571e0ffa8ea48ea42167058043351';

/// كشف واحد بالمعرّف
///
/// Copied from [payrollPeriod].
@ProviderFor(payrollPeriod)
const payrollPeriodProvider = PayrollPeriodFamily();

/// كشف واحد بالمعرّف
///
/// Copied from [payrollPeriod].
class PayrollPeriodFamily extends Family<AsyncValue<PayrollPeriod?>> {
  /// كشف واحد بالمعرّف
  ///
  /// Copied from [payrollPeriod].
  const PayrollPeriodFamily();

  /// كشف واحد بالمعرّف
  ///
  /// Copied from [payrollPeriod].
  PayrollPeriodProvider call(
    int periodId,
  ) {
    return PayrollPeriodProvider(
      periodId,
    );
  }

  @override
  PayrollPeriodProvider getProviderOverride(
    covariant PayrollPeriodProvider provider,
  ) {
    return call(
      provider.periodId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'payrollPeriodProvider';
}

/// كشف واحد بالمعرّف
///
/// Copied from [payrollPeriod].
class PayrollPeriodProvider extends AutoDisposeStreamProvider<PayrollPeriod?> {
  /// كشف واحد بالمعرّف
  ///
  /// Copied from [payrollPeriod].
  PayrollPeriodProvider(
    int periodId,
  ) : this._internal(
          (ref) => payrollPeriod(
            ref as PayrollPeriodRef,
            periodId,
          ),
          from: payrollPeriodProvider,
          name: r'payrollPeriodProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$payrollPeriodHash,
          dependencies: PayrollPeriodFamily._dependencies,
          allTransitiveDependencies:
              PayrollPeriodFamily._allTransitiveDependencies,
          periodId: periodId,
        );

  PayrollPeriodProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.periodId,
  }) : super.internal();

  final int periodId;

  @override
  Override overrideWith(
    Stream<PayrollPeriod?> Function(PayrollPeriodRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PayrollPeriodProvider._internal(
        (ref) => create(ref as PayrollPeriodRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        periodId: periodId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<PayrollPeriod?> createElement() {
    return _PayrollPeriodProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PayrollPeriodProvider && other.periodId == periodId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, periodId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PayrollPeriodRef on AutoDisposeStreamProviderRef<PayrollPeriod?> {
  /// The parameter `periodId` of this provider.
  int get periodId;
}

class _PayrollPeriodProviderElement
    extends AutoDisposeStreamProviderElement<PayrollPeriod?>
    with PayrollPeriodRef {
  _PayrollPeriodProviderElement(super.provider);

  @override
  int get periodId => (origin as PayrollPeriodProvider).periodId;
}

String _$payrollEntriesHash() => r'dfbb650b3a84066cd081f59686f46566990fbf4b';

/// سطور كشف — Reactive
///
/// Copied from [payrollEntries].
@ProviderFor(payrollEntries)
const payrollEntriesProvider = PayrollEntriesFamily();

/// سطور كشف — Reactive
///
/// Copied from [payrollEntries].
class PayrollEntriesFamily extends Family<AsyncValue<List<SalaryPayment>>> {
  /// سطور كشف — Reactive
  ///
  /// Copied from [payrollEntries].
  const PayrollEntriesFamily();

  /// سطور كشف — Reactive
  ///
  /// Copied from [payrollEntries].
  PayrollEntriesProvider call(
    int periodId,
  ) {
    return PayrollEntriesProvider(
      periodId,
    );
  }

  @override
  PayrollEntriesProvider getProviderOverride(
    covariant PayrollEntriesProvider provider,
  ) {
    return call(
      provider.periodId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'payrollEntriesProvider';
}

/// سطور كشف — Reactive
///
/// Copied from [payrollEntries].
class PayrollEntriesProvider
    extends AutoDisposeStreamProvider<List<SalaryPayment>> {
  /// سطور كشف — Reactive
  ///
  /// Copied from [payrollEntries].
  PayrollEntriesProvider(
    int periodId,
  ) : this._internal(
          (ref) => payrollEntries(
            ref as PayrollEntriesRef,
            periodId,
          ),
          from: payrollEntriesProvider,
          name: r'payrollEntriesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$payrollEntriesHash,
          dependencies: PayrollEntriesFamily._dependencies,
          allTransitiveDependencies:
              PayrollEntriesFamily._allTransitiveDependencies,
          periodId: periodId,
        );

  PayrollEntriesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.periodId,
  }) : super.internal();

  final int periodId;

  @override
  Override overrideWith(
    Stream<List<SalaryPayment>> Function(PayrollEntriesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PayrollEntriesProvider._internal(
        (ref) => create(ref as PayrollEntriesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        periodId: periodId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<SalaryPayment>> createElement() {
    return _PayrollEntriesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PayrollEntriesProvider && other.periodId == periodId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, periodId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PayrollEntriesRef on AutoDisposeStreamProviderRef<List<SalaryPayment>> {
  /// The parameter `periodId` of this provider.
  int get periodId;
}

class _PayrollEntriesProviderElement
    extends AutoDisposeStreamProviderElement<List<SalaryPayment>>
    with PayrollEntriesRef {
  _PayrollEntriesProviderElement(super.provider);

  @override
  int get periodId => (origin as PayrollEntriesProvider).periodId;
}

String _$payrollTotalsHash() => r'884a6910cf8da50b67a9ac1cb6207faccc60e510';

/// إجماليات كشف — **مصدر الحقيقة الوحيد** لمجموع الرواتب
///
/// كل شاشة وطباعة وتقرير تسأل هنا. توزيع الجمع على المستدعين هو حرفياً ما
/// ضرب مشروع DMS المرجعي: كان مكرَّراً في ثمانية مواضع فاحتُسب راتب لم يُدفع.
///
/// Copied from [payrollTotals].
@ProviderFor(payrollTotals)
const payrollTotalsProvider = PayrollTotalsFamily();

/// إجماليات كشف — **مصدر الحقيقة الوحيد** لمجموع الرواتب
///
/// كل شاشة وطباعة وتقرير تسأل هنا. توزيع الجمع على المستدعين هو حرفياً ما
/// ضرب مشروع DMS المرجعي: كان مكرَّراً في ثمانية مواضع فاحتُسب راتب لم يُدفع.
///
/// Copied from [payrollTotals].
class PayrollTotalsFamily extends Family<AsyncValue<PayrollPeriodTotals>> {
  /// إجماليات كشف — **مصدر الحقيقة الوحيد** لمجموع الرواتب
  ///
  /// كل شاشة وطباعة وتقرير تسأل هنا. توزيع الجمع على المستدعين هو حرفياً ما
  /// ضرب مشروع DMS المرجعي: كان مكرَّراً في ثمانية مواضع فاحتُسب راتب لم يُدفع.
  ///
  /// Copied from [payrollTotals].
  const PayrollTotalsFamily();

  /// إجماليات كشف — **مصدر الحقيقة الوحيد** لمجموع الرواتب
  ///
  /// كل شاشة وطباعة وتقرير تسأل هنا. توزيع الجمع على المستدعين هو حرفياً ما
  /// ضرب مشروع DMS المرجعي: كان مكرَّراً في ثمانية مواضع فاحتُسب راتب لم يُدفع.
  ///
  /// Copied from [payrollTotals].
  PayrollTotalsProvider call(
    int periodId,
  ) {
    return PayrollTotalsProvider(
      periodId,
    );
  }

  @override
  PayrollTotalsProvider getProviderOverride(
    covariant PayrollTotalsProvider provider,
  ) {
    return call(
      provider.periodId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'payrollTotalsProvider';
}

/// إجماليات كشف — **مصدر الحقيقة الوحيد** لمجموع الرواتب
///
/// كل شاشة وطباعة وتقرير تسأل هنا. توزيع الجمع على المستدعين هو حرفياً ما
/// ضرب مشروع DMS المرجعي: كان مكرَّراً في ثمانية مواضع فاحتُسب راتب لم يُدفع.
///
/// Copied from [payrollTotals].
class PayrollTotalsProvider
    extends AutoDisposeFutureProvider<PayrollPeriodTotals> {
  /// إجماليات كشف — **مصدر الحقيقة الوحيد** لمجموع الرواتب
  ///
  /// كل شاشة وطباعة وتقرير تسأل هنا. توزيع الجمع على المستدعين هو حرفياً ما
  /// ضرب مشروع DMS المرجعي: كان مكرَّراً في ثمانية مواضع فاحتُسب راتب لم يُدفع.
  ///
  /// Copied from [payrollTotals].
  PayrollTotalsProvider(
    int periodId,
  ) : this._internal(
          (ref) => payrollTotals(
            ref as PayrollTotalsRef,
            periodId,
          ),
          from: payrollTotalsProvider,
          name: r'payrollTotalsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$payrollTotalsHash,
          dependencies: PayrollTotalsFamily._dependencies,
          allTransitiveDependencies:
              PayrollTotalsFamily._allTransitiveDependencies,
          periodId: periodId,
        );

  PayrollTotalsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.periodId,
  }) : super.internal();

  final int periodId;

  @override
  Override overrideWith(
    FutureOr<PayrollPeriodTotals> Function(PayrollTotalsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PayrollTotalsProvider._internal(
        (ref) => create(ref as PayrollTotalsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        periodId: periodId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PayrollPeriodTotals> createElement() {
    return _PayrollTotalsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PayrollTotalsProvider && other.periodId == periodId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, periodId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PayrollTotalsRef on AutoDisposeFutureProviderRef<PayrollPeriodTotals> {
  /// The parameter `periodId` of this provider.
  int get periodId;
}

class _PayrollTotalsProviderElement
    extends AutoDisposeFutureProviderElement<PayrollPeriodTotals>
    with PayrollTotalsRef {
  _PayrollTotalsProviderElement(super.provider);

  @override
  int get periodId => (origin as PayrollTotalsProvider).periodId;
}

String _$payrollPaidEmployeesForMonthHash() =>
    r'c4b82ec7c6f2639cbfc284dec7278840fb4c82db';

/// موظفو شهرٍ الذين سُدِّدت رواتبهم فعلاً — تنبيه معالج الاستيراد
///
/// 🔑 **سبب وجوده** (طلب المالك 2026-08-26): قد يكون صرف راتب موظف مباشرةً من
///   بطاقته عن شهر ٨، ثم يستورد ملف الشهر نفسه وقد نسي. فيجب أن يراه **باسمه
///   وتاريخ صرفه ورقم سنده** في خطوة المراجعة — حين يكون استبعاده ما زال
///   ممكناً بضغطة، لا بعد أن يخرج المال.
///
/// 📌 والحماية الحقيقية قائمة تحته: الاستيراد لا يمسّ سطراً مسدَّداً، والتسديد
///   لا يدفع إلا `unpaid`. فهذا **إخبارٌ ليقرّر** لا حاجزٌ وحيد.
///
/// Copied from [payrollPaidEmployeesForMonth].
@ProviderFor(payrollPaidEmployeesForMonth)
const payrollPaidEmployeesForMonthProvider =
    PayrollPaidEmployeesForMonthFamily();

/// موظفو شهرٍ الذين سُدِّدت رواتبهم فعلاً — تنبيه معالج الاستيراد
///
/// 🔑 **سبب وجوده** (طلب المالك 2026-08-26): قد يكون صرف راتب موظف مباشرةً من
///   بطاقته عن شهر ٨، ثم يستورد ملف الشهر نفسه وقد نسي. فيجب أن يراه **باسمه
///   وتاريخ صرفه ورقم سنده** في خطوة المراجعة — حين يكون استبعاده ما زال
///   ممكناً بضغطة، لا بعد أن يخرج المال.
///
/// 📌 والحماية الحقيقية قائمة تحته: الاستيراد لا يمسّ سطراً مسدَّداً، والتسديد
///   لا يدفع إلا `unpaid`. فهذا **إخبارٌ ليقرّر** لا حاجزٌ وحيد.
///
/// Copied from [payrollPaidEmployeesForMonth].
class PayrollPaidEmployeesForMonthFamily
    extends Family<AsyncValue<List<PaidEmployeeInMonth>>> {
  /// موظفو شهرٍ الذين سُدِّدت رواتبهم فعلاً — تنبيه معالج الاستيراد
  ///
  /// 🔑 **سبب وجوده** (طلب المالك 2026-08-26): قد يكون صرف راتب موظف مباشرةً من
  ///   بطاقته عن شهر ٨، ثم يستورد ملف الشهر نفسه وقد نسي. فيجب أن يراه **باسمه
  ///   وتاريخ صرفه ورقم سنده** في خطوة المراجعة — حين يكون استبعاده ما زال
  ///   ممكناً بضغطة، لا بعد أن يخرج المال.
  ///
  /// 📌 والحماية الحقيقية قائمة تحته: الاستيراد لا يمسّ سطراً مسدَّداً، والتسديد
  ///   لا يدفع إلا `unpaid`. فهذا **إخبارٌ ليقرّر** لا حاجزٌ وحيد.
  ///
  /// Copied from [payrollPaidEmployeesForMonth].
  const PayrollPaidEmployeesForMonthFamily();

  /// موظفو شهرٍ الذين سُدِّدت رواتبهم فعلاً — تنبيه معالج الاستيراد
  ///
  /// 🔑 **سبب وجوده** (طلب المالك 2026-08-26): قد يكون صرف راتب موظف مباشرةً من
  ///   بطاقته عن شهر ٨، ثم يستورد ملف الشهر نفسه وقد نسي. فيجب أن يراه **باسمه
  ///   وتاريخ صرفه ورقم سنده** في خطوة المراجعة — حين يكون استبعاده ما زال
  ///   ممكناً بضغطة، لا بعد أن يخرج المال.
  ///
  /// 📌 والحماية الحقيقية قائمة تحته: الاستيراد لا يمسّ سطراً مسدَّداً، والتسديد
  ///   لا يدفع إلا `unpaid`. فهذا **إخبارٌ ليقرّر** لا حاجزٌ وحيد.
  ///
  /// Copied from [payrollPaidEmployeesForMonth].
  PayrollPaidEmployeesForMonthProvider call(
    int year,
    int month,
  ) {
    return PayrollPaidEmployeesForMonthProvider(
      year,
      month,
    );
  }

  @override
  PayrollPaidEmployeesForMonthProvider getProviderOverride(
    covariant PayrollPaidEmployeesForMonthProvider provider,
  ) {
    return call(
      provider.year,
      provider.month,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'payrollPaidEmployeesForMonthProvider';
}

/// موظفو شهرٍ الذين سُدِّدت رواتبهم فعلاً — تنبيه معالج الاستيراد
///
/// 🔑 **سبب وجوده** (طلب المالك 2026-08-26): قد يكون صرف راتب موظف مباشرةً من
///   بطاقته عن شهر ٨، ثم يستورد ملف الشهر نفسه وقد نسي. فيجب أن يراه **باسمه
///   وتاريخ صرفه ورقم سنده** في خطوة المراجعة — حين يكون استبعاده ما زال
///   ممكناً بضغطة، لا بعد أن يخرج المال.
///
/// 📌 والحماية الحقيقية قائمة تحته: الاستيراد لا يمسّ سطراً مسدَّداً، والتسديد
///   لا يدفع إلا `unpaid`. فهذا **إخبارٌ ليقرّر** لا حاجزٌ وحيد.
///
/// Copied from [payrollPaidEmployeesForMonth].
class PayrollPaidEmployeesForMonthProvider
    extends AutoDisposeFutureProvider<List<PaidEmployeeInMonth>> {
  /// موظفو شهرٍ الذين سُدِّدت رواتبهم فعلاً — تنبيه معالج الاستيراد
  ///
  /// 🔑 **سبب وجوده** (طلب المالك 2026-08-26): قد يكون صرف راتب موظف مباشرةً من
  ///   بطاقته عن شهر ٨، ثم يستورد ملف الشهر نفسه وقد نسي. فيجب أن يراه **باسمه
  ///   وتاريخ صرفه ورقم سنده** في خطوة المراجعة — حين يكون استبعاده ما زال
  ///   ممكناً بضغطة، لا بعد أن يخرج المال.
  ///
  /// 📌 والحماية الحقيقية قائمة تحته: الاستيراد لا يمسّ سطراً مسدَّداً، والتسديد
  ///   لا يدفع إلا `unpaid`. فهذا **إخبارٌ ليقرّر** لا حاجزٌ وحيد.
  ///
  /// Copied from [payrollPaidEmployeesForMonth].
  PayrollPaidEmployeesForMonthProvider(
    int year,
    int month,
  ) : this._internal(
          (ref) => payrollPaidEmployeesForMonth(
            ref as PayrollPaidEmployeesForMonthRef,
            year,
            month,
          ),
          from: payrollPaidEmployeesForMonthProvider,
          name: r'payrollPaidEmployeesForMonthProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$payrollPaidEmployeesForMonthHash,
          dependencies: PayrollPaidEmployeesForMonthFamily._dependencies,
          allTransitiveDependencies:
              PayrollPaidEmployeesForMonthFamily._allTransitiveDependencies,
          year: year,
          month: month,
        );

  PayrollPaidEmployeesForMonthProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.year,
    required this.month,
  }) : super.internal();

  final int year;
  final int month;

  @override
  Override overrideWith(
    FutureOr<List<PaidEmployeeInMonth>> Function(
            PayrollPaidEmployeesForMonthRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PayrollPaidEmployeesForMonthProvider._internal(
        (ref) => create(ref as PayrollPaidEmployeesForMonthRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        year: year,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PaidEmployeeInMonth>> createElement() {
    return _PayrollPaidEmployeesForMonthProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PayrollPaidEmployeesForMonthProvider &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PayrollPaidEmployeesForMonthRef
    on AutoDisposeFutureProviderRef<List<PaidEmployeeInMonth>> {
  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `month` of this provider.
  int get month;
}

class _PayrollPaidEmployeesForMonthProviderElement
    extends AutoDisposeFutureProviderElement<List<PaidEmployeeInMonth>>
    with PayrollPaidEmployeesForMonthRef {
  _PayrollPaidEmployeesForMonthProviderElement(super.provider);

  @override
  int get year => (origin as PayrollPaidEmployeesForMonthProvider).year;
  @override
  int get month => (origin as PayrollPaidEmployeesForMonthProvider).month;
}

String _$stalePaidPayrollsHash() => r'2df198aa12e9041dada15b2a2440adcc77a64e7c';

/// كشوف فيها رواتب «مسدَّدة» بسندٍ محذوف — الكاشف المرآة (ع-٤٠)
///
/// Copied from [stalePaidPayrolls].
@ProviderFor(stalePaidPayrolls)
final stalePaidPayrollsProvider =
    AutoDisposeFutureProvider<List<StalePaidPayroll>>.internal(
  stalePaidPayrolls,
  name: r'stalePaidPayrollsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$stalePaidPayrollsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StalePaidPayrollsRef
    = AutoDisposeFutureProviderRef<List<StalePaidPayroll>>;
String _$payrollYearReportHash() => r'dfe23cc2afe6c18b7964d22b86d2ab849282fc93';

/// تقرير رواتب سنة — الأشهر وتوزيع المسدَّد على الخزائن (المرحلة ٤)
///
/// 📌 **يجمع أرقاماً حسبها الـ DAO لا يحسبها بنفسه**، ويقرأ العمود نفسه
///   (`net_amount_iqd`) بالشروط نفسها التي تقرأها [payrollTotals]. يحرس
///   تطابقَ الرقمين اختبارٌ مخصّص — «استعلامان يُفترَض أنهما متطابقان» هو
///   بالضبط ما انفرط في المشروع المرجعي DMS.
///
/// Copied from [payrollYearReport].
@ProviderFor(payrollYearReport)
const payrollYearReportProvider = PayrollYearReportFamily();

/// تقرير رواتب سنة — الأشهر وتوزيع المسدَّد على الخزائن (المرحلة ٤)
///
/// 📌 **يجمع أرقاماً حسبها الـ DAO لا يحسبها بنفسه**، ويقرأ العمود نفسه
///   (`net_amount_iqd`) بالشروط نفسها التي تقرأها [payrollTotals]. يحرس
///   تطابقَ الرقمين اختبارٌ مخصّص — «استعلامان يُفترَض أنهما متطابقان» هو
///   بالضبط ما انفرط في المشروع المرجعي DMS.
///
/// Copied from [payrollYearReport].
class PayrollYearReportFamily
    extends Family<AsyncValue<PayrollYearReportData>> {
  /// تقرير رواتب سنة — الأشهر وتوزيع المسدَّد على الخزائن (المرحلة ٤)
  ///
  /// 📌 **يجمع أرقاماً حسبها الـ DAO لا يحسبها بنفسه**، ويقرأ العمود نفسه
  ///   (`net_amount_iqd`) بالشروط نفسها التي تقرأها [payrollTotals]. يحرس
  ///   تطابقَ الرقمين اختبارٌ مخصّص — «استعلامان يُفترَض أنهما متطابقان» هو
  ///   بالضبط ما انفرط في المشروع المرجعي DMS.
  ///
  /// Copied from [payrollYearReport].
  const PayrollYearReportFamily();

  /// تقرير رواتب سنة — الأشهر وتوزيع المسدَّد على الخزائن (المرحلة ٤)
  ///
  /// 📌 **يجمع أرقاماً حسبها الـ DAO لا يحسبها بنفسه**، ويقرأ العمود نفسه
  ///   (`net_amount_iqd`) بالشروط نفسها التي تقرأها [payrollTotals]. يحرس
  ///   تطابقَ الرقمين اختبارٌ مخصّص — «استعلامان يُفترَض أنهما متطابقان» هو
  ///   بالضبط ما انفرط في المشروع المرجعي DMS.
  ///
  /// Copied from [payrollYearReport].
  PayrollYearReportProvider call(
    int year,
  ) {
    return PayrollYearReportProvider(
      year,
    );
  }

  @override
  PayrollYearReportProvider getProviderOverride(
    covariant PayrollYearReportProvider provider,
  ) {
    return call(
      provider.year,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'payrollYearReportProvider';
}

/// تقرير رواتب سنة — الأشهر وتوزيع المسدَّد على الخزائن (المرحلة ٤)
///
/// 📌 **يجمع أرقاماً حسبها الـ DAO لا يحسبها بنفسه**، ويقرأ العمود نفسه
///   (`net_amount_iqd`) بالشروط نفسها التي تقرأها [payrollTotals]. يحرس
///   تطابقَ الرقمين اختبارٌ مخصّص — «استعلامان يُفترَض أنهما متطابقان» هو
///   بالضبط ما انفرط في المشروع المرجعي DMS.
///
/// Copied from [payrollYearReport].
class PayrollYearReportProvider
    extends AutoDisposeFutureProvider<PayrollYearReportData> {
  /// تقرير رواتب سنة — الأشهر وتوزيع المسدَّد على الخزائن (المرحلة ٤)
  ///
  /// 📌 **يجمع أرقاماً حسبها الـ DAO لا يحسبها بنفسه**، ويقرأ العمود نفسه
  ///   (`net_amount_iqd`) بالشروط نفسها التي تقرأها [payrollTotals]. يحرس
  ///   تطابقَ الرقمين اختبارٌ مخصّص — «استعلامان يُفترَض أنهما متطابقان» هو
  ///   بالضبط ما انفرط في المشروع المرجعي DMS.
  ///
  /// Copied from [payrollYearReport].
  PayrollYearReportProvider(
    int year,
  ) : this._internal(
          (ref) => payrollYearReport(
            ref as PayrollYearReportRef,
            year,
          ),
          from: payrollYearReportProvider,
          name: r'payrollYearReportProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$payrollYearReportHash,
          dependencies: PayrollYearReportFamily._dependencies,
          allTransitiveDependencies:
              PayrollYearReportFamily._allTransitiveDependencies,
          year: year,
        );

  PayrollYearReportProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.year,
  }) : super.internal();

  final int year;

  @override
  Override overrideWith(
    FutureOr<PayrollYearReportData> Function(PayrollYearReportRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PayrollYearReportProvider._internal(
        (ref) => create(ref as PayrollYearReportRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        year: year,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PayrollYearReportData> createElement() {
    return _PayrollYearReportProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PayrollYearReportProvider && other.year == year;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PayrollYearReportRef
    on AutoDisposeFutureProviderRef<PayrollYearReportData> {
  /// The parameter `year` of this provider.
  int get year;
}

class _PayrollYearReportProviderElement
    extends AutoDisposeFutureProviderElement<PayrollYearReportData>
    with PayrollYearReportRef {
  _PayrollYearReportProviderElement(super.provider);

  @override
  int get year => (origin as PayrollYearReportProvider).year;
}

String _$payrollOutOfSheetHash() => r'6b7d601264c48206d8154a60278b5f425bffd9b2';

/// رواتب صُرفت في السنة **خارج أي كشف** — عددها ومجموعها
///
/// 🔑 يعرضها التقرير في شريط منفصل. مسار «صرف راتب» من بطاقة الموظف يكتب
///   سطراً بلا كشف، فتقريرٌ يقتصر على الكشوف يُخفي مالاً خرج فعلاً — وهو
///   الصنف نفسه من العطل الذي ضرب DMS.
///
/// Copied from [payrollOutOfSheet].
@ProviderFor(payrollOutOfSheet)
const payrollOutOfSheetProvider = PayrollOutOfSheetFamily();

/// رواتب صُرفت في السنة **خارج أي كشف** — عددها ومجموعها
///
/// 🔑 يعرضها التقرير في شريط منفصل. مسار «صرف راتب» من بطاقة الموظف يكتب
///   سطراً بلا كشف، فتقريرٌ يقتصر على الكشوف يُخفي مالاً خرج فعلاً — وهو
///   الصنف نفسه من العطل الذي ضرب DMS.
///
/// Copied from [payrollOutOfSheet].
class PayrollOutOfSheetFamily
    extends Family<AsyncValue<({int count, double totalIqd})>> {
  /// رواتب صُرفت في السنة **خارج أي كشف** — عددها ومجموعها
  ///
  /// 🔑 يعرضها التقرير في شريط منفصل. مسار «صرف راتب» من بطاقة الموظف يكتب
  ///   سطراً بلا كشف، فتقريرٌ يقتصر على الكشوف يُخفي مالاً خرج فعلاً — وهو
  ///   الصنف نفسه من العطل الذي ضرب DMS.
  ///
  /// Copied from [payrollOutOfSheet].
  const PayrollOutOfSheetFamily();

  /// رواتب صُرفت في السنة **خارج أي كشف** — عددها ومجموعها
  ///
  /// 🔑 يعرضها التقرير في شريط منفصل. مسار «صرف راتب» من بطاقة الموظف يكتب
  ///   سطراً بلا كشف، فتقريرٌ يقتصر على الكشوف يُخفي مالاً خرج فعلاً — وهو
  ///   الصنف نفسه من العطل الذي ضرب DMS.
  ///
  /// Copied from [payrollOutOfSheet].
  PayrollOutOfSheetProvider call(
    int year,
  ) {
    return PayrollOutOfSheetProvider(
      year,
    );
  }

  @override
  PayrollOutOfSheetProvider getProviderOverride(
    covariant PayrollOutOfSheetProvider provider,
  ) {
    return call(
      provider.year,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'payrollOutOfSheetProvider';
}

/// رواتب صُرفت في السنة **خارج أي كشف** — عددها ومجموعها
///
/// 🔑 يعرضها التقرير في شريط منفصل. مسار «صرف راتب» من بطاقة الموظف يكتب
///   سطراً بلا كشف، فتقريرٌ يقتصر على الكشوف يُخفي مالاً خرج فعلاً — وهو
///   الصنف نفسه من العطل الذي ضرب DMS.
///
/// Copied from [payrollOutOfSheet].
class PayrollOutOfSheetProvider
    extends AutoDisposeFutureProvider<({int count, double totalIqd})> {
  /// رواتب صُرفت في السنة **خارج أي كشف** — عددها ومجموعها
  ///
  /// 🔑 يعرضها التقرير في شريط منفصل. مسار «صرف راتب» من بطاقة الموظف يكتب
  ///   سطراً بلا كشف، فتقريرٌ يقتصر على الكشوف يُخفي مالاً خرج فعلاً — وهو
  ///   الصنف نفسه من العطل الذي ضرب DMS.
  ///
  /// Copied from [payrollOutOfSheet].
  PayrollOutOfSheetProvider(
    int year,
  ) : this._internal(
          (ref) => payrollOutOfSheet(
            ref as PayrollOutOfSheetRef,
            year,
          ),
          from: payrollOutOfSheetProvider,
          name: r'payrollOutOfSheetProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$payrollOutOfSheetHash,
          dependencies: PayrollOutOfSheetFamily._dependencies,
          allTransitiveDependencies:
              PayrollOutOfSheetFamily._allTransitiveDependencies,
          year: year,
        );

  PayrollOutOfSheetProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.year,
  }) : super.internal();

  final int year;

  @override
  Override overrideWith(
    FutureOr<({int count, double totalIqd})> Function(
            PayrollOutOfSheetRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PayrollOutOfSheetProvider._internal(
        (ref) => create(ref as PayrollOutOfSheetRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        year: year,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<({int count, double totalIqd})>
      createElement() {
    return _PayrollOutOfSheetProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PayrollOutOfSheetProvider && other.year == year;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PayrollOutOfSheetRef
    on AutoDisposeFutureProviderRef<({int count, double totalIqd})> {
  /// The parameter `year` of this provider.
  int get year;
}

class _PayrollOutOfSheetProviderElement
    extends AutoDisposeFutureProviderElement<({int count, double totalIqd})>
    with PayrollOutOfSheetRef {
  _PayrollOutOfSheetProviderElement(super.provider);

  @override
  int get year => (origin as PayrollOutOfSheetProvider).year;
}

String _$payrollMatchCandidatesHash() =>
    r'049ddef1b722c592efe2d6767b74b8b8e1a19f5b';

/// موظفو القاعدة بصيغة مرشّحي المطابقة — لمعالج الاستيراد
///
/// Copied from [payrollMatchCandidates].
@ProviderFor(payrollMatchCandidates)
final payrollMatchCandidatesProvider =
    AutoDisposeFutureProvider<List<PayrollMatchCandidate>>.internal(
  payrollMatchCandidates,
  name: r'payrollMatchCandidatesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$payrollMatchCandidatesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PayrollMatchCandidatesRef
    = AutoDisposeFutureProviderRef<List<PayrollMatchCandidate>>;
String _$pendingAdvancesForEmployeesHash() =>
    r'6779d82ce4c55624ad782a5929739a250a3971a7';

/// المتبقّي من سلف مجموعة موظفين — **استعلام واحد** (طلب المالك 2026-08-27)
///
/// 🔑 يُستعمل في معالج الاستيراد وفي كشف الشهر: «هذا الموظف عليه سلفة
///   متبقّية ٥٠٠٬٠٠٠». وبدونه كان المالك يستورد الكشف ويسدّده وقد نسي
///   الخصم — فتبقى السلفة كاملةً على الموظف بلا سبب.
///
/// 📌 والخريطة **لا تحوي مفتاحاً لمن لا سلفة عليه** — فالغياب نفسه جواب.
///
/// Copied from [pendingAdvancesForEmployees].
@ProviderFor(pendingAdvancesForEmployees)
const pendingAdvancesForEmployeesProvider = PendingAdvancesForEmployeesFamily();

/// المتبقّي من سلف مجموعة موظفين — **استعلام واحد** (طلب المالك 2026-08-27)
///
/// 🔑 يُستعمل في معالج الاستيراد وفي كشف الشهر: «هذا الموظف عليه سلفة
///   متبقّية ٥٠٠٬٠٠٠». وبدونه كان المالك يستورد الكشف ويسدّده وقد نسي
///   الخصم — فتبقى السلفة كاملةً على الموظف بلا سبب.
///
/// 📌 والخريطة **لا تحوي مفتاحاً لمن لا سلفة عليه** — فالغياب نفسه جواب.
///
/// Copied from [pendingAdvancesForEmployees].
class PendingAdvancesForEmployeesFamily
    extends Family<AsyncValue<Map<int, double>>> {
  /// المتبقّي من سلف مجموعة موظفين — **استعلام واحد** (طلب المالك 2026-08-27)
  ///
  /// 🔑 يُستعمل في معالج الاستيراد وفي كشف الشهر: «هذا الموظف عليه سلفة
  ///   متبقّية ٥٠٠٬٠٠٠». وبدونه كان المالك يستورد الكشف ويسدّده وقد نسي
  ///   الخصم — فتبقى السلفة كاملةً على الموظف بلا سبب.
  ///
  /// 📌 والخريطة **لا تحوي مفتاحاً لمن لا سلفة عليه** — فالغياب نفسه جواب.
  ///
  /// Copied from [pendingAdvancesForEmployees].
  const PendingAdvancesForEmployeesFamily();

  /// المتبقّي من سلف مجموعة موظفين — **استعلام واحد** (طلب المالك 2026-08-27)
  ///
  /// 🔑 يُستعمل في معالج الاستيراد وفي كشف الشهر: «هذا الموظف عليه سلفة
  ///   متبقّية ٥٠٠٬٠٠٠». وبدونه كان المالك يستورد الكشف ويسدّده وقد نسي
  ///   الخصم — فتبقى السلفة كاملةً على الموظف بلا سبب.
  ///
  /// 📌 والخريطة **لا تحوي مفتاحاً لمن لا سلفة عليه** — فالغياب نفسه جواب.
  ///
  /// Copied from [pendingAdvancesForEmployees].
  PendingAdvancesForEmployeesProvider call(
    List<int> employeeIds,
  ) {
    return PendingAdvancesForEmployeesProvider(
      employeeIds,
    );
  }

  @override
  PendingAdvancesForEmployeesProvider getProviderOverride(
    covariant PendingAdvancesForEmployeesProvider provider,
  ) {
    return call(
      provider.employeeIds,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'pendingAdvancesForEmployeesProvider';
}

/// المتبقّي من سلف مجموعة موظفين — **استعلام واحد** (طلب المالك 2026-08-27)
///
/// 🔑 يُستعمل في معالج الاستيراد وفي كشف الشهر: «هذا الموظف عليه سلفة
///   متبقّية ٥٠٠٬٠٠٠». وبدونه كان المالك يستورد الكشف ويسدّده وقد نسي
///   الخصم — فتبقى السلفة كاملةً على الموظف بلا سبب.
///
/// 📌 والخريطة **لا تحوي مفتاحاً لمن لا سلفة عليه** — فالغياب نفسه جواب.
///
/// Copied from [pendingAdvancesForEmployees].
class PendingAdvancesForEmployeesProvider
    extends AutoDisposeFutureProvider<Map<int, double>> {
  /// المتبقّي من سلف مجموعة موظفين — **استعلام واحد** (طلب المالك 2026-08-27)
  ///
  /// 🔑 يُستعمل في معالج الاستيراد وفي كشف الشهر: «هذا الموظف عليه سلفة
  ///   متبقّية ٥٠٠٬٠٠٠». وبدونه كان المالك يستورد الكشف ويسدّده وقد نسي
  ///   الخصم — فتبقى السلفة كاملةً على الموظف بلا سبب.
  ///
  /// 📌 والخريطة **لا تحوي مفتاحاً لمن لا سلفة عليه** — فالغياب نفسه جواب.
  ///
  /// Copied from [pendingAdvancesForEmployees].
  PendingAdvancesForEmployeesProvider(
    List<int> employeeIds,
  ) : this._internal(
          (ref) => pendingAdvancesForEmployees(
            ref as PendingAdvancesForEmployeesRef,
            employeeIds,
          ),
          from: pendingAdvancesForEmployeesProvider,
          name: r'pendingAdvancesForEmployeesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pendingAdvancesForEmployeesHash,
          dependencies: PendingAdvancesForEmployeesFamily._dependencies,
          allTransitiveDependencies:
              PendingAdvancesForEmployeesFamily._allTransitiveDependencies,
          employeeIds: employeeIds,
        );

  PendingAdvancesForEmployeesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.employeeIds,
  }) : super.internal();

  final List<int> employeeIds;

  @override
  Override overrideWith(
    FutureOr<Map<int, double>> Function(PendingAdvancesForEmployeesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingAdvancesForEmployeesProvider._internal(
        (ref) => create(ref as PendingAdvancesForEmployeesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        employeeIds: employeeIds,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<int, double>> createElement() {
    return _PendingAdvancesForEmployeesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingAdvancesForEmployeesProvider &&
        other.employeeIds == employeeIds;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, employeeIds.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PendingAdvancesForEmployeesRef
    on AutoDisposeFutureProviderRef<Map<int, double>> {
  /// The parameter `employeeIds` of this provider.
  List<int> get employeeIds;
}

class _PendingAdvancesForEmployeesProviderElement
    extends AutoDisposeFutureProviderElement<Map<int, double>>
    with PendingAdvancesForEmployeesRef {
  _PendingAdvancesForEmployeesProviderElement(super.provider);

  @override
  List<int> get employeeIds =>
      (origin as PendingAdvancesForEmployeesProvider).employeeIds;
}

String _$employeePendingAdvancesHash() =>
    r'beee4812aaa3b0e07e149b219e3c5ee89211306c';

/// سلف الموظف غير المسدَّدة — لاقتراح الخصم في شاشة الكشف
///
/// Copied from [employeePendingAdvances].
@ProviderFor(employeePendingAdvances)
const employeePendingAdvancesProvider = EmployeePendingAdvancesFamily();

/// سلف الموظف غير المسدَّدة — لاقتراح الخصم في شاشة الكشف
///
/// Copied from [employeePendingAdvances].
class EmployeePendingAdvancesFamily
    extends Family<AsyncValue<List<CashAdvance>>> {
  /// سلف الموظف غير المسدَّدة — لاقتراح الخصم في شاشة الكشف
  ///
  /// Copied from [employeePendingAdvances].
  const EmployeePendingAdvancesFamily();

  /// سلف الموظف غير المسدَّدة — لاقتراح الخصم في شاشة الكشف
  ///
  /// Copied from [employeePendingAdvances].
  EmployeePendingAdvancesProvider call(
    int employeeId,
  ) {
    return EmployeePendingAdvancesProvider(
      employeeId,
    );
  }

  @override
  EmployeePendingAdvancesProvider getProviderOverride(
    covariant EmployeePendingAdvancesProvider provider,
  ) {
    return call(
      provider.employeeId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'employeePendingAdvancesProvider';
}

/// سلف الموظف غير المسدَّدة — لاقتراح الخصم في شاشة الكشف
///
/// Copied from [employeePendingAdvances].
class EmployeePendingAdvancesProvider
    extends AutoDisposeFutureProvider<List<CashAdvance>> {
  /// سلف الموظف غير المسدَّدة — لاقتراح الخصم في شاشة الكشف
  ///
  /// Copied from [employeePendingAdvances].
  EmployeePendingAdvancesProvider(
    int employeeId,
  ) : this._internal(
          (ref) => employeePendingAdvances(
            ref as EmployeePendingAdvancesRef,
            employeeId,
          ),
          from: employeePendingAdvancesProvider,
          name: r'employeePendingAdvancesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$employeePendingAdvancesHash,
          dependencies: EmployeePendingAdvancesFamily._dependencies,
          allTransitiveDependencies:
              EmployeePendingAdvancesFamily._allTransitiveDependencies,
          employeeId: employeeId,
        );

  EmployeePendingAdvancesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.employeeId,
  }) : super.internal();

  final int employeeId;

  @override
  Override overrideWith(
    FutureOr<List<CashAdvance>> Function(EmployeePendingAdvancesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EmployeePendingAdvancesProvider._internal(
        (ref) => create(ref as EmployeePendingAdvancesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        employeeId: employeeId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<CashAdvance>> createElement() {
    return _EmployeePendingAdvancesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EmployeePendingAdvancesProvider &&
        other.employeeId == employeeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, employeeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EmployeePendingAdvancesRef
    on AutoDisposeFutureProviderRef<List<CashAdvance>> {
  /// The parameter `employeeId` of this provider.
  int get employeeId;
}

class _EmployeePendingAdvancesProviderElement
    extends AutoDisposeFutureProviderElement<List<CashAdvance>>
    with EmployeePendingAdvancesRef {
  _EmployeePendingAdvancesProviderElement(super.provider);

  @override
  int get employeeId => (origin as EmployeePendingAdvancesProvider).employeeId;
}

String _$payrollMonthFiscalCheckHash() =>
    r'a84e5404a9451564f716f954c3674e6f800c4bb9';

/// فحص السنة المالية لشهر **قبل** أن يبذل المالك عمل تعيين الأعمدة
///
/// 🔑 **سبب وجوده:** الحارس في `PayrollRepository` يرفض بحقّ، لكنه يرفض في
///   **آخر خطوة** — بعد اختيار الملف وتعيين أحد عشر عموداً ومراجعة سبعة
///   وأربعين سطراً. عرضُ المانع في **الخطوة الثانية** يوفّر ذلك كلّه.
///   (بلاغ المالك 2026-08-25: ضغط «بناء الكشف» فلم يحدث شيء — كانت سنته
///   المالية 2026 والكشف لأيار 2025.)
///
/// Copied from [payrollMonthFiscalCheck].
@ProviderFor(payrollMonthFiscalCheck)
const payrollMonthFiscalCheckProvider = PayrollMonthFiscalCheckFamily();

/// فحص السنة المالية لشهر **قبل** أن يبذل المالك عمل تعيين الأعمدة
///
/// 🔑 **سبب وجوده:** الحارس في `PayrollRepository` يرفض بحقّ، لكنه يرفض في
///   **آخر خطوة** — بعد اختيار الملف وتعيين أحد عشر عموداً ومراجعة سبعة
///   وأربعين سطراً. عرضُ المانع في **الخطوة الثانية** يوفّر ذلك كلّه.
///   (بلاغ المالك 2026-08-25: ضغط «بناء الكشف» فلم يحدث شيء — كانت سنته
///   المالية 2026 والكشف لأيار 2025.)
///
/// Copied from [payrollMonthFiscalCheck].
class PayrollMonthFiscalCheckFamily
    extends Family<AsyncValue<PayrollMonthFiscalCheck>> {
  /// فحص السنة المالية لشهر **قبل** أن يبذل المالك عمل تعيين الأعمدة
  ///
  /// 🔑 **سبب وجوده:** الحارس في `PayrollRepository` يرفض بحقّ، لكنه يرفض في
  ///   **آخر خطوة** — بعد اختيار الملف وتعيين أحد عشر عموداً ومراجعة سبعة
  ///   وأربعين سطراً. عرضُ المانع في **الخطوة الثانية** يوفّر ذلك كلّه.
  ///   (بلاغ المالك 2026-08-25: ضغط «بناء الكشف» فلم يحدث شيء — كانت سنته
  ///   المالية 2026 والكشف لأيار 2025.)
  ///
  /// Copied from [payrollMonthFiscalCheck].
  const PayrollMonthFiscalCheckFamily();

  /// فحص السنة المالية لشهر **قبل** أن يبذل المالك عمل تعيين الأعمدة
  ///
  /// 🔑 **سبب وجوده:** الحارس في `PayrollRepository` يرفض بحقّ، لكنه يرفض في
  ///   **آخر خطوة** — بعد اختيار الملف وتعيين أحد عشر عموداً ومراجعة سبعة
  ///   وأربعين سطراً. عرضُ المانع في **الخطوة الثانية** يوفّر ذلك كلّه.
  ///   (بلاغ المالك 2026-08-25: ضغط «بناء الكشف» فلم يحدث شيء — كانت سنته
  ///   المالية 2026 والكشف لأيار 2025.)
  ///
  /// Copied from [payrollMonthFiscalCheck].
  PayrollMonthFiscalCheckProvider call(
    int year,
    int month,
  ) {
    return PayrollMonthFiscalCheckProvider(
      year,
      month,
    );
  }

  @override
  PayrollMonthFiscalCheckProvider getProviderOverride(
    covariant PayrollMonthFiscalCheckProvider provider,
  ) {
    return call(
      provider.year,
      provider.month,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'payrollMonthFiscalCheckProvider';
}

/// فحص السنة المالية لشهر **قبل** أن يبذل المالك عمل تعيين الأعمدة
///
/// 🔑 **سبب وجوده:** الحارس في `PayrollRepository` يرفض بحقّ، لكنه يرفض في
///   **آخر خطوة** — بعد اختيار الملف وتعيين أحد عشر عموداً ومراجعة سبعة
///   وأربعين سطراً. عرضُ المانع في **الخطوة الثانية** يوفّر ذلك كلّه.
///   (بلاغ المالك 2026-08-25: ضغط «بناء الكشف» فلم يحدث شيء — كانت سنته
///   المالية 2026 والكشف لأيار 2025.)
///
/// Copied from [payrollMonthFiscalCheck].
class PayrollMonthFiscalCheckProvider
    extends AutoDisposeFutureProvider<PayrollMonthFiscalCheck> {
  /// فحص السنة المالية لشهر **قبل** أن يبذل المالك عمل تعيين الأعمدة
  ///
  /// 🔑 **سبب وجوده:** الحارس في `PayrollRepository` يرفض بحقّ، لكنه يرفض في
  ///   **آخر خطوة** — بعد اختيار الملف وتعيين أحد عشر عموداً ومراجعة سبعة
  ///   وأربعين سطراً. عرضُ المانع في **الخطوة الثانية** يوفّر ذلك كلّه.
  ///   (بلاغ المالك 2026-08-25: ضغط «بناء الكشف» فلم يحدث شيء — كانت سنته
  ///   المالية 2026 والكشف لأيار 2025.)
  ///
  /// Copied from [payrollMonthFiscalCheck].
  PayrollMonthFiscalCheckProvider(
    int year,
    int month,
  ) : this._internal(
          (ref) => payrollMonthFiscalCheck(
            ref as PayrollMonthFiscalCheckRef,
            year,
            month,
          ),
          from: payrollMonthFiscalCheckProvider,
          name: r'payrollMonthFiscalCheckProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$payrollMonthFiscalCheckHash,
          dependencies: PayrollMonthFiscalCheckFamily._dependencies,
          allTransitiveDependencies:
              PayrollMonthFiscalCheckFamily._allTransitiveDependencies,
          year: year,
          month: month,
        );

  PayrollMonthFiscalCheckProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.year,
    required this.month,
  }) : super.internal();

  final int year;
  final int month;

  @override
  Override overrideWith(
    FutureOr<PayrollMonthFiscalCheck> Function(
            PayrollMonthFiscalCheckRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PayrollMonthFiscalCheckProvider._internal(
        (ref) => create(ref as PayrollMonthFiscalCheckRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        year: year,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PayrollMonthFiscalCheck> createElement() {
    return _PayrollMonthFiscalCheckProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PayrollMonthFiscalCheckProvider &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PayrollMonthFiscalCheckRef
    on AutoDisposeFutureProviderRef<PayrollMonthFiscalCheck> {
  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `month` of this provider.
  int get month;
}

class _PayrollMonthFiscalCheckProviderElement
    extends AutoDisposeFutureProviderElement<PayrollMonthFiscalCheck>
    with PayrollMonthFiscalCheckRef {
  _PayrollMonthFiscalCheckProviderElement(super.provider);

  @override
  int get year => (origin as PayrollMonthFiscalCheckProvider).year;
  @override
  int get month => (origin as PayrollMonthFiscalCheckProvider).month;
}

String _$employeePayrollReportHash() =>
    r'9e6e0086b85ace638e2a6796346adf35ec9c2c7d';

/// تقرير رواتب موظف أو مجموعة خلال مدى أشهر (طلب المالك 2026-08-26)
///
/// Copied from [employeePayrollReport].
@ProviderFor(employeePayrollReport)
const employeePayrollReportProvider = EmployeePayrollReportFamily();

/// تقرير رواتب موظف أو مجموعة خلال مدى أشهر (طلب المالك 2026-08-26)
///
/// Copied from [employeePayrollReport].
class EmployeePayrollReportFamily
    extends Family<AsyncValue<EmployeePayrollReportData>> {
  /// تقرير رواتب موظف أو مجموعة خلال مدى أشهر (طلب المالك 2026-08-26)
  ///
  /// Copied from [employeePayrollReport].
  const EmployeePayrollReportFamily();

  /// تقرير رواتب موظف أو مجموعة خلال مدى أشهر (طلب المالك 2026-08-26)
  ///
  /// Copied from [employeePayrollReport].
  EmployeePayrollReportProvider call(
    EmployeeReportQuery query,
  ) {
    return EmployeePayrollReportProvider(
      query,
    );
  }

  @override
  EmployeePayrollReportProvider getProviderOverride(
    covariant EmployeePayrollReportProvider provider,
  ) {
    return call(
      provider.query,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'employeePayrollReportProvider';
}

/// تقرير رواتب موظف أو مجموعة خلال مدى أشهر (طلب المالك 2026-08-26)
///
/// Copied from [employeePayrollReport].
class EmployeePayrollReportProvider
    extends AutoDisposeFutureProvider<EmployeePayrollReportData> {
  /// تقرير رواتب موظف أو مجموعة خلال مدى أشهر (طلب المالك 2026-08-26)
  ///
  /// Copied from [employeePayrollReport].
  EmployeePayrollReportProvider(
    EmployeeReportQuery query,
  ) : this._internal(
          (ref) => employeePayrollReport(
            ref as EmployeePayrollReportRef,
            query,
          ),
          from: employeePayrollReportProvider,
          name: r'employeePayrollReportProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$employeePayrollReportHash,
          dependencies: EmployeePayrollReportFamily._dependencies,
          allTransitiveDependencies:
              EmployeePayrollReportFamily._allTransitiveDependencies,
          query: query,
        );

  EmployeePayrollReportProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final EmployeeReportQuery query;

  @override
  Override overrideWith(
    FutureOr<EmployeePayrollReportData> Function(
            EmployeePayrollReportRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EmployeePayrollReportProvider._internal(
        (ref) => create(ref as EmployeePayrollReportRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<EmployeePayrollReportData> createElement() {
    return _EmployeePayrollReportProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EmployeePayrollReportProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EmployeePayrollReportRef
    on AutoDisposeFutureProviderRef<EmployeePayrollReportData> {
  /// The parameter `query` of this provider.
  EmployeeReportQuery get query;
}

class _EmployeePayrollReportProviderElement
    extends AutoDisposeFutureProviderElement<EmployeePayrollReportData>
    with EmployeePayrollReportRef {
  _EmployeePayrollReportProviderElement(super.provider);

  @override
  EmployeeReportQuery get query =>
      (origin as EmployeePayrollReportProvider).query;
}

String _$payrollReportEmployeesHash() =>
    r'd9f6240139d34be940b4402b8a16224cf8de13a7';

/// كل الموظفين لقائمة اختيار التقرير — الاسم والصفة وخزينته
///
/// Copied from [payrollReportEmployees].
@ProviderFor(payrollReportEmployees)
final payrollReportEmployeesProvider =
    AutoDisposeFutureProvider<List<Employee>>.internal(
  payrollReportEmployees,
  name: r'payrollReportEmployeesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$payrollReportEmployeesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PayrollReportEmployeesRef
    = AutoDisposeFutureProviderRef<List<Employee>>;
String _$orphanPayrollVouchersHash() =>
    r'2bd35951d500cb9893c7d13de0d45679e49f6ab9';

/// سندات رواتب لا يقابلها سطرٌ حيّ — **مالٌ خرج بلا سجل** (ع-٣٣)
///
/// 🔑 شبكة أمان تكشف **العَرَض** لا السبب: هذه الحالة وُلدت من بابٍ لم
///   نتوقّعه (حذف الكشف)، وأيّ باب آخر لم يُشخَّص بعدُ سيُنتجها ثانيةً.
///
/// Copied from [orphanPayrollVouchers].
@ProviderFor(orphanPayrollVouchers)
final orphanPayrollVouchersProvider =
    AutoDisposeFutureProvider<List<OrphanPayrollVoucher>>.internal(
  orphanPayrollVouchers,
  name: r'orphanPayrollVouchersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$orphanPayrollVouchersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OrphanPayrollVouchersRef
    = AutoDisposeFutureProviderRef<List<OrphanPayrollVoucher>>;
String _$payrollNotifierHash() => r'1097b34a871591c7c5ccf797c4854523962a26e0';

/// Notifier عمليات كشوف الرواتب
///
/// الحالة رسالة نجاح عربية أو خطأ — تُعرَض في شريط سفلي وتُصفَّر بعده.
///
/// Copied from [PayrollNotifier].
@ProviderFor(PayrollNotifier)
final payrollNotifierProvider =
    AutoDisposeNotifierProvider<PayrollNotifier, AsyncValue<String?>>.internal(
  PayrollNotifier.new,
  name: r'payrollNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$payrollNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PayrollNotifier = AutoDisposeNotifier<AsyncValue<String?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
