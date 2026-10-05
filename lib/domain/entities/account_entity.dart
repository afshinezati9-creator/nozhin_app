import 'package:equatable/equatable.dart';

enum AccountType { bank, cash, wallet, savings }

class AccountEntity extends Equatable {
  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final String icon;
  final DateTime createdAt;

  const AccountEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.icon = 'bank',
    required this.createdAt,
  });

  AccountEntity copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    String? icon,
    DateTime? createdAt,
  }) {
    return AccountEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get typeLabel {
    switch (type) {
      case AccountType.bank:
        return 'بانک';
      case AccountType.cash:
        return 'نقد';
      case AccountType.wallet:
        return 'کیف پول';
      case AccountType.savings:
        return 'پس‌انداز';
    }
  }

  @override
  List<Object?> get props => [id, name, type, balance, icon, createdAt];
}
