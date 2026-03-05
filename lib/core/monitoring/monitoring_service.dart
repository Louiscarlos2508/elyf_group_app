import 'dart:async';

/// Abstract handle for an active performance trace.
///
/// Obtained via [MonitoringService.startTrace]. Always call [stop] when done.
abstract class PerformanceTrace {
  /// Add a custom integer metric to the trace.
  void putMetric(String name, int value);

  /// Add a custom string attribute to the trace.
  void putAttribute(String name, String value);

  /// Stop the trace and upload the data.
  Future<void> stop();
}

/// Top-level monitoring facade.
///
/// All feature modules and infrastructure services should depend on this
/// interface, never on Firebase SDK types directly.
///
/// Concrete implementation: [FirebaseMonitoringService].
/// Can be swapped for Sentry, Datadog, or a no-op in tests.
///
/// Usage:
/// ```dart
/// monitoring.logEvent('order_created', {'amount': 5000});
/// monitoring.logSyncStart(module: 'boutique');
/// monitoring.logSyncSuccess(durationMs: 1200);
/// monitoring.logSyncError(error, stackTrace);
/// ```
abstract class MonitoringService {
  // ---------------------------------------------------------------------------
  // Crash / Error reporting
  // ---------------------------------------------------------------------------

  /// Record a non-fatal or fatal error, forwarding to the crash backend.
  ///
  /// [fatal] marks whether the app crashed (true) or only had an error (false).
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  });

  /// Associate subsequent crash reports with [userId].
  Future<void> setUserIdentifier(String userId);

  /// Clear the user identifier (call on logout).
  Future<void> clearUserIdentifier();

  /// Attach an arbitrary key-value pair to future crash reports.
  Future<void> setCustomKey(String key, Object value);

  // ---------------------------------------------------------------------------
  // Analytics / Business events
  // ---------------------------------------------------------------------------

  /// Log a custom business event with optional [parameters].
  ///
  /// [name] must be ≤ 40 chars; parameter keys ≤ 24 chars; string values ≤ 100 chars.
  Future<void> logEvent(String name, [Map<String, Object>? parameters]);

  /// Notify the analytics backend about the current screen.
  Future<void> setCurrentScreen(String screenName);

  // ---------------------------------------------------------------------------
  // Performance
  // ---------------------------------------------------------------------------

  /// Start a custom performance trace named [name] and return its handle.
  ///
  /// The caller is responsible for calling [PerformanceTrace.stop].
  Future<PerformanceTrace> startTrace(String name);

  // ---------------------------------------------------------------------------
  // Sync monitoring helpers
  // ---------------------------------------------------------------------------

  /// Log the start of a sync cycle for [module].
  Future<void> logSyncStart({required String module, String? enterpriseId});

  /// Log a successful sync cycle.
  Future<void> logSyncSuccess({required int durationMs, String? module});

  /// Log a sync failure, recording the error to the crash backend too.
  Future<void> logSyncError(
    Object error,
    StackTrace? stack, {
    String? module,
  });

  /// Log a conflict detected during sync.
  Future<void> logSyncConflict({
    required String collection,
    String? resolution,
    String? module,
  });

  /// Log when the app enters offline mode.
  Future<void> logOfflineModeActivated({String? reason});

  // ---------------------------------------------------------------------------
  // Drift (SQLite) monitoring helpers
  // ---------------------------------------------------------------------------

  /// Log a slow Drift query (exceeding the configured threshold).
  Future<void> logQuerySlow({
    required String queryName,
    required int durationMs,
  });

  // ---------------------------------------------------------------------------
  // Firebase network monitoring helpers
  // ---------------------------------------------------------------------------

  /// Log a slow Firebase call (exceeding the configured threshold).
  Future<void> logFirebaseCallSlow({
    required String operation,
    required int durationMs,
  });
}
