import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/providers/app_boot_status_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget for the Elyf multi-enterprise application.
class ElyfApp extends ConsumerWidget {
  const ElyfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
