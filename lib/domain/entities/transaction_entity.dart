import 'package:equatable/equatable.dart';

enum TransactionType { income, expense, saving, transfer }

class TransactionEntity extends Equatable {
  final String id;
  final TransactionType type;
  final String title;
  final double amount;
  final String category;
  final String? description;
  final String accountId;
  /// فقط برای انتقال: حساب مقصد
  final String? toAccountId;
  final DateTime date;

  const TransactionEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.category,
    this.description,
    required this.accountId,
    this.toAccountId,
    required this.date,
  });

  TransactionEntity copyWith({
    String? id,
    TransactionType? type,
    String? title,
    double? amount,
    String? category,
    String? description,
    String? accountId,
    String? toAccountId,
    bool clearToAccount = false,
    DateTime? date,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      accountId: accountId ?? this.accountId,
      toAccountId:
          clearToAccount ? null : (toAccountId ?? this.toAccountId),
      date: date ?? this.date,
    );
  }

  String get typeLabel {
    switch (type) {
      case TransactionType.income:
        return 'درآمد';
      case TransactionType.expense:
        return 'هزینه';
      case TransactionType.saving:
        return 'پس‌انداز';
      case TransactionType.transfer:
        return 'انتقال';
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        amount,
        category,
        description,
        accountId,
        toAccountId,
        date,
      ];
}
