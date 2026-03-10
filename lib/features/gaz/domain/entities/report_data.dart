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
    this.internalWholesaleRevenue = 0,
    this.externalWholesaleRevenue = 0,
    this.retailRevenue = 0,
    this.cashTotal = 0,
    this.omTotal = 0,
    this.cashBalance = 0,
    this.omBalance = 0,
  });

  final GazReportPeriod period;
  final double salesRevenue; // Chiffre d'affaires total brut
  final double expensesAmount; // Montant des dépenses
  final double profit; // Bénéfice net (salesRevenue - expensesAmount)
  final int salesCount;
  final int expensesCount;
  final int retailSalesCount;
  final int wholesaleSalesCount;

  // Ventilations des revenus
  final double internalWholesaleRevenue; // Ventes Parent -> POS
  final double externalWholesaleRevenue; // Ventes vers clients externes
  final double retailRevenue; // Ventes au détail

  // Totaux par mode de paiement
  final double cashTotal;
  final double omTotal;

  // Situation actuelle Trésorerie
  final double cashBalance;
  final double omBalance;

  /// Chiffre d'Affaires Réel (Exclut les mouvements internes)
  double get realSalesRevenue => externalWholesaleRevenue + retailRevenue;

  /// Bénéfice Réel (CA Réel - Dépenses)
  double get realProfit => realSalesRevenue - expensesAmount;

  /// Quantity sold per cylinder label (e.g., {'6kg': 45, '12kg': 20})
  final Map<String, int> productBreakdown;

  /// List of performance data per POS (if applicable)
  final List<GazPosPerformance> posPerformance;

  /// Taux de marge bénéficiaire réel en pourcentage
  double get profitMarginPercentage {
    if (realSalesRevenue == 0) return 0;
    return (realProfit / realSalesRevenue) * 100;
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
