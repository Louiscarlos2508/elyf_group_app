import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../core/errors/error_handler.dart';
import '../core/logging/app_logger.dart';

import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseFirestore, Settings;

import '../firebase_options.dart';
import '../core/offline/connectivity_service.dart';
import '../core/offline/drift_service.dart';
import '../features/administration/data/services/firestore_sync_service.dart';
import '../features/administration/data/services/realtime_sync_service.dart';
import '../core/offline/sync_manager.dart';
import '../core/offline/handlers/firebase_sync_handler.dart';
import '../core/offline/global_module_realtime_sync_service.dart';
import '../core/firebase/messaging_service.dart';
import '../core/firebase/fcm_handlers.dart'
    show onBackgroundMessage, onForegroundMessage, onMessageOpenedApp;
import '../core/permissions/services/permission_initializer.dart';
import '../core/navigation/navigation_service.dart';
import '../shared/utils/local_notification_service.dart';
import '../core/offline/sync_paths.dart';

/// Global connectivity service instance.
///
/// Available after [bootstrap] completes successfully.
ConnectivityService? globalConnectivityService;

/// Global sync manager instance.
///
/// Available after [bootstrap] completes successfully.
SyncManager? globalSyncManager;

/// Global realtime sync service instance.
///
/// Available after [bootstrap] completes successfully.
/// Used to stop realtime sync on logout.
RealtimeSyncService? globalRealtimeSyncService;

/// Global module realtime sync service instance.
///
/// Available after [bootstrap] completes successfully.
/// Used to manage realtime sync for all business modules.
GlobalModuleRealtimeSyncService? globalModuleRealtimeSyncService;

/// Global messaging service instance.
///
/// Available after [bootstrap] completes successfully.
MessagingService? globalMessagingService;

/// Performs global asynchronous initialization before the app renders.
///
/// This is where we initialize Firebase, Drift, Remote Config,
/// crash reporting, and any other shared services.


Future<void> bootstrap() async {
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

  // Initialize permissions registry
  PermissionInitializer.initializeAllPermissions();
  developer.log('Permissions initialized', name: 'bootstrap');

  // Initialize offline-first infrastructure
  await _initializeOfflineServices();

  // Initialize Firebase Cloud Messaging (FCM)
  await _initializeFCM();

  developer.log('Bootstrap completed successfully', name: 'bootstrap');
}

/// Initializes offline-first services (Drift database and connectivity).
Future<void> _initializeOfflineServices() async {
  try {
    // Initialize Drift database
    await DriftService.instance.initialize();
    developer.log('DriftService initialized', name: 'bootstrap');

    // Initialize connectivity monitoring
    globalConnectivityService = ConnectivityService();
    await globalConnectivityService!.initialize();
    developer.log('ConnectivityService initialized', name: 'bootstrap');

    // Initialize sync manager with Firebase handler
    // Note: Firebase must be initialized before this point
    // Configure Firestore settings to handle database initialization
    FirebaseFirestore firestore;
    try {
      firestore = FirebaseFirestore.instance;
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
      firestore = FirebaseFirestore.instance;
    }

    // Note: Firestore database errors (like "database does not exist") are handled
    // gracefully by the sync manager. The app can work offline-first and will
    // sync automatically when the database becomes available.

    // collectionPaths is now global

    final firebaseHandler = FirebaseSyncHandler(
      firestore: firestore,
      driftService: DriftService.instance,
      collectionPaths: collectionPaths,
    );

        // Récupérer AuthService pour vérifier l'authentification pendant sync
        // Note: AuthService est un singleton, on peut le récupérer via le provider
        // mais pour éviter la dépendance circulaire, on l'injectera plus tard si nécessaire
        // Pour l'instant, on peut utiliser null et l'injecter via un setter si besoin
        globalSyncManager = SyncManager(
          driftService: DriftService.instance,
          connectivityService: globalConnectivityService!,
          config: const SyncConfig(
            maxRetryAttempts: 5,
            syncIntervalMinutes: 5,
            maxOperationAgeHours: 72,
          ),
          syncHandler: firebaseHandler,
          // AuthService sera injecté après l'initialisation via un setter si nécessaire
          // Pour l'instant, on peut utiliser null et vérifier via FirebaseAuth directement
        );
    await globalSyncManager!.initialize();

    // Initialize realtime sync for administration module
    // Store globally so it can be stopped on logout
    try {
      globalRealtimeSyncService = RealtimeSyncService(
        driftService: DriftService.instance,
        firestore: firestore,
        firestoreSync: FirestoreSyncService(
          driftService: DriftService.instance,
          firestore: firestore,
        ),
      );
      await globalRealtimeSyncService!.startRealtimeSync();
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

    // Initialize global module realtime sync service
    // This will be used to sync all business modules after login
    try {
      globalModuleRealtimeSyncService = GlobalModuleRealtimeSyncService(
        firestore: firestore,
        driftService: DriftService.instance,
        syncManager: globalSyncManager,
        conflictResolver: const ConflictResolver(),
        collectionPaths: collectionPaths,
      );
      developer.log(
        'Global module realtime sync service initialized',
        name: 'bootstrap',
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Failed to initialize global module realtime sync service: ${appException.message}',
        name: 'bootstrap',
        error: e,
        stackTrace: stackTrace,
      );
      // Continue app startup even if this fails
    }

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
Future<void> _initializeFCM() async {
  try {
    final messaging = FirebaseMessaging.instance;
    globalMessagingService = MessagingService(messaging: messaging);

    // Initialize local notifications service
    await _initializeLocalNotifications();

    // Initialize the messaging service with handlers
    await globalMessagingService!.initialize(
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
Future<void> disposeOfflineServices() async {
  await globalSyncManager?.dispose();
  await globalConnectivityService?.dispose();
  await DriftService.dispose();
}
