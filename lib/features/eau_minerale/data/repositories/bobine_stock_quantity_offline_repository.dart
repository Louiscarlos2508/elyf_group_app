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
  BobineStock fromMap(Map<String, dynamic> map) {
    return BobineStock(
      id: map['id'] as String? ?? map['localId'] as String,
      type: map['type'] as String,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unit: map['unit'] as String? ?? 'unités',
      seuilAlerte: map['seuilAlerte'] != null
          ? (map['seuilAlerte'] as num).toInt()
          : null,
      fournisseur: map['fournisseur'] as String?,
      prixUnitaire: map['prixUnitaire'] != null
          ? (map['prixUnitaire'] as num).toInt()
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(BobineStock entity) {
    return {
      'id': entity.id,
      'type': entity.type,
      'quantity': entity.quantity,
      'unit': entity.unit,
      if (entity.seuilAlerte != null) 'seuilAlerte': entity.seuilAlerte,
      if (entity.fournisseur != null) 'fournisseur': entity.fournisseur,
      if (entity.prixUnitaire != null) 'prixUnitaire': entity.prixUnitaire,
      if (entity.createdAt != null)
        'createdAt': entity.createdAt!.toIso8601String(),
      if (entity.updatedAt != null)
        'updatedAt': entity.updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> _movementToMap(BobineStockMovement movement) {
    return {
      'id': movement.id,
      'bobineId': movement.bobineId,
      'bobineReference': movement.bobineReference,
      'type': movement.type.name,
      'date': movement.date.toIso8601String(),
      'quantite': movement.quantite,
      'raison': movement.raison,
      if (movement.productionId != null) 'productionId': movement.productionId,
      if (movement.machineId != null) 'machineId': movement.machineId,
      if (movement.notes != null) 'notes': movement.notes,
      if (movement.createdAt != null)
        'createdAt': movement.createdAt!.toIso8601String(),
    };
  }

  BobineStockMovement _movementFromMap(Map<String, dynamic> map) {
    return BobineStockMovement(
      id: map['id'] as String? ?? map['localId'] as String,
      bobineId: map['bobineId'] as String,
      bobineReference: map['bobineReference'] as String,
      type: _parseMovementType(map['type'] as String? ?? 'entree'),
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      quantite: (map['quantite'] as num?)?.toDouble() ?? 0.0,
      raison: map['raison'] as String? ?? '',
      productionId: map['productionId'] as String?,
      machineId: map['machineId'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  BobineMovementType _parseMovementType(String type) {
    return BobineMovementType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => BobineMovementType.entree,
    );
  }

  @override
  String getLocalId(BobineStock entity) {
    // Si l'ID commence par "local_", le retourner tel quel
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    // Si l'ID est un ID fixe basé sur le type (ex: "bobine-bobine"), le préserver
    // pour garantir la cohérence entre les mouvements et le stock
    if (entity.id.startsWith('bobine-')) {
      return 'local_${entity.id}';
    }
    // Sinon, générer un nouvel ID
    return LocalIdGenerator.generate();
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
  Future<void> saveToLocal(BobineStock entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
    final now = DateTime.now();
    await driftService.records.upsert(
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
  Future<void> deleteFromLocal(BobineStock entity) async {
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
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
      map['localId'] = record.localId;
      if (record.remoteId != null) {
        map['id'] = record.remoteId;
      }
      return fromMap(map);
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
      }).toList();

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
      final map = _movementToMap(movement)..['localId'] = localId;
      final now = DateTime.now();

      await driftService.records.upsert(
        collectionName: movementsCollectionName,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
        dataJson: jsonEncode(map),
        localUpdatedAt: movement.createdAt ?? now,
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

      // Chercher le stock par type (plus fiable que par ID car l'ID peut changer)
      var stock = await fetchByType(movement.bobineReference);
      
      // Si le stock n'existe pas, le créer avec la quantité initiale basée sur le mouvement
      if (stock == null) {
        int initialQuantity = 0;
        switch (movement.type) {
          case BobineMovementType.entree:
            initialQuantity = movement.quantite.toInt();
            break;
          case BobineMovementType.sortie:
          case BobineMovementType.retrait:
            initialQuantity = 0; // Ne pas créer un stock négatif
            break;
        }
        
        // Utiliser un ID fixe basé sur le type pour garantir la cohérence
        final stockId = 'bobine-${movement.bobineReference.toLowerCase().replaceAll(' ', '-')}';
        stock = BobineStock(
          id: stockId,
          type: movement.bobineReference,
          quantity: initialQuantity,
          unit: 'unité',
          createdAt: now,
          updatedAt: now,
        );
      } else {
        // Mettre à jour la quantité existante
        int newQuantity = stock.quantity;
        switch (movement.type) {
          case BobineMovementType.entree:
            newQuantity += movement.quantite.toInt();
            // Protection contre les débordements
            if (newQuantity > 1000000) {
              throw ValidationException(
                'La quantité totale ne peut pas dépasser 1 000 000',
                'QUANTITY_EXCEEDS_LIMIT',
              );
            }
            break;
          case BobineMovementType.sortie:
          case BobineMovementType.retrait:
            newQuantity -= movement.quantite.toInt();
            // Vérifier que le stock ne devient pas négatif
            if (newQuantity < 0) {
              throw ValidationException(
                'Stock insuffisant. Stock actuel: ${stock.quantity}, '
                'Demandé: ${movement.quantite.toInt()}',
                'INSUFFICIENT_STOCK',
              );
            }
            break;
        }

        stock = stock.copyWith(
          quantity: newQuantity,
          updatedAt: now,
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
        map['localId'] = record.localId;
        if (record.remoteId != null) {
          map['id'] = record.remoteId;
        }
        return _movementFromMap(map);
      }).toList();

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
