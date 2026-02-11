import 'dart:async';

import '../errors/error_handler.dart';
import '../logging/app_logger.dart';
import 'drift_service.dart';
import 'security/data_sanitizer.dart';
import 'sync_manager.dart';
import 'sync_status.dart';
import 'retry_handler.dart';

/// Processes sync operations with retry logic and error handling.
class SyncOperationProcessor {
  SyncOperationProcessor({
    required this.driftService,
    required this.config,
    required this.retryHandler,
    this.syncHandler,
  });

  final DriftService driftService;
  final SyncConfig config;
  final RetryHandler retryHandler;
  final SyncOperationHandler? syncHandler;

  /// Processes a sync operation with timeout and retry logic.
  Future<void> processOperation(SyncOperation operation) async {
    if (!DataSanitizer.isValidId(operation.documentId)) {
      throw SyncException('Invalid document ID: ${operation.documentId}');
    }

    if (retryHandler.hasExceededMaxRetries(operation.retryCount)) {
      throw SyncException(
        'Max retry attempts (${config.maxRetryAttempts}) exceeded for '
        '${operation.collectionName}/${operation.documentId}',
      );
    }

    await retryHandler.waitForRetry(operation.retryCount);

    if (syncHandler == null) {
      throw SyncException(
        'No sync handler configured for ${operation.collectionName}',
      );
    }

    AppLogger.debug(
      'Processing ${operation.operationType} for '
      '${operation.collectionName}/${operation.documentId}',
      name: 'offline.sync.processor',
    );

    try {
      await syncHandler!
          .processOperation(operation)
          .timeout(
            Duration(milliseconds: config.operationTimeoutMs),
            onTimeout: () {
              throw SyncException(
                'Operation timeout after ${config.operationTimeoutMs}ms',
              );
            },
          );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Failed to process operation ${operation.id}: ${appException.message}',
        name: 'offline.sync.processor',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Updates retry count for an operation.
  Future<void> updateRetryCount(
    SyncOperation operation,
    int newRetryCount,
  ) async {
    await driftService.syncOperations.updateRetryCount(
      operation.id,
      newRetryCount,
    );
  }

  /// Marks an operation as synced.
  Future<void> markOperationSynced(SyncOperation operation) async {
    await driftService.syncOperations.markSynced(operation.id);
  }

  /// Marks an operation as failed.
  Future<void> markOperationFailed(
    SyncOperation operation,
    String error,
  ) async {
    await driftService.syncOperations.markFailed(
      operation.id,
      error,
      newRetryCount: operation.retryCount + 1,
    );
  }
}
