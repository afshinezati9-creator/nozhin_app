import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/finance_constants.dart';
import '../../core/utils/jalali.dart';
import '../../core/utils/money_format.dart';
import '../../data/repositories/finance_repository.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/emergency_fund_entity.dart';
import '../../domain/entities/fin_goal_entity.dart';
import '../../domain/entities/installment_entity.dart';
import '../../domain/entities/transaction_entity.dart';

class FinanceState {
  final List<AccountEntity> accounts;
  final List<TransactionEntity> transactions;
  final List<DebtEntity> debts;
  final List<InstallmentEntity> installments;
  final List<BudgetEntity> budgets;
  final List<FinGoalEntity> goals;
  final EmergencyFundEntity emergency;
  final bool isLoading;
  final String? error;
  final FinanceSubTab subTab;
  final int viewYear; // شمسی
  final int viewMonth; // شمسی ۱–۱۲

  const FinanceState({
    this.accounts = const [],
    this.transactions = const [],
    this.debts = const [],
    this.installments = const [],
    this.budgets = const [],
    this.goals = const [],
    this.emergency = const EmergencyFundEntity(),
    this.isLoading = false,
    this.error,
    this.subTab = FinanceSubTab.overview,
    this.viewYear = 1403,
    this.viewMonth = 1,
  });

  FinanceState copyWith({
    List<AccountEntity>? accounts,
    List<TransactionEntity>? transactions,
    List<DebtEntity>? debts,
    List<InstallmentEntity>? installments,
    List<BudgetEntity>? budgets,
    List<FinGoalEntity>? goals,
    EmergencyFundEntity? emergency,
    bool? isLoading,
    String? error,
    bool clearError = false,
    FinanceSubTab? subTab,
    int? viewYear,
    int? viewMonth,
  }) {
    return FinanceState(
      accounts: accounts ?? this.accounts,
      transactions: transactions ?? this.transactions,
      debts: debts ?? this.debts,
      installments: installments ?? this.installments,
      budgets: budgets ?? this.budgets,
      goals: goals ?? this.goals,
      emergency: emergency ?? this.emergency,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      subTab: subTab ?? this.subTab,
      viewYear: viewYear ?? this.viewYear,
      viewMonth: viewMonth ?? this.viewMonth,
    );
  }

  double get totalBalance =>
      accounts.fold<double>(0, (s, a) => s + a.balance);

  double get totalDebtOwe => debts
      .where((d) => d.type == DebtType.owe)
      .fold<double>(0, (s, d) => s + d.amount);

  double get totalDebtOwed => debts
      .where((d) => d.type == DebtType.owed)
      .fold<double>(0, (s, d) => s + d.amount);

  /// تراکنش‌های ماه شمسی انتخاب‌شده
  List<TransactionEntity> get monthTransactions {
    return transactions.where((t) {
      final j = Jalali.fromDateTime(t.date);
      return j.year == viewYear && j.month == viewMonth;
    }).toList();
  }

  double get monthIncome => monthTransactions
      .where((t) => t.type == TransactionType.income)
      .fold<double>(0, (s, t) => s + t.amount);

  double get monthExpense => monthTransactions
      .where((t) => t.type == TransactionType.expense)
      .fold<double>(0, (s, t) => s + t.amount);

  Map<String, double> get expenseByCategory {
    final map = <String, double>{};
    for (final t in monthTransactions) {
      if (t.type != TransactionType.expense) continue;
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  List<BudgetEntity> get monthBudgets => budgets
      .where((b) => b.year == viewYear && b.month == viewMonth)
      .toList();

  /// هزینه/درآمد ۶ ماه اخیر (از ماه انتخاب‌شده به عقب)
  List<({int year, int month, String label, double expense, double income})>
      get last6Months {
    final months = <({int year, int month, String label, double expense, double income})>[];
    var y = viewYear;
    var m = viewMonth;
    const names = [
      'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
      'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
    ];
    for (var i = 0; i < 6; i++) {
      final yy = y;
      final mm = m;
      double exp = 0, inc = 0;
      for (final t in transactions) {
        final j = Jalali.fromDateTime(t.date);
        if (j.year == yy && j.month == mm) {
          if (t.type == TransactionType.expense) exp += t.amount;
          if (t.type == TransactionType.income) inc += t.amount;
        }
      }
      months.add((
        year: yy,
        month: mm,
        label: names[mm - 1],
        expense: exp,
        income: inc,
      ));
      m--;
      if (m < 1) {
        m = 12;
        y--;
      }
    }
    return months.reversed.toList();
  }

  double get monthBalance => monthIncome - monthExpense;
}


class FinanceNotifier extends StateNotifier<FinanceState> {
  FinanceNotifier() : super(_initial()) {
    load();
  }

  final _repo = FinanceRepository();

  static FinanceState _initial() {
    final ym = MoneyFormat.currentJalaliYm();
    return FinanceState(viewYear: ym.$1, viewMonth: ym.$2);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final accounts = await _repo.getAccounts();
      final transactions = await _repo.getTransactions();
      final debts = await _repo.getDebts();
      final installments = await _repo.getInstallments();
      final budgets = await _repo.getBudgets();
      final goals = await _repo.getGoals();
      final emergency = await _repo.getEmergency();
      state = state.copyWith(
        accounts: accounts,
        transactions: transactions,
        debts: debts,
        installments: installments,
        budgets: budgets,
        goals: goals,
        emergency: emergency,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSubTab(FinanceSubTab tab) {
    state = state.copyWith(subTab: tab);
  }

  void setViewMonth(int year, int month) {
    state = state.copyWith(viewYear: year, viewMonth: month);
  }

  // Accounts
  Future<void> addAccount({
    required String name,
    required AccountType type,
    double balance = 0,
  }) async {
    await _repo.createAccount(name: name, type: type, balance: balance);
    await load();
  }

  Future<void> updateAccount(AccountEntity a) async {
    await _repo.updateAccount(a);
    await load();
  }

  Future<void> deleteAccount(String id) async {
    await _repo.deleteAccount(id);
    await load();
  }

  // Transactions
  Future<void> addTransaction(TransactionEntity t) async {
    await _repo.createTransaction(t);
    await load();
  }

  Future<void> deleteTransaction(String id) async {
    await _repo.deleteTransaction(id);
    await load();
  }

  Future<void> updateTransaction(
      TransactionEntity oldTx, TransactionEntity newTx) async {
    await _repo.updateTransaction(oldTx, newTx);
    await load();
  }

  // Debts
  Future<void> addDebt(DebtEntity d) async {
    await _repo.createDebt(d);
    await load();
  }

  Future<void> updateDebt(DebtEntity d) async {
    await _repo.updateDebt(d);
    await load();
  }

  Future<void> deleteDebt(String id) async {
    await _repo.deleteDebt(id);
    await load();
  }

  // Installments
  Future<void> addInstallment(InstallmentEntity i) async {
    await _repo.createInstallment(i);
    await load();
  }

  Future<void> updateInstallment(InstallmentEntity i) async {
    await _repo.updateInstallment(i);
    await load();
  }

  Future<void> deleteInstallment(String id) async {
    await _repo.deleteInstallment(id);
    await load();
  }

  // Budgets
  Future<void> upsertBudget(BudgetEntity b) async {
    await _repo.upsertBudget(b);
    await load();
  }

  Future<void> deleteBudget(String id) async {
    await _repo.deleteBudget(id);
    await load();
  }

  // Goals
  Future<void> addGoal(FinGoalEntity g) async {
    await _repo.createGoal(g);
    await load();
  }

  Future<void> updateGoal(FinGoalEntity g) async {
    await _repo.updateGoal(g);
    await load();
  }

  Future<void> deleteGoal(String id) async {
    await _repo.deleteGoal(id);
    await load();
  }

  // Emergency
  Future<void> saveEmergency(EmergencyFundEntity e) async {
    await _repo.saveEmergency(e);
    await load();
  }
}

final financeProvider =
    StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  return FinanceNotifier();
});
