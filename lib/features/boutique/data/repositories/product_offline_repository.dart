import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
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
    required this.auditTrailRepository,
    this.userId = 'system',
  });

  final String enterpriseId;
  final String moduleType;
  final AuditTrailRepository auditTrailRepository;
  final String userId;

  @override
  String get collectionName => 'products';

  @override
  Product fromMap(Map<String, dynamic> map) {
    return Product.fromMap(map, enterpriseId);
  }

  @override
  Map<String, dynamic> toMap(Product entity) {
    return entity.toMap();
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
      // Try to find by local ID
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
      AppLogger.error(
        'Error getting product by barcode: $barcode - ${appException.message}',
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
      final productWithLocalId = product.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        updatedAt: DateTime.now(),
      );
      await save(productWithLocalId);
      
      // Audit Log
      await _logAudit(
        action: 'create_product',
        entityId: localId,
        metadata: {'name': product.name, 'price': product.price},
      );

      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
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
      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      await save(updatedProduct);

      // Audit Log
      await _logAudit(
        action: 'update_product',
        entityId: product.id,
        metadata: {'name': product.name, 'price': product.price},
      );
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
  Future<void> deleteProduct(String id, {String? deletedBy}) async {
    try {
      final product = await getProduct(id);
      if (product != null && !product.isDeleted) {
        // Soft delete: marquer comme supprimé au lieu de supprimer physiquement
        final deletedProduct = product.copyWith(
          deletedAt: DateTime.now(),
          deletedBy: deletedBy,
          updatedAt: DateTime.now(),
        );
        await save(deletedProduct);

        // Audit Log
        await _logAudit(
          action: 'delete_product',
          entityId: id,
          metadata: {'deletedBy': deletedBy},
        );
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
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
          updatedAt: DateTime.now(),
        );
        await save(restoredProduct);

        // Audit Log
        await _logAudit(
          action: 'restore_product',
          entityId: id,
        );
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error restoring product: $id - ${appException.message}',
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
      AppLogger.error(
        'Error fetching deleted products: ${appException.message}',
        name: 'ProductOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<List<Product>> watchProducts() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      final products = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .toList();
      return deduplicateByRemoteId(products)
          .where((p) => !p.isDeleted)
          .toList();
    });
  }

  @override
  Stream<List<Product>> watchDeletedProducts() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
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
    });
  }

  Future<void> _logAudit({
    required String action,
    required String entityId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await auditTrailRepository.log(
        AuditRecord(
          id: '', // Generated by repository
          enterpriseId: enterpriseId,
          userId: userId,
          module: 'boutique',
          action: action,
          entityId: entityId,
          entityType: 'product',
          metadata: metadata,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to log product audit: $action', error: e);
    }
  }
}
