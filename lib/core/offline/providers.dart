import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_providers.dart';
import 'sync_paths.dart';
import 'global_module_realtime_sync_service.dart';
import '../../features/administration/data/services/firestore_sync_service.dart';
import '../../features/administration/data/services/realtime_sync_service.dart';
import '../firebase/providers.dart';
import '../tenant/tenant_provider.dart';
import 'sync/sync_conflict_resolver.dart';
export 'base_providers.dart';

import '../monitoring/monitoring_providers.dart';

/// Provider for sync metadata for a specific entity (stub returns null).

/// Provider for FirestoreSyncService (Admin module)
final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  final driftService = ref.watch(driftServiceProvider);
  final firestore = ref.watch(firestoreProvider);
  final monitoring = ref.watch(monitoringServiceProvider);
  
  return FirestoreSyncService(
    driftService: driftService,
    firestore: firestore,
    monitoring: monitoring,
  );
});

/// Provider for RealtimeSyncService (Admin module)
final realtimeSyncServiceProvider = Provider<RealtimeSyncService>((ref) {
  final driftService = ref.watch(driftServiceProvider);
  final firestore = ref.watch(firestoreProvider);
  final firestoreSync = ref.watch(firestoreSyncServiceProvider);
  final service = RealtimeSyncService(
    driftService: driftService,
    firestore: firestore,
    firestoreSync: firestoreSync,
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Provider for ConflictResolver
final conflictResolverProvider = Provider<SyncConflictResolver>((ref) {
  return const SyncConflictResolver(
    customStrategies: {
      'production_sessions': ConflictResolutionStrategy.merge,
      // Add other complex collections here if needed
    },
  );
});

/// Provider for GlobalModuleRealtimeSyncService
final globalModuleRealtimeSyncServiceProvider =
    Provider<GlobalModuleRealtimeSyncService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final driftService = ref.watch(driftServiceProvider);
  final syncManager = ref.watch(syncManagerProvider);
  final conflictResolver = ref.watch(conflictResolverProvider);

  return GlobalModuleRealtimeSyncService(
    firestore: firestore,
    driftService: driftService,
    collectionPaths: collectionPaths,
    syncManager: syncManager,
    conflictResolver: conflictResolver,
    getActiveEnterpriseId: () => ref.read(activeEnterpriseIdProvider).value,
  );
});
