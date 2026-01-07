import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/isar_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../../core/offline/collections/product_collection.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

/// Offline-first repository for Product entities.
class ProductOfflineRepository extends OfflineRepository<Product>
    implements ProductRepository {
  ProductOfflineRepository({
    required super.isarService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'products';

  @override
  Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String? ?? map['localId'] as String,
      name: map['name'] as String,
      price: (map['price'] as num?)?.toInt() ?? (map['sellingPrice'] as num?)?.toInt() ?? 0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      description: map['description'] as String?,
      category: map['category'] as String?,
      imageUrl: map['imageUrl'] as String?,
      barcode: map['barcode'] as String?,
      purchasePrice: (map['purchasePrice'] as num?)?.toInt(),
    );
  }

  @override
  Map<String, dynamic> toMap(Product entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'price': entity.price,
      'sellingPrice': entity.price,
      'stock': entity.stock.toDouble(),
      'description': entity.description,
      'category': entity.category,
      'imageUrl': entity.imageUrl,
      'barcode': entity.barcode,
      'purchasePrice': entity.purchasePrice?.toDouble(),
      'isActive': true,
    };
  }

  @override
  String getLocalId(Product entity) {
    // If ID starts with 'local_', it's already a local ID
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    // Otherwise, generate a new local ID
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Product entity) {
    // If ID doesn't start with 'local_', it's a remote ID
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(Product entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Product entity) async {
    final collection = ProductCollection.fromMap(
      toMap(entity),
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      localId: getLocalId(entity),
    );
    collection.remoteId = getRemoteId(entity) ?? getLocalId(entity);
    collection.localUpdatedAt = DateTime.now();

    await isarService.isar.writeTxn(() async {
      await isarService.isar.productCollections.put(collection);
    });
  }

  @override
  Future<void> deleteFromLocal(Product entity) async {
    final remoteId = getRemoteId(entity);
    await isarService.isar.writeTxn(() async {
      if (remoteId != null) {
        await isarService.isar.productCollections
            .filter()
            .remoteIdEqualTo(remoteId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .deleteAll();
      } else {
        final localId = getLocalId(entity);
        await isarService.isar.productCollections
            .filter()
            .remoteIdEqualTo(localId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .deleteAll();
      }
    });
  }

  @override
  Future<Product?> getByLocalId(String localId) async {
    // Try to find by remote ID first (in case localId is actually a remote ID)
    var collection = await isarService.isar.productCollections
        .filter()
        .remoteIdEqualTo(localId)
        .and()
        .enterpriseIdEqualTo(enterpriseId)
        .findFirst();

    if (collection != null) {
      return fromMap(collection.toMap());
    }

    // If not found, search all collections and match by any ID field
    // Note: Isar doesn't support searching by localId directly in this schema
    // So we need to search all and filter manually
    final allCollections = await isarService.isar.productCollections
        .filter()
        .enterpriseIdEqualTo(enterpriseId)
        .findAll();

    // Try to find a collection that matches (this is a workaround)
    // In a real implementation, we'd store localId in the collection
    for (final c in allCollections) {
      final product = fromMap(c.toMap());
      if (getLocalId(product) == localId || getRemoteId(product) == localId) {
        return product;
      }
    }

    return null;
  }

  @override
  Future<List<Product>> getAllForEnterprise(String enterpriseId) async {
    final collections = await isarService.isar.productCollections
        .filter()
        .enterpriseIdEqualTo(enterpriseId)
        .and()
        .moduleTypeEqualTo(moduleType)
        .findAll();

    return collections.map((c) => fromMap(c.toMap())).toList();
  }

  // ProductRepository interface implementation

  @override
  Future<List<Product>> fetchProducts() async {
    try {
      developer.log(
        'Fetching products for enterprise: $enterpriseId',
        name: 'ProductOfflineRepository',
      );
      return await getAllForEnterprise(enterpriseId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching products',
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
      // Try to find by remote ID first
      final collection = await isarService.isar.productCollections
          .filter()
          .remoteIdEqualTo(id)
          .and()
          .enterpriseIdEqualTo(enterpriseId)
          .findFirst();

      if (collection != null) {
        return fromMap(collection.toMap());
      }

      // Try to find by local ID
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting product: $id',
        name: 'ProductOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final collection = await isarService.isar.productCollections
          .filter()
          .barcodeEqualTo(barcode)
          .and()
          .enterpriseIdEqualTo(enterpriseId)
          .and()
          .moduleTypeEqualTo(moduleType)
          .findFirst();

      if (collection == null) return null;
      return fromMap(collection.toMap());
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting product by barcode: $barcode',
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
      final localId = getLocalId(product);
      final productWithLocalId = product.copyWith(id: localId);
      await save(productWithLocalId);
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating product',
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
      await save(product);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating product: ${product.id}',
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
      developer.log(
        'Error deleting product: $id',
        name: 'ProductOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}

