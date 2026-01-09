import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/stock_repository.dart';

/// Offline-first repository for Stock entities (eau_minerale module).
///
/// Gère les mouvements de stock et calcule le stock actuel en utilisant
/// InventoryRepository et ProductRepository.
class StockOfflineRepository extends OfflineRepository<StockMovement>
    implements StockRepository {
  StockOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.inventoryRepository,
    required this.productRepository,
  });

  final String enterpriseId;
  final InventoryRepository inventoryRepository;
  final ProductRepository productRepository;

  @override
  String get collectionName => 'stock_movements';

  @override
  StockMovement fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as String? ?? map['localId'] as String,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      productName: map['productName'] as String,
      type: _parseStockMovementType(map['type'] as String? ?? 'entry'),
      reason: map['reason'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? 'unité',
      productionId: map['productionId'] as String?,
      notes: map['notes'] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap(StockMovement entity) {
    return {
      'id': entity.id,
      'date': entity.date.toIso8601String(),
      'productName': entity.productName,
      'type': entity.type.name,
      'reason': entity.reason,
      'quantity': entity.quantity,
      'unit': entity.unit,
      if (entity.productionId != null) 'productionId': entity.productionId,
      if (entity.notes != null) 'notes': entity.notes,
    };
  }

  @override
  String getLocalId(StockMovement entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(StockMovement entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(StockMovement entity) => enterpriseId;

  @override
  Future<void> saveToLocal(StockMovement entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(StockMovement entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
  }

  @override
  Future<StockMovement?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byRemote != null) {
      final map = jsonDecode(byRemote.dataJson) as Map<String, dynamic>;
      return fromMap(map);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byLocal == null) return null;

    final map = jsonDecode(byLocal.dataJson) as Map<String, dynamic>;
    return fromMap(map);
  }

  @override
  Future<List<StockMovement>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    return rows
        .map((row) {
          try {
            final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
            return fromMap(map);
          } catch (e) {
            developer.log(
              'Error parsing stock movement: $e',
              name: 'StockOfflineRepository',
            );
            return null;
          }
        })
        .whereType<StockMovement>()
        .toList();
  }

  // Implémentation des méthodes de StockRepository

  @override
  Future<int> getStock(String productId) async {
    try {
      // Pour les produits finis, utiliser InventoryRepository
      final product = await productRepository.getProduct(productId);
      if (product != null && product.isFinishedGood) {
        final stockItems = await inventoryRepository.fetchStockItems();
        try {
          final packItem = stockItems.firstWhere(
            (item) =>
                item.type == StockType.finishedGoods &&
                (item.name.toLowerCase().contains('pack') ||
                    item.name.toLowerCase().contains(product.name.toLowerCase())),
          );
          return packItem.quantity.toInt();
        } catch (_) {
          // Aucun stock item trouvé
          return 0;
        }
      }

      // Pour les autres produits, calculer à partir des mouvements
      final movements = await getAllForEnterprise(enterpriseId);
      final productMovements = movements.where((m) {
        // Note: StockMovement utilise productName, pas productId
        // On doit comparer avec le nom du produit
        return m.productName.toLowerCase() ==
            (product?.name.toLowerCase() ?? '');
      }).toList();

      int stock = 0;
      for (final movement in productMovements) {
        if (movement.type == StockMovementType.entry) {
          stock += movement.quantity.toInt();
        } else {
          stock -= movement.quantity.toInt();
        }
      }

      return stock;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting stock for product: $productId',
        name: 'StockOfflineRepository',
        error: appException,
      );
      return 0;
    }
  }

  @override
  Future<void> updateStock(String productId, int quantity) async {
    if (quantity < 0) {
      throw Exception('Le stock ne peut pas être négatif');
    }

    try {
      // Pour les produits finis, mettre à jour InventoryRepository
      final product = await productRepository.getProduct(productId);
      if (product != null && product.isFinishedGood) {
        final stockItems = await inventoryRepository.fetchStockItems();
        StockItem? packItem;
        try {
          packItem = stockItems.firstWhere(
            (item) =>
                item.type == StockType.finishedGoods &&
                (item.name.toLowerCase().contains('pack') ||
                    item.name.toLowerCase().contains(product.name.toLowerCase())),
          );
        } catch (_) {
          // Créer un nouveau StockItem si aucun n'existe
          packItem = StockItem(
            id: 'pack-${DateTime.now().millisecondsSinceEpoch}',
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
        await inventoryRepository.updateStockItem(updatedItem);
        return;
      }

      // Pour les autres produits, enregistrer un mouvement d'ajustement
      final currentStock = await getStock(productId);
      final difference = quantity - currentStock;

      if (difference != 0) {
        final movement = StockMovement(
          id: LocalIdGenerator.generate(),
          date: DateTime.now(),
          productName: product?.name ?? productId,
          type: difference > 0 ? StockMovementType.entry : StockMovementType.exit,
          reason: 'Ajustement manuel',
          quantity: difference.abs().toDouble(),
          unit: product?.unit ?? 'unité',
          notes: 'Ajustement de stock: $currentStock -> $quantity',
        );

        await recordMovement(movement);
      }
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating stock for product: $productId',
        name: 'StockOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> recordMovement(StockMovement movement) async {
    try {
      await save(movement);
      developer.log(
        'Stock movement recorded: ${movement.productName} - ${movement.type.name} - ${movement.quantity}',
        name: 'StockOfflineRepository',
      );
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error recording stock movement',
        name: 'StockOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<List<StockMovement>> fetchMovements({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var movements = await getAllForEnterprise(enterpriseId);

      // Filtrer par productId (via productName)
      if (productId != null) {
        final product = await productRepository.getProduct(productId);
        if (product != null) {
          movements = movements
              .where((m) =>
                  m.productName.toLowerCase() == product.name.toLowerCase())
              .toList();
        }
      }

      // Filtrer par date
      if (startDate != null) {
        movements = movements
            .where((m) =>
                m.date.isAfter(startDate) || m.date.isAtSameMomentAs(startDate))
            .toList();
      }

      if (endDate != null) {
        movements = movements
            .where((m) =>
                m.date.isBefore(endDate) || m.date.isAtSameMomentAs(endDate))
            .toList();
      }

      // Trier par date décroissante
      movements.sort((a, b) => b.date.compareTo(a.date));

      return movements;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching stock movements',
        name: 'StockOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<List<String>> getLowStockAlerts(int thresholdPercent) async {
    try {
      // Pour le moment, on retourne une liste vide
      // Dans une implémentation complète, on comparerait avec un stock initial
      // ou un stock minimum configuré
      return [];
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting low stock alerts',
        name: 'StockOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  StockMovementType _parseStockMovementType(String type) {
    switch (type.toLowerCase()) {
      case 'entry':
      case 'entree':
        return StockMovementType.entry;
      case 'exit':
      case 'sortie':
        return StockMovementType.exit;
      default:
        return StockMovementType.entry;
    }
  }
}

