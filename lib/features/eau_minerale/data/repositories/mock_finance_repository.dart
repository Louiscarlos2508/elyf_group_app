import 'dart:async';

import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/expense_record.dart';
import '../../domain/repositories/finance_repository.dart';

class MockFinanceRepository implements FinanceRepository {
  final _expenses = <String, ExpenseRecord>{};

  MockFinanceRepository() {
    // Initialize with sample data
    for (var i = 0; i < 4; i++) {
      _expenses['expense-$i'] = ExpenseRecord.sample(i);
    }
  }

  @override
  Future<List<ExpenseRecord>> fetchRecentExpenses({int limit = 10}) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final expenses = _expenses.values.toList();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses.take(limit).toList();
  }

  @override
  Future<String> createExpense(ExpenseRecord expense) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final id = expense.id.isEmpty ? 'expense-${_expenses.length}' : expense.id;
    _expenses[id] = ExpenseRecord(
      id: id,
      label: expense.label,
      amountCfa: expense.amountCfa,
      category: expense.category,
      date: expense.date,
      productionId: expense.productionId,
      notes: expense.notes,
      createdAt: expense.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return id;
  }

  @override
  Future<void> updateExpense(ExpenseRecord expense) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!_expenses.containsKey(expense.id)) {
      throw NotFoundException(
        'Dépense introuvable',
        'EXPENSE_NOT_FOUND',
      );
    }
    _expenses[expense.id] = expense.copyWith(updatedAt: DateTime.now());
  }
}
