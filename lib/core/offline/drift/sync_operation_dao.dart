import 'package:drift/drift.dart';

import 'app_database.dart';
import '../sync_status.dart' as entities;

/// DAO for managing sync operations queue.
class SyncOperationDao {
  SyncOperationDao(this._db);

  final AppDatabase _db;

  /// Inserts a new sync operation into the queue.
  Future<int> insert(SyncOperationsCompanion operation) async {
    return await _db.into(_db.syncOperations).insert(operation);
  }

  /// Gets a pending operation by ID.
  Future<SyncOperation?> getById(int id) async {
    return await (_db.select(_db.syncOperations)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Gets all pending operations, ordered by creation time (oldest first).
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
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);

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
  Future<void> markProcessing(int id) async {
    await (_db.update(_db.syncOperations)
          ..where((t) => t.id.equals(id)))
        .write(
      SyncOperationsCompanion(
        status: const Value('processing'),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Marks an operation as synced.
  Future<void> markSynced(int id) async {
    await (_db.update(_db.syncOperations)
          ..where((t) => t.id.equals(id)))
        .write(
      SyncOperationsCompanion(
        status: const Value('synced'),
        processedAt: Value(DateTime.now()),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Marks an operation as failed and increments retry count.
  Future<void> markFailed(int id, String error, {int? newRetryCount}) async {
    final current = await getById(id);
    if (current == null) return;

    await (_db.update(_db.syncOperations)
          ..where((t) => t.id.equals(id)))
        .write(
      SyncOperationsCompanion(
        status: const Value('failed'),
        lastError: Value(error),
        retryCount: Value(newRetryCount ?? (current.retryCount + 1)),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Resets a failed operation back to pending for retry.
  Future<void> resetToPending(int id) async {
    await (_db.update(_db.syncOperations)
          ..where((t) => t.id.equals(id)))
        .write(
      SyncOperationsCompanion(
        status: const Value('pending'),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Updates retry count for an operation.
  Future<void> updateRetryCount(int id, int retryCount) async {
    await (_db.update(_db.syncOperations)
          ..where((t) => t.id.equals(id)))
        .write(
      SyncOperationsCompanion(
        retryCount: Value(retryCount),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Deletes old synced operations (cleanup).
  Future<void> deleteOldSynced({
    required Duration maxAge,
  }) async {
    final cutoff = DateTime.now().subtract(maxAge);
    await (_db.delete(_db.syncOperations)
          ..where(
            (t) =>
                t.status.equals('synced') &
                t.processedAt.isSmallerThanValue(cutoff),
          ))
        .go();
  }

  /// Deletes operations that have exceeded max retry attempts.
  Future<void> deleteExceededRetries(int maxRetries) async {
    await (_db.delete(_db.syncOperations)
          ..where((t) => t.retryCount.isBiggerOrEqualValue(maxRetries)))
        .go();
  }

  /// Clears all sync operations (for testing/cleanup).
  Future<void> clearAll() async {
    await _db.delete(_db.syncOperations).go();
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
    );
  }
}

