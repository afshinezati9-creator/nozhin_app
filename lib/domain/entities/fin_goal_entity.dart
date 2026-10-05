import 'package:equatable/equatable.dart';

class FinGoalEntity extends Equatable {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String? deadline; // تاریخ شمسی متنی
  final String? note;
  final DateTime createdAt;

  const FinGoalEntity({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    this.note,
    required this.createdAt,
  });

  double get progress => targetAmount <= 0
      ? 0
      : (currentAmount / targetAmount).clamp(0.0, 1.0);

  bool get isDone => currentAmount >= targetAmount;

  FinGoalEntity copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    String? deadline,
    String? note,
    DateTime? createdAt,
  }) {
    return FinGoalEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, targetAmount, currentAmount, deadline, note, createdAt];
}
