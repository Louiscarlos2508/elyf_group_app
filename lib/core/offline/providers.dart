import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_service.dart';
import 'drift_service.dart';
import 'sync_manager.dart';
import 'sync_status.dart';

/// Provider for the Drift service singleton.
final driftServiceProvider = Provider<DriftService>((ref) {
  return DriftService.instance;
});

/// Provider for the connectivity service.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the current connectivity status.
final connectivityStatusProvider =
    StreamProvider<ConnectivityStatus>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield service.currentStatus;
  yield* service.statusStream;
});

/// Provider for whether the device is online.
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityStatusProvider);
  return status.maybeWhen(
    data: (s) => s.isOnline,
    orElse: () => false,
  );
});

/// Provider for the sync manager (stub).
final syncManagerProvider = Provider<SyncManager>((ref) {
  final driftService = ref.watch(driftServiceProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  final manager = SyncManager(
    driftService: driftService,
    connectivityService: connectivityService,
  );

  ref.onDispose(() => manager.dispose());
  return manager;
});

/// Provider for sync progress updates.
final syncProgressProvider = StreamProvider<SyncProgress>((ref) {
  final manager = ref.watch(syncManagerProvider);
  return manager.syncProgressStream;
});

/// Provider for the count of pending sync operations.
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final manager = ref.watch(syncManagerProvider);
  return manager.getPendingCount();
});

/// Provider for whether a sync is in progress.
final isSyncingProvider = Provider<bool>((ref) {
  final progress = ref.watch(syncProgressProvider);
  return progress.maybeWhen(
    data: (p) => p.status == SyncStatus.syncing,
    orElse: () => false,
  );
});

/// Notifier for offline mode state.
class OfflineModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final isOnline = ref.watch(isOnlineProvider);
    return !isOnline;
  }

  /// Manually toggle offline mode (for testing).
  void toggle() {
    state = !state;
  }
}

/// Provider for offline mode state.
final offlineModeProvider =
    NotifierProvider<OfflineModeNotifier, bool>(OfflineModeNotifier.new);

/// Provider for sync metadata for a specific entity (stub returns null).
final syncMetadataProvider =
    FutureProvider.family<SyncMetadata?, (String, String)>((ref, params) async {
  // Stub: return null (sync metadata persistence not implemented yet).
  return null;
});

/// Actions provider for triggering sync operations.
class SyncActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Triggers a manual sync.
  Future<SyncResult> triggerSync() async {
    final manager = ref.read(syncManagerProvider);
    return manager.syncPendingOperations();
  }

  /// Clears all pending operations.
  Future<void> clearPending() async {
    final manager = ref.read(syncManagerProvider);
    await manager.clearPendingOperations();
  }
}

/// Provider for sync actions.
final syncActionsProvider =
    NotifierProvider<SyncActionsNotifier, void>(SyncActionsNotifier.new);
