import '../../domain/entities/expense_record.dart';
import '../../domain/repositories/finance_repository.dart';

class FinancesController {
  FinancesController(this._repository);

  final FinanceRepository _repository;

  Future<FinancesState> fetchRecentExpenses() async {
    final expenses = await _repository.fetchRecentExpenses(limit: 4);
    return FinancesState(expenses: expenses);
  }

  Future<String> createExpense(ExpenseRecord expense) async {
    return await _repository.createExpense(expense);
  }
}

class FinancesState {
  const FinancesState({required this.expenses});

  final List<ExpenseRecord> expenses;

  int get totalCharges =>
      expenses.fold(0, (value, expense) => value + expense.amountCfa);
}
