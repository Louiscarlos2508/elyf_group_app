import 'production_session.dart';

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
  final List<ProductionSession> productions; // List of production sessions in period
}

