import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/presentation/widgets/auth_guard.dart';
import '../../features/administration/presentation/screens/admin_home_screen.dart';
import '../../features/intro/presentation/screens/login_screen.dart';
import '../../features/intro/presentation/screens/onboarding_screen.dart';
import '../../features/intro/presentation/screens/splash_screen.dart';
import '../../features/modules/presentation/screens/module_menu_screen.dart';
import '../../shared/presentation/screens/placeholder_screen.dart';
import 'module_route_wrappers.dart';

enum AppRoute {
  splash,
  onboarding,
  login,
  moduleMenu,
  dashboard,
  tenantSelection,
  admin,
  homeEauSachet,
  homeGaz,
  homeOrangeMoney,
  homeImmobilier,
  homeBoutique,
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
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
        builder: (context, state) => const AuthGuard(child: ModuleMenuScreen()),
      ),
      GoRoute(
        path: '/admin',
        name: AppRoute.admin.name,
        builder: (context, state) => const AuthGuard(child: AdminHomeScreen()),
      ),
      GoRoute(
        path: '/',
        name: AppRoute.dashboard.name,
        pageBuilder: (context, state) => _buildTransitionPage(
          const PlaceholderScreen(
            title: 'Elyf Dashboard',
            message:
                'Point d’entrée pour gérer toutes les entreprises et modules.',
          ),
        ),
      ),
      // Routes pour les modules utilisant l'entreprise active (protégées)
      GoRoute(
        path: '/modules/eau_sachet',
        name: AppRoute.homeEauSachet.name,
        builder: (context, state) =>
            const AuthGuard(child: EauMineraleRouteWrapper()),
      ),
      GoRoute(
        path: '/modules/gaz',
        name: AppRoute.homeGaz.name,
        builder: (context, state) => const AuthGuard(child: GazRouteWrapper()),
      ),
      GoRoute(
        path: '/modules/orange_money',
        name: AppRoute.homeOrangeMoney.name,
        builder: (context, state) =>
            const AuthGuard(child: OrangeMoneyRouteWrapper()),
      ),
      GoRoute(
        path: '/modules/immobilier',
        name: AppRoute.homeImmobilier.name,
        builder: (context, state) =>
            const AuthGuard(child: ImmobilierRouteWrapper()),
      ),
      GoRoute(
        path: '/modules/boutique',
        name: AppRoute.homeBoutique.name,
        builder: (context, state) =>
            const AuthGuard(child: BoutiqueRouteWrapper()),
      ),
      GoRoute(
        path: '/tenants',
        name: AppRoute.tenantSelection.name,
        pageBuilder: (context, state) => _buildTransitionPage(
          const PlaceholderScreen(
            title: "Sélection de l'entreprise",
            message:
                "Écran pour choisir l'entreprise active et charger ses modules.",
          ),
        ),
      ),
    ],
  );
});

CustomTransitionPage<void> _buildTransitionPage(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, view) {
      final tween = Tween<double>(begin: 0.9, end: 1);
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: animation.drive(
            tween.chain(CurveTween(curve: Curves.easeOut)),
          ),
          child: view,
        ),
      );
    },
  );
}
