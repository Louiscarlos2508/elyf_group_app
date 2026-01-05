import 'package:isar/isar.dart';

part 'sync_status.g.dart';

/// Represents the synchronization status of a record.
///
/// Used to track whether data has been synced with the remote server.
enum SyncState {
  /// Data is synced with the server.
  synced,

  /// Data is pending upload to the server.
  pendingUpload,

  /// Data is pending deletion on the server.
  pendingDelete,

  /// Data failed to sync and needs retry.
  failed,

  /// Data has conflicts that need resolution.
  conflict,
}

/// Tracks synchronization metadata for any syncable entity.
@collection
class SyncMetadata {
  Id id = Isar.autoIncrement;

  /// The collection/table name this metadata belongs to.
  @Index()
  late String collectionName;

  /// The local ID of the entity.
  @Index(composite: [CompositeIndex('collectionName')])
  late String localId;

  /// The remote ID (Firebase document ID) of the entity.
  String? remoteId;

  /// Current sync state.
  @Enumerated(EnumType.name)
  late SyncState syncState;

  /// Timestamp of last local modification.
  late DateTime localUpdatedAt;

  /// Timestamp of last remote modification (from server).
  DateTime? remoteUpdatedAt;

  /// Number of sync attempts.
  int syncAttempts = 0;

  /// Last sync error message, if any.
  String? lastError;

  /// Timestamp of last sync attempt.
  DateTime? lastSyncAttempt;

  /// JSON representation of the entity data for offline operations.
  String? pendingData;

  /// Creates a new sync metadata entry.
  SyncMetadata();

  /// Creates sync metadata for a new local entity.
  factory SyncMetadata.forNewEntity({
    required String collectionName,
    required String localId,
    String? pendingData,
  }) {
    return SyncMetadata()
      ..collectionName = collectionName
      ..localId = localId
      ..syncState = SyncState.pendingUpload
      ..localUpdatedAt = DateTime.now()
      ..pendingData = pendingData;
  }

  /// Creates sync metadata for an entity synced from the server.
  factory SyncMetadata.fromServer({
    required String collectionName,
    required String localId,
    required String remoteId,
    required DateTime remoteUpdatedAt,
  }) {
    return SyncMetadata()
      ..collectionName = collectionName
      ..localId = localId
      ..remoteId = remoteId
      ..syncState = SyncState.synced
      ..localUpdatedAt = remoteUpdatedAt
      ..remoteUpdatedAt = remoteUpdatedAt;
  }

  /// Marks the entity as pending upload.
  void markPendingUpload({String? data}) {
    syncState = SyncState.pendingUpload;
    localUpdatedAt = DateTime.now();
    if (data != null) {
      pendingData = data;
    }
  }

  /// Marks the entity as pending deletion.
  void markPendingDelete() {
    syncState = SyncState.pendingDelete;
    localUpdatedAt = DateTime.now();
  }

  /// Marks the entity as synced.
  void markSynced({
    String? remoteId,
    DateTime? serverUpdatedAt,
  }) {
    syncState = SyncState.synced;
    if (remoteId != null) {
      this.remoteId = remoteId;
    }
    if (serverUpdatedAt != null) {
      remoteUpdatedAt = serverUpdatedAt;
    }
    pendingData = null;
    lastError = null;
    syncAttempts = 0;
  }

  /// Marks the sync as failed.
  void markFailed(String error) {
    syncState = SyncState.failed;
    lastError = error;
    lastSyncAttempt = DateTime.now();
    syncAttempts++;
  }

  /// Marks the entity as having conflicts.
  void markConflict() {
    syncState = SyncState.conflict;
    lastSyncAttempt = DateTime.now();
  }

  /// Whether this entity needs to be synced.
  bool get needsSync =>
      syncState == SyncState.pendingUpload ||
      syncState == SyncState.pendingDelete ||
      syncState == SyncState.failed;

  /// Whether sync should be retried (max 5 attempts).
  bool get shouldRetry => syncAttempts < 5;
}

/// Represents a pending sync operation in the queue.
@collection
class SyncOperation {
  Id id = Isar.autoIncrement;

  /// Type of operation: create, update, delete.
  @Index()
  late String operationType;

  /// The collection/table name.
  @Index()
  late String collectionName;

  /// The local entity ID.
  late String localId;

  /// The remote entity ID (for updates/deletes).
  String? remoteId;

  /// JSON data of the operation.
  late String data;

  /// Timestamp when the operation was queued.
  @Index()
  late DateTime createdAt;

  /// Priority of the operation (lower = higher priority).
  @Index()
  int priority = 100;

  /// Number of retry attempts.
  int retryCount = 0;

  /// Last error message.
  String? lastError;

  /// Enterprise ID for multi-tenant support.
  @Index()
  String? enterpriseId;

  /// Creates a new sync operation.
  SyncOperation();

  /// Creates a create operation.
  factory SyncOperation.create({
    required String collectionName,
    required String localId,
    required String data,
    String? enterpriseId,
    int priority = 100,
  }) {
    return SyncOperation()
      ..operationType = 'create'
      ..collectionName = collectionName
      ..localId = localId
      ..data = data
      ..createdAt = DateTime.now()
      ..priority = priority
      ..enterpriseId = enterpriseId;
  }

  /// Creates an update operation.
  factory SyncOperation.update({
    required String collectionName,
    required String localId,
    required String remoteId,
    required String data,
    String? enterpriseId,
    int priority = 100,
  }) {
    return SyncOperation()
      ..operationType = 'update'
      ..collectionName = collectionName
      ..localId = localId
      ..remoteId = remoteId
      ..data = data
      ..createdAt = DateTime.now()
      ..priority = priority
      ..enterpriseId = enterpriseId;
  }

  /// Creates a delete operation.
  factory SyncOperation.delete({
    required String collectionName,
    required String localId,
    required String remoteId,
    String? enterpriseId,
    int priority = 50,
  }) {
    return SyncOperation()
      ..operationType = 'delete'
      ..collectionName = collectionName
      ..localId = localId
      ..remoteId = remoteId
      ..data = '{}'
      ..createdAt = DateTime.now()
      ..priority = priority
      ..enterpriseId = enterpriseId;
  }
}
