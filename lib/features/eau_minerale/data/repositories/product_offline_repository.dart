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

/// Offline-first repository for Product entities (eau_minerale module).
class ProductOfflineRepository extends OfflineRepository<Product>
    implements ProductRepository {
  ProductOfflineRepository({
    required super.isarService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'products';

  @override
  Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String? ?? map['remoteId'] as String,
      name: map['name'] as String,
      type: _parseProductType(map['category'] as String? ?? map['type'] as String? ?? 'finishedGood'),
      unitPrice: (map['unitPrice'] as num?)?.toInt() ?? 
                 (map['sellingPrice'] as num?)?.toInt() ?? 0,
      unit: map['unit'] as String? ?? 'Unité',
      description: map['description'] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap(Product entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'type': entity.type.name,
      'category': entity.type.name,
      'unitPrice': entity.unitPrice.toDouble(),
      'sellingPrice': entity.unitPrice.toDouble(),
      'unit': entity.unit,
      'description': entity.description,
      'isActive': true,
    };
  }

  @override
  String getLocalId(Product entity) {
    // ProductCollection uses remoteId as primary identifier
    // For local products, we'll use the entity.id directly
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
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
  Future<void> saveToLocal(Product entity) async {
    final map = toMap(entity);
    final remoteId = getRemoteId(entity) ?? getLocalId(entity);
    
    final collection = ProductCollection.fromMap(
      {...map, 'id': remoteId},
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
      localId: getLocalId(entity),
    );
    collection.localUpdatedAt = DateTime.now();

    await isarService.isar.writeTxn(() async {
      await isarService.isar.productCollections.put(collection);
    });
  }

  @override
  Future<void> deleteFromLocal(Product entity) async {
    final remoteId = getRemoteId(entity) ?? entity.id;
    await isarService.isar.writeTxn(() async {
      await isarService.isar.productCollections
          .filter()
          .remoteIdEqualTo(remoteId)
          .and()
          .enterpriseIdEqualTo(enterpriseId)
          .and()
          .moduleTypeEqualTo('eau_minerale')
          .deleteAll();
    });
  }

  @override
  Future<Product?> getByLocalId(String localId) async {
    // Try to find by remoteId first
    var collection = await isarService.isar.productCollections
        .filter()
        .remoteIdEqualTo(localId)
        .and()
        .enterpriseIdEqualTo(enterpriseId)
        .and()
        .moduleTypeEqualTo('eau_minerale')
        .findFirst();

    if (collection != null) {
      return fromMap(collection.toMap());
    }

    return null;
  }

  @override
  Future<List<Product>> getAllForEnterprise(String enterpriseId) async {
    final collections = await isarService.isar.productCollections
        .filter()
        .enterpriseIdEqualTo(enterpriseId)
        .and()
        .moduleTypeEqualTo('eau_minerale')
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
      final collection = await isarService.isar.productCollections
          .filter()
          .remoteIdEqualTo(id)
          .and()
          .enterpriseIdEqualTo(enterpriseId)
          .and()
          .moduleTypeEqualTo('eau_minerale')
          .findFirst();

      if (collection != null) {
        return fromMap(collection.toMap());
      }

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
  Future<String> createProduct(Product product) async {
    try {
      final localId = getLocalId(product);
      final productWithLocalId = Product(
        id: localId,
        name: product.name,
        type: product.type,
        unitPrice: product.unitPrice,
        unit: product.unit,
        description: product.description,
      );
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

  ProductType _parseProductType(String type) {
    switch (type) {
      case 'rawMaterial':
      case 'MP':
        return ProductType.rawMaterial;
      case 'finishedGood':
      case 'PF':
        return ProductType.finishedGood;
      default:
        return ProductType.finishedGood;
    }
  }
}

