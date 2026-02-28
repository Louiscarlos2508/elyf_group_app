import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../errors/error_handler.dart';
import '../logging/app_logger.dart';

import '../auth/services/auth_service.dart';
import 'connectivity_service.dart';
import 'drift_service.dart';
import 'rate_limiter.dart';
import 'retry_handler.dart';
import 'security/data_sanitizer.dart';
import 'sync_metrics.dart';
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
    this.useBatchOperations = true, // Enable batch operations by default
    this.batchThreshold = 10, // Use batch if >= 10 operations
  });

  final int maxRetryAttempts;
  final int baseRetryDelayMs;
  final int maxRetryDelayMs;
  final int syncIntervalMinutes;
  final int operationTimeoutMs;
  final int maxOperationAgeHours;
  final int batchSize;
  final bool useBatchOperations;
  final int batchThreshold; // Minimum operations to use batch
}

/// Complete SyncManager with Drift-based queue, auto sync, and retry.
class SyncManager {
  SyncManager({
    required DriftService driftService,
    required ConnectivityService connectivityService,
    this.config = const SyncConfig(),
    this.syncHandler,
    AuthService? authService,
  }) : _driftService = driftService,
       _connectivityService = connectivityService,
       _authService = authService,
       _processor = SyncOperationProcessor(
         driftService: driftService,
         config: config,
         retryHandler: RetryHandler(config: config),
         syncHandler: syncHandler,
       ),
       _rateLimiter = RateLimiter(
         maxOperationsPerSecond: 10,
         maxConcurrentOperations: 5,
       );

  final DriftService _driftService;
  final ConnectivityService _connectivityService;
  final AuthService? _authService;
  final SyncConfig config;
  final SyncOperationHandler? syncHandler;
  final SyncOperationProcessor _processor;
  final RateLimiter _rateLimiter;
  final SyncMetrics _metrics = SyncMetrics();

  final _syncStatusController = StreamController<SyncProgress>.broadcast();
  Timer? _autoSyncTimer;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  bool _isSyncing = false;
  bool _isInitialized = false;

  Stream<SyncProgress> get syncProgressStream => _syncStatusController.stream;
  bool get isSyncing => _isSyncing;

  /// Initializes the sync manager and starts auto-sync if enabled.
  Future<void> initialize() async {
    // On Web, the sync manager is a no-op as we use direct Firestore
    if (kIsWeb) {
      AppLogger.info('SyncManager: Skipping initialization on Web platform', name: 'offline.sync');
      _isInitialized = true;
      return;
    }

    if (_isInitialized) {
      AppLogger.debug('SyncManager already initialized', name: 'offline.sync');
      return;
    }

    await _cleanupOldOperations();
    _rateLimiter.initialize();
    _startAutoSync();
    _startConnectivityListener();
    _isInitialized = true;

    AppLogger.info(
      'SyncManager initialized with auto-sync every ${config.syncIntervalMinutes} minutes',
      name: 'offline.sync',
    );
  }

  /// Syncs all pending operations.
  Future<SyncResult> syncPendingOperations() async {
    if (kIsWeb) return SyncResult(success: true, message: 'No-op on Web', syncedCount: 0);
    
    if (_isSyncing) {
      AppLogger.debug('Sync already in progress', name: 'offline.sync');
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        syncedCount: 0,
      );
    }

    // Vérifier si l'utilisateur est toujours authentifié
    // Utiliser AuthService si disponible, sinon FirebaseAuth directement
    bool isAuthenticated = true;
    final authService = _authService;
    if (authService != null) {
      isAuthenticated = authService.isAuthenticated;
    } else {
      // Fallback: vérifier directement via FirebaseAuth
      try {
        isAuthenticated = FirebaseAuth.instance.currentUser != null;
      } catch (e, stackTrace) {
        final appException = ErrorHandler.instance.handleError(e, stackTrace);
        AppLogger.warning(
          'Error checking authentication status: ${appException.message}. Continuing sync.',
          name: 'offline.sync',
          error: e,
          stackTrace: stackTrace,
        );
        // En cas d'erreur, continuer la sync (meilleur que de bloquer)
      }
    }

    if (!isAuthenticated) {
      AppLogger.info(
        'User logged out during sync, stopping sync operations',
        name: 'offline.sync',
      );
      return SyncResult(
        success: false,
        message: 'User logged out',
        syncedCount: 0,
      );
    }

    if (!_connectivityService.isOnline) {
      AppLogger.debug('Device is offline, skipping sync', name: 'offline.sync');
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

      final allPending = await _driftService.syncOperations.getPending(
        limit: config.batchSize,
      );

      // Filter only "ready" operations (fresh ones or those past their backoff)
      final operations = allPending.where((data) {
        final operation = _driftService.syncOperations.toEntity(data);
        if (operation.retryCount == 0) return true;
        
        // Calculate expected delay based on retry handler logic
        final retryHandler = _processor.retryHandler;
        final delayMs = retryHandler.calculateBackoffDelay(operation.retryCount);
        final readyAt = operation.localUpdatedAt.add(Duration(milliseconds: delayMs));
        
        return DateTime.now().isAfter(readyAt);
      }).toList();

      if (operations.isEmpty && allPending.isNotEmpty) {
        AppLogger.debug(
          '${allPending.length} operations pending but none ready for retry yet',
          name: 'offline.sync',
        );
        _isSyncing = false;
        _syncStatusController.add(SyncProgress.completed(0));
        return SyncResult(
          success: true,
          message: 'Retrying later...',
          syncedCount: 0,
        );
      }

      int syncedCount = 0;
      int failedCount = 0;
      int consecutiveFailures = 0;
      const int maxConsecutiveFailures = 3;
      final List<String> errors = [];

      for (int i = 0; i < operations.length; i++) {
        final data = operations[i];
        final operation = _driftService.syncOperations.toEntity(data);

        // Circuit breaker: stop if too many consecutive failures
        if (consecutiveFailures >= maxConsecutiveFailures) {
          AppLogger.warning(
            'Too many consecutive failures ($consecutiveFailures), stopping sync loop',
            name: 'offline.sync',
          );
          errors.add('Sync stopped: Too many consecutive failures');
          break;
        }

        _syncStatusController.add(
          SyncProgress.inProgress(
            current: i + 1,
            total: operations.length,
            currentOperation:
                '${operation.operationType} ${operation.collectionName}/${operation.documentId}',
          ),
        );

        // Vérifier à nouveau l'authentification avant chaque opération
        bool stillAuthenticated = true;
        if (authService != null) {
          stillAuthenticated = authService.isAuthenticated;
        } else {
          try {
            stillAuthenticated = FirebaseAuth.instance.currentUser != null;
          } catch (e) {
            // En cas d'erreur, continuer (meilleur que de bloquer)
            stillAuthenticated = true;
          }
        }

        if (!stillAuthenticated) {
          AppLogger.info(
            'User logged out during sync, stopping remaining operations',
            name: 'offline.sync',
          );
          // Marquer les opérations restantes comme non traitées
          break;
        }

        try {
          final startTime = DateTime.now();
          final payloadSize = operation.payload?.length ?? 0;

          // Utiliser le rate limiter pour éviter trop de requêtes simultanées
          await _rateLimiter.execute(() => _processOperation(operation));

          final duration = DateTime.now().difference(startTime);
          syncedCount++;
          consecutiveFailures = 0; // Reset consecutive failures on success

          // Enregistrer le succès dans les métriques
          _metrics.recordSuccess(
            operationType: operation.operationType,
            collectionName: operation.collectionName,
            priority: operation.priority.name,
            payloadSize: payloadSize,
            duration: duration,
          );
        } catch (e) {
          final startTime = DateTime.now();
          final payloadSize = operation.payload?.length ?? 0;
          final duration = DateTime.now().difference(startTime);

          failedCount++;
          consecutiveFailures++;
          final errorMsg = e.toString();
          errors.add(errorMsg);

          // Extraire le type d'erreur
          final errorType = _extractErrorType(e);

          // Enregistrer l'échec dans les métriques
          _metrics.recordFailure(
            operationType: operation.operationType,
            collectionName: operation.collectionName,
            priority: operation.priority.name,
            errorType: errorType,
            payloadSize: payloadSize,
            duration: duration,
            retryCount: operation.retryCount,
          );

          AppLogger.error(
            'Failed to sync operation ${operation.id} (consecutive: $consecutiveFailures): $errorMsg',
            name: 'offline.sync',
            error: e,
          );
        }
      }

      _isSyncing = false;
      _syncStatusController.add(SyncProgress.completed(syncedCount));

      final result = SyncResult(
        success: failedCount == 0,
        message: 'Synced $syncedCount operations, $failedCount failed',
        syncedCount: syncedCount,
        failedCount: failedCount,
        errors: errors,
      );

      // Log des métriques périodiquement (toutes les 100 opérations)
      if (_metrics.totalOperations % 100 == 0) {
        _metrics.logSummary();
      }

      AppLogger.info(
        'Sync completed: ${result.syncedCount} synced, ${result.failedCount} failed',
        name: 'offline.sync',
      );

      return result;
    } catch (e) {
      _isSyncing = false;
      final errorMsg = 'Sync failed: $e';
      _syncStatusController.add(SyncProgress.failed(errorMsg));
      AppLogger.error(errorMsg, name: 'offline.sync', error: e);
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
      await _driftService.syncOperations.deleteById(operation.id);
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
    SyncPriority? priority,
  }) async {
    if (kIsWeb) return;

    // Valider la taille du payload avant de le queue
    final jsonPayload = jsonEncode(data);
    try {
      DataSanitizer.validateJsonSize(jsonPayload);
    } on DataSizeException catch (e) {
      throw SyncException(
        'Données trop volumineuses pour $collectionName/$localId: ${e.message}',
      );
    }

    final operation = SyncOperation()
      ..operationType = 'create'
      ..collectionName = collectionName
      ..documentId = localId
      ..enterpriseId = enterpriseId ?? ''
      ..payload = jsonPayload
      ..retryCount = 0
      ..createdAt = DateTime.now()
      ..localUpdatedAt = DateTime.now()
      ..status = 'pending'
      ..priority = priority ?? SyncOperation.determinePriority(collectionName, 'create');

    await _driftService.syncOperations.insert(
      _driftService.syncOperations.fromEntity(operation),
    );

    AppLogger.debug(
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
    if (kIsWeb) return;

    // Valider la taille du payload avant de le queue
    final jsonPayload = jsonEncode(data);
    try {
      DataSanitizer.validateJsonSize(jsonPayload);
    } on DataSizeException catch (e) {
      throw SyncException(
        'Données trop volumineuses pour $collectionName/${remoteId.isNotEmpty ? remoteId : localId}: ${e.message}',
      );
    }

    final operation = SyncOperation()
      ..operationType = 'update'
      ..collectionName = collectionName
      ..documentId = remoteId.isNotEmpty ? remoteId : localId
      ..enterpriseId = enterpriseId ?? ''
      ..payload = jsonPayload
      ..retryCount = 0
      ..createdAt = DateTime.now()
      ..localUpdatedAt = DateTime.now()
      ..status = 'pending'
      ..priority = SyncOperation.determinePriority(collectionName, 'update');

    await _driftService.syncOperations.insert(
      _driftService.syncOperations.fromEntity(operation),
    );

    AppLogger.debug(
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
    if (kIsWeb) return;

    final operation = SyncOperation()
      ..operationType = 'delete'
      ..collectionName = collectionName
      ..documentId = remoteId.isNotEmpty ? remoteId : localId
      ..enterpriseId = enterpriseId ?? ''
      ..payload = null
      ..retryCount = 0
      ..createdAt = DateTime.now()
      ..localUpdatedAt = DateTime.now()
      ..status = 'pending'
      ..priority = SyncOperation.determinePriority(collectionName, 'delete');

    await _driftService.syncOperations.insert(
      _driftService.syncOperations.fromEntity(operation),
    );

    AppLogger.debug(
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
    AppLogger.debug('Cleared all pending operations', name: 'offline.sync');
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

  /// Starts listening to connectivity changes to trigger sync when network comes back.
  void _startConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivityService.statusStream.listen(
      (status) {
        // Déclencher la synchronisation quand le réseau revient
        if (status.isOnline && !_isSyncing) {
          AppLogger.info(
            'Network came back, triggering sync',
            name: 'offline.sync',
          );
          unawaited(syncPendingOperations());
        }
      },
      onError: (error) {
        AppLogger.error(
          'Error in connectivity listener: $error',
          name: 'offline.sync',
          error: error,
        );
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
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Failed to cleanup old operations: ${appException.message}',
        name: 'offline.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Extrait le type d'erreur depuis une exception.
  String _extractErrorType(dynamic error) {
    if (error is SyncException) {
      final message = error.toString();
      if (message.contains('permission')) return 'permission-denied';
      if (message.contains('timeout')) return 'timeout';
      if (message.contains('quota')) return 'quota-exceeded';
      if (message.contains('network')) return 'network-error';
      return 'sync-error';
    }
    return error.runtimeType.toString();
  }

  /// Accès aux métriques de synchronisation.
  SyncMetrics get metrics => _metrics;

  /// Disposes resources.
  Future<void> dispose() async {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    await _syncStatusController.close();
    
    // Log des métriques finales avant de disposer
    _metrics.logSummary();
    
    _isInitialized = false;
    AppLogger.info('SyncManager disposed', name: 'offline.sync');
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
