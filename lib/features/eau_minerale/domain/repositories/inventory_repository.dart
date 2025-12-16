import '../entities/stock_item.dart';

/// Handles finished goods and raw material snapshots.
abstract class InventoryRepository {
  Future<List<StockItem>> fetchStockItems();
  
  /// Met à jour un StockItem (produits finis ou matières premières).
  Future<void> updateStockItem(StockItem item);
  
  /// Récupère un StockItem par son ID.
  Future<StockItem?> fetchStockItemById(String id);
}
