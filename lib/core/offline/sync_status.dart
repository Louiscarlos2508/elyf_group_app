/// Stub sync status classes - Isar temporarily disabled.
/// 
/// TODO: Migrate to ObjectBox.

/// Enum for sync status.
enum SyncStatus {
  idle,
  syncing,
  synced,
  error,
}

/// Enum for entity sync state.
enum SyncState {
  pendingUpload,
  pendingDelete,
  synced,
  failed,
}

/// Stub SyncMetadata class.
class SyncMetadata {
  int id = 0;
  late String collectionName;
  late String enterpriseId;
  DateTime? lastSyncedAt;
  String? lastSyncError;
  int pendingCount = 0;
  late DateTime localUpdatedAt;

  SyncMetadata();
}

/// Stub SyncOperation class.
class SyncOperation {
  int id = 0;
  late String operationType;
  late String collectionName;
  late String documentId;
  late String enterpriseId;
  String? payload;
  int retryCount = 0;
  String? lastError;
  late DateTime createdAt;
  DateTime? processedAt;
  String status = 'pending';
  late DateTime localUpdatedAt;

  SyncOperation();

  Map<String, dynamic>? get payloadMap => null;
}
