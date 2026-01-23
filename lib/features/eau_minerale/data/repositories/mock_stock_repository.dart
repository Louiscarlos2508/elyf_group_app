import 'dart:async';

import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/stock_repository.dart';

/// Mock implementation of StockRepository for development.
/// Utilise InventoryRepository comme source unique de vérité pour les produits finis.
class MockStockRepository implements StockRepository {
  MockStockRepository(this._inventoryRepository, this._productRepository);

  final InventoryRepository _inventoryRepository;
  final ProductRepository _productRepository;

  final List<StockMovement> _movements = [];

  @override
  Future<int> getStock(String productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Pour les produits finis, utiliser InventoryRepository
    try {
      final product = await _productRepository.getProduct(productId);
      if (product != null && product.isFinishedGood) {
        final stockItems = await _inventoryRepository.fetchStockItems();
        final packItem = stockItems.firstWhere(
          (item) =>
              item.type == StockType.finishedGoods &&
              (item.name.toLowerCase().contains('pack') ||
                  item.name.toLowerCase().contains(product.name.toLowerCase())),
        );
        return packItem.quantity.toInt();
      }
    } catch (_) {
      // Si le produit n'est pas un produit fini ou n'existe pas, retourner 0
    }

    return 0;
  }

  @override
  Future<void> updateStock(String productId, int quantity) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (quantity < 0) {
      throw ValidationException(
        'Le stock ne peut pas être négatif',
        'NEGATIVE_STOCK',
      );
    }

    // Pour les produits finis, mettre à jour InventoryRepository
    try {
      final product = await _productRepository.getProduct(productId);
      if (product != null && product.isFinishedGood) {
        final stockItems = await _inventoryRepository.fetchStockItems();
        StockItem? packItem;
        try {
          packItem = stockItems.firstWhere(
            (item) =>
                item.type == StockType.finishedGoods &&
                (item.name.toLowerCase().contains('pack') ||
                    item.name.toLowerCase().contains(
                      product.name.toLowerCase(),
                    )),
          );
        } catch (_) {
          // Créer un nouveau StockItem si aucun n'existe
          packItem = StockItem(
            id: 'pack-1',
            name: product.name,
            quantity: quantity.toDouble(),
            unit: product.unit,
            type: StockType.finishedGoods,
            updatedAt: DateTime.now(),
          );
        }

        final updatedItem = StockItem(
          id: packItem.id,
          name: packItem.name,
          quantity: quantity.toDouble(),
          unit: packItem.unit,
          type: packItem.type,
          updatedAt: DateTime.now(),
        );
        await _inventoryRepository.updateStockItem(updatedItem);
        return;
      }
    } catch (_) {
      // Si le produit n'est pas un produit fini, on ne fait rien
      // (pour les matières premières, le stock est géré différemment)
    }
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
          .where(
            (m) =>
                m.date.isAfter(startDate) || m.date.isAtSameMomentAs(startDate),
          )
          .toList();
    }

    if (endDate != null) {
      movements = movements
          .where(
            (m) => m.date.isBefore(endDate) || m.date.isAtSameMomentAs(endDate),
          )
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
