import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/offline_repository.dart';
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
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'liquidity_checkpoints';

  @override
  LiquidityCheckpoint fromMap(Map<String, dynamic> map) {
    return LiquidityCheckpoint(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String,
      date: DateTime.parse(map['date'] as String),
      type: LiquidityCheckpointType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => LiquidityCheckpointType.full,
      ),
      amount: (map['amount'] as num).toInt(),
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
    if (entity.id.startsWith('local_')) return entity.id;
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
      String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final checkpoints = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
    checkpoints.sort((a, b) => b.date.compareTo(a.date));
    return checkpoints;
  }

  // LiquidityRepository implementation

  @override
  Future<List<LiquidityCheckpoint>> fetchCheckpoints({
    String? enterpriseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final checkpoints =
          await getAllForEnterprise(enterpriseId ?? this.enterpriseId);
      return checkpoints.where((c) {
        if (startDate != null && c.date.isBefore(startDate)) return false;
        if (endDate != null && c.date.isAfter(endDate)) return false;
        return true;
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching checkpoints',
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
      developer.log(
        'Error getting checkpoint: $checkpointId',
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
      developer.log(
        'Error getting today checkpoint',
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
      final checkpointWithLocalId = LiquidityCheckpoint(
        id: localId,
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(checkpointWithLocalId);
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating checkpoint',
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
      final updated = LiquidityCheckpoint(
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
      await save(updated);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating checkpoint: ${checkpoint.id}',
        name: 'LiquidityOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
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
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting checkpoint: $checkpointId',
        name: 'LiquidityOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
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

      final totalAmount =
          checkpoints.fold<int>(0, (sum, c) => sum + c.amount);
      final completedCheckpoints =
          checkpoints.where((c) => c.isComplete).toList();

      return {
        'totalCheckpoints': checkpoints.length,
        'completedCheckpoints': completedCheckpoints.length,
        'totalLiquidity': totalAmount,
        'averageLiquidity':
            checkpoints.isEmpty ? 0 : totalAmount ~/ checkpoints.length,
      };
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting liquidity statistics',
        name: 'LiquidityOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
