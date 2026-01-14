import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/domain/entities/attached_file.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/repositories/purchase_repository.dart';

/// Offline-first repository for Purchase entities.
class PurchaseOfflineRepository extends OfflineRepository<Purchase>
    implements PurchaseRepository {
  PurchaseOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'purchases';

  @override
  Purchase fromMap(Map<String, dynamic> map) {
    final items =
        (map['items'] as List<dynamic>?)
            ?.map(
              (item) => PurchaseItem(
                productId: item['productId'] as String,
                productName: item['productName'] as String,
                quantity: (item['quantity'] as num).toInt(),
                purchasePrice: (item['purchasePrice'] as num).toInt(),
                totalPrice: (item['totalPrice'] as num).toInt(),
              ),
            )
            .toList() ??
        [];

    final attachedFilesRaw = map['attachedFiles'] as List<dynamic>?;
    final attachedFiles = attachedFilesRaw?.map((f) {
      final typeString = f['type'] as String? ?? 'document';
      AttachedFileType fileType;
      switch (typeString) {
        case 'image':
          fileType = AttachedFileType.image;
          break;
        case 'pdf':
          fileType = AttachedFileType.pdf;
          break;
        default:
          fileType = AttachedFileType.document;
      }
      return AttachedFile(
        id: f['id'] as String,
        name: f['name'] as String,
        path:
            f['path'] as String? ??
            f['url'] as String? ??
            '', // Support both path and url for backward compatibility
        type: fileType,
        size: (f['size'] as num?)?.toInt(),
        uploadedAt: f['uploadedAt'] != null
            ? DateTime.parse(f['uploadedAt'] as String)
            : null,
      );
    }).toList();

    return Purchase(
      id: map['id'] as String? ?? map['localId'] as String,
      date: DateTime.parse(map['date'] as String),
      items: items,
      totalAmount: (map['totalAmount'] as num).toInt(),
      supplier: map['supplier'] as String?,
      notes: map['notes'] as String?,
      attachedFiles: attachedFiles,
    );
  }

  @override
  Map<String, dynamic> toMap(Purchase entity) {
    return {
      'id': entity.id,
      'date': entity.date.toIso8601String(),
      'items': entity.items
          .map(
            (item) => {
              'productId': item.productId,
              'productName': item.productName,
              'quantity': item.quantity,
              'purchasePrice': item.purchasePrice,
              'totalPrice': item.totalPrice,
            },
          )
          .toList(),
      'totalAmount': entity.totalAmount,
      'supplier': entity.supplier,
      'notes': entity.notes,
      'attachedFiles': entity.attachedFiles
          ?.map(
            (f) => {
              'id': f.id,
              'name': f.name,
              'path': f.path,
              'type': f.type.name, // image, pdf, document
              'size': f.size,
              'uploadedAt': f.uploadedAt?.toIso8601String(),
            },
          )
          .toList(),
    };
  }

  @override
  String getLocalId(Purchase entity) {
    if (entity.id.startsWith('local_')) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Purchase entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(Purchase entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Purchase entity) async {
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
  Future<void> deleteFromLocal(Purchase entity) async {
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
  Future<Purchase?> getByLocalId(String localId) async {
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
  Future<List<Purchase>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final purchases = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
    purchases.sort((a, b) => b.date.compareTo(a.date));
    return purchases;
  }

  // PurchaseRepository implementation

  @override
  Future<List<Purchase>> fetchPurchases({int limit = 50}) async {
    try {
      developer.log(
        'Fetching purchases for enterprise: $enterpriseId',
        name: 'PurchaseOfflineRepository',
      );
      final purchases = await getAllForEnterprise(enterpriseId);
      return purchases.take(limit).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching purchases',
        name: 'PurchaseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Purchase?> getPurchase(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting purchase: $id',
        name: 'PurchaseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> createPurchase(Purchase purchase) async {
    try {
      final localId = getLocalId(purchase);
      final purchaseWithLocalId = Purchase(
        id: localId,
        date: purchase.date,
        items: purchase.items,
        totalAmount: purchase.totalAmount,
        supplier: purchase.supplier,
        notes: purchase.notes,
        attachedFiles: purchase.attachedFiles,
      );
      await save(purchaseWithLocalId);
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating purchase',
        name: 'PurchaseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
