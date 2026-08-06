// ─────────────────────────────────────────────────────────────────────────────
// user_model.dart — نموذج المستخدم في طبقة الـ Domain
//
// هذا النموذج مستقل عن قاعدة البيانات (Drift) وعن الواجهة (Flutter).
// يُستخدَم في طبقة الـ Business Logic فقط.
//
// لماذا Freezed؟
//   - Immutability: لا يمكن تغيير البيانات بعد إنشاء النموذج
//   - copyWith: تحديث نظيف بدون تغيير النموذج الأصلي
//   - equality: مقارنة صحيحة بـ == بدون كتابة يدوية
//   - toString: مفيد جداً عند تتبع الأخطاء (Debugging)
//
// الأدوار المدعومة:
//   'super_admin' — صلاحيات كاملة، لا يمكن حذفه إذا كان الأخير
//   'admin'       — إدارة العمليات اليومية
//   'user'        — قراءة وإدخال بيانات فقط
// ─────────────────────────────────────────────────────────────────────────────

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// نموذج المستخدم في طبقة الـ Domain
///
/// يُحوَّل من [User] (Drift) عبر extension في طبقة الـ Data
@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    /// المعرّف الفريد في قاعدة البيانات
    required int id,

    /// اسم المستخدم للدخول (فريد، case-insensitive)
    required String username,

    /// الاسم الكامل للعرض في الواجهة
    required String fullName,

    /// الدور: 'super_admin' | 'admin' | 'user'
    required String role,

    /// صلاحيات إضافية مخصصة بصيغة JSON
    /// مثال: {"can_export": true, "can_delete_voucher": false}
    @Default('{}') String permissionsJson,

    /// هل الحساب مفعَّل؟
    @Default(true) bool isActive,

    /// عدد محاولات الدخول الفاشلة المتتالية
    @Default(0) int failedLoginAttempts,

    /// وقت رفع القفل (null = غير مقفول)
    DateTime? lockedUntil,

    /// وقت آخر دخول ناجح
    DateTime? lastLoginAt,

    /// وقت إنشاء الحساب
    DateTime? createdAt,
  }) = _UserModel;

  /// إنشاء من JSON (للحفظ في SharedPreferences أو الإرسال عبر الشبكة)
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

// ── Extensions مساعدة ────────────────────────────────────────────────────────

/// امتدادات لنموذج المستخدم
extension UserModelX on UserModel {
  /// هل المستخدم مدير نظام؟
  bool get isSuperAdmin => role == 'super_admin';

  /// هل المستخدم مدير؟ (admin أو super_admin)
  bool get isAdmin => role == 'admin' || role == 'super_admin';

  /// هل الحساب مقفول حالياً؟
  bool get isLocked {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }

  /// الوقت المتبقي على رفع القفل بالدقائق
  int get minutesUntilUnlock {
    if (!isLocked) return 0;
    return lockedUntil!.difference(DateTime.now()).inMinutes + 1;
  }

  /// وصف الدور بالعربية
  String get roleDisplayName {
    switch (role) {
      case 'super_admin':
        return 'مدير النظام';
      case 'admin':
        return 'مدير';
      case 'user':
        return 'مستخدم';
      default:
        return role;
    }
  }
}
