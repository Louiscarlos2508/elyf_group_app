import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/collection_names.dart';
import '../../domain/entities/bobine_stock.dart';
import '../../domain/entities/bobine_stock_movement.dart';
import '../../domain/repositories/bobine_stock_quantity_repository.dart';

/// Offline-first repository for BobineStock entities (eau_minerale module).
///
/// Gère les stocks de bobines et leurs mouvements.
class BobineStockQuantityOfflineRepository
    extends OfflineRepository<BobineStock>
    implements BobineStockQuantityRepository {
  BobineStockQuantityOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => CollectionNames.bobineStocks;

  String get movementsCollectionName => CollectionNames.bobineStockMovements;

  @override
  BobineStock fromMap(Map<String, dynamic> map) =>
      BobineStock.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(BobineStock entity) => entity.toMap();

  Map<String, dynamic> _movementToMap(BobineStockMovement movement) => movement.toMap();
  BobineStockMovement _movementFromMap(Map<String, dynamic> map) => BobineStockMovement.fromMap(map, enterpriseId);

  @override
  String getLocalId(BobineStock entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    // Prefix with local_ to mark as local and ensure deterministic IDs
    return 'local_${entity.id}';
  }

  @override
  String? getRemoteId(BobineStock entity) {
    // Si l'ID commence par 'local_bobine-', extraire l'ID sans le préfixe 'local_'
    // pour permettre la synchronisation vers Firestore
    if (entity.id.startsWith('local_bobine-')) {
      return entity.id.substring(6); // Enlever 'local_' pour obtenir 'bobine-...'
    }
    // Si l'ID ne commence pas par 'local_', c'est un remoteId
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    // Sinon, c'est un ID local généré, pas encore synchronisé
    return null;
  }

  @override
  String? getEnterpriseId(BobineStock entity) => enterpriseId;

  @override
  Future<void> saveToLocal(BobineStock entity, {String? userId}) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
    final now = DateTime.now();
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
      dataJson: jsonEncode(map),
      localUpdatedAt: entity.updatedAt ?? now,
    );
  }

  @override
  Future<void> deleteFromLocal(BobineStock entity, {String? userId}) async {
    // Soft-delete
    final deletedBobine = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveToLocal(deletedBobine, userId: syncManager.getUserId() ?? '');
    
    AppLogger.info(
      'Soft-deleted bobine stock: ${entity.id}',
      name: 'BobineStockQuantityOfflineRepository',
    );
  }

  @override
  Future<BobineStock?> getByLocalId(String localId) async {
    try {
      final record = await driftService.records.findByLocalId(
        collectionName: collectionName,
        localId: localId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );

      if (record == null) return null;

      final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
      final stock = fromMap(map);
      return stock.isDeleted ? null : stock;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error getting bobine stock by local ID: ${appException.message}',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<BobineStock>> getAllForEnterprise(String enterpriseId) async {
    try {
      final records = await driftService.records.listForEnterprise(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );

      final stocks = records.map((record) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        map['localId'] = record.localId;
        if (record.remoteId != null) {
          map['id'] = record.remoteId;
        }
        return fromMap(map);
      })
      .where((stock) => !stock.isDeleted)
      .toList();

      // Dédupliquer par remoteId d'abord
      final deduplicatedByRemoteId = deduplicateByRemoteId(stocks);

      // Dédupliquer par type : regrouper les stocks de même type et additionner les quantités
      final Map<String, BobineStock> stocksByType = {};
      for (final stock in deduplicatedByRemoteId) {
        final existing = stocksByType[stock.type];
        if (existing == null) {
          stocksByType[stock.type] = stock;
        } else {
          // Fusionner : garder le plus récent et additionner les quantités
          final existingUpdatedAt = existing.updatedAt ?? DateTime.now();
          final stockUpdatedAt = stock.updatedAt ?? DateTime.now();
          final mergedStock = existing.copyWith(
            quantity: existing.quantity + stock.quantity,
            updatedAt: stockUpdatedAt.isAfter(existingUpdatedAt)
                ? stockUpdatedAt
                : existingUpdatedAt,
          );
          stocksByType[stock.type] = mergedStock;
        }
      }

      return stocksByType.values.toList();
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error fetching bobine stocks from local: ${appException.message}',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  Future<BobineStock?> getFromLocal(String localId) async {
    return await getByLocalId(localId);
  }

  // Implementation of BobineStockQuantityRepository interface

  @override
  Future<List<BobineStock>> fetchAll() async {
    try {
      return await getAllForEnterprise(enterpriseId);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error fetching all bobine stocks: ${appException.message}',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<BobineStock?> fetchById(String id) async {
    try {
      final allStocks = await getAllForEnterprise(enterpriseId);
      try {
        return allStocks.firstWhere((stock) => stock.id == id);
      } catch (_) {
        return await getByLocalId(id);
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Future<BobineStock?> fetchByType(String type) async {
    try {
      final allStocks = await getAllForEnterprise(enterpriseId);
      try {
        return allStocks.firstWhere((stock) => stock.type == type);
      } catch (_) {
        return null;
      }
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error fetching bobine stock by type: ${appException.message}',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<BobineStock?> fetchByProductId(String productId) async {
    try {
      final allStocks = await getAllForEnterprise(enterpriseId);
      try {
        return allStocks.firstWhere((stock) => stock.productId == productId);
      } catch (_) {
        return null;
      }
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error fetching bobine stock by productId: ${appException.message}',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<BobineStock> save(BobineStock entity) async {
    try {
      final now = DateTime.now();
      final updatedStock = entity.copyWith(
        updatedAt: now,
        createdAt: entity.createdAt ?? now,
      );
      
      // Utiliser super.save() pour bénéficier de la transaction atomique
      // et de la gestion automatique de la synchronisation
      // Cela garantit la même logique que pour les emballages
      await super.save(updatedStock);
      
      return updatedStock;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error saving bobine stock: ${appException.message}',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> recordMovement(BobineStockMovement movement) async {
    try {
      // Validation du mouvement AVANT toute opération de sauvegarde
      if (movement.bobineReference.trim().isEmpty) {
        throw ValidationException('La référence de bobine est requise pour le mouvement.');
      }
      if (movement.quantite <= 0) {
        throw ValidationException('La quantité du mouvement doit être positive.');
      }

      final localId = movement.id.startsWith('local_')
          ? movement.id
          : LocalIdGenerator.generate();
      final remoteId = movement.id.startsWith('local_') ? null : movement.id;
      
      final movementWithAudit = movement.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        createdAt: movement.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final map = movementWithAudit.toMap()..['localId'] = localId;

      await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
        collectionName: movementsCollectionName,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      // Queue sync operation
      if (remoteId == null) {
        await syncManager.queueCreate(
          collectionName: movementsCollectionName,
          localId: localId,
          data: map,
          enterpriseId: enterpriseId,
        );
      } else {
        await syncManager.queueUpdate(
          collectionName: movementsCollectionName,
          localId: localId,
          remoteId: remoteId,
          data: map,
          enterpriseId: enterpriseId,
        );
      }

      // 1. Chercher le stock par ID (ex: ID catalogue ou fixed ID)
      var stock = await fetchById(movement.bobineId);
      
      // 2. Chercher par productId si non trouvé (le mouvement bobineId peut être le productId)
      stock ??= await fetchByProductId(movement.bobineId);

      // 3. Fallback: Chercher par type si non trouvé par ID
      stock ??= await fetchByType(movement.bobineReference);
      
      if (stock == null) {
        // 2. Si le stock n'existe pas du tout, le créer
        double initialQuantity = 0;
        if (movement.type == BobineMovementType.entree) {
          initialQuantity = movement.quantite;
        }
        
        // Déterminer le facteur de lot à partir du mouvement si possible
        int movementUnitsPerLot = 1;
        if (movement.isInLots && movement.quantiteSaisie != null && movement.quantiteSaisie! > 0) {
          movementUnitsPerLot = (movement.quantite / movement.quantiteSaisie!).round();
          if (movementUnitsPerLot < 1) movementUnitsPerLot = 1;
        }

        stock = BobineStock(
          id: movement.bobineId,
          enterpriseId: enterpriseId,
          type: movement.bobineReference,
          quantity: initialQuantity.toInt(),
          unit: 'unité',
          unitsPerLot: movementUnitsPerLot,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        // 3. Mettre à jour la quantité existante (ADDITION)
        int newQuantity = stock.quantity;
        
        // Mettre à jour le facteur de lot si le mouvement en apporte un nouveau plus précis
        int updatedUnitsPerLot = stock.unitsPerLot;
        if (movement.isInLots && movement.quantiteSaisie != null && movement.quantiteSaisie! > 0) {
          final computedUnitsPerLot = (movement.quantite / movement.quantiteSaisie!).round();
          if (computedUnitsPerLot > 1) {
             updatedUnitsPerLot = computedUnitsPerLot;
          }
        }

        switch (movement.type) {
          case BobineMovementType.entree:
            newQuantity += movement.quantite.toInt();
            break;
          case BobineMovementType.sortie:
          case BobineMovementType.retrait:
            newQuantity -= movement.quantite.toInt();
            if (newQuantity < 0) newQuantity = 0; // Sécurité
            break;
        }

        stock = stock.copyWith(
          quantity: newQuantity,
          unitsPerLot: updatedUnitsPerLot,
          updatedAt: DateTime.now(),
        );
      }

      // Sauvegarder le stock (création ou mise à jour) avec la bonne quantité
      // Utiliser save() au lieu de saveToLocal + queue sync pour être cohérent
      // avec la méthode save() et garantir la même logique que pour les emballages
      await save(stock);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error recording bobine stock movement: ${appException.message}',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<BobineStockMovement>> fetchMovements({
    String? bobineStockId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final records = await driftService.records.listForEnterprise(
        collectionName: movementsCollectionName,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );

      var movements = records.map((record) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        final movement = _movementFromMap(map);
        return movement.isDeleted ? null : movement;
      }).whereType<BobineStockMovement>().toList();

      // Apply filters
      if (bobineStockId != null) {
        movements = movements
            .where((m) => m.bobineId == bobineStockId)
            .toList();
      }
      if (startDate != null) {
        movements = movements
            .where(
              (m) =>
                  m.date.isAfter(startDate.subtract(const Duration(days: 1))),
            )
            .toList();
      }
      if (endDate != null) {
        movements = movements
            .where((m) => m.date.isBefore(endDate.add(const Duration(days: 1))))
            .toList();
      }

      // Sort by date descending
      movements.sort((a, b) => b.date.compareTo(a.date));

      return movements;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error fetching bobine stock movements: ${appException.message}',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<BobineStock>> fetchLowStockAlerts() async {
    try {
      final allStocks = await getAllForEnterprise(enterpriseId);
      return allStocks.where((stock) => stock.estStockFaible).toList();
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error fetching low stock alerts: ${appException.message}',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
