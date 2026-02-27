/// Represents report data for the gaz module.
class GazReportData {
  const GazReportData({
    required this.period,
    required this.salesRevenue,
    required this.expensesAmount,
    required this.profit,
    required this.salesCount,
    required this.expensesCount,
    this.retailSalesCount = 0,
    this.wholesaleSalesCount = 0,
    this.productBreakdown = const {},
    this.posPerformance = const [],
  });

  final GazReportPeriod period;
  final double salesRevenue; // Chiffre d'affaires
  final double expensesAmount; // Montant des dépenses
  final double profit; // Bénéfice net (salesRevenue - expensesAmount)
  final int salesCount;
  final int expensesCount;
  final int retailSalesCount;
  final int wholesaleSalesCount;

  /// Quantity sold per cylinder label (e.g., {'6kg': 45, '12kg': 20})
  final Map<String, int> productBreakdown;

  /// List of performance data per POS (if applicable)
  final List<GazPosPerformance> posPerformance;

  /// Taux de marge bénéficiaire en pourcentage
  double get profitMarginPercentage {
    if (salesRevenue == 0) return 0;
    return (profit / salesRevenue) * 100;
  }
}

/// Period for reports.
enum GazReportPeriod { today, week, month, year, custom }

/// Performance data for a specific Point of Sale.
class GazPosPerformance {
  const GazPosPerformance({
    required this.enterpriseName,
    required this.revenue,
    required this.salesCount,
    required this.quantitySold,
    required this.revenuePercentage,
    this.topProduct,
  });

  final String enterpriseName;
  final double revenue;
  final int salesCount;
  final int quantitySold;
  final double revenuePercentage;
  final String? topProduct;
}
