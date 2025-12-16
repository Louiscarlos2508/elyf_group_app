import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/administration/presentation/screens/admin_home_screen.dart';
import '../../features/intro/presentation/screens/login_screen.dart';
import '../../features/intro/presentation/screens/onboarding_screen.dart';
import '../../features/intro/presentation/screens/splash_screen.dart';
import '../../features/eau_minerale/presentation/screens/eau_minerale_shell_screen.dart';
import '../../features/boutique/presentation/screens/boutique_shell_screen.dart';
import '../../features/immobilier/presentation/screens/immobilier_shell_screen.dart';
import '../../features/modules/presentation/screens/module_menu_screen.dart';
import '../../features/gaz/presentation/screens/gaz_shell_screen.dart';
import '../../features/orange_money/presentation/screens/orange_money_shell_screen.dart';
import '../../shared/presentation/screens/placeholder_screen.dart';
import '../../shared/presentation/screens/treasury_shell_screen.dart';

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
  treasury,
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
        path: '/admin',
        name: AppRoute.admin.name,
        builder: (context, state) => const AdminHomeScreen(),
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
      // Routes pour les modules avec enterpriseId optionnel
      GoRoute(
        path: '/modules/eau_sachet',
        name: AppRoute.homeEauSachet.name,
        builder: (context, state) {
          const enterpriseId = 'eau_sachet_1';
          const moduleId = 'eau_minerale';
          return EauMineraleShellScreen(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          );
        },
        routes: [
          GoRoute(
            path: ':enterpriseId',
            builder: (context, state) {
              final enterpriseId = state.pathParameters['enterpriseId']!;
              const moduleId = 'eau_minerale';
              return EauMineraleShellScreen(
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/modules/gaz',
        name: AppRoute.homeGaz.name,
        builder: (context, state) {
          const enterpriseId = 'gaz_1';
          const moduleId = 'gaz';
          return GazShellScreen(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          );
        },
        routes: [
          GoRoute(
            path: ':enterpriseId',
            builder: (context, state) {
              final enterpriseId = state.pathParameters['enterpriseId']!;
              const moduleId = 'gaz';
              return GazShellScreen(
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/modules/orange_money',
        name: AppRoute.homeOrangeMoney.name,
        builder: (context, state) {
          const enterpriseId = 'orange_money_1';
          const moduleId = 'orange_money';
          return OrangeMoneyShellScreen(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          );
        },
        routes: [
          GoRoute(
            path: ':enterpriseId',
            builder: (context, state) {
              final enterpriseId = state.pathParameters['enterpriseId']!;
              const moduleId = 'orange_money';
              return OrangeMoneyShellScreen(
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/modules/immobilier',
        name: AppRoute.homeImmobilier.name,
        builder: (context, state) {
          const enterpriseId = 'immobilier_1';
          const moduleId = 'immobilier';
          return ImmobilierShellScreen(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          );
        },
        routes: [
          GoRoute(
            path: ':enterpriseId',
            builder: (context, state) {
              final enterpriseId = state.pathParameters['enterpriseId']!;
              const moduleId = 'immobilier';
              return ImmobilierShellScreen(
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/modules/boutique',
        name: AppRoute.homeBoutique.name,
        builder: (context, state) {
          const enterpriseId = 'boutique_1';
          const moduleId = 'boutique';
          return BoutiqueShellScreen(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          );
        },
        routes: [
          GoRoute(
            path: ':enterpriseId',
            builder: (context, state) {
              final enterpriseId = state.pathParameters['enterpriseId']!;
              const moduleId = 'boutique';
              return BoutiqueShellScreen(
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              );
            },
          ),
        ],
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
      // Route pour la trésorerie (module partagé)
      GoRoute(
        path: '/treasury',
        name: AppRoute.treasury.name,
        builder: (context, state) => const TreasuryShellScreen(),
        routes: [
          GoRoute(
            path: ':moduleId',
            builder: (context, state) {
              final moduleId = state.pathParameters['moduleId']!;
              return TreasuryShellScreen(moduleId: moduleId);
            },
          ),
        ],
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
