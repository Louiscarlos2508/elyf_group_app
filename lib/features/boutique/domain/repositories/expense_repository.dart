import '../entities/expense.dart';

/// Repository for managing expenses.
abstract class ExpenseRepository {
  Future<List<Expense>> fetchExpenses({int limit = 50});
  Future<Expense?> getExpense(String id);
  Future<String> createExpense(Expense expense);
  Future<void> deleteExpense(String id);
}

