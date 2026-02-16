import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/services/security/ledger_hash_service.dart';

/// Offline-first repository for Purchase entities.
class PurchaseOfflineRepository extends OfflineRepository<Purchase>
    implements PurchaseRepository {
  PurchaseOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.auditTrailRepository,
    required this.enterpriseId,
    required this.moduleType,
    this.userId = 'system',
    this.shopSecret = 'DEFAULT_SECRET',
  });

  final String enterpriseId;
  final String moduleType;
  final AuditTrailRepository auditTrailRepository;
  final String userId;
  final String shopSecret;

  @override
  String get collectionName => 'purchases';

  @override
  Purchase fromMap(Map<String, dynamic> map) {
    return Purchase.fromMap(map, enterpriseId);
  }

  @override
  Map<String, dynamic> toMap(Purchase entity) {
    return entity.toMap();
  }

  @override
  String getLocalId(Purchase entity) {
    if (entity.id.isNotEmpty) return entity.id;
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
    // 1. Chain hash if not already hashed
    Purchase toSave = entity;
    if (toSave.hash == null) {
      final lastPurchase = await _getLastPurchase();
      final hash = LedgerHashService.generateHash(
        previousHash: lastPurchase?.hash,
        entity: toSave,
        shopSecret: shopSecret,
      );
      toSave = toSave.copyWith(hash: hash, previousHash: lastPurchase?.hash);
    }

    final localId = getLocalId(toSave);
    final remoteId = getRemoteId(toSave);
    final map = toMap(toSave)..['localId'] = localId;
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

  Future<Purchase?> _getLastPurchase() async {
    final all = await getAllForEnterprise(enterpriseId);
    if (all.isEmpty) return null;
    all.sort((a, b) => b.date.compareTo(a.date));
    return all.first;
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
      final map = safeDecodeJson(byRemote.dataJson, localId);
      if (map == null) return null;
      try {
        return fromMap(map);
      } catch (e, stackTrace) {
        final appException = ErrorHandler.instance.handleError(e, stackTrace);
        AppLogger.warning(
          'Error parsing Purchase from map: ${appException.message}',
          name: 'PurchaseOfflineRepository',
          error: e,
          stackTrace: stackTrace,
        );
        return null;
      }
    }
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    final map = safeDecodeJson(byLocal.dataJson, localId);
    if (map == null) return null;
    try {
      return fromMap(map);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error parsing Purchase from map: $e',
        name: 'PurchaseOfflineRepository',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<List<Purchase>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    
    // Décoder et parser de manière sécurisée, en ignorant les données corrompues
    final purchases = <Purchase>[];
    for (final row in rows) {
      final map = safeDecodeJson(row.dataJson, row.localId);
      if (map == null) continue; // Ignorer les données corrompues
      
      try {
        purchases.add(fromMap(map));
      } catch (e, stackTrace) {
        final appException = ErrorHandler.instance.handleError(e, stackTrace);
        AppLogger.warning(
          'Error parsing Purchase from map (skipping): ${appException.message}',
          name: 'PurchaseOfflineRepository',
          error: e,
          stackTrace: stackTrace,
        );
        // Continuer avec les autres enregistrements
      }
    }
    
    // Dédupliquer par remoteId pour éviter les doublons
    final deduplicatedPurchases = deduplicateByRemoteId(purchases);
    
    // Trier par date décroissante
    deduplicatedPurchases.sort((a, b) => b.date.compareTo(a.date));

    // Filtrer les achats supprimés (soft delete)
    return deduplicatedPurchases.where((purchase) => !purchase.isDeleted).toList();
  }

  // PurchaseRepository implementation

  @override
  Future<List<Purchase>> fetchPurchases({int limit = 50}) async {
    try {
      AppLogger.debug(
        'Fetching purchases for enterprise: $enterpriseId',
        name: 'PurchaseOfflineRepository',
      );
      final purchases = await getAllForEnterprise(enterpriseId);
      return purchases.take(limit).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching purchases: ${appException.message}',
        name: 'PurchaseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<int> getCountForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    final purchases = await getPurchasesInPeriod(start, end);
    return purchases.length;
  }

  @override
  Future<Purchase?> getPurchase(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
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
      
      // Generate Hash
      final lastPurchase = await _getLastPurchase();
      final hash = LedgerHashService.generateHash(
        previousHash: lastPurchase?.hash,
        entity: purchase,
        shopSecret: shopSecret,
      );

      final purchaseWithLocalId = purchase.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        updatedAt: DateTime.now(),
        hash: hash,
        previousHash: lastPurchase?.hash,
      );
      await save(purchaseWithLocalId);
      
      // Audit Log
      await _logAudit(
        action: 'create_purchase',
        entityId: localId,
        metadata: {
          'supplierId': purchase.supplierId, 
          'totalAmount': purchase.totalAmount,
          'hash': hash,
        },
      );

      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error creating purchase: ${appException.message}',
        name: 'PurchaseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Purchase>> getPurchasesInPeriod(DateTime start, DateTime end) async {
    try {
      final allPurchases = await getAllForEnterprise(enterpriseId);
      return allPurchases.where((purchase) {
        return purchase.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            purchase.date.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching purchases in period: ${appException.message}',
        name: 'PurchaseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<List<Purchase>> watchPurchases({int limit = 50}) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      final purchases = <Purchase>[];
      for (final row in rows) {
        final map = safeDecodeJson(row.dataJson, row.localId);
        if (map == null) continue;
        try {
          purchases.add(fromMap(map));
        } catch (_) {}
      }
      final deduplicatedPurchases = deduplicateByRemoteId(purchases);
      // Trier par date décroissante
      deduplicatedPurchases.sort((a, b) => b.date.compareTo(a.date));
      // Filtrer les achats actifs
      return deduplicatedPurchases.where((p) => !p.isDeleted).toList();
    });
  }

  @override
  Future<void> deletePurchase(String id, {String? deletedBy}) async {
    try {
      final purchase = await getPurchase(id);
      if (purchase != null && !purchase.isDeleted) {
        final deletedPurchase = purchase.copyWith(
          deletedAt: DateTime.now(),
          deletedBy: deletedBy,
          updatedAt: DateTime.now(),
        );
        await save(deletedPurchase);

        // Audit Log
        await _logAudit(
          action: 'delete_purchase',
          entityId: id,
          metadata: {'deletedBy': deletedBy},
        );
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting purchase: $id',
        name: 'PurchaseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> restorePurchase(String id) async {
    try {
      final purchase = await getPurchase(id);
      if (purchase != null && purchase.isDeleted) {
        final restoredPurchase = purchase.copyWith(
          deletedAt: null,
          deletedBy: null,
          updatedAt: DateTime.now(),
        );
        await save(restoredPurchase);

        // Audit Log
        await _logAudit(
          action: 'restore_purchase',
          entityId: id,
        );
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error restoring purchase: $id',
        name: 'PurchaseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Purchase>> getDeletedPurchases() async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      final purchases = <Purchase>[];
      for (final row in rows) {
        final map = safeDecodeJson(row.dataJson, row.localId);
        if (map == null) continue;
        try {
          final purchase = fromMap(map);
          if (purchase.isDeleted) {
            purchases.add(purchase);
          }
        } catch (_) {}
      }
      final deduplicatedPurchases = deduplicateByRemoteId(purchases);
      deduplicatedPurchases.sort((a, b) => b.date.compareTo(a.date));
      return deduplicatedPurchases;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching deleted purchases',
        name: 'PurchaseOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<List<Purchase>> watchDeletedPurchases() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      final purchases = <Purchase>[];
      for (final row in rows) {
        final map = safeDecodeJson(row.dataJson, row.localId);
        if (map == null) continue;
        try {
          final purchase = fromMap(map);
          if (purchase.isDeleted) {
            purchases.add(purchase);
          }
        } catch (_) {}
      }
      final deduplicatedPurchases = deduplicateByRemoteId(purchases);
      deduplicatedPurchases.sort((a, b) => b.date.compareTo(a.date));
      return deduplicatedPurchases;
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
          id: '', 
          enterpriseId: enterpriseId,
          userId: userId, 
          module: 'boutique',
          action: action,
          entityId: entityId,
          entityType: 'purchase',
          metadata: metadata,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to log purchase audit: $action', error: e);
    }
  }

  @override
  Future<bool> verifyChain() async {
    try {
      final purchases = await getAllForEnterprise(enterpriseId);
      if (purchases.isEmpty) return true;

      purchases.sort((a, b) => b.date.compareTo(a.date));

      for (int i = 0; i < purchases.length; i++) {
        final current = purchases[i];
        final previous = i + 1 < purchases.length ? purchases[i + 1] : null;

        final isValid = LedgerHashService.verify(
          current,
          previous?.hash,
          shopSecret,
        );

        if (!isValid) {
          AppLogger.error(
            'Chain integrity violation at purchase ${current.id}.',
            name: 'PurchaseOfflineRepository',
          );
          return false;
        }
      }
      return true;
    } catch (e) {
      AppLogger.error('Purchase chain verification failed', error: e);
      return false;
    }
  }
}
