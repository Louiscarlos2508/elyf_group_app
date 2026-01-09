import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
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
  String get collectionName => 'stock_movements';

  @override
  StockMovement fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as String? ?? map['localId'] as String,
      productId: map['productId'] as String,
      quantity: (map['quantity'] as num).toInt(),
      type: MovementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MovementType.adjustment,
      ),
      reason: map['reason'] as String?,
      date: DateTime.parse(map['date'] as String),
    );
  }

  @override
  Map<String, dynamic> toMap(StockMovement entity) {
    return {
      'id': entity.id,
      'productId': entity.productId,
      'quantity': entity.quantity,
      'type': entity.type.name,
      'reason': entity.reason,
      'date': entity.date.toIso8601String(),
    };
  }

  @override
  String getLocalId(StockMovement entity) {
    if (entity.id.startsWith('local_')) return entity.id;
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
  Future<void> saveToLocal(StockMovement entity) async {
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
  Future<void> deleteFromLocal(StockMovement entity) async {
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
  Future<StockMovement?> getByLocalId(String localId) async {
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
  Future<List<StockMovement>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
  }

  // StockRepository implementation

  @override
  Future<int> getStock(String productId) async {
    try {
      final product = await productRepository.getProduct(productId);
      return product?.stockQuantity ?? 0;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error getting stock for product: $productId',
          name: 'StockOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }

  @override
  Future<void> updateStock(String productId, int quantity) async {
    try {
      final product = await productRepository.getProduct(productId);
      if (product != null) {
        final updated = product.copyWith(stockQuantity: quantity);
        await productRepository.updateProduct(updated);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error updating stock for product: $productId',
          name: 'StockOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }

  @override
  Future<void> recordMovement(StockMovement movement) async {
    try {
      final localId = getLocalId(movement);
      final movementWithLocalId = StockMovement(
        id: localId,
        productId: movement.productId,
        quantity: movement.quantity,
        type: movement.type,
        reason: movement.reason,
        date: movement.date,
      );
      await save(movementWithLocalId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error recording stock movement',
          name: 'StockOfflineRepository',
          error: error,
          stackTrace: stackTrace);
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
      return movements.where((m) {
        if (productId != null && m.productId != productId) return false;
        if (startDate != null && m.date.isBefore(startDate)) return false;
        if (endDate != null && m.date.isAfter(endDate)) return false;
        return true;
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error fetching stock movements',
          name: 'StockOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }

  @override
  Future<List<String>> getLowStockAlerts(int thresholdPercent) async {
    try {
      final products = await productRepository.fetchProducts();
      return products
          .where((p) =>
              p.seuilAlerte != null &&
              p.stockQuantity <= (p.seuilAlerte! * thresholdPercent / 100))
          .map((p) => p.id)
          .toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error getting low stock alerts',
          name: 'StockOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }
}
