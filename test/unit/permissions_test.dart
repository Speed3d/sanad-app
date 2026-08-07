// ─────────────────────────────────────────────────────────────────────────────
// permissions_test.dart — اختبارات نظام الصلاحيات (RBAC)
//
// لماذا هذا الملف؟
//   كشف تدقيق 2026-08-06 أن العمليات المدمّرة (استعادة قاعدة البيانات، إلغاء
//   سلفة، حذف سجل التدقيق، تصفير الحسابات) كانت متاحة لأي مستخدم، وأن حاجز
//   "تصفير الحسابات" كان مقلوباً (يمنع super_admin ويسمح لـ admin).
//   هذه الاختبارات تُثبّت مصفوفة الصلاحيات الصحيحة وتمنع أي انزلاق مستقبلي.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/auth/permissions.dart';
import 'package:sales_management/domain/models/user_model.dart';

void main() {
  // مستخدمون تجريبيون بالأدوار الثلاثة
  const superAdmin = UserModel(
    id: 1,
    username: 'root',
    fullName: 'مدير النظام',
    role: 'super_admin',
  );
  const admin = UserModel(
    id: 2,
    username: 'manager',
    fullName: 'مدير',
    role: 'admin',
  );
  const user = UserModel(
    id: 3,
    username: 'clerk',
    fullName: 'موظف',
    role: 'user',
  );

  group('العمليات الكارثية — super_admin فقط', () {
    const catastrophic = [
      AppPermission.restoreBackup,
      AppPermission.resetFinancialData,
      AppPermission.reopenFiscalPeriod,
      AppPermission.recomputeBalances,
      AppPermission.purgeAuditLog,
      AppPermission.deleteUser,
    ];

    test('super_admin يملكها كلها', () {
      for (final p in catastrophic) {
        expect(superAdmin.can(p), isTrue, reason: '$p يجب أن تكون متاحة لـ super_admin');
      }
    });

    test('admin لا يملك أياً منها', () {
      for (final p in catastrophic) {
        expect(admin.can(p), isFalse, reason: '$p يجب أن تُمنع عن admin');
      }
    });

    test('user لا يملك أياً منها', () {
      for (final p in catastrophic) {
        expect(user.can(p), isFalse, reason: '$p يجب أن تُمنع عن user');
      }
    });
  });

  group('العمليات الإدارية — admin و super_admin', () {
    const adminOps = [
      AppPermission.deleteVoucher,
      AppPermission.manageTreasuries,
      AppPermission.manageExchangeRate,
      AppPermission.importExcel,
      AppPermission.createBackup,
      AppPermission.viewAudit,
      AppPermission.closeFiscalPeriod,
      AppPermission.manageUsers,
      AppPermission.managePayroll,
      AppPermission.cancelAdvance,
    ];

    test('super_admin و admin يملكانها', () {
      for (final p in adminOps) {
        expect(superAdmin.can(p), isTrue, reason: 'super_admin: $p');
        expect(admin.can(p), isTrue, reason: 'admin: $p');
      }
    });

    test('user لا يملك أياً منها', () {
      for (final p in adminOps) {
        expect(user.can(p), isFalse, reason: 'user يجب أن يُمنع عن $p');
      }
    });
  });

  group('العمليات العادية — أي مستخدم مصادَق', () {
    const basicOps = [
      AppPermission.createVoucher,
      AppPermission.manageEntities,
    ];

    test('الأدوار الثلاثة تملكها', () {
      for (final p in basicOps) {
        expect(superAdmin.can(p), isTrue);
        expect(admin.can(p), isTrue);
        expect(user.can(p), isTrue);
      }
    });
  });

  group('اختبار الثغرة المقلوبة تحديداً', () {
    test('تصفير الحسابات: super_admin نعم، admin لا (كان مقلوباً)', () {
      // الحاجز القديم كان `role == "admin"` فيمنع super_admin ويسمح لـ admin
      expect(superAdmin.can(AppPermission.resetFinancialData), isTrue);
      expect(admin.can(AppPermission.resetFinancialData), isFalse);
    });
  });
}
