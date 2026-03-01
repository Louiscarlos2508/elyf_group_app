import 'dart:convert';

/// Sync status classes for managing sync operations.

/// Enum for sync status.
enum SyncStatus { idle, syncing, synced, error }

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
  }) : createdAt = createdAt ?? DateTime.now(),
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

/// Priority levels for sync operations.
///
/// Higher priority operations are processed first.
enum SyncPriority {
  /// Critical operations: sales, payments, financial transactions
  critical(0),

  /// High priority: inventory, stocks, important updates
  high(1),

  /// Normal priority: general data updates
  normal(2),

  /// Low priority: logs, metrics, non-critical data
  low(3);

  const SyncPriority(this.value);
  final int value;

  /// Compare priorities (lower value = higher priority).
  static int compare(SyncPriority a, SyncPriority b) {
    return a.value.compareTo(b.value);
  }
}

/// SyncOperation class representing a queued sync operation.
class SyncOperation {
  int id = 0;
  late String operationType;
  late String collectionName;
  late String documentId;
  late String enterpriseId;
  String? userId;
  String? payload;
  int retryCount = 0;
  String? lastError;
  late DateTime createdAt;
  DateTime? processedAt;
  String status = 'pending';
  late DateTime localUpdatedAt;
  SyncPriority priority = SyncPriority.normal;

  SyncOperation();

  /// Determines priority based on collection name and operation type.
  ///
  /// Critical: sales, payments, transactions
  /// High: stocks, inventory, important updates
  /// Normal: everything else
  static SyncPriority determinePriority(
    String collectionName,
    String operationType,
  ) {
    // Critical collections
    if (collectionName.contains('sale') ||
        collectionName.contains('payment') ||
        collectionName.contains('transaction') ||
        collectionName.contains('purchase')) {
      return SyncPriority.critical;
    }

    // High priority collections
    if (collectionName.contains('stock') ||
        collectionName.contains('inventory') ||
        collectionName.contains('cylinder') ||
        collectionName.contains('product')) {
      return SyncPriority.high;
    }

    // Low priority collections
    if (collectionName.contains('log') ||
        collectionName.contains('metric') ||
        collectionName.contains('audit')) {
      return SyncPriority.low;
    }

    return SyncPriority.normal;
  }

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
