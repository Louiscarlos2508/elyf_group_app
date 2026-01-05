import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/services/auth_service.dart';
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
    // Initialiser l'auth service au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = ref.read(authServiceProvider);
      authService.initialize();
    });
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
    );
  }
}
