// ─────────────────────────────────────────────────────────────────────────────
// settings_tabs_render_test.dart — كل تبويبات الإعدادات تُرسَم بلا خطأ
//
// **البلاغ (المالك 2026-10-15):** فتحُ «الأمان» يطبع:
//     ListTile background color or ink splashes may be invisible.
//     The ListTile is wrapped in a DecoratedBox that has a background color.
//
// **السبب:** `SwitchListTile` قابلٌ للضغط داخل `Container` بلونٍ مرسوم ولا
//   `Material` بينهما — فموجة الضغط تُرسَم على أقرب `Material` **خلف**
//   البطاقة فلا تُرى. والإطار يفحص ذلك في كل بناء.
//
// ولا اختبار كان يرسم تبويبات الإعدادات قطّ — فهذا يرسمها **كلّها** في
//   الوضعين، لأن العطل نمطٌ لا موضع (درس ع-٢٨: لا تُصلح باباً وتترك البقية).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/core/theme/app_theme.dart';
import 'package:sales_management/data/database/app_database.dart';
import 'package:sales_management/presentation/features/settings/tabs/appearance_tab.dart';
import 'package:sales_management/presentation/features/settings/tabs/attachments_tab.dart';
import 'package:sales_management/presentation/features/settings/tabs/backup_tab.dart';
import 'package:sales_management/presentation/features/settings/tabs/company_tab.dart';
import 'package:sales_management/presentation/features/settings/tabs/currency_tab.dart';
import 'package:sales_management/presentation/features/settings/tabs/database_tab.dart';
import 'package:sales_management/presentation/features/settings/tabs/item_types_tab.dart';
import 'package:sales_management/presentation/features/settings/tabs/security_tab.dart';
import 'package:sales_management/presentation/features/settings/tabs/system_info_tab.dart';
import 'package:sales_management/presentation/features/settings/tabs/users_tab.dart';
import 'package:sales_management/presentation/providers/database_provider.dart';

void main() {
  final tabs = <String, Widget Function()>{
    'الشركة': () => const CompanyTab(),
    'المظهر': () => const AppearanceTab(),
    'العملات': () => const CurrencyTab(),
    'أنواع البنود': () => const ItemTypesTab(),
    'الأمان': () => const SecurityTab(),
    'المستخدمون': () => const UsersTab(),
    'المرفقات': () => const AttachmentsTab(),
    'قاعدة البيانات': () => const DatabaseTab(),
    'النسخ الاحتياطي': () => const BackupTab(),
    'معلومات النظام': () => const SystemInfoTab(),
  };

  for (final mode in {'الفاتح': AppTheme.light, 'الداكن': AppTheme.dark}.entries) {
    for (final tab in tabs.entries) {
      testWidgets('⭐⭐ «${tab.key}» يُرسَم بلا خطأ — ${mode.key}',
          (tester) async {
        tester.view.physicalSize = const Size(1400, 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        await tester.pumpWidget(ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: mode.value,
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: tab.value()),
            ),
          ),
        ));
        // لا pumpAndSettle — مؤشّرات التحميل أنيميشن لا ينتهي.
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 60));
        }

        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
      });
    }
  }
}
