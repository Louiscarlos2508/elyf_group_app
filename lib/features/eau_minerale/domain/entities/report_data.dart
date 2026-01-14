/// Represents report summary data for a period.
class ReportData {
  const ReportData({
    required this.revenue,
    required this.collections,
    required this.totalExpenses,
    required this.treasury,
    required this.salesCount,
    required this.collectionRate,
  });

  final int revenue; // Chiffre d'affaires
  final int collections; // Encaissements
  final int totalExpenses; // Charges totales (dépenses + salaires)
  final int treasury; // Trésorerie (entrées - sorties)
  final int salesCount; // Nombre de ventes
  final double collectionRate; // Taux d'encaissement (0-100)
}
