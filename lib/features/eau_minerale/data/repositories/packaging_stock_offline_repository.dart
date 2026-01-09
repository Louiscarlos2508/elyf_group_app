import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/packaging_stock.dart';
import '../../domain/entities/packaging_stock_movement.dart';
import '../../domain/repositories/packaging_stock_repository.dart';

/// Offline-first repository for PackagingStock entities (eau_minerale module).
///
/// Gère les stocks d'emballages et leurs mouvements.
class PackagingStockOfflineRepository extends OfflineRepository<PackagingStock>
    implements PackagingStockRepository {
  PackagingStockOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'packaging_stocks';

  String get movementsCollectionName => 'packaging_stock_movements';

  @override
  PackagingStock fromMap(Map<String, dynamic> map) {
    return PackagingStock(
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
  Map<String, dynamic> toMap(PackagingStock entity) {
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

  Map<String, dynamic> _movementToMap(PackagingStockMovement movement) {
    return {
      'id': movement.id,
      'packagingId': movement.packagingId,
      'packagingType': movement.packagingType,
      'type': movement.type.name,
      'date': movement.date.toIso8601String(),
      'quantite': movement.quantite,
      'raison': movement.raison,
      if (movement.productionId != null) 'productionId': movement.productionId,
      if (movement.fournisseur != null) 'fournisseur': movement.fournisseur,
      if (movement.notes != null) 'notes': movement.notes,
      if (movement.createdAt != null)
        'createdAt': movement.createdAt!.toIso8601String(),
    };
  }

  PackagingStockMovement _movementFromMap(Map<String, dynamic> map) {
    return PackagingStockMovement(
      id: map['id'] as String? ?? map['localId'] as String,
      packagingId: map['packagingId'] as String,
      packagingType: map['packagingType'] as String,
      type: _parseMovementType(map['type'] as String? ?? 'entree'),
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      quantite: (map['quantite'] as num?)?.toInt() ?? 0,
      raison: map['raison'] as String? ?? '',
      productionId: map['productionId'] as String?,
      fournisseur: map['fournisseur'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  PackagingMovementType _parseMovementType(String type) {
    return PackagingMovementType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => PackagingMovementType.entree,
    );
  }

  @override
  String getLocalId(PackagingStock entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(PackagingStock entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(PackagingStock entity) => enterpriseId;

  @override
  Future<void> saveToLocal(PackagingStock entity) async {
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
      updatedAt: entity.updatedAt ?? now,
    );
  }

  @override
  Future<void> deleteFromLocal(String localId) async {
    await driftService.records.delete(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
  }

  @override
  Future<List<PackagingStock>> fetchFromLocal() async {
    try {
      final records = await driftService.records.query(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );

      return records.map((record) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        map['localId'] = record.localId;
        if (record.remoteId != null) {
          map['id'] = record.remoteId;
        }
        return fromMap(map);
      }).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching packaging stocks from local',
        name: 'PackagingStockOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }

  @override
  Future<PackagingStock?> getFromLocal(String localId) async {
    try {
      final record = await driftService.records.get(
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
      developer.log(
        'Error getting packaging stock from local',
        name: 'PackagingStockOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }

  // Implementation of PackagingStockRepository interface

  @override
  Future<List<PackagingStock>> fetchAll() async {
    try {
      return await fetchFromLocal();
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching all packaging stocks',
        name: 'PackagingStockOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }

  @override
  Future<PackagingStock?> fetchById(String id) async {
    try {
      final allStocks = await fetchFromLocal();
      try {
        return allStocks.firstWhere((stock) => stock.id == id);
      } catch (_) {
        return await getFromLocal(id);
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Future<PackagingStock?> fetchByType(String type) async {
    try {
      final allStocks = await fetchFromLocal();
      try {
        return allStocks.firstWhere((stock) => stock.type == type);
      } catch (_) {
        return null;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching packaging stock by type',
        name: 'PackagingStockOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }

  @override
  Future<PackagingStock> save(PackagingStock stock) async {
    try {
      final now = DateTime.now();
      final updatedStock = stock.copyWith(
        updatedAt: now,
        createdAt: stock.createdAt ?? now,
      );
      await saveToLocal(updatedStock);
      
      // Queue sync operation
      final localId = getLocalId(updatedStock);
      final remoteId = getRemoteId(updatedStock);
      final map = toMap(updatedStock);
      if (remoteId == null) {
        await syncManager.queueCreate(
          collectionName: collectionName,
          localId: localId,
          data: map,
          enterpriseId: enterpriseId,
        );
      } else {
        await syncManager.queueUpdate(
          collectionName: collectionName,
          localId: localId,
          remoteId: remoteId,
          data: map,
          enterpriseId: enterpriseId,
        );
      }
      
      return updatedStock;
    } catch (e, stackTrace) {
      developer.log(
        'Error saving packaging stock',
        name: 'PackagingStockOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }

  @override
  Future<void> recordMovement(PackagingStockMovement movement) async {
    try {
      final localId = movement.id.startsWith('local_')
          ? movement.id
          : LocalIdGenerator.generate();
      final remoteId =
          movement.id.startsWith('local_') ? null : movement.id;
      final map = _movementToMap(movement)..['localId'] = localId;
      final now = DateTime.now();

      await driftService.records.upsert(
        collectionName: movementsCollectionName,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
        dataJson: jsonEncode(map),
        updatedAt: movement.createdAt ?? now,
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

      // Update stock quantity based on movement type
      final stock = await fetchById(movement.packagingId);
      if (stock != null) {
        int newQuantity = stock.quantity;
        switch (movement.type) {
          case PackagingMovementType.entree:
            newQuantity += movement.quantite;
            break;
          case PackagingMovementType.sortie:
          case PackagingMovementType.ajustement:
            newQuantity -= movement.quantite;
            break;
        }
        if (newQuantity < 0) newQuantity = 0;

        final updatedStock = stock.copyWith(
          quantity: newQuantity,
          updatedAt: now,
        );
        await saveToLocal(updatedStock);
        
        // Queue sync operation for stock update
        final stockLocalId = getLocalId(updatedStock);
        final stockRemoteId = getRemoteId(updatedStock);
        final stockMap = toMap(updatedStock);
        if (stockRemoteId == null) {
          await syncManager.queueCreate(
            collectionName: collectionName,
            localId: stockLocalId,
            data: stockMap,
            enterpriseId: enterpriseId,
          );
        } else {
          await syncManager.queueUpdate(
            collectionName: collectionName,
            localId: stockLocalId,
            remoteId: stockRemoteId,
            data: stockMap,
            enterpriseId: enterpriseId,
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error recording packaging stock movement',
        name: 'PackagingStockOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }

  @override
  Future<List<PackagingStockMovement>> fetchMovements({
    String? packagingId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final records = await driftService.records.query(
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
      if (packagingId != null) {
        movements = movements
            .where((m) => m.packagingId == packagingId)
            .toList();
      }
      if (startDate != null) {
        movements = movements
            .where((m) => m.date.isAfter(startDate.subtract(const Duration(days: 1))))
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
      developer.log(
        'Error fetching packaging stock movements',
        name: 'PackagingStockOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }

  @override
  Future<List<PackagingStock>> fetchLowStockAlerts() async {
    try {
      final allStocks = await fetchFromLocal();
      return allStocks.where((stock) => stock.estStockFaible).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching low stock alerts',
        name: 'PackagingStockOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }
}

