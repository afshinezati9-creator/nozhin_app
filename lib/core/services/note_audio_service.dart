import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

/// ضبط واقعی صدا برای دفترچه (فایل محلی؛ روی وب محدود)
class NoteAudioService {
  NoteAudioService._();
  static final NoteAudioService instance = NoteAudioService._();

  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;
  DateTime? _startedAt;

  Future<bool> get hasPermission async {
    try {
      return await _recorder.hasPermission();
    } catch (_) {
      return false;
    }
  }

  Future<bool> start() async {
    try {
      if (!await _recorder.hasPermission()) return false;

      if (kIsWeb) {
        // وب: ضبط در حافظه موقت مسیر ساختگی
        _currentPath = 'web_${const Uuid().v4()}.m4a';
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
          path: _currentPath!,
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final folder = Directory('${dir.path}/hawzhin_audio');
        if (!await folder.exists()) await folder.create(recursive: true);
        _currentPath =
            '${folder.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _currentPath!,
        );
      }
      _startedAt = DateTime.now();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('NoteAudio start error: $e');
      return false;
    }
  }

  /// توقف و برگرداندن مسیر/داده برای embed
  Future<Map<String, dynamic>?> stop() async {
    try {
      final path = await _recorder.stop();
      final started = _startedAt;
      _startedAt = null;
      final duration = started == null
          ? 1
          : DateTime.now().difference(started).inSeconds.clamp(1, 99999);

      final resolved = path ?? _currentPath;
      _currentPath = null;
      if (resolved == null) return null;

      // برای پایداری در JSON یادداشت: روی موبایل path فایل؛ در صورت امکان bytes کوتاه base64
      String? dataUrl;
      if (!kIsWeb) {
        try {
          final f = File(resolved);
          if (await f.exists()) {
            final bytes = await f.readAsBytes();
            // فقط فایل‌های کوچک‌تر از ۱.۵MB داخل یادداشت embed می‌شوند
            if (bytes.length <= 1500 * 1024) {
              dataUrl =
                  'data:audio/mp4;base64,${base64Encode(bytes)}';
            }
          }
        } catch (_) {}
      }

      return {
        'path': resolved,
        if (dataUrl != null) 'data': dataUrl,
        'duration': duration,
        'label': 'ضبط صوتی',
        'mime': 'audio/mp4',
      };
    } catch (e) {
      // ignore: avoid_print
      print('NoteAudio stop error: $e');
      return null;
    }
  }

  Future<void> cancel() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
    _currentPath = null;
    _startedAt = null;
  }

  /// ذخیره فایل انتخاب‌شده کاربر
  Future<Map<String, dynamic>?> importBytes(
    Uint8List bytes, {
    String name = 'فایل صوتی',
    String mime = 'audio/mpeg',
  }) async {
    try {
      if (bytes.length > 5 * 1024 * 1024) {
        return {'error': 'حجم فایل بیش از ۵ مگابایت است'};
      }
      String path = '';
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        final folder = Directory('${dir.path}/hawzhin_audio');
        if (!await folder.exists()) await folder.create(recursive: true);
        path =
            '${folder.path}/imp_${DateTime.now().millisecondsSinceEpoch}.bin';
        await File(path).writeAsBytes(bytes, flush: true);
      }
      final dataUrl = bytes.length <= 1500 * 1024
          ? 'data:$mime;base64,${base64Encode(bytes)}'
          : null;
      return {
        if (path.isNotEmpty) 'path': path,
        if (dataUrl != null) 'data': dataUrl,
        'duration': 0,
        'label': name,
        'mime': mime,
      };
    } catch (e) {
      return {'error': '$e'};
    }
  }
}
