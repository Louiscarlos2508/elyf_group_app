import '../logging/app_logger.dart';
import 'monitoring_service.dart';

/// High-level sync monitoring helper.
///
/// Wraps [MonitoringService] with sync-specific convenience methods.
/// Inject this into [SyncManager], [ModuleRealtimeSyncService], etc.
/// instead of calling [MonitoringService] directly, to keep a consistent
/// naming convention for sync events.
class SyncMonitorService {
  SyncMonitorService(this._monitoring);

  final MonitoringService _monitoring;

  // ---------------------------------------------------------------------------
  // Sync lifecycle
  // ---------------------------------------------------------------------------

  /// Call at the start of a sync cycle.
  Future<void> logSyncStart({
    required String module,
    String? enterpriseId,
  }) async {
    await _monitoring.logSyncStart(
      module: module,
      enterpriseId: enterpriseId,
    );
  }

  /// Call when a sync cycle completes successfully.
  Future<void> logSyncSuccess({
    required int durationMs,
    String? module,
  }) async {
    await _monitoring.logSyncSuccess(durationMs: durationMs, module: module);
  }

  /// Call when a sync cycle fails.
  Future<void> logSyncError(
    Object error,
    StackTrace? stack, {
    String? module,
  }) async {
    await _monitoring.logSyncError(error, stack, module: module);
  }

  // ---------------------------------------------------------------------------
  // Conflict detection
  // ---------------------------------------------------------------------------

  /// Log a data conflict detected during sync.
  Future<void> logConflict({
    required String collection,
    String? resolution,
    String? module,
  }) async {
    await _monitoring.logSyncConflict(
      collection: collection,
      resolution: resolution,
      module: module,
    );
  }

  // ---------------------------------------------------------------------------
  // Offline mode
  // ---------------------------------------------------------------------------

  /// Log when offline mode is activated.
  Future<void> logOfflineMode({String? reason}) async {
    await _monitoring.logOfflineModeActivated(reason: reason);
  }

  // ---------------------------------------------------------------------------
  // Timed sync helper
  // ---------------------------------------------------------------------------

  /// Execute [body] while measuring its duration and logging start/success/error.
  ///
  /// Example:
  /// ```dart
  /// await syncMonitor.timedSync(
  ///   module: 'boutique',
  ///   body: () async { /* your sync logic */ },
  /// );
  /// ```
  Future<T> timedSync<T>({
    required String module,
    String? enterpriseId,
    required Future<T> Function() body,
  }) async {
    await logSyncStart(module: module, enterpriseId: enterpriseId);
    final sw = Stopwatch()..start();
    try {
      final result = await body();
      sw.stop();
      await logSyncSuccess(durationMs: sw.elapsedMilliseconds, module: module);
      return result;
    } catch (error, stack) {
      sw.stop();
      await logSyncError(error, stack, module: module);
      AppLogger.error('SyncMonitor: timedSync failed for $module',
          name: 'monitoring.sync', error: error, stackTrace: stack);
      rethrow;
    }
  }
}
