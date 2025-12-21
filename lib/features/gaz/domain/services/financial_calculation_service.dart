import '../entities/expense.dart';
import '../entities/loading_event.dart';
import '../repositories/expense_repository.dart';
import '../repositories/loading_event_repository.dart';

/// Service de calcul financier pour les rapports et reliquat siège.
class FinancialCalculationService {
  const FinancialCalculationService({
    required this.expenseRepository,
    required this.loadingEventRepository,
  });

  final GazExpenseRepository expenseRepository;
  final LoadingEventRepository loadingEventRepository;

  /// Calcule les charges totales pour une période.
  Future<({
    double fixedCharges,
    double variableCharges,
    double salaries,
    double loadingEventExpenses,
    double totalExpenses,
  })> calculateCharges(
    String enterpriseId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final expenses = await expenseRepository.getExpenses(
      from: startDate,
      to: endDate,
    );

    // Filtrer par entreprise
    final enterpriseExpenses = expenses.where(
      (e) => e.enterpriseId == enterpriseId,
    ).toList();

    double fixedCharges = 0.0;
    double variableCharges = 0.0;
    double salaries = 0.0;

    for (final expense in enterpriseExpenses) {
      if (expense.category == ExpenseCategory.salaries) {
        salaries += expense.amount;
      } else if (expense.isFixed) {
        fixedCharges += expense.amount;
      } else {
        variableCharges += expense.amount;
      }
    }

    // Calculer les frais de chargement
    final loadingEvents = await loadingEventRepository.getLoadingEvents(
      enterpriseId,
      from: startDate,
      to: endDate,
    );

    double loadingEventExpenses = 0.0;
    for (final event in loadingEvents) {
      loadingEventExpenses += event.totalExpenses;
    }

    final totalExpenses =
        fixedCharges + variableCharges + salaries + loadingEventExpenses;

    return (
      fixedCharges: fixedCharges,
      variableCharges: variableCharges,
      salaries: salaries,
      loadingEventExpenses: loadingEventExpenses,
      totalExpenses: totalExpenses,
    );
  }

  /// Calcule le reliquat net (revenus - toutes dépenses).
  Future<double> calculateNetAmount(
    String enterpriseId,
    DateTime startDate,
    DateTime endDate,
    double totalRevenue,
  ) async {
    final charges = await calculateCharges(
      enterpriseId,
      startDate,
      endDate,
    );

    return totalRevenue - charges.totalExpenses;
  }

  /// Agrège les dépenses par catégorie.
  Future<Map<ExpenseCategory, double>> aggregateExpensesByCategory(
    String enterpriseId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final expenses = await expenseRepository.getExpenses(
      from: startDate,
      to: endDate,
    );

    final enterpriseExpenses = expenses.where(
      (e) => e.enterpriseId == enterpriseId,
    ).toList();

    final Map<ExpenseCategory, double> aggregated = {};

    for (final expense in enterpriseExpenses) {
      aggregated[expense.category] =
          (aggregated[expense.category] ?? 0.0) + expense.amount;
    }

    return aggregated;
  }
}