/// Aggregated KPIs for the water module.
class ActivitySummary {
  const ActivitySummary({
    required this.date,
    required this.totalProduction,
    required this.totalSales,
    required this.pendingCredits,
    required this.rawMaterialDays,
  });

  final DateTime date;
  final int totalProduction;
  final int totalSales;
  final int pendingCredits;
  final double rawMaterialDays;

  factory ActivitySummary.placeholder() {
    return ActivitySummary(
      date: DateTime.now(),
      totalProduction: 22000,
      totalSales: 17500,
      pendingCredits: 320000,
      rawMaterialDays: 6.5,
    );
  }
}
