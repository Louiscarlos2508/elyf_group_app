import 'package:firebase_analytics/firebase_analytics.dart';

/// Abstract analytics interface.
///
/// Implementations: [FirebaseAnalyticsService].
abstract class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, Object>? parameters]);
  Future<void> setCurrentScreen(String screenName);
  Future<void> setUserId(String userId);
  Future<void> clearUserId();
}

/// Firebase Analytics implementation of [AnalyticsService].
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? instance})
      : _analytics = instance ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    // Firebase Analytics only accepts String, int, double, bool values.
    // We convert safe types and skip unsupported ones.
    final safeParams = parameters?.map((k, v) {
      if (v is String || v is int || v is double || v is bool) {
        return MapEntry(k, v);
      }
      return MapEntry(k, v.toString());
    });

    await _analytics.logEvent(
      name: _sanitizeEventName(name),
      parameters: safeParams,
    );
  }

  @override
  Future<void> setCurrentScreen(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  @override
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  @override
  Future<void> clearUserId() async {
    await _analytics.setUserId(id: null);
  }

  /// Firebase event names must be ≤ 40 chars, alphanumeric + underscore.
  String _sanitizeEventName(String name) {
    final sanitized = name
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .substring(0, name.length > 40 ? 40 : name.length);
    return sanitized;
  }
}
