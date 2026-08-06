// ─────────────────────────────────────────────────────────────────────────────
// app_colors.dart — ألوان نظام إدارة المبيعات والخزينة (Fintech Theme)
//
// هذا الملف يُعَرّف جميع ألوان النظام اللوني الفاخر (Midnight Navy & Luxury Gold)
// المقتبس من النموذج المعتمد: Sales Management Redesign.dc.html
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// الألوان الثابتة والمتغيرات اللونية الخاصة بالنظام اللوني الفاخر
abstract final class AppColors {
  // ── الألوان الرئيسية والأساسية ──────────────────────────────────────────

  /// اللون الأزرق الملكي الداكن (Royal Midnight Navy) — الأساسي للمؤسسات المالية
  static const Color navy = Color(0xFF0F172A);

  /// اللون النيلي للسايدبار والتصاميم الفرعية (Midnight Navy Sidebar)
  static const Color navySidebarLight = Color(0xFF16213B);
  static const Color navySidebarDark = Color(0xFF18233A);

  /// اللون الذهبي الفاخر في الوضع الفاتح (Luxury Gold - Light)
  static const Color goldLight = Color(0xFFB8862E);

  /// اللون الذهبي الساطع في الوضع الداكن (Luxury Gold - Dark)
  static const Color goldDark = Color(0xFFE0BC66);

  /// اللون الأساسي لـ ColorScheme
  static const Color primarySeed = Color(0xFF0F172A);

  /// اللون الثانوي لـ ColorScheme
  static const Color secondarySeed = Color(0xFFB8862E);

  // ── ألوان الوضع الفاتح (Light Mode Tokens) ──────────────────────────────

  /// خلفية التطبيق العامة في الوضع الفاتح
  static const Color bgLight = Color(0xFFF5F6FA);

  /// أسطح البطاقات والكروت في الوضع الفاتح
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// الأسطح الثانوية والتقسيمات في الوضع الفاتح
  static const Color surface2Light = Color(0xFFF0F1F5);

  /// النص الرئيسي في الوضع الفاتح
  static const Color textLight = Color(0xFF0F172A);

  /// النص الفرعي والمستندات في الوضع الفاتح
  static const Color subtextLight = Color(0xFF64748B);

  /// حدود البطاقات وعناصر الواجهة في الوضع الفاتح
  static const Color borderLight = Color(0xFFE4E6EC);

  // ── ألوان الوضع الداكن (Dark Mode Tokens) ───────────────────────────────

  /// خلفية التطبيق العامة في الوضع الداكن (Deep Midnight Space)
  static const Color bgDark = Color(0xFF0B1220);

  /// أسطح البطاقات والكروت في الوضع الداكن
  static const Color surfaceDark = Color(0xFF131B2C);

  /// الأسطح الثانوية في الوضع الداكن
  static const Color surface2Dark = Color(0xFF1B2740);

  /// النص الرئيسي في الوضع الداكن
  static const Color textDark = Color(0xFFE7EAF2);

  /// النص الفرعي في الوضع الداكن
  static const Color subtextDark = Color(0xFF94A0B8);

  /// حدود البطاقات في الوضع الداكن
  static const Color borderDark = Color(0xFF232F48);

  // ── ألوان العمليات المالية والحالات ─────────────────────────────────────

  /// لون سند القبض والمبالغ الموجبة (الفاتح)
  static const Color greenLight = Color(0xFF16A34A);

  /// لون سند القبض والمبالغ الموجبة (الداكن)
  static const Color greenDark = Color(0xFF34D399);

  /// لون سند الصرف والمبالغ السالبة (الفاتح)
  static const Color redLight = Color(0xFFDC2626);

  /// لون سند الصرف والمبالغ السالبة (الداكن)
  static const Color redDark = Color(0xFFF87171);

  /// لون عمليات التحويل بين الخزائن والمقاولين (الفاتح)
  static const Color blueLight = Color(0xFF2563EB);

  /// لون عمليات التحويل بين الخزائن والمقاولين (الداكن)
  static const Color blueDark = Color(0xFF60A5FA);

  // ── الألوان الثابتة للتوافقية والمعالجة ──────────────────────────────────

  /// لون سند القبض (إيداع)
  static const Color receiptColor = Color(0xFF16A34A);

  /// لون سند الصرف (سحب)
  static const Color paymentColor = Color(0xFFDC2626);

  /// لون التحويل بين الخزائن
  static const Color transferColor = Color(0xFF2563EB);

  /// لون الأرقام الموجبة
  static const Color positiveAmount = Color(0xFF16A34A);

  /// لون الأرقام السالبة
  static const Color negativeAmount = Color(0xFFDC2626);
}
