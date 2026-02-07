import '../entities/expense.dart';

/// Repository abstrait pour la gestion des dépenses.
abstract class PropertyExpenseRepository {
  /// Récupère toutes les dépenses.
  Future<List<PropertyExpense>> getAllExpenses();

  /// Récupère une dépense par son ID.
  Future<PropertyExpense?> getExpenseById(String id);

  /// Récupère les dépenses par propriété.
  Future<List<PropertyExpense>> getExpensesByProperty(String propertyId);

  /// Récupère les dépenses par catégorie.
  Future<List<PropertyExpense>> getExpensesByCategory(ExpenseCategory category);

  /// Récupère les dépenses par période.
  Future<List<PropertyExpense>> getExpensesByPeriod(
    DateTime start,
    DateTime end,
  );

  /// Crée une nouvelle dépense.
  Future<PropertyExpense> createExpense(PropertyExpense expense);

  /// Met à jour une dépense existante.
  Future<PropertyExpense> updateExpense(PropertyExpense expense);

  /// Observe les dépenses.
  Stream<List<PropertyExpense>> watchExpenses();

  /// Observe les dépenses supprimées.
  Stream<List<PropertyExpense>> watchDeletedExpenses();

  /// Supprime une dépense.
  Future<void> deleteExpense(String id);

  /// Restaure une dépense supprimée.
  Future<void> restoreExpense(String id);
}
