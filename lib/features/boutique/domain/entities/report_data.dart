/// Represents report data for the boutique.
class ReportData {
  const ReportData({
    required this.period,
    required this.salesRevenue,
    required this.purchasesAmount,
    required this.expensesAmount,
    required this.profit,
    required this.salesCount,
    required this.purchasesCount,
    required this.expensesCount,
  });

  final ReportPeriod period;
  final int salesRevenue; // Chiffre d'affaires
  final int purchasesAmount; // Montant des achats
  final int expensesAmount; // Montant des dépenses
  final int
  profit; // Bénéfice net (salesRevenue - purchasesAmount - expensesAmount)
  final int salesCount;
  final int purchasesCount;
  final int expensesCount;

  /// Taux de marge bénéficiaire en pourcentage
  double get profitMarginPercentage {
    if (salesRevenue == 0) return 0;
    return (profit / salesRevenue) * 100;
  }
}

/// Period for reports.
enum ReportPeriod { today, week, month, year, custom }

/// Represents sales report data.
class SalesReportData {
  const SalesReportData({
    required this.totalRevenue,
    required this.totalItemsSold,
    required this.averageSaleAmount,
    required this.salesCount,
    required this.topProducts,
  });

  final int totalRevenue;
  final int totalItemsSold;
  final int averageSaleAmount;
  final int salesCount;
  final List<ProductSalesSummary> topProducts;
}

/// Summary of product sales.
class ProductSalesSummary {
  const ProductSalesSummary({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });

  final String productId;
  final String productName;
  final int quantitySold;
  final int revenue;
}

/// Represents purchases report data.
class PurchasesReportData {
  const PurchasesReportData({
    required this.totalAmount,
    required this.totalItemsPurchased,
    required this.averagePurchaseAmount,
    this.purchasesCount = 0,
    required this.topSuppliers,
  });

  final int totalAmount;
  final int totalItemsPurchased;
  final int averagePurchaseAmount;
  final int purchasesCount;
  final List<SupplierSummary> topSuppliers;
}

/// Summary of supplier purchases.
class SupplierSummary {
  const SupplierSummary({
    required this.supplierName,
    required this.totalAmount,
    required this.purchasesCount,
  });

  final String supplierName;
  final int totalAmount;
  final int purchasesCount;
}

/// Represents expenses report data.
class ExpensesReportData {
  const ExpensesReportData({
    required this.totalAmount,
    required this.expensesCount,
    required this.averageExpenseAmount,
    required this.byCategory,
  });

  final int totalAmount;
  final int expensesCount;
  final int averageExpenseAmount;
  final Map<String, int> byCategory; // Category -> Amount
}

/// Represents profit report data.
class ProfitReportData {
  const ProfitReportData({
    required this.totalRevenue,
    required this.totalCostOfGoodsSold, // Coût des marchandises vendues
    required this.totalExpenses,
    required this.grossProfit, // Marge brute (Revenue - COGS)
    required this.netProfit, // Bénéfice net (Gross Profit - Expenses)
    required this.grossMarginPercentage,
    required this.netMarginPercentage,
  });

  final int totalRevenue;
  final int totalCostOfGoodsSold;
  final int totalExpenses;
  final int grossProfit;
  final int netProfit;
  final double grossMarginPercentage;
  final double netMarginPercentage;
}

/// Represents debt report data.
class DebtsReportData {
  const DebtsReportData({
    required this.totalDebt,
    required this.aging,
    required this.debtBySupplier,
  });

  final int totalDebt;
  final Map<String, int> aging; // '0-30', '31-60', '61+' -> Amount
  final List<SupplierDebtSummary> debtBySupplier;
}

/// Summary of a supplier's debt.
class SupplierDebtSummary {
  const SupplierDebtSummary({
    required this.supplierId,
    required this.supplierName,
    required this.balance,
  });

  final String supplierId;
  final String supplierName;
  final int balance;
}

/// Aggregates all boutique report data for full PDF generation.
class FullBoutiqueReportData {
  const FullBoutiqueReportData({
    required this.general,
    required this.sales,
    required this.purchases,
    required this.expenses,
    required this.profit,
    this.debts, // Optionnel pour le moment
    required this.startDate,
    required this.endDate,
  });

  final ReportData general;
  final SalesReportData sales;
  final PurchasesReportData purchases;
  final ExpensesReportData expenses;
  final ProfitReportData profit;
  final DebtsReportData? debts;
  final DateTime startDate;
  final DateTime endDate;
}
