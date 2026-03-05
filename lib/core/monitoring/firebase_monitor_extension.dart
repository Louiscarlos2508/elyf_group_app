import 'monitoring_service.dart';

/// Extension on [MonitoringService] for tracking Firebase/Firestore call latency.
///
/// Wraps any async Firebase operation with a stopwatch. If the call exceeds
/// [thresholdMs] a slow-call event is logged to analytics. Uses a Firebase
/// Performance custom trace when [useTrace] is true (default).
///
/// Usage:
/// ```dart
/// final docs = await monitoring.monitoredFirebaseCall(
///   'firestore_get_boutique_products',
///   () => firestore.collection('...').get(),
/// );
/// ```
extension FirebaseMonitorExtension on MonitoringService {
  /// Execute [body] and log telemetry if it exceeds [thresholdMs].
  ///
  /// - [operation] — human-readable name (e.g., `'firestore_sync_boutique'`).
  /// - [thresholdMs] — default 500 ms for network calls.
  /// - [useTrace] — when true, wraps the call in a Firebase Performance trace.
  Future<T> monitoredFirebaseCall<T>(
    String operation,
    Future<T> Function() body, {
    int thresholdMs = 500,
    bool useTrace = true,
  }) async {
    PerformanceTrace? trace;
    if (useTrace) {
      // Start trace; if it fails we still run the actual call.
      trace = await startTrace(operation).onError((_, __) => _NoopTrace());
    }

    final sw = Stopwatch()..start();
    try {
      final result = await body();
      sw.stop();
      trace?.putMetric('duration_ms', sw.elapsedMilliseconds);
      trace?.putAttribute('status', 'success');

      if (sw.elapsedMilliseconds > thresholdMs) {
        logFirebaseCallSlow(
          operation: operation,
          durationMs: sw.elapsedMilliseconds,
        );
      }

      return result;
    } catch (e) {
      sw.stop();
      trace?.putMetric('duration_ms', sw.elapsedMilliseconds);
      trace?.putAttribute('status', 'error');
      rethrow;
    } finally {
      await trace?.stop().onError((_, __) => null);
    }
  }
}

/// No-op [PerformanceTrace] used as a fallback when trace creation fails.
class _NoopTrace implements PerformanceTrace {
  @override
  void putMetric(String name, int value) {}

  @override
  void putAttribute(String name, String value) {}

  @override
  Future<void> stop() async {}
}
