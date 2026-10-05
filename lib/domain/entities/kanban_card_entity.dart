import 'package:equatable/equatable.dart';

enum KanbanColumn { todo, doing, done }

class KanbanCardEntity extends Equatable {
  final String id;
  final String title;
  final String note;
  final int priority; // 1 low … 3 high
  final KanbanColumn column;
  final DateTime createdAt;

  const KanbanCardEntity({
    required this.id,
    required this.title,
    this.note = '',
    this.priority = 2,
    required this.column,
    required this.createdAt,
  });

  KanbanCardEntity copyWith({
    String? id,
    String? title,
    String? note,
    int? priority,
    KanbanColumn? column,
    DateTime? createdAt,
  }) {
    return KanbanCardEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      priority: priority ?? this.priority,
      column: column ?? this.column,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'note': note,
        'priority': priority,
        'column': column.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory KanbanCardEntity.fromMap(Map<String, dynamic> m) {
    final col = m['column'] as String? ?? 'todo';
    return KanbanCardEntity(
      id: m['id'] as String? ?? '',
      title: m['title'] as String? ?? '',
      note: m['note'] as String? ?? '',
      priority: m['priority'] as int? ?? 2,
      column: KanbanColumn.values.firstWhere(
        (e) => e.name == col,
        orElse: () => KanbanColumn.todo,
      ),
      createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, title, note, priority, column, createdAt];
}
