import 'dart:developer' as developer;
import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

/// Offline-first repository for Product entities.
class ProductOfflineRepository extends OfflineRepository<Product>
    implements ProductRepository {
  ProductOfflineRepository({
    required super.driftService,
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
    DateTime? deletedAt;
    if (map['deletedAt'] != null) {
      deletedAt = map['deletedAt'] is DateTime
          ? map['deletedAt'] as DateTime
          : DateTime.parse(map['deletedAt'] as String);
    }
    return Product(
      id: map['id'] as String? ?? map['localId'] as String,
      name: map['name'] as String,
      price:
          (map['price'] as num?)?.toInt() ??
          (map['sellingPrice'] as num?)?.toInt() ??
          0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      description: map['description'] as String?,
      category: map['category'] as String?,
      imageUrl: map['imageUrl'] as String?,
      barcode: map['barcode'] as String?,
      purchasePrice: (map['purchasePrice'] as num?)?.toInt(),
      deletedAt: deletedAt,
      deletedBy: map['deletedBy'] as String?,
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
      'deletedAt': entity.deletedAt?.toIso8601String(),
      'deletedBy': entity.deletedBy,
    };
  }

  @override
  String getLocalId(Product entity) {
    // If ID starts with 'local_', it's already a local ID
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    // Si l'ID ne commence pas par 'local_', c'est soit un remoteId, soit un ID généré
    // On utilise l'ID tel quel comme localId pour éviter les duplications
    // Le système upsert se chargera de mettre à jour l'enregistrement existant
    // si il existe déjà (par remoteId ou localId)
    return entity.id;
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
  Future<void> deleteFromLocal(Product entity) async {
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
  Future<Product?> getByLocalId(String localId) async {
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
  Future<List<Product>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final products = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
    
    // Dédupliquer par remoteId pour éviter les doublons
    final deduplicatedProducts = deduplicateByRemoteId(products);
    
    // Filtrer les produits supprimés (soft delete)
    return deduplicatedProducts.where((product) => !product.isDeleted).toList();
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
      final products = await getAllForEnterprise(enterpriseId);
      try {
        return products.firstWhere((p) => p.barcode == barcode);
      } catch (_) {
        return null;
      }
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
  Future<void> deleteProduct(String id, {String? deletedBy}) async {
    try {
      final product = await getProduct(id);
      if (product != null && !product.isDeleted) {
        // Soft delete: marquer comme supprimé au lieu de supprimer physiquement
        final deletedProduct = product.copyWith(
          deletedAt: DateTime.now(),
          deletedBy: deletedBy,
        );
        await save(deletedProduct);
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

  @override
  Future<void> restoreProduct(String id) async {
    try {
      final product = await getProduct(id);
      if (product != null && product.isDeleted) {
        // Restaurer: enlever deletedAt et deletedBy
        final restoredProduct = product.copyWith(
          deletedAt: null,
          deletedBy: null,
        );
        await save(restoredProduct);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error restoring product: $id',
        name: 'ProductOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Product>> getDeletedProducts() async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      // Récupérer uniquement les produits supprimés
      final products = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((product) => product.isDeleted)
          .toList();
      products.sort(
        (a, b) => (b.deletedAt ?? DateTime(1970)).compareTo(
          a.deletedAt ?? DateTime(1970),
        ),
      );
      return products;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching deleted products',
        name: 'ProductOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
