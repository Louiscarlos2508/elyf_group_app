import 'dart:convert';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../domain/entities/closing.dart';
import '../../domain/repositories/closing_repository.dart';

/// Offline-first repository for financial Closing sessions (eau_minerale module).
class ClosingOfflineRepository implements ClosingRepository {
  ClosingOfflineRepository({
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

  String get collectionName => 'closings';

  Closing _recordToEntity(String dataJson) {
    return Closing.fromMap(jsonDecode(dataJson) as Map<String, dynamic>, enterpriseId);
  }

  @override
  Future<Closing?> getCurrentSession() async {
    try {
      final all = await fetchHistory(limit: 10);
      if (all.isEmpty) return null;
      
      // Sort by date descending
      all.sort((a, b) => b.date.compareTo(a.date));
      final last = all.first;
      
      if (last.status == ClosingStatus.open) {
        return last;
      }
      return null;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<String> openSession(Closing session) async {
    try {
      final localId = LocalIdGenerator.generate();
      final entity = session.copyWith(id: localId, enterpriseId: enterpriseId);
      final map = entity.toMap()..['localId'] = localId;

      await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
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
        action: 'open_session',
        entityId: localId,
        metadata: {
          'number': entity.number,
          'openingCash': entity.openingCashAmount,
        },
      );

      return localId;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<void> closeSession(Closing session) async {
    try {
      final map = session.toMap();
      final record = await driftService.records.findByLocalId(
        collectionName: collectionName,
        localId: session.id,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );

      await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
        collectionName: collectionName,
        localId: session.id,
        remoteId: record?.remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      await syncManager.queueUpdate(
        collectionName: collectionName,
        localId: session.id,
        remoteId: record?.remoteId ?? '',
        data: map,
        enterpriseId: enterpriseId,
      );

      await _logAudit(
        action: 'close_session',
        entityId: session.id,
        metadata: {
          'number': session.number,
          'expectedCash': session.expectedCash,
          'physicalCash': session.physicalCashAmount,
          'discrepancy': session.cashDiscrepancy,
        },
      );
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<List<Closing>> fetchHistory({int limit = 50}) async {
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
  Stream<Closing?> watchCurrentSession() {
    return driftService.records.watchForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    ).map((rows) {
      if (rows.isEmpty) return null;
      final all = rows.map((r) => _recordToEntity(r.dataJson)).toList();
      all.sort((a, b) => b.date.compareTo(a.date));
      final last = all.first;
      return last.status == ClosingStatus.open ? last : null;
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
          userId: syncManager.getUserId() ?? '',
          module: 'eau_minerale',
          action: action,
          entityId: entityId,
          entityType: 'closing',
          metadata: metadata,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      // Ignore audit logging errors
    }
  }
}
