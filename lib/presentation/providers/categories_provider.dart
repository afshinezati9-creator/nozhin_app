import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/security/secure_storage_service.dart';

class CategoriesState {
  final List<String> categories;
  final bool loaded;

  const CategoriesState({
    this.categories = const ['عمومی', 'ایده‌ها', 'کاری', 'شخصی', 'مطالعه'],
    this.loaded = false,
  });

  CategoriesState copyWith({List<String>? categories, bool? loaded}) {
    return CategoriesState(
      categories: categories ?? this.categories,
      loaded: loaded ?? this.loaded,
    );
  }
}

class CategoriesNotifier extends StateNotifier<CategoriesState> {
  CategoriesNotifier() : super(const CategoriesState()) {
    load();
  }

  final _secure = SecureStorageService.instance;

  static const seedDefaults = ['عمومی', 'ایده‌ها', 'کاری', 'شخصی', 'مطالعه'];

  Future<void> load() async {
    try {
      final raw = await _secure.getNoteCategories();
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .map((e) => '$e'.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (list.isEmpty) {
          state = const CategoriesState(
              categories: seedDefaults, loaded: true);
        } else {
          state = CategoriesState(categories: list, loaded: true);
        }
      } else {
        state = const CategoriesState(
            categories: seedDefaults, loaded: true);
      }
    } catch (_) {
      state = const CategoriesState(
          categories: seedDefaults, loaded: true);
    }
  }

  Future<void> _persist() async {
    await _secure.saveNoteCategories(jsonEncode(state.categories));
  }

  Future<bool> add(String name) async {
    final n = name.trim();
    if (n.isEmpty) return false;
    if (state.categories.contains(n)) return false;
    state = state.copyWith(categories: [...state.categories, n]);
    await _persist();
    return true;
  }

  /// همه دسته‌ها قابل حذف‌اند؛ فقط «همه» در فیلتر لیست ثابت است (دسته نیست)
  Future<bool> remove(String name) async {
    if (!state.categories.contains(name)) return false;
    // حداقل یک دسته باقی بماند
    if (state.categories.length <= 1) return false;
    state = state.copyWith(
      categories: state.categories.where((c) => c != name).toList(),
    );
    await _persist();
    return true;
  }

  Future<bool> rename(String oldName, String newName) async {
    final n = newName.trim();
    if (n.isEmpty) return false;
    if (state.categories.contains(n)) return false;
    if (!state.categories.contains(oldName)) return false;
    state = state.copyWith(
      categories: state.categories.map((c) => c == oldName ? n : c).toList(),
    );
    await _persist();
    return true;
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, CategoriesState>((ref) {
  return CategoriesNotifier();
});
