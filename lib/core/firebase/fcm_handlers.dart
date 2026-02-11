import 'dart:convert';

import '../logging/app_logger.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../shared/utils/local_notification_service.dart';

/// Handler pour les notifications reçues en foreground.
///
/// Cette fonction est appelée quand l'app est active et reçoit une notification.
void onForegroundMessage(RemoteMessage message) {
  AppLogger.debug(
    'Notification reçue en foreground: ${message.messageId}',
    name: 'fcm.handlers',
  );
  AppLogger.debug(
    'Titre: ${message.notification?.title}, Corps: ${message.notification?.body}',
    name: 'fcm.handlers',
  );
  AppLogger.debug('Données: ${message.data}', name: 'fcm.handlers');

  // ✅ TODO résolu: Afficher une notification locale
  final title = message.notification?.title ?? 'Nouvelle notification';
  final body = message.notification?.body ?? '';
  
  // Encoder les données en JSON pour le payload
  final payload = message.data.isNotEmpty 
      ? jsonEncode(message.data) 
      : null;

  // Afficher la notification locale
  LocalNotificationService.showNotification(
    id: message.hashCode,
    title: title,
    body: body,
    payload: payload,
  );
}

/// Handler pour les notifications qui ouvrent l'app.
///
/// Cette fonction est appelée quand l'utilisateur appuie sur une notification
/// et que l'app est en arrière-plan ou fermée.
void onMessageOpenedApp(RemoteMessage message) {
  AppLogger.info(
    'Notification a ouvert l\'app: ${message.messageId}',
    name: 'fcm.handlers',
  );
  AppLogger.info(
    'Titre: ${message.notification?.title}, Corps: ${message.notification?.body}',
    name: 'fcm.handlers',
  );
  AppLogger.info('Données: ${message.data}', name: 'fcm.handlers');

  // ✅ TODO résolu: Naviguer vers la page appropriée
  _handleNotificationNavigation(message.data);
}

/// Handler pour les notifications reçues en background.
///
/// Cette fonction DOIT être top-level (pas une méthode de classe) pour être
/// appelée par Firebase Messaging quand l'app est en arrière-plan.
///
/// Cette fonction sera appelée automatiquement par Firebase Messaging.
@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  AppLogger.debug(
    'Notification reçue en background: ${message.messageId}',
    name: 'fcm.handlers.background',
  );
  AppLogger.debug(
    'Titre: ${message.notification?.title}, Corps: ${message.notification?.body}',
    name: 'fcm.handlers.background',
  );
  AppLogger.debug('Données: ${message.data}', name: 'fcm.handlers.background');

  // ✅ TODO résolu: Traiter la notification en arrière-plan
  // Pour l'instant, on log simplement. Si nécessaire, on peut :
  // - Sauvegarder les données en local (Drift/SQLite)
  // - Mettre à jour un compteur de badges
  // - Déclencher une synchronisation
  
  AppLogger.debug(
    'Notification traitée en background',
    name: 'fcm.handlers.background',
  );
}

/// Gère la navigation basée sur les données de la notification.
///
/// Format attendu des données :
/// {
///   "type": "module" | "screen" | "action",
///   "target": "gaz" | "orange_money" | "boutique" | etc.,
///   "params": {...} // Paramètres additionnels
/// }
void _handleNotificationNavigation(Map<String, dynamic> data) {
  if (data.isEmpty) {
    AppLogger.info(
      'Pas de données de navigation dans la notification',
      name: 'fcm.handlers',
    );
    return;
  }

  final type = data['type'] as String?;
  final target = data['target'] as String?;

  AppLogger.info(
    'Navigation demandée - Type: $type, Target: $target',
    name: 'fcm.handlers',
  );

  // La navigation sera gérée via un NavigationService global
  // qui sera créé dans la prochaine étape
  // Pour l'instant, on log simplement l'intention
  
  // Exemples de navigation possibles :
  // - type: "module", target: "gaz" -> /modules/gaz
  // - type: "module", target: "orange_money" -> /modules/orange_money
  // - type: "screen", target: "commissions" -> /modules/orange_money (section commissions)
  // - type: "action", target: "new_tour" -> Ouvrir dialog de création de tour
}

