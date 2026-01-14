import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

class PropertyExpenseController {
  PropertyExpenseController(this._expenseRepository);

  final PropertyExpenseRepository _expenseRepository;

  Future<List<PropertyExpense>> fetchExpenses() async {
    return await _expenseRepository.getAllExpenses();
  }

  Future<PropertyExpense?> getExpense(String id) async {
    return await _expenseRepository.getExpenseById(id);
  }

  Future<List<PropertyExpense>> getExpensesByProperty(String propertyId) async {
    return await _expenseRepository.getExpensesByProperty(propertyId);
  }

  Future<List<PropertyExpense>> getExpensesByCategory(
    ExpenseCategory category,
  ) async {
    return await _expenseRepository.getExpensesByCategory(category);
  }

  Future<List<PropertyExpense>> getExpensesByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    return await _expenseRepository.getExpensesByPeriod(start, end);
  }

  Future<PropertyExpense> createExpense(PropertyExpense expense) async {
    return await _expenseRepository.createExpense(expense);
  }

  Future<PropertyExpense> updateExpense(PropertyExpense expense) async {
    return await _expenseRepository.updateExpense(expense);
  }

  Future<void> deleteExpense(String id) async {
    await _expenseRepository.deleteExpense(id);
  }
}
