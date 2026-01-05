import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'connectivity_service.dart';
import 'isar_service.dart';
import 'sync_status.dart';
import 'security/data_sanitizer.dart';
import 'security/secure_storage.dart';

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

  /// Maximum number of retry attempts before giving up.
  final int maxRetryAttempts;

  /// Base delay for exponential backoff (in milliseconds).
  final int baseRetryDelayMs;

  /// Maximum delay between retries (in milliseconds).
  final int maxRetryDelayMs;

  /// Interval between automatic sync attempts (in minutes).
  final int syncIntervalMinutes;

  /// Timeout for individual operations (in milliseconds).
  final int operationTimeoutMs;

  /// Maximum age of pending operations before cleanup (in hours).
  final int maxOperationAgeHours;

  /// Number of operations to process in a single batch.
  final int batchSize;
}

/// Manages offline-first data synchronization.
///
/// Implements a sync strategy with:
/// - Local-first writes (immediate local persistence)
/// - Background sync when online
/// - Conflict resolution using `updated_at` timestamps
/// - Automatic retry with exponential backoff
/// - Data sanitization and validation
class SyncManager {
  SyncManager({
    required IsarService isarService,
    required ConnectivityService connectivityService,
    this.config = const SyncConfig(),
    this.syncHandler,
  })  : _isarService = isarService,
        _connectivityService = connectivityService;

  final IsarService _isarService;
  final ConnectivityService _connectivityService;
  final SyncConfig config;

  /// Custom handler for processing sync operations.
  /// If null, operations will be marked as synced (for testing).
  final SyncOperationHandler? syncHandler;

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  Timer? _syncTimer;
  Timer? _cleanupTimer;
  bool _isSyncing = false;
  bool _isDisposed = false;

  final _syncStatusController = StreamController<SyncProgress>.broadcast();

  /// Stream of sync progress updates.
  Stream<SyncProgress> get syncProgressStream => _syncStatusController.stream;

  /// Whether a sync is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Initializes the sync manager.
  ///
  /// Starts listening to connectivity changes and schedules periodic syncs.
  Future<void> initialize() async {
    if (_isDisposed) {
      throw StateError('SyncManager has been disposed');
    }

    _connectivitySubscription = _connectivityService.statusStream.listen(
      _onConnectivityChanged,
    );

    // Schedule periodic sync
    _syncTimer = Timer.periodic(
      Duration(minutes: config.syncIntervalMinutes),
      (_) => _attemptSync(),
    );

    // Schedule periodic cleanup of old operations
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _cleanupOldOperations(),
    );

    // Attempt initial sync if online
    if (_connectivityService.isOnline) {
      unawaited(_attemptSync());
    }

    // Run initial cleanup
    unawaited(_cleanupOldOperations());

    developer.log(
      'SyncManager initialized with config: '
      'maxRetry=${config.maxRetryAttempts}, '
      'interval=${config.syncIntervalMinutes}min',
      name: 'offline.sync',
    );
  }

  /// Cleans up old pending operations that have exceeded max age.
  Future<void> _cleanupOldOperations() async {
    try {
      final cutoffDate = DateTime.now().subtract(
        Duration(hours: config.maxOperationAgeHours),
      );

      final isar = _isarService.isar;
      final oldOps = await isar.syncOperations
          .filter()
          .createdAtLessThan(cutoffDate)
          .findAll();

      if (oldOps.isNotEmpty) {
        await isar.writeTxn(() async {
          for (final op in oldOps) {
            await isar.syncOperations.delete(op.id);
          }
        });

        developer.log(
          'Cleaned up ${oldOps.length} old sync operations',
          name: 'offline.sync',
        );
      }
    } catch (error) {
      developer.log(
        'Failed to cleanup old operations',
        name: 'offline.sync',
        error: error,
      );
    }
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

  /// Processes a single sync operation with retry logic.
  Future<void> _processSyncOperation(SyncOperation operation) async {
    // Validate operation data
    if (!DataSanitizer.isValidId(operation.localId)) {
      throw SyncException('Invalid local ID: ${operation.localId}');
    }

    if (operation.remoteId != null &&
        !DataSanitizer.isValidId(operation.remoteId)) {
      throw SyncException('Invalid remote ID: ${operation.remoteId}');
    }

    // Check if max retries exceeded
    if (operation.retryCount >= config.maxRetryAttempts) {
      throw SyncException(
        'Max retry attempts (${config.maxRetryAttempts}) exceeded',
      );
    }

    // Calculate delay with exponential backoff
    if (operation.retryCount > 0) {
      final delayMs = _calculateBackoffDelay(operation.retryCount);
      developer.log(
        'Retry ${operation.retryCount}/${config.maxRetryAttempts}, '
        'waiting ${delayMs}ms',
        name: 'offline.sync',
      );
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }

    developer.log(
      'Processing ${operation.operationType} for '
      '${operation.collectionName}/${operation.localId}',
      name: 'offline.sync',
    );

    // Use custom handler if provided, otherwise use default behavior
    if (syncHandler != null) {
      await syncHandler!.processOperation(operation).timeout(
            Duration(milliseconds: config.operationTimeoutMs),
            onTimeout: () =>
                throw TimeoutException('Operation timed out', operation),
          );
    } else {
      // Default: mark as synced (useful for testing)
      developer.log(
        'No sync handler configured, marking as synced',
        name: 'offline.sync',
      );
    }
  }

  /// Calculates exponential backoff delay with jitter.
  int _calculateBackoffDelay(int retryCount) {
    // Exponential backoff: base * 2^retryCount
    final exponentialDelay =
        config.baseRetryDelayMs * math.pow(2, retryCount).toInt();

    // Cap at max delay
    final cappedDelay = math.min(exponentialDelay, config.maxRetryDelayMs);

    // Add jitter (±25%)
    final jitter = (cappedDelay * 0.25 * (math.Random().nextDouble() - 0.5))
        .toInt();

    return cappedDelay + jitter;
  }

  /// Queues a create operation for sync.
  ///
  /// Throws [DataValidationException] if data is invalid.
  Future<void> queueCreate({
    required String collectionName,
    required String localId,
    required Map<String, dynamic> data,
    String? enterpriseId,
  }) async {
    // Validate inputs
    final sanitizedLocalId = DataSanitizer.sanitizeId(localId);
    if (sanitizedLocalId == null) {
      throw DataValidationException('Invalid local ID: $localId');
    }

    final sanitizedEnterpriseId = enterpriseId != null
        ? DataSanitizer.sanitizeId(enterpriseId)
        : null;

    // Sanitize data and remove sensitive fields
    final sanitizedData = SecureDataHandler.removeSensitiveData(
      DataSanitizer.sanitizeMap(data),
    );

    final operation = SyncOperation.create(
      collectionName: DataSanitizer.sanitizeString(collectionName, maxLength: 50),
      localId: sanitizedLocalId,
      data: DataSanitizer.toSafeJson(sanitizedData),
      enterpriseId: sanitizedEnterpriseId,
    );

    await _isarService.isar.writeTxn(() async {
      await _isarService.isar.syncOperations.put(operation);
    });

    developer.log(
      'Queued create for $collectionName/$sanitizedLocalId',
      name: 'offline.sync',
    );

    // Attempt immediate sync if online (fire and forget)
    if (_connectivityService.isOnline) {
      unawaited(_attemptSync());
    }
  }

  /// Queues an update operation for sync.
  ///
  /// Throws [DataValidationException] if data is invalid.
  Future<void> queueUpdate({
    required String collectionName,
    required String localId,
    required String remoteId,
    required Map<String, dynamic> data,
    String? enterpriseId,
  }) async {
    // Validate inputs
    final sanitizedLocalId = DataSanitizer.sanitizeId(localId);
    final sanitizedRemoteId = DataSanitizer.sanitizeId(remoteId);

    if (sanitizedLocalId == null) {
      throw DataValidationException('Invalid local ID: $localId');
    }
    if (sanitizedRemoteId == null) {
      throw DataValidationException('Invalid remote ID: $remoteId');
    }

    final sanitizedEnterpriseId = enterpriseId != null
        ? DataSanitizer.sanitizeId(enterpriseId)
        : null;

    // Sanitize data and remove sensitive fields
    final sanitizedData = SecureDataHandler.removeSensitiveData(
      DataSanitizer.sanitizeMap(data),
    );

    final operation = SyncOperation.update(
      collectionName: DataSanitizer.sanitizeString(collectionName, maxLength: 50),
      localId: sanitizedLocalId,
      remoteId: sanitizedRemoteId,
      data: DataSanitizer.toSafeJson(sanitizedData),
      enterpriseId: sanitizedEnterpriseId,
    );

    await _isarService.isar.writeTxn(() async {
      await _isarService.isar.syncOperations.put(operation);
    });

    developer.log(
      'Queued update for $collectionName/$sanitizedLocalId',
      name: 'offline.sync',
    );

    if (_connectivityService.isOnline) {
      unawaited(_attemptSync());
    }
  }

  /// Queues a delete operation for sync.
  ///
  /// Throws [DataValidationException] if IDs are invalid.
  Future<void> queueDelete({
    required String collectionName,
    required String localId,
    required String remoteId,
    String? enterpriseId,
  }) async {
    // Validate inputs
    final sanitizedLocalId = DataSanitizer.sanitizeId(localId);
    final sanitizedRemoteId = DataSanitizer.sanitizeId(remoteId);

    if (sanitizedLocalId == null) {
      throw DataValidationException('Invalid local ID: $localId');
    }
    if (sanitizedRemoteId == null) {
      throw DataValidationException('Invalid remote ID: $remoteId');
    }

    final sanitizedEnterpriseId = enterpriseId != null
        ? DataSanitizer.sanitizeId(enterpriseId)
        : null;

    final operation = SyncOperation.delete(
      collectionName: DataSanitizer.sanitizeString(collectionName, maxLength: 50),
      localId: sanitizedLocalId,
      remoteId: sanitizedRemoteId,
      enterpriseId: sanitizedEnterpriseId,
    );

    await _isarService.isar.writeTxn(() async {
      await _isarService.isar.syncOperations.put(operation);
    });

    developer.log(
      'Queued delete for $collectionName/$sanitizedLocalId',
      name: 'offline.sync',
    );

    if (_connectivityService.isOnline) {
      unawaited(_attemptSync());
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
    if (_isDisposed) return;
    _isDisposed = true;

    _syncTimer?.cancel();
    _cleanupTimer?.cancel();
    await _connectivitySubscription?.cancel();
    await _syncStatusController.close();

    developer.log(
      'SyncManager disposed',
      name: 'offline.sync',
    );
  }
}

/// Interface for handling sync operations.
///
/// Implement this to integrate with Firebase or your backend.
abstract class SyncOperationHandler {
  /// Processes a sync operation.
  ///
  /// Should throw on failure for retry logic to work.
  Future<void> processOperation(SyncOperation operation);
}

/// Exception thrown during sync operations.
class SyncException implements Exception {
  const SyncException(this.message);
  final String message;

  @override
  String toString() => 'SyncException: $message';
}

/// Exception thrown when an operation times out.
class TimeoutException implements Exception {
  const TimeoutException(this.message, this.operation);
  final String message;
  final SyncOperation operation;

  @override
  String toString() => 'TimeoutException: $message';
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
