import 'dart:developer' as developer;

import 'connectivity_service.dart';
import 'drift_service.dart';
import 'sync_manager.dart';
import 'sync_status.dart';

/// Stub OfflineRepository - Drift integration pending.
abstract class OfflineRepository<T> {
  OfflineRepository({
    required this.driftService,
    required this.syncManager,
    required this.connectivityService,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;

  String get collectionName;
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T entity);
  String getLocalId(T entity);
  String? getRemoteId(T entity);
  String? getEnterpriseId(T entity);

  bool get isOnline => connectivityService.isOnline;

  Future<void> save(T entity) async {
    final localId = getLocalId(entity);
    developer.log(
      'OfflineRepository.save called (stub): $collectionName/$localId',
      name: 'offline.repository',
    );
    await saveToLocal(entity);
  }

  Future<void> saveToLocal(T entity);

  Future<void> delete(T entity) async {
    final localId = getLocalId(entity);
    developer.log(
      'OfflineRepository.delete called (stub): $collectionName/$localId',
      name: 'offline.repository',
    );
    await deleteFromLocal(entity);
  }

  Future<void> deleteFromLocal(T entity);

  Future<T?> getByLocalId(String localId);

  Future<List<T>> getAllForEnterprise(String enterpriseId);

  Future<void> markSynced({
    required String localId,
    required String remoteId,
    DateTime? serverUpdatedAt,
  }) async {
    developer.log(
      'markSynced called (stub): $collectionName/$localId',
      name: 'offline.repository',
    );
  }

  Future<SyncState?> getSyncState(String localId) async => SyncState.synced;

  Future<List<SyncMetadata>> getPendingSync() async => [];
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
