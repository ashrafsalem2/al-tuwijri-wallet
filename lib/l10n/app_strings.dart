import 'package:flutter/material.dart';

/// Global, listenable app locale. Toggling this rebuilds MaterialApp,
/// which flips the whole UI between Arabic (RTL) and English (LTR).
class LocaleController {
  LocaleController._();
  static final ValueNotifier<Locale> locale =
      ValueNotifier<Locale>(const Locale('ar')); // default: Arabic / RTL

  static bool get isArabic => locale.value.languageCode == 'ar';

  static void toggle() =>
      locale.value = isArabic ? const Locale('en') : const Locale('ar');

  static void set(String code) => locale.value = Locale(code);
}

/// Lightweight, dependency-free string table. `AppStrings.of(context)` picks
/// the right language from the active locale.
class AppStrings {
  final Locale locale;
  const AppStrings(this.locale);

  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context));

  bool get isAr => locale.languageCode == 'ar';
  String get code => locale.languageCode;
  String _(String ar, String en) => isAr ? ar : en;

  // App / splash
  String get appName => 'Al Tuwijri Wallet';
  String get tagline =>
      _('تابع مشترياتك واجمع نقاطك', 'Track every purchase, earn every point');

  // Login
  String get welcomeBack => _('مرحباً بعودتك 👋', 'Welcome back 👋');
  String get loginSubtitle =>
      _('سجّل الدخول لمتابعة مشترياتك ونقاطك',
        'Sign in to track your purchases and points');
  String get mobileNumber => _('رقم الجوال', 'Mobile number');
  String get password => _('كلمة المرور', 'Password');
  String get signIn => _('تسجيل الدخول', 'Sign In');
  String get demoHint => _('بيانات تجريبية جاهزة — اضغط تسجيل الدخول',
      'Demo credentials are pre-filled — just tap Sign In');
  String get enterMobile => _('أدخل رقم جوالك', 'Enter your mobile number');
  String get enterPassword => _('أدخل كلمة المرور', 'Enter your password');
  // Remember me + biometric login
  String get rememberMe => _('تذكرني', 'Remember me');
  String get loginWithBiometrics =>
      _('الدخول بالبصمة', 'Sign in with biometrics');
  String get loginWithFace => _('الدخول بالتعرّف على الوجه', 'Sign in with Face');
  String get loginWithFingerprint => _('الدخول ببصمة الإصبع', 'Sign in with fingerprint');
  String get biometricReason =>
      _('أكّد هويتك للدخول إلى محفظتك', 'Confirm your identity to open your wallet');
  String get enableBiometricTitle =>
      _('تفعيل الدخول بالبصمة؟', 'Enable biometric sign-in?');
  String get enableBiometricBody => _(
      'ادخل بسرعة وأمان باستخدام بصمتك أو وجهك في المرة القادمة.',
      'Sign in quickly and securely with your fingerprint or face next time.');
  String get enable => _('تفعيل', 'Enable');
  String get notNow => _('ليس الآن', 'Not now');
  String get biometricEnabled => _('تم تفعيل الدخول بالبصمة', 'Biometric sign-in enabled');
  String get biometricFailed => _('تعذّر التحقق بالبصمة', 'Biometric check failed');
  String tooManyAttempts(int seconds) => _(
      'محاولات كثيرة، حاول مرة أخرى بعد $seconds ثانية',
      'Too many attempts. Try again in $seconds seconds.');

  // Forgot / reset password
  String get forgotPassword => _('نسيت كلمة المرور؟', 'Forgot password?');
  String get resetTitle => _('استعادة كلمة المرور', 'Reset password');
  String get resetSubtitle => _('أدخل رقم جوالك لإرسال رمز التحقق',
      'Enter your mobile to receive a verification code');
  String get sendCode => _('إرسال الرمز', 'Send code');
  String get resendCode => _('إعادة إرسال الرمز', 'Resend code');
  String get verificationCode => _('رمز التحقق', 'Verification code');
  String get enterCode => _('أدخل رمز التحقق', 'Enter the code');
  String get resetPasswordAction =>
      _('إعادة تعيين كلمة المرور', 'Reset password');
  String get codeSent => _('تم إرسال رمز التحقق', 'Verification code sent');
  String get passwordResetDone =>
      _('تم تعيين كلمة المرور، سجّل الدخول', 'Password reset — please sign in');
  String devCode(String code) => _('رمز تجريبي: $code', 'Dev code: $code');

  // Register
  String get registerTitle => _('أنشئ حسابك', 'Create your account');
  String get registerSubtitle =>
      _('انضم واجمع نقاطك مع كل عملية شراء', 'Join and earn points on every purchase');
  String get fullName => _('الاسم الكامل', 'Full name');
  String get email => _('البريد الإلكتروني', 'Email');
  String get enterName => _('أدخل اسمك', 'Enter your name');
  String get enterEmail => _('أدخل بريدك الإلكتروني', 'Enter your email');
  String get passwordTooShort =>
      _('كلمة المرور 4 أحرف على الأقل', 'Password must be at least 4 characters');
  String get createAccount => _('إنشاء الحساب', 'Create account');
  String get noAccountYet => _('ليس لديك حساب؟', "Don't have an account?");
  String get haveAccount => _('لديك حساب بالفعل؟', 'Already have an account?');

  // Home
  String get showAtCheckout => _('اعرض هذا عند الدفع', 'Show this at checkout');
  String get scanHint => _('يقوم الكاشير بمسح رمزك لربط عملية الشراء بك',
      'The cashier scans your code to link the sale to you');
  String get refundBarcodeHint => _(
      'يمسح الكاشير هذا الرمز لاسترجاع الفاتورة',
      'Cashier scans this to retrieve the receipt');
  String get refundBarcodeExpired => _(
      'انتهت صلاحية رمز الاسترجاع (3 أيام من تاريخ الشراء)',
      'Refund barcode expired (3 days from purchase)');
  String get refundBarcodeValidity => _(
      'هذا الرمز صالح لمدة 3 أيام فقط من تاريخ الشراء',
      'This barcode is valid for only 3 days from the purchase date');
  String get verifyingMembership =>
      _('جارٍ التحقق من العضوية...', 'Verifying membership…');
  String get notMemberTitle => _('لست عضواً في النادي', 'Not a registered member');
  String get notMemberHint => _(
      'رقم جوالك غير مسجّل في نظام التويجري. يُرجى التسجيل في أحد الفروع لتفعيل بطاقتك.',
      "Your mobile isn't registered in Al Tuwijri. Please sign up at a branch to activate your card.");
  String get verifyFailed =>
      _('تعذّر التحقق من العضوية', 'Could not verify membership');
  String points(int n) => _('$n نقطة', '$n points');
  String get myTransactionsTip => _('عملياتي', 'My sales transactions');

  // Transactions
  String get myTransactions => _('عملياتي', 'My Transactions');
  String get noTransactions => _('لا توجد عمليات بعد', 'No transactions yet');
  String get retry => _('إعادة المحاولة', 'Retry');
  String itemsCount(int n) => _('$n منتج', '$n item(s)');
  // Filters / search
  String get searchTransactionsHint =>
      _('ابحث برقم الإيصال أو الفرع أو المبلغ', 'Search by receipt, store or amount');
  String get filterAll => _('الكل', 'All');
  String get filterCompleted => _('مكتملة', 'Completed');
  String get filterRefunded => _('مستردة', 'Refunded');
  String get noResults => _('لا توجد نتائج مطابقة', 'No matching results');
  String get clearSearch => _('مسح', 'Clear');

  // Statuses
  String status(String raw) {
    switch (raw.toLowerCase()) {
      case 'completed':
        return _('مكتملة', 'completed');
      case 'refunded':
        return _('مستردة', 'refunded');
      case 'pending':
        return _('قيد المعالجة', 'pending');
      default:
        return raw;
    }
  }

  // Detail
  String get items => _('المنتجات', 'Items');
  String get summary => _('الملخص', 'Summary');
  String get details => _('التفاصيل', 'Details');
  String get subtotal => _('المجموع الفرعي', 'Subtotal');
  String get discount => _('الخصم', 'Discount');
  String get vat => _('ضريبة القيمة المضافة (15%)', 'VAT (15%)');
  String get total => _('الإجمالي', 'Total');
  String pointsEarned(int n) => _('+$n نقطة مكتسبة', '+$n points earned');
  String get transactionId => _('رقم العملية', 'Transaction ID');
  String get payment => _('طريقة الدفع', 'Payment');
  String get cashier => _('الكاشير', 'Cashier');
  String get branch => _('الفرع', 'Branch');
  String each(String price) => _('$price للوحدة', '$price each');

  // Points history
  String get pointsTitle => _('النقاط', 'Points');
  String get pointsHistory => _('سجل النقاط', 'Points History');
  String get currentBalance => _('الرصيد الحالي', 'Current balance');
  String get totalEarned => _('المكتسبة', 'Earned');
  String get totalRedeemed => _('المستبدلة', 'Redeemed');
  String get earned => _('مكتسبة', 'Earned');
  String get redeemed => _('مستبدلة', 'Redeemed');
  String get noPoints => _('لا يوجد نشاط نقاط بعد', 'No points activity yet');

  // Profile sheet
  String get profile => _('الملف الشخصي', 'Profile');
  String get language => _('اللغة', 'Language');
  String get arabic => _('العربية', 'العربية');
  String get english => _('English', 'English');
  String memberSince(String date) => _('عضو منذ $date', 'Member since $date');
  String get viewPoints => _('عرض سجل النقاط', 'View points history');
  String get settings => _('الإعدادات', 'Settings');
  String get editProfile => _('تعديل الملف الشخصي', 'Edit profile');
  String get changePassword => _('تغيير كلمة المرور', 'Change password');
  String get currentPassword => _('كلمة المرور الحالية', 'Current password');
  String get newPassword => _('كلمة المرور الجديدة', 'New password');
  String get confirmPassword => _('تأكيد كلمة المرور', 'Confirm password');
  String get passwordsDontMatch =>
      _('كلمتا المرور غير متطابقتين', 'Passwords do not match');
  String get profileUpdated => _('تم تحديث الملف الشخصي', 'Profile updated');
  String get passwordChanged => _('تم تغيير كلمة المرور', 'Password changed');
  String get saveChanges => _('حفظ التغييرات', 'Save changes');
  String get logout => _('تسجيل الخروج', 'Log out');
  String get logoutConfirmTitle => _('تسجيل الخروج؟', 'Log out?');
  String get logoutConfirmBody =>
      _('سيتم إنهاء جلستك الحالية.', 'You will be signed out of your session.');
  String get cancel => _('إلغاء', 'Cancel');

  // Settings screen
  String get apiSettings => _('إعدادات الـ API', 'API settings');
  String get useMockData => _('استخدام بيانات تجريبية', 'Use mock data');
  String get useMockSubtitle => _('اقرأ من ملفات JSON المحلية بدل الخادم',
      'Read local JSON files instead of the server');
  String get apiBaseUrl => _('رابط الـ API الأساسي', 'API base URL');
  String get apiBaseUrlHint => _(
      'للجهاز الحقيقي استخدم عنوان IP للحاسب، مثل http://192.168.1.20:5080',
      'For a physical device use your PC\'s IP, e.g. http://192.168.1.20:5080');
  String get save => _('حفظ', 'Save');
  String get saved => _('تم الحفظ', 'Saved');

  // Bottom navigation
  String get navCard => _('البطاقة', 'Card');
  String get navSales => _('العمليات', 'Sales');
  String get navPoints => _('النقاط', 'Points');
  String get navProfile => _('حسابي', 'Profile');

  // Rewards / redeem
  String get rewards => _('المكافآت', 'Rewards');
  String get redeemRewards => _('استبدال النقاط', 'Redeem points');
  String get redeem => _('استبدال', 'Redeem');
  String cost(String points) => _('$points نقطة', '$points points');
  String yourBalance(String points) =>
      _('رصيدك $points نقطة', 'Your balance: $points points');
  String get redeemConfirmTitle => _('تأكيد الاستبدال؟', 'Confirm redemption?');
  String redeemConfirmBody(String title, String points) => _(
      'سيتم خصم $points نقطة مقابل "$title".',
      '$points points will be deducted for "$title".');
  String get confirm => _('تأكيد', 'Confirm');
  String get redeemSuccess => _('تم الاستبدال بنجاح 🎉', 'Redeemed successfully 🎉');
  String get notEnoughPoints => _('نقاط غير كافية', 'Not enough points');
  String get noRewards => _('لا توجد مكافآت متاحة', 'No rewards available');
  String get done => _('تم', 'Done');
  String get redeemFailed =>
      _('تعذّر إتمام الاستبدال، حاول مرة أخرى', 'Redemption failed, please try again');
}
