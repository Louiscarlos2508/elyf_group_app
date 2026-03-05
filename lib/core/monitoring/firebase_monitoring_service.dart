import '../logging/app_logger.dart';
import 'analytics_service.dart';
import 'crash_service.dart';
import 'monitoring_service.dart';
import 'performance_service.dart';

/// Concrete [MonitoringService] that delegates to the three Firebase services.
///
/// This is the ONLY file inside `lib/core/monitoring/` that holds references
/// to the Firebase sub-services. Feature modules see only [MonitoringService].
class FirebaseMonitoringService implements MonitoringService {
  FirebaseMonitoringService({
    required CrashService crash,
    required AnalyticsService analytics,
    required PerformanceService performance,
  })  : _crash = crash,
        _analytics = analytics,
        _performance = performance;

  final CrashService _crash;
  final AnalyticsService _analytics;
  final PerformanceService _performance;

  // ---------------------------------------------------------------------------
  // Crash
  // ---------------------------------------------------------------------------

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {
    try {
      await _crash.recordError(error, stack, fatal: fatal, reason: reason);
    } catch (e) {
      AppLogger.warning('MonitoringService.recordError failed: $e',
          name: 'monitoring');
    }
  }

  @override
  Future<void> setUserIdentifier(String userId) async {
    try {
      await _crash.setUserIdentifier(userId);
      await _analytics.setUserId(userId);
    } catch (e) {
      AppLogger.warning('MonitoringService.setUserIdentifier failed: $e',
          name: 'monitoring');
    }
  }

  @override
  Future<void> clearUserIdentifier() async {
    try {
      await _crash.clearUserIdentifier();
      await _analytics.clearUserId();
    } catch (e) {
      AppLogger.warning('MonitoringService.clearUserIdentifier failed: $e',
          name: 'monitoring');
    }
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    try {
      await _crash.setCustomKey(key, value);
    } catch (e) {
      AppLogger.warning('MonitoringService.setCustomKey failed: $e',
          name: 'monitoring');
    }
  }

  // ---------------------------------------------------------------------------
  // Analytics
  // ---------------------------------------------------------------------------

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name, parameters);
      AppLogger.debug('📊 Event: $name ${parameters ?? ''}',
          name: 'monitoring');
    } catch (e) {
      AppLogger.warning('MonitoringService.logEvent failed: $e',
          name: 'monitoring');
    }
  }

  @override
  Future<void> setCurrentScreen(String screenName) async {
    try {
      await _analytics.setCurrentScreen(screenName);
    } catch (e) {
      AppLogger.warning('MonitoringService.setCurrentScreen failed: $e',
          name: 'monitoring');
    }
  }

  // ---------------------------------------------------------------------------
  // Performance
  // ---------------------------------------------------------------------------

  @override
  Future<PerformanceTrace> startTrace(String name) async {
    return _performance.startTrace(name);
  }

  // ---------------------------------------------------------------------------
  // Sync monitoring
  // ---------------------------------------------------------------------------

  @override
  Future<void> logSyncStart({
    required String module,
    String? enterpriseId,
  }) async {
    AppLogger.info('🔄 Sync START — module: $module', name: 'monitoring.sync');
    await logEvent('sync_start', {
      'module': module,
      if (enterpriseId != null) 'enterprise_id': enterpriseId,
    });
  }

  @override
  Future<void> logSyncSuccess({
    required int durationMs,
    String? module,
  }) async {
    AppLogger.info(
        '✅ Sync SUCCESS — module: ${module ?? 'unknown'} (${durationMs}ms)',
        name: 'monitoring.sync');
    await logEvent('sync_success', {
      'duration_ms': durationMs,
      if (module != null) 'module': module,
    });
  }

  @override
  Future<void> logSyncError(
    Object error,
    StackTrace? stack, {
    String? module,
  }) async {
    AppLogger.error(
        '❌ Sync ERROR — module: ${module ?? 'unknown'}',
        name: 'monitoring.sync',
        error: error,
        stackTrace: stack);
    await recordError(error, stack,
        fatal: false, reason: 'sync_error:${module ?? 'unknown'}');
    await logEvent('sync_error', {
      'error': error.toString().substring(
          0, error.toString().length > 100 ? 100 : error.toString().length),
      if (module != null) 'module': module,
    });
  }

  @override
  Future<void> logSyncConflict({
    required String collection,
    String? resolution,
    String? module,
  }) async {
    AppLogger.warning(
        '⚠️ Sync CONFLICT — collection: $collection resolution: $resolution',
        name: 'monitoring.sync');
    await logEvent('sync_conflict', {
      'collection': collection,
      if (resolution != null) 'resolution': resolution,
      if (module != null) 'module': module,
    });
  }

  @override
  Future<void> logOfflineModeActivated({String? reason}) async {
    AppLogger.info('📴 Offline mode ACTIVATED — reason: $reason',
        name: 'monitoring');
    await logEvent('offline_mode_activated', {
      if (reason != null) 'reason': reason,
    });
  }

  // ---------------------------------------------------------------------------
  // Drift monitoring
  // ---------------------------------------------------------------------------

  @override
  Future<void> logQuerySlow({
    required String queryName,
    required int durationMs,
  }) async {
    AppLogger.warning(
        '🐢 SLOW QUERY: $queryName took ${durationMs}ms',
        name: 'monitoring.drift');
    await logEvent('drift_slow_query', {
      'query_name': queryName,
      'duration_ms': durationMs,
    });
  }

  // ---------------------------------------------------------------------------
  // Firebase latency monitoring
  // ---------------------------------------------------------------------------

  @override
  Future<void> logFirebaseCallSlow({
    required String operation,
    required int durationMs,
  }) async {
    AppLogger.warning(
        '🐢 SLOW FIREBASE CALL: $operation took ${durationMs}ms',
        name: 'monitoring.firebase');
    await logEvent('firebase_slow_call', {
      'operation': operation,
      'duration_ms': durationMs,
    });
  }
}
