import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:elyf_groupe_app/core/navigation/navigation_service.dart';
import 'package:elyf_groupe_app/core/session/providers.dart';
import 'package:elyf_groupe_app/shared/providers/app_boot_status_provider.dart';
import 'package:elyf_groupe_app/app/router/app_router.dart';
import 'package:elyf_groupe_app/app/theme/app_theme.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

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
    
    // Initialiser le contrôleur de cycle de vie de l'application
    // Il gère les transitions de session et les effets secondaires (Sync, etc.)
    ref.watch(appLifecycleControllerProvider);

    // Initialiser le NavigationService avec le router
    NavigationService.instance.initialize(() => router);

    return MaterialApp.router(
      title: 'Elyf Groupe',
      routerConfig: router,
      theme: AppTheme.light(bootStatus),
      darkTheme: AppTheme.dark(bootStatus),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      // Ajout des délégués de localisation pour corriger l'erreur DatePickerDialog
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', ''), // Français
        Locale('en', ''), // Anglais
      ],
      builder: (context, child) {
        final isSwitching = ref.watch(isSwitchingTenantProvider);

        // Configurer SystemUIOverlayStyle
        final brightness = Theme.of(context).brightness;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarColor: Theme.of(context).colorScheme.surface,
            systemNavigationBarIconBrightness: brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
          ),
        );
        return Stack(
          children: [
            if (child != null) child,
            if (isSwitching)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Changement d\'organisation...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
