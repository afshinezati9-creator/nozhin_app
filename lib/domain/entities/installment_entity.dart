import 'package:equatable/equatable.dart';

class InstallmentEntity extends Equatable {
  final String id;
  final String title;
  final double totalAmount;
  final int totalCount;
  final int paidCount;
  final double installmentAmount;
  final String? dueDay; // روز سررسید در ماه
  final String? note;
  final String? accountId;
  final DateTime createdAt;

  const InstallmentEntity({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.totalCount,
    this.paidCount = 0,
    required this.installmentAmount,
    this.dueDay,
    this.note,
    this.accountId,
    required this.createdAt,
  });

  double get remainingAmount =>
      (totalAmount - (paidCount * installmentAmount)).clamp(0, totalAmount);

  int get remainingCount => (totalCount - paidCount).clamp(0, totalCount);

  bool get isDone => paidCount >= totalCount;

  double get progress =>
      totalCount == 0 ? 0 : (paidCount / totalCount).clamp(0.0, 1.0);

  InstallmentEntity copyWith({
    String? id,
    String? title,
    double? totalAmount,
    int? totalCount,
    int? paidCount,
    double? installmentAmount,
    String? dueDay,
    String? note,
    String? accountId,
    DateTime? createdAt,
  }) {
    return InstallmentEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      totalCount: totalCount ?? this.totalCount,
      paidCount: paidCount ?? this.paidCount,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      dueDay: dueDay ?? this.dueDay,
      note: note ?? this.note,
      accountId: accountId ?? this.accountId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        totalAmount,
        totalCount,
        paidCount,
        installmentAmount,
        dueDay,
        note,
        accountId,
        createdAt,
      ];
}
