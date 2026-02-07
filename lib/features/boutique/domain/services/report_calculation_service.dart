import '../entities/expense.dart';
import '../entities/purchase.dart';
import '../entities/report_data.dart' show ProfitReportData;
import '../entities/sale.dart';

/// Service for calculating report metrics for the boutique module.
///
/// Extracts business logic from repositories to make it testable and reusable.
class BoutiqueReportCalculationService {
  BoutiqueReportCalculationService();

  /// Calculates profit report data for a given period.
  ///
  /// This extracts the calculation logic from MockReportRepository.getProfitReportData()
  ProfitReportData calculateProfitReportData({
    required List<Sale> filteredSales,
    required List<Purchase> filteredPurchases,
    required List<Expense> filteredExpenses,
  }) {
    // Calculate total revenue
    final totalRevenue = filteredSales.fold<int>(
      0,
      (sum, s) => sum + s.totalAmount,
    );

    // Calculate COGS (Cost of Goods Sold) from purchases and stock-related expenses
    final purchasesAmount = filteredPurchases.fold<int>(
      0,
      (sum, p) => sum + p.totalAmount,
    );
    
    final stockExpenses = filteredExpenses
        .where((e) => e.category == ExpenseCategory.stock)
        .fold<int>(0, (sum, e) => sum + e.amountCfa);

    final totalCostOfGoodsSold = purchasesAmount + stockExpenses;

    // Calculate total operational expenses (excluding stock)
    final totalExpenses = filteredExpenses
        .where((e) => e.category != ExpenseCategory.stock)
        .fold<int>(0, (sum, e) => sum + e.amountCfa);

    // Calculate profits
    final grossProfit = totalRevenue - totalCostOfGoodsSold;
    final netProfit = grossProfit - totalExpenses;

    // Calculate margins
    final grossMarginPercentage = totalRevenue == 0
        ? 0.0
        : (grossProfit / totalRevenue) * 100;
    final netMarginPercentage = totalRevenue == 0
        ? 0.0
        : (netProfit / totalRevenue) * 100;

    return ProfitReportData(
      totalRevenue: totalRevenue,
      totalCostOfGoodsSold: totalCostOfGoodsSold,
      totalExpenses: totalExpenses,
      grossProfit: grossProfit,
      netProfit: netProfit,
      grossMarginPercentage: grossMarginPercentage,
      netMarginPercentage: netMarginPercentage,
    );
  }
}
