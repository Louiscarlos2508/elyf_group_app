import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/firebase/fcm_handlers.dart';

/// Handler background pour FCM - doit être top-level et enregistré avant runApp
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await onBackgroundMessage(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enregistrer le handler background AVANT toute autre initialisation Firebase
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final container = await bootstrap();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ElyfApp(),
    ),
  );
}
