import 'dart:convert';
import 'dart:developer' as developer;

import 'package:isar/isar.dart';

import 'connectivity_service.dart';
import 'isar_service.dart';
import 'sync_manager.dart';
import 'sync_status.dart';

/// Base class for offline-first repositories.
///
/// Provides common functionality for:
/// - Reading from local cache first
/// - Writing to local cache and queuing sync
/// - Automatic sync when online
///
/// Example usage:
/// ```dart
/// class ProductRepository extends OfflineRepository<Product> {
///   @override
///   String get collectionName => 'products';
///
///   @override
///   Product fromMap(Map<String, dynamic> map) => Product.fromMap(map);
///
///   @override
///   Map<String, dynamic> toMap(Product entity) => entity.toMap();
/// }
/// ```
abstract class OfflineRepository<T> {
  OfflineRepository({
    required this.isarService,
    required this.syncManager,
    required this.connectivityService,
  });

  final IsarService isarService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;

  /// The name of this collection (used for sync tracking).
  String get collectionName;

  /// Converts a map to an entity.
  T fromMap(Map<String, dynamic> map);

  /// Converts an entity to a map.
  Map<String, dynamic> toMap(T entity);

  /// Gets the local ID from an entity.
  String getLocalId(T entity);

  /// Gets the remote ID from an entity (null if not synced yet).
  String? getRemoteId(T entity);

  /// Gets the enterprise ID from an entity.
  String? getEnterpriseId(T entity);

  /// Whether the device is currently online.
  bool get isOnline => connectivityService.isOnline;

  /// Saves an entity locally and queues for sync.
  Future<void> save(T entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final enterpriseId = getEnterpriseId(entity);
    final data = toMap(entity);

    // Save to local cache (implementation depends on collection type)
    await saveToLocal(entity);

    // Queue for sync
    if (remoteId != null) {
      await syncManager.queueUpdate(
        collectionName: collectionName,
        localId: localId,
        remoteId: remoteId,
        data: data,
        enterpriseId: enterpriseId,
      );
    } else {
      await syncManager.queueCreate(
        collectionName: collectionName,
        localId: localId,
        data: data,
        enterpriseId: enterpriseId,
      );
    }

    // Update sync metadata
    await _updateSyncMetadata(
      localId: localId,
      remoteId: remoteId,
      state: SyncState.pendingUpload,
      data: data,
    );

    developer.log(
      'Saved $collectionName/$localId locally, queued for sync',
      name: 'offline.repository',
    );
  }

  /// Saves an entity to local storage.
  ///
  /// Override this in subclasses to implement collection-specific storage.
  Future<void> saveToLocal(T entity);

  /// Deletes an entity locally and queues for sync.
  Future<void> delete(T entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final enterpriseId = getEnterpriseId(entity);

    // Delete from local cache
    await deleteFromLocal(entity);

    // Queue for sync (only if it was synced to server)
    if (remoteId != null) {
      await syncManager.queueDelete(
        collectionName: collectionName,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
      );

      await _updateSyncMetadata(
        localId: localId,
        remoteId: remoteId,
        state: SyncState.pendingDelete,
      );
    } else {
      // Never synced, just remove local metadata
      await _removeSyncMetadata(localId);
    }

    developer.log(
      'Deleted $collectionName/$localId locally, queued for sync',
      name: 'offline.repository',
    );
  }

  /// Deletes an entity from local storage.
  ///
  /// Override this in subclasses to implement collection-specific deletion.
  Future<void> deleteFromLocal(T entity);

  /// Gets an entity by local ID.
  Future<T?> getByLocalId(String localId);

  /// Gets all entities for an enterprise.
  Future<List<T>> getAllForEnterprise(String enterpriseId);

  /// Updates sync metadata for an entity.
  Future<void> _updateSyncMetadata({
    required String localId,
    String? remoteId,
    required SyncState state,
    Map<String, dynamic>? data,
  }) async {
    final isar = isarService.isar;

    await isar.writeTxn(() async {
      var metadata = await isar.syncMetadatas
          .filter()
          .collectionNameEqualTo(collectionName)
          .and()
          .localIdEqualTo(localId)
          .findFirst();

      if (metadata == null) {
        metadata = SyncMetadata.forNewEntity(
          collectionName: collectionName,
          localId: localId,
          pendingData: data != null ? jsonEncode(data) : null,
        );
      } else {
        metadata.syncState = state;
        metadata.localUpdatedAt = DateTime.now();
        if (remoteId != null) {
          metadata.remoteId = remoteId;
        }
        if (data != null) {
          metadata.pendingData = jsonEncode(data);
        }
      }

      await isar.syncMetadatas.put(metadata);
    });
  }

  /// Removes sync metadata for an entity.
  Future<void> _removeSyncMetadata(String localId) async {
    final isar = isarService.isar;

    await isar.writeTxn(() async {
      await isar.syncMetadatas
          .filter()
          .collectionNameEqualTo(collectionName)
          .and()
          .localIdEqualTo(localId)
          .deleteAll();
    });
  }

  /// Marks an entity as synced.
  Future<void> markSynced({
    required String localId,
    required String remoteId,
    DateTime? serverUpdatedAt,
  }) async {
    final isar = isarService.isar;

    await isar.writeTxn(() async {
      final metadata = await isar.syncMetadatas
          .filter()
          .collectionNameEqualTo(collectionName)
          .and()
          .localIdEqualTo(localId)
          .findFirst();

      if (metadata != null) {
        metadata.markSynced(
          remoteId: remoteId,
          serverUpdatedAt: serverUpdatedAt,
        );
        await isar.syncMetadatas.put(metadata);
      }
    });
  }

  /// Gets sync status for an entity.
  Future<SyncState?> getSyncState(String localId) async {
    final metadata = await isarService.isar.syncMetadatas
        .filter()
        .collectionNameEqualTo(collectionName)
        .and()
        .localIdEqualTo(localId)
        .findFirst();

    return metadata?.syncState;
  }

  /// Gets all entities that need syncing.
  Future<List<SyncMetadata>> getPendingSync() async {
    return isarService.isar.syncMetadatas
        .filter()
        .collectionNameEqualTo(collectionName)
        .and()
        .group((q) => q
            .syncStateEqualTo(SyncState.pendingUpload)
            .or()
            .syncStateEqualTo(SyncState.pendingDelete)
            .or()
            .syncStateEqualTo(SyncState.failed))
        .findAll();
  }
}

/// Utility for generating local IDs.
class LocalIdGenerator {
  LocalIdGenerator._();

  /// Generates a unique local ID.
  ///
  /// Uses timestamp + random component for uniqueness.
  static String generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode.toRadixString(36);
    return 'local_${timestamp}_$random';
  }

  /// Checks if an ID is a local ID.
  static bool isLocalId(String id) {
    return id.startsWith('local_');
  }
}
