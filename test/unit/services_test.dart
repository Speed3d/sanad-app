// ─────────────────────────────────────────────────────────────────────────────
// services_test.dart — اختبارات الخدمات الذكية والنسخ السحابي (Phase 4)
//
// الغرض:
//   اختبار آلية عمل SmartAlertService و CloudBackupService
//   - التحقق من توليد التنبيهات عند انخفاض الرصيد عن 1,000,000 د.ع
//   - التحقق من فحص السلف المعلقة القديمة
//   - التحقق من الرفع السحابي والمزامنة
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/services/cloud_backup_service.dart';
import 'package:sales_management/core/services/smart_alert_service.dart';
import 'package:sales_management/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SmartAlertService alertService;
  late CloudBackupService cloudService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    alertService = SmartAlertService(db);
    cloudService = CloudBackupService();
  });

  tearDown(() async {
    await db.close();
  });

  group('اختبارات التنبيهات الذكية (SmartAlertService)', () {
    test('يجب أن يُولد تنبيه رصيد منخفض عندما يكون إجمالي الأرصدة 0', () async {
      final alerts = await alertService.checkAllAlerts();
      final lowBalanceAlert = alerts.where((a) => a.id == 'low_total_balance');
      expect(lowBalanceAlert.isNotEmpty, isTrue);
      expect(lowBalanceAlert.first.severity, equals(AlertSeverity.warning));
    });

    test('يجب كشف السُلف المعلقة القديمة إذا تجاوزت 30 يوماً', () async {
      // سلفة معلّقة (pending) مضى على منحها 35 يوماً
      await db.employeesDao.insertAdvance(
        CashAdvancesCompanion.insert(
          amount: 250000,
          advanceDate: DateTime.now().subtract(const Duration(days: 35)),
          externalPersonName: const Value('دائن خارجي'),
        ),
      );

      final alerts = await alertService.checkAllAlerts();
      final overdueAlert = alerts.where((a) => a.id == 'overdue_advances');
      expect(overdueAlert.isNotEmpty, isTrue);
      expect(overdueAlert.first.severity, equals(AlertSeverity.warning));
    });

    test('السند القديم (وليس سلفة) لا يُطلق تنبيه السلف المتأخرة', () async {
      final periodId = await db.fiscalPeriodsDao.insertPeriod(
        FiscalPeriodsCompanion.insert(
          name: '2026',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
        ),
      );
      final tId = await db.treasuriesDao.insertTreasury(
        TreasuriesCompanion.insert(
          name: 'خزينة',
          kind: const Value('main'),
        ),
      );
      // سند صرف قديم — يجب ألا يُحسَب كسلفة متأخرة (كان الخطأ سابقاً)
      await db.vouchersDao.insertVoucher(
        VouchersCompanion.insert(
          voucherNumber: 101,
          treasuryId: tId,
          fiscalPeriodId: periodId,
          voucherType: 'sarf',
          amount: 250000,
          currency: const Value('IQD'),
          voucherDate: DateTime.now().subtract(const Duration(days: 35)),
        ),
      );

      final alerts = await alertService.checkAllAlerts();
      expect(
        alerts.where((a) => a.id == 'overdue_advances').isEmpty,
        isTrue,
        reason: 'السند العادي القديم يجب ألا يُطلق تنبيه السلف',
      );
    });
  });

  group('اختبارات الخدمة السحابية (CloudBackupService)', () {
    test('يجب أن تكون الحالة الأوليّة جاهزة للمزامنة', () {
      final info = cloudService.info;
      expect(info.status, equals(CloudSyncStatus.idle));
      expect(info.lastSyncTime, isNull);
    });

    test('تنسيق حجم الملف المرفوع', () {
      const info = CloudBackupInfo(fileSizeBytes: 2048);
      expect(info.formattedSize, equals('2.0 ك.ب'));
    });
  });
}
