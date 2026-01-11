import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/offline_repository.dart';
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
  StockItem fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'] as String? ?? map['localId'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      type: StockType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => StockType.finishedGoods,
      ),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toMap(StockItem entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'quantity': entity.quantity,
      'unit': entity.unit,
      'type': entity.type.name,
      'updatedAt': entity.updatedAt.toIso8601String(),
    };
  }

  @override
  String getLocalId(StockItem entity) {
    if (entity.id.startsWith('local_')) return entity.id;
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
  Future<void> saveToLocal(StockItem entity) async {
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
  Future<void> deleteFromLocal(StockItem entity) async {
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
  Future<StockItem?> getByLocalId(String localId) async {
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
  Future<List<StockItem>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
  }

  // InventoryRepository implementation

  @override
  Future<List<StockItem>> fetchStockItems() async {
    try {
      return await getAllForEnterprise(enterpriseId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error fetching stock items',
          name: 'InventoryOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }

  @override
  Future<void> updateStockItem(StockItem item) async {
    try {
      final updated = StockItem(
        id: item.id,
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        type: item.type,
        updatedAt: DateTime.now(),
      );
      await save(updated);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error updating stock item: ${item.id}',
          name: 'InventoryOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }

  @override
  Future<StockItem?> fetchStockItemById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error fetching stock item: $id',
          name: 'InventoryOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }
}
