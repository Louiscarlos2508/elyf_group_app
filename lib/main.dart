import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:workmanager/workmanager.dart';
import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/offline/sync_worker.dart';

Future<void> main() async {
  // S'assurer que les bindings sont initialisés
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Préserver le splash screen natif pendant l'initialisation (bootstrap)
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
  final container = await bootstrap();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ElyfApp(),
    ),
  );
}
