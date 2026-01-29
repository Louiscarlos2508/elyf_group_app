import 'dart:convert';

import 'package:go_router/go_router.dart';

import '../logging/app_logger.dart';
import '../../app/router/app_router.dart';

/// Service global de navigation basé sur les payloads de notifications.
///
/// Gère la navigation vers différentes routes de l'application
/// en fonction des données reçues dans les notifications.
class NavigationService {
  NavigationService._();

  static final NavigationService instance = NavigationService._();

  /// Callback pour obtenir le GoRouter.
  /// Doit être initialisé avec une fonction qui retourne le router.
  GoRouter? Function()? _routerGetter;

  /// Queue de payloads en attente de traitement.
  final List<String> _pendingPayloads = [];

  /// Initialise le service avec une fonction pour obtenir le router.
  void initialize(GoRouter Function() routerGetter) {
    _routerGetter = routerGetter;
    // Traiter les payloads en attente
    for (final payload in _pendingPayloads) {
      navigateFromPayload(payload);
    }
    _pendingPayloads.clear();
  }

  /// Navigue vers une route basée sur un payload JSON.
  ///
  /// Format attendu du payload :
  /// ```json
  /// {
  ///   "type": "module" | "screen" | "action",
  ///   "target": "gaz" | "orange_money" | "boutique" | etc.,
  ///   "params": {
  ///     "id": "...",
  ///     "section": "..."
  ///   }
  /// }
  /// ```
  ///
  /// Exemples :
  /// - `{"type": "module", "target": "gaz"}` -> `/modules/gaz`
  /// - `{"type": "module", "target": "orange_money", "params": {"section": "commissions"}}` -> `/modules/orange_money` (avec section)
  /// - `{"type": "screen", "target": "admin"}` -> `/admin`
  Future<void> navigateFromPayload(String? payload) async {
    if (payload == null || payload.isEmpty) {
      AppLogger.warning(
        'NavigationService: Payload manquant',
        name: 'navigation',
      );
      return;
    }

    if (_routerGetter == null) {
      AppLogger.warning(
        'NavigationService: Router getter non initialisé, mise en queue du payload',
        name: 'navigation',
      );
      _pendingPayloads.add(payload);
      return;
    }

    final router = _routerGetter!();
    if (router == null) {
      AppLogger.warning(
        'NavigationService: Router non disponible, mise en queue du payload',
        name: 'navigation',
      );
      _pendingPayloads.add(payload);
      return;
    }

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      await _handleNavigation(data);
    } catch (e, stackTrace) {
      AppLogger.error(
        'NavigationService: Erreur lors du parsing du payload: $e',
        name: 'navigation',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Gère la navigation basée sur les données de la notification.
  Future<void> _handleNavigation(Map<String, dynamic> data) async {
    if (data.isEmpty) {
      AppLogger.warning(
        'NavigationService: Pas de données de navigation',
        name: 'navigation',
      );
      return;
    }

    final router = _routerGetter?.call();
    if (router == null) {
      AppLogger.warning(
        'NavigationService: Router non disponible',
        name: 'navigation',
      );
      return;
    }

    final type = data['type'] as String?;
    final target = data['target'] as String?;
    final params = data['params'] as Map<String, dynamic>?;

    AppLogger.info(
      'NavigationService: Navigation demandée - Type: $type, Target: $target',
      name: 'navigation',
    );

    if (type == null || target == null) {
      AppLogger.warning(
        'NavigationService: Type ou target manquant dans les données',
        name: 'navigation',
      );
      return;
    }

    switch (type) {
      case 'module':
        await _navigateToModule(router, target, params);
        break;
      case 'screen':
        await _navigateToScreen(router, target, params);
        break;
      case 'action':
        await _handleAction(target, params);
        break;
      default:
        AppLogger.warning(
          'NavigationService: Type de navigation inconnu: $type',
          name: 'navigation',
        );
    }
  }

  /// Navigue vers un module spécifique.
  Future<void> _navigateToModule(
    GoRouter router,
    String target,
    Map<String, dynamic>? params,
  ) async {
    final routeMap = {
      'gaz': AppRoute.homeGaz.name,
      'orange_money': AppRoute.homeOrangeMoney.name,
      'eau_sachet': AppRoute.homeEauSachet.name,
      'immobilier': AppRoute.homeImmobilier.name,
      'boutique': AppRoute.homeBoutique.name,
    };

    final routeName = routeMap[target];
    if (routeName == null) {
      AppLogger.warning(
        'NavigationService: Module inconnu: $target',
        name: 'navigation',
      );
      return;
    }

    try {
      if (params != null && params.containsKey('id')) {
        // Navigation avec paramètre d'ID
        router.goNamed(
          routeName,
          pathParameters: {'id': params['id'].toString()},
        );
      } else {
        // Navigation simple vers le module
        router.goNamed(routeName);
      }

      AppLogger.info(
        'NavigationService: Navigation vers module $target réussie',
        name: 'navigation',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'NavigationService: Erreur lors de la navigation vers $target: $e',
        name: 'navigation',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Navigue vers un écran spécifique.
  Future<void> _navigateToScreen(
    GoRouter router,
    String target,
    Map<String, dynamic>? params,
  ) async {
    final routeMap = {
      'admin': AppRoute.admin.name,
      'modules': AppRoute.moduleMenu.name,
      'login': AppRoute.login.name,
    };

    final routeName = routeMap[target];
    if (routeName == null) {
      AppLogger.warning(
        'NavigationService: Écran inconnu: $target',
        name: 'navigation',
      );
      return;
    }

    try {
      router.goNamed(routeName);
      AppLogger.info(
        'NavigationService: Navigation vers écran $target réussie',
        name: 'navigation',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'NavigationService: Erreur lors de la navigation vers $target: $e',
        name: 'navigation',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Gère une action spécifique (dialogs, etc.).
  Future<void> _handleAction(
    String target,
    Map<String, dynamic>? params,
  ) async {
    AppLogger.info(
      'NavigationService: Action demandée - Target: $target',
      name: 'navigation',
    );

    // Les actions spécifiques peuvent être implémentées ici
    // Par exemple : ouvrir un dialog, afficher un snackbar, etc.
    switch (target) {
      case 'new_tour':
        // Exemple : Ouvrir un dialog de création de tour
        // Cette logique dépendra de l'implémentation spécifique
        AppLogger.info(
          'NavigationService: Action new_tour demandée',
          name: 'navigation',
        );
        break;
      default:
        AppLogger.warning(
          'NavigationService: Action inconnue: $target',
          name: 'navigation',
        );
    }
  }
}
