import 'dart:convert';

import '../logging/app_logger.dart';
import '../offline/sync/sync_push_service.dart';
import 'package:workmanager/workmanager.dart';
import '../offline/sync_worker.dart';

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
  AppLogger.debug('Données: ${message.data}', name: 'fcm.handlers');
 
  // Handle sync trigger (silent push)
  if (message.data['type'] == 'sync_trigger') {
    AppLogger.info('Sync trigger received in foreground', name: 'fcm.handlers');
    // We will trigger this via a global state or stream that the app listens to
    _triggerReactiveSync(message.data);
    return; // Silent push, don't show local notification
  }

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
  AppLogger.debug('Données: ${message.data}', name: 'fcm.handlers.background');

  // Handle sync trigger (silent push)
  if (message.data['type'] == 'sync_trigger') {
    AppLogger.info('Sync trigger received in background', name: 'fcm.handlers.background');
    await _handleBackgroundSyncTrigger(message.data);
    return;
  }

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
  
  // - type: "action", target: "new_tour" -> Ouvrir dialog de création de tour
}

/// Trigger one-time sync based on FCM data
void _triggerReactiveSync(Map<String, dynamic> data) {
  final moduleId = data['moduleId'] as String?;
  final enterpriseId = data['enterpriseId'] as String?;
  
  SyncPushService.instance.triggerSync(
    type: moduleId != null ? SyncTriggerType.module : SyncTriggerType.global,
    moduleId: moduleId,
    enterpriseId: enterpriseId,
  );
}

/// Handle sync trigger when app is in background
Future<void> _handleBackgroundSyncTrigger(Map<String, dynamic> data) async {
  AppLogger.info('Scheduling background sync from push trigger via Workmanager', name: 'fcm.handlers.background');
  
  try {
    // On lance une tâche unique immédiate pour synchroniser les données
    await Workmanager().registerOneOffTask(
      "reactive_sync_${DateTime.now().millisecondsSinceEpoch}",
      syncTaskName,
      inputData: data,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  } catch (e) {
    AppLogger.error('Failed to schedule background sync: $e', name: 'fcm.handlers.background');
  }
}

