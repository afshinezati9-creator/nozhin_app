# هاوژین · Hawzhin

اپ آفلاین فارسی برای:

- **دفترچه** یادداشت غنی
- **مالی** (حساب، تراکنش، بودجه، اهداف، قصد خرید)
- **دم‌دستی** (اطلاعات مهم)
- **استیکی‌نت**

## سازنده

**افشین عزتی (Afshin Ezzati)**  
ایمیل پشتیبانی و بازخورد: **afshinezati9@gmail.com**

هر نقد، گزارش باگ یا پیشنهاد را به همین ایمیل بفرستید.

## ساخت APK (Release)

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

خروجی: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`  
نام پیشنهادی: `Hawzhin-1.1.0.apk`

GitHub Actions روی `main` همین بیلد را با نام `Hawzhin-*.apk` منتشر می‌کند.

## هویت فنی (پایداری داده)

- Package: `com.nozhin.nozhin`
- نام نمایشی UI: هاوژین / Hawzhin
