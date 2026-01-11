import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';

/// Handler pour les notifications reçues en foreground.
/// 
/// Cette fonction est appelée quand l'app est active et reçoit une notification.
void onForegroundMessage(RemoteMessage message) {
  developer.log(
    'Notification reçue en foreground: ${message.messageId}',
    name: 'fcm.handlers',
  );
  developer.log(
    'Titre: ${message.notification?.title}, Corps: ${message.notification?.body}',
    name: 'fcm.handlers',
  );
  developer.log(
    'Données: ${message.data}',
    name: 'fcm.handlers',
  );
  
  // TODO: Afficher une notification locale ou mettre à jour l'UI
  // Note: On ne peut pas utiliser NotificationService ici car on n'a pas de BuildContext
  // Il faudra utiliser un système de notification locale ou un state management global
}

/// Handler pour les notifications qui ouvrent l'app.
/// 
/// Cette fonction est appelée quand l'utilisateur appuie sur une notification
/// et que l'app est en arrière-plan ou fermée.
void onMessageOpenedApp(RemoteMessage message) {
  developer.log(
    'Notification a ouvert l\'app: ${message.messageId}',
    name: 'fcm.handlers',
  );
  developer.log(
    'Titre: ${message.notification?.title}, Corps: ${message.notification?.body}',
    name: 'fcm.handlers',
  );
  developer.log(
    'Données: ${message.data}',
    name: 'fcm.handlers',
  );
  
  // TODO: Naviguer vers la page appropriée basée sur les données de la notification
  // Il faudra utiliser un système de navigation global (GoRouter avec un provider)
}

/// Handler pour les notifications reçues en background.
/// 
/// Cette fonction DOIT être top-level (pas une méthode de classe) pour être
/// appelée par Firebase Messaging quand l'app est en arrière-plan.
/// 
/// Cette fonction sera appelée automatiquement par Firebase Messaging.
@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  developer.log(
    'Notification reçue en background: ${message.messageId}',
    name: 'fcm.handlers.background',
  );
  developer.log(
    'Titre: ${message.notification?.title}, Corps: ${message.notification?.body}',
    name: 'fcm.handlers.background',
  );
  developer.log(
    'Données: ${message.data}',
    name: 'fcm.handlers.background',
  );
  
  // TODO: Traiter la notification (sauvegarder en local, mettre à jour les données, etc.)
  // Note: On ne peut pas accéder à l'UI ici car l'app est en background
}

