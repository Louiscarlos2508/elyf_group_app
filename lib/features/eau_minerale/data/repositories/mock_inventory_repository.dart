import 'dart:async';

import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/inventory_repository.dart';

class MockInventoryRepository implements InventoryRepository {
  @override
  Future<List<StockItem>> fetchStockItems() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return [
      // Finished goods
      StockItem(
        id: 'pack-1',
        name: 'Pack',
        quantity: 0,
        unit: 'unité',
        type: StockType.finishedGoods,
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      // Raw materials
      StockItem(
        id: 'sachets-1',
        name: 'Sachets',
        quantity: 0,
        unit: 'kg',
        type: StockType.rawMaterial,
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      StockItem(
        id: 'bidons-1',
        name: 'Bidons',
        quantity: 0,
        unit: 'unité',
        type: StockType.rawMaterial,
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }
}
