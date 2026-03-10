import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/drift/app_database.dart';
import '../../../../core/offline/collection_names.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/stock_repository.dart';

/// Offline-first repository for Stock management.
class StockOfflineRepository extends OfflineRepository<StockMovement>
    implements StockRepository {
  StockOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
    required this.productRepository,
  });

  final String enterpriseId;
  final String moduleType;
  final ProductRepository productRepository;

  @override
  String get collectionName => CollectionNames.stockMovements;

  @override
  StockMovement fromMap(Map<String, dynamic> map) =>
      StockMovement.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(StockMovement entity) => entity.toMap();

  @override
  String getLocalId(StockMovement entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(StockMovement entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(StockMovement entity) => enterpriseId;

  @override
  Future<void> saveToLocal(StockMovement entity, {String? userId}) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
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
  Future<void> deleteFromLocal(StockMovement entity, {String? userId}) async {
    // Soft-delete
    final deletedStock = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveToLocal(deletedStock, userId: syncManager.getUserId() ?? '');
  }

  @override
  Future<StockMovement?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      final movement = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return movement.isDeleted ? null : movement;
    }
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    final movement = fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
    return movement.isDeleted ? null : movement;
  }

  @override
  Future<List<StockMovement>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final entities = rows
      .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
      .where((m) => !m.isDeleted)
      .toList();

    return deduplicateByRemoteId(entities);
  }

  // StockRepository implementation

  @override
  Future<int> getStock(String productId) async {
    try {
      final movements = await fetchMovements(productId: productId);
      AppLogger.debug('Found ${movements.length} movements for product $productId', name: 'StockOfflineRepository');
      
      double total = 0;
      for (final m in movements) {
        if (m.type == StockMovementType.entry) {
          total += m.quantity;
        } else {
          total -= m.quantity;
        }
      }
      AppLogger.debug('Calculated total stock for $productId: $total', name: 'StockOfflineRepository');
      return total.toInt();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting stock for product: $productId - ${appException.message}',
        name: 'StockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateStock(String productId, int quantity) async {
    try {
      final currentStock = await getStock(productId);
      final diff = quantity - currentStock;
      
      if (diff == 0) return;
      
      final product = await productRepository.getProduct(productId);
      
      await recordMovement(StockMovement(
        id: LocalIdGenerator.generate(),
        enterpriseId: enterpriseId,
        productId: productId,
        productName: product?.name ?? 'Inconnu',
        date: DateTime.now(),
        type: diff > 0 ? StockMovementType.entry : StockMovementType.exit,
        reason: 'Ajustement manuel de stock',
        quantity: diff.abs().toDouble(),
        unit: product?.unit ?? 'unite',
      ));
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating stock for product: $productId - ${appException.message}',
        name: 'StockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> recordMovement(StockMovement movement) async {
    try {
      final localId = movement.id.startsWith('local_')
          ? movement.id
          : LocalIdGenerator.generate();
      
      final movementWithAudit = movement.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        productId: movement.productId, // Just in case
        createdAt: movement.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      AppLogger.info('Recording movement: ${movementWithAudit.type.name} of ${movementWithAudit.quantity} for ${movementWithAudit.productId}', name: 'StockOfflineRepository');
      await save(movementWithAudit);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error recording stock movement: ${appException.message}',
        name: 'StockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<StockMovement>> fetchMovements({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final filters = <String, String>{};
      if (productId != null) {
        filters['productId'] = productId;
      }

      List<OfflineRecord> rows;
      if (filters.isNotEmpty) {
        rows = await driftService.records.listForEnterpriseWithJsonFilter(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
          jsonFilters: filters,
        );
      } else {
        rows = await driftService.records.listForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        );
      }

      final movements = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((m) => !m.isDeleted)
          .where((m) {
            if (startDate != null && m.date.isBefore(startDate)) return false;
            if (endDate != null && m.date.isAfter(endDate)) return false;
            return true;
          }).toList();

      return deduplicateByRemoteId(movements);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching stock movements',
        name: 'StockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<String>> getLowStockAlerts(int thresholdPercent) async {
    // This could involve fetching all products and checking their stock
    // For now, keep it simple or implement as needed.
    return [];
  }
}
