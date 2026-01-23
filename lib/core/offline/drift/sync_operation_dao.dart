import 'package:drift/drift.dart';

import '../../logging/app_logger.dart';
import 'app_database.dart';
import '../sync_status.dart' as entities;

/// DAO for managing sync operations queue.
///
/// **Robustness vs UNIQUE(operation_type, collection_name, document_id,
/// enterprise_id, status):**
/// - **Success:** [deleteById] after sync (no 'synced' rows → no constraint).
/// - **Processing:** [markProcessing] deletes stale 'processing' before update.
/// - **Failure:** [markFailed] deletes stale 'failed' before update.
/// - **Retry:** [resetToPending] drops self if another 'pending' exists.
class SyncOperationDao {
  SyncOperationDao(this._db);

  final AppDatabase _db;

  /// Inserts a new sync operation into the queue.
  /// If an operation with the same unique constraint already exists, updates it instead.
  /// This prevents duplicate operations and ensures the queue always has the latest data.
  Future<int> insert(SyncOperationsCompanion operation) async {
    // First, check if an operation with the same unique constraint already exists
    final operationType = operation.operationType.value;
    final collectionName = operation.collectionName.value;
    final documentId = operation.documentId.value;
    final enterpriseId = operation.enterpriseId.value;
    final status = operation.status.value;

    final existing = await findExisting(
      operationType: operationType,
      collectionName: collectionName,
      documentId: documentId,
      enterpriseId: enterpriseId,
      status: status,
    );

    if (existing != null) {
      // Update existing operation with new data (payload, priority, etc.)
      // This ensures we always have the latest data to sync
      AppLogger.info(
        'Updating existing sync operation: $operationType $collectionName/$documentId (status: $status)',
        name: 'SyncOperationDao.insert',
      );
      await (_db.update(_db.syncOperations)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        SyncOperationsCompanion(
          payload: operation.payload,
          priority: operation.priority,
          localUpdatedAt: Value(DateTime.now()),
          retryCount: const Value(0), // Reset retry count for updated operation
          lastError: const Value(null), // Clear any previous errors
        ),
      );
      return existing.id;
    }

    // No existing operation found, insert new one
    try {
      return await _db.into(_db.syncOperations).insert(operation);
    } catch (e) {
      // Handle UNIQUE constraint violation as fallback (race condition)
      // This can happen if another thread/isolate inserted the same operation
      if (e.toString().contains('UNIQUE constraint failed')) {
        // Try to find existing operation again (might have been inserted by another thread)
        final existingAfterError = await findExisting(
          operationType: operationType,
          collectionName: collectionName,
          documentId: documentId,
          enterpriseId: enterpriseId,
          status: status,
        );

        if (existingAfterError != null) {
          // Update existing operation (race condition handled)
          AppLogger.info(
            'Race condition detected: updating existing sync operation after UNIQUE constraint error: $operationType $collectionName/$documentId',
            name: 'SyncOperationDao.insert',
          );
          await (_db.update(_db.syncOperations)
                ..where((t) => t.id.equals(existingAfterError.id)))
              .write(
            SyncOperationsCompanion(
              payload: operation.payload,
              priority: operation.priority,
              localUpdatedAt: Value(DateTime.now()),
              retryCount: const Value(0),
              lastError: const Value(null),
            ),
          );
          return existingAfterError.id;
        }
      }
      rethrow;
    }
  }

  /// Finds an existing operation matching the unique constraint.
  Future<SyncOperation?> findExisting({
    required String operationType,
    required String collectionName,
    required String documentId,
    required String enterpriseId,
    required String status,
  }) async {
    return await (_db.select(_db.syncOperations)
          ..where(
            (t) =>
                t.operationType.equals(operationType) &
                t.collectionName.equals(collectionName) &
                t.documentId.equals(documentId) &
                t.enterpriseId.equals(enterpriseId) &
                t.status.equals(status),
          ))
        .getSingleOrNull();
  }

  /// Gets a pending operation by ID.
  Future<SyncOperation?> getById(int id) async {
    return await (_db.select(
      _db.syncOperations,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Gets all pending operations, ordered by priority (critical first) then creation time.
  Future<List<SyncOperation>> getPending({
    int? limit,
    String? collectionName,
    String? enterpriseId,
  }) async {
    var query = _db.select(_db.syncOperations)
      ..where((t) {
        var condition = t.status.equals('pending');
        if (collectionName != null) {
          condition = condition & t.collectionName.equals(collectionName);
        }
        if (enterpriseId != null) {
          condition = condition & t.enterpriseId.equals(enterpriseId);
        }
        return condition;
      })
      // Order by priority (ascending: 0=critical first), then by creation time (oldest first)
      ..orderBy([
        (t) => OrderingTerm.asc(t.priority),
        (t) => OrderingTerm.asc(t.createdAt),
      ]);

    if (limit != null) {
      query = query..limit(limit);
    }

    return await query.get();
  }

  /// Gets pending operations for a specific collection.
  Future<List<SyncOperation>> getPendingForCollection(
    String collectionName, {
    String? enterpriseId,
    int? limit,
  }) async {
    return await getPending(
      limit: limit,
      collectionName: collectionName,
      enterpriseId: enterpriseId,
    );
  }

  /// Counts pending operations.
  Future<int> countPending({
    String? collectionName,
    String? enterpriseId,
  }) async {
    // Use getPending and count in memory as a workaround for selectOnly where clause issues
    final pending = await getPending(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
    );
    return pending.length;
  }

  /// Marks an operation as processing.
  ///
  /// Before updating, any other operation for the same (operationType,
  /// collectionName, documentId, enterpriseId) with status 'processing' is
  /// marked 'failed' to avoid UNIQUE constraint violation (only one row per
  /// document+status).
  Future<void> markProcessing(int id) async {
    final op = await getById(id);
    if (op == null) return;

    await markStaleProcessingAsFailed(
      operationType: op.operationType,
      collectionName: op.collectionName,
      documentId: op.documentId,
      enterpriseId: op.enterpriseId,
      excludeId: id,
    );

    await (_db.update(_db.syncOperations)..where((t) => t.id.equals(id))).write(
      SyncOperationsCompanion(
        status: const Value('processing'),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Removes any 'processing' operations for the same document.
  /// Use before markProcessing to avoid UNIQUE(..., status) violation.
  /// We delete (not mark failed) to avoid UNIQUE conflict with existing 'failed' rows.
  Future<void> markStaleProcessingAsFailed({
    required String operationType,
    required String collectionName,
    required String documentId,
    required String enterpriseId,
    required int excludeId,
  }) async {
    final stale = await (_db.select(_db.syncOperations)
          ..where(
            (t) =>
                t.operationType.equals(operationType) &
                t.collectionName.equals(collectionName) &
                t.documentId.equals(documentId) &
                t.enterpriseId.equals(enterpriseId) &
                t.status.equals('processing') &
                t.id.isNotValue(excludeId),
          ))
        .get();

    for (final row in stale) {
      await (_db.delete(_db.syncOperations)..where((t) => t.id.equals(row.id)))
          .go();
      AppLogger.info(
        'Deleted stale processing op ${row.id}: '
        '$operationType $collectionName/$documentId',
        name: 'SyncOperationDao',
      );
    }
  }

  /// Deletes an operation by id.
  ///
  /// Preferred on sync success: removing the op avoids UNIQUE violations
  /// (no 'synced' rows). Use this instead of [markSynced] in the main sync path.
  Future<void> deleteById(int id) async {
    await (_db.delete(_db.syncOperations)..where((t) => t.id.equals(id))).go();
  }

  /// Marks an operation as synced.
  ///
  /// Deletes any other 'synced' op for the same document first to avoid
  /// UNIQUE(operation_type, collection_name, document_id, enterprise_id, status).
  /// Prefer [deleteById] on success to avoid storing 'synced' rows.
  Future<void> markSynced(int id) async {
    final op = await getById(id);
    if (op == null) return;

    await _deleteStaleOpsWithStatus(
      operationType: op.operationType,
      collectionName: op.collectionName,
      documentId: op.documentId,
      enterpriseId: op.enterpriseId,
      status: 'synced',
      excludeId: id,
    );

    await (_db.update(_db.syncOperations)..where((t) => t.id.equals(id))).write(
      SyncOperationsCompanion(
        status: const Value('synced'),
        processedAt: Value(DateTime.now()),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Marks an operation as failed and increments retry count.
  ///
  /// Deletes any other 'failed' op for the same document first to avoid
  /// UNIQUE(operation_type, collection_name, document_id, enterprise_id, status).
  Future<void> markFailed(int id, String error, {int? newRetryCount}) async {
    final current = await getById(id);
    if (current == null) return;

    await _deleteStaleOpsWithStatus(
      operationType: current.operationType,
      collectionName: current.collectionName,
      documentId: current.documentId,
      enterpriseId: current.enterpriseId,
      status: 'failed',
      excludeId: id,
    );

    await (_db.update(_db.syncOperations)..where((t) => t.id.equals(id))).write(
      SyncOperationsCompanion(
        status: const Value('failed'),
        lastError: Value(error),
        retryCount: Value(newRetryCount ?? (current.retryCount + 1)),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Deletes other operations with the same (op_type, collection, document_id,
  /// enterprise_id, status) to avoid UNIQUE constraint when updating our row.
  Future<void> _deleteStaleOpsWithStatus({
    required String operationType,
    required String collectionName,
    required String documentId,
    required String enterpriseId,
    required String status,
    required int excludeId,
  }) async {
    final stale = await (_db.select(_db.syncOperations)
          ..where(
            (t) =>
                t.operationType.equals(operationType) &
                t.collectionName.equals(collectionName) &
                t.documentId.equals(documentId) &
                t.enterpriseId.equals(enterpriseId) &
                t.status.equals(status) &
                t.id.isNotValue(excludeId),
          ))
        .get();

    for (final row in stale) {
      await (_db.delete(_db.syncOperations)..where((t) => t.id.equals(row.id)))
          .go();
      AppLogger.info(
        'Deleted stale $status op ${row.id}: '
        '$operationType $collectionName/$documentId',
        name: 'SyncOperationDao',
      );
    }
  }

  /// Resets a failed operation back to pending for retry.
  ///
  /// If another 'pending' op exists for the same document, deletes this op
  /// instead to avoid UNIQUE(..., status); the existing pending will be synced.
  Future<void> resetToPending(int id) async {
    final op = await getById(id);
    if (op == null) return;

    final otherPending = await (_db.select(_db.syncOperations)
          ..where(
            (t) =>
                t.operationType.equals(op.operationType) &
                t.collectionName.equals(op.collectionName) &
                t.documentId.equals(op.documentId) &
                t.enterpriseId.equals(op.enterpriseId) &
                t.status.equals('pending') &
                t.id.isNotValue(id),
          ))
        .get();

    if (otherPending.isNotEmpty) {
      await (_db.delete(_db.syncOperations)..where((t) => t.id.equals(id))).go();
      AppLogger.info(
        'Dropped failed op $id (pending exists): '
        '${op.operationType} ${op.collectionName}/${op.documentId}',
        name: 'SyncOperationDao',
      );
      return;
    }

    await (_db.update(_db.syncOperations)..where((t) => t.id.equals(id))).write(
      SyncOperationsCompanion(
        status: const Value('pending'),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Updates retry count for an operation.
  Future<void> updateRetryCount(int id, int retryCount) async {
    await (_db.update(_db.syncOperations)..where((t) => t.id.equals(id))).write(
      SyncOperationsCompanion(
        retryCount: Value(retryCount),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Deletes old synced operations (cleanup).
  Future<void> deleteOldSynced({required Duration maxAge}) async {
    final cutoff = DateTime.now().subtract(maxAge);
    await (_db.delete(_db.syncOperations)..where(
          (t) =>
              t.status.equals('synced') &
              t.processedAt.isSmallerThanValue(cutoff),
        ))
        .go();
  }

  /// Deletes operations that have exceeded max retry attempts.
  Future<void> deleteExceededRetries(int maxRetries) async {
    await (_db.delete(
      _db.syncOperations,
    )..where((t) => t.retryCount.isBiggerOrEqualValue(maxRetries))).go();
  }

  /// Clears all sync operations (for testing/cleanup).
  Future<void> clearAll() async {
    await _db.delete(_db.syncOperations).go();
  }

  /// Deletes all sync operations for a specific enterprise.
  Future<void> clearEnterprise(String enterpriseId) async {
    await (_db.delete(_db.syncOperations)
          ..where((t) => t.enterpriseId.equals(enterpriseId)))
        .go();
  }

  /// Converts a Drift SyncOperation to a SyncOperation entity.
  entities.SyncOperation toEntity(SyncOperation data) {
    final operation = entities.SyncOperation();
    operation.id = data.id;
    operation.operationType = data.operationType;
    operation.collectionName = data.collectionName;
    operation.documentId = data.documentId;
    operation.enterpriseId = data.enterpriseId;
    operation.payload = data.payload;
    operation.retryCount = data.retryCount;
    operation.lastError = data.lastError;
    operation.createdAt = data.createdAt;
    operation.processedAt = data.processedAt;
    operation.status = data.status;
    operation.localUpdatedAt = data.localUpdatedAt;
    // Map priority integer to SyncPriority enum
    operation.priority = entities.SyncPriority.values.firstWhere(
      (p) => p.value == data.priority,
      orElse: () => entities.SyncPriority.normal,
    );
    return operation;
  }

  /// Converts a SyncOperation entity to a SyncOperationsCompanion for insertion.
  SyncOperationsCompanion fromEntity(entities.SyncOperation operation) {
    return SyncOperationsCompanion.insert(
      operationType: operation.operationType,
      collectionName: operation.collectionName,
      documentId: operation.documentId,
      enterpriseId: operation.enterpriseId,
      payload: Value(operation.payload),
      retryCount: Value(operation.retryCount),
      lastError: Value(operation.lastError),
      createdAt: operation.createdAt,
      processedAt: Value(operation.processedAt),
      status: Value(operation.status),
      localUpdatedAt: operation.localUpdatedAt,
      priority: Value(operation.priority.value),
    );
  }
}
