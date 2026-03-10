import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elyf_groupe_app/features/administration/presentation/screens/admin_home_screen.dart';
import 'package:elyf_groupe_app/features/administration/presentation/screens/sections/admin_enterprise_management_section.dart';
import 'package:elyf_groupe_app/features/intro/presentation/screens/login_screen.dart';
import 'package:elyf_groupe_app/features/intro/presentation/screens/onboarding_screen.dart';
import 'package:elyf_groupe_app/features/intro/presentation/screens/splash_screen.dart';
import 'package:elyf_groupe_app/features/modules/presentation/screens/module_menu_screen.dart';
import 'package:elyf_groupe_app/features/intro/presentation/screens/tenant_selection_screen.dart';
import 'package:elyf_groupe_app/app/router/module_route_wrappers.dart';
import 'package:elyf_groupe_app/features/tour/presentation/screens/tour_router.dart';

import 'package:elyf_groupe_app/core/auth/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

enum AppRoute {
  splash,
  onboarding,
  login,
  moduleMenu,
  tenantSelection,
  dashboard,
  admin,
  adminEnterpriseManagement,
  homeEauSachet,
  homeGaz,
  homeOrangeMoney,
  homeImmobilier,
  homeBoutique,
}

/// Notifier qui écoute les changements d'état pour déclencher les redirections GoRouter
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    // Écouter les changements d'auth
    ref.listen(isAuthenticatedProvider, (_, __) => notifyListeners());
    // Écouter les changements de l'utilisateur actuel (pour isAdmin)
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
    // Écouter les changements d'entreprise active
    ref.listen(activeEnterpriseIdProvider, (_, __) => notifyListeners());
    // Écouter le flag de changement de tenant
    ref.listen(isSwitchingTenantProvider, (_, __) => notifyListeners());

    // Écouter les accès aux entreprises et modules pour déclencher la redirection
    // après le "Phase 1 Pull" (chargement des assignations)
    ref.listen(userAccessibleEnterprisesProvider, (_, __) => notifyListeners());
    ref.listen(userAccessibleModulesForActiveEnterpriseProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) async {
      final authState = ref.read(isAuthenticatedProvider);
      final activeEnterpriseIdSync = ref.read(activeEnterpriseIdProvider);
      final currentUserSync = ref.read(currentUserProvider);
      final bool isSwitching = ref.read(isSwitchingTenantProvider);
      final String location = state.uri.path;

      developer.log(
        'Router: redirect check for $location (auth: $authState, switching: $isSwitching)', 
        name: 'router'
      );

      // 0. Bloquer toute redirection pendant un switch transactionnel
      // Cela évite de tomber sur des "Permission Denied" car les données Drift 
      // n'ont pas encore fini de s'accorder avec le nouvel enterpriseId.
      if (isSwitching) {
        developer.log('Router: Switching tenant in progress, skipping redirect', name: 'router');
        return null;
      }

      // Récupérer l'état de l'auth de manière synchrone
      final bool isAuthenticated = authState;

      // Récupérer l'utilisateur pour le statut admin
      final bool isAdmin = currentUserSync.maybeWhen(
        data: (user) => user?.isAdmin ?? false,
        orElse: () => false,
      );

      // Récupérer l'ID de l'entreprise active
      final String? activeEnterpriseId = activeEnterpriseIdSync.when(
        data: (id) => id,
        loading: () => null,
        error: (_, __) => null,
      );

      // Routes publiques
      final bool isSplash = location == '/splash';
      final bool isLogin = location == '/login';
      final bool isOnboarding = location == '/onboarding';

      // 1. Splash screen : laisser passer
      if (isSplash) return null;

      // 2. Utilisateur non authentifié
      if (!isAuthenticated) {
        // Rediriger vers login si on essaie d'accéder à une route protégée
        if (!isLogin && !isOnboarding) return '/login';
        return null;
      }

      // 3. Utilisateur authentifié sur la page de login ou onboarding
      if (isLogin || isOnboarding) {
        // Attendre que l'utilisateur soit chargé pour décider de la redirection
        if (currentUserSync.isLoading) return null;
        if (isAdmin) return '/admin';

        // Tenter de déterminer si on peut sauter l'écran de sélection
        final enterprisesAsync = ref.read(userAccessibleEnterprisesProvider);
        if (enterprisesAsync.isLoading) return null;

        final enterprises = enterprisesAsync.value ?? [];
        if (enterprises.length == 1) {
          final enterpriseId = enterprises.first.id;
          
          if (activeEnterpriseId != enterpriseId) {
            // Pas encore le bon tenant, on laisse l'écran de sélection (qui va auto-switch)
            // ou on déclenche manuellement si on est certain.
            // Pour l'instant, on redirige vers selection qui a le listener auto-switch.
            return '/tenant_selection';
          }

          // Entreprise active, vérifier les modules
          final modulesAsync = ref.read(userAccessibleModulesForActiveEnterpriseProvider);
          if (modulesAsync.isLoading) return null;

          final modules = modulesAsync.value ?? [];
          if (modules.length == 1) {
            final modulePath = _getModulePathFromId(modules.first);
            if (modulePath != null) return '/modules/$modulePath';
          }
          return '/modules';
        }

        return '/tenant_selection';
      }

      // 4. Rediriger les admins qui essaient d'accéder à /modules vers /admin
      if (location == '/modules' && isAdmin) {
        return '/admin';
      }

      // 5. Auto-redirection depuis /modules si un seul choix possible
      if (location == '/modules') {
        final modulesAsync = ref.read(userAccessibleModulesForActiveEnterpriseProvider);
        if (modulesAsync.hasValue && modulesAsync.value!.length == 1) {
          final modulePath = _getModulePathFromId(modulesAsync.value!.first);
          if (modulePath != null) return '/modules/$modulePath';
        }
      }

      // 6. Protection des routes de modules
      final bool isModuleRoute = location.startsWith('/modules/');
      final bool isModuleMenu = location == '/modules';

      if (isModuleRoute && !isModuleMenu) {
        // 1. Vérifier si une entreprise est sélectionnée
        if (activeEnterpriseId == null) {
          return '/tenant_selection';
        }

        // 2. Vérifier si l'utilisateur a accès à ce module spécifique pour cette entreprise
        // On récupère les modules accessibles (déjà pré-chargés par le switch manager)
        final modulesAsync = ref.read(userAccessibleModulesForActiveEnterpriseProvider);
        if (modulesAsync.hasValue) {
          final List<String> accessibleModuleIds = modulesAsync.value!;
          final String? currentModuleId = _getModuleIdFromPath(location);

          // Si on connaît le module et qu'il n'est pas dans la liste des accès -> redirection
          if (currentModuleId != null && !accessibleModuleIds.contains(currentModuleId)) {
            developer.log(
              'Router: Access denied for module $currentModuleId in enterprise $activeEnterpriseId. Redirecting to /modules', 
              name: 'router'
            );
            return '/modules';
          }
        }
      }

      // 7. Rediriger vers la sélection d'organisation si aucune entreprise active
      if (!isAdmin && activeEnterpriseId == null && !isLogin && !isSplash && !isOnboarding && location != '/tenant_selection') {
        return '/tenant_selection';
      }

      // 7. Redirection de la racine / vers /modules ou /admin
      if (location == '/') {
        // Attendre que l'utilisateur soit chargé
        if (currentUserSync.isLoading) return null;
        if (isAdmin) return '/admin';
        return activeEnterpriseId == null ? '/tenant_selection' : '/modules';
      }

      developer.log('Router: passing through to $location', name: 'router');
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: AppRoute.splash.name,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: AppRoute.onboarding.name,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: AppRoute.login.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/modules',
        name: AppRoute.moduleMenu.name,
        builder: (context, state) => const ModuleMenuScreen(),
      ),
      GoRoute(
        path: '/tenant_selection',
        name: AppRoute.tenantSelection.name,
        builder: (context, state) => const TenantSelectionScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: AppRoute.admin.name,
        builder: (context, state) => const AdminHomeScreen(),
        routes: [
          GoRoute(
            path: 'enterprise/:id',
            name: AppRoute.adminEnterpriseManagement.name,
            builder: (context, state) {
              final enterpriseId = state.pathParameters['id']!;
              return AdminEnterpriseManagementSection(enterpriseId: enterpriseId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/',
        name: AppRoute.dashboard.name,
        builder: (context, state) => const SizedBox.shrink(), // Redirigé par le logic ci-dessus
      ),
      // Routes pour les modules utilisant l'entreprise active
      GoRoute(
        path: '/modules/eau_sachet',
        name: AppRoute.homeEauSachet.name,
        builder: (context, state) => const EauMineraleRouteWrapper(),
      ),
      GoRoute(
        path: '/modules/gaz',
        name: AppRoute.homeGaz.name,
        builder: (context, state) => const GazRouteWrapper(),
      ),
      GoRoute(
        path: '/modules/orange_money',
        name: AppRoute.homeOrangeMoney.name,
        builder: (context, state) => const OrangeMoneyRouteWrapper(),
      ),
      GoRoute(
        path: '/modules/immobilier',
        name: AppRoute.homeImmobilier.name,
        builder: (context, state) => const ImmobilierRouteWrapper(),
      ),
      GoRoute(
        path: '/modules/boutique',
        name: AppRoute.homeBoutique.name,
        builder: (context, state) => const BoutiqueRouteWrapper(),
      ),
      ...tourRouterRoutes,
    ],
  );
});

/// Helper pour mapper l'ID d'un module vers son chemin de route
String? _getModulePathFromId(String moduleId) {
  switch (moduleId) {
    case 'gaz':
      return 'gaz';
    case 'eau_minerale':
      return 'eau_sachet';
    case 'orange_money':
      return 'orange_money';
    case 'immobilier':
      return 'immobilier';
    case 'boutique':
      return 'boutique';
    default:
      return null;
  }
}

/// Helper pour mapper un chemin de route vers l'ID d'un module
String? _getModuleIdFromPath(String path) {
  if (path.contains('/modules/gaz')) return 'gaz';
  if (path.contains('/modules/eau_sachet')) return 'eau_minerale';
  if (path.contains('/modules/orange_money')) return 'orange_money';
  if (path.contains('/modules/immobilier')) return 'immobilier';
  if (path.contains('/modules/boutique')) return 'boutique';
  return null;
}
