import '../entities/expense.dart';

/// Expense management repository.
abstract class ExpenseRepository {
  Future<List<Expense>> fetchExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  });
  Future<Expense?> getExpense(String id);
  Future<String> createExpense(Expense expense);
  Future<void> deleteExpense(String id);
  Future<int> getMonthExpenses(DateTime month);
  Future<Map<String, int>> getExpensesByType(DateTime month);
}
