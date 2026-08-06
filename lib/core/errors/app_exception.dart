// ─────────────────────────────────────────────────────────────────────────────
// app_exception.dart — استثناءات التطبيق المركزية
//
// هذا الملف يُعرّف التسلسل الهرمي لجميع الأخطاء الممكنة في التطبيق.
//
// الغرض:
//   بدلاً من رمي Exception عشوائية في كل مكان، نستخدم هذه الكلاسات
//   الموحَّدة التي تحمل رسائل عربية واضحة يمكن عرضها مباشرة للمستخدم.
//
// كيفية الاستخدام:
//   try {
//     await repository.login(username, password);
//   } on AppException catch (e) {
//     showSnackBar(e.userMessage);   // رسالة عربية جاهزة للعرض
//   }
//
// الكلاسات المتاحة:
//   AppException       — الكلاس الأساسي (sealed)
//   ├── AuthException       — أخطاء المصادقة وتسجيل الدخول
//   ├── DatabaseException   — أخطاء قاعدة البيانات
//   ├── ValidationException — أخطاء التحقق من صحة المدخلات
//   ├── FileException       — أخطاء الملفات والتخزين
//   ├── PermissionException — أخطاء الصلاحيات
//   └── NetworkException    — أخطاء الشبكة والاتصال
// ─────────────────────────────────────────────────────────────────────────────

/// الكلاس الأساسي لجميع استثناءات التطبيق
///
/// sealed يعني أن Dart يعرف جميع الأنواع الممكنة وقت التصريف،
/// مما يتيح pattern matching مضموناً (exhaustive switch).
sealed class AppException implements Exception {
  // ── المُنشئ ───────────────────────────────────────────────────────────────

  /// [technicalMessage] — وصف تقني للمطور (يظهر في الـ Logs فقط)
  /// [userMessage]      — رسالة عربية واضحة تُعرض للمستخدم
  /// [originalError]    — الاستثناء الأصلي (للـ Debugging)
  const AppException({
    required this.technicalMessage,
    required this.userMessage,
    this.originalError,
  });

  // ── الحقول المشتركة ───────────────────────────────────────────────────────

  /// الوصف التقني — يُطبَع في الـ Console للمطور
  final String technicalMessage;

  /// الرسالة العربية — تُعرض مباشرة في الـ SnackBar أو Dialog
  final String userMessage;

  /// الاستثناء الأصلي — للتتبع العميق (Stack Trace)
  final Object? originalError;

  // ── دالة مساعدة ──────────────────────────────────────────────────────────

  @override
  String toString() => 'AppException[$runtimeType]: $technicalMessage';
}

// ─────────────────────────────────────────────────────────────────────────────
// أنواع الاستثناءات
// ─────────────────────────────────────────────────────────────────────────────

/// أخطاء المصادقة وتسجيل الدخول
///
/// تُرمى عند:
///   - اسم مستخدم أو كلمة مرور خاطئة
///   - حساب موقوف أو مقفل
///   - انتهاء صلاحية الجلسة
///   - محاولة تسجيل دخول متعددة فاشلة
final class AuthException extends AppException {
  const AuthException({
    required super.technicalMessage,
    required super.userMessage,
    super.originalError,
    this.type = AuthExceptionType.invalidCredentials,
  });

  /// نوع خطأ المصادقة المحدد
  final AuthExceptionType type;

  // ── مصانع جاهزة الاستخدام ─────────────────────────────────────────────────

  /// بيانات الدخول غير صحيحة
  factory AuthException.invalidCredentials() => const AuthException(
        technicalMessage: 'Invalid username or password',
        userMessage: 'اسم المستخدم أو كلمة المرور غير صحيحة',
        type: AuthExceptionType.invalidCredentials,
      );

  /// الحساب موقوف من قِبل المدير
  factory AuthException.accountDisabled() => const AuthException(
        technicalMessage: 'Account is disabled',
        userMessage: 'هذا الحساب موقوف. تواصل مع المدير',
        type: AuthExceptionType.accountDisabled,
      );

  /// الحساب مقفل مؤقتاً بسبب محاولات فاشلة
  factory AuthException.accountLocked({required int minutesLeft}) =>
      AuthException(
        technicalMessage: 'Account locked for $minutesLeft minutes',
        userMessage: 'الحساب مقفل مؤقتاً. حاول مرة أخرى بعد $minutesLeft دقيقة',
        type: AuthExceptionType.accountLocked,
      );

  /// لا توجد جلسة نشطة (تسجيل خروج تلقائي)
  factory AuthException.sessionExpired() => const AuthException(
        technicalMessage: 'Session expired or not found',
        userMessage: 'انتهت جلسة العمل. سجّل دخولك مجدداً',
        type: AuthExceptionType.sessionExpired,
      );

  /// كلمة المرور القديمة خاطئة (عند تغيير كلمة المرور)
  factory AuthException.wrongCurrentPassword() => const AuthException(
        technicalMessage: 'Current password is incorrect',
        userMessage: 'كلمة المرور الحالية غير صحيحة',
        type: AuthExceptionType.wrongCurrentPassword,
      );
}

/// أنواع أخطاء المصادقة — للتمييز بين الحالات في الـ UI
enum AuthExceptionType {
  /// بيانات دخول خاطئة
  invalidCredentials,

  /// حساب موقوف
  accountDisabled,

  /// حساب مقفل مؤقتاً
  accountLocked,

  /// جلسة منتهية
  sessionExpired,

  /// كلمة المرور الحالية خاطئة
  wrongCurrentPassword,
}

// ─────────────────────────────────────────────────────────────────────────────

/// أخطاء قاعدة البيانات
///
/// تُرمى عند:
///   - فشل عملية INSERT/UPDATE/DELETE
///   - انتهاك القيود (Constraint Violation)
///   - تعطّل الاتصال بقاعدة البيانات
///   - فشل الـ Migration
final class DatabaseException extends AppException {
  const DatabaseException({
    required super.technicalMessage,
    required super.userMessage,
    super.originalError,
    this.type = DatabaseExceptionType.operationFailed,
  });

  /// نوع خطأ قاعدة البيانات
  final DatabaseExceptionType type;

  // ── مصانع جاهزة الاستخدام ─────────────────────────────────────────────────

  /// فشل عملية الإدراج
  factory DatabaseException.insertFailed({Object? error}) => DatabaseException(
        technicalMessage: 'INSERT operation failed: $error',
        userMessage: 'فشل حفظ البيانات. حاول مرة أخرى',
        type: DatabaseExceptionType.operationFailed,
        originalError: error,
      );

  /// فشل عملية التحديث
  factory DatabaseException.updateFailed({Object? error}) => DatabaseException(
        technicalMessage: 'UPDATE operation failed: $error',
        userMessage: 'فشل تحديث البيانات. حاول مرة أخرى',
        type: DatabaseExceptionType.operationFailed,
        originalError: error,
      );

  /// فشل عملية الحذف
  factory DatabaseException.deleteFailed({Object? error}) => DatabaseException(
        technicalMessage: 'DELETE operation failed: $error',
        userMessage: 'فشل حذف البيانات. حاول مرة أخرى',
        type: DatabaseExceptionType.operationFailed,
        originalError: error,
      );

  /// انتهاك قيد التفرد (مثل: اسم المستخدم مكرر)
  factory DatabaseException.uniqueViolation({required String field}) =>
      DatabaseException(
        technicalMessage: 'UNIQUE constraint violation on field: $field',
        userMessage: 'هذا $field مستخدم بالفعل. اختر قيمة مختلفة',
        type: DatabaseExceptionType.uniqueViolation,
      );

  /// السجل المطلوب غير موجود
  factory DatabaseException.notFound({required String entity}) =>
      DatabaseException(
        technicalMessage: 'Record not found: $entity',
        userMessage: 'لم يتم العثور على $entity المطلوب',
        type: DatabaseExceptionType.notFound,
      );

  /// خطأ عام في قاعدة البيانات
  factory DatabaseException.unknown({Object? error}) => DatabaseException(
        technicalMessage: 'Database error: $error',
        userMessage: 'حدث خطأ في قاعدة البيانات. أعد تشغيل التطبيق',
        type: DatabaseExceptionType.operationFailed,
        originalError: error,
      );
}

/// أنواع أخطاء قاعدة البيانات
enum DatabaseExceptionType {
  /// فشل عملية (INSERT/UPDATE/DELETE)
  operationFailed,

  /// انتهاك قيد التفرد
  uniqueViolation,

  /// سجل غير موجود
  notFound,

  /// فشل الـ Migration
  migrationFailed,
}

// ─────────────────────────────────────────────────────────────────────────────

/// أخطاء التحقق من صحة المدخلات
///
/// تُرمى عند:
///   - حقل مطلوب فارغ
///   - قيمة خارج النطاق المسموح
///   - تنسيق غير صحيح (مثل: رقم سالب في المبلغ)
///   - شرط أعمال غير مكتمل
final class ValidationException extends AppException {
  const ValidationException({
    required super.technicalMessage,
    required super.userMessage,
    super.originalError,
    this.fieldName,
  });

  /// اسم الحقل الذي فشل التحقق منه (للـ Form Field تمييز الخطأ)
  final String? fieldName;

  // ── مصانع جاهزة الاستخدام ─────────────────────────────────────────────────

  /// حقل مطلوب فارغ
  factory ValidationException.required({required String field}) =>
      ValidationException(
        technicalMessage: 'Required field is empty: $field',
        userMessage: 'حقل "$field" مطلوب ولا يمكن تركه فارغاً',
        fieldName: field,
      );

  /// مبلغ غير صالح (صفر أو سالب)
  factory ValidationException.invalidAmount() => const ValidationException(
        technicalMessage: 'Amount must be greater than zero',
        userMessage: 'المبلغ يجب أن يكون أكبر من صفر',
        fieldName: 'amount',
      );

  /// رصيد الخزينة غير كافٍ
  factory ValidationException.insufficientBalance({
    required double available,
    required double required_,
  }) =>
      ValidationException(
        technicalMessage:
            'Insufficient balance: available=$available, required=$required_',
        userMessage:
            'الرصيد المتاح غير كافٍ. المتاح: ${available.toStringAsFixed(0)} د.ع',
        fieldName: 'balance',
      );

  /// نسبة مشاركة غير صالحة (يجب بين 0 و 100)
  factory ValidationException.invalidSharePercentage() =>
      const ValidationException(
        technicalMessage: 'Share percentage must be between 0 and 100',
        userMessage: 'نسبة المشاركة يجب أن تكون بين 0 و 100%',
        fieldName: 'sharePercentage',
      );

  /// خطأ تحقق مخصص
  factory ValidationException.custom({
    required String message,
    String? field,
  }) =>
      ValidationException(
        technicalMessage: 'Validation failed: $message',
        userMessage: message,
        fieldName: field,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

/// أخطاء الملفات والتخزين
///
/// تُرمى عند:
///   - فشل قراءة/كتابة ملف
///   - ملف Excel تالف أو غير مدعوم
///   - مساحة التخزين ممتلئة
///   - ملف النسخة الاحتياطية تالف
final class FileException extends AppException {
  const FileException({
    required super.technicalMessage,
    required super.userMessage,
    super.originalError,
    this.type = FileExceptionType.readFailed,
  });

  /// نوع خطأ الملف
  final FileExceptionType type;

  // ── مصانع جاهزة الاستخدام ─────────────────────────────────────────────────

  /// فشل قراءة الملف
  factory FileException.readFailed({required String path, Object? error}) =>
      FileException(
        technicalMessage: 'Failed to read file: $path — $error',
        userMessage: 'فشل فتح الملف. تأكد من صلاحية الوصول وأن الملف غير تالف',
        type: FileExceptionType.readFailed,
        originalError: error,
      );

  /// فشل كتابة الملف
  factory FileException.writeFailed({required String path, Object? error}) =>
      FileException(
        technicalMessage: 'Failed to write file: $path — $error',
        userMessage: 'فشل حفظ الملف. تأكد من وجود مساحة كافية في التخزين',
        type: FileExceptionType.writeFailed,
        originalError: error,
      );

  /// ملف Excel غير صالح أو تالف
  factory FileException.invalidExcel() => const FileException(
        technicalMessage: 'Invalid or corrupted Excel file',
        userMessage:
            'الملف المحدد ليس ملف Excel صالحاً. يُدعم فقط امتداد .xlsx',
        type: FileExceptionType.invalidFormat,
      );

  /// ملف النسخة الاحتياطية تالف
  factory FileException.corruptedBackup() => const FileException(
        technicalMessage: 'Backup file is corrupted or tampered',
        userMessage: 'ملف النسخة الاحتياطية تالف أو لم يتم إنشاؤه من هذا التطبيق',
        type: FileExceptionType.corruptedBackup,
      );

  /// المستخدم ألغى اختيار الملف
  factory FileException.cancelled() => const FileException(
        technicalMessage: 'File selection was cancelled by user',
        userMessage: 'تم إلغاء اختيار الملف',
        type: FileExceptionType.cancelled,
      );
}

/// أنواع أخطاء الملفات
enum FileExceptionType {
  /// فشل قراءة الملف
  readFailed,

  /// فشل كتابة الملف
  writeFailed,

  /// تنسيق غير صالح
  invalidFormat,

  /// نسخة احتياطية تالفة
  corruptedBackup,

  /// إلغاء من المستخدم
  cancelled,
}

// ─────────────────────────────────────────────────────────────────────────────

/// أخطاء الصلاحيات
///
/// تُرمى عند:
///   - محاولة الوصول لميزة لا تتوفر للمستخدم
///   - محاولة حذف آخر مدير
///   - محاولة تعديل فترة مالية مغلقة
///   - محاولة العمل على خزينة غير نشطة
final class PermissionException extends AppException {
  const PermissionException({
    required super.technicalMessage,
    required super.userMessage,
    super.originalError,
  });

  // ── مصانع جاهزة الاستخدام ─────────────────────────────────────────────────

  /// صلاحية غير كافية للقيام بهذا الإجراء
  factory PermissionException.insufficientRole({required String action}) =>
      PermissionException(
        technicalMessage: 'Insufficient role for action: $action',
        userMessage: 'ليس لديك صلاحية كافية للقيام بهذه العملية',
      );

  /// محاولة حذف آخر مدير عام
  factory PermissionException.cannotDeleteLastSuperAdmin() =>
      const PermissionException(
        technicalMessage: 'Cannot delete the last super admin',
        userMessage: 'لا يمكن حذف المدير العام الوحيد في النظام',
      );

  /// محاولة إنشاء سند في فترة مالية مغلقة
  factory PermissionException.fiscalPeriodClosed() => const PermissionException(
        technicalMessage: 'Cannot create voucher in a closed fiscal period',
        userMessage:
            'الفترة المالية الحالية مغلقة. لا يمكن إضافة سندات جديدة',
      );

  /// محاولة العمل على خزينة غير نشطة
  factory PermissionException.vaultInactive() => const PermissionException(
        technicalMessage: 'Cannot operate on an inactive vault',
        userMessage: 'هذه الخزينة غير نشطة. فعّلها أولاً من إدارة الخزائن',
      );
}

// ─────────────────────────────────────────────────────────────────────────────

/// أخطاء الشبكة والاتصال
///
/// تُرمى عند:
///   - عدم وجود اتصال بالإنترنت
///   - فشل رفع النسخة الاحتياطية للسحابة
///   - انتهاء مهلة الطلب (Timeout)
final class NetworkException extends AppException {
  const NetworkException({
    required super.technicalMessage,
    required super.userMessage,
    super.originalError,
    this.type = NetworkExceptionType.noConnection,
  });

  /// نوع خطأ الشبكة
  final NetworkExceptionType type;

  // ── مصانع جاهزة الاستخدام ─────────────────────────────────────────────────

  /// لا يوجد اتصال بالإنترنت
  factory NetworkException.noConnection() => const NetworkException(
        technicalMessage: 'No internet connection available',
        userMessage:
            'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وأعد المحاولة',
        type: NetworkExceptionType.noConnection,
      );

  /// انتهاء مهلة الطلب
  factory NetworkException.timeout() => const NetworkException(
        technicalMessage: 'Network request timed out',
        userMessage: 'انتهت مهلة الاتصال. تحقق من الشبكة وأعد المحاولة',
        type: NetworkExceptionType.timeout,
      );

  /// فشل رفع النسخة الاحتياطية للسحابة
  factory NetworkException.cloudUploadFailed({Object? error}) =>
      NetworkException(
        technicalMessage: 'Cloud backup upload failed: $error',
        userMessage: 'فشل رفع النسخة الاحتياطية للسحابة. تحقق من الاتصال',
        type: NetworkExceptionType.uploadFailed,
        originalError: error,
      );
}

/// أنواع أخطاء الشبكة
enum NetworkExceptionType {
  /// لا يوجد اتصال
  noConnection,

  /// انتهاء المهلة
  timeout,

  /// فشل الرفع
  uploadFailed,
}
