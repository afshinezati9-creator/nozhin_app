# ساخت APK فقط با GitHub Actions (ایران / تحریم)

روی سیستم خودت لازم نیست Android SDK از گوگل دانلود شود.
Runnerهای GitHub خارج از ایران‌اند و بیلد را آنجا انجام می‌دهند.

## ۱) کد را push کن
```bat
git add .github/workflows/flutter_ci.yml
git commit -m "CI: APK-only job for sanctioned regions"
git pull --rebase origin main
git push origin main
```

## ۲) اجرای دستی (اگر push صف runner نگرفت)
1. https://github.com/afshinezati9-creator/nozhin_app/actions
2. سمت چپ: **Flutter CI**
3. **Run workflow** → Branch `main` → **Run workflow**
4. ۱۰ تا ۲۰ دقیقه صبر کن؛ صفحه را مدام رفرش نکن

## ۳) دانلود APK
وقتی job سبز شد:
- Summary → **Artifacts** → `nozhin-debug-apk`
- ZIP را باز کن → `app-debug.apk` را روی گوشی نصب کن

## اگر باز خطای runner دیدی
پیام‌هایی مثل:
- `job was not acquired by Runner`
- `Internal server error`

یعنی **کد خراب نیست**؛ صف GitHub شلوغ است.
۱–۲ ساعت بعد دوباره **Run workflow** بزن (روز کمتر شلوغ‌تر است، مثلاً صبح زود یا نیمه‌شب).

## مهم
- وسط بیلد دوباره push نکن
- فقط یک workflow در حال اجرا بگذار
