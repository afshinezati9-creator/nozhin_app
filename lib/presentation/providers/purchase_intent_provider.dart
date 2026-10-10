import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/local_database.dart';
import '../../domain/entities/purchase_intent_entity.dart';

class PurchaseIntentState {
  final List<PurchaseIntentEntity> items;
  final bool isLoading;
  final bool showArchive;
  final PurchaseTimeTab tab;
  final String? error;

  const PurchaseIntentState({
    this.items = const [],
    this.isLoading = false,
    this.showArchive = false,
    this.tab = PurchaseTimeTab.today,
    this.error,
  });

  List<PurchaseIntentEntity> get visible {
    final base = items.where((e) => e.archived == showArchive).toList();
    if (showArchive) {
      return base
        ..sort((a, b) => (b.resolvedAt ?? b.createdAt)
            .compareTo(a.resolvedAt ?? a.createdAt));
    }
    final filtered = base
        .where((e) => PurchaseTimeFilter.matches(e.plannedDate, tab))
        .toList()
      ..sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
    return filtered;
  }

  List<PurchaseIntentEntity> get overdue {
    if (showArchive) return const [];
    return items
        .where((e) =>
            !e.archived &&
            PurchaseTimeFilter.isOverdue(e.plannedDate, e.status))
        .toList()
      ..sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
  }

  double get openCommitment {
    return items
        .where((e) =>
            !e.archived && e.status == PurchaseIntentStatus.pending)
        .fold<double>(0, (s, e) => s + (e.amount ?? 0));
  }

  PurchaseIntentState copyWith({
    List<PurchaseIntentEntity>? items,
    bool? isLoading,
    bool? showArchive,
    PurchaseTimeTab? tab,
    String? error,
    bool clearError = false,
  }) {
    return PurchaseIntentState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      showArchive: showArchive ?? this.showArchive,
      tab: tab ?? this.tab,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PurchaseIntentNotifier extends StateNotifier<PurchaseIntentState> {
  PurchaseIntentNotifier() : super(const PurchaseIntentState()) {
    load();
  }

  final _db = LocalDatabase.instance;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final raw = await _db.readAll(Collections.purchaseIntents);
      final list = raw.map(PurchaseIntentEntity.fromMap).toList();
      state = state.copyWith(items: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  Future<void> _persist(List<PurchaseIntentEntity> list) async {
    state = state.copyWith(items: list);
    await _db.writeAll(
      Collections.purchaseIntents,
      list.map((e) => e.toMap()).toList(),
    );
  }

  void setTab(PurchaseTimeTab tab) {
    state = state.copyWith(tab: tab, showArchive: false);
  }

  void setShowArchive(bool v) {
    state = state.copyWith(showArchive: v);
  }

  Future<void> add({
    required String title,
    double? amount,
    required DateTime plannedDate,
    String note = '',
    int priority = 2,
  }) async {
    final item = PurchaseIntentEntity(
      id: _db.generateId(),
      title: title.trim(),
      amount: amount,
      plannedDate: plannedDate,
      note: note,
      createdAt: DateTime.now(),
      priority: priority.clamp(1, 4),
    );
    await _persist([item, ...state.items]);
  }

  Future<void> update(PurchaseIntentEntity item) async {
    final list =
        state.items.map((e) => e.id == item.id ? item : e).toList();
    await _persist(list);
  }

  Future<void> markBought(String id) async {
    final list = state.items.map((e) {
      if (e.id != id) return e;
      return e.copyWith(
        status: PurchaseIntentStatus.bought,
        archived: true,
        resolvedAt: DateTime.now(),
      );
    }).toList();
    await _persist(list);
  }

  Future<void> markCouldNot(String id) async {
    final list = state.items.map((e) {
      if (e.id != id) return e;
      return e.copyWith(
        status: PurchaseIntentStatus.couldNot,
        archived: true,
        resolvedAt: DateTime.now(),
      );
    }).toList();
    await _persist(list);
  }

  Future<void> archive(String id) async {
    final list = state.items
        .map((e) => e.id == id ? e.copyWith(archived: true) : e)
        .toList();
    await _persist(list);
  }

  Future<void> restore(String id) async {
    final list = state.items.map((e) {
      if (e.id != id) return e;
      return e.copyWith(
        archived: false,
        status: PurchaseIntentStatus.pending,
      );
    }).toList();
    await _persist(list);
  }

  Future<void> delete(String id) async {
    await _persist(state.items.where((e) => e.id != id).toList());
  }
}

final purchaseIntentProvider =
    StateNotifierProvider<PurchaseIntentNotifier, PurchaseIntentState>(
  (ref) => PurchaseIntentNotifier(),
);
