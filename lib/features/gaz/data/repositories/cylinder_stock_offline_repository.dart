import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/cylinder_stock.dart';
import '../../domain/repositories/cylinder_stock_repository.dart';

/// Offline-first repository for CylinderStock entities.
class CylinderStockOfflineRepository extends OfflineRepository<CylinderStock>
    implements CylinderStockRepository {
  CylinderStockOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'cylinder_stocks';

  @override
  CylinderStock fromMap(Map<String, dynamic> map) {
    return CylinderStock(
      id: map['id'] as String? ?? map['localId'] as String,
      cylinderId: map['cylinderId'] as String,
      weight: (map['weight'] as num).toInt(),
      status: CylinderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CylinderStatus.full,
      ),
      quantity: (map['quantity'] as num).toInt(),
      enterpriseId: map['enterpriseId'] as String,
      siteId: map['siteId'] as String?,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toMap(CylinderStock entity) {
    return {
      'id': entity.id,
      'cylinderId': entity.cylinderId,
      'weight': entity.weight,
      'status': entity.status.name,
      'quantity': entity.quantity,
      'enterpriseId': entity.enterpriseId,
      'siteId': entity.siteId,
      'updatedAt': entity.updatedAt.toIso8601String(),
    };
  }

  @override
  String getLocalId(CylinderStock entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(CylinderStock entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(CylinderStock entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(CylinderStock entity) async {
    // Utiliser la méthode utilitaire pour trouver le localId existant
    final existingLocalId = await findExistingLocalId(entity, moduleType: moduleType);
    final localId = existingLocalId ?? getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId..['id'] = localId;
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
  Future<void> deleteFromLocal(CylinderStock entity) async {
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
  Future<CylinderStock?> getByLocalId(String localId) async {
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
  Future<List<CylinderStock>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final entities = rows

        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))

        .toList();

    

    // Dédupliquer par remoteId pour éviter les doublons

    return deduplicateByRemoteId(entities);
  }

  // CylinderStockRepository implementation

  @override
  Future<List<CylinderStock>> getStocksByStatus(
    String enterpriseId,
    CylinderStatus status, {
    String? siteId,
  }) async {
    try {
      final stocks = await getAllForEnterprise(enterpriseId);
      return stocks.where((stock) {
        if (stock.status != status) return false;
        if (siteId != null && stock.siteId != siteId) return false;
        return true;
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting stocks by status: ${appException.message}',
        name: 'CylinderStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Stream<List<CylinderStock>> watchStocks(
    String enterpriseId, {
    CylinderStatus? status,
    String? siteId,
  }) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final entities = rows
              .map((r) {
                try {
                  final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
                  return fromMap(map);
                } catch (e) {
                  return null;
                }
              })
              .whereType<CylinderStock>()
              .toList();

          final deduplicated = deduplicateByRemoteId(entities);
          return deduplicated.where((stock) {
            if (status != null && stock.status != status) return false;
            if (siteId != null && stock.siteId != siteId) return false;
            return true;
          }).toList();
        });
  }

  @override
  Future<List<CylinderStock>> getStocksByWeight(
    String enterpriseId,
    int weight, {
    String? siteId,
  }) async {
    try {
      final stocks = await getAllForEnterprise(enterpriseId);
      return stocks.where((stock) {
        if (stock.weight != weight) return false;
        if (siteId != null && stock.siteId != siteId) return false;
        return true;
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting stocks by weight',
        name: 'CylinderStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<CylinderStock?> getStockById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting stock: $id - ${appException.message}',
        name: 'CylinderStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateStockQuantity(String id, int newQuantity) async {
    try {
      final stock = await getStockById(id);
      if (stock != null) {
        final updated = stock.copyWith(
          quantity: newQuantity,
          updatedAt: DateTime.now(),
        );
        await save(updated);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating stock quantity: $id',
        name: 'CylinderStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> changeStockStatus(String id, CylinderStatus newStatus) async {
    try {
      final stock = await getStockById(id);
      if (stock != null) {
        final updated = stock.copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
        await save(updated);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error changing stock status: $id - ${appException.message}',
        name: 'CylinderStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<CylinderStock>> getStockBySite(
    String enterpriseId,
    String siteId,
  ) async {
    try {
      final stocks = await getAllForEnterprise(enterpriseId);
      return stocks.where((stock) => stock.siteId == siteId).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting stocks by site',
        name: 'CylinderStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> addStock(CylinderStock stock) async {
    try {
      final localId = getLocalId(stock);
      final stockWithLocalId = stock.copyWith(id: localId);
      await save(stockWithLocalId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error adding stock: ${appException.message}',
        name: 'CylinderStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateStock(CylinderStock stock) async {
    try {
      await save(stock);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating stock: ${stock.id}',
        name: 'CylinderStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteStock(String id) async {
    try {
      final stock = await getStockById(id);
      if (stock != null) {
        await delete(stock);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting stock: $id - ${appException.message}',
        name: 'CylinderStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
