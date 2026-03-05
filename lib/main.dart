import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:workmanager/workmanager.dart';
import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/offline/sync_worker.dart';

Future<void> main() async {
  // S'assurer que les bindings sont initialisés
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Préserver le splash screen natif pendant l'initialisation (bootstrap)
  developer.log('Preserving native splash', name: 'main');
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialiser Workmanager en arrière-plan (non-bloquant pour le démarrage)
  unawaited(Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  ).then((_) {
    return Workmanager().registerPeriodicTask(
      "1",
      syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }));

  // bootstrap() initialise déjà Firebase, Drift, et lance les services de sync en arrière-plan
  developer.log('Starting bootstrap()', name: 'main');
  final container = await bootstrap().timeout(
    const Duration(seconds: 20),
    onTimeout: () {
      developer.log('Bootstrap TIMEOUT! Proceeding with fallback...', name: 'main');
      // On pourrait retourner un container minimal ici si besoin
      throw TimeoutException('Bootstrap timed out after 20s');
    },
  );

  developer.log('Bootstrap completed, running app', name: 'main');
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ElyfApp(),
    ),
  );
}
