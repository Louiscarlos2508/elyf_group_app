import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

/// Offline-first repository for Product entities (eau_minerale module).
class ProductOfflineRepository extends OfflineRepository<Product>
    implements ProductRepository {
  ProductOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'products';

  @override
  Product fromMap(Map<String, dynamic> map) =>
      Product.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(Product entity) => entity.toMap();

  @override
  String getLocalId(Product entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Product entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(Product entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Product entity, {String? userId}) async {
    final map = toMap(entity);
    final localId = getLocalId(entity);
    map['localId'] = localId;
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(Product entity, {String? userId}) async {
    // Soft-delete
    final deletedProduct = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveToLocal(deletedProduct, userId: syncManager.getUserId() ?? '');
    
    AppLogger.info(
      'Soft-deleted product: ${entity.id}',
      name: 'ProductOfflineRepository',
    );
  }

  @override
  Future<Product?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byRemote != null) {
      final product = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return product.isDeleted ? null : product;
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byLocal == null) return null;
    final product = fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
    return product.isDeleted ? null : product;
  }

  @override
  Future<List<Product>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    final entities = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((product) => !product.isDeleted)
        .toList();

    // Dédupliquer par remoteId pour éviter les doublons
    return deduplicateByRemoteId(entities);
  }

  // ProductRepository interface implementation

  @override
  Future<List<Product>> fetchProducts() async {
    try {
      AppLogger.debug(
        'Fetching products for enterprise: $enterpriseId',
        name: 'ProductOfflineRepository',
      );
      return await getAllForEnterprise(enterpriseId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching products: ${appException.message}',
        name: 'ProductOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Product?> getProduct(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting product: $id - ${appException.message}',
        name: 'ProductOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> createProduct(Product product) async {
    try {
      final productToSave = product.copyWith(
        id: getLocalId(product),
        enterpriseId: enterpriseId,
        createdAt: DateTime.now(),
      );
      await save(productToSave);
      return productToSave.id;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error creating product: ${appException.message}',
        name: 'ProductOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateProduct(Product product) async {
    try {
      final updated = product.copyWith(updatedAt: DateTime.now());
      await save(updated);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating product: ${product.id} - ${appException.message}',
        name: 'ProductOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      final product = await getProduct(id);
      if (product != null) {
        await delete(product);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting product: $id - ${appException.message}',
        name: 'ProductOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
