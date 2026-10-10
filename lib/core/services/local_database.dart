import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:uuid/uuid.dart';

import 'dart:io' if (dart.library.html) '../utils/io_stub.dart';
import 'package:path_provider/path_provider.dart'
    if (dart.library.html) '../utils/path_provider_stub.dart';

/// نسخهٔ schema داده — برای آپدیت بدون پاک شدن دیتا
const int kDataSchemaVersion = 1;

/// دیتابیس محلی – کاملاً آفلاین
/// روی وب: حافظه موقت
/// روی اندروید/دسکتاپ: فایل JSON فشرده (بدون indent)
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  final _uuid = const Uuid();
  bool _initialized = false;
  final Map<String, List<Map<String, dynamic>>> _memory = {};
  String? _dirPath;

  /// آستانهٔ پارس در isolate (بایت) — برای هزاران رکورد UI را قفل نمی‌کند
  static const int _isolateThreshold = 120000;

  Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        _dirPath = '${appDir.path}/nozhin_data';
        final dir = Directory(_dirPath!);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        await _ensureSchemaMeta();
      } catch (_) {
        _dirPath = null;
      }
    }

    _initialized = true;
  }

  Future<void> _ensureSchemaMeta() async {
    if (_dirPath == null) return;
    try {
      final meta = File('$_dirPath/schema_meta.json');
      if (!await meta.exists()) {
        await meta.writeAsString(
          jsonEncode({
            'version': kDataSchemaVersion,
            'createdAt': DateTime.now().toIso8601String(),
          }),
        );
      } else {
        // نسخهٔ فعلی را نگه می‌داریم — migration بعدی اینجا اضافه می‌شود
        final raw = await meta.readAsString();
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final v = map['version'] as int? ?? 1;
        if (v < kDataSchemaVersion) {
          map['version'] = kDataSchemaVersion;
          map['migratedAt'] = DateTime.now().toIso8601String();
          await meta.writeAsString(jsonEncode(map));
        }
      }
    } catch (_) {}
  }

  String generateId() => _uuid.v4();

  Future<void> _writeFile(
      String collection, List<Map<String, dynamic>> items) async {
    if (_dirPath == null) return;
    try {
      final file = File('$_dirPath/$collection.json');
      // بدون indent → حجم و زمان نوشتن کمتر برای هزاران آیتم
      await file.writeAsString(jsonEncode(items));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _readFile(String collection) async {
    if (_dirPath == null) return [];
    try {
      final file = File('$_dirPath/$collection.json');
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      if (content.length >= _isolateThreshold) {
        return await compute(_parseJsonList, content);
      }
      return _parseJsonList(content);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> readAll(String collection) async {
    await init();
    if (_memory.containsKey(collection)) {
      return List<Map<String, dynamic>>.from(_memory[collection]!);
    }
    if (kIsWeb) {
      _memory[collection] = [];
      return [];
    }
    final items = await _readFile(collection);
    _memory[collection] = items;
    return List<Map<String, dynamic>>.from(items);
  }

  /// فقط n تای اول (پس از کش شدن کل فایل) — برای لیست‌های خیلی بزرگ
  Future<List<Map<String, dynamic>>> readPage(
    String collection, {
    int offset = 0,
    int limit = 80,
  }) async {
    final all = await readAll(collection);
    if (offset >= all.length) return [];
    final end = (offset + limit).clamp(0, all.length);
    return all.sublist(offset, end);
  }

  Future<int> count(String collection) async {
    final all = await readAll(collection);
    return all.length;
  }

  Future<void> writeAll(
      String collection, List<Map<String, dynamic>> items) async {
    await init();
    _memory[collection] = List<Map<String, dynamic>>.from(items);
    if (!kIsWeb) {
      await _writeFile(collection, items);
    }
  }

  Future<void> insert(String collection, Map<String, dynamic> item) async {
    final items = await readAll(collection);
    items.insert(0, item);
    await writeAll(collection, items);
  }

  Future<bool> update(
      String collection, String id, Map<String, dynamic> item) async {
    final items = await readAll(collection);
    final index = items.indexWhere((e) => e['id'] == id);
    if (index < 0) return false;
    items[index] = item;
    await writeAll(collection, items);
    return true;
  }

  Future<bool> delete(String collection, String id) async {
    final items = await readAll(collection);
    final before = items.length;
    items.removeWhere((e) => e['id'] == id);
    if (items.length == before) return false;
    await writeAll(collection, items);
    return true;
  }

  Future<Map<String, dynamic>?> findById(String collection, String id) async {
    final items = await readAll(collection);
    try {
      return items.firstWhere((e) => e['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear(String collection) async {
    await writeAll(collection, []);
  }

  Future<void> clearAll() async {
    await init();
    _memory.clear();
    if (!kIsWeb && _dirPath != null) {
      try {
        final dir = Directory(_dirPath!);
        if (await dir.exists()) {
          await for (final f in dir.list()) {
            if (f is File && f.path.endsWith('.json')) {
              // schema_meta را پاک نکن
              if (f.path.endsWith('schema_meta.json')) continue;
              await f.delete();
            }
          }
        }
      } catch (_) {}
    }
  }
}

/// top-level برای compute
List<Map<String, dynamic>> _parseJsonList(String content) {
  final list = jsonDecode(content) as List<dynamic>;
  return list
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList(growable: false);
}

class Collections {
  static const notes = 'notes';
  static const accounts = 'accounts';
  static const transactions = 'transactions';
  static const debts = 'debts';
  static const installments = 'installments';
  static const finGoals = 'fin_goals';
  static const budgets = 'budgets';
  static const infoItems = 'info_items';
  static const stickerSurfaces = 'sticker_surfaces';
  static const stickerActiveId = 'sticker_active_id';
  static const habits = 'habits';
  static const eisen = 'eisen';
  static const programData = 'program_data';
  static const planningArchives = 'planning_archives';
  static const emergency = 'emergency';
  static const purchaseIntents = 'purchase_intents';
}
