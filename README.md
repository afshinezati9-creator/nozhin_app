# نوژین (Nozhin)

دستیار زندگی آفلاین — Flutter · فارسی · RTL

## تب‌ها
یادداشت · مالی · توسعه فردی · اطلاعات · برچسب

## راه‌اندازی
```bash
flutter pub get
flutter run
```

اگر پوشه `android` نیست:
```bash
flutter create . --org com.nozhin --project-name nozhin
```

## گیت‌هاب و اپ اندروید
راهنمای کامل: **[GITHUB_ANDROID.md](GITHUB_ANDROID.md)**  
امنیت پلی: **[ANDROID_PLAY_SECURITY.md](ANDROID_PLAY_SECURITY.md)**

## دیباگ موقت
تنظیمات → دیباگ → خروجی فایل لاگ  
قبل از انتشار عمومی حذف شود: `DEBUG_REMOVE_BEFORE_RELEASE.md`


---

# نوژین (Nozhin) – دستیار هوشمند زندگی

نسخه حرفه‌ای آفلاین | ساخته‌شده با Flutter

## فاز فعلی: فاز ۱ – اسکلت پروژه و سیستم طراحی

### ساختار پروژه

```
lib/
├── core/
│   ├── theme/          → رنگ‌ها، تایپوگرافی، شعاع، سایه، تم
│   ├── constants/      → ثابت‌ها و متن‌ها
│   ├── utils/          → اکستنشن‌ها
│   └── widgets/        → کامپوننت‌های پایه مشترک
├── data/               → (فاز ۲)
├── domain/             → (فاز ۲)
├── presentation/
│   ├── providers/      → مدیریت state (Riverpod)
│   ├── screens/        → صفحات اصلی
│   └── widgets/        → ویجت‌های مخصوص صفحات
└── main.dart
```

### نحوه راه‌اندازی

1. Flutter را نصب داشته باش (نسخه ۳.۱۶ به بالا توصیه می‌شود).
2. در پوشه پروژه دستور زیر را بزن:

```bash
flutter pub get
```

3. فونت وزیرمتن را دانلود کن و در پوشه `assets/fonts/` قرار بده:
   - Vazirmatn-Regular.ttf
   - Vazirmatn-Medium.ttf
   - Vazirmatn-SemiBold.ttf
   - Vazirmatn-Bold.ttf
   - Vazirmatn-ExtraBold.ttf
   - Vazirmatn-Black.ttf

   لینک دانلود: https://github.com/rastikerdar/vazirmatn/releases

4. اجرا:

```bash
flutter run
```

### چیزهایی که در این فاز آماده شده

- سیستم طراحی کامل (رنگ‌ها، فاصله‌ها، شعاع، سایه، تایپوگرافی) دقیقاً مطابق دمو
- پشتیبانی Dark / Light / System
- تغییر اندازه فونت (کوچک / متوسط / بزرگ)
- هدر با لوگو و دکمه‌های تم و تنظیمات
- ناوبری تب‌های اصلی (یادداشت، مالی، برنامه، اطلاعات)
- FAB گرادیانی
- صفحه تنظیمات پایه (تم + فونت + درباره)
- کامپوننت‌های مشترک: Card، Chip، Button، EmptyState، Header
- RTL کامل
- ساختار Clean Architecture آماده برای فازهای بعدی

### نکات مهم

- فونت هنوز محلی نیست (در pubspec تعریف شده اما فایل‌ها باید اضافه شوند). تا اضافه کردن فایل‌ها ممکن است فونت پیش‌فرض استفاده شود.
- ذخیره‌سازی تنظیمات هنوز در حافظه است (در فاز ۲ به Secure Storage و Isar منتقل می‌شود).
- صفحات اصلی فعلاً placeholder هستند و در فازهای بعدی پر می‌شوند.
