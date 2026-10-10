import 'package:equatable/equatable.dart';

class HabitEntity extends Equatable {
  final String id;
  final String title;
  final String? icon;
  final String color;
  final List<String> completedDays; // 'YYYY-MM-DD' میلادی برای دقت ذخیره
  final DateTime createdAt;
  final bool archived;

  const HabitEntity({
    required this.id,
    required this.title,
    this.icon,
    this.color = 'purple',
    this.completedDays = const [],
    required this.createdAt,
    this.archived = false,
  });

  bool isDoneOn(DateTime day) {
    final key =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return completedDays.contains(key);
  }

  HabitEntity copyWith({
    String? id,
    String? title,
    String? icon,
    String? color,
    List<String>? completedDays,
    DateTime? createdAt,
    bool? archived,
  }) {
    return HabitEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      completedDays: completedDays ?? this.completedDays,
      createdAt: createdAt ?? this.createdAt,
      archived: archived ?? this.archived,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, icon, color, completedDays, createdAt, archived];
}
