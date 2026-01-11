import 'dart:developer' as developer;

import 'connectivity_service.dart';
import 'drift_service.dart';
import 'sync_manager.dart';
import 'sync_status.dart';

/// Base class for offline-first repositories with automatic sync queuing.
///
/// Provides:
/// - Local storage via Drift (SQLite)
/// - Automatic sync queue management
/// - Conflict detection and resolution
/// - Connectivity-aware sync triggering
abstract class OfflineRepository<T> {
  OfflineRepository({
    required this.driftService,
    required this.syncManager,
    required this.connectivityService,
    this.enableAutoSync = true,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;

  /// Whether to automatically queue sync operations on save/delete.
  final bool enableAutoSync;

  String get collectionName;
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T entity);
  String getLocalId(T entity);
  String? getRemoteId(T entity);
  String? getEnterpriseId(T entity);

  bool get isOnline => connectivityService.isOnline;

  /// Saves an entity to local storage and queues for sync.
  /// 
  /// Ne lance pas d'exception si la sauvegarde locale échoue (erreur SQLite),
  /// pour permettre à l'opération de continuer. L'entité sera récupérée depuis
  /// Firestore lors de la prochaine synchronisation.
  Future<void> save(T entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final enterpriseId = getEnterpriseId(entity);
    final data = toMap(entity);

    developer.log(
      'OfflineRepository.save: $collectionName/$localId',
      name: 'offline.repository',
    );

    // Save to local storage first
    try {
      await saveToLocal(entity);
    } catch (e, stackTrace) {
      developer.log(
        'Error saving to local storage (entity exists in Firestore, will be synced later): $e',
        name: 'offline.repository',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne pas rethrow - permet à l'opération de continuer même si Drift échoue
      // L'entité sera récupérée depuis Firestore lors de la prochaine synchronisation
    }

    // Queue sync operation if auto-sync is enabled
    // Même si la sauvegarde locale a échoué, on peut quand même queue la sync
    if (enableAutoSync) {
      try {
        if (remoteId != null && remoteId.isNotEmpty) {
          // Update existing remote document
          await syncManager.queueUpdate(
            collectionName: collectionName,
            localId: localId,
            remoteId: remoteId,
            data: data,
            enterpriseId: enterpriseId,
          );
        } else {
          // Create new document
          await syncManager.queueCreate(
            collectionName: collectionName,
            localId: localId,
            data: data,
            enterpriseId: enterpriseId,
          );
        }
      } catch (e) {
        developer.log(
          'Error queueing sync operation: $e',
          name: 'offline.repository',
        );
        // Ne pas rethrow - la sync se fera plus tard
      }
    }
  }

  Future<void> saveToLocal(T entity);

  /// Deletes an entity from local storage and queues delete for sync.
  Future<void> delete(T entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final enterpriseId = getEnterpriseId(entity);

    developer.log(
      'OfflineRepository.delete: $collectionName/$localId',
      name: 'offline.repository',
    );

    // Delete from local storage first
    await deleteFromLocal(entity);

    // Queue sync operation if auto-sync is enabled and has remote ID
    if (enableAutoSync && remoteId != null && remoteId.isNotEmpty) {
      await syncManager.queueDelete(
        collectionName: collectionName,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
      );
    }
  }

  Future<void> deleteFromLocal(T entity);

  Future<T?> getByLocalId(String localId);

  Future<List<T>> getAllForEnterprise(String enterpriseId);

  /// Marks an entity as synced with the remote server.
  Future<void> markSynced({
    required String localId,
    required String remoteId,
    DateTime? serverUpdatedAt,
  }) async {
    developer.log(
      'markSynced: $collectionName/$localId -> $remoteId',
      name: 'offline.repository',
    );

    // Update the record with the remote ID
    await driftService.records.updateRemoteId(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      serverUpdatedAt: serverUpdatedAt,
    );
  }

  /// Gets the sync state for an entity.
  Future<SyncState> getSyncState(String localId) async {
    final pendingOps = await syncManager.getPendingForCollection(collectionName);
    final hasPending = pendingOps.any((op) => op.documentId == localId);
    return hasPending ? SyncState.pending : SyncState.synced;
  }

  /// Gets all entities pending sync.
  Future<List<SyncMetadata>> getPendingSync() async {
    final pendingOps = await syncManager.getPendingForCollection(collectionName);
    return pendingOps.map((op) => SyncMetadata(
      localId: op.documentId,
      collectionName: op.collectionName,
      operationType: op.operationType,
      createdAt: op.createdAt,
    )).toList();
  }
}

/// Utility for generating local IDs.
class LocalIdGenerator {
  LocalIdGenerator._();

  static String generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode.toRadixString(36);
    return 'local_${timestamp}_$random';
  }

  static bool isLocalId(String id) {
    return id.startsWith('local_');
  }
}
