import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

Future<void> main() async {
  // S'assurer que les bindings sont initialisés avant bootstrap
  WidgetsFlutterBinding.ensureInitialized();

  // bootstrap() initialise déjà Firebase, Drift, et les handlers FCM (background & foreground)
  // de manière ordonnée pour éviter les conflits d'isolats.
  final container = await bootstrap();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ElyfApp(),
    ),
  );
}
