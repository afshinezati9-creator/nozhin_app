/// ثابت‌های سراسری اپ — هاوژین
class AppConstants {
  AppConstants._();

  static const String appName = 'هاوژین';
  static const String appNameEn = 'Hawzhin';
  static const String appTagline = 'همراه آرام زندگی روزمره';
  static const String appVersion = '1.1.0';
  static const String appBuild = '2';

  static const String developerName = 'افشین عزتی';
  static const String developerNameEn = 'Afshin Ezzati';
  static const String supportEmail = 'afshinezati9@gmail.com';
  /// کارت بانکی — فقط بعد از لمس کاربر در UI نشان داده می‌شود
  static const String supportCardNumber = '6219861939293428';
  static const String aboutBlurb =
      'هاوژین را برای کار روزمره خودم و اطرافیانم نوشتم: یادداشت، حساب‌وکتاب، '
      'اطلاعات دم‌دست و برچسب‌های روی میز کار. همه چیز روی گوشی می‌ماند و '
      'برای باز شدن به اینترنت وابسته نیست.';

  // Storage keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyFontSize = 'font_size';
  static const String keyUserName = 'user_name';
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyAppLockEnabled = 'app_lock_enabled';
  static const String keyAppLockPin = 'app_lock_pin';

  // Font size factors
  static const double fontSizeSmall = 0.9;
  static const double fontSizeMedium = 1.0;
  static const double fontSizeLarge = 1.15;
}
