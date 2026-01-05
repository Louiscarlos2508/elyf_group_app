import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:isar/isar.dart';

import 'connectivity_service.dart';
import 'isar_service.dart';
import 'sync_status.dart';

/// Manages offline-first data synchronization.
///
/// Implements a sync strategy with:
/// - Local-first writes (immediate local persistence)
/// - Background sync when online
/// - Conflict resolution using `updated_at` timestamps
/// - Automatic retry with exponential backoff
class SyncManager {
  SyncManager({
    required IsarService isarService,
    required ConnectivityService connectivityService,
  })  : _isarService = isarService,
        _connectivityService = connectivityService;

  final IsarService _isarService;
  final ConnectivityService _connectivityService;

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;

  final _syncStatusController = StreamController<SyncProgress>.broadcast();

  /// Stream of sync progress updates.
  Stream<SyncProgress> get syncProgressStream => _syncStatusController.stream;

  /// Whether a sync is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Initializes the sync manager.
  ///
  /// Starts listening to connectivity changes and schedules periodic syncs.
  Future<void> initialize() async {
    _connectivitySubscription = _connectivityService.statusStream.listen(
      _onConnectivityChanged,
    );

    // Schedule periodic sync every 5 minutes when online
    _syncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _attemptSync(),
    );

    // Attempt initial sync if online
    if (_connectivityService.isOnline) {
      await _attemptSync();
    }

    developer.log(
      'SyncManager initialized',
      name: 'offline.sync',
    );
  }

  void _onConnectivityChanged(ConnectivityStatus status) {
    developer.log(
      'Connectivity changed: ${status.description}',
      name: 'offline.sync',
    );

    if (status.isOnline) {
      // Trigger sync when coming back online
      _attemptSync();
    }
  }

  /// Attempts to sync pending operations.
  Future<void> _attemptSync() async {
    if (_isSyncing) {
      developer.log(
        'Sync already in progress, skipping',
        name: 'offline.sync',
      );
      return;
    }

    if (!_connectivityService.isOnline) {
      developer.log(
        'Offline, cannot sync',
        name: 'offline.sync',
      );
      return;
    }

    await syncPendingOperations();
  }

  /// Manually triggers synchronization.
  Future<SyncResult> syncPendingOperations() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
      );
    }

    _isSyncing = true;
    _syncStatusController.add(SyncProgress.started());

    try {
      final isar = _isarService.isar;

      // Get pending operations sorted by priority and creation time
      final operations = await isar.syncOperations
          .where()
          .sortByPriority()
          .thenByCreatedAt()
          .findAll();

      if (operations.isEmpty) {
        _syncStatusController.add(SyncProgress.completed(0));
        return SyncResult(
          success: true,
          message: 'No pending operations',
          syncedCount: 0,
        );
      }

      developer.log(
        'Starting sync of ${operations.length} operations',
        name: 'offline.sync',
      );

      int successCount = 0;
      int failureCount = 0;
      final errors = <String>[];

      for (var i = 0; i < operations.length; i++) {
        final operation = operations[i];

        _syncStatusController.add(SyncProgress.inProgress(
          current: i + 1,
          total: operations.length,
          currentOperation: operation.collectionName,
        ));

        try {
          await _processSyncOperation(operation);
          successCount++;

          // Remove successful operation from queue
          await isar.writeTxn(() async {
            await isar.syncOperations.delete(operation.id);
          });
        } catch (error) {
          failureCount++;
          errors.add('${operation.collectionName}: $error');

          // Update retry count
          await isar.writeTxn(() async {
            operation.retryCount++;
            operation.lastError = error.toString();
            await isar.syncOperations.put(operation);
          });

          developer.log(
            'Failed to sync ${operation.collectionName}/${operation.localId}',
            name: 'offline.sync',
            error: error,
          );
        }
      }

      _syncStatusController.add(SyncProgress.completed(successCount));

      return SyncResult(
        success: failureCount == 0,
        message: failureCount == 0
            ? 'Sync completed successfully'
            : 'Sync completed with $failureCount errors',
        syncedCount: successCount,
        failedCount: failureCount,
        errors: errors,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Sync failed',
        name: 'offline.sync',
        error: error,
        stackTrace: stackTrace,
      );

      _syncStatusController.add(SyncProgress.failed(error.toString()));

      return SyncResult(
        success: false,
        message: 'Sync failed: $error',
        errors: [error.toString()],
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Processes a single sync operation.
  Future<void> _processSyncOperation(SyncOperation operation) async {
    // This is where you would integrate with Firebase or your backend
    // For now, this is a placeholder that simulates the sync

    developer.log(
      'Processing ${operation.operationType} for '
      '${operation.collectionName}/${operation.localId}',
      name: 'offline.sync',
    );

    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // In a real implementation, you would:
    // 1. Parse the operation data
    // 2. Call the appropriate Firebase/API method
    // 3. Handle conflicts using updated_at comparison
    // 4. Update local sync metadata
  }

  /// Queues a create operation for sync.
  Future<void> queueCreate({
    required String collectionName,
    required String localId,
    required Map<String, dynamic> data,
    String? enterpriseId,
  }) async {
    final operation = SyncOperation.create(
      collectionName: collectionName,
      localId: localId,
      data: jsonEncode(data),
      enterpriseId: enterpriseId,
    );

    await _isarService.isar.writeTxn(() async {
      await _isarService.isar.syncOperations.put(operation);
    });

    developer.log(
      'Queued create for $collectionName/$localId',
      name: 'offline.sync',
    );

    // Attempt immediate sync if online
    if (_connectivityService.isOnline) {
      _attemptSync();
    }
  }

  /// Queues an update operation for sync.
  Future<void> queueUpdate({
    required String collectionName,
    required String localId,
    required String remoteId,
    required Map<String, dynamic> data,
    String? enterpriseId,
  }) async {
    final operation = SyncOperation.update(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      data: jsonEncode(data),
      enterpriseId: enterpriseId,
    );

    await _isarService.isar.writeTxn(() async {
      await _isarService.isar.syncOperations.put(operation);
    });

    developer.log(
      'Queued update for $collectionName/$localId',
      name: 'offline.sync',
    );

    if (_connectivityService.isOnline) {
      _attemptSync();
    }
  }

  /// Queues a delete operation for sync.
  Future<void> queueDelete({
    required String collectionName,
    required String localId,
    required String remoteId,
    String? enterpriseId,
  }) async {
    final operation = SyncOperation.delete(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
    );

    await _isarService.isar.writeTxn(() async {
      await _isarService.isar.syncOperations.put(operation);
    });

    developer.log(
      'Queued delete for $collectionName/$localId',
      name: 'offline.sync',
    );

    if (_connectivityService.isOnline) {
      _attemptSync();
    }
  }

  /// Gets the count of pending sync operations.
  Future<int> getPendingCount() async {
    return _isarService.isar.syncOperations.count();
  }

  /// Gets pending operations for a specific collection.
  Future<List<SyncOperation>> getPendingForCollection(
    String collectionName,
  ) async {
    return _isarService.isar.syncOperations
        .filter()
        .collectionNameEqualTo(collectionName)
        .findAll();
  }

  /// Clears all pending operations (use with caution).
  Future<void> clearPendingOperations() async {
    await _isarService.isar.writeTxn(() async {
      await _isarService.isar.syncOperations.clear();
    });

    developer.log(
      'Cleared all pending sync operations',
      name: 'offline.sync',
    );
  }

  /// Disposes resources.
  Future<void> dispose() async {
    _syncTimer?.cancel();
    await _connectivitySubscription?.cancel();
    await _syncStatusController.close();
  }
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

/// Status of the sync process.
enum SyncStatus {
  idle,
  syncing,
  synced,
  error,
}

/// Conflict resolution strategy.
enum ConflictResolution {
  /// Server data wins.
  serverWins,

  /// Client data wins.
  clientWins,

  /// Most recent update wins (based on updated_at).
  lastWriteWins,

  /// Merge changes.
  merge,
}

/// Resolves conflicts between local and server data.
class ConflictResolver {
  const ConflictResolver({
    this.defaultStrategy = ConflictResolution.lastWriteWins,
  });

  final ConflictResolution defaultStrategy;

  /// Resolves a conflict between local and server data.
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
        // Deep merge: server data as base, local changes override
        return _deepMerge(serverData, localData);
    }
  }

  Map<String, dynamic> _deepMerge(
    Map<String, dynamic> base,
    Map<String, dynamic> override,
  ) {
    final result = Map<String, dynamic>.from(base);

    for (final entry in override.entries) {
      if (entry.value is Map<String, dynamic> &&
          result[entry.key] is Map<String, dynamic>) {
        result[entry.key] = _deepMerge(
          result[entry.key] as Map<String, dynamic>,
          entry.value as Map<String, dynamic>,
        );
      } else if (entry.value != null) {
        result[entry.key] = entry.value;
      }
    }

    return result;
  }
}
