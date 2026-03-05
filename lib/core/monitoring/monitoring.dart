/// Core monitoring layer — production-grade crash, analytics, and performance
/// tracking for elyf_group_app.
///
/// Public API surface:
/// - [MonitoringService]: the abstract facade — inject this everywhere.
/// - [SyncMonitorService]: sync-specific helpers.
/// - [DriftMonitorExtension]: `monitoring.monitoredQuery(...)` extension.
/// - [FirebaseMonitorExtension]: `monitoring.monitoredFirebaseCall(...)` extension.
/// - [monitoringServiceProvider] / [syncMonitorServiceProvider]: Riverpod DI.

export 'analytics_service.dart' show AnalyticsService, FirebaseAnalyticsService;
export 'crash_service.dart' show CrashService, FirebaseCrashService;
export 'drift_monitor_extension.dart' show DriftMonitorExtension;
export 'firebase_monitor_extension.dart' show FirebaseMonitorExtension;
export 'firebase_monitoring_service.dart' show FirebaseMonitoringService;
export 'monitoring_providers.dart'
    show monitoringServiceProvider, syncMonitorServiceProvider;
export 'monitoring_service.dart' show MonitoringService, PerformanceTrace;
export 'performance_service.dart'
    show PerformanceService, FirebasePerformanceService;
export 'sync_monitor_service.dart' show SyncMonitorService;
