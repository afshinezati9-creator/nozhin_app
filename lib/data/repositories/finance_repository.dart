import '../../core/services/local_database.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/emergency_fund_entity.dart';
import '../../domain/entities/fin_goal_entity.dart';
import '../../domain/entities/installment_entity.dart';
import '../../domain/entities/transaction_entity.dart';

class FinanceRepository {
  final _db = LocalDatabase.instance;

  // ─── Account ───────────────────────────────────────────

  AccountEntity _accountFrom(Map<String, dynamic> m) {
    return AccountEntity(
      id: m['id'] as String,
      name: m['name'] as String? ?? '',
      type: AccountType.values.firstWhere(
        (e) => e.name == (m['type'] as String? ?? 'bank'),
        orElse: () => AccountType.bank,
      ),
      balance: (m['balance'] as num?)?.toDouble() ?? 0,
      icon: m['icon'] as String? ?? 'bank',
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _accountTo(AccountEntity a) => {
        'id': a.id,
        'name': a.name,
        'type': a.type.name,
        'balance': a.balance,
        'icon': a.icon,
        'createdAt': a.createdAt.toIso8601String(),
      };

  Future<List<AccountEntity>> getAccounts() async {
    final items = await _db.readAll(Collections.accounts);
    return items.map(_accountFrom).toList();
  }

  Future<AccountEntity> createAccount({
    required String name,
    required AccountType type,
    double balance = 0,
    String icon = 'bank',
  }) async {
    final a = AccountEntity(
      id: _db.generateId(),
      name: name,
      type: type,
      balance: balance,
      icon: icon,
      createdAt: DateTime.now(),
    );
    await _db.insert(Collections.accounts, _accountTo(a));
    return a;
  }

  Future<void> updateAccount(AccountEntity a) async {
    await _db.update(Collections.accounts, a.id, _accountTo(a));
  }

  Future<void> deleteAccount(String id) async {
    await _db.delete(Collections.accounts, id);
  }

  Future<void> adjustAccountBalance(String accountId, double delta) async {
    final m = await _db.findById(Collections.accounts, accountId);
    if (m == null) return;
    final a = _accountFrom(m);
    await updateAccount(a.copyWith(balance: a.balance + delta));
  }

  // ─── Transaction ───────────────────────────────────────

  TransactionEntity _txFrom(Map<String, dynamic> m) {
    return TransactionEntity(
      id: m['id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == (m['type'] as String? ?? 'expense'),
        orElse: () => TransactionType.expense,
      ),
      title: m['title'] as String? ?? '',
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      category: m['category'] as String? ?? 'سایر',
      description: m['description'] as String?,
      accountId: m['accountId'] as String? ?? '',
      toAccountId: m['toAccountId'] as String?,
      date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _txTo(TransactionEntity t) => {
        'id': t.id,
        'type': t.type.name,
        'title': t.title,
        'amount': t.amount,
        'category': t.category,
        'description': t.description,
        'accountId': t.accountId,
        'toAccountId': t.toAccountId,
        'date': t.date.toIso8601String(),
      };

  Future<void> _applyTxBalance(TransactionEntity tx, {required bool reverse}) async {
    final sign = reverse ? -1.0 : 1.0;
    switch (tx.type) {
      case TransactionType.income:
      case TransactionType.saving:
        if (tx.accountId.isNotEmpty) {
          await adjustAccountBalance(tx.accountId, sign * tx.amount);
        }
        break;
      case TransactionType.expense:
        if (tx.accountId.isNotEmpty) {
          await adjustAccountBalance(tx.accountId, -sign * tx.amount);
        }
        break;
      case TransactionType.transfer:
        if (tx.accountId.isNotEmpty) {
          await adjustAccountBalance(tx.accountId, -sign * tx.amount);
        }
        if (tx.toAccountId != null && tx.toAccountId!.isNotEmpty) {
          await adjustAccountBalance(tx.toAccountId!, sign * tx.amount);
        }
        break;
    }
  }

  Future<List<TransactionEntity>> getTransactions() async {
    final items = await _db.readAll(Collections.transactions);
    return items.map(_txFrom).toList();
  }

  Future<TransactionEntity> createTransaction(TransactionEntity t) async {
    final tx = TransactionEntity(
      id: t.id.isNotEmpty ? t.id : _db.generateId(),
      type: t.type,
      title: t.title,
      amount: t.amount,
      category: t.category,
      description: t.description,
      accountId: t.accountId,
      toAccountId: t.toAccountId,
      date: t.date,
    );
    await _db.insert(Collections.transactions, _txTo(tx));
    await _applyTxBalance(tx, reverse: false);
    return tx;
  }

  Future<void> deleteTransaction(String id) async {
    final m = await _db.findById(Collections.transactions, id);
    if (m == null) return;
    final tx = _txFrom(m);
    await _applyTxBalance(tx, reverse: true);
    await _db.delete(Collections.transactions, id);
  }

  Future<void> updateTransaction(
      TransactionEntity oldTx, TransactionEntity newTx) async {
    await _applyTxBalance(oldTx, reverse: true);
    final kept = TransactionEntity(
      id: oldTx.id,
      type: newTx.type,
      title: newTx.title,
      amount: newTx.amount,
      category: newTx.category,
      description: newTx.description,
      accountId: newTx.accountId,
      toAccountId: newTx.toAccountId,
      date: newTx.date,
    );
    await _db.update(Collections.transactions, kept.id, _txTo(kept));
    await _applyTxBalance(kept, reverse: false);
  }

  // ─── Debt ──────────────────────────────────────────────

  DebtEntity _debtFrom(Map<String, dynamic> m) {
    return DebtEntity(
      id: m['id'] as String,
      type: DebtType.values.firstWhere(
        (e) => e.name == (m['type'] as String? ?? 'owe'),
        orElse: () => DebtType.owe,
      ),
      name: m['name'] as String? ?? '',
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      dueDate: m['dueDate'] as String?,
      note: m['note'] as String?,
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _debtTo(DebtEntity d) => {
        'id': d.id,
        'type': d.type.name,
        'name': d.name,
        'amount': d.amount,
        'dueDate': d.dueDate,
        'note': d.note,
        'createdAt': d.createdAt.toIso8601String(),
      };

  Future<List<DebtEntity>> getDebts() async {
    final items = await _db.readAll(Collections.debts);
    return items.map(_debtFrom).toList();
  }

  Future<DebtEntity> createDebt(DebtEntity d) async {
    final debt = DebtEntity(
      id: _db.generateId(),
      type: d.type,
      name: d.name,
      amount: d.amount,
      dueDate: d.dueDate,
      note: d.note,
      createdAt: DateTime.now(),
    );
    await _db.insert(Collections.debts, _debtTo(debt));
    return debt;
  }

  Future<void> updateDebt(DebtEntity d) async {
    await _db.update(Collections.debts, d.id, _debtTo(d));
  }

  Future<void> deleteDebt(String id) async {
    await _db.delete(Collections.debts, id);
  }

  // ─── Installment ───────────────────────────────────────

  InstallmentEntity _instFrom(Map<String, dynamic> m) {
    return InstallmentEntity(
      id: m['id'] as String,
      title: m['title'] as String? ?? '',
      totalAmount: (m['totalAmount'] as num?)?.toDouble() ?? 0,
      totalCount: (m['totalCount'] as num?)?.toInt() ?? 1,
      paidCount: (m['paidCount'] as num?)?.toInt() ?? 0,
      installmentAmount: (m['installmentAmount'] as num?)?.toDouble() ?? 0,
      dueDay: m['dueDay'] as String?,
      note: m['note'] as String?,
      accountId: m['accountId'] as String?,
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _instTo(InstallmentEntity i) => {
        'id': i.id,
        'title': i.title,
        'totalAmount': i.totalAmount,
        'totalCount': i.totalCount,
        'paidCount': i.paidCount,
        'installmentAmount': i.installmentAmount,
        'dueDay': i.dueDay,
        'note': i.note,
        'accountId': i.accountId,
        'createdAt': i.createdAt.toIso8601String(),
      };

  Future<List<InstallmentEntity>> getInstallments() async {
    final items = await _db.readAll(Collections.installments);
    return items.map(_instFrom).toList();
  }

  Future<InstallmentEntity> createInstallment(InstallmentEntity i) async {
    final inst = InstallmentEntity(
      id: _db.generateId(),
      title: i.title,
      totalAmount: i.totalAmount,
      totalCount: i.totalCount,
      paidCount: i.paidCount,
      installmentAmount: i.installmentAmount,
      dueDay: i.dueDay,
      note: i.note,
      accountId: i.accountId,
      createdAt: DateTime.now(),
    );
    await _db.insert(Collections.installments, _instTo(inst));
    return inst;
  }

  Future<void> updateInstallment(InstallmentEntity i) async {
    await _db.update(Collections.installments, i.id, _instTo(i));
  }

  Future<void> deleteInstallment(String id) async {
    await _db.delete(Collections.installments, id);
  }

  // ─── Budget ────────────────────────────────────────────

  BudgetEntity _budgetFrom(Map<String, dynamic> m) {
    return BudgetEntity(
      id: m['id'] as String,
      category: m['category'] as String? ?? '',
      limit: (m['limit'] as num?)?.toDouble() ?? 0,
      year: (m['year'] as num?)?.toInt() ?? 1403,
      month: (m['month'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> _budgetTo(BudgetEntity b) => {
        'id': b.id,
        'category': b.category,
        'limit': b.limit,
        'year': b.year,
        'month': b.month,
      };

  Future<List<BudgetEntity>> getBudgets() async {
    final items = await _db.readAll(Collections.budgets);
    return items.map(_budgetFrom).toList();
  }

  Future<BudgetEntity> upsertBudget(BudgetEntity b) async {
    final all = await getBudgets();
    final existing = all.where(
        (x) => x.category == b.category && x.year == b.year && x.month == b.month);
    if (existing.isNotEmpty) {
      final updated = b.copyWith(id: existing.first.id);
      await _db.update(Collections.budgets, updated.id, _budgetTo(updated));
      return updated;
    }
    final created = BudgetEntity(
      id: _db.generateId(),
      category: b.category,
      limit: b.limit,
      year: b.year,
      month: b.month,
    );
    await _db.insert(Collections.budgets, _budgetTo(created));
    return created;
  }

  Future<void> deleteBudget(String id) async {
    await _db.delete(Collections.budgets, id);
  }

  // ─── Goals ─────────────────────────────────────────────

  FinGoalEntity _goalFrom(Map<String, dynamic> m) {
    return FinGoalEntity(
      id: m['id'] as String,
      title: m['title'] as String? ?? '',
      targetAmount: (m['targetAmount'] as num?)?.toDouble() ?? 0,
      currentAmount: (m['currentAmount'] as num?)?.toDouble() ?? 0,
      deadline: m['deadline'] as String?,
      note: m['note'] as String?,
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _goalTo(FinGoalEntity g) => {
        'id': g.id,
        'title': g.title,
        'targetAmount': g.targetAmount,
        'currentAmount': g.currentAmount,
        'deadline': g.deadline,
        'note': g.note,
        'createdAt': g.createdAt.toIso8601String(),
      };

  Future<List<FinGoalEntity>> getGoals() async {
    final items = await _db.readAll(Collections.finGoals);
    return items.map(_goalFrom).toList();
  }

  Future<FinGoalEntity> createGoal(FinGoalEntity g) async {
    final goal = FinGoalEntity(
      id: _db.generateId(),
      title: g.title,
      targetAmount: g.targetAmount,
      currentAmount: g.currentAmount,
      deadline: g.deadline,
      note: g.note,
      createdAt: DateTime.now(),
    );
    await _db.insert(Collections.finGoals, _goalTo(goal));
    return goal;
  }

  Future<void> updateGoal(FinGoalEntity g) async {
    await _db.update(Collections.finGoals, g.id, _goalTo(g));
  }

  Future<void> deleteGoal(String id) async {
    await _db.delete(Collections.finGoals, id);
  }

  // ─── Emergency fund ────────────────────────────────────

  Future<EmergencyFundEntity> getEmergency() async {
    final items = await _db.readAll(Collections.emergency);
    if (items.isEmpty) return const EmergencyFundEntity();
    final m = items.first;
    return EmergencyFundEntity(
      target: (m['target'] as num?)?.toDouble() ?? 0,
      current: (m['current'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<void> saveEmergency(EmergencyFundEntity e) async {
    await _db.writeAll(Collections.emergency, [
      {'id': 'emergency', 'target': e.target, 'current': e.current},
    ]);
  }
}
