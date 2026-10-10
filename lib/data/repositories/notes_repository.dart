import '../../core/services/local_database.dart';
import '../../domain/entities/note_entity.dart';

class NotesRepository {
  final _db = LocalDatabase.instance;

  NoteEntity _fromMap(Map<String, dynamic> m) {
    return NoteEntity(
      id: m['id'] as String,
      title: m['title'] as String? ?? '',
      body: m['body'] as String? ?? '',
      category: m['category'] as String? ?? 'عمومی',
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(m['updatedAt'] as String? ?? '') ?? DateTime.now(),
      pinned: m['pinned'] as bool? ?? false,
      color: m['color'] as String? ?? 'blue',
      direction: m['direction'] as String? ?? 'rtl',
      tags: (m['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> _toMap(NoteEntity n) {
    return {
      'id': n.id,
      'title': n.title,
      'body': n.body,
      'category': n.category,
      'createdAt': n.createdAt.toIso8601String(),
      'updatedAt': n.updatedAt.toIso8601String(),
      'pinned': n.pinned,
      'color': n.color,
      'direction': n.direction,
      'tags': n.tags,
    };
  }

  Future<List<NoteEntity>> getAll() async {
    final items = await _db.readAll(Collections.notes);
    return items.map(_fromMap).toList();
  }

  Future<NoteEntity?> getById(String id) async {
    final m = await _db.findById(Collections.notes, id);
    if (m == null) return null;
    return _fromMap(m);
  }

  Future<NoteEntity> create({
    String title = '',
    String body = '',
    String category = 'عمومی',
    String color = 'blue',
  }) async {
    final now = DateTime.now();
    final note = NoteEntity(
      id: _db.generateId(),
      title: title,
      body: body,
      category: category,
      createdAt: now,
      updatedAt: now,
      color: color,
    );
    await _db.insert(Collections.notes, _toMap(note));
    return note;
  }

  Future<NoteEntity> duplicate(NoteEntity source) async {
    final now = DateTime.now();
    final note = NoteEntity(
      id: _db.generateId(),
      title: '${source.title.isEmpty ? "بدون عنوان" : source.title} (کپی)',
      body: source.body,
      category: source.category,
      createdAt: now,
      updatedAt: now,
      pinned: false,
      color: source.color,
      direction: source.direction,
      tags: List.from(source.tags),
    );
    await _db.insert(Collections.notes, _toMap(note));
    return note;
  }

  Future<void> update(NoteEntity note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    await _db.update(Collections.notes, note.id, _toMap(updated));
  }

  Future<void> delete(String id) async {
    await _db.delete(Collections.notes, id);
  }

  Future<void> togglePin(String id) async {
    final note = await getById(id);
    if (note == null) return;
    await update(note.copyWith(pinned: !note.pinned));
  }
}
