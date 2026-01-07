import '../../domain/entities/report_data.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/expense.dart';

/// Service for report calculations.
///
/// Extracts business logic from report generation to make it testable and reusable.
class ReportCalculationService {
  ReportCalculationService();

  /// Filters sales by date range.
  List<Sale> filterSalesByDateRange({
    required List<Sale> sales,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return sales.where((s) {
      return s.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          s.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Filters expenses by date range.
  List<Expense> filterExpensesByDateRange({
    required List<Expense> expenses,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return expenses.where((e) {
      return e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          e.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Calculates total revenue from sales.
  int calculateTotalRevenue(List<Sale> sales) {
    return sales.fold(0, (sum, s) => sum + s.totalPrice);
  }

  /// Calculates total collections from sales.
  int calculateTotalCollections(List<Sale> sales) {
    return sales.fold(0, (sum, s) => sum + s.amountPaid);
  }

  /// Calculates total expenses.
  int calculateTotalExpenses(List<Expense> expenses) {
    return expenses.fold(0, (sum, e) => sum + e.amount);
  }

  /// Calculates profit (revenue - expenses).
  int calculateProfit(int revenue, int expenses) {
    return revenue - expenses;
  }

  /// Calculates profit margin percentage.
  double calculateProfitMarginPercentage(int revenue, int profit) {
    if (revenue == 0) return 0.0;
    return (profit / revenue) * 100;
  }

  /// Calculates collection rate percentage.
  double calculateCollectionRate(int revenue, int collections) {
    if (revenue == 0) return 0.0;
    return (collections / revenue) * 100;
  }
}

