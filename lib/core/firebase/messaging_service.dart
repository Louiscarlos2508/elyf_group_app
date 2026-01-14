import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';

/// Service pour gérer les notifications push FCM (Firebase Cloud Messaging).
///
/// Ce service gère :
/// - L'enregistrement des tokens FCM
/// - L'abonnement aux topics par entreprise/module
/// - La réception et le traitement des notifications
/// - La gestion des permissions
class MessagingService {
  MessagingService({required this.messaging});

  final FirebaseMessaging messaging;

  /// Initialise le service de messaging.
  ///
  /// Configure les handlers pour les notifications en foreground.
  /// Note: Le handler background doit être enregistré dans main.dart avant runApp.
  Future<void> initialize({
    required void Function(RemoteMessage) onMessage,
    required void Function(RemoteMessage) onMessageOpenedApp,
    required void Function(RemoteMessage) onBackgroundMessage,
  }) async {
    // Demander la permission pour les notifications
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    developer.log(
      'Notification permission status: ${settings.authorizationStatus}',
      name: 'messaging.service',
    );

    // Configurer les handlers
    // Note: onBackgroundMessage doit être enregistré dans main.dart AVANT runApp
    FirebaseMessaging.onMessage.listen(onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);

    // Récupérer le token initial
    final token = await getToken();
    if (token != null) {
      developer.log(
        'FCM token obtained: ${token.substring(0, 20)}...',
        name: 'messaging.service',
      );
    }
  }

  /// Récupère le token FCM actuel.
  Future<String?> getToken() async {
    try {
      final token = await messaging.getToken();
      return token;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting FCM token',
        name: 'messaging.service',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Supprime le token FCM.
  Future<void> deleteToken() async {
    try {
      await messaging.deleteToken();
      developer.log('FCM token deleted', name: 'messaging.service');
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting FCM token',
        name: 'messaging.service',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// S'abonne à un topic.
  ///
  /// Les topics sont organisés par entreprise et module :
  /// - `enterprise_{enterpriseId}` : Toutes les notifications de l'entreprise
  /// - `enterprise_{enterpriseId}_module_{moduleId}` : Notifications du module
  Future<void> subscribeToTopic({
    required String enterpriseId,
    String? moduleId,
  }) async {
    try {
      // S'abonner au topic de l'entreprise
      final enterpriseTopic = 'enterprise_$enterpriseId';
      await messaging.subscribeToTopic(enterpriseTopic);
      developer.log(
        'Subscribed to topic: $enterpriseTopic',
        name: 'messaging.service',
      );

      // S'abonner au topic du module si fourni
      if (moduleId != null && moduleId.isNotEmpty) {
        final moduleTopic = 'enterprise_${enterpriseId}_module_$moduleId';
        await messaging.subscribeToTopic(moduleTopic);
        developer.log(
          'Subscribed to topic: $moduleTopic',
          name: 'messaging.service',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error subscribing to topic',
        name: 'messaging.service',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Se désabonne d'un topic.
  Future<void> unsubscribeFromTopic({
    required String enterpriseId,
    String? moduleId,
  }) async {
    try {
      // Se désabonner du topic de l'entreprise
      final enterpriseTopic = 'enterprise_$enterpriseId';
      await messaging.unsubscribeFromTopic(enterpriseTopic);
      developer.log(
        'Unsubscribed from topic: $enterpriseTopic',
        name: 'messaging.service',
      );

      // Se désabonner du topic du module si fourni
      if (moduleId != null && moduleId.isNotEmpty) {
        final moduleTopic = 'enterprise_${enterpriseId}_module_$moduleId';
        await messaging.unsubscribeFromTopic(moduleTopic);
        developer.log(
          'Unsubscribed from topic: $moduleTopic',
          name: 'messaging.service',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error unsubscribing from topic',
        name: 'messaging.service',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Récupère le message initial si l'app a été ouverte via une notification.
  Future<RemoteMessage?> getInitialMessage() async {
    try {
      return await messaging.getInitialMessage();
    } catch (e, stackTrace) {
      developer.log(
        'Error getting initial message',
        name: 'messaging.service',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Configure les options de notification pour Android.
  ///
  /// Permet de personnaliser l'apparence des notifications.
  void setAndroidNotificationChannel({
    required String channelId,
    required String channelName,
    required String channelDescription,
    String? sound,
    bool enableVibration = true,
  }) {
    // Note: La configuration du canal Android se fait généralement dans
    // le code natif Android (MainActivity.kt) ou via flutter_local_notifications.
    // Cette méthode peut être utilisée pour documenter ou préparer la configuration.
    // Pour configurer l'importance des notifications, utilisez flutter_local_notifications
    // avec Importance enum, ou configurez directement dans AndroidManifest.xml.
    developer.log(
      'Android notification channel configured: $channelId',
      name: 'messaging.service',
    );
  }

  /// Configure les options de notification pour iOS.
  void setIOSNotificationOptions({
    bool presentAlert = true,
    bool presentBadge = true,
    bool presentSound = true,
  }) {
    // Note: La configuration iOS se fait généralement dans le code natif.
    developer.log(
      'iOS notification options configured',
      name: 'messaging.service',
    );
  }
}
