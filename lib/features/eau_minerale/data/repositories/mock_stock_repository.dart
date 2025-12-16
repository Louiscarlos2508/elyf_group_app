import 'dart:async';

import '../../domain/entities/stock_movement.dart';
import '../../domain/repositories/stock_repository.dart';

/// Mock implementation of StockRepository for development.
class MockStockRepository implements StockRepository {
  // Simule un stock en mémoire par productId
  final Map<String, int> _stocks = {
    'product-1': 1000, // Pack - produit fini
  };

  final List<StockMovement> _movements = [];

  @override
  Future<int> getStock(String productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _stocks[productId] ?? 0;
  }

  @override
  Future<void> updateStock(String productId, int quantity) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (quantity < 0) {
      throw Exception('Le stock ne peut pas être négatif');
    }
    _stocks[productId] = quantity;
  }

  @override
  Future<void> recordMovement(StockMovement movement) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _movements.add(movement);
  }

  @override
  Future<List<StockMovement>> fetchMovements({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    var movements = List<StockMovement>.from(_movements);

    if (productId != null) {
      // Note: StockMovement utilise productName, pas productId
      // Pour filtrer par productId, on devrait avoir une correspondance productId -> productName
      // Pour le mock, on ignore ce filtre car on n'a pas cette correspondance
      // Dans une vraie implémentation, il faudrait mapper productId vers productName
    }

    if (startDate != null) {
      movements = movements
          .where((m) => m.date.isAfter(startDate) || m.date.isAtSameMomentAs(startDate))
          .toList();
    }

    if (endDate != null) {
      movements = movements
          .where((m) => m.date.isBefore(endDate) || m.date.isAtSameMomentAs(endDate))
          .toList();
    }

    movements.sort((a, b) => b.date.compareTo(a.date));
    return movements;
  }

  @override
  Future<List<String>> getLowStockAlerts(int thresholdPercent) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    // Pour le mock, on retourne une liste vide
    // Dans une vraie implémentation, on comparerait avec un stock initial
    return [];
  }
}

