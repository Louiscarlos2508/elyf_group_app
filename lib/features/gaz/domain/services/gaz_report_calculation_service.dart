import '../entities/expense.dart';
import '../entities/gas_sale.dart';

/// Service for calculating report metrics for the Gaz module.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class GazReportCalculationService {
  GazReportCalculationService();

  /// Filters sales by date range.
  List<GasSale> filterSalesByDateRange({
    required List<GasSale> sales,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return sales.where((s) {
      return s.saleDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          s.saleDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Filters expenses by date range.
  List<GazExpense> filterExpensesByDateRange({
    required List<GazExpense> expenses,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return expenses.where((e) {
      return e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          e.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Separates sales by type (retail/wholesale).
  ({List<GasSale> retailSales, List<GasSale> wholesaleSales})
  separateSalesByType(List<GasSale> sales) {
    final retailSales = sales
        .where((s) => s.saleType == SaleType.retail)
        .toList();
    final wholesaleSales = sales
        .where((s) => s.saleType == SaleType.wholesale)
        .toList();
    return (retailSales: retailSales, wholesaleSales: wholesaleSales);
  }

  /// Calculates total revenue for retail sales.
  double calculateRetailTotal(List<GasSale> retailSales) {
    return retailSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  }

  /// Calculates total revenue for wholesale sales.
  double calculateWholesaleTotal(List<GasSale> wholesaleSales) {
    return wholesaleSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  }

  /// Groups wholesale sales by tour.
  Map<String, ({int count, double total})> groupWholesaleSalesByTour(
    List<GasSale> wholesaleSales,
  ) {
    final byTour = <String, ({int count, double total})>{};
    for (final sale in wholesaleSales) {
      final tourId = sale.tourId ?? 'Sans tour';
      if (!byTour.containsKey(tourId)) {
        byTour[tourId] = (count: 0, total: 0.0);
      }
      final current = byTour[tourId]!;
      byTour[tourId] = (
        count: current.count + 1,
        total: current.total + sale.totalAmount,
      );
    }
    return byTour;
  }

  /// Groups expenses by category.
  Map<ExpenseCategory, double> groupExpensesByCategory(
    List<GazExpense> expenses,
  ) {
    final byCategory = <ExpenseCategory, double>{};
    for (final expense in expenses) {
      byCategory[expense.category] =
          (byCategory[expense.category] ?? 0) + expense.amount;
    }
    return byCategory;
  }

  /// Calculates average expense amount.
  double calculateAverageExpense(List<GazExpense> expenses) {
    if (expenses.isEmpty) return 0.0;
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    return total / expenses.length;
  }

  /// Calculates total expenses amount.
  double calculateTotalExpenses(List<GazExpense> expenses) {
    return expenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// Calculates sales analysis for a date range.
  SalesAnalysis calculateSalesAnalysis({
    required List<GasSale> sales,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final filteredSales = filterSalesByDateRange(
      sales: sales,
      startDate: startDate,
      endDate: endDate,
    );
    final separated = separateSalesByType(filteredSales);
    final retailTotal = calculateRetailTotal(separated.retailSales);
    final wholesaleTotal = calculateWholesaleTotal(separated.wholesaleSales);
    final wholesaleByTour = groupWholesaleSalesByTour(separated.wholesaleSales);

    return SalesAnalysis(
      totalSales: filteredSales.length,
      retailSales: separated.retailSales,
      retailTotal: retailTotal,
      wholesaleSales: separated.wholesaleSales,
      wholesaleTotal: wholesaleTotal,
      wholesaleByTour: wholesaleByTour,
    );
  }

  /// Calculates expenses analysis for a date range.
  ExpensesAnalysis calculateExpensesAnalysis({
    required List<GazExpense> expenses,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final filteredExpenses = filterExpensesByDateRange(
      expenses: expenses,
      startDate: startDate,
      endDate: endDate,
    );
    final byCategory = groupExpensesByCategory(filteredExpenses);
    final total = calculateTotalExpenses(filteredExpenses);
    final average = calculateAverageExpense(filteredExpenses);

    return ExpensesAnalysis(
      totalExpenses: filteredExpenses.length,
      totalAmount: total,
      averageAmount: average,
      byCategory: byCategory,
    );
  }

  /// Generates CSV headers for sales.
  List<String> getSalesCsvHeaders() {
    return [
      'ID',
      'Date',
      'Type',
      'ID Bouteille',
      'Quantité',
      'Prix Unitaire',
      'Montant Total',
      'Client',
      'Téléphone Client',
      'Tour',
      'Grossiste',
      'Notes'
    ];
  }

  /// Maps a list of gas sales to CSV rows.
  List<List<dynamic>> mapSalesToCsvRows(List<GasSale> sales) {
    return sales.map((sale) {
      return [
        sale.id,
        sale.saleDate.toIso8601String(),
        sale.saleType.label,
        sale.cylinderId,
        sale.quantity,
        sale.unitPrice,
        sale.totalAmount,
        sale.customerName ?? '',
        sale.customerPhone ?? '',
        sale.tourId ?? '',
        sale.wholesalerName ?? '',
        sale.notes ?? '',
      ];
    }).toList();
  }

  /// Generates CSV headers for expenses.
  List<String> getExpensesCsvHeaders() {
    return [
      'ID',
      'Date',
      'Catégorie',
      'Description',
      'Montant',
      'Type',
      'Notes'
    ];
  }

  /// Maps a list of gas expenses to CSV rows.
  List<List<dynamic>> mapExpensesToCsvRows(List<GazExpense> expenses) {
    return expenses.map((expense) {
      return [
        expense.id,
        expense.date.toIso8601String(),
        expense.category.label,
        expense.description,
        expense.amount,
        expense.isFixed ? 'Fixe' : 'Variable',
        expense.notes ?? '',
      ];
    }).toList();
  }
}

/// Sales analysis result.
class SalesAnalysis {
  const SalesAnalysis({
    required this.totalSales,
    required this.retailSales,
    required this.retailTotal,
    required this.wholesaleSales,
    required this.wholesaleTotal,
    required this.wholesaleByTour,
  });

  final int totalSales;
  final List<GasSale> retailSales;
  final double retailTotal;
  final List<GasSale> wholesaleSales;
  final double wholesaleTotal;
  final Map<String, ({int count, double total})> wholesaleByTour;
}

/// Expenses analysis result.
class ExpensesAnalysis {
  const ExpensesAnalysis({
    required this.totalExpenses,
    required this.totalAmount,
    required this.averageAmount,
    required this.byCategory,
  });

  final int totalExpenses;
  final double totalAmount;
  final double averageAmount;
  final Map<ExpenseCategory, double> byCategory;
}
