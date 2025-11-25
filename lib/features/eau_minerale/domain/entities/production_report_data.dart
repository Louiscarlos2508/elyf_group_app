import 'production.dart';

/// Represents production report data for a period.
class ProductionReportData {
  const ProductionReportData({
    required this.totalQuantity,
    required this.totalBatches,
    required this.averageQuantityPerBatch,
    required this.productions,
  });

  final int totalQuantity; // Total quantity produced
  final int totalBatches; // Number of production batches
  final double averageQuantityPerBatch; // Average quantity per batch
  final List<Production> productions; // List of productions in period
}

