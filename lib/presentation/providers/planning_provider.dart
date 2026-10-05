import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/planning_constants.dart';
import '../../data/repositories/planning_repository.dart';
import '../../domain/entities/eisen_task_entity.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/kanban_card_entity.dart';
import '../../domain/entities/planning_archive_entity.dart';
import '../../core/utils/jalali.dart';

class PlanningState {
  final List<HabitEntity> habits;
  final List<EisenTaskEntity> eisenTasks;
  final List<KanbanCardEntity> kanbanCards;
  final List<String> activePrograms;
  final Map<String, int> moodMap;
  final Map<String, String> programNotes;
  final Map<String, PlanningPeriod> periods;
  final List<PlanningArchive> archives;
  final bool isLoading;
  final String? error;
  final PlanningSubTab subTab;

  const PlanningState({
    this.habits = const [],
    this.eisenTasks = const [],
    this.kanbanCards = const [],
    this.activePrograms = const ['eisen', 'habits', 'pomodoro'],
    this.moodMap = const {},
    this.programNotes = const {},
    this.periods = const {},
    this.archives = const [],
    this.isLoading = false,
    this.error,
    this.subTab = PlanningSubTab.home,
  });

  PlanningState copyWith({
    List<HabitEntity>? habits,
    List<EisenTaskEntity>? eisenTasks,
    List<KanbanCardEntity>? kanbanCards,
    List<String>? activePrograms,
    Map<String, int>? moodMap,
    Map<String, String>? programNotes,
    Map<String, PlanningPeriod>? periods,
    List<PlanningArchive>? archives,
    bool? isLoading,
    String? error,
    bool clearError = false,
    PlanningSubTab? subTab,
  }) {
    return PlanningState(
      habits: habits ?? this.habits,
      eisenTasks: eisenTasks ?? this.eisenTasks,
      kanbanCards: kanbanCards ?? this.kanbanCards,
      activePrograms: activePrograms ?? this.activePrograms,
      moodMap: moodMap ?? this.moodMap,
      programNotes: programNotes ?? this.programNotes,
      periods: periods ?? this.periods,
      archives: archives ?? this.archives,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      subTab: subTab ?? this.subTab,
    );
  }

  List<HabitEntity> get activeHabits =>
      habits.where((h) => !h.archived).toList();

  int get openEisenCount => eisenTasks.where((t) => !t.done).length;

  int habitsDoneToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return activeHabits.where((h) => h.isDoneOn(today)).length;
  }
}

class PlanningNotifier extends StateNotifier<PlanningState> {
  PlanningNotifier() : super(const PlanningState()) {
    load();
  }

  final _repo = PlanningRepository();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final habits = await _repo.getHabits();
      final eisen = await _repo.getEisenTasks();
      final kanban = await _repo.getKanbanCards();
      final active = await _repo.getActivePrograms();
      final mood = await _repo.getMoodMap();
      final notes = await _repo.getProgramNotes();
      final periods = await _repo.getPeriods();
      final archives = await _repo.getArchives();
      state = state.copyWith(
        habits: habits,
        eisenTasks: eisen,
        kanbanCards: kanban,
        activePrograms: active,
        moodMap: mood,
        programNotes: notes,
        periods: periods,
        archives: archives,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSubTab(PlanningSubTab tab) {
    state = state.copyWith(subTab: tab);
  }

  // ── Habits ─────────────────────────────────────────────

  Future<void> addHabit(String title, {String color = 'purple'}) async {
    final t = title.trim();
    if (t.isEmpty) return;
    await _repo.createHabit(HabitEntity(
      id: '',
      title: t,
      color: color,
      createdAt: DateTime.now(),
    ));
    await load();
  }

  Future<void> updateHabit(HabitEntity h) async {
    await _repo.updateHabit(h);
    await load();
  }

  Future<void> deleteHabit(String id) async {
    await _repo.deleteHabit(id);
    await load();
  }

  Future<void> toggleHabitDay(HabitEntity h, DateTime day) async {
    final key =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final list = List<String>.from(h.completedDays);
    if (list.contains(key)) {
      list.remove(key);
    } else {
      list.add(key);
    }
    await _repo.updateHabit(h.copyWith(completedDays: list));
    await load();
  }

  // ── Eisenhower ─────────────────────────────────────────

  Future<void> addEisenTask(String text, EisenQuadrant q) async {
    final t = text.trim();
    if (t.isEmpty) return;
    await _repo.createEisenTask(EisenTaskEntity(
      id: '',
      text: t,
      quadrant: q,
      createdAt: DateTime.now(),
    ));
    await load();
  }

  Future<void> updateEisenTask(EisenTaskEntity t) async {
    await _repo.updateEisenTask(t);
    await load();
  }

  Future<void> deleteEisenTask(String id) async {
    await _repo.deleteEisenTask(id);
    await load();
  }

  Future<void> toggleEisenDone(EisenTaskEntity t) async {
    await _repo.updateEisenTask(t.copyWith(done: !t.done));
    await load();
  }

  // ── Programs ───────────────────────────────────────────

  Future<void> toggleProgram(String id) async {
    final list = List<String>.from(state.activePrograms);
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    await _repo.saveActivePrograms(list);
    state = state.copyWith(activePrograms: list);
  }

  Future<void> moveProgramUp(String id) async {
    final list = List<String>.from(state.activePrograms);
    final i = list.indexOf(id);
    if (i <= 0) return;
    final tmp = list[i - 1];
    list[i - 1] = list[i];
    list[i] = tmp;
    await _repo.saveActivePrograms(list);
    state = state.copyWith(activePrograms: list);
  }

  Future<void> moveProgramDown(String id) async {
    final list = List<String>.from(state.activePrograms);
    final i = list.indexOf(id);
    if (i < 0 || i >= list.length - 1) return;
    final tmp = list[i + 1];
    list[i + 1] = list[i];
    list[i] = tmp;
    await _repo.saveActivePrograms(list);
    state = state.copyWith(activePrograms: list);
  }

  // ── Kanban ─────────────────────────────────────────────

  Future<void> addKanbanCard(
    String title, {
    KanbanColumn column = KanbanColumn.todo,
    String note = '',
    int priority = 2,
  }) async {
    final t = title.trim();
    if (t.isEmpty) return;
    final cards = List<KanbanCardEntity>.from(state.kanbanCards);
    cards.add(KanbanCardEntity(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: t,
      note: note.trim(),
      priority: priority.clamp(1, 3),
      column: column,
      createdAt: DateTime.now(),
    ));
    await _repo.saveKanbanCards(cards);
    await load();
  }

  Future<void> moveKanbanCard(String id, KanbanColumn column) async {
    final cards = state.kanbanCards
        .map((c) => c.id == id ? c.copyWith(column: column) : c)
        .toList();
    await _repo.saveKanbanCards(cards);
    await load();
  }

  Future<void> deleteKanbanCard(String id) async {
    final cards = state.kanbanCards.where((c) => c.id != id).toList();
    await _repo.saveKanbanCards(cards);
    await load();
  }

  Future<void> updateKanbanCard(KanbanCardEntity card) async {
    final cards =
        state.kanbanCards.map((c) => c.id == card.id ? card : c).toList();
    await _repo.saveKanbanCards(cards);
    await load();
  }

  // ── Mood & notes ───────────────────────────────────────

  Future<void> setMood(String dateKey, int score) async {
    final map = Map<String, int>.from(state.moodMap);
    map[dateKey] = score.clamp(1, 5);
    await _repo.saveMoodMap(map);
    state = state.copyWith(moodMap: map);
  }

  Future<void> saveProgramNote(String key, String text) async {
    final map = Map<String, String>.from(state.programNotes);
    map[key] = text;
    await _repo.saveProgramNotes(map);
    state = state.copyWith(programNotes: map);
  }

  String _programName(String programId) {
    for (final p in programCatalog) {
      if (p.id == programId) return p.name;
    }
    return programId;
  }

  Future<void> ensurePeriod(String programId) async {
    await _repo.ensurePeriod(programId);
    final periods = await _repo.getPeriods();
    state = state.copyWith(periods: periods);
  }

  Future<void> updatePeriodMeta(
    String programId, {
    String? title,
    List<String>? tags,
  }) async {
    await _repo.updatePeriodMeta(programId, title: title, tags: tags);
    final periods = await _repo.getPeriods();
    state = state.copyWith(periods: periods);
  }

  /// آرشیو دوره جاری یک برنامه.
  /// [clearCurrent] طبق شورا: پیش‌فرض true — داده جاری برای دوره جدید پاک می‌شود.
  /// [deactivate] از لیست فعال‌ها حذف شود.
  Future<PlanningArchive?> archiveCurrentPeriod(
    String programId, {
    int? feelingScore,
    String? feelingNote,
    bool clearCurrent = true,
    bool deactivate = true,
  }) async {
    try {
      final period = await _repo.ensurePeriod(programId);
      final snapshot = await _repo.buildSnapshot(programId);
      final stats = _repo.buildStats(programId, snapshot);
      final now = DateTime.now();
      final j = Jalali.fromDateTime(now);
      final name = _programName(programId);
      final summary = _repo.buildSummaryText(
        programName: name,
        programId: programId,
        period: period,
        stats: stats,
        feelingScore: feelingScore,
        feelingNote: feelingNote,
      );

      final archive = PlanningArchive(
        id: '',
        programId: programId,
        programName: name,
        periodId: period.periodId,
        archivedAt: now,
        jalaliDate: j.format(withMonthName: true),
        jalaliTime:
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        feelingScore: feelingScore,
        feelingNote: feelingNote,
        periodTitle: period.title,
        tags: period.tags,
        periodStartedAt: period.startedAt,
        snapshot: snapshot,
        summaryText: summary,
        stats: stats,
      );

      final saved = await _repo.insertArchive(archive);

      if (clearCurrent) {
        await _clearProgramData(programId);
      }
      if (deactivate) {
        final active = List<String>.from(state.activePrograms)
          ..remove(programId);
        await _repo.saveActivePrograms(active);
      }
      await _repo.resetPeriod(programId);
      await load();
      return saved;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> _clearProgramData(String programId) async {
    switch (programId) {
      case 'habits':
        for (final h in List<HabitEntity>.from(state.habits)) {
          await _repo.deleteHabit(h.id);
        }
        break;
      case 'eisen':
        for (final t in List<EisenTaskEntity>.from(state.eisenTasks)) {
          await _repo.deleteEisenTask(t.id);
        }
        break;
      case 'kanban':
        await _repo.saveKanbanCards([]);
        break;
      case 'mood':
        await _repo.saveMoodMap({});
        break;
      default:
        break;
    }
    final notes = Map<String, String>.from(state.programNotes);
    notes.remove(programId);
    await _repo.saveProgramNotes(notes);
  }

  Future<void> deleteArchive(String id) async {
    await _repo.deleteArchive(id);
    final archives = await _repo.getArchives();
    state = state.copyWith(archives: archives);
  }
}

final planningProvider =
    StateNotifierProvider<PlanningNotifier, PlanningState>((ref) {
  return PlanningNotifier();
});
