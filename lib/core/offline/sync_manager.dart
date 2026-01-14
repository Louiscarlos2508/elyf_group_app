import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'connectivity_service.dart';
import 'drift_service.dart';
import 'retry_handler.dart';
import 'sync_operation_processor.dart';
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

/// Complete SyncManager with Drift-based queue, auto sync, and retry.
class SyncManager {
  SyncManager({
    required DriftService driftService,
    required ConnectivityService connectivityService,
    this.config = const SyncConfig(),
    this.syncHandler,
  }) : _driftService = driftService,
       _connectivityService = connectivityService,
       _processor = SyncOperationProcessor(
         driftService: driftService,
         config: config,
         retryHandler: RetryHandler(config: config),
         syncHandler: syncHandler,
       );

  final DriftService _driftService;
  final ConnectivityService _connectivityService;
  final SyncConfig config;
  final SyncOperationHandler? syncHandler;
  final SyncOperationProcessor _processor;

  final _syncStatusController = StreamController<SyncProgress>.broadcast();
  Timer? _autoSyncTimer;
  bool _isSyncing = false;
  bool _isInitialized = false;

  Stream<SyncProgress> get syncProgressStream => _syncStatusController.stream;
  bool get isSyncing => _isSyncing;

  /// Initializes the sync manager and starts auto-sync if enabled.
  Future<void> initialize() async {
    if (_isInitialized) {
      developer.log('SyncManager already initialized', name: 'offline.sync');
      return;
    }

    await _cleanupOldOperations();
    _startAutoSync();
    _isInitialized = true;

    developer.log(
      'SyncManager initialized with auto-sync every ${config.syncIntervalMinutes} minutes',
      name: 'offline.sync',
    );
  }

  /// Syncs all pending operations.
  Future<SyncResult> syncPendingOperations() async {
    if (_isSyncing) {
      developer.log('Sync already in progress', name: 'offline.sync');
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        syncedCount: 0,
      );
    }

    if (!_connectivityService.isOnline) {
      developer.log('Device is offline, skipping sync', name: 'offline.sync');
      return SyncResult(
        success: false,
        message: 'Device is offline',
        syncedCount: 0,
      );
    }

    _isSyncing = true;
    _syncStatusController.add(SyncProgress.started());

    try {
      final pendingCount = await getPendingCount();
      if (pendingCount == 0) {
        _isSyncing = false;
        _syncStatusController.add(SyncProgress.completed(0));
        return SyncResult(
          success: true,
          message: 'No pending operations',
          syncedCount: 0,
        );
      }

      final operations = await _driftService.syncOperations.getPending(
        limit: config.batchSize,
      );

      int syncedCount = 0;
      int failedCount = 0;
      final List<String> errors = [];

      for (int i = 0; i < operations.length; i++) {
        final data = operations[i];
        final operation = _driftService.syncOperations.toEntity(data);

        _syncStatusController.add(
          SyncProgress.inProgress(
            current: i + 1,
            total: operations.length,
            currentOperation:
                '${operation.operationType} ${operation.collectionName}/${operation.documentId}',
          ),
        );

        try {
          await _processOperation(operation);
          syncedCount++;
        } catch (e) {
          failedCount++;
          final errorMsg = e.toString();
          errors.add(errorMsg);
          developer.log(
            'Failed to sync operation ${operation.id}: $errorMsg',
            name: 'offline.sync',
            error: e,
          );
        }
      }

      _isSyncing = false;
      _syncStatusController.add(SyncProgress.completed(syncedCount));

      return SyncResult(
        success: failedCount == 0,
        message: 'Synced $syncedCount operations, $failedCount failed',
        syncedCount: syncedCount,
        failedCount: failedCount,
        errors: errors,
      );
    } catch (e) {
      _isSyncing = false;
      final errorMsg = 'Sync failed: $e';
      _syncStatusController.add(SyncProgress.failed(errorMsg));
      developer.log(errorMsg, name: 'offline.sync', error: e);
      return SyncResult(
        success: false,
        message: errorMsg,
        syncedCount: 0,
        errors: [errorMsg],
      );
    }
  }

  /// Processes a single sync operation.
  Future<void> _processOperation(SyncOperation operation) async {
    await _driftService.syncOperations.markProcessing(operation.id);

    try {
      await _processor.processOperation(operation);
      await _driftService.syncOperations.markSynced(operation.id);
    } catch (e) {
      final errorMsg = e.toString();
      await _driftService.syncOperations.markFailed(operation.id, errorMsg);

      // Reset to pending if retries not exceeded
      if (operation.retryCount < config.maxRetryAttempts) {
        await _driftService.syncOperations.resetToPending(operation.id);
      }

      rethrow;
    }
  }

  /// Queues a create operation.
  Future<void> queueCreate({
    required String collectionName,
    required String localId,
    required Map<String, dynamic> data,
    String? enterpriseId,
  }) async {
    final operation = SyncOperation()
      ..operationType = 'create'
      ..collectionName = collectionName
      ..documentId = localId
      ..enterpriseId = enterpriseId ?? ''
      ..payload = jsonEncode(data)
      ..retryCount = 0
      ..createdAt = DateTime.now()
      ..localUpdatedAt = DateTime.now()
      ..status = 'pending';

    await _driftService.syncOperations.insert(
      _driftService.syncOperations.fromEntity(operation),
    );

    developer.log(
      'Queued create: $collectionName/$localId',
      name: 'offline.sync',
    );

    // Trigger sync if online
    if (_connectivityService.isOnline && !_isSyncing) {
      unawaited(syncPendingOperations());
    }
  }

  /// Queues an update operation.
  Future<void> queueUpdate({
    required String collectionName,
    required String localId,
    required String remoteId,
    required Map<String, dynamic> data,
    String? enterpriseId,
  }) async {
    final operation = SyncOperation()
      ..operationType = 'update'
      ..collectionName = collectionName
      ..documentId = remoteId.isNotEmpty ? remoteId : localId
      ..enterpriseId = enterpriseId ?? ''
      ..payload = jsonEncode(data)
      ..retryCount = 0
      ..createdAt = DateTime.now()
      ..localUpdatedAt = DateTime.now()
      ..status = 'pending';

    await _driftService.syncOperations.insert(
      _driftService.syncOperations.fromEntity(operation),
    );

    developer.log(
      'Queued update: $collectionName/${remoteId.isNotEmpty ? remoteId : localId}',
      name: 'offline.sync',
    );

    // Trigger sync if online
    if (_connectivityService.isOnline && !_isSyncing) {
      unawaited(syncPendingOperations());
    }
  }

  /// Queues a delete operation.
  Future<void> queueDelete({
    required String collectionName,
    required String localId,
    required String remoteId,
    String? enterpriseId,
  }) async {
    final operation = SyncOperation()
      ..operationType = 'delete'
      ..collectionName = collectionName
      ..documentId = remoteId.isNotEmpty ? remoteId : localId
      ..enterpriseId = enterpriseId ?? ''
      ..payload = null
      ..retryCount = 0
      ..createdAt = DateTime.now()
      ..localUpdatedAt = DateTime.now()
      ..status = 'pending';

    await _driftService.syncOperations.insert(
      _driftService.syncOperations.fromEntity(operation),
    );

    developer.log(
      'Queued delete: $collectionName/${remoteId.isNotEmpty ? remoteId : localId}',
      name: 'offline.sync',
    );

    // Trigger sync if online
    if (_connectivityService.isOnline && !_isSyncing) {
      unawaited(syncPendingOperations());
    }
  }

  /// Gets the count of pending operations.
  Future<int> getPendingCount() async {
    return await _driftService.syncOperations.countPending();
  }

  /// Gets pending operations for a specific collection.
  Future<List<SyncOperation>> getPendingForCollection(
    String collectionName,
  ) async {
    final dataList = await _driftService.syncOperations.getPendingForCollection(
      collectionName,
    );
    return dataList.map(_driftService.syncOperations.toEntity).toList();
  }

  /// Clears all pending operations.
  Future<void> clearPendingOperations() async {
    await _driftService.syncOperations.clearAll();
    developer.log('Cleared all pending operations', name: 'offline.sync');
  }

  /// Starts automatic periodic sync.
  void _startAutoSync() {
    if (config.syncIntervalMinutes <= 0) {
      return; // Auto-sync disabled
    }

    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      Duration(minutes: config.syncIntervalMinutes),
      (_) {
        if (!_isSyncing && _connectivityService.isOnline) {
          unawaited(syncPendingOperations());
        }
      },
    );
  }

  /// Cleans up old synced operations.
  Future<void> _cleanupOldOperations() async {
    try {
      await _driftService.syncOperations.deleteOldSynced(
        maxAge: Duration(hours: config.maxOperationAgeHours),
      );
      await _driftService.syncOperations.deleteExceededRetries(
        config.maxRetryAttempts,
      );
    } catch (e) {
      developer.log(
        'Failed to cleanup old operations: $e',
        name: 'offline.sync',
        error: e,
      );
    }
  }

  /// Disposes resources.
  Future<void> dispose() async {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    await _syncStatusController.close();
    _isInitialized = false;
    developer.log('SyncManager disposed', name: 'offline.sync');
  }
}

/// Helper to avoid unawaited warnings.
void unawaited(Future<void> future) {
  // Intentionally not awaiting
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
  }) => SyncProgress._(
    status: SyncStatus.syncing,
    current: current,
    total: total,
    currentOperation: currentOperation,
  );

  factory SyncProgress.completed(int count) =>
      SyncProgress._(status: SyncStatus.synced, total: count, current: count);

  factory SyncProgress.failed(String error) =>
      SyncProgress._(status: SyncStatus.error, error: error);

  double get progress => total > 0 ? current / total : 0;
}

/// Conflict resolution strategy.
enum ConflictResolution { serverWins, clientWins, lastWriteWins, merge }

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
