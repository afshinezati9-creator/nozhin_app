import 'package:equatable/equatable.dart';

class BudgetEntity extends Equatable {
  final String id;
  final String category;
  final double limit;
  final int year; // شمسی
  final int month; // ۱–۱۲ شمسی

  const BudgetEntity({
    required this.id,
    required this.category,
    required this.limit,
    required this.year,
    required this.month,
  });

  BudgetEntity copyWith({
    String? id,
    String? category,
    double? limit,
    int? year,
    int? month,
  }) {
    return BudgetEntity(
      id: id ?? this.id,
      category: category ?? this.category,
      limit: limit ?? this.limit,
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }

  @override
  List<Object?> get props => [id, category, limit, year, month];
}
