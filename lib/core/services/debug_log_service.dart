import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// دیباگ موقت پیش از انتشار عمومی — بعداً کل این سرویس و UI تنظیمات را حذف کن.
///
/// ثبت خطا، هشدار، زمان مسیر و رویدادهای دستی برای خروجی فایل.
class DebugLogService {
  DebugLogService._();
  static final DebugLogService instance = DebugLogService._();

  static const int maxEntries = 2500;
  static const bool enabled = true; // قبل از انتشار عمومی → false یا حذف سرویس

  final Queue<_LogEntry> _entries = Queue<_LogEntry>();
  final Map<String, DateTime> _routeStart = {};

  int get count => _entries.length;

  void info(String message, {String? cause, String? tag}) =>
      _add('INFO', message, cause: cause, tag: tag);

  void warn(String message, {String? cause, String? tag}) =>
      _add('WARN', message, cause: cause, tag: tag);

  void error(String message, {String? cause, String? tag, Object? error, StackTrace? stack}) {
    final c = [
      if (cause != null) cause,
      if (error != null) error.toString(),
      if (stack != null) stack.toString().split('\n').take(12).join('\n'),
    ].where((e) => e.isNotEmpty).join('\n');
    _add('ERROR', message, cause: c.isEmpty ? null : c, tag: tag);
  }

  void perf(String message, {required Duration duration, String? tag}) {
    _add(
      'PERF',
      message,
      cause: 'مدت: ${duration.inMilliseconds} ms',
      tag: tag ?? 'perf',
    );
  }

  void event(String message, {String? cause, String? tag}) =>
      _add('EVENT', message, cause: cause, tag: tag);

  void _add(String level, String message, {String? cause, String? tag}) {
    if (!enabled) return;
    final e = _LogEntry(
      time: DateTime.now(),
      level: level,
      message: message,
      cause: cause,
      tag: tag,
    );
    _entries.addLast(e);
    while (_entries.length > maxEntries) {
      _entries.removeFirst();
    }
    if (kDebugMode) {
      debugPrint('[NozhinDebug][${e.level}] ${e.message}'
          '${e.cause != null ? ' | ${e.cause}' : ''}');
    }
  }

  void clear() => _entries.clear();

  /// متن کامل برای فایل خروجی
  String exportText() {
    final buf = StringBuffer();
    buf.writeln('═══════════════════════════════════════════════');
    buf.writeln('نوژین — گزارش دیباگ (موقت، قبل از انتشار عمومی)');
    buf.writeln('تولید: ${DateTime.now().toIso8601String()}');
    buf.writeln('تعداد رکورد: ${_entries.length}');
    buf.writeln('پلتفرم: ${kIsWeb ? 'web' : defaultTargetPlatform.name}');
    buf.writeln('═══════════════════════════════════════════════');
    buf.writeln();
    if (_entries.isEmpty) {
      buf.writeln('(لاگی ثبت نشده — بعد از کار با اپ دوباره خروجی بگیر)');
      return buf.toString();
    }
    for (final e in _entries) {
      buf.writeln('---');
      buf.writeln('زمان: ${_fmt(e.time)}');
      buf.writeln('سطح: ${e.level}');
      if (e.tag != null) buf.writeln('برچسب: ${e.tag}');
      buf.writeln('پیام: ${e.message}');
      if (e.cause != null && e.cause!.isNotEmpty) {
        buf.writeln('علت / جزئیات:');
        buf.writeln(e.cause);
      }
      buf.writeln();
    }
    buf.writeln('═══════════════════════════════════════════════');
    buf.writeln('پایان گزارش');
    return buf.toString();
  }

  String _fmt(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${t.millisecond.toString().padLeft(3, '0')}';
  }

  void onRoutePush(String name) {
    _routeStart[name] = DateTime.now();
    event('ورود به مسیر: $name', tag: 'nav');
  }

  void onRouteSettled(String name) {
    final start = _routeStart.remove(name);
    if (start != null) {
      final d = DateTime.now().difference(start);
      perf('آماده شدن مسیر: $name', duration: d, tag: 'nav');
      if (d.inMilliseconds > 800) {
        warn(
          'بارگذاری کند مسیر: $name',
          cause: 'بیش از ${d.inMilliseconds} ms — احتمال ویجت سنگین یا IO',
          tag: 'nav',
        );
      }
    }
  }

  void onRoutePop(String name) {
    event('خروج از مسیر: $name', tag: 'nav');
    _routeStart.remove(name);
  }

  /// اتصال به Flutter framework
  void installGlobalHandlers() {
    if (!enabled) return;
    info('دیباگ فعال شد', tag: 'boot');

    FlutterError.onError = (details) {
      error(
        'FlutterError: ${details.exceptionAsString()}',
        cause: details.stack?.toString(),
        tag: 'flutter',
        error: details.exception,
        stack: details.stack,
      );
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      this.error(
        'Zone/Platform error',
        error: error,
        stack: stack,
        tag: 'platform',
      );
      return true;
    };
  }
}

class _LogEntry {
  final DateTime time;
  final String level;
  final String message;
  final String? cause;
  final String? tag;
  _LogEntry({
    required this.time,
    required this.level,
    required this.message,
    this.cause,
    this.tag,
  });
}

/// مشاهده‌گر ناوبری برای زمان بار مسیر
class DebugNavigatorObserver extends NavigatorObserver {
  String _name(Route<dynamic>? route) =>
      route?.settings.name ?? route?.runtimeType.toString() ?? '?';

  @override
  void didPush(Route route, Route? previousRoute) {
    final n = _name(route);
    DebugLogService.instance.onRoutePush(n);
    // بعد از فریم اول «settled» تقریبی
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DebugLogService.instance.onRouteSettled(n);
    });
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    DebugLogService.instance.onRoutePop(_name(route));
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute != null) {
      final n = _name(newRoute);
      DebugLogService.instance.onRoutePush(n);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugLogService.instance.onRouteSettled(n);
      });
    }
  }
}
