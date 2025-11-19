/// Dashboard statistics for manager view.
class DashboardStats {
  const DashboardStats({
    required this.todayRevenue,
    required this.todayCollections,
    required this.monthRevenue,
    required this.monthCollections,
    required this.collectionRate,
    required this.totalCredits,
    required this.creditCustomersCount,
    required this.pendingSalesCount,
    required this.monthProduction,
    required this.avgProduction,
    required this.finishedGoodsStock,
    required this.lowStockAlerts,
    required this.monthExpenses,
    required this.monthSalaries,
    required this.monthResult,
  });

  final int todayRevenue;
  final int todayCollections;
  final int monthRevenue;
  final int monthCollections;
  final double collectionRate;
  final int totalCredits;
  final int creditCustomersCount;
  final int pendingSalesCount;
  final int monthProduction;
  final double avgProduction;
  final int finishedGoodsStock;
  final List<String> lowStockAlerts;
  final int monthExpenses;
  final int monthSalaries;
  final int monthResult;
}
