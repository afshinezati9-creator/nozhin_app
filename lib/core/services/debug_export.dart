import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/io_stub.dart' if (dart.library.io) 'dart:io';
import 'debug_log_service.dart';
import 'package:path_provider/path_provider.dart';

/// خروجی فایل لاگ — وب: کلیپ‌بورد؛ بومی: فایل در Documents
class DebugExport {
  static Future<DebugExportResult> export() async {
    final text = DebugLogService.instance.exportText();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final name = 'nozhin_debug_$stamp.txt';

    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: text));
      return DebugExportResult(
        ok: true,
        pathOrHint: 'متن لاگ در کلیپ‌بورد کپی شد (وب). در نوت‌پد Paste کن و ذخیره کن.',
        textPreview: text,
        fileName: name,
      );
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$name';
      final file = File(path);
      await file.writeAsString(text);
      DebugLogService.instance.info('خروجی دیباگ ذخیره شد', cause: path, tag: 'debug');
      return DebugExportResult(
        ok: true,
        pathOrHint: path,
        textPreview: text,
        fileName: name,
      );
    } catch (e, st) {
      DebugLogService.instance.error('خطا در ذخیره فایل دیباگ', error: e, stack: st);
      await Clipboard.setData(ClipboardData(text: text));
      return DebugExportResult(
        ok: false,
        pathOrHint: 'ذخیره فایل ناموفق — متن در کلیپ‌بورد کپی شد. $e',
        textPreview: text,
        fileName: name,
      );
    }
  }
}

class DebugExportResult {
  final bool ok;
  final String pathOrHint;
  final String textPreview;
  final String fileName;
  DebugExportResult({
    required this.ok,
    required this.pathOrHint,
    required this.textPreview,
    required this.fileName,
  });
}
