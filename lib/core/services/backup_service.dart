import 'dart:convert';
import 'local_database.dart';

/// پشتیبان‌گیری آفلاین — JSON کامل با امکان رمز ساده روی PIN
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  final _db = LocalDatabase.instance;

  static const _collections = [
    Collections.notes,
    Collections.accounts,
    Collections.transactions,
    Collections.debts,
    Collections.installments,
    Collections.finGoals,
    Collections.purchaseIntents,
    Collections.budgets,
    Collections.infoItems,
    Collections.stickerSurfaces,
    Collections.stickerActiveId,
    Collections.habits,
    Collections.eisen,
    Collections.programData,
    Collections.planningArchives,
    Collections.emergency,
  ];

  /// ساخت داده پشتیبان (بدون رمز کارت)
  Future<Map<String, dynamic>> buildBackupData() async {
    final data = <String, dynamic>{
      '_meta': {
        'app': 'nozhin',
        'version': '1.0.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'encrypted': false,
      },
    };

    for (final c in _collections) {
      var items = await _db.readAll(c);
      if (c == Collections.infoItems) {
        items = items.map(_stripCardPassword).toList();
      }
      data[c] = items;
    }
    return data;
  }

  Map<String, dynamic> _stripCardPassword(Map<String, dynamic> item) {
    final m = Map<String, dynamic>.from(item);
    final card = m['card'];
    if (card is Map) {
      final cm = Map<String, dynamic>.from(card);
      cm['password'] = '';
      m['card'] = cm;
    }
    return m;
  }

  Future<String> exportJsonString({String? pin}) async {
    final data = await buildBackupData();
    var raw = const JsonEncoder.withIndent('  ').convert(data);
    if (pin != null && pin.length >= 4) {
      final enc = _xorCrypt(raw, pin);
      final wrapper = {
        '_meta': {
          'app': 'nozhin',
          'version': '1.0.0',
          'exportedAt': DateTime.now().toIso8601String(),
          'encrypted': true,
        },
        'payload': base64.encode(utf8.encode(enc)),
      };
      return const JsonEncoder.withIndent('  ').convert(wrapper);
    }
    return raw;
  }

  Future<void> importJsonString(String content, {String? pin}) async {
    final data = jsonDecode(content) as Map<String, dynamic>;
    Map<String, dynamic> payload = data;

    if (data['_meta'] is Map &&
        (data['_meta'] as Map)['encrypted'] == true &&
        data['payload'] is String) {
      if (pin == null || pin.length < 4) {
        throw Exception('این بک‌آپ رمزگذاری شده — PIN لازم است');
      }
      final decoded = utf8.decode(base64.decode(data['payload'] as String));
      final plain = _xorCrypt(decoded, pin);
      payload = jsonDecode(plain) as Map<String, dynamic>;
    }

    if (payload['_meta'] == null) {
      throw Exception('فایل پشتیبان معتبر نیست');
    }

    await _db.clearAll();
    for (final c in _collections) {
      final items = payload[c];
      if (items is List) {
        final maps = items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .map((e) => c == Collections.infoItems ? _stripCardPassword(e) : e)
            .toList();
        await _db.writeAll(c, maps);
      }
    }
  }

  /// XOR ساده با کلید تکرارشونده — برای موبایل آفلاین کافی است
  String _xorCrypt(String input, String key) {
    final kb = key.codeUnits;
    final out = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      out.writeCharCode(input.codeUnitAt(i) ^ kb[i % kb.length]);
    }
    return out.toString();
  }

  /// سازگاری قدیمی — در وب ممکن است fail شود
  Future<String> exportToTempFile() async {
    return exportJsonString();
  }
}

