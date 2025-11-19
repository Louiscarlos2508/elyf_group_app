import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/inventory_repository.dart';

class StockController {
  StockController(this._repository);

  final InventoryRepository _repository;

  Future<StockState> fetchSnapshot() async {
    final items = await _repository.fetchStockItems();
    return StockState(items: items);
  }
}

class StockState {
  const StockState({required this.items});

  final List<StockItem> items;

  StockItem? get finishedGoods =>
      items.firstWhere((i) => i.type == StockType.finishedGoods);
}
