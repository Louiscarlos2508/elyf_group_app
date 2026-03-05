import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Abstract crash-reporting interface.
///
/// Implementations: [FirebaseCrashService].
/// Can be replaced with a Sentry or noop implementation without changing callers.
abstract class CrashService {
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  });

  Future<void> setUserIdentifier(String userId);

  Future<void> clearUserIdentifier();

  Future<void> setCustomKey(String key, Object value);

  Future<void> setCrashlyticsEnabled(bool enabled);
}

/// Firebase Crashlytics implementation of [CrashService].
class FirebaseCrashService implements CrashService {
  FirebaseCrashService({FirebaseCrashlytics? instance})
      : _crashlytics = instance ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {
    await _crashlytics.recordError(
      error,
      stack,
      reason: reason,
      fatal: fatal,
      printDetails: kDebugMode,
    );
  }

  @override
  Future<void> setUserIdentifier(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  @override
  Future<void> clearUserIdentifier() async {
    await _crashlytics.setUserIdentifier('');
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  @override
  Future<void> setCrashlyticsEnabled(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }
}
