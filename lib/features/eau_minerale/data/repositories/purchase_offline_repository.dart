import 'dart:convert';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/repositories/purchase_repository.dart';

/// Offline-first repository for Purchase entities (eau_minerale module).
class PurchaseOfflineRepository implements PurchaseRepository {
  PurchaseOfflineRepository({
    required this.driftService,
    required this.syncManager,
    required this.connectivityService,
    required this.enterpriseId,
    required this.auditTrailRepository,
    this.userId = 'system',
  });

  final DriftService driftService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;
  final String enterpriseId;
  final AuditTrailRepository auditTrailRepository;
  final String userId;

  String get collectionName => 'purchases';

  Purchase _recordToEntity(String dataJson) {
    return Purchase.fromMap(jsonDecode(dataJson) as Map<String, dynamic>, enterpriseId);
  }

  @override
  Future<List<Purchase>> fetchPurchases({int limit = 100}) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );
      return rows.map((r) => _recordToEntity(r.dataJson)).toList();
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<Purchase?> getPurchase(String id) async {
    try {
      final record = await driftService.records.findByLocalId(
        collectionName: collectionName,
        localId: id,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      ) ?? await driftService.records.findByRemoteId(
        collectionName: collectionName,
        remoteId: id,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );

      if (record == null) return null;
      return _recordToEntity(record.dataJson);
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<String> createPurchase(Purchase purchase) async {
    try {
      final localId = LocalIdGenerator.generate();
      final entity = purchase.copyWith(id: localId, enterpriseId: enterpriseId);
      final map = entity.toMap()..['localId'] = localId;

      await driftService.records.upsert(
        collectionName: collectionName,
        localId: localId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      await syncManager.queueCreate(
        collectionName: collectionName,
        localId: localId,
        data: map,
        enterpriseId: enterpriseId,
      );

      await _logAudit(
        action: 'create_purchase',
        entityId: localId,
        metadata: {
          'number': entity.number,
          'totalAmount': entity.totalAmount,
          'isPO': entity.isPO,
        },
      );

      return localId;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<void> updatePurchase(Purchase purchase) async {
    try {
      final map = purchase.toMap();
      final record = await driftService.records.findByLocalId(
        collectionName: collectionName,
        localId: purchase.id,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );

      await driftService.records.upsert(
        collectionName: collectionName,
        localId: purchase.id,
        remoteId: record?.remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      await syncManager.queueUpdate(
        collectionName: collectionName,
        localId: purchase.id,
        remoteId: record?.remoteId ?? '',
        data: map,
        enterpriseId: enterpriseId,
      );

      await _logAudit(
        action: 'update_purchase',
        entityId: purchase.id,
        metadata: {
          'number': purchase.number,
          'status': purchase.status.name,
        },
      );
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<void> deletePurchase(String id) async {
    try {
      final purchase = await getPurchase(id);
      if (purchase == null) return;

      final map = purchase.toMap()..['deletedAt'] = DateTime.now().toIso8601String();
      
      await driftService.records.upsert(
        collectionName: collectionName,
        localId: id,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      final databaseRecord = await driftService.records.findByLocalId(
        collectionName: collectionName,
        localId: id,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );

      await syncManager.queueDelete(
        collectionName: collectionName,
        localId: id,
        remoteId: databaseRecord?.remoteId ?? '',
        enterpriseId: enterpriseId,
      );

      await _logAudit(
        action: 'delete_purchase',
        entityId: id,
      );
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Stream<List<Purchase>> watchPurchases({int limit = 100, String? supplierId}) {
    return driftService.records.watchForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    ).map((rows) {
      final all = rows.map((r) => _recordToEntity(r.dataJson)).toList();
      if (supplierId != null) {
        return all.where((p) => p.supplierId == supplierId).toList();
      }
      return all;
    });
  }

  @override
  Future<void> validatePurchaseOrder(String purchaseId) async {
    final purchase = await getPurchase(purchaseId);
    if (purchase != null && purchase.status == PurchaseStatus.draft) {
      await updatePurchase(purchase.copyWith(status: PurchaseStatus.validated));
      await _logAudit(
        action: 'validate_po',
        entityId: purchaseId,
        metadata: {'number': purchase.number},
      );
    }
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
          module: 'eau_minerale',
          action: action,
          entityId: entityId,
          entityType: 'purchase',
          metadata: metadata,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      // Ignore audit logging errors
    }
  }
}
