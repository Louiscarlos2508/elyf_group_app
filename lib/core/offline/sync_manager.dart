import 'dart:async';
import 'dart:developer' as developer;

import 'connectivity_service.dart';
import 'isar_service.dart';
import 'sync_status.dart';

/// Configuration for sync behavior.
class SyncConfig {
  const SyncConfig({
    this.maxRetryAttempts = 5,
    this.baseRetryDelayMs = 1000,
    this.maxRetryDelayMs = 60000,
    this.syncIntervalMinutes = 5,
    this.operationTimeoutMs = 30000,
    this.maxOperationAgeHours = 72,
    this.batchSize = 50,
  });

  final int maxRetryAttempts;
  final int baseRetryDelayMs;
  final int maxRetryDelayMs;
  final int syncIntervalMinutes;
  final int operationTimeoutMs;
  final int maxOperationAgeHours;
  final int batchSize;
}

/// Stub SyncManager - Isar temporarily disabled.
/// TODO: Migrate to ObjectBox.
class SyncManager {
  SyncManager({
    required IsarService isarService,
    required ConnectivityService connectivityService,
    this.config = const SyncConfig(),
    this.syncHandler,
  })  : _connectivityService = connectivityService;

  final ConnectivityService _connectivityService;
  final SyncConfig config;
  final SyncOperationHandler? syncHandler;

  final _syncStatusController = StreamController<SyncProgress>.broadcast();

  Stream<SyncProgress> get syncProgressStream => _syncStatusController.stream;
  bool get isSyncing => false;

  Future<void> initialize() async {
    developer.log(
      'SyncManager initialized (stub - offline sync disabled)',
      name: 'offline.sync',
    );
  }

  Future<SyncResult> syncPendingOperations() async {
    return SyncResult(
      success: true,
      message: 'Sync disabled (stub)',
      syncedCount: 0,
    );
  }

  Future<void> queueCreate({
    required String collectionName,
    required String localId,
    required Map<String, dynamic> data,
    String? enterpriseId,
  }) async {
    developer.log(
      'queueCreate called (stub): $collectionName/$localId',
      name: 'offline.sync',
    );
  }

  Future<void> queueUpdate({
    required String collectionName,
    required String localId,
    required String remoteId,
    required Map<String, dynamic> data,
    String? enterpriseId,
  }) async {
    developer.log(
      'queueUpdate called (stub): $collectionName/$localId',
      name: 'offline.sync',
    );
  }

  Future<void> queueDelete({
    required String collectionName,
    required String localId,
    required String remoteId,
    String? enterpriseId,
  }) async {
    developer.log(
      'queueDelete called (stub): $collectionName/$localId',
      name: 'offline.sync',
    );
  }

  Future<int> getPendingCount() async => 0;

  Future<List<SyncOperation>> getPendingForCollection(String collectionName) async => [];

  Future<void> clearPendingOperations() async {
    developer.log('clearPendingOperations called (stub)', name: 'offline.sync');
  }

  Future<void> dispose() async {
    await _syncStatusController.close();
    developer.log('SyncManager disposed (stub)', name: 'offline.sync');
  }
}

/// Interface for handling sync operations.
abstract class SyncOperationHandler {
  Future<void> processOperation(SyncOperation operation);
}

/// Exception thrown during sync operations.
class SyncException implements Exception {
  const SyncException(this.message);
  final String message;

  @override
  String toString() => 'SyncException: $message';
}

/// Represents the result of a sync operation.
class SyncResult {
  const SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.errors = const [],
  });

  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;
  final List<String> errors;
}

/// Represents sync progress for UI updates.
class SyncProgress {
  const SyncProgress._({
    required this.status,
    this.current = 0,
    this.total = 0,
    this.currentOperation,
    this.error,
  });

  final SyncStatus status;
  final int current;
  final int total;
  final String? currentOperation;
  final String? error;

  factory SyncProgress.started() =>
      const SyncProgress._(status: SyncStatus.syncing);

  factory SyncProgress.inProgress({
    required int current,
    required int total,
    String? currentOperation,
  }) =>
      SyncProgress._(
        status: SyncStatus.syncing,
        current: current,
        total: total,
        currentOperation: currentOperation,
      );

  factory SyncProgress.completed(int count) => SyncProgress._(
        status: SyncStatus.synced,
        total: count,
        current: count,
      );

  factory SyncProgress.failed(String error) => SyncProgress._(
        status: SyncStatus.error,
        error: error,
      );

  double get progress => total > 0 ? current / total : 0;
}

/// Conflict resolution strategy.
enum ConflictResolution {
  serverWins,
  clientWins,
  lastWriteWins,
  merge,
}

/// Resolves conflicts between local and server data.
class ConflictResolver {
  const ConflictResolver({
    this.defaultStrategy = ConflictResolution.lastWriteWins,
  });

  final ConflictResolution defaultStrategy;

  Map<String, dynamic> resolve({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    ConflictResolution? strategy,
  }) {
    final effectiveStrategy = strategy ?? defaultStrategy;

    switch (effectiveStrategy) {
      case ConflictResolution.serverWins:
        return serverData;
      case ConflictResolution.clientWins:
        return localData;
      case ConflictResolution.lastWriteWins:
        final localUpdated = DateTime.tryParse(
          localData['updatedAt'] as String? ?? '',
        );
        final serverUpdated = DateTime.tryParse(
          serverData['updatedAt'] as String? ?? '',
        );
        if (localUpdated == null) return serverData;
        if (serverUpdated == null) return localData;
        return localUpdated.isAfter(serverUpdated) ? localData : serverData;
      case ConflictResolution.merge:
        return {...serverData, ...localData};
    }
  }
}
