import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/notes_repository.dart';
import '../../domain/entities/note_entity.dart';

enum NotesSort { newest, oldest, pinned }

class NotesState {
  final List<NoteEntity> notes;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final NotesSort sort;
  final String? selectedCategory;

  const NotesState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.sort = NotesSort.newest,
    this.selectedCategory,
  });

  NotesState copyWith({
    List<NoteEntity>? notes,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
    NotesSort? sort,
    String? selectedCategory,
    bool clearCategory = false,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      sort: sort ?? this.sort,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
    );
  }

  List<NoteEntity> get filtered {
    var list = List<NoteEntity>.from(notes);

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.body.toLowerCase().contains(q) ||
              n.category.toLowerCase().contains(q))
          .toList();
    }

    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      list = list.where((n) => n.category == selectedCategory).toList();
    }

    switch (sort) {
      case NotesSort.newest:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case NotesSort.oldest:
        list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case NotesSort.pinned:
        list.sort((a, b) {
          if (a.pinned && !b.pinned) return -1;
          if (!a.pinned && b.pinned) return 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
        break;
    }

    return list;
  }

  List<NoteEntity> get pinnedNotes =>
      filtered.where((n) => n.pinned).toList();

  List<NoteEntity> get unpinnedNotes =>
      filtered.where((n) => !n.pinned).toList();

  int get totalCount => notes.length;
}

class NotesNotifier extends StateNotifier<NotesState> {
  NotesNotifier() : super(const NotesState(isLoading: true)) {
    // بعد از اولین فریم تا اسپلش/شل قفل نشود
    Future.microtask(load);
  }

  final _repo = NotesRepository();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final notes = await _repo.getAll();
      // مرتب‌سازی یک‌بار در لود برای لیست‌های خیلی بزرگ
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = state.copyWith(notes: notes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSort(NotesSort sort) {
    state = state.copyWith(sort: sort);
  }

  void setCategory(String? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  Future<NoteEntity> createNote({String title = '', String body = ''}) async {
    final note = await _repo.create(title: title, body: body);
    await load();
    return note;
  }

  Future<void> updateNote(NoteEntity note) async {
    await _repo.update(note);
    await load();
  }

  Future<void> deleteNote(String id) async {
    await _repo.delete(id);
    await load();
  }

  Future<void> togglePin(String id) async {
    await _repo.togglePin(id);
    await load();
  }

  Future<NoteEntity?> duplicateNote(String id) async {
    final matches = state.notes.where((n) => n.id == id);
    if (matches.isEmpty) return null;
    final copy = await _repo.duplicate(matches.first);
    await load();
    return copy;
  }
}

final notesProvider =
    StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  return NotesNotifier();
});
