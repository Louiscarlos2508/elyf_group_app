import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/intro/presentation/screens/login_screen.dart';
import '../../features/intro/presentation/screens/onboarding_screen.dart';
import '../../features/intro/presentation/screens/splash_screen.dart';
import '../../features/eau_minerale/presentation/screens/eau_minerale_shell_screen.dart';
import '../../features/modules/presentation/screens/boutique_home_screen.dart';
import '../../features/modules/presentation/screens/gaz_home_screen.dart';
import '../../features/modules/presentation/screens/immobilier_home_screen.dart';
import '../../features/modules/presentation/screens/module_menu_screen.dart';
import '../../features/modules/presentation/screens/orange_money_home_screen.dart';
import '../../shared/presentation/screens/placeholder_screen.dart';

enum AppRoute {
  splash,
  onboarding,
  login,
  moduleMenu,
  dashboard,
  tenantSelection,
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
        builder: (context, state) => const ModuleMenuScreen(),
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
      GoRoute(
        path: '/modules/eau_sachet',
        name: AppRoute.homeEauSachet.name,
        builder: (context, state) => const EauMineraleShellScreen(),
      ),
      GoRoute(
        path: '/modules/gaz',
        name: AppRoute.homeGaz.name,
        builder: (context, state) => const GazHomeScreen(),
      ),
      GoRoute(
        path: '/modules/orange_money',
        name: AppRoute.homeOrangeMoney.name,
        builder: (context, state) => const OrangeMoneyHomeScreen(),
      ),
      GoRoute(
        path: '/modules/immobilier',
        name: AppRoute.homeImmobilier.name,
        builder: (context, state) => const ImmobilierHomeScreen(),
      ),
      GoRoute(
        path: '/modules/boutique',
        name: AppRoute.homeBoutique.name,
        builder: (context, state) => const BoutiqueHomeScreen(),
      ),
      GoRoute(
        path: '/tenants',
        name: AppRoute.tenantSelection.name,
        pageBuilder: (context, state) => _buildTransitionPage(
          const PlaceholderScreen(
            title: 'Sélection de l’entreprise',
            message:
                'Écran pour choisir l’entreprise active et charger ses modules.',
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
