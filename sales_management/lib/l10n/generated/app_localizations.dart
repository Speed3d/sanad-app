import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// اسم التطبيق الظاهر في عنوان الشاشة
  ///
  /// In ar, this message translates to:
  /// **'نظام إدارة المبيعات'**
  String get appTitle;

  /// شعار فرعي للتطبيق
  ///
  /// In ar, this message translates to:
  /// **'إدارة حسابات ذكية وسريعة'**
  String get appTagline;

  /// نص التحميل العام
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل...'**
  String get loading;

  /// زر الحفظ
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// زر الإلغاء
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// زر الحذف
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// زر التعديل
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// زر الإضافة
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get add;

  /// زر/حقل البحث
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// زر التصفية
  ///
  /// In ar, this message translates to:
  /// **'تصفية'**
  String get filter;

  /// زر الطباعة
  ///
  /// In ar, this message translates to:
  /// **'طباعة'**
  String get print;

  /// زر التصدير
  ///
  /// In ar, this message translates to:
  /// **'تصدير'**
  String get export;

  /// زر الاستيراد
  ///
  /// In ar, this message translates to:
  /// **'استيراد'**
  String get import;

  /// زر التأكيد
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// إجابة نعم
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get yes;

  /// إجابة لا
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get no;

  /// زر الإغلاق
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// زر الرجوع
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// زر التالي
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// زر السابق
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get previous;

  /// زر الإنهاء
  ///
  /// In ar, this message translates to:
  /// **'إنهاء'**
  String get finish;

  /// زر التحديث
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get refresh;

  /// زر إعادة المحاولة عند الخطأ
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// رسالة النجاح العامة
  ///
  /// In ar, this message translates to:
  /// **'تمت العملية بنجاح'**
  String get success;

  /// رسالة الخطأ العامة
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ'**
  String get error;

  /// كلمة تحذير
  ///
  /// In ar, this message translates to:
  /// **'تحذير'**
  String get warning;

  /// رسالة عدم وجود بيانات
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات'**
  String get noData;

  /// رسالة حقل مطلوب
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get requiredField;

  /// رسالة مدخل غير صحيح
  ///
  /// In ar, this message translates to:
  /// **'مدخل غير صحيح'**
  String get invalidInput;

  /// رسالة تأكيد الحذف
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من الحذف؟'**
  String get confirmDelete;

  /// تحذير الحذف النهائي
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن التراجع عن هذه العملية.'**
  String get deleteWarning;

  /// عنوان شاشة تسجيل الدخول
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// حقل اسم المستخدم
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم'**
  String get username;

  /// حقل كلمة المرور
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// زر تسجيل الدخول
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get loginButton;

  /// رسالة خطأ تسجيل الدخول
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم أو كلمة المرور غير صحيحة'**
  String get loginError;

  /// رسالة قفل الحساب بعد 5 محاولات فاشلة
  ///
  /// In ar, this message translates to:
  /// **'الحساب مقفل. حاول بعد {minutes} دقيقة'**
  String accountLocked(int minutes);

  /// زر تسجيل الخروج
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// تأكيد تسجيل الخروج
  ///
  /// In ar, this message translates to:
  /// **'هل تريد تسجيل الخروج؟'**
  String get logoutConfirm;

  /// عنوان لوحة التحكم
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get dashboard;

  /// عنوان الإعدادات
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// اسم قسم الخزينة
  ///
  /// In ar, this message translates to:
  /// **'الخزينة'**
  String get treasury;

  /// اسم قسم الخزائن (الجمع)
  ///
  /// In ar, this message translates to:
  /// **'الخزائن'**
  String get treasuries;

  /// اسم سند الصرف
  ///
  /// In ar, this message translates to:
  /// **'سند الصرف'**
  String get voucherSarf;

  /// اسم سند القبض
  ///
  /// In ar, this message translates to:
  /// **'سند القبض'**
  String get voucherKabd;

  /// اسم قسم السندات
  ///
  /// In ar, this message translates to:
  /// **'السندات'**
  String get vouchers;

  /// اسم قسم الموظفين
  ///
  /// In ar, this message translates to:
  /// **'الموظفون'**
  String get employees;

  /// كلمة موظف مفرد
  ///
  /// In ar, this message translates to:
  /// **'موظف'**
  String get employee;

  /// اسم قسم السلف
  ///
  /// In ar, this message translates to:
  /// **'السلف'**
  String get loans;

  /// اسم قسم الرواتب
  ///
  /// In ar, this message translates to:
  /// **'الرواتب'**
  String get salaries;

  /// اسم قسم المقاولين
  ///
  /// In ar, this message translates to:
  /// **'المقاولون'**
  String get contractors;

  /// اسم قسم الشركاء
  ///
  /// In ar, this message translates to:
  /// **'الشركاء'**
  String get partners;

  /// اسم قسم التقارير
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reports;

  /// عنوان كشف الحساب
  ///
  /// In ar, this message translates to:
  /// **'كشف حساب'**
  String get accountStatement;

  /// اسم قسم النسخ الاحتياطي
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي'**
  String get backup;

  /// اسم قسم السنة المالية
  ///
  /// In ar, this message translates to:
  /// **'السنة المالية'**
  String get fiscalYear;

  /// اسم قسم سجل المراجعة
  ///
  /// In ar, this message translates to:
  /// **'سجل المراجعة'**
  String get auditLog;

  /// اسم العملة العراقية
  ///
  /// In ar, this message translates to:
  /// **'دينار عراقي'**
  String get currencyIQD;

  /// اسم الدولار الأمريكي
  ///
  /// In ar, this message translates to:
  /// **'دولار أمريكي'**
  String get currencyUSD;

  /// حقل المبلغ
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get amount;

  /// حقل التاريخ
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get date;

  /// حقل الملاحظات
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get notes;

  /// حقل السبب
  ///
  /// In ar, this message translates to:
  /// **'السبب'**
  String get reason;

  /// حقل الاسم
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get name;

  /// حقل الهاتف
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get phone;

  /// حقل العنوان
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get address;

  /// عرض الرصيد
  ///
  /// In ar, this message translates to:
  /// **'الرصيد'**
  String get balance;

  /// إجمالي رصيد جميع الخزائن
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الرصيد'**
  String get totalBalance;

  /// حقل رقم السند
  ///
  /// In ar, this message translates to:
  /// **'رقم السند'**
  String get voucherNumber;

  /// إعداد اللغة
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// اللغة العربية
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// اللغة الإنجليزية
  ///
  /// In ar, this message translates to:
  /// **'الإنجليزية'**
  String get languageEnglish;

  /// إعداد المظهر
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get theme;

  /// المظهر الفاتح
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// المظهر الداكن
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// المظهر حسب إعداد النظام
  ///
  /// In ar, this message translates to:
  /// **'تلقائي (النظام)'**
  String get themeSystem;

  /// عنوان إدارة المستخدمين
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون'**
  String get users;

  /// إدارة الصلاحيات
  ///
  /// In ar, this message translates to:
  /// **'الصلاحيات'**
  String get permissions;

  /// اسم دور مدير النظام
  ///
  /// In ar, this message translates to:
  /// **'مدير النظام'**
  String get roleSuperAdmin;

  /// اسم دور المدير
  ///
  /// In ar, this message translates to:
  /// **'مدير'**
  String get roleAdmin;

  /// اسم دور المستخدم العادي
  ///
  /// In ar, this message translates to:
  /// **'مستخدم'**
  String get roleUser;

  /// عنوان شاشة الإعداد الأول
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في نظام إدارة المبيعات'**
  String get firstRunTitle;

  /// شرح شاشة الإعداد الأول
  ///
  /// In ar, this message translates to:
  /// **'أولى خطوة: إنشاء حساب مدير النظام'**
  String get firstRunSubtitle;

  /// زر إنشاء الحساب
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get createAccount;

  /// حقل اسم الشركة
  ///
  /// In ar, this message translates to:
  /// **'اسم الشركة'**
  String get companyName;

  /// تلميح حقل اسم الشركة
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسم شركتك'**
  String get companyNameHint;

  /// عنوان صفحة 404
  ///
  /// In ar, this message translates to:
  /// **'الصفحة غير موجودة'**
  String get pageNotFound;

  /// زر العودة للصفحة الرئيسية
  ///
  /// In ar, this message translates to:
  /// **'الذهاب للرئيسية'**
  String get goHome;

  /// رسالة رفض الصلاحية
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك صلاحية للوصول لهذه الصفحة'**
  String get permissionDenied;

  /// عدد السندات
  ///
  /// In ar, this message translates to:
  /// **'{count} سند'**
  String voucherCount(int count);

  /// عرض الرصيد بالدينار
  ///
  /// In ar, this message translates to:
  /// **'الرصيد بالدينار: {amount}'**
  String balanceIQD(String amount);

  /// عرض الرصيد بالدولار
  ///
  /// In ar, this message translates to:
  /// **'الرصيد بالدولار: {amount}'**
  String balanceUSD(String amount);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
