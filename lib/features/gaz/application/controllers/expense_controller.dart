import 'package:flutter/material.dart';

import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

/// Contrôleur pour la gestion des dépenses gaz.
class GazExpenseController extends ChangeNotifier {
  GazExpenseController(this._repository);

  final GazExpenseRepository _repository;

  List<GazExpense> _expenses = [];
  bool _isLoading = false;

  List<GazExpense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  Future<void> loadExpenses({DateTime? from, DateTime? to}) async {
    _isLoading = true;
    notifyListeners();

    _expenses = await _repository.getExpenses(from: from, to: to);

    _isLoading = false;
    notifyListeners();
  }

  /// Observe les dépenses en temps réel.
  Stream<List<GazExpense>> watchExpenses({DateTime? from, DateTime? to}) {
    return _repository.watchExpenses(from: from, to: to);
  }

  Future<void> addExpense(GazExpense expense) async {
    await _repository.addExpense(expense);
    await loadExpenses();
  }

  Future<void> updateExpense(GazExpense expense) async {
    await _repository.updateExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await _repository.deleteExpense(id);
    await loadExpenses();
  }

  Future<double> getTotalExpenses({DateTime? from, DateTime? to}) async {
    return _repository.getTotalExpenses(from: from, to: to);
  }
}
