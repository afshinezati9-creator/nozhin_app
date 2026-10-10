# ارسال به GitHub و ساخت اپ اندروید — هاوژین

ریپوی شما: `https://github.com/afshinezati9-creator/nozhin_app`

## الف) اولین push از ویندوز

در PowerShell یا CMD (پوشه‌ای که داخلش `lib` و `pubspec.yaml` است):

```bat
cd C:\Users\1\Desktop\nozhin_app

git init
git add .
git commit -m "Initial Hawzhin Flutter app"
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

- خطای FATAL در لاگ نبود.
- اولین مسیر `/` حدود ۱ ثانیه طول کشید (روی ریلیز اندروید معمولاً بهتر است).
- بقیه مسیرها زیر ۸۰۰ms بودند.

## و) قبل از انتشار عمومی


## ز) GitHub Actions (بعد از push)

1. پوشه workflow را هم push کن:
   ```
   git add .github/workflows/flutter_ci.yml
   git commit -m "Add Flutter CI workflow"
   git push
   ```
2. در گیت‌هاب برو به **Actions** → باید workflow **Flutter CI** اجرا شود.
3. بعد از سبز شدن job **Build APK**، از بخش Artifacts فایل `Hawzhin-APK` را دانلود کن.

**مهم:** این APK از نوع release است. برای پلی استور هنوز باید روی سیستم خودت `flutter build appbundle --release` با keystore بزنی.

روی صفحه "Get started with GitHub Actions" لازم نیست workflow پیشنهادی **Dart** را Configure کنی — همان فایل `flutter_ci.yml` کافی است.
