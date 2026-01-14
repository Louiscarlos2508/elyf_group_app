import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/offline_repository.dart';
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
  String get collectionName => 'bobine_stocks';

  String get movementsCollectionName => 'bobine_stock_movements';

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
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(BobineStock entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
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
      developer.log(
        'Error getting bobine stock by local ID',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
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
        'Error fetching bobine stocks from local',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
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
      developer.log(
        'Error fetching all bobine stocks',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
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
      developer.log(
        'Error fetching bobine stock by type',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
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
        'Error saving bobine stock',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      throw appException;
    }
  }

  @override
  Future<void> recordMovement(BobineStockMovement movement) async {
    try {
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

      // Update stock quantity based on movement type
      final stock = await fetchById(movement.bobineId);
      if (stock != null) {
        int newQuantity = stock.quantity;
        switch (movement.type) {
          case BobineMovementType.entree:
            newQuantity += movement.quantite.toInt();
            break;
          case BobineMovementType.sortie:
          case BobineMovementType.retrait:
            newQuantity -= movement.quantite.toInt();
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
        'Error recording bobine stock movement',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
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
      developer.log(
        'Error fetching bobine stock movements',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      throw appException;
    }
  }

  @override
  Future<List<BobineStock>> fetchLowStockAlerts() async {
    try {
      final allStocks = await getAllForEnterprise(enterpriseId);
      return allStocks.where((stock) => stock.estStockFaible).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching low stock alerts',
        name: 'BobineStockQuantityOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      throw appException;
    }
  }
}
