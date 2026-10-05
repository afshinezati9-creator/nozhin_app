# ارسال به GitHub و ساخت اپ اندروید — نوژین

ریپوی شما: `https://github.com/afshinezati9-creator/nozhin_app`

## الف) اولین push از ویندوز

در PowerShell یا CMD (پوشه‌ای که داخلش `lib` و `pubspec.yaml` است):

```bat
cd C:\Users\1\Desktop\nozhin_app

git init
git add .
git commit -m "Initial Nozhin Flutter app"
git branch -M main
git remote add origin https://github.com/afshinezati9-creator/nozhin_app.git
git push -u origin main
```

اگر remote از قبل بود:

```bat
git remote set-url origin https://github.com/afshinezati9-creator/nozhin_app.git
git push -u origin main
```

**نفرست:** فایل‌های `*.jks`، `key.properties`، رمزها.  
`.gitignore` پروژه معمولاً build و `.dart_tool` را نادیده می‌گیرد.

## ب) ساخت اسکلت اندروید (یک‌بار)

اگر پوشه `android` ندارید:

```bat
cd C:\Users\1\Desktop\nozhin_app
flutter create . --org com.nozhin --project-name nozhin
flutter pub get
```

بعد دوباره commit و push:

```bat
git add .
git commit -m "Add Android platform"
git push
```

## ج) تست روی گوشی / امولاتور

```bat
flutter devices
flutter run
```

اثرانگشت فقط روی دستگاه واقعی معنی‌دار است.

## د) نسخه انتشار (Google Play / بازار)

1. ساخت keystore (یک‌بار) — طبق مستند رسمی Flutter Signing  
2. `flutter build appbundle --release`  
3. فایل `build/app/outputs/bundle/release/app-release.aab` را در کنسول پلی آپلود کنید  

جزئیات امنیت: `ANDROID_PLAY_SECURITY.md`

## ه) گزارش دیباگ شما (وب)

- خطای FATAL در لاگ نبود.
- اولین مسیر `/` حدود ۱ ثانیه طول کشید (روی وب debug طبیعی است؛ روی ریلیز اندروید معمولاً بهتر است).
- بقیه مسیرها زیر ۸۰۰ms بودند.

## و) قبل از انتشار عمومی

- بخش «دیباگ (موقت)» و فایل‌های `debug_log_service` / `debug_export` را حذف کنید (`DEBUG_REMOVE_BEFORE_RELEASE.md`).
