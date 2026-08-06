// ─────────────────────────────────────────────────────────────────────────────
// app_colors.dart — ألوان التطبيق الثابتة
//
// هذا الملف يحتوي على جميع الألوان المستخدمة في التطبيق.
// الألوان الرئيسية: أخضر داكن (الأساسي) + ذهبي (الثانوي)
// ملاحظة: لا تستخدم هذه الألوان مباشرة في الـ Widgets —
//          استخدم Theme.of(context).colorScheme بدلاً من ذلك.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// ألوان ثابتة تستخدم كـ Seed للـ ColorScheme
abstract final class AppColors {
  // ── الألوان الأساسية (Seed Colors) ──────────────────────────────────────

  /// اللون الأساسي: أزرق ملكي فاخر (Royal Midnight Navy) — طابع التطبيقات المالية الحديثة (Fintech)
  static const Color primarySeed = Color(0xFF0F172A);

  /// اللون الثانوي: سايان كهربائي (Electric Cyan) — للعناصر البارزة والأيقونات والتحديدات
  static const Color secondarySeed = Color(0xFF0284C7);

  /// لون الخطأ: أحمر قياسي Material
  static const Color errorSeed = Color(0xFFB00020);

  // ── ألوان سندات القبض والصرف ─────────────────────────────────────────────

  /// لون سند القبض (إيداع) — أخضر
  static const Color receiptColor = Color(0xFF2E7D32);

  /// لون سند الصرف (سحب) — أحمر
  static const Color paymentColor = Color(0xFFC62828);

  /// لون التحويل بين الخزينتين — أزرق
  static const Color transferColor = Color(0xFF1565C0);

  // ── ألوان الحالات ─────────────────────────────────────────────────────────

  /// حالة: نشط / مكتمل
  static const Color statusActive = Color(0xFF388E3C);

  /// حالة: معلق / جزئي
  static const Color statusPending = Color(0xFFF57C00);

  /// حالة: مغلق / غير نشط
  static const Color statusClosed = Color(0xFF757575);

  /// حالة: مشكلة / مرفوض
  static const Color statusError = Color(0xFFD32F2F);

  // ── ألوان الإشعارات ────────────────────────────────────────────────────────

  /// لون الإشعارات المعلوماتية
  static const Color infoColor = Color(0xFF0277BD);

  /// لون رسائل النجاح
  static const Color successColor = Color(0xFF2E7D32);

  /// لون رسائل التحذير
  static const Color warningColor = Color(0xFFE65100);

  // ── ألوان النص الخاصة ─────────────────────────────────────────────────────

  /// نص الأرقام الموجبة (الأموال الواردة)
  static const Color positiveAmount = Color(0xFF1B5E20);

  /// نص الأرقام السالبة (الأموال الصادرة)
  static const Color negativeAmount = Color(0xFFB71C1C);
}
