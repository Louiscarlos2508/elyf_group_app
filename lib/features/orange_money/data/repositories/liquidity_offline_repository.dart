import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/liquidity_checkpoint.dart';
import '../../domain/repositories/liquidity_repository.dart';

/// Offline-first repository for LiquidityCheckpoint entities (orange_money module).
class LiquidityOfflineRepository extends OfflineRepository<LiquidityCheckpoint>
    implements LiquidityRepository {
  LiquidityOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'liquidity_checkpoints';

  @override
  LiquidityCheckpoint fromMap(Map<String, dynamic> map) {
    return LiquidityCheckpoint(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? enterpriseId,
      date: DateTime.parse(map['date'] as String),
      type: _parseType(map['type'] as String? ?? 'full'),
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      morningCheckpoint: (map['morningCheckpoint'] as num?)?.toInt(),
      eveningCheckpoint: (map['eveningCheckpoint'] as num?)?.toInt(),
      cashAmount: (map['cashAmount'] as num?)?.toInt(),
      simAmount: (map['simAmount'] as num?)?.toInt(),
      morningCashAmount: (map['morningCashAmount'] as num?)?.toInt(),
      morningSimAmount: (map['morningSimAmount'] as num?)?.toInt(),
      eveningCashAmount: (map['eveningCashAmount'] as num?)?.toInt(),
      eveningSimAmount: (map['eveningSimAmount'] as num?)?.toInt(),
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(LiquidityCheckpoint entity) {
    return {
      'id': entity.id,
      'enterpriseId': entity.enterpriseId,
      'date': entity.date.toIso8601String(),
      'type': entity.type.name,
      'amount': entity.amount,
      'morningCheckpoint': entity.morningCheckpoint,
      'eveningCheckpoint': entity.eveningCheckpoint,
      'cashAmount': entity.cashAmount,
      'simAmount': entity.simAmount,
      'morningCashAmount': entity.morningCashAmount,
      'morningSimAmount': entity.morningSimAmount,
      'eveningCashAmount': entity.eveningCashAmount,
      'eveningSimAmount': entity.eveningSimAmount,
      'notes': entity.notes,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(LiquidityCheckpoint entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(LiquidityCheckpoint entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
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
      moduleType: 'orange_money',
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
        moduleType: 'orange_money',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
  }

  @override
  Future<LiquidityCheckpoint?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
    if (byRemote != null) {
      final map = jsonDecode(byRemote.dataJson) as Map<String, dynamic>;
      return fromMap(map);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
    if (byLocal == null) return null;

    final map = jsonDecode(byLocal.dataJson) as Map<String, dynamic>;
    return fromMap(map);
  }

  @override
  Future<List<LiquidityCheckpoint>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
    return rows
        .map((row) {
          try {
            final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
            return fromMap(map);
          } catch (e) {
            developer.log(
              'Error parsing liquidity checkpoint: $e',
              name: 'LiquidityOfflineRepository',
            );
            return null;
          }
        })
        .whereType<LiquidityCheckpoint>()
        .toList();
  }

  // Implémentation de LiquidityRepository

  @override
  Future<List<LiquidityCheckpoint>> fetchCheckpoints({
    String? enterpriseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final effectiveEnterpriseId = enterpriseId ?? this.enterpriseId;
      var checkpoints = await getAllForEnterprise(effectiveEnterpriseId);

      if (startDate != null) {
        checkpoints = checkpoints
            .where((c) => c.date.isAfter(startDate) || c.date.isAtSameMomentAs(startDate))
            .toList();
      }

      if (endDate != null) {
        checkpoints = checkpoints
            .where((c) => c.date.isBefore(endDate) || c.date.isAtSameMomentAs(endDate))
            .toList();
      }

      checkpoints.sort((a, b) => b.date.compareTo(a.date));
      return checkpoints;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching checkpoints',
        name: 'LiquidityOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<LiquidityCheckpoint?> getCheckpoint(String checkpointId) async {
    try {
      return await getByLocalId(checkpointId);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting checkpoint',
        name: 'LiquidityOfflineRepository',
        error: appException,
      );
      return null;
    }
  }

  @override
  Future<LiquidityCheckpoint?> getTodayCheckpoint(String enterpriseId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final checkpoints = await fetchCheckpoints(
        enterpriseId: enterpriseId,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      return checkpoints.isNotEmpty ? checkpoints.first : null;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting today checkpoint',
        name: 'LiquidityOfflineRepository',
        error: appException,
      );
      return null;
    }
  }

  @override
  Future<String> createCheckpoint(LiquidityCheckpoint checkpoint) async {
    try {
      final checkpointWithId = checkpoint.id.isEmpty
          ? LiquidityCheckpoint(
              id: LocalIdGenerator.generate(),
              enterpriseId: checkpoint.enterpriseId,
              date: checkpoint.date,
              type: checkpoint.type,
              amount: checkpoint.amount,
              morningCheckpoint: checkpoint.morningCheckpoint,
              eveningCheckpoint: checkpoint.eveningCheckpoint,
              cashAmount: checkpoint.cashAmount,
              simAmount: checkpoint.simAmount,
              morningCashAmount: checkpoint.morningCashAmount,
              morningSimAmount: checkpoint.morningSimAmount,
              eveningCashAmount: checkpoint.eveningCashAmount,
              eveningSimAmount: checkpoint.eveningSimAmount,
              notes: checkpoint.notes,
              createdAt: checkpoint.createdAt ?? DateTime.now(),
              updatedAt: DateTime.now(),
            )
          : checkpoint;
      await save(checkpointWithId);
      return checkpointWithId.id;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating checkpoint',
        name: 'LiquidityOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateCheckpoint(LiquidityCheckpoint checkpoint) async {
    try {
      final updatedCheckpoint = LiquidityCheckpoint(
        id: checkpoint.id,
        enterpriseId: checkpoint.enterpriseId,
        date: checkpoint.date,
        type: checkpoint.type,
        amount: checkpoint.amount,
        morningCheckpoint: checkpoint.morningCheckpoint,
        eveningCheckpoint: checkpoint.eveningCheckpoint,
        cashAmount: checkpoint.cashAmount,
        simAmount: checkpoint.simAmount,
        morningCashAmount: checkpoint.morningCashAmount,
        morningSimAmount: checkpoint.morningSimAmount,
        eveningCashAmount: checkpoint.eveningCashAmount,
        eveningSimAmount: checkpoint.eveningSimAmount,
        notes: checkpoint.notes,
        createdAt: checkpoint.createdAt,
        updatedAt: DateTime.now(),
      );
      await save(updatedCheckpoint);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating checkpoint',
        name: 'LiquidityOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteCheckpoint(String checkpointId) async {
    try {
      final checkpoint = await getCheckpoint(checkpointId);
      if (checkpoint != null) {
        await delete(checkpoint);
      }
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting checkpoint',
        name: 'LiquidityOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getStatistics({
    String? enterpriseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final effectiveEnterpriseId = enterpriseId ?? this.enterpriseId;
      final checkpoints = await fetchCheckpoints(
        enterpriseId: effectiveEnterpriseId,
        startDate: startDate,
        endDate: endDate,
      );

      final totalAmount = checkpoints.fold<int>(
        0,
        (sum, c) => sum + c.amount,
      );
      final completeCount = checkpoints.where((c) => c.isComplete).length;

      return {
        'totalCheckpoints': checkpoints.length,
        'completeCheckpoints': completeCount,
        'incompleteCheckpoints': checkpoints.length - completeCount,
        'totalAmount': totalAmount,
        'averageAmount': checkpoints.isNotEmpty
            ? totalAmount / checkpoints.length
            : 0,
      };
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting statistics',
        name: 'LiquidityOfflineRepository',
        error: appException,
      );
      return {};
    }
  }

  LiquidityCheckpointType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'morning':
        return LiquidityCheckpointType.morning;
      case 'evening':
        return LiquidityCheckpointType.evening;
      case 'full':
        return LiquidityCheckpointType.full;
      default:
        return LiquidityCheckpointType.full;
    }
  }
}

