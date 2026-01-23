import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/errors/error_handler.dart';
import '../../core/logging/app_logger.dart';

/// Service pour gérer les notifications locales.
///
/// Ce service utilise flutter_local_notifications pour afficher des notifications
/// locales lorsque l'application est en premier plan ou en arrière-plan.
class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialise le service de notifications locales.
  ///
  /// Cette méthode doit être appelée au démarrage de l'application.
  /// [onNotificationTap] : Callback appelé lorsqu'une notification est tapée.
  static Future<void> initialize({
    required Function(String? payload) onNotificationTap,
  }) async {
    if (_initialized) return;

    try {
      // Configuration Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuration iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Configuration globale
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialiser avec le callback de tap
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          if (details.payload != null) {
            onNotificationTap(details.payload);
          }
        },
      );

      // Créer le canal de notification Android
      await _createNotificationChannel();

      _initialized = true;
      developer.log(
        'Local notification service initialized',
        name: 'local_notification.service',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing local notification service',
        name: 'local_notification.service',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Crée le canal de notification pour Android.
  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'elyf_notifications', // ID du canal
      'Notifications ELYF', // Nom du canal
      description: 'Notifications pour l\'application ELYF Group',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Affiche une notification locale.
  ///
  /// [id] : ID unique de la notification
  /// [title] : Titre de la notification
  /// [body] : Corps de la notification
  /// [payload] : Données à passer lors du tap (format JSON recommandé)
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      developer.log(
        'Cannot show notification: service not initialized',
        name: 'local_notification.service',
      );
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'elyf_notifications',
        'Notifications ELYF',
        channelDescription: 'Notifications pour l\'application ELYF Group',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      developer.log(
        'Notification shown: $title',
        name: 'local_notification.service',
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error showing notification: ${appException.message}',
        name: 'local_notification.service',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Demande les permissions de notification (iOS uniquement).
  ///
  /// Sur Android, les permissions sont accordées automatiquement.
  static Future<bool> requestPermissions() async {
    if (!_initialized) {
      developer.log(
        'Cannot request permissions: service not initialized',
        name: 'local_notification.service',
      );
      return false;
    }

    try {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      return result ?? true; // Sur Android, retourne true par défaut
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error requesting permissions: ${appException.message}',
        name: 'local_notification.service',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Annule une notification spécifique.
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Annule toutes les notifications.
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
