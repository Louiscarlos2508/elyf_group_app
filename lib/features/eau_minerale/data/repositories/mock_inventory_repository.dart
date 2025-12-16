import 'dart:async';

import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/inventory_repository.dart';

class MockInventoryRepository implements InventoryRepository {
  // Simule un stock en mémoire (normalement ce serait dans une base de données)
  final Map<String, StockItem> _stockItems = {
    'pack-1': StockItem(
      id: 'pack-1',
      name: 'Pack',
      quantity: 0,
      unit: 'unité',
      type: StockType.finishedGoods,
      updatedAt: DateTime.now(),
    ),
  };

  @override
  Future<List<StockItem>> fetchStockItems() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _stockItems.values.toList();
  }

  @override
  Future<void> updateStockItem(StockItem item) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _stockItems[item.id] = item;
  }

  @override
  Future<StockItem?> fetchStockItemById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _stockItems[id];
  }
}
