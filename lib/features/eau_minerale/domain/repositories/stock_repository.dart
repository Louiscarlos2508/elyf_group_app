import '../entities/stock_movement.dart';

/// Stock management repository.
abstract class StockRepository {
  Future<double> getStock(String productId);
  Future<double?> getStoredQuantity(String productId);
  Future<void> updateStock(String productId, double quantity);
  Future<void> recordMovement(StockMovement movement);
  Future<List<StockMovement>> fetchMovements({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<void> deleteMovement(String movementId);
  Future<List<String>> getLowStockAlerts(int thresholdPercent);
  Future<void> syncStoredQuantity(String productId);
}
