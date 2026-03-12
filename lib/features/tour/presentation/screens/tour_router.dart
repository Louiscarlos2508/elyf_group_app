import 'package:go_router/go_router.dart';
import '../../data/models/tour.dart';
import 'tour_list_screen.dart';
import 'tour_creation_screen.dart';
import 'tour_shell.dart';
import 'collecte_screen.dart';
import 'collecte_site_screen.dart';
import 'recharge_screen.dart';
import 'livraison_screen.dart';
import 'livraison_grossiste_screen.dart';
import 'livraison_pos_screen.dart';
import 'frais_screen.dart';
import 'cloture_screen.dart';

final tourRouterRoutes = [
  GoRoute(
    path: '/tours',
    name: 'tour-list',
    builder: (_, __) => const TourListScreen(),
  ),
  GoRoute(
    path: '/tours/new',
    name: 'tour-creation',
    builder: (_, __) => const TourCreationScreen(),
  ),
  ShellRoute(
    builder: (context, state, child) => TourShell(
      tourId: state.pathParameters['tourId'] ?? '',
      child: child,
    ),
    routes: [
      GoRoute(
        path: '/tours/:tourId/collecte',
        name: 'collecte',
        builder: (_, state) => CollecteScreen(
          tourId: state.pathParameters['tourId']!,
        ),
        routes: [
          GoRoute(
            path: 'site/:siteId',
            name: 'collecte-site',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>;
              return CollecteSiteScreen(
                tourId: state.pathParameters['tourId']!,
                siteId: state.pathParameters['siteId']!,
                siteType: extra['type'] as TypeSite,
                siteName: extra['name'] as String,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/tours/:tourId/recharge',
        name: 'recharge',
        builder: (_, state) => RechargeScreen(
          tourId: state.pathParameters['tourId']!,
        ),
      ),
      GoRoute(
        path: '/tours/:tourId/livraison',
        name: 'livraison',
        builder: (_, state) => LivraisonScreen(
          tourId: state.pathParameters['tourId']!,
        ),
        routes: [
          GoRoute(
            path: 'grossiste/:siteId',
            name: 'livraison-grossiste',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>;
              return LivraisonGrossisteScreen(
                tourId: state.pathParameters['tourId']!,
                siteId: state.pathParameters['siteId']!,
                siteName: extra['name'] as String,
              );
            },
          ),
          GoRoute(
            path: 'pos/:siteId',
            name: 'livraison-pos',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>;
              return LivraisonPosScreen(
                tourId: state.pathParameters['tourId']!,
                siteId: state.pathParameters['siteId']!,
                siteName: extra['name'] as String,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/tours/:tourId/frais',
        name: 'frais',
        builder: (_, state) => FraisScreen(
          tourId: state.pathParameters['tourId']!,
        ),
      ),
      GoRoute(
        path: '/tours/:tourId/cloture',
        name: 'cloture',
        builder: (_, state) => ClotureScreen(
          tourId: state.pathParameters['tourId']!,
        ),
      ),
    ],
  ),
];
