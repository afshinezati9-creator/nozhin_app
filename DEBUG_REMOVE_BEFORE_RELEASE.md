# حذف دیباگ قبل از انتشار عمومی

فایل‌ها و ارجاع‌ها:
- `lib/core/services/debug_log_service.dart`
- `lib/core/services/debug_export.dart`
- ارجاع در `lib/main.dart` (installGlobalHandlers + navigatorObservers)
- بخش «دیباگ (موقت)» در `settings_screen.dart`

پس از حذف، `flutter analyze` بزن.
