import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
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
    
    AppLogger.info(
      'Soft-deleted stock movement: ${entity.id}',
      name: 'StockOfflineRepository',
    );
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

    

    // Dédupliquer par remoteId pour éviter les doublons

    return deduplicateByRemoteId(entities);
  }

  // StockRepository implementation

  @override
  Future<int> getStock(String productId) async {
    try {
      // Stock is calculated from movements, not stored directly on Product
      // For now, return 0. This should be calculated from StockMovements
      // or use InventoryRepository to get StockItem
      return 0;
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
      // Stock updates are done through movements, not directly on Product
      // Product entity doesn't have stock properties
      AppLogger.debug(
        'updateStock called but Product entity does not have stock properties. Use recordMovement instead.',
        name: 'StockOfflineRepository',
      );
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
        createdAt: movement.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
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
      final movements = await getAllForEnterprise(enterpriseId);

      // If productId is provided, fetch the product to get its name for filtering
      String? productName;
      if (productId != null) {
        final product = await productRepository.getProduct(productId);
        productName = product?.name;
      }

      return movements.where((m) {
        if (productName != null && m.productName != productName) return false;
        if (startDate != null && m.date.isBefore(startDate)) return false;
        if (endDate != null && m.date.isAfter(endDate)) return false;
        return true;
      }).toList();
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
    try {
      // Product entity doesn't have stock properties or alert thresholds
      // This should be calculated from StockMovements or use InventoryRepository
      // For now, return empty list
      return [];
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting low stock alerts: ${appException.message}',
        name: 'StockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
