import 'dart:async';

import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

class MockExpenseRepository implements ExpenseRepository {
  final _expenses = <String, Expense>{};

  MockExpenseRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();
    final expenses = [
      Expense(
        id: 'expense-1',
        label: 'Loyer du mois',
        amountCfa: 150000,
        category: ExpenseCategory.rent,
        date: now.subtract(const Duration(days: 1)),
      ),
      Expense(
        id: 'expense-2',
        label: 'Facture d\'électricité',
        amountCfa: 25000,
        category: ExpenseCategory.utilities,
        date: now.subtract(const Duration(days: 3)),
      ),
      Expense(
        id: 'expense-3',
        label: 'Réparation réfrigérateur',
        amountCfa: 35000,
        category: ExpenseCategory.maintenance,
        date: now.subtract(const Duration(days: 7)),
      ),
      Expense(
        id: 'expense-4',
        label: 'Publicité radio',
        amountCfa: 50000,
        category: ExpenseCategory.marketing,
        date: now.subtract(const Duration(days: 10)),
      ),
    ];

    for (final expense in expenses) {
      _expenses[expense.id] = expense;
    }
  }

  @override
  Future<List<Expense>> fetchExpenses({int limit = 50}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _expenses.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<Expense?> getExpense(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _expenses[id];
  }

  @override
  Future<String> createExpense(Expense expense) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _expenses[expense.id] = expense;
    return expense.id;
  }

  @override
  Future<void> deleteExpense(String id, {String? deletedBy}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final expense = _expenses[id];
    if (expense != null && !expense.isDeleted) {
      _expenses[id] = Expense(
        id: expense.id,
        label: expense.label,
        amountCfa: expense.amountCfa,
        category: expense.category,
        date: expense.date,
        notes: expense.notes,
        deletedAt: DateTime.now(),
        deletedBy: deletedBy,
      );
    }
  }

  @override
  Future<void> restoreExpense(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final expense = _expenses[id];
    if (expense != null && expense.isDeleted) {
      _expenses[id] = Expense(
        id: expense.id,
        label: expense.label,
        amountCfa: expense.amountCfa,
        category: expense.category,
        date: expense.date,
        notes: expense.notes,
        deletedAt: null,
        deletedBy: null,
      );
    }
  }

  @override
  Future<List<Expense>> getDeletedExpenses() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _expenses.values.where((e) => e.isDeleted).toList()..sort(
      (a, b) => (b.deletedAt ?? DateTime(1970)).compareTo(
        a.deletedAt ?? DateTime(1970),
      ),
    );
  }
}
