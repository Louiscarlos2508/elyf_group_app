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
    show FirebaseFirestore, Settings;

import '../firebase_options.dart';
import '../core/permissions/services/permission_initializer.dart';
import '../core/offline/drift_service.dart';
import '../core/firebase/fcm_handlers.dart'
    show onBackgroundMessage, onForegroundMessage, onMessageOpenedApp;
import '../core/navigation/navigation_service.dart';
import '../shared/utils/local_notification_service.dart';
import '../core/offline/providers.dart';
import '../core/firebase/providers.dart';

/// Performs global asynchronous initialization before the app renders.
///
/// This is where we initialize Firebase, Drift, Remote Config,
/// crash reporting, and any other shared services.
/// Returning a [ProviderContainer] to be used in the [UncontrolledProviderScope].
Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (optional - uses fallback values if missing)
  try {
    await dotenv.load(fileName: '.env');
    developer.log('Environment variables loaded', name: 'bootstrap');
  } catch (e) {
    developer.log(
      'No .env file found - using default values',
      name: 'bootstrap',
    );
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    developer.log('Firebase initialized successfully', name: 'bootstrap');
  } catch (e, stackTrace) {
    final appException = ErrorHandler.instance.handleError(e, stackTrace);
    AppLogger.critical(
      'Error initializing Firebase: ${appException.message}',
      name: 'bootstrap',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow; // Ne pas continuer si Firebase ne peut pas s'initialiser
  }

  // Initialize date formatting for French locale
  await initializeDateFormatting('fr', null);

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  developer.log('SharedPreferences initialized', name: 'bootstrap');

  // Initialize permissions registry
  PermissionInitializer.initializeAllPermissions();
  developer.log('Permissions initialized', name: 'bootstrap');

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // Initialize offline-first infrastructure
  await _initializeOfflineServices(container);

  // Initialize Firebase Cloud Messaging (FCM)
  await _initializeFCM(container);

  developer.log('Bootstrap completed successfully', name: 'bootstrap');
  return container;
}

/// Initializes offline-first services (Drift database and connectivity).
Future<void> _initializeOfflineServices(ProviderContainer container) async {
  try {
    // Initialize Drift database
    await container.read(driftServiceProvider).initialize();
    developer.log('DriftService initialized', name: 'bootstrap');

    // Initialize connectivity monitoring
    final connectivityService = container.read(connectivityServiceProvider);
    await connectivityService.initialize();
    developer.log('ConnectivityService initialized', name: 'bootstrap');

    // Initialize sync manager with Firebase handler
    // Note: Firebase must be initialized before this point
    // Configure Firestore settings to handle database initialization
    FirebaseFirestore firestore;
    try {
      firestore = container.read(firestoreProvider);
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      developer.log('Firestore configured successfully', name: 'bootstrap');
    } catch (e, stackTrace) {
      // Firestore peut ne pas être immédiatement disponible après Firebase.initializeApp()
      // C'est normal et n'empêche pas l'app de fonctionner (mode offline-first)
      developer.log(
        'Firestore configuration warning (will work offline-first): ${e.toString()}',
        name: 'bootstrap',
        error: e,
        stackTrace: stackTrace,
      );
      // Récupérer l'instance même en cas d'erreur pour permettre la création du handler
      firestore = container.read(firestoreProvider);
    }

    // Initialize sync manager
    final syncManager = container.read(syncManagerProvider);
    await syncManager.initialize();

    // Initialize realtime sync for administration module
    try {
      final realtimeSyncService = container.read(realtimeSyncServiceProvider);
      await realtimeSyncService.startRealtimeSync();
      developer.log(
        'Realtime sync started for administration module',
        name: 'bootstrap',
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Failed to start realtime sync (will continue with periodic sync): ${appException.message}',
        name: 'bootstrap',
        error: e,
        stackTrace: stackTrace,
      );
      // Continue app startup even if realtime sync fails
    }

    // Global module realtime sync service is available via provider:
    // container.read(globalModuleRealtimeSyncServiceProvider)

    developer.log(
      'Offline services initialized successfully',
      name: 'bootstrap',
    );
  } catch (error, stackTrace) {
    final appException = ErrorHandler.instance.handleError(error, stackTrace);
    AppLogger.critical(
      'Failed to initialize offline services: ${appException.message}',
      name: 'bootstrap',
      error: error,
      stackTrace: stackTrace,
    );
    // Continue app startup even if offline services fail
    // The app should still work in online-only mode
  }
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
