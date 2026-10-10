# ساخت APK هاوژین (فقط Release)

```bat
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

خروجی:
`build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`

تغییر نام پیشنهادی:
```bat
copy build\app\outputs\flutter-apk\app-arm64-v8a-release.apk Hawzhin-1.0.0.apk
```

**دیباگ ساخته نمی‌شود و توصیه نمی‌شود** — حجم بالا و برای نصب نهایی مناسب نیست.
