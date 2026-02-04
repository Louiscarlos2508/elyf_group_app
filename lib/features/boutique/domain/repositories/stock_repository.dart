import '../entities/product.dart';

/// Repository for managing stock/inventory.
abstract class StockRepository {
  Future<void> updateStock(String productId, int quantity);
  Future<int> getStock(String productId);
  Future<List<Product>> getLowStockProducts({int threshold = 10});
  Stream<int> watchStock(String productId);
  Stream<List<Product>> watchLowStockProducts({int threshold = 10});
}
