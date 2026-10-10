/// تمام متن‌های ثابت اپ
class AppStrings {
  AppStrings._();

  // Tabs — ترتیب روان‌شناختی: دم‌دستی | مالی | دفترچه | برچسب
  static const String tabHandy = 'دم‌دستی';
  static const String tabFinance = 'مالی';
  static const String tabNotes = 'دفترچه';
  static const String tabStickers = 'استیکی‌نت';

  // سازگاری با کدهای قدیمی (در صورت ارجاع)
  static const String tabInfo = tabHandy;
  static const String tabPlanning = 'توسعه فردی'; // دیگر در شل نیست

  // Common
  static const String save = 'ذخیره';
  static const String cancel = 'لغو';
  static const String delete = 'حذف';
  static const String edit = 'ویرایش';
  static const String search = 'جستجو...';
  static const String confirm = 'تأیید';
  static const String close = 'بستن';
  static const String add = 'افزودن';
  static const String empty = 'موردی وجود ندارد';
  static const String loading = 'در حال بارگذاری...';
  static const String error = 'خطایی رخ داد';
  static const String success = 'موفق';
  static const String retry = 'تلاش مجدد';

  // Settings
  static const String settings = 'تنظیمات';
  static const String theme = 'حالت نمایش';
  static const String themeLight = 'روشن';
  static const String themeDark = 'تاریک';
  static const String themeSystem = 'سیستم';
  static const String fontSize = 'اندازه فونت';
  static const String fontSmall = 'کوچک';
  static const String fontMedium = 'متوسط';
  static const String fontLarge = 'بزرگ';
  static const String profile = 'پروفایل';
  static const String yourName = 'نام شما';
  static const String data = 'داده‌ها';
  static const String exportData = 'خروجی پشتیبان';
  static const String importData = 'بازیابی از پشتیبان';
  static const String clearAllData = 'پاک کردن همه داده‌ها';
  static const String about = 'درباره';

  // Notes
  static const String notesTitle = 'دفترچه';
  static const String newNote = 'یادداشت جدید';
  static const String pinned = 'سنجاق‌شده';
  static const String allNotes = 'همه';

  // Finance
  static const String financeTitle = 'مالی';
  static const String netWorth = 'ارزش خالص';
  static const String accounts = 'حساب‌ها';
  static const String transactions = 'تراکنش‌ها';
  static const String budgets = 'بودجه';
  static const String debts = 'بدهی و طلب';
  static const String goals = 'اهداف مالی';
  static const String installments = 'اقساط';

  // Handy (former Info)
  static const String infoTitle = 'دم‌دستی';
  static const String newInfo = 'آیتم جدید';

  // Stickers
  static const String stickersTitle = 'برچسب';
}
