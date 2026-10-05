import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/info_repository.dart';
import '../../domain/entities/info_item_entity.dart';

class InfoState {
  final List<InfoItemEntity> items;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  /// null = همه
  final InfoItemType? filterType;

  const InfoState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.filterType,
  });

  InfoState copyWith({
    List<InfoItemEntity>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
    InfoItemType? filterType,
    bool clearFilter = false,
  }) {
    return InfoState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      filterType: clearFilter ? null : (filterType ?? this.filterType),
    );
  }

  List<InfoItemEntity> get filtered {
    var list = List<InfoItemEntity>.from(items);

    if (filterType != null) {
      list = list.where((e) => e.type == filterType).toList();
    }

    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((e) => e.searchBlob.toLowerCase().contains(q))
          .toList();
    }

    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  int get totalCount => items.length;
}

class InfoNotifier extends StateNotifier<InfoState> {
  InfoNotifier() : super(const InfoState()) {
    load();
  }

  final _repo = InfoRepository();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.getAll();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearch(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setFilter(InfoItemType? type) {
    if (type == null) {
      state = state.copyWith(clearFilter: true);
    } else if (state.filterType == type) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterType: type);
    }
  }

  Future<InfoItemEntity> create({
    required String title,
    required InfoItemType type,
    String value = '',
    CardDetails? card,
    String color = 'blue',
  }) async {
    final item = await _repo.create(
      title: title,
      type: type,
      value: value,
      card: card,
      color: color,
    );
    await load();
    return item;
  }

  Future<void> update(InfoItemEntity item) async {
    await _repo.update(item);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }

  /// افزایش شمارنده استفاده (بعد از کپی موفق)
  Future<void> registerCopy(String id) async {
    await _repo.incrementUses(id);
    await load();
  }
}

final infoProvider =
    StateNotifierProvider<InfoNotifier, InfoState>((ref) {
  return InfoNotifier();
});
