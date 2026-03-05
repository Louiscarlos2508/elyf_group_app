import 'monitoring_service.dart';

/// Extension on [MonitoringService] for monitoring Drift (SQLite) queries.
///
/// Wraps any async Drift query with duration tracking. If the query exceeds
/// [thresholdMs], an event is logged to analytics. This never throws —
/// monitoring failures never propagate to the caller.
///
/// Usage:
/// ```dart
/// // Inject MonitoringService via Riverpod
/// final monitoring = ref.watch(monitoringServiceProvider);
///
/// final results = await monitoring.monitoredQuery(
///   'boutique_products_list',
///   () => driftService.products.getAll(enterpriseId: eid),
/// );
/// ```
extension DriftMonitorExtension on MonitoringService {
  /// Execute [body] and log a slow-query event if it exceeds [thresholdMs].
  ///
  /// - [queryName] — human-readable name (e.g., `'gaz_sales_by_date'`).
  /// - [thresholdMs] — default 200 ms; adjust per query sensitivity.
  Future<T> monitoredQuery<T>(
    String queryName,
    Future<T> Function() body, {
    int thresholdMs = 200,
  }) async {
    final sw = Stopwatch()..start();
    try {
      return await body();
    } finally {
      sw.stop();
      if (sw.elapsedMilliseconds > thresholdMs) {
        // Fire-and-forget — we do NOT await to avoid altering query semantics.
        logQuerySlow(
          queryName: queryName,
          durationMs: sw.elapsedMilliseconds,
        );
      }
    }
  }
}
