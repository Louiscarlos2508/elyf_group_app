import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

/// Implémentation mock du repository des dépenses gaz.
class MockGazExpenseRepository implements GazExpenseRepository {
  final List<GazExpense> _expenses = [];

  @override
  Future<List<GazExpense>> getExpenses({DateTime? from, DateTime? to}) async {
    return _expenses.where((e) {
      if (from != null && e.date.isBefore(from)) return false;
      if (to != null && e.date.isAfter(to)) return false;
      return true;
    }).toList();
  }

  @override
  Future<GazExpense?> getExpenseById(String id) async {
    return _expenses.where((e) => e.id == id).firstOrNull;
  }

  @override
  Future<void> addExpense(GazExpense expense) async {
    _expenses.add(expense);
  }

  @override
  Future<void> updateExpense(GazExpense expense) async {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) _expenses[index] = expense;
  }

  @override
  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
  }

  @override
  Future<double> getTotalExpenses({DateTime? from, DateTime? to}) async {
    final expenses = await getExpenses(from: from, to: to);
    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }
}
