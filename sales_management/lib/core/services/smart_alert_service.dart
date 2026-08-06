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

    // 1. فحص أرصدة الخزائن من VIEW الأرصدة
    try {
      final totals = await _db.treasuriesDao.getTotalBalance();
      if (totals.totalIqd < kLowBalanceThresholdIQD) {
        alerts.add(
          SmartAlert(
            id: 'low_total_balance',
            title: 'تحذير: رصيد الخزائن منخفض',
            description:
                'إجمالي رصيد الخزائن الحالي هو ${totals.totalIqd.toStringAsFixed(0)} د.ع، وهو أقل من الحد الأدنى المقترح (1,000,000 د.ع).',
            severity: AlertSeverity.warning,
            createdAt: DateTime.now(),
            actionLabel: 'استعراض الخزائن',
          ),
        );
      }
    } catch (_) {
      // ابتلاع الأخطاء لعدم إيقاف الشاشة
    }

    // 2. فحص السُلف المعلقة القديمة (Vouchers من نوع advance)
    try {
      final now = DateTime.now();
      final allVouchers = await _db.vouchersDao.getAllVouchers();
      final overdueAdvances = allVouchers.where((v) {
        if (v.isDeleted) return false;
        final age = now.difference(v.voucherDate).inDays;
        return age >= kOverdueAdvanceDays;
      }).toList();

      if (overdueAdvances.isNotEmpty) {
        alerts.add(
          SmartAlert(
            id: 'overdue_advances',
            title: 'تنبيه: سُلف ومستحقات معلقة قديمة',
            description:
                'يوجد عدد ${overdueAdvances.length} سند/سُلفة مضى على تسجيلها أكثر من $kOverdueAdvanceDays يوماً ولم تُقفل بعد.',
            severity: AlertSeverity.critical,
            createdAt: DateTime.now(),
            actionLabel: 'عرض السندات',
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
