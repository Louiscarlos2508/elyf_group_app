import 'production_session.dart';

/// Represents production report data for a period.
class ProductionReportData {
  const ProductionReportData({
    required this.totalQuantity,
    required this.totalBatches,
    required this.averageQuantityPerBatch,
    required this.productions,
    this.totalCost = 0,
    this.totalBobinesCost = 0,
    this.totalPackagingCost = 0,
    this.totalElectricityCost = 0,
    this.totalPersonnelCost = 0,
  });

  final int totalQuantity; // Total quantity produced
  final int totalBatches; // Number of production batches
  final double averageQuantityPerBatch; // Average quantity per batch
  final List<ProductionSession>
  productions; // List of production sessions in period
  final int totalCost; // Coût total (bobines + emballages + électricité + personnel)
  final int totalBobinesCost; // Coût total des bobines
  final int totalPackagingCost; // Coût total des emballages
  final int totalElectricityCost; // Coût total de l'électricité
  final int totalPersonnelCost; // Coût total du personnel
}
