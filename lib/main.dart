import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

Future<void> main() async {
  // S'assurer que les bindings sont initialisés
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Préserver le splash screen natif pendant l'initialisation (bootstrap)
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // bootstrap() initialise déjà Firebase, Drift, et les handlers FCM
  final container = await bootstrap();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ElyfApp(),
    ),
  );
}
