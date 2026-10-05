import '../../core/constants/planning_constants.dart';
import '../../core/services/local_database.dart';
import '../../domain/entities/eisen_task_entity.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/kanban_card_entity.dart';
import '../../domain/entities/planning_archive_entity.dart';
import '../../core/utils/jalali.dart';

class PlanningRepository {
  final _db = LocalDatabase.instance;

  // ─── Habits ────────────────────────────────────────────

  HabitEntity _habitFrom(Map<String, dynamic> m) {
    return HabitEntity(
      id: m['id'] as String,
      title: m['title'] as String? ?? '',
      icon: m['icon'] as String?,
      color: m['color'] as String? ?? 'purple',
      completedDays:
          (m['completedDays'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      archived: m['archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _habitTo(HabitEntity h) => {
        'id': h.id,
        'title': h.title,
        'icon': h.icon,
        'color': h.color,
        'completedDays': h.completedDays,
        'createdAt': h.createdAt.toIso8601String(),
        'archived': h.archived,
      };

  Future<List<HabitEntity>> getHabits() async {
    final items = await _db.readAll(Collections.habits);
    return items.map(_habitFrom).toList();
  }

  Future<HabitEntity> createHabit(HabitEntity h) async {
    final habit = HabitEntity(
      id: _db.generateId(),
      title: h.title,
      icon: h.icon,
      color: h.color,
      completedDays: h.completedDays,
      createdAt: DateTime.now(),
      archived: h.archived,
    );
    await _db.insert(Collections.habits, _habitTo(habit));
    return habit;
  }

  Future<void> updateHabit(HabitEntity h) async {
    await _db.update(Collections.habits, h.id, _habitTo(h));
  }

  Future<void> deleteHabit(String id) async {
    await _db.delete(Collections.habits, id);
  }

  // ─── Eisenhower ────────────────────────────────────────

  EisenTaskEntity _eisenFrom(Map<String, dynamic> m) {
    return EisenTaskEntity(
      id: m['id'] as String,
      text: m['text'] as String? ?? '',
      quadrant: EisenQuadrant.values.firstWhere(
        (e) => e.name == (m['quadrant'] as String? ?? 'q2'),
        orElse: () => EisenQuadrant.q2,
      ),
      done: m['done'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _eisenTo(EisenTaskEntity t) => {
        'id': t.id,
        'text': t.text,
        'quadrant': t.quadrant.name,
        'done': t.done,
        'createdAt': t.createdAt.toIso8601String(),
      };

  Future<List<EisenTaskEntity>> getEisenTasks() async {
    final items = await _db.readAll(Collections.eisen);
    return items.map(_eisenFrom).toList();
  }

  Future<EisenTaskEntity> createEisenTask(EisenTaskEntity t) async {
    final task = EisenTaskEntity(
      id: _db.generateId(),
      text: t.text,
      quadrant: t.quadrant,
      done: t.done,
      createdAt: DateTime.now(),
    );
    await _db.insert(Collections.eisen, _eisenTo(task));
    return task;
  }

  Future<void> updateEisenTask(EisenTaskEntity t) async {
    await _db.update(Collections.eisen, t.id, _eisenTo(t));
  }

  Future<void> deleteEisenTask(String id) async {
    await _db.delete(Collections.eisen, id);
  }

  // ─── Kanban (stored inside program_data) ───────────────

  Future<List<KanbanCardEntity>> getKanbanCards() async {
    final items = await _db.readAll(Collections.programData);
    final row = items.where((e) => e['id'] == 'kanban').toList();
    if (row.isEmpty) return [];
    final cards = (row.first['cards'] as List<dynamic>? ?? []);
    return cards.map((c) {
      final m = c as Map<String, dynamic>;
      return KanbanCardEntity(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        column: KanbanColumn.values.firstWhere(
          (e) => e.name == (m['column'] as String? ?? 'todo'),
          orElse: () => KanbanColumn.todo,
        ),
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  Future<void> saveKanbanCards(List<KanbanCardEntity> cards) async {
    final payload = {
      'id': 'kanban',
      'cards': cards
          .map((c) => {
                'id': c.id,
                'title': c.title,
                'column': c.column.name,
                'createdAt': c.createdAt.toIso8601String(),
              })
          .toList(),
    };
    final all = await _db.readAll(Collections.programData);
    final idx = all.indexWhere((e) => e['id'] == 'kanban');
    if (idx >= 0) {
      all[idx] = payload;
    } else {
      all.add(payload);
    }
    await _db.writeAll(Collections.programData, all);
  }

  // ─── Active programs ───────────────────────────────────

  Future<List<String>> getActivePrograms() async {
    final items = await _db.readAll(Collections.programData);
    final row = items.where((e) => e['id'] == 'active_programs').toList();
    if (row.isEmpty) return List<String>.from(defaultActivePrograms);
    return (row.first['ids'] as List<dynamic>?)?.cast<String>() ??
        List<String>.from(defaultActivePrograms);
  }

  Future<void> saveActivePrograms(List<String> ids) async {
    final payload = {'id': 'active_programs', 'ids': ids};
    final all = await _db.readAll(Collections.programData);
    final idx = all.indexWhere((e) => e['id'] == 'active_programs');
    if (idx >= 0) {
      all[idx] = payload;
    } else {
      all.add(payload);
    }
    await _db.writeAll(Collections.programData, all);
  }

  // ─── Mood (simple map date -> score 1-5) ───────────────

  Future<Map<String, int>> getMoodMap() async {
    final items = await _db.readAll(Collections.programData);
    final row = items.where((e) => e['id'] == 'mood').toList();
    if (row.isEmpty) return {};
    final raw = row.first['map'] as Map<String, dynamic>? ?? {};
    return raw.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  Future<void> saveMoodMap(Map<String, int> map) async {
    final payload = {'id': 'mood', 'map': map};
    final all = await _db.readAll(Collections.programData);
    final idx = all.indexWhere((e) => e['id'] == 'mood');
    if (idx >= 0) {
      all[idx] = payload;
    } else {
      all.add(payload);
    }
    await _db.writeAll(Collections.programData, all);
  }

  Future<Map<String, String>> getProgramNotes() async {
    final items = await _db.readAll(Collections.programData);
    final row = items.where((e) => e['id'] == 'program_notes').toList();
    if (row.isEmpty) return {};
    final raw = row.first['map'] as Map<String, dynamic>? ?? {};
    return raw.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> saveProgramNotes(Map<String, String> map) async {
    final payload = {'id': 'program_notes', 'map': map};
    final all = await _db.readAll(Collections.programData);
    final idx = all.indexWhere((e) => e['id'] == 'program_notes');
    if (idx >= 0) {
      all[idx] = payload;
    } else {
      all.add(payload);
    }
    await _db.writeAll(Collections.programData, all);
  }

  // ─── Periods (current period meta per program) ─────────

  Future<Map<String, PlanningPeriod>> getPeriods() async {
    final items = await _db.readAll(Collections.programData);
    final row = items.where((e) => e['id'] == 'periods').toList();
    if (row.isEmpty) return {};
    final raw = row.first['map'] as Map<String, dynamic>? ?? {};
    return raw.map(
      (k, v) => MapEntry(
        k,
        PlanningPeriod.fromMap(Map<String, dynamic>.from(v as Map)),
      ),
    );
  }

  Future<void> savePeriods(Map<String, PlanningPeriod> map) async {
    final payload = {
      'id': 'periods',
      'map': map.map((k, v) => MapEntry(k, v.toMap())),
    };
    final all = await _db.readAll(Collections.programData);
    final idx = all.indexWhere((e) => e['id'] == 'periods');
    if (idx >= 0) {
      all[idx] = payload;
    } else {
      all.add(payload);
    }
    await _db.writeAll(Collections.programData, all);
  }

  /// اگر دوره برای برنامه وجود نداشت، یکی می‌سازد و برمی‌گرداند.
  Future<PlanningPeriod> ensurePeriod(String programId) async {
    final all = await getPeriods();
    final existing = all[programId];
    if (existing != null && existing.periodId.isNotEmpty) return existing;
    final period = PlanningPeriod(
      periodId: _db.generateId(),
      programId: programId,
      startedAt: DateTime.now(),
    );
    all[programId] = period;
    await savePeriods(all);
    return period;
  }

  Future<void> updatePeriodMeta(
    String programId, {
    String? title,
    List<String>? tags,
  }) async {
    final all = await getPeriods();
    var p = all[programId] ??
        PlanningPeriod(
          periodId: _db.generateId(),
          programId: programId,
          startedAt: DateTime.now(),
        );
    p = p.copyWith(title: title ?? p.title, tags: tags ?? p.tags);
    all[programId] = p;
    await savePeriods(all);
  }

  Future<void> resetPeriod(String programId) async {
    final all = await getPeriods();
    all[programId] = PlanningPeriod(
      periodId: _db.generateId(),
      programId: programId,
      startedAt: DateTime.now(),
      title: null,
      tags: const [],
    );
    await savePeriods(all);
  }

  // ─── Archives ──────────────────────────────────────────

  Future<List<PlanningArchive>> getArchives() async {
    final items = await _db.readAll(Collections.planningArchives);
    final list = items.map(PlanningArchive.fromMap).toList();
    list.sort((a, b) => b.archivedAt.compareTo(a.archivedAt));
    return list;
  }

  Future<PlanningArchive?> getArchiveById(String id) async {
    final items = await _db.readAll(Collections.planningArchives);
    final found = items.where((e) => e['id'] == id).toList();
    if (found.isEmpty) return null;
    return PlanningArchive.fromMap(found.first);
  }

  Future<PlanningArchive> insertArchive(PlanningArchive a) async {
    final row = a.id.isEmpty
        ? a.copyWith(id: _db.generateId())
        : a;
    await _db.insert(Collections.planningArchives, row.toMap());
    return row;
  }

  Future<void> deleteArchive(String id) async {
    await _db.delete(Collections.planningArchives, id);
  }

  /// ساخت اسنپ‌شات خام از داده‌های فعلی مرتبط با یک programId
  Future<Map<String, dynamic>> buildSnapshot(String programId) async {
    final notes = await getProgramNotes();
    final mood = await getMoodMap();
    final snap = <String, dynamic>{
      'programNote': notes[programId] ?? '',
      'allProgramNotes': notes,
    };

    switch (programId) {
      case 'habits':
        final habits = await getHabits();
        snap['habits'] = habits
            .map((h) => {
                  'id': h.id,
                  'title': h.title,
                  'color': h.color,
                  'completedDays': h.completedDays,
                  'archived': h.archived,
                })
            .toList();
        break;
      case 'eisen':
        final tasks = await getEisenTasks();
        snap['eisenTasks'] = tasks
            .map((t) => {
                  'id': t.id,
                  'text': t.text,
                  'quadrant': t.quadrant.name,
                  'done': t.done,
                })
            .toList();
        break;
      case 'kanban':
        final cards = await getKanbanCards();
        snap['kanbanCards'] = cards
            .map((c) => {
                  'id': c.id,
                  'title': c.title,
                  'column': c.column.name,
                  'note': c.note,
                })
            .toList();
        break;
      case 'mood':
        snap['moodMap'] = mood;
        break;
      case 'pomodoro':
        snap['pomo_log'] = notes['pomo_log'] ?? '';
        snap['pomo_count'] = notes['pomo_count'] ?? '0';
        break;
      case 'deepwork':
        snap['dw_history'] = notes['dw_history'] ?? '';
        snap['dw_topic'] = notes['dw_topic'] ?? '';
        break;
      default:
        snap['moodMap'] = mood;
    }
    return snap;
  }

  /// آمار پایه برای نمودار / خلاصه (فاز A0 — اسکلت)
  Map<String, dynamic> buildStats(String programId, Map<String, dynamic> snapshot) {
    final stats = <String, dynamic>{
      'programId': programId,
    };
    switch (programId) {
      case 'habits':
        final habits = (snapshot['habits'] as List?) ?? [];
        var totalTicks = 0;
        for (final h in habits) {
          final days = (h as Map)['completedDays'] as List? ?? [];
          totalTicks += days.length;
        }
        stats['habitCount'] = habits.length;
        stats['totalTicks'] = totalTicks;
        break;
      case 'eisen':
        final tasks = (snapshot['eisenTasks'] as List?) ?? [];
        final done = tasks.where((t) => (t as Map)['done'] == true).length;
        stats['taskCount'] = tasks.length;
        stats['doneCount'] = done;
        stats['openCount'] = tasks.length - done;
        break;
      case 'kanban':
        final cards = (snapshot['kanbanCards'] as List?) ?? [];
        int todo = 0, doing = 0, done = 0;
        for (final c in cards) {
          final col = (c as Map)['column']?.toString() ?? 'todo';
          if (col == 'done') {
            done++;
          } else if (col == 'doing') {
            doing++;
          } else {
            todo++;
          }
        }
        stats['todo'] = todo;
        stats['doing'] = doing;
        stats['done'] = done;
        stats['total'] = cards.length;
        break;
      case 'mood':
        final map = (snapshot['moodMap'] as Map?) ?? {};
        stats['dayCount'] = map.length;
        if (map.isNotEmpty) {
          final vals = map.values.map((v) => (v as num).toDouble()).toList();
          final avg = vals.reduce((a, b) => a + b) / vals.length;
          stats['avgMood'] = double.parse(avg.toStringAsFixed(2));
        }
        break;
      case 'pomodoro':
        stats['sessionCount'] =
            int.tryParse('${snapshot['pomo_count'] ?? 0}') ?? 0;
        break;
      case 'deepwork':
        final h = '${snapshot['dw_history'] ?? ''}';
        stats['blockCount'] =
            h.split('---').where((e) => e.trim().isNotEmpty).length;
        break;
      default:
        final note = snapshot['programNote']?.toString() ?? '';
        stats['noteLength'] = note.length;
        stats['hasNote'] = note.trim().isNotEmpty;
    }
    return stats;
  }

  String buildSummaryText({
    required String programName,
    required String programId,
    required PlanningPeriod period,
    required Map<String, dynamic> stats,
    int? feelingScore,
    String? feelingNote,
  }) {
    final jStart = Jalali.fromDateTime(period.startedAt).format(withMonthName: true);
    final jEnd = Jalali.nowString(withMonthName: true);
    final days = DateTime.now().difference(period.startedAt).inDays + 1;
    final buf = StringBuffer();
    buf.writeln('برنامه: $programName');
    if (period.title != null && period.title!.trim().isNotEmpty) {
      buf.writeln('عنوان دوره: ${period.title}');
    }
    buf.writeln('شروع دوره: $jStart');
    buf.writeln('آرشیو: $jEnd');
    buf.writeln('مدت تقریبی: $days روز');
    buf.writeln('');
    switch (programId) {
      case 'habits':
        buf.writeln(
            'تعداد عادت‌ها: ${stats['habitCount'] ?? 0} — مجموع تیک‌ها: ${stats['totalTicks'] ?? 0}');
        break;
      case 'eisen':
        buf.writeln(
            'کارها: ${stats['taskCount'] ?? 0} (انجام‌شده: ${stats['doneCount'] ?? 0} / باز: ${stats['openCount'] ?? 0})');
        break;
      case 'kanban':
        buf.writeln(
            'کانبان — انجام‌دادنی: ${stats['todo'] ?? 0} | در حال انجام: ${stats['doing'] ?? 0} | شده: ${stats['done'] ?? 0}');
        break;
      case 'mood':
        buf.writeln(
            'روزهای ثبت‌شده: ${stats['dayCount'] ?? 0} — میانگین مود: ${stats['avgMood'] ?? '—'}');
        break;
      default:
        if (stats['hasNote'] == true) {
          buf.writeln('یادداشت دوره ثبت شده (${stats['noteLength']} کاراکتر).');
        } else {
          buf.writeln('یادداشت اختصاصی برای این دوره خالی بود.');
        }
    }
    if (feelingScore != null) {
      buf.writeln('');
      buf.writeln('حس پایان دوره: $feelingScore از ۵');
      if (feelingNote != null && feelingNote.trim().isNotEmpty) {
        buf.writeln('توضیح حس: $feelingNote');
      }
    }
    return buf.toString().trim();
  }
}
