import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/inventory_repository.dart';

/// Offline-first repository for StockItem entities (eau_minerale module).
///
/// Gère les snapshots d'inventaire (produits finis et matières premières).
class InventoryOfflineRepository extends OfflineRepository<StockItem>
    implements InventoryRepository {
  InventoryOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'stock_items';

  @override
  StockItem fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'] as String? ?? map['localId'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? 'unité',
      type: _parseStockType(map['type'] as String? ?? 'finishedGoods'),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
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
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(StockItem entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
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
      moduleType: 'eau_minerale',
      dataJson: jsonEncode(map),
      updatedAt: entity.updatedAt,
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
  Future<List<StockItem>> fetchFromLocal() async {
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
        'Error fetching stock items from local',
        name: 'InventoryOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }

  @override
  Future<StockItem?> getFromLocal(String localId) async {
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
        'Error getting stock item from local',
        name: 'InventoryOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }

  StockType _parseStockType(String type) {
    return StockType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => StockType.finishedGoods,
    );
  }

  // Implementation of InventoryRepository interface

  @override
  Future<List<StockItem>> fetchStockItems() async {
    try {
      final items = await fetchFromLocal();
      return items;
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching stock items',
        name: 'InventoryOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }

  @override
  Future<void> updateStockItem(StockItem item) async {
    try {
      // Update updatedAt timestamp
      final updatedItem = StockItem(
        id: item.id,
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        type: item.type,
        updatedAt: DateTime.now(),
      );

      await save(updatedItem);
    } catch (e, stackTrace) {
      developer.log(
        'Error updating stock item',
        name: 'InventoryOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e);
      rethrow;
    }
  }

  @override
  Future<StockItem?> fetchStockItemById(String id) async {
    try {
      // Try to find by remote ID first
      final allItems = await fetchFromLocal();
      final item = allItems.firstWhere(
        (item) => item.id == id,
        orElse: () => allItems.firstWhere(
          (item) => item.id == id || getLocalId(item) == id,
          orElse: () => throw Exception('StockItem not found'),
        ),
      );
      return item;
    } catch (e) {
      // If not found, try by local ID
      try {
        return await getFromLocal(id);
      } catch (_) {
        return null;
      }
    }
  }
}

