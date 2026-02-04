import '../entities/expense.dart';

/// Interface pour le repository des dépenses gaz.
abstract class GazExpenseRepository {
  Future<List<GazExpense>> getExpenses({DateTime? from, DateTime? to});
  Stream<List<GazExpense>> watchExpenses({DateTime? from, DateTime? to});
  Future<GazExpense?> getExpenseById(String id);
  Future<void> addExpense(GazExpense expense);
  Future<void> updateExpense(GazExpense expense);
  Future<void> deleteExpense(String id);
  Future<double> getTotalExpenses({DateTime? from, DateTime? to});
}
