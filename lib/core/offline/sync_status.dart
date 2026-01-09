import 'dart:convert';

/// Sync status classes for managing sync operations.

/// Enum for sync status.
enum SyncStatus {
  idle,
  syncing,
  synced,
  error,
}

/// Enum for entity sync state.
enum SyncState {
  /// Entity is pending upload/sync.
  pending,
  /// Alias for pending (backward compatibility).
  pendingUpload,
  /// Entity is pending delete sync.
  pendingDelete,
  /// Entity is synced with server.
  synced,
  /// Sync failed for this entity.
  failed,
}

/// Metadata about sync state for an entity or collection.
class SyncMetadata {
  SyncMetadata({
    this.id = 0,
    this.localId,
    required this.collectionName,
    this.enterpriseId = '',
    this.operationType,
    this.lastSyncedAt,
    this.lastSyncError,
    this.pendingCount = 0,
    DateTime? createdAt,
    DateTime? localUpdatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        localUpdatedAt = localUpdatedAt ?? DateTime.now();

  int id;
  String? localId;
  String collectionName;
  String enterpriseId;
  String? operationType;
  DateTime? lastSyncedAt;
  String? lastSyncError;
  int pendingCount;
  DateTime createdAt;
  DateTime localUpdatedAt;
}

/// SyncOperation class representing a queued sync operation.
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

  /// Parses the JSON payload into a Map.
  Map<String, dynamic>? get payloadMap {
    if (payload == null || payload!.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(payload!) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
