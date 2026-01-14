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
  });

  final GazReportPeriod period;
  final double salesRevenue; // Chiffre d'affaires
  final double expensesAmount; // Montant des dépenses
  final double profit; // Bénéfice net (salesRevenue - expensesAmount)
  final int salesCount;
  final int expensesCount;
  final int retailSalesCount;
  final int wholesaleSalesCount;

  /// Taux de marge bénéficiaire en pourcentage
  double get profitMarginPercentage {
    if (salesRevenue == 0) return 0;
    return (profit / salesRevenue) * 100;
  }
}

/// Period for reports.
enum GazReportPeriod { today, week, month, year, custom }
