import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/cylinder_stock.dart';
import '../../domain/repositories/cylinder_stock_repository.dart';

/// Offline-first repository for CylinderStock entities (gaz module).
class CylinderStockOfflineRepository extends OfflineRepository<CylinderStock>
    implements CylinderStockRepository {
  CylinderStockOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'cylinder_stocks';

  @override
  CylinderStock fromMap(Map<String, dynamic> map) {
    return CylinderStock(
      id: map['id'] as String? ?? map['localId'] as String,
      cylinderId: map['cylinderId'] as String,
      weight: (map['weight'] as num?)?.toInt() ?? 0,
      status: _parseStatus(map['status'] as String? ?? 'full'),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      enterpriseId: map['enterpriseId'] as String? ?? enterpriseId,
      siteId: map['siteId'] as String?,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
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
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(CylinderStock entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(CylinderStock entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(CylinderStock entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
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
        moduleType: 'gaz',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    );
  }

  @override
  Future<CylinderStock?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    );
    if (byRemote != null) {
      final map = jsonDecode(byRemote.dataJson) as Map<String, dynamic>;
      return fromMap(map);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    );
    if (byLocal == null) return null;

    final map = jsonDecode(byLocal.dataJson) as Map<String, dynamic>;
    return fromMap(map);
  }

  @override
  Future<List<CylinderStock>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    );
    return rows
        .map((row) {
          try {
            final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
            return fromMap(map);
          } catch (e) {
            developer.log(
              'Error parsing cylinder stock: $e',
              name: 'CylinderStockOfflineRepository',
            );
            return null;
          }
        })
        .whereType<CylinderStock>()
        .toList();
  }

  // Implémentation de CylinderStockRepository

  @override
  Future<List<CylinderStock>> getStocksByStatus(
    String enterpriseId,
    CylinderStatus status, {
    String? siteId,
  }) async {
    try {
      var stocks = await getAllForEnterprise(enterpriseId);
      stocks = stocks.where((s) => s.status == status).toList();
      if (siteId != null) {
        stocks = stocks.where((s) => s.siteId == siteId).toList();
      }
      return stocks;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching stocks by status',
        name: 'CylinderStockOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<List<CylinderStock>> getStocksByWeight(
    String enterpriseId,
    int weight, {
    String? siteId,
  }) async {
    try {
      var stocks = await getAllForEnterprise(enterpriseId);
      stocks = stocks.where((s) => s.weight == weight).toList();
      if (siteId != null) {
        stocks = stocks.where((s) => s.siteId == siteId).toList();
      }
      return stocks;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching stocks by weight',
        name: 'CylinderStockOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<CylinderStock?> getStockById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting stock',
        name: 'CylinderStockOfflineRepository',
        error: appException,
      );
      return null;
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
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating stock quantity',
        name: 'CylinderStockOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> changeStockStatus(
    String id,
    CylinderStatus newStatus,
  ) async {
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
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error changing stock status',
        name: 'CylinderStockOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<List<CylinderStock>> getStockBySite(
    String enterpriseId,
    String siteId,
  ) async {
    try {
      final stocks = await getAllForEnterprise(enterpriseId);
      return stocks.where((s) => s.siteId == siteId).toList();
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching stocks by site',
        name: 'CylinderStockOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<void> addStock(CylinderStock stock) async {
    try {
      final stockWithId = stock.id.isEmpty
          ? stock.copyWith(
              id: LocalIdGenerator.generate(),
              updatedAt: DateTime.now(),
            )
          : stock;
      await save(stockWithId);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error adding stock',
        name: 'CylinderStockOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateStock(CylinderStock stock) async {
    try {
      final updated = stock.copyWith(updatedAt: DateTime.now());
      await save(updated);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating stock',
        name: 'CylinderStockOfflineRepository',
        error: appException,
      );
      rethrow;
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
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting stock',
        name: 'CylinderStockOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  CylinderStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'full':
      case 'pleines':
        return CylinderStatus.full;
      case 'emptyatstore':
      case 'empty_at_store':
      case 'vides (magasin)':
        return CylinderStatus.emptyAtStore;
      case 'emptyintransit':
      case 'empty_in_transit':
      case 'vides (en transit)':
        return CylinderStatus.emptyInTransit;
      case 'emptyatwholesaler':
      case 'empty_at_wholesaler':
      case 'vides (grossiste)':
        return CylinderStatus.emptyAtWholesaler;
      default:
        return CylinderStatus.full;
    }
  }
}

