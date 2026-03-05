import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_service.dart';
import 'crash_service.dart';
import 'firebase_monitoring_service.dart';
import 'monitoring_service.dart';
import 'performance_service.dart';
import 'sync_monitor_service.dart';

/// Provides the concrete [MonitoringService] backed by Firebase.
///
/// To swap to another backend (Sentry, Datadog…) replace this provider's
/// body — all call sites stay unchanged.
final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  return FirebaseMonitoringService(
    crash: FirebaseCrashService(),
    analytics: FirebaseAnalyticsService(),
    performance: FirebasePerformanceService(),
  );
});

/// Provides [SyncMonitorService], the sync-specific monitoring helper.
final syncMonitorServiceProvider = Provider<SyncMonitorService>((ref) {
  return SyncMonitorService(ref.watch(monitoringServiceProvider));
});
