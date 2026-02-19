import 'dart:convert';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/entities/supplier_settlement.dart';
import '../../domain/repositories/supplier_repository.dart';

/// Offline-first repository for Supplier entities (eau_minerale module).
class SupplierOfflineRepository implements SupplierRepository {
  SupplierOfflineRepository({
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

  String get collectionName => 'suppliers';

  Supplier _recordToEntity(String dataJson) {
    return Supplier.fromMap(jsonDecode(dataJson) as Map<String, dynamic>, enterpriseId);
  }

  @override
  Future<List<Supplier>> fetchSuppliers({int limit = 100}) async {
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
  Future<Supplier?> getSupplier(String id) async {
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
  Future<String> createSupplier(Supplier supplier) async {
    try {
      final localId = LocalIdGenerator.generate();
      final entity = supplier.copyWith(id: localId, enterpriseId: enterpriseId);
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
        action: 'create_supplier',
        entityId: localId,
        metadata: {'name': supplier.name},
      );

      return localId;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<void> updateSupplier(Supplier supplier) async {
    try {
      final map = supplier.toMap();
      final record = await driftService.records.findByLocalId(
        collectionName: collectionName,
        localId: supplier.id,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );

      await driftService.records.upsert(
        collectionName: collectionName,
        localId: supplier.id,
        remoteId: record?.remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      await syncManager.queueUpdate(
        collectionName: collectionName,
        localId: supplier.id,
        remoteId: record?.remoteId ?? '',
        data: map,
        enterpriseId: enterpriseId,
      );

      await _logAudit(
        action: 'update_supplier',
        entityId: supplier.id,
        metadata: {'name': supplier.name},
      );
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<void> deleteSupplier(String id) async {
    try {
      final supplier = await getSupplier(id);
      if (supplier == null) return;

      final map = supplier.toMap()..['deletedAt'] = DateTime.now().toIso8601String();
      
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
        action: 'delete_supplier',
        entityId: id,
      );
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Stream<List<Supplier>> watchSuppliers({int limit = 100}) {
    return driftService.records.watchForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    ).map((rows) => rows.map((r) => _recordToEntity(r.dataJson)).toList());
  }

  @override
  Future<List<Supplier>> searchSuppliers(String query) async {
    final all = await fetchSuppliers();
    final q = query.toLowerCase();
    return all.where((s) => s.name.toLowerCase().contains(q) || (s.phone?.contains(q) ?? false)).toList();
  }

  @override
  Future<String> recordSettlement(SupplierSettlement settlement) async {
    try {
      final localId = LocalIdGenerator.generate();
      final entity =
          settlement.copyWith(id: localId, enterpriseId: enterpriseId);
      final map = entity.toMap()..['localId'] = localId;

      await driftService.records.upsert(
        collectionName: 'supplier_settlements',
        localId: localId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      await syncManager.queueCreate(
        collectionName: 'supplier_settlements',
        localId: localId,
        data: map,
        enterpriseId: enterpriseId,
      );

      await _logAudit(
        action: 'record_settlement',
        entityId: localId,
        metadata: {
          'supplierId': settlement.supplierId,
          'amount': settlement.amount,
        },
      );

      return localId;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<List<SupplierSettlement>> fetchSettlements(String supplierId) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: 'supplier_settlements',
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );
      return rows
          .map((r) => SupplierSettlement.fromMap(
              jsonDecode(r.dataJson) as Map<String, dynamic>, enterpriseId))
          .where((s) => s.supplierId == supplierId)
          .toList();
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
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
          entityType: 'supplier',
          metadata: metadata,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to log supplier audit: $action', error: e);
    }
  }
}
