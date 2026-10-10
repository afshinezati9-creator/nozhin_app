import 'growth_enums.dart';

/// مسیر رشد: هدف + روش + بازه + اجراها
class GrowthJourney {
  final String id;
  final String title;
  final String reason;
  final String successCriteria;
  final DateTime? startAt;
  final DateTime? endAt;
  final List<String> programIds;
  final JourneyStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GrowthJourney({
    required this.id,
    required this.title,
    this.reason = '',
    this.successCriteria = '',
    this.startAt,
    this.endAt,
    this.programIds = const [],
    this.status = JourneyStatus.draft,
    required this.createdAt,
    required this.updatedAt,
  });

  GrowthJourney copyWith({
    String? title,
    String? reason,
    String? successCriteria,
    DateTime? startAt,
    DateTime? endAt,
    List<String>? programIds,
    JourneyStatus? status,
    DateTime? updatedAt,
  }) {
    return GrowthJourney(
      id: id,
      title: title ?? this.title,
      reason: reason ?? this.reason,
      successCriteria: successCriteria ?? this.successCriteria,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      programIds: programIds ?? this.programIds,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'reason': reason,
        'successCriteria': successCriteria,
        'startAt': startAt?.toIso8601String(),
        'endAt': endAt?.toIso8601String(),
        'programIds': programIds,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory GrowthJourney.fromMap(Map<String, dynamic> m) {
    return GrowthJourney(
      id: m['id'] as String,
      title: (m['title'] as String?) ?? '',
      reason: (m['reason'] as String?) ?? '',
      successCriteria: (m['successCriteria'] as String?) ?? '',
      startAt: m['startAt'] != null ? DateTime.tryParse('${m['startAt']}') : null,
      endAt: m['endAt'] != null ? DateTime.tryParse('${m['endAt']}') : null,
      programIds: (m['programIds'] as List?)?.map((e) => '$e').toList() ?? const [],
      status: JourneyStatus.values.firstWhere(
        (e) => e.name == m['status'],
        orElse: () => JourneyStatus.draft,
      ),
      createdAt: DateTime.tryParse('${m['createdAt']}') ?? DateTime.now(),
      updatedAt: DateTime.tryParse('${m['updatedAt']}') ?? DateTime.now(),
    );
  }
}
