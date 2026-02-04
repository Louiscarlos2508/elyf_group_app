import '../entities/expense_record.dart';

/// Handles expenses and charge tracking.
abstract class FinanceRepository {
  Future<List<ExpenseRecord>> fetchRecentExpenses({int limit = 10});
  Future<List<ExpenseRecord>> fetchExpenses({
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Stream<List<ExpenseRecord>> watchExpenses({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<String> createExpense(ExpenseRecord expense);
  Future<void> updateExpense(ExpenseRecord expense);
}
