// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نظام إدارة المبيعات';

  @override
  String get appTagline => 'إدارة حسابات ذكية وسريعة';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get add => 'إضافة';

  @override
  String get search => 'بحث';

  @override
  String get filter => 'تصفية';

  @override
  String get print => 'طباعة';

  @override
  String get export => 'تصدير';

  @override
  String get import => 'استيراد';

  @override
  String get confirm => 'تأكيد';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get close => 'إغلاق';

  @override
  String get back => 'رجوع';

  @override
  String get next => 'التالي';

  @override
  String get previous => 'السابق';

  @override
  String get finish => 'إنهاء';

  @override
  String get refresh => 'تحديث';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get success => 'تمت العملية بنجاح';

  @override
  String get error => 'حدث خطأ';

  @override
  String get warning => 'تحذير';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get requiredField => 'هذا الحقل مطلوب';

  @override
  String get invalidInput => 'مدخل غير صحيح';

  @override
  String get confirmDelete => 'هل أنت متأكد من الحذف؟';

  @override
  String get deleteWarning => 'لا يمكن التراجع عن هذه العملية.';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get loginButton => 'دخول';

  @override
  String get loginError => 'اسم المستخدم أو كلمة المرور غير صحيحة';

  @override
  String accountLocked(int minutes) {
    return 'الحساب مقفل. حاول بعد $minutes دقيقة';
  }

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirm => 'هل تريد تسجيل الخروج؟';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get settings => 'الإعدادات';

  @override
  String get treasury => 'الخزينة';

  @override
  String get treasuries => 'الخزائن';

  @override
  String get voucherSarf => 'سند الصرف';

  @override
  String get voucherKabd => 'سند القبض';

  @override
  String get vouchers => 'السندات';

  @override
  String get employees => 'الموظفون';

  @override
  String get employee => 'موظف';

  @override
  String get loans => 'السلف';

  @override
  String get salaries => 'الرواتب';

  @override
  String get contractors => 'المقاولون';

  @override
  String get partners => 'الشركاء';

  @override
  String get reports => 'التقارير';

  @override
  String get accountStatement => 'كشف حساب';

  @override
  String get backup => 'النسخ الاحتياطي';

  @override
  String get fiscalYear => 'السنة المالية';

  @override
  String get auditLog => 'سجل المراجعة';

  @override
  String get currencyIQD => 'دينار عراقي';

  @override
  String get currencyUSD => 'دولار أمريكي';

  @override
  String get amount => 'المبلغ';

  @override
  String get date => 'التاريخ';

  @override
  String get notes => 'ملاحظات';

  @override
  String get reason => 'السبب';

  @override
  String get name => 'الاسم';

  @override
  String get phone => 'الهاتف';

  @override
  String get address => 'العنوان';

  @override
  String get balance => 'الرصيد';

  @override
  String get totalBalance => 'إجمالي الرصيد';

  @override
  String get voucherNumber => 'رقم السند';

  @override
  String get language => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get theme => 'المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'تلقائي (النظام)';

  @override
  String get users => 'المستخدمون';

  @override
  String get permissions => 'الصلاحيات';

  @override
  String get roleSuperAdmin => 'مدير النظام';

  @override
  String get roleAdmin => 'مدير';

  @override
  String get roleUser => 'مستخدم';

  @override
  String get firstRunTitle => 'مرحباً بك في نظام إدارة المبيعات';

  @override
  String get firstRunSubtitle => 'أولى خطوة: إنشاء حساب مدير النظام';

  @override
  String get createAccount => 'إنشاء الحساب';

  @override
  String get companyName => 'اسم الشركة';

  @override
  String get companyNameHint => 'أدخل اسم شركتك';

  @override
  String get pageNotFound => 'الصفحة غير موجودة';

  @override
  String get goHome => 'الذهاب للرئيسية';

  @override
  String get permissionDenied => 'ليس لديك صلاحية للوصول لهذه الصفحة';

  @override
  String voucherCount(int count) {
    return '$count سند';
  }

  @override
  String balanceIQD(String amount) {
    return 'الرصيد بالدينار: $amount';
  }

  @override
  String balanceUSD(String amount) {
    return 'الرصيد بالدولار: $amount';
  }
}
