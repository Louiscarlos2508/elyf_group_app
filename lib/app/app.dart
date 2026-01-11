import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/providers/app_boot_status_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget for the Elyf multi-enterprise application.
class ElyfApp extends ConsumerStatefulWidget {
  const ElyfApp({super.key});

  @override
  ConsumerState<ElyfApp> createState() => _ElyfAppState();
}

class _ElyfAppState extends ConsumerState<ElyfApp> {
  @override
  void initState() {
    super.initState();
    // L'initialisation de l'auth service est gérée automatiquement
    // par le provider currentUserProvider lors du premier accès.
    // Pas besoin d'initialisation manuelle ici.
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final bootStatus = ref.watch(appBootStatusProvider);

    return MaterialApp.router(
      title: 'Elyf Groupe',
      routerConfig: router,
      theme: AppTheme.light(bootStatus),
      darkTheme: AppTheme.dark(bootStatus),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
    );
  }
}
