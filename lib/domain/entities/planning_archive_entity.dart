import 'package:equatable/equatable.dart';

/// متادیتای «دوره جاری» یک برنامه فعال
class PlanningPeriod extends Equatable {
  final String periodId;
  final String programId;
  final DateTime startedAt;
  final String? title;
  final List<String> tags;

  const PlanningPeriod({
    required this.periodId,
    required this.programId,
    required this.startedAt,
    this.title,
    this.tags = const [],
  });

  PlanningPeriod copyWith({
    String? periodId,
    String? programId,
    DateTime? startedAt,
    String? title,
    List<String>? tags,
  }) {
    return PlanningPeriod(
      periodId: periodId ?? this.periodId,
      programId: programId ?? this.programId,
      startedAt: startedAt ?? this.startedAt,
      title: title ?? this.title,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() => {
        'periodId': periodId,
        'programId': programId,
        'startedAt': startedAt.toIso8601String(),
        'title': title,
        'tags': tags,
      };

  factory PlanningPeriod.fromMap(Map<String, dynamic> m) {
    return PlanningPeriod(
      periodId: m['periodId'] as String? ?? '',
      programId: m['programId'] as String? ?? '',
      startedAt: DateTime.tryParse(m['startedAt'] as String? ?? '') ??
          DateTime.now(),
      title: m['title'] as String?,
      tags: (m['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  @override
  List<Object?> get props => [periodId, programId, startedAt, title, tags];
}

/// اسنپ‌شات آرشیو یک دوره برنامه‌ریزی
class PlanningArchive extends Equatable {
  final String id;
  final String programId;
  final String programName;
  final String periodId;
  final DateTime archivedAt;
  final String jalaliDate;
  final String jalaliTime;
  final int? feelingScore; // 1–5
  final String? feelingNote;
  final String? periodTitle;
  final List<String> tags;
  final DateTime periodStartedAt;
  final Map<String, dynamic> snapshot;
  final String summaryText;
  final Map<String, dynamic> stats;

  const PlanningArchive({
    required this.id,
    required this.programId,
    required this.programName,
    required this.periodId,
    required this.archivedAt,
    required this.jalaliDate,
    required this.jalaliTime,
    this.feelingScore,
    this.feelingNote,
    this.periodTitle,
    this.tags = const [],
    required this.periodStartedAt,
    this.snapshot = const {},
    this.summaryText = '',
    this.stats = const {},
  });

  Duration get periodDuration => archivedAt.difference(periodStartedAt);

  PlanningArchive copyWith({
    String? id,
    String? programId,
    String? programName,
    String? periodId,
    DateTime? archivedAt,
    String? jalaliDate,
    String? jalaliTime,
    int? feelingScore,
    String? feelingNote,
    String? periodTitle,
    List<String>? tags,
    DateTime? periodStartedAt,
    Map<String, dynamic>? snapshot,
    String? summaryText,
    Map<String, dynamic>? stats,
  }) {
    return PlanningArchive(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      periodId: periodId ?? this.periodId,
      archivedAt: archivedAt ?? this.archivedAt,
      jalaliDate: jalaliDate ?? this.jalaliDate,
      jalaliTime: jalaliTime ?? this.jalaliTime,
      feelingScore: feelingScore ?? this.feelingScore,
      feelingNote: feelingNote ?? this.feelingNote,
      periodTitle: periodTitle ?? this.periodTitle,
      tags: tags ?? this.tags,
      periodStartedAt: periodStartedAt ?? this.periodStartedAt,
      snapshot: snapshot ?? this.snapshot,
      summaryText: summaryText ?? this.summaryText,
      stats: stats ?? this.stats,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'programId': programId,
        'programName': programName,
        'periodId': periodId,
        'archivedAt': archivedAt.toIso8601String(),
        'jalaliDate': jalaliDate,
        'jalaliTime': jalaliTime,
        'feelingScore': feelingScore,
        'feelingNote': feelingNote,
        'periodTitle': periodTitle,
        'tags': tags,
        'periodStartedAt': periodStartedAt.toIso8601String(),
        'snapshot': snapshot,
        'summaryText': summaryText,
        'stats': stats,
      };

  factory PlanningArchive.fromMap(Map<String, dynamic> m) {
    return PlanningArchive(
      id: m['id'] as String? ?? '',
      programId: m['programId'] as String? ?? '',
      programName: m['programName'] as String? ?? '',
      periodId: m['periodId'] as String? ?? '',
      archivedAt: DateTime.tryParse(m['archivedAt'] as String? ?? '') ??
          DateTime.now(),
      jalaliDate: m['jalaliDate'] as String? ?? '',
      jalaliTime: m['jalaliTime'] as String? ?? '',
      feelingScore: (m['feelingScore'] as num?)?.toInt(),
      feelingNote: m['feelingNote'] as String?,
      periodTitle: m['periodTitle'] as String?,
      tags: (m['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      periodStartedAt:
          DateTime.tryParse(m['periodStartedAt'] as String? ?? '') ??
              DateTime.now(),
      snapshot: Map<String, dynamic>.from(
          (m['snapshot'] as Map?)?.cast<String, dynamic>() ?? const {}),
      summaryText: m['summaryText'] as String? ?? '',
      stats: Map<String, dynamic>.from(
          (m['stats'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        programId,
        periodId,
        archivedAt,
        feelingScore,
        summaryText,
      ];
}
