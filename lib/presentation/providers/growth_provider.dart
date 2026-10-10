import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/growth_repository.dart';
import '../../domain/entities/growth/growth_enums.dart';
import '../../domain/entities/growth/growth_journey.dart';
import '../../domain/entities/growth/growth_session.dart';

class GrowthState {
  final List<GrowthJourney> journeys;
  final List<GrowthSession> sessions;
  final bool isLoading;
  final String? error;

  const GrowthState({
    this.journeys = const [],
    this.sessions = const [],
    this.isLoading = false,
    this.error,
  });

  List<GrowthJourney> get activeJourneys =>
      journeys.where((j) => j.status == JourneyStatus.active).toList();

  List<GrowthJourney> get pausedJourneys =>
      journeys.where((j) => j.status == JourneyStatus.paused).toList();

  List<GrowthJourney> get archivedJourneys =>
      journeys.where((j) => j.status == JourneyStatus.archived).toList();

  GrowthSession? get activeSession {
    for (final s in sessions) {
      if (s.status == SessionStatus.inProgress) return s;
    }
    return null;
  }

  GrowthSession? inProgressFor(String programId) {
    for (final s in sessions) {
      if (s.programId == programId && s.status == SessionStatus.inProgress) {
        return s;
      }
    }
    return null;
  }

  GrowthState copyWith({
    List<GrowthJourney>? journeys,
    List<GrowthSession>? sessions,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GrowthState(
      journeys: journeys ?? this.journeys,
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GrowthNotifier extends StateNotifier<GrowthState> {
  GrowthNotifier() : super(const GrowthState()) {
    load();
  }

  final _repo = GrowthRepository();

  /// محدودیت نرم مسیرهای فعال
  static const maxSoftActive = 3;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final journeys = await _repo.loadJourneys();
      final sessions = await _repo.loadSessions();
      state = state.copyWith(
        journeys: journeys,
        sessions: sessions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  Future<void> _persistJourneys(List<GrowthJourney> list) async {
    await _repo.saveJourneys(list);
    state = state.copyWith(journeys: list);
  }

  /// ساخت مسیر جدید — پیش‌فرض فعال (اگر زیاد باشد هشدار در UI)
  Future<GrowthJourney> createJourney({
    required String title,
    String reason = '',
    String successCriteria = '',
    List<String> programIds = const [],
    bool startActive = true,
  }) async {
    final now = DateTime.now();
    final activeCount = state.activeJourneys.length;
    final status = startActive
        ? (activeCount >= maxSoftActive
            ? JourneyStatus.draft
            : JourneyStatus.active)
        : JourneyStatus.draft;

    final j = GrowthJourney(
      id: _repo.newId(),
      title: title.trim(),
      reason: reason.trim(),
      successCriteria: successCriteria.trim(),
      programIds: programIds,
      status: status,
      startAt: status == JourneyStatus.active ? now : null,
      createdAt: now,
      updatedAt: now,
    );
    await _persistJourneys([j, ...state.journeys]);
    return j;
  }

  Future<void> updateJourney(GrowthJourney updated) async {
    final list = state.journeys
        .map((j) => j.id == updated.id
            ? updated.copyWith(updatedAt: DateTime.now())
            : j)
        .toList();
    await _persistJourneys(list);
  }

  Future<void> setStatus(String id, JourneyStatus status) async {
    final list = state.journeys.map((j) {
      if (j.id != id) return j;
      return j.copyWith(
        status: status,
        startAt: status == JourneyStatus.active && j.startAt == null
            ? DateTime.now()
            : j.startAt,
        updatedAt: DateTime.now(),
      );
    }).toList();
    await _persistJourneys(list);
  }

  Future<void> activate(String id) => setStatus(id, JourneyStatus.active);
  Future<void> pause(String id) => setStatus(id, JourneyStatus.paused);
  Future<void> complete(String id) => setStatus(id, JourneyStatus.completed);
  Future<void> archive(String id) => setStatus(id, JourneyStatus.archived);

  Future<void> deleteJourney(String id) async {
    final list = state.journeys.where((j) => j.id != id).toList();
    await _persistJourneys(list);
  }


  Future<void> _persistSessions(List<GrowthSession> list) async {
    await _repo.saveSessions(list);
    state = state.copyWith(sessions: list);
  }

  /// شروع یا ادامه اجرای برنامه
  Future<GrowthSession> startSession({
    required String programId,
    String? journeyId,
  }) async {
    final existing = state.inProgressFor(programId);
    if (existing != null) return existing;

    final s = GrowthSession(
      id: _repo.newId(),
      programId: programId,
      journeyId: journeyId,
      status: SessionStatus.inProgress,
      startedAt: DateTime.now(),
      objective: {'step': 0, 'checklist': <String, bool>{}},
      subjective: {},
    );
    await _persistSessions([s, ...state.sessions]);
    return s;
  }

  Future<void> autoSaveSession(GrowthSession session) async {
    final list = state.sessions
        .map((s) => s.id == session.id ? session : s)
        .toList();
    // اگر نبود اضافه کن
    if (!list.any((s) => s.id == session.id)) {
      list.insert(0, session);
    }
    await _persistSessions(list);
  }

  Future<void> pauseSession(String sessionId) async {
    final list = state.sessions.map((s) {
      if (s.id != sessionId) return s;
      return s.copyWith(status: SessionStatus.saved);
    }).toList();
    await _persistSessions(list);
  }

  Future<void> abandonSession(String sessionId) async {
    final list = state.sessions.map((s) {
      if (s.id != sessionId) return s;
      return s.copyWith(
        status: SessionStatus.abandoned,
        endedAt: DateTime.now(),
      );
    }).toList();
    await _persistSessions(list);
  }

  Future<void> finishSessionForEval(GrowthSession session) async {
    final updated = session.copyWith(
      status: SessionStatus.saved,
      endedAt: DateTime.now(),
    );
    await autoSaveSession(updated);
  }

  Future<void> markSessionEvaluated(GrowthSession session) async {
    final updated = session.copyWith(
      status: SessionStatus.evaluated,
      endedAt: session.endedAt ?? DateTime.now(),
    );
    await autoSaveSession(updated);
  }

  bool get isOverSoftLimit => state.activeJourneys.length > maxSoftActive;
}

final growthProvider =
    StateNotifierProvider<GrowthNotifier, GrowthState>((ref) {
  return GrowthNotifier();
});
