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
      // 🔒 نُقلت من admin بطلب المالك 2026-08-30: السجل يكشف من فعل ماذا
      //   لكل مستخدم، وإتاحته لكل مدير تجعل الرقابة مكشوفة لمن يُراقَب.
      AppPermission.viewAudit,
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
      AppPermission.createBackup,
      AppPermission.closeFiscalPeriod,
      AppPermission.manageUsers,
      AppPermission.managePayroll,
      AppPermission.cancelAdvance,
      AppPermission.postAdvance,
      AppPermission.postAdvanceWithDeficit,
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
      AppPermission.importExcel,
      AppPermission.prepareAdvance,
      AppPermission.preparePayroll,
    ];

    test('الأدوار الثلاثة تملكها', () {
      for (final p in basicOps) {
        expect(superAdmin.can(p), isTrue);
        expect(admin.can(p), isTrue);
        expect(user.can(p), isTrue);
      }
    });
  });

  // ── فصل الأدوار في نظام الرواتب (قرار المالك 2026-08-24) ────────────────
  //
  // نفس مبدأ السلف: **الكشف في حالة مسودة لا يمسّ رصيد أي خزينة**، فتجهيزه
  // بمستوى `user`. الأثر المالي كلّه في التسديد المحمي بـ`managePayroll`.
  group('فصل الأدوار في نظام الرواتب', () {
    test('المحاسب (user) يستورد كشف الرواتب ويصحّح سطوره', () {
      expect(user.can(AppPermission.preparePayroll), isTrue,
          reason: 'المسودة بلا أثر مالي — والفروق تُصحَّح قبل الصرف');
    });

    test('⭐ لكن المحاسب لا يصرف — التسديد هو الحاجز الحقيقي', () {
      expect(user.can(AppPermission.managePayroll), isFalse,
          reason: 'التسديد هو اللحظة الوحيدة التي يخرج فيها المال');
    });

    test('المدير يجهّز ويصرف', () {
      expect(admin.can(AppPermission.preparePayroll), isTrue);
      expect(admin.can(AppPermission.managePayroll), isTrue);
    });
  });

  // ── فصل الأدوار في نظام السلف (قرار المالك 2026-08-07) ──────────────────
  group('فصل الأدوار في نظام السلف', () {
    test('المحاسب (user) يستورد ويجهّز المسودة ويحرّرها', () {
      expect(user.can(AppPermission.importExcel), isTrue,
          reason: 'الاستيراد صار يُنتج مسودة لا سندات — لا أثر مالي');
      expect(user.can(AppPermission.prepareAdvance), isTrue,
          reason: 'تحرير المسودة بلا أثر مالي');
    });

    test('لكن المحاسب لا يعتمد — الاعتماد هو الحاجز الحقيقي', () {
      expect(user.can(AppPermission.postAdvance), isFalse,
          reason: 'الاعتماد هو اللحظة الوحيدة التي تتأثر فيها الخزينة');
      expect(user.can(AppPermission.postAdvanceWithDeficit), isFalse);
      expect(user.can(AppPermission.cancelAdvance), isFalse);
    });

    test('المدير يعتمد ويعتمد بعجز', () {
      expect(admin.can(AppPermission.postAdvance), isTrue);
      expect(admin.can(AppPermission.postAdvanceWithDeficit), isTrue);
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
