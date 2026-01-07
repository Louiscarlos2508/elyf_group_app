import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/offline/connectivity_service.dart';
import '../core/offline/isar_service.dart';
import '../core/offline/sync_manager.dart';
import '../core/offline/handlers/firebase_sync_handler.dart';

/// Global connectivity service instance.
///
/// Available after [bootstrap] completes successfully.
ConnectivityService? globalConnectivityService;

/// Global sync manager instance.
///
/// Available after [bootstrap] completes successfully.
SyncManager? globalSyncManager;

/// Performs global asynchronous initialization before the app renders.
///
/// This is where we initialize Firebase, Isar, Remote Config,
/// crash reporting, and any other shared services.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for French locale
  await initializeDateFormatting('fr', null);

  // Initialize offline-first infrastructure
  await _initializeOfflineServices();

  // TODO(carlo): wire Firebase.initializeApp and background jobs.
}

/// Initializes offline-first services (Isar database and connectivity).
Future<void> _initializeOfflineServices() async {
  try {
    // Initialize Isar database
    await IsarService.instance.initialize();

    // Initialize connectivity monitoring
    globalConnectivityService = ConnectivityService();
    await globalConnectivityService!.initialize();

    // Initialize sync manager with Firebase handler
    // Note: Firebase must be initialized before this point
    final firebaseHandler = FirebaseSyncHandler(
      firestore: FirebaseFirestore.instance,
      collectionPaths: {
        'sales': (enterpriseId) => 'enterprises/$enterpriseId/sales',
        'products': (enterpriseId) => 'enterprises/$enterpriseId/products',
        'expenses': (enterpriseId) => 'enterprises/$enterpriseId/expenses',
        'customers': (enterpriseId) => 'enterprises/$enterpriseId/customers',
        'agents': (enterpriseId) => 'enterprises/$enterpriseId/agents',
        'transactions': (enterpriseId) => 'enterprises/$enterpriseId/transactions',
        'properties': (enterpriseId) => 'enterprises/$enterpriseId/properties',
        'tenants': (enterpriseId) => 'enterprises/$enterpriseId/tenants',
        'contracts': (enterpriseId) => 'enterprises/$enterpriseId/contracts',
        'payments': (enterpriseId) => 'enterprises/$enterpriseId/payments',
        'machines': (enterpriseId) => 'enterprises/$enterpriseId/machines',
        'bobines': (enterpriseId) => 'enterprises/$enterpriseId/bobines',
        'productionSessions': (enterpriseId) => 'enterprises/$enterpriseId/productionSessions',
      },
    );

    globalSyncManager = SyncManager(
      isarService: IsarService.instance,
      connectivityService: globalConnectivityService!,
      config: const SyncConfig(
        maxRetryAttempts: 5,
        syncIntervalMinutes: 5,
        maxOperationAgeHours: 72,
      ),
      syncHandler: firebaseHandler,
    );
    await globalSyncManager!.initialize();

    developer.log(
      'Offline services initialized successfully',
      name: 'bootstrap',
    );
  } catch (error, stackTrace) {
    developer.log(
      'Failed to initialize offline services',
      name: 'bootstrap',
      error: error,
      stackTrace: stackTrace,
    );
    // Continue app startup even if offline services fail
    // The app should still work in online-only mode
  }
}

/// Disposes global offline services.
///
/// Call this when the app is closing.
Future<void> disposeOfflineServices() async {
  await globalSyncManager?.dispose();
  await globalConnectivityService?.dispose();
  await IsarService.dispose();
}
