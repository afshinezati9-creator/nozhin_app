import 'growth_enums.dart';

/// یک اجرای واقعی برنامه
class GrowthSession {
  final String id;
  final String programId;
  final String? journeyId;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// داده عینی (چه اتفاقی افتاد)
  final Map<String, dynamic> objective;

  /// داده ذهنی (حس و کیفیت)
  final Map<String, dynamic> subjective;

  final CompletionLevel? completion;
  final List<String> barriers;
  final String note;
  final NextStepKind? nextStep;
  final String nextStepNote;

  const GrowthSession({
    required this.id,
    required this.programId,
    this.journeyId,
    this.status = SessionStatus.inProgress,
    required this.startedAt,
    this.endedAt,
    this.objective = const {},
    this.subjective = const {},
    this.completion,
    this.barriers = const [],
    this.note = '',
    this.nextStep,
    this.nextStepNote = '',
  });

  GrowthSession copyWith({
    SessionStatus? status,
    DateTime? endedAt,
    Map<String, dynamic>? objective,
    Map<String, dynamic>? subjective,
    CompletionLevel? completion,
    List<String>? barriers,
    String? note,
    NextStepKind? nextStep,
    String? nextStepNote,
  }) {
    return GrowthSession(
      id: id,
      programId: programId,
      journeyId: journeyId,
      status: status ?? this.status,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      objective: objective ?? this.objective,
      subjective: subjective ?? this.subjective,
      completion: completion ?? this.completion,
      barriers: barriers ?? this.barriers,
      note: note ?? this.note,
      nextStep: nextStep ?? this.nextStep,
      nextStepNote: nextStepNote ?? this.nextStepNote,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'programId': programId,
        'journeyId': journeyId,
        'status': status.name,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'objective': objective,
        'subjective': subjective,
        'completion': completion?.name,
        'barriers': barriers,
        'note': note,
        'nextStep': nextStep?.name,
        'nextStepNote': nextStepNote,
      };

  factory GrowthSession.fromMap(Map<String, dynamic> m) {
    CompletionLevel? comp;
    final cn = m['completion'] as String?;
    if (cn != null) {
      comp = CompletionLevel.values.firstWhere(
        (e) => e.name == cn,
        orElse: () => CompletionLevel.partial,
      );
    }
    NextStepKind? ns;
    final nn = m['nextStep'] as String?;
    if (nn != null) {
      ns = NextStepKind.values.firstWhere(
        (e) => e.name == nn,
        orElse: () => NextStepKind.continueSame,
      );
    }
    return GrowthSession(
      id: m['id'] as String,
      programId: m['programId'] as String,
      journeyId: m['journeyId'] as String?,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == m['status'],
        orElse: () => SessionStatus.inProgress,
      ),
      startedAt: DateTime.tryParse('${m['startedAt']}') ?? DateTime.now(),
      endedAt: m['endedAt'] != null ? DateTime.tryParse('${m['endedAt']}') : null,
      objective: Map<String, dynamic>.from(m['objective'] as Map? ?? {}),
      subjective: Map<String, dynamic>.from(m['subjective'] as Map? ?? {}),
      completion: comp,
      barriers: (m['barriers'] as List?)?.map((e) => '$e').toList() ?? const [],
      note: (m['note'] as String?) ?? '',
      nextStep: ns,
      nextStepNote: (m['nextStepNote'] as String?) ?? '',
    );
  }
}
