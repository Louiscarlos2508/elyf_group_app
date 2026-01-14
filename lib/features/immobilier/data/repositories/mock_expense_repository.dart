import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

class MockPropertyExpenseRepository implements PropertyExpenseRepository {
  final _expenses = <String, PropertyExpense>{};

  MockPropertyExpenseRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();
    final expenses = [
      PropertyExpense(
        id: 'expense-1',
        propertyId: 'prop-1',
        amount: 50000,
        expenseDate: now.subtract(const Duration(days: 15)),
        category: ExpenseCategory.maintenance,
        description: 'Réparation de la toiture',
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      PropertyExpense(
        id: 'expense-2',
        propertyId: 'prop-2',
        amount: 25000,
        expenseDate: now.subtract(const Duration(days: 7)),
        category: ExpenseCategory.repair,
        description: 'Réparation plomberie',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    ];

    for (final expense in expenses) {
      _expenses[expense.id] = expense;
    }
  }

  @override
  Future<List<PropertyExpense>> getAllExpenses() async {
    return _expenses.values.toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
  }

  @override
  Future<PropertyExpense?> getExpenseById(String id) async {
    return _expenses[id];
  }

  @override
  Future<List<PropertyExpense>> getExpensesByProperty(String propertyId) async {
    return _expenses.values.where((e) => e.propertyId == propertyId).toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
  }

  @override
  Future<List<PropertyExpense>> getExpensesByCategory(
    ExpenseCategory category,
  ) async {
    return _expenses.values.where((e) => e.category == category).toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
  }

  @override
  Future<List<PropertyExpense>> getExpensesByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    return _expenses.values.where((e) {
      return e.expenseDate.isAfter(start.subtract(const Duration(days: 1))) &&
          e.expenseDate.isBefore(end.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
  }

  @override
  Future<PropertyExpense> createExpense(PropertyExpense expense) async {
    final now = DateTime.now();
    final newExpense = PropertyExpense(
      id: expense.id,
      propertyId: expense.propertyId,
      amount: expense.amount,
      expenseDate: expense.expenseDate,
      category: expense.category,
      description: expense.description,
      property: expense.property,
      receipt: expense.receipt,
      createdAt: now,
      updatedAt: now,
    );
    _expenses[expense.id] = newExpense;
    return newExpense;
  }

  @override
  Future<PropertyExpense> updateExpense(PropertyExpense expense) async {
    final existing = _expenses[expense.id];
    if (existing == null) {
      throw Exception('Expense not found');
    }
    final updated = PropertyExpense(
      id: expense.id,
      propertyId: expense.propertyId,
      amount: expense.amount,
      expenseDate: expense.expenseDate,
      category: expense.category,
      description: expense.description,
      property: expense.property,
      receipt: expense.receipt,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    _expenses[expense.id] = updated;
    return updated;
  }

  @override
  Future<void> deleteExpense(String id) async {
    _expenses.remove(id);
  }
}
