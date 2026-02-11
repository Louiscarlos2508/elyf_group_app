import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../domain/entities/liquidity_checkpoint.dart';
import '../../domain/repositories/liquidity_repository.dart';

/// Offline-first repository for LiquidityCheckpoint entities.
class LiquidityOfflineRepository extends OfflineRepository<LiquidityCheckpoint>
    implements LiquidityRepository {
  LiquidityOfflineRepository({
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
  String get collectionName => 'liquidity_checkpoints';

  @override
  LiquidityCheckpoint fromMap(Map<String, dynamic> map) {
    return LiquidityCheckpoint.fromMap(map, enterpriseId);
  }

  @override
  Map<String, dynamic> toMap(LiquidityCheckpoint entity) {
    return entity.toMap();
  }

  @override
  String getLocalId(LiquidityCheckpoint entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(LiquidityCheckpoint entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(LiquidityCheckpoint entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(LiquidityCheckpoint entity) async {
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
  Future<void> deleteFromLocal(LiquidityCheckpoint entity) async {
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
  Future<LiquidityCheckpoint?> getByLocalId(String localId) async {
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
  Future<List<LiquidityCheckpoint>> getAllForEnterprise(
    String enterpriseId,
  ) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final checkpoints = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((c) => !c.isDeleted)
        .toList();
    
    // Dédupliquer par remoteId pour éviter les doublons
    final deduplicatedCheckpoints = deduplicateByRemoteId(checkpoints);
    
    // Trier par date décroissante
    deduplicatedCheckpoints.sort((a, b) => b.date.compareTo(a.date));
    return deduplicatedCheckpoints;
  }

  Future<List<LiquidityCheckpoint>> getAllDeletedForEnterprise(
    String enterpriseId,
  ) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final checkpoints = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((c) => c.isDeleted)
        .toList();
    
    return deduplicateByRemoteId(checkpoints);
  }

  // LiquidityRepository implementation

  @override
  Future<List<LiquidityCheckpoint>> fetchCheckpoints({
    String? enterpriseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final checkpoints = await getAllForEnterprise(
        enterpriseId ?? this.enterpriseId,
      );
      return checkpoints.where((c) {
        if (startDate != null && c.date.isBefore(startDate)) return false;
        if (endDate != null && c.date.isAfter(endDate)) return false;
        return true;
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching checkpoints: ${appException.message}',
        name: 'LiquidityOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<LiquidityCheckpoint?> getCheckpoint(String checkpointId) async {
    try {
      return await getByLocalId(checkpointId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting checkpoint: $checkpointId - ${appException.message}',
        name: 'LiquidityOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<LiquidityCheckpoint?> getTodayCheckpoint(String enterpriseId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final checkpoints = await fetchCheckpoints(
        enterpriseId: enterpriseId,
        startDate: startOfDay,
        endDate: endOfDay,
      );
      return checkpoints.isNotEmpty ? checkpoints.first : null;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting today checkpoint: ${appException.message}',
        name: 'LiquidityOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> createCheckpoint(LiquidityCheckpoint checkpoint) async {
    try {
      final localId = getLocalId(checkpoint);
      final now = DateTime.now();
      final checkpointWithLocalId = checkpoint.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        createdAt: checkpoint.createdAt ?? now,
        updatedAt: now,
      );
      await save(checkpointWithLocalId);

      // Audit Log
      await auditTrailRepository.log(
        AuditRecord(
          id: LocalIdGenerator.generate(),
          enterpriseId: enterpriseId,
          userId: userId,
          module: 'orange_money',
          action: 'create_liquidity_checkpoint',
          entityId: localId,
          entityType: 'liquidity_checkpoint',
          metadata: {
            'amount': checkpoint.amount,
            'type': checkpoint.type.name,
            'date': checkpoint.date.toIso8601String(),
          },
          timestamp: now,
        ),
      );

      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error creating checkpoint: ${appException.message}',
        name: 'LiquidityOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateCheckpoint(LiquidityCheckpoint checkpoint) async {
    try {
      final now = DateTime.now();
      final updated = checkpoint.copyWith(updatedAt: now);
      await save(updated);

      // Audit Log
      await auditTrailRepository.log(
        AuditRecord(
          id: LocalIdGenerator.generate(),
          enterpriseId: enterpriseId,
          userId: userId,
          module: 'orange_money',
          action: 'update_liquidity_checkpoint',
          entityId: checkpoint.id,
          entityType: 'liquidity_checkpoint',
          metadata: {
            'amount': checkpoint.amount,
            'type': checkpoint.type.name,
          },
          timestamp: now,
        ),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating checkpoint: ${checkpoint.id} - ${appException.message}',
        name: 'LiquidityOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteCheckpoint(String checkpointId, String userId) async {
    try {
      final checkpoint = await getCheckpoint(checkpointId);
      if (checkpoint != null) {
        final now = DateTime.now();
        final updatedCheckpoint = checkpoint.copyWith(
          deletedAt: now,
          deletedBy: userId,
          updatedAt: now,
        );
        await save(updatedCheckpoint);

        // Audit Log
        await auditTrailRepository.log(
          AuditRecord(
            id: LocalIdGenerator.generate(),
            enterpriseId: enterpriseId,
            userId: userId,
            module: 'orange_money',
            action: 'delete_liquidity_checkpoint',
            entityId: checkpointId,
            entityType: 'liquidity_checkpoint',
            metadata: {'amount': checkpoint.amount, 'type': checkpoint.type.name},
            timestamp: now,
          ),
        );
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting checkpoint: $checkpointId - ${appException.message}',
        name: 'LiquidityOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> restoreCheckpoint(String checkpointId) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      
      final row = rows.firstWhere(
        (r) {
          final data = jsonDecode(r.dataJson) as Map<String, dynamic>;
          return data['id'] == checkpointId || r.localId == checkpointId;
        },
      );

      final checkpoint = fromMap(jsonDecode(row.dataJson) as Map<String, dynamic>);
      
      final now = DateTime.now();
      final updatedCheckpoint = checkpoint.copyWith(
        deletedAt: null,
        deletedBy: null,
        updatedAt: now,
      );
      await save(updatedCheckpoint);

      // Audit Log
      await auditTrailRepository.log(
        AuditRecord(
          id: LocalIdGenerator.generate(),
          enterpriseId: enterpriseId,
          userId: userId,
          module: 'orange_money',
          action: 'restore_liquidity_checkpoint',
          entityId: checkpointId,
          entityType: 'liquidity_checkpoint',
          timestamp: now,
        ),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error restoring checkpoint: $checkpointId',
        name: 'LiquidityOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<List<LiquidityCheckpoint>> watchCheckpoints({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      var checkpoints = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((c) => !c.isDeleted)
          .toList();

      if (startDate != null) {
        checkpoints = checkpoints.where((c) => !c.date.isBefore(startDate)).toList();
      }
      if (endDate != null) {
        checkpoints = checkpoints.where((c) => !c.date.isAfter(endDate)).toList();
      }

      checkpoints.sort((a, b) => b.date.compareTo(a.date));
      return deduplicateByRemoteId(checkpoints);
    });
  }

  @override
  Stream<List<LiquidityCheckpoint>> watchDeletedCheckpoints() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      final checkpoints = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((c) => c.isDeleted)
          .toList();

      checkpoints.sort((a, b) => (b.deletedAt ?? DateTime.now()).compareTo(a.deletedAt ?? DateTime.now()));
      return deduplicateByRemoteId(checkpoints);
    });
  }

  @override
  Future<Map<String, dynamic>> getStatistics({
    String? enterpriseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final checkpoints = await fetchCheckpoints(
        enterpriseId: enterpriseId,
        startDate: startDate,
        endDate: endDate,
      );

      final totalAmount = checkpoints.fold<int>(0, (sum, c) => sum + c.amount);
      final completedCheckpoints = checkpoints
          .where((c) => c.isComplete)
          .toList();

      return {
        'totalCheckpoints': checkpoints.length,
        'completedCheckpoints': completedCheckpoints.length,
        'totalLiquidity': totalAmount,
        'averageLiquidity': checkpoints.isEmpty
            ? 0
            : totalAmount ~/ checkpoints.length,
      };
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting liquidity statistics: ${appException.message}',
        name: 'LiquidityOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
