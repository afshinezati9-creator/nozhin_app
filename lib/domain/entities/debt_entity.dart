import 'package:equatable/equatable.dart';

enum DebtType { owe, owed } // بدهکار / طلبکار

class DebtEntity extends Equatable {
  final String id;
  final DebtType type;
  final String name;
  final double amount;
  final String? dueDate;
  final String? note;
  final DateTime createdAt;

  const DebtEntity({
    required this.id,
    required this.type,
    required this.name,
    required this.amount,
    this.dueDate,
    this.note,
    required this.createdAt,
  });

  DebtEntity copyWith({
    String? id,
    DebtType? type,
    String? name,
    double? amount,
    String? dueDate,
    String? note,
    DateTime? createdAt,
  }) {
    return DebtEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, type, name, amount, dueDate, note, createdAt];
}
