import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../domain/entities/commission.dart';
import '../../domain/repositories/commission_repository.dart';

/// Offline-first repository for Commission entities.
class CommissionOfflineRepository extends OfflineRepository<Commission>
    implements CommissionRepository {
  CommissionOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.auditTrailRepository,
    required this.userId,
    this.moduleType = 'orange_money',
  });

  final String enterpriseId;
  final String moduleType;
  final AuditTrailRepository auditTrailRepository;
  final String userId;

  @override
  String get collectionName => 'commissions';

  @override
  Commission fromMap(Map<String, dynamic> map) {
    return Commission.fromMap(map, enterpriseId);
  }

  @override
  Map<String, dynamic> toMap(Commission entity) {
    return entity.toMap();
  }

  @override
  String getLocalId(Commission entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Commission entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(Commission entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(Commission entity) async {
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
  Future<void> deleteFromLocal(Commission entity) async {
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
  Future<Commission?> getByLocalId(String localId) async {
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
  Future<List<Commission>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final entities = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((c) => !c.isDeleted)
        .toList();

    // Dédupliquer par remoteId pour éviter les doublons
    return deduplicateByRemoteId(entities);
  }

  Future<List<Commission>> getAllDeletedForEnterprise(
    String enterpriseId,
  ) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final entities = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((c) => c.isDeleted)
        .toList();

    return deduplicateByRemoteId(entities);
  }


  // CommissionRepository implementation

  @override
  Future<List<Commission>> fetchCommissions({
    String? enterpriseId,
    CommissionStatus? status,
    String? period,
  }) async {
    try {
      final commissions = await getAllForEnterprise(
        enterpriseId ?? this.enterpriseId,
      );
      return commissions.where((c) {
        if (status != null && c.status != status) return false;
        if (period != null && c.period != period) return false;
        return true;
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching commissions',
        name: 'CommissionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Commission?> getCommission(String commissionId) async {
    try {
      return await getByLocalId(commissionId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting commission: $commissionId - ${appException.message}',
        name: 'CommissionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Commission?> getCurrentMonthCommission(String enterpriseId) async {
    try {
      final now = DateTime.now();
      final currentPeriod =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final commissions = await fetchCommissions(
        enterpriseId: enterpriseId,
        period: currentPeriod,
      );
      return commissions.isNotEmpty ? commissions.first : null;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting current month commission: ${appException.message}',
        name: 'CommissionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> createCommission(Commission commission) async {
    try {
      final localId = getLocalId(commission);
      final now = DateTime.now();
      final commissionWithLocalId = commission.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        createdAt: commission.createdAt ?? now,
        updatedAt: now,
      );
      await save(commissionWithLocalId);

      // Audit Log
      await auditTrailRepository.log(
        AuditRecord(
          id: LocalIdGenerator.generate(),
          enterpriseId: enterpriseId,
          userId: userId,
          module: 'orange_money',
          action: 'create_commission',
          entityId: localId,
          entityType: 'commission',
          metadata: {
            'period': commission.period,
            'estimatedAmount': commission.estimatedAmount,
          },
          timestamp: now,
        ),
      );

      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error creating commission',
        name: 'CommissionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateCommission(Commission commission) async {
    try {
      final now = DateTime.now();
      final updated = commission.copyWith(updatedAt: now);
      await save(updated);

      // Audit Log
      await auditTrailRepository.log(
        AuditRecord(
          id: LocalIdGenerator.generate(),
          enterpriseId: enterpriseId,
          userId: userId,
          module: 'orange_money',
          action: 'update_commission',
          entityId: commission.id,
          entityType: 'commission',
          metadata: {
            'period': commission.period,
            'status': commission.status.name,
            'amount': commission.amount,
          },
          timestamp: now,
        ),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating commission: ${commission.id} - ${appException.message}',
        name: 'CommissionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteCommission(String commissionId, String userId) async {
    try {
      final commission = await getCommission(commissionId);
      if (commission != null) {
        final now = DateTime.now();
        final updatedCommission = commission.copyWith(
          deletedAt: now,
          deletedBy: userId,
          updatedAt: now,
        );
        await save(updatedCommission);

        // Audit Log
        await auditTrailRepository.log(
          AuditRecord(
            id: LocalIdGenerator.generate(),
            enterpriseId: enterpriseId,
            userId: userId,
            module: 'orange_money',
            action: 'delete_commission',
            entityId: commissionId,
            entityType: 'commission',
            metadata: {'period': commission.period},
            timestamp: now,
          ),
        );
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting commission: $commissionId - ${appException.message}',
        name: 'CommissionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> restoreCommission(String commissionId) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      
      final row = rows.firstWhere(
        (r) {
          final data = jsonDecode(r.dataJson) as Map<String, dynamic>;
          return data['id'] == commissionId || r.localId == commissionId;
        },
      );

      final commission = fromMap(jsonDecode(row.dataJson) as Map<String, dynamic>);
      
      final now = DateTime.now();
      final updatedCommission = commission.copyWith(
        deletedAt: null,
        deletedBy: null,
        updatedAt: now,
      );
      await save(updatedCommission);

      // Audit Log
      await auditTrailRepository.log(
        AuditRecord(
          id: LocalIdGenerator.generate(),
          enterpriseId: enterpriseId,
          userId: userId,
          module: 'orange_money',
          action: 'restore_commission',
          entityId: commissionId,
          entityType: 'commission',
          timestamp: now,
        ),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error restoring commission: $commissionId',
        name: 'CommissionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<List<Commission>> watchDeletedCommissions() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      final commissions = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((c) => c.isDeleted)
          .toList();

      commissions.sort((a, b) => (b.deletedAt ?? DateTime.now()).compareTo(a.deletedAt ?? DateTime.now()));
      return deduplicateByRemoteId(commissions);
    });
  }

  @override
  Future<Map<String, dynamic>> getStatistics({String? enterpriseId}) async {
    try {
      final commissions = await getAllForEnterprise(
        enterpriseId ?? this.enterpriseId,
      );
      final paidCommissions = commissions
          .where((c) => c.status == CommissionStatus.paid)
          .toList();
      final pendingCommissions = commissions
          .where((c) => c.status == CommissionStatus.pending)
          .toList();

      return {
        'totalCommissions': commissions.length,
        'totalPaid': paidCommissions.fold<int>(0, (sum, c) => sum + c.amount),
        'totalPending': pendingCommissions.fold<int>(
          0,
          (sum, c) => sum + c.amount,
        ),
        'paidCount': paidCommissions.length,
        'pendingCount': pendingCommissions.length,
      };
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting commission statistics: ${appException.message}',
        name: 'CommissionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
