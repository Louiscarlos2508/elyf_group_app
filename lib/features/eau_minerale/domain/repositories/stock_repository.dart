import '../entities/stock_movement.dart';

/// Stock management repository.
abstract class StockRepository {
  Future<int> getStock(String productId);
  Future<void> updateStock(String productId, int quantity);
  Future<void> recordMovement(StockMovement movement);
  Future<List<StockMovement>> fetchMovements({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<String>> getLowStockAlerts(int thresholdPercent);
}
