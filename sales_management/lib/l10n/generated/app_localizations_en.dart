// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sales Management System';

  @override
  String get appTagline => 'Smart & Fast Accounting';

  @override
  String get loading => 'Loading...';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get print => 'Print';

  @override
  String get export => 'Export';

  @override
  String get import => 'Import';

  @override
  String get confirm => 'Confirm';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get finish => 'Finish';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

  @override
  String get success => 'Operation completed successfully';

  @override
  String get error => 'An error occurred';

  @override
  String get warning => 'Warning';

  @override
  String get noData => 'No data available';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidInput => 'Invalid input';

  @override
  String get confirmDelete => 'Are you sure you want to delete?';

  @override
  String get deleteWarning => 'This action cannot be undone.';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loginError => 'Incorrect username or password';

  @override
  String accountLocked(int minutes) {
    return 'Account locked. Try again in $minutes minutes';
  }

  @override
  String get logout => 'Sign Out';

  @override
  String get logoutConfirm => 'Are you sure you want to sign out?';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get settings => 'Settings';

  @override
  String get treasury => 'Treasury';

  @override
  String get treasuries => 'Treasuries';

  @override
  String get voucherSarf => 'Payment Voucher';

  @override
  String get voucherKabd => 'Receipt Voucher';

  @override
  String get vouchers => 'Vouchers';

  @override
  String get employees => 'Employees';

  @override
  String get employee => 'Employee';

  @override
  String get loans => 'Cash Advances';

  @override
  String get salaries => 'Salaries';

  @override
  String get contractors => 'Contractors';

  @override
  String get partners => 'Partners';

  @override
  String get reports => 'Reports';

  @override
  String get accountStatement => 'Account Statement';

  @override
  String get backup => 'Backup';

  @override
  String get fiscalYear => 'Fiscal Year';

  @override
  String get auditLog => 'Audit Log';

  @override
  String get currencyIQD => 'Iraqi Dinar';

  @override
  String get currencyUSD => 'US Dollar';

  @override
  String get amount => 'Amount';

  @override
  String get date => 'Date';

  @override
  String get notes => 'Notes';

  @override
  String get reason => 'Reason';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get balance => 'Balance';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get voucherNumber => 'Voucher No.';

  @override
  String get language => 'Language';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get languageEnglish => 'English';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System Default';

  @override
  String get users => 'Users';

  @override
  String get permissions => 'Permissions';

  @override
  String get roleSuperAdmin => 'Super Admin';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleUser => 'User';

  @override
  String get firstRunTitle => 'Welcome to Sales Management System';

  @override
  String get firstRunSubtitle => 'First step: Create your admin account';

  @override
  String get createAccount => 'Create Account';

  @override
  String get companyName => 'Company Name';

  @override
  String get companyNameHint => 'Enter your company name';

  @override
  String get pageNotFound => 'Page Not Found';

  @override
  String get goHome => 'Go to Home';

  @override
  String get permissionDenied =>
      'You do not have permission to access this page';

  @override
  String voucherCount(int count) {
    return '$count voucher(s)';
  }

  @override
  String balanceIQD(String amount) {
    return 'IQD Balance: $amount';
  }

  @override
  String balanceUSD(String amount) {
    return 'USD Balance: $amount';
  }
}
