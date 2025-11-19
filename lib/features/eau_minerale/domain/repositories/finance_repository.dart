import '../entities/expense_record.dart';

/// Handles expenses and charge tracking.
abstract class FinanceRepository {
  Future<List<ExpenseRecord>> fetchRecentExpenses({int limit = 10});
  Future<String> createExpense(ExpenseRecord expense);
}
