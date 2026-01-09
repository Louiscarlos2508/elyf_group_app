import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/repositories/purchase_repository.dart';

/// Offline-first repository for Purchase entities (boutique module).
class PurchaseOfflineRepository extends OfflineRepository<Purchase>
    implements PurchaseRepository {
  PurchaseOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'purchases';

  @override
  Purchase fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] as String? ?? map['localId'] as String,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => PurchaseItem(
                    productId: item['productId'] as String,
                    productName: item['productName'] as String,
                    quantity: (item['quantity'] as num?)?.toInt() ?? 0,
                    purchasePrice: (item['purchasePrice'] as num?)?.toInt() ?? 0,
                    totalPrice: (item['totalPrice'] as num?)?.toInt() ?? 0,
                  ))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] as num?)?.toInt() ?? 0,
      supplier: map['supplier'] as String?,
      notes: map['notes'] as String?,
      attachedFiles: null, // TODO: Implémenter si nécessaire
    );
  }

  @override
  Map<String, dynamic> toMap(Purchase entity) {
    return {
      'id': entity.id,
      'date': entity.date.toIso8601String(),
      'items': entity.items.map((item) => {
            'productId': item.productId,
            'productName': item.productName,
            'quantity': item.quantity,
            'purchasePrice': item.purchasePrice,
            'totalPrice': item.totalPrice,
          }).toList(),
      'totalAmount': entity.totalAmount,
      'supplier': entity.supplier,
      'notes': entity.notes,
    };
  }

  @override
  String getLocalId(Purchase entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Purchase entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
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
      moduleType: 'boutique',
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
        moduleType: 'boutique',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'boutique',
    );
  }

  @override
  Future<Purchase?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'boutique',
    );
    if (byRemote != null) {
      final map = jsonDecode(byRemote.dataJson) as Map<String, dynamic>;
      return fromMap(map);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'boutique',
    );
    if (byLocal == null) return null;

    final map = jsonDecode(byLocal.dataJson) as Map<String, dynamic>;
    return fromMap(map);
  }

  @override
  Future<List<Purchase>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'boutique',
    );
    return rows
        .map((row) {
          try {
            final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
            return fromMap(map);
          } catch (e) {
            developer.log(
              'Error parsing purchase: $e',
              name: 'PurchaseOfflineRepository',
            );
            return null;
          }
        })
        .whereType<Purchase>()
        .toList();
  }

  // Implémentation de PurchaseRepository

  @override
  Future<List<Purchase>> fetchPurchases({int limit = 50}) async {
    try {
      final purchases = await getAllForEnterprise(enterpriseId);
      purchases.sort((a, b) => b.date.compareTo(a.date));
      return purchases.take(limit).toList();
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching purchases',
        name: 'PurchaseOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<Purchase?> getPurchase(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting purchase',
        name: 'PurchaseOfflineRepository',
        error: appException,
      );
      return null;
    }
  }

  @override
  Future<String> createPurchase(Purchase purchase) async {
    try {
      final purchaseWithId = purchase.id.isEmpty
          ? Purchase(
              id: LocalIdGenerator.generate(),
              date: purchase.date,
              items: purchase.items,
              totalAmount: purchase.totalAmount,
              supplier: purchase.supplier,
              notes: purchase.notes,
              attachedFiles: purchase.attachedFiles,
            )
          : purchase;
      await save(purchaseWithId);
      return purchaseWithId.id;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating purchase',
        name: 'PurchaseOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }
}

