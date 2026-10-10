import 'dart:typed_data';

Future<void> writeBytesToPath(String path, Uint8List bytes) async {
  throw UnsupportedError('ذخیره مستقیم فایل روی این پلتفرم پشتیبانی نمی‌شود');
}

Future<Uint8List> readBytesFromPath(String path) async {
  throw UnsupportedError('خواندن مستقیم فایل روی این پلتفرم پشتیبانی نمی‌شود');
}
