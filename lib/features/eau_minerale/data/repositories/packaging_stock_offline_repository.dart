import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/packaging_stock.dart';
import '../../domain/entities/packaging_stock_movement.dart';
import '../../domain/repositories/packaging_stock_repository.dart';

/// Offline-first repository for PackagingStock entities.
class PackagingStockOfflineRepository extends OfflineRepository<PackagingStock>
    implements PackagingStockRepository {
  PackagingStockOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'packaging_stocks';

  String get movementsCollection => 'packaging_stock_movements';

  @override
  PackagingStock fromMap(Map<String, dynamic> map) {
    return PackagingStock(
      id: map['id'] as String? ?? map['localId'] as String,
      type: map['type'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unit: map['unit'] as String? ?? 'unités',
      seuilAlerte: (map['seuilAlerte'] as num?)?.toInt(),
      fournisseur: map['fournisseur'] as String?,
      prixUnitaire: (map['prixUnitaire'] as num?)?.toInt(),
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
      'seuilAlerte': entity.seuilAlerte,
      'fournisseur': entity.fournisseur,
      'prixUnitaire': entity.prixUnitaire,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(PackagingStock entity) {
    if (entity.id.startsWith('local_')) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(PackagingStock entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(PackagingStock entity) => enterpriseId;

  @override
  Future<void> saveToLocal(PackagingStock entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(PackagingStock entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<PackagingStock?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
    }
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<PackagingStock>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
  }

  // PackagingStockRepository implementation

  @override
  Future<List<PackagingStock>> fetchAll() async {
    try {
      return await getAllForEnterprise(enterpriseId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error fetching packaging stocks',
          name: 'PackagingStockOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }

  @override
  Future<PackagingStock?> fetchById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error fetching packaging stock: $id',
          name: 'PackagingStockOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }

  @override
  Future<PackagingStock?> fetchByType(String type) async {
    try {
      final stocks = await fetchAll();
      try {
        return stocks.firstWhere((s) => s.type == type);
      } catch (_) {
        return null;
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error fetching packaging stock by type: $type',
          name: 'PackagingStockOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }

  @override
  Future<PackagingStock> save(PackagingStock stock) async {
    try {
      final localId = getLocalId(stock);
      final stockWithLocalId = stock.copyWith(
        id: localId,
        updatedAt: DateTime.now(),
        createdAt: stock.createdAt ?? DateTime.now(),
      );
      await super.save(stockWithLocalId);
      return stockWithLocalId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error saving packaging stock',
          name: 'PackagingStockOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }

  @override
  Future<void> recordMovement(PackagingStockMovement movement) async {
    try {
      final localId = movement.id.startsWith('local_')
          ? movement.id
          : LocalIdGenerator.generate();
      final map = {
        'id': localId,
        'localId': localId,
        'packagingId': movement.packagingId,
        'type': movement.type.name,
        'quantity': movement.quantity,
        'date': movement.date.toIso8601String(),
        'reason': movement.reason,
        'productionId': movement.productionId,
      };

      await driftService.records.upsert(
        collectionName: movementsCollection,
        localId: localId,
        remoteId: null,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error recording packaging movement',
          name: 'PackagingStockOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }

  @override
  Future<List<PackagingStockMovement>> fetchMovements({
    String? packagingId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: movementsCollection,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      final movements = rows.map((r) {
        final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
        return PackagingStockMovement(
          id: map['id'] as String,
          packagingId: map['packagingId'] as String,
          type: PackagingMovementType.values.firstWhere(
            (e) => e.name == map['type'],
            orElse: () => PackagingMovementType.usage,
          ),
          quantity: (map['quantity'] as num).toInt(),
          date: DateTime.parse(map['date'] as String),
          reason: map['reason'] as String?,
          productionId: map['productionId'] as String?,
        );
      }).toList();

      return movements.where((m) {
        if (packagingId != null && m.packagingId != packagingId) return false;
        if (startDate != null && m.date.isBefore(startDate)) return false;
        if (endDate != null && m.date.isAfter(endDate)) return false;
        return true;
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error fetching packaging movements',
          name: 'PackagingStockOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }

  @override
  Future<List<PackagingStock>> fetchLowStockAlerts() async {
    try {
      final stocks = await fetchAll();
      return stocks.where((s) => s.estStockFaible).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error fetching low stock alerts',
          name: 'PackagingStockOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }
}
