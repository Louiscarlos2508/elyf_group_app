import 'package:firebase_performance/firebase_performance.dart';

import 'monitoring_service.dart';

/// Abstract performance-monitoring interface.
///
/// Implementations: [FirebasePerformanceService].
abstract class PerformanceService {
  Future<PerformanceTrace> startTrace(String name);
}

// ---------------------------------------------------------------------------
// Firebase implementation
// ---------------------------------------------------------------------------

/// Firebase Performance implementation of [PerformanceTrace].
class _FirebasePerformanceTrace implements PerformanceTrace {
  _FirebasePerformanceTrace(this._trace);

  final Trace _trace;

  @override
  void putMetric(String name, int value) => _trace.setMetric(name, value);

  @override
  void putAttribute(String name, String value) =>
      _trace.putAttribute(name, value);

  @override
  Future<void> stop() => _trace.stop();
}

/// Firebase Performance implementation of [PerformanceService].
class FirebasePerformanceService implements PerformanceService {
  FirebasePerformanceService({FirebasePerformance? instance})
      : _perf = instance ?? FirebasePerformance.instance;

  final FirebasePerformance _perf;

  @override
  Future<PerformanceTrace> startTrace(String name) async {
    final trace = _perf.newTrace(_sanitizeTraceName(name));
    await trace.start();
    return _FirebasePerformanceTrace(trace);
  }

  /// Firebase trace names: ≤ 100 chars, no leading/trailing whitespace.
  String _sanitizeTraceName(String name) {
    final trimmed = name.trim();
    return trimmed.length > 100 ? trimmed.substring(0, 100) : trimmed;
  }
}
