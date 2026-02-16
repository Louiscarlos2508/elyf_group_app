
import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/gaz_inventory_audit.dart';
import '../../domain/repositories/inventory_audit_repository.dart';

/// Implémentation offline-first de GazInventoryAuditRepository.
class GazInventoryAuditOfflineRepository implements GazInventoryAuditRepository {
  GazInventoryAuditOfflineRepository({
    required this.driftService,
    required this.syncManager,
    required this.connectivityService,
    required this.enterpriseId,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;
  final String enterpriseId;

  static const String _collectionName = 'inventory_audits';

  GazInventoryAudit _fromMap(Map<String, dynamic> map) => GazInventoryAudit.fromMap(map);
  Map<String, dynamic> _toMap(GazInventoryAudit entity) => entity.toMap();

  @override
  Future<List<GazInventoryAudit>> getAudits(
    String enterpriseId, {
    String? siteId,
    int? limit,
  }) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: _collectionName,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );

      final audits = rows
          .map((row) {
            try {
              final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
              return _fromMap(map);
            } catch (e) {
              return null;
            }
          })
          .whereType<GazInventoryAudit>()
          .where((a) => siteId == null || a.siteId == siteId)
          .toList()
        ..sort((a, b) => b.auditDate.compareTo(a.auditDate));

      if (limit != null && audits.length > limit) {
        return audits.take(limit).toList();
      }
      return audits;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting inventory audits: ${appException.message}',
        name: 'GazInventoryAuditOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Stream<List<GazInventoryAudit>> watchAudits(
    String enterpriseId, {
    String? siteId,
  }) {
    return driftService.records
        .watchForEnterprise(
          collectionName: _collectionName,
          enterpriseId: enterpriseId,
          moduleType: 'gaz',
        )
        .map((rows) {
          return rows
              .map((row) {
                try {
                  final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
                  return _fromMap(map);
                } catch (e) {
                  return null;
                }
              })
              .whereType<GazInventoryAudit>()
              .where((a) => siteId == null || a.siteId == siteId)
              .toList()
            ..sort((a, b) => b.auditDate.compareTo(a.auditDate));
        });
  }

  @override
  Future<GazInventoryAudit?> getAuditById(String id) async {
    try {
      final row = await driftService.records.findByLocalId(
        collectionName: _collectionName,
        localId: id,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );

      if (row == null) return null;

      final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
      return _fromMap(map);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Error getting inventory audit by id: $id',
        name: 'GazInventoryAuditOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> saveAudit(GazInventoryAudit audit) async {
    try {
      final localId = audit.id.startsWith('local_') || audit.id.startsWith('audit-')
          ? audit.id
          : LocalIdGenerator.generate();
      
      final remoteId = (audit.id.startsWith('local_') || audit.id.startsWith('audit-')) ? null : audit.id;

      final map = _toMap(audit)..['localId'] = localId..['id'] = localId;

      await driftService.records.upsert(
        collectionName: _collectionName,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      // Sync automatique
      await syncManager.queueCreate(
        collectionName: _collectionName,
        localId: localId,
        data: map,
        enterpriseId: enterpriseId,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Error saving inventory audit',
        name: 'GazInventoryAuditOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteAudit(String id) async {
    try {
      final audit = await getAuditById(id);
      if (audit == null) return;

      final cancelledAudit = audit.copyWith(status: InventoryAuditStatus.cancelled);
      await saveAudit(cancelledAudit);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Error deleting inventory audit',
        name: 'GazInventoryAuditOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

extension on GazInventoryAudit {
  GazInventoryAudit copyWith({
    InventoryAuditStatus? status,
  }) {
    return GazInventoryAudit(
      id: id,
      enterpriseId: enterpriseId,
      auditDate: auditDate,
      auditedBy: auditedBy,
      items: items,
      siteId: siteId,
      notes: notes,
      status: status ?? this.status,
    );
  }
}
