import '../../../core/domain/entities/expense_balance_data.dart';

/// Adaptateur pour convertir les dépenses de différents modules en ExpenseBalanceData.
abstract class ExpenseBalanceAdapter {
  /// Convertit une liste de dépenses du module en ExpenseBalanceData.
  List<ExpenseBalanceData> convertToBalanceData(List<dynamic> expenses);

  /// Retourne la liste des catégories disponibles pour ce module.
  List<String> getCategories();

  /// Retourne le libellé d'une catégorie.
  String getCategoryLabel(String category);
}

