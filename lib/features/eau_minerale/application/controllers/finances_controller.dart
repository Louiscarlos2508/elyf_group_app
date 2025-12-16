import '../../domain/entities/expense_record.dart';
import '../../domain/repositories/finance_repository.dart';

class FinancesController {
  FinancesController(this._repository);

  final FinanceRepository _repository;

  Future<FinancesState> fetchRecentExpenses() async {
    // Fetch more expenses to support monthly summary
    final expenses = await _repository.fetchRecentExpenses(limit: 50);
    return FinancesState(expenses: expenses);
  }

  Future<String> createExpense(ExpenseRecord expense) async {
    return await _repository.createExpense(expense);
  }

  Future<void> updateExpense(ExpenseRecord expense) async {
    return await _repository.updateExpense(expense);
  }
}

class FinancesState {
  const FinancesState({required this.expenses});

  final List<ExpenseRecord> expenses;

  int get totalCharges =>
      expenses.fold(0, (value, expense) => value + expense.amountCfa);
}
