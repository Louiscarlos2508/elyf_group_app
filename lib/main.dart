import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/monitoring/monitoring_providers.dart';
import 'core/offline/sync_worker.dart';

/// Application entry point.
///
/// Wraps everything in [runZonedGuarded] so that uncaught async errors
/// are forwarded to Firebase Crashlytics in production.
/// [FlutterError.onError] is overridden after bootstrap (when Firebase is
/// guaranteed to be initialized) to capture Flutter framework errors.
Future<void> main() async {
  await runZonedGuarded(
    () async {
      // 1. Ensure widgets binding is ready before any platform calls.
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

      // 2. Keep the native splash screen visible while we boot.
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      // 3. Start Workmanager for background sync (non-blocking).
      unawaited(
        Workmanager()
            .initialize(callbackDispatcher, isInDebugMode: kDebugMode)
            .then((_) => Workmanager().registerPeriodicTask(
                  '1',
                  syncTaskName,
                  frequency: const Duration(minutes: 15),
                  constraints: Constraints(
                    networkType: NetworkType.connected,
                    requiresBatteryNotLow: true,
                  ),
                )),
      );

      // 4. Bootstrap: initializes Firebase, Drift, Connectivity, FCM, etc.
      developer.log('Starting bootstrap()', name: 'main');
      final container = await bootstrap().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          developer.log('Bootstrap TIMEOUT after 20s', name: 'main');
          throw TimeoutException('Bootstrap timed out after 20s');
        },
      );

      // 5. Wire up Flutter framework error handler now that Firebase is ready.
      //    We read from the container — no direct Firebase SDK usage here.
      final monitoring = container.read(monitoringServiceProvider);

      FlutterError.onError = (FlutterErrorDetails details) {
        // Present in debug mode; suppress in release to avoid double logs.
        if (kDebugMode) FlutterError.presentError(details);
        monitoring.recordError(
          details.exception,
          details.stack,
          fatal: false,
          reason: 'flutter_framework_error',
        );
      };

      developer.log('Bootstrap completed — running app', name: 'main');

      // 6. Launch the app.
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const ElyfApp(),
        ),
      );
    },
    // 7. Catch ALL uncaught async errors thrown outside the Flutter framework.
    //    At this point the Riverpod container might not exist yet, so we use
    //    FirebaseCrashlytics.instance directly (safe: Firebase was initialized
    //    in bootstrap before this handler is ever invoked in normal flow).
    (Object error, StackTrace stack) {
      developer.log(
        'Uncaught async error: $error',
        name: 'main',
        error: error,
        stackTrace: stack,
      );
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}
