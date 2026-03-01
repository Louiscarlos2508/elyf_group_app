import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/error_handler.dart';
import '../core/logging/app_logger.dart';

import 'package:cloud_firestore/cloud_firestore.dart'
    show Settings;

import '../firebase_options.dart';
import '../core/permissions/services/permission_initializer.dart';
import '../core/offline/drift_service.dart';
import '../core/firebase/fcm_handlers.dart'
    show onBackgroundMessage, onForegroundMessage, onMessageOpenedApp;
import '../core/navigation/navigation_service.dart';
import '../shared/utils/local_notification_service.dart';
import '../core/offline/providers.dart';
import '../core/firebase/providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
/// Performs global asynchronous initialization before the app renders.
///
/// This is where we initialize Firebase, Drift, Remote Config,
/// crash reporting, and any other shared services.
Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisations de base en parallèle
  final results = await Future.wait([
    // Load environment variables
    dotenv.load(fileName: '.env').catchError((_) {
      developer.log('No .env file found - using default values', name: 'bootstrap');
      return null;
    }),
    
    // Initialize Firebase
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    
    // Initialize date formatting
    initializeDateFormatting('fr', null),
    
    // Initialize SharedPreferences
    SharedPreferences.getInstance(),
  ]);

  final prefs = results[3] as SharedPreferences;
  developer.log('Base services initialized (Firebase, Prefs, Env, Dates)', name: 'bootstrap');

  // Initialize permissions registry
  PermissionInitializer.initializeAllPermissions();
  developer.log('Permissions initialized', name: 'bootstrap');

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // Initialize critical offline-first infrastructure (Drift and Connectivity)
  // We await these because they are needed for the app to function
  await _initializeCriticalOfflineServices(container);

  // Start background initializations without awaiting (Non-blocking)
  _startBackgroundServices(container);

  developer.log('Bootstrap completed successfully', name: 'bootstrap');
  return container;
}

/// Initializes critical services needed for the first screen.
Future<void> _initializeCriticalOfflineServices(ProviderContainer container) async {
  try {
    // 1. Initialize Drift and Connectivity in parallel with a safety timeout
    await Future.wait([
      container.read(driftServiceProvider).initialize(),
      container.read(connectivityServiceProvider).initialize(),
    ]).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        AppLogger.warning(
          'Critical offline services initialization timed out',
          name: 'bootstrap',
        );
        return [];
      },
    );

    // 2. Configure Firestore (Local persistence)
    final firestore = container.read(firestoreProvider);
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      // Note: Low-level timeouts are handled by Firestore internally.
      // By using persistence, we ensure the app is ready immediately.
    );
    
    developer.log('Critical offline services ready', name: 'bootstrap');
  } catch (e) {
    AppLogger.critical('Failed critical boot services: $e', name: 'bootstrap');
  }
}

/// Starts services that can run in background after the initial render.
void _startBackgroundServices(ProviderContainer container) {
  // Sync manager initialization (can be background)
  container.read(syncManagerProvider).initialize().then((_) {
    // Start realtime sync if user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      container.read(realtimeSyncServiceProvider)
          .startRealtimeSync(userId: currentUser.uid)
        .catchError((e) {
          developer.log('Realtime sync background failed: $e');
          return null;
        });
    }
  }).catchError((e) {
    developer.log('SyncManager background failed: $e');
    return null;
  });

  // FCM and Notifications (Background)
  _initializeFCM(container).catchError((e) => developer.log('FCM background failed: $e'));
}

/// Initializes Firebase Cloud Messaging (FCM).
Future<void> _initializeFCM(ProviderContainer container) async {
  try {
    final messagingService = container.read(messagingServiceProvider);

    // Initialize local notifications service
    await _initializeLocalNotifications();

    // Initialize the messaging service with handlers
    await messagingService.initialize(
      onMessage: onForegroundMessage,
      onMessageOpenedApp: onMessageOpenedApp,
      onBackgroundMessage: onBackgroundMessage,
    );

    developer.log('FCM initialized successfully', name: 'bootstrap');
  } catch (error, stackTrace) {
    final appException = ErrorHandler.instance.handleError(error, stackTrace);
    AppLogger.warning(
      'Failed to initialize FCM: ${appException.message}',
      name: 'bootstrap',
      error: error,
      stackTrace: stackTrace,
    );
    // Continue app startup even if FCM fails
    // The app should still work without push notifications
  }
}

/// Initializes local notifications service.
Future<void> _initializeLocalNotifications() async {
  try {
    await LocalNotificationService.initialize(
      onNotificationTap: (payload) {
        // Handle notification tap
        // The payload contains JSON data from the notification
        developer.log(
          'Notification tapped with payload: $payload',
          name: 'bootstrap',
        );
        
        // Navigate based on payload using NavigationService
        NavigationService.instance.navigateFromPayload(payload);
      },
    );

    // Request permissions for iOS
    await LocalNotificationService.requestPermissions();

    developer.log(
      'Local notifications initialized successfully',
      name: 'bootstrap',
    );
  } catch (error, stackTrace) {
    final appException = ErrorHandler.instance.handleError(error, stackTrace);
    AppLogger.warning(
      'Failed to initialize local notifications: ${appException.message}',
      name: 'bootstrap',
      error: error,
      stackTrace: stackTrace,
    );
    // Continue even if local notifications fail
  }
}

/// Disposes global offline services.
///
/// Call this when the app is closing.
Future<void> disposeOfflineServices(ProviderContainer container) async {
  await container.read(syncManagerProvider).dispose();
  await container.read(connectivityServiceProvider).dispose();
  await DriftService.dispose();
}
