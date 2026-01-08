import 'dart:async';
import 'dart:developer' as developer;

import 'drift_service.dart';
import 'security/data_sanitizer.dart';
import 'sync_manager.dart';
import 'sync_status.dart';
import 'retry_handler.dart';

/// Stub SyncOperationProcessor.
/// TODO: Persist sync operations in Drift and process them in background.
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

  Future<void> processOperation(SyncOperation operation) async {
    if (!DataSanitizer.isValidId(operation.documentId)) {
      throw SyncException('Invalid local ID: ${operation.documentId}');
    }

    if (retryHandler.hasExceededMaxRetries(operation.retryCount)) {
      throw SyncException(
        'Max retry attempts (${config.maxRetryAttempts}) exceeded',
      );
    }

    await retryHandler.waitForRetry(operation.retryCount);

    developer.log(
      'Processing ${operation.operationType} for '
      '${operation.collectionName}/${operation.documentId} (stub)',
      name: 'offline.sync.processor',
    );

    if (syncHandler != null) {
      await syncHandler!.processOperation(operation);
    }
  }

  Future<void> updateRetryCount(
    SyncOperation operation,
    int newRetryCount,
  ) async {
    developer.log(
      'updateRetryCount called (stub): ${operation.documentId}',
      name: 'offline.sync.processor',
    );
  }

  Future<void> markOperationSynced(SyncOperation operation) async {
    developer.log(
      'markOperationSynced called (stub): ${operation.documentId}',
      name: 'offline.sync.processor',
    );
  }

  Future<void> markOperationFailed(
    SyncOperation operation,
    String error,
  ) async {
    developer.log(
      'markOperationFailed called (stub): ${operation.documentId}, error: $error',
      name: 'offline.sync.processor',
    );
  }
}
