import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/inventory_repository.dart';

/// Controller pour gérer les stocks d'inventaire (produits finis et matières premières).
class InventoryController {
  InventoryController(this._repository);

  final InventoryRepository _repository;

  /// Récupère tous les items de stock.
  Future<List<StockItem>> fetchStockItems() async {
    return await _repository.fetchStockItems();
  }

  /// Récupère un item de stock par son ID.
  Future<StockItem?> fetchStockItemById(String id) async {
    return await _repository.fetchStockItemById(id);
  }

  /// Met à jour un item de stock.
  Future<void> updateStockItem(StockItem item) async {
    return await _repository.updateStockItem(item);
  }
}
