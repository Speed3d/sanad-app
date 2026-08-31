// ─────────────────────────────────────────────────────────────────────────────
// factory_reset_service.dart — تصفير المصنع: التطبيق كلّه من الصفر
//
// 🔥 **أخطر عملية في التطبيق** — أخطر حتى من المحو القسري لفترة مالية:
//   ذاك يمحو سنةً واحدة ويُبقي من أنشأها، وهذا يمحو **البرنامج كلّه** —
//   المستخدمين والخزائن والموظفين والشعار وسجل التدقيق نفسه — ويُعيد
//   التطبيق إلى شاشة الإعداد الأول كأنه لم يُشغَّل قط.
//
// أُضيفت بطلب صريح من المالك (2026-08-30): «لغاية الآن لا يوجد لدي بيانات
// حقيقية وكل شيء في مرحلة التطوير والاختبار» — ومرحلة الاختبار تحتاج نقطة
// بداية نظيفة مضمونة، لا تصفيراً جزئياً يترك خزائن وموظفين من تجربة سابقة
// يشوّشون نتيجة التجربة التالية.
//
// ─────────────────────────────────────────────────────────────────────────────
// لماذا خدمة مستقلّة لا منطقٌ داخل الشاشة؟
//
//   القانون ٤: «الحارس في أعمق طبقة ممكنة — وحارسٌ لا يمرّ به اختبار ليس
//   حارساً». الحُرّاس الثلاثة هنا تُتحقَّق في مكان واحد يمرّ به **كل**
//   مستدعٍ، ويغطّيها `test/unit/factory_reset_test.dart` بلا واجهة إطلاقاً.
//
//   وهذا على نهج `BalanceGuard` و`FiscalPeriodGuard`: خدمة في `core` تعرف
//   قاعدة البيانات. (الاستثناء الوحيد المحروس هو `PdfService` التي يجب أن
//   تبقى جاهلة بها — راجع `company_identity_test.dart`.)
//
// ─────────────────────────────────────────────────────────────────────────────
// ثلاث طبقات حراسة — كلها إلزامية، وترتيبها مقصود
//
//   ١. **الصلاحية** `factoryReset` — مدير النظام وحده. تُفحَص أولاً لأنها
//      الأرخص ولا تلمس القرص.
//   ٢. **كلمة المرور** — تحقّق bcrypt حقيقي لا مقارنة نصية. تمنع من يجد
//      الجهاز مفتوحاً وصاحبه غائب.
//   ٣. **رمز المحو القسري** — عاملٌ ثانٍ لا يُكتب يومياً فلا يُرى على الشاشة
//      ولا يُحفَظ في مدير كلمات مرور. وبدون **تعيينه مسبقاً** تُرفض العملية
//      كلها — راجع `purge_code_card.dart`.
//
//   الطبقتان ٢ و٣ معاً تعنيان أن معرفة إحداهما وحدها لا تكفي. وهو نفس
//   العقد المعتمد في المحو القسري للفترة المالية (`FiscalNotifier.purgePeriod`)
//   — عمليتان بالخطورة نفسها يجب أن تُحرَسا بالطريقة نفسها، وإلا صار
//   الأضعف بابَ الدخول.
//
// ⚠️ ما ليس من مسؤولية هذه الخدمة: **مسح الجلسة**. تعيش في `AuthService`
//   فوق `flutter_secure_storage` (قناة منصّة لا تعمل على الـ VM)، فوضعها هنا
//   كان سيجعل الخدمة كلها غير قابلة للاختبار. يمسحها مزوّد الواجهة بعد
//   نجاح هذه الدالة — راجع `factory_reset_provider.dart`.
// ─────────────────────────────────────────────────────────────────────────────

import '../../data/database/app_database.dart';
import '../../domain/models/user_model.dart';
import '../auth/permissions.dart';
import '../constants/app_settings_keys.dart';
import '../utils/audit_logger.dart';
import 'attachment_service.dart';
import 'auth_service.dart';

/// حصيلة تصفير المصنع — ما مُحي فعلاً، ليُعرَض على المالك بصدق
typedef FactoryResetReport = ({
  int vouchers,
  int periods,
  int advances,
  int payrolls,
  int users,
  int treasuries,
  int employees,
  int attachments,

  /// ملفات المرفقات التي حُذفت من القرص فعلاً
  ///
  /// قد يقلّ عن [attachments] إن كان ملف مفقوداً أصلاً أو مفتوحاً في برنامج
  /// آخر — ولهذا يُعَدّ على حدة بدل افتراض التطابق.
  int filesDeleted,
});

/// خدمة تصفير المصنع
class FactoryResetService {
  const FactoryResetService._();

  /// تنفيذ التصفير الشامل بعد التحقّق من الطبقات الثلاث
  ///
  /// [db]              — قاعدة البيانات
  /// [auth]            — خدمة المصادقة (bcrypt للتحقّقين)
  /// [user]            — المستخدم الذي يضغط الزرّ الآن
  /// [password]        — كلمة مروره
  /// [purgeCode]       — رمز المحو القسري المُعيَّن من الإعدادات
  /// [attachmentsRoot] — جذر مجلد المرفقات (فارغ = لم يُعيَّن، فلا ملفات تُمحى)
  /// [audit]           — يُكتَب فيه سطر **قبل** المسح، راجع `logFactoryReset`
  ///
  /// يرمي [StateError] برسالة عربية عند رفض أي طبقة — والمستدعي يعرضها كما هي.
  static Future<FactoryResetReport> run({
    required AppDatabase db,
    required AuthService auth,
    required UserModel user,
    required String password,
    required String purgeCode,
    required String attachmentsRoot,
    required AuditLogger audit,
  }) async {
    // ── الطبقة ١: الصلاحية ─────────────────────────────────────────────
    if (!user.can(AppPermission.factoryReset)) {
      throw StateError('تصفير المصنع متاح لمدير النظام وحده.');
    }

    // ── الطبقة ٢: كلمة مرور المستخدم (bcrypt) ──────────────────────────
    final dbUser = await db.usersDao.getUserById(user.id);
    if (dbUser == null) {
      throw StateError('تعذّر قراءة بيانات المستخدم.');
    }
    if (!await auth.verifyPassword(password, dbUser.passwordHash)) {
      // رسالة واحدة لكل سبب — كل تمييز إضافي معلومةٌ لمن لا يملكها
      throw StateError('كلمة المرور غير صحيحة.');
    }

    // ── الطبقة ٣: رمز المحو القسري ─────────────────────────────────────
    final codeHash =
        await db.appSettingsDao.getString(AppSettingsKeys.purgeCodeHash);
    if (codeHash == null || codeHash.isEmpty) {
      throw StateError(
        'لم يُعيَّن رمز المحو القسري بعد.\n'
        'عيّنه من: الإعدادات ← الأمان ← رمز المحو القسري.',
      );
    }
    if (!await auth.verifyPassword(purgeCode, codeHash)) {
      throw StateError('رمز المحو القسري غير صحيح.');
    }

    // ── التقاط مسارات المرفقات قبل مسح فهرسها ──────────────────────────
    // بعد `factoryReset` يصير الجدول فارغاً فلا يبقى ما يدلّ على الملفات،
    // وتُصبح الملفات يتيمة على القرص إلى الأبد.
    final rows = await db.attachmentsDao.getAll();
    final relativePaths = [for (final a in rows) a.relativePath];

    // ── سطر التدقيق قبل التنفيذ — راجع logFactoryReset ─────────────────
    await audit.logFactoryReset(userId: user.id, username: user.username);

    // ── التنفيذ: قاعدة البيانات في معاملة واحدة ────────────────────────
    final counts = await db.factoryReset();

    // ── ثم الملفات — بعد نجاح الصفوف لا قبله ───────────────────────────
    // نفس ترتيب حذف المرفق المفرد: «احذف الصفّ ثم امحُ الملف». لو انعكس
    // لأمكن أن تُمحى الملفات ثم تفشل المعاملة، فيبقى فهرس يشير إلى عدم.
    final filesDeleted = await AttachmentService.deleteAllInStore(
      root: attachmentsRoot,
      relativePaths: relativePaths,
    );

    return (
      vouchers: counts.vouchers,
      periods: counts.periods,
      advances: counts.advances,
      payrolls: counts.payrolls,
      users: counts.users,
      treasuries: counts.treasuries,
      employees: counts.employees,
      attachments: counts.attachments,
      filesDeleted: filesDeleted,
    );
  }
}
