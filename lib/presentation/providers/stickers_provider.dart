import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/stickers_repository.dart';
import '../../domain/entities/sticker_entities.dart';

class StickersState {
  final List<StickerSurface> surfaces;
  final String? activeSurfaceId;
  final bool isLoading;
  final String? error;

  const StickersState({
    this.surfaces = const [],
    this.activeSurfaceId,
    this.isLoading = false,
    this.error,
  });

  StickersState copyWith({
    List<StickerSurface>? surfaces,
    String? activeSurfaceId,
    bool clearActive = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return StickersState(
      surfaces: surfaces ?? this.surfaces,
      activeSurfaceId:
          clearActive ? null : (activeSurfaceId ?? this.activeSurfaceId),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  List<StickerSurface> get activeSurfaces =>
      surfaces.where((s) => !s.archived).toList();

  StickerSurface? get activeSurface {
    final id = activeSurfaceId;
    if (id == null) return null;
    try {
      return surfaces.firstWhere((s) => s.id == id && !s.archived);
    } catch (_) {
      return null;
    }
  }

  int get archiveCount {
    var n = 0;
    for (final s in surfaces) {
      if (s.archived) {
        n += 1 + s.notes.length;
      } else {
        n += s.notes.where((x) => x.archived).length;
      }
    }
    return n;
  }
}

class StickersNotifier extends StateNotifier<StickersState> {
  StickersNotifier() : super(const StickersState()) {
    load();
  }

  final _repo = StickersRepository();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      var list = await _repo.getAllSurfaces();
      if (list.isEmpty) {
        // سطوح پیش‌فرض
        list = [
          StickerSurface(
            id: _repo.newId(),
            name: 'دیوار اتاق',
            type: SurfaceType.wall,
          ),
          StickerSurface(
            id: _repo.newId(),
            name: 'میز کار',
            type: SurfaceType.desk,
          ),
          StickerSurface(
            id: _repo.newId(),
            name: 'یخچال',
            type: SurfaceType.fridge,
          ),
        ];
        await _repo.saveAllSurfaces(list);
      }
      var activeId = await _repo.getActiveSurfaceId();
      final activeList = list.where((s) => !s.archived).toList();
      if (activeId == null || !activeList.any((s) => s.id == activeId)) {
        activeId = activeList.isEmpty ? null : activeList.first.id;
        await _repo.setActiveSurfaceId(activeId);
      }
      state = state.copyWith(
        surfaces: list,
        activeSurfaceId: activeId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setActive(String id) async {
    await _repo.setActiveSurfaceId(id);
    state = state.copyWith(activeSurfaceId: id);
  }

  Future<void> _persist(List<StickerSurface> list) async {
    await _repo.saveAllSurfaces(list);
    state = state.copyWith(surfaces: list);
  }

  Future<StickerSurface> addSurface(String name, SurfaceType type) async {
    final s = await _repo.createSurface(name: name, type: type);
    await load();
    await setActive(s.id);
    return s;
  }

  Future<void> updateSurface(StickerSurface s) async {
    final list = state.surfaces.map((x) => x.id == s.id ? s : x).toList();
    await _persist(list);
  }

  Future<void> archiveSurface(String id, String reason) async {
    final list = state.surfaces.map((s) {
      if (s.id != id) return s;
      return s.copyWith(
        archived: true,
        archiveNote: reason,
        archivedAt: DateTime.now(),
      );
    }).toList();
    await _persist(list);
    final active = list.where((s) => !s.archived).toList();
    final newId = active.isEmpty ? null : active.first.id;
    await _repo.setActiveSurfaceId(newId);
    state = state.copyWith(clearActive: newId == null, activeSurfaceId: newId);
  }

  Future<void> restoreSurface(String id) async {
    final list = state.surfaces.map((s) {
      if (s.id != id) return s;
      return s.copyWith(
        archived: false,
        archiveNote: '',
        clearArchivedAt: true,
      );
    }).toList();
    await _persist(list);
  }

  Future<void> deleteSurface(String id) async {
    final list = state.surfaces.where((s) => s.id != id).toList();
    await _persist(list);
    if (state.activeSurfaceId == id) {
      final active = list.where((s) => !s.archived).toList();
      final newId = active.isEmpty ? null : active.first.id;
      await _repo.setActiveSurfaceId(newId);
      state = state.copyWith(clearActive: newId == null, activeSurfaceId: newId);
    }
  }

  Future<void> addNote(String surfaceId, StickerNote note) async {
    final list = state.surfaces.map((s) {
      if (s.id != surfaceId) return s;
      if (s.activeNotes.length >= 9) return s;
      return s.copyWith(notes: [...s.notes, note]);
    }).toList();
    await _persist(list);
  }

  Future<void> updateNote(String surfaceId, StickerNote note) async {
    final list = state.surfaces.map((s) {
      if (s.id != surfaceId) return s;
      return s.copyWith(
        notes: s.notes.map((n) => n.id == note.id ? note : n).toList(),
      );
    }).toList();
    await _persist(list);
  }

  Future<void> deleteNote(String surfaceId, String noteId) async {
    final list = state.surfaces.map((s) {
      if (s.id != surfaceId) return s;
      return s.copyWith(notes: s.notes.where((n) => n.id != noteId).toList());
    }).toList();
    await _persist(list);
  }

  Future<void> archiveNote(
    String surfaceId,
    String noteId, {
    String reason = '',
  }) async {
    final list = state.surfaces.map((s) {
      if (s.id != surfaceId) return s;
      return s.copyWith(
        notes: s.notes.map((n) {
          if (n.id != noteId) return n;
          return n.copyWith(
            archived: true,
            archiveNote: reason,
            archivedAt: DateTime.now(),
          );
        }).toList(),
      );
    }).toList();
    await _persist(list);
  }

  String newId() => _repo.newId();

  /// جابه‌جایی ترتیب سطوح فعال (مهم‌تر اول)
  Future<void> reorderSurfaces(int oldIndex, int newIndex) async {
    final active = state.activeSurfaces.toList();
    if (oldIndex < 0 || oldIndex >= active.length) return;
    if (newIndex < 0 || newIndex > active.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = active.removeAt(oldIndex);
    active.insert(newIndex, item);
    // ادغام با آرشیوی‌ها در انتها
    final archived = state.surfaces.where((s) => s.archived).toList();
    final list = [...active, ...archived];
    await _persist(list);
  }
}


final stickersProvider =
    StateNotifierProvider<StickersNotifier, StickersState>((ref) {
  return StickersNotifier();
});


/// افزایش = درخواست FAB برای افزودن برچسب
final stickerFabTickProvider = StateProvider<int>((ref) => 0);
