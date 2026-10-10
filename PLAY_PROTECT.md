# Google Play Protect و نصب هاوژین

پیام «App blocked to protect your device» برای اپ‌هایی است که:
- از فروشگاه Play نصب نشده‌اند
- امضای انتشار رسمی و سابقه در Google ندارند
- یا APK دیباگ هستند

## این باگ اپ نیست
Play Protect ناشناس بودن توسعه‌دهنده را هشدار می‌دهد. برای نصب:
1. روی **Install anyway** بزن (گاهی زیر Learn more)
2. یا Settings → Security → Google Play Protect → گزینه‌های نصب از منابع ناشناس

## وقتی هشدار کمتر می‌شود
- انتشار در **Google Play** یا **بازار**
- امضای release ثابت (نه debug keystore)
- APK از نوع `flutter build apk --release --split-per-abi`

کد اپ نمی‌تواند این دیالوگ را غیرفعال کند؛ فقط انتشار رسمی آن را برطرف می‌کند.
