// ─────────────────────────────────────────────────────────────────────────────
// smart_alert_service.dart — خدمة التنبيهات وإشعارات النظام الذكية
//
// الغرض:
//   يقوم هذا الملف بمسح وتحديد التنبيهات المحاسبية والإدارية الحرجة في النظام، مثل:
//   - انخفاض رصيد الخزائن عن الحد الأدنى المحدد (مثل أقل من 1,000,000 د.ع)
//   - وجود سُلف ومستحقات معلقة تجاوزت مدتها (أكثر من 30 يوماً)
//   - التحقق من حالة النسخ الاحتياطي (إذا لم يتم التصدير منذ أكثر من 7 أيام)
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../presentation/providers/database_provider.dart';

/// مستوى خطورة التنبيه
enum AlertSeverity {
  /// معلومة عامة
  info,

  /// تحذير متوسط الأهمية
  warning,

  /// خطر حرج يستدعي التدخل الفوري
  critical,
}

/// نموذج بيانات التنبيه الذكي
class SmartAlert {
  /// المعرّف الفريد للتنبيه
  final String id;

  /// عنوان التنبيه بالعربية
  final String title;

  /// التفاصيل والوصف بالعربية
  final String description;

  /// درجة الخطورة (info, warning, critical)
  final AlertSeverity severity;

  /// تاريخ ووقت صدور التنبيه
  final DateTime createdAt;

  /// إجراء مقترح للمستخدم (مثل: "عرض الخزينة" أو "نسخ احتياطي")
  final String? actionLabel;

  const SmartAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.createdAt,
    this.actionLabel,
  });
}

/// خدمة التنبيهات الذكية
class SmartAlertService {
  final AppDatabase _db;

  /// الحد الأدنى للرصيد المحذِّر (بالدينار العراقي)
  static const double kLowBalanceThresholdIQD = 1000000.0;

  /// عدد الأيام الأقصى لتنبيه السلف المعلقة
  static const int kOverdueAdvanceDays = 30;

  SmartAlertService(this._db);

  /// مسح جميع التنبيهات الحالية في النظام
  ///
  /// يُعيد قائمة بجميع التنبيهات النشطة مرتبة حسب الأهمية
  Future<List<SmartAlert>> checkAllAlerts() async {
    final alerts = <SmartAlert>[];

        // ملاحظة (2026-08-24): حُذف تنبيه «رصيد الخزائن منخفض» بطلب المالك.
    //
    //   السبب: الحدّ كان رقماً ثابتاً (مليون دينار) لا يعرف طبيعة الخزينة.
    //   خزنة مشروع صغيرة رصيدها ٥٠٠ ألف حالة طبيعية تماماً، فكان التنبيه
    //   الأحمر يظهر دائماً حتى صار ضجيجاً يُتجاهَل — وتنبيه يُتجاهَل دائماً
    //   أسوأ من لا تنبيه، لأنه يُدرّب العين على تخطّي الشريط كلّه.
    //
    //   ورصيد كل خزينة ظاهر أصلاً في لوحة التحكم وشاشة الخزائن.
    //   إن أُعيد يوماً فليكن بحدّ لكل خزينة على حدة لا رقماً واحداً للجميع.

    // 2. فحص السُلف المعلقة القديمة
    //
    // ⚠️ إصلاح H4 (تدقيق 2026-08-06): كان يقرأ *كل* السندات ويعدّ أي سند
    //    أقدم من 30 يوماً كـ"سلفة متأخرة" — أي أن أي بيانات قديمة تُظهر
    //    تنبيهاً أحمر دائماً. الآن نقرأ جدول السلف الفعلي (pending/partial).
    try {
      final now = DateTime.now();
      final pending = await _db.employeesDao.getPendingAdvances();
      final overdueAdvances = pending.where((a) {
        final age = now.difference(a.advanceDate).inDays;
        return age >= kOverdueAdvanceDays;
      }).toList();

      if (overdueAdvances.isNotEmpty) {
        alerts.add(
          SmartAlert(
            id: 'overdue_advances',
            title: 'تنبيه: سلف موظفين معلّقة',
            description:
                'يوجد ${overdueAdvances.length} سلفة موظف لم تُسدَّد بالكامل ومضى '
                'على منحها أكثر من $kOverdueAdvanceDays يوماً.',
            severity: AlertSeverity.warning,
            createdAt: DateTime.now(),
            actionLabel: 'عرض سلف الموظفين',
          ),
        );
      }
    } catch (_) {
      // ابتلاع الأخطاء لعدم إيقاف الشاشة
    }

    return alerts;
  }
}

/// Provider لخدمة التنبيهات الذكية
final smartAlertServiceProvider = Provider<SmartAlertService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SmartAlertService(db);
});

/// FutureProvider لمتابعة التنبيهات الفعالة في الواجهة
final smartAlertsProvider = FutureProvider<List<SmartAlert>>((ref) async {
  final service = ref.watch(smartAlertServiceProvider);
  return service.checkAllAlerts();
});
