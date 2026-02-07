import '../entities/expense.dart';

/// Repository for managing expenses.
abstract class ExpenseRepository {
  Future<List<Expense>> fetchExpenses({int limit = 50});
  Future<Expense?> getExpense(String id);
  Future<String> createExpense(Expense expense);
  Future<void> deleteExpense(String id, {String? deletedBy});
  Future<void> restoreExpense(String id);
  Future<List<Expense>> getDeletedExpenses();
  Future<List<Expense>> getExpensesInPeriod(DateTime start, DateTime end);
  Stream<List<Expense>> watchExpenses({int limit = 50});
  Stream<List<Expense>> watchDeletedExpenses();
}
