import 'dart:convert';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/security/data_sanitizer.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/inventory_repository.dart';

/// Offline-first repository for StockItem entities.
class InventoryOfflineRepository extends OfflineRepository<StockItem>
    implements InventoryRepository {
  InventoryOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'stock_items';

  @override
  StockItem fromMap(Map<String, dynamic> map) =>
      StockItem.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(StockItem entity) => entity.toMap();

  @override
  String getLocalId(StockItem entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(StockItem entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(StockItem entity) => enterpriseId;

  @override
  Future<void> saveToLocal(StockItem entity, {String? userId}) async {
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
  Future<void> deleteFromLocal(StockItem entity, {String? userId}) async {
    // Soft-delete
    final deletedInventory = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveToLocal(deletedInventory, userId: syncManager.getUserId() ?? '');
    
    AppLogger.info(
      'Soft-deleted stock item: ${entity.id}',
      name: 'InventoryOfflineRepository',
    );
  }

  @override
  Future<StockItem?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      final item = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return item.isDeleted ? null : item;
    }
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    final item = fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
    return item.isDeleted ? null : item;
  }

  @override
  Future<List<StockItem>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final entities = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((item) => !item.isDeleted)
        .toList();

    

    // Dédupliquer par remoteId pour éviter les doublons

    return deduplicateByRemoteId(entities);
  }

  // InventoryRepository implementation

  @override
  Future<List<StockItem>> fetchStockItems() async {
    try {
      return await getAllForEnterprise(enterpriseId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching stock items: ${appException.message}',
        name: 'InventoryOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateStockItem(StockItem item) async {
    try {
      if (item.id.trim().isEmpty) {
        throw ValidationException(
          'StockItem.id requis',
          'INVALID_STOCK_ITEM_ID',
        );
      }
      if (item.quantity < 0) {
        throw ValidationException(
          'La quantité ne peut pas être négative: ${item.quantity}',
          'INVALID_QUANTITY',
        );
      }
      final updated = item.copyWith(
        enterpriseId: enterpriseId,
        updatedAt: DateTime.now(),
      );
      await save(updated);
    } on ValidationException {
      rethrow;
    } on DataSizeException {
      rethrow;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating stock item: ${item.id}',
        name: 'InventoryOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<StockItem?> fetchStockItemById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching stock item: $id - ${appException.message}',
        name: 'InventoryOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
