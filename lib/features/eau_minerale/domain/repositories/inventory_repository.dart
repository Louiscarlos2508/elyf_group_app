import '../entities/stock_item.dart';

/// Handles finished goods and raw material snapshots.
abstract class InventoryRepository {
  Future<List<StockItem>> fetchStockItems();
}
