import '../../core/services/local_database.dart';
import '../../domain/entities/info_item_entity.dart';

class InfoRepository {
  final _db = LocalDatabase.instance;

  InfoItemEntity _fromMap(Map<String, dynamic> m) {
    final type = InfoItemTypeX.fromKey(m['type'] as String?);
    CardDetails? card;
    if (type == InfoItemType.card) {
      final raw = m['card'];
      if (raw is Map<String, dynamic>) {
        card = CardDetails.fromMap(raw);
      } else if (raw is Map) {
        card = CardDetails.fromMap(Map<String, dynamic>.from(raw));
      } else {
        // سازگاری با دمو قدیمی: value = شماره کارت
        card = CardDetails(
          cardNumber: (m['value'] as String? ?? '').replaceAll(RegExp(r'\D'), ''),
          holderName: m['title'] as String? ?? '',
        );
      }
    }

    return InfoItemEntity(
      id: m['id'] as String,
      title: m['title'] as String? ?? '',
      type: type,
      value: m['value'] as String? ?? '',
      card: card,
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(m['updatedAt'] as String? ?? '') ?? DateTime.now(),
      uses: (m['uses'] as num?)?.toInt() ?? 0,
      color: m['color'] as String? ?? 'blue',
    );
  }

  Map<String, dynamic> _toMap(InfoItemEntity e) {
    return {
      'id': e.id,
      'title': e.title,
      'type': e.type.key,
      'value': e.value,
      if (e.card != null) 'card': e.card!.toMap(),
      'createdAt': e.createdAt.toIso8601String(),
      'updatedAt': e.updatedAt.toIso8601String(),
      'uses': e.uses,
      'color': e.color,
    };
  }

  Future<List<InfoItemEntity>> getAll() async {
    final items = await _db.readAll(Collections.infoItems);
    final list = items.map(_fromMap).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<InfoItemEntity?> getById(String id) async {
    final m = await _db.findById(Collections.infoItems, id);
    if (m == null) return null;
    return _fromMap(m);
  }

  Future<InfoItemEntity> create({
    required String title,
    required InfoItemType type,
    String value = '',
    CardDetails? card,
    String color = 'blue',
  }) async {
    final now = DateTime.now();
    final item = InfoItemEntity(
      id: _db.generateId(),
      title: title.trim().isEmpty ? type.label : title.trim(),
      type: type,
      value: value,
      card: type == InfoItemType.card ? (card ?? const CardDetails()) : null,
      createdAt: now,
      updatedAt: now,
      color: color,
    );
    await _db.insert(Collections.infoItems, _toMap(item));
    return item;
  }

  Future<void> update(InfoItemEntity item) async {
    final updated = item.copyWith(updatedAt: DateTime.now());
    await _db.update(Collections.infoItems, item.id, _toMap(updated));
  }

  Future<void> delete(String id) async {
    await _db.delete(Collections.infoItems, id);
  }

  Future<void> incrementUses(String id) async {
    final item = await getById(id);
    if (item == null) return;
    await update(item.copyWith(uses: item.uses + 1));
  }
}
