import '../../domain/entities/growth/growth_journey.dart';
import '../../domain/entities/growth/growth_session.dart';
import '../../core/services/local_database.dart';

/// ذخیره آفلاین مسیرها و اجراها
class GrowthRepository {
  static const journeysCol = 'growth_journeys';
  static const sessionsCol = 'growth_sessions';

  final LocalDatabase _db = LocalDatabase.instance;

  Future<List<GrowthJourney>> loadJourneys() async {
    final raw = await _db.readAll(journeysCol);
    return raw.map(GrowthJourney.fromMap).toList();
  }

  Future<void> saveJourneys(List<GrowthJourney> list) async {
    await _db.writeAll(journeysCol, list.map((e) => e.toMap()).toList());
  }

  Future<List<GrowthSession>> loadSessions() async {
    final raw = await _db.readAll(sessionsCol);
    return raw.map(GrowthSession.fromMap).toList();
  }

  Future<void> saveSessions(List<GrowthSession> list) async {
    await _db.writeAll(sessionsCol, list.map((e) => e.toMap()).toList());
  }

  String newId() => _db.generateId();
}
