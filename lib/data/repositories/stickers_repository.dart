import '../../core/services/local_database.dart';
import '../../domain/entities/sticker_entities.dart';

class StickersRepository {
  final _db = LocalDatabase.instance;

  Future<List<StickerSurface>> getAllSurfaces() async {
    final items = await _db.readAll(Collections.stickerSurfaces);
    return items.map((m) => StickerSurface.fromMap(m)).toList();
  }

  Future<void> saveAllSurfaces(List<StickerSurface> list) async {
    await _db.writeAll(
      Collections.stickerSurfaces,
      list.map((e) => e.toMap()).toList(),
    );
  }

  Future<String?> getActiveSurfaceId() async {
    final items = await _db.readAll(Collections.stickerActiveId);
    if (items.isEmpty) return null;
    return items.first['id'] as String?;
  }

  Future<void> setActiveSurfaceId(String? id) async {
    if (id == null) {
      await _db.writeAll(Collections.stickerActiveId, []);
      return;
    }
    await _db.writeAll(Collections.stickerActiveId, [
      {'id': id},
    ]);
  }

  Future<StickerSurface> createSurface({
    required String name,
    required SurfaceType type,
  }) async {
    final s = StickerSurface(
      id: _db.generateId(),
      name: name.trim().isEmpty ? type.label : name.trim(),
      type: type,
    );
    final all = await getAllSurfaces();
    all.add(s);
    await saveAllSurfaces(all);
    return s;
  }

  String newId() => _db.generateId();
}
