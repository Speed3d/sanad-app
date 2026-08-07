// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allEmployeesHash() => r'79ccc7b97999e69c12e4f72c51a92cf2276d0aca';

/// Stream تفاعلي لجميع الموظفين (غير المحذوفين) مرتب أبجدياً
///
/// Copied from [allEmployees].
@ProviderFor(allEmployees)
final allEmployeesProvider =
    AutoDisposeStreamProvider<List<EmployeeModel>>.internal(
  allEmployees,
  name: r'allEmployeesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allEmployeesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllEmployeesRef = AutoDisposeStreamProviderRef<List<EmployeeModel>>;
String _$advancesByEmployeeHash() =>
    r'18201a85a5c32e62a78d0fbe0a48f4f70cd60dd6';

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

/// Stream تفاعلي للسلف الممنوحة لموظف محدد
///
/// Copied from [advancesByEmployee].
@ProviderFor(advancesByEmployee)
const advancesByEmployeeProvider = AdvancesByEmployeeFamily();

/// Stream تفاعلي للسلف الممنوحة لموظف محدد
///
/// Copied from [advancesByEmployee].
class AdvancesByEmployeeFamily
    extends Family<AsyncValue<List<CashAdvanceModel>>> {
  /// Stream تفاعلي للسلف الممنوحة لموظف محدد
  ///
  /// Copied from [advancesByEmployee].
  const AdvancesByEmployeeFamily();

  /// Stream تفاعلي للسلف الممنوحة لموظف محدد
  ///
  /// Copied from [advancesByEmployee].
  AdvancesByEmployeeProvider call(
    int employeeId,
  ) {
    return AdvancesByEmployeeProvider(
      employeeId,
    );
  }

  @override
  AdvancesByEmployeeProvider getProviderOverride(
    covariant AdvancesByEmployeeProvider provider,
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
  String? get name => r'advancesByEmployeeProvider';
}

/// Stream تفاعلي للسلف الممنوحة لموظف محدد
///
/// Copied from [advancesByEmployee].
class AdvancesByEmployeeProvider
    extends AutoDisposeStreamProvider<List<CashAdvanceModel>> {
  /// Stream تفاعلي للسلف الممنوحة لموظف محدد
  ///
  /// Copied from [advancesByEmployee].
  AdvancesByEmployeeProvider(
    int employeeId,
  ) : this._internal(
          (ref) => advancesByEmployee(
            ref as AdvancesByEmployeeRef,
            employeeId,
          ),
          from: advancesByEmployeeProvider,
          name: r'advancesByEmployeeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$advancesByEmployeeHash,
          dependencies: AdvancesByEmployeeFamily._dependencies,
          allTransitiveDependencies:
              AdvancesByEmployeeFamily._allTransitiveDependencies,
          employeeId: employeeId,
        );

  AdvancesByEmployeeProvider._internal(
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
    Stream<List<CashAdvanceModel>> Function(AdvancesByEmployeeRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AdvancesByEmployeeProvider._internal(
        (ref) => create(ref as AdvancesByEmployeeRef),
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
  AutoDisposeStreamProviderElement<List<CashAdvanceModel>> createElement() {
    return _AdvancesByEmployeeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdvancesByEmployeeProvider &&
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
mixin AdvancesByEmployeeRef
    on AutoDisposeStreamProviderRef<List<CashAdvanceModel>> {
  /// The parameter `employeeId` of this provider.
  int get employeeId;
}

class _AdvancesByEmployeeProviderElement
    extends AutoDisposeStreamProviderElement<List<CashAdvanceModel>>
    with AdvancesByEmployeeRef {
  _AdvancesByEmployeeProviderElement(super.provider);

  @override
  int get employeeId => (origin as AdvancesByEmployeeProvider).employeeId;
}

String _$salariesByEmployeeHash() =>
    r'602c27eac056f26a8c2a54dd2c29346d27611207';

/// Stream تفاعلي لرواتب موظف محدد
///
/// Copied from [salariesByEmployee].
@ProviderFor(salariesByEmployee)
const salariesByEmployeeProvider = SalariesByEmployeeFamily();

/// Stream تفاعلي لرواتب موظف محدد
///
/// Copied from [salariesByEmployee].
class SalariesByEmployeeFamily
    extends Family<AsyncValue<List<SalaryPaymentModel>>> {
  /// Stream تفاعلي لرواتب موظف محدد
  ///
  /// Copied from [salariesByEmployee].
  const SalariesByEmployeeFamily();

  /// Stream تفاعلي لرواتب موظف محدد
  ///
  /// Copied from [salariesByEmployee].
  SalariesByEmployeeProvider call(
    int employeeId,
  ) {
    return SalariesByEmployeeProvider(
      employeeId,
    );
  }

  @override
  SalariesByEmployeeProvider getProviderOverride(
    covariant SalariesByEmployeeProvider provider,
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
  String? get name => r'salariesByEmployeeProvider';
}

/// Stream تفاعلي لرواتب موظف محدد
///
/// Copied from [salariesByEmployee].
class SalariesByEmployeeProvider
    extends AutoDisposeStreamProvider<List<SalaryPaymentModel>> {
  /// Stream تفاعلي لرواتب موظف محدد
  ///
  /// Copied from [salariesByEmployee].
  SalariesByEmployeeProvider(
    int employeeId,
  ) : this._internal(
          (ref) => salariesByEmployee(
            ref as SalariesByEmployeeRef,
            employeeId,
          ),
          from: salariesByEmployeeProvider,
          name: r'salariesByEmployeeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$salariesByEmployeeHash,
          dependencies: SalariesByEmployeeFamily._dependencies,
          allTransitiveDependencies:
              SalariesByEmployeeFamily._allTransitiveDependencies,
          employeeId: employeeId,
        );

  SalariesByEmployeeProvider._internal(
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
    Stream<List<SalaryPaymentModel>> Function(SalariesByEmployeeRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SalariesByEmployeeProvider._internal(
        (ref) => create(ref as SalariesByEmployeeRef),
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
  AutoDisposeStreamProviderElement<List<SalaryPaymentModel>> createElement() {
    return _SalariesByEmployeeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SalariesByEmployeeProvider &&
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
mixin SalariesByEmployeeRef
    on AutoDisposeStreamProviderRef<List<SalaryPaymentModel>> {
  /// The parameter `employeeId` of this provider.
  int get employeeId;
}

class _SalariesByEmployeeProviderElement
    extends AutoDisposeStreamProviderElement<List<SalaryPaymentModel>>
    with SalariesByEmployeeRef {
  _SalariesByEmployeeProviderElement(super.provider);

  @override
  int get employeeId => (origin as SalariesByEmployeeProvider).employeeId;
}

String _$pendingAdvancesAmountHash() =>
    r'7e4934db34fa0ebe377c2dfd49eb78117ca4c303';

/// إجمالي السلف غير المسدَّدة لموظف (للعرض في البطاقة)
///
/// Copied from [pendingAdvancesAmount].
@ProviderFor(pendingAdvancesAmount)
const pendingAdvancesAmountProvider = PendingAdvancesAmountFamily();

/// إجمالي السلف غير المسدَّدة لموظف (للعرض في البطاقة)
///
/// Copied from [pendingAdvancesAmount].
class PendingAdvancesAmountFamily extends Family<AsyncValue<double>> {
  /// إجمالي السلف غير المسدَّدة لموظف (للعرض في البطاقة)
  ///
  /// Copied from [pendingAdvancesAmount].
  const PendingAdvancesAmountFamily();

  /// إجمالي السلف غير المسدَّدة لموظف (للعرض في البطاقة)
  ///
  /// Copied from [pendingAdvancesAmount].
  PendingAdvancesAmountProvider call(
    int employeeId,
  ) {
    return PendingAdvancesAmountProvider(
      employeeId,
    );
  }

  @override
  PendingAdvancesAmountProvider getProviderOverride(
    covariant PendingAdvancesAmountProvider provider,
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
  String? get name => r'pendingAdvancesAmountProvider';
}

/// إجمالي السلف غير المسدَّدة لموظف (للعرض في البطاقة)
///
/// Copied from [pendingAdvancesAmount].
class PendingAdvancesAmountProvider extends AutoDisposeFutureProvider<double> {
  /// إجمالي السلف غير المسدَّدة لموظف (للعرض في البطاقة)
  ///
  /// Copied from [pendingAdvancesAmount].
  PendingAdvancesAmountProvider(
    int employeeId,
  ) : this._internal(
          (ref) => pendingAdvancesAmount(
            ref as PendingAdvancesAmountRef,
            employeeId,
          ),
          from: pendingAdvancesAmountProvider,
          name: r'pendingAdvancesAmountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pendingAdvancesAmountHash,
          dependencies: PendingAdvancesAmountFamily._dependencies,
          allTransitiveDependencies:
              PendingAdvancesAmountFamily._allTransitiveDependencies,
          employeeId: employeeId,
        );

  PendingAdvancesAmountProvider._internal(
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
    FutureOr<double> Function(PendingAdvancesAmountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingAdvancesAmountProvider._internal(
        (ref) => create(ref as PendingAdvancesAmountRef),
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
  AutoDisposeFutureProviderElement<double> createElement() {
    return _PendingAdvancesAmountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingAdvancesAmountProvider &&
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
mixin PendingAdvancesAmountRef on AutoDisposeFutureProviderRef<double> {
  /// The parameter `employeeId` of this provider.
  int get employeeId;
}

class _PendingAdvancesAmountProviderElement
    extends AutoDisposeFutureProviderElement<double>
    with PendingAdvancesAmountRef {
  _PendingAdvancesAmountProviderElement(super.provider);

  @override
  int get employeeId => (origin as PendingAdvancesAmountProvider).employeeId;
}

String _$employeeNotifierHash() => r'5a202d1b39e09e89045aef5d520d1a7781edabb4';

/// Notifier لإدارة عمليات الموظفين (إضافة / تعديل / حذف / تفعيل)
///
/// Copied from [EmployeeNotifier].
@ProviderFor(EmployeeNotifier)
final employeeNotifierProvider =
    AutoDisposeNotifierProvider<EmployeeNotifier, AsyncValue<String?>>.internal(
  EmployeeNotifier.new,
  name: r'employeeNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$employeeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$EmployeeNotifier = AutoDisposeNotifier<AsyncValue<String?>>;
String _$salaryNotifierHash() => r'e526545c095c59717523edb1c3e9e7f04467a233';

/// Notifier لصرف الرواتب
///
/// عند صرف الراتب:
///   1. يُنشئ سند صرف تلقائياً من الخزينة المحددة
///   2. يُسجَّل في جدول SalaryPayments مع ربطه بالسند
///
/// Copied from [SalaryNotifier].
@ProviderFor(SalaryNotifier)
final salaryNotifierProvider =
    AutoDisposeNotifierProvider<SalaryNotifier, AsyncValue<String?>>.internal(
  SalaryNotifier.new,
  name: r'salaryNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$salaryNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SalaryNotifier = AutoDisposeNotifier<AsyncValue<String?>>;
String _$advanceNotifierHash() => r'c4dd6001d7c9ee2cad9377a8db7e53cf1b2465da';

/// Notifier لإدارة السلف وأقساط السداد
///
/// منح سلفة:
///   يُنشئ سند صرف تلقائياً + يُسجَّل في CashAdvances
///
/// سداد قسط:
///   يُنشئ سند قبض تلقائياً + يُحدَّث رصيد السلفة وحالتها ذرياً
///
/// Copied from [AdvanceNotifier].
@ProviderFor(AdvanceNotifier)
final advanceNotifierProvider =
    AutoDisposeNotifierProvider<AdvanceNotifier, AsyncValue<String?>>.internal(
  AdvanceNotifier.new,
  name: r'advanceNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$advanceNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AdvanceNotifier = AutoDisposeNotifier<AsyncValue<String?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
