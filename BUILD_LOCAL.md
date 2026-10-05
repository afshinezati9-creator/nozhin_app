# ساخت APK روی ویندوز (بدون وابستگی به GitHub Actions)

اگر CI لغو شد یا کند بود، همین‌جا بساز:

```bat
cd C:\Users\1\Desktop\nozhin_app
flutter pub get
flutter doctor
flutter build apk --debug
```

فایل خروجی:
```
C:\Users\1\Desktop\nozhin_app\build\app\outputs\flutter-apk\app-debug.apk
```

نصب روی گوشی:
1. APK را با کابل یا تلگرام به گوشی بفرست
2. نصب از منابع ناشناس را موقتاً اجازه بده
3. نصب کن

نسخه release (برای پلی استور بعداً):
```bat
flutter build appbundle --release
```

نیازمندی:
- Android SDK / cmdline-tools نصب باشد (`flutter doctor` باید Android toolchain را OK نشان دهد)
