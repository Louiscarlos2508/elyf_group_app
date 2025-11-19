import 'dart:async';

import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/inventory_repository.dart';

class MockInventoryRepository implements InventoryRepository {
  @override
  Future<List<StockItem>> fetchStockItems() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return [
      StockItem.sample('fg-1', StockType.finishedGoods),
      StockItem.sample('rm-1', StockType.rawMaterial),
    ];
  }
}
